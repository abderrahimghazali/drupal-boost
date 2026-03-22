---
name: quality-check
description: Run full code quality suite (PHPCS, PHPStan, Drupal Check) on custom Drupal code.
argument-hint: [path or --all]
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, TodoWrite
---

# Drupal Code Quality Check

You are running the full quality suite on Drupal custom code. Follow these steps:

## Step 1: DETERMINE SCOPE

- If `$ARGUMENTS` contains a path, check that path only
- If `$ARGUMENTS` contains `--all`, check all custom code
- If no arguments, check `web/modules/custom/` and `web/themes/custom/`

Detect the environment (DDEV/Lando) and prefix commands accordingly.

## Step 2: RUN QUALITY TOOLS

Launch the `drupal-test-runner` agent to run all quality checks:

### PHPCS (Coding Standards)
```bash
ddev exec ./vendor/bin/phpcs --standard=Drupal,DrupalPractice PATH
```

### PHPStan (Static Analysis)
```bash
ddev exec ./vendor/bin/phpstan analyse PATH --level=6
```

### Drupal Check (Deprecations) — if available
```bash
ddev exec ./vendor/bin/drupal-check PATH
```

## Step 3: REPORT

Present results grouped by tool:

```
=== CODE QUALITY REPORT ===

## PHPCS (Coding Standards)
- Errors: X
- Warnings: Y
- [List top issues]

## PHPStan (Static Analysis)
- Errors: X
- [List top issues]

## Drupal Check (Deprecations)
- Deprecated APIs found: X
- [List deprecations]

## Summary
Total issues: X errors, Y warnings
Auto-fixable with phpcbf: Z issues
```

If issues are auto-fixable, offer to run `phpcbf`:
```bash
ddev exec ./vendor/bin/phpcbf --standard=Drupal,DrupalPractice PATH
```
