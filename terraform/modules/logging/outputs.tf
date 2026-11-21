output "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  value       = aws_s3_bucket.alb_logs.id
}

output "application_log_group_name" {
  description = "CloudWatch Log Group for Spring Boot"
  value       = aws_cloudwatch_log_group.application.name
}

output "waf_log_group_arn" {
  description = "CloudWatch Log Group ARN for WAF"
  value       = aws_cloudwatch_log_group.waf.arn
}

output "rds_error_log_group_name" {
  description = "CloudWatch Log Group for RDS error logs"
  value       = aws_cloudwatch_log_group.rds_error.name
}
