# Drupal 11 Entity & Field API

## Content Entity vs Config Entity

| Aspect | Content Entity | Config Entity |
|--------|---------------|---------------|
| Storage | Database tables | YAML config files |
| Examples | Node, User, Term, Comment | View, Role, Vocabulary, ImageStyle |
| Fieldable | Yes (fields via UI) | No (properties only) |
| Translatable | Yes | Limited |
| Revisionable | Yes | No |
| Class extends | `ContentEntityBase` | `ConfigEntityBase` |

## Content Entity Definition

Location: `src/Entity/`

```php
namespace Drupal\my_module\Entity;

use Drupal\Core\Entity\Attribute\ContentEntityType;
use Drupal\Core\Entity\ContentEntityBase;
use Drupal\Core\Entity\EntityChangedInterface;
use Drupal\Core\Entity\EntityChangedTrait;
use Drupal\Core\Entity\EntityTypeInterface;
use Drupal\Core\Field\BaseFieldDefinition;
use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\user\EntityOwnerInterface;
use Drupal\user\EntityOwnerTrait;

#[ContentEntityType(
  id: 'my_module_task',
  label: new TranslatableMarkup('Task'),
  label_collection: new TranslatableMarkup('Tasks'),
  label_singular: new TranslatableMarkup('task'),
  label_plural: new TranslatableMarkup('tasks'),
  handlers: [
    'storage' => \Drupal\Core\Entity\Sql\SqlContentEntityStorage::class,
    'access' => \Drupal\Core\Entity\EntityAccessControlHandler::class,
    'list_builder' => \Drupal\my_module\TaskListBuilder::class,
    'form' => [
      'default' => \Drupal\my_module\Form\TaskForm::class,
      'delete' => \Drupal\Core\Entity\ContentEntityDeleteForm::class,
    ],
    'view_builder' => \Drupal\Core\Entity\EntityViewBuilder::class,
    'views_data' => \Drupal\views\EntityViewsData::class,
    'route_provider' => [
      'html' => \Drupal\Core\Entity\Routing\AdminHtmlRouteProvider::class,
    ],
  ],
  base_table: 'my_module_task',
  admin_permission: 'administer tasks',
  entity_keys: [
    'id' => 'id',
    'uuid' => 'uuid',
    'label' => 'title',
    'owner' => 'uid',
  ],
  links: [
    'canonical' => '/task/{my_module_task}',
    'add-form' => '/task/add',
    'edit-form' => '/task/{my_module_task}/edit',
    'delete-form' => '/task/{my_module_task}/delete',
    'collection' => '/admin/content/tasks',
  ],
)]
class Task extends ContentEntityBase implements EntityChangedInterface, EntityOwnerInterface {

  use EntityChangedTrait;
  use EntityOwnerTrait;

  public static function baseFieldDefinitions(EntityTypeInterface $entity_type): array {
    $fields = parent::baseFieldDefinitions($entity_type);

    // Owner field from trait.
    $fields += static::ownerBaseFieldDefinitions($entity_type);

    $fields['title'] = BaseFieldDefinition::create('string')
      ->setLabel(new TranslatableMarkup('Title'))
      ->setRequired(TRUE)
      ->setSetting('max_length', 255)
      ->setDisplayOptions('form', [
        'type' => 'string_textfield',
        'weight' => 0,
      ])
      ->setDisplayOptions('view', [
        'label' => 'hidden',
        'type' => 'string',
        'weight' => 0,
      ])
      ->setDisplayConfigurable('form', TRUE)
      ->setDisplayConfigurable('view', TRUE);

    $fields['description'] = BaseFieldDefinition::create('text_long')
      ->setLabel(new TranslatableMarkup('Description'))
      ->setDisplayOptions('form', [
        'type' => 'text_textarea',
        'weight' => 5,
      ])
      ->setDisplayOptions('view', [
        'type' => 'text_default',
        'weight' => 5,
      ])
      ->setDisplayConfigurable('form', TRUE)
      ->setDisplayConfigurable('view', TRUE);

    $fields['status'] = BaseFieldDefinition::create('boolean')
      ->setLabel(new TranslatableMarkup('Completed'))
      ->setDefaultValue(FALSE)
      ->setDisplayOptions('form', [
        'type' => 'boolean_checkbox',
        'weight' => 10,
      ])
      ->setDisplayConfigurable('form', TRUE);

    $fields['due_date'] = BaseFieldDefinition::create('datetime')
      ->setLabel(new TranslatableMarkup('Due date'))
      ->setSetting('datetime_type', 'date')
      ->setDisplayOptions('form', [
        'type' => 'datetime_default',
        'weight' => 15,
      ])
      ->setDisplayOptions('view', [
        'type' => 'datetime_default',
        'weight' => 15,
      ])
      ->setDisplayConfigurable('form', TRUE)
      ->setDisplayConfigurable('view', TRUE);

    $fields['created'] = BaseFieldDefinition::create('created')
      ->setLabel(new TranslatableMarkup('Created'));

    $fields['changed'] = BaseFieldDefinition::create('changed')
      ->setLabel(new TranslatableMarkup('Changed'));

    return $fields;
  }

}
```

