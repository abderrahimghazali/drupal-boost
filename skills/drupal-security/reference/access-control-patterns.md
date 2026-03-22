# Access Control Patterns in Drupal

## Route-Level Permissions

Define access requirements directly in routing YAML:

```yaml
# Simple permission check.
mymodule.admin:
  path: '/admin/mymodule'
  defaults:
    _controller: '\Drupal\mymodule\Controller\AdminController::overview'
  requirements:
    _permission: 'administer mymodule'

# Multiple permissions (AND logic - all required).
mymodule.settings:
  path: '/admin/mymodule/settings'
  requirements:
    _permission: 'administer mymodule+administer site configuration'

# Multiple permissions (OR logic - any one sufficient).
mymodule.view:
  path: '/mymodule/view'
  requirements:
    _permission: 'access mymodule,view any mymodule content'

# Role-based (avoid when possible; prefer permissions).
mymodule.special:
  path: '/mymodule/special'
  requirements:
    _role: 'administrator'

# Custom access checker.
mymodule.custom:
  path: '/mymodule/{entity}'
  requirements:
    _custom_access: '\Drupal\mymodule\Access\MyAccessChecker::access'
```

## Entity Access Control Handlers

```php
namespace Drupal\mymodule\Entity;

use Drupal\Core\Entity\ContentEntityBase;
use Drupal\Core\Entity\EntityTypeInterface;

/**
 * @ContentEntityType(
 *   id = "myentity",
 *   handlers = {
 *     "access" = "Drupal\mymodule\Access\MyEntityAccessControlHandler",
 *   },
 * )
 */
class MyEntity extends ContentEntityBase {}
```

```php
namespace Drupal\mymodule\Access;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Entity\EntityAccessControlHandler;
use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Session\AccountInterface;

class MyEntityAccessControlHandler extends EntityAccessControlHandler {

  protected function checkAccess(EntityInterface $entity, $operation, AccountInterface $account) {
    switch ($operation) {
      case 'view':
        if ($entity->isPublished()) {
          return AccessResult::allowedIfHasPermission($account, 'view myentity')
            ->addCacheableDependency($entity);
        }
        return AccessResult::allowedIfHasPermission($account, 'view unpublished myentity')
          ->addCacheableDependency($entity);

      case 'update':
        if ($account->id() === $entity->getOwnerId()) {
          return AccessResult::allowedIfHasPermission($account, 'edit own myentity')
            ->cachePerUser()
            ->addCacheableDependency($entity);
        }
        return AccessResult::allowedIfHasPermission($account, 'edit any myentity');

      case 'delete':
        return AccessResult::allowedIfHasPermission($account, 'delete myentity');
    }

    return AccessResult::neutral();
  }

  protected function checkCreateAccess(AccountInterface $account, array $context, $entity_bundle = NULL) {
    return AccessResult::allowedIfHasPermission($account, 'create myentity');
  }

}
```

## Custom Access Checkers

Register as a tagged service:

```yaml
# mymodule.services.yml
services:
  mymodule.access_checker:
    class: Drupal\mymodule\Access\MyRouteAccessChecker
    tags:
      - { name: access_check, applies_to: _mymodule_access }
```

```php
namespace Drupal\mymodule\Access;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Routing\Access\AccessInterface;
use Drupal\Core\Session\AccountInterface;
use Symfony\Component\Routing\Route;

class MyRouteAccessChecker implements AccessInterface {

  public function access(Route $route, AccountInterface $account, $entity = NULL) {
    if (!$entity) {
      return AccessResult::forbidden('Entity parameter required.');
    }
    $has_perm = $account->hasPermission('access mymodule');
    $is_owner = $entity->getOwnerId() === $account->id();

    return AccessResult::allowedIf($has_perm && $is_owner)
      ->cachePerUser()
      ->addCacheableDependency($entity);
  }

}
```

## AccessResult Patterns

```php
use Drupal\Core\Access\AccessResult;

// Allowed - grants access (can be overridden by forbidden).
AccessResult::allowed();

// Forbidden - denies access (overrides allowed, cannot be overridden).
AccessResult::forbidden('Reason for denial');

// Neutral - no opinion; other checks decide.
AccessResult::neutral();

// Conditional helpers.
AccessResult::allowedIfHasPermission($account, 'permission_name');
AccessResult::allowedIfHasPermissions($account, ['perm1', 'perm2'], 'AND');
AccessResult::allowedIf($condition);
AccessResult::forbiddenIf($condition, 'Reason');

// Cacheability is critical - always add cache metadata.
AccessResult::allowed()
  ->cachePerUser()                          // Varies by user.
  ->cachePerPermissions()                   // Varies by permissions.
  ->addCacheableDependency($entity)         // Invalidate when entity changes.
  ->addCacheTags(['mymodule:settings'])      // Custom cache tags.
  ->setCacheMaxAge(3600);                   // Time-based expiry.

// Combining results (AND logic).
$result = $result1->andIf($result2);

// Combining results (OR logic).
$result = $result1->orIf($result2);
```

## Node Grants System

For row-level access control on nodes:

```php
// mymodule.module

function mymodule_node_grants(\Drupal\Core\Session\AccountInterface $account, $op) {
  $grants = [];
  if ($account->hasPermission('view private content')) {
    $grants['mymodule_private'] = [1];
  }
  // User-specific grant.
  $grants['mymodule_author'] = [$account->id()];
  return $grants;
}

function mymodule_node_access_records(\Drupal\node\NodeInterface $node) {
  $grants = [];
  if ($node->hasField('field_private') && $node->get('field_private')->value) {
    $grants[] = [
      'realm' => 'mymodule_private',
      'gid' => 1,
      'grant_view' => 1,
      'grant_update' => 0,
      'grant_delete' => 0,
    ];
  }
  // Author can always view their own nodes.
  $grants[] = [
    'realm' => 'mymodule_author',
    'gid' => $node->getOwnerId(),
    'grant_view' => 1,
    'grant_update' => 1,
    'grant_delete' => 0,
  ];
  return $grants;
}
```

After changing grants, rebuild: `drush node-access-rebuild` or `node_access_rebuild()`.

## Permission Definitions

```yaml
# mymodule.permissions.yml - static permissions.
administer mymodule:
  title: 'Administer MyModule'
  description: 'Full administrative access to MyModule settings.'
  restrict access: true

view myentity:
  title: 'View MyEntity content'

create myentity:
  title: 'Create MyEntity content'
```

Dynamic permissions via callback:

```yaml
# mymodule.permissions.yml
permission_callbacks:
  - \Drupal\mymodule\Permission\MyModulePermissions::permissions
```

```php
namespace Drupal\mymodule\Permission;

use Drupal\Core\StringTranslation\StringTranslationTrait;

class MyModulePermissions {
  use StringTranslationTrait;

  public function permissions() {
    $perms = [];
    foreach (\Drupal::entityTypeManager()->getStorage('myentity_type')->loadMultiple() as $type) {
      $perms["create {$type->id()} myentity"] = [
        'title' => $this->t('Create %type content', ['%type' => $type->label()]),
      ];
    }
    return $perms;
  }

}
```

Use `restrict access: true` for dangerous permissions (shown with warning in UI).
