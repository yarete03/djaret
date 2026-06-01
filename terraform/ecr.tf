module "ecr" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecr.git?ref=v3.2.0"

  repository_name                 = "${var.project_name}-ecr-${terraform.workspace}/${var.project_name}"
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true
  repository_encryption_type      = "KMS"
  repository_kms_key              = data.aws_kms_alias.ecr.target_key_arn

  create_lifecycle_policy  = false
  attach_repository_policy = false

  tags = var.tags
}
