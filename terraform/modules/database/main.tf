###################################################################
# LOCALS - Configuración centralizada
###################################################################
locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

###################################################################
# SUBNET GROUP PARA RDS
###################################################################
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

###################################################################
# SECURITY GROUP PARA RDS
###################################################################
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = var.vpc_id
  description = "Security group para RDS MySQL"

  ingress {
    description = "MySQL from private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description     = "MySQL from application security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###################################################################
# PARAMETER GROUP PARA MYSQL
###################################################################
resource "aws_db_parameter_group" "main" {
  family = var.parameter_group_family
  name   = "${var.project_name}-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-params"
  })
}

###################################################################
# RDS MYSQL MULTI-AZ
###################################################################
resource "aws_db_instance" "main" {
  # Identificadores
  identifier = "${var.project_name}-mysql-db"

  # Motor de base de datos
  engine                = "mysql"
  engine_version        = var.mysql_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id

  # Configuración de base de datos
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  # Redes y seguridad
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false

  # Multi-AZ para alta disponibilidad
  multi_az = var.multi_az

  # Configuraciones adicionales
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = var.option_group_name

  # Backups y mantenimiento
  backup_retention_period   = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Monitoreo
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Protección contra eliminación
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-db"
    Type = "Multi-AZ"
  })

  depends_on = [aws_db_subnet_group.main, aws_security_group.rds]
}

###################################################################
# IAM ROLE PARA ENHANCED MONITORING
###################################################################
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.project_name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

###################################################################
# SECRETS MANAGER PARA CREDENCIALES
###################################################################
resource "aws_secretsmanager_secret" "db_credentials" {
  count       = var.create_secrets_manager ? 1 : 0
  name        = "${var.project_name}/rds/mysql/credentials"
  description = "Credenciales para la base de datos MySQL"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.create_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = var.master_username
    password = var.master_password
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = var.database_name
  })
}

###################################################################
# CLOUDWATCH LOG GROUPS
###################################################################
resource "aws_cloudwatch_log_group" "mysql_error" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/error"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-error-logs"
  })
}

resource "aws_cloudwatch_log_group" "mysql_general" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/general"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-general-logs"
  })
}

resource "aws_cloudwatch_log_group" "mysql_slowquery" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/slowquery"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-mysql-slowquery-logs"
  })
}
