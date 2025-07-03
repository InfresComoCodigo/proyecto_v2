# Módulo de Autenticación con Amazon Cognito

Este módulo de Terraform crea y configura Amazon Cognito User Pool e Identity Pool para proporcionar autenticación y autorización a tu API Gateway.

## Características

- **User Pool de Cognito**: Gestión de usuarios con configuración de contraseñas personalizable
- **User Pool Domain**: Dominio hospedado para la UI de autenticación
- **User Pool Clients**: Configuración para API Gateway y aplicaciones web/móviles
- **Identity Pool** (opcional): Para acceso directo a recursos AWS
- **Roles IAM**: Para usuarios autenticados y no autenticados
- **Integración con API Gateway**: Configuración lista para usar como authorizer

## Uso

### Configuración Básica (Solo API Gateway - Sin UI Hospedada)

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "dev"
  
  # Configuración de contraseñas
  password_minimum_length    = 8
  password_require_lowercase = true
  password_require_numbers   = true
  password_require_symbols   = false
  password_require_uppercase = true
  
  # NO configurar OAuth flows para uso solo con API Gateway
  allowed_oauth_flows = []  # IMPORTANTE: Dejar vacío
  allowed_oauth_scopes = [] # IMPORTANTE: Dejar vacío
  callback_urls = []        # IMPORTANTE: Dejar vacío
  logout_urls = []          # IMPORTANTE: Dejar vacío
  
  tags = {
    Project = "mi-proyecto"
    Team    = "desarrollo"
  }
}
```

### Con UI Hospedada de Cognito

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "dev"
  
  # Habilitar OAuth para UI hospedada
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  
  # URLs para OAuth
  callback_urls = ["https://miapp.com/callback"]
  logout_urls   = ["https://miapp.com/logout"]
  
  tags = {
    Project = "mi-proyecto"
  }
}
```

### Con Identity Pool

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "dev"
  
  # Habilitar Identity Pool
  create_identity_pool             = true
  allow_unauthenticated_identities = false
  
  tags = {
    Project = "mi-proyecto"
  }
}
```

### Con MFA Habilitado

```hcl
module "auth" {
  source = "./modules/auth"

  project_name = "mi-proyecto"
  environment  = "dev"
  
  # Habilitar MFA
  enable_mfa = true
  
  # Configuración de dispositivos
  challenge_required_on_new_device      = true
  device_only_remembered_on_user_prompt = true
  
  tags = {
    Project = "mi-proyecto"
  }
}
```

## Integración con API Gateway

Para usar este módulo con API Gateway, necesitas crear un authorizer:

```hcl
# En tu configuración de API Gateway
resource "aws_api_gateway_authorizer" "cognito" {
  name                   = "cognito-authorizer"
  rest_api_id           = aws_api_gateway_rest_api.main.id
  type                  = "COGNITO_USER_POOLS"
  authorizer_uri        = module.auth.authorizer_invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  provider_arns         = [module.auth.user_pool_arn]
}

# Usar el authorizer en métodos
resource "aws_api_gateway_method" "protected" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Nombre del proyecto | `string` | n/a | yes |
| environment | Ambiente (dev, staging, prod) | `string` | n/a | yes |
| password_minimum_length | Longitud mínima de la contraseña | `number` | `8` | no |
| password_require_lowercase | Requerir letras minúsculas | `bool` | `true` | no |
| password_require_numbers | Requerir números | `bool` | `true` | no |
| password_require_symbols | Requerir símbolos | `bool` | `true` | no |
| password_require_uppercase | Requerir letras mayúsculas | `bool` | `true` | no |
| enable_mfa | Habilitar MFA | `bool` | `false` | no |
| create_web_client | Crear cliente web | `bool` | `true` | no |
| create_identity_pool | Crear Identity Pool | `bool` | `false` | no |
| callback_urls | URLs de callback OAuth | `list(string)` | `[]` | no |
| logout_urls | URLs de logout OAuth | `list(string)` | `[]` | no |
| tags | Tags comunes | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| user_pool_id | ID del User Pool |
| user_pool_arn | ARN del User Pool |
| user_pool_domain | Dominio del User Pool |
| api_client_id | ID del cliente API |
| web_client_id | ID del cliente web |
| identity_pool_id | ID del Identity Pool |
| login_url | URL de login |
| logout_url | URL de logout |
| token_endpoint | Endpoint de tokens |

## Flujo de Autenticación

1. **Registro**: Los usuarios se registran a través de la UI hospedada o tu aplicación
2. **Verificación**: Email de verificación automático
3. **Login**: Autenticación a través de username/email y password
4. **Tokens**: Cognito devuelve access_token, id_token y refresh_token
5. **API Access**: Usar el access_token en el header Authorization para acceder a la API
6. **Refresh**: Usar refresh_token para obtener nuevos tokens cuando expiren

## Configuración de la Aplicación Cliente

### JavaScript/Node.js

```javascript
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';

const poolData = {
    UserPoolId: 'USER_POOL_ID', // Desde module.auth.user_pool_id
    ClientId: 'CLIENT_ID'       // Desde module.auth.api_client_id
};

const userPool = new CognitoUserPool(poolData);

// Login
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
        // Usar accessToken en requests a API Gateway
    },
    onFailure: function(err) {
        console.error(err);
    }
});
```

### Python/Boto3

```python
import boto3

client = boto3.client('cognito-idp', region_name='us-east-1')

response = client.admin_initiate_auth(
    UserPoolId='USER_POOL_ID',
    ClientId='CLIENT_ID',
    AuthFlow='ADMIN_NO_SRP_AUTH',
    AuthParameters={
        'USERNAME': username,
        'PASSWORD': password
    }
)

access_token = response['AuthenticationResult']['AccessToken']

# Usar en requests
headers = {
    'Authorization': f'Bearer {access_token}'
}
```

## Seguridad

- Las contraseñas se validan según las políticas configuradas
- Los tokens tienen tiempos de expiración configurables
- MFA opcional disponible
- Los secrets se marcan como sensibles en Terraform
- Roles IAM con permisos mínimos para Identity Pool

## Monitoreo

Cognito genera logs en CloudWatch automáticamente. Puedes monitorear:
- Intentos de login
- Registros de usuarios
- Errores de autenticación
- Uso de tokens

## Costos

- User Pool: Gratis hasta 50,000 MAU (Monthly Active Users)
- Identity Pool: Gratis
- Después del límite gratuito: $0.0055 por MAU adicional

## Troubleshooting

### Error: "email is not supported with client_credentials flow"
- **Causa**: Configuración OAuth incompatible con scopes de email
- **Solución**: Para uso solo con API Gateway, configurar:
  ```hcl
  allowed_oauth_flows = []
  allowed_oauth_scopes = []
  callback_urls = []
  logout_urls = []
  ```

### Error: "User does not exist"
- Verificar que el usuario esté confirmado
- Verificar que el email esté verificado

### Error: "Invalid client"
- Verificar Client ID
- Verificar que el cliente tenga los flujos de auth correctos

### Error: "Access Token has expired"
- Implementar refresh token logic
- Verificar configuración de tiempo de vida de tokens
