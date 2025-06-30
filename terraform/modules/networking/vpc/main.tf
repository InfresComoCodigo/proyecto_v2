###################################################################
# LOCALS - Configuración centralizada
###################################################################
locals {
    # Tags comunes
    common_tags = merge(var.tags, {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "terraform"
    })
}

###################################################################
# DATA SOURCES - Obtener AZs disponibles dinámicamente
###################################################################
data "aws_availability_zones" "available" {
    state = "available"
}

###################################################################
# VPC
###################################################################
resource "aws_vpc" "main" {
    cidr_block           = var.vpc_cidr
    enable_dns_support   = var.enable_dns_support
    enable_dns_hostnames = var.enable_dns_hostnames

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-vpc"
    })
}

###################################################################
# INTERNET GATEWAY
###################################################################
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-igw"
    })
}

###################################################################
# SUBREDES PÚBLICAS
###################################################################
resource "aws_subnet" "public" {
    count = var.create_nat_gateway ? length(var.public_subnet_cidrs) : 0

    vpc_id                  = aws_vpc.main.id
    cidr_block              = var.public_subnet_cidrs[count.index]
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = var.map_public_ip_on_launch

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-public-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
        Type = "Public"
    })
}

###################################################################
# SUBREDES PRIVADAS
###################################################################
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)

    vpc_id            = aws_vpc.main.id
    cidr_block        = var.private_subnet_cidrs[count.index]
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-private-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}"
        Type = "Private"
    })
}

###################################################################
# ELASTIC IPs PARA NAT GATEWAYS
###################################################################
resource "aws_eip" "nat" {
    count = var.create_nat_gateway ? length(aws_subnet.public) : 0

    domain = "vpc"

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-nat-eip-${count.index + 1}"
    })

    depends_on = [aws_internet_gateway.main]
}

###################################################################
# NAT GATEWAYS
###################################################################
resource "aws_nat_gateway" "main" {
    count = var.create_nat_gateway ? length(aws_subnet.public) : 0

    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-nat-gateway-${count.index + 1}"
    })

    depends_on = [aws_internet_gateway.main]
}

###################################################################
# ROUTE TABLE PÚBLICA
###################################################################
resource "aws_route_table" "public" {
    count = var.create_nat_gateway ? 1 : 0

    vpc_id = aws_vpc.main.id

    route {
    cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-public-rt"
        Type = "Public"
    })
}

###################################################################
# ROUTE TABLES PRIVADAS
###################################################################
resource "aws_route_table" "private" {
    count = var.create_nat_gateway ? length(aws_subnet.private) : 1

    vpc_id = aws_vpc.main.id

    dynamic "route" {
        for_each = var.create_nat_gateway ? [1] : []
        content {
            cidr_block     = "0.0.0.0/0"
            nat_gateway_id = aws_nat_gateway.main[count.index].id
        }
    }

    tags = merge(local.common_tags, {
        Name = var.create_nat_gateway ? "${var.project_name}-private-rt-${count.index + 1}" : "${var.project_name}-private-rt"
        Type = "Private"
    })
}

###################################################################
# ASOCIACIONES DE ROUTE TABLES PÚBLICAS
###################################################################
resource "aws_route_table_association" "public" {
    count = var.create_nat_gateway ? length(aws_subnet.public) : 0

    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public[0].id
}

###################################################################
# ASOCIACIONES DE ROUTE TABLES PRIVADAS
###################################################################
resource "aws_route_table_association" "private" {
    count = length(aws_subnet.private)

    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = var.create_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}