## Config Entity Definition

```php
namespace Drupal\my_module\Entity;

use Drupal\Core\Config\Entity\ConfigEntityBase;
use Drupal\Core\Entity\Attribute\ConfigEntityType;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[ConfigEntityType(
  id: 'my_module_task_type',
  label: new TranslatableMarkup('Task type'),
  handlers: [
    'list_builder' => \Drupal\my_module\TaskTypeListBuilder::class,
    'form' => [
      'add' => \Drupal\my_module\Form\TaskTypeForm::class,
      'edit' => \Drupal\my_module\Form\TaskTypeForm::class,
      'delete' => \Drupal\Core\Entity\EntityDeleteForm::class,
    ],
    'route_provider' => [
      'html' => \Drupal\Core\Entity\Routing\AdminHtmlRouteProvider::class,
    ],
  ],
  config_prefix: 'task_type',
  admin_permission: 'administer tasks',
  entity_keys: [
    'id' => 'id',
    'label' => 'label',
    'uuid' => 'uuid',
  ],
  config_export: ['id', 'label', 'description'],
  links: [
    'add-form' => '/admin/structure/task-types/add',
    'edit-form' => '/admin/structure/task-types/{my_module_task_type}/edit',
    'delete-form' => '/admin/structure/task-types/{my_module_task_type}/delete',
    'collection' => '/admin/structure/task-types',
  ],
)]
class TaskType extends ConfigEntityBase {

  protected string $id;
  protected string $label;
  protected string $description = '';

}
```

Config entities also need a schema file at `config/schema/my_module.schema.yml`.

## Entity Handlers

Handlers control entity behavior. Override by specifying in the `handlers` key.

| Handler | Purpose | Default |
|---------|---------|---------|
| `storage` | CRUD operations, queries | `SqlContentEntityStorage` |
| `access` | Access control | `EntityAccessControlHandler` |
| `list_builder` | Admin listing table | `EntityListBuilder` |
| `form.default` | Add/edit form | `ContentEntityForm` |
| `form.delete` | Delete confirmation | `ContentEntityDeleteForm` |
| `view_builder` | Render entity | `EntityViewBuilder` |
| `views_data` | Views integration | `EntityViewsData` |
| `route_provider.html` | Auto-generate routes | `AdminHtmlRouteProvider` |

## Base Field Types

| Type | Class | Use case |
|------|-------|----------|
| `string` | `StringItem` | Short text (title) |
| `string_long` | `StringLongItem` | Long plain text |
| `text` | `TextItem` | Formatted text (short) |
| `text_long` | `TextLongItem` | Formatted text (long) |
| `text_with_summary` | `TextWithSummaryItem` | Body with summary |
| `integer` | `IntegerItem` | Integer values |
| `float` | `FloatItem` | Float values |
| `decimal` | `DecimalItem` | Precise decimal |
| `boolean` | `BooleanItem` | True/false |
| `email` | `EmailItem` | Email address |
| `uri` | `UriItem` | URI |
| `datetime` | `DateTimeItem` | Date/time |
| `timestamp` | `TimestampItem` | Unix timestamp |
| `created` | `CreatedItem` | Auto-set on creation |
| `changed` | `ChangedItem` | Auto-set on update |
| `entity_reference` | `EntityReferenceItem` | Reference to entity |
| `image` | `ImageItem` | Image file reference |
| `file` | `FileItem` | File reference |
| `link` | `LinkItem` | URL with title |
| `list_string` | `ListStringItem` | Select list (text keys) |
| `list_integer` | `ListIntegerItem` | Select list (int keys) |

