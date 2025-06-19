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

# Iniciar servicio
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

# Tu lógica de aplicación aquí
echo "Iniciando aplicación en ambiente ${env}" > /var/log/app.log