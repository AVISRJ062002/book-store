variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name that API Gateway can invoke."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN for the Lambda integration."
  type        = string
}

variable "lambda_route_key" {
  description = "HTTP API route key mapped to the Lambda integration."
  type        = string
}

variable "additional_lambda_route_keys" {
  description = "Additional route keys mapped to the same Lambda integration."
  type        = list(string)
  default     = []
}

variable "cors_allowed_origins" {
  description = "CORS origins for the HTTP API."
  type        = list(string)
  default     = ["*"]
}

variable "enable_fargate_route" {
  description = "Create an additional route backed by a private Fargate service."
  type        = bool
  default     = false
}

variable "fargate_route_key" {
  description = "Route key mapped to the private Fargate integration."
  type        = string
  default     = "ANY /admin/{proxy+}"
}

variable "fargate_listener_arn" {
  description = "ALB listener ARN used by the private integration."
  type        = string
  default     = ""
}

variable "vpc_link_subnet_ids" {
  description = "Subnet IDs used by the API Gateway VPC Link."
  type        = list(string)
  default     = []
}

variable "vpc_link_security_group_ids" {
  description = "Security groups used by the API Gateway VPC Link."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to API Gateway resources."
  type        = map(string)
  default     = {}
}
