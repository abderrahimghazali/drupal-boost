# Drupal Deployment Workflow

## Step-by-Step Deployment Process

Standard Drupal deployment sequence:

```bash
# 1. Put site in maintenance mode.
drush state:set system.maintenance_mode 1

# 2. Pull code changes.
git pull origin main

# 3. Install composer dependencies.
composer install --no-dev --optimize-autoloader

# 4. Run database updates.
drush updatedb -y

# 5. Import configuration.
drush config:import -y

# 6. Deploy hooks (Drupal 10.3+).
drush deploy:hook

# 7. Rebuild caches.
drush cache:rebuild

# 8. Disable maintenance mode.
drush state:set system.maintenance_mode 0
```

Combined deploy command (does steps 4-7):

```bash
drush deploy
```

## Update Hooks (hook_update_N)

For database schema changes and data migrations tied to code releases:

```php
// mymodule.install

/**
 * Add 'status' column to mymodule_data table.
 */
function mymodule_update_10001(&$sandbox) {
  $schema = \Drupal::database()->schema();
  if (!$schema->fieldExists('mymodule_data', 'status')) {
    $schema->addField('mymodule_data', 'status', [
      'type' => 'int',
      'size' => 'tiny',
      'not null' => TRUE,
      'default' => 1,
      'description' => 'Entity status.',
    ]);
  }
}

/**
 * Migrate data from old_field to new_field on all articles.
 */
function mymodule_update_10002(&$sandbox) {
  // Batch processing for large datasets.
  if (!isset($sandbox['total'])) {
    $sandbox['ids'] = \Drupal::entityQuery('node')
      ->condition('type', 'article')
      ->accessCheck(FALSE)
      ->execute();
    $sandbox['total'] = count($sandbox['ids']);
    $sandbox['current'] = 0;
  }

  $batch_size = 50;
  $ids = array_slice($sandbox['ids'], $sandbox['current'], $batch_size);

  $nodes = \Drupal::entityTypeManager()->getStorage('node')->loadMultiple($ids);
  foreach ($nodes as $node) {
    $node->set('field_new', $node->get('field_old')->value);
    $node->save();
  }

  $sandbox['current'] += count($ids);
  $sandbox['#finished'] = $sandbox['total'] > 0
    ? $sandbox['current'] / $sandbox['total']
    : 1;

  return t('Processed @count of @total articles.', [
    '@count' => $sandbox['current'],
    '@total' => $sandbox['total'],
  ]);
}
```

Naming convention: `mymodule_update_XYZZ` where X = Drupal major version (10), Y = module's major version, ZZ = sequential counter.

## Deploy Hooks (hook_deploy_N)

Run after `updatedb` and `config:import`. Use for content and data updates that depend on config being in place:

```php
// mymodule.deploy.php

/**
 * Create default taxonomy terms for the new vocabulary.
 */
function mymodule_deploy_10001() {
  $terms = ['Draft', 'Review', 'Published', 'Archived'];
  $storage = \Drupal::entityTypeManager()->getStorage('taxonomy_term');

  foreach ($terms as $weight => $name) {
    $storage->create([
      'vid' => 'workflow_states',
      'name' => $name,
      'weight' => $weight,
    ])->save();
  }

  return t('Created @count workflow state terms.', ['@count' => count($terms)]);
}

/**
 * Assign default workflow state to existing content.
 */
function mymodule_deploy_10002(&$sandbox) {
  if (!isset($sandbox['total'])) {
    $sandbox['ids'] = \Drupal::entityQuery('node')
      ->condition('type', 'article')
      ->notExists('field_workflow_state')
      ->accessCheck(FALSE)
      ->execute();
    $sandbox['total'] = count($sandbox['ids']);
    $sandbox['current'] = 0;
  }

  $batch = array_slice($sandbox['ids'], $sandbox['current'], 25);
  $nodes = \Drupal::entityTypeManager()->getStorage('node')->loadMultiple($batch);
  $published_tid = \Drupal::entityTypeManager()
    ->getStorage('taxonomy_term')
    ->loadByProperties(['vid' => 'workflow_states', 'name' => 'Published']);
  $published_tid = reset($published_tid)?->id();

  foreach ($nodes as $node) {
    $node->set('field_workflow_state', $published_tid);
    $node->save();
  }

  $sandbox['current'] += count($batch);
  $sandbox['#finished'] = $sandbox['total'] ? $sandbox['current'] / $sandbox['total'] : 1;
}
```

## Post-Update Hooks

Run after all `hook_update_N` but before `config:import`:

```php
// mymodule.post_update.php

/**
 * Re-save all article nodes to populate computed field.
 */
function mymodule_post_update_resave_articles(&$sandbox) {
  // Naming: mymodule_post_update_DESCRIPTIVE_NAME (not numeric).
  $storage = \Drupal::entityTypeManager()->getStorage('node');

  if (!isset($sandbox['ids'])) {
    $sandbox['ids'] = $storage->getQuery()
      ->condition('type', 'article')
      ->accessCheck(FALSE)
      ->execute();
    $sandbox['total'] = count($sandbox['ids']);
    $sandbox['current'] = 0;
  }

  $batch = array_slice($sandbox['ids'], $sandbox['current'], 50);
  foreach ($storage->loadMultiple($batch) as $node) {
    $node->save();
  }

  $sandbox['current'] += count($batch);
  $sandbox['#finished'] = $sandbox['total'] ? $sandbox['current'] / $sandbox['total'] : 1;
}
```

## Maintenance Mode

```php
// settings.php - custom maintenance page.
$settings['maintenance_template'] = '/path/to/maintenance.html';

// Exempt specific IPs from maintenance mode.
$settings['maintenance_mode_allow_ips'] = ['192.168.1.100'];
```

```php
// Programmatic toggle.
\Drupal::state()->set('system.maintenance_mode', TRUE);
\Drupal::state()->set('system.maintenance_mode', FALSE);
```

## Rollback Strategies

### Database snapshot rollback

```bash
# Pre-deploy snapshot.
drush sql:dump --gzip > /backups/pre-deploy-$(date +%Y%m%d%H%M).sql.gz

# Rollback if deploy fails.
git checkout previous-tag
composer install --no-dev
drush sql:drop -y
drush sql:cli < /backups/pre-deploy-TIMESTAMP.sql
drush cache:rebuild
```

### Config-only rollback

```bash
# If only config import caused issues.
git checkout previous-tag -- config/sync
drush config:import -y
drush cache:rebuild
```

### Feature flags for safe rollback

```php
// Use state API for feature flags during deployment.
\Drupal::state()->set('mymodule.new_feature_enabled', TRUE);

// In code, check before using new functionality.
if (\Drupal::state()->get('mymodule.new_feature_enabled', FALSE)) {
  // New behavior.
}
```
