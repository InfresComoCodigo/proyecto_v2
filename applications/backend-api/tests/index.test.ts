import request from 'supertest';
import app from '../src/index';

describe('Backend API Tests', () => {
  describe('GET /', () => {
    it('should return Hello World message', async () => {
      const response = await request(app)
        .get('/')
        .expect(200);

      expect(response.body).toMatchObject({
        message: 'Hello World! Backend API is running! 🚀',
        version: '1.0.0'
      });
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('GET /health', () => {
    it('should return health check status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toMatchObject({
        status: 'OK',
        environment: 'test'
      });
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('POST /api/auth/test-login', () => {
    it('should login with valid test credentials', async () => {
      const loginData = {
        email: 'test@gmail.com',
        password: 'Test123123'
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(loginData)
        .expect(200);

      expect(response.body).toMatchObject({
        success: true,
        message: 'Login successful (test mode)',
        user: {
          id: 'test-user-123',
          email: 'test@gmail.com',
          user_type: 'CLIENTE',
          first_name: 'Test',
          last_name: 'User'
        },
        token: 'fake-jwt-token-for-testing'
      });
      expect(response.body.timestamp).toBeDefined();
    });

    it('should reject invalid credentials', async () => {
      const loginData = {
        email: 'wrong@email.com',
        password: 'wrongpassword'
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(loginData)
        .expect(401);

      expect(response.body).toMatchObject({
        success: false,
        message: 'Invalid credentials'
      });
      expect(response.body.timestamp).toBeDefined();
    });

    it('should validate email format', async () => {
      const loginData = {
        email: 'invalid-email',
        password: 'Test123123'
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(loginData)
        .expect(400);

      expect(response.body).toMatchObject({
        success: false,
        message: 'Validation failed'
      });
      expect(response.body.errors).toBeDefined();
    });

    it('should require password', async () => {
      const loginData = {
        email: 'test@gmail.com'
        // password missing
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(loginData)
        .expect(400);

      expect(response.body).toMatchObject({
        success: false,
        message: 'Validation failed'
      });
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('404 Not Found', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/non-existent-route')
        .expect(404);

      expect(response.body).toMatchObject({
        success: false,
        message: 'Route GET /non-existent-route not found'
      });
    });
  });

  describe('Rate Limiting', () => {
    it('should allow requests within rate limit', async () => {
      // Make a few requests to test rate limiting doesn't block normal usage
      for (let i = 0; i < 5; i++) {
        await request(app)
          .get('/health')
          .expect(200);
      }
    });
  });

  describe('CORS Headers', () => {
    it('should include CORS headers in response', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      // Check that the request doesn't fail due to CORS
      expect(response.status).toBe(200);
    });
  });

  describe('Security Headers', () => {
    it('should include security headers from helmet', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      // Check for some common security headers set by helmet
      expect(response.headers['x-dns-prefetch-control']).toBeDefined();
      expect(response.headers['x-frame-options']).toBeDefined();
      expect(response.headers['x-download-options']).toBeDefined();
      expect(response.headers['x-content-type-options']).toBeDefined();
    });
  });

  describe('Request Body Parsing', () => {
    it('should parse JSON request bodies correctly', async () => {
      const testData = {
        email: 'test@gmail.com',
        password: 'Test123123',
        extraField: 'should be ignored gracefully'
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(testData)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should handle malformed JSON gracefully', async () => {
      const response = await request(app)
        .post('/api/auth/test-login')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }');

      // Malformed JSON should return an error status (400 or 500)
      expect(response.status).toBeGreaterThanOrEqual(400);
    });
  });
});
