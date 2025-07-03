###################################################################
# LOCALS - Valores locales y configuraciones centralizadas
###################################################################

locals {
  # Información del proyecto
  project_info = {
    name        = var.project_name
    environment = var.environment
    region      = var.aws_region
  }

  # Tags comunes para todos los recursos
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    ProjectName = var.project_name
    Region      = var.aws_region
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  })

  # Configuración de red
  network_config = {
    vpc_cidr             = "10.0.0.0/16"
    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  }

  # Configuración por ambiente
  environment_config = {
    dev = {
      instance_type     = "t2.micro"
      enable_monitoring = false
      # Auto Scaling: 2 instancias fijas + 0-2 adicionales = total 2-4
      min_size                  = 0
      max_size                  = 2
      desired_capacity          = 0
      scale_up_threshold        = 70
      scale_down_threshold      = 30
      health_check_grace_period = 300
      # Configuración de API Gateway
      api_throttle_rate_limit  = 100
      api_throttle_burst_limit = 200
      api_log_level            = "ERROR"
      # Configuración de Cognito Auth
      enable_cognito_auth      = false
      create_public_endpoints  = true
      enable_oauth_flows       = false # OAuth flows disabled for API-only usage
      password_minimum_length  = 6
      password_require_symbols = false
      access_token_validity    = 1
      id_token_validity        = 1
      refresh_token_validity   = 1
      # Configuración de Base de Datos
      db_instance_class          = "db.t3.micro"
      db_allocated_storage       = 20
      db_max_allocated_storage   = 50
      db_backup_retention_period = 3
    }
    staging = {
      instance_type     = "t2.micro"
      enable_monitoring = true
      # Auto Scaling: 2 instancias fijas + 0-2 adicionales = total 2-4
      min_size                  = 0
      max_size                  = 2
      desired_capacity          = 1
      scale_up_threshold        = 60
      scale_down_threshold      = 20
      health_check_grace_period = 300
      # Configuración de API Gateway
      api_throttle_rate_limit  = 500
      api_throttle_burst_limit = 1000
      api_log_level            = "INFO"
      # Configuración de Cognito Auth
      enable_cognito_auth      = true
      create_public_endpoints  = true
      enable_oauth_flows       = false # Set to true if using hosted UI
      password_minimum_length  = 8
      password_require_symbols = true
      access_token_validity    = 12
      id_token_validity        = 12
      refresh_token_validity   = 7
      # Configuración de Base de Datos
      db_instance_class          = "db.t3.small"
      db_allocated_storage       = 20
      db_max_allocated_storage   = 100
      db_backup_retention_period = 7
    }
    prod = {
      instance_type     = "t2.micro"
      enable_monitoring = true
      # Auto Scaling: 2 instancias fijas + 0-2 adicionales = total 2-4
      min_size                  = 0
      max_size                  = 2
      desired_capacity          = 2
      scale_up_threshold        = 75
      scale_down_threshold      = 25
      health_check_grace_period = 600
      # Configuración de API Gateway
      api_throttle_rate_limit  = 1000
      api_throttle_burst_limit = 2000
      api_log_level            = "INFO"
      # Configuración de Cognito Auth
      enable_cognito_auth      = true
      create_public_endpoints  = false
      enable_oauth_flows       = false # Set to true if using hosted UI
      password_minimum_length  = 12
      password_require_symbols = true
      access_token_validity    = 24
      id_token_validity        = 24
      refresh_token_validity   = 30
      # Configuración de Base de Datos
      db_instance_class          = "db.t3.medium"
      db_allocated_storage       = 100
      db_max_allocated_storage   = 1000
      db_backup_retention_period = 14
    }
  }

  # Configuración actual basada en el ambiente
  current_env_config = local.environment_config[var.environment]

  # Configuración de CloudFront por ambiente
  cloudfront_config = {
    dev = {
      price_class        = "PriceClass_100" # Solo US, Canada y Europa (más económico)
      cache_default_ttl  = 0                # Sin cache en dev para pruebas
      enable_compression = true
      enable_monitoring  = false
    }
    staging = {
      price_class        = "PriceClass_100" # Solo US, Canada y Europa
      cache_default_ttl  = 3600             # 1 hora de cache
      enable_compression = true
      enable_monitoring  = true
    }
    prod = {
      price_class        = "PriceClass_200" # US, Canada, Europa, Asia, Middle East, Africa
      cache_default_ttl  = 86400            # 1 día de cache
      enable_compression = true
      enable_monitoring  = true
    }
  }

  # Configuración actual de CloudFront basada en el ambiente
  current_cloudfront_config = local.cloudfront_config[var.environment]
}
