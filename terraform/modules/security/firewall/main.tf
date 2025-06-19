resource "aws_fms_policy" "egress_policy" {
  name                  = "${var.env}-egress-policy"
  resource_type         = "AWS::EC2::SecurityGroup"
  exclude_resource_tags = false

  security_service_policy_data {
    type                = "WAF"
    managed_service_data = jsonencode({
      type          = "WAFV2"
      defaultAction = "ALLOW"
    })
  }

  resource_tags = var.tags
}
