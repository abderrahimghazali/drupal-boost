# Drupal 11 Plugin Types

## Annotations vs Attributes

Drupal 11 supports PHP 8 attributes as the preferred way to define plugins. Annotations still work but attributes are recommended for new code.

```php
// Attribute (preferred in Drupal 11)
#[\Drupal\Core\Block\Attribute\Block(
  id: 'my_block',
  admin_label: new \Drupal\Core\StringTranslation\TranslatableMarkup('My Block'),
)]

// Annotation (legacy, still supported)
/**
 * @Block(
 *   id = "my_block",
 *   admin_label = @Translation("My Block"),
 * )
 */
```

## Block Plugin

Location: `src/Plugin/Block/`

```php
namespace Drupal\my_module\Plugin\Block;

use Drupal\Core\Block\Attribute\Block;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Block(
  id: 'my_module_example',
  admin_label: new TranslatableMarkup('Example Block'),
  category: new TranslatableMarkup('Custom'),
)]
class ExampleBlock extends BlockBase {

  public function build(): array {
    return [
      '#markup' => $this->t('Hello from block'),
      '#cache' => ['max-age' => 3600],
    ];
  }

  public function blockForm($form, FormStateInterface $form_state): array {
    $form['message'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Message'),
      '#default_value' => $this->configuration['message'] ?? '',
    ];
    return $form;
  }

  public function blockSubmit($form, FormStateInterface $form_state): void {
    $this->configuration['message'] = $form_state->getValue('message');
  }

}
```

## Field Type

Location: `src/Plugin/Field/FieldType/`

```php
namespace Drupal\my_module\Plugin\Field\FieldType;

use Drupal\Core\Field\Attribute\FieldType;
use Drupal\Core\Field\FieldItemBase;
use Drupal\Core\Field\FieldStorageDefinitionInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\Core\TypedData\DataDefinition;

#[FieldType(
  id: 'my_module_rating',
  label: new TranslatableMarkup('Rating'),
  description: new TranslatableMarkup('A rating field'),
  default_widget: 'my_module_rating_widget',
  default_formatter: 'my_module_rating_formatter',
)]
class RatingItem extends FieldItemBase {

  public static function propertyDefinitions(FieldStorageDefinitionInterface $field_definition): array {
    $properties['value'] = DataDefinition::create('integer')
      ->setLabel(new TranslatableMarkup('Rating value'))
      ->setRequired(TRUE);
    return $properties;
  }

  public static function schema(FieldStorageDefinitionInterface $field_definition): array {
    return [
      'columns' => [
        'value' => ['type' => 'int', 'unsigned' => TRUE, 'size' => 'small'],
      ],
    ];
  }

  public function isEmpty(): bool {
    $value = $this->get('value')->getValue();
    return $value === NULL || $value === '';
  }

}
```

## Field Widget

Location: `src/Plugin/Field/FieldWidget/`

```php
namespace Drupal\my_module\Plugin\Field\FieldWidget;

use Drupal\Core\Field\Attribute\FieldWidget;
use Drupal\Core\Field\FieldItemListInterface;
use Drupal\Core\Field\WidgetBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[FieldWidget(
  id: 'my_module_rating_widget',
  label: new TranslatableMarkup('Rating select'),
  field_types: ['my_module_rating'],
)]
class RatingWidget extends WidgetBase {

  public function formElement(FieldItemListInterface $items, $delta, array $element, array &$form, FormStateInterface $form_state): array {
    $element['value'] = $element + [
      '#type' => 'select',
      '#options' => [1 => '1', 2 => '2', 3 => '3', 4 => '4', 5 => '5'],
      '#default_value' => $items[$delta]->value ?? NULL,
    ];
    return $element;
  }

}
```

## Field Formatter

Location: `src/Plugin/Field/FieldFormatter/`

```php
namespace Drupal\my_module\Plugin\Field\FieldFormatter;

use Drupal\Core\Field\Attribute\FieldFormatter;
use Drupal\Core\Field\FieldItemListInterface;
use Drupal\Core\Field\FormatterBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[FieldFormatter(
  id: 'my_module_rating_formatter',
  label: new TranslatableMarkup('Rating stars'),
  field_types: ['my_module_rating'],
)]
class RatingFormatter extends FormatterBase {

  public function viewElements(FieldItemListInterface $items, $langcode): array {
    $elements = [];
    foreach ($items as $delta => $item) {
      $elements[$delta] = [
        '#markup' => str_repeat('★', $item->value) . str_repeat('☆', 5 - $item->value),
      ];
    }
    return $elements;
  }

}
```

## QueueWorker

Location: `src/Plugin/QueueWorker/`

```php
namespace Drupal\my_module\Plugin\QueueWorker;

use Drupal\Core\Queue\Attribute\QueueWorker;
use Drupal\Core\Queue\QueueWorkerBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[QueueWorker(
  id: 'my_module_email_queue',
  title: new TranslatableMarkup('Email queue processor'),
  cron: ['time' => 60],
)]
class EmailQueueWorker extends QueueWorkerBase {

  public function processItem($data): void {
    // Process one queue item. Throw exception to requeue.
    \Drupal::service('plugin.manager.mail')
      ->mail('my_module', 'notice', $data['to'], 'en', $data);
  }

}
```

## Action

Location: `src/Plugin/Action/`

