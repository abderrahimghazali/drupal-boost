# JSON:API Patterns for Drupal 11

## Endpoint Structure and Conventions

JSON:API is enabled by default in Drupal 10+. Base path: `/jsonapi`.

```
GET    /jsonapi/node/article              # List articles
GET    /jsonapi/node/article/{uuid}       # Single article
POST   /jsonapi/node/article              # Create article
PATCH  /jsonapi/node/article/{uuid}       # Update article
DELETE /jsonapi/node/article/{uuid}       # Delete article
```

Resource type format: `{entity_type}--{bundle}`. The URL uses slashes: `/jsonapi/{entity_type}/{bundle}`.

```
/jsonapi/node/article                    # node--article
/jsonapi/taxonomy_term/tags              # taxonomy_term--tags
/jsonapi/user/user                       # user--user
/jsonapi/media/image                     # media--image
/jsonapi/block_content/basic             # block_content--basic
/jsonapi/paragraph/text                  # paragraph--text
```

Discover all available resources:

```
GET /jsonapi
```

## Filtering

Simple equality filter:

```
GET /jsonapi/node/article?filter[status]=1
GET /jsonapi/node/article?filter[field_category.name]=News
```

Shorthand operator filters:

```
# Condition-based filter
GET /jsonapi/node/article?filter[title-filter][condition][path]=title&filter[title-filter][condition][operator]=CONTAINS&filter[title-filter][condition][value]=drupal

# Operators: =, <>, <, <=, >, >=, CONTAINS, STARTS_WITH, ENDS_WITH, IN, NOT IN, BETWEEN, IS NULL, IS NOT NULL
```

Filter groups (AND/OR):

```
GET /jsonapi/node/article?filter[or-group][group][conjunction]=OR&filter[filter-a][condition][path]=title&filter[filter-a][condition][value]=Foo&filter[filter-a][condition][memberOf]=or-group&filter[filter-b][condition][path]=title&filter[filter-b][condition][value]=Bar&filter[filter-b][condition][memberOf]=or-group
```

Filter on related entity fields:

```
GET /jsonapi/node/article?filter[uid.name]=admin
GET /jsonapi/node/article?filter[field_tags.name]=Drupal
```

## Sorting

```
GET /jsonapi/node/article?sort=title                     # ASC
GET /jsonapi/node/article?sort=-created                   # DESC
GET /jsonapi/node/article?sort=-sticky,created            # Multiple
GET /jsonapi/node/article?sort[sort-title][path]=title&sort[sort-title][direction]=DESC
```

## Pagination

JSON:API returns paginated results (default 50 items). Use `page[limit]` and `page[offset]`:

```
GET /jsonapi/node/article?page[limit]=10&page[offset]=0
GET /jsonapi/node/article?page[limit]=10&page[offset]=10
```

Response includes pagination links:

```json
{
  "links": {
    "next": { "href": "https://example.com/jsonapi/node/article?page[offset]=10&page[limit]=10" },
    "prev": { "href": "https://example.com/jsonapi/node/article?page[offset]=0&page[limit]=10" }
  }
}
```

Maximum limit is 50 by default. Override in settings.php:

```php
$settings['jsonapi_maximum_page_size'] = 100;
```

## Sparse Fieldsets

Request only specific fields to reduce payload:

```
GET /jsonapi/node/article?fields[node--article]=title,body,created
GET /jsonapi/node/article?fields[node--article]=title,field_image&fields[file--file]=uri
```

## Includes (Related Resources)

Embed related resources in a single request:

```
GET /jsonapi/node/article?include=uid,field_tags
GET /jsonapi/node/article?include=field_image,field_image.uid
GET /jsonapi/node/article/{uuid}?include=field_paragraphs,field_paragraphs.field_image
```

Included resources appear in the top-level `included` array.

## Custom JSON:API Resource Types

Create a custom resource type by implementing `Drupal\jsonapi\ResourceType\ResourceType` or by using the `jsonapi_extras` module for config-based customization.

With `jsonapi_extras`, override resource type paths and field names in the admin UI at `/admin/config/services/jsonapi/resource_types`.

Programmatic resource type via event subscriber:

```php
namespace Drupal\my_module\EventSubscriber;

use Drupal\jsonapi\ResourceType\ResourceTypeBuildEvent;
use Drupal\jsonapi\ResourceType\ResourceTypeBuildEvents;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class JsonApiResourceSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [
      ResourceTypeBuildEvents::BUILD => 'onResourceTypeBuild',
    ];
  }

  public function onResourceTypeBuild(ResourceTypeBuildEvent $event): void {
    $resource_type_name = $event->getResourceTypeName();
    if ($resource_type_name === 'node--article') {
      // Disable a field from being exposed.
      foreach ($event->getFields() as $field) {
        if ($field->getPublicName() === 'field_internal_notes') {
          $event->disableField($field);
        }
      }
    }
  }

}
```

## JSON:API Resource Config (Limiting Exposed Fields)

With `jsonapi_extras` module:

```
composer require drupal/jsonapi_extras
drush en jsonapi_extras
```

Configure at `/admin/config/services/jsonapi`. Options:

- Disable entire resource types
- Rename public field names (e.g., `field_hero_image` to `heroImage`)
- Disable individual fields from being exposed
- Change resource type path (e.g., `/jsonapi/node/article` to `/jsonapi/articles`)

Set JSON:API to read-only mode via settings.php:

```php
$settings['jsonapi_read_only'] = TRUE;
```

## Error Handling

JSON:API returns errors in a standard format:

```json
{
  "errors": [
    {
      "status": "403",
      "title": "Forbidden",
      "detail": "The current user is not allowed to GET the selected resource.",
      "links": {
        "info": { "href": "https://www.drupal.org/docs/..." }
      }
    }
  ]
}
```

Common status codes:

- `200` - Success
- `201` - Created
- `204` - Deleted (no content)
- `400` - Malformed request (bad filter syntax, invalid body)
- `403` - Access denied (check permissions)
- `404` - Resource not found
- `405` - Method not allowed (read-only mode)
- `409` - Conflict (e.g., creating with existing UUID)
- `415` - Wrong content type (must send `Content-Type: application/vnd.api+json`)
- `422` - Unprocessable entity (validation errors)

POST/PATCH requests must include the correct content type header:

```
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
```

POST body structure:

```json
{
  "data": {
    "type": "node--article",
    "attributes": {
      "title": "My Article",
      "body": { "value": "<p>Content</p>", "format": "full_html" }
    },
    "relationships": {
      "field_tags": {
        "data": [
          { "type": "taxonomy_term--tags", "id": "{{uuid}}" }
        ]
      }
    }
  }
}
```
