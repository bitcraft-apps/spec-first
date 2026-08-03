#!/bin/bash
# Claude Stop hook adapter - runs scripts/validate-spec.sh and reports its result

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // ""')
SCRIPT="$(dirname "$0")/../scripts/validate-spec.sh"

REASON=$(bash "$SCRIPT" "${SF_DIR:-$PROJECT_DIR/.sf}" 2>&1 >/dev/null) \
  || jq -nc --arg reason "$REASON" '{decision:"block",reason:$reason}'
exit 0
