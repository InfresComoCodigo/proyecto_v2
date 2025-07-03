# API Endpoints Documentation

## Autenticación

### Registro de Usuario
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "cliente@example.com",
  "password": "password123",
  "first_name": "Juan",
  "last_name": "Pérez",
  "phone": "+51999888777",
  "user_type": "CLIENTE"
}
```

### Inicio de Sesión
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "cliente@example.com",
  "password": "password123"
}
```

### Renovar Token
```http
POST /api/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "your_refresh_token_here"
}
```

### Obtener Perfil
```http
GET /api/auth/profile
Authorization: Bearer your_jwt_token_here
```

## Paquetes y Servicios

### Obtener Categorías de Servicios
```http
GET /api/packages/categories
Authorization: Bearer your_jwt_token_here
```

### Obtener Todos los Servicios
```http
GET /api/packages/services
Authorization: Bearer your_jwt_token_here
```

### Obtener Servicios por Categoría
```http
GET /api/packages/categories/1/services
Authorization: Bearer your_jwt_token_here
```

### Obtener Todos los Paquetes
```http
GET /api/packages/packages
Authorization: Bearer your_jwt_token_here
```

### Obtener Paquete por ID
```http
GET /api/packages/packages/1
Authorization: Bearer your_jwt_token_here
```

### Crear Nuevo Servicio (Admin/Staff)
```http
POST /api/packages/services
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "category_id": 1,
  "name": "Nuevo Servicio de Aventura",
  "description": "Descripción del servicio",
  "base_price": 150.00,
  "duration_hours": 6,
  "max_capacity": 20,
  "requirements": "Requisitos especiales"
}
```

### Crear Nuevo Paquete (Admin/Staff)
```http
POST /api/packages/packages
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "packageData": {
    "name": "Paquete Aventura Premium",
    "description": "Paquete completo de aventura",
    "total_price": 500.00,
    "discount_percentage": 15.00,
    "duration_hours": 48,
    "max_capacity": 15
  },
  "services": [
    {
      "service_id": 1,
      "quantity": 1,
      "custom_price": 150.00
    },
    {
      "service_id": 3,
      "quantity": 1,
      "custom_price": 80.00
    }
  ]
}
```

### Buscar Paquetes y Servicios
```http
GET /api/packages/search?q=rafting
Authorization: Bearer your_jwt_token_here
```

## Cotizaciones

### Obtener Todas las Cotizaciones
```http
GET /api/quotations?page=1&limit=10&status=SENT
Authorization: Bearer your_jwt_token_here
```

### Obtener Cotización por ID
```http
GET /api/quotations/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer your_jwt_token_here
```

### Crear Nueva Cotización
```http
POST /api/quotations
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "client_id": "550e8400-e29b-41d4-a716-446655440002",
  "event_type": "Evento Corporativo",
  "event_date": "2024-12-25",
  "estimated_guests": 25,
  "items": [
    {
      "item_type": "SERVICE",
      "item_id": 1,
      "quantity": 1
    },
    {
      "item_type": "PACKAGE",
      "item_id": 1,
      "quantity": 1
    }
  ],
  "discount_amount": 50.00,
  "notes": "Evento especial de fin de año"
}
```

### Actualizar Estado de Cotización (Admin/Staff)
```http
PATCH /api/quotations/550e8400-e29b-41d4-a716-446655440000/status
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "status": "SENT"
}
```

### Enviar Cotización (Admin/Staff)
```http
POST /api/quotations/550e8400-e29b-41d4-a716-446655440000/send
Authorization: Bearer your_jwt_token_here
```

### Aprobar Cotización (Cliente)
```http
POST /api/quotations/550e8400-e29b-41d4-a716-446655440000/approve
Authorization: Bearer your_jwt_token_here
```

### Rechazar Cotización (Cliente)
```http
POST /api/quotations/550e8400-e29b-41d4-a716-446655440000/reject
Authorization: Bearer your_jwt_token_here
```

### Obtener Cotizaciones de Cliente
```http
GET /api/quotations/client/550e8400-e29b-41d4-a716-446655440002
Authorization: Bearer your_jwt_token_here
```

## Usuarios

### Actualizar Perfil
```http
PUT /api/users/profile
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "first_name": "Juan Carlos",
  "last_name": "Pérez García",
  "phone": "+51999888777",
  "address": "Av. Principal 123, Cusco",
  "emergency_contact": "María Pérez",
  "emergency_phone": "+51999888778"
}
```

### Buscar Usuarios (Admin/Staff)
```http
GET /api/users/search?q=juan&type=CLIENTE
Authorization: Bearer your_jwt_token_here
```

## Administración

### Obtener Todos los Usuarios (Admin)
```http
GET /api/admin/users?page=1&limit=10&userType=CLIENTE
Authorization: Bearer your_jwt_token_here
```

### Desactivar Usuario (Admin)
```http
PATCH /api/admin/users/550e8400-e29b-41d4-a716-446655440002/deactivate
Authorization: Bearer your_jwt_token_here
```

### Activar Usuario (Admin)
```http
PATCH /api/admin/users/550e8400-e29b-41d4-a716-446655440002/activate
Authorization: Bearer your_jwt_token_here
```

### Asignar Rol a Usuario (Admin)
```http
POST /api/admin/users/550e8400-e29b-41d4-a716-446655440001/roles
Authorization: Bearer your_jwt_token_here
Content-Type: application/json

{
  "roleId": 2
}
```

### Remover Rol de Usuario (Admin)
```http
DELETE /api/admin/users/550e8400-e29b-41d4-a716-446655440001/roles/2
Authorization: Bearer your_jwt_token_here
```

## Personal

### Dashboard del Personal (Staff)
```http
GET /api/staff/dashboard
Authorization: Bearer your_jwt_token_here
```

### Tareas del Personal (Staff)
```http
GET /api/staff/tasks
Authorization: Bearer your_jwt_token_here
```

## Códigos de Estado HTTP

- `200` - OK: Solicitud exitosa
- `201` - Created: Recurso creado exitosamente
- `400` - Bad Request: Error en los datos enviados
- `401` - Unauthorized: Token faltante o inválido
- `403` - Forbidden: Sin permisos suficientes
- `404` - Not Found: Recurso no encontrado
- `409` - Conflict: Conflicto (ej: usuario ya existe)
- `500` - Internal Server Error: Error del servidor

## Estructura de Respuesta

### Respuesta Exitosa
```json
{
  "success": true,
  "message": "Operación exitosa",
  "data": {
    // Datos de respuesta
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Respuesta con Paginación
```json
{
  "success": true,
  "message": "Datos obtenidos exitosamente",
  "data": [
    // Array de datos
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "pages": 3
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Respuesta de Error
```json
{
  "success": false,
  "message": "Descripción del error",
  "error": "Detalles técnicos del error (solo en desarrollo)",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Tipos de Usuario

- **CLIENTE**: Usuarios finales que solicitan servicios
- **PERSONAL**: Staff operativo que maneja cotizaciones y servicios
- **ADMINISTRADOR**: Administradores con acceso completo al sistema

## Autenticación

El sistema utiliza JWT (JSON Web Tokens) para la autenticación. Todos los endpoints (excepto registro y login) requieren un token válido en el header:

```
Authorization: Bearer your_jwt_token_here
```

Los tokens expiran en 24 horas por defecto, pero se puede usar el refresh token para obtener un nuevo token sin necesidad de hacer login nuevamente.
