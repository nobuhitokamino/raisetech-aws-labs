output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.main.address
}

output "rds_secret_arn" {
  description = "ARN of the RDS master user secret"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "rds_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_allocated_storage_gib" {
  description = "Allocated RDS storage capacity in GiB"
  value       = aws_db_instance.main.allocated_storage
}
