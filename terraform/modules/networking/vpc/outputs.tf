###################################################################
# OUTPUTS - Valores de salida del módulo VPC
###################################################################

output "vpc_id" {
    description = "ID de la VPC creada"
    value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
    description = "Bloque CIDR de la VPC"
    value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
    description = "ID del Internet Gateway"
    value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
    description = "IDs de las subredes públicas"
    value       = var.create_nat_gateway ? aws_subnet.public[*].id : []
}

output "private_subnet_ids" {
    description = "IDs de las subredes privadas"
    value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
    description = "Bloques CIDR de las subredes públicas"
    value       = var.create_nat_gateway ? aws_subnet.public[*].cidr_block : []
}

output "private_subnet_cidrs" {
    description = "Bloques CIDR de las subredes privadas"
    value       = aws_subnet.private[*].cidr_block
}

output "nat_gateway_ids" {
    description = "IDs de los NAT Gateways"
    value       = var.create_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_gateway_public_ips" {
    description = "IPs públicas de los NAT Gateways"
    value       = var.create_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "public_route_table_id" {
    description = "ID de la tabla de rutas pública"
    value       = var.create_nat_gateway ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
    description = "IDs de las tablas de rutas privadas"
    value       = aws_route_table.private[*].id
}

output "availability_zones" {
    description = "Zonas de disponibilidad utilizadas"
    value       = var.availability_zones
}
