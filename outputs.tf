output "api_endpoint" {
  description = "Base URL of the low-cost HTTP API Gateway."
  value       = module.api.api_endpoint
}

output "cloudfront_url" {
  description = "Public HTTPS endpoint for the React frontend."
  value       = module.cdn.url
}

output "cloudfront_distribution_domain_name" {
  description = "Native CloudFront domain name for the frontend CDN."
  value       = module.cdn.distribution_domain_name
}

output "frontend_bucket_name" {
  description = "S3 bucket name that stores the React build artifacts."
  value       = module.storage.frontend_bucket_id
}

output "images_bucket_name" {
  description = "Optional S3 bucket name for book images."
  value       = module.storage.images_bucket_name
}

output "db_endpoint" {
  description = "Private RDS PostgreSQL endpoint."
  value       = module.database.endpoint
}

output "db_port" {
  description = "RDS PostgreSQL port."
  value       = module.database.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN containing the generated PostgreSQL credentials."
  value       = module.database.master_secret_arn
}

output "public_lambda_name" {
  description = "Public API Lambda function name."
  value       = module.public_api_lambda.function_name
}

output "private_worker_lambda_name" {
  description = "Private scheduled worker Lambda function name."
  value       = module.private_worker_lambda.function_name
}

output "fargate_repository_url" {
  description = "Optional ECR repository URL for the Spring Boot image."
  value       = var.enable_fargate ? module.fargate[0].repository_url : null
}
