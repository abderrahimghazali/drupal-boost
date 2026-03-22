# drupal-boost

The most comprehensive Drupal 11 development toolkit for Claude Code. Module scaffolding, theme development, configuration management, migration, security auditing, testing, deployment, and more.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Commands](#commands)
- [Agents](#agents)
- [Skills](#skills)
- [Hooks](#hooks)
- [Environment Support](#environment-support)
- [Drupal Compatibility](#drupal-compatibility)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI v1.0+
- `jq` installed (used by hook scripts for JSON processing)
- For full functionality within a Drupal project:
  - PHP 8.2+ (Drupal 11 requirement)
  - Composer
  - A Drupal 10.3+ or 11.x project
  - Optionally: [DDEV](https://ddev.readthedocs.io/) or [Lando](https://lando.dev/) for local development

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

## How It Works

drupal-boost operates on a 3-tier architecture that combines automatic detection, contextual skills, and user-invoked workflows:

```
┌─────────────────────────────────────────────────────────┐
│  Tier 1: AUTOMATIC                                      │
│  SessionStart hook detects Drupal version, DDEV/Lando,  │
│  PHP version, Composer, and Drush availability.         │
├─────────────────────────────────────────────────────────┤
│  Tier 2: SKILLS (Auto-Triggered)                        │
│  13 skills activate based on conversation context.      │
│  Ask about migrations → migrate-api skill loads.        │
│  Ask about caching → caching-strategy skill loads.      │
├─────────────────────────────────────────────────────────┤
│  Tier 3: COMMANDS (User-Invoked)                        │
│  8 slash commands for multi-phase workflows.            │
│  /boost-feature runs a full 7-phase dev cycle.          │
├─────────────────────────────────────────────────────────┤
│  Cross-cutting: HOOKS                                   │
│  Every Write/Edit is validated for PSR-4 namespaces,    │
│  .info.yml structure, and Drupal coding standards.      │
│  Bash commands are adapted for DDEV/Lando.              │
└─────────────────────────────────────────────────────────┘
```

The flagship `/drupal-boost:boost-feature` command orchestrates a 7-phase workflow:

1. **Discovery** — gather requirements from the user
2. **Exploration** — parallel `drupal-explorer` agents analyze the codebase
3. **Clarifying Questions** — fill knowledge gaps
4. **Architecture** — parallel `drupal-architect` agents propose multiple approaches
5. **Implementation** — build the chosen approach
6. **Quality Review** — parallel `drupal-reviewer` + `drupal-security-auditor` agents
7. **Summary** — files created, next steps, manual testing guidance

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

## Troubleshooting

**Plugin not activating skills?**
Skills are triggered by conversation context. Mention the topic explicitly (e.g., "I need to set up a migration from Drupal 7") to activate the relevant skill.

**Hook scripts failing?**
Ensure `jq` is installed (`brew install jq` on macOS, `apt install jq` on Ubuntu). Hook scripts require `jq` for JSON parsing.

**DDEV/Lando not detected?**
The SessionStart hook looks for `.ddev/config.yaml` or `.lando.yml` in your working directory. Make sure you launch Claude Code from the project root.

**Commands not found?**
Verify the plugin is installed with `claude plugin list`. If loading directly, ensure the path points to the plugin root directory containing `.claude-plugin/plugin.json`.

**Namespace validation blocking writes?**
The PreToolUse hook validates PSR-4 namespaces for files under `modules/*/src/`. If your project uses a non-standard module path, the validation will be skipped.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this plugin.

## License

MIT
