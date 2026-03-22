---
name: migrate-api
description: Drupal Migrate API for ETL data migration including source plugins, process plugins, destination plugins, migration groups, and migration dependencies. Use when building migrations, importing data, or migrating from another CMS/database.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Drupal Migrate API

The Migrate API follows an ETL (Extract-Transform-Load) pattern.

## Migration YAML Structure

```yaml
id: my_migration
label: 'Migrate articles from legacy database'
migration_group: my_migrations
migration_tags:
  - content

source:
  plugin: d7_node  # or csv, url, json, etc.
  node_type: article

process:
  title: title
  body/value: body
  body/format:
    plugin: default_value
    default_value: basic_html
  uid:
    plugin: migration_lookup
    migration: my_users_migration
    source: author_id
  field_tags:
    plugin: sub_process
    source: tags
    process:
      target_id:
        plugin: entity_generate
        source: name
        entity_type: taxonomy_term
        bundle: tags
        bundle_key: vid
        value_key: name

destination:
  plugin: entity:node
  default_bundle: article

migration_dependencies:
  required:
    - my_users_migration
  optional:
    - my_tags_migration
```

## Common Source Plugins

### Database Source
```yaml
source:
  plugin: d7_node
  node_type: article
  # Or custom SQL:
  plugin: custom_sql
  query: "SELECT id, title, body FROM legacy_articles"
```

### CSV Source (requires migrate_source_csv)
```yaml
source:
  plugin: csv
  path: /path/to/data.csv
  ids: [id]
  header_offset: 0
  fields:
    - name: id
    - name: title
    - name: body
```

### JSON/URL Source (requires migrate_plus)
```yaml
source:
  plugin: url
  data_fetcher_plugin: http
  data_parser_plugin: json
  urls:
    - 'https://api.example.com/articles'
  item_selector: /data
  fields:
    - name: id
      selector: /id
    - name: title
      selector: /attributes/title
  ids:
    id:
      type: integer
```

## Common Process Plugins

```yaml
process:
  # Direct copy
  title: source_title

  # Default value
  status:
    plugin: default_value
    default_value: 1

  # Value mapping
  field_type:
    plugin: static_map
    source: legacy_type
    map:
      news: article
      blog: blog_post

  # Entity lookup/generate
  uid:
    plugin: migration_lookup
    migration: users
    source: author_id

  # Date formatting
  created:
    plugin: format_date
    source: date
    from_format: 'Y-m-d H:i:s'
    to_format: 'U'

  # Concatenation
  path:
    plugin: concat
    source:
      - constants/prefix
      - slug
    delimiter: /

  # Skip empty
  field_image:
    - plugin: skip_on_empty
      source: image_url
      method: process
    - plugin: file_copy
      source: image_url
      destination: 'public://images/'

  # Callback
  title:
    plugin: callback
    callable: trim
    source: title
```

## Drush Migration Commands

```bash
# Run a migration
drush migrate:import my_migration

# Run with limit (for testing)
drush migrate:import my_migration --limit=10

# Check status
drush migrate:status

# Rollback
drush migrate:rollback my_migration

# Reset stuck migration
drush migrate:reset-status my_migration

# Run all in a group
drush migrate:import --group=my_migrations

# Update existing (re-import changed rows)
drush migrate:import my_migration --update
```

## Key Rules

- Always define `migration_dependencies` to ensure correct execution order
- Use `migration_lookup` for entity references between migrations
- Test with `--limit=10` before running full migration
- Use `entity_generate` for creating referenced entities on the fly
- Always add rollback support (`drush migrate:rollback`)
- For large datasets, consider memory limits and batch processing
- Use `migrate_plus` for URL/JSON/XML sources
- Use `migrate_tools` for advanced Drush commands and groups

Read reference files for details:
- `reference/source-plugins.md` for all source plugin types
- `reference/process-plugins.md` for process plugin reference
- `reference/destination-plugins.md` for destination plugin types
