# Jenkins Pipelines para Terraform

Este directorio contiene dos pipelines de Jenkins separados para gestionar la infraestructura con Terraform:

## 📁 Archivos

- **`Jenkinsfile-apply`**: Pipeline para desplegar/aplicar infraestructura
- **`Jenkinsfile-destroy`**: Pipeline para destruir infraestructura
- **`Jenkinsfile`**: Pipeline original (mantener como referencia)

## 🚀 Jenkinsfile-apply (Despliegue)

### Propósito
Pipeline optimizado para el despliegue seguro de infraestructura.

### Características
- ✅ Validación completa de configuración
- 🔒 Análisis de seguridad básico
- 📋 Plan detallado con resumen de cambios
- ⏸️ Pausa para revisión manual (opcional)
- 🧪 Pruebas automáticas post-despliegue
- 📊 Reporte HTML de infraestructura
- 💾 Respaldos automáticos del estado

### Parámetros
- **`AUTO_APPROVE`**: Auto-aprobar cambios (default: false)
- **`TERRAFORM_WORKSPACE`**: Workspace a usar (default: default)
- **`RUN_TESTS`**: Ejecutar pruebas post-despliegue (default: true)

### Uso Recomendado
```bash
# Para desarrollo
AUTO_APPROVE = false
TERRAFORM_WORKSPACE = "dev"
RUN_TESTS = true

# Para producción
AUTO_APPROVE = false
TERRAFORM_WORKSPACE = "prod"
RUN_TESTS = true
```

## 💥 Jenkinsfile-destroy (Destrucción)

### Propósito
Pipeline con múltiples capas de seguridad para destrucción controlada de infraestructura.

### Características de Seguridad
- 🛑 Verificación de confirmación por texto ("DESTROY")
- 🚨 Protección adicional para workspaces de producción
- 💾 Respaldo completo PRE-destrucción
- 📋 Inventario detallado de recursos
- ⏸️ Doble confirmación manual
- 📊 Reporte de destrucción
- 🧹 Limpieza controlada

### Parámetros
- **`AUTO_APPROVE`**: Auto-aprobar destrucción (⚠️ PELIGROSO)
- **`TERRAFORM_WORKSPACE`**: Workspace a destruir
- **`FORCE_DESTROY`**: Forzar destrucción de producción
- **`CONFIRMATION_TEXT`**: Debe escribir "DESTROY" para proceder

### Uso Recomendado
```bash
# Para desarrollo
AUTO_APPROVE = false
TERRAFORM_WORKSPACE = "dev"
FORCE_DESTROY = false
CONFIRMATION_TEXT = "DESTROY"

# Para producción (EXTREMA PRECAUCIÓN)
AUTO_APPROVE = false
TERRAFORM_WORKSPACE = "prod"
FORCE_DESTROY = true
CONFIRMATION_TEXT = "DESTROY"
```

## 🔧 Configuración en Jenkins

### 1. Crear Jobs Separados

#### Job para Deploy
```
Nombre: "terraform-infrastructure-deploy"
Tipo: Pipeline
Pipeline script from SCM:
  - Repository: [tu-repo]
  - Script Path: ci-cd/Jenkinsfile-apply
```

#### Job para Destroy
```
Nombre: "terraform-infrastructure-destroy"
Tipo: Pipeline
Pipeline script from SCM:
  - Repository: [tu-repo]
  - Script Path: ci-cd/Jenkinsfile-destroy
```

### 2. Configurar Credenciales AWS
```
Jenkins → Manage Credentials → Global
- AWS Access Key ID
- AWS Secret Access Key
- O preferiblemente: IAM Role para EC2/ECS
```

### 3. Plugins Requeridos
- Pipeline
- AWS Steps
- HTML Publisher
- Blue Ocean (opcional, pero recomendado)

## 🔄 Workflow Recomendado

### Desarrollo
1. **Deploy**: Usar `terraform-infrastructure-deploy`
2. **Test**: Verificar funcionalidad
3. **Iterate**: Modificar código y redesplegar
4. **Cleanup**: Usar `terraform-infrastructure-destroy` al final del día

### Staging/Producción
1. **Deploy**: Usar `terraform-infrastructure-deploy` con revisión manual
2. **Monitor**: Verificar métricas y logs
3. **Maintain**: Aplicar actualizaciones cuando sea necesario
4. **Destroy**: Solo en casos excepcionales y con máxima precaución

## 📊 Reportes y Artefactos

### Jenkinsfile-apply genera:
- `infrastructure-report.html`: Reporte completo de despliegue
- `terraform-outputs.json`: Outputs de Terraform
- `backups/`: Respaldos del estado

### Jenkinsfile-destroy genera:
- `destruction-report.html`: Reporte de destrucción
- `destroy-plan.txt`: Plan de destrucción
- `backups/pre-destroy-*`: Respaldo completo pre-destrucción
- `backups/post-destroy-*`: Logs de destrucción

## ⚠️ Consideraciones de Seguridad

### Para Jenkinsfile-apply:
- Siempre revisar el plan antes de aplicar
- Usar workspaces separados para cada ambiente
- Mantener respaldos automáticos
- Monitorear costos AWS

### Para Jenkinsfile-destroy:
- **NUNCA** usar AUTO_APPROVE en producción
- Verificar twice todos los parámetros
- Confirmar que tienes respaldos
- Comunicar al equipo antes de destruir
- Considerar usar `terraform state rm` para recursos específicos

## 🆘 Recuperación de Desastres

### Si el destroy falla parcialmente:
1. Revisar `backups/pre-destroy-*` para el estado anterior
2. Usar `terraform import` para recursos huérfanos
3. Aplicar `terraform destroy` específico por recurso
4. Limpiar manualmente recursos en AWS Console

### Si necesitas restaurar:
1. Copiar estado desde `backups/`
2. Verificar con `terraform plan`
3. Aplicar selectivamente los cambios necesarios

## 📞 Soporte

Para problemas o dudas:
1. Revisar logs de Jenkins
2. Verificar estado de Terraform
3. Consultar documentación de AWS
4. Contactar al equipo DevOps

---

**⚠️ IMPORTANTE**: Siempre probar estos pipelines en un ambiente de desarrollo antes de usar en producción.
