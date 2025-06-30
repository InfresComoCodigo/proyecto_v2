# Módulo WAF para CloudFront

Este módulo crea un AWS WAF v2 Web ACL específicamente diseñado para proteger una distribución de CloudFront.

## Características

- **Reglas administradas por AWS**: Protección contra ataques comunes, SQL injection, y entradas maliciosas conocidas
- **Rate Limiting**: Protección contra ataques DDoS y abuso de API
- **Geo Blocking**: Bloqueo de países específicos
- **IP Filtering**: Lista negra y blanca de direcciones IP
- **User Agent Filtering**: Bloqueo de user agents específicos
- **Logging**: Integración con CloudWatch Logs
- **Métricas**: Monitoreo con CloudWatch Metrics

## Uso Básico

```hcl
module "waf" {
  source = "./modules/waf"
  
  project_name = "mi-proyecto"
  environment  = "prod"
  
  # Configuración básica
  enable_sql_injection_protection = true
  enable_rate_limiting           = true
  rate_limit_requests           = 2000
  
  # Bloqueo geográfico
  blocked_countries = ["CN", "RU", "KP"]
  
  # Tags
  tags = {
    Project     = "mi-proyecto"
    Environment = "prod"
    Owner       = "equipo-devops"
  }
}

# Asociar WAF con CloudFront
resource "aws_cloudfront_distribution" "example" {
  # ... otras configuraciones ...
  
  web_acl_id = module.waf.web_acl_id
  
  # ... resto de la configuración ...
}
```

## Uso Avanzado con IP Whitelist

```hcl
module "waf" {
  source = "./modules/waf"
  
  project_name = "mi-proyecto"
  environment  = "prod"
  
  # IP Whitelist - Solo estas IPs tendrán acceso
  allowed_ip_addresses = [
    "203.0.113.0/24",    # Oficina principal
    "198.51.100.50/32",  # IP específica
  ]
  
  # Configuración de logging
  enable_waf_logging  = true
  log_retention_days  = 90
  
  # Campos a ocultar en logs
  redacted_fields = [
    {
      type = "single_header"
      name = "authorization"
    },
    {
      type = "query_string"
    }
  ]
}
```

## Variables de Entrada

### Variables Requeridas

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `project_name` | `string` | Nombre del proyecto |
| `environment` | `string` | Entorno (dev, staging, prod) |

### Variables Opcionales

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Tags comunes |
| `enable_sql_injection_protection` | `bool` | `true` | Habilitar protección SQL injection |
| `enable_rate_limiting` | `bool` | `true` | Habilitar rate limiting |
| `rate_limit_requests` | `number` | `2000` | Requests máximos por IP/5min |
| `blocked_countries` | `list(string)` | `[]` | Países a bloquear (ISO 3166-1) |
| `allowed_countries` | `list(string)` | `[]` | Países permitidos (bloquea el resto) |
| `blocked_ip_addresses` | `list(string)` | `[]` | IPs a bloquear (CIDR) |
| `allowed_ip_addresses` | `list(string)` | `[]` | IPs permitidas (bloquea el resto) |
| `blocked_user_agents` | `list(string)` | `[]` | User agents a bloquear |
| `enable_cloudwatch_metrics` | `bool` | `true` | Habilitar métricas CloudWatch |
| `enable_sampled_requests` | `bool` | `true` | Habilitar muestreo de requests |
| `enable_waf_logging` | `bool` | `false` | Habilitar logging WAF |
| `log_retention_days` | `number` | `30` | Días retención logs |

## Outputs

| Output | Descripción |
|--------|-------------|
| `web_acl_id` | ID del WAF Web ACL |
| `web_acl_arn` | ARN del WAF Web ACL |
| `cloudfront_web_acl_arn` | ARN para usar en CloudFront |
| `waf_configuration` | Resumen de configuración |

## Consideraciones Importantes

### Región
- El WAF para CloudFront **DEBE** estar en la región `us-east-1`
- Asegúrate de que tu provider de AWS esté configurado para us-east-1

### Costos
- El WAF tiene costos por Web ACL, reglas y requests procesados
- Las reglas administradas de AWS tienen costos adicionales
- El logging en CloudWatch genera costos adicionales

### Límites
- Máximo 1,500 WCU (Web ACL Capacity Units) por Web ACL
- Cada regla consume WCU dependiendo de su complejidad

## Ejemplos de Códigos de País

| Código | País |
|--------|------|
| `US` | Estados Unidos |
| `CA` | Canadá |
| `MX` | México |
| `CN` | China |
| `RU` | Rusia |
| `KP` | Corea del Norte |
| `IR` | Irán |

## Monitoreo

El módulo crea métricas de CloudWatch automáticamente para:

- `CommonRuleSetMetric`: Reglas del conjunto común
- `KnownBadInputsRuleSetMetric`: Entradas maliciosas conocidas
- `SQLiRuleSetMetric`: Ataques SQL injection
- `RateLimitRuleMetric`: Rate limiting
- `GeoBlockingRuleMetric`: Bloqueo geográfico
- `IPBlockingRuleMetric`: Bloqueo de IPs

## Integración con Terraform

```hcl
# En tu configuración principal
module "waf" {
  source = "./modules/waf"
  
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

module "cdn" {
  source = "./modules/cdn"
  
  # ... otras variables ...
  
  # Asociar WAF
  web_acl_id = module.waf.web_acl_id
}
```
