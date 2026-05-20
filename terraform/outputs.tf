# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = module.security.ec2_security_group_id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = module.security.redis_security_group_id
}

# Compute Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

# Storage Outputs
output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend"
  value       = module.storage.frontend_bucket_name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.storage.cloudfront_domain_name
}

output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.storage.terraform_state_bucket
}

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.storage.dynamodb_lock_table
}

# General
output "aws_region" {
  description = "The AWS region used for deployment"
  value       = var.aws_region
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}
