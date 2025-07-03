# Agente especializado para Terraform e Infraestructura
FROM hashicorp/terraform:1.5

USER root

# Instalar herramientas adicionales
RUN apk add --no-cache \
    git \
    curl \
    bash \
    openssh-client \
    python3 \
    py3-pip \
    openjdk11-jre

# Instalar AWS CLI
RUN pip3 install --break-system-packages awscli

# Instalar herramientas de análisis de infraestructura
RUN pip3 install --break-system-packages \
    checkov \
    terrascan

# Instalar tfsec como binario
RUN curl -sSfL https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64 -o /usr/local/bin/tfsec \
    && chmod +x /usr/local/bin/tfsec

# Instalar Jenkins agent (crear directorio primero)
RUN mkdir -p /usr/share/jenkins \
    && curl -fsSL -o /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/4.13/remoting-4.13.jar

# Crear usuario jenkins
RUN addgroup -g 1000 jenkins \
    && adduser -D -u 1000 -G jenkins jenkins

USER jenkins
WORKDIR /home/jenkins

# Script de entrada para el agente
COPY agent-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/agent-entrypoint.sh"]
