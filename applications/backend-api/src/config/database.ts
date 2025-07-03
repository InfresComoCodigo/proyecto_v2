import mysql from 'mysql2/promise';
import { config } from 'dotenv';

config();

export interface DatabaseConfig {
  host: string;
  port: number;
  user: string;
  password: string;
  database: string;
  timezone: string;
  charset: string;
  acquireTimeout: number;
  timeout: number;
  reconnect: boolean;
  connectionLimit: number;
}

const dbConfig: DatabaseConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'IAC',
  timezone: '+00:00',
  charset: 'utf8mb4',
  acquireTimeout: 60000,
  timeout: 60000,
  reconnect: true,
  connectionLimit: 10
};

// Create connection pool (only if database connection is enabled)
export let pool: mysql.Pool | null = null;

// Initialize database connection
export const initializeDatabase = () => {
  if (!pool) {
    pool = mysql.createPool(dbConfig);
  }
  return pool;
};

// Test database connection
export const connectDB = async (): Promise<void> => {
  try {
    if (!pool) {
      initializeDatabase();
    }
    if (pool) {
      const connection = await pool.getConnection();
      console.log(`✅ Connected to MySQL database: ${dbConfig.database}`);
      connection.release();
    }
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    throw error;
  }
};

// Helper function to execute queries
export const executeQuery = async (query: string, params: any[] = []): Promise<any> => {
  try {
    if (!pool) {
      throw new Error('Database not initialized. Call initializeDatabase() first.');
    }
    const [results] = await pool.execute(query, params);
    return results;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

// Helper function for transactions
export const executeTransaction = async (queries: Array<{ query: string; params: any[] }>): Promise<any> => {
  if (!pool) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    
    const results = [];
    for (const { query, params } of queries) {
      const [result] = await connection.execute(query, params);
      results.push(result);
    }
    
    await connection.commit();
    return results;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

export default pool;
