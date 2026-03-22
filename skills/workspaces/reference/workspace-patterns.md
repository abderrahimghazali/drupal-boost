# Workspace Patterns

## Setting Up Workspaces

Enable the core Workspaces module:

```bash
drush en workspaces -y
```

Create workspaces programmatically:

```php
use Drupal\workspaces\Entity\Workspace;

$workspace = Workspace::create([
  'id' => 'staging',
  'label' => 'Staging',
  'parent' => '',       // Empty for top-level workspace.
]);
$workspace->save();

// Create a child workspace.
$child = Workspace::create([
  'id' => 'feature_redesign',
  'label' => 'Feature: Redesign',
  'parent' => 'staging',
]);
$child->save();
```

Switch active workspace:

```php
$workspace_manager = \Drupal::service('workspaces.manager');
$workspace = \Drupal::entityTypeManager()
  ->getStorage('workspace')
  ->load('staging');
$workspace_manager->setActiveWorkspace($workspace);
```

Via Drush (contrib `workspace_cli`):

```bash
drush workspace:activate staging
drush workspace:list
drush workspace:info staging
```

## Workspace-Aware Entity Code

### Checking Workspace Context

```php
$workspace_manager = \Drupal::service('workspaces.manager');

// Check if a workspace is active (not Live).
if ($workspace_manager->hasActiveWorkspace()) {
  $active = $workspace_manager->getActiveWorkspace();
  $workspace_id = $active->id();
}

// Execute code in a specific workspace context.
$workspace_manager->executeInWorkspace('staging', function () {
  // All entity operations here happen in the staging workspace.
  $nodes = \Drupal::entityTypeManager()
    ->getStorage('node')
    ->loadByProperties(['type' => 'article']);
  // These are the staging versions of the articles.
});
```

### Entity Queries in Workspaces

Entity queries automatically filter by active workspace:

```php
// This automatically returns workspace-specific revisions.
$nids = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->condition('status', 1)
  ->accessCheck(TRUE)
  ->execute();
```

### Workspace-Aware Entity Operations

```php
// Loading an entity in a workspace returns the workspace revision.
$node = \Drupal::entityTypeManager()->getStorage('node')->load(42);
// $node is now the workspace-specific revision if a workspace is active.

// Saving creates a new revision tracked by the workspace.
$node->set('title', 'Updated in staging');
$node->save();
// This revision is only visible in the current workspace.
```

## Publishing Workflows

### Publishing (Deploying) a Workspace

```php
$workspace = Workspace::load('staging');

// Check if workspace can be published.
$workspace_publisher = \Drupal::service('workspaces.manager');
// Publishing pushes all workspace changes to Live (or parent workspace).
$workspace_publisher->publish($workspace);
```

### Event Subscribers for Workspace Operations

```php
namespace Drupal\mymodule\EventSubscriber;

use Drupal\workspaces\Event\WorkspacePublishEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class WorkspaceSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents() {
    return [
      'workspaces.publish.pre' => 'onPrePublish',
      'workspaces.publish.post' => 'onPostPublish',
    ];
  }

  public function onPrePublish(WorkspacePublishEvent $event) {
    $workspace = $event->getWorkspace();
    // Validate content before publishing.
    // Throw exception to prevent publishing.
    \Drupal::logger('mymodule')->info('Publishing workspace: @label', [
      '@label' => $workspace->label(),
    ]);
  }

  public function onPostPublish(WorkspacePublishEvent $event) {
    $workspace = $event->getWorkspace();
    // Trigger downstream actions after publishing.
    // Clear external caches, notify editors, etc.
  }

}
```

```yaml
# mymodule.services.yml
services:
  mymodule.workspace_subscriber:
    class: Drupal\mymodule\EventSubscriber\WorkspaceSubscriber
    tags:
      - { name: event_subscriber }
```

## Custom Entity Workspace Support

To make a custom content entity workspace-aware:

```php
/**
 * @ContentEntityType(
 *   id = "myentity",
 *   label = @Translation("My Entity"),
 *   revision_table = "myentity_revision",
 *   handlers = {
 *     "workspace" = "Drupal\workspaces\EntityHandler\DefaultWorkspaceHandler",
 *   },
 *   entity_keys = {
 *     "id" = "id",
 *     "revision" = "revision_id",
 *     "label" = "label",
 *   },
 * )
 */
class MyEntity extends ContentEntityBase implements RevisionableInterface {

  // Entity must be revisionable for workspace support.
  // Ensure revision_table is defined in the annotation.

  public static function baseFieldDefinitions(EntityTypeInterface $entity_type) {
    $fields = parent::baseFieldDefinitions($entity_type);

    $fields['label'] = BaseFieldDefinition::create('string')
      ->setLabel(t('Label'))
      ->setRevisionable(TRUE);   // Fields must be revisionable.

    return $fields;
  }

}
```

Requirements for workspace support:
- Entity must be revisionable (have a revision table).
- Entity must specify a workspace handler.
- All fields that should vary across workspaces must be revisionable.

## Workspace Limitations and Workarounds

### Unsupported Entity Types

Config entities are not workspace-aware. Workarounds:
- Use content entities for workspace-sensitive configuration.
- Use the State API with workspace-prefixed keys.
- Manage config changes separately from workspace publishing.

### Non-Revisionable Fields

Fields that are not revisionable share the same value across workspaces:

```php
// This field is NOT workspace-aware even if the entity is.
$fields['global_setting'] = BaseFieldDefinition::create('boolean')
  ->setLabel(t('Global setting'))
  ->setRevisionable(FALSE);
```

### Path Aliases

Path aliases are workspace-aware in Drupal 11. Content in a workspace can have different aliases that only take effect on publish.

### Menu Links

Content menu links track workspace revisions. Custom menu links (non-content) are not workspace-aware. Workaround: use content-based menu link fields.

### Views Integration

Views automatically respect the active workspace. No special configuration is needed. However, custom views plugins that bypass the entity API may need manual workspace handling:

```php
// In custom views code, ensure workspace-aware loading.
$storage = \Drupal::entityTypeManager()->getStorage('node');
// Use loadMultiple() instead of direct database queries.
$nodes = $storage->loadMultiple($nids);
```

### Caching Considerations

Workspace context is automatically added as a cache context. Custom render arrays that depend on workspace data should include:

```php
$build['#cache']['contexts'][] = 'workspace';
```

### Performance Notes

- Each entity save in a workspace creates a new revision, increasing database size.
- Publishing large workspaces can be resource-intensive.
- Consider batching workspace publishing for sites with many changes.
- Regularly clean up unused workspace revisions.
