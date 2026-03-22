# DDEV Command Reference for Drupal 11

## Common DDEV Commands

### Project Lifecycle

```bash
ddev config                    # Initialize or reconfigure a project
ddev start                     # Start the project containers
ddev stop                      # Stop containers (preserves data)
ddev restart                   # Stop and start
ddev delete                    # Remove project (containers + db, keeps files)
ddev poweroff                  # Stop all DDEV projects
ddev describe                  # Show project info (URLs, services, ports)
ddev list                      # List all DDEV projects and their status
```

### Drupal-Specific

```bash
ddev drush site:install --db-url=mysql://db:db@db/db    # Install Drupal
ddev drush cr                  # Clear cache
ddev drush updb                # Run database updates
ddev drush cex -y              # Export config
ddev drush cim -y              # Import config
ddev composer require drupal/admin_toolbar    # Add a module
ddev composer install           # Install dependencies
```

### Database Operations

```bash
ddev export-db --file=dump.sql.gz    # Export database
ddev import-db --file=dump.sql.gz    # Import database
ddev mysql                           # Open MySQL CLI
ddev sequelace                       # Open Sequel Ace (macOS)
```

### File and SSH Operations

```bash
ddev ssh                       # SSH into web container
ddev ssh -s db                 # SSH into database container
ddev exec <command>            # Run command in web container
ddev logs                      # View web container logs
ddev logs -s db                # View database container logs
```

### Utilities

```bash
ddev launch                    # Open site in browser
ddev launch /admin             # Open specific path
ddev xdebug on                 # Enable Xdebug
ddev xdebug off                # Disable Xdebug
ddev share                     # Share site via ngrok
ddev snapshot                  # Create database snapshot
ddev snapshot restore          # Restore last snapshot
ddev snapshot restore --name=my_snap   # Restore named snapshot
```

## Custom DDEV Commands

Create custom commands as shell scripts in `.ddev/commands/`. Files in `host/` run on the host; files in `web/` run in the web container.

### Host command example

```bash
#!/bin/bash
## Description: Run PHPStan analysis
## Usage: phpstan
## Example: ddev phpstan

ddev exec vendor/bin/phpstan analyse --memory-limit=512M
```

Save as `.ddev/commands/host/phpstan`. Make executable: `chmod +x .ddev/commands/host/phpstan`.

### Web container command example

```bash
#!/bin/bash
## Description: Run Drupal coding standards check
## Usage: phpcs [path]
## Example: ddev phpcs web/modules/custom

cd /var/www/html
vendor/bin/phpcs --standard=Drupal,DrupalPractice ${@:-web/modules/custom}
```

Save as `.ddev/commands/web/phpcs`.

## .ddev/config.yaml Options

Key configuration options:

```yaml
name: my-drupal-site
type: drupal
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm       # or apache-fpm
database:
  type: mysql                    # or mariadb, postgres
  version: "8.0"

# Composer version
composer_version: "2"

# Node.js version (for theming)
nodejs_version: "20"

# Additional hostnames
additional_hostnames:
  - my-drupal-site.local

# Additional FQDN
additional_fqdns:
  - my-drupal-site.example.com

# Router HTTP/HTTPS ports (defaults: 80/443)
router_http_port: "80"
router_https_port: "443"

# PHP memory limit
web_environment:
  - PHP_MEMORY_LIMIT=512M
  - DRUSH_OPTIONS_URI=https://my-drupal-site.ddev.site

# Upload directories (excluded from Mutagen sync)
upload_dirs:
  - web/sites/default/files

# Performance mode
performance_mode: mutagen       # or none

# Disable settings management
disable_settings_management: false
```

## Environment Variables and Hooks

Set environment variables in `config.yaml`:

```yaml
web_environment:
  - SIMPLETEST_BASE_URL=https://my-drupal-site.ddev.site
  - SIMPLETEST_DB=mysql://db:db@db/db
  - BROWSERTEST_OUTPUT_DIRECTORY=/var/www/html/web/sites/simpletest/browser_output
  - MINK_DRIVER_ARGS_WEBDRIVER=["chrome",{"browserName":"chrome","chromeOptions":{"args":["--headless","--disable-gpu"]}},http://chromedriver:9515]
```

Hooks run at specific lifecycle points:

```yaml
hooks:
  post-start:
    - exec: composer install
    - exec: drush deploy
  post-import-db:
    - exec: drush cr
    - exec: drush updb -y
  pre-stop: []
  post-stop: []
  pre-start: []
```

## Multi-Site Configuration

For Drupal multi-site setups:

```yaml
additional_hostnames:
  - site2
  - site3

web_environment:
  - DRUPAL_SITES=default,site2,site3
```

Create site-specific settings in `web/sites/site2/settings.php`. Add to `web/sites/sites.php`:

```php
$sites['site2.ddev.site'] = 'site2';
$sites['site3.ddev.site'] = 'site3';
```

Each subsite can have its own database. Use a `docker-compose.*.yaml` override to add extra databases:

```yaml
# .ddev/docker-compose.site2-db.yaml
services:
  site2-db:
    container_name: ddev-${DDEV_SITENAME}-site2-db
    image: ddev/ddev-dbserver-mariadb-10.11:v1.23.0
    environment:
      MYSQL_DATABASE: db
      MYSQL_USER: db
      MYSQL_PASSWORD: db
    volumes:
      - site2-db:/var/lib/mysql
volumes:
  site2-db:
```

Then in `web/sites/site2/settings.ddev.php`:

```php
$databases['default']['default'] = [
  'database' => 'db',
  'username' => 'db',
  'password' => 'db',
  'host' => 'site2-db',
  'driver' => 'mysql',
];
```
