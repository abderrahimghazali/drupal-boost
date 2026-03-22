---
name: quality-testing
description: Drupal code quality and testing with PHPStan, Drupal Check, PHP CodeSniffer (Drupal coding standards), PHPUnit (unit/kernel/functional/browser tests), Nightwatch.js, and Rector. Use when writing tests, checking code quality, or setting up CI quality gates.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Drupal Quality & Testing

## PHPUnit Test Types

### Unit Tests
- Location: `tests/src/Unit/`
- Extend: `Drupal\Tests\UnitTestCase`
- No Drupal bootstrap, no database
- Mock all dependencies with `$this->createMock()` or Prophecy

```php
namespace Drupal\Tests\MODULE_NAME\Unit;

use Drupal\Tests\UnitTestCase;

class MyServiceTest extends UnitTestCase {

  public function testSomething(): void {
    $mock = $this->createMock(SomeInterface::class);
    $mock->method('getValue')->willReturn('test');
    $service = new MyService($mock);
    $this->assertEquals('expected', $service->process());
  }

}
```

### Kernel Tests
- Location: `tests/src/Kernel/`
- Extend: `Drupal\KernelTests\KernelTestBase`
- Minimal bootstrap with database and services

```php
namespace Drupal\Tests\MODULE_NAME\Kernel;

use Drupal\KernelTests\KernelTestBase;

class MyServiceKernelTest extends KernelTestBase {

  protected static $modules = ['system', 'user', 'node', 'MODULE_NAME'];

  protected function setUp(): void {
    parent::setUp();
    $this->installEntitySchema('user');
    $this->installEntitySchema('node');
    $this->installConfig(['system', 'MODULE_NAME']);
  }

  public function testServiceIntegration(): void {
    $service = $this->container->get('MODULE_NAME.my_service');
    $this->assertNotNull($service);
  }

}
```

### Functional Tests
- Location: `tests/src/Functional/`
- Extend: `Drupal\Tests\BrowserTestBase`
- Full Drupal install, simulated browser

```php
namespace Drupal\Tests\MODULE_NAME\Functional;

use Drupal\Tests\BrowserTestBase;

class MyPageTest extends BrowserTestBase {

  protected static $modules = ['MODULE_NAME'];
  protected $defaultTheme = 'stark';

  public function testPageAccess(): void {
    $user = $this->drupalCreateUser(['access content']);
    $this->drupalLogin($user);
    $this->drupalGet('/my-page');
    $this->assertSession()->statusCodeEquals(200);
    $this->assertSession()->pageTextContains('Expected text');
  }

}
```

## Running Tests

```bash
# Single test file
ddev exec ./vendor/bin/phpunit -c web/core web/modules/custom/MODULE/tests/src/Unit/MyTest.php

# By group
ddev exec ./vendor/bin/phpunit -c web/core --group MODULE_NAME

# By test type directory
ddev exec ./vendor/bin/phpunit -c web/core web/modules/custom/MODULE/tests/src/Kernel/

# With filter
ddev exec ./vendor/bin/phpunit -c web/core --filter testMethodName
```

## PHPStan

```bash
# Run analysis
ddev exec ./vendor/bin/phpstan analyse web/modules/custom/MODULE --level=6

# Generate baseline (accept existing issues)
ddev exec ./vendor/bin/phpstan analyse web/modules/custom/MODULE --generate-baseline

# With Drupal extension (phpstan.neon)
```

### phpstan.neon configuration
```neon
includes:
  - vendor/mglaman/phpstan-drupal/extension.neon
  - vendor/phpstan/phpstan-deprecation-rules/rules.neon
parameters:
  level: 6
  paths:
    - web/modules/custom
  drupal:
    drupal_root: web
```

## PHP CodeSniffer

```bash
# Check
ddev exec ./vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/custom/MODULE

# Auto-fix
ddev exec ./vendor/bin/phpcbf --standard=Drupal,DrupalPractice web/modules/custom/MODULE
```

## Rector (Automated Deprecation Fixes)

```bash
# Preview changes
ddev exec ./vendor/bin/rector process web/modules/custom/MODULE --dry-run

# Apply changes
ddev exec ./vendor/bin/rector process web/modules/custom/MODULE
```

## Key Rules

- Write Unit tests for pure logic, Kernel tests for service integration, Functional tests for user-facing behavior
- Always set `protected $defaultTheme = 'stark';` in Functional tests
- Always declare `$modules` array with ALL required modules
- Install entity schemas and config in `setUp()` for Kernel tests
- Use `->accessCheck(TRUE)` in test entity queries too
- Run PHPCS and PHPStan in CI — fail the build on violations
- Use PHPStan baseline to avoid blocking on legacy issues

Read reference files for details:
- `reference/phpunit-patterns.md` for test patterns
- `reference/phpstan-config.md` for PHPStan setup
- `reference/rector-rules.md` for Rector configuration
