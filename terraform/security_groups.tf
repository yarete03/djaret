module "lambda_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.3.1"

  name            = "${var.project_name}-lambda-sg-${terraform.workspace}"
  description     = "Security group attached to Lambda function to allow them to securely connect to ${var.project_name}-rds-${terraform.workspace}. Modification could lead to connection loss."
  vpc_id          = module.vpc.vpc_id
  use_name_prefix = false

  egress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Rule to allow connections to RDS database from any Lambda function this security group is attached to."
      source_security_group_id = module.rds_sg.security_group_id
    }
  ]

  tags = var.tags
}

module "rds_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.3.1"

  name            = "${var.project_name}-rds-sg-${terraform.workspace}"
  description     = "Security group attached to ${var.project_name}-rds-${terraform.workspace} to allow Lambda function with specific security groups attached to connect to the RDS database. Modification could lead to connection loss."
  vpc_id          = module.vpc.vpc_id
  use_name_prefix = false

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Rule to allow connections from Lambda function with sg-095a4abed36a0a077 attached."
      source_security_group_id = module.lambda_sg.security_group_id
    }
  ]

  tags = var.tags
}
