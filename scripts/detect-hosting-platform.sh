#!/usr/bin/env bash
# PreToolUse hook (Bash): Suggests command adaptations for DDEV/Lando environments
# Non-blocking (always exits 0), provides suggestions via additionalContext

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$INPUT" | jq -r '.hookSpecificOutput.toolInput // empty' 2>/dev/null || echo "")
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || echo "")

if [ -z "$COMMAND" ] || [ -z "$CWD" ]; then
  exit 0
fi

ENV_TYPE="native"

if [ -f "$CWD/.ddev/config.yaml" ]; then
  ENV_TYPE="ddev"
elif [ -f "$CWD/.lando.yml" ] || [ -f "$CWD/.lando.local.yml" ]; then
  ENV_TYPE="lando"
fi

# Only suggest adaptations for DDEV/Lando environments
if [ "$ENV_TYPE" = "native" ]; then
  exit 0
fi

SUGGESTION=""

# Check if command uses drush directly without the environment prefix
if echo "$COMMAND" | grep -qP '(?<!\w)drush\s' && ! echo "$COMMAND" | grep -q "ddev drush" && ! echo "$COMMAND" | grep -q "lando drush"; then
  if [ "$ENV_TYPE" = "ddev" ]; then
    SUGGESTION="This project uses DDEV. Consider using 'ddev drush' instead of 'drush' to run commands inside the container."
  elif [ "$ENV_TYPE" = "lando" ]; then
    SUGGESTION="This project uses Lando. Consider using 'lando drush' instead of 'drush' to run commands inside the container."
  fi
fi

# Check if command uses composer directly
if echo "$COMMAND" | grep -qP '(?<!\w)composer\s' && ! echo "$COMMAND" | grep -q "ddev composer" && ! echo "$COMMAND" | grep -q "lando composer"; then
  if [ "$ENV_TYPE" = "ddev" ]; then
    SUGGESTION="${SUGGESTION:+$SUGGESTION }This project uses DDEV. Consider using 'ddev composer' for Composer commands."
  elif [ "$ENV_TYPE" = "lando" ]; then
    SUGGESTION="${SUGGESTION:+$SUGGESTION }This project uses Lando. Consider using 'lando composer' for Composer commands."
  fi
fi

# Check if command uses php directly
if echo "$COMMAND" | grep -qP '(?<!\w)php\s' && ! echo "$COMMAND" | grep -q "ddev exec php" && ! echo "$COMMAND" | grep -q "ddev php" && ! echo "$COMMAND" | grep -q "lando php"; then
  if [ "$ENV_TYPE" = "ddev" ]; then
    SUGGESTION="${SUGGESTION:+$SUGGESTION }This project uses DDEV. Consider using 'ddev php' or 'ddev exec php' for PHP commands."
  elif [ "$ENV_TYPE" = "lando" ]; then
    SUGGESTION="${SUGGESTION:+$SUGGESTION }This project uses Lando. Consider using 'lando php' for PHP commands."
  fi
fi

if [ -n "$SUGGESTION" ]; then
  cat <<EOF
{
  "additionalContext": "${SUGGESTION}"
}
EOF
fi

exit 0
