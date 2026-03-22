# Cache API Patterns

## Custom Cache Bins

Define a custom cache bin for module-specific data:

```yaml
# mymodule.services.yml
services:
  cache.mymodule:
    class: Drupal\Core\Cache\CacheBackendInterface
    tags:
      - { name: cache.bin }
    factory: ['@cache_factory', 'get']
    arguments: [mymodule]
```

Using the cache bin:

```php
// Inject via dependency injection.
public function __construct(
  protected CacheBackendInterface $cache,
) {}

// Store data with tags and expiry.
$this->cache->set(
  'mymodule:results:' . $id,
  $expensive_data,
  Cache::PERMANENT,                     // Or a Unix timestamp for expiry.
  ['mymodule:result', 'node:' . $nid]   // Cache tags for invalidation.
);

// Retrieve cached data.
$cached = $this->cache->get('mymodule:results:' . $id);
if ($cached) {
  return $cached->data;
}

// Delete specific entry.
$this->cache->delete('mymodule:results:' . $id);

// Invalidate (mark stale but keep for stale-while-revalidate).
$this->cache->invalidate('mymodule:results:' . $id);

// Delete all entries in the bin.
$this->cache->deleteAll();
```

## Cache Tag Patterns

Tags enable targeted invalidation when data changes:

```php
use Drupal\Core\Cache\Cache;

// In render arrays - declare what data this output depends on.
$build['content'] = [
  '#markup' => $output,
  '#cache' => [
    'tags' => [
      'node:42',                // Invalidated when node 42 changes.
      'node_list',              // Invalidated when any node is created/deleted.
      'taxonomy_term:5',        // Invalidated when term 5 changes.
      'config:system.site',     // Invalidated when site config changes.
      'mymodule:custom_tag',    // Custom tag.
    ],
  ],
];

// Invalidate tags programmatically.
Cache::invalidateTags(['node:42']);
Cache::invalidateTags(['mymodule:custom_tag']);

// Entity list tags (invalidated on entity create/delete).
// Pattern: {entity_type}_list or {entity_type}_list:{bundle}
$build['#cache']['tags'][] = 'node_list:article';
```

Common built-in tags:
- `node:{id}`, `user:{id}`, `taxonomy_term:{id}` - entity-specific
- `node_list`, `user_list` - entity type lists
- `config:{name}` - configuration objects
- `library_info` - library definitions

## Cache Context Patterns

Contexts define the variations of cached data:

```php
$build['content'] = [
  '#markup' => $personalized_output,
  '#cache' => [
    'contexts' => [
      'user',                   // Vary per user (most granular, use sparingly).
      'user.permissions',       // Vary by permission set (preferred over 'user').
      'user.roles:authenticated', // Vary for authenticated vs anonymous.
      'url',                    // Vary per URL.
      'url.path',               // Vary per path only.
      'url.query_args:page',    // Vary per specific query parameter.
      'languages:language_interface', // Vary per language.
      'theme',                  // Vary per theme.
      'timezone',               // Vary per timezone.
    ],
  ],
];
```

Custom cache context:

```php
namespace Drupal\mymodule\Cache;

use Drupal\Core\Cache\CacheableMetadata;
use Drupal\Core\Cache\Context\CacheContextInterface;

class MyCustomCacheContext implements CacheContextInterface {

  public static function getLabel() {
    return t('My custom context');
  }

  public function getContext() {
    // Return a string that varies based on condition.
    return \Drupal::currentUser()->hasPermission('premium access') ? 'premium' : 'standard';
  }

  public function getCacheableMetadata() {
    return new CacheableMetadata();
  }

}
```

```yaml
# mymodule.services.yml
services:
  cache_context.mymodule_tier:
    class: Drupal\mymodule\Cache\MyCustomCacheContext
    tags:
      - { name: cache.context }
```

## Lazy Builders and Placeholders

Exclude dynamic elements from page cache:

```php
$build['dynamic_part'] = [
  '#lazy_builder' => [
    'mymodule.lazy_builder:renderUserGreeting',
    [$account_id],
  ],
  '#create_placeholder' => TRUE,   // Forces placeholder even in non-BigPipe.
];
```

```php
namespace Drupal\mymodule;

use Drupal\Core\Security\TrustedCallbackInterface;

class LazyBuilder implements TrustedCallbackInterface {

  public function renderUserGreeting(int $uid): array {
    $user = \Drupal::entityTypeManager()->getStorage('user')->load($uid);
    return [
      '#markup' => t('Hello, @name!', ['@name' => $user->getDisplayName()]),
      '#cache' => [
        'contexts' => ['user'],
        'tags' => ['user:' . $uid],
      ],
    ];
  }

  public static function trustedCallbacks(): array {
    return ['renderUserGreeting'];
  }

}
```

## BigPipe Integration

BigPipe automatically streams lazy builders. Ensure dynamic content uses `#lazy_builder`:

```php
// This will be replaced with a placeholder, then streamed via BigPipe.
$build['cart_count'] = [
  '#lazy_builder' => ['mymodule.cart:renderCount', []],
  '#create_placeholder' => TRUE,
];
```

Disable BigPipe for specific responses:

```php
$response->headers->set('BigPipe-No-Js-Placeholder', 'true');
```

## Cache Debugging

```php
// settings.local.php - disable caching for development.
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';

// Enable cache debug headers.
$settings['http.response.debug_cacheability_headers'] = TRUE;
// Response headers will include:
//   X-Drupal-Cache-Tags: node:1 node_list config:system.site
//   X-Drupal-Cache-Contexts: user.permissions languages:language_interface
//   X-Drupal-Cache-Max-Age: 3600
```

Drush cache inspection:

```bash
# Clear specific cache bin.
drush cache:rebuild
drush cr

# Inspect cache tags.
drush ev "print_r(\Drupal::cache('render')->get('entity_view:node:1:full'));"
```

## Performance Profiling

```php
// Identify cache misses with logging.
$cached = \Drupal::cache('mymodule')->get($cid);
if (!$cached) {
  \Drupal::logger('mymodule')->debug('Cache miss: @cid', ['@cid' => $cid]);
  $data = $this->expensiveCalculation();
  \Drupal::cache('mymodule')->set($cid, $data, Cache::PERMANENT, $tags);
}

// Use max-age to prevent thundering herd.
$build['#cache']['max_age'] = 300;  // 5 minutes.
```

Key rules:
- Never cache per-user unless absolutely necessary; prefer `user.permissions`.
- Always add cache tags so content updates propagate.
- Use `#create_placeholder` for personalized blocks on otherwise-cacheable pages.
- Use `max_age = 0` only as a last resort; it disables all caching upstream.
