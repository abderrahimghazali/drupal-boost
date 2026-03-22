#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): Lightweight Drupal coding standards check
# Non-blocking (always exits 0), provides informational warnings

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null || echo "")

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .filePath // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ -z "$CWD" ]; then
  exit 0
fi

# Only check PHP files
case "$FILE_PATH" in
  *.php|*.module|*.install|*.theme) ;;
  *) exit 0 ;;
esac

# Only check files within a Drupal project
DRUPAL_ROOT=""
for candidate in "$CWD/web" "$CWD" "$CWD/docroot"; do
  if [ -f "$candidate/core/lib/Drupal.php" ]; then
    DRUPAL_ROOT="$candidate"
    break
  fi
done

if [ -z "$DRUPAL_ROOT" ]; then
  exit 0
fi

# Read the file content
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

WARNINGS=""

# Check for \Drupal::service() calls in classes that should use DI
if [[ "$FILE_PATH" == */src/*.php ]]; then
  if grep -q '\\Drupal::service(' "$FILE_PATH" 2>/dev/null; then
    WARNINGS="${WARNINGS}Found \\Drupal::service() call in a class under src/. Prefer dependency injection via __construct() and services.yml. "
  fi
  if grep -q '\\Drupal::' "$FILE_PATH" 2>/dev/null; then
    COUNT=$(grep -c '\\Drupal::' "$FILE_PATH" 2>/dev/null || echo "0")
    if [ "$COUNT" -gt 0 ]; then
      WARNINGS="${WARNINGS}Found ${COUNT} static \\Drupal:: call(s) in src/ class. Use dependency injection instead for better testability. "
    fi
  fi
fi

# Check for common deprecated patterns in Drupal 11
if grep -q 'drupal_set_message(' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}drupal_set_message() is deprecated. Use \\Drupal::messenger()->addMessage() or inject the messenger service. "
fi

if grep -q '\\Drupal::l(' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}\\Drupal::l() is deprecated. Use Link::fromTextAndUrl() instead. "
fi

if grep -q 'entity_load(' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}entity_load() is deprecated. Use \\Drupal::entityTypeManager()->getStorage()->load() or inject the service. "
fi

if grep -q 'db_query(' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}db_query() is deprecated. Use the database service via dependency injection. "
fi

# Check for debug leftovers
if grep -qE '(var_dump|print_r|dpm|kint|dsm|dd)\(' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}Debug function found (var_dump/print_r/dpm/kint/dsm/dd). Remove before committing. "
fi

# Check for direct superglobal usage
if grep -qE '\$_(GET|POST|REQUEST|SERVER|COOKIE)\[' "$FILE_PATH" 2>/dev/null; then
  WARNINGS="${WARNINGS}Direct superglobal access detected. Use the Request object via dependency injection instead. "
fi

if [ -n "$WARNINGS" ]; then
  jq -n --arg ctx "Drupal coding standards notices: ${WARNINGS}" '{ additionalContext: $ctx }'
fi

exit 0
