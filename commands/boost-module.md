---
name: boost-module
description: Guided multi-phase module scaffolding for Drupal 11 with exploration, architecture design, and quality review.
argument-hint: <module_name> [description]
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, TodoWrite, AskUserQuestion
---

# Drupal 11 Module Scaffolding

You are scaffolding a new Drupal 11 module. Follow these phases:

## Phase 1: DISCOVERY

Parse the arguments:
- `$ARGUMENTS[0]` = module machine name (snake_case)
- `$ARGUMENTS[1]` = module description (optional)

Ask the user what the module needs:
- What does the module do?
- Does it need custom entities? (content entity, config entity)
- Does it need routes/pages? (controllers, forms)
- Does it need plugins? (blocks, fields, queue workers)
- Does it need services?
- Does it need hooks?
- Does it need REST/API endpoints?
- Does it need configuration? (admin settings form)

## Phase 2: EXPLORATION

Launch a `drupal-explorer` agent to:
- Check for existing modules with similar functionality
- Identify patterns and conventions used in the project
- Find services and entities that the new module should interact with
- Read CLAUDE.md for project-specific conventions

## Phase 3: ARCHITECTURE

Launch a `drupal-architect` agent to:
- Design the module architecture based on requirements
- Propose file structure, services, entities, plugins
- Identify which Drupal APIs to use
- Plan the dependency injection graph

Present the architecture to the user for approval.

## Phase 4: IMPLEMENTATION

Scaffold all files based on the approved architecture:

### Always create:
- `MODULE_NAME.info.yml`

### Create as needed:
- `MODULE_NAME.services.yml` (if services are needed)
- `MODULE_NAME.routing.yml` (if routes are needed)
- `MODULE_NAME.permissions.yml` (if custom permissions)
- `MODULE_NAME.links.menu.yml` (if menu items)
- `MODULE_NAME.libraries.yml` (if CSS/JS)
- `src/` classes (controllers, forms, services, entities, plugins)
- `config/schema/` (config schema for any configuration)
- `config/install/` (default configuration)
- `templates/` (Twig templates)
- `tests/src/Unit/` (unit tests)
- `tests/src/Kernel/` (kernel tests)

## Phase 5: QUALITY REVIEW

Launch `drupal-reviewer` to check the scaffolded code for:
- Coding standards compliance
- Proper DI patterns
- Complete cache metadata
- Config schema correctness

Fix any issues found.

## Phase 6: SUMMARY

List all created files and provide next steps:
1. Enable: `drush en MODULE_NAME -y`
2. Clear cache: `drush cr`
3. Test: provide specific test commands
4. Export config if needed: `drush cex`
