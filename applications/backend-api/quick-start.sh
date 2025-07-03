#!/bin/bash
# Script de inicio rápido para el Backend API

echo "🚀 Iniciando Backend API..."
echo ""

echo "1. Instalando dependencias..."
npm install

echo ""
echo "2. Compilando TypeScript..."
npm run build

echo ""
echo "3. Ejecutando pruebas..."
npm test

echo ""
echo "4. Iniciando servidor..."
echo "   El servidor se iniciará en http://localhost:4000"
echo "   Presiona Ctrl+C para detener"
echo ""

npm start
