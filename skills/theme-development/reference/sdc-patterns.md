# Advanced Single Directory Component (SDC) Patterns

## component.yml Schema

Every SDC lives in its own directory under `components/` and requires a `component_name.component.yml` file.

```yaml
# components/my_card/my_card.component.yml
name: My Card
description: A reusable card component with image and body.
status: stable  # stable | experimental | deprecated | obsolete

props:
  type: object
  required:
    - heading
  properties:
    heading:
      type: string
      title: Card heading
      description: The main heading text.
    variant:
      type: string
      title: Style variant
      enum: ['default', 'highlighted', 'compact']
      default: 'default'
    image_url:
      type: string
      format: uri
      title: Image URL
    count:
      type: integer
      minimum: 0
      maximum: 100
    is_featured:
      type: boolean
      default: false
    tags:
      type: array
      items:
        type: string

slots:
  body:
    title: Card body
    description: The main content area of the card.
  footer:
    title: Card footer

libraryOverrides:
  css:
    component:
      css/my-card.css: {}
  js:
    js/my-card.js: {}
  dependencies:
    - core/drupal
    - core/once

# Declare other SDCs this component depends on
libraryDependencies:
  - 'core:sdc--my_theme--icon'
```

### Supported Prop Types

| Type | JSON Schema Keywords |
|------|---------------------|
| `string` | `enum`, `default`, `format` (uri, date, email), `minLength`, `maxLength` |
| `integer` / `number` | `minimum`, `maximum`, `default` |
| `boolean` | `default` |
| `array` | `items`, `minItems`, `maxItems` |
| `object` | `properties`, `required` |

## Nested Components (Embedding SDCs Inside SDCs)

Use the `include` function with the SDC namespace to embed components.

```twig
{# components/my_card/my_card.twig #}
<article class="card card--{{ variant }}">
  {% include 'my_theme:icon' with { name: 'star', size: 'sm' } only %}
  <h3>{{ heading }}</h3>
  <div class="card__body">
    {% block body %}{% endblock %}
  </div>
  <footer>
    {% block footer %}{% endblock %}
  </footer>
</article>
```

To nest an SDC that itself has slots, use `embed`:

```twig
{# In a parent template or another SDC #}
{% embed 'my_theme:my_card' with { heading: 'Hello', variant: 'highlighted' } %}
  {% block body %}
    <p>This is the card body content.</p>
    {% include 'my_theme:badge' with { label: 'New' } only %}
  {% endblock %}
  {% block footer %}
    <a href="/read-more">Read more</a>
  {% endblock %}
{% endembed %}
```

## Component Variants and Conditional Rendering

Handle variants through props and Twig logic:

```twig
{# components/alert/alert.twig #}
{% set classes = ['alert', 'alert--' ~ (variant ?? 'info')] %}
{% if dismissible %}
  {% set classes = classes|merge(['alert--dismissible']) %}
{% endif %}

<div{{ attributes.addClass(classes) }}>
  {% if icon %}
    {% include 'my_theme:icon' with { name: icon } only %}
  {% endif %}
  <div class="alert__content">{% block content %}{% endblock %}</div>
  {% if dismissible %}
    <button class="alert__close" aria-label="Close">&times;</button>
  {% endif %}
</div>
```

## Props Validation and Default Values

Drupal validates props against the JSON Schema at render time. Invalid props trigger runtime errors in development. Set defaults in YAML and Twig:

```yaml
# In component.yml
props:
  type: object
  properties:
    size:
      type: string
      enum: ['sm', 'md', 'lg']
      default: 'md'
```

```twig
{# Twig-side fallback for safety #}
{% set size = size ?? 'md' %}
```

## Passing Entity Data to SDCs

From a preprocess function or a field formatter, map entity fields to component props:

```php
// In a .theme file or OOP preprocess subscriber
function my_theme_preprocess_node__article(&$variables) {
  $node = $variables['node'];
  $variables['card_props'] = [
    'heading' => $node->getTitle(),
    'image_url' => $node->field_image->entity?->createFileUrl(),
    'variant' => $node->isPromoted() ? 'highlighted' : 'default',
    'is_featured' => $node->isSticky(),
  ];
}
```

```twig
{# node--article.html.twig #}
{% embed 'my_theme:my_card' with card_props %}
  {% block body %}
    {{ content.body }}
  {% endblock %}
{% endembed %}
```

## SDC Discovery and Namespacing

SDCs are discovered automatically from:

- **Themes**: `themes/my_theme/components/<component_name>/`
- **Modules**: `modules/my_module/components/<component_name>/`

The namespace follows the pattern `provider_machine_name:component_machine_name`. For example, a component at `themes/my_theme/components/hero_banner/` is referenced as `my_theme:hero_banner`.

To list all discovered components, use Drush:

```bash
drush sdc:list
drush sdc:list --provider=my_theme
```

Component directories must contain at minimum:
- `component_name.component.yml` (metadata and schema)
- `component_name.twig` (template)

Optional files in the same directory:
- `component_name.css` (auto-attached styles)
- `component_name.js` (auto-attached scripts)
- Subdirectories for assets (`css/`, `js/`, `images/`)

CSS and JS files placed directly alongside the `.twig` file are auto-discovered and attached without needing `libraryOverrides`. Use `libraryOverrides` only when you need custom weight, external dependencies, or non-standard file locations.
