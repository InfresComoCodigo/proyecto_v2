#!/bin/bash

# Script para verificar y configurar Docker Desktop en Windows/Linux/macOS

echo "🐳 Verificador de Docker Desktop"
echo "================================"
echo ""

# Función para mostrar resultado de prueba
test_result() {
    if [ $1 -eq 0 ]; then
        echo "✅ $2"
    else
        echo "❌ $2"
        return 1
    fi
}

# Función para mostrar advertencia
warning() {
    echo "⚠️ $1"
}

# Verificar si Docker está instalado
echo "🔍 Verificando instalación de Docker..."
if command -v docker >/dev/null 2>&1; then
    test_result 0 "Docker está instalado"
else
    test_result 1 "Docker no está instalado"
    echo ""
    echo "📥 Para instalar Docker:"
    echo "- Windows: https://www.docker.com/products/docker-desktop"
    echo "- macOS: https://www.docker.com/products/docker-desktop"
    echo "- Linux: sudo apt-get install docker.io (Ubuntu) o equivalente"
    echo ""
    exit 1
fi

echo ""

# Verificar si Docker está ejecutándose
echo "🔍 Verificando estado de Docker..."
if docker version >/dev/null 2>&1; then
    test_result 0 "Docker está ejecutándose"
else
    test_result 1 "Docker no está ejecutándose"
    echo ""
    echo "🚀 Para iniciar Docker:"
    echo "- Windows/macOS: Abrir Docker Desktop"
    echo "- Linux: sudo systemctl start docker"
    echo ""
    echo "⏳ Si acabas de iniciar Docker, espera unos minutos..."
    echo ""
    exit 1
fi

echo ""

# Verificar conexión con Docker daemon
echo "🔍 Verificando conexión con Docker daemon..."
if docker ps >/dev/null 2>&1; then
    test_result 0 "Conexión con Docker daemon OK"
else
    test_result 1 "No se puede conectar al daemon de Docker"
    echo ""
    echo "🔄 Posibles soluciones:"
    echo "- Reiniciar Docker Desktop"
    echo "- Verificar permisos de usuario"
    echo "- En Linux: sudo usermod -aG docker \$USER (luego reiniciar sesión)"
    echo ""
    exit 1
fi

echo ""

# Mostrar información de Docker
echo "📊 Información de Docker:"
echo "-------------------------"
docker version --format "Cliente: {{.Client.Version}}" 2>/dev/null || echo "Cliente: $(docker version | grep 'Client:' -A1 | tail -1 | awk '{print $2}')"
docker version --format "Servidor: {{.Server.Version}}" 2>/dev/null || echo "Servidor: $(docker version | grep 'Server:' -A1 | tail -1 | awk '{print $2}')"
echo ""

# Verificar recursos disponibles
echo "🔧 Verificando configuración..."
docker system info 2>/dev/null | grep -E "CPUs|Total Memory" || echo "No se pudo obtener información del sistema"
echo ""

# Probar funcionalidad básica
echo "🧪 Probando funcionalidad básica..."
if docker run --rm hello-world >/dev/null 2>&1; then
    test_result 0 "Docker funciona correctamente"
else
    warning "Hay problemas con Docker, pero puede funcionar para Jenkins"
fi

echo ""

# Verificar puertos necesarios
echo "🔍 Verificando puertos necesarios..."
check_port() {
    local port=$1
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost $port 2>/dev/null; then
            warning "Puerto $port ya está en uso"
        else
            test_result 0 "Puerto $port disponible"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -ln 2>/dev/null | grep ":$port " >/dev/null; then
            warning "Puerto $port ya está en uso"
        else
            test_result 0 "Puerto $port disponible"
        fi
    else
        echo "⚠️ No se puede verificar puerto $port (nc/netstat no disponible)"
    fi
}

check_port 8080
check_port 50000

echo ""
echo "🎉 Verificación completada!"
echo ""

# Mostrar siguiente pasos
echo "📋 Próximos pasos:"
echo "1. Si todo está OK, ejecutar:"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "   ./start-jenkins.sh  (o start-jenkins.bat desde cmd)"
else
    echo "   ./start-jenkins.sh"
fi
echo "2. Si hay problemas, solucionarlos primero"
echo "3. Acceder a http://localhost:8080 cuando Jenkins esté listo"
echo ""
