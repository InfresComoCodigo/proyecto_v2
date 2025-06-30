const express = require('express');
const { executeQuery } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validateQuote } = require('../middleware/validation');

const router = express.Router();

// Crear cotización
router.post('/', authenticateToken, validateQuote, async (req, res) => {
    try {
        const {
            package_id,
            travel_date,
            number_of_people,
            special_requests,
            contact_preferences
        } = req.body;
        
        const userId = req.user.userId;
        
        // Verificar que el paquete existe
        const packages = await executeQuery(
            'SELECT id, name, price, max_people FROM packages WHERE id = ? AND is_active = 1',
            [package_id]
        );
        
        if (packages.length === 0) {
            return res.status(404).json({
                error: 'Paquete no encontrado',
                message: 'El paquete seleccionado no existe o no está disponible'
            });
        }
        
        const packageData = packages[0];
        
        // Verificar capacidad
        if (number_of_people > packageData.max_people) {
            return res.status(400).json({
                error: 'Capacidad excedida',
                message: `El paquete solo permite máximo ${packageData.max_people} personas`
            });
        }
        
        // Calcular precio base
        const basePrice = packageData.price * number_of_people;
        
        // Aplicar descuentos o recargos según las reglas de negocio
        let finalPrice = basePrice;
        let discounts = [];
        
        // Descuento por grupo grande (más de 5 personas)
        if (number_of_people > 5) {
            const groupDiscount = basePrice * 0.1; // 10% descuento
            finalPrice -= groupDiscount;
            discounts.push({
                type: 'group_discount',
                description: 'Descuento por grupo',
                amount: groupDiscount
            });
        }
        
        // Crear la cotización
        const result = await executeQuery(`
            INSERT INTO quotes (
                user_id, package_id, travel_date, number_of_people, 
                base_price, final_price, special_requests, contact_preferences,
                status, created_at, expires_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY))
        `, [
            userId, package_id, travel_date, number_of_people,
            basePrice, finalPrice, special_requests, contact_preferences
        ]);
        
        const quoteId = result.insertId;
        
        // Guardar descuentos aplicados
        for (const discount of discounts) {
            await executeQuery(`
                INSERT INTO quote_discounts (quote_id, type, description, amount)
                VALUES (?, ?, ?, ?)
            `, [quoteId, discount.type, discount.description, discount.amount]);
        }
        
        // Obtener la cotización completa
        const quote = await executeQuery(`
            SELECT q.*, p.name as package_name, u.first_name, u.last_name, u.email
            FROM quotes q
            JOIN packages p ON q.package_id = p.id
            JOIN users u ON q.user_id = u.id
            WHERE q.id = ?
        `, [quoteId]);
        
        res.status(201).json({
            message: 'Cotización creada exitosamente',
            quote: {
                ...quote[0],
                discounts
            }
        });
        
    } catch (error) {
        console.error('Error creando cotización:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo crear la cotización'
        });
    }
});

// Obtener cotizaciones del usuario
router.get('/my-quotes', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { status, page = 1, limit = 10 } = req.query;
        
        let query = `
            SELECT q.*, p.name as package_name, p.duration, d.name as destination_name
            FROM quotes q
            JOIN packages p ON q.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            WHERE q.user_id = ?
        `;
        
        const params = [userId];
        
        if (status) {
            query += ' AND q.status = ?';
            params.push(status);
        }
        
        query += ' ORDER BY q.created_at DESC LIMIT ? OFFSET ?';
        const offset = (page - 1) * limit;
        params.push(parseInt(limit), parseInt(offset));
        
        const quotes = await executeQuery(query, params);
        
        // Contar total para paginación
        let countQuery = 'SELECT COUNT(*) as total FROM quotes WHERE user_id = ?';
        const countParams = [userId];
        
        if (status) {
            countQuery += ' AND status = ?';
            countParams.push(status);
        }
        
        const [{ total }] = await executeQuery(countQuery, countParams);
        
        res.json({
            quotes,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });
        
    } catch (error) {
        console.error('Error obteniendo cotizaciones:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener las cotizaciones'
        });
    }
});

// Obtener una cotización específica
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;
        
        let query = `
            SELECT q.*, p.name as package_name, p.description as package_description, 
                   p.duration, d.name as destination_name, d.country,
                   u.first_name, u.last_name, u.email, u.phone
            FROM quotes q
            JOIN packages p ON q.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON q.user_id = u.id
            WHERE q.id = ?
        `;
        
        const params = [id];
        
        // Si no es admin, solo puede ver sus propias cotizaciones
        if (userRole !== 'admin') {
            query += ' AND q.user_id = ?';
            params.push(userId);
        }
        
        const quotes = await executeQuery(query, params);
        
        if (quotes.length === 0) {
            return res.status(404).json({
                error: 'Cotización no encontrada',
                message: 'La cotización solicitada no existe o no tienes acceso a ella'
            });
        }
        
        // Obtener descuentos aplicados
        const discounts = await executeQuery(`
            SELECT type, description, amount
            FROM quote_discounts
            WHERE quote_id = ?
        `, [id]);
        
        res.json({
            ...quotes[0],
            discounts
        });
        
    } catch (error) {
        console.error('Error obteniendo cotización:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo obtener la cotización'
        });
    }
});

// Actualizar estado de cotización (solo admin)
router.patch('/:id/status', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden actualizar el estado de las cotizaciones'
            });
        }
        
        const { id } = req.params;
        const { status, admin_notes } = req.body;
        
        const validStatuses = ['pending', 'approved', 'rejected', 'expired'];
        
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                error: 'Estado inválido',
                message: 'El estado debe ser: pending, approved, rejected o expired'
            });
        }
        
        await executeQuery(`
            UPDATE quotes 
            SET status = ?, admin_notes = ?, updated_at = NOW()
            WHERE id = ?
        `, [status, admin_notes, id]);
        
        res.json({
            message: 'Estado de cotización actualizado exitosamente'
        });
        
    } catch (error) {
        console.error('Error actualizando cotización:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo actualizar la cotización'
        });
    }
});

// Obtener todas las cotizaciones (solo admin)
router.get('/admin/all', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden ver todas las cotizaciones'
            });
        }
        
        const { status, page = 1, limit = 20 } = req.query;
        
        let query = `
            SELECT q.*, p.name as package_name, d.name as destination_name,
                   u.first_name, u.last_name, u.email
            FROM quotes q
            JOIN packages p ON q.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON q.user_id = u.id
        `;
        
        const params = [];
        
        if (status) {
            query += ' WHERE q.status = ?';
            params.push(status);
        }
        
        query += ' ORDER BY q.created_at DESC LIMIT ? OFFSET ?';
        const offset = (page - 1) * limit;
        params.push(parseInt(limit), parseInt(offset));
        
        const quotes = await executeQuery(query, params);
        
        // Contar total
        let countQuery = 'SELECT COUNT(*) as total FROM quotes';
        const countParams = [];
        
        if (status) {
            countQuery += ' WHERE status = ?';
            countParams.push(status);
        }
        
        const [{ total }] = await executeQuery(countQuery, countParams);
        
        res.json({
            quotes,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });
        
    } catch (error) {
        console.error('Error obteniendo todas las cotizaciones:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener las cotizaciones'
        });
    }
});

module.exports = router;
