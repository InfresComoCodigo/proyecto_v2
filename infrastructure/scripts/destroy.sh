#!/bin/bash

###################################################################
# SCRIPT DE DESTRUCCIÓN SEGURA DE INFRAESTRUCTURA
# Este script destruye la infraestructura de manera controlada
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

# Banner de advertencia
echo -e "${RED}"
echo "###################################################################"
echo "#                      ⚠️  ADVERTENCIA  ⚠️                      #"
echo "#              DESTRUCCIÓN DE INFRAESTRUCTURA                    #"
echo "#                                                                 #"
echo "#  Esta acción eliminará TODOS los recursos de AWS               #"
echo "#  incluyendo la base de datos y todos los datos                 #"
echo "###################################################################"
echo -e "${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "main.tf" ] || [ ! -f "provider.tf" ]; then
    error "Este script debe ejecutarse desde el directorio raíz del proyecto Terraform"
    exit 1
fi

# Verificar si terraform está instalado
if ! command -v terraform &> /dev/null; then
    error "Terraform no está instalado."
    exit 1
fi

# Verificar si hay un estado de Terraform
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    warning "No se encontró estado de Terraform. No hay infraestructura que destruir."
    exit 0
fi

# Leer información del estado actual
if [ -f "terraform.tfvars" ]; then
    PROJECT_NAME=$(grep 'project_name' terraform.tfvars | cut -d'"' -f2 || echo "aventuraxtremo")
    ENVIRONMENT=$(grep 'environment' terraform.tfvars | cut -d'"' -f2 || echo "dev")
else
    PROJECT_NAME="aventuraxtremo"
    ENVIRONMENT="unknown"
fi

log "Preparando destrucción de: $PROJECT_NAME ($ENVIRONMENT)"

# Mostrar recursos que serán destruidos
log "Generando plan de destrucción..."
terraform plan -destroy

echo ""
warning "=== RECURSOS QUE SERÁN ELIMINADOS ==="
warning "• Base de datos RDS MySQL (incluyendo todos los datos)"
warning "• Instancias EC2 y Auto Scaling Groups"
warning "• Load Balancers y Target Groups"
warning "• API Gateway y configuraciones"
warning "• CloudFront Distribution"
warning "• S3 Buckets (con todos los archivos)"
warning "• VPC y componentes de red"
warning "• Security Groups y NACLs"
warning "• CloudWatch Logs y métricas"
warning "• Secretos en Secrets Manager"
warning "• Roles y políticas de IAM"
warning "• Certificados SSL/TLS"
echo ""

if [ "$ENVIRONMENT" = "prod" ]; then
    error "⚠️  AMBIENTE DE PRODUCCIÓN DETECTADO ⚠️"
    echo ""
    echo "Estás a punto de destruir un ambiente de PRODUCCIÓN."
    echo "Esto eliminará:"
    echo "• Todos los datos de la base de datos de producción"
    echo "• Todo el contenido del sitio web"
    echo "• Todas las configuraciones de usuarios"
    echo "• Historiales de transacciones y reservas"
    echo ""
    warning "Esta acción es IRREVERSIBLE"
    echo ""
    
    # Doble confirmación para producción
    read -p "Escribir 'DELETE PRODUCTION' para confirmar: " confirm_prod
    if [ "$confirm_prod" != "DELETE PRODUCTION" ]; then
        log "Destrucción cancelada - confirmación incorrecta"
        exit 0
    fi
fi

echo ""
read -p "¿Estás COMPLETAMENTE SEGURO de que quieres eliminar toda la infraestructura? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log "Destrucción cancelada por el usuario"
    exit 0
fi

echo ""
read -p "Esta es tu ÚLTIMA OPORTUNIDAD para cancelar. ¿Continuar? (yes/no): " final_confirm
if [ "$final_confirm" != "yes" ]; then
    log "Destrucción cancelada por el usuario"
    exit 0
fi

# Crear backup del estado antes de destruir
log "Creando backup del estado de Terraform..."
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp terraform.tfstate "$BACKUP_DIR/" 2>/dev/null || true
cp terraform.tfstate.backup "$BACKUP_DIR/" 2>/dev/null || true
cp terraform.tfvars "$BACKUP_DIR/" 2>/dev/null || true
success "Backup creado en: $BACKUP_DIR"

# Ejecutar destrucción
log "Iniciando destrucción de infraestructura..."
echo ""
warning "No interrumpas este proceso una vez iniciado"
echo ""

# Contar hacia atrás
for i in {5..1}; do
    echo -ne "${RED}Iniciando destrucción en $i segundos...\r${NC}"
    sleep 1
done
echo ""

# Destruir infraestructura
log "Ejecutando terraform destroy..."
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    success "¡Infraestructura destruida exitosamente!"
    echo ""
    info "=== LIMPIEZA COMPLETADA ==="
    info "• Todos los recursos de AWS han sido eliminados"
    info "• El estado local de Terraform se ha limpiado"
    info "• Backup guardado en: $BACKUP_DIR"
    echo ""
    
    # Limpiar archivos locales opcionales
    read -p "¿Eliminar también archivos locales de Terraform? (.terraform/, *.tfstate*) (y/n): " clean_local
    if [ "$clean_local" = "y" ] || [ "$clean_local" = "Y" ]; then
        log "Limpiando archivos locales..."
        rm -rf .terraform/
        rm -f terraform.tfstate*
        rm -f .terraform.lock.hcl
        success "Archivos locales eliminados"
    fi
    
    echo ""
    warning "RECORDATORIO:"
    echo "• Verificar en la consola de AWS que no queden recursos huérfanos"
    echo "• Revisar CloudWatch Logs por logs que no se eliminen automáticamente"
    echo "• Verificar S3 buckets por versiones de objetos"
    echo "• Comprobar que no haya cargos inesperados en la facturación"
    
else
    error "Error durante la destrucción de la infraestructura"
    echo ""
    warning "Posibles problemas:"
    echo "• Recursos con protection habilitada"
    echo "• Dependencias que impiden eliminación"
    echo "• Permisos insuficientes"
    echo ""
    echo "Revisar los errores arriba y ejecutar terraform destroy manualmente si es necesario"
    exit 1
fi

log "Script de destrucción completado"
