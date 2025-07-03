# Backend API - Sistema de Gestión de Eventos y Servicios

## 📋 Descripción
API REST desarrollada con Node.js, Express y TypeScript para la gestión de eventos y servicios. Actualmente configurada para funcionar sin base de datos para desarrollo y pruebas.

## 🚀 Inicio Rápido

### Prerrequisitos
- Node.js (versión 18 o superior)
- npm o yarn
- Git

### 1. Instalación de Dependencias

```bash
# Navegar al directorio del backend
cd applications/backend-api

# Instalar dependencias
npm install
```

### 2. Configuración del Entorno

```bash
# Crear archivo de variables de entorno (opcional)
cp .env.example .env
```

**Nota:** El servidor funciona sin configuración adicional usando valores por defecto.

### 3. Compilación del Proyecto

```bash
# Compilar TypeScript a JavaScript
npm run build
```

### 4. Iniciar el Servidor

#### Modo Desarrollo (con recarga automática)
```bash
npm run dev
```

#### Modo Producción
```bash
npm start
```

El servidor se iniciará en `http://localhost:3000`

## 🧪 Pruebas

### Ejecutar Todas las Pruebas
```bash
npm test
```

### Ejecutar Pruebas en Modo Watch
```bash
npm run test:watch
```

### Ejecutar Pruebas con Cobertura
```bash
npm run test:coverage
```

### 📋 Guía Paso a Paso para Ejecutar Pruebas

#### 1. Preparación del Entorno
```bash
# Asegúrate de estar en el directorio correcto
cd applications/backend-api

# Verifica que las dependencias estén instaladas
npm install

# Compila el proyecto
npm run build
```

#### 2. Ejecutar Pruebas Básicas
```bash
# Ejecutar todas las pruebas
npm test

# O ejecutar solo las pruebas simples
npm test simple.test.ts
```

#### 3. Ejecutar Pruebas con Detalles
```bash
# Ejecutar con información detallada
npm test -- --verbose

# Ejecutar pruebas específicas por nombre
npm test -- --testNamePattern="Hello World"
```

#### 4. Ejecutar Pruebas con Cobertura
```bash
# Generar reporte de cobertura
npm run test:coverage
```

El reporte se guardará en `coverage/` y mostrará:
- **Statements**: Porcentaje de líneas ejecutadas
- **Branches**: Porcentaje de ramas condicionales probadas
- **Functions**: Porcentaje de funciones llamadas
- **Lines**: Porcentaje de líneas de código cubiertas

#### 5. Ejecutar Pruebas en Modo Desarrollo
```bash
# Ejecutar en modo watch (se ejecutan automáticamente al cambiar archivos)
npm run test:watch
```

#### 6. Tipos de Pruebas Disponibles

##### Pruebas de Endpoints:
- ✅ `GET /` - Hello World
- ✅ `GET /health` - Health Check
- ✅ `POST /api/auth/test-login` - Login de prueba

##### Pruebas de Validación:
- ✅ Validación de email
- ✅ Validación de contraseña
- ✅ Manejo de errores

##### Pruebas de Middleware:
- ✅ Manejo de errores 404
- ✅ Headers de seguridad
- ✅ CORS
- ✅ Rate limiting

#### 7. Interpretando los Resultados

```bash
# Ejemplo de salida exitosa:
# ✅ PASS tests/simple.test.ts
# ✅ PASS tests/auth.test.ts  
# ✅ PASS tests/middleware.test.ts
# ✅ PASS tests/index.test.ts
#
# Test Suites: 4 passed, 4 total
# Tests:       39 passed, 39 total
# Snapshots:   0 total
# Time:        8.96 s
```

#### 8. Solución de Problemas en Pruebas

```bash
# Si las pruebas fallan, revisa:
# 1. Que el servidor no esté corriendo en puerto 3000
netstat -ano | findstr :3000

# 2. Limpia y reinstala dependencias
rm -rf node_modules package-lock.json
npm install

# 3. Recompila el proyecto
npm run build

# 4. Ejecuta las pruebas con más detalle
npm test -- --verbose --detectOpenHandles
```

## 📊 Verificación Manual de Endpoints

### 1. Health Check
```bash
curl http://localhost:3000/health
```
Respuesta esperada:
```json
{
  "status": "OK",
  "timestamp": "2025-07-02T15:00:00.000Z",
  "environment": "development"
}
```

### 2. Hello World
```bash
curl http://localhost:3000/
```
Respuesta esperada:
```json
{
  "message": "Hello World! Backend API is running! 🚀",
  "timestamp": "2025-07-02T15:00:00.000Z",
  "version": "1.0.0"
}
```

### 3. Test Login (Sin Base de Datos)
```bash
curl -X POST http://localhost:3000/api/auth/test-login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "password": "Test123123"
  }'
```

Respuesta esperada:
```json
{
  "success": true,
  "message": "Login successful (test mode)",
  "user": {
    "id": "test-user-123",
    "email": "test@gmail.com",
    "user_type": "CLIENTE",
    "first_name": "Test",
    "last_name": "User"
  },
  "token": "fake-jwt-token-for-testing",
  "timestamp": "2025-07-02T15:00:00.000Z"
}
```

