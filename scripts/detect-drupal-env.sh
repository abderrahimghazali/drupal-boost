#!/usr/bin/env bash
# SessionStart hook: Detects Drupal version and local development environment
# Outputs JSON context for Claude to understand the project setup

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")

if [ -z "$CWD" ]; then
  exit 0
fi

DRUPAL_VERSION=""
DRUPAL_ROOT=""
ENV_TYPE="unknown"
PHP_VERSION=""

# Detect Drupal root (check common locations)
for candidate in "$CWD/web/core/lib/Drupal.php" "$CWD/core/lib/Drupal.php" "$CWD/docroot/core/lib/Drupal.php"; do
  if [ -f "$candidate" ]; then
    DRUPAL_ROOT=$(dirname "$(dirname "$(dirname "$candidate")")")
    DRUPAL_VERSION=$(grep -oP "const VERSION = '\K[^']+" "$candidate" 2>/dev/null || echo "unknown")
    break
  fi
done

# Not a Drupal project
if [ -z "$DRUPAL_ROOT" ]; then
  echo '{"additionalContext": "This does not appear to be a Drupal project. drupal-boost skills and agents are available but environment-specific features are dormant."}'
  exit 0
fi

# Detect DDEV
if [ -f "$CWD/.ddev/config.yaml" ]; then
  ENV_TYPE="ddev"
  PHP_VERSION=$(grep -oP 'php_version:\s*"\K[^"]+' "$CWD/.ddev/config.yaml" 2>/dev/null || echo "")
fi

# Detect Lando
if [ -f "$CWD/.lando.yml" ] || [ -f "$CWD/.lando.local.yml" ]; then
  if [ "$ENV_TYPE" = "unknown" ]; then
    ENV_TYPE="lando"
  else
    ENV_TYPE="${ENV_TYPE}+lando"
  fi
fi

# Detect PHP version if not found via DDEV
if [ -z "$PHP_VERSION" ]; then
  PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;' 2>/dev/null || echo "unknown")
fi

# Detect Composer
COMPOSER_EXISTS="false"
if [ -f "$CWD/composer.json" ]; then
  COMPOSER_EXISTS="true"
fi

# Detect Drush
DRUSH_EXISTS="false"
if [ -f "$CWD/vendor/bin/drush" ]; then
  DRUSH_EXISTS="true"
fi

# Build context message
CONTEXT="Drupal ${DRUPAL_VERSION} project detected."
CONTEXT="${CONTEXT} Root: ${DRUPAL_ROOT}."
CONTEXT="${CONTEXT} Environment: ${ENV_TYPE}."
CONTEXT="${CONTEXT} PHP: ${PHP_VERSION}."

if [ "$ENV_TYPE" = "ddev" ]; then
  CONTEXT="${CONTEXT} Use 'ddev drush' for Drush commands, 'ddev exec' for shell commands."
elif [ "$ENV_TYPE" = "lando" ]; then
  CONTEXT="${CONTEXT} Use 'lando drush' for Drush commands, 'lando ssh' for shell access."
fi

if [ "$COMPOSER_EXISTS" = "true" ]; then
  CONTEXT="${CONTEXT} Composer project detected."
fi

cat <<EOF
{
  "additionalContext": "${CONTEXT}",
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "drupalVersion": "${DRUPAL_VERSION}",
    "drupalRoot": "${DRUPAL_ROOT}",
    "envType": "${ENV_TYPE}",
    "phpVersion": "${PHP_VERSION}",
    "composerExists": ${COMPOSER_EXISTS},
    "drushExists": ${DRUSH_EXISTS}
  }
}
EOF
