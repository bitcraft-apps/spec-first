#!/bin/bash

# Fails if a skill ships a symlink that points outside its own skill folder.
# Per-skill-dir installers reject escaping paths, so each skill folder stays
# self-contained. Reads the index rather than the working tree — the index is
# what a fresh clone gets. Must be run from the repository root.

set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
    echo "FAIL: git is required to check skill links"
    exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "FAIL: not inside a git repository"
    exit 1
fi

failed=0
count=0

while IFS=$'\t' read -r meta path; do
    [ -n "$meta" ] || continue
    mode="${meta%% *}"
    [ "$mode" = "120000" ] || continue
    count=$((count + 1))

    skill_dir="$(echo "$path" | cut -d/ -f1-2)"
    skill_abs="$(cd "$skill_dir" && pwd -P)"
    if ! target="$(readlink "$path" 2>/dev/null)"; then
        echo "FAIL: $path is tracked as a symlink but is not one on disk (stage your changes)"
        failed=1
        continue
    fi

    case "$target" in
        /*) abs="$target" ;;
        *) abs="$(cd "$(dirname "$path")" && pwd -P)/$target" ;;
    esac

    if ! dir_canon="$(cd -P "$(dirname "$abs")" 2>/dev/null && pwd)"; then
        echo "FAIL: $path points at missing location $target"
        failed=1
        continue
    fi
    canon="$dir_canon/$(basename "$abs")"

    if [ ! -e "$canon" ]; then
        echo "FAIL: $path points at missing location $target"
        failed=1
        continue
    fi

    case "$canon" in
        "$skill_abs"/*) ;;
        *)
            echo "FAIL: $path escapes $skill_dir (points at $target)"
            failed=1
            ;;
    esac
done < <(git ls-files -s -- 'skills/*')

if [ "$failed" -eq 1 ]; then
    exit 1
fi

echo "PASS: $count skill symlink(s) stay inside their skill folder"
