# Drupal 11 Service & Dependency Injection Patterns

## services.yml Syntax

Service definitions live in `my_module.services.yml` at the module root.

```yaml
services:
  # Basic service
  my_module.example:
    class: Drupal\my_module\ExampleService
    arguments: ['@entity_type.manager', '@current_user']

  # Autowired service (Drupal 11 preferred)
  my_module.autowired:
    class: Drupal\my_module\AutowiredService
    autowire: true

  # Factory-created service
  my_module.logger:
    class: Psr\Log\LoggerInterface
    factory: ['@logger.factory', 'get']
    arguments: ['my_module']

  # Tagged service
  my_module.event_subscriber:
    class: Drupal\my_module\EventSubscriber\MySubscriber
    arguments: ['@current_user']
    tags:
      - { name: event_subscriber }

  # Service decorator
  my_module.decorated_mailer:
    class: Drupal\my_module\DecoratedMailer
    decorates: plugin.manager.mail
    arguments: ['@my_module.decorated_mailer.inner']

  # Alias
  my_module.alias:
    alias: my_module.example
```

## Autowire

Drupal 11 supports Symfony autowiring. The container resolves constructor arguments by type-hint automatically.

```yaml
services:
  my_module.report_generator:
    class: Drupal\my_module\ReportGenerator
    autowire: true
```

```php
namespace Drupal\my_module;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Session\AccountProxyInterface;

class ReportGenerator {

  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
    protected readonly AccountProxyInterface $currentUser,
  ) {}

}
```

## ContainerInjectionInterface (Controllers, Forms)

Controllers and form classes use `ContainerInjectionInterface` to inject services.

```php
namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ReportController extends ControllerBase {

  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('entity_type.manager'),
    );
  }

  public function list(): array {
    $nodes = $this->entityTypeManager->getStorage('node')->loadMultiple();
    return ['#markup' => 'Report'];
  }

}
```

`ControllerBase` already extends `ContainerInjectionInterface` and provides shortcut methods like `$this->entityTypeManager()`, `$this->currentUser()`.

## ContainerFactoryPluginInterface (Plugins)

Plugins use `ContainerFactoryPluginInterface` for DI since they receive additional constructor arguments (`$configuration`, `$plugin_id`, `$plugin_definition`).

```php
namespace Drupal\my_module\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

#[\Drupal\Core\Block\Attribute\Block(
  id: 'my_module_greeting',
  admin_label: new \Drupal\Core\StringTranslation\TranslatableMarkup('Greeting Block'),
)]
class GreetingBlock extends BlockBase implements ContainerFactoryPluginInterface {

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    protected readonly AccountProxyInterface $currentUser,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition): static {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_user'),
    );
  }

  public function build(): array {
    return ['#markup' => 'Hello, ' . $this->currentUser->getDisplayName()];
  }

}
```

## Tagged Services

Common tags and their purpose:

| Tag | Purpose |
|-----|---------|
| `event_subscriber` | Symfony event subscriber |
| `breadcrumb_builder` | Custom breadcrumb builder (use `priority` key) |
| `route_enhancer` | Alter route defaults |
| `access_check` | Custom route access checker |
| `theme_negotiator` | Dynamic theme switching |
| `path_processor_inbound` | Inbound path processing |
| `path_processor_outbound` | Outbound URL processing |
| `cache.context` | Custom cache context |

Event subscriber example:

```php
namespace Drupal\my_module\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class MySubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
    ];
  }

  public function onRequest(RequestEvent $event): void {
    // Handle request.
  }

}
```

## Service Decoration & Alteration

Decoration wraps an existing service:

```yaml
services:
  my_module.custom_access:
    class: Drupal\my_module\CustomEntityAccess
    decorates: node.grant_storage
    arguments: ['@my_module.custom_access.inner']
```

For broader alterations, implement `ServiceModifierInterface` or use a `ServiceProvider`:

```php
// src/MyModuleServiceProvider.php
namespace Drupal\my_module;

use Drupal\Core\DependencyInjection\ContainerBuilder;
use Drupal\Core\DependencyInjection\ServiceProviderBase;

class MyModuleServiceProvider extends ServiceProviderBase {

  public function alter(ContainerBuilder $container): void {
    if ($container->hasDefinition('some.service')) {
      $definition = $container->getDefinition('some.service');
      $definition->setClass(MyOverriddenService::class);
    }
  }

}
```

The file must be named `{ModuleName}ServiceProvider.php` in the module `src/` directory (CamelCase of the module name).

## Common Core Services

| Service ID | Interface / Class | Purpose |
|---|---|---|
| `entity_type.manager` | `EntityTypeManagerInterface` | Load entity storage, definitions |
| `current_user` | `AccountProxyInterface` | Current logged-in user |
| `database` | `Connection` | Database connection |
| `logger.factory` | `LoggerChannelFactoryInterface` | Create logger channels |
| `messenger` | `MessengerInterface` | Status/error messages |
| `config.factory` | `ConfigFactoryInterface` | Read/write config |
| `state` | `StateInterface` | Key-value state storage |
| `module_handler` | `ModuleHandlerInterface` | Module info and hook invocation |
| `event_dispatcher` | `EventDispatcherInterface` | Dispatch Symfony events |
| `cache.default` | `CacheBackendInterface` | Default cache bin |
| `language_manager` | `LanguageManagerInterface` | Language negotiation |
| `path.current` | `CurrentPathStack` | Current request path |
| `request_stack` | `RequestStack` | Symfony request stack |
| `file_system` | `FileSystemInterface` | File operations |
| `token` | `Token` | Token replacement |
| `renderer` | `RendererInterface` | Render arrays to markup |
| `string_translation` | `TranslationInterface` | String translation |
| `typed_data_manager` | `TypedDataManagerInterface` | Typed data handling |
| `plugin.manager.block` | `BlockManagerInterface` | Block plugin manager |
| `datetime.time` | `TimeInterface` | Current time (use instead of `time()`) |
| `uuid` | `UuidInterface` | UUID generation |
