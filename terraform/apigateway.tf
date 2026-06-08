resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "${var.project_name}-api-gateway-${terraform.workspace}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = module.lambda.lambda_function_invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_MATCH"
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.proxy_lambda.id,
      aws_api_gateway_rest_api_policy.cloudfront_only.policy,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = module.api_gateway_cloudwatch_role.arn
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_iam_policy_document" "api_gateway_cloudfront_only" {
  statement {
    sid    = "AllowInvoke"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"]
  }

  statement {
    sid    = "DenyNonCloudFront"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.entries[*].cidr
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "cloudfront_only" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  policy      = data.aws_iam_policy_document.api_gateway_cloudfront_only.json
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  rest_api_id          = aws_api_gateway_rest_api.api_gateway.id
  deployment_id        = aws_api_gateway_deployment.api_gateway_deployment.id
  stage_name           = terraform.workspace
  xray_tracing_enabled = true

  depends_on = [aws_api_gateway_account.api_gateway_account]

  access_log_settings {
    destination_arn = module.api_gateway_log_group.cloudwatch_log_group_arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.tags
}

resource "aws_lambda_permission" "apigw_lambda_permissions" {
  statement_id  = "187bacc9-bcf0-5aa2-bae7-7e1d12b63d85"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*/*"
}
