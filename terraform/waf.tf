module "waf" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=v2.1.0"

  providers = {
    aws = aws.us_east_1
  }

  name        = "${var.project_name}-waf-${terraform.workspace}"
  description = "waf"
  scope       = "CLOUDFRONT"

  default_action = "allow"

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-${terraform.workspace}"
    sampled_requests_enabled   = true
  }

  rules = {
    "AWS-AWSManagedRulesAntiDDoSRuleSet" = {
      priority        = 0
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesAntiDDoSRuleSet"
          managed_rule_group_configs = [
            {
              aws_managed_rules_anti_ddos_rule_set = {
                sensitivity_to_block = "LOW"
                client_side_action_config = {
                  challenge = {
                    usage_of_action = "ENABLED"
                    sensitivity     = "HIGH"
                    exempt_uri_regular_expression = [
                      { regex_string = "\\/api\\/|\\.(acc|avi|css|gif|ico|jpe?g|js|json|mp[34]|ogg|otf|pdf|png|tiff?|ttf|webm|webp|woff2?|xml)$" }
                    ]
                  }
                }
              }
            }
          ]
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-AWSManagedRulesAntiDDoSRuleSet"
        sampled_requests_enabled   = true
      }
    }

    "AWS-AWSManagedRulesAmazonIpReputationList" = {
      priority        = 1
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesAmazonIpReputationList"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
        sampled_requests_enabled   = true
      }
    }

    "AWS-AWSManagedRulesCommonRuleSet" = {
      priority        = 2
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesCommonRuleSet"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    }

    "AWS-AWSManagedRulesKnownBadInputsRuleSet" = {
      priority        = 3
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = var.tags
}