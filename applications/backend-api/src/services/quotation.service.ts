import { executeQuery, executeTransaction } from '../config/database';
import { Quotation, QuotationDetail, CreateQuotationRequest } from '../types';
import { v4 as uuidv4 } from 'uuid';

export class QuotationService {
  // Generate quotation number
  private static generateQuotationNumber(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const timestamp = Date.now().toString().slice(-6);
    return `COT-${year}${month}${day}-${timestamp}`;
  }

  // Create new quotation
  static async createQuotation(quotationData: CreateQuotationRequest, createdBy: string): Promise<Quotation> {
    const quotationId = uuidv4();
    const quotationNumber = this.generateQuotationNumber();
    
    // Calculate totals
    let totalAmount = 0;
    const quotationDetails: QuotationDetail[] = [];
    
    // Get prices for each item
    for (const item of quotationData.items) {
      let unitPrice = 0;
      
      if (item.item_type === 'SERVICE') {
        const serviceQuery = 'SELECT base_price FROM services WHERE id = ?';
        const serviceResult = await executeQuery(serviceQuery, [item.item_id]);
        if (serviceResult.length === 0) {
          throw new Error(`Service with ID ${item.item_id} not found`);
        }
        unitPrice = serviceResult[0].base_price;
      } else {
        const packageQuery = 'SELECT total_price FROM packages WHERE id = ?';
        const packageResult = await executeQuery(packageQuery, [item.item_id]);
        if (packageResult.length === 0) {
          throw new Error(`Package with ID ${item.item_id} not found`);
        }
        unitPrice = packageResult[0].total_price;
      }
      
      const itemTotal = unitPrice * item.quantity;
      totalAmount += itemTotal;
      
      quotationDetails.push({
        id: 0, // Will be set by database
        quotation_id: quotationId,
        item_type: item.item_type,
        item_id: item.item_id,
        quantity: item.quantity,
        unit_price: unitPrice,
        total_price: itemTotal
      });
    }
    
    const discountAmount = quotationData.discount_amount || 0;
    const taxAmount = (totalAmount - discountAmount) * 0.18; // 18% tax
    const finalAmount = totalAmount - discountAmount + taxAmount;
    
    // Set valid until date (30 days from now)
    const validUntil = new Date();
    validUntil.setDate(validUntil.getDate() + 30);
    
    const queries = [
      {
        query: `
          INSERT INTO quotations (
            id, client_id, quotation_number, event_type, event_date, 
            estimated_guests, total_amount, discount_amount, tax_amount, 
            final_amount, status, valid_until, notes, created_by
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'DRAFT', ?, ?, ?)
        `,
        params: [
          quotationId,
          quotationData.client_id,
          quotationNumber,
          quotationData.event_type || null,
          quotationData.event_date || null,
          quotationData.estimated_guests || null,
          totalAmount,
          discountAmount,
          taxAmount,
          finalAmount,
          validUntil,
          quotationData.notes || null,
          createdBy
        ]
      },
      ...quotationDetails.map(detail => ({
        query: `
          INSERT INTO quotation_details (
            quotation_id, item_type, item_id, quantity, unit_price, total_price
          ) VALUES (?, ?, ?, ?, ?, ?)
        `,
        params: [
          detail.quotation_id,
          detail.item_type,
          detail.item_id,
          detail.quantity,
          detail.unit_price,
          detail.total_price
        ]
      }))
    ];
    
    await executeTransaction(queries);
    return await this.getQuotationById(quotationId);
  }

  // Get quotation by ID with details
  static async getQuotationById(quotationId: string): Promise<Quotation & { details: QuotationDetail[] }> {
    const quotationQuery = `
      SELECT q.*, 
             CONCAT(u.first_name, ' ', u.last_name) as client_name,
             CONCAT(c.first_name, ' ', c.last_name) as created_by_name
      FROM quotations q
      JOIN user_profiles u ON q.client_id = u.id
      LEFT JOIN user_profiles c ON q.created_by = c.id
      WHERE q.id = ?
    `;
    
    const detailsQuery = `
      SELECT qd.*, 
             CASE 
               WHEN qd.item_type = 'SERVICE' THEN s.name
               WHEN qd.item_type = 'PACKAGE' THEN p.name
             END as item_name
      FROM quotation_details qd
      LEFT JOIN services s ON qd.item_type = 'SERVICE' AND qd.item_id = s.id
      LEFT JOIN packages p ON qd.item_type = 'PACKAGE' AND qd.item_id = p.id
      WHERE qd.quotation_id = ?
      ORDER BY qd.id
    `;
    
    const [quotationResult, detailsResult] = await Promise.all([
      executeQuery(quotationQuery, [quotationId]),
      executeQuery(detailsQuery, [quotationId])
    ]);
    
    if (!quotationResult || quotationResult.length === 0) {
      throw new Error('Quotation not found');
    }
    
    const quotation = quotationResult[0] as Quotation;
    (quotation as any).details = detailsResult as QuotationDetail[];
    
    return quotation as Quotation & { details: QuotationDetail[] };
  }

