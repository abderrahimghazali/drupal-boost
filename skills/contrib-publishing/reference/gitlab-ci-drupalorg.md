# drupal.org GitLab CI

## Setting Up CI on drupal.org Projects

Every project on drupal.org has GitLab CI available automatically. Add a `.gitlab-ci.yml` to your project root to enable it.

Minimal setup using Drupal Association templates:

```yaml
# .gitlab-ci.yml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'
```

This provides:
- PHPUnit testing against the current Drupal stable release.
- PHPCS coding standards checking (Drupal and DrupalPractice).
- Composer validation.
- PHP compatibility checking.

## Drupal Association Template Usage

### Available Template Files

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      # Required: main pipeline definition.
      - '/includes/include.drupalci.main.yml'
      # Required: default variable definitions.
      - '/includes/include.drupalci.variables.yml'
      # Required: workflow rules (when pipelines run).
      - '/includes/include.drupalci.workflows.yml'
```

### Customizing with Variables

Override default behavior with variables:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'

variables:
  # Test against previous major Drupal version.
  OPT_IN_TEST_PREVIOUS_MAJOR: 1

  # Test against next major Drupal version.
  OPT_IN_TEST_NEXT_MAJOR: 1

  # Test against next minor Drupal version (dev).
  OPT_IN_TEST_NEXT_MINOR: 1

  # Test with the maximum supported PHP version.
  OPT_IN_TEST_MAX_PHP: 1

  # Skip specific jobs.
  SKIP_PHPCS: 0         # Set to 1 to skip coding standards.
  SKIP_PHPUNIT: 0       # Set to 1 to skip tests.
  SKIP_COMPOSER: 0      # Set to 1 to skip composer validation.

  # Extra PHPUnit flags.
  _PHPUNIT_EXTRA: '--verbose --testdox'

  # Custom test directory (defaults to module root).
  _PHPUNIT_TESTDIR: ''

  # Additional Composer dependencies needed for tests.
  _COMPOSER_EXTRA: 'drupal/token drupal/pathauto'
```

### Adding Custom Jobs

Extend the templates with custom jobs:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'

# Add PHPStan analysis.
phpstan:
  stage: validate
  image: drupalci/php-8.3-apache:production
  allow_failure: true
  script:
    - composer install --prefer-dist
    - composer require --dev phpstan/phpstan phpstan/extension-installer mglaman/phpstan-drupal
    - vendor/bin/phpstan analyse . --level=6 --no-progress
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH
```

## Test Matrix Configuration

Test across multiple Drupal and PHP versions:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
      - '/includes/include.drupalci.variables.yml'
      - '/includes/include.drupalci.workflows.yml'

variables:
  # Enable all version testing.
  OPT_IN_TEST_PREVIOUS_MAJOR: 1
  OPT_IN_TEST_NEXT_MAJOR: 1
  OPT_IN_TEST_NEXT_MINOR: 1
  OPT_IN_TEST_MAX_PHP: 1
```

This creates jobs for:
- Current stable Drupal + minimum PHP.
- Current stable Drupal + maximum PHP.
- Previous major Drupal version.
- Next major Drupal dev version.
- Next minor Drupal dev version.

For contrib modules supporting both Drupal 10 and 11:

```json
// composer.json
{
  "require": {
    "drupal/core": "^10.3 || ^11"
  }
}
```

## Handling CI Failures

### Coding Standards Failures

View the `phpcs` job log. Common fixes:

```bash
# Run locally to see all issues.
vendor/bin/phpcs --standard=Drupal,DrupalPractice \
  --extensions=php,module,install,theme,inc .

# Auto-fix.
vendor/bin/phpcbf --standard=Drupal,DrupalPractice \
  --extensions=php,module,install,theme,inc .
```

### PHPUnit Failures

Debug test failures locally:

```bash
# Run specific test class.
vendor/bin/phpunit --configuration web/core/phpunit.xml.dist \
  web/modules/contrib/my_module/tests/src/Unit/MyServiceTest.php

# Run with verbose output.
vendor/bin/phpunit --verbose --testdox \
  web/modules/contrib/my_module/tests/
```

### Composer Validation Failures

```bash
# Validate composer.json.
composer validate --strict

# Common issues:
# - Missing license field.
# - Invalid package name (must be drupal/machine_name).
# - Version constraint conflicts.
```

### Next Major/Minor Failures

When `OPT_IN_TEST_NEXT_MAJOR` or `OPT_IN_TEST_NEXT_MINOR` fails:
- Check for deprecated API usage. Run `drupal-check`:

```bash
composer require --dev mglaman/drupal-check
vendor/bin/drupal-check --deprecations web/modules/contrib/my_module/
```

- Review Drupal change records for breaking changes.
- Update code to use replacement APIs while maintaining backward compatibility.
- Use version-conditional code when necessary:

```php
if (version_compare(\Drupal::VERSION, '11.0', '>=')) {
  // Drupal 11+ code path.
}
else {
  // Drupal 10 code path.
}
```

### Allowing Failures

For forward-compatibility jobs that are expected to fail temporarily:

```yaml
variables:
  # These jobs run but won't block merge requests.
  OPT_IN_TEST_NEXT_MAJOR: 1
  _ALLOW_FAILURE_NEXT_MAJOR: 1
```
