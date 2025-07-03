#!/bin/bash

# Script de entrada alternativo para uso como herramientas (no como agente Jenkins)
set -e

# Verificar si se está ejecutando como agente Jenkins o como herramientas
if [ "$1" = "tools-mode" ] || [ -z "$JENKINS_SECRET" ]; then
    echo "🛠️ Ejecutando en modo herramientas (tools mode)"
    shift  # Remover el primer argumento si es "tools-mode"
    
    # Si no hay argumentos, iniciar bash interactivo
    if [ $# -eq 0 ]; then
        exec /bin/bash
    else
        # Ejecutar el comando proporcionado
        exec "$@"
    fi
else
    echo "🤖 Ejecutando en modo agente Jenkins"
    
    # Variables de entorno requeridas para modo agente
    JENKINS_URL=${JENKINS_URL:-"http://jenkins:8080"}
    JENKINS_AGENT_NAME=${JENKINS_AGENT_NAME:-"agent"}
    JENKINS_AGENT_WORKDIR=${JENKINS_AGENT_WORKDIR:-"/home/jenkins/agent"}
    
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
fi
