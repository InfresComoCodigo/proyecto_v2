output "fms_policy_id" {
  description = "ID of the Firewall Manager policy"
  value       = aws_fms_policy.egress_policy.id
}
