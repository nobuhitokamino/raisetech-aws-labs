output "alarm_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alarm.arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
