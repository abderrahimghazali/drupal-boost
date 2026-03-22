# Drupal-Specific Twig Reference

## Drupal Twig Filters

### Translation and Rendering

```twig
{# |t — Translate a string. Supports placeholders. #}
{{ 'Welcome back'|t }}
{{ 'Hello @name'|t({'@name': user_name}) }}

{# |render — Forces a render array to render to markup. #}
{{ content.field_body|render }}

{# |placeholder — Wraps the value in an <em> tag for translation emphasis. #}
{{ 'Submitted by @author'|t({'@author': author_name|placeholder}) }}
```

### CSS and HTML Helpers

```twig
{# |clean_class — Converts a string to a valid CSS class name. #}
<div class="node--{{ type|clean_class }}">

{# |clean_id — Converts a string to a valid HTML ID. #}
<div id="block--{{ id|clean_id }}">

{# |safe_join — Joins array items with a separator, preserving safe markup. #}
{{ items|safe_join(', ') }}
```

### Attribute and Field Manipulation

```twig
{# |without — Renders a render array excluding specified child elements. #}
{{ content|without('field_image', 'field_tags') }}

{# |add_class — Adds CSS classes to an Attributes object. #}
{{ attributes.addClass('extra-class') }}

{# |set_attribute — Sets an HTML attribute. #}
{{ attributes.setAttribute('data-id', node.id) }}
```

## Drupal Twig Functions

### URL and Link Generation

```twig
{# url() — Generates an absolute URL from a route name. #}
<a href="{{ url('entity.node.canonical', {'node': node.id}) }}">View</a>

{# path() — Generates a relative path from a route name. #}
<a href="{{ path('view.frontpage.page_1') }}">Home</a>

{# link() — Creates a full <a> element from a URL object and title. #}
{{ link('My Link', url('entity.node.canonical', {'node': 1})) }}

{# file_url() — Converts a relative file URI to a URL. #}
<img src="{{ file_url(node.field_image.entity.uri.value) }}" />
```

### Library and Asset Attachment

```twig
{# attach_library() — Attaches a CSS/JS library to the page. #}
{{ attach_library('my_theme/hero-slider') }}
{{ attach_library('core/drupal.dialog') }}
```

### Utility Functions

```twig
{# create_attribute() — Creates a new Attribute object for custom elements. #}
{% set wrapper_attrs = create_attribute({'class': ['wrapper'], 'id': 'main'}) %}
<div{{ wrapper_attrs }}>

{# active_theme_path() — Returns the path to the active theme. #}
<img src="/{{ active_theme_path() }}/images/logo.svg" />

{# active_theme() — Returns the machine name of the active theme. #}
{% if active_theme() == 'my_theme' %}
```

## Twig Debug Mode Setup

Enable Twig debug to see template suggestions and source comments in HTML output.

In `sites/default/development.services.yml`:

```yaml
parameters:
  twig.config:
    debug: true
    auto_reload: true
    cache: false
```

In `sites/default/settings.local.php`:

```php
$settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
```

After enabling, rebuild the cache: `drush cr`

HTML output will include comments like:

```html
<!-- THEME DEBUG -->
<!-- THEME HOOK: 'node' -->
<!-- FILE NAME SUGGESTIONS:
   * node--article--full.html.twig
   * node--article.html.twig
   * node--1.html.twig
   x node.html.twig
-->
```

## Template Suggestions

Register custom suggestions in `my_theme.theme`:

```php
function my_theme_theme_suggestions_node_alter(array &$suggestions, array $variables) {
  $node = $variables['elements']['#node'];
  // Add suggestion based on a field value.
  if ($node->hasField('field_layout') && !$node->field_layout->isEmpty()) {
    $layout = $node->field_layout->value;
    $suggestions[] = 'node__' . $node->bundle() . '__' . $layout;
  }
}

function my_theme_theme_suggestions_page_alter(array &$suggestions, array $variables) {
  // Add suggestion for node type pages.
  if ($node = \Drupal::routeMatch()->getParameter('node')) {
    $suggestions[] = 'page__node__' . $node->bundle();
  }
}
```

## Theme Hook Suggestions

Common patterns for template naming:

| Hook | Suggestion Pattern | Example File |
|------|-------------------|--------------|
| `node` | `node--{bundle}--{view_mode}` | `node--article--teaser.html.twig` |
| `block` | `block--{plugin_id}` | `block--system-branding-block.html.twig` |
| `field` | `field--{name}--{bundle}` | `field--field-image--article.html.twig` |
| `views-view` | `views-view--{view_id}--{display}` | `views-view--frontpage--page-1.html.twig` |
| `page` | `page--{content_type}` | `page--node--article.html.twig` |

## Preprocess Functions

### Procedural (in .theme file)

```php
function my_theme_preprocess_node(&$variables) {
  $node = $variables['node'];
  $variables['formatted_date'] = \Drupal::service('date.formatter')
    ->format($node->getCreatedTime(), 'medium');
  $variables['has_image'] = !$node->field_image->isEmpty();
}
```

### OOP Preprocess (Drupal 11 — hook attribute)

```php
// src/Hook/NodePreprocess.php
namespace Drupal\my_theme\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class NodePreprocess {

  #[Hook('preprocess_node')]
  public function preprocess(array &$variables): void {
    $node = $variables['node'];
    $variables['reading_time'] = ceil(str_word_count(strip_tags($node->body->value ?? '')) / 200);
  }

}
```

Register the namespace in `my_theme.info.yml` (Drupal 11.1+):

```yaml
hooks:
  path: src/Hook
```

### Common Variables Available in Preprocess

| Variable | Available In | Description |
|----------|-------------|-------------|
| `$variables['node']` | `preprocess_node` | The full node entity |
| `$variables['content']` | `preprocess_node` | Render array of all fields |
| `$variables['elements']` | Most hooks | Raw render elements |
| `$variables['attributes']` | All templates | HTML attributes object |
| `$variables['title_attributes']` | Node, block | Title element attributes |
| `$variables['logged_in']` | All templates | Whether user is authenticated |
| `$variables['is_admin']` | Page-level | Whether user has admin role |