```php
namespace Drupal\my_module\Plugin\Action;

use Drupal\Core\Action\Attribute\Action;
use Drupal\Core\Action\ActionBase;
use Drupal\Core\Session\AccountInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Action(
  id: 'my_module_publish_action',
  label: new TranslatableMarkup('Publish selected content'),
  type: 'node',
)]
class PublishAction extends ActionBase {

  public function execute($entity = NULL): void {
    $entity->setPublished()->save();
  }

  public function access($object, ?AccountInterface $account = NULL, $return_as_object = FALSE) {
    return $object->access('update', $account, $return_as_object);
  }

}
```

## Condition

Location: `src/Plugin/Condition/`

```php
namespace Drupal\my_module\Plugin\Condition;

use Drupal\Core\Condition\Attribute\Condition;
use Drupal\Core\Condition\ConditionPluginBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[Condition(
  id: 'my_module_time_range',
  label: new TranslatableMarkup('Time range'),
)]
class TimeRangeCondition extends ConditionPluginBase {

  public function buildConfigurationForm(array $form, FormStateInterface $form_state): array {
    $form['start_hour'] = [
      '#type' => 'number',
      '#title' => $this->t('Start hour'),
      '#default_value' => $this->configuration['start_hour'] ?? 9,
      '#min' => 0, '#max' => 23,
    ];
    return parent::buildConfigurationForm($form, $form_state);
  }

  public function evaluate(): bool {
    $hour = (int) date('G');
    return $hour >= ($this->configuration['start_hour'] ?? 0);
  }

  public function summary(): TranslatableMarkup {
    return $this->t('Active after @hour:00', ['@hour' => $this->configuration['start_hour']]);
  }

}
```

## Constraint (Validation)

Location: `src/Plugin/Validation/Constraint/`

```php
// Constraint definition.
namespace Drupal\my_module\Plugin\Validation\Constraint;

use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\Core\Validation\Attribute\Constraint;
use Symfony\Component\Validator\Constraint as SymfonyConstraint;

#[Constraint(
  id: 'UniqueTitle',
  label: new TranslatableMarkup('Unique title'),
)]
class UniqueTitleConstraint extends SymfonyConstraint {
  public string $message = 'A node with title %title already exists.';
}

// Validator (same directory).
namespace Drupal\my_module\Plugin\Validation\Constraint;

use Symfony\Component\Validator\Constraint;
use Symfony\Component\Validator\ConstraintValidator;

class UniqueTitleConstraintValidator extends ConstraintValidator {

  public function validate(mixed $value, Constraint $constraint): void {
    /** @var \Drupal\Core\Entity\ContentEntityInterface $entity */
    $entity = $value->getEntity();
    // Run query, add violation if duplicate found.
    $this->context->addViolation($constraint->message, ['%title' => $entity->label()]);
  }

}
```

## Plugin Derivatives

Derivatives allow one plugin class to provide multiple plugin instances dynamically.

```php
// In the plugin attribute, add a deriver:
#[Block(
  id: 'my_module_per_vocab',
  admin_label: new TranslatableMarkup('Vocabulary block'),
  deriver: \Drupal\my_module\Plugin\Derivative\VocabularyBlockDeriver::class,
)]

// src/Plugin/Derivative/VocabularyBlockDeriver.php
namespace Drupal\my_module\Plugin\Derivative;

use Drupal\Component\Plugin\Derivative\DeriverBase;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Plugin\Discovery\ContainerDeriverInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class VocabularyBlockDeriver extends DeriverBase implements ContainerDeriverInterface {

  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public static function create(ContainerInterface $container, $base_plugin_id): static {
    return new static($container->get('entity_type.manager'));
  }

  public function getDerivativeDefinitions($base_plugin_definition): array {
    $vocabs = $this->entityTypeManager->getStorage('taxonomy_vocabulary')->loadMultiple();
    foreach ($vocabs as $id => $vocab) {
      $this->derivatives[$id] = $base_plugin_definition;
      $this->derivatives[$id]['admin_label'] = $vocab->label();
    }
    return $this->derivatives;
  }

}
```

## Creating a Custom Plugin Type

1. Define the plugin manager as a service:

```yaml
services:
  plugin.manager.my_module_chart:
    class: Drupal\my_module\ChartPluginManager
    parent: default_plugin_manager
```

2. Create the attribute, interface, base class, and manager:

```php
// src/Attribute/Chart.php
namespace Drupal\my_module\Attribute;

use Drupal\Component\Plugin\Attribute\Plugin;

#[\Attribute(\Attribute::TARGET_CLASS)]
class Chart extends Plugin {
  public function __construct(
    public readonly string $id,
    public readonly string $label,
    public readonly string $chart_type = 'bar',
  ) {}
}

// src/ChartPluginInterface.php
namespace Drupal\my_module;

interface ChartPluginInterface {
  public function render(array $data): array;
}

// src/ChartPluginBase.php
namespace Drupal\my_module;

use Drupal\Core\Plugin\PluginBase;

abstract class ChartPluginBase extends PluginBase implements ChartPluginInterface {}

// src/ChartPluginManager.php
namespace Drupal\my_module;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Extension\ModuleHandlerInterface;
use Drupal\Core\Plugin\DefaultPluginManager;
use Drupal\my_module\Attribute\Chart;

class ChartPluginManager extends DefaultPluginManager {

  public function __construct(
    \Traversable $namespaces,
    CacheBackendInterface $cache_backend,
    ModuleHandlerInterface $module_handler,
  ) {
    parent::__construct(
      'Plugin/Chart',
      $namespaces,
      $module_handler,
      ChartPluginInterface::class,
      Chart::class,
    );
    $this->setCacheBackend($cache_backend, 'my_module_chart_plugins');
  }

}
```

Plugins are then placed in `src/Plugin/Chart/` in any module.
