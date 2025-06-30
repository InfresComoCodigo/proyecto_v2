# Sistema de Reservas de Paquetes Turísticos

**Integrantes**
- Aguilar Alayo ALessia
- Donayre Alvarez Jose
- Fernandez Gutierrez Valentin
- Leon Rojas Franco
- Moreno Quevedo Camila

## 🏗️ Arquitectura

Este proyecto implementa un sistema completo de reservas turísticas usando:

- **Backend**: Node.js + Express en EC2
- **Base de datos**: MySQL en RDS 
- **Autenticación**: AWS Cognito + JWT
- **Infraestructura**: Terraform (IaC)
- **Monitoreo**: CloudWatch + Grafana
- **Frontend**: S3 + CloudFront (CDN)

## 🚀 Funcionalidades del Backend

### ✅ Autenticación y Autorización
- **Login**: `/api/auth/login` - Autenticación de usuarios
- **Registro**: `/api/auth/register` - Registro de nuevos usuarios
- **Verificación**: `/api/auth/verify` - Validar token JWT
- **Roles**: Cliente y Administrador

### ✅ Gestión de Paquetes Turísticos
- **Listar paquetes**: `GET /api/packages` - Con filtros y paginación
- **Detalle de paquete**: `GET /api/packages/:id` - Información completa
- **Crear paquete**: `POST /api/packages` - Solo administradores
- **Destinos**: `GET /api/packages/destinations/list`
- **Categorías**: `GET /api/packages/categories/list`

### ✅ Sistema de Cotizaciones
- **Crear cotización**: `POST /api/quotes` - Solicitar precio
- **Mis cotizaciones**: `GET /api/quotes/my-quotes` - Del usuario actual
- **Ver cotización**: `GET /api/quotes/:id` - Detalle específico
- **Aprobar/Rechazar**: `PATCH /api/quotes/:id/status` - Solo admin
- **Ver todas**: `GET /api/quotes/admin/all` - Solo admin

### ✅ Gestión de Reservas
- **Desde cotización**: `POST /api/reservations/from-quote/:quoteId`
- **Reserva directa**: `POST /api/reservations/direct`
- **Mis reservas**: `GET /api/reservations/my-reservations`
- **Ver reserva**: `GET /api/reservations/:id`
- **Cancelar**: `PATCH /api/reservations/:id/cancel`
- **Actualizar estado**: `PATCH /api/reservations/:id/status` - Solo admin

### ✅ Sistema de Contratos
- **Generar contrato**: `POST /api/contracts/generate/:reservationId`
- **Mis contratos**: `GET /api/contracts/my-contracts`
- **Ver contrato**: `GET /api/contracts/:id`
- **Actualizar estado**: `PATCH /api/contracts/:id/status` - Solo admin
- **Ver todos**: `GET /api/contracts/admin/all` - Solo admin

## 🛠️ Configuración y Despliegue

### Prerequisitos

1. **Infraestructura desplegada** con Terraform
2. **Base de datos RDS MySQL** funcionando
3. **Instancia EC2** con acceso a RDS

### Pasos de Instalación

#### 1. Preparar archivos en tu máquina local
```bash
# Comprimir archivos de la aplicación
cd d:\UPAO\IaC\proyecto_v2\app
tar -czf reservas-backend.tar.gz .

# Subir a EC2 (reemplaza con tu IP de EC2)
scp -i your-key.pem reservas-backend.tar.gz ec2-user@YOUR-EC2-IP:/tmp/
```

#### 2. Conectarse a EC2 y extraer archivos
```bash
# Conectar a EC2
ssh -i your-key.pem ec2-user@YOUR-EC2-IP

# Extraer archivos
cd /tmp
tar -xzf reservas-backend.tar.gz
sudo mkdir -p /tmp/app
sudo mv * /tmp/app/ 2>/dev/null || true
```

#### 3. Ejecutar script de instalación
```bash
# Hacer ejecutable el script
sudo chmod +x /tmp/app/scripts/install.sh

# Ejecutar instalación
sudo /tmp/app/scripts/install.sh
```

#### 4. Configurar variables de entorno
```bash
# Editar archivo de configuración
sudo nano /opt/reservas-backend/.env

# Configurar estos valores:
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_USERNAME=admin
DB_PASSWORD=your-db-password
DB_NAME=reservas
JWT_SECRET=tu-super-secret-key-muy-seguro
PORT=3000
NODE_ENV=production
```

#### 5. Inicializar base de datos
```bash
# Conectar a RDS y crear esquema
mysql -h YOUR-RDS-ENDPOINT -u admin -p < /opt/reservas-backend/database/init.sql
```

