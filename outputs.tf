output "service_name" {
  value = aws_ecs_service.jnv_ecs_service.name
}
output "secret_arn" {
  value = aws_secretsmanager_secret.jnv_ecs_service_secrets.arn
}
output "codedeploy_app_name" {
  value = aws_codedeploy_app.codedeploy_app.name
}
output "codedeploy_deploymentgroup_name" {
  value = aws_codedeploy_deployment_group.codedeploy_deploymentgroup.deployment_group_name
}
