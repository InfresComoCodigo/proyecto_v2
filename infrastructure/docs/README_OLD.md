# Proyecto Villa Alfredo - Infraestructura como Código

Este proyecto despliega la infraestructura completa para el proyecto Villa Alfredo utilizando Terraform y AWS.

## 🏗️ Arquitectura

La infraestructura incluye:

- **VPC**: Red privada virtual con subredes públicas y privadas
- **Security Groups**: Grupos de seguridad para instancias y VPC endpoints
- **VPC Endpoints**: Conectividad privada a servicios AWS (S3, CloudWatch, EC2)
- **Auto Scaling Group**: Escalado automático de instancias EC2
- **NAT Gateway**: Conectividad a internet para recursos privados

## 📁 Estructura del Proyecto

```
.
├── main.tf                    # Configuración principal de módulos
├── variables.tf               # Variables de entrada
├── outputs.tf                 # Valores de salida
├── locals.tf                  # Valores locales y configuraciones
├── provider.tf                # Configuración del proveedor AWS
├── terraform.tfvars.example   # Ejemplo de configuración de variables
├── modules/
│   ├── networking/
│   │   ├── vpc/              # Módulo de VPC
│   │   └── vpc_endpoint/     # Módulo de VPC Endpoints
│   ├── security/             # Módulo de Security Groups
│   ├── compute/              # Módulo de EC2 y Auto Scaling
│   ├── database/             # Módulo de base de datos
│   ├── storage/              # Módulo de almacenamiento
│   └── monitoring/           # Módulo de monitoreo
```

## 🚀 Uso

### Prerrequisitos

1. **Terraform** >= 1.0
2. **AWS CLI** configurado
3. Credenciales de AWS con permisos necesarios

### Configuración

1. Clonar el repositorio
2. Copiar el archivo de ejemplo de variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Editar `terraform.tfvars` con tus valores específicos

### Despliegue

```bash
# Inicializar Terraform
terraform init

# Planificar el despliegue
terraform plan

# Aplicar los cambios
terraform apply

# Ver outputs
terraform output
```

## 🔧 Configuración por Ambiente

El proyecto soporta múltiples ambientes (dev, staging, prod) con configuraciones específicas:

### Desarrollo (dev)
- Instancias: t3.micro
- Min/Max instancias: 1/2
- Monitoreo: Deshabilitado

### Staging
- Instancias: t3.small
- Min/Max instancias: 1/3
- Monitoreo: Habilitado

### Producción (prod)
- Instancias: t3.medium
- Min/Max instancias: 2/10
- Monitoreo: Habilitado

## 📋 Variables Principales

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `project_name` | Nombre del proyecto | `villa-alfredo` |
| `environment` | Ambiente de despliegue | `dev` |
| `aws_region` | Región de AWS | `us-east-1` |
| `common_tags` | Tags comunes para recursos | Ver variables.tf |

## 📤 Outputs Importantes

- `vpc_info`: Información completa de la VPC
- `subnet_info`: IDs de subredes públicas y privadas
- `security_groups_info`: IDs de security groups
- `autoscaling_info`: Información del Auto Scaling Group
- `project_summary`: Resumen del proyecto desplegado

## 🔒 Seguridad

- Todas las instancias se despliegan en subredes privadas
- Conectividad a internet a través de NAT Gateway
- VPC Endpoints para servicios AWS sin tráfico por internet
- Security Groups con reglas mínimas necesarias

## 🔄 Mantenimiento

### Actualización de la infraestructura

```bash
terraform plan
terraform apply
```

### Destrucción de recursos

```bash
terraform destroy
```

### Validación de configuración

```bash
terraform validate
terraform fmt
```

## 📞 Soporte

Para dudas o problemas:
- **Equipo**: Infrastructure Team
- **Proyecto**: Villa Alfredo
- **Mantenido por**: DevOps Team

## 📝 Notas

- El proyecto está configurado para usar Terraform >= 1.0
- Se requiere AWS Provider ~> 5.0
- Todos los recursos incluyen tags para identificación y gestión de costos
