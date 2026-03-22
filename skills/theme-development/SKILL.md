---
name: theme-development
description: Drupal 11 theme development with Single Directory Components (SDC), Starterkit themes, Twig templates, component composition, and CSS/JS libraries. Use when creating a theme, building SDCs, writing Twig templates, or styling Drupal output.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Drupal 11 Theme Development

## Theme Structure

```
themes/custom/THEME_NAME/
├── THEME_NAME.info.yml
├── THEME_NAME.theme                # Preprocess functions
├── THEME_NAME.libraries.yml        # CSS/JS libraries
├── THEME_NAME.breakpoints.yml      # Responsive breakpoints
├── components/                     # Single Directory Components
│   ├── card/
│   │   ├── card.component.yml
│   │   ├── card.twig
│   │   ├── card.css
│   │   └── card.js
│   └── hero/
│       ├── hero.component.yml
│       ├── hero.twig
│       └── hero.css
├── templates/                      # Template overrides
│   ├── layout/
│   ├── node/
│   ├── block/
│   ├── field/
│   └── views/
├── css/                            # Global styles
├── js/                             # Global scripts
└── images/                         # Theme images
```

## Starterkit Theme Generation

```bash
php web/core/scripts/drupal generate-theme my_theme --starterkit starterkit_theme
```

## Single Directory Components (SDC)

### component.yml Schema

```yaml
name: Card
status: stable
description: A card component with image, title, and body
props:
  type: object
  properties:
    title:
      type: string
      title: Card Title
    image_url:
      type: string
      title: Image URL
    variant:
      type: string
      title: Variant
      enum: ['default', 'featured', 'compact']
      default: 'default'
  required:
    - title
slots:
  body:
    title: Card Body
    description: The main content of the card
libraryOverrides:
  css:
    component:
      card.css: {}
  js:
    card.js: {}
  dependencies:
    - core/drupal
```

### SDC Twig Template

```twig
<article class="card card--{{ variant|default('default') }}">
  {% if image_url %}
    <img src="{{ image_url }}" alt="{{ title }}" class="card__image" />
  {% endif %}
  <h3 class="card__title">{{ title }}</h3>
  <div class="card__body">
    {% block body %}{% endblock %}
  </div>
</article>
```

### Using SDCs

```twig
{% include 'THEME_NAME:card' with {
  title: 'My Card',
  image_url: '/path/to/image.jpg',
  variant: 'featured',
} %}

{% embed 'THEME_NAME:card' with { title: 'Custom Body' } %}
  {% block body %}
    <p>Custom content in the body slot.</p>
  {% endblock %}
{% endembed %}
```

## Twig Best Practices

- Auto-escaping is ON by default — use `{{ variable }}` safely
- Use `|raw` only when you are 100% certain content is safe (rare)
- Use `|t` for translatable strings: `{{ 'Hello'|t }}`
- Attach libraries: `{{ attach_library('THEME_NAME/my-library') }}`
- URL generation: `{{ path('entity.node.canonical', {'node': nid}) }}`
- Enable Twig debug in `development.services.yml` for template suggestions

## Libraries

```yaml
# THEME_NAME.libraries.yml
global-styling:
  css:
    theme:
      css/global.css: {}
  js:
    js/global.js: {}
  dependencies:
    - core/drupal
    - core/once
```

Attach in info.yml:
```yaml
libraries:
  - THEME_NAME/global-styling
```

## Key Rules

- Prefer SDCs over traditional template overrides for reusable components
- Always define props in component.yml for type safety
- Use slots for content that varies between usages
- Keep Twig logic minimal — complex logic belongs in preprocess functions
- Never use `|raw` with user-generated content
- Use `{{ attach_library() }}` to load CSS/JS on demand
- Follow BEM naming for CSS classes: `block__element--modifier`

Read reference files for details:
- `reference/sdc-patterns.md` for advanced SDC patterns
- `reference/twig-reference.md` for Drupal Twig functions/filters
- `reference/starterkit-guide.md` for theme generation
