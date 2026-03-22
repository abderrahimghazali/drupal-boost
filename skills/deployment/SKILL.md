---
name: deployment
description: Drupal deployment workflows, CI/CD pipeline configuration (GitHub Actions, GitLab CI), Composer management, and deployment order (database updates, config import, cache rebuild). Use when setting up deployment pipelines, creating CI/CD configs, or planning a release.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Drupal Deployment

## Deployment Order (Critical)

The correct order matters. Getting it wrong can break your site.

```bash
# 1. Enable maintenance mode (optional)
drush state:set system.maintenance_mode 1

# 2. Run database updates FIRST (needs old state to know what changed)
drush updatedb --no-cache-clear

# 3. Clear caches (rebuild container after code changes)
drush cache:rebuild

# 4. Import configuration
drush config:import -y

# 5. Clear caches again (config changes may alter the container)
drush cache:rebuild

# 6. Run deploy hooks (custom post-deploy logic)
drush deploy:hook

# 7. Disable maintenance mode
drush state:set system.maintenance_mode 0
```

Or use the `drush deploy` shortcut which runs the correct sequence.

## GitHub Actions

```yaml
# .github/workflows/drupal-ci.yml
name: Drupal CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: drupal
        ports: ['3306:3306']
        options: --health-cmd="mysqladmin ping" --health-interval=10s

    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: gd, pdo_mysql, mbstring
          coverage: xdebug

      - run: composer install --no-interaction --prefer-dist

      - name: PHPCS
        run: ./vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/custom/

      - name: PHPStan
        run: ./vendor/bin/phpstan analyse web/modules/custom/ --level=6

      - name: PHPUnit
        run: ./vendor/bin/phpunit -c web/core web/modules/custom/
        env:
          SIMPLETEST_DB: mysql://root:root@127.0.0.1:3306/drupal
          SIMPLETEST_BASE_URL: http://localhost:8080
```

## GitLab CI

```yaml
# .gitlab-ci.yml
include:
  - project: 'drupalspoons/composer-plugin'
    ref: '1.x'
    file: '/templates/.gitlab-ci.yml'

variables:
  _TARGET_PHP: "8.3"
  _TARGET_DB: "mysql-8"
  _PHPUNIT_EXTRA: "--group my_module"
  DRUPAL_CORE: "11.x"
```

For drupal.org projects, use the Drupal Association's official template.

## Composer Best Practices

```bash
# Add a module
composer require drupal/module_name

# Update a specific module
composer update drupal/module_name --with-all-dependencies

# Apply patches (via cweagans/composer-patches)
# In composer.json:
{
  "extra": {
    "patches": {
      "drupal/module_name": {
        "Fix issue #12345": "https://www.drupal.org/files/issues/fix.patch"
      }
    }
  }
}

# Always commit composer.lock
git add composer.json composer.lock
```

## Pre-Deployment Checklist

1. All config exported (`drush cex`) and committed
2. `composer.lock` is up to date and committed
3. No security advisories (`composer audit`)
4. All tests passing in CI
5. Database backup taken
6. Update hooks written for schema changes
7. Deploy hooks written for one-time operations

## Key Rules

- NEVER clear caches before running database updates
- ALWAYS run `drush updatedb` before `drush config:import`
- ALWAYS commit `composer.lock` — it ensures reproducible builds
- Use update hooks (`hook_update_N`) for schema changes
- Use deploy hooks (`hook_deploy_N`) for one-time data operations
- Take database backups before every deployment
- Test the deployment sequence on staging first

Read reference files for details:
- `reference/deploy-workflow.md` for deployment patterns
- `reference/github-actions-templates.md` for GitHub CI templates
- `reference/gitlab-ci-templates.md` for GitLab CI templates
