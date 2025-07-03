import { executeQuery, executeTransaction } from '../config/database';
import { User, Role, UserRole, RegisterRequest } from '../types';
import { v4 as uuidv4 } from 'uuid';

export class UserService {
  // Create a new user profile
  static async createUser(userData: RegisterRequest): Promise<User> {
    const userId = uuidv4();
    
    const query = `
      INSERT INTO user_profiles (
        id, cognito_user_id, user_type, first_name, last_name, phone, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, true)
    `;
    
    const params = [
      userId,
      userData.email, // Using email as cognito_user_id for now
      userData.user_type,
      userData.first_name,
      userData.last_name,
      userData.phone || null
    ];
    
    await executeQuery(query, params);
    
    return await this.getUserById(userId);
  }

  // Get user by ID
  static async getUserById(userId: string): Promise<User> {
    const query = 'SELECT * FROM user_profiles WHERE id = ?';
    const results = await executeQuery(query, [userId]);
    
    if (!results || results.length === 0) {
      throw new Error('User not found');
    }
    
    return results[0] as User;
  }

  // Get user by Cognito ID
  static async getUserByCognitoId(cognitoUserId: string): Promise<User> {
    const query = 'SELECT * FROM user_profiles WHERE cognito_user_id = ?';
    const results = await executeQuery(query, [cognitoUserId]);
    
    if (!results || results.length === 0) {
      throw new Error('User not found');
    }
    
    return results[0] as User;
  }

  // Update user profile
  static async updateUser(userId: string, updateData: Partial<User>): Promise<User> {
    const allowedFields = ['first_name', 'last_name', 'phone', 'date_of_birth', 'address', 'emergency_contact', 'emergency_phone'];
    const updates: string[] = [];
    const params: any[] = [];
    
    Object.keys(updateData).forEach(key => {
      if (allowedFields.includes(key) && updateData[key as keyof User] !== undefined) {
        updates.push(`${key} = ?`);
        params.push(updateData[key as keyof User]);
      }
    });
    
    if (updates.length === 0) {
      throw new Error('No valid fields to update');
    }
    
    params.push(userId);
    const query = `UPDATE user_profiles SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
    
    await executeQuery(query, params);
    return await this.getUserById(userId);
  }

  // Get all users with pagination
  static async getAllUsers(page: number = 1, limit: number = 10, userType?: string): Promise<{ users: User[], total: number }> {
    const offset = (page - 1) * limit;
    let whereClause = '';
    const params: any[] = [];
    
    if (userType) {
      whereClause = 'WHERE user_type = ?';
      params.push(userType);
    }
    
    const countQuery = `SELECT COUNT(*) as total FROM user_profiles ${whereClause}`;
    const dataQuery = `SELECT * FROM user_profiles ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`;
    
    params.push(limit, offset);
    
    const [countResult, dataResult] = await Promise.all([
      executeQuery(countQuery, userType ? [userType] : []),
      executeQuery(dataQuery, params)
    ]);
    
    return {
      users: dataResult as User[],
      total: countResult[0].total
    };
  }

  // Deactivate user
  static async deactivateUser(userId: string): Promise<void> {
    const query = 'UPDATE user_profiles SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await executeQuery(query, [userId]);
  }

  // Activate user
  static async activateUser(userId: string): Promise<void> {
    const query = 'UPDATE user_profiles SET is_active = true, updated_at = CURRENT_TIMESTAMP WHERE id = ?';
    await executeQuery(query, [userId]);
  }

  // Get user roles
  static async getUserRoles(userId: string): Promise<Role[]> {
    const query = `
      SELECT r.* FROM roles r
      JOIN user_roles ur ON r.id = ur.role_id
      WHERE ur.user_id = ?
    `;
    
    const results = await executeQuery(query, [userId]);
    return results as Role[];
  }

  // Assign role to user
  static async assignRole(userId: string, roleId: number, assignedBy: string): Promise<void> {
    const query = `
      INSERT INTO user_roles (user_id, role_id, assigned_by)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE assigned_at = CURRENT_TIMESTAMP, assigned_by = ?
    `;
    
    await executeQuery(query, [userId, roleId, assignedBy, assignedBy]);
  }

  // Remove role from user
  static async removeRole(userId: string, roleId: number): Promise<void> {
    const query = 'DELETE FROM user_roles WHERE user_id = ? AND role_id = ?';
    await executeQuery(query, [userId, roleId]);
  }

  // Search users
  static async searchUsers(searchTerm: string, userType?: string): Promise<User[]> {
    let query = `
      SELECT * FROM user_profiles 
      WHERE (first_name LIKE ? OR last_name LIKE ? OR phone LIKE ?)
    `;
    const params = [`%${searchTerm}%`, `%${searchTerm}%`, `%${searchTerm}%`];
    
    if (userType) {
      query += ' AND user_type = ?';
      params.push(userType);
    }
    
    query += ' ORDER BY first_name, last_name LIMIT 20';
    
    const results = await executeQuery(query, params);
    return results as User[];
  }
}
