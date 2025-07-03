#!/bin/bash

###################################################################
# Script de Prueba - Cognito + API Gateway Integration
# 
# Este script prueba la configuración de autenticación con Cognito
# y los endpoints del API Gateway
###################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${GREEN}>>> $1${NC}"
}

# Verificar que terraform esté disponible
if ! command -v terraform &> /dev/null; then
    print_error "Terraform no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que aws cli esté disponible
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI no está instalado o no está en el PATH"
    exit 1
fi

# Verificar que curl esté disponible
if ! command -v curl &> /dev/null; then
    print_error "curl no está disponible"
    exit 1
fi

print_step "Verificando configuración de Terraform"

# Verificar que estemos en el directorio correcto
if [ ! -f "main.tf" ]; then
    print_error "No se encontró main.tf. Ejecuta este script desde el directorio raíz del proyecto."
    exit 1
fi

# Obtener outputs de Terraform
print_step "Obteniendo outputs de Terraform"

if ! terraform output > /dev/null 2>&1; then
    print_error "No se pueden obtener los outputs de Terraform. ¿Has ejecutado 'terraform apply'?"
    exit 1
fi

# Extraer información necesaria de los outputs
API_GATEWAY_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id 2>/dev/null || echo "")
COGNITO_LOGIN_URL=$(terraform output -raw cognito_login_url 2>/dev/null || echo "")

# Verificar que los outputs necesarios existan
if [ -z "$API_GATEWAY_URL" ]; then
    print_error "No se pudo obtener la URL del API Gateway"
    exit 1
fi

print_status "API Gateway URL: $API_GATEWAY_URL"

if [ -n "$COGNITO_USER_POOL_ID" ]; then
    print_status "Cognito User Pool ID: $COGNITO_USER_POOL_ID"
    print_status "Cognito Client ID: $COGNITO_CLIENT_ID"
else
    print_warning "Cognito no está configurado o no está disponible"
fi

print_step "Probando endpoints del API Gateway"

# Probar endpoint público (si está disponible)
print_status "Probando endpoint público..."
PUBLIC_ENDPOINT="${API_GATEWAY_URL}/public/health"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PUBLIC_ENDPOINT" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    print_status "✓ Endpoint público responde correctamente (200)"
elif [ "$HTTP_STATUS" = "404" ]; then
    print_warning "Endpoint público no disponible (404) - esto es normal si no hay endpoints públicos configurados"
elif [ "$HTTP_STATUS" = "000" ]; then
    print_error "✗ No se pudo conectar al endpoint público"
else
    print_warning "Endpoint público respondió con código: $HTTP_STATUS"
fi

# Probar endpoint protegido sin autenticación
print_status "Probando endpoint protegido sin autenticación..."
PROTECTED_ENDPOINT="${API_GATEWAY_URL}/protected"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PROTECTED_ENDPOINT" || echo "000")

if [ "$HTTP_STATUS" = "401" ]; then
    print_status "✓ Endpoint protegido rechaza correctamente requests sin autenticación (401)"
elif [ "$HTTP_STATUS" = "403" ]; then
    print_status "✓ Endpoint protegido rechaza correctamente requests sin autenticación (403)"
elif [ "$HTTP_STATUS" = "200" ]; then
    print_warning "⚠ Endpoint protegido permite acceso sin autenticación - verificar configuración"
else
    print_warning "Endpoint protegido respondió con código inesperado: $HTTP_STATUS"
fi

