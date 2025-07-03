#!/bin/bash

# Script de entrada para agentes Jenkins
set -e

# Variables de entorno requeridas
JENKINS_URL=${JENKINS_URL:-"http://jenkins:8080"}
JENKINS_AGENT_NAME=${JENKINS_AGENT_NAME:-"agent"}
JENKINS_AGENT_WORKDIR=${JENKINS_AGENT_WORKDIR:-"/home/jenkins/agent"}
JENKINS_SECRET=${JENKINS_SECRET}

# Verificar que el secreto esté configurado
if [ -z "$JENKINS_SECRET" ]; then
    echo "ERROR: JENKINS_SECRET no está configurado"
    exit 1
fi

# Crear directorio de trabajo si no existe
mkdir -p "$JENKINS_AGENT_WORKDIR"

# Esperar a que Jenkins esté disponible
echo "Esperando a que Jenkins esté disponible en $JENKINS_URL..."
while ! curl -s "$JENKINS_URL/login" > /dev/null; do
    echo "Jenkins no está disponible aún, esperando 10 segundos..."
    sleep 10
done

echo "Jenkins está disponible, conectando agente $JENKINS_AGENT_NAME..."

# Ejecutar el agente Jenkins
exec java -jar /usr/share/jenkins/agent.jar \
    -jnlpUrl "$JENKINS_URL/computer/$JENKINS_AGENT_NAME/jenkins-agent.jnlp" \
    -secret "$JENKINS_SECRET" \
    -workDir "$JENKINS_AGENT_WORKDIR"
