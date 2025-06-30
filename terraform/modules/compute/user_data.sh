#!/bin/bash
# Instalar agente de CloudWatch
sudo yum install -y amazon-cloudwatch-agent

# Configurar métricas básicas
cat << EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "resources": ["*"],
        "measurement": ["cpu_usage_idle"]
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      }
    }
  }
}
EOF

# Iniciar servicio de CloudWatch
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

# Instalar Node.js 18.x
echo "Instalando Node.js..." >> /var/log/user-data.log
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git nginx

# Crear directorio para la aplicación
mkdir -p /opt/reservas-backend
cd /opt/reservas-backend

# Crear usuario para la aplicación
useradd -m -s /bin/bash reservas || echo "Usuario ya existe"

# Crear archivo index.js básico (será reemplazado por el deployment)
cat > index.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Backend de reservas funcionando correctamente',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

app.get('/', (req, res) => {
    res.redirect('/health');
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en puerto $${PORT}`);
});
EOF

# Crear package.json básico
cat > package.json << 'EOF'
{
  "name": "reservas-backend",
  "version": "1.0.0",
  "description": "Backend para sistema de reservas de paquetes turísticos",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

# Instalar dependencias básicas
npm install

# Configurar nginx como proxy
cat > /etc/nginx/conf.d/reservas-backend.conf << 'EOF'
server {
    listen 80;
    server_name _;

    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;

    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Crear servicio systemd
cat > /etc/systemd/system/reservas-backend.service << 'EOF'
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

[Install]
WantedBy=multi-user.target
EOF

# Cambiar permisos
chown -R reservas:reservas /opt/reservas-backend

# Habilitar y iniciar servicios
systemctl daemon-reload
systemctl enable reservas-backend
systemctl start reservas-backend
systemctl enable nginx
systemctl start nginx

# Configurar firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload

echo "Backend básico iniciado en ambiente ${env}" >> /var/log/app.log
echo "Para deployment completo, ejecutar script de instalación" >> /var/log/app.log