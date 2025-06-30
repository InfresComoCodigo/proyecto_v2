const jwt = require('jsonwebtoken');
const { executeQuery } = require('../config/database');

const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
        
        if (!token) {
            return res.status(401).json({
                error: 'Token de acceso requerido',
                message: 'Debes estar autenticado para acceder a este recurso'
            });
        }
        
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'tu-secret-key');
        
        // Verificar que el usuario aún existe y está activo
        const users = await executeQuery(
            'SELECT id, email, role, is_active FROM users WHERE id = ?',
            [decoded.userId]
        );
        
        if (users.length === 0 || !users[0].is_active) {
            return res.status(401).json({
                error: 'Token inválido',
                message: 'El usuario no existe o está desactivado'
            });
        }
        
        req.user = {
            userId: decoded.userId,
            email: decoded.email,
            role: decoded.role
        };
        
        next();
        
    } catch (error) {
        console.error('Error en autenticación:', error);
        
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({
                error: 'Token inválido',
                message: 'El token proporcionado no es válido'
            });
        }
        
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                error: 'Token expirado',
                message: 'El token ha expirado, por favor inicia sesión nuevamente'
            });
        }
        
        return res.status(500).json({
            error: 'Error interno del servidor',
            message: 'Error al verificar la autenticación'
        });
    }
};

const requireAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            error: 'Acceso denegado',
            message: 'Se requieren permisos de administrador para esta acción'
        });
    }
    next();
};

const requireCustomer = (req, res, next) => {
    if (req.user.role !== 'customer') {
        return res.status(403).json({
            error: 'Acceso denegado',
            message: 'Solo los clientes pueden realizar esta acción'
        });
    }
    next();
};

module.exports = {
    authenticateToken,
    requireAdmin,
    requireCustomer
};
