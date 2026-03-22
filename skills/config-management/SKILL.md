---
name: config-management
description: Drupal configuration management including config export/import, Config Split, environment-specific configuration, and config override patterns. Use when managing Drupal configuration, setting up Config Split, or handling environment-specific settings.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Drupal Configuration Management

## Core Concepts

Configuration is stored in YAML files and tracked in the `config/sync` directory (set in `settings.php` via `$settings['config_sync_directory']`).

## Essential Commands

```bash
# Export all config
drush config:export    # or drush cex
# Import all config
drush config:import    # or drush cim
# Check status (what's changed)
drush config:status    # or drush cst
# Export single config
drush config:get system.site
# Set single value
drush config:set system.site name "My Site"
```

## Config Split (Multi-Environment)

Install: `composer require drupal/config_split`

### Setup for dev/staging/prod

```yaml
# config/sync/config_split.config_split.dev.yml
id: dev
label: Development
folder: ../config/splits/dev
status: true
weight: 0
module:
  devel: 0
  kint: 0
  webprofiler: 0
theme: {}
complete_list: []
partial_list: []
```

### Activate per environment in settings.php

```php
// settings.php
$config['config_split.config_split.dev']['status'] = FALSE;
$config['config_split.config_split.prod']['status'] = FALSE;

// settings.local.php (dev only)
$config['config_split.config_split.dev']['status'] = TRUE;

// settings.prod.php (prod only)
$config['config_split.config_split.prod']['status'] = TRUE;
```

### Config Split Commands

```bash
drush config-split:export dev    # or drush csex dev
drush config-split:import dev    # or drush csim dev
```

## Config Overrides in settings.php

Override any config at runtime (not exported):

```php
// Disable caching in development
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Change site name per environment
$config['system.site']['name'] = 'My Site (Dev)';
```

## Config Schema

Always define schema for custom config in `config/schema/MODULE_NAME.schema.yml`:

```yaml
MODULE_NAME.settings:
  type: config_object
  label: 'Module settings'
  mapping:
    api_key:
      type: string
      label: 'API Key'
    max_items:
      type: integer
      label: 'Maximum items'
    enabled:
      type: boolean
      label: 'Enabled'
```

## Workflow

1. Make config changes on your dev site
2. Export: `drush cex`
3. Commit the YAML files
4. On deploy: `drush cim`
5. For environment-specific config, use Config Split

## Key Rules

- Never edit config YAML files by hand unless you know what you're doing
- Always export after making config changes in the UI
- Always define config schema for custom module configuration
- Use Config Split for environment-specific modules and settings
- Use `$config` overrides in `settings.php` for secrets and environment values
- Run `drush cim` as part of your deployment pipeline
- Check `drush cst` before importing to see what will change
