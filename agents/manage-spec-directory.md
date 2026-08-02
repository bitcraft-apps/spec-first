---
name: manage-spec-directory
description: Create and manage spec output directories. Use when initializing or resetting the SF workspace.
tools: Bash
model: haiku
maxTurns: 3
---

# Spec Directory Manager

Modes: **first** (create initial dir), **update** (backup spec, clear research), **new** (archive with timestamp+symlinks)

## Implementation
```bash
# Find project root (directory containing CLAUDE.md)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ]; do
    [ -f "$PROJECT_ROOT/CLAUDE.md" ] && break
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && echo "Error: CLAUDE.md not found in any parent directory" >&2 && exit 1
SF_DIR="$PROJECT_ROOT/.claude/.sf"
mkdir -p "$SF_DIR" 2>/dev/null || { echo "Error: Cannot create or write to $SF_DIR" >&2; exit 1; }
[ -d "$PROJECT_ROOT/.git" ] && [ -f "$PROJECT_ROOT/.gitignore" ] && ! grep -qF '.claude/.sf/' "$PROJECT_ROOT/.gitignore" && echo '.claude/.sf/' >> "$PROJECT_ROOT/.gitignore"
if [ -f "$SF_DIR/mode" ]; then
    MODE=$(cat "$SF_DIR/mode")
elif [ -f "$SF_DIR/spec.md" ]; then
    MODE=""
    while [ "$MODE" != "update" ] && [ "$MODE" != "new" ]; do
        printf "Existing spec found. Update existing or create new? (update/new): " && read -r MODE
    done
    echo "$MODE" > "$SF_DIR/mode"
else
    MODE="first"
fi
case $MODE in
    "update")
        cp "$SF_DIR/spec.md" "$SF_DIR/spec-backup.md" 2>/dev/null
        rm -rf "$SF_DIR/research/"
        ;;
    "new")
        timestamp=$(date -u +%Y-%m-%dT%H%M%S)
        mkdir -p "$SF_DIR/specs/$timestamp"
        mv "$SF_DIR/spec.md" "$SF_DIR/specs/$timestamp/" 2>/dev/null
        mv "$SF_DIR/research/" "$SF_DIR/specs/$timestamp/" 2>/dev/null
        ln -sf "specs/$timestamp/spec.md" "$SF_DIR/spec.md" && \
        ln -sf "specs/$timestamp/research/" "$SF_DIR/research" || {
            rm -rf "$SF_DIR/specs/$timestamp/"
            echo "Error: Failed to create symlinks" && exit 1
        }
        ;;
esac
mkdir -p "$SF_DIR/research/"
rm -f "$SF_DIR/mode"
```

Output: Directory structure ready for spec generation.
