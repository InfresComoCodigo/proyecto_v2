resource "aws_wafv2_web_acl" "main" {
  name        = "${var.env}-web-acl"
  scope       = "REGIONAL"
  description = "WAF for application"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}