#!/bin/bash

# Script para iniciar el stack completo de monitoreo y logging
# Jenkins + Grafana + Prometheus + ELK Stack

echo "🚀 Iniciando Stack de Monitoreo y Logging..."
echo "=============================================="

# Verificar que Docker esté corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Por favor, inicia Docker primero."
    exit 1
fi

# Verificar que Docker Compose esté instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado."
    exit 1
fi

# Crear directorios necesarios
echo "📁 Creando directorios necesarios..."
mkdir -p jenkins-logs
mkdir -p prometheus/{rules,data}
mkdir -p grafana/{dashboards,provisioning/{dashboards,datasources}}
mkdir -p logstash/{pipeline,config}
mkdir -p alertmanager
mkdir -p traefik

# Ajustar permisos
echo "🔐 Ajustando permisos..."
chmod 777 jenkins-logs
chmod 777 prometheus/data
chmod 777 grafana
sudo chown -R 472:472 grafana/ 2>/dev/null || true

# Construir la imagen personalizada de Jenkins
echo "🏗️  Construyendo imagen personalizada de Jenkins..."
docker-compose -f docker-compose-monitoring.yml build jenkins

# Iniciar servicios de infraestructura primero
echo "🔄 Iniciando servicios de infraestructura..."
docker-compose -f docker-compose-monitoring.yml up -d elasticsearch prometheus

# Esperar a que Elasticsearch esté listo
echo "⏳ Esperando a que Elasticsearch esté listo..."
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
    echo "   Esperando Elasticsearch..."
    sleep 5
done
echo "✅ Elasticsearch está listo"

# Iniciar servicios de logging
echo "🔄 Iniciando servicios de logging..."
docker-compose -f docker-compose-monitoring.yml up -d logstash kibana

# Iniciar servicios de monitoreo
echo "🔄 Iniciando servicios de monitoreo..."
docker-compose -f docker-compose-monitoring.yml up -d grafana node-exporter cadvisor alertmanager

# Esperar a que Grafana esté listo
echo "⏳ Esperando a que Grafana esté listo..."
until curl -s http://localhost:3000/api/health | grep -q '"database":"ok"'; do
    echo "   Esperando Grafana..."
    sleep 5
done
echo "✅ Grafana está listo"

# Iniciar Jenkins
echo "🔄 Iniciando Jenkins..."
docker-compose -f docker-compose-monitoring.yml up -d jenkins

# Iniciar proxy reverso
echo "🔄 Iniciando Traefik..."
docker-compose -f docker-compose-monitoring.yml up -d traefik

# Esperar a que todos los servicios estén listos
echo "⏳ Verificando que todos los servicios estén funcionando..."
sleep 30

# Verificar estado de servicios
echo "📊 Estado de servicios:"
echo "======================="

services=("jenkins:8080" "grafana:3000" "prometheus:9090" "kibana:5601" "elasticsearch:9200" "traefik:8082")

for service in "${services[@]}"; do
    port=$(echo $service | cut -d: -f2)
    name=$(echo $service | cut -d: -f1)
    
    if curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
        echo "✅ $name está funcionando en puerto $port"
    else
        echo "❌ $name no responde en puerto $port"
    fi
done

echo ""
echo "🎉 Stack de Monitoreo y Logging iniciado!"
echo "=========================================="
echo ""
echo "📊 Acceso a servicios:"
echo "====================="
echo "🏗️  Jenkins:     http://localhost:8080"
echo "📈 Grafana:      http://localhost:3000 (admin/admin123)"
echo "🔍 Prometheus:   http://localhost:9090"
echo "📊 Kibana:       http://localhost:5601"
echo "🌐 Traefik:      http://localhost:8082"
echo "🚨 Alertmanager: http://localhost:9093"
echo ""
echo "📋 Servicios adicionales:"
echo "========================"
echo "🔧 Node Exporter: http://localhost:9100"
echo "📊 cAdvisor:      http://localhost:8081"
echo "🗄️  Elasticsearch: http://localhost:9200"
echo ""
echo "🔍 Para ver logs en tiempo real:"
echo "docker-compose -f docker-compose-monitoring.yml logs -f"
echo ""
echo "🛑 Para detener todos los servicios:"
echo "./stop-monitoring.sh"
echo ""
echo "📚 Para más información, consulta la documentación en README.md"
