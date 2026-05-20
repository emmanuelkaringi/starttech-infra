#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Infrastructure Deployment...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars not found. Creating from example...${NC}"
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo -e "${RED}Please edit terraform/terraform.tfvars with your values before running this script again.${NC}"
    exit 1
fi

cd terraform

# Initialize Terraform
echo -e "${GREEN}Initializing Terraform...${NC}"
terraform init

# Format and validate
echo -e "${GREEN}Formatting and validating Terraform code...${NC}"
terraform fmt
terraform validate

# Plan
echo -e "${GREEN}Creating Terraform plan...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "${YELLOW}Do you want to apply this plan? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Applying Terraform configuration...${NC}"
    terraform apply tfplan

    # Show outputs
    echo -e "${GREEN}Deployment complete! Infrastructure outputs:${NC}"
    terraform output

    # Update kubeconfig if using EKS (future use)
    echo -e "${GREEN}Saving infrastructure outputs to ../infrastructure-outputs.json${NC}"
    terraform output -json > ../infrastructure-outputs.json
    
    echo -e "${GREEN}Infrastructure deployment completed successfully!${NC}"
else
    echo -e "${YELLOW}Deployment cancelled.${NC}"
fi
