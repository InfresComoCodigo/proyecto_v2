-- Turnos de trabajo
CREATE TABLE work_shifts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_shift_times CHECK (start_time < end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Programación de personal
CREATE TABLE staff_schedules (
    id CHAR(36) PRIMARY KEY,  -- UUID como CHAR(36)
    staff_id CHAR(36) NOT NULL,
    reservation_id CHAR(36),
    shift_id INT,
    work_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    status ENUM('SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'ABSENT') DEFAULT 'SCHEDULED',
    assigned_by CHAR(36),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE SET NULL,
    FOREIGN KEY (shift_id) REFERENCES work_shifts(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES user_profiles(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trigger para establecer horas basadas en turnos
DELIMITER //
CREATE TRIGGER set_shift_times
BEFORE INSERT ON staff_schedules
FOR EACH ROW
BEGIN
    IF NEW.shift_id IS NOT NULL THEN
        SELECT start_time, end_time INTO @shift_start, @shift_end
        FROM work_shifts WHERE id = NEW.shift_id;
        
        SET NEW.start_time = @shift_start;
        SET NEW.end_time = @shift_end;
    END IF;
    
    -- Validar que las horas sean consistentes
    IF NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL AND NEW.start_time >= NEW.end_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La hora de inicio debe ser anterior a la hora de fin';
    END IF;
END//
DELIMITER ;

-- Evaluaciones de desempeño
CREATE TABLE staff_evaluations (
    id CHAR(36) PRIMARY KEY,  -- UUID como CHAR(36)
    staff_id CHAR(36) NOT NULL,
    evaluator_id CHAR(36) NOT NULL,
    reservation_id CHAR(36),
    rating INT,
    feedback TEXT,
    evaluation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (staff_id) REFERENCES user_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (evaluator_id) REFERENCES user_profiles(id) ON DELETE RESTRICT,
    FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trigger para validar calificaciones
DELIMITER //
CREATE TRIGGER validate_evaluation_rating
BEFORE INSERT ON staff_evaluations
FOR EACH ROW
BEGIN
    IF NEW.rating NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La calificación debe estar entre 1 y 5';
    END IF;
END//
DELIMITER ;

-- Trigger para actualizaciones
DELIMITER //
CREATE TRIGGER validate_evaluation_rating_update
BEFORE UPDATE ON staff_evaluations
FOR EACH ROW
BEGIN
    IF NEW.rating NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La calificación debe estar entre 1 y 5';
    END IF;
END//
DELIMITER ;

-- Índices para optimización
CREATE INDEX idx_schedules_staff_date ON staff_schedules(staff_id, work_date);
CREATE INDEX idx_evaluations_staff ON staff_evaluations(staff_id);
CREATE INDEX idx_evaluations_date ON staff_evaluations(evaluation_date);