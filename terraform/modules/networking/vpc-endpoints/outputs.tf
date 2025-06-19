output "endpoint_ids" {
  description = "List of created VPC endpoint IDs"
  value = [
    aws_vpc_endpoint.s3.id,
    aws_vpc_endpoint.logs.id,
  ]
}
