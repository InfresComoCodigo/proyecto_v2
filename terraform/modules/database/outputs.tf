output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "rds_identifier" {
  value = aws_db_instance.this.id
}