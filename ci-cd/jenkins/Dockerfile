# Jenkins Master - Coordinador central simplificado
FROM jenkins/jenkins:lts

# Cambiar a usuario root para instalar dependencias básicas
USER root

# Instalar dependencias básicas del sistema
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instalar Docker CLI para coordinar builds
RUN curl -fsSL https://get.docker.com -o get-docker.sh \
    && sh get-docker.sh \
    && rm get-docker.sh

# Dar permisos al usuario jenkins para Docker
# Agregar jenkins al grupo root (GID 0) que es el propietario del socket de Docker en Windows
RUN usermod -aG root jenkins

# Copiar lista de plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Volver al usuario jenkins
USER jenkins

# Variables de entorno
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV JENKINS_USER=admin
ENV JENKINS_PASS=admin123
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc.yaml

# Configuración inicial
COPY --chown=jenkins:jenkins jenkins-config/ /usr/share/jenkins/ref/
