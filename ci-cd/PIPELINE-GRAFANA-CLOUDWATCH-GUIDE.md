# 📊 Guía Completa: Pipeline CI/CD con Grafana y CloudWatch

## 🎯 Resumen

Esta guía te ayuda a configurar un pipeline completo de CI/CD que envía logs a CloudWatch y los visualiza en Grafana, incluyendo métricas de infraestructura con Prometheus.

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Jenkins     │    │   CloudWatch    │    │     Grafana     │
│   (Pipeline)    │───▶│     (Logs)      │───▶│ (Visualización) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              ▲
         ▼                                              │
┌─────────────────┐    ┌─────────────────┐             │
│   Prometheus    │───▶│    Métricas     │─────────────┘
│  (Recolector)   │    │ (Infraestructura│
└─────────────────┘    └─────────────────┘
```

## 📋 Componentes Configurados

### 1. **Jenkins Pipeline**
- ✅ Envío automático de logs a CloudWatch
- ✅ Métricas de duración y estado de pipeline
- ✅ Logging estructurado en JSON
- ✅ Integración con credenciales AWS

### 2. **Grafana Dashboards**
- ✅ Dashboard de monitoreo de pipeline CI/CD
- ✅ Dashboard de logs de AWS CloudWatch
- ✅ Dashboard de métricas de infraestructura
- ✅ Configuración automática de datasources

### 3. **CloudWatch Integration**
- ✅ Log groups automáticos para Jenkins
- ✅ Structured logging con metadata
- ✅ Retention policies configurables

### 4. **Prometheus Monitoring**
- ✅ Métricas de sistema (CPU, memoria, disco)
- ✅ Métricas de contenedores Docker
- ✅ Métricas de Jenkins y SonarQube

## 🚀 Pasos de Configuración

### Paso 1: Configurar Credenciales AWS

```bash
# 1. Navegar al directorio del proyecto
cd d:/UPAO/IaC/project/ci-cd

# 2. Ejecutar script de configuración
chmod +x setup-cloudwatch-integration.sh
./setup-cloudwatch-integration.sh
```

### Paso 2: Editar Variables de Entorno

Edita el archivo `.env` creado:

```bash
# AWS Configuration for CloudWatch
AWS_ACCESS_KEY_ID=AKIA...tu_access_key
AWS_SECRET_ACCESS_KEY=tu_secret_key_aqui
AWS_DEFAULT_REGION=us-east-1

# Jenkins Agent Secrets
JENKINS_NODEJS_AGENT_SECRET=tu_secret_nodejs
JENKINS_TERRAFORM_AGENT_SECRET=tu_secret_terraform
JENKINS_SECURITY_AGENT_SECRET=tu_secret_security

# Grafana Configuration
GF_SECURITY_ADMIN_PASSWORD=admin123
```

### Paso 3: Iniciar el Stack Completo

```bash
# Iniciar todos los servicios
./start-monitoring-stack.sh
```

### Paso 4: Configurar Credenciales en Jenkins

1. **Accede a Jenkins**: http://localhost:8080
   - Usuario: `admin`
   - Contraseña: `admin123`

2. **Configurar credenciales AWS**:
   - Ve a `Manage Jenkins` > `Manage Credentials`
   - Agrega `Global credentials (unrestricted)`
   - Tipo: `Secret text`
   - Secret: Tu AWS Access Key
   - ID: `aws-access-key-id`

3. **Repetir para AWS Secret Key**:
   - Secret: Tu AWS Secret Key
   - ID: `aws-secret-access-key`

### Paso 5: Ejecutar el Pipeline

1. **Crear nuevo pipeline job**:
   - `New Item` > `Pipeline`
   - Nombre: `villa-alfredo-pipeline`

2. **Configurar pipeline**:
   - Pipeline script from SCM
   - Git repository: tu repositorio
   - Script path: `ci-cd/Jenkinsfile`

3. **Ejecutar el pipeline**:
   - Click en `Build with Parameters`
   - Selecciona: Action=`plan`, Agent Type=`terraform`
   - Click `Build`

### Paso 6: Verificar Dashboards en Grafana

1. **Accede a Grafana**: http://localhost:3000
   - Usuario: `admin`
   - Contraseña: `admin123`

2. **Dashboards disponibles**:
   - **Pipeline Monitoring**: `/d/pipeline-monitoring`
   - **CloudWatch Logs**: `/d/cloudwatch-logs`
   - **Infrastructure Metrics**: `/d/infrastructure-metrics`

## 📊 Dashboards y Métricas

### Dashboard 1: Pipeline CI/CD Monitoring

**Paneles incluidos:**
- 📈 Estado de ejecución del pipeline (SUCCESS/FAILURE)
- ⏱️ Tendencias de duración del pipeline
- 📝 Logs recientes del pipeline
- 🔍 Logs de errores con filtros

**Métricas clave:**
- Build success rate
- Average build duration
- Failed stages identification
- Resource usage during builds

### Dashboard 2: AWS CloudWatch Logs

**Paneles incluidos:**
- 🌐 Logs de API Gateway (errores HTTP 4xx/5xx)
- ⚡ Logs de Lambda functions
- 🗄️ Logs de RDS database
- 🐳 Logs de contenedores ECS
- 📊 Métricas de tiempo de respuesta
- 📈 Rate de errores por código de estado

### Dashboard 3: Infrastructure Metrics

**Paneles incluidos:**
- 💻 CPU y memoria del sistema
- 💾 Uso de disco
- 🌐 I/O de red
- 🐳 Estado de contenedores Docker
- 🏗️ Estado de Jenkins (queue, executors)
- 🔍 Estado de SonarQube

## 🔧 Configuración Avanzada

### Alertas en Grafana

```yaml
# Ejemplo de alerta para pipeline failures
groups:
  - name: jenkins-alerts
    rules:
      - alert: PipelineFailure
        expr: jenkins_builds_last_build_result_ordinal == 4
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Jenkins pipeline failed"
          description: "Pipeline {{ $labels.job }} has failed"
```

### Retention Policies CloudWatch

```bash
# Configurar retention de logs (30 días)
aws logs put-retention-policy \
    --log-group-name /jenkins/pipeline-logs \
    --retention-in-days 30
```

### Backup de Configuración

```bash
# Crear backup de configuración Grafana
docker exec grafana grafana-cli admin export-dashboard > backup-dashboards.json
```

## 🎯 Log Queries Útiles

### CloudWatch Insights Queries

**Errores en el pipeline:**
```sql
fields @timestamp, @message, level
| filter level = "ERROR"
| sort @timestamp desc
| limit 100
```

**Duración promedio por stage:**
```sql
fields @timestamp, stage, duration
| filter ispresent(duration)
| stats avg(duration) by stage
```

**Top errores por frecuencia:**
```sql
fields @message
| filter @message like /ERROR/
| stats count() as error_count by @message
| sort error_count desc
| limit 10
```

## 🔍 Troubleshooting

### Problemas Comunes

**1. Jenkins no puede enviar logs a CloudWatch**
```bash
# Verificar credenciales AWS
aws sts get-caller-identity

# Verificar permisos
aws logs describe-log-groups --log-group-name-prefix "/jenkins"
```

**2. Grafana no muestra datos de CloudWatch**
```bash
# Verificar configuración de datasource
curl -u admin:admin123 http://localhost:3000/api/datasources
```

**3. Prometheus no encuentra targets**
```bash
# Verificar conectividad
docker exec prometheus wget -qO- http://jenkins:8080/prometheus
```

### Logs de Debug

**Jenkins logs:**
```bash
docker logs jenkins-master
```

**Grafana logs:**
```bash
docker logs grafana
```

**Prometheus logs:**
```bash
docker logs prometheus
```

## 📈 Próximos Pasos

1. **Configurar alertas automáticas**
2. **Integrar con Slack/Teams para notificaciones**
3. **Agregar métricas custom de aplicación**
4. **Configurar dashboards por ambiente (dev/staging/prod)**
5. **Implementar auto-scaling basado en métricas**

## 🛡️ Seguridad

- ✅ Credenciales AWS almacenadas en Jenkins Credentials
- ✅ Acceso a logs limitado por IAM roles
- ✅ Dashboards de Grafana con autenticación
- ✅ Logs sensibles filtrados automáticamente

## 📚 Referencias

- [Grafana CloudWatch Data Source](https://grafana.com/docs/grafana/latest/datasources/cloudwatch/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/)
- [AWS CloudWatch Logs](https://docs.aws.amazon.com/cloudwatch/latest/logs/)

---

**¡Tu pipeline está listo! 🎉**

Ahora tienes visibilidad completa de tu infraestructura y pipelines con logs centralizados y métricas en tiempo real.
