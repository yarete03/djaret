data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "user_agent_referer_headers" {
  name = "Managed-UserAgentRefererHeaders"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_response_headers_policy" "simple_cors" {
  name = "Managed-SimpleCORS"
}

data "aws_cloudfront_response_headers_policy" "cors_and_security_headers" {
  name = "Managed-CORS-and-SecurityHeadersPolicy"
}

locals {
  oac_name = "oac-${var.project_name}-s3-${terraform.workspace}.s3.${var.region}.amazonaws.com-mpncqcrdj5d"
}


module "cloudfront" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudfront.git?ref=v6.7.0"

  aliases             = [var.domain_name]
  comment             = ""
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  web_acl_id          = module.waf.web_acl_arn

  origin_access_control = {
    (local.oac_name) = {
      description      = "${var.project_name} origin access control policy to allow CloudFront access S3 on ${terraform.workspace}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3 = {
      domain_name                 = module.s3.s3_bucket_bucket_regional_domain_name
      origin_id                   = module.s3.s3_bucket_id
      origin_access_control_key   = local.oac_name
      response_completion_timeout = 0

      origin_shield = {
        enabled              = true
        origin_shield_region = var.region
      }
    }

    api = {
      domain_name = "${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com"
      origin_id   = aws_api_gateway_rest_api.api_gateway.id
      origin_path = "/${terraform.workspace}"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_read_timeout      = 30
        origin_keepalive_timeout = 5
      }
    }
  }

  default_cache_behavior = {
    target_origin_id           = module.s3.s3_bucket_id
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    use_forwarded_values       = false
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.user_agent_referer_headers.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors.id
  }

  ordered_cache_behavior = [
    {
      path_pattern               = "/static/*"
      target_origin_id           = module.s3.s3_bucket_id
      viewer_protocol_policy     = "redirect-to-https"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      use_forwarded_values       = false
      cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.user_agent_referer_headers.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors_and_security_headers.id
    },
    {
      path_pattern               = "/api/*"
      target_origin_id           = aws_api_gateway_rest_api.api_gateway.id
      viewer_protocol_policy     = "redirect-to-https"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      use_forwarded_values       = false
      cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors.id
    },
    {
      path_pattern               = "/admin/*"
      target_origin_id           = aws_api_gateway_rest_api.api_gateway.id
      viewer_protocol_policy     = "redirect-to-https"
      allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods             = ["GET", "HEAD"]
      compress                   = true
      use_forwarded_values       = false
      cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors.id
    },
  ]

  restrictions = {
    geo_restriction = {
      restriction_type = "none"
    }
  }

  viewer_certificate = {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-cloudfront-${terraform.workspace}"
  })
}



