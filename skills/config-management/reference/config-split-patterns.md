# Config Split Patterns

## Overview

Config Split (`config_split` module) allows maintaining separate configuration sets per environment. It works by filtering the config import/export pipeline to include or exclude specific configuration items.

## Complete Split vs Partial Split

### Complete Split

A complete split moves entire configuration objects to a separate directory. Those objects are excluded from the default sync directory and only exist in the split's directory.

Use case: Module that should only be enabled on dev (e.g., `devel`, `field_ui`).

```yaml
# config/sync/config_split.config_split.dev.yml
id: dev
label: Development
status: true
folder: ../config/splits/dev
weight: 0
module:
  devel: 0
  field_ui: 0
  dblog: 0
theme: {}
complete_list:
  - devel.settings
  - devel.toolbar.settings
  - system.menu.devel
partial_list: []
```

### Partial Split

A partial split overrides specific values within configuration objects that also exist in the default sync directory. The base config remains in sync; only the differences live in the split folder.

Use case: Different mail transport settings per environment.

```yaml
# config/sync/config_split.config_split.prod.yml
id: prod
label: Production
status: true
folder: ../config/splits/prod
weight: 0
module: {}
theme: {}
complete_list: []
partial_list:
  - system.mail
  - system.performance
  - system.logging
```

The split folder then contains only the overridden versions of those config objects.

## Multi-Environment Setup

### Directory Structure

```
project_root/
  config/
    sync/              # Default (shared) configuration
    splits/
      dev/             # Dev-only config
      staging/         # Staging-only config
      prod/            # Production-only config
```

### Creating Split Entities

Create a split for each environment:

```bash
# Create splits via Drush (or through the UI at /admin/config/development/configuration/config-split)
drush config:set config_split.config_split.dev status 1
drush config:set config_split.config_split.staging status 0
drush config:set config_split.config_split.prod status 0
```

### settings.php Activation Patterns

Only one environment split should be active at a time. Activate via `settings.php`:

```php
// sites/default/settings.php — Base: all splits inactive.
$config['config_split.config_split.dev']['status'] = FALSE;
$config['config_split.config_split.staging']['status'] = FALSE;
$config['config_split.config_split.prod']['status'] = FALSE;
```

```php
// sites/default/settings.local.php (on dev machines)
$config['config_split.config_split.dev']['status'] = TRUE;
```

```php
// settings.php — Environment detection pattern
if (defined('PANTHEON_ENVIRONMENT')) {
  switch (PANTHEON_ENVIRONMENT) {
    case 'live':
      $config['config_split.config_split.prod']['status'] = TRUE;
      break;
    case 'test':
      $config['config_split.config_split.staging']['status'] = TRUE;
      break;
    default:
      $config['config_split.config_split.dev']['status'] = TRUE;
  }
}

// Alternative: Use an environment variable
$env = getenv('APP_ENV') ?: 'dev';
$config["config_split.config_split.{$env}"]['status'] = TRUE;
```

## Config Ignore Patterns

Use `config_ignore` (separate module) alongside Config Split to prevent specific config from being overwritten on import. Useful for site-specific content like blocks, webforms, or contact form recipients.

```yaml
# config/sync/config_ignore.settings.yml
ignored_config_entities:
  - system.site          # Don't overwrite site name/slogan
  - contact.form.*       # Preserve contact form recipients
  - webform.webform.*    # Preserve webform definitions
  - 'core.extension:module.devel'  # Ignore devel module status
```

The `~` prefix forces import even if normally ignored:

```
~system.site
```

## Drush Commands for Config Split

```bash
# Export configuration respecting active splits
drush config:export
# Shorthand:
drush cex

# Import configuration respecting active splits
drush config:import
# Shorthand:
drush cim

# Export only a specific split
drush config-split:export dev

# Import only a specific split
drush config-split:import dev

# Show the status of all splits
drush config-split:status

# Activate a split (runtime only, does not change settings.php)
drush config-split:activate dev

# Deactivate a split
drush config-split:deactivate staging
```

### Workflow Example

```bash
# 1. Make changes in the UI on your local dev environment.
# 2. Export all config (split-aware):
drush cex -y

# 3. Review what went where:
git status
# config/sync/ — shared config
# config/splits/dev/ — dev-only config

# 4. Commit and push.
git add config/
git commit -m "Add Devel module config for dev split"

# 5. On staging/production, import:
drush cim -y
drush cr
```

### Weight and Priority

When multiple splits could apply to the same config, `weight` determines priority. Lower weight = higher priority. Set weights to control override order:

```yaml
# Dev split: weight 0 (highest priority)
# Staging split: weight 10
# Prod split: weight 5
```

This matters when a partial split on dev and staging both override the same config key.
