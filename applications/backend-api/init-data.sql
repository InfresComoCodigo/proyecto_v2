-- Script de inicialización de datos de ejemplo para el backend
USE IAC;

-- Insertar roles básicos
INSERT INTO roles (name, description, permissions) VALUES 
('Admin', 'Administrador del sistema', '{"users": ["create", "read", "update", "delete"], "packages": ["create", "read", "update", "delete"], "quotations": ["create", "read", "update", "delete"], "reservations": ["create", "read", "update", "delete"], "payments": ["read", "update"], "settings": ["read", "update"]}'),
('Staff', 'Personal operativo', '{"packages": ["create", "read", "update"], "quotations": ["create", "read", "update"], "reservations": ["create", "read", "update"], "clients": ["read", "update"]}'),
('Manager', 'Gerente de operaciones', '{"packages": ["read", "update"], "quotations": ["read", "update"], "reservations": ["read", "update"], "reports": ["read"]}');

-- Insertar categorías de servicios
INSERT INTO service_categories (name, description) VALUES 
('Turismo de Aventura', 'Actividades de aventura y deportes extremos'),
('Turismo Cultural', 'Tours culturales y históricos'),
('Turismo Gastronómico', 'Experiencias culinarias y gastronómicas'),
('Turismo Rural', 'Actividades en zonas rurales y naturales'),
('Eventos Corporativos', 'Servicios para empresas y eventos corporativos'),
('Alojamiento', 'Servicios de hospedaje y alojamiento');

-- Insertar servicios de ejemplo
INSERT INTO services (category_id, name, description, base_price, duration_hours, max_capacity, requirements) VALUES 
-- Turismo de Aventura
(1, 'Rafting en Río Urubamba', 'Descenso en rafting por el río Urubamba con guías especializados', 150.00, 6, 12, 'Edad mínima 12 años, saber nadar'),
(1, 'Trekking Salkantay', 'Caminata de aventura al nevado Salkantay', 280.00, 48, 15, 'Buen estado físico, experiencia en trekking'),
(1, 'Canopy en Urubamba', 'Circuito de canopy con 8 plataformas', 80.00, 3, 20, 'Edad mínima 8 años, peso máximo 120kg'),

-- Turismo Cultural
(2, 'Tour Machu Picchu', 'Visita guiada a la ciudadela de Machu Picchu', 320.00, 12, 25, 'Reserva con anticipación, documento de identidad'),
(2, 'Tour Valle Sagrado', 'Recorrido por Pisaq, Ollantaytambo y Chinchero', 180.00, 10, 30, 'Documento de identidad'),
(2, 'City Tour Cusco', 'Recorrido por los principales atractivos de Cusco', 120.00, 6, 35, 'Documento de identidad'),

-- Turismo Gastronómico
(3, 'Experiencia Culinaria Andina', 'Preparación y degustación de platos típicos', 95.00, 4, 16, 'Sin restricciones alimentarias severas'),
(3, 'Tour de Mercados Locales', 'Recorrido gastronómico por mercados tradicionales', 60.00, 3, 20, 'Ninguno'),

-- Turismo Rural
(4, 'Vivencia en Comunidad Maras', 'Experiencia de vida rural en Maras', 200.00, 24, 12, 'Adaptabilidad a condiciones rurales'),
(4, 'Tour a Salineras de Maras', 'Visita a las salineras y proceso de extracción', 45.00, 4, 25, 'Calzado cómodo'),

-- Eventos Corporativos
(5, 'Team Building Aventura', 'Actividades de integración empresarial', 180.00, 8, 50, 'Coordinación previa con RR.HH.'),
(5, 'Conferencias con Vista', 'Espacios para eventos corporativos', 350.00, 6, 100, 'Equipos audiovisuales incluidos'),

-- Alojamiento
(6, 'Lodge Eco-turístico', 'Alojamiento ecológico con vista panorámica', 250.00, 24, 4, 'Reserva mínima 2 noches'),
(6, 'Casa Rural Familiar', 'Alojamiento familiar en zona rural', 120.00, 24, 8, 'Apto para familias con niños');

-- Insertar paquetes de ejemplo
INSERT INTO packages (name, description, total_price, discount_percentage, duration_hours, max_capacity) VALUES 
('Aventura Completa Cusco', 'Paquete que incluye rafting, canopy y trekking', 480.00, 10.00, 72, 12),
('Experiencia Cultural Total', 'Machu Picchu + Valle Sagrado + City Tour', 580.00, 15.00, 28, 25),
('Gastronomy & Culture', 'Experiencia culinaria + Tour de mercados + City Tour', 250.00, 8.00, 13, 16),
('Escape Rural Completo', 'Vivencia comunitaria + Salineras + Lodge', 420.00, 12.00, 52, 12),
('Corporate Adventure', 'Team building + Conferencias + Alojamiento', 650.00, 20.00, 38, 50);

-- Insertar servicios en paquetes
INSERT INTO package_services (package_id, service_id, quantity, custom_price) VALUES 
-- Aventura Completa Cusco
(1, 1, 1, 150.00), -- Rafting
(1, 3, 1, 80.00),  -- Canopy
(1, 2, 1, 250.00), -- Trekking (precio reducido)

-- Experiencia Cultural Total
(2, 4, 1, 320.00), -- Machu Picchu
(2, 5, 1, 180.00), -- Valle Sagrado
(2, 6, 1, 80.00),  -- City Tour (precio reducido)

-- Gastronomy & Culture
(3, 7, 1, 95.00),  -- Experiencia Culinaria
(3, 8, 1, 60.00),  -- Tour Mercados
(3, 6, 1, 95.00),  -- City Tour (precio reducido)

-- Escape Rural Completo
(4, 9, 1, 200.00), -- Vivencia Maras
(4, 10, 1, 45.00), -- Salineras
(4, 13, 1, 175.00), -- Lodge (precio reducido)

-- Corporate Adventure
(5, 11, 1, 180.00), -- Team Building
(5, 12, 1, 350.00), -- Conferencias
(5, 13, 1, 120.00); -- Lodge (precio reducido)

-- Insertar usuario administrador de ejemplo
INSERT INTO user_profiles (id, cognito_user_id, user_type, first_name, last_name, phone, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'admin@iacturismo.com', 'ADMINISTRADOR', 'Admin', 'Sistema', '+51999888777', TRUE);

-- Asignar rol de admin al usuario
INSERT INTO user_roles (user_id, role_id, assigned_by) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 1, '550e8400-e29b-41d4-a716-446655440000');

-- Insertar usuarios de ejemplo
INSERT INTO user_profiles (id, cognito_user_id, user_type, first_name, last_name, phone, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'staff@iacturismo.com', 'PERSONAL', 'Ana', 'García', '+51999888776', TRUE),
('550e8400-e29b-41d4-a716-446655440002', 'cliente1@gmail.com', 'CLIENTE', 'Juan', 'Pérez', '+51999888775', TRUE),
('550e8400-e29b-41d4-a716-446655440003', 'cliente2@gmail.com', 'CLIENTE', 'María', 'López', '+51999888774', TRUE);

-- Asignar rol de staff
INSERT INTO user_roles (user_id, role_id, assigned_by) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 2, '550e8400-e29b-41d4-a716-446655440000');
