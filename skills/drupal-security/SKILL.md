---
name: drupal-security
description: Drupal security best practices, vulnerability prevention, permissions and access control, input sanitization, and the Access Policy API. Use when reviewing security, setting up permissions, or hardening a Drupal site.
allowed-tools: Read, Grep, Glob, Bash
---

# Drupal Security Best Practices

## XSS Prevention

### Twig (auto-escaping ON by default)
- `{{ variable }}` — safe, auto-escaped
- `{{ variable|raw }}` — DANGEROUS, bypasses escaping. Only use for pre-sanitized markup
- `{% set markup %}...{% endset %}` — auto-escaped when rendered
- `{{ variable|striptags }}` — strips HTML tags

### PHP
- Use `$this->t()` or `new TranslatableMarkup()` for user-facing strings
- Use `Xss::filter()` for user HTML that needs limited tags
- Use `Html::escape()` for plain text output
- Use `#plain_text` render element for untrusted text
- NEVER use `Markup::create()` with user input
- NEVER use `#markup` with unsanitized content

## SQL Injection Prevention

```php
// SAFE: parameterized query
$result = $connection->select('users', 'u')
  ->fields('u', ['name'])
  ->condition('status', 1)
  ->execute();

// SAFE: placeholder in query()
$result = $connection->query('SELECT name FROM {users} WHERE uid = :uid', [':uid' => $uid]);

// DANGEROUS: string concatenation
$result = $connection->query("SELECT * FROM {users} WHERE name = '$name'"); // NEVER DO THIS
```

## Access Control

### Route Permissions
```yaml
my_route:
  path: '/admin/my-page'
  requirements:
    _permission: 'administer my module'
```

### Entity Access
- Always call `->accessCheck(TRUE)` on entity queries
- Implement `EntityAccessControlHandler` for custom entities
- Use `AccessResult::allowed()`, `::forbidden()`, `::neutral()` with proper cacheability

```php
// REQUIRED in Drupal 10+
$nodes = \Drupal::entityTypeManager()
  ->getStorage('node')
  ->getQuery()
  ->accessCheck(TRUE)  // MANDATORY
  ->condition('status', 1)
  ->execute();
```

### Permission Definitions
```yaml
# MODULE_NAME.permissions.yml
administer my module:
  title: 'Administer My Module'
  description: 'Full admin access to My Module settings.'
  restrict access: true  # Only for permissions that allow site takeover

view my content:
  title: 'View My Content'
  description: 'View custom content managed by My Module.'
```

## CSRF Protection

- Drupal forms have built-in CSRF tokens — never disable them
- For custom AJAX endpoints, require `X-CSRF-Token` header
- Get token from `/session/token` endpoint
- REST/JSON:API requests with cookie auth must include CSRF token

## File Upload Security

- Validate file extensions with `file_validate_extensions()`
- Set file size limits with `file_validate_size()`
- Use `private://` for sensitive files (not `public://`)
- Never allow `.php`, `.phtml`, `.phar` extensions

## Input Handling

- Never access `$_GET`, `$_POST`, `$_REQUEST` directly
- Use the Request object: `$request->query->get('param')`
- Validate and sanitize all input at the boundary
- Use Form API validation for user-submitted forms

## Common Anti-Patterns to Flag

- `\Drupal::request()->get()` without validation
- `$_GET`, `$_POST`, `$_SERVER` direct access
- `|raw` in Twig templates
- `db_query()` with string interpolation
- `Markup::create($user_input)`
- Missing `accessCheck(TRUE)` on entity queries
- `_access: 'TRUE'` on sensitive routes
- Debug functions in production code (var_dump, dpm, kint, dd)
- Hardcoded credentials or API keys

## Security Review Checklist

1. All user input sanitized before output
2. All database queries use placeholders
3. All routes have proper access requirements
4. All entity queries include `accessCheck(TRUE)`
5. All file uploads validated (type, size, extension)
6. No debug functions in production code
7. No hardcoded secrets in code
8. CSRF tokens on all state-changing operations
9. Sensitive files use `private://` scheme
10. Error messages don't expose internals

Read reference files for details:
- `reference/vulnerability-checklist.md` for complete vulnerability patterns
- `reference/access-control-patterns.md` for access control implementation
