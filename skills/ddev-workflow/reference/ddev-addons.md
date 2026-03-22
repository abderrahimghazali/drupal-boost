# DDEV Add-ons for Drupal 11

## Redis Setup and Drupal Configuration

Install the DDEV Redis add-on and Drupal module:

```bash
ddev get ddev/ddev-redis
ddev restart
ddev composer require drupal/redis
ddev drush en redis
```

Configure Drupal to use Redis in `settings.php` (DDEV auto-configures via `settings.ddev.php`, but for explicit control):

```php
$settings['redis.connection']['interface'] = 'PhpRedis';
$settings['redis.connection']['host'] = 'redis';
$settings['redis.connection']['port'] = 6379;
$settings['cache']['default'] = 'cache.backend.redis';

// Optional: use Redis for locks and flood control.
$settings['container_yamls'][] = 'modules/contrib/redis/example.services.yml';

// Ensure the cache_container table is used for container cache.
$settings['cache']['bins']['container'] = 'cache.backend.database';
$settings['cache']['bins']['discovery'] = 'cache.backend.database';
```

Verify Redis is working:

```bash
ddev redis-cli INFO keyspace
ddev drush cr
ddev redis-cli INFO keyspace    # Should show keys populated
```

### Redis for Queue

```php
$settings['queue_default'] = 'queue.redis_reliable';
// Or per-queue:
$settings['queue_service_aggregator_feeds'] = 'queue.redis_reliable';
```

## Solr Setup and Search API Configuration

Install the DDEV Solr add-on:

```bash
ddev get ddev/ddev-solr
ddev restart
```

Install Drupal modules:

```bash
ddev composer require drupal/search_api_solr
ddev drush en search_api_solr
```

Upload Solr config from Drupal to the Solr instance. Go to `/admin/config/search/search-api/add-server`:

- Backend: Solr
- Solr Connector: Standard
- HTTP protocol: http
- Solr host: solr
- Solr port: 8983
- Solr core: dev

Generate and deploy config files:

```bash
# Generate config zip from Drupal UI: server config page > "Get config.zip"
# Or via drush:
ddev drush search-api-solr:get-server-config SERVER_ID solr_config.zip
ddev exec unzip solr_config.zip -d /tmp/solr_config
# Upload to Solr
ddev exec curl -s "http://solr:8983/solr/dev/config" -X POST -H 'Content-type:application/json' --data-binary @/tmp/solr_config/schema.xml
```

Or use the Solr configset approach:

```bash
ddev exec cp -r /tmp/solr_config/* /var/solr/data/dev/conf/
ddev exec curl "http://solr:8983/solr/admin/cores?action=RELOAD&core=dev"
```

## Elasticsearch Setup

Install DDEV Elasticsearch add-on:

```bash
ddev get ddev/ddev-elasticsearch
ddev restart
```

Default Elasticsearch is available at `http://elasticsearch:9200` inside the container.

Install Drupal integration:

```bash
ddev composer require drupal/elasticsearch_connector drupal/search_api
ddev drush en elasticsearch_connector search_api
```

Configure at `/admin/config/search/elasticsearch-connector/add`:

- URL: `http://elasticsearch:9200`

Verify connectivity:

```bash
ddev exec curl http://elasticsearch:9200
ddev exec curl http://elasticsearch:9200/_cluster/health
```

### Custom Elasticsearch configuration

Override memory and settings in `.ddev/docker-compose.elasticsearch.yaml`:

```yaml
services:
  elasticsearch:
    environment:
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "discovery.type=single-node"
```

## Mailpit for Email Testing

Mailpit is built into DDEV by default (replacing Mailhog in newer versions). No add-on needed.

Access the Mailpit UI:

```bash
ddev launch -m              # Opens Mailpit in browser
# Or navigate to: https://my-site.ddev.site:8026
```

Drupal is auto-configured to send email through Mailpit in DDEV. All outgoing emails are captured and visible in the Mailpit web UI.

For additional control, install the `symfony_mailer` module:

```bash
ddev composer require drupal/symfony_mailer
ddev drush en symfony_mailer
```

Configure at `/admin/config/system/mailer/transport`:

- Transport type: SMTP
- Host: `localhost`
- Port: `1025`

### Mailpit API

Inspect captured emails programmatically:

```bash
ddev exec curl -s http://localhost:8025/api/v1/messages | jq '.messages[0].Subject'
```

## Memcached

Install the DDEV Memcached add-on:

```bash
ddev get ddev/ddev-memcached
ddev restart
```

Install Drupal module:

```bash
ddev composer require drupal/memcache
ddev drush en memcache
```

Configure in `settings.php`:

```php
$settings['memcache']['servers'] = ['memcached:11211' => 'default'];
$settings['memcache']['bins'] = ['default' => 'default'];
$settings['memcache']['key_prefix'] = 'my_site_';
$settings['cache']['default'] = 'cache.backend.memcache';

// Keep container and discovery caches in the database.
$settings['cache']['bins']['container'] = 'cache.backend.database';
$settings['cache']['bins']['discovery'] = 'cache.backend.database';
```

Verify:

```bash
ddev exec php -r "
\$m = new \Memcached();
\$m->addServer('memcached', 11211);
\$m->set('test', 'hello');
echo \$m->get('test');
"
```

### Choosing Redis vs Memcached

- **Redis**: Supports data structures, persistence, pub/sub, queues. Better for complex caching and queue backends.
- **Memcached**: Simpler, slightly faster for pure key-value caching. Multi-threaded. Good for simple cache-only setups.

For most Drupal projects, Redis is the more versatile choice.
