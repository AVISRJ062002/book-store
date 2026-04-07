locals {
  name_prefix = substr(replace(lower("${var.project_name}-${var.environment}"), "/[^a-z0-9-]/", "-"), 0, 40)

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Workload    = "bookstore"
    },
    var.tags
  )
}

# Core networking keeps application traffic private and avoids NAT Gateway cost.
module "vpc" {
  source = "./modules/vpc"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_fargate           = var.enable_fargate
  tags                     = local.tags
}

# Private worker Lambdas use this security group to reach RDS and VPC endpoints.
resource "aws_security_group" "private_lambda" {
  name        = "${local.name_prefix}-private-lambda-sg"
  description = "Security group for private bookstore worker Lambdas"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow private workers to reach RDS and AWS endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# API Gateway VPC Link uses a dedicated security group when the Fargate path is enabled.
resource "aws_security_group" "apigw_vpc_link" {
  count = var.enable_fargate ? 1 : 0

  name        = "${local.name_prefix}-apigw-vpclink-sg"
  description = "Security group for API Gateway VPC Link ENIs"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow API Gateway to reach the internal ALB"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Static frontend storage stays private and is exposed only through CloudFront.
module "storage" {
  source = "./modules/s3"

  name_prefix          = local.name_prefix
  force_destroy        = var.frontend_bucket_force_destroy
  create_images_bucket = var.create_images_bucket
  tags                 = local.tags
}

# Optional Fargate path is provisioned only when explicitly enabled.
module "fargate" {
  count  = var.enable_fargate ? 1 : 0
  source = "./modules/fargate"

  name_prefix                    = local.name_prefix
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_app_subnet_ids
  allowed_alb_security_group_ids = [aws_security_group.apigw_vpc_link[0].id]
  container_port                 = var.fargate_container_port
  cpu                            = var.fargate_cpu
  memory                         = var.fargate_memory
  desired_count                  = var.fargate_desired_count
  min_capacity                   = var.fargate_min_capacity
  max_capacity                   = var.fargate_max_capacity
  health_check_path              = var.fargate_health_check_path
  container_image                = var.fargate_container_image
  task_environment               = var.fargate_environment
  tags                           = local.tags
}

# PostgreSQL runs in isolated private subnets and exposes credentials through Secrets Manager.
module "database" {
  source = "./modules/rds"

  name_prefix   = local.name_prefix
  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.private_db_subnet_ids
  allowed_security_group_ids = compact(concat(
    [aws_security_group.private_lambda.id],
    var.enable_fargate ? [module.fargate[0].service_security_group_id] : []
  ))
  db_name                = var.db_name
  master_username        = var.db_master_username
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  engine_version         = var.db_engine_version
  parameter_group_family = var.db_parameter_group_family
  backup_retention_days  = var.db_backup_retention_days
  multi_az               = var.db_multi_az
  deletion_protection    = var.db_deletion_protection
  skip_final_snapshot    = var.db_skip_final_snapshot
  tags                   = local.tags
}

# Public Lambda stays outside the VPC so it can reach external book APIs without a NAT Gateway.
module "public_api_lambda" {
  source = "./modules/lambda"

  name_prefix                    = local.name_prefix
  function_name                  = "${local.name_prefix}-public-books-api"
  description                    = "Public bookstore API Lambda for external integrations and lightweight HTTP requests"
  source_file                    = "${path.root}/lambda_src/book_handler.py"
  handler                        = "book_handler.lambda_handler"
  runtime                        = var.lambda_runtime
  architectures                  = var.lambda_architectures
  memory_size                    = var.api_lambda_memory_size
  timeout                        = var.api_lambda_timeout
  reserved_concurrent_executions = var.api_lambda_reserved_concurrency
  attach_to_vpc                  = false
  subnet_ids                     = []
  security_group_ids             = []
  secret_arns                    = []
  environment_variables = merge(
    {
      EXTERNAL_API_BASE_URL = "https://openlibrary.org/search.json"
      BOOK_IMAGES_BUCKET    = module.storage.images_bucket_name != null ? module.storage.images_bucket_name : ""
    },
    var.api_lambda_environment
  )
  tags = local.tags
}

# Private worker Lambda demonstrates background processing and private DB connectivity without internet egress.
module "private_worker_lambda" {
  source = "./modules/lambda"

  name_prefix                    = local.name_prefix
  function_name                  = "${local.name_prefix}-private-worker"
  description                    = "Private bookstore worker Lambda for scheduled jobs and secure database checks"
  source_file                    = "${path.root}/lambda_src/book_worker.py"
  handler                        = "book_worker.lambda_handler"
  runtime                        = var.lambda_runtime
  architectures                  = var.lambda_architectures
  memory_size                    = var.worker_lambda_memory_size
  timeout                        = var.worker_lambda_timeout
  reserved_concurrent_executions = var.worker_lambda_reserved_concurrency
  attach_to_vpc                  = true
  subnet_ids                     = module.vpc.private_app_subnet_ids
  security_group_ids             = [aws_security_group.private_lambda.id]
  secret_arns                    = [module.database.master_secret_arn]
  environment_variables = merge(
    {
      DB_SECRET_ARN = module.database.master_secret_arn
      DB_HOST       = module.database.endpoint
      DB_PORT       = tostring(module.database.port)
      DB_NAME       = var.db_name
    },
    var.worker_lambda_environment
  )
  tags = local.tags
}

# EventBridge triggers the private worker so background jobs do not require a permanently running host.
resource "aws_cloudwatch_event_rule" "background_worker" {
  name                = "${local.name_prefix}-background-worker"
  description         = "Scheduled trigger for the private bookstore worker Lambda"
  schedule_expression = var.background_worker_schedule_expression
}

resource "aws_cloudwatch_event_target" "background_worker" {
  rule      = aws_cloudwatch_event_rule.background_worker.name
  target_id = "private-worker-lambda"
  arn       = module.private_worker_lambda.function_arn
}

resource "aws_lambda_permission" "allow_eventbridge_worker" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.private_worker_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.background_worker.arn
}

# HTTP API is the low-cost front door for Lambda routes and the optional private Fargate path.
module "api" {
  source = "./modules/api_gateway"

  name_prefix                  = local.name_prefix
  lambda_function_name         = module.public_api_lambda.function_name
  lambda_invoke_arn            = module.public_api_lambda.invoke_arn
  lambda_route_key             = var.api_lambda_route_key
  additional_lambda_route_keys = var.additional_api_lambda_route_keys
  cors_allowed_origins         = var.api_cors_allowed_origins
  enable_fargate_route         = var.enable_fargate
  fargate_route_key            = var.api_fargate_route_key
  fargate_listener_arn         = var.enable_fargate ? module.fargate[0].alb_listener_arn : ""
  vpc_link_subnet_ids          = var.enable_fargate ? module.vpc.private_app_subnet_ids : []
  vpc_link_security_group_ids  = var.enable_fargate ? [aws_security_group.apigw_vpc_link[0].id] : []
  tags                         = local.tags
}

# CloudFront fronts the private S3 bucket and optionally provisions ACM + Route53 for a custom domain.
module "cdn" {
  source = "./modules/cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix                 = local.name_prefix
  frontend_bucket_id          = module.storage.frontend_bucket_id
  frontend_bucket_domain_name = module.storage.frontend_bucket_regional_domain_name
  cloudfront_price_class      = var.cloudfront_price_class
  custom_domain_name          = var.custom_domain_name
  route53_zone_id             = var.route53_zone_id
  tags                        = local.tags
}

# Bucket policy only trusts this CloudFront distribution through Origin Access Control.
data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid = "AllowCloudFrontReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.storage.frontend_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.storage.frontend_bucket_id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}
