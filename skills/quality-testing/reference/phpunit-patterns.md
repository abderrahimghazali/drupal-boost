# PHPUnit Test Patterns for Drupal 11

## Unit Test Patterns

Unit tests extend `UnitTestCase`. No Drupal bootstrap. Use mocks for all dependencies.

```php
namespace Drupal\Tests\my_module\Unit;

use Drupal\my_module\Service\PriceCalculator;
use Drupal\Tests\UnitTestCase;

class PriceCalculatorTest extends UnitTestCase {

  protected PriceCalculator $calculator;

  protected function setUp(): void {
    parent::setUp();
    $this->calculator = new PriceCalculator();
  }

  public function testCalculateDiscount(): void {
    $result = $this->calculator->applyDiscount(100, 15);
    $this->assertEquals(85.0, $result);
  }

}
```

### Mocking Services

```php
public function testServiceWithDependency(): void {
  $entityStorage = $this->createMock(EntityStorageInterface::class);
  $entityStorage->method('load')->willReturn($this->createMock(NodeInterface::class));

  $entityTypeManager = $this->createMock(EntityTypeManagerInterface::class);
  $entityTypeManager->method('getStorage')->with('node')->willReturn($entityStorage);

  $service = new MyService($entityTypeManager);
  $this->assertTrue($service->nodeExists('1'));
}
```

### Mocking the String Translation Trait

```php
protected function setUp(): void {
  parent::setUp();
  $this->service = new MyService();
  $this->service->setStringTranslation($this->getStringTranslationStub());
}
```

## Kernel Test Patterns

Kernel tests extend `KernelTestBase`. They boot a minimal Drupal kernel with only the modules you specify.

```php
namespace Drupal\Tests\my_module\Kernel;

use Drupal\KernelTests\KernelTestBase;

class MyServiceKernelTest extends KernelTestBase {

  protected static $modules = ['system', 'user', 'node', 'field', 'text', 'my_module'];

  protected function setUp(): void {
    parent::setUp();
    $this->installEntitySchema('user');
    $this->installEntitySchema('node');
    $this->installConfig(['system', 'node', 'my_module']);
    // Install specific schemas if needed.
    $this->installSchema('node', ['node_access']);
  }

  public function testServiceFromContainer(): void {
    $service = \Drupal::service('my_module.my_service');
    $this->assertInstanceOf(MyService::class, $service);
  }

}
```

### Testing Entities in Kernel Tests

```php
use Drupal\node\Entity\Node;
use Drupal\node\Entity\NodeType;

protected function setUp(): void {
  parent::setUp();
  $this->installEntitySchema('user');
  $this->installEntitySchema('node');
  $this->installSchema('node', ['node_access']);

  NodeType::create(['type' => 'article', 'name' => 'Article'])->save();
}

public function testNodeCreation(): void {
  $node = Node::create([
    'type' => 'article',
    'title' => 'Test article',
  ]);
  $node->save();

  $loaded = Node::load($node->id());
  $this->assertEquals('Test article', $loaded->label());
}
```

## Functional Test Patterns

Functional tests extend `BrowserTestBase`. Full Drupal install with a real browser client (no JavaScript).

```php
namespace Drupal\Tests\my_module\Functional;

use Drupal\Tests\BrowserTestBase;

class MyModulePageTest extends BrowserTestBase {

  protected static $modules = ['my_module', 'node'];
  protected $defaultTheme = 'stark';

  public function testAdminPageAccess(): void {
    $admin = $this->drupalCreateUser(['access administration pages', 'administer my_module']);
    $this->drupalLogin($admin);

    $this->drupalGet('/admin/config/my-module/settings');
    $this->assertSession()->statusCodeEquals(200);
    $this->assertSession()->pageTextContains('My Module Settings');
  }

  public function testFormSubmission(): void {
    $admin = $this->drupalCreateUser(['administer my_module']);
    $this->drupalLogin($admin);

    $this->drupalGet('/admin/config/my-module/settings');
    $this->submitForm([
      'api_key' => 'test-key-123',
      'enabled' => TRUE,
    ], 'Save configuration');

    $this->assertSession()->pageTextContains('The configuration options have been saved.');
    $this->assertEquals('test-key-123', \Drupal::config('my_module.settings')->get('api_key'));
  }

  public function testAnonymousAccessDenied(): void {
    $this->drupalGet('/admin/config/my-module/settings');
    $this->assertSession()->statusCodeEquals(403);
  }

}
```

