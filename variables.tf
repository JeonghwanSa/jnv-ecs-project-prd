variable "application_name" {}
variable "jnv_project" {
  default = "szs"
}
variable "jnv_region" {
  default = "apne2"
}
variable "jnv_environment" {
  default = "stg"
}
variable "vpc_id" {
  default = "vpc-05fdeab3a96c4569c"
}
variable "subnet_ids" {
  default = ["subnet-0d5db094815b4fd2e", "subnet-034bc577f88f4f46d"]
}
variable "public_subnet_ids" {
}
variable "cluster_arn" {
  default = "arn:aws:ecs:ap-northeast-2:414779424500:cluster/szs-apne2-ecs-cluster-stg"
}
variable "need_loadbalancer" {
  type    = bool
  default = false
}
variable "internal_lb" {
  type    = bool
  default = false
}
variable "container_port" {
  default = 8080
}

variable "auto_rollback_enabled" {
  default     = true
  type        = string
  description = "Indicates whether a defined automatic rollback configuration is currently enabled for this Deployment Group."
}

variable "auto_rollback_events" {
  default     = ["DEPLOYMENT_FAILURE"]
  type        = list(string)
  description = "The event type or types that trigger a rollback."
}

variable "action_on_timeout" {
  default     = "CONTINUE_DEPLOYMENT"
  type        = string
  description = "When to reroute traffic from an original environment to a replacement environment in a blue/green deployment."
}

variable "wait_time_in_minutes" {
  default     = 0
  type        = string
  description = "The number of minutes to wait before the status of a blue/green deployment changed to Stopped if rerouting is not started manually."
}

variable "termination_wait_time_in_minutes" {
  default     = 60
  type        = string
  description = "The number of minutes to wait after a successful blue/green deployment before terminating instances from the original environment."
}

variable "management_sg" {
  type    = string
  default = "sg-0c3d145b7bddb3bb5"
}
