terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend will be configured after S3 bucket creation
  # backend "s3" {
  #   bucket         = "starttech-tfstate-production"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks-production"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = var.tags
}

# Security Module
module "security" {
  source = "./modules/security"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = var.tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  environment                     = var.environment
  vpc_id                          = module.networking.vpc_id
  public_subnet_ids              = module.networking.public_subnet_ids
  private_subnet_ids             = module.networking.private_subnet_ids
  alb_security_group_id          = module.security.alb_security_group_id
  ec2_security_group_id          = module.security.ec2_security_group_id
  instance_type                  = var.instance_type
  min_size                       = var.min_size
  max_size                       = var.max_size
  desired_capacity               = var.desired_capacity
  mongodb_atlas_connection_string = var.mongodb_atlas_connection_string
  tags                           = var.tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  environment = var.environment
  domain_name = var.domain_name
  tags        = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  redis_security_group_id  = module.security.redis_security_group_id
  autoscaling_group_name   = module.compute.autoscaling_group_name
  alb_arn                  = module.compute.alb_arn
  tags                     = var.tags
}
