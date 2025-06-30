# API Gateway Module

Este módulo crea un API Gateway que se conecta directamente con un Application Load Balancer (ALB) público.

## Arquitectura

```
Internet -> API Gateway -> ALB Público -> EC2 Instances
```

## Características

- **Conexión directa**: API Gateway se conecta directamente al ALB público sin usar VPC Link
- **Regional API**: Configurado como API Gateway regional para menor latencia
- **Proxy completo**: Captura todas las rutas con `{proxy+}` y las reenvía al ALB
- **Logging**: CloudWatch logging habilitado por defecto
- **Throttling**: Configuración de rate limiting ajustable

## Ventajas de la conexión directa

1. **Simplicidad**: No requiere VPC Link ni configuraciones complejas de red
2. **Menor latencia**: Conexión directa sin saltos adicionales
3. **Menos costos**: No hay cargos por VPC Link
4. **Fácil troubleshooting**: Menos componentes en la cadena de conexión

## Variables requeridas

- `project_name`: Nombre del proyecto
- `environment`: Entorno (dev, staging, prod)
- `alb_dns_name`: DNS name del ALB público

## Variables opcionales

- `api_gateway_type`: Tipo de API Gateway (REGIONAL por defecto)
- `stage_name`: Nombre del stage (api por defecto)
- `throttle_rate_limit`: Límite de rate (1000 por defecto)
- `throttle_burst_limit`: Límite de burst (2000 por defecto)
- `enable_logging`: Habilitar logging (true por defecto)
- `log_level`: Nivel de logging (INFO por defecto)

## Outputs principales

- `api_gateway_url`: URL pública del API Gateway
- `api_gateway_id`: ID del API Gateway
- `api_gateway_arn`: ARN del API Gateway

## Ejemplo de uso

```hcl
module "api_gateway" {
    source = "./modules/api_gateway"

    project_name = "villa-alfredo"
    environment  = "prod"
    alb_dns_name = "villa-alfredo-prod-alb-123456789.us-east-1.elb.amazonaws.com"
    
    api_gateway_type = "REGIONAL"
    stage_name       = "api"
    enable_logging   = true
    
    tags = {
        Project     = "VillaAlfredo"
        Environment = "prod"
    }
}
```

Este módulo crea un API Gateway REST que se conecta al Application Load Balancer (ALB) a través de un VPC Link, proporcionando una interfaz pública para acceder a las aplicaciones privadas.

## Características

- **API Gateway REST**: API Gateway con endpoints configurados para proxy hacia el ALB
- **VPC Link**: Conexión privada entre API Gateway y ALB sin exposición a internet
- **Throttling**: Control de tasa de peticiones configurable por ambiente
- **Logging**: Logs detallados en CloudWatch con configuración por ambiente
- **Proxy Integration**: Reenvío transparente de todas las rutas hacia el ALB
- **Security Groups**: Configuración de seguridad específica para VPC Link

## Arquitectura

```
Internet → API Gateway → VPC Link → ALB → EC2 Instances
```

## Recursos Creados

1. **aws_api_gateway_rest_api**: API REST principal
2. **aws_api_gateway_vpc_link**: Conexión privada al ALB
3. **aws_api_gateway_resource**: Recurso proxy para capturar todas las rutas
4. **aws_api_gateway_method**: Métodos HTTP (ANY) para proxy
5. **aws_api_gateway_integration**: Integración HTTP_PROXY con el ALB
6. **aws_api_gateway_deployment**: Despliegue del API
7. **aws_api_gateway_stage**: Stage para el API
8. **aws_cloudwatch_log_group**: Grupo de logs para monitoreo

## Variables

- `project_name`: Nombre del proyecto
- `environment`: Ambiente (dev/staging/prod)
- `alb_dns_name`: DNS del ALB target
- `vpc_id`: ID de la VPC
- `private_subnet_ids`: IDs de subredes privadas
- `security_group_id`: Security group para VPC Link
- `api_gateway_type`: Tipo de API Gateway (REGIONAL/EDGE)
- `stage_name`: Nombre del stage
- `throttle_rate_limit`: Límite de peticiones por segundo
- `throttle_burst_limit`: Límite de burst
- `enable_logging`: Habilitar logging
- `log_level`: Nivel de logs (ERROR/INFO)

## Outputs

- `api_gateway_url`: URL pública del API Gateway
- `vpc_link_id`: ID del VPC Link
- `api_gateway_info`: Información completa del API Gateway

## Configuración por Ambiente

### Development
- Rate limit: 100 req/s
- Burst limit: 200 req/s
- Log level: ERROR

### Staging
- Rate limit: 500 req/s
- Burst limit: 1000 req/s
- Log level: INFO

### Production
- Rate limit: 1000 req/s
- Burst limit: 2000 req/s
- Log level: INFO

## Uso

El API Gateway actúa como un proxy transparente hacia el ALB. Todas las rutas y métodos HTTP son reenviados automáticamente:

- `GET /` → ALB
- `GET /api/users` → ALB
- `POST /api/data` → ALB
- etc.

## Monitoreo

Los logs se almacenan en CloudWatch bajo el grupo:
`/aws/apigateway/{project_name}-{environment}`

Las métricas incluyen:
- Número de peticiones
- Latencia
- Errores 4xx/5xx
- Throttling

## Dominio Personalizado

Para usar un dominio personalizado, descomenta las secciones correspondientes en `main.tf` y proporciona:
- Nombre del dominio
- ARN del certificado SSL (ACM)
