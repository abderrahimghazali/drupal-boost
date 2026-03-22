---
name: deploy-check
description: Pre-deployment readiness check for Drupal projects. Validates config, dependencies, security, and deployment scripts.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, TodoWrite
---

# Pre-Deployment Readiness Check

You are checking if this Drupal project is ready for deployment. Run through each check:

## Check 1: Configuration Status

```bash
# Check for uncommitted config changes
drush config:status
```
- If config is out of sync, warn the user to export and commit

## Check 2: Composer Lock

- Verify `composer.lock` exists and is committed
- Run `composer validate` to check composer.json syntax
- Check for security advisories: `composer audit`

## Check 3: Database Updates

```bash
# Check for pending updates
drush updatedb --no-post-updates --no-cache-clear 2>&1 | head -20
```
- If updates exist, they will run during deployment

## Check 4: Git Status

- Check for uncommitted changes
- Check current branch
- Verify branch is up to date with remote

## Check 5: Code Quality Quick Check

- Check for debug functions in custom code: `var_dump`, `print_r`, `dpm`, `kint`, `dd`, `dsm`
- Check for `TODO` or `FIXME` comments in custom modules
- Check for `\Drupal::service()` calls in `src/` directories

## Check 6: Deployment Script

Look for deployment scripts and verify they follow correct order:
1. `drush updatedb`
2. `drush cache:rebuild`
3. `drush config:import`
4. `drush cache:rebuild`
5. `drush deploy:hook` (if using deploy hooks)

## Report

Present a deployment readiness report:

```
=== DEPLOYMENT READINESS CHECK ===

Config Status:    [PASS/FAIL] - Details
Composer Lock:    [PASS/FAIL] - Details
Security Audit:   [PASS/FAIL] - Details
Database Updates: [PASS/WARN] - Details
Git Status:       [PASS/FAIL] - Details
Code Quality:     [PASS/WARN] - Details
Deploy Script:    [PASS/WARN] - Details

Overall: READY / NOT READY
```

If NOT READY, list what needs to be fixed before deploying.
