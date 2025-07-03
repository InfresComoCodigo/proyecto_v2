#!/bin/bash

# Script para detener Jenkins y limpiar recursos
echo "🛑 Deteniendo Jenkins..."

# Detener contenedores
docker-compose down

echo "🧹 ¿Deseas limpiar todos los datos de Jenkins? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🗑️ Limpiando volúmenes de datos..."
    docker-compose down -v
    docker volume prune -f
    
    echo "🗂️ Limpiando directorios locales..."
    rm -rf jenkins_home logs
    
    echo "✅ Limpieza completa realizada"
else
    echo "✅ Jenkins detenido (datos preservados)"
fi

echo "🐳 Limpiando imágenes no utilizadas..."
docker image prune -f

echo "📊 Estado actual de Docker:"
docker ps -a
docker images
