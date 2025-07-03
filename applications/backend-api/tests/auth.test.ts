import request from 'supertest';
import app from '../src/index';

describe('Authentication Routes Tests', () => {
  describe('POST /api/auth/test-login', () => {
    describe('Successful Login', () => {
      it('should accept valid credentials', async () => {
        const validCredentials = {
          email: 'test@gmail.com',
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(validCredentials)
          .expect('Content-Type', /json/)
          .expect(200);

        expect(response.body).toEqual({
          success: true,
          message: 'Login successful (test mode)',
          user: {
            id: 'test-user-123',
            email: 'test@gmail.com',
            user_type: 'CLIENTE',
            first_name: 'Test',
            last_name: 'User'
          },
          token: 'fake-jwt-token-for-testing',
          timestamp: expect.any(String)
        });
      });
    });

    describe('Failed Login', () => {
      it('should reject wrong email', async () => {
        const invalidCredentials = {
          email: 'wrong@gmail.com',
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(invalidCredentials)
          .expect('Content-Type', /json/)
          .expect(401);

        expect(response.body).toEqual({
          success: false,
          message: 'Invalid credentials',
          timestamp: expect.any(String)
        });
      });

      it('should reject wrong password', async () => {
        const invalidCredentials = {
          email: 'test@gmail.com',
          password: 'wrongpassword'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(invalidCredentials)
          .expect('Content-Type', /json/)
          .expect(401);

        expect(response.body).toEqual({
          success: false,
          message: 'Invalid credentials',
          timestamp: expect.any(String)
        });
      });
    });

    describe('Validation Errors', () => {
      it('should validate email format', async () => {
        const invalidEmail = {
          email: 'not-an-email',
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(invalidEmail)
          .expect('Content-Type', /json/)
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.message).toBe('Validation failed');
        expect(response.body.errors).toBeInstanceOf(Array);
        expect(response.body.errors.length).toBeGreaterThan(0);
      });

      it('should require email field', async () => {
        const missingEmail = {
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(missingEmail)
          .expect('Content-Type', /json/)
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.message).toBe('Validation failed');
        expect(response.body.errors).toBeInstanceOf(Array);
      });

      it('should require password field', async () => {
        const missingPassword = {
          email: 'test@gmail.com'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(missingPassword)
          .expect('Content-Type', /json/)
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.message).toBe('Validation failed');
        expect(response.body.errors).toBeInstanceOf(Array);
      });

      it('should require both email and password', async () => {
        const emptyCredentials = {};

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(emptyCredentials)
          .expect('Content-Type', /json/)
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.message).toBe('Validation failed');
        expect(response.body.errors).toBeInstanceOf(Array);
        expect(response.body.errors.length).toBeGreaterThanOrEqual(2);
      });
    });

    describe('Edge Cases', () => {
      it('should handle empty strings', async () => {
        const emptyStrings = {
          email: '',
          password: ''
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(emptyStrings)
          .expect('Content-Type', /json/)
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.message).toBe('Validation failed');
      });

      it('should handle whitespace in email', async () => {
        const whitespaceEmail = {
          email: '  test@gmail.com  ',
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(whitespaceEmail)
          .expect('Content-Type', /json/);

        // The email validation might normalize the email or reject it
        expect([200, 400].includes(response.status)).toBe(true);
      });

      it('should handle case sensitivity in email', async () => {
        const uppercaseEmail = {
          email: 'TEST@GMAIL.COM',
          password: 'Test123123'
        };

        const response = await request(app)
          .post('/api/auth/test-login')
          .send(uppercaseEmail)
          .expect('Content-Type', /json/)
          .expect(200);

        expect(response.body.success).toBe(true);
      });
    });
  });

  describe('Authentication Endpoints (Database Required)', () => {
    it('should return appropriate error for register endpoint', async () => {
      const registerData = {
        email: 'newuser@gmail.com',
        password: 'Password123',
        first_name: 'John',
        last_name: 'Doe',
        user_type: 'CLIENTE'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(registerData)
        .expect('Content-Type', /json/);

      // Since database is not connected, this should fail
      expect(response.status).toBeGreaterThanOrEqual(400);
    });

    it('should return appropriate error for login endpoint', async () => {
      const loginData = {
        email: 'user@gmail.com',
        password: 'Password123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect('Content-Type', /json/);

      // Since database is not connected, this should fail
      expect(response.status).toBeGreaterThanOrEqual(400);
    });
  });
});
