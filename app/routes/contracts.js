const express = require('express');
const { executeQuery } = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Generar contrato para reserva confirmada
router.post('/generate/:reservationId', authenticateToken, async (req, res) => {
    try {
        const { reservationId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;
        
        // Verificar que la reserva existe y está confirmada
        let query = `
            SELECT r.*, p.name as package_name, p.description as package_description,
                   p.duration, d.name as destination_name, d.country,
                   u.first_name, u.last_name, u.email, u.phone
            FROM reservations r
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON r.user_id = u.id
            WHERE r.id = ? AND r.status = 'confirmed'
        `;
        
        const params = [reservationId];
        
        // Si no es admin, solo puede generar contratos de sus propias reservas
        if (userRole !== 'admin') {
            query += ' AND r.user_id = ?';
            params.push(userId);
        }
        
        const reservations = await executeQuery(query, params);
        
        if (reservations.length === 0) {
            return res.status(404).json({
                error: 'Reserva no válida',
                message: 'La reserva no existe, no está confirmada o no tienes acceso a ella'
            });
        }
        
        const reservation = reservations[0];
        
        // Verificar si ya existe un contrato
        const existingContract = await executeQuery(
            'SELECT id FROM contracts WHERE reservation_id = ?',
            [reservationId]
        );
        
        if (existingContract.length > 0) {
            return res.status(400).json({
                error: 'Contrato ya existe',
                message: 'Ya existe un contrato para esta reserva'
            });
        }
        
        // Generar número de contrato único
        const contractNumber = `CONT-${Date.now()}-${reservation.reservation_code.split('-')[2]}`;
        
        // Obtener servicios incluidos en el paquete
        const services = await executeQuery(`
            SELECT s.name, s.description, ps.is_included
            FROM package_services ps
            JOIN services s ON ps.service_id = s.id
            WHERE ps.package_id = ? AND ps.is_included = 1
        `, [reservation.package_id]);
        
        // Obtener itinerario
        const itinerary = await executeQuery(`
            SELECT day_number, activity, description, location
            FROM package_itinerary
            WHERE package_id = ?
            ORDER BY day_number
        `, [reservation.package_id]);
        
        // Generar términos y condiciones del contrato
        const contractTerms = generateContractTerms(reservation, services, itinerary);
        
        // Crear el contrato
        const result = await executeQuery(`
            INSERT INTO contracts (
                contract_number, reservation_id, user_id, 
                contract_terms, total_amount, status, 
                created_at, valid_until
            ) VALUES (?, ?, ?, ?, ?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR))
        `, [
            contractNumber, reservationId, reservation.user_id,
            JSON.stringify(contractTerms), reservation.total_amount
        ]);
        
        const contractId = result.insertId;
        
        // Obtener el contrato completo
        const contract = await executeQuery(`
            SELECT c.*, r.reservation_code, p.name as package_name
            FROM contracts c
            JOIN reservations r ON c.reservation_id = r.id
            JOIN packages p ON r.package_id = p.id
            WHERE c.id = ?
        `, [contractId]);
        
        res.status(201).json({
            message: 'Contrato generado exitosamente',
            contract: contract[0]
        });
        
    } catch (error) {
        console.error('Error generando contrato:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo generar el contrato'
        });
    }
});

// Obtener contratos del usuario
router.get('/my-contracts', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { page = 1, limit = 10 } = req.query;
        
        const query = `
            SELECT c.*, r.reservation_code, r.travel_date, r.number_of_people,
                   p.name as package_name, d.name as destination_name
            FROM contracts c
            JOIN reservations r ON c.reservation_id = r.id
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            WHERE c.user_id = ?
            ORDER BY c.created_at DESC
            LIMIT ? OFFSET ?
        `;
        
        const offset = (page - 1) * limit;
        const contracts = await executeQuery(query, [userId, parseInt(limit), parseInt(offset)]);
        
        res.json({
            contracts
        });
        
    } catch (error) {
        console.error('Error obteniendo contratos:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener los contratos'
        });
    }
});

