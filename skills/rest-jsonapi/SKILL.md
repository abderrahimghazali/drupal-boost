---
name: rest-jsonapi
description: REST and JSON:API endpoint development in Drupal 11 including custom REST resources, JSON:API customization, authentication, input validation, and decoupled architecture patterns. Use when building APIs, decoupled frontends, or custom REST endpoints.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Drupal 11 REST & JSON:API Development

## JSON:API (Recommended for Entity CRUD)

JSON:API is enabled by default. Endpoints follow the pattern:

```
/jsonapi/{entity_type_id}/{bundle_id}
/jsonapi/{entity_type_id}/{bundle_id}/{uuid}
```

### Examples
```
GET    /jsonapi/node/article                    # List articles
GET    /jsonapi/node/article/{uuid}             # Get single article
POST   /jsonapi/node/article                    # Create article
PATCH  /jsonapi/node/article/{uuid}             # Update article
DELETE /jsonapi/node/article/{uuid}             # Delete article
```

### Filtering & Sorting
```
/jsonapi/node/article?filter[status]=1
/jsonapi/node/article?sort=-created
/jsonapi/node/article?include=uid,field_tags
/jsonapi/node/article?fields[node--article]=title,body
/jsonapi/node/article?page[limit]=10&page[offset]=0
```

### JSON:API Request Body (POST/PATCH)
```json
{
  "data": {
    "type": "node--article",
    "attributes": {
      "title": "My Article",
      "body": {
        "value": "<p>Content</p>",
        "format": "basic_html"
      }
    },
    "relationships": {
      "uid": {
        "data": { "type": "user--user", "id": "USER_UUID" }
      }
    }
  }
}
```

## Custom REST Resources

For non-entity data or complex business logic:

```php
namespace Drupal\MODULE_NAME\Plugin\rest\resource;

use Drupal\rest\Plugin\ResourceBase;
use Drupal\rest\ResourceResponse;

#[RestResource(
  id: "my_resource",
  label: new TranslatableMarkup("My Resource"),
  uri_paths: [
    "canonical" => "/api/my-resource/{id}",
    "create" => "/api/my-resource",
  ]
)]
class MyResource extends ResourceBase {

  public function get(string $id): ResourceResponse {
    $data = ['id' => $id, 'message' => 'Hello'];
    $response = new ResourceResponse($data, 200);
    $response->addCacheableDependency(CacheableMetadata::createFromRenderArray([
      '#cache' => ['max-age' => 3600],
    ]));
    return $response;
  }

  public function post(array $data): ModifiedResourceResponse {
    // Validate and process $data
    return new ModifiedResourceResponse($result, 201);
  }
}
```

Enable via REST UI module or config:
```yaml
# rest.resource.my_resource.yml
id: my_resource
plugin_id: my_resource
granularity: resource
configuration:
  methods: [GET, POST]
  formats: [json]
  authentication: [cookie, basic_auth, oauth2]
```

## Authentication

- **Cookie** — For same-origin browser requests (include CSRF token header)
- **Basic Auth** — For simple server-to-server (enable `basic_auth` module)
- **OAuth 2.0** — For decoupled apps (use `simple_oauth` contrib module)

### CSRF Token for Cookie Auth
```
GET /session/token → returns token string
POST /jsonapi/node/article
  X-CSRF-Token: {token}
  Content-Type: application/vnd.api+json
```

## Custom Controllers (Simple JSON)

For non-RESTful endpoints:

```php
class ApiController extends ControllerBase {
  public function data(): JsonResponse {
    return new JsonResponse(['status' => 'ok']);
  }
}
```

Route:
```yaml
MODULE_NAME.api_data:
  path: '/api/data'
  defaults:
    _controller: '\Drupal\MODULE_NAME\Controller\ApiController::data'
  requirements:
    _permission: 'access content'
  options:
    _format: json
```

## Key Rules

- Prefer JSON:API for standard entity CRUD — it's built-in and follows the spec
- Use custom REST resources for complex business logic
- Always add cache metadata to responses
- Always validate input on POST/PATCH endpoints
- Use proper authentication — never expose write endpoints without auth
- Add `->accessCheck(TRUE)` on all entity queries in custom endpoints
- JSON:API uses PATCH, not PUT
- Never expose sensitive fields via JSON:API — use `jsonapi_resource_config` to limit
