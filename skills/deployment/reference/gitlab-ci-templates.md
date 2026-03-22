# GitLab CI for Drupal Projects

## Drupal Association Official Template

For projects hosted on drupal.org, include the official template:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'
```

## Custom Pipeline Configuration

Full custom pipeline for a Drupal project:

```yaml
variables:
  MYSQL_ROOT_PASSWORD: root
  MYSQL_DATABASE: drupal
  SIMPLETEST_DB: mysql://root:root@mysql:3306/drupal
  SIMPLETEST_BASE_URL: http://localhost
  COMPOSER_ALLOW_SUPERUSER: 1

stages:
  - validate
  - test
  - deploy

default:
  image: drupalci/php-8.3-apache:production
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - vendor/

.mysql-service: &mysql-service
  services:
    - name: mysql:8.0
      alias: mysql
      variables:
        MYSQL_ROOT_PASSWORD: root
        MYSQL_DATABASE: drupal

before_script:
  - composer install --prefer-dist --no-progress
```

## Testing Stages

```yaml
phpcs:
  stage: validate
  script:
    - composer require --dev drupal/coder
    - vendor/bin/phpcs --standard=Drupal,DrupalPractice
        --extensions=php,module,install,theme,inc
        web/modules/custom/
  allow_failure: false

phpstan:
  stage: validate
  script:
    - vendor/bin/phpstan analyse web/modules/custom/
        --level=6
        --no-progress
  allow_failure: true

unit-tests:
  stage: test
  script:
    - vendor/bin/phpunit
        --configuration web/core/phpunit.xml.dist
        --testsuite unit
        --log-junit report-unit.xml
        web/modules/custom/
  artifacts:
    when: always
    reports:
      junit: report-unit.xml

kernel-tests:
  stage: test
  <<: *mysql-service
  script:
    - vendor/bin/phpunit
        --configuration web/core/phpunit.xml.dist
        --testsuite kernel
        --log-junit report-kernel.xml
        web/modules/custom/
  artifacts:
    when: always
    reports:
      junit: report-kernel.xml

functional-tests:
  stage: test
  <<: *mysql-service
  variables:
    BROWSERTEST_OUTPUT_DIRECTORY: /tmp/browser_output
  script:
    - mkdir -p /tmp/browser_output
    - apache2-foreground &
    - vendor/bin/phpunit
        --configuration web/core/phpunit.xml.dist
        --testsuite functional
        --log-junit report-functional.xml
        web/modules/custom/
  artifacts:
    when: always
    reports:
      junit: report-functional.xml
    paths:
      - /tmp/browser_output/
```

## Deployment Stages

```yaml
deploy-staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop
  script:
    - apt-get update && apt-get install -y openssh-client rsync
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | ssh-add -
    - rsync -avz --delete
        --exclude='.git'
        --exclude='web/sites/default/files'
        ./ $DEPLOY_USER@$STAGING_HOST:$DEPLOY_PATH/
    - ssh $DEPLOY_USER@$STAGING_HOST "cd $DEPLOY_PATH && drush deploy -y && drush cr"

deploy-production:
  stage: deploy
  environment:
    name: production
    url: https://www.example.com
  only:
    - main
  when: manual
  script:
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | ssh-add -
    - ssh $DEPLOY_USER@$PRODUCTION_HOST "
        cd $DEPLOY_PATH &&
        git pull origin main &&
        composer install --no-dev --optimize-autoloader &&
        drush deploy -y &&
        drush cr"
```

## drupal.org Project CI Setup

For contrib modules on drupal.org:

```yaml
# .gitlab-ci.yml at project root.
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'

variables:
  OPT_IN_TEST_PREVIOUS_MAJOR: 1
  OPT_IN_TEST_NEXT_MAJOR: 1
  OPT_IN_TEST_NEXT_MINOR: 1
  OPT_IN_TEST_MAX_PHP: 1
  _PHPUNIT_EXTRA: --verbose
```

Variables reference:
- `OPT_IN_TEST_PREVIOUS_MAJOR`: Test against Drupal 10 (when project supports D11).
- `OPT_IN_TEST_NEXT_MAJOR`: Test against next major Drupal version.
- `OPT_IN_TEST_NEXT_MINOR`: Test against next minor release.
- `OPT_IN_TEST_MAX_PHP`: Test with the latest PHP version.

## Multi-Version Matrix

```yaml
test-matrix:
  stage: test
  parallel:
    matrix:
      - PHP_VERSION: ['8.2', '8.3', '8.4']
        DRUPAL_CORE: ['10.4.x', '11.1.x']
  image: drupalci/php-${PHP_VERSION}-apache:production
  <<: *mysql-service
  script:
    - composer require drupal/core-recommended:~${DRUPAL_CORE} --no-update
    - composer update --prefer-dist
    - vendor/bin/phpunit
        --configuration web/core/phpunit.xml.dist
        web/modules/custom/
```
