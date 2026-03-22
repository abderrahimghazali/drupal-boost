# PHPStan Configuration for Drupal 11

## phpstan.neon Setup

Create `phpstan.neon` (or `phpstan.neon.dist`) in the project root:

```neon
includes:
  - vendor/mglaman/phpstan-drupal/extension.neon
  - vendor/phpstan/phpstan-deprecation-rules/rules.neon

parameters:
  level: 2
  paths:
    - web/modules/custom
    - web/themes/custom
  excludePaths:
    - web/modules/custom/*/tests/*
    - web/themes/custom/*/node_modules/*
  drupal:
    drupal_root: web
  treatPhpDocTypesAsCertain: false
```

Install dependencies:

```bash
composer require --dev phpstan/phpstan mglaman/phpstan-drupal phpstan/phpstan-deprecation-rules
```

Run PHPStan:

```bash
vendor/bin/phpstan analyse --memory-limit=512M
vendor/bin/phpstan analyse web/modules/custom/my_module
```

## phpstan-drupal Extension

The `mglaman/phpstan-drupal` extension provides Drupal-specific understanding:

- Recognizes `\Drupal::service()` return types
- Understands entity type managers and storage handlers
- Resolves plugin types and their interfaces
- Handles hook implementations
- Recognizes `@var` annotations in `.module` files
- Supports `ContainerInjectionInterface` patterns

Configuration options:

```neon
parameters:
  drupal:
    drupal_root: web
    # Map entity type IDs to their classes for better inference.
    entityMapping:
      node: Drupal\node\Entity\Node
      user: Drupal\user\Entity\User
      taxonomy_term: Drupal\taxonomy\Entity\Term
      media: Drupal\media\Entity\Media
```

## phpstan-deprecation-rules

Detects usage of deprecated Drupal APIs:

```neon
includes:
  - vendor/phpstan/phpstan-deprecation-rules/rules.neon
```

This catches calls to functions and methods marked with `@deprecated`. Essential for Drupal upgrade preparation.

Example output:

```
Call to deprecated method format() of class Drupal\Component\Utility\SafeMarkup.
Use \Drupal\Component\Render\FormattableMarkup instead.
```

## Baseline Management

Generate a baseline to ignore existing errors while enforcing zero new errors:

```bash
vendor/bin/phpstan analyse --generate-baseline
```

This creates `phpstan-baseline.neon`. Include it in your config:

```neon
includes:
  - phpstan-baseline.neon
  - vendor/mglaman/phpstan-drupal/extension.neon
  - vendor/phpstan/phpstan-deprecation-rules/rules.neon
```

Reduce baseline over time by fixing errors and regenerating:

```bash
# Fix some errors, then regenerate.
vendor/bin/phpstan analyse --generate-baseline
```

Use `--generate-baseline` with a specific file name:

```bash
vendor/bin/phpstan analyse --generate-baseline=phpstan-baseline.neon
```

## Level Descriptions and Recommendations

PHPStan levels 0-9 (each includes all checks from lower levels):

| Level | What It Checks |
|-------|---------------|
| 0     | Basic checks: unknown classes, functions, methods called on known classes |
| 1     | Possibly undefined variables, unknown magic methods, properties on `$this` |
| 2     | Unknown methods on all expressions (not just `$this`), validates PHPDocs |
| 3     | Return types verified |
| 4     | Basic dead code checks, always true/false conditions |
| 5     | Argument types of methods and functions |
| 6     | Report missing typehints |
| 7     | Report partially wrong union types |
| 8     | Report nullable types not handled |
| 9     | Strict mixed type checking |

**Recommendations for Drupal:**

- **New projects**: Start at level 5 or 6 with a baseline.
- **Existing projects**: Start at level 2, generate a baseline, increase gradually.
- **Contrib modules**: Level 2 is the commonly accepted minimum.
- **Level 8+**: Practical for new code but generates many false positives with legacy Drupal APIs.

## Common False Positives in Drupal

### Dynamic service calls

```
Parameter #1 ... expects string, string|false given.
```

Suppress with inline comment:

```php
/** @var \Drupal\my_module\Service\MyService $service */
$service = \Drupal::service('my_module.my_service');
```

### Entity field access

PHPStan may not understand entity field magic methods:

```php
// Error: Access to an undefined property Drupal\node\Entity\Node::$field_custom
$value = $node->field_custom->value;
```

Fix with `get()` method or inline annotation:

```php
$value = $node->get('field_custom')->value;
```

### Plugin constructors

Drupal plugins receive variable constructor arguments. Suppress false positives:

```neon
parameters:
  ignoreErrors:
    - '#Constructor of class .* has an unused parameter#'
```

### Hook implementations

Hook functions may trigger unused parameter warnings:

```neon
parameters:
  ignoreErrors:
    - '#Function [a-z_]+_(form|preprocess|alter).* has parameter \$.* that is not used#'
```

### Common ignore patterns for Drupal projects

```neon
parameters:
  ignoreErrors:
    # Drupal module file function patterns.
    - '#Function [a-z_]+_preprocess_[a-z_]+ has parameter \$variables with no type specified#'
    # Container not typed in procedural code.
    - '#Variable \$container in PHPDoc tag @var does not match#'
    # Entity storage return type.
    - '#Method .* should return .* but returns Drupal\\Core\\Entity\\EntityStorageInterface#'
```

## CI Integration

Add PHPStan to CI pipeline:

```yaml
# .github/workflows/phpstan.yml
- name: Run PHPStan
  run: vendor/bin/phpstan analyse --no-progress --error-format=github
```

The `--error-format=github` flag produces GitHub-compatible annotations that appear on the PR diff.

For GitLab:

```yaml
phpstan:
  script:
    - vendor/bin/phpstan analyse --no-progress --error-format=gitlab > phpstan-report.json
  artifacts:
    reports:
      codequality: phpstan-report.json
```
