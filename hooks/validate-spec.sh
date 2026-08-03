#!/bin/bash
# SF Spec validation hook - validates spec.md structure

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
SF_DIR="${SF_DIR:-$PROJECT_DIR/.sf}"
SPEC_FILE="$SF_DIR/spec.md"

[ ! -f "$SPEC_FILE" ] && exit 0

MISSING=""
grep -qi "scope\|problem" "$SPEC_FILE" || MISSING="$MISSING scope/problem,"
grep -qi "criteria\|acceptance" "$SPEC_FILE" || MISSING="$MISSING acceptance criteria,"
grep -qi "risk" "$SPEC_FILE" || MISSING="$MISSING risks,"

if [ -n "$MISSING" ]; then
  MISSING="${MISSING%,}"
  echo "{\"decision\":\"block\",\"reason\":\"Spec missing sections:$MISSING\"}"
fi
exit 0
