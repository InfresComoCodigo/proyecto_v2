#!/bin/bash

echo "🚀 Iniciando stack completo de monitoreo..."

# Verificar que Docker esté ejecutándose
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está ejecutándose. Inicia Docker primero."
    exit 1
fi

# Verificar que las variables de entorno estén configuradas
if [ ! -f .env ]; then
    echo "❌ Archivo .env no encontrado. Ejecuta el script de configuración primero."
    exit 1
fi

# Cargar variables de entorno
source .env

# Validar que las credenciales de AWS estén configuradas
if [ "$AWS_ACCESS_KEY_ID" = "your_aws_access_key_here" ]; then
    echo "❌ Configura tus credenciales de AWS en el archivo .env"
    exit 1
fi

echo "📦 Construyendo e iniciando contenedores..."
docker-compose down
docker-compose pull
docker-compose up -d

echo "⏳ Esperando a que los servicios estén listos..."
sleep 30

echo "🔍 Verificando servicios..."
echo "Jenkins: http://localhost:8080 (admin/admin123)"
echo "Grafana: http://localhost:3000 (admin/admin123)"
echo "Prometheus: http://localhost:9090"
echo "SonarQube: http://localhost:9000 (admin/admin)"

echo "✅ Stack de monitoreo iniciado correctamente!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Configura las credenciales de AWS en Jenkins"
echo "2. Ejecuta un pipeline para generar logs"
echo "3. Ve a Grafana para visualizar los dashboards"
echo "4. Configura alertas en Grafana si es necesario"

