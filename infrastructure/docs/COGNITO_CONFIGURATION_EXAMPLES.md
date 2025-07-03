# Configuraciones de Ejemplo para Cognito

Este archivo muestra diferentes configuraciones según tu caso de uso.

## Configuración 1: Solo API Gateway (Sin UI Hospedada)

**Caso de uso**: Aplicación con su propia interfaz de login que usa Cognito programáticamente.

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "dev"
  
  # Configuración básica para API Gateway únicamente
  # No configurar OAuth flows para evitar el error
  allowed_oauth_flows = []  # VACÍO - muy importante
  allowed_oauth_scopes = [] # VACÍO - muy importante
  callback_urls = []        # VACÍO - no se usa
  logout_urls = []          # VACÍO - no se usa
  
  # Configuración de autenticación programática
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",  # Para login con username/password
    "ALLOW_REFRESH_TOKEN_AUTH",  # Para renovar tokens
    "ALLOW_USER_SRP_AUTH"        # Para login seguro (recomendado)
  ]
  
  tags = {
    Project = "mi-proyecto"
  }
}
```

**Uso en frontend**:
```javascript
// Login programático sin OAuth
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const userPool = new CognitoUserPool({
    UserPoolId: 'us-east-1_xxxxxxx',
    ClientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxx'
});

// No se usa OAuth, se autentica directamente
const cognitoUser = new CognitoUser({
    Username: 'usuario@email.com',
    Pool: userPool
});

const authDetails = new AuthenticationDetails({
    Username: 'usuario@email.com',
    Password: 'miPassword123!'
});

cognitoUser.authenticateUser(authDetails, {
    onSuccess: (result) => {
        const token = result.getAccessToken().getJwtToken();
        // Usar token en API Gateway
    }
});
```

## Configuración 2: Con UI Hospedada de Cognito

**Caso de uso**: Quieres usar la interfaz de login que proporciona Cognito (hosted UI).

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "staging"
  
  # Configuración para UI hospedada
  allowed_oauth_flows = ["code"]  # Habilitar OAuth
  allowed_oauth_scopes = ["email", "openid", "profile"]
  
  # URLs donde redirigir después del login/logout
  callback_urls = [
    "https://mi-app.com/callback",
    "http://localhost:3000/callback"
  ]
  logout_urls = [
    "https://mi-app.com/logout", 
    "http://localhost:3000/logout"
  ]
  
  tags = {
    Project = "mi-proyecto"
  }
}
```

**Uso en frontend**:
```javascript
// Con OAuth y UI hospedada
import { Amplify, Auth } from 'aws-amplify';

Amplify.configure({
    Auth: {
        region: 'us-east-1',
        userPoolId: 'us-east-1_xxxxxxx',
        userPoolWebClientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxx',
        oauth: {
            domain: 'mi-proyecto-staging-auth-abcdef.auth.us-east-1.amazoncognito.com',
            scope: ['email', 'openid', 'profile'],
            redirectSignIn: 'https://mi-app.com/callback',
            redirectSignOut: 'https://mi-app.com/logout',
            responseType: 'code'
        }
    }
});

// Redirigir a la UI hospedada
Auth.federatedSignIn();
```

## Configuración 3: Aplicación Móvil

**Caso de uso**: Aplicación móvil que necesita autenticación.

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-app-movil"
  environment  = "prod"
  
  # Sin OAuth para aplicaciones móviles nativas
  allowed_oauth_flows = []
  allowed_oauth_scopes = []
  callback_urls = []
  logout_urls = []
  
  # Configuración específica para móviles
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",      # Protocolo seguro
    "ALLOW_REFRESH_TOKEN_AUTH"  # Para renovar tokens
  ]
  
  # Configuración de tokens más larga para móviles
  access_token_validity = 24   # 24 horas
  refresh_token_validity = 30  # 30 días
  
  tags = {
    Project = "mi-app-movil"
  }
}
```

## Configuración 4: Aplicación Híbrida

**Caso de uso**: Aplicación que soporta tanto login programático como UI hospedada.

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-app-hibrida"
  environment  = "prod"
  
  # Habilitar OAuth para UI hospedada
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  
  callback_urls = ["https://mi-app.com/callback"]
  logout_urls = ["https://mi-app.com/logout"]
  
  # También permitir autenticación programática
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  
  # Crear cliente adicional para aplicaciones web
  create_web_client = true
  web_callback_urls = ["https://admin.mi-app.com/callback"]
  
  tags = {
    Project = "mi-app-hibrida"
  }
}
```

## Configuración Actual del Proyecto

En tu configuración actual (`locals.tf`), está configurado para **Caso de Uso 1** (Solo API Gateway):

```hcl
# En locals.tf
enable_oauth_flows = false  # Deshabilitado
```

Esto significa:
- ✅ No hay OAuth flows configurados (evita el error)
- ✅ Perfecto para autenticación programática
- ✅ Tokens JWT para usar en API Gateway
- ❌ No se puede usar UI hospedada de Cognito

## Cambiar a UI Hospedada

Si quieres usar la UI hospedada de Cognito, cambia en `locals.tf`:

```hcl
# Para habilitar UI hospedada
enable_oauth_flows = true  # Cambiar a true
```

Y configura las URLs apropiadas en el módulo auth en `main.tf`.

## Resumen de Opciones

| Configuración | OAuth Flows | Callback URLs | Uso Principal |
|---------------|-------------|---------------|---------------|
| Solo API Gateway | `[]` (vacío) | `[]` (vacío) | Apps con UI propia |
| UI Hospedada | `["code"]` | URLs reales | Apps que usan Cognito UI |
| Móvil Nativo | `[]` (vacío) | `[]` (vacío) | Apps móviles |
| Híbrida | `["code", "implicit"]` | URLs reales | Apps web complejas |

La configuración actual evitará el error OAuth que estabas experimentando.
