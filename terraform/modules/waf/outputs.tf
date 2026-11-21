output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_metric_name" {
  description = "CloudWatch metric name for the Web ACL"
  value       = aws_wafv2_web_acl.main.visibility_config[0].metric_name
}
