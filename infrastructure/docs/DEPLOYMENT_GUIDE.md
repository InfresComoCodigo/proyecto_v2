# Deployment Guide - Villa Alfredo Infrastructure with S3 Integration

## Resumen de la Arquitectura

Su infraestructura ahora incluye:

### Flujo de Datos S3:
```
EC2 Instances (Private Subnets) 
    ↓ (VPC Endpoint - Private)
S3 Bucket (Private) 
    ↓ (Origin Access Control)
CloudFront Distribution
    ↓
Global Users
```

### Componentes Agregados:

1. **S3 Bucket** (`modules/storage/`)
   - Bucket privado con encriptación AES256
   - Acceso via VPC Endpoint desde EC2
   - Origin Access Control (OAC) para CloudFront
   - Lifecycle policies para optimización de costos

2. **CloudFront Dual Origin + WAF**
   - **Origen Principal**: S3 (contenido estático: HTML, CSS, JS, imágenes)
   - **Origen Secundario**: API Gateway (contenido dinámico: APIs)
   - **WAF Protection**: Protección automática contra ataques web
   - Cache behaviors inteligentes por tipo de contenido

3. **WAF (Web Application Firewall)**
   - Protección contra OWASP Top 10
   - Rate limiting inteligente  
   - Geo-blocking y filtrado por IP
   - Monitoreo con CloudWatch

4. **EC2 S3 Integration**
   - AWS CLI preconfigurado en las instancias
   - Scripts de prueba de conectividad
   - Scripts de upload a S3

## Pasos para el Deployment

### 1. Verificar Configuración
```bash
# Revisar variables
cat terraform.tfvars.example

# Verificar sintaxis
terraform validate
```

### 2. Plan del Deployment
```bash
terraform plan -out=tfplan
```

### 3. Ejecutar Deployment
```bash
terraform apply tfplan
```

### 4. Verificar Deployment
```bash
# Ver outputs importantes
terraform output s3_info
terraform output s3_connectivity_flow
terraform output project_summary
```

## Configuración por Ambiente

### Development (dev)
- S3: Sin lifecycle policies, archivos de ejemplo incluidos
- CloudFront: Sin cache (TTL = 0)
- Instancias: t2.micro

### Staging/Production
- S3: Lifecycle policies habilitadas, versionado activo
- CloudFront: Cache optimizado
- Monitoreo: CloudWatch habilitado

## Testing de S3 Integration

### Desde las instancias EC2:

1. **Conectar a las instancias** (si tienes key pair configurado):
```bash
# SSH a instancia en zona A
aws ec2 describe-instances --filters "Name=tag:Name,Values=*zone-a*" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text

# SSH a instancia en zona B  
aws ec2 describe-instances --filters "Name=tag:Name,Values=*zone-b*" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
```

2. **Probar conectividad S3**:
```bash
# Dentro de la instancia EC2
./test-s3-access.sh

# Ver logs de conectividad
tail -f /var/log/vpc-endpoint-test.log
```

3. **Upload test file a S3**:
```bash
# Crear archivo de prueba
echo "Hello from Villa Alfredo EC2!" > test-file.txt

# Configurar bucket name (obten el nombre real del output)
export S3_BUCKET_NAME="villa-alfredo-dev-content-xxxxxxxx"

# Subir archivo
./upload-to-s3.sh test-file.txt
```

### Desde CloudFront:

1. **Acceder al contenido via CDN**:
```bash
# Obtener URL de CloudFront
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
echo $CLOUDFRONT_URL

# Probar contenido estático (S3)
curl $CLOUDFRONT_URL/index.html

# Probar APIs (API Gateway)
curl $CLOUDFRONT_URL/api/health
```

2. **Probar protección WAF**:
```bash
# Ejecutar script de prueba del WAF
chmod +x scripts/test_waf.sh
./scripts/test_waf.sh

# Probar request normal (debe pasar)
curl -i https://your-cloudfront-domain.amazonaws.com/

# Probar SQL injection (debe ser bloqueado)
curl -i "https://your-cloudfront-domain.amazonaws.com/?id=1' OR '1'='1"

# Probar User Agent malicioso (debe ser bloqueado)
curl -i -H "User-Agent: BadBot" https://your-cloudfront-domain.amazonaws.com/
```

