# REST Authentication Patterns for Drupal 11

## Cookie Authentication with CSRF Tokens

Cookie auth is the default for browser-based clients. Drupal requires a CSRF token for mutating requests (POST, PATCH, DELETE).

Step 1: Log in and obtain a session cookie:

```
POST /user/login?_format=json
Content-Type: application/json

{
  "name": "admin",
  "pass": "password"
}
```

Response sets a session cookie and returns CSRF token info. Step 2: Get a CSRF token:

```
GET /session/token
Cookie: SESS...=abc123
```

Returns a plain-text token. Step 3: Use the token in mutating requests:

```
PATCH /jsonapi/node/article/{uuid}
Content-Type: application/vnd.api+json
Cookie: SESS...=abc123
X-CSRF-Token: <token-from-step-2>

{ "data": { "type": "node--article", "id": "...", "attributes": { "title": "Updated" } } }
```

For JSON:API, the CSRF token header is `X-CSRF-Token`. For core REST, it is also `X-CSRF-Token`.

Enable cookie auth on REST resources at `/admin/config/services/rest` or in `rest.resource.*.yml`:

```yaml
# config/install/rest.resource.entity.node.yml
id: entity.node
granularity: method
configuration:
  GET:
    supported_formats: [json]
    supported_auth: [cookie]
  POST:
    supported_formats: [json]
    supported_auth: [cookie]
```

## Basic Auth Setup

Install the `basic_auth` core module:

```
drush en basic_auth
```

Send credentials with each request via the `Authorization` header:

```
GET /jsonapi/node/article
Authorization: Basic base64(username:password)
```

Enable on REST resources:

```yaml
configuration:
  GET:
    supported_formats: [json]
    supported_auth: [basic_auth, cookie]
```

Basic auth works with JSON:API out of the box once the module is enabled. No additional configuration needed for JSON:API endpoints.

**Security note**: Only use basic auth over HTTPS. Credentials are base64-encoded, not encrypted.

## OAuth 2.0 with Simple OAuth

Install and configure:

```
composer require drupal/simple_oauth
drush en simple_oauth
```

Generate keys:

```
# Generate RSA keys for token signing
openssl genrsa -out /path/to/private.key 2048
openssl rsa -in /path/to/private.key -pubout -o /path/to/public.key
chmod 600 /path/to/private.key
chmod 644 /path/to/public.key
```

Configure key paths at `/admin/config/people/simple_oauth`.

Create a consumer (OAuth client) at `/admin/config/services/consumer/add`:

- Label: My App
- Client ID: auto-generated or custom
- New Secret: a strong secret
- Scopes: assign Drupal roles
- Redirect URI: your app callback

### Authorization Code Grant

```
# Step 1: Redirect user to authorize
GET /oauth/authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=REDIRECT_URI&scope=authenticated

# Step 2: Exchange code for token
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=AUTH_CODE&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&redirect_uri=REDIRECT_URI
```

### Client Credentials Grant (machine-to-machine)

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&scope=authenticated
```

### Password Grant

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&username=USER&password=PASS&client_id=CLIENT_ID&client_secret=CLIENT_SECRET
```

### Using the Token

```
GET /jsonapi/node/article
Authorization: Bearer ACCESS_TOKEN
```

### Refreshing Tokens

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=REFRESH_TOKEN&client_id=CLIENT_ID&client_secret=CLIENT_SECRET
```

## JWT Authentication

Install the JWT module:

```
composer require drupal/jwt
drush en jwt jwt_auth_consumer jwt_auth_issuer
```

Configure at `/admin/config/system/jwt`. Set the algorithm (e.g., RS256) and key.

Use the `key` module to manage signing keys:

```
composer require drupal/key
drush en key
```

Create a key at `/admin/config/system/keys/add` (type: JWT RSA Key).

Obtaining a JWT:

```
GET /jwt/token
Authorization: Basic base64(username:password)
```

Response:

```json
{ "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..." }
```

Using the JWT:

```
GET /jsonapi/node/article
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Custom Authentication Provider

Create a custom auth provider by implementing `AuthenticationProviderInterface`:

```php
namespace Drupal\my_module\Authentication\Provider;

use Drupal\Core\Authentication\AuthenticationProviderInterface;
use Symfony\Component\HttpFoundation\Request;

class ApiKeyAuth implements AuthenticationProviderInterface {

  public function applies(Request $request): bool {
    return $request->headers->has('X-API-Key');
  }

  public function authenticate(Request $request): ?AccountInterface {
    $api_key = $request->headers->get('X-API-Key');
    // Look up the user associated with this API key.
    $uid = $this->lookupApiKey($api_key);
    if ($uid) {
      return User::load($uid);
    }
    throw new AccessDeniedHttpException('Invalid API key.');
  }

}
```

Register as a service with the `authentication_provider` tag:

```yaml
# my_module.services.yml
services:
  my_module.authentication.api_key:
    class: Drupal\my_module\Authentication\Provider\ApiKeyAuth
    tags:
      - { name: authentication_provider, provider_id: api_key, priority: 100 }
```

Enable on REST resources:

```yaml
configuration:
  GET:
    supported_auth: [api_key, cookie]
```

### Authentication Priority

When multiple auth providers apply to a request, the one with the highest priority wins. Core defaults:

- `cookie`: priority 0
- `basic_auth`: priority 100

Set your custom provider's priority in the service tag to control precedence.
