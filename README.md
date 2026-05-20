# StartTech Infrastructure

Infrastructure as Code (IaC) for the StartTech full-stack application using Terraform.

## Architecture

- **Frontend**: React application served from S3 with CloudFront CDN
- **Backend**: Golang API on EC2 instances with Auto Scaling behind ALB
- **Caching**: ElastiCache Redis cluster
- **Database**: MongoDB Atlas
- **Monitoring**: CloudWatch Logs, Metrics, and Dashboards

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- GitHub account with repository secrets set up

## Quick Start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Repository Structure
```
.
├── .github/workflows/          # CI/CD for infrastructure
├── terraform/                  # Terraform configurations
│   ├── modules/               # Reusable modules
│   │   ├── networking/        # VPC, subnets, etc.
│   │   ├── compute/           # EC2, ASG, ALB
│   │   ├── storage/           # S3, CloudFront
│   │   └── monitoring/        # CloudWatch
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/                    # Helper scripts
└── monitoring/                 # Monitoring configurations
```

