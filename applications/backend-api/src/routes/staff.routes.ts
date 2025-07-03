import { Router } from 'express';
import { Request, Response } from 'express';
import { authorizeRoles } from '../middleware/auth';
import { ApiResponse } from '../types';

const router = Router();

// All staff routes require PERSONAL role
router.use(authorizeRoles('PERSONAL'));

// Mock staff routes - to be implemented fully later
router.get('/dashboard', async (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Staff dashboard - to be implemented',
    data: {
      totalReservations: 0,
      pendingQuotations: 0,
      todaysEvents: []
    },
    timestamp: new Date()
  } as ApiResponse);
});

router.get('/tasks', async (req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'Staff tasks - to be implemented',
    data: [],
    timestamp: new Date()
  } as ApiResponse);
});

export default router;
