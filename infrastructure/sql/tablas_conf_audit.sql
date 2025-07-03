USE iac;

-- Configuraciones del sistema
CREATE TABLE system_settings (
    key_name VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    updated_by CHAR(36),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES user_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insertar configuraciones básicas
INSERT INTO system_settings (key_name, value, description, is_public) VALUES
('COMPANY_NAME', 'AventuraXtreme', 'Nombre de la empresa', TRUE),
('CURRENCY', 'PEN', 'Moneda principal del sistema', TRUE),
('TAX_PERCENTAGE', '18', 'Porcentaje de impuesto aplicable', FALSE),
('BOOKING_WINDOW_DAYS', '90', 'Días máximos para reservar en el futuro', FALSE),
('CANCELLATION_POLICY', '{"days":7,"percentage":50}', 'Política de cancelación en formato JSON', TRUE);

-- Auditoría de cambios importantes
CREATE TABLE audit_logs (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),  -- Generación automática de UUID
    user_id CHAR(36),
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL COMMENT 'ID del registro modificado (puede ser UUID o INT)',
    action ENUM('CREATE', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45) COMMENT 'Soporta IPv6 (máximo 45 caracteres)',
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índices para optimización
CREATE INDEX idx_audit_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);
CREATE INDEX idx_audit_user ON audit_logs(user_id);

-- Trigger para auditoría automática de configuraciones
DELIMITER //
CREATE TRIGGER audit_system_settings
AFTER UPDATE ON system_settings
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (
        user_id,
        table_name,
        record_id,
        action,
        old_values,
        new_values
    ) VALUES (
        NEW.updated_by,
        'system_settings',
        NEW.key_name,
        'UPDATE',
        JSON_OBJECT('value', OLD.value, 'is_public', OLD.is_public, 'description', OLD.description),
        JSON_OBJECT('value', NEW.value, 'is_public', NEW.is_public, 'description', NEW.description)
    );
END//
DELIMITER ;