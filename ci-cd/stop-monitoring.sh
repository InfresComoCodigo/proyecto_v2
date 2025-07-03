#!/bin/bash

# Script para detener el stack completo de monitoreo y logging

echo "🛑 Deteniendo Stack de Monitoreo y Logging..."
echo "=============================================="

# Detener todos los servicios
echo "🔄 Deteniendo todos los servicios..."
docker-compose -f docker-compose-monitoring.yml down

# Opcional: Limpiar volúmenes (descomenta si quieres eliminar datos)
# echo "🧹 Limpiando volúmenes..."
# docker-compose -f docker-compose-monitoring.yml down -v

# Opcional: Limpiar imágenes no utilizadas
# echo "🧹 Limpiando imágenes no utilizadas..."
# docker system prune -f

echo "✅ Stack de Monitoreo y Logging detenido correctamente"
echo ""
echo "ℹ️  Para reiniciar el stack, ejecuta:"
echo "./start-monitoring.sh"
