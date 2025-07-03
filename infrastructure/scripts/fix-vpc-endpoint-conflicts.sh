#!/bin/bash

# Script para resolver conflictos de VPC Endpoints S3
# Autor: DevOps Team
# Fecha: $(date)

set -e

echo "🔧 Script de Resolución de Conflictos VPC Endpoint S3"
echo "=================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "terraform.tfvars" ]; then
    log_error "No se encontró terraform.tfvars. Ejecuta desde el directorio infrastructure/"
    exit 1
fi

log_info "Iniciando diagnóstico de VPC Endpoints..."

# 1. Obtener información del VPC actual
log_info "Obteniendo información del VPC..."

# Usar terraform show con grep en lugar de jq
VPC_ID=$(terraform show -json 2>/dev/null | grep -o '"id":"vpc-[^"]*"' | head -1 | sed 's/"id":"//; s/"//')

if [ -z "$VPC_ID" ]; then
    # Método alternativo usando terraform state
    VPC_ID=$(terraform state show module.vpc.aws_vpc.main 2>/dev/null | grep "^id" | awk '{print $3}' | tr -d '"')
fi

if [ -z "$VPC_ID" ]; then
    log_error "No se pudo obtener el VPC ID del estado de Terraform"
    log_info "Intentando obtener VPC ID de los outputs..."
    VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
fi

if [ -z "$VPC_ID" ]; then
    log_error "No se pudo obtener el VPC ID de ninguna fuente"
    exit 1
fi

log_success "VPC ID encontrado: $VPC_ID"

# 2. Listar VPC endpoints existentes
log_info "Listando VPC endpoints existentes..."
aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.us-east-1.s3" \
    --output table 2>/dev/null || log_warning "No se pudieron listar VPC endpoints"

# 3. Obtener VPC endpoints S3 existentes
S3_ENDPOINTS=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=service-name,Values=com.amazonaws.us-east-1.s3" \
    --output text --query 'VpcEndpoints[].VpcEndpointId' 2>/dev/null || echo "")

if [ ! -z "$S3_ENDPOINTS" ]; then
    log_warning "VPC Endpoints S3 existentes encontrados:"
    for endpoint in $S3_ENDPOINTS; do
        echo "  - $endpoint"
    done
    
    # 4. Verificar rutas asociadas
    log_info "Verificando rutas asociadas..."
    aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --output table 2>/dev/null || log_warning "No se pudieron verificar rutas"
    
    # 5. Ofrecer opciones de resolución
    echo ""
    log_warning "OPCIONES DE RESOLUCIÓN:"
    echo "1. Importar VPC endpoint existente al estado de Terraform"
    echo "2. Eliminar VPC endpoint existente y crear uno nuevo"
    echo "3. Remover del estado y aplicar plan limpio"
    echo ""
    
    read -p "Selecciona una opción (1-3): " OPTION
    
    case $OPTION in
        1)
            log_info "Opción 1: Importando VPC endpoint existente..."
            for endpoint in $S3_ENDPOINTS; do
                log_info "Importando endpoint: $endpoint"
                terraform import module.vpc_endpoints.aws_vpc_endpoint.s3 $endpoint || log_warning "Error al importar $endpoint"
            done
            ;;
        2)
            log_info "Opción 2: Eliminando VPC endpoints existentes..."
            for endpoint in $S3_ENDPOINTS; do
                log_warning "Eliminando endpoint: $endpoint"
                aws ec2 delete-vpc-endpoint --vpc-endpoint-id $endpoint
                log_success "Endpoint $endpoint eliminado"
            done
            log_info "Esperando 30 segundos para que se propague la eliminación..."
            sleep 30
            ;;
        3)
            log_info "Opción 3: Removiendo del estado de Terraform..."
            terraform state rm module.vpc_endpoints.aws_vpc_endpoint.s3 || log_warning "No se pudo remover del estado"
            ;;
        *)
            log_error "Opción inválida"
            exit 1
            ;;
    esac
else
    log_success "No se encontraron VPC endpoints S3 conflictivos"
fi

# 6. Verificar estado después de la resolución
log_info "Verificando estado después de la resolución..."
terraform refresh -var-file=terraform.tfvars

# 7. Generar nuevo plan
log_info "Generando nuevo plan..."
terraform plan -out=tfplan-fixed -var-file=terraform.tfvars

log_success "Resolución completada. Revisa el plan y ejecuta: terraform apply tfplan-fixed"

# 8. Mostrar resumen
echo ""
log_info "RESUMEN DE ACCIONES:"
echo "==================="
echo "- VPC ID: $VPC_ID"
echo "- Acción realizada: Opción $OPTION"
echo "- Nuevo plan generado: tfplan-fixed"
echo "- Siguiente paso: terraform apply tfplan-fixed"
echo ""
log_success "Script completado exitosamente"
