# Terraform Bookstore on AWS

This project provisions a production-oriented, zero-EC2 bookstore platform on AWS using a serverless-first approach:

- React frontend on private S3 behind CloudFront
- HTTP API Gateway for low-cost APIs
- Public Lambda for searchable book catalog, collections, and book detail APIs
- Private worker Lambda for scheduled/background jobs and secure RDS access
- PostgreSQL on Amazon RDS in private subnets
- Optional ECS Fargate path for heavier Spring Boot workloads

## Prerequisites

- Terraform 1.14.x
- AWS credentials with permissions for VPC, IAM, Lambda, API Gateway, CloudFront, S3, RDS, ECS, ECR, ACM, and Route53
- A pre-created S3 bucket for Terraform remote state if you want to use the `backend "s3"` block

## Commands

Initialize with a production S3 backend:

```powershell
terraform init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="key=terraform-bookstore/prod.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="use_lockfile=true"
```

Validate the configuration:

```powershell
terraform validate
```

Create an execution plan:

```powershell
terraform plan -out=tfplan
```

Apply the infrastructure:

```powershell
terraform apply tfplan
```

## Deployment Notes

- Upload your React build after apply:

```powershell
aws s3 sync .\build "s3://<frontend-bucket-name>" --delete
```

- A complete React multi-page storefront lives under `react-storefront`. Build it with:

```powershell
cd .\react-storefront
npm install
npm run build
aws s3 sync .\dist "s3://<frontend-bucket-name>" --delete
```

- If you want a branded HTTPS domain, set `custom_domain_name` and `route53_zone_id` in `terraform.tfvars`. The CloudFront module will request and validate an ACM certificate in `us-east-1`.
- If you want the Spring Boot path, set `enable_fargate = true`, build the image from `springboot-app/Dockerfile`, push it to the output ECR repository, then increase `fargate_desired_count` from `0`.
- The architecture intentionally avoids NAT Gateway charges. Public internet access is handled by CloudFront and the public Lambda, while private workloads use VPC endpoints to reach AWS services.
