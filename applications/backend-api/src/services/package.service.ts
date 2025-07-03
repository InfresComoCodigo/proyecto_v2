import { executeQuery } from '../config/database';
import { Package, Service, ServiceCategory } from '../types';

export class PackageManagementService {
  // Get all service categories
  static async getServiceCategories(): Promise<ServiceCategory[]> {
    const query = 'SELECT * FROM service_categories WHERE is_active = true ORDER BY name';
    const results = await executeQuery(query);
    return results as ServiceCategory[];
  }

  // Get services by category
  static async getServicesByCategory(categoryId: number): Promise<Service[]> {
    const query = 'SELECT * FROM services WHERE category_id = ? AND is_active = true ORDER BY name';
    const results = await executeQuery(query, [categoryId]);
    return results as Service[];
  }

  // Get all services
  static async getAllServices(): Promise<Service[]> {
    const query = `
      SELECT s.*, sc.name as category_name 
      FROM services s 
      JOIN service_categories sc ON s.category_id = sc.id 
      WHERE s.is_active = true 
      ORDER BY sc.name, s.name
    `;
    const results = await executeQuery(query);
    return results as Service[];
  }

  // Get service by ID
  static async getServiceById(serviceId: number): Promise<Service> {
    const query = 'SELECT * FROM services WHERE id = ? AND is_active = true';
    const results = await executeQuery(query, [serviceId]);
    
    if (!results || results.length === 0) {
      throw new Error('Service not found');
    }
    
    return results[0] as Service;
  }

  // Create new service
  static async createService(serviceData: Omit<Service, 'id' | 'created_at' | 'updated_at'>): Promise<Service> {
    const query = `
      INSERT INTO services (
        category_id, name, description, base_price, duration_hours, 
        max_capacity, requirements, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const params = [
      serviceData.category_id,
      serviceData.name,
      serviceData.description || null,
      serviceData.base_price,
      serviceData.duration_hours || null,
      serviceData.max_capacity || null,
      serviceData.requirements || null,
      serviceData.is_active !== false
    ];
    
    const result = await executeQuery(query, params);
    return await this.getServiceById(result.insertId);
  }

  // Update service
  static async updateService(serviceId: number, updateData: Partial<Service>): Promise<Service> {
    const allowedFields = ['name', 'description', 'base_price', 'duration_hours', 'max_capacity', 'requirements', 'is_active'];
    const updates: string[] = [];
    const params: any[] = [];
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key) && updateData[key as keyof Service] !== undefined) {
        updates.push(`${key} = ?`);
        params.push(updateData[key as keyof Service]);
      }
    });
    
    if (updates.length === 0) {
      throw new Error('No valid fields to update');
    }
    
    params.push(serviceId);
    const query = `UPDATE services SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
    
    await executeQuery(query, params);
    return await this.getServiceById(serviceId);
  }

  // Get all packages
  static async getAllPackages(): Promise<Package[]> {
    const query = `
      SELECT p.*, 
             COUNT(ps.service_id) as service_count,
             GROUP_CONCAT(s.name) as service_names
      FROM packages p
      LEFT JOIN package_services ps ON p.id = ps.package_id
      LEFT JOIN services s ON ps.service_id = s.id
      WHERE p.is_active = true
      GROUP BY p.id
      ORDER BY p.name
    `;
    const results = await executeQuery(query);
    return results as Package[];
  }

  // Get package by ID with services
  static async getPackageById(packageId: number): Promise<Package & { services?: Service[] }> {
    const packageQuery = 'SELECT * FROM packages WHERE id = ? AND is_active = true';
    const servicesQuery = `
      SELECT s.*, ps.quantity, ps.custom_price
      FROM services s
      JOIN package_services ps ON s.id = ps.service_id
      WHERE ps.package_id = ?
    `;
    
    const [packageResult, servicesResult] = await Promise.all([
      executeQuery(packageQuery, [packageId]),
      executeQuery(servicesQuery, [packageId])
    ]);
    
    if (!packageResult || packageResult.length === 0) {
      throw new Error('Package not found');
    }
    
    const packageData = packageResult[0] as Package;
    (packageData as any).services = servicesResult as Service[];
    
    return packageData;
  }

