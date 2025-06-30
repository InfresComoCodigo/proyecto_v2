#!/bin/bash

# Script de instalación y configuración del backend en EC2
# Este script debe ejecutarse en tu instancia EC2

echo "🚀 Iniciando configuración del backend de reservas..."

# Actualizar el sistema
echo "📦 Actualizando sistema..."
sudo yum update -y

# Instalar Node.js 18.x
echo "📦 Instalando Node.js..."
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Verificar instalación
echo "✅ Versión de Node.js: $(node --version)"
echo "✅ Versión de npm: $(npm --version)"

# Crear usuario para la aplicación
echo "👤 Creando usuario de aplicación..."
sudo useradd -m -s /bin/bash reservas || echo "Usuario ya existe"

# Crear directorios de la aplicación
echo "📁 Creando directorios..."
sudo mkdir -p /opt/reservas-backend
sudo chown reservas:reservas /opt/reservas-backend

# Copiar archivos de la aplicación (asume que los archivos están en /tmp/app)
echo "📋 Copiando archivos de la aplicación..."
sudo cp -r /tmp/app/* /opt/reservas-backend/
sudo chown -R reservas:reservas /opt/reservas-backend

# Cambiar al directorio de la aplicación
cd /opt/reservas-backend

# Instalar dependencias como usuario reservas
echo "📦 Instalando dependencias..."
sudo -u reservas npm install

# Crear archivo de variables de entorno
echo "🔧 Configurando variables de entorno..."
sudo -u reservas cp .env.example .env

echo "⚠️  IMPORTANTE: Edita el archivo .env con tus valores reales:"
echo "   - DB_HOST: endpoint de tu RDS"
echo "   - DB_USERNAME: usuario de la base de datos"
echo "   - DB_PASSWORD: contraseña de la base de datos"
echo "   - JWT_SECRET: clave secreta para JWT"

# Crear servicio systemd
echo "🔧 Creando servicio systemd..."
sudo tee /etc/systemd/system/reservas-backend.service > /dev/null <<EOF
[Unit]
Description=Reservas Backend API
After=network.target

[Service]
Type=simple
User=reservas
WorkingDirectory=/opt/reservas-backend
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# Logging
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=reservas-backend

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd y habilitar el servicio
echo "🔧 Configurando servicio..."
sudo systemctl daemon-reload
sudo systemctl enable reservas-backend

# Configurar logrotate para los logs
echo "📝 Configurando rotación de logs..."
sudo tee /etc/logrotate.d/reservas-backend > /dev/null <<EOF
/var/log/reservas-backend.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    create 644 reservas reservas
    postrotate
        systemctl reload reservas-backend > /dev/null 2>&1 || true
    endscript
}
EOF

# Instalar PM2 para manejo de procesos (alternativa a systemd)
echo "📦 Instalando PM2..."
sudo npm install -g pm2

# Crear configuración de PM2
sudo -u reservas tee /opt/reservas-backend/ecosystem.config.js > /dev/null <<EOF
module.exports = {
  apps: [{
    name: 'reservas-backend',
    script: './index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/reservas-backend-error.log',
    out_file: '/var/log/reservas-backend-out.log',
    log_file: '/var/log/reservas-backend-combined.log',
    time: true,
    max_memory_restart: '1G'
  }]
};
EOF

# Configurar nginx como proxy reverso
echo "🌐 Instalando y configurando Nginx..."
sudo yum install -y nginx

sudo tee /etc/nginx/conf.d/reservas-backend.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Configuración de CORS
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;

    # Manejar solicitudes OPTIONS
    if (\$request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # API routes
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # Redirect root to health check
    location = / {
        return 302 /health;
    }
}
EOF

# Habilitar y iniciar nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Configurar firewall
echo "🔥 Configurando firewall..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

echo "✅ Configuración completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Edita /opt/reservas-backend/.env con tus valores de base de datos"
echo "2. Ejecuta la base de datos con: mysql -h YOUR_RDS_ENDPOINT -u admin -p < /opt/reservas-backend/database/init.sql"
echo "3. Inicia el servicio con uno de estos comandos:"
echo "   - Usando systemd: sudo systemctl start reservas-backend"
echo "   - Usando PM2: sudo -u reservas pm2 start /opt/reservas-backend/ecosystem.config.js"
echo "4. Verifica que funciona: curl http://localhost/health"
echo ""
echo "🔧 Comandos útiles:"
echo "- Ver logs systemd: sudo journalctl -u reservas-backend -f"
echo "- Ver logs PM2: sudo -u reservas pm2 logs"
echo "- Estado del servicio: sudo systemctl status reservas-backend"
echo "- Reiniciar nginx: sudo systemctl restart nginx"
echo "- Ejecutar tests: cd /opt/reservas-backend && sudo -u reservas npm test"
