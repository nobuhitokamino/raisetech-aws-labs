output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.network.igw_id
}

output "alb_logs_bucket_name" {
  description = "ALB access logs bucket name"
  value       = module.logging.alb_logs_bucket_name
}

output "application_log_group_name" {
  description = "Application Log Group name"
  value       = module.logging.application_log_group_name
}

output "waf_log_group_arn" {
  description = "WAF Log Group ARN"
  value       = module.logging.waf_log_group_arn
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = module.database.rds_endpoint
}

output "rds_instance_identifier" {
  description = "RDS instance identifier"
  value       = module.database.rds_instance_identifier
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.application.ec2_instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IPv4 address"
  value       = module.application.ec2_public_ip
}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = module.application.alb_dns_name
}

output "alb_arn" {
  description = "ARN of ALB"
  value       = module.application.alb_arn
}

output "alb_full_name" {
  description = "Full name of ALB"
  value       = module.application.alb_full_name
}

output "target_group_full_name" {
  description = "Full name of Target Group"
  value       = module.application.target_group_full_name
}

output "web_acl_arn" {
  description = "ARN of WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "alarm_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarms"
  value       = module.monitoring.alarm_topic_arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard name"
  value       = module.monitoring.dashboard_name
}