## 🛠️ Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `npm run dev` | Inicia el servidor en modo desarrollo con recarga automática |
| `npm run build` | Compila TypeScript a JavaScript |
| `npm start` | Inicia el servidor en modo producción |
| `npm test` | Ejecuta las pruebas unitarias |
| `npm run test:watch` | Ejecuta las pruebas en modo observador |
| `npm run test:coverage` | Ejecuta las pruebas con reporte de cobertura |
| `npm run lint` | Ejecuta el linter |
| `npm run lint:fix` | Ejecuta el linter y corrige errores automáticamente |

## 🌐 Endpoints Disponibles

### Públicos
- `GET /` - Hello World
- `GET /health` - Health Check
- `POST /api/auth/test-login` - Login de prueba (sin BD)

### Autenticación
- `POST /api/auth/register` - Registrar usuario (requiere BD)
- `POST /api/auth/login` - Login de usuario (requiere BD)
- `POST /api/auth/refresh-token` - Renovar token (requiere BD)
- `GET /api/auth/profile` - Obtener perfil (requiere BD)
- `POST /api/auth/logout` - Logout (requiere BD)

### EC2 (AWS)
- `GET /api/ec2/*` - Endpoints de EC2

## 🗂️ Estructura del Proyecto

```
src/
├── config/
│   ├── database.ts      # Configuración de base de datos
│   └── socket.ts        # Configuración de Socket.IO
├── controllers/
│   └── auth.controller.ts
├── middleware/
│   ├── auth.ts          # Middleware de autenticación
│   ├── errorHandler.ts  # Manejo de errores
│   ├── logger.ts        # Logger de requests
│   └── notFound.ts      # Middleware 404
├── routes/
│   ├── auth.routes.ts   # Rutas de autenticación
│   └── ec2.routes.ts    # Rutas de EC2
├── services/            # Lógica de negocio (comentado)
├── types/               # Tipos TypeScript
├── utils/               # Utilidades
└── index.ts             # Punto de entrada

tests/                   # Pruebas unitarias
├── setup.ts            # Configuración de pruebas
├── simple.test.ts      # Pruebas básicas (ejemplo)
├── index.test.ts       # Pruebas principales de API
├── auth.test.ts        # Pruebas de autenticación
└── middleware.test.ts  # Pruebas de middleware

coverage/               # Reportes de cobertura (generado)
├── lcov-report/       # Reporte HTML
└── lcov.info          # Datos de cobertura
```

### 📝 Archivos de Pruebas

#### `tests/simple.test.ts` - Ejemplo básico
```typescript
import request from 'supertest';
import app from '../src/index';

test('GET / debe retornar mensaje de bienvenida', async () => {
  const response = await request(app).get('/');
  
  expect(response.status).toBe(200);
  expect(response.body.message).toBe('Hello World! Backend API is running! 🚀');
});
```

#### `tests/auth.test.ts` - Pruebas de autenticación
- Login exitoso
- Login fallido
- Validaciones de email
- Casos edge (espacios, mayúsculas)

#### `tests/middleware.test.ts` - Pruebas de middleware
- Manejo de errores 404
- Headers de seguridad
- CORS
- Parsing de JSON

#### `tests/index.test.ts` - Pruebas generales
- Health check
- Rate limiting
- Validación de requests

### 🔧 Configuración de Pruebas

#### `jest.config.js`
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: ['src/**/*.ts'],
  coverageDirectory: 'coverage',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
};
```

#### `tests/setup.ts`
```typescript
import 'dotenv/config';

// Configuración global para todas las pruebas
process.env.NODE_ENV = 'test';
process.env.PORT = '0';
```

## 🔧 Configuración

### Variables de Entorno (Opcionales)
```env
PORT=3000
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4200
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100

# Base de datos (actualmente deshabilitada)
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=IAC
```

## 🚨 Troubleshooting

### Error: Puerto 3000 en uso
```bash
# Windows
netstat -ano | findstr :3000
taskkill //PID <PID> //F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Error: Dependencias faltantes
```bash
rm -rf node_modules package-lock.json
npm install
```

### Error: Compilación TypeScript
```bash
npm run lint:fix
npm run build
```

## 🔄 Habilitando Base de Datos

Cuando quieras conectar la base de datos:

1. Descomenta en `src/index.ts`:
```typescript
import { connectDB } from './config/database';
// ...
await connectDB();
```

2. Descomenta las rutas necesarias en `src/index.ts`

3. Configura las variables de entorno de la base de datos

## 📝 Notas de Desarrollo

- El servidor está configurado para funcionar sin base de datos
- Las rutas de base de datos están comentadas para evitar errores
- Se incluye middleware de seguridad (helmet, CORS, rate limiting)
- Socket.IO está configurado pero no se usa actualmente
- Los logs de requests se muestran en consola

### 🧪 Creando Nuevas Pruebas

