# Módulo Storage (S3) - Villa Alfredo

Este módulo configura el almacenamiento S3 para el proyecto Villa Alfredo, incluyendo la integración con VPC endpoints y CloudFront.

## Arquitectura

```
EC2 Instances (Private Subnets)
    ↓ (via VPC Endpoint)
S3 Bucket (Private)
    ↓ (via CloudFront OAC)
CloudFront Distribution
    ↓
End Users
```

## Componentes Principales

### 1. S3 Bucket
- **Bucket privado** con acceso público bloqueado
- **Encriptación AES256** habilitada por defecto
- **Versionado** configurable
- **Lifecycle policies** para optimización de costos

### 2. Seguridad
- **Origin Access Control (OAC)** para CloudFront
- **Bucket policy** que permite acceso solo desde:
  - VPC Endpoint (para instancias EC2)
  - CloudFront (usando OAC)
  - Roles específicos de EC2 (opcional)

### 3. Conectividad
- **VPC Endpoint**: Las instancias EC2 pueden acceder a S3 sin salir a internet
- **CloudFront**: Distribución global del contenido
- **CORS**: Configuración para aplicaciones web

## Variables de Configuración

### Obligatorias
- `project_name`: Nombre del proyecto
- `environment`: Ambiente (dev/staging/prod)
- `s3_vpc_endpoint_id`: ID del VPC endpoint para S3
- `cloudfront_distribution_arn`: ARN de CloudFront
- `vpc_id`: ID de la VPC
- `private_subnet_ids`: IDs de subredes privadas

### Opcionales
- `enable_versioning`: Habilitar versionado (default: true)
- `enable_lifecycle_policy`: Policies de lifecycle (default: true)
- `create_sample_files`: Crear archivos de ejemplo (default: false)
- `enable_cors`: Habilitar CORS (default: true)
- `ec2_instance_roles`: Roles adicionales para acceso

## Outputs Principales

- `bucket_name`: Nombre del bucket S3
- `bucket_arn`: ARN del bucket
- `cloudfront_oac_id`: ID del Origin Access Control
- `integration_info`: Información para integración con otros servicios

## Flujo de Datos

### Para EC2 → S3:
1. Las instancias EC2 en subredes privadas acceden a S3
2. El tráfico va a través del VPC Endpoint (sin internet)
3. La bucket policy valida que el acceso venga del VPC Endpoint
4. Se permite acceso a operaciones: GetObject, PutObject, DeleteObject, ListBucket

### Para S3 → CloudFront:
1. CloudFront usa Origin Access Control (OAC) para acceder a S3
2. La bucket policy permite acceso solo desde CloudFront específico
3. Los usuarios finales acceden al contenido via CloudFront (no directamente a S3)

## Seguridad

### Acceso Bloqueado
- ✅ Todo acceso público bloqueado
- ✅ Solo acceso via VPC Endpoint para EC2
- ✅ Solo acceso via OAC para CloudFront

### Encriptación
- ✅ AES256 server-side encryption
- ✅ Bucket key habilitado para reducir costos

### Lifecycle Management
- 30 días: Transición a Standard-IA
- 90 días: Transición a Glacier
- 365 días: Eliminación de versiones antiguas
- 7 días: Cleanup de uploads incompletos

## Uso desde EC2

Las instancias EC2 pueden usar AWS CLI o SDKs normalmente:

```bash
# Listar objetos
aws s3 ls s3://bucket-name/

# Subir archivo
aws s3 cp file.txt s3://bucket-name/

# Descargar archivo
aws s3 cp s3://bucket-name/file.txt ./
```

El tráfico automáticamente va por el VPC Endpoint.

## Integración con CloudFront

El bucket está configurado como origen de CloudFront con:
- Origin Access Control (OAC) para seguridad
- Distribución automática de contenido
- Cache configurado según el ambiente

## Monitoreo

El módulo incluye tags para:
- Identificación del proyecto y ambiente
- Seguimiento de costos
- Gestión de recursos

## Ejemplo de Uso

```hcl
module "storage" {
  source = "./modules/storage"
  
  project_name     = "villa-alfredo"
  environment      = "prod"
  
  s3_vpc_endpoint_id           = module.vpc_endpoints.s3_endpoint_id
  cloudfront_distribution_arn  = module.cdn.cloudfront_distribution_arn
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  
  enable_versioning        = true
  enable_lifecycle_policy  = true
  create_sample_files     = false
  
  tags = {
    CostCenter = "Infrastructure"
    Owner      = "DevOps Team"
  }
}
```
