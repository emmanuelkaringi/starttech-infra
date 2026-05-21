# StartTech Infrastructure Architecture

> **Live Application**: [https://d2uv8gh2gkla6v.cloudfront.net](https://d2uv8gh2gkla6v.cloudfront.net)

Infrastructure as Code (IaC) architecture for the StartTech full-stack application.

---

## 📋 Table of Contents

- [Infrastructure Overview](#infrastructure-overview)
- [Network Architecture](#network-architecture)
- [Compute Architecture](#compute-architecture)
- [Storage & CDN Architecture](#storage--cdn-architecture)
- [Caching Architecture](#caching-architecture)
- [Monitoring Architecture](#monitoring-architecture)
- [Security Architecture](#security-architecture)
- [Terraform Module Structure](#terraform-module-structure)

---

## Infrastructure Overview

All infrastructure is defined as code using Terraform and deployed via GitHub Actions.

### AWS Resources

| Category | Resource | Count | Purpose |
|----------|----------|-------|---------|
| **Network** | VPC | 1 | Isolated network |
| | Public Subnets | 2 | ALB, NAT Gateway |
| | Private Subnets | 2 | EC2, Redis |
| | NAT Gateway | 1 | Outbound internet for private subnets |
| | Internet Gateway | 1 | Public internet access |
| **Compute** | EC2 Instances | 2-4 | Backend application (Auto Scaling) |
| | Launch Template | 1 | EC2 configuration |
| | ALB | 1 | Load balancing |
| | Target Group | 1 | Health checks, routing |
| **Storage** | S3 Buckets | 2 | Frontend hosting + Terraform state |
| | CloudFront | 1 | CDN (S3 + ALB origins) |
| **Caching** | ElastiCache Redis | 1 | Session and data caching |
| **Security** | Security Groups | 3 | ALB, EC2, Redis |
| | IAM Roles | 2 | EC2 + Policies |
| **Monitoring** | CloudWatch Log Groups | 2 | Application + System logs |
| | CloudWatch Alarms | 3 | CPU, Healthy Hosts, Redis CPU |

---

## Network Architecture
```
INTERNET
│
▼
┌─────────────────┐
│ Internet Gateway│
└────────┬────────┘
│
┌────────▼────────┐
│ VPC (10.0.0.0/16)│
└────────┬────────┘
│
┌──────────────────┼──────────────────┐
│ │ │
┌───────▼───────┐ ┌───────▼───────┐ ┌───────▼───────┐
│ Public Subnet │ │ Public Subnet │ │ NAT Gateway │
│ 10.0.1.0/24 │ │ 10.0.2.0/24 │ │ (us-east-1a) │
│ (us-east-1a) │ │ (us-east-1b) │ └───────┬───────┘
└───────┬───────┘ └───────┬───────┘ │
│ │ │
┌───────▼───────┐ ┌───────▼───────┐ │
│ ALB (Public) │ │ ALB (Public) │ │
└───────┬───────┘ └───────┬───────┘ │
│ │ │
┌───────▼───────┐ ┌───────▼───────┐ │
│ Private Subnet│ │ Private Subnet│ │
│ 10.0.10.0/24 │ │ 10.0.11.0/24 │ │
│ (us-east-1a) │ │ (us-east-1b) │◄─────────┘
└───────┬───────┘ └───────┬───────┘
│ │
┌───────▼───────┐ ┌───────▼───────┐
│ EC2 + Redis │ │ EC2 + Redis │
└───────────────┘ └───────────────┘
```

### Subnet Design

| Subnet Type | CIDR | AZ | Purpose |
|-------------|------|----|---------|
| Public 1 | 10.0.1.0/24 | us-east-1a | ALB endpoint |
| Public 2 | 10.0.2.0/24 | us-east-1b | ALB endpoint (HA) |
| Private 1 | 10.0.10.0/24 | us-east-1a | EC2 + Redis |
| Private 2 | 10.0.11.0/24 | us-east-1b | EC2 (HA) |

---

## Compute Architecture

### Auto Scaling Configuration

| Parameter | Value |
|-----------|-------|
| Min Size | 2 |
| Max Size | 4 |
| Desired Capacity | 2 |
| Instance Type | t3.small |
| AMI | Amazon Linux 2023 |
| Health Check | ELB (port 8080, path /health) |

### Scaling Policies

| Policy | Trigger | Action |
|--------|---------|--------|
| Scale Up | CPU > 80% for 10 min | +1 instance |
| Scale Down | CPU < 40% for 10 min | -1 instance |

### IAM Role Permissions

| Policy | Purpose |
|--------|---------|
| ECR Access | Pull Docker images |
| CloudWatch Logs | Write application logs |
| SSM Managed Instance | Remote management |

---

## Storage & CDN Architecture

### S3 Buckets

| Bucket | Purpose | Public Access |
|--------|---------|---------------|
| `starttech-frontend-production-*` | React static files | Blocked (CloudFront only) |
| `starttech-tfstate-production-*` | Terraform state | Blocked |

### CloudFront Configuration

| Setting | Value |
|---------|-------|
| Price Class | 100 (US, Canada, Europe) |
| Default TTL | 3600s (1 hour) |
| Max TTL | 86400s (24 hours) |
| Viewer Protocol | Redirect HTTP → HTTPS |

### CloudFront Behaviors

| Path Pattern | Origin | Methods | Caching |
|-------------|--------|---------|---------|
| Default (*) | S3 | GET, HEAD | Enabled |
| /auth/* | ALB | All | Disabled |
| /tasks/* | ALB | All | Disabled |
| /users/* | ALB | All | Disabled |
| /health | ALB | GET, HEAD | Disabled |
| /swagger/* | ALB | GET, HEAD | Disabled |

---

## Terraform Module Structure
```
terraform/
├── main.tf # Root module, provider config
├── variables.tf # Input variables
├── outputs.tf # Output values
├── terraform.tfvars # Variable values (gitignored)
├── bootstrap/ # State backend setup
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
└── modules/
├── networking/ # VPC, subnets, NAT, IGW, route tables
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
├── security/ # Security groups
│ ├── main.tf
│ ├── variables.tf
│ └── outputs.tf
├── compute/ # EC2, ASG, ALB, IAM, Launch Template
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ ├── user_data.sh
│ └── ecr_policy.tf
├── storage/ # S3, CloudFront
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── cloudfront_full.tf
└── monitoring/ # CloudWatch, ElastiCache
├── main.tf
├── variables.tf
└── outputs.tf
```

---

## Security Architecture

### Security Groups

| SG Name | Ingress | Egress |
|---------|---------|--------|
| `starttech-alb-sg` | Port 80/443 from 0.0.0.0/0 | All |
| `starttech-ec2-sg` | Port 8080 from ALB SG | All |
| `starttech-redis-sg` | Port 6379 from EC2 SG | All |

### Principle of Least Privilege

- EC2 instances can only pull from ECR (not push)
- EC2 can only write to specific CloudWatch log groups
- Redis only accessible from EC2 instances
- S3 buckets block all public access