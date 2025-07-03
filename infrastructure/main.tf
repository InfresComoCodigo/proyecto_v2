###################################################################
# CONFIGURACIÓN PRINCIPAL DE INFRAESTRUCTURA
# Proyecto: Villa Alfredo
# Mantenido por: Infrastructure Team
###################################################################

###################################################################
# MÓDULO VPC - Red y conectividad
###################################################################

module "vpc" {
    source = "./modules/networking/vpc"

    # Configuración básica usando locals
    project_name = local.project_info.name
    environment  = local.project_info.environment
    vpc_cidr     = local.network_config.vpc_cidr

    # Configuración de subredes
    public_subnet_cidrs  = local.network_config.public_subnet_cidrs
    private_subnet_cidrs = local.network_config.private_subnet_cidrs

    # Configuraciones de red
    create_nat_gateway       = true
    map_public_ip_on_launch = false
    enable_dns_support       = true
    enable_dns_hostnames     = true

    # Tags usando configuración centralizada
    tags = local.common_tags
}

###################################################################
# MÓDULO SECURITY - Grupos de seguridad
###################################################################

module "security" {
    source = "./modules/security"

    vpc_id                = module.vpc.vpc_id
    private_subnet_cidrs  = module.vpc.private_subnet_cidrs
    project_name          = local.project_info.name
    environment           = local.project_info.environment
    
    tags = local.common_tags
}

###################################################################
# MÓDULO VPC ENDPOINTS - Conectividad privada a servicios AWS
###################################################################

module "vpc_endpoints" {
    source = "./modules/networking/vpc_endpoint"

    vpc_id                    = module.vpc.vpc_id
    private_subnet_ids        = module.vpc.private_subnet_ids
    private_route_table_ids   = module.vpc.private_route_table_ids
    security_group_id         = module.security.vpc_endpoints_sg_id
    project_name              = local.project_info.name
    environment               = local.project_info.environment
    
    depends_on = [module.security]
}

###################################################################
# MÓDULO ALB - Application Load Balancer
###################################################################

module "alb" {
    source = "./modules/networking/alb"

    # Configuración de red
    vpc_id             = module.vpc.vpc_id
    public_subnet_ids  = module.vpc.public_subnet_ids
    security_group_id  = module.security.alb_sg_id
    
    # Configuración de instancias target (inicialmente vacío)
    target_instance_ids = []
    
    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de puertos
    alb_port    = 80
    target_port = 80
    
    # Configuración de health checks
    health_check_path     = "/"
    health_check_interval = 30
    health_check_timeout  = 5
    healthy_threshold     = 2
    unhealthy_threshold   = 2
    
    # Tags
    tags = local.common_tags
    
    depends_on = [module.security]
}

###################################################################
# MÓDULO COMPUTE - Instancias EC2 fijas + Auto Scaling
###################################################################

module "compute" {
    source = "./modules/compute"

    # Configuración básica
    vpc_id            = module.vpc.vpc_id
    security_group_id = module.security.ec2_instances_sg_id
    subnet_ids        = module.vpc.private_subnet_ids
    environment       = local.project_info.environment
    project_name      = local.project_info.name
    
    # Configuración de instancia
    instance_type     = local.current_env_config.instance_type
    enable_monitoring = local.current_env_config.enable_monitoring
    ami_id           = "ami-05ffe3c48a9991133"  # AMI específica solicitada
    
    # Configuración de Auto Scaling (instancias adicionales)
    min_size                 = local.current_env_config.min_size
    max_size                 = local.current_env_config.max_size
    desired_capacity         = local.current_env_config.desired_capacity
    scale_up_threshold       = local.current_env_config.scale_up_threshold
    scale_down_threshold     = local.current_env_config.scale_down_threshold
    health_check_grace_period = local.current_env_config.health_check_grace_period
    
    # Configuración del ALB Target Group
    target_group_arn = module.alb.target_group_arn
    
    # Key pair (opcional - usa la variable o deja como null)
    key_name = var.key_pair_name
    
    # Tags
    tags = local.common_tags
    
    depends_on = [module.security, module.alb]
}

###################################################################
# ASOCIACIÓN DE INSTANCIAS FIJAS AL ALB
###################################################################

resource "aws_lb_target_group_attachment" "fixed_instances" {
  count            = 2  # 2 instancias fijas
  target_group_arn = module.alb.target_group_arn
  target_id        = count.index == 0 ? module.compute.ec2_zone_a_id : module.compute.ec2_zone_b_id
  port             = 80
  
  depends_on = [module.alb, module.compute]
}

###################################################################
# MÓDULO AUTH - Amazon Cognito para autenticación
###################################################################

module "auth" {
    source = "./modules/auth"

    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de contraseñas
    password_minimum_length    = local.current_env_config.password_minimum_length
    password_require_lowercase = true
    password_require_numbers   = true
    password_require_symbols   = local.current_env_config.password_require_symbols
    password_require_uppercase = true
    
    # Configuración de tokens
    access_token_validity  = local.current_env_config.access_token_validity
    id_token_validity     = local.current_env_config.id_token_validity
    refresh_token_validity = local.current_env_config.refresh_token_validity
    
