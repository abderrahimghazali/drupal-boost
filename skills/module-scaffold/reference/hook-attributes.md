# Drupal 11.1+ OOP Hook System

## Overview

Drupal 11.1 introduced the `#[Hook]` attribute to replace procedural hook implementations. Hook classes live in `src/Hook/` by convention and are auto-discovered.

## Basic #[Hook] Attribute Syntax

```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class NodeHooks {

  #[Hook('node_presave')]
  public function setDefaultTitle(\Drupal\node\NodeInterface $node): void {
    if ($node->isNew() && empty($node->getTitle())) {
      $node->setTitle('Untitled - ' . date('Y-m-d'));
    }
  }

}
```

The class is auto-registered as a service. Constructor injection works via autowiring.

```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\Core\Session\AccountProxyInterface;

class AccessHooks {

  public function __construct(
    protected readonly AccountProxyInterface $currentUser,
  ) {}

  #[Hook('node_access')]
  public function restrictDrafts(\Drupal\node\NodeInterface $node, string $op, \Drupal\Core\Session\AccountInterface $account): \Drupal\Core\Access\AccessResultInterface {
    if ($op === 'view' && !$node->isPublished()) {
      return \Drupal\Core\Access\AccessResult::forbiddenIf(
        !$account->hasPermission('view unpublished content')
      );
    }
    return \Drupal\Core\Access\AccessResult::neutral();
  }

}
```

## Migration from Procedural Hooks

Before (my_module.module):
```php
function my_module_form_alter(&$form, \Drupal\Core\Form\FormStateInterface $form_state, $form_id) {
  if ($form_id === 'node_article_edit_form') {
    $form['title']['#description'] = t('Enter a descriptive title');
  }
}
```

After (src/Hook/FormHooks.php):
```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Hook\Attribute\Hook;

class FormHooks {

  #[Hook('form_node_article_edit_form_alter')]
  public function alterArticleForm(array &$form, FormStateInterface $form_state, string $form_id): void {
    $form['title']['#description'] = t('Enter a descriptive title');
  }

}
```

Note: the `.module` file is still required to exist (can be empty) for module discovery. Procedural hooks and OOP hooks can coexist during migration.

## Hook Ordering

Control execution order with `order` parameter using `Drupal\Core\Hook\Order` and related classes.

```php
use Drupal\Core\Hook\Attribute\Hook;
use Drupal\Core\Hook\Order;
use Drupal\Core\Hook\OrderBefore;
use Drupal\Core\Hook\OrderAfter;

class OrderedHooks {

  // Run this implementation first, before all others.
  #[Hook('entity_presave', order: Order::First)]
  public function earlyPresave($entity): void {
    // Runs before other hook_entity_presave implementations.
  }

  // Run this implementation last, after all others.
  #[Hook('entity_update', order: Order::Last)]
  public function lateUpdate($entity): void {
    // Runs after other hook_entity_update implementations.
  }

  // Run before a specific module's implementation.
  #[Hook('node_presave', order: new OrderBefore(['content_moderation']))]
  public function beforeModeration(\Drupal\node\NodeInterface $node): void {
    // Runs before content_moderation's hook_node_presave.
  }

  // Run after a specific module's implementation.
  #[Hook('form_alter', order: new OrderAfter(['system']))]
  public function afterSystemFormAlter(array &$form): void {
    // Runs after system's hook_form_alter.
  }

}
```

## Multiple Hook Implementations per Class

A single class can implement many hooks. Group related hooks logically.

```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\Core\Entity\EntityInterface;

class EntityLifecycleHooks {

  #[Hook('entity_presave')]
  public function onPresave(EntityInterface $entity): void {
    // Fires before any entity is saved.
  }

  #[Hook('entity_insert')]
  public function onInsert(EntityInterface $entity): void {
    // Fires after a new entity is created.
  }

  #[Hook('entity_update')]
  public function onUpdate(EntityInterface $entity): void {
    // Fires after an existing entity is updated.
  }

  #[Hook('entity_delete')]
  public function onDelete(EntityInterface $entity): void {
    // Fires after an entity is deleted.
  }

}
```

## One Method Implementing Multiple Hooks

A single method can respond to multiple hooks by stacking attributes.

```php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class CacheHooks {

  #[Hook('entity_insert')]
  #[Hook('entity_update')]
  #[Hook('entity_delete')]
  public function invalidateCustomCache(\Drupal\Core\Entity\EntityInterface $entity): void {
    if ($entity->getEntityTypeId() === 'node') {
      \Drupal::cache('my_module')->invalidateAll();
    }
  }

}
```

## Common Hooks Reference

### Entity Hooks
| Hook | Fires when |
|------|-----------|
| `entity_presave` | Before any entity save |
| `entity_insert` | After new entity created |
| `entity_update` | After existing entity updated |
| `entity_delete` | After entity deleted |
| `entity_view` | Entity being rendered |
| `entity_view_alter` | Alter entity render array |
| `entity_access` | Access check on entity |
| `ENTITY_TYPE_presave` | Before specific type save (e.g., `node_presave`) |
| `ENTITY_TYPE_insert` | After specific type created |

### Form Hooks
| Hook | Fires when |
|------|-----------|
| `form_alter` | Any form is built |
| `form_FORM_ID_alter` | Specific form is built |
| `form_BASE_FORM_ID_alter` | Base form altered (e.g., `form_node_form_alter`) |

### Theme / Render Hooks
| Hook | Fires when |
|------|-----------|
| `theme` | Register theme implementations |
| `preprocess_HOOK` | Preprocess variables for template (e.g., `preprocess_node`) |
| `page_attachments` | Attach libraries to page |
| `page_attachments_alter` | Alter page attachments |
| `theme_suggestions_HOOK_alter` | Alter template suggestions |

### System Hooks
| Hook | Fires when |
|------|-----------|
| `install` | Module installed |
| `uninstall` | Module uninstalled |
| `cron` | Cron run |
| `requirements` | Status report / install checks |
| `schema` | Define database tables |
| `help` | Admin help page |
| `permissions` | Define permissions (use `*.permissions.yml` instead) |

### Routing & Menu Hooks
| Hook | Fires when |
|------|-----------|
| `menu_links_discovered_alter` | Alter menu link definitions |
| `local_tasks_alter` | Alter local task tabs |
| `menu_local_actions_alter` | Alter local action buttons |

### Field / Views Hooks
| Hook | Fires when |
|------|-----------|
| `entity_base_field_info` | Define base fields on entity types |
| `entity_bundle_field_info` | Define bundle fields |
| `entity_extra_field_info` | Pseudo-fields in manage display |
| `views_data` | Expose data to Views |
| `views_data_alter` | Alter Views data definitions |

## Class Organization Convention

Recommended file structure:

```
src/Hook/
  EntityHooks.php      — entity lifecycle hooks
  FormHooks.php        — form_alter hooks
  ThemeHooks.php       — theme, preprocess, page_attachments
  ViewsHooks.php       — views_data, views hooks
  SystemHooks.php      — cron, install, requirements
```

Keep the `.module` file minimal or empty. Only procedural code that cannot be converted (rare edge cases) should remain there.
