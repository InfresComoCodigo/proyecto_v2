import { Router } from 'express';
import { Request, Response } from 'express';
import { UserService } from '../services/user.service';
import { authorizeRoles } from '../middleware/auth';
import { ApiResponse } from '../types';

const router = Router();

// Get current user profile
router.get('/profile', async (req: Request, res: Response) => {
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
        ...user,
        roles
      },
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve profile',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Update user profile
router.put('/profile', async (req: Request, res: Response) => {
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

    const updatedUser = await UserService.updateUser(userId, req.body);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Search users (Admin/Staff only)
router.get('/search', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const { q: searchTerm, type: userType } = req.query;
    
    if (!searchTerm || typeof searchTerm !== 'string') {
      res.status(400).json({
        success: false,
        message: 'Search term is required',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }

    const users = await UserService.searchUsers(searchTerm, userType as string);

    res.status(200).json({
      success: true,
      message: 'Users found successfully',
      data: users,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search users',
      timestamp: new Date()
    } as ApiResponse);
  }
});

export default router;
