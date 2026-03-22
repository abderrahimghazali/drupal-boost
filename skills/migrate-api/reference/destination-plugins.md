# Migration Destination Plugins

## entity:node

Most common destination for content migration:

```yaml
id: articles
label: 'Migrate articles'
source:
  plugin: d7_node
  node_type: article
destination:
  plugin: entity:node
  default_bundle: article
  # Preserve original node IDs.
  overwrite_properties:
    - title
    - body
    - field_tags
process:
  nid: nid
  type:
    plugin: default_value
    default_value: article
  title: title
  uid:
    plugin: migration_lookup
    migration: users
    source: uid
  status: status
  created: created
  changed: changed
  body/value: body_value
  body/summary: body_summary
  body/format:
    plugin: static_map
    source: body_format
    map:
      1: full_html
      2: basic_html
    default_value: basic_html
```

## entity:user

```yaml
id: users
destination:
  plugin: entity:user
process:
  uid: uid
  name: username
  mail: email
  status: is_active
  created: created
  field_first_name: first_name
  field_last_name: last_name
  roles:
    plugin: static_map
    source: legacy_role
    map:
      admin: administrator
      writer: editor
      reader: authenticated
```

Passwords: use `user_password` process plugin to handle hashed passwords from D7.

## entity:taxonomy_term

```yaml
id: tags
destination:
  plugin: entity:taxonomy_term
  default_bundle: tags
process:
  tid: tid
  vid:
    plugin: default_value
    default_value: tags
  name: name
  description/value: description
  weight: weight
  parent:
    plugin: migration_lookup
    migration: tags
    source: parent_tid
```

## entity:media

```yaml
id: media_images
destination:
  plugin: entity:media
  default_bundle: image
process:
  name: filename
  field_media_image/target_id:
    plugin: migration_lookup
    migration: files
    source: fid
  field_media_image/alt: alt_text
  field_media_image/title: title_text
  uid:
    plugin: migration_lookup
    migration: users
    source: uid
  status:
    plugin: default_value
    default_value: 1
```

## entity:file

File migration with download:

```yaml
id: files
destination:
  plugin: entity:file
process:
  fid: fid
  filename: filename
  uri:
    plugin: file_copy
    source:
      - source_full_path
      - destination_uri
    file_exists: rename     # rename, replace, or use existing.
    move: false
  uid:
    plugin: migration_lookup
    migration: users
    source: uid
  status:
    plugin: default_value
    default_value: 1
```

Building source URL in the pipeline:

```yaml
process:
  source_full_path:
    plugin: concat
    source:
      - constants/source_base_url
      - filepath
  destination_uri:
    plugin: concat
    source:
      - constants/destination_base
      - filename
  uri:
    plugin: file_copy
    source:
      - '@source_full_path'
      - '@destination_uri'
```

## entity_reference_revisions (Paragraphs)

Requires `entity_reference_revisions` and `migrate_plus`:

```yaml
# Step 1: Migrate paragraph entities.
id: content_paragraphs
destination:
  plugin: 'entity_reference_revisions:paragraph'
  default_bundle: text_block
process:
  field_body/value: body
  field_body/format:
    plugin: default_value
    default_value: full_html
```

```yaml
# Step 2: Attach paragraphs to nodes.
id: articles_with_paragraphs
destination:
  plugin: entity:node
  default_bundle: article
process:
  title: title
  field_content:
    plugin: sub_process
    source: content_blocks
    process:
      target_id:
        plugin: migration_lookup
        migration: content_paragraphs
        source: block_id
      target_revision_id:
        plugin: migration_lookup
        migration: content_paragraphs
        source: block_id
```

## Config Destination

For migrating settings and configuration:

```yaml
id: site_settings
destination:
  plugin: config
  config_name: system.site
process:
  name: site_name
  slogan: site_slogan
  mail: site_email
  page/front: front_page
```

## Custom Destination Plugin

```php
namespace Drupal\mymodule\Plugin\migrate\destination;

use Drupal\migrate\Plugin\migrate\destination\DestinationBase;
use Drupal\migrate\Plugin\MigrateDestinationInterface;
use Drupal\migrate\Plugin\MigrationInterface;
use Drupal\migrate\Row;

/**
 * Writes data to a custom table.
 *
 * @MigrateDestination(
 *   id = "custom_table"
 * )
 */
class CustomTable extends DestinationBase implements MigrateDestinationInterface {

  public function import(Row $row, array $old_destination_id_values = []) {
    $values = [
      'external_id' => $row->getDestinationProperty('external_id'),
      'label' => $row->getDestinationProperty('label'),
      'data' => serialize($row->getDestinationProperty('data')),
    ];

    $result = \Drupal::database()->merge('mymodule_custom_data')
      ->key('external_id', $values['external_id'])
      ->fields($values)
      ->execute();

    return [$values['external_id']];
  }

  public function getIds() {
    return ['external_id' => ['type' => 'integer']];
  }

  public function fields(MigrationInterface $migration = NULL) {
    return [
      'external_id' => $this->t('External ID'),
      'label' => $this->t('Label'),
      'data' => $this->t('Serialized data'),
    ];
  }

  public function rollback(array $destination_identifier) {
    \Drupal::database()->delete('mymodule_custom_data')
      ->condition('external_id', $destination_identifier['external_id'])
      ->execute();
  }

}
```

Usage:

```yaml
destination:
  plugin: custom_table
process:
  external_id: id
  label: name
  data: metadata
```
