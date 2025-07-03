# Agente especializado para análisis de seguridad
FROM python:3.11-slim

USER root

# Instalar herramientas del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Instalar herramientas de seguridad
RUN pip3 install \
    bandit \
    safety \
    semgrep \
    checkov \
    pip-audit

# Instalar OWASP Dependency Check
RUN wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip \
    && unzip dependency-check-8.4.0-release.zip -d /opt/ \
    && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check \
    && rm dependency-check-8.4.0-release.zip

# Instalar SonarScanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip \
    && unzip sonar-scanner-cli-4.8.0.2856-linux.zip -d /opt/ \
    && ln -s /opt/sonar-scanner-4.8.0.2856-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner \
    && rm sonar-scanner-cli-4.8.0.2856-linux.zip

# Instalar Jenkins agent (crear directorio primero)
RUN mkdir -p /usr/share/jenkins \
    && curl -fsSL -o /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/4.13/remoting-4.13.jar

# Crear usuario jenkins
RUN useradd -m -u 1000 jenkins

USER jenkins
WORKDIR /home/jenkins

# Script de entrada para el agente
COPY agent-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/agent-entrypoint.sh"]
