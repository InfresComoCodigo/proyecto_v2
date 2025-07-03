-- Espacios/Locaciones disponibles
CREATE TABLE venues (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    capacity INT NOT NULL CHECK (capacity > 0),
    hourly_rate DECIMAL(10,2) CHECK (hourly_rate >= 0),
    amenities JSON COMMENT 'Lista de amenidades disponibles en formato JSON',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Reservas principales
CREATE TABLE reservations (
    id CHAR(36) PRIMARY KEY,  -- UUID como CHAR(36)
    reservation_number VARCHAR(50) UNIQUE NOT NULL,
    client_id CHAR(36) NOT NULL,
    quotation_id CHAR(36),  -- Referencia a cotización aprobada
    venue_id INT,
    event_type VARCHAR(100),
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    estimated_guests INT NOT NULL CHECK (estimated_guests > 0),
    actual_guests INT CHECK (actual_guests > 0),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    advance_payment DECIMAL(10,2) DEFAULT 0 CHECK (advance_payment >= 0),
    remaining_balance DECIMAL(10,2) NOT NULL CHECK (remaining_balance >= 0),
    status ENUM('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
    special_requests TEXT,
    cancellation_reason TEXT,
    created_by CHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES user_profiles(id) ON DELETE RESTRICT,
    FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE SET NULL,
    FOREIGN KEY (venue_id) REFERENCES venues(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL,
    CONSTRAINT chk_times CHECK (start_time < end_time),
    CONSTRAINT chk_balance CHECK (remaining_balance = total_amount - advance_payment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Servicios contratados por reserva
CREATE TABLE reservation_services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id CHAR(36) NOT NULL,
    item_type ENUM('SERVICE', 'PACKAGE') NOT NULL,
    item_id INT NOT NULL COMMENT 'ID de servicio (services.id) o paquete (packages.id)',
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED') DEFAULT 'PENDING',
    assigned_staff JSON COMMENT 'IDs del personal asignado en formato JSON',
    notes TEXT,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;