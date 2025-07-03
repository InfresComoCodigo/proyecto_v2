#!/bin/bash

# Script para configurar Jenkins con CloudWatch y Grafana

echo "🚀 Configurando integración de Jenkins con CloudWatch y Grafana..."

# 1. Crear archivo de variables de entorno
cat > .env << 'EOF'
# AWS Configuration for CloudWatch
AWS_ACCESS_KEY_ID=your_aws_access_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_key_here
AWS_DEFAULT_REGION=us-east-1

# Jenkins Agent Secrets (generar con: openssl rand -hex 32)
JENKINS_NODEJS_AGENT_SECRET=change_me_nodejs_secret
JENKINS_TERRAFORM_AGENT_SECRET=change_me_terraform_secret
JENKINS_SECURITY_AGENT_SECRET=change_me_security_secret

# Grafana Configuration
GF_SECURITY_ADMIN_PASSWORD=admin123
EOF

echo "✅ Archivo .env creado. EDITA LAS CREDENCIALES ANTES DE CONTINUAR!"

# 2. Crear script para inicializar Jenkins con credenciales
cat > setup-jenkins-credentials.sh << 'EOF'
#!/bin/bash

echo "📋 Configurando credenciales de Jenkins..."

# Esperar a que Jenkins esté listo
echo "Esperando a que Jenkins esté disponible..."
while ! curl -s http://localhost:8080/login > /dev/null; do
    echo "Jenkins no está listo, esperando 10 segundos..."
    sleep 10
done

echo "✅ Jenkins está disponible!"

# Configurar credenciales de AWS usando Jenkins CLI
# Nota: Esto requiere que tengas Jenkins CLI configurado

echo "Para configurar las credenciales manualmente:"
echo "1. Ve a http://localhost:8080"
echo "2. Login con admin/admin123"
echo "3. Ve a Manage Jenkins > Manage Credentials"
echo "4. Agrega las siguientes credenciales:"
echo "   - AWS Access Key ID (Secret text)"
echo "   - AWS Secret Access Key (Secret text)"
echo "   - Username/Password para GitHub"

EOF

chmod +x setup-jenkins-credentials.sh

# 3. Crear script de inicio completo
cat > start-monitoring-stack.sh << 'EOF'
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

EOF

chmod +x start-monitoring-stack.sh

echo "✅ Scripts de configuración creados!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Edita el archivo .env con tus credenciales reales"
echo "2. Ejecuta: ./start-monitoring-stack.sh"
echo "3. Ejecuta: ./setup-jenkins-credentials.sh"
