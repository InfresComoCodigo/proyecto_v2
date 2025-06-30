const request = require('supertest');
const app = require('./index');

// Mockear la base de datos antes de importar la aplicación
jest.mock('./config/database', () => ({
    executeQuery: jest.fn(),
    testConnection: jest.fn().mockResolvedValue(true),
    getConnection: jest.fn()
}));

const { executeQuery } = require('./config/database');

describe('Backend API Tests - Patrón Arrange, Act, Assert', () => {
    
    // Limpiar mocks antes de cada test
    beforeEach(() => {
        jest.clearAllMocks();
    });
    
    // TEST 1: Health Check Endpoint
    describe('GET /health', () => {
        test('should return correct health status with proper structure', async () => {
            // ARRANGE: Preparar los datos esperados
            const expectedStatus = 'OK';
            const expectedMessage = 'Backend de reservas funcionando correctamente';
            
            // ACT: Ejecutar la acción que queremos probar
            const response = await request(app)
                .get('/health')
                .expect(200);
            
            // ASSERT: Verificar que el resultado es el esperado
            expect(response.body.status).toBe(expectedStatus);
            expect(response.body.message).toBe(expectedMessage);
            expect(response.body).toHaveProperty('timestamp');
            expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
        });
    });

    // TEST 2: Registro de Usuario con Validación de Email
    describe('POST /api/auth/register', () => {
        test('should reject registration with invalid email format', async () => {
            // ARRANGE: Preparar datos de entrada inválidos
            const invalidUserData = {
                email: 'invalid-email-format',
                password: 'ValidPassword123',
                firstName: 'Juan',
                lastName: 'Pérez'
            };
            const expectedStatusCode = 400;
            
            // ACT: Intentar registrar usuario con email inválido
            const response = await request(app)
                .post('/api/auth/register')
                .send(invalidUserData)
                .expect(expectedStatusCode);
            
            // ASSERT: Verificar que se rechaza correctamente
            expect(response.body).toHaveProperty('error');
            expect(response.body.message).toContain('email válido');
            expect(response.status).toBe(expectedStatusCode);
        });
    });

    // TEST 3: Login con Campos Requeridos
    describe('POST /api/auth/login', () => {
        test('should validate required fields for login', async () => {
            // ARRANGE: Preparar datos vacíos para probar validación
            const emptyLoginData = {};
            const expectedStatusCode = 400;
            
            // ACT: Intentar hacer login sin datos
            const response = await request(app)
                .post('/api/auth/login')
                .send(emptyLoginData)
                .expect(expectedStatusCode);
            
            // ASSERT: Verificar que se requieren los campos obligatorios
            expect(response.body).toHaveProperty('error');
            expect(response.status).toBe(expectedStatusCode);
        });
    });

    // TEST 4: Obtener Lista de Paquetes con Paginación
    describe('GET /api/packages', () => {
        test('should return packages with proper pagination structure', async () => {
            // ARRANGE: Preparar parámetros de paginación y mock de datos
            const pageNumber = 1;
            const limitNumber = 5;
            const queryParams = `?page=${pageNumber}&limit=${limitNumber}`;
            const expectedStatusCode = 200;
            
            // Mock de datos de paquetes
            const mockPackages = [
                {
                    id: 1,
                    name: 'Paquete Lima',
                    price: 150.00,
                    destination: 'Lima',
                    category: 'Turismo'
                },
                {
                    id: 2,
                    name: 'Paquete Cusco',
                    price: 250.00,
                    destination: 'Cusco',
                    category: 'Aventura'
                }
            ];
            
            const mockCountResult = [{ total: 10 }];
            
            // Configurar mocks para las consultas de base de datos
            executeQuery
                .mockResolvedValueOnce(mockPackages) // Primera llamada para obtener paquetes
                .mockResolvedValueOnce(mockCountResult); // Segunda llamada para contar total
            
            // ACT: Solicitar paquetes con paginación
            const response = await request(app)
                .get(`/api/packages${queryParams}`)
                .expect(expectedStatusCode);
            
            // ASSERT: Verificar estructura de respuesta y paginación
            expect(response.body).toHaveProperty('packages');
            expect(response.body).toHaveProperty('pagination');
            expect(Array.isArray(response.body.packages)).toBe(true);
            expect(response.body.pagination.page).toBe(pageNumber);
            expect(response.body.pagination.limit).toBe(limitNumber);
            expect(response.body.pagination.total).toBe(10);
            expect(response.status).toBe(expectedStatusCode);
        });
    });

    // TEST 5: Manejo de Rutas No Existentes (404)
    describe('404 Error Handler', () => {
        test('should return proper 404 error for non-existent routes', async () => {
            // ARRANGE: Preparar una ruta que no existe
            const nonExistentRoute = '/api/esta-ruta-no-existe';
            const expectedStatusCode = 404;
            const expectedErrorMessage = 'Ruta no encontrada';
            
            // ACT: Intentar acceder a una ruta inexistente
            const response = await request(app)
                .get(nonExistentRoute)
                .expect(expectedStatusCode);
            
            // ASSERT: Verificar que se maneja correctamente el error 404
            expect(response.body.error).toBe(expectedErrorMessage);
            expect(response.body.message).toContain(nonExistentRoute);
            expect(response.status).toBe(expectedStatusCode);
        });
    });
});
