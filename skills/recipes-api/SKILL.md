---
name: recipes-api
description: Drupal Recipes API for automating module installation and configuration. Use when creating recipes, applying recipes, or building site templates with the Drupal 11 Recipes system.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Drupal Recipes API

Recipes automate module installation and configuration. Available in Drupal 10.3+ as experimental, stable in Drupal 11.

## Recipe Structure

```
recipes/my_recipe/
├── recipe.yml          # Required: recipe definition
├── config/             # Optional: config to import
│   ├── system.site.yml
│   └── node.type.article.yml
└── content/            # Optional: default content
```

## recipe.yml Schema

```yaml
name: 'My Recipe'
description: 'Sets up a blog with article content type and views.'
type: 'Content type'

# Install modules
install:
  - node
  - views
  - pathauto
  - metatag

# Install themes
themes:
  install:
    - olivero
  default: olivero
  admin: claro

# Apply other recipes first
recipes:
  - core/recipes/standard

# Config actions
config:
  actions:
    node.type.article:
      createIfNotExists:
        label: 'Article'
        description: 'Use articles for time-sensitive content.'
    system.site:
      simpleConfigUpdate:
        name: 'My Blog'
        page:
          front: '/blog'
```

## Applying Recipes

```bash
# Via Drush (recommended)
drush recipe recipes/my_recipe

# Via PHP script
php core/scripts/drupal recipe recipes/my_recipe
```

## Config Actions

- `createIfNotExists` — Create config if it doesn't exist
- `simpleConfigUpdate` — Update specific values in existing config
- `createForEach` — Create multiple config entities from a template
- `setPermissions` — Assign permissions to roles

## Composing Recipes

Recipes can include other recipes:

```yaml
recipes:
  - core/recipes/standard
  - recipes/blog_base
  - recipes/media_setup
```

## Key Rules

- Recipes are idempotent — safe to apply multiple times
- Recipes are applied once and cannot be "uninstalled"
- Use recipes for site setup, not for ongoing configuration management
- Place custom recipes in the project root `recipes/` directory
- Test recipes on a clean install before distributing
- Use `createIfNotExists` to avoid overwriting existing config
