# Jenkins CI/CD Pipeline para Terraform

Este directorio contiene la configuración completa para un pipeline de Jenkins que puede ejecutar `terraform apply` y `terraform destroy` de forma automatizada.

## 🏗️ Arquitectura

- **Dockerfile**: Imagen personalizada de Jenkins con Terraform, AWS CLI, Docker y Node.js
- **Jenkinsfile**: Pipeline declarativo con etapas para validación, planificación y aplicación/destrucción
- **docker-compose.yml**: Orquestación de servicios de Jenkins
- **Scripts de ayuda**: Automatización para inicio y parada del entorno

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker Desktop instalado y ejecutándose
- Docker Compose incluido (viene con Docker Desktop)
- Acceso a AWS (credenciales configuradas)
- Repositorio Git con código de Terraform

**⚠️ Importante para Windows:**
- Docker Desktop debe estar ejecutándose
- Habilitar "Use the WSL 2 based engine" en Docker Desktop settings
- Asegurarse de que el motor de Docker esté iniciado

### 1. Verificar Docker Desktop

**⚠️ IMPORTANTE: Antes de ejecutar Jenkins, asegúrate de que Docker Desktop esté ejecutándose:**

**Verificación automática:**
```bash
# En bash (Git Bash, WSL, Linux, macOS)
./check-docker.sh

# En Command Prompt (Windows)
check-docker.bat
```

**Verificación manual:**

1. **Abrir Docker Desktop**:
   - Buscar "Docker Desktop" en el menú de inicio de Windows
   - Hacer clic para abrir la aplicación
   - Esperar a que aparezca el ícono de Docker en la bandeja del sistema (área de notificaciones)

2. **Verificar que Docker está funcionando**:
   ```cmd
   docker version
   ```
   Si ves información de cliente y servidor, Docker está listo.

3. **Si Docker no responde**:
   - Esperar unos minutos a que Docker termine de iniciar
   - El ícono en la bandeja debe mostrar "Docker Desktop is running"
   - Reiniciar Docker Desktop si es necesario

### 2. Iniciar Jenkins

**En Linux/macOS:**
```bash
chmod +x start-jenkins.sh
./start-jenkins.sh
```

**En Windows:**
```cmd
start-jenkins.bat
```

### 2. Configuración Inicial

1. Acceder a http://localhost:8080
2. Usar la contraseña inicial mostrada por el script
3. Instalar plugins sugeridos
4. Crear usuario administrador
5. Configurar credenciales de AWS:
   - Ir a "Manage Jenkins" > "Manage Credentials"
   - Agregar credenciales de tipo "AWS Credentials"
   - ID: `aws-credentials`

### 3. Crear Pipeline

1. Crear nuevo job de tipo "Pipeline"
2. En "Pipeline", seleccionar "Pipeline script from SCM"
3. Configurar repositorio Git
4. Especificar ruta del Jenkinsfile: `ci-cd/Jenkinsfile`

## 📋 Características del Pipeline

### Parámetros de Ejecución

- **ACTION**: `apply` o `destroy`
- **AUTO_APPROVE**: Aprobar automáticamente los cambios
- **TERRAFORM_WORKSPACE**: Workspace de Terraform a usar

### Etapas del Pipeline

1. **Checkout**: Clonar repositorio
2. **Validate Environment**: Verificar herramientas instaladas
3. **Terraform Init**: Inicializar Terraform y seleccionar workspace
4. **Terraform Validate**: Validar y formatear código
5. **Terraform Plan**: Generar plan de ejecución
6. **Review Plan**: Revisión manual (si AUTO_APPROVE=false)
7. **Terraform Apply/Destroy**: Ejecutar acción seleccionada
8. **Save State**: Respaldar estado de Terraform
9. **Test Infrastructure**: Pruebas post-aplicación

### Variables de Entorno

- `AWS_DEFAULT_REGION`: Región de AWS por defecto
- `TF_VAR_environment`: Environment para Terraform
- `TERRAFORM_DIR`: Directorio donde están los archivos .tf

## 🔧 Configuración Avanzada

### Credenciales de AWS

El pipeline busca credenciales con ID `aws-credentials`. Configurar en Jenkins:

1. Manage Jenkins > Manage Credentials
2. Add Credentials > AWS Credentials
3. ID: `aws-credentials`
4. Agregar Access Key ID y Secret Access Key

### Notificaciones

El Jenkinsfile incluye secciones comentadas para notificaciones Slack:

```groovy
// Descomentar y configurar para habilitar notificaciones
slackSend(
    channel: '#devops',
    color: 'good',
    message: "✅ Terraform apply completado"
)
```

### Workspaces de Terraform

El pipeline soporta múltiples workspaces:

- `default`: Entorno por defecto
- `dev`: Desarrollo
- `staging`: Pruebas
- `prod`: Producción

## 📁 Estructura de Archivos

