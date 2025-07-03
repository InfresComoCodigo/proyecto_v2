#!/bin/bash

###################################################################
# SCRIPT DE DESPLIEGUE DE INFRAESTRUCTURA AVENTURA XTREMO
# Este script automatiza el despliegue de la infraestructura completa
###################################################################

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Banner
echo -e "${GREEN}"
echo "###################################################################"
echo "#                    AVENTURA XTREMO                            #"
echo "#              DESPLIEGUE DE INFRAESTRUCTURA                     #"
echo "###################################################################"
echo -e "${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "main.tf" ] || [ ! -f "provider.tf" ]; then
    error "Este script debe ejecutarse desde el directorio raíz del proyecto Terraform"
    exit 1
fi

# Verificar si terraform está instalado
if ! command -v terraform &> /dev/null; then
    error "Terraform no está instalado. Por favor instalar terraform primero."
    exit 1
fi

# Verificar si AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS CLI no está configurado. Por favor configurar las credenciales de AWS."
    exit 1
fi

log "Verificación de prerequisitos completada"

# Mostrar información del usuario AWS
AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
info "Usuario AWS: $AWS_USER"
info "Región AWS: $AWS_REGION"

# Verificar archivo de variables
if [ ! -f "terraform.tfvars" ]; then
    warning "No se encontró terraform.tfvars"
    echo ""
    echo "Pasos para crear terraform.tfvars:"
    echo "1. Copiar terraform.tfvars.example a terraform.tfvars"
    echo "2. Editar terraform.tfvars con tus valores específicos"
    echo "3. Asegurarse de configurar db_password con una contraseña segura"
    echo ""
    read -p "¿Quieres crear terraform.tfvars ahora desde el ejemplo? (y/n): " create_tfvars
    
    if [ "$create_tfvars" = "y" ] || [ "$create_tfvars" = "Y" ]; then
        cp terraform.tfvars.example terraform.tfvars
        warning "Archivo terraform.tfvars creado. DEBES editarlo antes de continuar."
        echo ""
        echo "Valores críticos que DEBES configurar:"
        echo "- db_password: Contraseña segura para la base de datos"
        echo "- project_name: Nombre de tu proyecto"
        echo "- environment: dev, staging o prod"
        echo ""
        read -p "Presiona Enter después de editar terraform.tfvars..."
    else
        error "No se puede continuar sin terraform.tfvars"
        exit 1
    fi
fi

# Leer variables del archivo terraform.tfvars
PROJECT_NAME=$(grep 'project_name' terraform.tfvars | cut -d'"' -f2 || echo "aventuraxtremo")
ENVIRONMENT=$(grep 'environment' terraform.tfvars | cut -d'"' -f2 || echo "dev")

log "Iniciando despliegue para: $PROJECT_NAME ($ENVIRONMENT)"

# Inicializar Terraform
log "Inicializando Terraform..."
terraform init

# Validar configuración
log "Validando configuración de Terraform..."
terraform validate

# Mostrar plan de ejecución
log "Generando plan de ejecución..."
terraform plan -out=tfplan

echo ""
info "=== RESUMEN DEL DESPLIEGUE ==="
info "Proyecto: $PROJECT_NAME"
info "Ambiente: $ENVIRONMENT"
info "Región: $AWS_REGION"
echo ""
warning "Recursos que se crearán:"
echo "- VPC con subredes públicas y privadas"
echo "- RDS MySQL Multi-AZ en red privada"
echo "- Application Load Balancer"
echo "- Auto Scaling Group con instancias EC2"
echo "- API Gateway con Cognito Auth"
echo "- CloudFront CDN"
echo "- S3 Bucket"
echo "- WAF para seguridad"
echo "- CloudWatch para monitoreo"
echo ""

read -p "¿Continuar con el despliegue? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log "Despliegue cancelado por el usuario"
    exit 0
fi

# Aplicar configuración
log "Aplicando configuración de Terraform..."
terraform apply tfplan

if [ $? -eq 0 ]; then
    success "¡Infraestructura desplegada exitosamente!"
    echo ""
    
    # Obtener outputs importantes
    log "Obteniendo información de la infraestructura..."
    
    DB_ENDPOINT=$(terraform output -raw database_info | jq -r '.endpoint' 2>/dev/null || echo "No disponible")
    CDN_URL=$(terraform output -raw project_summary | jq -r '.cloudfront.url' 2>/dev/null || echo "No disponible")
    API_URL=$(terraform output -raw project_summary | jq -r '.api_gateway.url' 2>/dev/null || echo "No disponible")
    
    echo ""
    info "=== INFORMACIÓN DE ACCESO ==="
    info "CDN URL: $CDN_URL"
    info "API Gateway URL: $API_URL"
    info "Base de datos endpoint: $DB_ENDPOINT"
    echo ""
    
    # Información para conectar a la base de datos
    if [ "$DB_ENDPOINT" != "No disponible" ]; then
        info "=== CONFIGURACIÓN DE BASE DE DATOS ==="
        info "Para inicializar la base de datos con los esquemas SQL:"
        echo ""
        echo "1. Obtener la contraseña desde Secrets Manager:"
        echo "   aws secretsmanager get-secret-value --secret-id $PROJECT_NAME/rds/mysql/credentials"
        echo ""
        echo "2. Ejecutar el script de inicialización:"
        echo "   ./scripts/init_database.sh $DB_ENDPOINT 3306 admin [PASSWORD] iac"
        echo ""
        echo "3. O conectarse manualmente:"
        echo "   mysql -h $DB_ENDPOINT -P 3306 -u admin -p iac"
        echo ""
    fi
    
    warning "IMPORTANTE: Guardar esta información en un lugar seguro"
    
    # Limpiar archivos temporales
    rm -f tfplan
    
else
    error "Error durante el despliegue de la infraestructura"
    exit 1
fi

log "Script de despliegue completado"
