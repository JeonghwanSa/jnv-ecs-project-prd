# JNV_ECS_PROJECT_PRD

## description
* STG, PROD 환경 ECS 서비스를 구성하는 모듈

## example
```
module "jnv_ecs_project_prd" {
  source            = "git::https://github.com/JeonghwanSa/jnv-ecs-project-prd.git"
  application_name  = "jobis-example"
  need_loadbalancer = false
}
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codedeploy_app.codedeploy_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.codedeploy_deploymentgroup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_ecr_repository.jnv_ecs_service_ecr_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_service.jnv_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.jnv_ecs_service_taskdef](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_lb.jnv_ecs_service_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.jnv_ecs_service_alb_prod_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.jnv_ecs_service_alb_test_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.jnv_ecs_service_alb_blue_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.jnv_ecs_service_alb_green_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_secretsmanager_secret.jnv_ecs_service_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_security_group.jnv_ecs_service_alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.jnv_ecs_service_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action_on_timeout"></a> [action\_on\_timeout](#input\_action\_on\_timeout) | When to reroute traffic from an original environment to a replacement environment in a blue/green deployment. | `string` | `"CONTINUE_DEPLOYMENT"` | no |
| <a name="input_alb_certificate_arn"></a> [alb\_certificate\_arn](#input\_alb\_certificate\_arn) | n/a | `string` | `"arn:aws:acm:ap-northeast-2:414779424500:certificate/ec2d17d6-ccc5-4b0a-8727-c2382943ec1c"` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | n/a | `any` | n/a | yes |
| <a name="input_auto_rollback_enabled"></a> [auto\_rollback\_enabled](#input\_auto\_rollback\_enabled) | Indicates whether a defined automatic rollback configuration is currently enabled for this Deployment Group. | `string` | `true` | no |
| <a name="input_auto_rollback_events"></a> [auto\_rollback\_events](#input\_auto\_rollback\_events) | The event type or types that trigger a rollback. | `list(string)` | <pre>[<br>  "DEPLOYMENT_FAILURE"<br>]</pre> | no |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | n/a | `string` | `"arn:aws:ecs:ap-northeast-2:414779424500:cluster/szs-apne2-ecs-cluster-stg"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | n/a | `number` | `8080` | no |
| <a name="input_internal_lb"></a> [internal\_lb](#input\_internal\_lb) | n/a | `bool` | `false` | no |
| <a name="input_jnv_environment"></a> [jnv\_environment](#input\_jnv\_environment) | n/a | `string` | `"stg"` | no |
| <a name="input_jnv_project"></a> [jnv\_project](#input\_jnv\_project) | n/a | `string` | `"szs"` | no |
| <a name="input_jnv_region"></a> [jnv\_region](#input\_jnv\_region) | n/a | `string` | `"apne2"` | no |
| <a name="input_management_sg"></a> [management\_sg](#input\_management\_sg) | n/a | `string` | `"sg-0c3d145b7bddb3bb5"` | no |
| <a name="input_need_loadbalancer"></a> [need\_loadbalancer](#input\_need\_loadbalancer) | n/a | `bool` | `false` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | n/a | `any` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list` | <pre>[<br>  "subnet-0d5db094815b4fd2e",<br>  "subnet-034bc577f88f4f46d"<br>]</pre> | no |
| <a name="input_termination_wait_time_in_minutes"></a> [termination\_wait\_time\_in\_minutes](#input\_termination\_wait\_time\_in\_minutes) | The number of minutes to wait after a successful blue/green deployment before terminating instances from the original environment. | `string` | `60` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `"vpc-05fdeab3a96c4569c"` | no |
| <a name="input_wait_time_in_minutes"></a> [wait\_time\_in\_minutes](#input\_wait\_time\_in\_minutes) | The number of minutes to wait before the status of a blue/green deployment changed to Stopped if rerouting is not started manually. | `string` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_alb_zoneid"></a> [alb\_zoneid](#output\_alb\_zoneid) | n/a |
| <a name="output_codedeploy_app_name"></a> [codedeploy\_app\_name](#output\_codedeploy\_app\_name) | n/a |
| <a name="output_codedeploy_deploymentgroup_name"></a> [codedeploy\_deploymentgroup\_name](#output\_codedeploy\_deploymentgroup\_name) | n/a |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | n/a |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | n/a |