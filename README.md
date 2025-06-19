# Proyecto_IaC

**Integrantes**
- Aguilar Alayo ALessia
- Donayre Alvarez Jose
- Fernandez Gutierrez Valentin
- Leon Rojas Franco
- Moreno Quevedo Camila

Proyecto de `IaC`

Teniendo en cuenta dicha estructura del proyecto

```plaintext
aws-reservas-platform/                     # 👉 Directorio raíz del proyecto
├── README.md                              # Descripción general, prerequisitos, cómo desplegar
├── .gitignore                             # Archivos/directorios que Git debe ignorar (ej. .terraform/, node_modules/)
├── .github/                               # Configuración de GitHub Actions
│   └── workflows/
│       ├── ci.yml                         # Pipeline de Integración Continua: lint, tests, terraform fmt/validate/plan
│       └── cd.yml                         # Pipeline de Despliegue Continuo: terraform apply, build & push imagen, CodeDeploy
├── terraform/                             # Infraestructura como Código (IaC) con Terraform
│   ├── environments/                      # Parámetros y backend por ambiente
│   │   ├── dev/
│   │   │   ├── backend.tf                 # Backend S3 + RDS MySQL Multi-AZ para estado remoto (ambiente dev)
│   │   │   ├── terraform.tfvars           # Valores sensibles/variables específicas de dev
│   │   │   └── variables.auto.tfvars      # Valores por defecto que detecta Terraform automáticamente
│   │   └── prod/
│   │       ├── backend.tf                 # Backend remoto prod (bucket/lock separado)
│   │       ├── terraform.tfvars           # Valores de producción (CIDR, tamaños, etc.)
│   │       └── variables.auto.tfvars
│   ├── modules/                           # Módulos reutilizables (uno por dominio de infraestructura)
│   │   ├── networking/                    # Define VPC, subredes, IGW, NAT, Endpoints, Route Tables
│   │   │   ├── main.tf                    # Recursos principales del módulo
│   │   │   ├── variables.tf               # Entrada: rangos CIDR, nombres, etiquetas…
│   │   │   └── outputs.tf                 # Salida: IDs de VPC, subredes, rutas, etc.
│   │   ├── security/                      # WAF, Security Groups, Firewall Manager, IAM roles básicos
│   │   ├── compute/                       # EC2 Launch Template + Auto Scaling Group + ALB
│   │   ├── database/                      # RDS MySQL Multi-AZ, snapshots, parámetros
│   │   ├── storage/                       # Buckets S3 (front, backups, logs) y políticas
│   │   ├── cdn/                           # CloudFront, ACM, rutas de origen (S3/ALB)
│   │   ├── auth/                          # Amazon Cognito (user pool, identity pool, dominios)
│   │   ├── monitoring/                    # CloudWatch Logs/Metrics, alarmas, dashboards básicos
│   │   └── external_integrations/         # Roles/SGs/VPC Endpoints para Twilio y pasarela de pago
│   └── main.tf                            # Módulo raíz: llama a todos los módulos anteriores y resuelve dependencias
├── app/                                   # Código fuente de la aplicación
│   ├── Dockerfile                         # Imagen del backend (Node, Python, etc.) que se ejecuta en EC2
│   ├── src/                               # Lógica de negocio, controladores, utilidades
│   ├── package.json                       # Dependencias NPM / gestor de paquetes correspondiente
│   └── …                                  # Otros archivos (tests, configs, etc.)
├── scripts/                               # Utilidades para desarrolladores y CI/CD
│   ├── build.sh                           # Compila/empaca la app localmente o en CI
│   ├── deploy.sh                          # Despliegue manual (ej. por SSH o AWS CLI) si se requiere
│   └── migrate_db.sh                      # Automatiza migraciones/esquema inicial en RDS
├── docs/                                  # Documentación viva del proyecto
│   ├── arquitectura.md                    # Descripción Arc42, decisiones de diseño, ADRs
│   └── diagramas/
│       └── iac.png                        # Diagrama de arquitectura (el que compartiste)
└── grafana/                               # Stack de observabilidad fuera de AWS (opcional)
    ├── Dockerfile                         # Imagen de Grafana con plugins CloudWatch configurados
    └── dashboards/
        └── cloudwatch.json                # Dashboard JSON listo para importar y visualizar métricas