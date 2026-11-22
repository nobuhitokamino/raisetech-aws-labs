terraform {
  backend "s3" {
    bucket       = "aws-multi-az-portfolio-state-135808944987-apne1"
    key          = "raisetech-aws-labs/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
