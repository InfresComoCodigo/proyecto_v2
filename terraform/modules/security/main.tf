resource "aws_security_group" "ec2_sg" {
  name        = "${var.env}-ec2-sg"
  description = "Security Group for EC2 instances"
  vpc_id      = var.vpc_id

  # Reglas de salida: permitir tráfico hacia el puerto 443 (Twilio, pasarela de pagos)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite a las instancias EC2 salir a cualquier IP en el puerto 443
  }

  tags = var.tags
}