    # Configuración de MFA (solo en producción por defecto)
    enable_mfa = local.project_info.environment == "prod" ? true : false
    
    # URLs para OAuth - Solo configurar si se van a usar flows OAuth
    # Para uso solo con API Gateway (sin UI hospedada), dejar vacío
    callback_urls = local.current_env_config.enable_oauth_flows ? [
        "https://${local.project_info.name}-${local.project_info.environment}.example.com/callback",
        "http://localhost:3000/callback" # Para desarrollo local
    ] : []
    logout_urls = local.current_env_config.enable_oauth_flows ? [
        "https://${local.project_info.name}-${local.project_info.environment}.example.com/logout",
        "http://localhost:3000/logout" # Para desarrollo local
    ] : []
    
    # Configuración OAuth (opcional - solo si usas UI hospedada)
    allowed_oauth_flows = local.current_env_config.enable_oauth_flows ? ["code"] : []
    allowed_oauth_scopes = local.current_env_config.enable_oauth_flows ? ["email", "openid", "profile"] : []
    
    # Configuración de clientes
    create_web_client = true
    
    # Identity Pool (solo para acceso directo a recursos AWS si es necesario)
    create_identity_pool             = false
    allow_unauthenticated_identities = false
    
    # Tags
    tags = local.common_tags
}

###################################################################
# MÓDULO DATABASE - RDS MySQL Multi-AZ
###################################################################

module "database" {
    source = "./modules/database"

    # Configuración general
    project_name = local.project_info.name
    environment  = local.project_info.environment

    # Configuración de red
    vpc_id             = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    allowed_cidr_blocks = [
        "10.0.101.0/24",  # Subred privada Zona A
        "10.0.102.0/24"   # Subred privada Zona B  
    ]
    allowed_security_groups = [
        module.security.ec2_instances_sg_id
    ]

    # Configuración de base de datos
    database_name   = "iac"
    master_username = "admin"
    master_password = var.db_password
    mysql_version   = "8.0.35"
    instance_class  = local.current_env_config.db_instance_class

    # Configuración de almacenamiento
    allocated_storage     = local.current_env_config.db_allocated_storage
    max_allocated_storage = local.current_env_config.db_max_allocated_storage
    storage_type         = "gp3"
    storage_encrypted    = true

    # Alta disponibilidad - Multi-AZ habilitado
    multi_az = true

    # Configuración de backup y mantenimiento
    backup_retention_period    = local.current_env_config.db_backup_retention_period
    backup_window             = "03:00-04:00"  # UTC - 10:00-11:00 PM hora de Perú
    maintenance_window        = "sun:04:00-sun:05:00"  # Domingo 11:00-12:00 PM hora de Perú
    auto_minor_version_upgrade = false
    deletion_protection       = local.project_info.environment == "prod"

    # Configuración de monitoreo
    monitoring_interval                    = 0  # Disabled to avoid IAM role issues
    performance_insights_enabled           = false  # Deshabilitado para evitar errores de compatibilidad
    performance_insights_retention_period  = 7
    enable_cloudwatch_logs                = true
    log_retention_days                    = 30

    # Secrets Manager para credenciales
    create_secrets_manager = true

    tags = local.common_tags
}

###################################################################
# MÓDULO API GATEWAY - Gateway público hacia ALB público con autenticación
###################################################################

module "api_gateway" {
    source = "./modules/api_gateway"

    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de ALB
    alb_dns_name         = module.alb.alb_dns_name
    
    # Configuración de API Gateway
    api_gateway_type      = "REGIONAL"
    stage_name           = "api"
    throttle_rate_limit  = local.current_env_config.api_throttle_rate_limit
    throttle_burst_limit = local.current_env_config.api_throttle_burst_limit
    
    # Configuración de autenticación Cognito
    enable_cognito_auth     = local.current_env_config.enable_cognito_auth
    cognito_user_pool_arn   = module.auth.user_pool_arn
    authorizer_ttl          = 300
    create_public_endpoints = local.current_env_config.create_public_endpoints
    
    # Configuración de logging
    enable_logging = local.current_env_config.enable_monitoring
    log_level      = local.current_env_config.api_log_level
    
    # Tags
    tags = local.common_tags
    
    depends_on = [module.alb, module.auth]
}

###################################################################
# MÓDULO WAF - Protección Web Application Firewall para CloudFront
###################################################################

module "waf" {
    source = "./modules/waf"
    
    providers = {
        aws.us_east_1 = aws.us_east_1
    }

    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de protecciones (simplificadas)
    enable_sql_injection_protection = true
    enable_rate_limiting           = true
    
    # Configuración de rate limiting específica por ambiente
    rate_limit_requests = local.project_info.environment == "prod" ? 1000 : 2000
    
    # Deshabilitamos configuraciones complejas temporalmente
    blocked_countries = []
    blocked_ip_addresses = []
    blocked_user_agents = []
    
    # Configuración de monitoreo
    enable_cloudwatch_metrics = true
    enable_sampled_requests   = true
    enable_logging            = local.project_info.environment == "prod" ? true : false
    log_retention_days        = 30
    
