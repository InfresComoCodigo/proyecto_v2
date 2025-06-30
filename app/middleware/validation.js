const Joi = require('joi');

// Validación para login
const validateLogin = (req, res, next) => {
    const schema = Joi.object({
        email: Joi.string().email().required().messages({
            'string.email': 'Debe ser un email válido',
            'any.required': 'El email es requerido'
        }),
        password: Joi.string().min(6).required().messages({
            'string.min': 'La contraseña debe tener al menos 6 caracteres',
            'any.required': 'La contraseña es requerida'
        })
    });
    
    const { error } = schema.validate(req.body);
    
    if (error) {
        return res.status(400).json({
            error: 'Datos de entrada inválidos',
            message: error.details[0].message
        });
    }
    
    next();
};

// Validación para registro
const validateRegister = (req, res, next) => {
    const schema = Joi.object({
        email: Joi.string().email().required().messages({
            'string.email': 'Debe ser un email válido',
            'any.required': 'El email es requerido'
        }),
        password: Joi.string().min(8).pattern(new RegExp('^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])')).required().messages({
            'string.min': 'La contraseña debe tener al menos 8 caracteres',
            'string.pattern.base': 'La contraseña debe contener al menos una minúscula, una mayúscula y un número',
            'any.required': 'La contraseña es requerida'
        }),
        firstName: Joi.string().min(2).max(50).required().messages({
            'string.min': 'El nombre debe tener al menos 2 caracteres',
            'string.max': 'El nombre no puede exceder 50 caracteres',
            'any.required': 'El nombre es requerido'
        }),
        lastName: Joi.string().min(2).max(50).required().messages({
            'string.min': 'El apellido debe tener al menos 2 caracteres',
            'string.max': 'El apellido no puede exceder 50 caracteres',
            'any.required': 'El apellido es requerido'
        }),
        phone: Joi.string().pattern(new RegExp('^[+]?[0-9]{8,15}$')).optional().messages({
            'string.pattern.base': 'El teléfono debe contener solo números y tener entre 8-15 dígitos'
        })
    });
    
    const { error } = schema.validate(req.body);
    
    if (error) {
        return res.status(400).json({
            error: 'Datos de entrada inválidos',
            message: error.details[0].message
        });
    }
    
    next();
};

// Validación para paquetes
const validatePackage = (req, res, next) => {
    const schema = Joi.object({
        name: Joi.string().min(3).max(100).required().messages({
            'string.min': 'El nombre debe tener al menos 3 caracteres',
            'string.max': 'El nombre no puede exceder 100 caracteres',
            'any.required': 'El nombre es requerido'
        }),
        description: Joi.string().min(10).max(1000).required().messages({
            'string.min': 'La descripción debe tener al menos 10 caracteres',
            'string.max': 'La descripción no puede exceder 1000 caracteres',
            'any.required': 'La descripción es requerida'
        }),
        price: Joi.number().positive().precision(2).required().messages({
            'number.positive': 'El precio debe ser un número positivo',
            'any.required': 'El precio es requerido'
        }),
        duration: Joi.number().integer().min(1).max(365).required().messages({
            'number.min': 'La duración debe ser al menos 1 día',
            'number.max': 'La duración no puede exceder 365 días',
            'any.required': 'La duración es requerida'
        }),
        max_people: Joi.number().integer().min(1).max(50).required().messages({
            'number.min': 'Debe permitir al menos 1 persona',
            'number.max': 'No puede exceder 50 personas',
            'any.required': 'El número máximo de personas es requerido'
        }),
        destination_id: Joi.number().integer().positive().required().messages({
            'number.positive': 'El ID del destino debe ser un número positivo',
            'any.required': 'El destino es requerido'
        }),
        category_id: Joi.number().integer().positive().required().messages({
            'number.positive': 'El ID de la categoría debe ser un número positivo',
            'any.required': 'La categoría es requerida'
        }),
        included_services: Joi.array().items(
            Joi.object({
                service_id: Joi.number().integer().positive().required(),
                is_included: Joi.boolean().required()
            })
        ).optional(),
        itinerary: Joi.array().items(
            Joi.object({
                day_number: Joi.number().integer().min(1).required(),
                activity: Joi.string().max(200).required(),
                description: Joi.string().max(500).optional(),
                location: Joi.string().max(100).optional()
            })
        ).optional()
    });
    
    const { error } = schema.validate(req.body);
    
    if (error) {
        return res.status(400).json({
            error: 'Datos de entrada inválidos',
            message: error.details[0].message
        });
    }
    
    next();
};

// Validación para cotizaciones
const validateQuote = (req, res, next) => {
    const schema = Joi.object({
        package_id: Joi.number().integer().positive().required().messages({
            'number.positive': 'El ID del paquete debe ser un número positivo',
            'any.required': 'El paquete es requerido'
        }),
        travel_date: Joi.date().min('now').required().messages({
            'date.min': 'La fecha de viaje debe ser futura',
            'any.required': 'La fecha de viaje es requerida'
        }),
        number_of_people: Joi.number().integer().min(1).max(50).required().messages({
            'number.min': 'Debe ser al menos 1 persona',
            'number.max': 'No puede exceder 50 personas',
            'any.required': 'El número de personas es requerido'
        }),
        special_requests: Joi.string().max(500).optional().messages({
            'string.max': 'Las solicitudes especiales no pueden exceder 500 caracteres'
        }),
        contact_preferences: Joi.string().valid('email', 'phone', 'both').optional().messages({
            'any.only': 'Las preferencias de contacto deben ser: email, phone o both'
        })
    });
    
    const { error } = schema.validate(req.body);
    
    if (error) {
        return res.status(400).json({
            error: 'Datos de entrada inválidos',
            message: error.details[0].message
        });
    }
    
    next();
};

// Validación para reservas
const validateReservation = (req, res, next) => {
    const schema = Joi.object({
        package_id: Joi.number().integer().positive().required().messages({
            'number.positive': 'El ID del paquete debe ser un número positivo',
            'any.required': 'El paquete es requerido'
        }),
        travel_date: Joi.date().min('now').required().messages({
            'date.min': 'La fecha de viaje debe ser futura',
            'any.required': 'La fecha de viaje es requerida'
        }),
        number_of_people: Joi.number().integer().min(1).max(50).required().messages({
            'number.min': 'Debe ser al menos 1 persona',
            'number.max': 'No puede exceder 50 personas',
            'any.required': 'El número de personas es requerido'
        }),
        special_requests: Joi.string().max(500).optional().messages({
            'string.max': 'Las solicitudes especiales no pueden exceder 500 caracteres'
        })
    });
    
    const { error } = schema.validate(req.body);
    
    if (error) {
        return res.status(400).json({
            error: 'Datos de entrada inválidos',
            message: error.details[0].message
        });
    }
    
    next();
};

module.exports = {
    validateLogin,
    validateRegister,
    validatePackage,
    validateQuote,
    validateReservation
};
