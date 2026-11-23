
# AWSへの実接続なしでテストする
mock_provider "aws" {}

# テスト用の入力値
variables {
  vpc_id   = "vpc-0123456789abcdef0"
  vpc_cidr = "10.0.0.0/16"
  my_ip    = "203.0.113.10/32"
}

run "ssh_security" {
  command = plan

  # SSHの接続元が指定したIPに制限されているか
  assert {
    condition     = aws_vpc_security_group_ingress_rule.ec2_ssh.cidr_ipv4 == var.my_ip
    error_message = "SSH ingress must use the specified IP."
  }

  # SSHのプロトコルがTCPか
  assert {
    condition     = aws_vpc_security_group_ingress_rule.ec2_ssh.ip_protocol == "tcp"
    error_message = "SSH ingress must use TCP."
  }

  # SSHの許可ポートが22番だけか
  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.ec2_ssh.from_port == 22 &&
      aws_vpc_security_group_ingress_rule.ec2_ssh.to_port == 22
    )
    error_message = "SSH ingress must allow only port 22."
  }
}

run "rds_ingress" {
  command = apply

  # RDSの接続元をEC2のSecurity Groupに制限
  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.rds_mysql.referenced_security_group_id
      == aws_security_group.ec2.id
    )
    error_message = "RDS ingress must reference the EC2 Security Group."
  }

  # MySQLのポート3306のみ許可
  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.rds_mysql.from_port == 3306 &&
      aws_vpc_security_group_ingress_rule.rds_mysql.to_port == 3306
    )
    error_message = "RDS ingress must allow only port 3306."
  }
}
