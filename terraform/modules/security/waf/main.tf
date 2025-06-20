resource "aws_wafv2_web_acl" "web_acl" {
  name  = "${var.env}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf"
    sampled_requests_enabled   = true
  }
}
