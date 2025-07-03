# Módulo VPC Optimizado

Este módulo de Terraform crea una VPC altamente configurable en AWS con subredes públicas y privadas, NAT Gateways, route tables y todas las configuraciones necesarias para una infraestructura de red robusta.

## Características

- ✅ **Configuración dinámica**: Utiliza bucles para crear recursos en lugar de duplicar código
- ✅ **Highly configurable**: Variables para personalizar todos los aspectos de la VPC
- ✅ **Multi-AZ**: Soporte para múltiples zonas de disponibilidad automáticamente
- ✅ **Etiquetado consistente**: Sistema de tags centralizados y configurables
- ✅ **Recursos opcionales**: Posibilidad de crear o no NAT Gateways según necesidades
- ✅ **Outputs completos**: Valores de salida para integración con otros módulos

## Mejoras implementadas

### 🔄 Antes (código duplicado)
```hcl
# Múltiples recursos individuales para cada AZ
resource "aws_subnet" "public_zone_a" { ... }
resource "aws_subnet" "public_zone_b" { ... }
resource "aws_nat_gateway" "nat_zone_a" { ... }
resource "aws_nat_gateway" "nat_zone_b" { ... }
```

### ✅ Después (código optimizado)
```hcl
# Un solo recurso con bucle para todas las AZs
resource "aws_subnet" "public" {
  count = var.create_nat_gateway ? length(var.public_subnet_cidrs) : 0
  # ...
}
```

## Uso

```hcl
module "vpc" {
  source = "./modules/networking/vpc"
  
  project_name     = "mi-proyecto"
  environment      = "production"
  vpc_cidr         = "10.0.0.0/16"
  
  # Configuración de subredes
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  
  # Opciones
  create_nat_gateway       = true
  map_public_ip_on_launch = true
  
  # Tags personalizados
  tags = {
    Team    = "Infrastructure"
    Cost    = "shared"
  }
}
```

## Variables

| Variable | Descripción | Tipo | Valor por defecto |
|----------|-------------|------|-------------------|
| `project_name` | Nombre del proyecto para etiquetar recursos | `string` | `"villa-alfredo"` |
| `environment` | Entorno de despliegue | `string` | `"dev"` |
| `vpc_cidr` | Bloque CIDR para la VPC | `string` | `"10.0.0.0/16"` |
| `create_nat_gateway` | Si crear NAT Gateways y subredes públicas | `bool` | `true` |
| `public_subnet_cidrs` | Lista de bloques CIDR para subredes públicas | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | Lista de bloques CIDR para subredes privadas | `list(string)` | `["10.0.101.0/24", "10.0.102.0/24"]` |
| `map_public_ip_on_launch` | Asignar IP pública automáticamente | `bool` | `false` |
| `tags` | Tags adicionales | `map(string)` | `{}` |

## Outputs

| Output | Descripción |
|--------|-------------|
| `vpc_id` | ID de la VPC creada |
| `public_subnet_ids` | IDs de las subredes públicas |
| `private_subnet_ids` | IDs de las subredes privadas |
| `nat_gateway_ids` | IDs de los NAT Gateways |
| `nat_gateway_public_ips` | IPs públicas de los NAT Gateways |

## Casos de uso

### 1. VPC solo con subredes privadas
```hcl
module "vpc_private_only" {
  source = "./modules/networking/vpc"
  
  project_name        = "backend-only"
  create_nat_gateway  = false
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
}
```

### 2. VPC completa para aplicación web
```hcl
module "vpc_web_app" {
  source = "./modules/networking/vpc"
  
  project_name         = "web-app"
  create_nat_gateway   = true
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  
  map_public_ip_on_launch = true
}
```

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  Public Subnet A        │  Public Subnet B                 │
│  (10.0.1.0/24)          │  (10.0.2.0/24)                   │
│  ┌─────────────┐        │  ┌─────────────┐                 │
│  │ NAT Gateway │        │  │ NAT Gateway │                 │
│  └─────────────┘        │  └─────────────┘                 │
├─────────────────────────────────────────────────────────────┤
│  Private Subnet A       │  Private Subnet B                │
│  (10.0.101.0/24)        │  (10.0.102.0/24)                 │
└─────────────────────────────────────────────────────────────┘
```

## Ventajas de la refactorización

1. **Menos código**: De ~200 líneas a ~170 líneas
2. **Más mantenible**: Un solo lugar para cambiar la lógica de subredes
3. **Escalable**: Fácil agregar más AZs o subredes
4. **Configurable**: Variables para diferentes casos de uso
5. **Reutilizable**: Módulo que se puede usar en múltiples proyectos
