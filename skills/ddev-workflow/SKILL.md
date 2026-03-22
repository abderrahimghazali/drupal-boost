---
name: ddev-workflow
description: DDEV and Lando-based Drupal development workflow including setup, commands, add-ons (Solr, Redis, Elasticsearch, Mailpit), Drush via DDEV/Lando, testing, and Xdebug configuration. Use when setting up or managing a Drupal development environment.
allowed-tools: Read, Bash, Grep, Glob
---

# Drupal Local Development (DDEV & Lando)

## DDEV Setup

### Initialize a Drupal project
```bash
mkdir my-drupal-project && cd my-drupal-project
ddev config --project-type=drupal --php-version=8.3 --docroot=web
ddev start
ddev composer create drupal/recommended-project:^11
ddev drush si -y
ddev launch
```

### Common DDEV Commands
```bash
ddev start                      # Start containers
ddev stop                       # Stop containers
ddev restart                    # Restart containers
ddev describe                   # Show project info (URLs, DB credentials)
ddev ssh                        # SSH into web container
ddev logs -s web                # View web logs
ddev launch                     # Open site in browser
ddev launch --mailpit           # Open Mailpit UI

# Drupal-specific
ddev drush cr                   # Clear/rebuild cache
ddev drush cex                  # Export config
ddev drush cim                  # Import config
ddev drush updb                 # Run database updates
ddev drush si -y                # Fresh install
ddev drush uli                  # One-time login URL
ddev drush pm:list              # List modules
ddev drush en MODULE_NAME       # Enable module
ddev drush pm:uninstall MODULE  # Uninstall module

# Composer
ddev composer require drupal/MODULE_NAME
ddev composer update
ddev composer install

# Database
ddev export-db > backup.sql.gz  # Export database
ddev import-db < backup.sql.gz  # Import database
```

### DDEV Add-ons
```bash
# Redis
ddev add-on get ddev/ddev-redis
# Then in settings.php:
# $settings['redis.connection']['host'] = 'redis';

# Solr
ddev add-on get ddev/ddev-solr

# Elasticsearch
ddev add-on get ddev/ddev-elasticsearch

# Memcached
ddev add-on get ddev/ddev-memcached
```

### Xdebug (DDEV)
```bash
ddev xdebug on                  # Enable Xdebug (port 9003)
ddev xdebug off                 # Disable Xdebug
ddev xdebug status              # Check status
```

Configure your IDE to listen on port 9003.

### Running Tests (DDEV)
```bash
# PHPUnit
ddev exec ./vendor/bin/phpunit -c web/core web/modules/custom/MODULE/tests/

# PHPCS
ddev exec ./vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/custom/MODULE/

# PHPStan
ddev exec ./vendor/bin/phpstan analyse web/modules/custom/MODULE --level=6
```

---

## Lando Setup

### Initialize a Drupal project
```bash
mkdir my-drupal-project && cd my-drupal-project
lando init --source cwd --recipe drupal11
lando start
lando composer create-project drupal/recommended-project:^11 .
lando drush si -y
```

### .lando.yml for Drupal 11
```yaml
name: my-drupal-project
recipe: drupal11
config:
  php: '8.3'
  via: nginx
  webroot: web
  database: mariadb:10.6
  drush: true
  xdebug: false
services:
  redis:
    type: redis:7
  mailhog:
    type: mailhog
    portforward: true
tooling:
  drush:
    service: appserver
    cmd: drush --root=/app/web
  phpunit:
    service: appserver
    cmd: ./vendor/bin/phpunit -c web/core
  phpcs:
    service: appserver
    cmd: ./vendor/bin/phpcs --standard=Drupal,DrupalPractice
```

### Common Lando Commands
```bash
lando start                     # Start containers
lando stop                      # Stop containers
lando rebuild                   # Rebuild containers
lando info                      # Show project info
lando ssh                       # SSH into appserver
lando logs -s appserver         # View logs

# Drupal-specific
lando drush cr                  # Clear cache
lando drush cex                 # Export config
lando drush cim                 # Import config
lando drush updb                # Database updates
lando drush uli                 # Login URL

# Composer
lando composer require drupal/MODULE_NAME
lando composer update

# Database
lando db-export backup.sql      # Export
lando db-import backup.sql      # Import
```

### Xdebug (Lando)
```yaml
# In .lando.yml
config:
  xdebug: true
```
Then `lando rebuild` to apply.

### Running Tests (Lando)
```bash
lando phpunit web/modules/custom/MODULE/tests/
lando phpcs web/modules/custom/MODULE/
lando php ./vendor/bin/phpstan analyse web/modules/custom/MODULE
```

## Key Rules

- Always prefix commands with `ddev` or `lando` depending on the environment
- Check for `.ddev/config.yaml` or `.lando.yml` to detect the environment
- Use `ddev describe` or `lando info` to find database credentials and URLs
- Always backup the database before major operations
- Disable Xdebug when not debugging (it slows PHP significantly)
- Use Mailpit/MailHog for email testing — never send real emails from dev
