
# AWSへ接続せずにProviderの動作を模擬する
mock_provider "aws" {}

# Database Moduleに渡すテスト用の入力値
variables {
  private_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ]
  rds_sg_id               = "sg-0123456789abcdef0"
  rds_instance_identifier = "raisetech-tf-rds"
  db_username             = "root"
}

# RDSのセキュリティ設定を検証する
run "rds_security" {
  command = plan

  # RDSが非公開になっていること
  assert {
    condition     = aws_db_instance.main.publicly_accessible == false
    error_message = "RDS must not be publicly accessible."
  }

  # RDSストレージが暗号化されていること
  assert {
    condition     = aws_db_instance.main.storage_encrypted == true
    error_message = "RDS storage encryption must be enabled."
  }
}
