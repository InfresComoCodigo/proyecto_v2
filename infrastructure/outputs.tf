###################################################################
# OUTPUTS - Información de infraestructura desplegada
###################################################################

###################################################################
# VPC OUTPUTS
###################################################################

output "vpc_info" {
    description = "Información completa de la VPC"
    value = {
        vpc_id              = module.vpc.vpc_id
        vpc_cidr            = module.vpc.vpc_cidr_block
        public_subnet_ids   = module.vpc.public_subnet_ids
        private_subnet_ids  = module.vpc.private_subnet_ids
        nat_gateway_ips     = module.vpc.nat_gateway_public_ips
        availability_zones  = module.vpc.availability_zones
    }
}

output "vpc_id" {
    description = "ID de la VPC para referencia en otros proyectos"
    value       = module.vpc.vpc_id
}

output "subnet_info" {
    description = "Información de subredes para otros módulos"
    value = {
        private_subnet_ids = module.vpc.private_subnet_ids
        public_subnet_ids  = module.vpc.public_subnet_ids
    }
}

###################################################################
# SECURITY OUTPUTS
###################################################################

output "security_groups_info" {
    description = "Información de los security groups creados"
    value = {
        vpc_endpoints_sg_id = module.security.vpc_endpoints_sg_id
        ec2_instances_sg_id = module.security.ec2_instances_sg_id
    }
}

###################################################################
# VPC ENDPOINTS OUTPUTS
###################################################################

output "vpc_endpoints_info" {
    description = "Información de los VPC endpoints para servicios AWS"
    value = {
        s3_endpoint_id                     = module.vpc_endpoints.s3_endpoint_id
        cloudwatch_logs_endpoint_id        = module.vpc_endpoints.cloudwatch_logs_endpoint_id
        cloudwatch_monitoring_endpoint_id  = module.vpc_endpoints.cloudwatch_monitoring_endpoint_id
        ec2_endpoint_id                    = module.vpc_endpoints.ec2_endpoint_id
    }
}

###################################################################
# COMPUTE OUTPUTS
###################################################################

output "ec2_instances_info" {
    description = "Información completa de las instancias EC2 (fijas + auto scaling)"
    value = {
        fixed_instances = {
            zone_a_instance = {
                instance_id  = module.compute.ec2_zone_a_id
                private_ip   = module.compute.ec2_zone_a_private_ip
                zone         = "us-east-1a"
                subnet       = "10.0.101.0/24"
                type         = "Fixed"
            }
            zone_b_instance = {
                instance_id  = module.compute.ec2_zone_b_id
                private_ip   = module.compute.ec2_zone_b_private_ip
                zone         = "us-east-1b"
                subnet       = "10.0.102.0/24"
                type         = "Fixed"
            }
        }
        auto_scaling = {
            asg_name     = module.compute.autoscaling_group_name
            asg_arn      = module.compute.autoscaling_group_arn
            min_size     = module.compute.capacity_configuration.min_size
            max_size     = module.compute.capacity_configuration.max_size
            desired      = module.compute.capacity_configuration.desired_capacity
        }
        scaling_policies = {
            scale_up_arn   = module.compute.scale_up_policy_arn
            scale_down_arn = module.compute.scale_down_policy_arn
            cpu_high_alarm = module.compute.cpu_high_alarm_name
            cpu_low_alarm  = module.compute.cpu_low_alarm_name
        }
        capacity_summary = module.compute.instances_configuration.total_capacity
    }
}

output "instance_configuration" {
    description = "Configuración detallada de las instancias EC2"
    value = module.compute.instances_configuration
}

###################################################################
# ALB OUTPUTS
###################################################################

output "alb_info" {
    description = "Información completa del Application Load Balancer"
    value = {
        alb_arn           = module.alb.alb_arn
        alb_dns_name      = module.alb.alb_dns_name
        alb_zone_id       = module.alb.alb_zone_id
        alb_url           = module.alb.alb_url
        target_group_arn  = module.alb.target_group_arn
        target_group_name = module.alb.target_group_name
        listener_arn      = module.alb.listener_arn
        public_subnets    = module.vpc.public_subnet_ids
        attached_instances = {
            fixed_instances = [
                module.compute.ec2_zone_a_id,
                module.compute.ec2_zone_b_id
            ]
            asg_integration = "Automatic via target_group_arn"
        }
    }
}

output "alb_dns_name" {
    description = "DNS name del ALB para acceso público"
    value       = module.alb.alb_dns_name
}

output "alb_url" {
    description = "URL completa del ALB"
    value       = module.alb.alb_url
}

###################################################################
# API GATEWAY OUTPUTS
###################################################################

output "api_gateway_info" {
    description = "Información completa del API Gateway"
    value = {
        api_id         = module.api_gateway.api_gateway_id
        api_arn        = module.api_gateway.api_gateway_arn
        api_url        = module.api_gateway.api_gateway_url
        stage_name     = module.api_gateway.api_gateway_stage_name
        log_group_name = module.api_gateway.cloudwatch_log_group_name
        connected_alb  = module.alb.alb_dns_name
        connection_type = "direct"
    }
}

