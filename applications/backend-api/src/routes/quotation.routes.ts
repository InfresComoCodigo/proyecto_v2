import { Router } from 'express';
import { Request, Response } from 'express';
import { QuotationService } from '../services/quotation.service';
import { authorizeRoles } from '../middleware/auth';
import { ApiResponse, PaginatedResponse, CreateQuotationRequest } from '../types';

const router = Router();

// Get all quotations with pagination
router.get('/', async (req: Request, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const status = req.query.status as string;
    const clientId = req.query.clientId as string;
    
    const result = await QuotationService.getAllQuotations(page, limit, status, clientId);
    
    res.status(200).json({
      success: true,
      message: 'Quotations retrieved successfully',
      data: result.quotations,
      pagination: {
        page,
        limit,
        total: result.total,
        pages: Math.ceil(result.total / limit)
      },
      timestamp: new Date()
    } as PaginatedResponse);
  } catch (error) {
    console.error('Get quotations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve quotations',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get quotation by ID
router.get('/:quotationId', async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    const quotation = await QuotationService.getQuotationById(quotationId);
    
    res.status(200).json({
      success: true,
      message: 'Quotation retrieved successfully',
      data: quotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get quotation error:', error);
    
    if ((error as Error).message === 'Quotation not found') {
      res.status(404).json({
        success: false,
        message: 'Quotation not found',
        timestamp: new Date()
      } as ApiResponse);
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to retrieve quotation',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }
});

// Create new quotation
router.post('/', async (req: Request, res: Response) => {
  try {
    const quotationData: CreateQuotationRequest = req.body;
    const createdBy = req.user?.userId || '';
    
    // Validate required fields
    if (!quotationData.client_id || !quotationData.items || quotationData.items.length === 0) {
      res.status(400).json({
        success: false,
        message: 'Client ID and items are required',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const quotation = await QuotationService.createQuotation(quotationData, createdBy);
    
    res.status(201).json({
      success: true,
      message: 'Quotation created successfully',
      data: quotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Create quotation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create quotation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Update quotation status
router.patch('/:quotationId/status', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    const { status } = req.body;
    
    if (!status) {
      res.status(400).json({
        success: false,
        message: 'Status is required',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const quotation = await QuotationService.updateQuotationStatus(quotationId, status);
    
    res.status(200).json({
      success: true,
      message: 'Quotation status updated successfully',
      data: quotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Update quotation status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update quotation status',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Send quotation to client
router.post('/:quotationId/send', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    const quotation = await QuotationService.sendQuotation(quotationId);
    
    // Here you would also send email notification to client
    // await EmailService.sendQuotationEmail(quotation);
    
    res.status(200).json({
      success: true,
      message: 'Quotation sent successfully',
      data: quotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Send quotation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send quotation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Approve quotation (Client action)
router.post('/:quotationId/approve', async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    
    // Verify that the user is the client for this quotation
    const quotation = await QuotationService.getQuotationById(quotationId);
    if (quotation.client_id !== req.user?.userId) {
      res.status(403).json({
        success: false,
        message: 'You can only approve your own quotations',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const updatedQuotation = await QuotationService.approveQuotation(quotationId);
    
    res.status(200).json({
      success: true,
      message: 'Quotation approved successfully',
      data: updatedQuotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Approve quotation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve quotation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Reject quotation (Client action)
router.post('/:quotationId/reject', async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    
    // Verify that the user is the client for this quotation
    const quotation = await QuotationService.getQuotationById(quotationId);
    if (quotation.client_id !== req.user?.userId) {
      res.status(403).json({
        success: false,
        message: 'You can only reject your own quotations',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const updatedQuotation = await QuotationService.rejectQuotation(quotationId);
    
    res.status(200).json({
      success: true,
      message: 'Quotation rejected successfully',
      data: updatedQuotation,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Reject quotation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject quotation',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get client's quotations
router.get('/client/:clientId', async (req: Request, res: Response) => {
  try {
    const clientId = req.params.clientId;
    
    // Ensure user can only see their own quotations (unless admin/staff)
    if (req.user?.userType === 'CLIENTE' && req.user.userId !== clientId) {
      res.status(403).json({
        success: false,
        message: 'You can only view your own quotations',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const quotations = await QuotationService.getQuotationsByClient(clientId);
    
    res.status(200).json({
      success: true,
      message: 'Client quotations retrieved successfully',
      data: quotations,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get client quotations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve client quotations',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Delete quotation (Admin only, only draft status)
router.delete('/:quotationId', authorizeRoles('ADMINISTRADOR'), async (req: Request, res: Response) => {
  try {
    const quotationId = req.params.quotationId;
    await QuotationService.deleteQuotation(quotationId);
    
    res.status(200).json({
      success: true,
      message: 'Quotation deleted successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Delete quotation error:', error);
    
    if ((error as Error).message === 'Only draft quotations can be deleted') {
      res.status(400).json({
        success: false,
        message: 'Only draft quotations can be deleted',
        timestamp: new Date()
      } as ApiResponse);
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to delete quotation',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }
});

export default router;