# Pruebas específicas de Cognito si está disponible
if [ -n "$COGNITO_USER_POOL_ID" ]; then
    print_step "Verificando configuración de Cognito"
    
    # Verificar que el User Pool existe
    print_status "Verificando User Pool..."
    
    if aws cognito-idp describe-user-pool --user-pool-id "$COGNITO_USER_POOL_ID" > /dev/null 2>&1; then
        print_status "✓ User Pool existe y es accesible"
        
        # Obtener información del User Pool
        USER_POOL_INFO=$(aws cognito-idp describe-user-pool --user-pool-id "$COGNITO_USER_POOL_ID" --query 'UserPool.{Name:Name,Status:Status,CreationDate:CreationDate}' --output table)
        echo "$USER_POOL_INFO"
        
    else
        print_error "✗ No se puede acceder al User Pool - verificar permisos AWS"
    fi
    
    # Verificar configuración del cliente
    print_status "Verificando User Pool Client..."
    
    if aws cognito-idp describe-user-pool-client --user-pool-id "$COGNITO_USER_POOL_ID" --client-id "$COGNITO_CLIENT_ID" > /dev/null 2>&1; then
        print_status "✓ User Pool Client existe y es accesible"
        
        # Obtener información del cliente
        CLIENT_INFO=$(aws cognito-idp describe-user-pool-client --user-pool-id "$COGNITO_USER_POOL_ID" --client-id "$COGNITO_CLIENT_ID" --query 'UserPoolClient.{ClientName:ClientName,ExplicitAuthFlows:ExplicitAuthFlows}' --output table)
        echo "$CLIENT_INFO"
        
    else
        print_error "✗ No se puede acceder al User Pool Client"
    fi
    
    # Mostrar URLs útiles
    print_step "URLs útiles para pruebas manuales"
    
    if [ -n "$COGNITO_LOGIN_URL" ]; then
        print_status "URL de Login: $COGNITO_LOGIN_URL"
    fi
    
    # Mostrar comando para crear usuario de prueba
    print_step "Comandos útiles para pruebas"
    
    echo ""
    echo "Para crear un usuario de prueba:"
    echo "aws cognito-idp admin-create-user \\"
    echo "    --user-pool-id $COGNITO_USER_POOL_ID \\"
    echo "    --username testuser \\"
    echo "    --user-attributes Name=email,Value=test@example.com \\"
    echo "    --temporary-password TempPass123! \\"
    echo "    --message-action SUPPRESS"
    
    echo ""
    echo "Para confirmar el usuario (saltar verificación de email):"
    echo "aws cognito-idp admin-confirm-sign-up \\"
    echo "    --user-pool-id $COGNITO_USER_POOL_ID \\"
    echo "    --username testuser"
    
    echo ""
    echo "Para establecer contraseña permanente:"
    echo "aws cognito-idp admin-set-user-password \\"
    echo "    --user-pool-id $COGNITO_USER_POOL_ID \\"
    echo "    --username testuser \\"
    echo "    --password MyPassword123! \\"
    echo "    --permanent"
fi

print_step "Verificando conectividad del ALB"

# Obtener DNS del ALB desde outputs
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")

if [ -n "$ALB_DNS" ]; then
    print_status "ALB DNS: $ALB_DNS"
    
    # Probar conectividad directa al ALB
    ALB_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS/" || echo "000")
    
    if [ "$ALB_HTTP_STATUS" = "200" ] || [ "$ALB_HTTP_STATUS" = "404" ]; then
        print_status "✓ ALB es accesible directamente"
    else
        print_warning "ALB respondió con código: $ALB_HTTP_STATUS"
    fi
else
    print_warning "No se pudo obtener el DNS del ALB"
fi

print_step "Resumen de la verificación"

echo ""
print_status "Infraestructura desplegada exitosamente:"
echo "  - API Gateway: $API_GATEWAY_URL"

if [ -n "$COGNITO_USER_POOL_ID" ]; then
    echo "  - Cognito User Pool: $COGNITO_USER_POOL_ID"
    echo "  - Autenticación: Habilitada"
else
    echo "  - Autenticación: Deshabilitada o no configurada"
fi

if [ -n "$ALB_DNS" ]; then
    echo "  - Application Load Balancer: $ALB_DNS"
fi

echo ""
print_status "Próximos pasos:"
echo "  1. Configurar tu aplicación con los endpoints mostrados"
echo "  2. Implementar el flujo de autenticación en tu frontend"
echo "  3. Configurar URLs de callback apropiadas"
echo "  4. Probar el flujo completo de autenticación"

if [ -n "$COGNITO_USER_POOL_ID" ]; then
    echo "  5. Crear usuarios de prueba usando los comandos mostrados arriba"
fi

echo ""
print_status "Documentación adicional disponible en:"
echo "  - COGNITO_INTEGRATION_GUIDE.md"
echo "  - modules/auth/README.md"
echo "  - modules/api_gateway/README.md"

echo ""
print_status "Script de verificación completado ✓"
