output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "EC2 public IPv4 address"
  value       = aws_instance.app.public_ip
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "alb_full_name" {
  description = "ALB full name for CloudWatch metrics"
  value       = aws_lb.app.arn_suffix
}

output "target_group_full_name" {
  description = "Target Group full name for CloudWatch metrics"
  value       = aws_lb_target_group.app.arn_suffix
}
