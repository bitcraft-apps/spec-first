#!/bin/bash

# Verifies no bats test body contains a `[[ ... ]]` outside its final position.
#
# bats runs a test body under `set -eET` and reports failure from a DEBUG trap. `[[ ... ]]` is a
# bash conditional construct, not a simple command, so a failing `[[ ... ]]` that is not the last
# line of a test body does not fail the test — it asserts nothing at all. `[ ... ]` fails
# correctly, and so does a `[[ ... ]]` in final position; only the non-final case is swallowed.
# 28 assertions were silently dead when this check was written (#283).
#
# The fix is to put the assertion in a function: a function call is a simple command, so errexit
# fires wherever it sits. See tests/helpers/assertions.bash.
#
# Only a line that *starts* with `[[` counts. A `[[` inside a quoted argument is data, not a
# conditional construct — this file's own tests write fixtures full of them.
#
# Must be run from the repository root.

set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
    echo "FAIL: git is required to find the test files"
    exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "FAIL: not inside a git repository"
    exit 1
fi

# Reads the whole file, so heredoc bodies and comments can be skipped in one pass.
# Prints "<line> <text>" for every offending line.
scan_file() {
    awk '
        # A heredoc body is data, not code: swallow it so its contents never look like assertions.
        # Handles <<TAG, <<-TAG and <<"TAG"/<<'"'"'TAG'"'"'.
        in_heredoc {
            line = $0
            sub(/^[ \t]+/, "", line)
            if (line == heredoc_tag) { in_heredoc = 0 }
            next
        }
        {
            if (match($0, /<<-?[ \t]*"?'"'"'?[A-Za-z_][A-Za-z0-9_]*"?'"'"'?/)) {
                tag = substr($0, RSTART, RLENGTH)
                gsub(/^<<-?[ \t]*|["'"'"']/, "", tag)
                heredoc_tag = tag
                in_heredoc = 1
                # The line opening the heredoc is still code, so fall through and inspect it.
            }
        }

        # Test bodies only. A closing brace in column 1 ends one.
        /^@test/ { in_test = 1; n = 0; next }
        !in_test { next }
        /^}/ {
            # The last significant line may hold a [[ ]]; everything before it may not.
            for (i = 1; i < n; i++) { if (is_cond[i]) print lineno[i] " " text[i] }
            in_test = 0
            next
        }
        {
            stripped = $0
            sub(/^[ \t]+/, "", stripped)
            if (stripped == "" || stripped ~ /^#/) { next }
            n++
            lineno[n] = FNR
            text[n] = stripped
            is_cond[n] = (stripped ~ /^\[\[/)
        }
    ' "$1"
}

failed=0
bodies=0
files=0

# Tracked .bats files only — skips the bats-core submodule, which is not ours to lint.
while IFS= read -r file; do
    [ -n "$file" ] || continue
    files=$((files + 1))
    bodies=$((bodies + $(grep -c '^@test' "$file" || true)))

    while IFS=' ' read -r line text; do
        [ -n "$line" ] || continue
        echo "FAIL: $file:$line: non-final [[ ]] cannot fail this test"
        echo "      $text"
        failed=1
    done < <(scan_file "$file")
done < <(git ls-files -- '*.bats')

if [ "$files" -eq 0 ]; then
    echo "FAIL: no tracked *.bats files found (run from the repository root)"
    exit 1
fi

if [ "$failed" -eq 1 ]; then
    echo ""
    echo "Use assert_output_contains / refute_output_contains from tests/helpers/assertions.bash,"
    echo "or move the [[ ]] to the last line of the test body."
    exit 1
fi

echo "PASS: $bodies test body/bodies in $files file(s) have no non-final [[ ]]"
