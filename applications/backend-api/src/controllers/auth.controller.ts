import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { UserService } from '../services/user.service';
import { ApiResponse, LoginRequest, RegisterRequest, JWTPayload } from '../types';
import { signJWT, verifyJWT } from '../utils/jwt';

export class AuthController {
  // Register new user
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const userData: RegisterRequest = req.body;
      
      // Validate required fields
      if (!userData.email || !userData.password || !userData.first_name || !userData.last_name) {
        res.status(400).json({
          success: false,
          message: 'Missing required fields',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // Check if user already exists
      try {
        await UserService.getUserByCognitoId(userData.email);
        res.status(409).json({
          success: false,
          message: 'User already exists',
          timestamp: new Date()
        } as ApiResponse);
        return;
      } catch (error) {
        // User doesn't exist, continue with registration
      }
      
      // Hash password
      const hashedPassword = await bcrypt.hash(userData.password, 12);
      
      // Create user
      const user = await UserService.createUser({
        ...userData,
        password: hashedPassword
      });
      
      // Generate JWT token
      const tokenPayload: JWTPayload = {
        userId: user.id,
        userType: user.user_type,
        cognitoUserId: user.cognito_user_id
      };
      
      const jwtSecret = process.env.JWT_SECRET;
      const refreshSecret = process.env.JWT_REFRESH_SECRET;
      
      if (!jwtSecret || !refreshSecret) {
        throw new Error('JWT secrets not configured');
      }
      
      const token = signJWT(tokenPayload, jwtSecret, process.env.JWT_EXPIRES_IN || '24h');
      
      const refreshToken = signJWT(tokenPayload, refreshSecret, process.env.JWT_REFRESH_EXPIRES_IN || '7d');
      
      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          user: {
            id: user.id,
            email: user.cognito_user_id,
            first_name: user.first_name,
            last_name: user.last_name,
            user_type: user.user_type,
            is_active: user.is_active
          },
          token,
          refreshToken
        },
        timestamp: new Date()
      } as ApiResponse);
      
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Registration failed',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }

  // Login user
  static async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password }: LoginRequest = req.body;
      
      if (!email || !password) {
        res.status(400).json({
          success: false,
          message: 'Email and password are required',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // Get user by email (cognito_user_id)
      const user = await UserService.getUserByCognitoId(email);
      
      if (!user.is_active) {
        res.status(403).json({
          success: false,
          message: 'Account is deactivated',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // For now, we'll use a simple password check
      // In production, this should integrate with AWS Cognito
      const isValidPassword = await bcrypt.compare(password, 'hashed_password'); // This would be from Cognito
      
      if (!isValidPassword) {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // Get user roles
      const roles = await UserService.getUserRoles(user.id);
      
      // Generate JWT token
      const tokenPayload: JWTPayload = {
        userId: user.id,
        userType: user.user_type,
        cognitoUserId: user.cognito_user_id
      };
      
      const jwtSecret = process.env.JWT_SECRET;
      const refreshSecret = process.env.JWT_REFRESH_SECRET;
      
      if (!jwtSecret || !refreshSecret) {
        throw new Error('JWT secrets not configured');
      }
      
      const token = signJWT(tokenPayload, jwtSecret, process.env.JWT_EXPIRES_IN || '24h');
      
      const refreshToken = signJWT(tokenPayload, refreshSecret, process.env.JWT_REFRESH_EXPIRES_IN || '7d');
      
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            email: user.cognito_user_id,
            first_name: user.first_name,
            last_name: user.last_name,
            user_type: user.user_type,
            roles: roles.map(role => ({
              id: role.id,
              name: role.name,
              permissions: role.permissions
            })),
            is_active: user.is_active
          },
          token,
          refreshToken
        },
        timestamp: new Date()
      } as ApiResponse);
      
    } catch (error) {
      console.error('Login error:', error);
      
      if ((error as Error).message === 'User not found') {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials',
          timestamp: new Date()
        } as ApiResponse);
      } else {
        res.status(500).json({
          success: false,
          message: 'Login failed',
          error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
          timestamp: new Date()
        } as ApiResponse);
      }
    }
  }

  // Refresh token
  static async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;
      
      if (!refreshToken) {
        res.status(400).json({
          success: false,
          message: 'Refresh token is required',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // Verify refresh token
      const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET;
      if (!jwtRefreshSecret) {
        throw new Error('JWT refresh secret not configured');
      }
      
      const decoded = verifyJWT(refreshToken, jwtRefreshSecret);
      
      // Get updated user info
      const user = await UserService.getUserById(decoded.userId);
      
      if (!user.is_active) {
        res.status(403).json({
          success: false,
          message: 'Account is deactivated',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      // Generate new tokens
      const tokenPayload: JWTPayload = {
        userId: user.id,
        userType: user.user_type,
        cognitoUserId: user.cognito_user_id
      };
      
      const jwtSecret = process.env.JWT_SECRET;
      const jwtRefreshSecretForNew = process.env.JWT_REFRESH_SECRET;
      
      if (!jwtSecret || !jwtRefreshSecretForNew) {
        throw new Error('JWT secrets not configured');
      }
      
      const newToken = signJWT(tokenPayload, jwtSecret, process.env.JWT_EXPIRES_IN || '24h');
      
      const newRefreshToken = signJWT(tokenPayload, jwtRefreshSecretForNew, process.env.JWT_REFRESH_EXPIRES_IN || '7d');
      
      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: {
          token: newToken,
          refreshToken: newRefreshToken
        },
        timestamp: new Date()
      } as ApiResponse);
      
    } catch (error) {
      console.error('Token refresh error:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid refresh token',
        timestamp: new Date()
      } as ApiResponse);
    }
  }

  // Get current user profile
  static async getProfile(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;
      
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'User not authenticated',
          timestamp: new Date()
        } as ApiResponse);
        return;
      }
      
      const user = await UserService.getUserById(userId);
      const roles = await UserService.getUserRoles(userId);
      
      res.status(200).json({
        success: true,
        message: 'Profile retrieved successfully',
        data: {
          user: {
            id: user.id,
            email: user.cognito_user_id,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone,
            date_of_birth: user.date_of_birth,
            address: user.address,
            emergency_contact: user.emergency_contact,
            emergency_phone: user.emergency_phone,
            user_type: user.user_type,
            roles: roles.map(role => ({
              id: role.id,
              name: role.name,
              permissions: role.permissions
            })),
            is_active: user.is_active,
            created_at: user.created_at
          }
        },
        timestamp: new Date()
      } as ApiResponse);
      
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to retrieve profile',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }

  // Logout (client-side token removal)
  static async logout(req: Request, res: Response): Promise<void> {
    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
      timestamp: new Date()
    } as ApiResponse);
  }
}
