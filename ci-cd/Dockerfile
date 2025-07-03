# Dockerfile para Jenkins con herramientas de monitoreo y logging
FROM jenkins/jenkins:lts

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar dependencias del sistema para monitoreo
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget \
    git \
    python3 \
    python3-pip \
    awscli \
    jq \
    htop \
    net-tools \
    procps \
    lsof \
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

# Instalar Docker Compose para orquestar servicios de monitoreo
RUN curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Instalar Prometheus Node Exporter para métricas del sistema
RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz \
    && tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz \
    && mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/ \
    && rm -rf node_exporter-1.6.1.linux-amd64*

# Instalar herramientas de logging
RUN pip3 install --no-cache-dir \
    elasticsearch \
    grafana-api \
    prometheus-client \
    psutil \
    requests

# Instalar Grafana CLI
RUN wget -q -O - https://packages.grafana.com/gpg.key | apt-key add - \
    && echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list \
    && apt-get update \
    && apt-get install -y grafana

# Verificar instalaciones
RUN terraform --version && \
    docker --version && \
    docker-compose --version && \
    node --version && \
    npm --version && \
    grafana --version && \
    node_exporter --version && \
    docker-compose --version && \
    grafana-cli --version

# Cambiar de vuelta al usuario jenkins
USER jenkins

# Instalar plugins de Jenkins necesarios para monitoreo
RUN jenkins-plugin-cli --plugins \
    pipeline-stage-view \
    workflow-aggregator \
    git \
    credentials \
    aws-credentials \
    docker-workflow \
    terraform \
    prometheus \
    grafana \
    monitoring \
    build-metrics \
    pipeline-timeline \
    performance \
    junit \
    timestamper \
    ansicolor

# Configurar variables de entorno para monitoreo
ENV JENKINS_HOME=/var/jenkins_home
ENV TERRAFORM_HOME=/usr/local/bin
ENV GRAFANA_HOME=/etc/grafana
ENV PROMETHEUS_HOME=/etc/prometheus
ENV NODE_EXPORTER_HOME=/usr/local/bin

# Exponer puertos para servicios de monitoreo
EXPOSE 8080 50000 3000 9090 9100

# Punto de entrada
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]