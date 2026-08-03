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
# Resolve the artifact directory: $SF_DIR, then ${CLAUDE_PROJECT_DIR}, then a marker walk
if [ -z "$SF_DIR" ]; then
    PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    while [ ! -e "$PROJECT_ROOT/.git" ] && [ ! -f "$PROJECT_ROOT/AGENTS.md" ] && [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; do
        [ "$PROJECT_ROOT" = "/" ] && { echo "Error: project root not found. Looked for .git, AGENTS.md or CLAUDE.md in $(pwd) and every parent directory." >&2; exit 1; }
        PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
    done
    SF_DIR="$PROJECT_ROOT/.sf"
    [ -d "$PROJECT_ROOT/.git" ] && [ -f "$PROJECT_ROOT/.gitignore" ] && ! grep -qF '.sf/' "$PROJECT_ROOT/.gitignore" && echo '.sf/' >> "$PROJECT_ROOT/.gitignore"
fi
mkdir -p "$SF_DIR" 2>/dev/null || { echo "Error: Cannot create or write to $SF_DIR" >&2; exit 1; }
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
        ln -sf "specs/$timestamp/spec.md" "$SF_DIR/spec.md" && ln -sf "specs/$timestamp/research/" "$SF_DIR/research" || {
            rm -rf "$SF_DIR/specs/$timestamp/"; echo "Error: Failed to create symlinks" >&2; exit 1; }
        ;;
esac
mkdir -p "$SF_DIR/research/"
rm -f "$SF_DIR/mode"
```

Output: Directory structure ready for spec generation.
