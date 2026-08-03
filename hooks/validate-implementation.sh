#!/bin/bash
# SF Implementation validation hook - validates implementation against spec

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
SF_DIR="${SF_DIR:-$PROJECT_DIR/.sf}"
SPEC_FILE="$SF_DIR/spec.md"
IMPL_FILE="$SF_DIR/implementation-summary.md"

if [ ! -f "$SPEC_FILE" ] || [ ! -f "$IMPL_FILE" ]; then exit 0; fi

CRITERIA=$(grep -i "^\- \[" "$SPEC_FILE" 2>/dev/null)
[ -z "$CRITERIA" ] && exit 0

UNCHECKED=$(echo "$CRITERIA" | grep -c "^\- \[ \]")
if [ "$UNCHECKED" -gt 0 ]; then
  echo "{\"decision\":\"block\",\"reason\":\"$UNCHECKED acceptance criteria unchecked in spec\"}"
fi
exit 0
