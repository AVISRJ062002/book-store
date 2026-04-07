variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "frontend_bucket_id" {
  description = "Bucket name used as the CloudFront origin ID."
  type        = string
}

variable "frontend_bucket_domain_name" {
  description = "Regional bucket domain name used by CloudFront."
  type        = string
}

variable "cloudfront_price_class" {
  description = "Price class used by the CloudFront distribution."
  type        = string
  default     = "PriceClass_100"
}

variable "custom_domain_name" {
  description = "Optional custom domain name for CloudFront."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID used for certificate validation and alias records."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to CloudFront and ACM resources."
  type        = map(string)
  default     = {}
}
