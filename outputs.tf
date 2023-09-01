output "service_name" {
  value = aws_ecs_service.jnv_ecs_service.name
}
output "secret_arn" {
  value = aws_secretsmanager_secret.jnv_ecs_service_secrets.arn
}
