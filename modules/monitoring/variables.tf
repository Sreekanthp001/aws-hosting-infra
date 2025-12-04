variable "project" {
  type = string
}
variable "ecs_cluster_name" {
  type = string
}
variable "sns_alert_email" {
  type    = string
  default = ""
}
variable "alb_name" {
  type = string
} # load balancer name (not arn)
