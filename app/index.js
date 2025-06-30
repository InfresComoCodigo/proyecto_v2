const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const packagesRoutes = require('./routes/packages');
const quotesRoutes = require('./routes/quotes');
const reservationsRoutes = require('./routes/reservations');
const contractsRoutes = require('./routes/contracts');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Backend de reservas funcionando correctamente',
        timestamp: new Date().toISOString()
    });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/packages', packagesRoutes);
app.use('/api/quotes', quotesRoutes);
app.use('/api/reservations', reservationsRoutes);
app.use('/api/contracts', contractsRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Algo salió mal!',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Error interno del servidor'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Ruta no encontrada',
        message: `La ruta ${req.originalUrl} no existe`
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;