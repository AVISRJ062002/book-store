variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to destroy buckets that still contain objects."
  type        = bool
  default     = false
}

variable "create_images_bucket" {
  description = "Create a second bucket for book images."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to S3 resources."
  type        = map(string)
  default     = {}
}
