# ALB Access Logs Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket_prefix = "raisetech-tf-alb-logs-"
  force_destroy = true

  tags = {
    Name = "raisetech-tf-alb-logs"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "DeleteOldLogs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 14
    }
  }
}

# Current AWS Account
data "aws_caller_identity" "current" {}

# ALB Access Logs Bucket Policy
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowALBAccessLogs"
        Effect = "Allow"

        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }

        Action = "s3:PutObject"

        Resource = "${aws_s3_bucket.alb_logs.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

# Spring Boot Application Logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/raisetech/terraform/application"
  retention_in_days = 14
}

# WAF Logs
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-raisetech-tf"
  retention_in_days = 14
}

# RDS Error Logs
resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${var.rds_instance_identifier}/error"
  retention_in_days = 14
}
