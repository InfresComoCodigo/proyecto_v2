# Configuración de WAF para CloudFront

## Descripción

Este proyecto ahora incluye un módulo WAF (Web Application Firewall) que protege tu distribución de CloudFront contra ataques comunes, abuse y tráfico malicioso.

## ¿Qué es WAF?

AWS WAF v2 es un firewall de aplicaciones web que te ayuda a proteger tus aplicaciones web contra ataques comunes que pueden afectar la disponibilidad de la aplicación, comprometer la seguridad, o consumir recursos excesivos.

## Características Implementadas

### 🛡️ Protecciones Automáticas
- **Core Rule Set**: Protección contra OWASP Top 10 y ataques comunes
- **Known Bad Inputs**: Bloqueo de entradas maliciosas conocidas
- **SQL Injection Protection**: Prevención de ataques de inyección SQL

### 🚫 Control de Acceso
- **Rate Limiting**: Límite de requests por IP para prevenir DDoS
- **Geo Blocking**: Bloqueo por país
- **IP Filtering**: Lista negra y blanca de direcciones IP
- **User Agent Filtering**: Bloqueo de bots maliciosos

### 📊 Monitoreo y Logging
- **CloudWatch Metrics**: Métricas detalladas de tráfico y bloqueos
- **CloudWatch Logs**: Logs detallados de requests (opcional)
- **Sampled Requests**: Muestras de requests para análisis

## Configuración Actual

El WAF está configurado automáticamente con:

```hcl
# Configuración actual en main.tf
module "waf" {
  source = "./modules/waf"
  
  project_name = "villa-alfredo"
  environment  = "dev"
  
  # Protecciones habilitadas
  enable_sql_injection_protection = true
  enable_rate_limiting           = true
  rate_limit_requests           = 2000  # 1000 en producción
  
  # User Agents bloqueados
  blocked_user_agents = [
    "BadBot",
    "SuspiciousBot", 
    "MaliciousBot"
  ]
  
  # Monitoreo habilitado
  enable_cloudwatch_metrics = true
  enable_sampled_requests   = true
}
```

## Personalización

### 1. Bloqueo Geográfico

Para bloquear países específicos, agrega en tu `terraform.tfvars`:

```hcl
# Bloquear países específicos
waf_blocked_countries = ["CN", "RU", "KP", "IR"]
```

### 2. Filtrado por IP

```hcl
# Bloquear IPs específicas
waf_blocked_ips = [
  "203.0.113.0/24",
  "198.51.100.50/32"
]

# O usar whitelist (solo permitir estas IPs)
waf_allowed_ips = [
  "203.0.113.100/32",  # IP de la oficina
  "10.0.0.0/8"         # Red interna
]
```

### 3. Rate Limiting Personalizado

```hcl
# Ajustar límite de requests
waf_rate_limit = 1000  # Para ambientes de producción
```

### 4. Logging Detallado

```hcl
# Habilitar logging (cuidado con los costos)
waf_enable_logging = true
```

## Monitoreo

### Métricas Disponibles en CloudWatch

1. **CommonRuleSetMetric**: Ataques bloqueados por reglas comunes
2. **KnownBadInputsRuleSetMetric**: Entradas maliciosas detectadas
3. **SQLiRuleSetMetric**: Intentos de SQL injection
4. **RateLimitRuleMetric**: IPs bloqueadas por rate limiting
5. **GeoBlockingRuleMetric**: Requests bloqueadas por país
6. **IPBlockingRuleMetric**: IPs específicas bloqueadas

### Dashboards Recomendados

Crea un dashboard en CloudWatch con:
- Requests totales vs bloqueadas
- Top países/IPs bloqueadas
- Tipos de ataques detectados
- Rate limiting activations

## Costos

### Estructura de Costos de WAF

- **Web ACL**: $1.00 USD por mes por Web ACL
- **Reglas**: $1.00 USD por mes por regla
- **Requests**: $0.60 USD por millón de requests
- **Reglas Administradas**: $1.00 USD por mes por grupo de reglas + $0.25 USD por millón de requests

### Estimación para este Proyecto

Para un sitio con **1 millón de requests/mes**:
- Web ACL: $1.00
- Reglas (3): $3.00  
- Requests: $0.60
- Reglas administradas (3 grupos): $3.75
- **Total aproximado: $8.35 USD/mes**

## Troubleshooting

### WAF Bloqueando Tráfico Legítimo

1. **Revisar métricas** en CloudWatch
2. **Analizar sampled requests** para ver qué está siendo bloqueado
3. **Ajustar reglas** excluyendo reglas específicas:

```hcl
excluded_common_rules = [
  "SizeRestrictions_BODY",  # Si necesitas bodies grandes
  "GenericRFI_BODY"        # Si tienes false positives
]
```

### Performance Issues

1. **Verificar WCU usage** (max 1,500 WCU por Web ACL)
2. **Simplificar reglas** si es necesario
3. **Revisar rate limiting** si es muy restrictivo

### Logs No Aparecen

1. Verificar que `enable_waf_logging = true`
2. Verificar permisos de CloudWatch
3. Logs aparecen en `/aws/waf/[project-name]-[environment]-cloudfront`

## Comandos Útiles

### Ver estado del WAF
```bash
# Ver Web ACL
terraform show | grep waf

# Ver métricas en tiempo real
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

### Actualizar reglas
```bash
# Planificar cambios
terraform plan -target=module.waf

# Aplicar solo cambios de WAF
terraform apply -target=module.waf
```

## Mejores Prácticas

1. **Empezar en modo COUNT** para nuevas reglas antes de BLOCK
2. **Monitorear false positives** durante las primeras semanas
3. **Ajustar rate limiting** basado en patrones de tráfico reales
4. **Revisar logs regularmente** para detectar nuevas amenazas
5. **Mantener whitelist** de IPs críticas si es necesario

## Próximos Pasos

1. **Monitoring**: Crear alertas en CloudWatch para bloqueos inusuales
2. **Automation**: Implementar reglas dinámicas basadas en threat intelligence
3. **Integration**: Conectar con sistemas SIEM para análisis avanzado
4. **Tuning**: Ajustar reglas basado en patrones de tráfico específicos

## Soporte

Para problemas con WAF:
1. Revisar logs de CloudWatch
2. Verificar métricas de WAF
3. Consultar documentación de AWS WAF v2
4. Contactar al equipo de infraestructura

---

**Nota**: Este WAF está optimizado para CloudFront y debe residir en la región `us-east-1`. Los cambios en el WAF pueden tomar varios minutos en propagarse a través de la red global de CloudFront.
