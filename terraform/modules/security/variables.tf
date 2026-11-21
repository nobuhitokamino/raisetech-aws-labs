variable "vpc_id" {
  description = "VPC ID for Security Groups"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "my_ip" {
  description = "IPv4 CIDR allowed for SSH access"
  type        = string
}