output "api_gateway_url" {
    description = "URL pública del API Gateway"
    value       = module.api_gateway.api_gateway_url
}

output "api_gateway_stage_url" {
    description = "URL completa del stage del API Gateway"
    value       = "${module.api_gateway.api_gateway_url}/${module.api_gateway.api_gateway_stage_name}"
}

###################################################################
# COGNITO AUTH OUTPUTS
###################################################################

output "cognito_auth_info" {
    description = "Información completa de autenticación Cognito"
    value = {
        user_pool_id       = module.auth.user_pool_id
        user_pool_arn      = module.auth.user_pool_arn
        user_pool_domain   = module.auth.user_pool_domain
        api_client_id      = module.auth.api_client_id
        web_client_id      = module.auth.web_client_id
        identity_pool_id   = module.auth.identity_pool_id
        hosted_ui_url      = module.auth.user_pool_hosted_ui_url
        auth_enabled       = module.api_gateway.auth_enabled
    }
}

output "cognito_user_pool_id" {
    description = "ID del User Pool de Cognito"
    value       = module.auth.user_pool_id
}

output "cognito_client_id" {
    description = "ID del cliente API de Cognito"
    value       = module.auth.api_client_id
}

output "cognito_web_client_id" {
    description = "ID del cliente web de Cognito"
    value       = module.auth.web_client_id
}

output "cognito_login_url" {
    description = "URL de login de Cognito"
    value       = module.auth.login_url
}

output "cognito_logout_url" {
    description = "URL de logout de Cognito"
    value       = module.auth.logout_url
}

output "cognito_token_endpoint" {
    description = "Endpoint para obtener tokens"
    value       = module.auth.token_endpoint
}

output "api_endpoints" {
    description = "URLs de los endpoints de la API"
    value = {
        base_url       = module.api_gateway.api_gateway_url
        protected_url  = module.api_gateway.protected_base_url
        public_url     = module.api_gateway.public_base_url
        auth_required  = module.api_gateway.auth_enabled
    }
}

###################################################################
# CDN (CLOUDFRONT) OUTPUTS
###################################################################

output "cdn_info" {
    description = "Información completa de CloudFront CDN"
    value = {
        distribution_id          = module.cdn.cloudfront_distribution_id
        distribution_arn         = module.cdn.cloudfront_distribution_arn
        domain_name             = module.cdn.cloudfront_domain_name
        distribution_url        = module.cdn.cloudfront_url
        origin_api_gateway      = module.api_gateway.api_gateway_url
        cache_enabled           = true
        compression_enabled     = true
        status                  = module.cdn.cloudfront_status
    }
}

output "cloudfront_distribution_id" {
    description = "ID de la distribución de CloudFront"
    value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
    description = "Nombre de dominio de CloudFront"
    value       = module.cdn.cloudfront_domain_name
}

output "cloudfront_url" {
    description = "URL completa de CloudFront (punto de acceso principal)"
    value       = module.cdn.cloudfront_url
}

###################################################################
# STORAGE (S3) OUTPUTS
###################################################################

output "s3_info" {
    description = "Información completa del bucket S3"
    value = {
        bucket_name                    = module.storage.bucket_name
        bucket_arn                     = module.storage.bucket_arn
        bucket_regional_domain_name    = module.storage.bucket_regional_domain_name
        bucket_s3_url                  = module.storage.bucket_s3_url
        bucket_https_url               = module.storage.bucket_https_url
        cloudfront_oac_id              = module.storage.cloudfront_oac_id
        access_configuration           = module.storage.access_configuration
        vpc_endpoint_access            = true
        cloudfront_distribution_access = true
    }
}

output "s3_bucket_name" {
    description = "Nombre del bucket S3"
    value       = module.storage.bucket_name
}

output "s3_bucket_url" {
    description = "URL del bucket S3"
    value       = module.storage.bucket_s3_url
}

output "s3_integration_info" {
    description = "Información de integración de S3"
    value       = module.storage.integration_info
}

###################################################################
# ARQUITECTURA DE CONECTIVIDAD S3
###################################################################

output "s3_connectivity_flow" {
    description = "Flujo de conectividad hacia y desde S3"
    value = {
        ec2_to_s3 = {
            path        = "EC2 (Private Subnets) → VPC Endpoint → S3"
            method      = "AWS CLI/SDK via VPC Endpoint"
            network     = "Private (no internet required)"
            security    = "Bucket policy validates VPC Endpoint source"
            subnets     = module.vpc.private_subnet_ids
            vpc_endpoint = module.vpc_endpoints.s3_endpoint_id
        }
        s3_to_cloudfront = {
            path        = "S3 → CloudFront OAC → Global Distribution"
            method      = "Origin Access Control (OAC)"
            security    = "Bucket policy allows only CloudFront service"
            distribution = module.cdn.cloudfront_distribution_id
            oac_id      = module.storage.cloudfront_oac_id
        }
        users_to_content = {
            path        = "End Users → CloudFront → S3 (static) + API Gateway (dynamic)"
            static_content  = "S3 via CloudFront (HTML, CSS, JS, images)"
            dynamic_content = "API Gateway via CloudFront (/api/* paths)"
            cdn_url         = module.cdn.cloudfront_url
        }
    }
}

