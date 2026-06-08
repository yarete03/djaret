resource "aws_rum_app_monitor" "cw_rum_app_monitor" {
  name           = "${var.project_name}-app-monitor-${terraform.workspace}"
  domain_list    = [var.domain_name]
  cw_log_enabled = true

  app_monitor_configuration {
    allow_cookies       = true
    enable_xray         = true
    session_sample_rate = 1
    telemetries         = ["errors", "performance", "http"]
    identity_pool_id    = aws_cognito_identity_pool.cognito_rum_identity_pool.id
    guest_role_arn      = module.rum_guest_role.arn
  }

  custom_events {
    status = "ENABLED"
  }

  tags = var.tags
}

resource "aws_xray_trace_segment_destination" "xray_trace_segment_destination" {
  destination = "CloudWatchLogs"
}

resource "aws_xray_indexing_rule" "xray_indexing_rule" {
  name = "Default"

  rule {
    probabilistic {
      desired_sampling_percentage = 100
    }
  }

  depends_on = [aws_xray_trace_segment_destination.xray_trace_segment_destination]
}

module "waf_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v5.7.2"

  providers = {
    aws = aws.us_east_1
  }

  name              = "aws-waf-logs-${var.project_name}-${terraform.workspace}"
  retention_in_days = 90
  tags              = var.tags
}

module "api_gateway_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v5.7.2"

  name              = "/aws/apigateway/${var.project_name}-${terraform.workspace}"
  retention_in_days = 90
  tags              = var.tags
}

module "cloudfront_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=v5.7.2"

  providers = {
    aws = aws.us_east_1
  }

  name              = "/aws/cloudfront/${var.project_name}-${terraform.workspace}"
  retention_in_days = 90
  tags              = var.tags
}
