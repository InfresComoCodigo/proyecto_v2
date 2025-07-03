-- Categorías de servicios
CREATE TABLE service_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Servicios disponibles
CREATE TABLE services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    duration_hours INT COMMENT 'Duración estimada en horas',
    max_capacity INT COMMENT 'Capacidad máxima de personas',
    requirements TEXT COMMENT 'Requisitos especiales',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Paquetes (combinación de servicios)
CREATE TABLE packages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    discount_percentage DECIMAL(5,2) DEFAULT 0 CHECK (discount_percentage BETWEEN 0 AND 100),
    duration_hours INT,
    max_capacity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Servicios incluidos en cada paquete
CREATE TABLE package_services (
    package_id INT NOT NULL,
    service_id INT NOT NULL,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    custom_price DECIMAL(10,2) COMMENT 'Precio personalizado para este paquete',
    PRIMARY KEY (package_id, service_id),
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;