#### Ejemplo de nueva prueba:
```typescript
// tests/mi-nueva-funcionalidad.test.ts
import request from 'supertest';
import app from '../src/index';

describe('Mi Nueva Funcionalidad', () => {
  test('debe hacer algo específico', async () => {
    const response = await request(app)
      .get('/mi-endpoint')
      .expect(200);
    
    expect(response.body).toMatchObject({
      success: true,
      data: expect.any(Object)
    });
  });
});
```

#### Mejores Prácticas para Pruebas:
1. **Nombres descriptivos**: `debe retornar error cuando el email es inválido`
2. **Arrange-Act-Assert**: Preparar → Ejecutar → Verificar
3. **Un concepto por prueba**: Cada test debe probar una sola cosa
4. **Datos de prueba consistentes**: Usar los mismos datos de prueba
5. **Limpiar después**: No dejar efectos secundarios

#### Comandos Útiles para Testing:
```bash
# Ejecutar una prueba específica
npm test -- --testNamePattern="login"

# Ejecutar pruebas de un archivo específico
npm test auth.test.ts

# Ejecutar con información de debug
npm test -- --verbose --detectOpenHandles

# Generar reporte de cobertura y abrirlo
npm run test:coverage && start coverage/lcov-report/index.html
```

## 🤝 Contribución

1. Fork el proyecto
2. Crea una branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Push a la branch (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia ISC.

2. **Configurar variables de entorno:**
```bash
cp .env.example .env
# Editar .env con tus configuraciones
```

3. **Compilar TypeScript:**
```bash
npm run build
```

4. **Desarrollo:**
```bash
npm run dev
```

5. **Producción:**
```bash
npm start
```

## Endpoints Principales

### Autenticación
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/login` - Inicio de sesión
- `GET /api/auth/profile` - Perfil del usuario
- `POST /api/auth/refresh-token` - Renovar token

### Paquetes y Servicios
- `GET /api/packages/categories` - Categorías de servicios
- `GET /api/packages/services` - Todos los servicios
- `GET /api/packages/packages` - Todos los paquetes
- `POST /api/packages/services` - Crear servicio (Admin/Staff)
- `POST /api/packages/packages` - Crear paquete (Admin/Staff)

### Cotizaciones
- `GET /api/quotations` - Lista de cotizaciones
- `POST /api/quotations` - Crear cotización
- `PATCH /api/quotations/:id/status` - Actualizar estado
- `POST /api/quotations/:id/approve` - Aprobar cotización
- `POST /api/quotations/:id/reject` - Rechazar cotización

### Administración
- `GET /api/admin/users` - Gestionar usuarios
- `PATCH /api/admin/users/:id/activate` - Activar usuario
- `PATCH /api/admin/users/:id/deactivate` - Desactivar usuario
- `POST /api/admin/users/:id/roles` - Asignar rol

### Personal
- `GET /api/staff/dashboard` - Dashboard del personal
- `GET /api/staff/tasks` - Tareas asignadas

## Roles y Permisos

### CLIENTE
- Ver y gestionar sus propias cotizaciones
- Aprobar/rechazar cotizaciones
- Ver servicios y paquetes disponibles
- Actualizar su perfil

### PERSONAL
- Gestionar servicios y paquetes
- Crear y enviar cotizaciones
- Ver dashboard operativo
- Comunicación con clientes

### ADMINISTRADOR
- Acceso completo al sistema
- Gestión de usuarios y roles
- Configuración del sistema
- Reportes y analytics

## Comunicación en Tiempo Real

El sistema utiliza Socket.IO para:
- Notificaciones instantáneas
- Chat entre usuarios
- Actualizaciones de estado en tiempo real
- Alertas del sistema

## Base de Datos

El sistema se conecta a MySQL con las siguientes tablas principales:
- `user_profiles` - Perfiles de usuario
- `services` - Servicios disponibles
- `packages` - Paquetes de servicios
- `quotations` - Cotizaciones
- `reservations` - Reservas
- `payments` - Pagos
- `notifications` - Notificaciones

## Seguridad

- Autenticación JWT
- Validación de entrada con express-validator
- Rate limiting
- Helmet para headers de seguridad
- Roles y permisos granulares
- Logs de auditoría

## Variables de Entorno Requeridas

```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_NAME=IAC
DB_USER=your_db_user
DB_PASSWORD=your_db_password
JWT_SECRET=your_jwt_secret
COGNITO_USER_POOL_ID=your_pool_id
COGNITO_CLIENT_ID=your_client_id
```

## Comandos Disponibles

- `npm run dev` - Desarrollo con hot reload
- `npm run build` - Compilar TypeScript
- `npm start` - Ejecutar en producción
- `npm test` - Ejecutar tests
- `npm run lint` - Linter
- `npm run lint:fix` - Fix automático del linter

## Próximas Funcionalidades

- [ ] Completar módulo de reservas
- [ ] Integración completa de pagos
- [ ] Sistema de notificaciones por email
- [ ] Reportes y analytics
- [ ] API de archivos/documentos
- [ ] Integración completa con AWS Cognito
- [ ] Tests unitarios y de integración

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request
