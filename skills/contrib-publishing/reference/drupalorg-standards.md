# drupal.org Publishing Standards

## Module Naming Conventions

- Machine name: lowercase, underscores only. Example: `my_module`.
- Must be unique across all drupal.org projects.
- Avoid generic names (`utils`, `helpers`). Be descriptive: `commerce_stock_notifications`.
- Do not prefix with `drupal_` (redundant on drupal.org).
- Human-readable name: Title Case. Example: "My Module".
- Namespace: `Drupal\my_module`.

Project page URL becomes: `https://www.drupal.org/project/my_module`.

## README Template

Every module must have a `README.md` at its root:

```markdown
# My Module

## Introduction

Brief description of what the module does and the problem it solves.

## Requirements

- Drupal 11.x
- [Token](https://www.drupal.org/project/token) module

## Installation

Install as you would normally install a contributed Drupal module.
See [Installing Modules](https://www.drupal.org/docs/extending-drupal/installing-modules)
for further information.

## Configuration

1. Navigate to Administration > Configuration > My Module.
2. Configure the settings as needed.

## Usage

Describe how to use the module after configuration.

## Maintainers

- Jane Doe - [janedoe](https://www.drupal.org/u/janedoe)
```

## composer.json Requirements

Every module must have a `composer.json`:

```json
{
  "name": "drupal/my_module",
  "description": "Brief description of the module.",
  "type": "drupal-module",
  "license": "GPL-2.0-or-later",
  "homepage": "https://www.drupal.org/project/my_module",
  "support": {
    "issues": "https://www.drupal.org/project/issues/my_module",
    "source": "https://git.drupalcode.org/project/my_module"
  },
  "require": {
    "drupal/core": "^10.3 || ^11"
  },
  "require-dev": {
    "drupal/core-dev": "^10.3 || ^11"
  }
}
```

Key points:
- `name` must be `drupal/machine_name`.
- `type` must be `drupal-module` (or `drupal-theme`, `drupal-profile`).
- `license` must be `GPL-2.0-or-later`.
- Specify compatible Drupal core versions in `require`.

## Coding Standards Requirements

All drupal.org code must pass Drupal coding standards:

```bash
# Install Coder.
composer require --dev drupal/coder

# Run checks.
vendor/bin/phpcs --standard=Drupal,DrupalPractice \
  --extensions=php,module,install,theme,inc,yml \
  web/modules/custom/my_module/

# Auto-fix what can be fixed.
vendor/bin/phpcbf --standard=Drupal,DrupalPractice \
  --extensions=php,module,install,theme,inc \
  web/modules/custom/my_module/
```

Critical standards:
- All functions and methods must have docblocks.
- Use type hints for parameters and return types.
- Two-space indentation, no tabs.
- Lines must not exceed 80 characters (comments) or reasonable length (code).
- Use `\Drupal::service()` only in procedural code; use dependency injection in OOP.
- `.module` files should contain only hook implementations.
- Use strict comparison (`===`) unless type coercion is intentional.

## Security Coverage Application

To get the "Covered by Drupal's security advisory policy" badge:

1. Request via project page: Edit > Security advisory coverage > Apply.
2. Requirements before applying:
   - Stable release published (not just dev or alpha/beta).
   - Passes automated security review.
   - No known security issues in issue queue.
   - Active maintainer responding to issues.
3. Security team reviews code for:
   - Proper input sanitization (no raw user input in output).
   - Parameterized database queries.
   - Access checks on all routes and entity operations.
   - CSRF protection on state-changing operations.
   - Safe file handling.
4. Common rejection reasons:
   - Using `\Drupal\Component\Utility\Html::decodeEntities()` on user input before output.
   - Missing access checks in controllers.
   - `#markup` with unsanitized variables.

## Release Management

### Version numbering

Drupal contrib follows semantic versioning: `MAJOR.MINOR.PATCH`.

```
2.0.0       Major release (breaking changes).
2.1.0       Minor release (new features, backward-compatible).
2.1.3       Patch release (bug fixes only).
2.2.0-beta1 Pre-release.
2.2.0-rc1   Release candidate.
```

### Creating a release

```bash
# Tag the release.
git tag 2.1.0
git push origin 2.1.0
```

Then on drupal.org: Project > Releases > Add new release > select tag.

### Release notes template

```markdown
## Changes since 2.0.0

### New features
- Added support for media entities (#3456789).
- New permission for managing widget settings.

### Bug fixes
- Fixed fatal error when node has no author (#3456790).
- Corrected cache tag invalidation on term update.

### Deprecated
- `my_module_legacy_function()` is deprecated. Use `MyService::newMethod()` instead.
```

### Branch strategy

- `1.0.x`: Maintenance branch for 1.x releases.
- `2.0.x`: Active development branch.
- Tags for releases: `1.0.5`, `2.0.0-beta1`.

Maintain one supported major version at minimum. Provide an upgrade path between major versions using update hooks.
