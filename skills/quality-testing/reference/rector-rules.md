# Rector for Drupal 11

## rector.php Configuration

Create `rector.php` in the project root:

```php
<?php

declare(strict_types=1);

use DrupalRector\Set\Drupal10SetList;
use DrupalRector\Set\Drupal11SetList;
use Rector\Config\RectorConfig;

return RectorConfig::configure()
  ->withPaths([
    __DIR__ . '/web/modules/custom',
    __DIR__ . '/web/themes/custom',
  ])
  ->withSkip([
    __DIR__ . '/web/modules/custom/*/tests',
    __DIR__ . '/web/themes/custom/*/node_modules',
  ])
  ->withSets([
    Drupal10SetList::DRUPAL_10,
    Drupal11SetList::DRUPAL_11,
  ]);
```

Install dependencies:

```bash
composer require --dev palantirnet/drupal-rector
```

## drupal-rector Rules

The `palantirnet/drupal-rector` package provides Rector rules for Drupal deprecation fixes. Rule sets are organized by Drupal version:

### Drupal 10 deprecation fixes

```php
use DrupalRector\Set\Drupal10SetList;

->withSets([
  Drupal10SetList::DRUPAL_10,
])
```

### Drupal 11 deprecation fixes

```php
use DrupalRector\Set\Drupal11SetList;

->withSets([
  Drupal11SetList::DRUPAL_11,
])
```

### Combining sets for upgrade path

When preparing a module for Drupal 11 compatibility:

```php
->withSets([
  Drupal10SetList::DRUPAL_10,
  Drupal11SetList::DRUPAL_11,
])
```

## Running with --dry-run

Always preview changes before applying:

```bash
# Preview changes without modifying files.
vendor/bin/rector process --dry-run

# Preview for a specific path.
vendor/bin/rector process web/modules/custom/my_module --dry-run

# Apply changes.
vendor/bin/rector process

# Apply to a specific path.
vendor/bin/rector process web/modules/custom/my_module
```

The dry-run output shows a diff of proposed changes:

```diff
 // web/modules/custom/my_module/src/Controller/MyController.php
-  $url = Url::fromRoute('entity.node.canonical', ['node' => $nid])->toString();
-  $rendered = \Drupal::service('renderer')->renderPlain($build);
+  $url = Url::fromRoute('entity.node.canonical', ['node' => $nid])->toString();
+  $rendered = \Drupal::service('renderer')->renderInIsolation($build);
```

## Common Deprecation Fixes

### Drupal 10 Deprecations

**`\Drupal\Component\Utility\Unicode::strlen()` replaced by `mb_strlen()`:**

```php
// Before
$length = Unicode::strlen($string);
// After
$length = mb_strlen($string);
```

**`\Drupal\Component\Utility\SafeMarkup::checkPlain()` replaced by `Html::escape()`:**

```php
// Before
$safe = SafeMarkup::checkPlain($text);
// After
$safe = Html::escape($text);
```

**Entity query `accessCheck()` now required:**

```php
// Before (triggers deprecation)
$nids = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->execute();
// After
$nids = \Drupal::entityQuery('node')
  ->condition('type', 'article')
  ->accessCheck(TRUE)
  ->execute();
```

### Drupal 11 Deprecations

**`\Drupal\Core\Render\RendererInterface::renderPlain()` renamed:**

```php
// Before
$output = $renderer->renderPlain($build);
// After
$output = $renderer->renderInIsolation($build);
```

**`\Drupal\Core\Extension\ModuleHandler::getModule()` returns `Extension`:**

```php
// Before
$path = drupal_get_path('module', 'my_module');
// After (already changed in D10, enforced in D11)
$path = \Drupal::service('extension.list.module')->getPath('my_module');
```

**Hook implementations moving to classes (Drupal 11.1+):**

```php
// Before: my_module.module
function my_module_form_alter(&$form, FormStateInterface $form_state, $form_id) { }

// After: src/Hook/MyModuleHooks.php
namespace Drupal\my_module\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class MyModuleHooks {

  #[Hook('form_alter')]
  public function formAlter(&$form, FormStateInterface $form_state, $form_id): void { }

}
```

## Custom Rule Configuration

### Skip specific rules

```php
return RectorConfig::configure()
  ->withPaths([__DIR__ . '/web/modules/custom'])
  ->withSets([Drupal11SetList::DRUPAL_11])
  ->withSkip([
    // Skip a specific rule entirely.
    \DrupalRector\Rector\Deprecation\FunctionToServiceRector::class,
    // Skip a rule for specific files.
    \DrupalRector\Rector\Deprecation\EntityQueryAccessCheckRector::class => [
      __DIR__ . '/web/modules/custom/legacy_module/*',
    ],
  ]);
```

### Add general PHP upgrade rules

Combine Drupal rules with PHP-level upgrades:

```php
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

return RectorConfig::configure()
  ->withPaths([__DIR__ . '/web/modules/custom'])
  ->withSets([
    Drupal11SetList::DRUPAL_11,
    LevelSetList::UP_TO_PHP_83,
    SetList::CODE_QUALITY,
    SetList::DEAD_CODE,
    SetList::TYPE_DECLARATION,
  ]);
```

### Configure specific rules

```php
use Rector\DeadCode\Rector\ClassMethod\RemoveUnusedPrivateMethodRector;
use Rector\TypeDeclaration\Rector\ClassMethod\ReturnTypeFromReturnNewRector;

return RectorConfig::configure()
  ->withPaths([__DIR__ . '/web/modules/custom'])
  ->withRules([
    RemoveUnusedPrivateMethodRector::class,
    ReturnTypeFromReturnNewRector::class,
  ]);
```

## CI Integration

Run Rector in CI to catch regressions:

```yaml
# .github/workflows/rector.yml
- name: Check for deprecations
  run: vendor/bin/rector process --dry-run --no-progress-bar
```

If Rector finds changes needed in `--dry-run`, the exit code is non-zero, failing the CI check.

## Workflow Recommendation

1. Run `--dry-run` first to review all proposed changes.
2. Commit current state so you have a clean diff.
3. Run `vendor/bin/rector process` to apply changes.
4. Review the diff carefully; Rector is not infallible.
5. Run tests (`vendor/bin/phpunit`) to verify nothing broke.
6. Run PHPStan to check for type errors introduced by changes.
7. Commit the Rector-applied changes.
