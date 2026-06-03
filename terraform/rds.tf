module "rds" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v7.2.0"

  identifier = "${var.project_name}-rds-${terraform.workspace}"

  engine               = "mysql"
  engine_version       = "8.4.8"
  family               = "mysql8.4"
  major_engine_version = "8.4"
  instance_class       = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id            = data.aws_kms_alias.rds.target_key_arn

  iam_database_authentication_enabled = true

  manage_master_user_password   = true
  master_user_secret_kms_key_id = data.aws_kms_alias.secretsmanager.target_key_arn
  username                      = "root"
  port                          = 3306

  multi_az               = false
  availability_zone      = "${var.region}a"
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  create_db_subnet_group = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  create_db_parameter_group = true
  parameters = [
    {
      name         = "sql_mode"
      value        = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
      apply_method = "immediate"
    }
  ]

  create_db_option_group = false
  option_group_name      = "default:mysql-8-4"

  backup_retention_period = 7
  backup_window           = "03:08-03:38"
  maintenance_window      = "mon:00:18-mon:00:48"

  monitoring_interval    = 60
  create_monitoring_role = false
  monitoring_role_arn    = module.rds_monitoring_role.arn

  ca_cert_identifier           = "rds-ca-rsa2048-g1"
  performance_insights_enabled = false
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  deletion_protection          = false
  publicly_accessible          = false
  skip_final_snapshot          = true

  tags = var.tags
}
