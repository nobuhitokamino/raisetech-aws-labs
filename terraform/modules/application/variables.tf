variable "rds_secret_arn" {
  description = "ARN of the RDS master user secret"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public Subnet A ID for EC2"
  type        = string
}

variable "public_subnet_c_id" {
  description = "Public Subnet C ID for ALB"
  type        = string
}

variable "ec2_sg_id" {
  description = "Security Group ID for EC2"
  type        = string
}

variable "ec2_key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint address"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "application_log_group_name" {
  description = "CloudWatch Log Group for Spring Boot"
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the application"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the Target Group"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "ec2_permissions_boundary_arn" {
  description = "Permissions boundary ARN for the EC2 application role"
  type        = string
}
