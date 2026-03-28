---
name: contrib-publishing
description: Publishing contributed modules to drupal.org including coding standards, documentation requirements, GitLab CI templates, and the module review process. Use when preparing a module for drupal.org submission.
allowed-tools: Read, Write, Edit, Bash, Grep
---

# Publishing to drupal.org

## Module Checklist

Before submitting a module to drupal.org:

### Code Quality
- [ ] Follows Drupal coding standards (run PHPCS with Drupal/DrupalPractice)
- [ ] Passes PHPStan at level 6+
- [ ] No deprecated API usage (run Drupal Check)
- [ ] All classes follow PSR-4 autoloading
- [ ] No hardcoded strings — all user-facing text uses `t()`
- [ ] Config schema defined for all configuration

### Documentation
- [ ] `README.md` with:
  - Module name and description
  - Requirements (Drupal version, PHP version, dependencies)
  - Installation instructions
  - Configuration guide
  - Usage examples
  - Troubleshooting
  - Maintainer info
- [ ] `INSTALL.md` if installation is complex
- [ ] Inline code documentation (PHPDoc on all public methods)
- [ ] Help hook or help page for in-Drupal documentation

### Testing
- [ ] PHPUnit tests (at minimum Unit tests, ideally Kernel too)
- [ ] Tests pass on all supported Drupal versions
- [ ] Test coverage for critical functionality

### Security
- [ ] Security review passed (no XSS, SQL injection, access bypass)
- [ ] Permissions defined with proper `restrict access` where needed
- [ ] All entity queries use `accessCheck(TRUE)`
- [ ] File uploads validated

### Structure
- [ ] Clean `.info.yml` with proper metadata
- [ ] `composer.json` with proper package name (`drupal/MODULE_NAME`)
- [ ] `.gitignore` excludes vendor, node_modules
- [ ] No generated files committed (compiled CSS/JS, vendor/)

## GitLab CI for drupal.org

Add `.gitlab-ci.yml` to your module:

```yaml
include:
  - project: $_GITLAB_TEMPLATES_REPO
    ref: $_GITLAB_TEMPLATES_REF
    file:
      - '/includes/include.drupalci.main.yml'
```

This runs the Drupal Association's standard CI pipeline.

## composer.json for Contrib

```json
{
  "name": "drupal/MODULE_NAME",
  "type": "drupal-module",
  "description": "Brief description.",
  "license": "GPL-2.0-or-later",
  "homepage": "https://www.drupal.org/project/MODULE_NAME",
  "require": {
    "drupal/core": "^10 || ^11"
  },
  "extra": {
    "drupal": {
      "version": "VERSION",
      "datestamp": "DATESTAMP"
    }
  }
}
```

## Submission Process

1. Create a project on drupal.org (Project > Add new project)
2. Set up Git repository on git.drupalcode.org
3. Push your code
4. Create a release (tag with semantic version)
5. Request security coverage (optional, recommended)
6. Promote via blog post, Slack, Drupal community channels

## Key Rules

- Use GPL-2.0-or-later license (required for drupal.org)
- Follow semantic versioning for releases
- Respond to issue queue reports promptly
- Apply for security coverage to get security team review
- Keep the module focused — do one thing well
