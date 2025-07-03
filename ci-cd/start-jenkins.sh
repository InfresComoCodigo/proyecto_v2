#!/bin/bash

# Script para iniciar Jenkins con Terraform
echo "🚀 Iniciando Jenkins con soporte para Terraform..."
echo ""

# Verificar si Docker está ejecutándose
echo "🔍 Verificando Docker..."
if ! docker version >/dev/null 2>&1; then
    echo "❌ Docker no está ejecutándose!"
    echo ""
    echo "📋 Para solucionar este problema:"
    echo "1. Iniciar Docker Desktop (en macOS/Windows)"
    echo "2. O iniciar el servicio de Docker (en Linux): sudo systemctl start docker"
    echo "3. Verificar con: docker version"
    echo "4. Ejecutar nuevamente este script"
    echo ""
    exit 1
fi

echo "✅ Docker está funcionando"
echo ""

# Verificar conexión con Docker daemon
if ! docker ps >/dev/null 2>&1; then
    echo "❌ No se puede conectar al daemon de Docker"
    echo "🔄 Verifica que Docker Desktop esté ejecutándose completamente"
    echo ""
    exit 1
fi

echo "✅ Conexión con Docker verificada"
echo ""

# Crear directorios necesarios
mkdir -p jenkins_home
mkdir -p logs

# Construir y ejecutar contenedores
echo "📦 Construyendo imagen de Jenkins personalizada..."
docker-compose build

echo "🔧 Iniciando servicios..."
docker-compose up -d

# Esperar a que Jenkins esté listo
echo "⏳ Esperando a que Jenkins esté listo..."
sleep 30

# Mostrar información de acceso
echo ""
echo "✅ Jenkins está ejecutándose!"
echo "🌐 Acceder a: http://localhost:8080"
echo ""

# Mostrar contraseña inicial de administrador
echo "🔑 Contraseña inicial de administrador:"
docker exec jenkins-terraform cat /var/jenkins_home/secrets/initialAdminPassword

echo ""
echo "📋 Comandos útiles:"
echo "  - Ver logs: docker-compose logs -f jenkins"
echo "  - Detener: docker-compose down"
echo "  - Reiniciar: docker-compose restart jenkins"
echo "  - Acceder al contenedor: docker exec -it jenkins-terraform bash"
echo ""
echo "🛠️ Configuración sugerida:"
echo "  1. Acceder a Jenkins en http://localhost:8080"
echo "  2. Usar la contraseña mostrada arriba"
echo "  3. Instalar plugins sugeridos"
echo "  4. Crear un usuario administrador"
echo "  5. Configurar credenciales de AWS"
echo "  6. Crear un nuevo pipeline usando el Jenkinsfile"
echo ""