  // Get all quotations with pagination
  static async getAllQuotations(
    page: number = 1,
    limit: number = 10,
    status?: string,
    clientId?: string
  ): Promise<{ quotations: Quotation[], total: number }> {
    const offset = (page - 1) * limit;
    const conditions: string[] = [];
    const params: any[] = [];
    
    if (status) {
      conditions.push('q.status = ?');
      params.push(status);
    }
    
    if (clientId) {
      conditions.push('q.client_id = ?');
      params.push(clientId);
    }
    
    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    
    const countQuery = `SELECT COUNT(*) as total FROM quotations q ${whereClause}`;
    const dataQuery = `
      SELECT q.*, 
             CONCAT(u.first_name, ' ', u.last_name) as client_name
      FROM quotations q
      JOIN user_profiles u ON q.client_id = u.id
      ${whereClause}
      ORDER BY q.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const countParams = [...params];
    const dataParams = [...params, limit, offset];
    
    const [countResult, dataResult] = await Promise.all([
      executeQuery(countQuery, countParams),
      executeQuery(dataQuery, dataParams)
    ]);
    
    return {
      quotations: dataResult as Quotation[],
      total: countResult[0].total
    };
  }

  // Update quotation status
  static async updateQuotationStatus(quotationId: string, status: string): Promise<Quotation> {
    const allowedStatuses = ['DRAFT', 'SENT', 'APPROVED', 'REJECTED', 'EXPIRED'];
    
    if (!allowedStatuses.includes(status)) {
      throw new Error('Invalid status');
    }
    
    const query = `
      UPDATE quotations 
      SET status = ?, updated_at = CURRENT_TIMESTAMP 
      WHERE id = ?
    `;
    
    await executeQuery(query, [status, quotationId]);
    return await this.getQuotationById(quotationId);
  }

  // Send quotation to client
  static async sendQuotation(quotationId: string): Promise<Quotation> {
    return await this.updateQuotationStatus(quotationId, 'SENT');
  }

  // Approve quotation
  static async approveQuotation(quotationId: string): Promise<Quotation> {
    return await this.updateQuotationStatus(quotationId, 'APPROVED');
  }

  // Reject quotation
  static async rejectQuotation(quotationId: string): Promise<Quotation> {
    return await this.updateQuotationStatus(quotationId, 'REJECTED');
  }

  // Get quotations by client
  static async getQuotationsByClient(clientId: string): Promise<Quotation[]> {
    const query = `
      SELECT q.*, 
             CONCAT(c.first_name, ' ', c.last_name) as created_by_name
      FROM quotations q
      LEFT JOIN user_profiles c ON q.created_by = c.id
      WHERE q.client_id = ?
      ORDER BY q.created_at DESC
    `;
    
    const results = await executeQuery(query, [clientId]);
    return results as Quotation[];
  }

  // Get expired quotations
  static async getExpiredQuotations(): Promise<Quotation[]> {
    const query = `
      SELECT q.*, 
             CONCAT(u.first_name, ' ', u.last_name) as client_name
      FROM quotations q
      JOIN user_profiles u ON q.client_id = u.id
      WHERE q.valid_until < CURDATE() AND q.status IN ('DRAFT', 'SENT')
    `;
    
    const results = await executeQuery(query);
    return results as Quotation[];
  }

  // Mark expired quotations
  static async markExpiredQuotations(): Promise<number> {
    const query = `
      UPDATE quotations 
      SET status = 'EXPIRED', updated_at = CURRENT_TIMESTAMP
      WHERE valid_until < CURDATE() AND status IN ('DRAFT', 'SENT')
    `;
    
    const result = await executeQuery(query);
    return result.affectedRows || 0;
  }

  // Update quotation
  static async updateQuotation(
    quotationId: string,
    updateData: Partial<CreateQuotationRequest>
  ): Promise<Quotation> {
    const allowedFields = ['event_type', 'event_date', 'estimated_guests', 'notes'];
    const updates: string[] = [];
    const params: any[] = [];
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key) && updateData[key as keyof CreateQuotationRequest] !== undefined) {
        updates.push(`${key} = ?`);
        params.push(updateData[key as keyof CreateQuotationRequest]);
      }
    });
    
    if (updates.length > 0) {
      params.push(quotationId);
      const query = `UPDATE quotations SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
      await executeQuery(query, params);
    }
    
    return await this.getQuotationById(quotationId);
  }

  // Delete quotation (only if in DRAFT status)
  static async deleteQuotation(quotationId: string): Promise<void> {
    // Check if quotation can be deleted
    const checkQuery = 'SELECT status FROM quotations WHERE id = ?';
    const checkResult = await executeQuery(checkQuery, [quotationId]);
    
    if (!checkResult || checkResult.length === 0) {
      throw new Error('Quotation not found');
    }
    
    if (checkResult[0].status !== 'DRAFT') {
      throw new Error('Only draft quotations can be deleted');
    }
    
    const queries = [
      { query: 'DELETE FROM quotation_details WHERE quotation_id = ?', params: [quotationId] },
      { query: 'DELETE FROM quotations WHERE id = ?', params: [quotationId] }
    ];
    
    await executeTransaction(queries);
  }
}
