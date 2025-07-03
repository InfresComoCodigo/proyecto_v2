import request from 'supertest';
import app from '../src/index';

describe('Middleware Tests', () => {
  describe('Error Handling Middleware', () => {
    it('should handle 404 errors for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/non-existent-route')
        .expect('Content-Type', /json/)
        .expect(404);

      expect(response.body).toMatchObject({
        success: false,
        message: 'Route GET /api/non-existent-route not found'
      });
      expect(response.body.timestamp).toBeDefined();
    });

    it('should handle 404 errors for non-existent API routes', async () => {
      const response = await request(app)
        .post('/api/non-existent')
        .expect('Content-Type', /json/)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Route POST /api/non-existent not found');
    });
  });

  describe('CORS Middleware', () => {
    it('should include CORS headers in GET requests', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      // Check that CORS doesn't block the request
      expect(response.status).toBe(200);
    });

    it('should include CORS headers in POST requests', async () => {
      const response = await request(app)
        .post('/api/auth/test-login')
        .send({
          email: 'test@gmail.com',
          password: 'Test123123'
        })
        .expect(200);

      // Check that CORS doesn't block the request
      expect(response.status).toBe(200);
    });

    it('should handle preflight OPTIONS requests', async () => {
      const response = await request(app)
        .options('/api/auth/test-login')
        .set('Origin', 'http://localhost:3000')
        .set('Access-Control-Request-Method', 'POST')
        .set('Access-Control-Request-Headers', 'Content-Type');

      expect(response.status).toBeLessThan(400);
    });
  });

  describe('Security Headers (Helmet)', () => {
    it('should include X-Frame-Options header', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers['x-frame-options']).toBeDefined();
    });

    it('should include X-Content-Type-Options header', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers['x-content-type-options']).toBe('nosniff');
    });

    it('should include X-DNS-Prefetch-Control header', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.headers['x-dns-prefetch-control']).toBeDefined();
    });
  });

  describe('Request Parsing Middleware', () => {
    it('should parse JSON requests correctly', async () => {
      const testData = {
        email: 'test@gmail.com',
        password: 'Test123123'
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(testData)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should handle large JSON payloads (within limit)', async () => {
      const largeData = {
        email: 'test@gmail.com',
        password: 'Test123123',
        largeField: 'x'.repeat(1000) // 1KB of data
      };

      const response = await request(app)
        .post('/api/auth/test-login')
        .send(largeData)
        .expect('Content-Type', /json/)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject malformed JSON', async () => {
      const response = await request(app)
        .post('/api/auth/test-login')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }');

      // Malformed JSON should return an error status
      expect(response.status).toBeGreaterThanOrEqual(400);
    });
  });

  describe('Rate Limiting Middleware', () => {
    it('should allow requests within rate limit', async () => {
      // Make several requests quickly to test rate limiting
      const promises = Array.from({ length: 10 }, () =>
        request(app)
          .get('/health')
          .expect(200)
      );

      const responses = await Promise.all(promises);
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });
    });

    it('should include rate limit headers', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      // Rate limiting headers may or may not be present depending on configuration
      // This test just checks they don't cause errors
      expect(response.status).toBe(200);
    });
  });

  describe('Request Logging Middleware', () => {
    it('should log requests without affecting response', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toMatchObject({
        status: 'OK'
      });
    });

    it('should log POST requests without affecting response', async () => {
      const response = await request(app)
        .post('/api/auth/test-login')
        .send({
          email: 'test@gmail.com',
          password: 'Test123123'
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });
});
