variable "notification_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
  sensitive   = true
}

variable "alb_full_name" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "target_group_full_name" {
  description = "Target Group ARN suffix for CloudWatch metrics"
  type        = string
}

variable "ec2_instance_id" {
  description = "EC2 instance ID"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "rds_allocated_storage_gib" {
  description = "Allocated RDS storage capacity in GiB"
  type        = number

  validation {
    condition     = var.rds_allocated_storage_gib >= 1
    error_message = "RDS allocated storage must be at least 1 GiB."
  }
}

variable "aws_region" {
  description = "AWS region used for CloudWatch metrics"
  type        = string
}

variable "waf_metric_name" {
  description = "Web ACL metric name for CloudWatch"
  type        = string
}
