output "frontend_bucket_id" {
  description = "Frontend bucket name."
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "Frontend bucket ARN."
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name used by CloudFront."
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "images_bucket_name" {
  description = "Optional images bucket name."
  value       = var.create_images_bucket ? aws_s3_bucket.images[0].id : null
}

output "images_bucket_arn" {
  description = "Optional images bucket ARN."
  value       = var.create_images_bucket ? aws_s3_bucket.images[0].arn : null
}
