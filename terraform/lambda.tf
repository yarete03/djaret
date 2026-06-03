resource "random_password" "django_secret" {
  length  = 64
  special = true
  # Avoid quotes/backslash so the value stays clean as a Lambda env var.
  override_special = "!@#%^&*()-_=+[]{}:?"
}

module "lambda" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=v8.8.0"

  function_name = "${var.project_name}-lambda-${terraform.workspace}"

  create_package = false
  package_type   = "Image"
  image_uri      = "${module.ecr.repository_url}:${var.image_tag}"

  architectures          = ["arm64"]
  memory_size            = 512
  timeout                = 30
  ephemeral_storage_size = 512
  tracing_mode           = "Active"

  image_config_command = ["lambda_handler.handler"]

  environment_variables = {
    DB_USER           = "${var.project_name}_db_user_${terraform.workspace}"
    DB_NAME           = "${var.project_name}_db_${terraform.workspace}"
    DB_HOST           = module.rds.db_instance_address
    DJANGO_SECRET_KEY = random_password.django_secret.result
    # CloudFront strips the Host header (all_viewer_except_host_header policy),
    # so the Host that reaches Django is the API Gateway origin, not the domain.
    DJANGO_ALLOWED_HOSTS = "${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com"
  }

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_sg.security_group_id]

  create_role = false
  lambda_role = module.lambda_role.arn

  tags = var.tags
}
