@echo off
REM Script de inicio rápido para el Backend API en Windows

echo 🚀 Iniciando Backend API...
echo.

echo 1. Instalando dependencias...
call npm install

echo.
echo 2. Compilando TypeScript...
call npm run build

echo.
echo 3. Ejecutando pruebas...
call npm test

echo.
echo 4. Iniciando servidor...
echo    El servidor se iniciará en http://localhost:3000
echo    Presiona Ctrl+C para detener
echo.

call npm start
