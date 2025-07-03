# 🏔️ AventuraXtremo - Infraestructura como Código

Infraestructura completa en AWS para la plataforma de turismo de aventura AventuraXtremo, implementada con Terraform y configurada para alta disponibilidad.

## 📋 Características Principales

### 🏗️ Arquitectura
- **VPC Multi-AZ**: Red privada segura con subredes públicas y privadas
- **RDS MySQL Multi-AZ**: Base de datos con replica automática para alta disponibilidad
- **Auto Scaling**: Escalamiento automático basado en demanda
- **Load Balancing**: Distribución de tráfico con Application Load Balancer
- **CDN**: CloudFront para entrega global de contenido
- **API Gateway**: API REST con autenticación Cognito
- **WAF**: Protección contra ataques web

### 🔐 Seguridad
- **Cognito Authentication**: Gestión de usuarios y autenticación
- **IAM Roles**: Acceso basado en principio de menor privilegio
- **Security Groups**: Firewall a nivel de instancia
- **VPC Endpoints**: Conectividad privada a servicios AWS
- **SSL/TLS**: Encriptación en tránsito
- **Storage Encryption**: Encriptación de datos en reposo

### 📊 Monitoreo
- **CloudWatch**: Métricas y logs centralizados
- **Performance Insights**: Monitoreo de base de datos
- **Enhanced Monitoring**: Métricas detalladas de RDS
- **Auto Scaling Metrics**: Escalamiento basado en métricas

## 🚀 Despliegue Rápido

### Prerequisitos
- AWS CLI configurado
- Terraform >= 1.5
- Bash shell
- jq (para procesamiento JSON)

### Pasos de Despliegue

1. **Configurar Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Editar terraform.tfvars con tus valores
   ```

2. **Ejecutar Despliegue Automatizado**
   ```bash
   ./scripts/deploy.sh
   ```

3. **Inicializar Base de Datos**
   ```bash
   # Después del despliegue, obtener endpoint de la base de datos
   DB_ENDPOINT=$(terraform output -raw database_info | jq -r '.endpoint')
   
   # Ejecutar script de inicialización
   ./scripts/init_database.sh $DB_ENDPOINT 3306 admin [PASSWORD] iac
   ```

## 🗄️ Esquema de Base de Datos

La base de datos incluye tablas para:

- **👥 Gestión de Usuarios**: Perfiles, roles y permisos
- **🎯 Servicios y Paquetes**: Catálogo de servicios turísticos
- **📅 Reservas y Eventos**: Sistema de reservas completo
- **💳 Procesamiento de Pagos**: Gestión de transacciones
- **📧 Comunicaciones**: Notificaciones y mensajería
- **👨‍💼 Gestión de Personal**: Staff y guías turísticos
- **💰 Cotizaciones**: Sistema de cotizaciones
- **⚙️ Configuración y Auditoría**: Configuración del sistema y logs

### Scripts SQL Incluidos
```
sql/
├── gestion_usuarios.sql           # Usuarios y autenticación
├── gestion_paquetes_servicios.sql # Catálogo de servicios
├── gestion_reservas_eventos.sql   # Sistema de reservas
├── procesamiento_pagos.sql        # Pagos y transacciones
├── comunicacion_notificaciones.sql # Comunicaciones
├── gestion_personal.sql           # Gestión de staff
├── cotizacion.sql                 # Sistema de cotizaciones
└── tablas_conf_audit.sql          # Configuración y auditoría
```

## 🏗️ Arquitectura de Red

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC 10.0.0.0/16                         │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │   Subred Pública A  │    │   Subred Pública B  │        │
│  │   10.0.1.0/24       │    │   10.0.2.0/24       │        │
│  │                     │    │                     │        │
│  │  ┌─────────────┐    │    │  ┌─────────────┐    │        │
│  │  │     ALB     │    │    │  │   NAT GW    │    │        │
│  │  └─────────────┘    │    │  └─────────────┘    │        │
│  └─────────────────────┘    └─────────────────────┘        │
│                                                             │
│  ┌─────────────────────┐    ┌─────────────────────┐        │
│  │  Subred Privada A   │    │  Subred Privada B   │        │
│  │   10.0.101.0/24     │    │   10.0.102.0/24     │        │
│  │                     │    │                     │        │
│  │  ┌─────────────┐    │    │  ┌─────────────┐    │        │
│  │  │ EC2 + Apps  │    │    │  │ RDS Replica │    │        │
│  │  │             │    │    │  │ (Multi-AZ)  │    │        │
│  │  │ RDS Primary │◄───┼────┼──┤             │    │        │
│  │  └─────────────┘    │    │  └─────────────┘    │        │
│  └─────────────────────┘    └─────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Configuración por Ambiente

### Development (dev)
- **RDS**: db.t3.micro, 20GB, 3 días backup
- **EC2**: t2.micro, 1-3 instancias
- **Monitoring**: Básico

### Staging (staging)  
- **RDS**: db.t3.small, 20GB, 7 días backup
- **EC2**: t2.micro, 1-4 instancias
- **Monitoring**: Completo

### Production (prod)
- **RDS**: db.t3.medium, 100GB, 14 días backup
- **EC2**: t2.micro, 2-4 instancias (mínimo 2 fijas)
- **Monitoring**: Completo + Enhanced
- **Deletion Protection**: Habilitada

## 🔧 Gestión de Infraestructura

### Comandos Terraform Directos
```bash
# Inicializar
terraform init

