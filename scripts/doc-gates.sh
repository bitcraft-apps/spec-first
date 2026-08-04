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

# A marker shape means an unfinished draft. A bare word like "placeholder" in a
# props table is ordinary prose.
MARKER='(TODO|TBD)[[:space:]]*:|[[<](TODO|TBD|PLACEHOLDER|INSERT)'

# An inline code span quotes a marker, it does not leave one, so strip spans first.
has_marker() {
    # shellcheck disable=SC2016  # the backticks are markdown, not a subshell
    sed 's/`[^`]*`//g' "$1" | grep -qiE "$MARKER"
}

STATUS=0
for file in $FILES; do
    if [ ! -f "$RESEARCH/$file" ]; then
        echo "FAIL $file: missing from $RESEARCH" >&2
        STATUS=1
    # An empty file is a valid "no docs needed" signal. Only markers fail.
    elif [ "$MODE" = generation ] && has_marker "$RESEARCH/$file"; then
        echo "FAIL $file: contains a placeholder marker" >&2
        STATUS=1
    else
        echo "PASS $file"
    fi
done
exit $STATUS