###################################################################
# DATABASE OUTPUTS
###################################################################

output "database_info" {
    description = "Información completa de la base de datos RDS"
    value = {
        endpoint            = module.database.db_instance_endpoint
        port               = module.database.db_instance_port
        database_name      = module.database.database_name
        instance_id        = module.database.db_instance_id
        multi_az           = module.database.db_instance_multi_az
        availability_zone  = module.database.db_instance_availability_zone
        engine             = module.database.engine
        engine_version     = module.database.engine_version
        instance_class     = module.database.instance_class
        allocated_storage  = module.database.allocated_storage
        storage_encrypted  = module.database.storage_encrypted
    }
    sensitive = false
}

output "database_connection_info" {
    description = "Información de conexión para aplicaciones"
    value = {
        host               = module.database.db_instance_address
        port               = module.database.db_instance_port
        database           = module.database.database_name
        jdbc_connection    = module.database.jdbc_connection_string
    }
    sensitive = false
}

output "database_security_info" {
    description = "Información de seguridad de la base de datos"
    value = {
        security_group_id    = module.database.db_security_group_id
        subnet_group_id      = module.database.db_subnet_group_id
        secrets_manager_arn  = module.database.secrets_manager_secret_arn
    }
    sensitive = false
}

output "database_monitoring_info" {
    description = "Información de monitoreo de la base de datos"
    value = {
        performance_insights_enabled = module.database.performance_insights_enabled
        monitoring_role_arn          = module.database.monitoring_role_arn
        cloudwatch_log_groups        = module.database.cloudwatch_log_groups
    }
    sensitive = false
}

# Output sensitivo para conexión completa (incluye credenciales)
output "database_connection_string" {
    description = "String de conexión completo (incluye credenciales)"
    value       = module.database.connection_string
    sensitive   = true
}

###################################################################
# COMPREHENSIVE PROJECT OUTPUT
###################################################################

output "project_summary" {
    description = "Resumen completo del proyecto Villa Alfredo"
    value = {
        project_name = var.project_name
        environment  = var.environment
        region       = var.aws_region
        vpc_id       = module.vpc.vpc_id
        
        # Punto de acceso principal (CloudFront)
        main_url = module.cdn.cloudfront_url
        
        # CloudFront CDN (múltiples orígenes)
        cloudfront = {
            distribution_id = module.cdn.cloudfront_distribution_id
            domain_name     = module.cdn.cloudfront_domain_name
            url            = module.cdn.cloudfront_url
            status         = module.cdn.cloudfront_status
            primary_origin = "S3 (static content)"
            secondary_origin = "API Gateway (dynamic content)"
            origins        = "S3 + API Gateway"
        }
        
        # S3 Storage (contenido estático)
        s3_storage = {
            bucket_name             = module.storage.bucket_name
            bucket_url              = module.storage.bucket_s3_url
            vpc_endpoint_access     = true
            cloudfront_integration  = true
            served_through          = "CloudFront CDN"
            access_method          = "VPC Endpoint (from EC2)"
        }
        
        # API Gateway (contenido dinámico)
        api_gateway = {
            url              = module.api_gateway.api_gateway_url
            stage_url        = "${module.api_gateway.api_gateway_url}/${module.api_gateway.api_gateway_stage_name}"
            connected_to_alb = module.alb.alb_dns_name
            connection_type  = "direct"
            served_through   = "CloudFront CDN (/api/* paths)"
        }
        
        # Application Load Balancer
        alb = {
            dns_name = module.alb.alb_dns_name
            url      = module.alb.alb_url
            subnets  = module.vpc.public_subnet_ids
        }
        
        # Configuración de capacidad
        capacity = {
            fixed_instances = 2
            additional_min  = module.compute.capacity_configuration.min_size
            additional_max  = module.compute.capacity_configuration.max_size
            total_min      = 2 + module.compute.capacity_configuration.min_size
            total_max      = 2 + module.compute.capacity_configuration.max_size
        }
        
        # Flujo de tráfico actualizado
        traffic_flow = "Users → CloudFront → [S3 (static) | API Gateway → ALB → EC2 (dynamic)]"
        storage_flow = "EC2 Instances → VPC Endpoint → S3 → CloudFront → Users"
        
        # Base de datos
        database = {
            endpoint       = module.database.db_instance_endpoint
            engine         = module.database.engine
            engine_version = module.database.engine_version
            multi_az       = module.database.db_instance_multi_az
            backup_retention = "7 días"
        }
        
        deployment_date = timestamp()
    }
}
