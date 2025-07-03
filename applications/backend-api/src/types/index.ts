export interface User {
  id: string;
  cognito_user_id: string;
  user_type: 'CLIENTE' | 'ADMINISTRADOR' | 'PERSONAL';
  first_name: string;
  last_name: string;
  phone?: string;
  date_of_birth?: Date;
  address?: string;
  emergency_contact?: string;
  emergency_phone?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface Role {
  id: number;
  name: string;
  description?: string;
  permissions: Record<string, any>;
  created_at: Date;
}

export interface UserRole {
  user_id: string;
  role_id: number;
  assigned_at: Date;
  assigned_by: string;
}

export interface Service {
  id: number;
  category_id: number;
  name: string;
  description?: string;
  base_price: number;
  duration_hours?: number;
  max_capacity?: number;
  requirements?: string;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface ServiceCategory {
  id: number;
  name: string;
  description?: string;
  is_active: boolean;
  created_at: Date;
}

export interface Package {
  id: number;
  name: string;
  description?: string;
  total_price: number;
  discount_percentage: number;
  duration_hours?: number;
  max_capacity?: number;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface PackageService {
  package_id: number;
  service_id: number;
  quantity: number;
  custom_price?: number;
}

export interface Quotation {
  id: string;
  client_id: string;
  quotation_number: string;
  event_type?: string;
  event_date?: Date;
  estimated_guests?: number;
  total_amount: number;
  discount_amount: number;
  tax_amount: number;
  final_amount: number;
  status: 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED';
  valid_until?: Date;
  notes?: string;
  created_by?: string;
  created_at: Date;
  updated_at: Date;
}

export interface QuotationDetail {
  id: number;
  quotation_id: string;
  item_type: 'SERVICE' | 'PACKAGE';
  item_id: number;
  quantity: number;
  unit_price: number;
  total_price: number;
  notes?: string;
}

export interface Reservation {
  id: string;
  quotation_id: string;
  client_id: string;
  event_date: Date;
  event_time: string;
  venue?: string;
  setup_time?: string;
  breakdown_time?: string;
  special_requirements?: string;
  total_amount: number;
  status: 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
  created_at: Date;
  updated_at: Date;
}

export interface Payment {
  id: string;
  reservation_id: string;
  amount: number;
  payment_method: 'CASH' | 'CARD' | 'TRANSFER' | 'CHECK';
  transaction_id?: string;
  payment_date: Date;
  status: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';
  notes?: string;
  created_at: Date;
}

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  message: string;
  type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR';
  is_read: boolean;
  created_at: Date;
}

export interface AuthUser extends User {
  token?: string;
  refreshToken?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone?: string;
  user_type: 'CLIENTE' | 'ADMINISTRADOR' | 'PERSONAL';
}

export interface CreateQuotationRequest {
  client_id: string;
  event_type?: string;
  event_date?: Date;
  estimated_guests?: number;
  items: {
    item_type: 'SERVICE' | 'PACKAGE';
    item_id: number;
    quantity: number;
  }[];
  discount_amount?: number;
  notes?: string;
}

export interface CreateReservationRequest {
  quotation_id: string;
  event_date: Date;
  event_time: string;
  venue?: string;
  setup_time?: string;
  breakdown_time?: string;
  special_requirements?: string;
}

export interface ProcessPaymentRequest {
  reservation_id: string;
  amount: number;
  payment_method: 'CASH' | 'CARD' | 'TRANSFER' | 'CHECK';
  transaction_id?: string;
  notes?: string;
}

// API Response interfaces
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
  timestamp: Date;
}

export interface PaginatedResponse<T = any> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

// JWT Token interface
export interface JWTPayload {
  userId: string;
  userType: string;
  cognitoUserId: string;
  iat?: number;
  exp?: number;
}
