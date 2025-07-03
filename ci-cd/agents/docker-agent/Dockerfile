# Agente especializado para Docker builds y despliegues
FROM docker:24-dind

USER root

# Instalar herramientas adicionales
RUN apk add --no-cache \
    git \
    curl \
    bash \
    openssh-client \
    python3 \
    py3-pip \
    openjdk11-jre \
    aws-cli

# Instalar herramientas de contenedores
RUN apk add --no-cache \
    docker-compose \
    helm \
    kubectl

# Instalar Jenkins agent (crear directorio primero)
RUN mkdir -p /usr/share/jenkins \
    && curl -fsSL -o /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/4.13/remoting-4.13.jar

# Crear usuario jenkins
RUN addgroup -g 1000 jenkins \
    && adduser -D -u 1000 -G jenkins jenkins \
    && addgroup jenkins docker

USER jenkins
WORKDIR /home/jenkins

# Script de entrada para el agente
COPY agent-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/agent-entrypoint.sh"]
