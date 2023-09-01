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