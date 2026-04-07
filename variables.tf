variable "aws_region" {
  description = "Primary AWS region for the bookstore stack."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Logical application name used in resource naming."
  type        = string
  default     = "bookstore"
}

variable "environment" {
  description = "Environment name used in tags and resource names."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags applied to every supported resource."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the bookstore VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used for public, app, and database subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets used by private Lambdas, VPC endpoints, and optional Fargate."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for isolated database subnets."
  type        = list(string)
  default     = ["10.20.20.0/24", "10.20.21.0/24"]
}

variable "frontend_bucket_force_destroy" {
  description = "Allow Terraform to destroy the frontend S3 bucket even if it still contains files."
  type        = bool
  default     = false
}

variable "create_images_bucket" {
  description = "Create a second private S3 bucket for book cover images and media uploads."
  type        = bool
  default     = true
}

variable "cloudfront_price_class" {
  description = "CloudFront price class used to control edge location cost."
  type        = string
  default     = "PriceClass_100"
}

variable "custom_domain_name" {
  description = "Optional custom domain for the CloudFront distribution. Leave empty to use the default CloudFront URL."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID used to validate ACM certificates and create the alias record."
  type        = string
  default     = ""
}

variable "api_cors_allowed_origins" {
  description = "Origins allowed to call the HTTP API."
  type        = list(string)
  default     = ["*"]
}

variable "api_lambda_route_key" {
  description = "Primary API Gateway route that forwards to the public Lambda."
  type        = string
  default     = "GET /books"
}

variable "additional_api_lambda_route_keys" {
  description = "Additional HTTP API route keys that forward to the public bookstore Lambda."
  type        = list(string)
  default     = ["GET /books/{work_id}", "GET /collections", "GET /health"]
}

variable "api_fargate_route_key" {
  description = "Optional API Gateway route that forwards to the private Fargate service."
  type        = string
  default     = "ANY /admin/{proxy+}"
}

variable "lambda_runtime" {
  description = "Python runtime for Lambda functions."
  type        = string
  default     = "python3.12"
}

variable "lambda_architectures" {
  description = "Processor architectures for the Lambda functions."
  type        = list(string)
  default     = ["x86_64"]
}

variable "api_lambda_memory_size" {
  description = "Memory size in MB for the public API Lambda."
  type        = number
  default     = 256
}

variable "api_lambda_timeout" {
  description = "Timeout in seconds for the public API Lambda."
  type        = number
  default     = 10
}

variable "api_lambda_reserved_concurrency" {
  description = "Reserved concurrency for the public API Lambda. Use -1 for unreserved."
  type        = number
  default     = -1
}

variable "api_lambda_environment" {
  description = "Extra environment variables added to the public API Lambda."
  type        = map(string)
  default     = {}
}

variable "worker_lambda_memory_size" {
  description = "Memory size in MB for the private background worker Lambda."
  type        = number
  default     = 256
}

variable "worker_lambda_timeout" {
  description = "Timeout in seconds for the private background worker Lambda."
  type        = number
  default     = 30
}

variable "worker_lambda_reserved_concurrency" {
  description = "Reserved concurrency for the private background worker Lambda. Use -1 for unreserved."
  type        = number
  default     = 2
}

variable "worker_lambda_environment" {
  description = "Extra environment variables added to the private worker Lambda."
  type        = map(string)
  default     = {}
}

variable "background_worker_schedule_expression" {
  description = "EventBridge schedule used to trigger the private worker Lambda."
  type        = string
  default     = "rate(15 minutes)"
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "bookstore"
}

variable "db_master_username" {
  description = "Master username for PostgreSQL. The password is generated and stored in Secrets Manager by RDS."
  type        = string
  default     = "bookadmin"
}

variable "db_instance_class" {
  description = "RDS instance class. Keep db.t3.micro for low cost."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage in GB for the PostgreSQL instance."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaled storage in GB for the PostgreSQL instance."
  type        = number
  default     = 100
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for Amazon RDS."
  type        = string
  default     = "16.4"
}

variable "db_parameter_group_family" {
  description = "Parameter group family matching the selected PostgreSQL major version."
  type        = string
  default     = "postgres16"
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for higher availability. Disabled by default for cost optimization."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Protect the database from accidental deletion."
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. Keep false for production safety."
  type        = bool
  default     = false
}

variable "enable_fargate" {
  description = "Deploy the optional Spring Boot backend on ECS Fargate."
  type        = bool
  default     = false
}

variable "fargate_cpu" {
  description = "CPU units for the Fargate task definition."
  type        = number
  default     = 512
}

variable "fargate_memory" {
  description = "Memory in MiB for the Fargate task definition."
  type        = number
  default     = 1024
}

variable "fargate_desired_count" {
  description = "Desired number of Fargate tasks. Defaults to zero so the optional path stays cost-neutral until an image is pushed."
  type        = number
  default     = 0
}

variable "fargate_min_capacity" {
  description = "Minimum desired count for ECS service auto scaling."
  type        = number
  default     = 0
}

variable "fargate_max_capacity" {
  description = "Maximum desired count for ECS service auto scaling."
  type        = number
  default     = 4
}

variable "fargate_container_port" {
  description = "Container port exposed by the Spring Boot service."
  type        = number
  default     = 8080
}

variable "fargate_container_image" {
  description = "Optional full container image URI. Leave empty to create an ECR repository and use the latest tag."
  type        = string
  default     = ""
}

variable "fargate_health_check_path" {
  description = "Health check path used by the internal ALB target group."
  type        = string
  default     = "/actuator/health"
}

variable "fargate_environment" {
  description = "Environment variables injected into the optional Spring Boot container."
  type        = map(string)
  default = {
    SPRING_PROFILES_ACTIVE = "prod"
  }
}
