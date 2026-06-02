resource "awscc_applicationsignals_service_level_objective" "backend_slo_availability" {
  name = "${var.project_name}-slo-availability-${terraform.workspace}"

  burn_rate_configurations = [
    { look_back_window_minutes = 360 },
    { look_back_window_minutes = 4320 },
    { look_back_window_minutes = 60 },
  ]

  goal = {
    attainment_goal   = 99.99
    warning_threshold = 80
    interval = {
      rolling_interval = {
        duration      = 28
        duration_unit = "DAY"
      }
    }
  }

  request_based_sli = {
    request_based_sli_metric = {
      key_attributes = {
        Environment = "lambda:default"
        Name        = "${var.project_name}-lambda-backend-${terraform.workspace}"
        Type        = "Service"
      }
      metric_type    = "AVAILABILITY"
      operation_name = "${var.project_name}-lambda-${terraform.workspace}/LambdaService"
    }
  }
}

resource "awscc_applicationsignals_service_level_objective" "backend_slo_latency" {
  name = "${var.project_name}-slo-latency-${terraform.workspace}"

  burn_rate_configurations = [
    { look_back_window_minutes = 360 },
    { look_back_window_minutes = 4320 },
    { look_back_window_minutes = 60 },
  ]

  goal = {
    attainment_goal   = 99.99
    warning_threshold = 80
    interval = {
      rolling_interval = {
        duration      = 28
        duration_unit = "DAY"
      }
    }
  }

  request_based_sli = {
    comparison_operator = "LessThanOrEqualTo"
    metric_threshold    = 2000
    request_based_sli_metric = {
      key_attributes = {
        Environment = "lambda:default"
        Name        = "${var.project_name}-lambda-backend-${terraform.workspace}"
        Type        = "Service"
      }
      metric_type    = "LATENCY"
      operation_name = "${var.project_name}-lambda-${terraform.workspace}/LambdaService"
    }
  }
}

resource "awscc_applicationsignals_service_level_objective" "apigw_slo_availability" {
  name = "${var.project_name}-slo-apigw-availability-${terraform.workspace}"

  burn_rate_configurations = [
    { look_back_window_minutes = 360 },
    { look_back_window_minutes = 4320 },
    { look_back_window_minutes = 60 },
  ]

  goal = {
    attainment_goal   = 99.99
    warning_threshold = 80
    interval = {
      rolling_interval = {
        duration      = 28
        duration_unit = "DAY"
      }
    }
  }

  request_based_sli = {
    request_based_sli_metric = {
      key_attributes = {
        Environment = "api-gateway:pro"
        Name        = "${var.project_name}-api-gateway-${terraform.workspace}"
        Type        = "Service"
      }
      metric_type    = "AVAILABILITY"
      operation_name = "ANY /{proxy+}"
    }
  }
}

resource "awscc_applicationsignals_service_level_objective" "apigw_slo_latency" {
  name = "${var.project_name}-slo-apigw-latency-${terraform.workspace}"

  burn_rate_configurations = [
    { look_back_window_minutes = 360 },
    { look_back_window_minutes = 4320 },
    { look_back_window_minutes = 60 },
  ]

  goal = {
    attainment_goal   = 99.99
    warning_threshold = 80
    interval = {
      rolling_interval = {
        duration      = 28
        duration_unit = "DAY"
      }
    }
  }

  request_based_sli = {
    comparison_operator = "LessThanOrEqualTo"
    metric_threshold    = 2000
    request_based_sli_metric = {
      key_attributes = {
        Environment = "api-gateway:pro"
        Name        = "${var.project_name}-api-gateway-${terraform.workspace}"
        Type        = "Service"
      }
      metric_type    = "LATENCY"
      operation_name = "ANY /{proxy+}"
    }
  }
}

resource "awscc_applicationsignals_service_level_objective" "slo_rum_performance" {
  name = "${var.project_name}-slo-rum-performance-${terraform.workspace}"

  goal = {
    attainment_goal   = 99
    warning_threshold = 80
    interval = {
      rolling_interval = {
        duration      = 1
        duration_unit = "DAY"
      }
    }
  }

  request_based_sli = {
    comparison_operator = "LessThanOrEqualTo"
    metric_threshold    = 3500
    request_based_sli_metric = {
      metric_name = "PerformanceNavigationDuration"
      metric_source = {
        metric_source_attributes = {
          AppMonitorPlatformType = "Web"
        }
        metric_source_key_attributes = {
          Identifier   = "${var.project_name}-app-monitor-${terraform.workspace}"
          ResourceType = "AWS::RUM::AppMonitor"
          Type         = "AWS::Resource"
        }
      }
    }
  }
}
