# Outputs will be added as modules are created
output "aws_region" {
  description = "The AWS region used for deployment"
  value       = var.aws_region
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}
