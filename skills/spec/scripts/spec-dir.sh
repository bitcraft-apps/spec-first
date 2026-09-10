#!/bin/bash
# SF artifact directory setup - prepares $SF_DIR for a spec run
# Usage: spec-dir.sh <first|update|new> [sf-dir]

MODE="$1"
case "$MODE" in
    first|update|new) ;;
    *) echo "Usage: spec-dir.sh <first|update|new> [sf-dir]" >&2; exit 1 ;;
esac

# Resolve the artifact directory: argument, then $SF_DIR, then a marker walk
SF_DIR="${2:-$SF_DIR}"
if [ -z "$SF_DIR" ]; then
    PROJECT_ROOT="$(pwd)"
    while [ ! -e "$PROJECT_ROOT/.git" ] && [ ! -f "$PROJECT_ROOT/AGENTS.md" ] && [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; do
        [ "$PROJECT_ROOT" = "/" ] && { echo "Error: project root not found. Looked for .git, AGENTS.md or CLAUDE.md in $(pwd) and every parent directory." >&2; exit 1; }
        PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
    done
    SF_DIR="$PROJECT_ROOT/.sf"
    [ -d "$PROJECT_ROOT/.git" ] && [ -f "$PROJECT_ROOT/.gitignore" ] && ! grep -qF '.sf/' "$PROJECT_ROOT/.gitignore" && echo '.sf/' >> "$PROJECT_ROOT/.gitignore"
fi

mkdir -p "$SF_DIR" 2>/dev/null || { echo "Error: Cannot create or write to $SF_DIR" >&2; exit 1; }

case "$MODE" in
    "update")
        cp "$SF_DIR/spec.md" "$SF_DIR/spec-backup.md" 2>/dev/null
        # No trailing slash: this must remove a symlink as a symlink
        rm -rf "$SF_DIR/research"
        ;;
    "new")
        # Never reuse an archive name, even for two runs in the same second
        name=$(date -u +%Y-%m-%dT%H%M%S)
        suffix=1
        while [ -e "$SF_DIR/specs/$name" ]; do
            name="$(date -u +%Y-%m-%dT%H%M%S)-$suffix"
            suffix=$((suffix + 1))
        done
        mkdir -p "$SF_DIR/specs/$name"
        # A symlink already points into an older archive. Drop it and keep that archive.
        if [ -L "$SF_DIR/spec.md" ]; then
            rm -f "$SF_DIR/spec.md"
        else
            mv "$SF_DIR/spec.md" "$SF_DIR/specs/$name/" 2>/dev/null
        fi
        if [ -L "$SF_DIR/research" ]; then
            rm -f "$SF_DIR/research"
        else
            mv "$SF_DIR/research" "$SF_DIR/specs/$name/" 2>/dev/null
        fi
        mkdir -p "$SF_DIR/specs/$name/research"
        if ! ln -sfn "specs/$name/spec.md" "$SF_DIR/spec.md" || ! ln -sfn "specs/$name/research" "$SF_DIR/research"; then
            rm -rf "$SF_DIR/specs/$name/"
            echo "Error: Failed to create symlinks" >&2
            exit 1
        fi
        ;;
esac

mkdir -p "$SF_DIR/research"
