#!/bin/bash
# Document skill gates - checks agent output before the next batch
# Usage: doc-gates.sh <analysis|generation> [sf-dir]

MODE="$1"
case "$MODE" in
    analysis) FILES="artifacts-summary.md implementation-summary.md docs-inventory.md" ;;
    generation) FILES="technical-docs.md user-docs.md" ;;
    *) echo "Usage: doc-gates.sh <analysis|generation> [sf-dir]" >&2; exit 1 ;;
esac

RESEARCH="${2:-${SF_DIR:-.sf}}/research"

STATUS=0
for file in $FILES; do
    if [ ! -f "$RESEARCH/$file" ]; then
        echo "FAIL $file: missing from $RESEARCH" >&2
        STATUS=1
    # An empty file is a valid "no docs needed" signal. Only markers fail.
    elif [ "$MODE" = generation ] && grep -qiE 'TODO|TBD|PLACEHOLDER|\[INSERT' "$RESEARCH/$file"; then
        echo "FAIL $file: contains a placeholder marker" >&2
        STATUS=1
    else
        echo "PASS $file"
    fi
done
exit $STATUS
