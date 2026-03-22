---
name: boost-migration
description: Guided migration builder with source data analysis and Drupal Migrate API YAML generation.
argument-hint: <source description>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, TodoWrite, AskUserQuestion
---

# Drupal Migration Builder

You are building a data migration into Drupal. Follow these phases:

## Phase 1: SOURCE ANALYSIS

Launch a `drupal-migration-analyst` agent to analyze the source data:
- If database: examine schema, tables, relationships, row counts
- If CSV/files: read headers, sample data, identify data types
- If API: examine endpoints, response structure, authentication
- If another Drupal site: identify version and content types

Present findings to the user for validation.

## Phase 2: ENTITY MAPPING

Based on the analysis, propose mapping:
- Source entities/tables → Drupal entity types (node, taxonomy, user, media, custom)
- Source fields → Drupal field types
- Source relationships → Entity references
- Identify fields that need creation

Ask the user to approve or adjust the mapping.

## Phase 3: MIGRATION YAML GENERATION

Create the migration module:
- `MODULE_NAME.info.yml` with `migrate` dependency
- Migration YAML files in `migrations/` or `config/install/`
- Custom source plugins (if non-standard source)
- Custom process plugins (if complex transformations needed)

For each migration, generate:
```yaml
id: migrate_ENTITY
label: 'Migrate ENTITY from SOURCE'
migration_group: MODULE_NAME
source:
  plugin: ...
process:
  field: source_field
destination:
  plugin: entity:ENTITY_TYPE
migration_dependencies:
  required: [...]
```

## Phase 4: TEST & REFINE

Provide commands to test:
```bash
# Check status
drush migrate:status --group=MODULE_NAME

# Test with limit
drush migrate:import migrate_ENTITY --limit=10

# Check for errors
drush migrate:messages migrate_ENTITY

# Rollback if needed
drush migrate:rollback migrate_ENTITY
```

## Phase 5: SUMMARY

List all created files, migration order, and provide:
1. Full import command: `drush migrate:import --group=MODULE_NAME`
2. Rollback command: `drush migrate:rollback --group=MODULE_NAME`
3. Known data quality issues to watch for
4. Post-migration validation steps
