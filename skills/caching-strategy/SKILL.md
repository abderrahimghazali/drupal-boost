---
name: caching-strategy
description: Drupal cache API patterns including cache tags, cache contexts, max-age, render caching, and cache invalidation strategies. Use when implementing caching, debugging cache issues, or optimizing Drupal performance.
allowed-tools: Read, Grep, Glob
---

# Drupal Caching Strategy

## Cache Metadata (The Three Pillars)

Every render array MUST include cache metadata:

```php
$build = [
  '#theme' => 'my_template',
  '#data' => $data,
  '#cache' => [
    'tags' => ['node_list', 'node:42'],           // WHAT invalidates this
    'contexts' => ['user.permissions', 'url.path'], // WHAT varies this
    'max-age' => 3600,                              // HOW LONG to cache (seconds)
  ],
];
```

### Cache Tags — "What invalidates this cache?"
- `node:NID` — Invalidated when a specific node changes
- `node_list` — Invalidated when any node is created/updated/deleted
- `user:UID` — Invalidated when a specific user changes
- `taxonomy_term:TID` — Invalidated when a term changes
- `config:system.site` — Invalidated when site config changes
- Custom: `MODULE_NAME:ENTITY:ID`

Invalidate manually:
```php
\Drupal\Core\Cache\Cache::invalidateTags(['node:42']);
```

### Cache Contexts — "What makes this vary?"
- `user` — Different per user
- `user.permissions` — Different per permission set (fewer variations)
- `user.roles` — Different per role combination
- `url.path` — Different per URL path
- `url.query_args` — Different per query string
- `url.query_args:sort` — Different per specific query param
- `languages:language_interface` — Different per language
- `theme` — Different per theme
- `route` — Different per route

### Max-Age
- `Cache::PERMANENT` (or `-1`) — Never expires (invalidated by tags only)
- `0` — Uncacheable (use sparingly — kills performance)
- `3600` — Cache for 1 hour
- `86400` — Cache for 1 day

## Cache Bubbling

Cache metadata "bubbles up" from child elements to parents. Drupal automatically merges:
- Tags: Union of all tags
- Contexts: Union of all contexts
- Max-age: Minimum of all max-ages (most restrictive wins)

This means if ANY child has `max-age: 0`, the entire page becomes uncacheable.

## Lazy Builders

For uncacheable content within cacheable pages:

```php
$build['dynamic_part'] = [
  '#lazy_builder' => ['MODULE_NAME.my_service:renderDynamic', [$entity_id]],
  '#create_placeholder' => TRUE,
];
```

The lazy builder method:
```php
public function renderDynamic(int $entity_id): array {
  return [
    '#markup' => $this->generateContent($entity_id),
    '#cache' => ['max-age' => 0],
  ];
}
```

BigPipe streams these placeholders after the main page loads.

## Custom Cache Bins

For storing computed data:

```php
// In services.yml
services:
  cache.MODULE_NAME:
    class: Drupal\Core\Cache\CacheBackendInterface
    tags:
      - { name: cache.bin }
    factory: cache_factory:get
    arguments: [MODULE_NAME]
```

Usage:
```php
// Store
$this->cache->set('my_key', $data, Cache::PERMANENT, ['node:42']);

// Retrieve
$cached = $this->cache->get('my_key');
if ($cached) {
  return $cached->data;
}
```

## Performance Anti-Patterns

- `max-age: 0` on render arrays that could be cached
- Missing cache tags (content changes but cache is stale)
- Missing cache contexts (same content shown to all users when it should vary)
- `\Drupal::cache()->deleteAll()` instead of tag-based invalidation
- Not using lazy builders for dynamic content in static pages
- `drupal_flush_all_caches()` in code (use `drush cr` in dev only)

## Debugging Cache

```bash
# Clear all caches
drush cr

# Check specific cache bin
drush ev "\Drupal::cache('render')->get('KEY')"
```

Enable debug headers in `development.services.yml`:
```yaml
parameters:
  http.response.debug_cacheability_headers: true
```

Then check response headers: `X-Drupal-Cache-Tags`, `X-Drupal-Cache-Contexts`, `X-Drupal-Cache-Max-Age`.