```
ci-cd/
├── Dockerfile              # Imagen de Jenkins personalizada
├── Jenkinsfile             # Definición del pipeline
├── docker-compose.yml      # Orquestación de servicios
├── start-jenkins.sh        # Script de inicio (Linux/macOS)
├── start-jenkins.bat       # Script de inicio (Windows)
├── stop-jenkins.sh         # Script de parada
├── check-docker.sh         # Verificador de Docker (bash)
├── check-docker.bat        # Verificador de Docker (Windows)
├── validate-setup.sh       # Validador de configuración
├── jenkins-job-config.xml  # Configuración de job ejemplo
└── README.md              # Esta documentación
```

## 🛠️ Comandos Útiles

### Docker

```bash
# Ver logs de Jenkins
docker-compose logs -f jenkins

# Acceder al contenedor
docker exec -it jenkins-terraform bash

# Reiniciar Jenkins
docker-compose restart jenkins

# Detener todo
docker-compose down

# Detener y limpiar volúmenes
docker-compose down -v
```

### Jenkins CLI

```bash
# Descargar Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Crear job desde archivo
java -jar jenkins-cli.jar -s http://localhost:8080 create-job terraform-pipeline < job-config.xml

# Ejecutar job
java -jar jenkins-cli.jar -s http://localhost:8080 build terraform-pipeline -p ACTION=apply
```

## 🔍 Troubleshooting

### Problema: Docker Desktop no está ejecutándose (Windows)

**Error típico**: `open //./pipe/dockerDesktopLinuxEngine: El sistema no puede encontrar el archivo especificado`

**Soluciones**:
1. **Iniciar Docker Desktop**:
   - Abrir Docker Desktop desde el menú de inicio
   - Esperar a que aparezca el ícono en la bandeja del sistema
   - Verificar que muestre "Docker Desktop is running"

2. **Verificar estado de Docker**:
   ```cmd
   docker version
   docker ps
   ```

3. **Reiniciar Docker Desktop**:
   - Clic derecho en el ícono de Docker en la bandeja del sistema
   - Seleccionar "Restart"
   - Esperar a que se reinicie completamente

4. **Configurar WSL 2 (recomendado)**:
   - Abrir Docker Desktop Settings
   - Ir a "General"
   - Habilitar "Use the WSL 2 based engine"
   - Aplicar y reiniciar

5. **Verificar recursos**:
   - En Docker Desktop Settings > "Resources"
   - Asignar suficiente memoria (mínimo 4GB recomendado)
   - Asignar suficiente espacio en disco

### Problema: Jenkins no puede acceder a Docker

**Solución**: Verificar que el socket de Docker está montado correctamente:
```bash
docker exec jenkins-terraform docker ps
```

### Problema: Terraform no encuentra archivos .tf

**Solución**: Verificar la variable `TERRAFORM_DIR` en el Jenkinsfile y la estructura del repositorio.

### Problema: Credenciales de AWS no funcionan

**Solución**: 
1. Verificar que las credenciales están configuradas con ID `aws-credentials`
2. Verificar permisos IAM del usuario
3. Verificar región configurada

### Problema: Error de permisos en scripts

**Solución**: Dar permisos de ejecución:
```bash
chmod +x start-jenkins.sh stop-jenkins.sh
```

## 🔒 Seguridad

### Mejores Prácticas

1. **Credenciales**: Nunca hardcodear credenciales en el código
2. **IAM**: Usar roles con permisos mínimos necesarios
3. **Secrets**: Usar Jenkins Credentials para datos sensibles
4. **Network**: Limitar acceso a Jenkins solo a IPs autorizadas
5. **Backups**: Respaldar estado de Terraform regularmente

### Configuración de Seguridad

```groovy
// En Jenkinsfile, usar credenciales seguras
withCredentials([
    aws(credentialsId: 'aws-credentials', 
        accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
]) {
    // Comandos que necesitan AWS
}
```

## 📊 Monitoreo

### Métricas del Pipeline

- Tiempo de ejecución por etapa
- Tasa de éxito/fallo
- Recursos creados/destruidos
- Costos de infraestructura

### Logs Importantes

- Terraform plan output
- AWS CloudTrail events
- Jenkins build console
- Docker container logs

## 🚀 Mejoras Futuras

- [ ] Integración con herramientas de testing (Terratest)
- [ ] Notificaciones por email/Slack
- [ ] Dashboard de métricas con Grafana
- [ ] Integración con sistemas de tickets (Jira)
- [ ] Análisis de costos automático
- [ ] Políticas de seguridad con Sentinel
- [ ] Multi-cloud support (Azure, GCP)

## 📞 Soporte

Para problemas o sugerencias:

1. Revisar logs de Jenkins y Docker
2. Verificar documentación de Terraform
3. Consultar documentación de AWS
4. Crear issue en el repositorio del proyecto
