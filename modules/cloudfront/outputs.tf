output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "Native CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "url" {
  description = "Public URL for the frontend."
  value       = "https://${local.use_custom_domain ? var.custom_domain_name : aws_cloudfront_distribution.this.domain_name}"
}
