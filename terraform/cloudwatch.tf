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
}
