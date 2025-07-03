# Guía de Integración: Amazon Cognito + API Gateway

Esta guía explica cómo usar la autenticación con Amazon Cognito integrada al API Gateway en tu infraestructura.

## Descripción de la Implementación

La infraestructura incluye:

- **Amazon Cognito User Pool**: Gestión de usuarios y autenticación
- **Cognito User Pool Domain**: UI hospedada para login/registro
- **Cognito User Pool Client**: Configurado para API Gateway
- **API Gateway Authorizer**: Valida tokens de Cognito
- **Endpoints Protegidos y Públicos**: Diferentes niveles de acceso

## Configuración por Ambiente

### Desarrollo (`dev`)
- **Autenticación**: Deshabilitada por defecto
- **Endpoints públicos**: Habilitados
- **Contraseñas**: Requisitos relajados (mínimo 6 caracteres)
- **Tokens**: Validez corta (1 hora)

### Staging (`staging`) 
- **Autenticación**: Habilitada
- **Endpoints públicos**: Habilitados 
- **Contraseñas**: Requisitos estándar (8 caracteres, símbolos)
- **Tokens**: Validez media (12 horas access, 7 días refresh)

### Producción (`prod`)
- **Autenticación**: Habilitada obligatoriamente
- **Endpoints públicos**: Deshabilitados
- **MFA**: Habilitado automáticamente
- **Contraseñas**: Requisitos estrictos (12 caracteres)
- **Tokens**: Validez estándar (24 horas access, 30 días refresh)

## Estructura de Endpoints

### Endpoints Protegidos (Requieren Autenticación)
```
{API_GATEWAY_URL}/api/*
```
- Requieren header `Authorization: Bearer <access_token>`
- Validados por Cognito Authorizer
- Acceso a todas las funcionalidades de la aplicación

### Endpoints Públicos (Sin Autenticación)
```
{API_GATEWAY_URL}/api/public/*
```
- No requieren autenticación
- Útiles para: health checks, información pública, registro inicial
- Solo disponibles en dev/staging por defecto

## Flujo de Autenticación

### 1. Registro de Usuario

#### Opción A: UI Hospedada de Cognito
```bash
# URL proporcionada en los outputs
https://{domain}.auth.{region}.amazoncognito.com/signup?client_id={client_id}&response_type=code&scope=email+openid+profile&redirect_uri={callback_url}
```

#### Opción B: API Directa
```javascript
import { CognitoUserPool } from 'amazon-cognito-identity-js';

const userPool = new CognitoUserPool({
    UserPoolId: '{USER_POOL_ID}',
    ClientId: '{CLIENT_ID}'
});

userPool.signUp(username, password, attributeList, null, callback);
```

### 2. Verificación de Email
- Cognito envía automáticamente un código de verificación
- El usuario debe confirmar su email antes del primer login

### 3. Login

#### Opción A: UI Hospedada
```bash
# URL de login proporcionada en outputs
https://{domain}.auth.{region}.amazoncognito.com/login?client_id={client_id}&response_type=code&scope=email+openid+profile&redirect_uri={callback_url}
```

#### Opción B: Programático
```javascript
import { CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const authenticationDetails = new AuthenticationDetails({
    Username: username,
    Password: password,
});

const cognitoUser = new CognitoUser({
    Username: username,
    Pool: userPool
});

cognitoUser.authenticateUser(authenticationDetails, {
    onSuccess: function (result) {
        const accessToken = result.getAccessToken().getJwtToken();
        const idToken = result.getIdToken().getJwtToken();
        const refreshToken = result.getRefreshToken().getToken();
        
        // Usar accessToken para llamadas a la API
    },
    onFailure: function(err) {
        console.error(err);
    }
});
```

### 4. Usar la API
```javascript
// Hacer llamadas autenticadas
fetch('{API_GATEWAY_URL}/api/protected-endpoint', {
    method: 'GET',
    headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
    }
})
.then(response => response.json())
.then(data => console.log(data));
```

## Ejemplos de Código

### Frontend - React con AWS Amplify
```javascript
import { Amplify, Auth } from 'aws-amplify';

// Configuración
Amplify.configure({
    Auth: {
        region: '{AWS_REGION}',
        userPoolId: '{USER_POOL_ID}',
        userPoolWebClientId: '{WEB_CLIENT_ID}',
        oauth: {
            domain: '{COGNITO_DOMAIN}',
            scope: ['email', 'openid', 'profile'],
            redirectSignIn: '{CALLBACK_URL}',
            redirectSignOut: '{LOGOUT_URL}',
            responseType: 'code'
        }
    }
});

// Login
async function signIn(username, password) {
    try {
        const user = await Auth.signIn(username, password);
        const session = await Auth.currentSession();
        const token = session.getAccessToken().getJwtToken();
        return token;
    } catch (error) {
        console.error('Error signing in', error);
    }
}

// Llamada a API protegida
async function callProtectedAPI() {
    try {
        const session = await Auth.currentSession();
        const token = session.getAccessToken().getJwtToken();
        
        const response = await fetch('{API_GATEWAY_URL}/api/data', {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        return await response.json();
    } catch (error) {
        console.error('Error calling API', error);
    }
}
```

