# EC2 Trust Policy
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role
resource "aws_iam_role" "app" {
  name                 = "raisetech-tf-app-role"
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  permissions_boundary = var.ec2_permissions_boundary_arn
}

# Attach AWS Managed Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Secrets Manager Read Policy
data "aws_iam_policy_document" "read_db_password" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.rds_secret_arn]
  }
}

# Attach Inline Policy to IAM Role
resource "aws_iam_role_policy" "read_db_password" {
  name   = "ReadDbPassword"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.read_db_password.json
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "app" {
  name = "raisetech-tf-app-instance-profile"
  role = aws_iam_role.app.name
}

# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# EC2 Instance
resource "aws_instance" "app" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  key_name = var.ec2_key_name

  subnet_id                   = var.public_subnet_a_id
  vpc_security_group_ids      = [var.ec2_sg_id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.app.name

  user_data = templatefile(
    "${path.module}/../../templates/user_data.sh.tftpl",
    {
      rds_endpoint               = var.rds_endpoint
      db_username                = var.db_username
      rds_secret_arn             = var.rds_secret_arn
      aws_region                 = var.aws_region
      application_log_group_name = var.application_log_group_name
    }
  )

  user_data_replace_on_change = true

  tags = {
    Name = "raisetech-tf-ec2"
  }

  depends_on = [
    aws_iam_role_policy.read_db_password,
    aws_iam_role_policy_attachment.cloudwatch_agent
  ]
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "raisetech-tf-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    var.public_subnet_a_id,
    var.public_subnet_c_id
  ]

  security_groups = [var.alb_sg_id]

  access_logs {
    bucket  = var.alb_logs_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "raisetech-tf-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "raisetech-tf-alb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }

  tags = {
    Name = "raisetech-tf-alb-tg"
  }
}

# Register EC2 to Target Group
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
