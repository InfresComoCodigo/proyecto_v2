#!/bin/bash

# Script para verificar que todos los archivos del pipeline están listos

echo "📋 Verificando archivos del pipeline Jenkins-Terraform..."
echo "======================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar resultado
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

# Verificar archivos principales
echo "🔍 Verificando archivos principales..."
check_file "Dockerfile" "Dockerfile para Jenkins"
check_file "docker-compose.yml" "Configuración de Docker Compose"
check_file "Jenkinsfile" "Pipeline principal de Jenkins"
check_file "Jenkinsfile-simple" "Pipeline simplificado para pruebas"

echo ""

# Verificar scripts
echo "🔍 Verificando scripts..."
check_file "start-jenkins.sh" "Script de inicio para Linux/macOS"
check_file "start-jenkins.bat" "Script de inicio para Windows"
check_file "stop-jenkins.sh" "Script de parada"
check_file "check-docker.sh" "Verificador de Docker (bash)"
check_file "check-docker.bat" "Verificador de Docker (Windows)"
check_file "validate-setup.sh" "Validador de configuración"

echo ""

# Verificar permisos de ejecución
echo "🔍 Verificando permisos de ejecución..."
for script in start-jenkins.sh stop-jenkins.sh check-docker.sh validate-setup.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo -e "${GREEN}✅ $script tiene permisos de ejecución${NC}"
        else
            echo -e "${YELLOW}⚠️ $script necesita permisos de ejecución${NC}"
            chmod +x "$script"
            echo -e "${GREEN}✅ Permisos corregidos para $script${NC}"
        fi
    fi
done

echo ""

# Verificar estructura del proyecto
echo "🔍 Verificando estructura del proyecto..."
if [ -d "../infrastructure" ]; then
    echo -e "${GREEN}✅ Directorio infrastructure encontrado${NC}"
    
    # Verificar archivos de Terraform
    tf_files=("main.tf" "variables.tf" "outputs.tf" "terraform.tfvars")
    for tf_file in "${tf_files[@]}"; do
        if [ -f "../infrastructure/$tf_file" ]; then
            echo -e "${GREEN}✅ $tf_file encontrado${NC}"
        else
            echo -e "${YELLOW}⚠️ $tf_file no encontrado (opcional)${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️ Directorio infrastructure no encontrado${NC}"
    echo "    Nota: Esto es normal si no tienes archivos de Terraform aún"
fi

echo ""

# Verificar sintaxis del Jenkinsfile
echo "🔍 Verificando sintaxis de Jenkinsfiles..."
for jenkinsfile in Jenkinsfile Jenkinsfile-simple; do
    if [ -f "$jenkinsfile" ]; then
        # Verificaciones básicas de sintaxis
        if grep -q "pipeline" "$jenkinsfile" && grep -q "stages" "$jenkinsfile"; then
            echo -e "${GREEN}✅ $jenkinsfile tiene estructura válida${NC}"
        else
            echo -e "${RED}❌ $jenkinsfile parece tener problemas de estructura${NC}"
        fi
        
        # Verificar que no hay caracteres problemáticos
        if grep -q $'\r' "$jenkinsfile"; then
            echo -e "${YELLOW}⚠️ $jenkinsfile tiene terminadores de línea Windows${NC}"
            echo "    Ejecutar: dos2unix $jenkinsfile"
        fi
    fi
done

echo ""

# Verificar Git
echo "🔍 Verificando estado de Git..."
if git status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Directorio es un repositorio Git${NC}"
    
    # Verificar archivos sin commit
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${GREEN}✅ Todos los archivos están committados${NC}"
    else
        echo -e "${YELLOW}⚠️ Hay archivos sin commit${NC}"
        echo "    Archivos modificados:"
        git status --porcelain
    fi
    
    # Verificar remote
    if git remote -v | grep -q "github\|gitlab\|bitbucket"; then
        echo -e "${GREEN}✅ Repositorio remoto configurado${NC}"
    else
        echo -e "${YELLOW}⚠️ No hay repositorio remoto configurado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ No es un repositorio Git${NC}"
    echo "    Para inicializar: git init"
fi

echo ""

# Resumen y recomendaciones
echo "📊 Resumen y recomendaciones:"
echo "=============================="

echo ""
echo "🚀 Para continuar:"
echo "1. Si todo está OK, ejecutar: ./start-jenkins.sh"
echo "2. Si hay archivos sin commit: git add . && git commit -m 'Add Jenkins pipeline'"
echo "3. Si hay repositorio remoto: git push origin main"
echo "4. En Jenkins, usar la URL de tu repositorio remoto"
echo ""

echo "💡 Opciones de pipeline:"
echo "- Para pruebas: ci-cd/Jenkinsfile-simple"
echo "- Para producción: ci-cd/Jenkinsfile"
echo ""

echo "✨ Verificación completada!"
