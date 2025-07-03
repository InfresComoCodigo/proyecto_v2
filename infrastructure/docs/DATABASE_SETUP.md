# 🗄️ Guía de Configuración de Base de Datos RDS MySQL

Esta guía te ayudará a configurar y desplegar la base de datos RDS MySQL Multi-AZ para AventuraXtremo.

## 🎯 Características de la Base de Datos

### Configuración Multi-AZ
- **Zona Primaria (A)**: 10.0.101.0/24 (us-east-1a)
- **Zona Secundaria (B)**: 10.0.102.0/24 (us-east-1b)
- **Failover Automático**: En caso de falla, cambio automático a la replica
- **Backup Automático**: Backups diarios con retención configurable

### Especificaciones Técnicas
```
Motor: MySQL 8.0.35
Instancia: Variable por ambiente (t3.micro/small/medium)
Almacenamiento: gp3 con auto-scaling
Encriptación: Habilitada con KMS
Red: Solo subredes privadas
Multi-AZ: Habilitado para alta disponibilidad
```

## 🚀 Pasos de Despliegue

### 1. Configurar Variables
Editar `terraform.tfvars` con la configuración de base de datos:

```hcl
# Configuración de base de datos
db_password = "MiPasswordSegura123!"  # CAMBIAR por una contraseña segura

# Otras configuraciones importantes
project_name = "aventuraxtremo"
environment  = "dev"  # o "staging", "prod"
aws_region   = "us-east-1"
```

### 2. Ejecutar Despliegue
```bash
# Opción 1: Despliegue automatizado (recomendado)
./scripts/deploy.sh

# Opción 2: Comandos Terraform manuales
terraform init
terraform plan
terraform apply
```

### 3. Verificar Despliegue
```bash
# Obtener información de la base de datos
terraform output database_info

# Verificar conectividad (desde una instancia EC2 en la VPC)
mysql -h [ENDPOINT] -P 3306 -u admin -p
```

## 📊 Configuración por Ambiente

### Development (dev)
```yaml
Instancia: db.t3.micro
Almacenamiento: 20 GB inicial, hasta 50 GB
Backup: 3 días de retención
Costo estimado: ~$15-20/mes
```

### Staging (staging)
```yaml
Instancia: db.t3.small
Almacenamiento: 20 GB inicial, hasta 100 GB
Backup: 7 días de retención
Costo estimado: ~$30-40/mes
```

### Production (prod)
```yaml
Instancia: db.t3.medium
Almacenamiento: 100 GB inicial, hasta 1TB
Backup: 14 días de retención
Deletion Protection: Habilitada
Costo estimado: ~$80-120/mes
```

## 🗃️ Inicialización de Esquemas SQL

### Ejecutar Script Automatizado
```bash
# Obtener endpoint de la base de datos
DB_ENDPOINT=$(terraform output -raw database_info | jq -r '.endpoint')

# Ejecutar inicialización completa
./scripts/init_database.sh $DB_ENDPOINT 3306 admin [PASSWORD] iac
```

### Scripts SQL Incluidos

El script carga automáticamente en el siguiente orden:

1. **gestion_usuarios.sql**
   - Tabla `user_profiles` - Perfiles de usuario
   - Tabla `roles` - Roles del sistema
   - Tabla `user_roles` - Asignación de roles

2. **tablas_conf_audit.sql**
   - Tabla `system_settings` - Configuraciones del sistema
   - Tabla `audit_logs` - Auditoría de cambios
   - Triggers de auditoría automática

3. **gestion_paquetes_servicios.sql**
   - Tabla `service_categories` - Categorías de servicios
   - Tabla `services` - Servicios disponibles
   - Tabla `packages` - Paquetes turísticos
   - Tabla `package_services` - Servicios en paquetes

4. **gestion_reservas_eventos.sql**
   - Tabla `venues` - Espacios/locaciones
   - Tabla `reservations` - Reservas principales
   - Tabla `reservation_services` - Servicios por reserva

5. **procesamiento_pagos.sql**
   - Tabla `payment_methods` - Métodos de pago
   - Tabla `transactions` - Transacciones
   - Tabla `payment_logs` - Logs de pagos

6. **comunicacion_notificaciones.sql**
   - Tabla `notification_templates` - Plantillas
   - Tabla `notifications` - Notificaciones
   - Tabla `communication_logs` - Logs de comunicación

