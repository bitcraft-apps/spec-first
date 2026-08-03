#!/usr/bin/env bats

# Unit tests for scripts/spec-dir.sh

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
SPEC_DIR_SH="$PROJECT_ROOT/scripts/spec-dir.sh"
export SPEC_DIR_SH

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    unset SF_DIR
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Run the script from $1 with the remaining arguments
run_spec_dir() {
    local cwd="$1"; shift
    (cd "$cwd" && bash "$SPEC_DIR_SH" "$@")
}

@test "rejects a missing mode" {
    run run_spec_dir "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "rejects an unknown mode" {
    run run_spec_dir "$TEST_DIR" bogus "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [ ! -d "$TEST_DIR/.sf" ]
}

@test "resolves the root from AGENTS.md" {
    mkdir -p "$TEST_DIR/repo/sub"
    touch "$TEST_DIR/repo/AGENTS.md"

    run run_spec_dir "$TEST_DIR/repo/sub" first
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/repo/.sf/research" ]
}

@test "names the markers when no root exists" {
    run run_spec_dir "$TEST_DIR" first
    [ "$status" -eq 1 ]
    [[ "$output" == *".git"* ]]
    [[ "$output" == *"AGENTS.md"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "uses SF_DIR when the caller exports it" {
    export SF_DIR="$TEST_DIR/custom"

    run run_spec_dir "$TEST_DIR" first
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/custom/research" ]
}

@test "the directory argument wins over SF_DIR" {
    export SF_DIR="$TEST_DIR/from-env"

    run run_spec_dir "$TEST_DIR" first "$TEST_DIR/from-arg"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/from-arg/research" ]
    [ ! -d "$TEST_DIR/from-env" ]
}

@test "an empty directory argument falls back to SF_DIR" {
    export SF_DIR="$TEST_DIR/custom"

    run run_spec_dir "$TEST_DIR" first ""
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/custom/research" ]
}

@test "update backs up the spec and clears research" {
    mkdir -p "$TEST_DIR/.sf/research"
    echo "old spec" > "$TEST_DIR/.sf/spec.md"
    echo "stale" > "$TEST_DIR/.sf/research/scope.md"

    run run_spec_dir "$TEST_DIR" update "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_DIR/.sf/spec-backup.md")" = "old spec" ]
    [ -d "$TEST_DIR/.sf/research" ]
    [ ! -f "$TEST_DIR/.sf/research/scope.md" ]
}

@test "new archives the spec and links to the archive" {
    mkdir -p "$TEST_DIR/.sf/research"
    echo "old spec" > "$TEST_DIR/.sf/spec.md"
    echo "old scope" > "$TEST_DIR/.sf/research/scope.md"

    run run_spec_dir "$TEST_DIR" new "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]

    local archive
    archive=$(find "$TEST_DIR/.sf/specs" -maxdepth 1 -mindepth 1 -type d)
    [ "$(cat "$archive/spec.md")" = "old spec" ]
    [ "$(cat "$archive/research/scope.md")" = "old scope" ]
    [ -L "$TEST_DIR/.sf/spec.md" ]
    [ -L "$TEST_DIR/.sf/research" ]
    [ "$(cat "$TEST_DIR/.sf/spec.md")" = "old spec" ]
}

@test "new twice keeps both archives" {
    mkdir -p "$TEST_DIR/.sf/research"
    echo "first spec" > "$TEST_DIR/.sf/spec.md"

    run run_spec_dir "$TEST_DIR" new "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    echo "second spec" > "$TEST_DIR/.sf/spec.md"

    run run_spec_dir "$TEST_DIR" new "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]

    # Two archives, and the older one still holds both specs written into it
    [ "$(find "$TEST_DIR/.sf/specs" -maxdepth 1 -mindepth 1 -type d | wc -l)" -eq 2 ]
    [ "$(grep -rh . "$TEST_DIR/.sf/specs"/*/spec.md)" = "second spec" ]
    [ -L "$TEST_DIR/.sf/spec.md" ]
    [ -L "$TEST_DIR/.sf/research" ]
}

@test "update after new leaves a usable research directory" {
    mkdir -p "$TEST_DIR/.sf/research"
    echo "old spec" > "$TEST_DIR/.sf/spec.md"

    run run_spec_dir "$TEST_DIR" new "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    echo "archived spec" > "$TEST_DIR/.sf/spec.md"

    run run_spec_dir "$TEST_DIR" update "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]

    # research is a real directory again, not a dangling symlink
    [ -d "$TEST_DIR/.sf/research" ]
    [ ! -L "$TEST_DIR/.sf/research" ]
    [ ! -e "$TEST_DIR/.sf/research/research" ]
    [ "$(cat "$TEST_DIR/.sf/spec-backup.md")" = "archived spec" ]
    echo "scope" > "$TEST_DIR/.sf/research/scope.md"
}

@test "new after update does not nest research" {
    mkdir -p "$TEST_DIR/.sf/research"
    echo "old spec" > "$TEST_DIR/.sf/spec.md"

    for mode in new update new; do
        run run_spec_dir "$TEST_DIR" "$mode" "$TEST_DIR/.sf"
        [ "$status" -eq 0 ]
    done

    [ -L "$TEST_DIR/.sf/research" ]
    [ ! -e "$TEST_DIR/.sf/research/research" ]
}

@test "appends .sf/ to .gitignore once" {
    mkdir -p "$TEST_DIR/repo/.git"
    touch "$TEST_DIR/repo/AGENTS.md"
    echo "node_modules/" > "$TEST_DIR/repo/.gitignore"

    run run_spec_dir "$TEST_DIR/repo" first
    [ "$status" -eq 0 ]
    run run_spec_dir "$TEST_DIR/repo" first
    [ "$status" -eq 0 ]

    [ "$(grep -cF '.sf/' "$TEST_DIR/repo/.gitignore")" -eq 1 ]
}

@test "fails when the directory is not writable" {
    mkdir -p "$TEST_DIR/readonly"
    chmod 500 "$TEST_DIR/readonly"

    run run_spec_dir "$TEST_DIR" first "$TEST_DIR/readonly/.sf"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot create or write to"* ]]

    chmod 700 "$TEST_DIR/readonly"
}
