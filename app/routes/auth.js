const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { executeQuery } = require('../config/database');
const { validateLogin, validateRegister } = require('../middleware/validation');

const router = express.Router();

// Registro de usuario
router.post('/register', validateRegister, async (req, res) => {
    try {
        const { email, password, firstName, lastName, phone } = req.body;
        
        // Verificar si el usuario ya existe
        const existingUser = await executeQuery(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );
        
        if (existingUser.length > 0) {
            return res.status(400).json({
                error: 'El usuario ya existe',
                message: 'Ya existe una cuenta con este email'
            });
        }
        
        // Encriptar contraseña
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        // Crear usuario
        const result = await executeQuery(
            `INSERT INTO users (email, password, first_name, last_name, phone, role, created_at) 
             VALUES (?, ?, ?, ?, ?, 'customer', NOW())`,
            [email, hashedPassword, firstName, lastName, phone]
        );
        
        res.status(201).json({
            message: 'Usuario creado exitosamente',
            userId: result.insertId
        });
        
    } catch (error) {
        console.error('Error en registro:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo crear el usuario'
        });
    }
});

// Login
router.post('/login', validateLogin, async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Buscar usuario
        const users = await executeQuery(
            'SELECT id, email, password, first_name, last_name, role, is_active FROM users WHERE email = ?',
            [email]
        );
        
        if (users.length === 0) {
            return res.status(401).json({
                error: 'Credenciales inválidas',
                message: 'Email o contraseña incorrectos'
            });
        }
        
        const user = users[0];
        
        // Verificar si el usuario está activo
        if (!user.is_active) {
            return res.status(401).json({
                error: 'Cuenta desactivada',
                message: 'Tu cuenta ha sido desactivada'
            });
        }
        
        // Verificar contraseña
        const isValidPassword = await bcrypt.compare(password, user.password);
        
        if (!isValidPassword) {
            return res.status(401).json({
                error: 'Credenciales inválidas',
                message: 'Email o contraseña incorrectos'
            });
        }
        
        // Generar JWT
        const token = jwt.sign(
            {
                userId: user.id,
                email: user.email,
                role: user.role
            },
            process.env.JWT_SECRET || 'tu-secret-key',
            { expiresIn: '24h' }
        );
        
        // Actualizar último login
        await executeQuery(
            'UPDATE users SET last_login = NOW() WHERE id = ?',
            [user.id]
        );
        
        res.json({
            message: 'Login exitoso',
            token,
            user: {
                id: user.id,
                email: user.email,
                firstName: user.first_name,
                lastName: user.last_name,
                role: user.role
            }
        });
        
    } catch (error) {
        console.error('Error en login:', error);
        res.status(500).json({
            error: 'Error interno del servidor',
            message: 'No se pudo procesar el login'
        });
    }
});

// Verificar token
router.get('/verify', async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({
                error: 'Token no proporcionado',
                message: 'Se requiere autenticación'
            });
        }
        
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'tu-secret-key');
        
        // Verificar si el usuario aún existe y está activo
        const users = await executeQuery(
            'SELECT id, email, first_name, last_name, role, is_active FROM users WHERE id = ?',
            [decoded.userId]
        );
        
        if (users.length === 0 || !users[0].is_active) {
            return res.status(401).json({
                error: 'Token inválido',
                message: 'El usuario no existe o está desactivado'
            });
        }
        
        res.json({
            valid: true,
            user: {
                id: users[0].id,
                email: users[0].email,
                firstName: users[0].first_name,
                lastName: users[0].last_name,
                role: users[0].role
            }
        });
        
    } catch (error) {
        console.error('Error verificando token:', error);
        res.status(401).json({
            error: 'Token inválido',
            message: 'El token no es válido o ha expirado'
        });
    }
});

module.exports = router;
