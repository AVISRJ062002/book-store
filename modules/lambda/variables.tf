variable "name_prefix" {
  description = "Common name prefix retained for future extensibility."
  type        = string
}

variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "description" {
  description = "Lambda function description."
  type        = string
  default     = ""
}

variable "source_file" {
  description = "Path to the Python handler source file."
  type        = string
}

variable "handler" {
  description = "Handler entrypoint."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
}

variable "architectures" {
  description = "Lambda architectures."
  type        = list(string)
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the function. Use -1 for unreserved."
  type        = number
  default     = -1
}

variable "attach_to_vpc" {
  description = "Attach the Lambda function to private subnets."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs used when the Lambda attaches to the VPC."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs used when the Lambda attaches to the VPC."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Manager ARNs the function can read."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Environment variables exposed to the function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to Lambda resources."
  type        = map(string)
  default     = {}
}
