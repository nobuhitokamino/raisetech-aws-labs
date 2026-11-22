variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB Subnet Group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}