### Backend - Node.js con verificación de token
```javascript
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
    jwksUri: `https://cognito-idp.{region}.amazonaws.com/{userPoolId}/.well-known/jwks.json`
});

function getKey(header, callback) {
    client.getSigningKey(header.kid, (err, key) => {
        const signingKey = key.publicKey || key.rsaPublicKey;
        callback(null, signingKey);
    });
}

function verifyToken(token) {
    return new Promise((resolve, reject) => {
        jwt.verify(token, getKey, {
            audience: '{CLIENT_ID}',
            issuer: `https://cognito-idp.{region}.amazonaws.com/{userPoolId}`,
            algorithms: ['RS256']
        }, (err, decoded) => {
            if (err) {
                reject(err);
            } else {
                resolve(decoded);
            }
        });
    });
}

// Middleware para Express
async function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.sendStatus(401);
    }
    
    try {
        const decoded = await verifyToken(token);
        req.user = decoded;
        next();
    } catch (error) {
        return res.sendStatus(403);
    }
}
```

### Python - Flask con validación de token
```python
import jwt
import requests
from functools import wraps
from flask import request, jsonify

COGNITO_REGION = '{region}'
USER_POOL_ID = '{userPoolId}'
CLIENT_ID = '{clientId}'

def get_jwks():
    url = f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json'
    response = requests.get(url)
    return response.json()

def verify_token(token):
    try:
        # Obtener las claves públicas
        jwks = get_jwks()
        
        # Decodificar el header del token
        header = jwt.get_unverified_header(token)
        
        # Encontrar la clave correspondiente
        key = None
        for jwk in jwks['keys']:
            if jwk['kid'] == header['kid']:
                key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
                break
        
        if not key:
            raise Exception('Public key not found')
        
        # Verificar el token
        decoded = jwt.decode(
            token,
            key,
            algorithms=['RS256'],
            audience=CLIENT_ID,
            issuer=f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USER_POOL_ID}'
        )
        
        return decoded
    except Exception as e:
        raise Exception(f'Token verification failed: {str(e)}')

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'Authorization header missing'}), 401
        
        try:
            token = auth_header.split(' ')[1]
            decoded_token = verify_token(token)
            request.user = decoded_token
            return f(*args, **kwargs)
        except Exception as e:
            return jsonify({'error': str(e)}), 403
    
    return decorated_function

# Uso en rutas
@app.route('/api/protected', methods=['GET'])
@require_auth
def protected_endpoint():
    return jsonify({
        'message': 'Hello authenticated user!',
        'user': request.user['cognito:username']
    })
```

## Configuración de CORS

Si tu frontend está en un dominio diferente, configura CORS en tu ALB/aplicación:

```javascript
// Headers requeridos en las respuestas de tu API
{
    'Access-Control-Allow-Origin': 'https://tu-frontend.com',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
}
```

## Monitoreo y Logs

### CloudWatch Logs
- **API Gateway**: Logs de requests y respuestas
- **Cognito**: Logs de autenticación y errores

### Métricas de CloudWatch
- Requests por segundo en API Gateway
- Errores de autenticación en Cognito
- Latencia de respuesta

### Ejemplo de consulta CloudWatch Insights
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

## Troubleshooting

### Error: "Unauthorized"
- Verificar que el token no haya expirado
- Confirmar que el header Authorization esté presente
- Validar formato: `Bearer <token>`

### Error: "Access Token has expired"
- Implementar refresh token logic
- Configurar tiempos de vida apropiados

### Error: "Invalid client"
- Verificar CLIENT_ID en la configuración
- Confirmar que el cliente tenga los flujos correctos

### Error: "User is not confirmed"
- El usuario debe verificar su email
- Usar `confirmSignUp` si es necesario

## Costos Estimados

### Cognito User Pool
- **Gratis**: Primeros 50,000 MAU
- **Después**: $0.0055 por MAU adicional

### API Gateway
- **Requests**: $3.50 por millón de requests
- **Data Transfer**: $0.09 por GB

### CloudWatch Logs
- **Ingestion**: $0.50 por GB
- **Storage**: $0.03 por GB por mes

## Próximos Pasos

1. **Desplegar la infraestructura** con `terraform apply`
2. **Configurar tu aplicación** con los outputs de Cognito
3. **Probar el flujo de autenticación** en desarrollo
4. **Configurar URLs de callback/logout** apropiadas
5. **Implementar manejo de refresh tokens**
6. **Configurar monitoreo y alertas**
