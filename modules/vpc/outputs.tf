output "vpc_id" {
  description = "VPC ID for the bookstore stack."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].id]
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = [for az in var.availability_zones : aws_subnet.private_db[az].id]
}

output "vpc_endpoint_security_group_id" {
  description = "Security group shared by interface VPC endpoints."
  value       = aws_security_group.endpoints.id
}
