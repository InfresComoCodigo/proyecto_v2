import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticateJWT } from '../middleware/auth';
import { body, validationResult } from 'express-validator';

const router = Router();

// Validation middleware
const validateRequest = (req: any, res: any, next: any) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
      timestamp: new Date()
    });
  }
  next();
};

// Register validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long'),
  body('first_name').trim().isLength({ min: 2 }).withMessage('First name must be at least 2 characters'),
  body('last_name').trim().isLength({ min: 2 }).withMessage('Last name must be at least 2 characters'),
  body('user_type').isIn(['CLIENTE', 'ADMINISTRADOR', 'PERSONAL']).withMessage('Invalid user type'),
  body('phone').optional().isMobilePhone('any')
];

// Login validation rules
const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required')
];

// Routes
router.post('/register', registerValidation, validateRequest, AuthController.register);
router.post('/login', loginValidation, validateRequest, AuthController.login);

// Endpoint temporal de prueba sin base de datos
router.post('/test-login', loginValidation, validateRequest, (req: any, res: any) => {
  const { email, password } = req.body;
  
  // Simular el usuario que creaste desde AWS CLI
  if (email === 'test@gmail.com' && password === 'Test123123') {
    return res.status(200).json({
      success: true,
      message: 'Login successful (test mode)',
      user: {
        id: 'test-user-123',
        email: 'test@gmail.com',
        user_type: 'CLIENTE',
        first_name: 'Test',
        last_name: 'User'
      },
      token: 'fake-jwt-token-for-testing',
      timestamp: new Date()
    });
  } else {
    return res.status(401).json({
      success: false,
      message: 'Invalid credentials',
      timestamp: new Date()
    });
  }
});

router.post('/refresh-token', AuthController.refreshToken);
router.get('/profile', authenticateJWT, AuthController.getProfile);
router.post('/logout', authenticateJWT, AuthController.logout);

export default router;
