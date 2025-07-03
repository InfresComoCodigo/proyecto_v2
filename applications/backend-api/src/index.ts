import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { config } from 'dotenv';
import { createServer } from 'http';
import { Server } from 'socket.io';

// Import routes
import authRoutes from './routes/auth.routes';
import ec2Routes from './routes/ec2.routes';

// Commented out imports - not being used currently
// import userRoutes from './routes/user.routes';
// import packageRoutes from './routes/package.routes';
// import quotationRoutes from './routes/quotation.routes';
// import reservationRoutes from './routes/reservation.routes';
// import paymentRoutes from './routes/payment.routes';
// import notificationRoutes from './routes/notification.routes';
// import adminRoutes from './routes/admin.routes';
// import staffRoutes from './routes/staff.routes';

// Import middleware
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import { logger } from './middleware/logger';
import { authenticateJWT } from './middleware/auth';

// Import database connection - COMMENTED OUT FOR NOW
// import { connectDB } from './config/database';

// Import socket configuration
import { configureSocketIO } from './config/socket';

// Load environment variables
config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ["http://localhost:3000"],
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true
  }
});

const PORT = process.env.PORT || 3000;

// Rate limiting
const limiter = rateLimit({
  windowMs: (parseInt(process.env.RATE_LIMIT_WINDOW as string) || 15) * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS as string) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ["http://localhost:3000"],
  credentials: true
}));
app.use(limiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(logger);

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Hello World route
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Hello World! Backend API is running! 🚀',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/ec2', ec2Routes);

// Commented out routes - not being used currently
// app.use('/api/users', authenticateJWT, userRoutes);
// app.use('/api/packages', authenticateJWT, packageRoutes);
// app.use('/api/quotations', authenticateJWT, quotationRoutes);
// app.use('/api/reservations', authenticateJWT, reservationRoutes);
// app.use('/api/payments', authenticateJWT, paymentRoutes);
// app.use('/api/notifications', authenticateJWT, notificationRoutes);
// app.use('/api/admin', authenticateJWT, adminRoutes);
// app.use('/api/staff', authenticateJWT, staffRoutes);

// Configure Socket.IO
configureSocketIO(io);

// Make io accessible to req object
app.use((req, res, next) => {
  (req as any).io = io;
  next();
});

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Start server
const startServer = async () => {
  try {
    // Connect to database - COMMENTED OUT FOR NOW
    // await connectDB();
    // console.log('✅ Database connected successfully');

    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 CORS enabled for: ${process.env.ALLOWED_ORIGINS || 'http://localhost:3000'}`);
      console.log(`🔌 EC2 endpoints available at /api/ec2/*`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Start server only if not in test environment
if (process.env.NODE_ENV !== 'test') {
  startServer();
}

export default app;
