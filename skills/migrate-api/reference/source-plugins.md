# Migration Source Plugins

## SQL Source

### Drupal 7 Source

Built-in sources for D7-to-D11 migrations:

```yaml
# migrate_plus.migration.d7_articles.yml
source:
  plugin: d7_node
  node_type: article
```

### Custom SQL Query

```yaml
source:
  plugin: d7_node
  node_type: article
  # Add fields from joined tables.
  fields:
    - name: field_legacy_id
      selector: legacy_id
```

For fully custom SQL queries:

```php
namespace Drupal\mymodule\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;
use Drupal\migrate\Row;

/**
 * Source plugin for legacy product data.
 *
 * @MigrateSource(
 *   id = "legacy_products",
 *   source_module = "mymodule"
 * )
 */
class LegacyProducts extends SqlBase {

  public function query() {
    return $this->select('legacy_products', 'p')
      ->fields('p', ['id', 'title', 'sku', 'price', 'description', 'created'])
      ->condition('p.status', 1)
      ->orderBy('p.id');
  }

  public function fields() {
    return [
      'id' => $this->t('Product ID'),
      'title' => $this->t('Title'),
      'sku' => $this->t('SKU'),
      'price' => $this->t('Price'),
      'description' => $this->t('Description'),
      'created' => $this->t('Created timestamp'),
    ];
  }

  public function getIds() {
    return [
      'id' => ['type' => 'integer'],
    ];
  }

  public function prepareRow(Row $row) {
    // Fetch related categories.
    $categories = $this->select('legacy_product_categories', 'pc')
      ->fields('pc', ['category_id'])
      ->condition('pc.product_id', $row->getSourceProperty('id'))
      ->execute()
      ->fetchCol();
    $row->setSourceProperty('categories', $categories);
    return parent::prepareRow($row);
  }

}
```

Database connection config in migration YAML:

```yaml
source:
  plugin: legacy_products
  key: legacy  # References $databases['legacy'] in settings.php.
```

```php
// settings.php
$databases['legacy']['default'] = [
  'driver' => 'mysql',
  'database' => 'legacy_db',
  'username' => 'root',
  'password' => 'root',
  'host' => 'localhost',
];
```

## CSV Source

Requires `migrate_source_csv` module:

```yaml
source:
  plugin: csv
  path: /path/to/data.csv
  # Or relative to Drupal root:
  # path: modules/custom/mymodule/data/import.csv
  ids: [id]
  delimiter: ','
  enclosure: '"'
  header_offset: 0  # First row is header (0-indexed).
  fields:
    - name: id
    - name: title
    - name: body
    - name: category
    - name: image_url
```

## JSON/XML URL Source (migrate_plus)

```yaml
# JSON from API endpoint.
source:
  plugin: url
  data_fetcher_plugin: http
  data_parser_plugin: json
  urls:
    - 'https://api.example.com/products.json'
  headers:
    Authorization: 'Bearer TOKEN_HERE'
  item_selector: '/data/products'
  ids:
    id:
      type: integer
  fields:
    - name: id
      label: 'Product ID'
      selector: id
    - name: title
      label: 'Title'
      selector: attributes/title
    - name: body
      label: 'Body'
      selector: attributes/description
```

```yaml
# XML source.
source:
  plugin: url
  data_fetcher_plugin: http
  data_parser_plugin: xml
  urls:
    - 'https://example.com/feed.xml'
  item_selector: /rss/channel/item
  ids:
    guid:
      type: string
  fields:
    - name: guid
      label: 'GUID'
      selector: guid
    - name: title
      label: 'Title'
      selector: title
    - name: body
      label: 'Body'
      selector: 'content:encoded'
```

## Empty Source

Create fixed content not tied to external data:

```yaml
source:
  plugin: embedded_data
  data_rows:
    - id: 1
      name: 'Administrator'
      machine_name: administrator
    - id: 2
      name: 'Editor'
      machine_name: editor
    - id: 3
      name: 'Contributor'
      machine_name: contributor
  ids:
    id:
      type: integer
```

## Custom Source Plugin Skeleton

```php
namespace Drupal\mymodule\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SourcePluginBase;
use Drupal\migrate\Row;

/**
 * Source plugin pulling from an external API.
 *
 * @MigrateSource(
 *   id = "api_source",
 *   source_module = "mymodule"
 * )
 */
class ApiSource extends SourcePluginBase {

  protected $items = [];

  public function initializeIterator() {
    $client = \Drupal::httpClient();
    $response = $client->get('https://api.example.com/items');
    $this->items = json_decode($response->getBody(), TRUE)['data'];
    return new \ArrayIterator($this->items);
  }

  public function fields() {
    return [
      'id' => $this->t('ID'),
      'title' => $this->t('Title'),
    ];
  }

  public function getIds() {
    return ['id' => ['type' => 'integer']];
  }

  public function __toString() {
    return 'External API source';
  }

}
```

For large datasets, implement `count()` and use `$this->configuration['batch_size']` to paginate.
