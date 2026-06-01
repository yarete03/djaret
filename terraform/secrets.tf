module "rds_master_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=v2.1.0"

  name        = "${var.project_name}-rds-master-${terraform.workspace}"
  description = "RDS master credentials for ${var.project_name}-rds-${terraform.workspace}"

  kms_key_id = data.aws_kms_alias.secretsmanager.target_key_arn
  secret_string = jsonencode(zipmap(
    ["username", "password"],
    ["root", random_password.rds_master.result],
  ))

  recovery_window_in_days = 7

  tags = var.tags
}
