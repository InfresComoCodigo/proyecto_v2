# CloudFront CDN Module

Este módulo crea una distribución de CloudFront optimizada para servir como CDN para un API Gateway, proporcionando mejor rendimiento, menor latencia y capacidades de cache avanzadas.

## Características

- **Distribución CloudFront**: CDN global con edge locations en todo el mundo
- **Integración con API Gateway**: Configuración optimizada para APIs
- **Cache configurable**: TTLs y comportamientos de cache personalizables
- **Funciones Edge**: Manipulación de requests/responses en el edge
- **Monitoreo**: CloudWatch alarms para latencia y errores
- **SSL/TLS**: Soporte completo para certificados personalizados
- **Compresión**: Compresión automática de contenido
- **Restricciones geográficas**: Control de acceso por país

## Arquitectura

```
Internet → CloudFront Edge Locations → API Gateway → ALB → EC2 Instances
```

## Ventajas de usar CloudFront con API Gateway

1. **Mejor rendimiento**: Cache en edge locations reduce latencia
2. **Reducción de costos**: Menos calls directas al API Gateway
3. **DDoS protection**: Protección nativa contra ataques DDoS
4. **Compresión**: Compresión automática reduce transferencia de datos
5. **SSL termination**: Terminación SSL en el edge
6. **Funciones Edge**: Manipulación de headers y requests

## Variables requeridas

| Variable | Descripción | Tipo |
|----------|-------------|------|
| `project_name` | Nombre del proyecto | `string` |
| `environment` | Entorno (dev/staging/prod) | `string` |
| `api_gateway_domain_name` | Dominio del API Gateway | `string` |

## Variables opcionales principales

| Variable | Descripción | Default |
|----------|-------------|---------|
| `viewer_protocol_policy` | Política de protocolo | `"redirect-to-https"` |
| `cache_default_ttl` | TTL de cache por defecto | `86400` (24h) |
| `enable_compression` | Habilitar compresión | `true` |
| `price_class` | Clase de precios | `"PriceClass_100"` |
| `enable_monitoring` | Habilitar monitoring | `false` |

## Ejemplo de uso básico

```hcl
module "cdn" {
    source = "./modules/cdn"

    project_name              = "villa-alfredo"
    environment              = "prod"
    api_gateway_domain_name  = "abc123.execute-api.us-east-1.amazonaws.com"
    
    # Configuración de cache
    cache_default_ttl = 3600  # 1 hora
    cache_max_ttl     = 86400 # 24 horas
    
    # Habilitar compresión
    enable_compression = true
    
    tags = {
        Project     = "VillaAlfredo"
        Environment = "prod"
    }
}
```

## Ejemplo de uso avanzado

```hcl
module "cdn" {
    source = "./modules/cdn"

    project_name              = "villa-alfredo"
    environment              = "prod"
    api_gateway_domain_name  = "abc123.execute-api.us-east-1.amazonaws.com"
    
    # Configuración SSL personalizada
    ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/abc-123"
    domain_aliases      = ["api.midominio.com"]
    
    # Cache behaviors personalizados
    cache_behaviors = [
        {
            path_pattern           = "/api/static/*"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["GET", "HEAD"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 3600
            default_ttl           = 86400
            max_ttl               = 31536000
            forward_query_string  = false
            forward_headers       = ["Host"]
            forward_cookies       = "none"
            compress              = true
        }
    ]
    
    # Función Edge personalizada
    create_edge_function = true
    
    # Monitoreo
    enable_monitoring = true
    
    # Restricciones geográficas
    geo_restriction_type      = "whitelist"
    geo_restriction_locations = ["US", "CA", "MX"]
    
    tags = {
        Project     = "VillaAlfredo"
        Environment = "prod"
    }
}
```

## Cache Behaviors

El módulo permite configurar diferentes comportamientos de cache para distintas rutas:

- **APIs dinámicas** (`/api/users/*`): Cache corto o sin cache
- **Contenido estático** (`/static/*`): Cache largo
- **Contenido de autenticación** (`/auth/*`): Sin cache

## Funciones Edge

Las funciones Edge permiten:

- Agregar headers de seguridad
- Modificar requests antes de enviarlos al origen
- Implementar redirects
- Validación de headers

## Monitoreo

El módulo incluye alarmas de CloudWatch para:

- **Latencia del origen**: Alerta si la latencia supera el umbral
- **Tasa de errores**: Alerta si los errores 4xx superan el umbral

## Outputs principales

| Output | Descripción |
|--------|-------------|
| `cloudfront_domain_name` | Dominio de CloudFront |
| `cloudfront_url` | URL completa de CloudFront |
| `cloudfront_distribution_id` | ID de la distribución |
| `distribution_info` | Información completa |

## Configuración por ambiente

### Development
- TTL corto para development rápido
- Sin restricciones geográficas
- Logging básico

### Staging
- TTL medio para testing
- Monitoreo habilitado
- Funciones Edge para testing

### Production
- TTL optimizado para performance
- Certificado SSL personalizado
- Monitoreo completo
- Restricciones geográficas si aplica

## Consideraciones de costos

- **PriceClass_100**: Solo US, Canada y Europa (más económico)
- **PriceClass_200**: Agrega Asia, Australia y Brasil
- **PriceClass_All**: Todas las edge locations (más caro pero mejor rendimiento)

## Integración con Route 53

Si tienes un dominio personalizado:

```hcl
resource "aws_route53_record" "api" {
    zone_id = var.hosted_zone_id
    name    = "api.midominio.com"
    type    = "A"
    
    alias {
        name                   = module.cdn.cloudfront_domain_name
        zone_id                = module.cdn.cloudfront_hosted_zone_id
        evaluate_target_health = false
    }
}
```

## Mejores prácticas

1. **Cache headers**: Configura headers de cache apropiados en tu API
2. **Versioning**: Usa query parameters para invalidar cache
3. **Monitoring**: Habilita monitoring en producción
4. **SSL**: Siempre usa certificados SSL personalizados en producción
5. **Geo-restrictions**: Considera restricciones geográficas para seguridad
