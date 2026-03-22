#!/usr/bin/env bash
# PreToolUse hook (Write|Edit): Validates Drupal code structure before file writes
# Exit 0 = allow, Exit 2 = block with error message

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null || echo "")

# Extract file path from tool input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .filePath // empty' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ -z "$CWD" ]; then
  exit 0
fi

# Only validate files within a Drupal project
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

ERRORS=""

# Validate .info.yml files
if [[ "$FILE_PATH" == *.info.yml ]]; then
  CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null || echo "")
  if [ -n "$CONTENT" ]; then
    # Check for required keys in module/theme info files
    if ! echo "$CONTENT" | grep -q "^name:" && ! echo "$CONTENT" | grep -q "^name :" ; then
      ERRORS="${ERRORS}Missing required 'name' key in .info.yml file. "
    fi
    if ! echo "$CONTENT" | grep -q "^type:" && ! echo "$CONTENT" | grep -q "^type :" ; then
      ERRORS="${ERRORS}Missing required 'type' key in .info.yml file (must be 'module', 'theme', or 'profile'). "
    fi
    if ! echo "$CONTENT" | grep -q "core_version_requirement" ; then
      ERRORS="${ERRORS}Missing 'core_version_requirement' in .info.yml (e.g., '^10 || ^11'). "
    fi
  fi
fi

# Validate PSR-4 namespace for PHP files in src/
if [[ "$FILE_PATH" == */src/*.php ]]; then
  CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // .new_string // empty' 2>/dev/null || echo "")
  if [ -n "$CONTENT" ]; then
    # Extract expected module name from path
    # Pattern: modules/custom/MODULE_NAME/src/ or modules/MODULE_NAME/src/
    MODULE_NAME=$(echo "$FILE_PATH" | sed -n 's|.*modules/\(custom/\|contrib/\)\{0,1\}\([^/]*\)/src/.*|\2|p')
    if [ -n "$MODULE_NAME" ]; then
      # Check if file has a namespace declaration
      ACTUAL_NS=$(echo "$CONTENT" | sed -n 's/^namespace \([^;]*\);.*/\1/p' | head -1)
      if [ -n "$ACTUAL_NS" ]; then
        EXPECTED_PREFIX="Drupal\\${MODULE_NAME}"
        case "$ACTUAL_NS" in
          "${EXPECTED_PREFIX}"*) ;; # matches — ok
          *) ERRORS="${ERRORS}PSR-4 namespace mismatch: expected 'Drupal\\${MODULE_NAME}\\...' but found '${ACTUAL_NS}'. " ;;
        esac
      fi
    fi
  fi
fi

if [ -n "$ERRORS" ]; then
  echo "$ERRORS" >&2
  exit 2
fi

exit 0
