# Migration Process Plugins

## Basic Value Plugins

### get

Maps source to destination directly:

```yaml
process:
  title: title              # Shorthand for get.
  field_name:
    plugin: get
    source: source_field
```

### default_value

Sets a fixed value:

```yaml
process:
  langcode:
    plugin: default_value
    default_value: en
  type:
    plugin: default_value
    default_value: article
```

### static_map

Maps source values to destination values:

```yaml
process:
  field_status:
    plugin: static_map
    source: legacy_status
    map:
      active: published
      inactive: draft
      removed: archived
    default_value: draft       # Fallback if no match.
    bypass: false              # Set true to pass unmapped values through.
```

### callback

Applies a PHP callable:

```yaml
process:
  title:
    plugin: callback
    callable: trim
    source: title
  field_email:
    plugin: callback
    callable: strtolower
    source: email
```

## Entity Reference Plugins

### migration_lookup

References entities created by another migration:

```yaml
process:
  uid:
    plugin: migration_lookup
    migration: users
    source: author_id
  field_tags:
    plugin: migration_lookup
    migration: tags
    source: tag_ids
    no_stub: false             # Create stub entities if lookup fails.
```

### entity_generate

Looks up or creates referenced entities:

```yaml
process:
  field_category:
    plugin: entity_generate
    source: category_name
    entity_type: taxonomy_term
    bundle_key: vid
    bundle: categories
    value_key: name
    values:
      description: category_description
```

### entity_lookup

Looks up existing entities without creating new ones:

```yaml
process:
  field_author:
    plugin: entity_lookup
    source: author_email
    entity_type: user
    value_key: mail
```

## String Manipulation Plugins

### concat

Joins multiple source values:

```yaml
process:
  field_full_name:
    plugin: concat
    source:
      - first_name
      - last_name
    delimiter: ' '
```

### explode

Splits a string into an array:

```yaml
process:
  field_tags:
    - plugin: explode
      source: tags_string
      delimiter: ','
    - plugin: callback
      callable: trim
    - plugin: entity_generate
      entity_type: taxonomy_term
      bundle_key: vid
      bundle: tags
      value_key: name
```

### flatten

Flattens nested arrays:

```yaml
process:
  field_values:
    plugin: flatten
    source: nested_array
```

### extract

Gets a specific value from an array:

```yaml
process:
  field_image/alt:
    plugin: extract
    source: image_data
    index:
      - alt
```

## Date and Conditional Plugins

### format_date

Converts date formats:

```yaml
process:
  created:
    plugin: format_date
    source: publish_date
    from_format: 'm/d/Y'
    to_format: 'U'            # Unix timestamp.
    from_timezone: 'America/New_York'
    to_timezone: 'UTC'
```

### skip_on_empty

Skips row or sets default when source is empty:

```yaml
process:
  field_optional:
    plugin: skip_on_empty
    source: optional_field
    method: process            # Skip only this field.
  title:
    plugin: skip_on_empty
    source: title
    method: row                # Skip entire row.
    message: 'Skipped row with empty title.'
```

### skip_row_if_not_set

Skips row when source property is missing:

```yaml
process:
  title:
    plugin: skip_row_if_not_set
    source: title
    index: value
    message: 'Title not found.'
```

## sub_process for Multi-Value Fields

Processes each item in an array independently:

```yaml
process:
  field_links:
    plugin: sub_process
    source: links
    process:
      uri:
        plugin: get
        source: url
      title:
        plugin: get
        source: link_text
```

Nested sub_process with entity references:

```yaml
process:
  field_paragraphs:
    plugin: sub_process
    source: content_blocks
    process:
      target_id:
        plugin: migration_lookup
        migration: paragraphs
        source: block_id
      target_revision_id:
        plugin: migration_lookup
        migration: paragraphs
        source: block_id
```

## Chaining Process Plugins

Plugins chain using pipeline syntax:

```yaml
process:
  field_slug:
    - plugin: get
      source: title
    - plugin: callback
      callable: strtolower
    - plugin: callback
      callable: trim
    - plugin: machine_name
```

## Custom Process Plugin

```php
namespace Drupal\mymodule\Plugin\migrate\process;

use Drupal\migrate\MigrateExecutableInterface;
use Drupal\migrate\ProcessPluginBase;
use Drupal\migrate\Row;

/**
 * Converts legacy HTML to clean markup.
 *
 * @MigrateProcessPlugin(
 *   id = "clean_html",
 *   handle_multiples = FALSE
 * )
 */
class CleanHtml extends ProcessPluginBase {

  public function transform($value, MigrateExecutableInterface $migrate_executable, Row $row, $destination_property) {
    if (empty($value)) {
      return $value;
    }

    // Strip legacy font tags and classes.
    $value = preg_replace('/<font[^>]*>/', '', $value);
    $value = str_replace('</font>', '', $value);

    // Convert legacy image paths.
    $base = $this->configuration['legacy_base_url'] ?? '';
    $value = str_replace('src="/images/', 'src="' . $base . '/images/', $value);

    return $value;
  }

}
```

Usage:

```yaml
process:
  body/value:
    plugin: clean_html
    source: body
    legacy_base_url: 'https://old.example.com'
  body/format:
    plugin: default_value
    default_value: full_html
```
