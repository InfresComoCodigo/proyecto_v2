output "ec2_sg_id" {
  description = "ID del Security Group para instancias EC2"
  value       = aws_security_group.ec2_sg.id
}