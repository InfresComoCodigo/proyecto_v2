#!/bin/bash

echo "📋 Configurando credenciales de Jenkins..."

# Esperar a que Jenkins esté listo
echo "Esperando a que Jenkins esté disponible..."
while ! curl -s http://localhost:8080/login > /dev/null; do
    echo "Jenkins no está listo, esperando 10 segundos..."
    sleep 10
done

echo "✅ Jenkins está disponible!"

# Configurar credenciales de AWS usando Jenkins CLI
# Nota: Esto requiere que tengas Jenkins CLI configurado

echo "Para configurar las credenciales manualmente:"
echo "1. Ve a http://localhost:8080"
echo "2. Login con admin/admin123"
echo "3. Ve a Manage Jenkins > Manage Credentials"
echo "4. Agrega las siguientes credenciales:"
echo "   - AWS Access Key ID (Secret text)"
echo "   - AWS Secret Access Key (Secret text)"
echo "   - Username/Password para GitHub"

