# ALB Security Group - Public facing
resource "aws_security_group" "alb" {
  name        = "starttech-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP ingress
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS ingress
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "starttech-alb-sg-${var.environment}"
  })
}

# EC2 Security Group - Backend instances
resource "aws_security_group" "ec2" {
  name        = "starttech-ec2-sg-${var.environment}"
  description = "Security group for EC2 backend instances"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSH access (restrict to your IP in production)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to specific IP in production
  }

  # Egress - allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "starttech-ec2-sg-${var.environment}"
  })
}

# ElastiCache Redis Security Group
resource "aws_security_group" "redis" {
  name        = "starttech-redis-sg-${var.environment}"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  # Allow traffic only from EC2 instances
  ingress {
    description     = "Redis from EC2 instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Egress - allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "starttech-redis-sg-${var.environment}"
  })
}
