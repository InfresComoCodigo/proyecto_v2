@echo off
REM Script para verificar y configurar Docker Desktop en Windows

echo 🐳 Verificador de Docker Desktop para Windows
echo ==========================================
echo.

REM Verificar si Docker Desktop está instalado
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker no está instalado o no está en el PATH
    echo.
    echo 📥 Para instalar Docker Desktop:
    echo 1. Ir a https://www.docker.com/products/docker-desktop
    echo 2. Descargar Docker Desktop para Windows
    echo 3. Ejecutar el instalador
    echo 4. Reiniciar el sistema si es necesario
    echo.
    pause
    exit /b 1
)

echo ✅ Docker está instalado
echo.

REM Verificar si Docker Desktop está ejecutándose
echo 🔍 Verificando estado de Docker Desktop...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Desktop no está ejecutándose
    echo.
    echo 🚀 Intentando iniciar Docker Desktop...
    
    REM Intentar iniciar Docker Desktop
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" 2>nul
    if %errorlevel% neq 0 (
        echo ⚠️ No se pudo iniciar automáticamente Docker Desktop
        echo.
        echo 📋 Inicia Docker Desktop manualmente:
        echo 1. Buscar "Docker Desktop" en el menú de inicio
        echo 2. Hacer clic para abrir
        echo 3. Esperar a que aparezca el ícono en la bandeja del sistema
        echo 4. Ejecutar nuevamente este script
        echo.
    ) else (
        echo ✅ Docker Desktop iniciado
        echo ⏳ Esperando a que Docker esté listo...
        
        REM Esperar hasta que Docker esté disponible (máximo 2 minutos)
        set /a counter=0
        :wait_loop
        timeout /t 5 /nobreak >nul
        docker version >nul 2>&1
        if %errorlevel% equ 0 goto docker_ready
        
        set /a counter+=1
        if %counter% lss 24 (
            echo Esperando... (%counter%/24^)
            goto wait_loop
        )
        
        echo ❌ Docker tardó demasiado en iniciar
        echo 🔄 Intenta reiniciar Docker Desktop manualmente
        pause
        exit /b 1
        
        :docker_ready
        echo ✅ Docker está listo!
    )
    echo.
else
    echo ✅ Docker Desktop está ejecutándose
    echo.
fi

REM Verificar información de Docker
echo 📊 Información de Docker:
echo -------------------------
docker version --format "Cliente: {{.Client.Version}}"
docker version --format "Servidor: {{.Server.Version}}"
echo.

REM Verificar recursos disponibles
echo 🔧 Verificando configuración...
docker system info | findstr "CPUs\|Total Memory" 2>nul
echo.

REM Probar funcionalidad básica
echo 🧪 Probando funcionalidad básica...
docker run --rm hello-world >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Docker funciona correctamente
) else (
    echo ❌ Hay problemas con Docker
    echo 💡 Intenta reiniciar Docker Desktop
)
echo.

echo 🎉 Verificación completada!
echo.
echo 📋 Próximos pasos:
echo 1. Si todo está OK, ejecutar: start-jenkins.bat
echo 2. Si hay problemas, reiniciar Docker Desktop
echo 3. Verificar configuración en Docker Desktop Settings
echo.

pause
