# Agente especializado para aplicaciones Node.js
FROM node:18-alpine

USER root

# Instalar herramientas básicas
RUN apk add --no-cache \
    git \
    docker \
    curl \
    bash \
    openssh-client \
    openjdk11-jre \
    python3 \
    py3-pip

# Instalar herramientas de seguridad específicas para Node.js
RUN npm install -g \
    eslint \
    @typescript-eslint/parser \
    @typescript-eslint/eslint-plugin \
    jest

# Instalar semgrep via pip (herramienta de análisis de código)
RUN pip3 install --break-system-packages semgrep

# Instalar Jenkins agent (crear directorio primero)
RUN mkdir -p /usr/share/jenkins \
    && curl -fsSL -o /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/4.13/remoting-4.13.jar

# Crear usuario jenkins
RUN addgroup -g 1001 jenkins \
    && adduser -D -u 1001 -G jenkins jenkins

USER jenkins
WORKDIR /home/jenkins

# Script de entrada para el agente
COPY agent-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/agent-entrypoint.sh"]
