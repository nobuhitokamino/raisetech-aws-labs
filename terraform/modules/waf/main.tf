# Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "raisetech-tf-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "raisetech-tf-waf"
    sampled_requests_enabled   = true
  }

  # Custom Rule: Block Test Header
  rule {
    name     = "BlockTestHeader"
    priority = 0

    statement {
      byte_match_statement {
        search_string         = "block-me"
        positional_constraint = "EXACTLY"

        field_to_match {
          single_header {
            name = "x-raisetech-test"
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockTestHeader"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules
  rule {
    name     = "AWSCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "raisetech-tf-waf"
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn = aws_wafv2_web_acl.main.arn

  log_destination_configs = [
    var.waf_log_group_arn
  ]

  redacted_fields {
    query_string {}
  }

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}
