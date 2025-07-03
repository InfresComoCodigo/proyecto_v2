/**
 * Ejemplo simple de pruebas unitarias para el backend
 * Este archivo demuestra las pruebas básicas más importante
 */

import request from 'supertest';
import app from '../src/index';

describe('🚀 Backend API - Pruebas Básicas', () => {
  
  // Prueba de Hello World
  test('GET / debe retornar mensaje de bienvenida', async () => {
    const response = await request(app).get('/');
    
    expect(response.status).toBe(200);
    expect(response.body.message).toBe('Hello World! Backend API is running! 🚀');
    expect(response.body.version).toBe('1.0.0');
  });

  // Prueba de Health Check
  test('GET /health debe retornar estado OK', async () => {
    const response = await request(app).get('/health');
    
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('OK');
    expect(response.body.environment).toBe('test');
  });

  // Prueba de login exitoso
  test('POST /api/auth/test-login debe permitir login con credenciales válidas', async () => {
    const credenciales = {
      email: 'test@gmail.com',
      password: 'Test123123'
    };

    const response = await request(app)
      .post('/api/auth/test-login')
      .send(credenciales);
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.user.email).toBe('test@gmail.com');
    expect(response.body.token).toBe('fake-jwt-token-for-testing');
  });

  // Prueba de login fallido
  test('POST /api/auth/test-login debe rechazar credenciales inválidas', async () => {
    const credenciales = {
      email: 'wrong@email.com',
      password: 'wrongpassword'
    };

    const response = await request(app)
      .post('/api/auth/test-login')
      .send(credenciales);
    
    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toBe('Invalid credentials');
  });

  // Prueba de validación de email
  test('POST /api/auth/test-login debe validar formato de email', async () => {
    const credenciales = {
      email: 'email-invalido',
      password: 'Test123123'
    };

    const response = await request(app)
      .post('/api/auth/test-login')
      .send(credenciales);
    
    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toBe('Validation failed');
    expect(response.body.errors).toBeDefined();
  });

  // Prueba de ruta no encontrada
  test('GET /ruta-inexistente debe retornar 404', async () => {
    const response = await request(app).get('/ruta-inexistente');
    
    expect(response.status).toBe(404);
    expect(response.body.success).toBe(false);
    expect(response.body.message).toContain('not found');
  });
});
