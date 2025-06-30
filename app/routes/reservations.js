const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { executeQuery } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { validateReservation } = require('../middleware/validation');

const router = express.Router();

// Crear reserva desde cotización aprobada
router.post('/from-quote/:quoteId', authenticateToken, async (req, res) => {
    try {
        const { quoteId } = req.params;
        const userId = req.user.userId;
        
        // Verificar que la cotización existe y está aprobada
        const quotes = await executeQuery(`
            SELECT q.*, p.name as package_name, p.price
            FROM quotes q
            JOIN packages p ON q.package_id = p.id
            WHERE q.id = ? AND q.user_id = ? AND q.status = 'approved'
        `, [quoteId, userId]);
        
        if (quotes.length === 0) {
            return res.status(404).json({
                error: 'Cotización no válida',
                message: 'La cotización no existe, no te pertenece o no está aprobada'
            });
        }
        
        const quote = quotes[0];
        
        // Verificar que no existe ya una reserva para esta cotización
        const existingReservation = await executeQuery(
            'SELECT id FROM reservations WHERE quote_id = ?',
            [quoteId]
        );
        
        if (existingReservation.length > 0) {
            return res.status(400).json({
                error: 'Reserva ya existe',
                message: 'Ya existe una reserva para esta cotización'
            });
        }
        
        // Generar código de reserva único
        const reservationCode = `RES-${Date.now()}-${Math.random().toString(36).substr(2, 4).toUpperCase()}`;
        
        // Crear la reserva
        const result = await executeQuery(`
            INSERT INTO reservations (
                reservation_code, quote_id, user_id, package_id, 
                travel_date, number_of_people, total_amount,
                status, payment_status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'confirmed', 'pending', NOW())
        `, [
            reservationCode, quoteId, userId, quote.package_id,
            quote.travel_date, quote.number_of_people, quote.final_price
        ]);
        
        const reservationId = result.insertId;
        
        // Crear registro de pago pendiente
        await executeQuery(`
            INSERT INTO payments (
                reservation_id, amount, status, payment_method, created_at
            ) VALUES (?, ?, 'pending', 'pending', NOW())
        `, [reservationId, quote.final_price]);
        
        // Obtener la reserva completa
        const reservation = await executeQuery(`
            SELECT r.*, p.name as package_name, d.name as destination_name,
                   u.first_name, u.last_name, u.email
            FROM reservations r
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON r.user_id = u.id
            WHERE r.id = ?
        `, [reservationId]);
        
        res.status(201).json({
            message: 'Reserva creada exitosamente',
            reservation: reservation[0]
        });
        
    } catch (error) {
        console.error('Error creando reserva:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo crear la reserva'
        });
    }
});

// Crear reserva directa (sin cotización previa)
router.post('/direct', authenticateToken, validateReservation, async (req, res) => {
    try {
        const {
            package_id,
            travel_date,
            number_of_people,
            special_requests
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
        
        // Calcular precio total
        const totalAmount = packageData.price * number_of_people;
        
        // Generar código de reserva único
        const reservationCode = `RES-${Date.now()}-${Math.random().toString(36).substr(2, 4).toUpperCase()}`;
        
        // Crear la reserva
        const result = await executeQuery(`
            INSERT INTO reservations (
                reservation_code, user_id, package_id, 
                travel_date, number_of_people, total_amount,
                special_requests, status, payment_status, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending_approval', 'pending', NOW())
        `, [
            reservationCode, userId, package_id,
            travel_date, number_of_people, totalAmount, special_requests
        ]);
        
        const reservationId = result.insertId;
        
        // Crear registro de pago pendiente
        await executeQuery(`
            INSERT INTO payments (
                reservation_id, amount, status, payment_method, created_at
            ) VALUES (?, ?, 'pending', 'pending', NOW())
        `, [reservationId, totalAmount]);
        
        res.status(201).json({
            message: 'Reserva creada exitosamente. Pendiente de aprobación.',
            reservationId,
            reservationCode
        });
        
    } catch (error) {
        console.error('Error creando reserva directa:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo crear la reserva'
        });
    }
});