# Planificar cambios
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy
```

### Scripts de Utilidad
```bash
# Despliegue completo automatizado
./scripts/deploy.sh

# Destrucción segura con confirmaciones
./scripts/destroy.sh

# Inicialización de base de datos
./scripts/init_database.sh [HOST] [PORT] [USER] [PASSWORD] [DATABASE]

# Pruebas de integración
./scripts/test_cognito_integration.sh
./scripts/test_waf.sh
```

## 📂 Estructura del Proyecto

```
.
├── main.tf                    # Configuración principal
├── variables.tf              # Variables de entrada
├── outputs.tf               # Outputs de la infraestructura
├── locals.tf                # Configuración local por ambiente
├── provider.tf              # Configuración de providers
├── terraform.tfvars.example # Ejemplo de variables
├── modules/                 # Módulos de Terraform
│   ├── api_gateway/        # API Gateway REST
│   ├── auth/               # Amazon Cognito
│   ├── cdn/                # CloudFront CDN
│   ├── compute/            # EC2 Auto Scaling
│   ├── database/           # RDS MySQL Multi-AZ
│   ├── monitoring/         # CloudWatch
│   ├── networking/         # VPC, Subnets, etc.
│   ├── security/           # Security Groups, IAM
│   ├── storage/            # S3 Buckets
│   └── waf/                # AWS WAF
├── scripts/                # Scripts de utilidad
│   ├── deploy.sh           # Despliegue automatizado
│   ├── destroy.sh          # Destrucción segura
│   ├── init_database.sh    # Inicialización de BD
│   └── test_*.sh           # Scripts de prueba
└── sql/                    # Esquemas de base de datos
    ├── gestion_usuarios.sql
    ├── gestion_paquetes_servicios.sql
    ├── gestion_reservas_eventos.sql
    └── ...
```

## 💾 Base de Datos RDS MySQL

### Características
- **Multi-AZ**: Replica automática en zona B para alta disponibilidad
- **Red Privada**: Implementada en subredes 10.0.101.0/24 y 10.0.102.0/24
- **Backup Automático**: Backups diarios con retención configurable
- **Encriptación**: Almacenamiento encriptado con KMS
- **Monitoreo**: Enhanced Monitoring y Performance Insights
- **Escalamiento**: Auto-scaling de almacenamiento hasta 1TB

### Conexión
```bash
# Obtener endpoint de la base de datos
terraform output database_info

# Conectar desde terminal
mysql -h [ENDPOINT] -P 3306 -u admin -p iac

# Obtener credenciales desde Secrets Manager
aws secretsmanager get-secret-value --secret-id aventuraxtremo/rds/mysql/credentials
```

### Inicialización
El script `init_database.sh` carga automáticamente todos los esquemas SQL en el orden correcto:

1. Usuarios y roles
2. Configuración y auditoría  
3. Servicios y paquetes
4. Reservas y eventos
5. Procesamiento de pagos
6. Comunicaciones
7. Personal
8. Cotizaciones

## 🔐 Seguridad

### Acceso a la Base de Datos
- **Solo desde subredes privadas**: 10.0.101.0/24 y 10.0.102.0/24
- **Security Groups restrictivos**: Puerto 3306 solo para instancias autorizadas
- **Sin acceso público**: No hay rutas desde Internet
- **Credenciales en Secrets Manager**: Rotación automática disponible

### Autenticación
- **Amazon Cognito**: Gestión de usuarios y autenticación JWT
- **API Gateway**: Authorizers integrados con Cognito
- **IAM Roles**: Acceso granular a recursos AWS

### Monitoreo de Seguridad
- **AWS WAF**: Protección contra ataques comunes
- **CloudWatch Logs**: Logs de acceso y errores
- **VPC Flow Logs**: Tráfico de red
- **CloudTrail**: Auditoría de API calls

## 📈 Monitoreo y Alertas

### Métricas Disponibles
- **RDS**: CPU, memoria, IOPS, conexiones
- **EC2**: CPU, memoria, red, disco
- **ALB**: Latencia, códigos de respuesta, targets
- **API Gateway**: Latencia, errores, throttling

### Dashboards
- Dashboard principal en CloudWatch
- Performance Insights para RDS
- X-Ray tracing para APIs

## 🚨 Solución de Problemas

### Base de Datos No Accesible
```bash
# Verificar security groups
aws ec2 describe-security-groups --group-ids [SG-ID]

# Verificar subnet group
aws rds describe-db-subnet-groups

# Verificar estado de la instancia
aws rds describe-db-instances --db-instance-identifier [INSTANCE-ID]
```

### Problemas de Conectividad
```bash
# Verificar VPC endpoints
terraform output vpc_endpoints_info

# Verificar NAT gateways
terraform output vpc_info
```

## 🤝 Contribución

1. Fork el repositorio
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Soporte

Para soporte técnico o preguntas:
- Crear un issue en GitHub
- Contactar al equipo de DevOps
- Documentación adicional en [docs/](docs/)

---

**⚠️ Nota Importante**: Este README asume familiaridad básica con AWS y Terraform. Para usuarios nuevos, revisar la documentación oficial de [Terraform](https://terraform.io) y [AWS](https://aws.amazon.com/documentation/).
