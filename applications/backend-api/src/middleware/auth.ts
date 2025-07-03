import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';
import { JWTPayload } from '../types';
import { verifyJWT } from '../utils/jwt';

// Extend Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: JWTPayload;
    }
  }
}

export const authenticateJWT = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    res.status(401).json({
      success: false,
      message: 'Access token is missing',
      timestamp: new Date()
    });
    return;
  }

  const token = authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    res.status(401).json({
      success: false,
      message: 'Access token is missing',
      timestamp: new Date()
    });
    return;
  }

  try {
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error('JWT secret not configured');
    }
    
    const decoded = verifyJWT(token, jwtSecret);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(403).json({
      success: false,
      message: 'Invalid or expired token',
      timestamp: new Date()
    });
  }
};

export const authorizeRoles = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        message: 'Authentication required',
        timestamp: new Date()
      });
      return;
    }

    if (!roles.includes(req.user.userType)) {
      res.status(403).json({
        success: false,
        message: 'Insufficient permissions',
        timestamp: new Date()
      });
      return;
    }

    next();
  };
};

export const optionalAuth = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  
  if (authHeader) {
    const token = authHeader.split(' ')[1];
    
    if (token) {
      try {
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
          console.warn('JWT secret not configured');
        } else {
          const decoded = verifyJWT(token, jwtSecret);
          req.user = decoded;
        }
      } catch (error) {
        // Token is invalid, but we continue without user info
        console.warn('Invalid token in optional auth:', error);
      }
    }
  }
  
  next();
};
