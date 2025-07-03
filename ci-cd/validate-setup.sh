#!/bin/bash

# Script de prueba para validar la configuración del pipeline
echo "🧪 Ejecutando pruebas de validación del pipeline Jenkins-Terraform..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar resultado de prueba
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Función para mostrar advertencia
warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

echo ""
echo "🔍 Verificando prerrequisitos..."

# Verificar Docker
docker --version > /dev/null 2>&1
test_result $? "Docker está instalado"

# Verificar Docker Compose
docker-compose --version > /dev/null 2>&1
test_result $? "Docker Compose está instalado"

# Verificar Git
git --version > /dev/null 2>&1
test_result $? "Git está instalado"

echo ""
echo "📁 Verificando archivos de configuración..."

# Verificar archivos principales
files=("Dockerfile" "Jenkinsfile" "docker-compose.yml" "README.md")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        test_result 0 "Archivo $file existe"
    else
        test_result 1 "Archivo $file no encontrado"
    fi
done

echo ""
echo "🐳 Verificando configuración de Docker..."

# Verificar sintaxis del Dockerfile
docker build --dry-run . > /dev/null 2>&1
if [ $? -eq 0 ]; then
    test_result 0 "Sintaxis del Dockerfile es válida"
else
    warning "No se pudo validar sintaxis del Dockerfile (--dry-run no soportado)"
fi

# Verificar docker-compose
docker-compose config > /dev/null 2>&1
test_result $? "Configuración de docker-compose es válida"

echo ""
echo "📋 Verificando estructura del proyecto..."

# Verificar directorio de Terraform
if [ -d "../infrastructure" ]; then
    test_result 0 "Directorio de infraestructura existe"
    
    # Verificar archivos de Terraform
    tf_files=("../infrastructure/main.tf" "../infrastructure/variables.tf" "../infrastructure/outputs.tf")
    for tf_file in "${tf_files[@]}"; do
        if [ -f "$tf_file" ]; then
            test_result 0 "Archivo Terraform $(basename $tf_file) existe"
        else
            warning "Archivo Terraform $(basename $tf_file) no encontrado"
        fi
    done
else
    test_result 1 "Directorio de infraestructura no encontrado"
fi

echo ""
echo "🔧 Verificando configuración de red..."

# Verificar puertos disponibles
check_port() {
    local port=$1
    if command -v nc >/dev/null 2>&1; then
        nc -z localhost $port 2>/dev/null
        if [ $? -eq 0 ]; then
            warning "Puerto $port ya está en uso"
        else
            test_result 0 "Puerto $port disponible"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        netstat -ln | grep ":$port " > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            warning "Puerto $port ya está en uso"
        else
            test_result 0 "Puerto $port disponible"
        fi
    else
        warning "No se puede verificar disponibilidad del puerto $port"
    fi
}

check_port 8080
check_port 50000

echo ""
echo "🏗️ Prueba de construcción de imagen..."

# Intentar construir la imagen
echo "Construyendo imagen de Jenkins personalizada..."
docker build -t jenkins-terraform-test . --quiet
if [ $? -eq 0 ]; then
    test_result 0 "Imagen construida exitosamente"
    
    # Limpiar imagen de prueba
    docker rmi jenkins-terraform-test > /dev/null 2>&1
else
    test_result 1 "Error al construir imagen"
fi

echo ""
echo "📝 Verificando sintaxis del Jenkinsfile..."

# Verificar sintaxis básica del Jenkinsfile
if grep -q "pipeline" Jenkinsfile && grep -q "stages" Jenkinsfile; then
    test_result 0 "Estructura básica del Jenkinsfile es correcta"
else
    test_result 1 "Estructura del Jenkinsfile parece incorrecta"
fi

# Verificar que contiene las etapas esperadas
expected_stages=("Checkout" "Terraform Init" "Terraform Plan" "Terraform Apply")
for stage in "${expected_stages[@]}"; do
    if grep -q "$stage" Jenkinsfile; then
        test_result 0 "Etapa '$stage' encontrada en Jenkinsfile"
    else
        warning "Etapa '$stage' no encontrada en Jenkinsfile"
    fi
done

echo ""
echo "🔑 Verificando permisos de archivos..."

# Verificar permisos de scripts
scripts=("start-jenkins.sh" "stop-jenkins.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            test_result 0 "Script $script tiene permisos de ejecución"
        else
            warning "Script $script no tiene permisos de ejecución (ejecutar: chmod +x $script)"
        fi
    fi
done

echo ""
echo "📊 Resumen de la validación:"
echo ""

# Mostrar siguiente pasos
echo "🚀 Siguientes pasos recomendados:"
echo ""
echo "1. Si todas las pruebas pasaron, ejecutar:"
echo "   ./start-jenkins.sh"
echo ""
echo "2. Configurar credenciales de AWS en Jenkins:"
echo "   - Acceder a http://localhost:8080"
echo "   - Ir a Manage Jenkins > Manage Credentials"
echo "   - Agregar AWS Credentials con ID 'aws-credentials'"
echo ""
echo "3. Crear pipeline en Jenkins:"
echo "   - New Item > Pipeline"
echo "   - Pipeline script from SCM"
echo "   - Configurar repositorio Git"
echo "   - Script Path: ci-cd/Jenkinsfile"
echo ""
echo "4. Ejecutar pipeline con parámetros:"
echo "   - ACTION: apply o destroy"
echo "   - AUTO_APPROVE: true/false"
echo "   - TERRAFORM_WORKSPACE: default/dev/staging/prod"
echo ""

echo "✨ Validación completada!"