  // Create new package
  static async createPackage(
    packageData: Omit<Package, 'id' | 'created_at' | 'updated_at'>,
    services: { service_id: number; quantity: number; custom_price?: number }[]
  ): Promise<Package> {
    const packageQuery = `
      INSERT INTO packages (
        name, description, total_price, discount_percentage, 
        duration_hours, max_capacity, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    
    const packageParams = [
      packageData.name,
      packageData.description || null,
      packageData.total_price,
      packageData.discount_percentage || 0,
      packageData.duration_hours || null,
      packageData.max_capacity || null,
      packageData.is_active !== false
    ];
    
    const packageResult = await executeQuery(packageQuery, packageParams);
    const packageId = packageResult.insertId;
    
    // Add services to package
    if (services && services.length > 0) {
      const serviceQueries = services.map(service => ({
        query: 'INSERT INTO package_services (package_id, service_id, quantity, custom_price) VALUES (?, ?, ?, ?)',
        params: [packageId, service.service_id, service.quantity, service.custom_price || null]
      }));
      
      await Promise.all(serviceQueries.map(sq => executeQuery(sq.query, sq.params)));
    }
    
    return await this.getPackageById(packageId);
  }

  // Update package
  static async updatePackage(
    packageId: number,
    updateData: Partial<Package>,
    services?: { service_id: number; quantity: number; custom_price?: number }[]
  ): Promise<Package> {
    const allowedFields = ['name', 'description', 'total_price', 'discount_percentage', 'duration_hours', 'max_capacity', 'is_active'];
    const updates: string[] = [];
    const params: any[] = [];
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key) && updateData[key as keyof Package] !== undefined) {
        updates.push(`${key} = ?`);
        params.push(updateData[key as keyof Package]);
      }
    });
    
    if (updates.length > 0) {
      params.push(packageId);
      const query = `UPDATE packages SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
      await executeQuery(query, params);
    }
    
    // Update services if provided
    if (services) {
      // Remove existing services
      await executeQuery('DELETE FROM package_services WHERE package_id = ?', [packageId]);
      
      // Add new services
      if (services.length > 0) {
        const serviceQueries = services.map(service => ({
          query: 'INSERT INTO package_services (package_id, service_id, quantity, custom_price) VALUES (?, ?, ?, ?)',
          params: [packageId, service.service_id, service.quantity, service.custom_price || null]
        }));
        
        await Promise.all(serviceQueries.map(sq => executeQuery(sq.query, sq.params)));
      }
    }
    
    return await this.getPackageById(packageId);
  }

  // Delete package (soft delete)
  static async deletePackage(packageId: number): Promise<void> {
    const query = 'UPDATE packages SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await executeQuery(query, [packageId]);
  }

  // Search packages and services
  static async searchPackagesAndServices(searchTerm: string): Promise<{ packages: Package[], services: Service[] }> {
    const packageQuery = `
      SELECT * FROM packages 
      WHERE (name LIKE ? OR description LIKE ?) AND is_active = true 
      ORDER BY name LIMIT 10
    `;
    
    const serviceQuery = `
      SELECT s.*, sc.name as category_name 
      FROM services s 
      JOIN service_categories sc ON s.category_id = sc.id 
      WHERE (s.name LIKE ? OR s.description LIKE ?) AND s.is_active = true 
      ORDER BY s.name LIMIT 10
    `;
    
    const searchPattern = `%${searchTerm}%`;
    
    const [packages, services] = await Promise.all([
      executeQuery(packageQuery, [searchPattern, searchPattern]),
      executeQuery(serviceQuery, [searchPattern, searchPattern])
    ]);
    
    return {
      packages: packages as Package[],
      services: services as Service[]
    };
  }
}
