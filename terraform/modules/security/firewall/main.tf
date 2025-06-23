resource "aws_fms_policy" "example" {
  name                  = "FMS-Policy-Example"
  exclude_resource_tags = false
  remediation_enabled   = false
  resource_type         = "AWS::ElasticLoadBalancingV2::LoadBalancer"

  security_service_policy_data {
    type = "WAFV2"

    managed_service_data = jsonencode({
      type = "WAFV2"
      defaultAction = { type = "ALLOW" }

      # 👉 Aquí SI hay una regla
      preProcessRuleGroups = [
        {
          ruleGroupType  = "ManagedRuleGroup"
          priority       = 1                     # 1-99
          overrideAction = { type = "NONE" }
          managedRuleGroupIdentifier = {
            vendorName           = "AWS"
            managedRuleGroupName = "AWSManagedRulesCommonRuleSet"
            # versionEnabled     = true           # opcional
            # version            = "Version_2.0"  # opcional
          }
          ruleGroupArn = null                    # debe ser null cuando usas managedRuleGroupIdentifier
        }
      ]

      postProcessRuleGroups = []                 # puede quedar vacío
      overrideCustomerWebACLAssociation = false
    })
  }


  tags = {
    Name = "example-fms-policy"
  }
}

resource "aws_wafregional_rule_group" "example" {
  metric_name = "WAFRuleGroupExample"
  name        = "WAF-Rule-Group-Example"
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}