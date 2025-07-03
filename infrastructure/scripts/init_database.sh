#!/bin/bash

###################################################################
# SCRIPT DE INICIALIZACIÓN DE BASE DE DATOS MYSQL
# Este script carga todos los esquemas SQL en la base de datos RDS
###################################################################

set -e  # Salir si cualquier comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar parámetros
if [ $# -lt 4 ]; then
    error "Uso: $0 <DB_HOST> <DB_PORT> <DB_USER> <DB_PASSWORD> [DB_NAME]"
    error "Ejemplo: $0 aventuraxtremo-mysql-db.xxxxx.us-east-1.rds.amazonaws.com 3306 admin mypassword iac"
    exit 1
fi

# Parámetros
DB_HOST=$1
DB_PORT=$2
DB_USER=$3
DB_PASSWORD=$4
DB_NAME=${5:-"iac"}

# Directorio de scripts SQL
SQL_DIR="$(dirname "$0")/../sql"

log "Iniciando configuración de base de datos MySQL..."
log "Host: $DB_HOST"
log "Puerto: $DB_PORT"
log "Usuario: $DB_USER"
log "Base de datos: $DB_NAME"

# Verificar conexión a la base de datos
log "Verificando conexión a la base de datos..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
    error "No se puede conectar a la base de datos. Verifique los parámetros de conexión."
    exit 1
fi
success "Conexión a la base de datos exitosa"

# Crear base de datos si no existe
log "Creando base de datos '$DB_NAME' si no existe..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
success "Base de datos '$DB_NAME' creada/verificada"

# Array con el orden correcto de ejecución de scripts
SQL_SCRIPTS=(
    "gestion_usuarios.sql"
    "tablas_conf_audit.sql"
    "gestion_paquetes_servicios.sql"
    "gestion_reservas_eventos.sql"
    "procesamiento_pagos.sql"
    "comunicacion_notificaciones.sql"
    "gestion_personal.sql"
    "cotizacion.sql"
)

# Ejecutar scripts SQL en orden
for script in "${SQL_SCRIPTS[@]}"; do
    script_path="$SQL_DIR/$script"
    
    if [ ! -f "$script_path" ]; then
        warning "Script no encontrado: $script_path - Saltando..."
        continue
    fi
    
    log "Ejecutando script: $script"
    
    # Ejecutar script y capturar salida
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$script_path" 2>&1; then
        success "Script ejecutado exitosamente: $script"
    else
        error "Error ejecutando script: $script"
        exit 1
    fi
done

# Verificar que las tablas se crearon correctamente
log "Verificando tablas creadas..."
table_count=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" -s -N)

if [ "$table_count" -gt 0 ]; then
    success "Base de datos inicializada correctamente con $table_count tablas"
    
    # Mostrar lista de tablas creadas
    log "Tablas creadas:"
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" | while read table; do
        if [ "$table" != "Tables_in_$DB_NAME" ]; then
            echo "  - $table"
        fi
    done
else
    error "No se encontraron tablas en la base de datos"
    exit 1
fi

# Insertar datos de configuración inicial
log "Insertando datos de configuración inicial..."

# Insertar roles básicos
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
-- Insertar roles básicos si no existen
INSERT IGNORE INTO roles (name, description, permissions) VALUES
('SUPER_ADMIN', 'Administrador Principal', '{"all": true}'),
('ADMIN', 'Administrador', '{"users": ["read", "write"], "bookings": ["read", "write"], "packages": ["read", "write"]}'),
('STAFF', 'Personal', '{"bookings": ["read", "write"], "customers": ["read"]}'),
('GUIDE', 'Guía Turístico', '{"bookings": ["read"], "customers": ["read"]}');
EOF

success "Datos de configuración inicial insertados"

# Mostrar estadísticas finales
log "Estadísticas de la base de datos:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" << 'EOF'
SELECT 
    'Tablas' as Tipo, 
    COUNT(*) as Cantidad 
FROM information_schema.tables 
WHERE table_schema = DATABASE()
UNION ALL
SELECT 
    'Triggers' as Tipo, 
    COUNT(*) as Cantidad 
FROM information_schema.triggers 
WHERE trigger_schema = DATABASE()
UNION ALL
SELECT 
    'Roles' as Tipo, 
    COUNT(*) as Cantidad 
FROM roles;
EOF

success "¡Inicialización de base de datos completada exitosamente!"

log "Para conectarse a la base de datos:"
log "mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD $DB_NAME"
