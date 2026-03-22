# GitHub Actions CI/CD for Drupal

## Basic Drupal CI Workflow

```yaml
name: Drupal CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  coding-standards:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer, phpcs, phpstan

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: PHPCS
        run: |
          phpcs --standard=Drupal,DrupalPractice \
            --extensions=php,module,install,theme,inc \
            web/modules/custom/

      - name: PHPStan
        run: |
          phpstan analyse web/modules/custom/ \
            --level=6 \
            --configuration=phpstan.neon
```

## PHPUnit with MySQL Service

```yaml
  phpunit-mysql:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: drupal
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo_mysql, gd, zip
          coverage: xdebug

      - name: Cache Composer packages
        uses: actions/cache@v4
        with:
          path: vendor
          key: ${{ runner.os }}-composer-${{ hashFiles('composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run PHPUnit
        env:
          SIMPLETEST_DB: mysql://root:root@127.0.0.1:3306/drupal
          SIMPLETEST_BASE_URL: http://localhost:8080
          BROWSERTEST_OUTPUT_DIRECTORY: /tmp/browser_output
        run: |
          mkdir -p /tmp/browser_output
          php -S localhost:8080 -t web &
          vendor/bin/phpunit \
            --configuration web/core/phpunit.xml.dist \
            --testsuite unit,kernel,functional \
            web/modules/custom/
```

## PHPUnit with SQLite (Faster)

```yaml
  phpunit-sqlite:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo_sqlite, gd, zip

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run Unit and Kernel tests
        env:
          SIMPLETEST_DB: sqlite://localhost/sites/default/files/.ht.sqlite
        run: |
          vendor/bin/phpunit \
            --configuration web/core/phpunit.xml.dist \
            --testsuite unit,kernel \
            web/modules/custom/
```

## Matrix Testing (Multiple PHP/Drupal Versions)

```yaml
  test-matrix:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php-version: ['8.2', '8.3', '8.4']
        drupal-version: ['~10.4.0', '~11.1.0']
        exclude:
          - php-version: '8.2'
            drupal-version: '~11.1.0'

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: drupal
        ports: ['3306:3306']
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP ${{ matrix.php-version }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          extensions: pdo_mysql, gd, zip

      - name: Set Drupal version
        run: composer require drupal/core-recommended:${{ matrix.drupal-version }} --no-update

      - name: Install dependencies
        run: composer update --prefer-dist --no-progress

      - name: Run tests
        env:
          SIMPLETEST_DB: mysql://root:root@127.0.0.1:3306/drupal
        run: vendor/bin/phpunit --configuration web/core/phpunit.xml.dist web/modules/custom/
```

## Deployment Step Templates

```yaml
  deploy-production:
    needs: [coding-standards, phpunit-mysql]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/drupal
            git pull origin main
            composer install --no-dev --optimize-autoloader
            drush deploy -y
            drush cache:rebuild

      - name: Deploy via Platform.sh
        if: false  # Enable when using Platform.sh.
        run: |
          curl -sS https://platform.sh/cli/installer | php
          platform deploy --yes

      - name: Notify on success
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {"text": "Deployed ${{ github.sha }} to production"}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Caching Composer Dependencies

```yaml
      - name: Get Composer cache directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT

      - name: Cache Composer dependencies
        uses: actions/cache@v4
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: ${{ runner.os }}-composer-${{ hashFiles('composer.lock') }}
          restore-keys: |
            ${{ runner.os }}-composer-
```

For sites using `drupal/core-dev` for testing, cache the entire vendor directory for faster builds since Drupal's test dependencies are large.
