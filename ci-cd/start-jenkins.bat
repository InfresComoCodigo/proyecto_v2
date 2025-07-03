@echo off
REM Script para iniciar Jenkins con Terraform en Windows

echo 🚀 Iniciando Jenkins con soporte para Terraform...
echo.

REM Verificar si Docker está ejecutándose
echo 🔍 Verificando Docker Desktop...
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Desktop no está ejecutándose!
    echo.
    echo 📋 Para solucionar este problema:
    echo 1. Abrir Docker Desktop desde el menú de inicio
    echo 2. Esperar a que aparezca el ícono en la bandeja del sistema
    echo 3. Verificar que muestre "Docker Desktop is running"
    echo 4. Ejecutar nuevamente este script
    echo.
    echo 💡 Tip: Docker puede tardar unos minutos en iniciar completamente
    echo.
    pause
    exit /b 1
)

echo ✅ Docker Desktop está funcionando
echo.

REM Verificar conexión con Docker daemon
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ No se puede conectar al daemon de Docker
    echo 🔄 Intentando reiniciar Docker Desktop...
    echo.
    echo Por favor, reinicia Docker Desktop manualmente y vuelve a ejecutar este script
    pause
    exit /b 1
)

echo ✅ Conexión con Docker verificada
echo.

REM Crear directorios necesarios
if not exist "jenkins_home" mkdir jenkins_home
if not exist "logs" mkdir logs

REM Construir y ejecutar contenedores
echo 📦 Construyendo imagen de Jenkins personalizada...
docker-compose build

echo 🔧 Iniciando servicios...
docker-compose up -d

REM Esperar a que Jenkins esté listo
echo ⏳ Esperando a que Jenkins esté listo...
timeout /t 30 /nobreak >nul

REM Mostrar información de acceso
echo.
echo ✅ Jenkins está ejecutándose!
echo 🌐 Acceder a: http://localhost:8080
echo.

REM Mostrar contraseña inicial de administrador
echo 🔑 Contraseña inicial de administrador:
docker exec jenkins-terraform cat /var/jenkins_home/secrets/initialAdminPassword

echo.
echo 📋 Comandos útiles:
echo   - Ver logs: docker-compose logs -f jenkins
echo   - Detener: docker-compose down
echo   - Reiniciar: docker-compose restart jenkins
echo   - Acceder al contenedor: docker exec -it jenkins-terraform bash
echo.
echo 🛠️ Configuración sugerida:
echo   1. Acceder a Jenkins en http://localhost:8080
echo   2. Usar la contraseña mostrada arriba
echo   3. Instalar plugins sugeridos
echo   4. Crear un usuario administrador
echo   5. Configurar credenciales de AWS
echo   6. Crear un nuevo pipeline usando el Jenkinsfile
echo.

pause