// Obtener un contrato específico
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;
        
        let query = `
            SELECT c.*, r.reservation_code, r.travel_date, r.number_of_people,
                   r.special_requests, p.name as package_name, p.description as package_description,
                   p.duration, d.name as destination_name, d.country,
                   u.first_name, u.last_name, u.email, u.phone
            FROM contracts c
            JOIN reservations r ON c.reservation_id = r.id
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON c.user_id = u.id
            WHERE c.id = ?
        `;
        
        const params = [id];
        
        // Si no es admin, solo puede ver sus propios contratos
        if (userRole !== 'admin') {
            query += ' AND c.user_id = ?';
            params.push(userId);
        }
        
        const contracts = await executeQuery(query, params);
        
        if (contracts.length === 0) {
            return res.status(404).json({
                error: 'Contrato no encontrado',
                message: 'El contrato solicitado no existe o no tienes acceso a él'
            });
        }
        
        const contract = contracts[0];
        
        // Parsear términos del contrato
        if (contract.contract_terms) {
            contract.contract_terms = JSON.parse(contract.contract_terms);
        }
        
        res.json(contract);
        
    } catch (error) {
        console.error('Error obteniendo contrato:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo obtener el contrato'
        });
    }
});

// Actualizar estado de contrato (solo admin)
router.patch('/:id/status', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden actualizar el estado de los contratos'
            });
        }
        
        const { id } = req.params;
        const { status, admin_notes } = req.body;
        
        const validStatuses = ['active', 'completed', 'cancelled', 'expired'];
        
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                error: 'Estado inválido',
                message: 'El estado debe ser: active, completed, cancelled o expired'
            });
        }
        
        await executeQuery(`
            UPDATE contracts 
            SET status = ?, admin_notes = ?, updated_at = NOW()
            WHERE id = ?
        `, [status, admin_notes, id]);
        
        res.json({
            message: 'Estado de contrato actualizado exitosamente'
        });
        
    } catch (error) {
        console.error('Error actualizando contrato:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo actualizar el contrato'
        });
    }
});

// Obtener todos los contratos (solo admin)
router.get('/admin/all', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                error: 'Acceso denegado',
                message: 'Solo los administradores pueden ver todos los contratos'
            });
        }
        
        const { status, page = 1, limit = 20 } = req.query;
        
        let query = `
            SELECT c.*, r.reservation_code, r.travel_date, 
                   p.name as package_name, d.name as destination_name,
                   u.first_name, u.last_name, u.email
            FROM contracts c
            JOIN reservations r ON c.reservation_id = r.id
            JOIN packages p ON r.package_id = p.id
            LEFT JOIN destinations d ON p.destination_id = d.id
            JOIN users u ON c.user_id = u.id
        `;
        
        const params = [];
        
        if (status) {
            query += ' WHERE c.status = ?';
            params.push(status);
        }
        
        query += ' ORDER BY c.created_at DESC LIMIT ? OFFSET ?';
        const offset = (page - 1) * limit;
        params.push(parseInt(limit), parseInt(offset));
        
        const contracts = await executeQuery(query, params);
        
        res.json({
            contracts
        });
        
    } catch (error) {
        console.error('Error obteniendo todos los contratos:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudieron obtener los contratos'
        });
    }
});

// Función para generar términos y condiciones del contrato
function generateContractTerms(reservation, services, itinerary) {
    return {
        contractInfo: {
            customerName: `${reservation.first_name} ${reservation.last_name}`,
            email: reservation.email,
            phone: reservation.phone,
            packageName: reservation.package_name,
            destination: `${reservation.destination_name}, ${reservation.country}`,
            travelDate: reservation.travel_date,
            duration: `${reservation.duration} días`,
            numberOfPeople: reservation.number_of_people,
            totalAmount: reservation.total_amount
        },
        includedServices: services,
        itinerary: itinerary,
        termsAndConditions: [
            "El cliente se compromete a pagar el monto total del paquete según los términos acordados.",
            "Las cancelaciones deben realizarse con al menos 48 horas de anticipación.",
            "La empresa no se hace responsable por gastos adicionales no incluidos en el paquete.",
            "Es responsabilidad del cliente contar con documentos de viaje válidos.",
            "Los cambios en el itinerario están sujetos a disponibilidad y costos adicionales.",
            "La empresa se reserva el derecho de cancelar el viaje por causas de fuerza mayor."
        ],
        paymentTerms: [
            "El pago completo debe realizarse antes de la fecha de viaje.",
            "Se requiere un depósito del 50% para confirmar la reserva.",
            "Los pagos pueden realizarse en efectivo, tarjeta de crédito o transferencia bancaria."
        ],
        cancellationPolicy: [
            "Cancelaciones con más de 30 días: reembolso del 80%",
            "Cancelaciones entre 15-30 días: reembolso del 50%",
            "Cancelaciones con menos de 15 días: sin reembolso"
        ]
    };
}

module.exports = router;
