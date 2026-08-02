#!/bin/bash
# SF Implementation validation hook - validates implementation against spec

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
SPEC_FILE="$PROJECT_DIR/.claude/.sf/spec.md"
IMPL_FILE="$PROJECT_DIR/.claude/.sf/implementation-summary.md"

if [ ! -f "$SPEC_FILE" ] || [ ! -f "$IMPL_FILE" ]; then exit 0; fi

CRITERIA=$(grep -i "^\- \[" "$SPEC_FILE" 2>/dev/null)
[ -z "$CRITERIA" ] && exit 0

UNCHECKED=$(echo "$CRITERIA" | grep -c "\[ \]" || echo "0")
if [ "$UNCHECKED" -gt 0 ]; then
  echo "{\"decision\":\"block\",\"reason\":\"$UNCHECKED acceptance criteria unchecked in spec\"}"
fi
exit 0
