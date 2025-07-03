# 🚀 CI/CD Pipeline - Villa Alfredo Project

Este directorio contiene la configuración completa del pipeline CI/CD para el proyecto Villa Alfredo, incluyendo Jenkins, análisis de seguridad, pruebas automatizadas y monitoreo con Grafana.

## 📋 Componentes del Sistema

### 🔧 Jenkins
- **Master**: Coordinador principal del pipeline
- **Agent**: Ejecutor de tareas en contenedor Docker
- **Plugins**: Configuración automática con plugins esenciales

### 🔍 Análisis de Seguridad
- **SonarQube**: Análisis de calidad de código
- **OWASP Dependency Check**: Detección de vulnerabilidades en dependencias
- **Semgrep**: Análisis estático de seguridad (SAST)
- **NPM Audit**: Auditoría de paquetes Node.js

### 📊 Monitoreo y Observabilidad
- **Grafana**: Dashboards y visualización
- **Prometheus**: Recolección de métricas
- **Alertas**: Notificaciones automáticas

## 🛠️ Configuración Inicial

### Prerrequisitos
```bash
# Verificar que tienes instalado:
docker --version
docker-compose --version
git --version
```

### 1. Configuración del Entorno
```bash
# Navegar al directorio del proyecto
cd /path/to/project

# Ejecutar script de configuración
chmod +x ci-cd/setup.sh
./ci-cd/setup.sh
```

### 2. Configurar Variables de Entorno
Edita el archivo `.env` creado por el script:

```bash
# GitHub Configuration
GITHUB_USERNAME=tu-usuario-github
GITHUB_TOKEN=ghp_tu_token_personal

# AWS Configuration
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_ACCOUNT_ID=123456789012

# SonarQube Configuration (se genera automáticamente)
SONARQUBE_TOKEN=tu-token-sonarqube

# Slack Configuration (opcional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

### 3. Levantar Servicios
```bash
cd ci-cd
docker-compose up -d

# Verificar estado
docker-compose ps
```

## 🌐 URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Jenkins | http://localhost:8080 | admin/admin123 |
| Grafana | http://localhost:3000 | admin/admin123 |
| SonarQube | http://localhost:9000 | admin/admin |
| Prometheus | http://localhost:9090 | - |

## 📈 Pipeline de CI/CD

### Etapas del Pipeline

1. **🔧 Setup**
   - Configuración del entorno Node.js
   - Checkout del código fuente
   - Limpieza del workspace

2. **📦 Install Dependencies**
   - Instalación de dependencias del backend
   - Validación de configuración de Terraform

3. **🔍 Code Quality & Security Analysis**
   - **ESLint**: Análisis de estilo de código
   - **SonarQube**: Análisis de calidad y cobertura
   - **Dependency Security Scan**: Vulnerabilidades en dependencias
   - **SAST Security Scan**: Análisis estático de seguridad

4. **🧪 Testing**
   - **Unit Tests**: Pruebas unitarias con Jest
   - **Integration Tests**: Pruebas de integración
   - **Coverage Reports**: Informes de cobertura

5. **🏗️ Build**
   - Compilación de TypeScript
   - Generación de artefactos

6. **🐳 Docker Build**
   - Construcción de imagen Docker
   - Tag con versión y commit hash

7. **🔒 Security Gate**
   - Quality Gate de SonarQube
   - Verificación de vulnerabilidades críticas
   - Límites de seguridad

8. **🚀 Deploy**
   - Push a Amazon ECR
   - Despliegue con Terraform
   - Smoke tests

### Triggers del Pipeline

- **Push a main/develop**: Ejecución automática
- **Pull Requests**: Verificación de calidad
- **Scheduled**: Scan completo semanal
- **Manual**: Ejecución bajo demanda

## 🔒 Configuración de Seguridad

### Quality Gates
```yaml
# Límites de calidad en SonarQube
Coverage: > 70%
Duplicated Lines: < 3%
Maintainability Rating: A
Reliability Rating: A
Security Rating: A
```

### Límites de Vulnerabilidades
```yaml
# Límites en el pipeline
Critical Vulnerabilities: 0
High Vulnerabilities: < 5
Medium Vulnerabilities: < 20
```

## 📊 Dashboards y Métricas

### Métricas de Jenkins
- Tiempo de ejecución de builds
- Tasa de éxito/fallo
- Cola de trabajos
- Uso de agentes

### Métricas de Aplicación
- Rendimiento de la API
- Errores y excepciones
- Uso de recursos
- Disponibilidad

### Métricas de Seguridad
- Vulnerabilidades detectadas
- Cobertura de tests
- Quality Gates

## 🛠️ Scripts de Utilidad

### Gestión de Servicios
```bash
# Iniciar servicios
./scripts/ci-cd-utils.sh start

# Detener servicios
./scripts/ci-cd-utils.sh stop

# Ver logs
./scripts/ci-cd-utils.sh logs jenkins

# Estado de servicios
./scripts/ci-cd-utils.sh status

# Backup de datos
./scripts/ci-cd-utils.sh backup
```

### Comandos Docker
```bash
# Ver logs de Jenkins
docker-compose logs -f jenkins

# Acceder a contenedor de Jenkins
docker-compose exec jenkins bash

# Reiniciar servicio específico
docker-compose restart grafana
```

## 🔧 Configuración Avanzada

### Configurar Webhooks de GitHub

1. Ve a tu repositorio en GitHub
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://tu-jenkins-url:8080/github-webhook/`
4. Content type: `application/json`
5. Events: Push events, Pull requests

### Configurar Notificaciones Slack

1. Crear webhook en Slack
2. Actualizar `SLACK_WEBHOOK_URL` en `.env`
3. Configurar canal en Jenkinsfile: `SLACK_CHANNEL = '#ci-cd'`

### Personalizar Dashboards Grafana

1. Acceder a Grafana (http://localhost:3000)
2. Importar dashboards desde `grafana/dashboards/`
3. Configurar alertas en base a métricas

## 🐛 Troubleshooting

### Problemas Comunes

#### Jenkins no inicia
```bash
# Verificar logs
docker-compose logs jenkins

# Verificar permisos
sudo chown -R 1000:1000 jenkins_home/
```

#### SonarQube falla al iniciar
```bash
# Aumentar límites del sistema
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

#### Pipeline falla en análisis de seguridad
```bash
# Verificar configuración de SonarQube
curl -u admin:admin http://localhost:9000/api/system/status

# Regenerar token
curl -u admin:admin -X POST "http://localhost:9000/api/user_tokens/generate" -d "name=jenkins-token"
```

## 📚 Documentación Adicional

- [Configuración de Jenkins](./docs/jenkins-configuration.md)
- [Configuración de SonarQube](./docs/sonarqube-setup.md)
- [Dashboards de Grafana](./docs/grafana-dashboards.md)
- [Análisis de Seguridad](./docs/security-analysis.md)
- [Deployment con Terraform](./docs/terraform-deployment.md)

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama para feature (`git checkout -b feature/amazing-feature`)
3. Commit cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abrir Pull Request

## 📞 Soporte

Para soporte y consultas:
- **Email**: devops@villalfredo.com
- **Slack**: #ci-cd-support
- **Issues**: GitHub Issues

---

**Última actualización**: Julio 2025
**Versión**: 1.0.0
**Mantenido por**: DevOps Team - Villa Alfredo
