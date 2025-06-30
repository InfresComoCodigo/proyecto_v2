-- Script para crear la base de datos del sistema de reservas
-- Ejecutar en tu instancia RDS MySQL

CREATE DATABASE IF NOT EXISTS reservas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE reservas;

-- Tabla de usuarios
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('customer', 'admin') DEFAULT 'customer',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);

-- Tabla de destinos
CREATE TABLE destinations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de categorías
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de servicios
CREATE TABLE services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de paquetes turísticos
CREATE TABLE packages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    duration INT NOT NULL, -- días
    max_people INT NOT NULL,
    destination_id INT NOT NULL,
    category_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Tabla de servicios incluidos en paquetes
CREATE TABLE package_services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    package_id INT NOT NULL,
    service_id INT NOT NULL,
    is_included BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id),
    UNIQUE KEY unique_package_service (package_id, service_id)
);

-- Tabla de itinerario de paquetes
CREATE TABLE package_itinerary (
    id INT PRIMARY KEY AUTO_INCREMENT,
    package_id INT NOT NULL,
    day_number INT NOT NULL,
    activity VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(100),
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE
);

-- Tabla de cotizaciones
CREATE TABLE quotes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    package_id INT NOT NULL,
    travel_date DATE NOT NULL,
    number_of_people INT NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    final_price DECIMAL(10,2) NOT NULL,
    special_requests TEXT,
    contact_preferences VARCHAR(20) DEFAULT 'email',
    status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Tabla de descuentos aplicados a cotizaciones
CREATE TABLE quote_discounts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    quote_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    description VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
);

-- Tabla de reservas
CREATE TABLE reservations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_code VARCHAR(50) UNIQUE NOT NULL,
    quote_id INT NULL, -- Puede ser NULL si es reserva directa
    user_id INT NOT NULL,
    package_id INT NOT NULL,
    travel_date DATE NOT NULL,
    number_of_people INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    special_requests TEXT,
    status ENUM('pending_approval', 'confirmed', 'cancelled', 'completed') DEFAULT 'pending_approval',
    payment_status ENUM('pending', 'paid', 'partially_paid', 'refunded') DEFAULT 'pending',
    admin_notes TEXT,
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (quote_id) REFERENCES quotes(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (package_id) REFERENCES packages(id)
);

-- Tabla de pagos
CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reservation_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'pending',
    transaction_id VARCHAR(200),
    gateway_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id)
);

-- Tabla de contratos
CREATE TABLE contracts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    reservation_id INT NOT NULL,
    user_id INT NOT NULL,
    contract_terms JSON NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('active', 'completed', 'cancelled', 'expired') DEFAULT 'active',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    valid_until TIMESTAMP NOT NULL,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_packages_destination ON packages(destination_id);
CREATE INDEX idx_packages_category ON packages(category_id);
CREATE INDEX idx_quotes_user ON quotes(user_id);
CREATE INDEX idx_quotes_package ON quotes(package_id);
CREATE INDEX idx_reservations_user ON reservations(user_id);
CREATE INDEX idx_reservations_package ON reservations(package_id);
CREATE INDEX idx_reservations_code ON reservations(reservation_code);
CREATE INDEX idx_contracts_reservation ON contracts(reservation_id);

-- Datos de ejemplo
INSERT INTO destinations (name, country, description) VALUES
('Lima', 'Perú', 'Capital del Perú, ciudad de contrastes'),
('Cusco', 'Perú', 'Ciudad imperial, puerta de entrada a Machu Picchu'),
('Arequipa', 'Perú', 'La ciudad blanca del sur del Perú'),
('Trujillo', 'Perú', 'Ciudad de la eterna primavera');

INSERT INTO categories (name, description) VALUES
('Aventura', 'Paquetes de turismo de aventura'),
('Cultural', 'Experiencias culturales e históricas'),
('Gastronómico', 'Tours gastronómicos y culinarios'),
('Naturaleza', 'Turismo ecológico y de naturaleza'),
('Relajación', 'Paquetes de descanso y bienestar');

INSERT INTO services (name, description) VALUES
('Transporte', 'Transporte incluido en el paquete'),
('Hospedaje', 'Alojamiento en hoteles seleccionados'),
('Alimentación', 'Desayuno, almuerzo y cena'),
('Guía turístico', 'Guía profesional especializado'),
('Seguro de viaje', 'Cobertura de seguro durante el viaje'),
('Actividades', 'Actividades y excursiones incluidas');

-- Usuario administrador por defecto (password: Admin123)
INSERT INTO users (email, password, first_name, last_name, role) VALUES
('admin@reservas.com', '$2a$10$8K1p/a0dLZRcWnhkD3Y.AueU6HgBbHKYP.2VJoXF7wJfkJ5bYj0Du', 'Admin', 'Sistema', 'admin');

-- Paquete de ejemplo
INSERT INTO packages (name, description, price, duration, max_people, destination_id, category_id) VALUES
('Lima Colonial y Gastronómica', 'Descubre la historia y sabores de Lima en un tour completo por el centro histórico y los mejores restaurantes de la ciudad.', 299.99, 3, 15, 1, 3);

-- Servicios incluidos en el paquete de ejemplo
INSERT INTO package_services (package_id, service_id, is_included) VALUES
(1, 1, TRUE), -- Transporte
(1, 2, TRUE), -- Hospedaje
(1, 3, TRUE), -- Alimentación
(1, 4, TRUE); -- Guía turístico

-- Itinerario del paquete de ejemplo
INSERT INTO package_itinerary (package_id, day_number, activity, description, location) VALUES
(1, 1, 'Llegada y City Tour', 'Recepción en aeropuerto y tour por el centro histórico', 'Centro Histórico de Lima'),
(1, 2, 'Tour Gastronómico', 'Visita a mercados locales y experiencia culinaria', 'Barranco y Miraflores'),
(1, 3, 'Museos y Partida', 'Visita a museos principales y traslado al aeropuerto', 'Museo Larco y Aeropuerto');
