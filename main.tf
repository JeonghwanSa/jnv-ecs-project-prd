data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_codedeploy_app" "codedeploy_app" {
  compute_platform = "ECS"
  name             = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-svc", "${var.jnv_environment}"])
}

resource "aws_codedeploy_deployment_group" "codedeploy_deploymentgroup" {
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name  = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-svc", "${var.jnv_environment}"])
  service_role_arn       = "arn:aws:iam::${local.account_id}:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  auto_rollback_configuration {
    enabled = var.auto_rollback_enabled
    events  = var.auto_rollback_events
  }

  blue_green_deployment_config {
    deployment_ready_option {
      # Information about when to reroute traffic from an original environment to a replacement environment in a blue/green deployment.
      #
      # - CONTINUE_DEPLOYMENT: Register new instances with the load balancer immediately after the new application
      #                        revision is installed on the instances in the replacement environment.
      # - STOP_DEPLOYMENT: Do not register new instances with a load balancer unless traffic rerouting is started
      #                    using ContinueDeployment. If traffic rerouting is not started before the end of the specified
      #                    wait period, the deployment status is changed to Stopped.
      action_on_timeout = var.action_on_timeout

      # The number of minutes to wait before the status of a blue/green deployment is changed to Stopped
      # if rerouting is not started manually. Applies only to the STOP_DEPLOYMENT option for action_on_timeout.
      # Can not be set to STOP_DEPLOYMENT when timeout is set to 0 minutes.
      wait_time_in_minutes = var.wait_time_in_minutes
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
    }
  }

  # For ECS deployment, the deployment type must be BLUE_GREEN, and deployment option must be WITH_TRAFFIC_CONTROL.
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Configuration block(s) of the ECS services for a deployment group.
  ecs_service {
    cluster_name = split("/", var.cluster_arn)[1]
    service_name = aws_ecs_service.jnv_ecs_service.name
  }

  # You can configure the Load Balancer to use in a deployment.
  load_balancer_info {
    # Information about two target groups and how traffic routes during an Amazon ECS deployment.
    # An optional test traffic route can be specified.
    # https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_TargetGroupPairInfo.html
    target_group_pair_info {
      # The path used by a load balancer to route production traffic when an Amazon ECS deployment is complete.
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.jnv_ecs_service_alb_prod_listener[0].arn
        ]
      }

      # One pair of target groups. One is associated with the original task set.
      # The second target is associated with the task set that serves traffic after the deployment completes.
      target_group {
        name = aws_lb_target_group.jnv_ecs_service_alb_blue_tg[0].name
      }

      target_group {
        name = aws_lb_target_group.jnv_ecs_service_alb_green_tg[0].name
      }

      # An optional path used by a load balancer to route test traffic after an Amazon ECS deployment.
      # Validation can happen while test traffic is served during a deployment.
      test_traffic_route {
        listener_arns = [
          aws_lb_listener.jnv_ecs_service_alb_test_listener[0].arn
        ]
      }
    }
  }

  lifecycle {
    ignore_changes = [
      load_balancer_info
    ]
  }
}

resource "aws_secretsmanager_secret" "jnv_ecs_service_secrets" {
  name = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "seckey", "${var.jnv_environment}"])
}

resource "aws_security_group" "jnv_ecs_service_alb_sg" {
  count = var.need_loadbalancer ? 1 : 0

  name        = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-alb-sg", "${var.jnv_environment}"])
  description = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-alb-sg", "${var.jnv_environment}"])
  vpc_id      = var.vpc_id

  # dynamic "ingress" {
  #   for_each = var.need_loadbalancer == true ? [1] : []
  #   content {
  #     description = "services"
  #     from_port   = 443
  #     to_port     = 443
  #     protocol    = "tcp"
  #     security_groups = [
  #       "sg-065f2646decd01027"
  #     ]
  #   }
  # }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-alb-sg", "${var.jnv_environment}"])
  }
}

resource "aws_lb" "jnv_ecs_service_alb" {
  count = var.need_loadbalancer ? 1 : 0

  name               = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "alb", "${var.jnv_environment}"])
  internal           = var.internal_lb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jnv_ecs_service_alb_sg[0].id]
  subnets            = var.internal_lb == true ? var.subnet_ids : var.public_subnet_ids

  enable_deletion_protection = true
}

resource "aws_lb_listener" "jnv_ecs_service_alb_prod_listener" {
  count = var.need_loadbalancer ? 1 : 0

  alpn_policy       = null
  certificate_arn   = var.alb_certificate_arn
  load_balancer_arn = aws_lb.jnv_ecs_service_alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  tags              = {}
  tags_all          = {}
  default_action {
    target_group_arn = aws_lb_target_group.jnv_ecs_service_alb_blue_tg[0].arn
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [
      default_action
    ]
  }
}

