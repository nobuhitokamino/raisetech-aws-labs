output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_a_id" {
  description = "ID of Public Subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_c_id" {
  description = "ID of Public Subnet C"
  value       = aws_subnet.public_c.id
}

output "private_subnet_a_id" {
  description = "ID of Private Subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_c_id" {
  description = "ID of Private Subnet C"
  value       = aws_subnet.private_c.id
}