## Entity Reference Field

```php
$fields['assigned_to'] = BaseFieldDefinition::create('entity_reference')
  ->setLabel(new TranslatableMarkup('Assigned to'))
  ->setSetting('target_type', 'user')
  ->setSetting('handler', 'default')
  ->setDisplayOptions('form', [
    'type' => 'entity_reference_autocomplete',
    'weight' => 20,
  ])
  ->setDisplayOptions('view', [
    'type' => 'entity_reference_label',
    'weight' => 20,
  ])
  ->setDisplayConfigurable('form', TRUE)
  ->setDisplayConfigurable('view', TRUE);
```

## Entity Queries

Always use `accessCheck()` -- Drupal 11 requires it.

```php
// Load all published articles by a specific author.
$nids = \Drupal::entityQuery('node')
  ->accessCheck(TRUE)
  ->condition('type', 'article')
  ->condition('status', 1)
  ->condition('uid', $author_uid)
  ->sort('created', 'DESC')
  ->range(0, 10)
  ->execute();

$nodes = \Drupal::entityTypeManager()->getStorage('node')->loadMultiple($nids);

// Count query.
$count = \Drupal::entityQuery('node')
  ->accessCheck(TRUE)
  ->condition('type', 'page')
  ->count()
  ->execute();

// OR condition group.
$query = \Drupal::entityQuery('node')->accessCheck(TRUE);
$or = $query->orConditionGroup()
  ->condition('title', '%urgent%', 'LIKE')
  ->condition('field_priority', 'high');
$query->condition($or);
$results = $query->execute();

// Exists / not exists.
$query = \Drupal::entityQuery('node')
  ->accessCheck(TRUE)
  ->condition('field_image', NULL, 'IS NOT NULL')
  ->execute();
```

## Entity CRUD Operations

```php
$storage = \Drupal::entityTypeManager()->getStorage('node');

// Create.
$node = $storage->create([
  'type' => 'article',
  'title' => 'My article',
  'body' => ['value' => 'Body text', 'format' => 'full_html'],
  'field_tags' => [['target_id' => 5]],
]);
$node->save();

// Read.
$node = $storage->load(42);
$nodes = $storage->loadMultiple([1, 2, 3]);
$nodes = $storage->loadByProperties(['type' => 'page', 'status' => 1]);

// Update.
$node = $storage->load(42);
$node->set('title', 'Updated title');
$node->save();

// Delete.
$node = $storage->load(42);
$node->delete();
// Or bulk delete:
$storage->delete($storage->loadMultiple([10, 11, 12]));
```

## Accessing Field Values

```php
$node = \Drupal\node\Entity\Node::load(1);

// Get simple value.
$title = $node->get('title')->value;
$body = $node->get('body')->value;
$format = $node->get('body')->format;

// Entity reference - get target entity.
$author = $node->get('uid')->entity;
$author_name = $node->get('uid')->entity->getDisplayName();
$author_id = $node->get('uid')->target_id;

// Multi-value fields.
foreach ($node->get('field_tags') as $item) {
  $term = $item->entity;
  $term_name = $term->label();
}

// Check emptiness.
if ($node->get('field_image')->isEmpty()) {
  // No image.
}

// Shorthand for common fields.
$title = $node->label();       // Entity label.
$id = $node->id();             // Entity ID.
$bundle = $node->bundle();     // Bundle (content type).
$uuid = $node->uuid();         // UUID.
$is_new = $node->isNew();      // Whether entity is unsaved.
```
