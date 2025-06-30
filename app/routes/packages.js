const express = require('express');
const { executeQuery } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validatePackage } = require('../middleware/validation');

const router = express.Router();

// Obtener todos los paquetes (público)
router.get('/', async (req, res) => {
    try {
        const { 
            destination, 
            minPrice, 
            maxPrice, 
            duration, 
            category,
            page = 1, 
            limit = 10 
        } = req.query;
        
        let query = `
            SELECT p.*, d.name as destination_name, d.country, c.name as category_name
            FROM packages p
            LEFT JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = 1
        `;
        
        const params = [];
        
        // Filtros
        if (destination) {
            query += ' AND d.name LIKE ?';
            params.push(`%${destination}%`);
        }
        
        if (minPrice) {
            query += ' AND p.price >= ?';
            params.push(minPrice);
        }
        
        if (maxPrice) {
            query += ' AND p.price <= ?';
            params.push(maxPrice);
        }
        
        if (duration) {
            query += ' AND p.duration = ?';
            params.push(duration);
        }
        
        if (category) {
            query += ' AND c.name LIKE ?';
            params.push(`%${category}%`);
        }
        
        // Paginación
        const offset = (page - 1) * limit;
        query += ' ORDER BY p.created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));
        
        const packages = await executeQuery(query, params);
        
        // Contar total para paginación
        let countQuery = `
            SELECT COUNT(*) as total
            FROM packages p
            LEFT JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = 1
        `;
        
        const countParams = [];
        if (destination) {
            countQuery += ' AND d.name LIKE ?';
            countParams.push(`%${destination}%`);
        }
        if (minPrice) {
            countQuery += ' AND p.price >= ?';
            countParams.push(minPrice);
        }
        if (maxPrice) {
            countQuery += ' AND p.price <= ?';
            countParams.push(maxPrice);
        }
        if (duration) {
            countQuery += ' AND p.duration = ?';
            countParams.push(duration);
        }
        if (category) {
            countQuery += ' AND c.name LIKE ?';
            countParams.push(`%${category}%`);
        }
        
        const [{ total }] = await executeQuery(countQuery, countParams);
        
        res.json({
            packages,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });
        
    } catch (error) {
        console.error('Error obteniendo paquetes:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener los paquetes'
        });
    }
});

// Obtener un paquete específico
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const packages = await executeQuery(`
            SELECT p.*, d.name as destination_name, d.country, d.description as destination_description,
                   c.name as category_name, c.description as category_description
            FROM packages p
            LEFT JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.id = ? AND p.is_active = 1
        `, [id]);
        
        if (packages.length === 0) {
            return res.status(404).json({
                error: 'Paquete no encontrado',
                message: 'El paquete solicitado no existe o no está disponible'
            });
        }
        
        // Obtener itinerario del paquete
        const itinerary = await executeQuery(`
            SELECT day_number, activity, description, location
            FROM package_itinerary
            WHERE package_id = ?
            ORDER BY day_number
        `, [id]);
        
        // Obtener servicios incluidos
        const services = await executeQuery(`
            SELECT s.name, s.description, ps.is_included
            FROM package_services ps
            JOIN services s ON ps.service_id = s.id
            WHERE ps.package_id = ?
        `, [id]);
        
        const packageData = {
            ...packages[0],
            itinerary,
            services
        };
        
        res.json(packageData);
        
    } catch (error) {
        console.error('Error obteniendo paquete:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo obtener el paquete'
        });
    }
});

// Crear paquete (solo admin)
router.post('/', authenticateToken, validatePackage, async (req, res) => {
    try {
        // Verificar que el usuario sea admin
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden crear paquetes'
            });
        }
        
        const {
            name,
            description,
            price,
            duration,
            max_people,
            destination_id,
            category_id,
            included_services,
            itinerary
        } = req.body;
        
        // Crear el paquete
        const result = await executeQuery(`
            INSERT INTO packages (name, description, price, duration, max_people, destination_id, category_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        `, [name, description, price, duration, max_people, destination_id, category_id]);
        
        const packageId = result.insertId;
        
        // Agregar servicios incluidos
        if (included_services && included_services.length > 0) {
            for (const service of included_services) {
                await executeQuery(`
                    INSERT INTO package_services (package_id, service_id, is_included)
                    VALUES (?, ?, ?)
                `, [packageId, service.service_id, service.is_included]);
            }
        }
        
        // Agregar itinerario
        if (itinerary && itinerary.length > 0) {
            for (const item of itinerary) {
                await executeQuery(`
                    INSERT INTO package_itinerary (package_id, day_number, activity, description, location)
                    VALUES (?, ?, ?, ?, ?)
                `, [packageId, item.day_number, item.activity, item.description, item.location]);
            }
        }
        
        res.status(201).json({
            message: 'Paquete creado exitosamente',
            packageId
        });
        
    } catch (error) {
        console.error('Error creando paquete:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo crear el paquete'
        });
    }
});

// Obtener destinos disponibles
router.get('/destinations/list', async (req, res) => {
    try {
        const destinations = await executeQuery(`
            SELECT id, name, country, description
            FROM destinations
            WHERE is_active = 1
            ORDER BY name
        `);
        
        res.json(destinations);
        
    } catch (error) {
        console.error('Error obteniendo destinos:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener los destinos'
        });
    }
});

// Obtener categorías disponibles
router.get('/categories/list', async (req, res) => {
    try {
        const categories = await executeQuery(`
            SELECT id, name, description
            FROM categories
            WHERE is_active = 1
            ORDER BY name
        `);
        
        res.json(categories);
        
    } catch (error) {
        console.error('Error obteniendo categorías:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener las categorías'
        });
    }
});

module.exports = router;
