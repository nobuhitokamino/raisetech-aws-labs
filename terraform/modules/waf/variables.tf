variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "waf_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for WAF"
  type        = string
}
