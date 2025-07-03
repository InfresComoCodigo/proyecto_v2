import { Router } from 'express';
import { Request, Response } from 'express';
import { PackageManagementService } from '../services/package.service';
import { authorizeRoles } from '../middleware/auth';
import { ApiResponse, PaginatedResponse } from '../types';

const router = Router();

// Get all service categories
router.get('/categories', async (req: Request, res: Response) => {
  try {
    const categories = await PackageManagementService.getServiceCategories();
    
    res.status(200).json({
      success: true,
      message: 'Service categories retrieved successfully',
      data: categories,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve categories',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get services by category
router.get('/categories/:categoryId/services', async (req: Request, res: Response) => {
  try {
    const categoryId = parseInt(req.params.categoryId);
    const services = await PackageManagementService.getServicesByCategory(categoryId);
    
    res.status(200).json({
      success: true,
      message: 'Services retrieved successfully',
      data: services,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get services error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve services',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get all services
router.get('/services', async (req: Request, res: Response) => {
  try {
    const services = await PackageManagementService.getAllServices();
    
    res.status(200).json({
      success: true,
      message: 'All services retrieved successfully',
      data: services,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get all services error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve services',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get service by ID
router.get('/services/:serviceId', async (req: Request, res: Response) => {
  try {
    const serviceId = parseInt(req.params.serviceId);
    const service = await PackageManagementService.getServiceById(serviceId);
    
    res.status(200).json({
      success: true,
      message: 'Service retrieved successfully',
      data: service,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get service error:', error);
    
    if ((error as Error).message === 'Service not found') {
      res.status(404).json({
        success: false,
        message: 'Service not found',
        timestamp: new Date()
      } as ApiResponse);
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to retrieve service',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }
});

// Create new service (Admin/Staff only)
router.post('/services', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const service = await PackageManagementService.createService(req.body);
    
    res.status(201).json({
      success: true,
      message: 'Service created successfully',
      data: service,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Create service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create service',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Update service (Admin/Staff only)
router.put('/services/:serviceId', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const serviceId = parseInt(req.params.serviceId);
    const service = await PackageManagementService.updateService(serviceId, req.body);
    
    res.status(200).json({
      success: true,
      message: 'Service updated successfully',
      data: service,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Update service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update service',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get all packages
router.get('/packages', async (req: Request, res: Response) => {
  try {
    const packages = await PackageManagementService.getAllPackages();
    
    res.status(200).json({
      success: true,
      message: 'Packages retrieved successfully',
      data: packages,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get packages error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve packages',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Get package by ID
router.get('/packages/:packageId', async (req: Request, res: Response) => {
  try {
    const packageId = parseInt(req.params.packageId);
    const packageData = await PackageManagementService.getPackageById(packageId);
    
    res.status(200).json({
      success: true,
      message: 'Package retrieved successfully',
      data: packageData,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Get package error:', error);
    
    if ((error as Error).message === 'Package not found') {
      res.status(404).json({
        success: false,
        message: 'Package not found',
        timestamp: new Date()
      } as ApiResponse);
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to retrieve package',
        error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
        timestamp: new Date()
      } as ApiResponse);
    }
  }
});

// Create new package (Admin/Staff only)
router.post('/packages', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const { packageData, services } = req.body;
    const newPackage = await PackageManagementService.createPackage(packageData, services);
    
    res.status(201).json({
      success: true,
      message: 'Package created successfully',
      data: newPackage,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Create package error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create package',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Update package (Admin/Staff only)
router.put('/packages/:packageId', authorizeRoles('ADMINISTRADOR', 'PERSONAL'), async (req: Request, res: Response) => {
  try {
    const packageId = parseInt(req.params.packageId);
    const { packageData, services } = req.body;
    const updatedPackage = await PackageManagementService.updatePackage(packageId, packageData, services);
    
    res.status(200).json({
      success: true,
      message: 'Package updated successfully',
      data: updatedPackage,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Update package error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update package',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Delete package (Admin only)
router.delete('/packages/:packageId', authorizeRoles('ADMINISTRADOR'), async (req: Request, res: Response) => {
  try {
    const packageId = parseInt(req.params.packageId);
    await PackageManagementService.deletePackage(packageId);
    
    res.status(200).json({
      success: true,
      message: 'Package deleted successfully',
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Delete package error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete package',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

// Search packages and services
router.get('/search', async (req: Request, res: Response) => {
  try {
    const { q: searchTerm } = req.query;
    
    if (!searchTerm || typeof searchTerm !== 'string') {
      res.status(400).json({
        success: false,
        message: 'Search term is required',
        timestamp: new Date()
      } as ApiResponse);
      return;
    }
    
    const results = await PackageManagementService.searchPackagesAndServices(searchTerm);
    
    res.status(200).json({
      success: true,
      message: 'Search completed successfully',
      data: results,
      timestamp: new Date()
    } as ApiResponse);
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({
      success: false,
      message: 'Search failed',
      error: process.env.NODE_ENV === 'development' ? (error as Error).message : undefined,
      timestamp: new Date()
    } as ApiResponse);
  }
});

export default router;
