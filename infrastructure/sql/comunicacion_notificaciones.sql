-- Plantillas de notificaciones
CREATE TABLE notification_templates (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    type ENUM('EMAIL', 'SMS', 'PUSH', 'IN_APP') NOT NULL,
    subject VARCHAR(200),
    template_body TEXT NOT NULL,
    variables JSON COMMENT 'Lista de variables disponibles para la plantilla',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notificaciones enviadas
CREATE TABLE notifications (
    id CHAR(36) PRIMARY KEY,  -- UUID como CHAR(36)
    recipient_id CHAR(36) NOT NULL,
    template_id INT,
    type ENUM('EMAIL', 'SMS', 'PUSH', 'IN_APP') NOT NULL,
    subject VARCHAR(200),
    message TEXT NOT NULL,
    status ENUM('PENDING', 'SENT', 'DELIVERED', 'FAILED') DEFAULT 'PENDING',
    sent_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    error_message TEXT,
    metadata JSON COMMENT 'Datos adicionales como email, teléfono, etc.',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES notification_templates(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Mensajes internos entre personal
CREATE TABLE internal_messages (
    id CHAR(36) PRIMARY KEY,  -- UUID como CHAR(36)
    sender_id CHAR(36) NOT NULL,
    recipient_id CHAR(36) NOT NULL,
    subject VARCHAR(200),
    message TEXT NOT NULL,
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'URGENT') DEFAULT 'NORMAL',
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES user_profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índices para optimización
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_internal_messages_recipient ON internal_messages(recipient_id);
CREATE INDEX idx_internal_messages_sender ON internal_messages(sender_id);
CREATE INDEX idx_internal_messages_priority ON internal_messages(priority);