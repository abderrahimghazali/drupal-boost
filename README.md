# drupal-boost

The most comprehensive Drupal 11 development toolkit for Claude Code. Module scaffolding, theme development, configuration management, migration, security auditing, testing, deployment, and more.

## Installation

```bash
claude plugin install drupal-boost
```

Or load directly:

```bash
claude --plugin-dir ./drupal-boost
```

## Quick Start

```
/drupal-boost:boost-module my_module "Custom content management module"
/drupal-boost:security-audit
/drupal-boost:quality-check
```

## Commands

| Command | Description |
|---------|-------------|
| `/drupal-boost:boost-feature` | Full 7-phase feature development workflow with parallel agents |
| `/drupal-boost:boost-module` | Guided multi-phase module scaffolding |
| `/drupal-boost:boost-theme` | Theme creation with Single Directory Component scaffolding |
| `/drupal-boost:boost-migration` | Guided migration builder with source analysis |
| `/drupal-boost:boost-recipe` | Scaffold a Drupal Recipe |
| `/drupal-boost:security-audit` | Comprehensive security audit with confidence scoring |
| `/drupal-boost:deploy-check` | Pre-deployment readiness check |
| `/drupal-boost:quality-check` | Run PHPCS + PHPStan + Drupal Check |

## Agents

| Agent | Color | Model | Purpose |
|-------|-------|-------|---------|
| `drupal-explorer` | Blue | Haiku | Fast codebase analysis, traces services, hooks, routing, entities |
| `drupal-architect` | Green | Sonnet | Designs module/feature architectures with implementation blueprints |
| `drupal-reviewer` | Orange | Sonnet | Code review for Drupal standards, DI patterns, deprecated APIs |
| `drupal-security-auditor` | Red | Sonnet | Deep security audit: XSS, SQL injection, access bypass, CSRF |
| `drupal-migration-analyst` | Purple | Sonnet | Analyzes source data, maps to Drupal entities, generates migration YAML |
| `drupal-test-runner` | Teal | Sonnet | Runs tests, analyzes failures, suggests and applies fixes |

## Skills (Auto-Triggered)

Skills activate automatically when Claude detects relevant context:

| Skill | Triggers On |
|-------|-------------|
| `module-scaffold` | Creating modules, services, plugins, controllers, forms, hooks, entities |
| `theme-development` | Theme, SDC, Twig, Starterkit, component work |
| `config-management` | Config export/import, Config Split, environment config |
| `recipes-api` | Drupal Recipes, site templates, automated setup |
| `rest-jsonapi` | REST, JSON:API, decoupled/headless architecture |
| `ddev-workflow` | DDEV, Lando, local dev environment, Xdebug, Solr, Redis |
| `quality-testing` | PHPUnit, PHPStan, PHPCS, Rector, Nightwatch |
| `drupal-security` | Security review, XSS, SQL injection, permissions |
| `deployment` | Deploy, CI/CD, GitHub Actions, GitLab CI |
| `migrate-api` | Data migration, ETL, source/process/destination plugins |
| `caching-strategy` | Cache tags, contexts, max-age, render caching, BigPipe |
| `contrib-publishing` | Publishing modules to drupal.org |
| `workspaces` | Content staging, editorial workflows |

## Hooks

| Event | Purpose |
|-------|---------|
| `SessionStart` | Detects Drupal version, DDEV/Lando environment |
| `PreToolUse (Write/Edit)` | Validates PSR-4 namespaces, .info.yml structure |
| `PreToolUse (Bash)` | Adapts commands for DDEV/Lando |
| `PostToolUse (Write/Edit)` | Checks Drupal coding standards |

## Environment Support

| Environment | Status |
|-------------|--------|
| DDEV | Fully supported |
| Lando | Fully supported |

## Drupal Compatibility

- Drupal 11 (primary target)
- Drupal 10.3+ (most features)
- OOP Hook attributes require Drupal 11.1+

## Workflow Architecture

```
Tier 1: AUTOMATIC — SessionStart hook detects environment
Tier 2: SKILLS   — Auto-triggered by conversation context
Tier 3: COMMANDS — User-invoked multi-phase workflows
Cross-cutting: HOOKS — Validate code on every write/edit
```

The flagship `/drupal-boost:boost-feature` command orchestrates a 7-phase workflow:
1. Discovery (gather requirements)
2. Exploration (parallel drupal-explorer agents)
3. Clarifying Questions (fill gaps)
4. Architecture (parallel drupal-architect agents with multiple approaches)
5. Implementation (build chosen approach)
6. Quality Review (parallel drupal-reviewer + drupal-security-auditor)
7. Summary (files created, next steps)

## License

MIT