    # Excluir reglas específicas si es necesario
    excluded_common_rules = [
        # "SizeRestrictions_BODY",  # Ejemplo: si necesitas permitir bodies grandes
    ]
    
    # Tags
    tags = merge(local.common_tags, {
        Type = "WAF"
        Purpose = "CloudFront-Protection"
    })
}

###################################################################
# MÓDULO CDN - CloudFront Distribution para S3 + API Gateway
###################################################################

module "cdn" {
    source = "./modules/cdn"

    providers = {
        aws.us_east_1 = aws.us_east_1
    }

    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de WAF
    enable_waf   = true
    web_acl_arn  = module.waf.web_acl_arn
    
    # Configuración de múltiples orígenes
    primary_origin                   = "s3"  # S3 como origen principal
    enable_dual_origin              = true   # Habilitar S3 + API Gateway
    
    # Configuración del origen S3 (principal)
    s3_bucket_regional_domain_name  = module.storage.bucket_regional_domain_name
    s3_origin_access_control_id     = module.storage.cloudfront_oac_id
    
    # Configuración del origen API Gateway (secundario)
    api_gateway_domain_name         = module.api_gateway.api_gateway_domain_name
    
    # Configuración de cache behavior
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    
    # Configuración de TTL basada en ambiente
    cache_min_ttl     = 0
    cache_default_ttl = local.current_cloudfront_config.cache_default_ttl
    cache_max_ttl     = 31536000  # 1 año
    
    # Configuración de forwarding para APIs
    forward_query_string = true
    forward_headers      = ["Authorization", "Content-Type", "Host"]
    forward_cookies      = "none"
    
    # Configuración de compresión
    enable_compression = local.current_cloudfront_config.enable_compression
    
    # Configuración de precio basada en ambiente
    price_class = local.current_cloudfront_config.price_class
    
    # Configuración de monitoreo basada en ambiente
    enable_monitoring = local.current_cloudfront_config.enable_monitoring
    
    # Configuración de logging (opcional)
    enable_logging = false  # Cambiar a true si necesitas logs detallados
    
    # Configuración de restricciones geográficas (opcional)
    geo_restriction_type      = "none"
    geo_restriction_locations = []
    
    # Configuración de SSL
    ssl_certificate_arn = null  # Usar certificado por defecto de CloudFront
    
    # Behaviors personalizados para APIs (sin cache para rutas dinámicas)
    cache_behaviors = [
        {
            path_pattern           = "/api/*"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 0
            default_ttl           = 0      # No cachear APIs por defecto
            max_ttl               = 86400
            forward_query_string  = true
            forward_headers       = ["*"]  # Forwardear todos los headers para APIs
            forward_cookies       = "all"
            compress              = true
        }
    ]
    
    # Tags
    tags = local.common_tags
    
    depends_on = [module.waf, module.api_gateway, module.storage]
}

###################################################################
# MÓDULO STORAGE - S3 Bucket para contenido estático
###################################################################

module "storage" {
    source = "./modules/storage"

    # Configuración básica
    project_name = local.project_info.name
    environment  = local.project_info.environment
    
    # Configuración de conectividad
    s3_vpc_endpoint_id           = module.vpc_endpoints.s3_endpoint_id
    cloudfront_distribution_arn  = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"  # Wildcard temporal
    vpc_id                      = module.vpc.vpc_id
    private_subnet_ids          = module.vpc.private_subnet_ids
    
    # Configuración de S3 basada en ambiente
    enable_versioning        = local.current_env_config.enable_monitoring  # Versioning en staging/prod
    enable_lifecycle_policy  = local.current_env_config.enable_monitoring  # Lifecycle en staging/prod
    create_sample_files     = var.environment == "dev"  # Solo archivos de ejemplo en dev
    enable_cors             = true
    
    # Roles de EC2 para acceso adicional (opcional)
    ec2_instance_roles = null  # Se maneja via VPC endpoint
    
    # Tags
    tags = local.common_tags
    
    depends_on = [module.vpc_endpoints]
}

###################################################################
# DATA SOURCES
###################################################################

data "aws_caller_identity" "current" {}

###################################################################
# ACTUALIZACIÓN DE BUCKET POLICY POST-CLOUDFRONT
###################################################################

# Actualizar la bucket policy con el ARN real de CloudFront
resource "aws_s3_bucket_policy" "cloudfront_update" {
  bucket = module.storage.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permitir acceso desde VPC Endpoint (para EC2 instances) - más restrictivo
      {
        Sid    = "AllowVPCEndpointAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${module.storage.bucket_arn}/*"  # Only objects, not bucket
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = module.vpc_endpoints.s3_endpoint_id
          }
        }
      },
      # Permitir acceso desde CloudFront (usando OAC)
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${module.storage.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cdn.cloudfront_distribution_arn
          }
        }
      },
      # Denegar acceso no SSL
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          module.storage.bucket_arn,
          "${module.storage.bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
  
  depends_on = [module.storage, module.cdn]
}