#!/bin/bash
# Implementation check - counts the acceptance criteria the spec still has unchecked
# Usage: validate-implementation.sh [sf-dir]

SF_DIR="${1:-${SF_DIR:-.sf}}"
SPEC_FILE="$SF_DIR/spec.md"
IMPL_FILE="$SF_DIR/implementation-summary.md"

# Before both files exist there is nothing to compare.
if [ ! -f "$SPEC_FILE" ] || [ ! -f "$IMPL_FILE" ]; then exit 0; fi

CRITERIA=$(grep -i "^\- \[" "$SPEC_FILE" 2>/dev/null)
[ -z "$CRITERIA" ] && exit 0

UNCHECKED=$(echo "$CRITERIA" | grep -c "^\- \[ \]")
if [ "$UNCHECKED" -gt 0 ]; then
    echo "$UNCHECKED acceptance criteria unchecked in spec" >&2
    exit 1
fi
exit 0
