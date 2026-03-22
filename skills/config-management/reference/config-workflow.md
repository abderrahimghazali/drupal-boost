# Config Management Workflow

## Export/Import Workflow

### Basic Export and Import

```bash
# Export active config to the sync directory (config/sync by default)
drush config:export -y
# Shorthand:
drush cex -y

# Import config from the sync directory into the active database
drush config:import -y
# Shorthand:
drush cim -y

# Preview changes before importing (dry run)
drush cim --preview

# Export a single config object for inspection
drush config:get system.site
drush config:get system.performance --include-overridden
```

### Setting the Sync Directory

In `settings.php`:

```php
$settings['config_sync_directory'] = '../config/sync';
```

This path is relative to the Drupal root. Placing it above the web root is a security best practice.

### Partial Export and Import

```bash
# Export a single config item to a file
drush config:export --destination=/tmp/config-export

# Import a single config item
drush config:set system.site name "My Site"
drush config:import --source=/tmp/config-export --partial
```

## Handling Config Conflicts

When `drush cim` fails due to conflicts, follow this process:

```bash
# 1. Check the current config status
drush config:status

# Output shows:
#  Name                          State
#  system.site                   Different
#  node.type.article             Only in sync

# 2. Inspect the difference
drush config:diff system.site

# 3. If the active config should win, re-export
drush cex -y

# 4. If the sync config should win, force import
drush cim -y

# 5. For UUID mismatches after a fresh install, sync the site UUID:
drush config:set system.site uuid "VALUE_FROM_SYNC_DIR" -y
```

### Config Hash Mismatches

Drupal tracks a `_core.default_config_hash` for config provided by modules. If a hash mismatch occurs during import, it usually means the config was modified in the database after module install. Export the current state to reset the hash.

## Config Override System

The `$config` array in `settings.php` overrides values at runtime without changing stored configuration. Overrides are read-only and do not appear in config export.

```php
// sites/default/settings.php

// Override site name and mail
$config['system.site']['name'] = 'My Production Site';
$config['system.site']['mail'] = 'admin@example.com';

// Override performance settings for production
$config['system.performance']['css']['preprocess'] = TRUE;
$config['system.performance']['js']['preprocess'] = TRUE;
$config['system.performance']['cache']['page']['max_age'] = 3600;

// Override SMTP settings per environment
$config['smtp.settings']['smtp_host'] = getenv('SMTP_HOST');
$config['smtp.settings']['smtp_username'] = getenv('SMTP_USER');
$config['smtp.settings']['smtp_password'] = getenv('SMTP_PASS');

// Disable modules via config override (used with config_split)
$config['config_split.config_split.dev']['status'] = FALSE;
```

### Override Priority Order

1. `settings.php` `$config` overrides (highest priority)
2. Config Split overrides
3. Module-provided overrides (`ConfigFactoryOverrideInterface`)
4. Stored (active) configuration in the database (lowest priority)

Overridden values display with a visual indicator in the admin UI and are excluded from export.

## Config Read-Only Mode for Production

Prevent accidental config changes on production by enabling read-only mode.

### Using the config_readonly Module

```bash
composer require drupal/config_readonly
drush en config_readonly -y
```

In `settings.php` on production:

```php
if (PHP_SAPI !== 'cli') {
  $settings['config_readonly'] = TRUE;
}
```

This blocks all config changes through the admin UI while still allowing `drush cim` to run from the command line.

### Locking Specific Forms

For more granular control, lock specific config forms:

```php
$settings['config_readonly_whitelist_patterns'] = [
  'system.menu.*',      # Allow menu config changes
  'block.block.*',      # Allow block placement changes
];
```

## Config Schema Best Practices

Every custom module providing config should include a schema file.

```yaml
# my_module/config/schema/my_module.schema.yml
my_module.settings:
  type: config_object
  label: 'My Module settings'
  mapping:
    enabled:
      type: boolean
      label: 'Enable feature'
    api_endpoint:
      type: uri
      label: 'API endpoint URL'
    max_retries:
      type: integer
      label: 'Maximum retry count'
    allowed_bundles:
      type: sequence
      label: 'Allowed content types'
      sequence:
        type: string
        label: 'Bundle machine name'
```

### Validating Config Schema

```bash
# Run config schema validation
drush config:inspect my_module.settings

# Validate all config against schemas
drush config:inspect
```

Schema is required for proper config translation support and ensures type safety during import.

## Config Dependencies

Configuration entities declare dependencies to ensure correct install/uninstall order.

```yaml
# Auto-calculated dependencies in exported config
dependencies:
  config:
    - field.storage.node.field_image
    - node.type.article
  module:
    - image
    - node
  theme:
    - my_custom_theme
  enforced:
    module:
      - my_module  # Delete this config when my_module is uninstalled
```

### Dependency Types

| Key | Meaning |
|-----|---------|
| `config` | Other config entities this depends on |
| `module` | Modules that must be enabled |
| `theme` | Themes that must be installed |
| `enforced` | Hard dependencies; removing the dependency deletes this config |

### Recalculating Dependencies

When dependencies get out of sync:

```bash
# Recalculate all config dependencies
drush config:import --diff
drush cex -y

# Or target a specific config
drush eval "\Drupal::service('config.manager')->getConfigFactory()->getEditable('views.view.my_view')->calculateDependencies()->save();"
```

Dependencies are automatically recalculated on export, but manual recalculation may be needed after config surgery or database manipulation.
