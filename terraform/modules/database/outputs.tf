###################################################################
# OUTPUTS DE LA INSTANCIA RDS
###################################################################
output "db_instance_id" {
  description = "ID de la instancia RDS"
  value       = aws_db_instance.main.id
}

output "db_instance_identifier" {
  description = "Identificador de la instancia RDS"
  value       = aws_db_instance.main.identifier
}

output "db_instance_endpoint" {
  description = "Endpoint de conexión a la base de datos"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "Dirección de la instancia RDS"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "Puerto de la base de datos"
  value       = aws_db_instance.main.port
}

output "db_instance_arn" {
  description = "ARN de la instancia RDS"
  value       = aws_db_instance.main.arn
}

output "db_instance_status" {
  description = "Estado de la instancia RDS"
  value       = aws_db_instance.main.status
}

output "db_instance_availability_zone" {
  description = "Zona de disponibilidad de la instancia principal"
  value       = aws_db_instance.main.availability_zone
}

output "db_instance_multi_az" {
  description = "Si la instancia es Multi-AZ"
  value       = aws_db_instance.main.multi_az
}

###################################################################
# OUTPUTS DE RED Y SEGURIDAD
###################################################################
output "db_subnet_group_id" {
  description = "ID del DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "ARN del DB subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_security_group_id" {
  description = "ID del security group de la base de datos"
  value       = aws_security_group.rds.id
}

output "db_security_group_arn" {
  description = "ARN del security group de la base de datos"
  value       = aws_security_group.rds.arn
}

###################################################################
# OUTPUTS DE CONFIGURACIÓN
###################################################################
output "db_parameter_group_id" {
  description = "ID del parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "ARN del parameter group"
  value       = aws_db_parameter_group.main.arn
}

output "database_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "Nombre de usuario maestro"
  value       = aws_db_instance.main.username
  sensitive   = true
}

###################################################################
# OUTPUTS DE MONITOREO
###################################################################
output "monitoring_role_arn" {
  description = "ARN del rol de monitoreo mejorado"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

output "performance_insights_enabled" {
  description = "Si Performance Insights está habilitado"
  value       = aws_db_instance.main.performance_insights_enabled
}

###################################################################
# OUTPUTS DE SECRETS MANAGER
###################################################################
output "secrets_manager_secret_id" {
  description = "ID del secreto en AWS Secrets Manager"
  value       = var.create_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].id : null
}

output "secrets_manager_secret_arn" {
  description = "ARN del secreto en AWS Secrets Manager"
  value       = var.create_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].arn : null
}

###################################################################
# OUTPUTS DE CLOUDWATCH LOGS
###################################################################
output "cloudwatch_log_groups" {
  description = "ARNs de los grupos de logs de CloudWatch"
  value = var.enable_cloudwatch_logs ? {
    error     = aws_cloudwatch_log_group.mysql_error[0].arn
    general   = aws_cloudwatch_log_group.mysql_general[0].arn
    slowquery = aws_cloudwatch_log_group.mysql_slowquery[0].arn
  } : {}
}

###################################################################
# OUTPUTS PARA CONEXIÓN DE APLICACIONES
###################################################################
output "connection_string" {
  description = "String de conexión para aplicaciones"
  value       = "mysql://${aws_db_instance.main.username}:${var.master_password}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "jdbc_connection_string" {
  description = "String de conexión JDBC"
  value       = "jdbc:mysql://${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

###################################################################
# OUTPUTS DE INFORMACIÓN GENERAL
###################################################################
output "engine" {
  description = "Motor de base de datos"
  value       = aws_db_instance.main.engine
}

output "engine_version" {
  description = "Versión del motor de base de datos"
  value       = aws_db_instance.main.engine_version
}

output "instance_class" {
  description = "Clase de instancia"
  value       = aws_db_instance.main.instance_class
}

output "allocated_storage" {
  description = "Almacenamiento asignado en GB"
  value       = aws_db_instance.main.allocated_storage
}

output "storage_encrypted" {
  description = "Si el almacenamiento está encriptado"
  value       = aws_db_instance.main.storage_encrypted
}
