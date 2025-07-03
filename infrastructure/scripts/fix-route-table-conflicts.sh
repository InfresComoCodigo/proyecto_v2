#!/bin/bash

# Script para resolver específicamente el conflicto de route table
# RouteAlreadyExists: route table rtb-0356aef4072409fa5 already has a route with destination-prefix-list-id pl-63a5400a

set -e

echo "🔧 Script de Resolución de Conflictos Route Table"
echo "================================================="

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

# Variables específicas del error
ROUTE_TABLE_ID="rtb-0356aef4072409fa5"
PREFIX_LIST_ID="pl-63a5400a"

# Verificar que estamos en el directorio correcto
if [ ! -f "terraform.tfvars" ]; then
    log_error "No se encontró terraform.tfvars. Ejecuta desde el directorio infrastructure/"
    exit 1
fi

log_info "Iniciando diagnóstico específico del conflicto de route table..."

# 1. Verificar el estado actual de la route table problemática
log_info "Verificando route table problemática: $ROUTE_TABLE_ID"

if aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" &>/dev/null; then
    log_success "Route table encontrada en AWS"
    
    # Mostrar rutas actuales
    log_info "Rutas actuales en la route table:"
    aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" \
        --query 'RouteTables[0].Routes[]' \
        --output table
    
    # Verificar la ruta específica problemática
    log_info "Verificando ruta específica con prefix list $PREFIX_LIST_ID"
    PROBLEMATIC_ROUTE=$(aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" \
        --query "RouteTables[0].Routes[?DestinationPrefixListId=='$PREFIX_LIST_ID']" \
        --output json)
    
    if [ "$PROBLEMATIC_ROUTE" != "[]" ] && [ -n "$PROBLEMATIC_ROUTE" ]; then
        log_warning "Ruta problemática encontrada:"
        echo "$PROBLEMATIC_ROUTE"
        
        # Verificar si es de un VPC endpoint
        VPC_ENDPOINT_ID=$(echo "$PROBLEMATIC_ROUTE" | grep -o '"VpcEndpointId":"[^"]*"' | sed 's/"VpcEndpointId":"//; s/"//' | head -1)
        
        if [ -n "$VPC_ENDPOINT_ID" ]; then
            log_info "Ruta asociada a VPC endpoint: $VPC_ENDPOINT_ID"
            
            # Verificar detalles del VPC endpoint
            log_info "Detalles del VPC endpoint:"
            aws ec2 describe-vpc-endpoints --vpc-endpoint-ids "$VPC_ENDPOINT_ID" \
                --query 'VpcEndpoints[0].{Id:VpcEndpointId,Service:ServiceName,State:State,RouteTableIds:RouteTableIds}' \
                --output table
        fi
    else
        log_success "No se encontró la ruta problemática en AWS"
    fi
else
    log_error "Route table no encontrada en AWS"
fi

# 2. Verificar recursos relacionados en el estado de Terraform
log_info "Verificando recursos en estado de Terraform..."

# Listar VPC endpoints
log_info "VPC endpoints en estado:"
terraform state list | grep -E "aws_vpc_endpoint" || log_warning "No hay VPC endpoints en estado"

# Listar route table associations
log_info "Route table associations en estado:"
terraform state list | grep -E "aws_vpc_endpoint_route_table_association" || log_warning "No hay associations en estado"

# 3. Intentar resolver el conflicto
log_info "Iniciando proceso de resolución..."

# Paso 1: Refrescar estado para sincronizar con AWS
log_info "Refrescando estado de Terraform..."
terraform refresh -var-file=terraform.tfvars

# Paso 2: Identificar recursos conflictivos
log_info "Identificando recursos conflictivos..."
CONFLICTING_RESOURCES=$(terraform state list | grep -E "aws_vpc_endpoint.*s3|aws_vpc_endpoint_route_table_association" || true)

if [ -n "$CONFLICTING_RESOURCES" ]; then
    log_warning "Recursos potencialmente conflictivos encontrados:"
    echo "$CONFLICTING_RESOURCES"
    
    # Preguntar al usuario si proceder
    read -p "¿Deseas eliminar estos recursos del estado para resolver el conflicto? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Eliminando recursos conflictivos del estado..."
        
        echo "$CONFLICTING_RESOURCES" | while read resource; do
            if [ -n "$resource" ]; then
                log_info "Eliminando: $resource"
                terraform state rm "$resource" || log_warning "No se pudo eliminar: $resource"
            fi
        done
        
        log_success "Recursos eliminados del estado"
    else
        log_info "Operación cancelada por el usuario"
    fi
else
    log_info "No se encontraron recursos conflictivos obvios"
fi

# Paso 3: Verificar si hay VPC endpoints huérfanos en AWS
log_info "Verificando VPC endpoints huérfanos..."
ALL_VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=service-name,Values=com.amazonaws.*.s3" \
    --query 'VpcEndpoints[].VpcEndpointId' \
    --output text)

if [ -n "$ALL_VPC_ENDPOINTS" ]; then
    log_info "VPC endpoints S3 encontrados en AWS:"
    for endpoint in $ALL_VPC_ENDPOINTS; do
        echo "  - $endpoint"
        
        # Verificar si está en el estado de Terraform
        if terraform state list | grep -q "$endpoint"; then
            log_info "    ✅ Presente en estado de Terraform"
        else
            log_warning "    ⚠️  Huérfano (no está en estado de Terraform)"
        fi
    done
fi

# Paso 4: Regenerar plan
log_info "Regenerando plan de Terraform..."
terraform plan -out=tfplan-fix -var-file=terraform.tfvars

# Paso 5: Verificar el plan
log_info "Verificando el plan generado..."
terraform show tfplan-fix | grep -E "aws_vpc_endpoint|route_table" || log_info "No hay cambios relacionados con VPC endpoints"

log_success "Proceso de diagnóstico y resolución completado"
log_info "Puedes proceder con 'terraform apply tfplan-fix' si el plan se ve correcto"

# Opcional: Mostrar comando sugerido
echo ""
log_info "Comandos sugeridos para continuar:"
echo "1. Revisar el plan: terraform show tfplan-fix"
echo "2. Aplicar cambios: terraform apply tfplan-fix"
echo "3. Si persisten errores, ejecutar: terraform import [resource] [id]"
