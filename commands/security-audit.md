---
name: security-audit
description: Run a comprehensive security audit on the current Drupal project covering XSS, SQL injection, access bypass, CSRF, and dependency vulnerabilities.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, TodoWrite
---

# Drupal Security Audit

You are running a comprehensive security audit. Follow these steps:

## Step 1: ENVIRONMENT CHECK

Verify this is a Drupal project and identify:
- Drupal version
- Custom modules location (`web/modules/custom/`)
- Custom themes location (`web/themes/custom/`)
- Whether `composer.lock` exists

## Step 2: DEPENDENCY AUDIT

Run `composer audit` to check for known vulnerabilities in dependencies:
```bash
# DDEV
ddev composer audit
# Lando
lando composer audit
# Native
composer audit
```

Report any vulnerabilities found with severity levels.

## Step 3: CODE AUDIT

Launch the `drupal-security-auditor` agent to perform deep code analysis on all custom modules and themes. The agent will check for:
- XSS vulnerabilities (Twig |raw, Markup::create with user input)
- SQL injection (string concatenation in queries)
- Access bypass (missing accessCheck, improper route permissions)
- CSRF issues (state changes via GET, missing tokens)
- File handling issues (unvalidated uploads)
- Information disclosure (debug functions, verbose errors)
- Hardcoded credentials

## Step 4: REPORT

Present the combined report:
1. **Dependency vulnerabilities** from `composer audit`
2. **Code audit findings** from `drupal-security-auditor`, grouped by severity
3. **Summary** with counts per severity level
4. **Recommended actions** prioritized by risk

Format as a clear, actionable report that can be shared with the team.