#### 6. Iniciar el servicio
```bash
# Opción 1: Usando systemd
sudo systemctl start reservas-backend
sudo systemctl status reservas-backend

# Opción 2: Usando PM2 (recomendado para producción)
sudo -u reservas pm2 start /opt/reservas-backend/ecosystem.config.js
sudo -u reservas pm2 save
sudo -u reservas pm2 startup
```

#### 7. Verificar funcionamiento
```bash
# Verificar health check
curl http://localhost/health

# Verificar desde internet (reemplaza con tu IP pública)
curl http://YOUR-EC2-PUBLIC-IP/health

# Ver logs
sudo journalctl -u reservas-backend -f
# o
sudo -u reservas pm2 logs
```

## 🧪 Ejecutar Tests

```bash
# En la instancia EC2
cd /opt/reservas-backend
sudo -u reservas npm test

# Ejecutar tests específicos
sudo -u reservas npm test -- --grep "Authentication"
```

## 📊 Endpoints de la API

### Autenticación
- `POST /api/auth/register` - Registro
- `POST /api/auth/login` - Login
- `GET /api/auth/verify` - Verificar token

### Paquetes (público)
- `GET /api/packages` - Listar paquetes
- `GET /api/packages/:id` - Detalle de paquete
- `GET /api/packages/destinations/list` - Destinos
- `GET /api/packages/categories/list` - Categorías

### Cotizaciones (requiere autenticación)
- `POST /api/quotes` - Crear cotización
- `GET /api/quotes/my-quotes` - Mis cotizaciones
- `GET /api/quotes/:id` - Ver cotización

### Reservas (requiere autenticación)
- `POST /api/reservations/from-quote/:quoteId` - Desde cotización
- `POST /api/reservations/direct` - Reserva directa
- `GET /api/reservations/my-reservations` - Mis reservas
- `GET /api/reservations/:id` - Ver reserva

### Contratos (requiere autenticación)
- `POST /api/contracts/generate/:reservationId` - Generar contrato
- `GET /api/contracts/my-contracts` - Mis contratos
- `GET /api/contracts/:id` - Ver contrato

### Admin (requiere rol admin)
- `POST /api/packages` - Crear paquete
- `GET /api/quotes/admin/all` - Todas las cotizaciones
- `PATCH /api/quotes/:id/status` - Aprobar/rechazar cotización
- `PATCH /api/reservations/:id/status` - Actualizar reserva
- `GET /api/contracts/admin/all` - Todos los contratos

## 📁 Estructura del Proyecto

```plaintext
aws-reservas-platform/                     
├── README.md                              
├── .gitignore                             
├── terraform/                             # Infraestructura como Código (IaC) con Terraform
│   ├── environments/                      # Parámetros y backend por ambiente
│   │   ├── dev/
│   │   │   ├── backend.tf                 
│   │   │   ├── terraform.tfvars           
│   │   │   └── variables.auto.tfvars      
│   │   └── prod/
│   │       ├── backend.tf                 
│   │       ├── terraform.tfvars           
│   │       └── variables.auto.tfvars
│   ├── modules/                           # Módulos reutilizables
│   │   ├── networking/                    
│   │   ├── security/                      
│   │   ├── compute/                       
│   │   ├── database/                      
│   │   ├── storage/                       
│   │   ├── cdn/                           
│   │   ├── auth/                          
│   │   ├── monitoring/                    
│   │   └── external_integrations/         
│   └── main.tf                            
├── app/                                   # Código fuente del backend
│   ├── index.js                           # Servidor Express principal
│   ├── package.json                       # Dependencias y scripts
│   ├── config/
│   │   └── database.js                    # Configuración de MySQL
│   ├── routes/                            # Rutas de la API
│   │   ├── auth.js                        # Autenticación
│   │   ├── packages.js                    # Paquetes turísticos
│   │   ├── quotes.js                      # Cotizaciones
│   │   ├── reservations.js                # Reservas
│   │   └── contracts.js                   # Contratos
│   ├── middleware/                        # Middlewares
│   │   ├── auth.js                        # Autenticación JWT
│   │   └── validation.js                  # Validaciones
│   ├── database/
│   │   └── init.sql                       # Script de inicialización DB
│   ├── scripts/
│   │   └── install.sh                     # Script de instalación
│   ├── index.test.js                      # Tests completos
│   └── .env.example                       # Variables de entorno
└── grafana/                               # Stack de observabilidad
    ├── Dockerfile                         
    └── dashboards/
        └── cloudwatch.json                
```