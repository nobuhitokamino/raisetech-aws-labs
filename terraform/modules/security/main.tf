# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "raisetech-tf-alb-sg"
  description = "Security Group for ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "raisetech-tf-alb-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "raisetech-tf-ec2-sg"
  description = "Security Group for EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "raisetech-tf-ec2-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "raisetech-tf-rds-sg"
  description = "Security Group for RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "raisetech-tf-rds-sg"
  }
}

# ALB Ingress
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# EC2 Ingress
resource "aws_vpc_security_group_ingress_rule" "ec2_app" {
  security_group_id            = aws_security_group.ec2.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Ingress
resource "aws_vpc_security_group_ingress_rule" "rds_mysql" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.ec2.id
}

# ALB Egress
resource "aws_vpc_security_group_egress_rule" "alb_app" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.vpc_cidr
}

# EC2 Egress
resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS Egress
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
