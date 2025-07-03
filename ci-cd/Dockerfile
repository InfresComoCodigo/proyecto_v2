# Usar la imagen oficial de Jenkins LTS como base
FROM jenkins/jenkins:lts

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget \
    git \
    python3 \
    python3-pip \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# Instalar Terraform
ARG TERRAFORM_VERSION=1.5.7
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Instalar Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# Instalar Node.js y npm para el backend
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Verificar instalaciones
RUN terraform --version && \
    docker --version && \
    node --version && \
    npm --version

# Cambiar de vuelta al usuario jenkins
USER jenkins

# Instalar plugins de Jenkins necesarios
RUN jenkins-plugin-cli --plugins \
    pipeline-stage-view \
    workflow-aggregator \
    git \
    credentials \
    aws-credentials \
    docker-workflow \
    terraform

# Configurar variables de entorno
ENV JENKINS_HOME=/var/jenkins_home
ENV TERRAFORM_HOME=/usr/local/bin

# Exponer puerto
EXPOSE 8080 50000

# Punto de entrada
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]