## Monitoreo y Logs

### CloudWatch Logs:
- `villa-alfredo-apache-access`: Logs de Apache
- `villa-alfredo-vpc-endpoints`: Tests de conectividad
- `villa-alfredo-api-gateway`: Logs de API Gateway
- `/aws/waf/villa-alfredo-dev-cloudfront`: Logs de WAF (si está habilitado)

### Métricas:
- **CloudFront**: Latencia, error rates, cache hit ratio
- **S3**: Requests, data transfer
- **VPC Endpoints**: Data processed
- **WAF**: Requests bloqueadas, tipos de ataques, rate limiting

### Dashboards Recomendados:
```bash
# Ver métricas de WAF en tiempo real
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=villa-alfredo-dev-cloudfront-waf \
  --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S') \
  --end-time $(date -u '+%Y-%m-%dT%H:%M:%S') \
  --period 300 --statistics Sum
```

## Costos Estimados (us-east-1)

### S3:
- Storage: $0.023/GB/mes (Standard)
- Requests: $0.0004/1K GET requests
- Data Transfer: Gratis a CloudFront

### CloudFront:
- Data Transfer: $0.085/GB (primeros 10TB)
- Requests: $0.0075/10K requests

### WAF:
- Web ACL: $1.00/mes
- Reglas (3): $3.00/mes  
- Requests: $0.60/millón de requests
- **Total WAF**: ~$8-15/mes para tráfico moderado

### VPC Endpoints:
- S3 Gateway: Gratis
- Interface Endpoints: $0.01/hora/endpoint

## Troubleshooting

### S3 Access Issues:
```bash
# Verificar bucket policy
aws s3api get-bucket-policy --bucket bucket-name

# Verificar VPC endpoint
aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.us-east-1.s3"
```

### CloudFront Issues:
```bash
# Ver distribución
aws cloudfront get-distribution --id DISTRIBUTION_ID

# Invalidar cache si es necesario
aws cloudfront create-invalidation --distribution-id DISTRIBUTION_ID --paths "/*"
```

### WAF Issues:
```bash
# Ver estado del WAF
aws wafv2 get-web-acl --scope CLOUDFRONT --id WAF_ID --region us-east-1

# Ver requests bloqueadas recientes
aws wafv2 get-sampled-requests \
  --web-acl-arn WAF_ARN \
  --rule-metric-name ALL \
  --scope CLOUDFRONT \
  --time-window StartTime=$(date -d '1 hour ago' +%s),EndTime=$(date +%s) \
  --max-items 100

# Si WAF está bloqueando tráfico legítimo
# 1. Revisar logs en CloudWatch
# 2. Ajustar reglas excluyendo false positives
# 3. Considerar cambiar reglas de BLOCK a COUNT temporalmente
```

## Siguientes Pasos

1. **Configurar dominio personalizado** para CloudFront
2. **Implementar CI/CD** para deployment automático a S3
3. **Configurar SSL certificate** en CloudFront
4. **Implementar backup strategy** para S3
5. **Configurar alertas** de CloudWatch
6. **Afinar reglas de WAF** basado en patrones de tráfico
7. **Implementar log analysis** para security insights
8. **Configurar auto-scaling** para las instancias EC2

## Configuración de WAF

Para personalizar las reglas de WAF:

1. **Modificar variables en terraform.tfvars**:
```hcl
# Bloquear países específicos
waf_blocked_countries = ["CN", "RU"]

# Configurar rate limiting
waf_rate_limit = 1000

# Habilitar logging detallado
waf_enable_logging = true
```

2. **Aplicar cambios**:
```bash
terraform plan -target=module.waf
terraform apply -target=module.waf
```

3. **Monitorear resultados**:
```bash
./scripts/test_waf.sh
```

Para más información detallada sobre WAF, consulta: `WAF_CONFIG.md`

## Cleanup

Para destruir la infraestructura:
```bash
# CUIDADO: Esto eliminará todo, incluyendo el contenido de S3
terraform destroy
```

Para preservar datos de S3:
```bash
# Hacer backup primero
aws s3 sync s3://bucket-name local-backup/

# Luego destruir
terraform destroy
```
