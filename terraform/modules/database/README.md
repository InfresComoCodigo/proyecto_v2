# Módulo de Base de Datos RDS MySQL Multi-AZ

Este módulo crea una instancia de base de datos RDS MySQL con configuración Multi-AZ para alta disponibilidad en una red privada.

## Características

- **Multi-AZ**: Réplica automática en otra zona de disponibilidad para alta disponibilidad
- **Red Privada**: Implementado en subredes privadas sin acceso público
- **Seguridad**: Security groups configurados para acceso controlado
- **Monitoreo**: Enhanced Monitoring y Performance Insights habilitados
- **Backup**: Backups automáticos con retención configurable
- **Encriptación**: Almacenamiento encriptado por defecto
- **Secrets Manager**: Credenciales almacenadas de forma segura
- **CloudWatch Logs**: Logs de errores, general y slow queries

## Uso

```hcl
module "database" {
  source = "./modules/database"

  # Configuración general
  project_name = "aventuraxtremo"
  environment  = "production"

  # Red
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  allowed_cidr_blocks = ["10.0.101.0/24", "10.0.102.0/24"]

  # Base de datos
  database_name    = "iac"
  master_username  = "admin"
  master_password  = var.db_password
  mysql_version    = "8.0.35"
  instance_class   = "db.t3.small"

  # Almacenamiento
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true

  # Alta disponibilidad
  multi_az = true

  # Backup y mantenimiento
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  tags = {
    Project     = "AventuraXtremo"
    Environment = "production"
    Owner       = "DevOps Team"
  }
}
```

## Configuración de Red

La base de datos se implementa en:
- **Subred Privada A**: 10.0.101.0/24 (us-east-1a)
- **Subred Privada B**: 10.0.102.0/24 (us-east-1b)

## Seguridad

- Security group que permite conexiones MySQL (puerto 3306) solo desde las subredes privadas
- Credenciales almacenadas en AWS Secrets Manager
- Almacenamiento encriptado con KMS
- Sin acceso público desde Internet

## Monitoreo

- Enhanced Monitoring con métricas cada 60 segundos
- Performance Insights habilitado
- CloudWatch Logs para:
  - Error logs
  - General logs  
  - Slow query logs

## Variables Principales

| Variable | Descripción | Tipo | Default |
|----------|-------------|------|---------|
| `project_name` | Nombre del proyecto | string | - |
| `environment` | Entorno (dev, staging, prod) | string | - |
| `vpc_id` | ID de la VPC | string | - |
| `private_subnet_ids` | IDs de subredes privadas | list(string) | - |
| `database_name` | Nombre de la base de datos | string | "iac" |
| `master_username` | Usuario maestro | string | "admin" |
| `master_password` | Contraseña maestra | string | - |
| `multi_az` | Habilitar Multi-AZ | bool | true |
| `instance_class` | Clase de instancia | string | "db.t3.micro" |

## Outputs Importantes

| Output | Descripción |
|--------|-------------|
| `db_instance_endpoint` | Endpoint de conexión |
| `db_instance_port` | Puerto de la base de datos |
| `db_security_group_id` | ID del security group |
| `secrets_manager_secret_arn` | ARN del secreto |

## Scripts SQL

Los scripts SQL para crear las tablas se encuentran en el directorio `sql/`:

- `gestion_usuarios.sql` - Gestión de usuarios y roles
- `gestion_paquetes_servicios.sql` - Paquetes y servicios
- `gestion_reservas_eventos.sql` - Reservas y eventos
- `procesamiento_pagos.sql` - Procesamiento de pagos
- `comunicacion_notificaciones.sql` - Comunicaciones
- `gestion_personal.sql` - Gestión de personal
- `cotizacion.sql` - Sistema de cotizaciones
- `tablas_conf_audit.sql` - Configuración y auditoría

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC 10.0.0.0/16                     │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │   Subred Privada A  │    │   Subred Privada B  │        │
│  │   10.0.101.0/24     │    │   10.0.102.0/24     │        │
│  │   (us-east-1a)      │    │   (us-east-1b)      │        │
│  │                     │    │                     │        │
│  │  ┌─────────────┐    │    │  ┌─────────────┐    │        │
│  │  │ RDS MySQL   │◄───┼────┼──┤   Replica   │    │        │
│  │  │ Primary     │    │    │  │ (Multi-AZ)  │    │        │
│  │  └─────────────┘    │    │  └─────────────┘    │        │
│  └─────────────────────┘    └─────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```
