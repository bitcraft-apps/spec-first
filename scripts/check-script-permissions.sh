#!/bin/bash

# Verifies every tracked shell script is committed executable.
# Scripts are invoked directly (`./scripts/version.sh`, `cd tests && ./run-tests.sh`), so a
# script committed 100644 fails at exit 126 with no explanation. Nothing else asserts this:
# `validate-plugin.sh` silently *skips* its `[ -x ]`-guarded checks when the bit is missing.
# Reads the index rather than the working tree — the index is what a fresh clone gets.
# Must be run from the repository root.

set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
    echo "FAIL: git is required to check script permissions"
    exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "FAIL: not inside a git repository"
    exit 1
fi

failed=0
count=0

# Modes: 100755 regular executable (wanted), 120000 symlink (mode lives on the target),
# 100644 regular non-executable (the bug this catches).
# `git ls-files -s` prints "<mode> <sha> <stage>\t<path>", so split the path off at the tab.
while IFS=$'\t' read -r meta path; do
    [ -n "$meta" ] || continue
    mode="${meta%% *}"
    count=$((count + 1))

    case "$mode" in
        100755 | 120000) ;;
        *)
            echo "FAIL: $path is mode $mode, expected 100755"
            echo "      fix with: git update-index --chmod=+x $path"
            failed=1
            ;;
    esac
done < <(git ls-files -s -- '*.sh')

if [ "$count" -eq 0 ]; then
    echo "FAIL: no tracked *.sh files found (run from the repository root)"
    exit 1
fi

if [ "$failed" -eq 1 ]; then
    exit 1
fi

echo "PASS: $count shell script(s) are committed executable"
