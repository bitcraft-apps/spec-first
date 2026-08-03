#!/bin/bash
# Installs the sf skills in the shared .agents/skills location
# Usage: install.sh [--copy|--symlink] [--dir DIR] [--force]

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$HOME/.agents/skills"
MODE=""
FORCE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --copy) MODE="copy" ;;
        --symlink) MODE="symlink" ;;
        --dir) DIR="$2"; shift ;;
        --force) FORCE=true ;;
        *) echo "Usage: install.sh [--copy|--symlink] [--dir DIR] [--force]" >&2; exit 1 ;;
    esac
    shift
done

# A checkout can point at itself. A release has no .git, so it must copy.
[ -z "$MODE" ] && { [ -d "$REPO_ROOT/.git" ] && MODE="symlink" || MODE="copy"; }

VERSION="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "unknown")"
mkdir -p "$DIR"

for source in "$REPO_ROOT"/skills/*/; do
    name="$(basename "$source")"
    target="$DIR/$name"

    # The skill names are generic. Never remove a directory sf did not write.
    if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -f "$target/.sf-install" ] && [ "$FORCE" = false ]; then
        echo "Error: $target exists and sf did not install it. Use --force to replace it." >&2
        exit 1
    fi

    rm -rf "$target"
    if [ "$MODE" = "symlink" ]; then
        ln -s "${source%/}" "$target"
    else
        cp -RL "${source%/}" "$target"
        chmod +x "$target"/scripts/*.sh
        echo "$VERSION" > "$target/.sf-install"
    fi
    echo "Installed $name ($MODE) -> $target"
done

echo "Every agent host that reads $DIR now finds these skills."
