resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  period = 60
  statistic = "Average"

  alarm_description = "CPU usage above 80% for ECS cluster"
  treat_missing_data = "missing"
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 80
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  period = 60
  statistic = "Average"

  alarm_description = "Memory usage above 80% for ECS cluster"
  treat_missing_data = "missing"
}
