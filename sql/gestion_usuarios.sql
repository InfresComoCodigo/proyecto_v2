CREATE DATABASE IAC;
USE IAC;

-- Tabla de perfiles de usuario (complementa Cognito)
CREATE TABLE user_profiles (
    id CHAR(36) PRIMARY KEY,  -- UUID como cadena CHAR(36)
    cognito_user_id VARCHAR(255) UNIQUE NOT NULL,
    user_type ENUM('CLIENTE', 'ADMINISTRADOR', 'PERSONAL') NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    address TEXT,
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de roles y permisos para personal
CREATE TABLE roles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSON,  -- Permisos en formato JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relación usuario-rol para personal
CREATE TABLE user_roles (
    user_id CHAR(36),  -- Mismo tipo que user_profiles.id
    role_id INT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by CHAR(36),  -- Relación con otro usuario
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);