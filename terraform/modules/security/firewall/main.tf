resource "aws_fms_policy" "egress_policy" {
  name                  = "${var.env}-egress-policy"
  resource_type         = "AWS::ElasticLoadBalancingV2::LoadBalancer"
  exclude_resource_tags = false

  security_service_policy_data {
    type = "WAFV2"

    managed_service_data = jsonencode({
      type = "WAFV2"
      defaultAction = {
        type = "ALLOW"
      }

      preProcessRuleGroups = [
        {
          ruleGroupArn   = "arn:aws:wafv2:us-east-1:901539331960:regional/rulegroup/test_pre_rulegroup/86bd9b59-2503-4afe-8040-1e26fd43c880"
          overrideAction = {
            type = "NONE"
          }
          ruleGroupType = "RuleGroup"
          priority      = 1
        }
      ]

      postProcessRuleGroups = [
        {
          ruleGroupArn   = "arn:aws:wafv2:us-east-1:901539331960:regional/rulegroup/test_post_rulegroup/ba63bafc-8298-459c-8c21-a46e5a1d9764"
          overrideAction = {
            type = "NONE"
          }
          ruleGroupType = "RuleGroup"
          priority      = 2
        }
      ]

      overrideAction = {
        type = "NONE"
      }

      loggingConfiguration = {
        logDestinationConfigs = [
          "arn:aws:s3:::aws-waf-logs-fms"
        ]
      }
    })
  }

  resource_tags = var.tags
}
