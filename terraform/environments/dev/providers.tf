provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "raisetech-aws-labs"
      ManagedBy = "Terraform"
    }
  }
}