resource "aws_lb_listener" "jnv_ecs_service_alb_test_listener" {
  count = var.need_loadbalancer ? 1 : 0

  alpn_policy       = null
  certificate_arn   = null
  load_balancer_arn = aws_lb.jnv_ecs_service_alb[0].arn
  port              = 8080
  protocol          = "HTTP"
  ssl_policy        = null
  tags              = {}
  tags_all          = {}
  default_action {
    target_group_arn = aws_lb_target_group.jnv_ecs_service_alb_green_tg[0].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "jnv_ecs_service_alb_blue_tg" {
  count = var.need_loadbalancer ? 1 : 0

  connection_termination             = null
  deregistration_delay               = "300"
  ip_address_type                    = "ipv4"
  lambda_multi_value_headers_enabled = null
  load_balancing_algorithm_type      = "round_robin"
  load_balancing_cross_zone_enabled  = "use_load_balancer_configuration"
  name                               = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "blue-tg", "${var.jnv_environment}"])
  name_prefix                        = null
  port                               = 80
  preserve_client_ip                 = null
  protocol                           = "HTTP"
  protocol_version                   = "HTTP1"
  proxy_protocol_v2                  = null
  slow_start                         = 0
  tags                               = {}
  tags_all                           = {}
  target_type                        = "ip"
  vpc_id                             = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_lb_target_group" "jnv_ecs_service_alb_green_tg" {
  count = var.need_loadbalancer ? 1 : 0

  connection_termination             = null
  deregistration_delay               = "300"
  ip_address_type                    = "ipv4"
  lambda_multi_value_headers_enabled = null
  load_balancing_algorithm_type      = "round_robin"
  load_balancing_cross_zone_enabled  = "use_load_balancer_configuration"
  name                               = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "green-tg", "${var.jnv_environment}"])
  name_prefix                        = null
  port                               = 80
  preserve_client_ip                 = null
  protocol                           = "HTTP"
  protocol_version                   = "HTTP1"
  proxy_protocol_v2                  = null
  slow_start                         = 0
  tags                               = {}
  tags_all                           = {}
  target_type                        = "ip"
  vpc_id                             = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}


resource "aws_ecr_repository" "jnv_ecs_service_ecr_repo" {
  force_delete         = null
  image_tag_mutability = "MUTABLE"
  name                 = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecr", "${var.jnv_environment}"])
  tags                 = {}
  tags_all             = {}
  encryption_configuration {
    encryption_type = "AES256"
    kms_key         = null
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_task_definition" "jnv_ecs_service_taskdef" {
  family = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-task", "${var.jnv_environment}"])
  container_definitions = jsonencode([
    {
      command     = []
      cpu         = 0
      entryPoint  = []
      environment = []
      essential   = true
      image       = join(":", ["${aws_ecr_repository.jnv_ecs_service_ecr_repo.repository_url}", "init"])
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = join("-", ["/ecs/${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-task", "${var.jnv_environment}"])
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "ecs"
        }
      }
      mountPoints = []
      name        = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "container", "${var.jnv_environment}"])
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "ENC_KEY"
          valueFrom = aws_secretsmanager_secret.jnv_ecs_service_secrets.arn
        }
      ]
      volumesFrom = []
    }
  ])
  cpu                      = "1024"
  execution_role_arn       = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  ipc_mode                 = null
  memory                   = "3072"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = null
  tags = {
    Application = var.application_name
    Environment = var.jnv_environment
    Owner       = "jnv"
    Project     = var.application_name
    Service     = "szs"
    Team        = var.application_name
    User        = "szs"
  }
  task_role_arn = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_security_group" "jnv_ecs_service_sg" {
  name        = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-sg", "${var.jnv_environment}"])
  description = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-sg", "${var.jnv_environment}"])
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.need_loadbalancer == true ? [1] : []
    content {
      description = "from alb"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      security_groups = [
        aws_security_group.jnv_ecs_service_alb_sg[0].id
      ]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-sg", "${var.jnv_environment}"])
  }
}

resource "aws_ecs_service" "jnv_ecs_service" {
  cluster                            = var.cluster_arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 0
  enable_ecs_managed_tags            = false
  enable_execute_command             = false
  force_new_deployment               = null
  health_check_grace_period_seconds  = 0
  # iam_role                           = "/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  launch_type           = "FARGATE"
  name                  = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "ecs-svc", "${var.jnv_environment}"])
  platform_version      = "LATEST"
  propagate_tags        = "NONE"
  scheduling_strategy   = "REPLICA"
  tags                  = {}
  tags_all              = {}
  task_definition       = aws_ecs_task_definition.jnv_ecs_service_taskdef.arn_without_revision
  triggers              = {}
  wait_for_steady_state = null
  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  dynamic "load_balancer" {
    for_each = var.need_loadbalancer == true ? [1] : []
    content {
      container_name   = join("-", ["${var.jnv_project}", "${var.jnv_region}", lower("${var.application_name}"), "container", "${var.jnv_environment}"])
      container_port   = var.container_port
      elb_name         = null
      target_group_arn = aws_lb_target_group.jnv_ecs_service_alb_blue_tg[0].arn
    }
  }
  network_configuration {
    assign_public_ip = false
    security_groups = [
      var.management_sg,
      aws_security_group.jnv_ecs_service_sg.id
    ]
    subnets = var.subnet_ids
  }

  lifecycle {
    ignore_changes = [
      platform_version,
      task_definition,
      deployment_circuit_breaker,
      desired_count,
      load_balancer
    ]
  }
}
