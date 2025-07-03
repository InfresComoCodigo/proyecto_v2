import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { JWTPayload } from '../types';
import { verifyJWT } from '../utils/jwt';

export const configureSocketIO = (io: Server): void => {
  // Middleware for socket authentication
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    
    if (!token) {
      return next(new Error('Authentication error'));
    }

    try {
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        return next(new Error('JWT secret not configured'));
      }
      
      const decoded = verifyJWT(token, jwtSecret);
      (socket as any).user = decoded;
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    const user = (socket as any).user as JWTPayload;
    console.log(`🔌 User connected: ${user.userId} (${user.userType})`);

    // Join user to their personal room
    socket.join(`user:${user.userId}`);
    
    // Join user to their role-based room
    socket.join(`role:${user.userType}`);

    // Handle notification acknowledgment
    socket.on('notification:read', (notificationId: string) => {
      // Mark notification as read
      socket.broadcast.to(`user:${user.userId}`).emit('notification:acknowledged', {
        notificationId,
        userId: user.userId
      });
    });

    // Handle real-time chat/communication
    socket.on('message:send', (data: { recipientId: string; message: string; type: string }) => {
      socket.to(`user:${data.recipientId}`).emit('message:received', {
        senderId: user.userId,
        senderName: `${user.userId}`, // You might want to get actual name from DB
        message: data.message,
        type: data.type,
        timestamp: new Date()
      });
    });

    // Handle reservation status updates
    socket.on('reservation:update', (data: { reservationId: string; status: string }) => {
      // Broadcast to all admin and staff
      socket.to('role:ADMINISTRADOR').to('role:PERSONAL').emit('reservation:status_changed', {
        reservationId: data.reservationId,
        status: data.status,
        updatedBy: user.userId,
        timestamp: new Date()
      });
    });

    // Handle payment notifications
    socket.on('payment:processed', (data: { paymentId: string; amount: number; status: string }) => {
      // Notify relevant users
      socket.to('role:ADMINISTRADOR').emit('payment:notification', {
        paymentId: data.paymentId,
        amount: data.amount,
        status: data.status,
        processedBy: user.userId,
        timestamp: new Date()
      });
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`🔌 User disconnected: ${user.userId}`);
    });
  });

  // Helper functions to emit notifications from other parts of the app
  const emitToUser = (userId: string, event: string, data: any) => {
    io.to(`user:${userId}`).emit(event, data);
  };

  const emitToRole = (role: string, event: string, data: any) => {
    io.to(`role:${role}`).emit(event, data);
  };

  const emitToAll = (event: string, data: any) => {
    io.emit(event, data);
  };

  // Make these functions available globally
  (global as any).socketEmitters = {
    emitToUser,
    emitToRole,
    emitToAll
  };
};
