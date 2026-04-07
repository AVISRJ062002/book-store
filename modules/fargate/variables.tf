variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the ECS service and ALB."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the ALB, ECS service, and VPC link path."
  type        = list(string)
}

variable "allowed_alb_security_group_ids" {
  description = "Security groups allowed to call the internal ALB."
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Container port exposed by the Spring Boot application."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the Fargate task."
  type        = number
}

variable "memory" {
  description = "Memory in MiB for the Fargate task."
  type        = number
}

variable "desired_count" {
  description = "Desired number of ECS tasks."
  type        = number
  default     = 0
}

variable "min_capacity" {
  description = "Minimum ECS service capacity."
  type        = number
  default     = 0
}

variable "max_capacity" {
  description = "Maximum ECS service capacity."
  type        = number
  default     = 4
}

variable "health_check_path" {
  description = "Health check path used by the ALB target group."
  type        = string
  default     = "/actuator/health"
}

variable "container_image" {
  description = "Optional full container image URI. Leave empty to use the ECR repository created by the module."
  type        = string
  default     = ""
}

variable "task_environment" {
  description = "Environment variables for the Spring Boot container."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to ECS, ECR, and ALB resources."
  type        = map(string)
  default     = {}
}
