data "aws_iam_policy" "ecr_power_user" {
  name = "AmazonEC2ContainerRegistryPowerUser"
}

data "aws_iam_policy" "lambda_appsignals" {
  name = "CloudWatchLambdaApplicationSignalsExecutionRolePolicy"
}

data "aws_iam_policy" "rds_enhanced_monitoring" {
  name = "AmazonRDSEnhancedMonitoringRole"
}

module "github_oidc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-oidc-provider?ref=v6.6.1"

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = var.tags
}

module "github_actions_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=v6.6.1"

  name                 = "${var.project_name}-github-actions-role-${terraform.workspace}"
  use_name_prefix      = false
  path                 = "/"
  max_session_duration = 3600

  source_trust_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = { Federated = module.github_oidc.arn }
          Action    = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringLike = {
              "token.actions.githubusercontent.com:sub" = "repo:yarete03/${var.project_name}:*"
            }
          }
        }
      ]
    })
  ]

  policies = {
    ecr = data.aws_iam_policy.ecr_power_user.arn
  }

  create_inline_policy = true
  inline_policy_permissions = {
    cloudfront = {
      actions   = ["cloudfront:CreateInvalidation"]
      resources = [module.cloudfront.cloudfront_distribution_arn]
    }
    lambda = {
      actions   = ["lambda:UpdateFunctionCode", "lambda:GetFunction"]
      resources = [module.lambda.lambda_function_arn_static]
    }
    s3 = {
      actions = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
      resources = [
        module.s3.s3_bucket_arn,
        "${module.s3.s3_bucket_arn}/*",
      ]
    }
  }

  tags = var.tags
}

module "lambda_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=v6.6.1"

  name            = "${var.project_name}-lambda-role-${terraform.workspace}"
  use_name_prefix = false
  path            = "/service-role/"

  source_trust_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = { Service = "lambda.amazonaws.com" }
          Action    = "sts:AssumeRole"
        }
      ]
    })
  ]

  policies = {
    basic      = module.iam_policy_lambda_basic.arn
    appsignals = data.aws_iam_policy.lambda_appsignals.arn
  }

  tags = var.tags
}

module "iam_policy_lambda_basic" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=v6.6.1"

  name = "${var.project_name}-lambda-execution-role-${terraform.workspace}"
  path = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:AssignPrivateIpAddresses",
        ]
        Resource = "*"
      },
      {
        Sid      = "RDSIAMConnect"
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${var.region}:${var.account_id}:dbuser:${module.rds.db_instance_resource_id}/${var.project_name}_db_user_${terraform.workspace}"
      },
      {
        Sid      = "LogsCreateGroup"
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:*"
      },
      {
        Sid      = "LogsWrite"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${module.lambda.lambda_cloudwatch_log_group_arn}:*"
      },
    ]
  })
}

module "rum_guest_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=v6.6.1"

  name            = "${var.project_name}-rum-identity-pool-role-${terraform.workspace}"
  use_name_prefix = false
  path            = "/service-role/"

  source_trust_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = { Federated = "cognito-identity.amazonaws.com" }
          Action    = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.cognito_rum_identity_pool.id
            }
            "ForAnyValue:StringLike" = {
              "cognito-identity.amazonaws.com:amr" = "unauthenticated"
            }
          }
        }
      ]
    })
  ]

  policies = {
    cognito = module.iam_policy_cognito_unauth.arn
  }

  tags = var.tags
}

module "iam_policy_cognito_unauth" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=v6.6.1"

  name = "${var.project_name}-cognito-unauth-policy-${terraform.workspace}"
  path = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cognito-identity:GetCredentialsForIdentity"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = "rum:PutRumEvents"
        Resource = "arn:aws:rum:${var.region}:${var.account_id}:appmonitor/${var.project_name}-app-monitor-${terraform.workspace}"
      }
    ]
  })
}

module "rds_monitoring_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=v6.6.1"

  name            = "${var.project_name}-rds-monitoring-role-${terraform.workspace}"
  use_name_prefix = false
  path            = "/"

  source_trust_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = { Service = "monitoring.rds.amazonaws.com" }
          Action    = "sts:AssumeRole"
        }
      ]
    })
  ]

  policies = {
    monitoring = data.aws_iam_policy.rds_enhanced_monitoring.arn
  }

  tags = var.tags
}
