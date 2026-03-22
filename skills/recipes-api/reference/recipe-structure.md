# Recipe Structure Deep Dive

## Complete recipe.yml Schema

```yaml
name: 'My Recipe'
description: 'Sets up a blog with common configuration.'
type: 'Content type'

# Recipes to apply before this one.
recipes:
  - core/recipes/standard
  - core/recipes/editorial_workflow

# Modules to install.
install:
  - node
  - taxonomy
  - path
  - media
  - media_library
  - content_moderation

# Configuration to import (from recipe's config directory).
config:
  # Strict mode: only import config listed here.
  strict: true

  # Import specific config files from recipe's /config directory.
  import:
    # Import all config from a module.
    node: '*'
    # Import specific items.
    taxonomy:
      - taxonomy.vocabulary.tags

  # Config actions to modify existing or imported config.
  actions:
    node.type.article:
      # Simple value override.
      setDescription: 'Blog articles with editorial workflow.'

    user.role.editor:
      grantPermissions:
        - 'create article content'
        - 'edit any article content'
        - 'use editorial_workflow transition create_new_draft'

    system.site:
      simpleConfigUpdate:
        name: 'My Blog'
        slogan: 'Thoughts and ideas'
        page.front: /blog
```

## Config Actions (All Types)

### Simple Config Update

Set values on simple configuration:

```yaml
config:
  actions:
    system.site:
      simpleConfigUpdate:
        name: 'Site Name'
        mail: admin@example.com
        page.front: /home
        page.403: /access-denied
        page.404: /not-found

    system.performance:
      simpleConfigUpdate:
        css.preprocess: true
        js.preprocess: true
        cache.page.max_age: 3600
```

### Grant and Revoke Permissions

```yaml
config:
  actions:
    user.role.content_editor:
      grantPermissions:
        - 'create article content'
        - 'edit own article content'
        - 'edit any article content'
        - 'delete own article content'
        - 'view own unpublished content'
        - 'use editorial_workflow transition create_new_draft'
        - 'use editorial_workflow transition publish'

    user.role.authenticated:
      revokePermissions:
        - 'post comments'
```

### Entity Method Actions

Call entity methods on config entities:

```yaml
config:
  actions:
    # Set the description on a content type.
    node.type.article:
      setDescription: 'Articles for the blog section.'
      setNewRevision: true

    # Set status on a view.
    views.view.content:
      setStatus: true

    # Set weight on a block.
    block.block.olivero_main_menu:
      setWeight: -5
```

### Add to Collections (Multi-Value Fields)

```yaml
config:
  actions:
    # Add formats to a text field.
    field.field.node.article.body:
      addItemToList:
        allowed_formats:
          - full_html
          - basic_html

    # Add fields to a form display.
    core.entity_form_display.node.article.default:
      setComponent:
        field_tags:
          type: entity_reference_autocomplete
          weight: 10
          region: content

    # Add fields to a view display.
    core.entity_view_display.node.article.default:
      setComponent:
        field_tags:
          type: entity_reference_label
          weight: 5
          region: content
          label: above
```

### Create If Not Exists

Config in the recipe's `/config` directory is created only if it does not already exist. Existing config is left untouched unless config actions modify it.

```
my_recipe/
  config/
    node.type.article.yml
    field.storage.node.field_tags.yml
    field.field.node.article.field_tags.yml
    taxonomy.vocabulary.tags.yml
  recipe.yml
```

## Composing Recipes

### Recipe Dependencies

```yaml
# A recipe can depend on other recipes.
recipes:
  # Core recipes.
  - core/recipes/standard
  - core/recipes/editorial_workflow

  # Contrib recipes (installed via Composer).
  - drupal/blog_recipe

  # Local recipes (relative path).
  - ../base_recipe
```

### Layered Recipe Architecture

```
recipes/
  base/
    recipe.yml          # Core modules, base config.
  blog/
    recipe.yml          # Depends on base, adds blog.
    config/
      node.type.article.yml
  full-site/
    recipe.yml          # Depends on base + blog + more.
```

```yaml
# recipes/full-site/recipe.yml
name: 'Full Site Setup'
description: 'Complete site configuration.'
recipes:
  - ../base
  - ../blog
install:
  - search
  - syslog
```

## Testing Recipes

### Kernel Test

```php
namespace Drupal\Tests\my_recipe\Kernel;

use Drupal\Core\Recipe\Recipe;
use Drupal\Core\Recipe\RecipeRunner;
use Drupal\KernelTests\KernelTestBase;

class MyRecipeTest extends KernelTestBase {

  public function testRecipeApplies(): void {
    $recipe = Recipe::createFromDirectory('/path/to/my_recipe');
    RecipeRunner::processRecipe($recipe);

    // Assert modules are installed.
    $this->assertTrue(
      \Drupal::moduleHandler()->moduleExists('node')
    );

    // Assert config was created.
    $type = \Drupal::entityTypeManager()
      ->getStorage('node_type')
      ->load('article');
    $this->assertNotNull($type);
    $this->assertEquals('Article', $type->label());

    // Assert permissions were granted.
    $role = \Drupal::entityTypeManager()
      ->getStorage('user_role')
      ->load('editor');
    $this->assertTrue($role->hasPermission('create article content'));
  }

}
```

### Functional Test

```php
namespace Drupal\Tests\my_recipe\Functional;

use Drupal\Core\Recipe\Recipe;
use Drupal\Core\Recipe\RecipeRunner;
use Drupal\Tests\BrowserTestBase;

class MyRecipeInstallTest extends BrowserTestBase {

  protected $defaultTheme = 'stark';

  public function testRecipeCreatesContentType(): void {
    $recipe = Recipe::createFromDirectory('/path/to/my_recipe');
    RecipeRunner::processRecipe($recipe);

    $admin = $this->drupalCreateUser(['administer content types']);
    $this->drupalLogin($admin);
    $this->drupalGet('/admin/structure/types');
    $this->assertSession()->pageTextContains('Article');
  }

}
```

### Apply recipe via Drush

```bash
drush recipe /path/to/my_recipe
```

## Converting Install Profiles to Recipes

### Key Differences

| Install Profile | Recipe |
|---|---|
| Can only be applied at install time | Can be applied anytime |
| One profile per site | Multiple recipes can be applied |
| Uses `.install` hooks | Uses config actions |
| Tightly coupled to site | Composable and reusable |

### Migration Steps

1. Extract module list from profile's `.info.yml`:

```yaml
# Old profile: myprofile.info.yml
install:
  - node
  - taxonomy
  - views
```

Becomes:

```yaml
# recipe.yml
install:
  - node
  - taxonomy
  - views
```

2. Move config from `config/install/` to recipe's `config/`.

3. Convert `hook_install()` logic to config actions:

```php
// Old: myprofile.install
function myprofile_install() {
  \Drupal::configFactory()->getEditable('system.site')
    ->set('page.front', '/home')
    ->save();

  $role = Role::load('editor');
  $role->grantPermission('create article content');
  $role->save();
}
```

Becomes:

```yaml
# recipe.yml
config:
  actions:
    system.site:
      simpleConfigUpdate:
        page.front: /home
    user.role.editor:
      grantPermissions:
        - 'create article content'
```

4. Content creation from install hooks should move to deploy hooks or a separate migration recipe.

5. Use `core/recipes/standard` as a base recipe to replace Standard install profile dependencies.
