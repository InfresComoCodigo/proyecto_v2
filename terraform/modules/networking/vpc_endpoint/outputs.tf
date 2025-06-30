# Outputs para VPC Endpoints

output "s3_endpoint_id" {
  description = "ID del VPC endpoint para S3"
  value       = aws_vpc_endpoint.s3.id
}

output "cloudwatch_logs_endpoint_id" {
  description = "ID del VPC endpoint para CloudWatch Logs"
  value       = aws_vpc_endpoint.cloudwatch_logs.id
}

output "cloudwatch_monitoring_endpoint_id" {
  description = "ID del VPC endpoint para CloudWatch Monitoring"
  value       = aws_vpc_endpoint.cloudwatch_monitoring.id
}

output "ec2_endpoint_id" {
  description = "ID del VPC endpoint para EC2"
  value       = aws_vpc_endpoint.ec2.id
}

output "endpoint_dns_entries" {
  description = "DNS entries para los VPC endpoints"
  value = {
    cloudwatch_logs       = aws_vpc_endpoint.cloudwatch_logs.dns_entry
    cloudwatch_monitoring = aws_vpc_endpoint.cloudwatch_monitoring.dns_entry
    ec2                   = aws_vpc_endpoint.ec2.dns_entry
  }
}
