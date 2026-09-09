#!/bin/bash
# Spec structure check - reports the sections spec.md does not have
# Usage: validate-spec.sh [sf-dir]

SPEC_FILE="${1:-${SF_DIR:-.sf}}/spec.md"

# No spec yet means nothing to check.
[ ! -f "$SPEC_FILE" ] && exit 0

MISSING=""
grep -qi "scope\|problem" "$SPEC_FILE" || MISSING="$MISSING scope/problem,"
grep -qi "criteria\|acceptance" "$SPEC_FILE" || MISSING="$MISSING acceptance criteria,"
grep -qi "risk" "$SPEC_FILE" || MISSING="$MISSING risks,"

if [ -n "$MISSING" ]; then
    echo "Spec missing sections:${MISSING%,}" >&2
    exit 1
fi
exit 0