## FunctionalJavascript Test Patterns

Extend `WebDriverTestBase` for tests requiring JavaScript (AJAX, dynamic UI).

```php
namespace Drupal\Tests\my_module\FunctionalJavascript;

use Drupal\FunctionalJavascriptTests\WebDriverTestBase;

class MyModuleJsTest extends WebDriverTestBase {

  protected static $modules = ['my_module', 'node'];
  protected $defaultTheme = 'stark';

  public function testAjaxFormBehavior(): void {
    $admin = $this->drupalCreateUser(['administer my_module']);
    $this->drupalLogin($admin);

    $this->drupalGet('/admin/config/my-module/settings');
    $page = $this->getSession()->getPage();

    $page->selectFieldOption('region', 'us-east');
    $this->assertSession()->assertWaitOnAjaxRequest();

    // Assert that AJAX-loaded content appears.
    $this->assertSession()->pageTextContains('US East endpoints loaded');
  }

  public function testModalDialog(): void {
    $this->drupalGet('/admin/content');
    $page = $this->getSession()->getPage();

    $page->clickLink('Add content');
    $this->assertSession()->waitForElementVisible('css', '.ui-dialog');
    $this->assertSession()->elementTextContains('css', '.ui-dialog-title', 'Add content');
  }

}
```

### Wait Conditions

```php
// Wait for AJAX.
$this->assertSession()->assertWaitOnAjaxRequest();

// Wait for element to be visible.
$this->assertSession()->waitForElementVisible('css', '.my-element', 5000);

// Wait for text.
$this->assertSession()->waitForText('Success');

// Wait for element to be removed.
$this->assertSession()->waitForElementRemoved('css', '.loading-spinner');

// Custom wait with callback.
$result = $this->getSession()->getPage()->waitFor(10, function ($page) {
  return $page->find('css', '.dynamic-content');
});
```

## Common Assertions and Helpers

```php
// HTTP status.
$this->assertSession()->statusCodeEquals(200);

// Page content.
$this->assertSession()->pageTextContains('Expected text');
$this->assertSession()->pageTextNotContains('Unexpected text');

// Elements.
$this->assertSession()->elementExists('css', '.my-class');
$this->assertSession()->elementNotExists('css', '.should-not-exist');
$this->assertSession()->fieldValueEquals('title[0][value]', 'My Title');
$this->assertSession()->checkboxChecked('status[value]');

// Links and buttons.
$this->assertSession()->linkExists('View');
$this->assertSession()->buttonExists('Save');

// Response headers.
$this->assertSession()->responseHeaderContains('Content-Type', 'text/html');

// Count elements.
$this->assertSession()->elementsCount('css', '.item', 5);
```

## Useful Test Traits

```php
use Drupal\Tests\node\Traits\NodeCreationTrait;       // createNode()
use Drupal\Tests\user\Traits\UserCreationTrait;        // createUser(), drupalLogin()
use Drupal\Tests\taxonomy\Traits\TaxonomyTestTrait;    // createVocabulary(), createTerm()
use Drupal\Tests\media\Traits\MediaTypeCreationTrait;   // createMediaType()
use Drupal\Tests\field\Traits\EntityReferenceFieldCreationTrait; // createEntityReferenceField()
```

## Running Tests

```bash
# Run a specific test class.
ddev exec vendor/bin/phpunit -c web/core/phpunit.xml.dist web/modules/custom/my_module/tests/src/Unit/PriceCalculatorTest.php

# Run a specific method.
ddev exec vendor/bin/phpunit --filter=testCalculateDiscount

# Run a test suite.
ddev exec vendor/bin/phpunit --testsuite=unit

# Run with verbose output.
ddev exec vendor/bin/phpunit -v --debug
```
