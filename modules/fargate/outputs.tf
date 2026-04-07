output "repository_url" {
  description = "ECR repository URL for the Spring Boot image."
  value       = aws_ecr_repository.this.repository_url
}

output "alb_listener_arn" {
  description = "Internal ALB listener ARN used by API Gateway private integration."
  value       = aws_lb_listener.this.arn
}

output "service_security_group_id" {
  description = "Security group attached to the ECS service."
  value       = aws_security_group.service.id
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}
