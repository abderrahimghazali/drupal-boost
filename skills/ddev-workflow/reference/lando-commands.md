# Lando for Drupal 11

## .lando.yml Configuration

Basic Drupal recipe configuration:

```yaml
name: my-drupal-site
recipe: drupal11
config:
  php: "8.3"
  via: nginx
  webroot: web
  database: mysql:8.0
  composer_version: 2
  xdebug: false
```

Full configuration with services and tooling:

```yaml
name: my-drupal-site
recipe: drupal11
config:
  php: "8.3"
  via: nginx
  webroot: web
  database: mysql:8.0

services:
  appserver:
    build_as_root:
      - apt-get update && apt-get install -y libmagickwand-dev
      - pecl install imagick && docker-php-ext-enable imagick
    overrides:
      environment:
        PHP_MEMORY_LIMIT: 512M
        SIMPLETEST_BASE_URL: https://my-drupal-site.lndo.site
        SIMPLETEST_DB: mysql://drupal11:drupal11@database/drupal11

proxy:
  appserver:
    - my-drupal-site.lndo.site

events:
  post-start:
    - appserver: composer install
    - appserver: drush deploy || true
  post-db-import:
    - appserver: drush cr
```

## Common Lando Commands

### Project Lifecycle

```bash
lando init --source cwd --recipe drupal11   # Initialize project
lando start                     # Start the project
lando stop                      # Stop containers
lando restart                   # Restart
lando destroy                   # Remove project (keeps files, drops DB)
lando rebuild                   # Rebuild containers from config
lando info                      # Show project info, URLs, service details
lando list                      # List all Lando projects
lando poweroff                  # Stop all Lando projects
```

### Running Commands

```bash
lando drush cr                  # Run drush in the appserver container
lando composer require drupal/token   # Run composer
lando php -v                    # Check PHP version
lando mysql                     # Open MySQL CLI
lando ssh                       # SSH into appserver
lando ssh -s database           # SSH into database service
```

### Database Operations

```bash
lando db-export dump.sql.gz     # Export database
lando db-import dump.sql.gz     # Import database
```

## Custom Tooling Definitions

Define custom commands in `.lando.yml` under `tooling`:

```yaml
tooling:
  phpcs:
    service: appserver
    cmd: vendor/bin/phpcs --standard=Drupal,DrupalPractice
    description: Run PHP CodeSniffer
    options:
      path:
        describe: Path to check
        default: web/modules/custom

  phpcbf:
    service: appserver
    cmd: vendor/bin/phpcbf --standard=Drupal,DrupalPractice
    description: Auto-fix coding standard violations

  phpstan:
    service: appserver
    cmd: vendor/bin/phpstan analyse --memory-limit=512M
    description: Run PHPStan static analysis

  phpunit:
    service: appserver
    cmd: vendor/bin/phpunit
    description: Run PHPUnit tests

  test:
    service: appserver
    cmd: vendor/bin/phpunit --testsuite=unit,kernel
    description: Run unit and kernel tests

  xdebug-on:
    service: appserver
    description: Enable Xdebug
    cmd: docker-php-ext-enable xdebug && kill -USR2 $(pgrep -o php-fpm)
    user: root

  xdebug-off:
    service: appserver
    description: Disable Xdebug
    cmd: rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && kill -USR2 $(pgrep -o php-fpm)
    user: root

  node:
    service: node
    cmd: node

  npm:
    service: node
    cmd: npm
```

Usage:

```bash
lando phpcs web/modules/custom/my_module
lando phpstan
lando phpunit --filter=MyTest
```

## Service Configuration

### Redis

```yaml
services:
  cache:
    type: redis:7
    portforward: true

tooling:
  redis-cli:
    service: cache
    cmd: redis-cli
```

### Solr

```yaml
services:
  search:
    type: solr:9
    core: drupal
    portforward: true
    config:
      dir: .lando/solr-config

tooling:
  solr:
    service: search
    cmd: solr
```

### Node.js (for theming)

```yaml
services:
  node:
    type: node:20
    build:
      - cd /app/web/themes/custom/my_theme && npm install
    scanner: false

tooling:
  npm:
    service: node
    cmd: npm
  gulp:
    service: node
    cmd: npx gulp
```

### Mailhog

```yaml
services:
  mailhog:
    type: mailhog
    hogfrom:
      - appserver

proxy:
  mailhog:
    - mail.my-drupal-site.lndo.site
```

### Elasticsearch

```yaml
services:
  elasticsearch:
    type: elasticsearch:8
    portforward: true
    overrides:
      environment:
        - "discovery.type=single-node"
        - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
```

## Lando vs DDEV Comparison

| Feature             | DDEV                              | Lando                             |
|---------------------|-----------------------------------|-----------------------------------|
| Config file         | `.ddev/config.yaml`               | `.lando.yml`                      |
| Drupal recipe       | `type: drupal`                    | `recipe: drupal11`                |
| Custom commands     | `.ddev/commands/web/` scripts     | `tooling:` in `.lando.yml`        |
| Add-ons/plugins     | `ddev get` (community add-ons)    | Built-in service types            |
| Database CLI        | `ddev mysql`                      | `lando mysql`                     |
| Drush               | `ddev drush`                      | `lando drush`                     |
| SSH                 | `ddev ssh`                        | `lando ssh`                       |
| DB export           | `ddev export-db`                  | `lando db-export`                 |
| DB import           | `ddev import-db`                  | `lando db-import`                 |
| Xdebug              | `ddev xdebug on/off`             | Custom tooling or config toggle   |
| Performance         | Mutagen sync (fast)               | Docker native (varies by OS)      |
| Mail capture        | Mailpit (built-in)                | Mailhog (add as service)          |
| Multi-site          | `additional_hostnames`            | `proxy:` configuration            |
| Snapshots           | `ddev snapshot`                   | Not built-in (use db-export)      |
| Sharing             | `ddev share` (ngrok)              | `lando share`                     |
