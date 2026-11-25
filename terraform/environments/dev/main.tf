data "aws_caller_identity" "current" {}

module "network" {
  source = "../../modules/network"

  vpc_cidr = var.vpc_cidr
}

module "security" {
  source = "../../modules/security"

  vpc_id   = module.network.vpc_id
  vpc_cidr = var.vpc_cidr
  my_ip    = var.my_ip
}

module "logging" {
  source = "../../modules/logging"

  rds_instance_identifier = var.rds_instance_identifier
}

module "database" {
  source = "../../modules/database"

  private_subnet_ids = [
    module.network.private_subnet_a_id,
    module.network.private_subnet_c_id
  ]

  rds_sg_id               = module.security.rds_sg_id
  rds_instance_identifier = var.rds_instance_identifier
  db_username             = var.db_username

  depends_on = [module.logging]
}

module "application" {
  source = "../../modules/application"

  public_subnet_a_id = module.network.public_subnet_a_id
  ec2_sg_id          = module.security.ec2_sg_id
  ec2_key_name       = var.ec2_key_name

  rds_endpoint   = module.database.rds_endpoint
  rds_secret_arn = module.database.rds_secret_arn
  db_username    = var.db_username

  application_log_group_name = module.logging.application_log_group_name
  aws_region                 = var.aws_region

  depends_on = [module.logging]

  vpc_id                       = module.network.vpc_id
  public_subnet_c_id           = module.network.public_subnet_c_id
  alb_sg_id                    = module.security.alb_sg_id
  alb_logs_bucket_name         = module.logging.alb_logs_bucket_name
  ec2_permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/RaiseTechEC2PermissionsBoundary"
}

module "waf" {
  source = "../../modules/waf"

  alb_arn           = module.application.alb_arn
  waf_log_group_arn = module.logging.waf_log_group_arn
}

module "monitoring" {
  source = "../../modules/monitoring"

  notification_email = var.notification_email

  alb_full_name          = module.application.alb_full_name
  target_group_full_name = module.application.target_group_full_name
  ec2_instance_id        = module.application.ec2_instance_id

  rds_instance_identifier   = module.database.rds_instance_identifier
  rds_allocated_storage_gib = module.database.rds_allocated_storage_gib

  waf_metric_name = module.waf.waf_metric_name
  aws_region      = var.aws_region
}
