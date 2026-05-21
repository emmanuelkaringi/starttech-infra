# StartTech Operations Runbook

## Table of Contents
1. [Common Operations](#common-operations)
2. [Troubleshooting](#troubleshooting)
3. [Disaster Recovery](#disaster-recovery)
4. [Maintenance Procedures](#maintenance)

---

## Common Operations

### Check System Health

```bash
# Check backend health
curl https://d37rt95zzt3h33.cloudfront.net/health
# Expected: {"cache":"ok","database":"ok"}

# Check EC2 instances
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names starttech-backend-asg-production \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService']"

# Check target group health
TG_ARN=$(aws elbv2 describe-target-groups \
  --names starttech-tg-production \
  --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

## View Application Logs

### Via AWS Console:

`CloudWatch → Log Groups → /starttech/application`

### Via CLI - tail logs

`aws logs tail /starttech/application --follow`

### Insights Query - Errors in last hour
```sh
aws logs start-query \
  --log-group-name /starttech/application \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50'
```

## Deploy New Backend Version (Manual)

`cd starttech-application/backend`

`ECR_URI="376129861708.dkr.ecr.us-east-1.amazonaws.com/starttech-backend"`

### Build and push
```sh
docker build -t starttech-backend:latest .

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

docker tag starttech-backend:latest $ECR_URI:latest

docker push $ECR_URI:latest

# Get instances and deploy
INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names starttech-backend-asg-production \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
  --output text)

for ID in $INSTANCE_IDS; do
  aws ssm send-command --instance-ids "$ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "{\"commands\":[\"docker pull $ECR_URI:latest && docker stop starttech-backend && docker rm starttech-backend && docker run -d --name starttech-backend -p 8080:8080 --restart always $ECR_URI:latest\"]}"
done
```

## Deploy New Frontend Version (Manual)
```sh
cd starttech-application/frontend
npm ci
npm run build

BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'starttech-frontend-production')].Name" --output text)
aws s3 sync dist/ "s3://$BUCKET/" --delete

CF_DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text)
aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths "/*"
```

## Troubleshooting
### Issue: 502 Bad Gateway
**Symptoms**: Frontend returns 502, health check fails

#### Causes & Fixes:
1. Container not running on EC2:

    ```
    # SSH or SSM into instance
    docker ps -a
    docker logs starttech-backend
    # Restart if needed
    docker start starttech-backend
    ```
2. Target group health check failing:
- Verify app listens on port 8080: `netstat -tlnp | grep 8080`
- Check security group allows traffic from ALB

### Issue: 401 Unauthorized
**Symptoms**: Login works but API calls return 401

#### Causes & Fixes:
1. Cookie domain mismatch: Verify `COOKIE_DOMAINS` matches the URL domain
2. Secure cookie over HTTP: Set `SECURE_COOKIE=false` if not using HTTPS
3. CORS not configured: Check `ALLOWED_ORIGINS` includes frontend URL

### Issue: High CPU Alarm
**Response**:
1. Check CloudWatch metrics for the instance
2. View application logs for unusual activity
3. Scale ASG if needed: aws autoscaling

    ```
    update-auto-scaling-group --auto-scaling-group-name starttech-backend-asg-production --desired-capacity 3
    ```

### Issue: MongoDB Connection Error
**Symptoms**: Health check shows `database: error`

**Fixes:**
1. Check MongoDB Atlas status page
2. Verify the connection string in EC2 env vars
3. Check if Atlas IP whitelist includes EC2 IPs

## Disaster Recovery
### Infrastructure Rebuild

```sh
# 1. Bootstrap state backend
cd starttech-infra/terraform/bootstrap
terraform init && terraform apply

# 2. Apply main infrastructure
cd ..
terraform init && terraform apply
```

## Database Recovery
MongoDB Atlas provides automatic backups:
1. Go to MongoDB Atlas Console
2. Select cluster → Backup → Choose snapshot → Restore

## Application Recovery
```sh
# Rebuild and redeploy everything
cd starttech-application

# Backend
cd backend && docker build -t starttech-backend . && cd ..

# Frontend
cd frontend && npm ci && npm run build && cd ..

# Deploy both (see deploy scripts above)
```

## Maintenance Procedures
### OS Patching
Amazon Linux 2023 applies security updates automatically

For major updates, update AMI in Terraform and refresh ASG instances

### SSL Certificate
CloudFront uses AWS default certificate (auto-renewed)

For custom domains, ACM certificates auto-renew

### Cost Optimization
Scale ASG down during low traffic

Use reserved instances for long-term savings

Review unused resources monthly'

## Backup Verification
```sh
# Verify S3 frontend
aws s3 ls s3://starttech-frontend-production-*/ --recursive | wc -l

# Verify ECR images
aws ecr describe-images --repository-name starttech-backend

# Verify Terraform state
aws s3 ls s3://starttech-tfstate-production-*/
```