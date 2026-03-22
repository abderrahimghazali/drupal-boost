---
name: module-scaffold
description: Scaffolds Drupal 11 modules with services, plugins, controllers, forms, routing, event subscribers, OOP Hook attributes, Entity/Field API, Queue/Batch API. Use when creating a new module, adding a service, creating a plugin type, implementing a hook, or building a custom entity.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Drupal 11 Module Development

You are helping build or extend a Drupal 11 custom module. Follow these patterns precisely.

## Module File Structure

```
modules/custom/MODULE_NAME/
├── MODULE_NAME.info.yml           # Required: module metadata
├── MODULE_NAME.module             # Optional: procedural hooks (prefer OOP)
├── MODULE_NAME.install            # Optional: install/update hooks
├── MODULE_NAME.services.yml       # Services and DI
├── MODULE_NAME.routing.yml        # Routes
├── MODULE_NAME.permissions.yml    # Permissions
├── MODULE_NAME.links.menu.yml     # Menu links
├── MODULE_NAME.links.task.yml     # Local tasks (tabs)
├── MODULE_NAME.links.action.yml   # Local actions
├── MODULE_NAME.libraries.yml      # CSS/JS libraries
├── src/
│   ├── Controller/                # Route controllers
│   ├── Form/                      # Forms
│   ├── Plugin/                    # Plugins (Block, Field, etc.)
│   ├── Entity/                    # Entity types
│   ├── Service/                   # Custom services
│   ├── EventSubscriber/           # Event subscribers
│   ├── Hook/                      # OOP Hook implementations (Drupal 11.1+)
│   ├── Access/                    # Custom access checkers
│   └── Commands/                  # Drush commands
├── config/
│   ├── install/                   # Default config installed with module
│   ├── optional/                  # Config installed if dependencies met
│   └── schema/                    # Config schema definitions
└── templates/                     # Twig templates
```

## info.yml Template

```yaml
name: 'Module Name'
type: module
description: 'Brief description of the module.'
core_version_requirement: ^10 || ^11
package: Custom
dependencies:
  - drupal:node
  - drupal:user
```

## Services & Dependency Injection

Always use DI. Define services in `MODULE_NAME.services.yml`:

```yaml
services:
  MODULE_NAME.my_service:
    class: Drupal\MODULE_NAME\Service\MyService
    arguments: ['@entity_type.manager', '@current_user', '@logger.factory']
```

Inject in classes via constructor:

```php
public function __construct(
  private readonly EntityTypeManagerInterface $entityTypeManager,
  private readonly AccountProxyInterface $currentUser,
  private readonly LoggerChannelFactoryInterface $loggerFactory,
) {}
```

Use `ContainerInjectionInterface` for controllers, `ContainerFactoryPluginInterface` for plugins.

## OOP Hook Attributes (Drupal 11.1+)

Preferred over procedural hooks:

```php
namespace Drupal\MODULE_NAME\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class ModuleHooks {

  #[Hook('entity_insert')]
  public function onEntityInsert(EntityInterface $entity): void {
    // Handle entity insert.
  }

  #[Hook('form_alter')]
  public function onFormAlter(array &$form, FormStateInterface $form_state, string $form_id): void {
    // Alter forms.
  }
}
```

Hook ordering (Drupal 11.2+):
```php
#[Hook('entity_presave', order: Order::First)]
#[Hook('entity_presave', order: new OrderBefore(['other_module']))]
```

## Routing

```yaml
MODULE_NAME.my_page:
  path: '/my-path/{node}'
  defaults:
    _controller: '\Drupal\MODULE_NAME\Controller\MyController::content'
    _title: 'My Page'
  requirements:
    _permission: 'access content'
  options:
    parameters:
      node:
        type: entity:node
```

## Forms

Extend `FormBase` for custom forms, `ConfigFormBase` for settings forms:

```php
class MyForm extends FormBase {
  public function getFormId(): string { return 'my_form'; }
  public function buildForm(array $form, FormStateInterface $form_state): array { ... }
  public function validateForm(array &$form, FormStateInterface $form_state): void { ... }
  public function submitForm(array &$form, FormStateInterface $form_state): void { ... }
}
```

## Plugins

Block plugin example:
```php
#[Block(
  id: "my_block",
  admin_label: new TranslatableMarkup("My Block"),
  category: new TranslatableMarkup("Custom"),
)]
class MyBlock extends BlockBase implements ContainerFactoryPluginInterface {
  // Inject services via create() and __construct()
}
```

## Key Rules

- Always use dependency injection in `src/` classes — never `\Drupal::service()`
- Always add cache metadata to render arrays (`#cache` => tags, contexts, max-age)
- Always add `->accessCheck(TRUE)` on entity queries
- Use `$this->t()` for translations in classes
- Define config schema for all custom configuration
- Prefer OOP Hook attributes over procedural hooks for Drupal 11.1+
- Follow PSR-4: namespace `Drupal\MODULE_NAME\*` maps to `src/*`

Read reference files in `reference/` for detailed API patterns:
- `reference/service-patterns.md` for DI patterns
- `reference/plugin-types.md` for plugin system details
- `reference/hook-attributes.md` for OOP hooks
- `reference/entity-field-api.md` for entity/field development
