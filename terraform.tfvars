aws_region   = "us-east-1"
project_name = "bookstore"
environment  = "prod"

# Leave empty to use the default CloudFront URL.
custom_domain_name = ""
route53_zone_id    = ""

# Keep Fargate disabled until you push a Spring Boot image and need heavier backend logic.
enable_fargate = false

db_name                            = "bookstore"
db_master_username                 = "bookadmin"
db_instance_class                  = "db.t3.micro"
db_backup_retention_days           = 1
worker_lambda_reserved_concurrency = -1
api_lambda_timeout                 = 20

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
