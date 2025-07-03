#!/bin/bash

###################################################################
# Script de Prueba para WAF de CloudFront
# Este script prueba que el WAF esté funcionando correctamente
###################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
CLOUDFRONT_DOMAIN=""
PROJECT_NAME="villa-alfredo"
ENVIRONMENT="dev"
WAF_WEB_ACL_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cloudfront-waf"

echo -e "${BLUE}=== Script de Prueba para WAF de CloudFront ===${NC}"
echo ""

# Función para obtener el dominio de CloudFront
get_cloudfront_domain() {
    echo -e "${YELLOW}Obteniendo dominio de CloudFront...${NC}"
    CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")
    
    if [ -z "$CLOUDFRONT_DOMAIN" ]; then
        echo -e "${RED}Error: No se pudo obtener el dominio de CloudFront${NC}"
        echo "Ejecuta 'terraform apply' primero o proporciona el dominio manualmente:"
        read -p "Ingresa el dominio de CloudFront: " CLOUDFRONT_DOMAIN
    fi
    
    echo -e "${GREEN}Dominio de CloudFront: $CLOUDFRONT_DOMAIN${NC}"
}

# Función para verificar el estado del WAF
check_waf_status() {
    echo -e "${YELLOW}Verificando estado del WAF...${NC}"
    
    # Verificar que el Web ACL existe
    WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 --query "WebACLs[?Name=='$WAF_WEB_ACL_NAME'].Id" --output text 2>/dev/null || echo "")
    
    if [ -z "$WAF_ID" ]; then
        echo -e "${RED}Error: WAF Web ACL no encontrado${NC}"
        return 1
    fi
    
    echo -e "${GREEN}WAF Web ACL encontrado: $WAF_ID${NC}"
    
    # Obtener información del WAF
    aws wafv2 get-web-acl --scope CLOUDFRONT --id "$WAF_ID" --region us-east-1 --query 'WebACL.{Name:Name,DefaultAction:DefaultAction,Rules:Rules[].Name}' --output table
}

# Función para hacer requests de prueba
test_normal_request() {
    echo -e "${YELLOW}Probando request normal...${NC}"
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$CLOUDFRONT_DOMAIN/" || echo "000")
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "404" ] || [ "$RESPONSE" = "403" ]; then
        echo -e "${GREEN}✓ Request normal exitoso (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}✗ Request normal falló (HTTP $RESPONSE)${NC}"
    fi
}

# Función para probar SQL injection (debería ser bloqueado)
test_sql_injection() {
    echo -e "${YELLOW}Probando protección contra SQL injection...${NC}"
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$CLOUDFRONT_DOMAIN/?id=1' OR '1'='1" || echo "000")
    
    if [ "$RESPONSE" = "403" ]; then
        echo -e "${GREEN}✓ SQL injection bloqueado correctamente (HTTP 403)${NC}"
    else
        echo -e "${YELLOW}⚠ SQL injection no bloqueado (HTTP $RESPONSE) - puede ser normal si la regla está en modo COUNT${NC}"
    fi
}

# Función para probar User Agent malicioso
test_bad_user_agent() {
    echo -e "${YELLOW}Probando User Agent malicioso...${NC}"
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "User-Agent: BadBot" "https://$CLOUDFRONT_DOMAIN/" || echo "000")
    
    if [ "$RESPONSE" = "403" ]; then
        echo -e "${GREEN}✓ User Agent malicioso bloqueado correctamente (HTTP 403)${NC}"
    else
        echo -e "${YELLOW}⚠ User Agent malicioso no bloqueado (HTTP $RESPONSE)${NC}"
    fi
}

# Función para mostrar métricas del WAF
show_waf_metrics() {
    echo -e "${YELLOW}Obteniendo métricas recientes del WAF...${NC}"
    
    # Métricas de los últimos 60 minutos
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    START_TIME=$(date -u -d '60 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "Período: $START_TIME a $END_TIME"
    echo ""
    
    # Requests permitidos
    ALLOWED=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/WAFV2 \
        --metric-name AllowedRequests \
        --dimensions Name=WebACL,Value="$WAF_WEB_ACL_NAME" Name=Region,Value=CloudFront Name=Rule,Value=ALL \
        --start-time "$START_TIME" \
        --end-time "$END_TIME" \
        --period 3600 \
        --statistics Sum \
        --region us-east-1 \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    # Requests bloqueados
    BLOCKED=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/WAFV2 \
        --metric-name BlockedRequests \
        --dimensions Name=WebACL,Value="$WAF_WEB_ACL_NAME" Name=Region,Value=CloudFront Name=Rule,Value=ALL \
        --start-time "$START_TIME" \
        --end-time "$END_TIME" \
        --period 3600 \
        --statistics Sum \
        --region us-east-1 \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    echo -e "Requests permitidos: ${GREEN}$ALLOWED${NC}"
    echo -e "Requests bloqueados: ${RED}$BLOCKED${NC}"
    
    if [ "$ALLOWED" != "None" ] && [ "$BLOCKED" != "None" ]; then
        TOTAL=$((ALLOWED + BLOCKED))
        if [ $TOTAL -gt 0 ]; then
            BLOCK_RATE=$(echo "scale=2; $BLOCKED * 100 / $TOTAL" | bc)
            echo -e "Tasa de bloqueo: ${YELLOW}$BLOCK_RATE%${NC}"
        fi
    fi
}

# Función principal
main() {
    echo -e "${BLUE}Iniciando pruebas del WAF...${NC}"
    echo ""
    
    # Verificar dependencias
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI no está instalado${NC}"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl no está instalado${NC}"
        exit 1
    fi
    
    # Ejecutar pruebas
    get_cloudfront_domain
    echo ""
    
    check_waf_status
    echo ""
    
    test_normal_request
    echo ""
    
    test_sql_injection
    echo ""
    
    test_bad_user_agent
    echo ""
    
    show_waf_metrics
    echo ""
    
    echo -e "${BLUE}=== Pruebas completadas ===${NC}"
    echo ""
    echo -e "${YELLOW}Notas:${NC}"
    echo "- Las reglas pueden estar en modo COUNT inicialmente"
    echo "- Las métricas pueden tardar hasta 5 minutos en aparecer"
    echo "- Para ver logs detallados, revisar CloudWatch Logs"
    echo "- Para cambiar reglas a modo BLOCK, actualizar la configuración de Terraform"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
