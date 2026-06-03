module "acm" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=v6.3.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name       = var.domain_name
  key_algorithm     = "RSA_2048"
  validation_method = "DNS"

  create_route53_records = false
  validate_certificate   = false
  wait_for_validation    = false

  tags = var.tags
}
