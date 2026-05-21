# StartTech System Architecture

## Overview

StartTech is a full-stack ToDo application with a React frontend, Go backend API, Redis caching, and MongoDB database. The infrastructure is fully managed with Terraform and deployed via GitHub Actions CI/CD pipelines.

## Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│ CloudFront CDN │
│ (HTTPS, Global Edge Caching) │
└─────────────────────┬───────────────────┬───────────────────────┘
│ │
┌───────▼───────┐ ┌───────▼───────┐
│ S3 Bucket │ │ ALB │
│ (Frontend) │ │ (Backend) │
└───────────────┘ └───────┬───────┘
│
┌───────────▼───────────┐
│ Auto Scaling Group │
│ EC2 Instances (2-4) │
│ Docker Containers │
└───────────┬───────────┘
│
┌─────────────────────┼─────────────────────┐
│ │ │
┌───────▼───────┐ ┌────────▼────────┐ ┌────────▼────────┐
│ ElastiCache │ │ CloudWatch │ │ MongoDB Atlas │
│ Redis 7.0 │ │ Logs & Metrics │ │ (Cloud DBaaS) │
└───────────────┘ └─────────────────┘ └─────────────────┘
```

## Component Details

### Frontend (React)
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **State Management**: React Context + TanStack Query
- **Styling**: Tailwind CSS with shadcn/ui components
- **Hosting**: S3 bucket with CloudFront CDN
- **Authentication**: JWT with httpOnly cookies

### Backend API (Go)
- **Framework**: Gin Web Framework
- **Authentication**: JWT tokens (httpOnly cookies)
- **Database Driver**: MongoDB Go Driver
- **Caching**: Redis via go-redis
- **Logging**: Structured JSON logging with zerolog
- **API Docs**: Swagger/OpenAPI auto-generated
- **Container**: Docker with multi-stage builds

### Infrastructure (Terraform)
- **Networking**: VPC with public/private subnets across 2 AZs
- **Compute**: EC2 with Auto Scaling (2-4 instances)
- **Load Balancer**: Application Load Balancer
- **CDN**: CloudFront with S3 and ALB origins
- **Caching**: ElastiCache Redis 7.0
- **Monitoring**: CloudWatch Logs, Metrics, Alarms
- **CI/CD**: GitHub Actions with ECR

## Data Flow

1. **User Request** → CloudFront CDN
2. **Static Assets** → S3 Bucket (cached at edge)
3. **API Requests** (`/auth/*`, `/tasks/*`, `/users/*`, `/health`) → ALB → EC2
4. **Backend Processing**:
   - Authentication: JWT validation
   - Cache Lookup: Redis (if enabled)
   - Data Store: MongoDB Atlas
5. **Response** → ALB → CloudFront → User

## Security Architecture

- **Network**: Security groups restrict traffic between components
- **Authentication**: JWT tokens with httpOnly, Secure cookies
- **Secrets**: GitHub Secrets for CI/CD, environment variables on EC2
- **IAM**: Least-privilege roles for EC2 (ECR pull, CloudWatch write)
- **Encryption**: HTTPS via CloudFront, MongoDB Atlas TLS
- **Scanning**: Trivy vulnerability scanning in CI/CD

## Monitoring Architecture

- **Logs**: CloudWatch Log Groups (`/starttech/application`, `/starttech/ec2/system`)
- **Metrics**: CPU, Memory, Network via CloudWatch Agent
- **Alarms**: High CPU, Unhealthy Hosts, Redis CPU
- **Dashboard**: CloudWatch Dashboard for unified view
- **Insights**: CloudWatch Logs Insights for log analysis