import { Router } from 'express';
import { Request, Response } from 'express';
import { authorizeRoles } from '../middleware/auth';
import { UserService } from '../services/user.service';
import { ApiResponse } from '../types';

const router = Router();

// All admin routes require ADMINISTRADOR role
router.use(authorizeRoles('ADMINISTRADOR'));

// Get all users with pagination
router.get('/users', async (req: Request, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const userType = req.query.userType as string;

    const result = await UserService.getAllUsers(page, limit, userType);

    res.status(200).json({
      success: true,
      message: 'Users retrieved successfully',
      data: result.users,
      pagination: {
        page,
        limit,
        total: result.total,
        pages: Math.ceil(result.total / limit)
      },
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve users',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Deactivate user
router.patch('/users/:userId/deactivate', async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId;
    await UserService.deactivateUser(userId);

    res.status(200).json({
      success: true,
      message: 'User deactivated successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to deactivate user',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Activate user
router.patch('/users/:userId/activate', async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId;
    await UserService.activateUser(userId);

    res.status(200).json({
      success: true,
      message: 'User activated successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Activate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to activate user',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Assign role to user
router.post('/users/:userId/roles', async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId;
    const { roleId } = req.body;
    const assignedBy = req.user?.userId || '';

    await UserService.assignRole(userId, roleId, assignedBy);

    res.status(200).json({
      success: true,
      message: 'Role assigned successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Assign role error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to assign role',
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Remove role from user
router.delete('/users/:userId/roles/:roleId', async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId;
    const roleId = parseInt(req.params.roleId);

    await UserService.removeRole(userId, roleId);

    res.status(200).json({
      success: true,
      message: 'Role removed successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Remove role error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove role',
      timestamp: new Date()
    } as ApiResponse);
  }
});

export default router;