7. **gestion_personal.sql**
   - Tabla `staff_profiles` - Perfiles de personal
   - Tabla `staff_schedules` - Horarios
   - Tabla `staff_assignments` - Asignaciones

8. **cotizacion.sql**
   - Tabla `quotations` - Cotizaciones
   - Tabla `quotation_items` - Items de cotización
   - Tabla `quotation_versions` - Versiones

## 🔐 Seguridad y Acceso

### Credenciales Seguras
Las credenciales se almacenan automáticamente en AWS Secrets Manager:

```bash
# Obtener credenciales desde Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id aventuraxtremo/rds/mysql/credentials \
  --query 'SecretString' \
  --output text | jq
```

### Acceso Restringido
- ✅ **Permitido**: Instancias EC2 en subredes privadas
- ✅ **Permitido**: Security groups autorizados
- ❌ **Bloqueado**: Acceso público desde Internet
- ❌ **Bloqueado**: Otras VPCs o redes

### Security Groups
```
Puerto: 3306 (MySQL)
Protocolo: TCP
Origen: 
  - 10.0.101.0/24 (Subred privada A)
  - 10.0.102.0/24 (Subred privada B)
  - Security groups de aplicaciones autorizadas
```

## 📈 Monitoreo y Mantenimiento

### Métricas Automáticas
- **CPU Utilization**: Uso de CPU de la instancia
- **Database Connections**: Número de conexiones activas
- **Free Storage Space**: Espacio libre en disco
- **Read/Write IOPS**: Operaciones de entrada/salida
- **Read/Write Latency**: Latencia de operaciones

### Performance Insights
Habilitado automáticamente para monitoreo detallado:
- Top SQL statements
- Wait events
- Database load

### Backups Automáticos
```
Ventana de backup: 03:00-04:00 UTC (10:00-11:00 PM Perú)
Retención: Variable por ambiente (3-14 días)
Snapshot final: Automático al eliminar (excepto dev)
```

### Mantenimiento
```
Ventana: Domingo 04:00-05:00 UTC (11:00 PM-12:00 AM Perú)
Auto Minor Version Upgrade: Deshabilitado (control manual)
```

## 🔧 Operaciones Comunes

### Conectar desde EC2
```bash
# Instalar cliente MySQL en EC2
sudo yum install mysql -y

# Conectar a la base de datos
mysql -h [RDS_ENDPOINT] -P 3306 -u admin -p iac
```

### Backup Manual
```bash
# Crear snapshot manual
aws rds create-db-snapshot \
  --db-instance-identifier aventuraxtremo-mysql-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d-%H%M%S)
```

### Restore desde Backup
```bash
# Listar snapshots disponibles
aws rds describe-db-snapshots \
  --db-instance-identifier aventuraxtremo-mysql-db

# Restaurar desde snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier aventuraxtremo-mysql-restored \
  --db-snapshot-identifier [SNAPSHOT-ID]
```

### Escalamiento Vertical
```bash
# Cambiar clase de instancia (requiere reinicio)
aws rds modify-db-instance \
  --db-instance-identifier aventuraxtremo-mysql-db \
  --db-instance-class db.t3.medium \
  --apply-immediately
```

## 🚨 Troubleshooting

### Conexión Rechazada
```bash
# Verificar security groups
aws ec2 describe-security-groups --group-ids [SG-ID]

# Verificar estado de la instancia
aws rds describe-db-instances \
  --db-instance-identifier aventuraxtremo-mysql-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### Espacio en Disco Bajo
El almacenamiento se escala automáticamente, pero puedes verificar:

```bash
# Verificar métricas de almacenamiento
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name FreeStorageSpace \
  --dimensions Name=DBInstanceIdentifier,Value=aventuraxtremo-mysql-db \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

### Performance Issues
```sql
-- Verificar conexiones activas
SHOW PROCESSLIST;

-- Verificar slow queries (si están habilitadas)
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- Verificar configuración de MySQL
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'max_connections';
```

## 📞 Soporte

Para problemas específicos:

1. **Verificar CloudWatch Logs**: Revisar logs de error de MySQL
2. **Performance Insights**: Analizar queries problemáticas
3. **AWS Support**: Para problemas de infraestructura
4. **Documentación AWS RDS**: https://docs.aws.amazon.com/rds/

---

**💡 Tip**: Siempre probar cambios en el ambiente de desarrollo antes de aplicarlos en staging o producción.