// Obtener reservas del usuario
router.get('/my-reservations', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { status, page = 1, limit = 10 } = req.query;
        
        let query = `
            SELECT r.*, p.name as package_name, p.duration, d.name as destination_name,
                   pay.status as payment_status, pay.payment_method
            FROM reservations r
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            LEFT JOIN payments pay ON r.id = pay.reservation_id
            WHERE r.user_id = ?
        `;
        
        const params = [userId];
        
        if (status) {
            query += ' AND r.status = ?';
            params.push(status);
        }
        
        query += ' ORDER BY r.created_at DESC LIMIT ? OFFSET ?';
        const offset = (page - 1) * limit;
        params.push(parseInt(limit), parseInt(offset));
        
        const reservations = await executeQuery(query, params);
        
        res.json({
            reservations
        });
        
    } catch (error) {
        console.error('Error obteniendo reservas:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener las reservas'
        });
    }
});

// Obtener una reserva específica
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;
        
        let query = `
            SELECT r.*, p.name as package_name, p.description as package_description,
                   p.duration, d.name as destination_name, d.country,
                   u.first_name, u.last_name, u.email, u.phone,
                   pay.amount as payment_amount, pay.status as payment_status,
                   pay.payment_method, pay.transaction_id
            FROM reservations r
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON r.user_id = u.id
            LEFT JOIN payments pay ON r.id = pay.reservation_id
            WHERE r.id = ?
        `;
        
        const params = [id];
        
        // Si no es admin, solo puede ver sus propias reservas
        if (userRole !== 'admin') {
            query += ' AND r.user_id = ?';
            params.push(userId);
        }
        
        const reservations = await executeQuery(query, params);
        
        if (reservations.length === 0) {
            return res.status(404).json({
                error: 'Reserva no encontrada',
                message: 'La reserva solicitada no existe o no tienes acceso a ella'
            });
        }
        
        res.json(reservations[0]);
        
    } catch (error) {
        console.error('Error obteniendo reserva:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo obtener la reserva'
        });
    }
});

// Cancelar reserva
router.patch('/:id/cancel', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const { cancellation_reason } = req.body;
        
        // Verificar que la reserva existe y pertenece al usuario
        const reservations = await executeQuery(
            'SELECT id, status, travel_date FROM reservations WHERE id = ? AND user_id = ?',
            [id, userId]
        );
        
        if (reservations.length === 0) {
            return res.status(404).json({
                error: 'Reserva no encontrada',
                message: 'La reserva no existe o no te pertenece'
            });
        }
        
        const reservation = reservations[0];
        
        // Verificar que la reserva se puede cancelar
        if (reservation.status === 'cancelled') {
            return res.status(400).json({
                error: 'Reserva ya cancelada',
                message: 'Esta reserva ya fue cancelada anteriormente'
            });
        }
        
        if (reservation.status === 'completed') {
            return res.status(400).json({
                error: 'No se puede cancelar',
                message: 'No se puede cancelar una reserva completada'
            });
        }
        
        // Verificar política de cancelación (ej: no se puede cancelar 48 horas antes)
        const travelDate = new Date(reservation.travel_date);
        const now = new Date();
        const hoursDifference = (travelDate - now) / (1000 * 60 * 60);
        
        if (hoursDifference < 48) {
            return res.status(400).json({
                error: 'Muy tarde para cancelar',
                message: 'No se puede cancelar la reserva con menos de 48 horas de anticipación'
            });
        }
        
        // Cancelar la reserva
        await executeQuery(`
            UPDATE reservations 
            SET status = 'cancelled', cancellation_reason = ?, cancelled_at = NOW()
            WHERE id = ?
        `, [cancellation_reason, id]);
        
        // Actualizar el pago a cancelado
        await executeQuery(`
            UPDATE payments 
            SET status = 'cancelled', updated_at = NOW()
            WHERE reservation_id = ?
        `, [id]);
        
        res.json({
            message: 'Reserva cancelada exitosamente'
        });
        
    } catch (error) {
        console.error('Error cancelando reserva:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo cancelar la reserva'
        });
    }
});

// Actualizar estado de reserva (solo admin)
router.patch('/:id/status', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden actualizar el estado de las reservas'
            });
        }
        
        const { id } = req.params;
        const { status, admin_notes } = req.body;
        
        const validStatuses = ['pending_approval', 'confirmed', 'cancelled', 'completed'];
        
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                error: 'Estado inválido',
                message: 'El estado debe ser: pending_approval, confirmed, cancelled o completed'
            });
        }
        
        await executeQuery(`
            UPDATE reservations 
            SET status = ?, admin_notes = ?, updated_at = NOW()
            WHERE id = ?
        `, [status, admin_notes, id]);
        
        res.json({
            message: 'Estado de reserva actualizado exitosamente'
        });
        
    } catch (error) {
        console.error('Error actualizando reserva:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo actualizar la reserva'
        });
    }
});

module.exports = router;
