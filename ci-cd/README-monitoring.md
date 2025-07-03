# Stack de Monitoreo y Logging para Jenkins

Este proyecto proporciona un stack completo de monitoreo y logging para Jenkins usando Docker Compose, incluyendo:

## 🏗️ Arquitectura del Stack

### Servicios Principales:
- **Jenkins** - Servidor CI/CD con plugins de monitoreo
- **Grafana** - Dashboards y visualización de métricas
- **Prometheus** - Recolección y almacenamiento de métricas
- **Elasticsearch** - Almacenamiento y búsqueda de logs
- **Logstash** - Procesamiento y enriquecimiento de logs
- **Kibana** - Visualización y análisis de logs
- **Alertmanager** - Gestión de alertas y notificaciones

### Servicios de Soporte:
- **Node Exporter** - Métricas del sistema
- **cAdvisor** - Métricas de contenedores
- **Traefik** - Proxy reverso y balanceador de carga

## 🚀 Inicio Rápido

### Prerrequisitos:
```bash
# Docker y Docker Compose instalados
docker --version
docker-compose --version

# Permisos de ejecución para scripts
chmod +x start-monitoring.sh stop-monitoring.sh
```

### Iniciar el Stack:
```bash
# Iniciar todos los servicios
./start-monitoring.sh

# O manualmente:
docker-compose -f docker-compose-monitoring.yml up -d
```

### Detener el Stack:
```bash
# Detener todos los servicios
./stop-monitoring.sh

# O manualmente:
docker-compose -f docker-compose-monitoring.yml down
```

## 📊 Acceso a Servicios

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Jenkins | http://localhost:8080 | admin/admin |
| Grafana | http://localhost:3000 | admin/admin123 |
| Prometheus | http://localhost:9090 | N/A |
| Kibana | http://localhost:5601 | N/A |
| Traefik Dashboard | http://localhost:8082 | N/A |
| Alertmanager | http://localhost:9093 | N/A |

## 🔧 Configuración

### Jenkins:
- Plugins preinstalados para monitoreo y métricas
- Configuración automática de endpoints de Prometheus
- Logs enviados automáticamente a Logstash

### Grafana:
- Dashboards preconfiguramos para Jenkins
- Fuentes de datos automáticas (Prometheus, Elasticsearch)
- Alertas configuradas

### Prometheus:
- Scraping automático de todos los servicios
- Reglas de alertas predefinidas
- Retención de datos de 200 horas

### Logstash:
- Procesamiento automático de logs de Jenkins
- Enriquecimiento y parseo de logs
- Detección automática de eventos de build

## 📈 Dashboards Disponibles

### Jenkins Monitoring Dashboard:
- Estado de builds (éxito/fallo)
- Duración de builds
- Uso de recursos (CPU, memoria)
- Métricas de cola de builds

### System Monitoring Dashboard:
- Métricas del sistema (CPU, memoria, disco)
- Métricas de contenedores
- Estado de servicios

### Logs Dashboard (Kibana):
- Logs de Jenkins en tiempo real
- Filtros por nivel de log
- Análisis de errores y warnings

## 🚨 Alertas

### Alertas Configuradas:
- Jenkins inactivo
- Alto uso de CPU/memoria
- Builds fallando frecuentemente
- Servicios caídos
- Espacio en disco bajo

### Canales de Notificación:
- Email
- Slack (requiere configuración)
- Webhooks personalizados

## 🔍 Monitoreo de Logs

### Tipos de Logs Procesados:
- Logs de Jenkins (builds, errores, warnings)
- Logs del sistema
- Logs de aplicaciones

### Campos Enriquecidos:
- Timestamp normalizado
- Nivel de log
- Servicio origen
- Eventos de build
- Correlación de errores

## 📋 Comandos Útiles

### Ver logs en tiempo real:
```bash
# Todos los servicios
docker-compose -f docker-compose-monitoring.yml logs -f

# Servicio específico
docker-compose -f docker-compose-monitoring.yml logs -f jenkins
```

### Reiniciar un servicio:
```bash
docker-compose -f docker-compose-monitoring.yml restart jenkins
```

### Verificar estado de servicios:
```bash
docker-compose -f docker-compose-monitoring.yml ps
```

### Acceder a un contenedor:
```bash
docker-compose -f docker-compose-monitoring.yml exec jenkins bash
```

## 🛠️ Personalización

### Añadir nuevos dashboards:
1. Colocar archivos JSON en `grafana/dashboards/`
2. Reiniciar Grafana

### Modificar alertas:
1. Editar `prometheus/rules/alerts.yml`
2. Reiniciar Prometheus

### Configurar notificaciones:
1. Editar `alertmanager/alertmanager.yml`
2. Configurar webhooks/email/Slack
3. Reiniciar Alertmanager

## 📊 Métricas Disponibles

### Jenkins:
- jenkins_builds_total
- jenkins_builds_success_total
- jenkins_builds_failed_total
- jenkins_builds_duration_milliseconds
- jenkins_queue_size
- jenkins_executor_count

### Sistema:
- node_cpu_seconds_total
- node_memory_MemTotal_bytes
- node_filesystem_avail_bytes
- node_load1

### Contenedores:
- container_cpu_usage_seconds_total
- container_memory_usage_bytes
- container_fs_usage_bytes

## 🔒 Seguridad

### Configuraciones de Seguridad:
- Autenticación habilitada en todos los servicios
- Comunicación interna entre contenedores
- Volúmenes seguros para persistencia
- Proxy reverso con Traefik

### Recomendaciones:
- Cambiar credenciales por defecto
- Configurar HTTPS con certificados
- Implementar autenticación LDAP/SSO
- Configurar backups automáticos

## 📚 Troubleshooting

### Problemas Comunes:

#### Servicios no inician:
```bash
# Verificar logs
docker-compose -f docker-compose-monitoring.yml logs service_name

# Verificar puertos
netstat -tlnp | grep :puerto
```

#### Prometheus no scraping:
```bash
# Verificar configuración
curl http://localhost:9090/config

# Verificar targets
curl http://localhost:9090/targets
```

#### Grafana no muestra datos:
```bash
# Verificar fuentes de datos
curl http://localhost:3000/api/datasources

# Verificar conectividad
curl http://localhost:3000/api/health
```

## 🔄 Actualizaciones

### Actualizar imágenes:
```bash
docker-compose -f docker-compose-monitoring.yml pull
docker-compose -f docker-compose-monitoring.yml up -d
```

### Backup de configuraciones:
```bash
# Backup de Grafana
docker cp grafana:/var/lib/grafana ./backup/grafana

# Backup de Prometheus
docker cp prometheus:/prometheus ./backup/prometheus
```

## 🤝 Contribuir

Para contribuir a este proyecto:

1. Fork el repositorio
2. Crea una rama feature
3. Realiza tus cambios
4. Añade tests si es necesario
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo LICENSE.md para detalles.

## 🆘 Soporte

Para obtener soporte:
- Crear un issue en GitHub
- Consultar la documentación oficial de cada servicio
- Revisar los logs de servicios

---

**Última actualización:** Julio 2025
**Versión:** 1.0.0
