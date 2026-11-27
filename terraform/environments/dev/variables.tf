variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip" {
  description = "Your public IPv4 address with /32"
  type        = string
  sensitive   = true

  validation {
    condition = (
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/32$", var.my_ip)) &&
      can(cidrhost(var.my_ip, 0))
    )
    error_message = "Enter a valid IPv4 address with /32."
  }
}

variable "rds_instance_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = "raisetech-tf-rds"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "root"
}

variable "ec2_key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "notification_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  sensitive   = true
}
