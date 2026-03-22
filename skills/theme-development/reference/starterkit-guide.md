# Starterkit Theme Generation Guide

## Generation Command and Options

Drupal 11 provides a starterkit generator that creates a new theme by cloning and renaming an existing starterkit-flagged theme. The default source is Starterkit (based on Claro/Olivero patterns).

```bash
# Basic generation
php core/scripts/drupal generate-theme my_custom_theme

# Specify a human-readable name
php core/scripts/drupal generate-theme my_custom_theme --name="My Custom Theme"

# Generate into a specific path
php core/scripts/drupal generate-theme my_custom_theme --path=themes/custom

# Use a different source theme (must have `starterkit: true` in its .info.yml)
php core/scripts/drupal generate-theme my_custom_theme --starterkit=other_starterkit

# Full example
php core/scripts/drupal generate-theme my_custom_theme \
  --name="My Custom Theme" \
  --description="A tailored theme for my project." \
  --path=themes/custom
```

## What Gets Generated

The generator produces a complete theme directory with all machine name references replaced:

```
themes/custom/my_custom_theme/
  my_custom_theme.info.yml
  my_custom_theme.libraries.yml
  my_custom_theme.theme
  my_custom_theme.breakpoints.yml
  css/
    base/
      elements.css
    components/
      navigation.css
      header.css
      footer.css
    layouts/
      layout.css
  js/
    scripts.js
  templates/
    layout/
      page.html.twig
    navigation/
      menu.html.twig
    content/
      node.html.twig
  components/
    (SDC component directories if source includes them)
  logo.svg
  screenshot.png
```

The generator performs these transformations:

- Renames all files containing the source machine name.
- Replaces the source machine name in all file contents (PHP, YAML, Twig, CSS, JS).
- Updates the `.info.yml` with the new name, description, and removes `starterkit: true`.
- Preserves the directory structure and any SDC components from the source.

## Customizing the Generated Theme

### info.yml Configuration

After generation, edit `my_custom_theme.info.yml`:

```yaml
name: My Custom Theme
type: theme
description: 'A custom theme for my project.'
core_version_requirement: ^11
base theme: false  # Set to false for fully standalone, or specify a base theme

regions:
  header: Header
  primary_menu: Primary Menu
  secondary_menu: Secondary Menu
  hero: Hero
  breadcrumb: Breadcrumb
  highlighted: Highlighted
  help: Help
  content: Content
  sidebar_first: Sidebar First
  sidebar_second: Sidebar Second
  footer_top: Footer Top
  footer: Footer

libraries:
  - my_custom_theme/global-styling
  - my_custom_theme/global-scripts
```

### Setting a Base Theme

```yaml
# Use Olivero as a base (inherit its templates and styles):
base theme: olivero

# Use Claro as a base (for admin themes):
base theme: claro

# Fully standalone (no inheritance):
base theme: false
```

## Adding Breakpoints

Define responsive breakpoints in `my_custom_theme.breakpoints.yml`:

```yaml
my_custom_theme.mobile:
  label: Mobile
  mediaQuery: ''
  weight: 0
  multipliers:
    - 1x
    - 2x

my_custom_theme.narrow:
  label: Narrow
  mediaQuery: 'all and (min-width: 560px)'
  weight: 1
  multipliers:
    - 1x
    - 2x

my_custom_theme.wide:
  label: Wide
  mediaQuery: 'all and (min-width: 1024px)'
  weight: 2
  multipliers:
    - 1x
    - 2x

my_custom_theme.extra_wide:
  label: Extra Wide
  mediaQuery: 'all and (min-width: 1440px)'
  weight: 3
  multipliers:
    - 1x
    - 2x
```

After adding or changing breakpoints, rebuild the cache: `drush cr`

Breakpoints integrate with the Responsive Image module for art-directed image styles.

## Library Management

### Defining Libraries

In `my_custom_theme.libraries.yml`:

```yaml
global-styling:
  css:
    base:
      css/base/elements.css: {}
    layout:
      css/layouts/layout.css: {}
    component:
      css/components/header.css: {}
      css/components/footer.css: {}
      css/components/navigation.css: {}

global-scripts:
  js:
    js/scripts.js: { attributes: { defer: true } }
  dependencies:
    - core/drupal
    - core/once

hero-slider:
  css:
    component:
      css/components/hero-slider.css: {}
  js:
    js/hero-slider.js: {}
  dependencies:
    - core/drupal
    - core/once
```

### CSS Weight Categories (SMACSS)

Libraries use SMACSS ordering. Lower categories load first:

| Category | Weight | Use Case |
|----------|--------|----------|
| `base` | CSS_BASE | Resets, element defaults |
| `layout` | CSS_LAYOUT | Page structure, grid |
| `component` | CSS_COMPONENT | Reusable UI patterns |
| `state` | CSS_STATE | Interaction states |
| `theme` | CSS_THEME | Visual overrides, skin |

### Overriding and Extending Libraries

Override a base theme or core library:

```yaml
# In my_custom_theme.info.yml
libraries-override:
  # Remove an entire library
  olivero/global-styling: false

  # Replace a specific CSS file
  olivero/navigation:
    css:
      component:
        css/components/navigation.css: css/components/my-navigation.css

  # Remove a specific file
  core/normalize:
    css:
      base:
        assets/vendor/normalize-css/normalize.css: false

libraries-extend:
  # Add extra CSS/JS when a library loads
  olivero/global-styling:
    - my_custom_theme/extra-global-styles
```

### Attaching Libraries Conditionally

In Twig templates:

```twig
{{ attach_library('my_custom_theme/hero-slider') }}
```

In preprocess functions:

```php
function my_custom_theme_preprocess_node(&$variables) {
  if ($variables['node']->bundle() === 'landing_page') {
    $variables['#attached']['library'][] = 'my_custom_theme/hero-slider';
  }
}
```
