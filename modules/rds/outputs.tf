output "endpoint" {
  description = "Private PostgreSQL hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.this.port
}

output "master_secret_arn" {
  description = "Secrets Manager ARN created and managed by RDS."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "Security group attached to the DB instance."
  value       = aws_security_group.this.id
}
