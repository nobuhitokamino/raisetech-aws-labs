output "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  value       = aws_s3_bucket.alb_logs.id

  # Configure the log destination before enabling ALB access logs.
  depends_on = [
    aws_s3_bucket_policy.alb_logs,
    aws_s3_bucket_public_access_block.alb_logs,
    aws_s3_bucket_server_side_encryption_configuration.alb_logs
  ]
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

output "rds_instance_identifier" {
  description = "RDS instance identifier after the error log group is ready"
  value       = var.rds_instance_identifier

  # Create the error log group before enabling RDS log exports.
  depends_on = [
    aws_cloudwatch_log_group.rds_error
  ]
}
