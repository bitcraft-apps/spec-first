#!/usr/bin/env bats

# Unit Tests for scripts/check-skill-links.sh
# All tests invoke as subprocess against temp fixture git repositories

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

LINKS_SCRIPT="$PROJECT_ROOT/scripts/check-skill-links.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"

    # Build a fixture repo with one self-contained skill
    mkdir -p "$FIXTURE_DIR/skills/demo/scripts"
    cp "$LINKS_SCRIPT" "$FIXTURE_DIR/scripts-check-skill-links.sh"
    printf '#!/bin/bash\necho ok\n' > "$FIXTURE_DIR/skills/demo/scripts/gate.sh"
    printf '# Skill\n' > "$FIXTURE_DIR/skills/demo/SKILL.md"

    cd "$FIXTURE_DIR"
    git init -q .
    git add -A
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

run_links_script() {
    run bash "$FIXTURE_DIR/scripts-check-skill-links.sh"
}

# --- Happy path ---

@test "check-skill-links passes when a skill has no symlinks" {
    cd "$FIXTURE_DIR"
    run_links_script
    [ "$status" -eq 0 ]
    assert_output_contains "PASS: 0 skill symlink(s) stay inside their skill folder"
}

@test "check-skill-links passes when a link stays inside its skill folder" {
    cd "$FIXTURE_DIR"
    ln -sf gate.sh "$FIXTURE_DIR/skills/demo/scripts/inner.sh"
    git add -A
    run_links_script
    [ "$status" -eq 0 ]
    assert_output_contains "PASS: 1 skill symlink(s)"
}

# --- Escaping links ---

@test "check-skill-links fails and names a link pointing outside its skill folder" {
    cd "$FIXTURE_DIR"
    mkdir -p shared
    printf '#!/bin/bash\n' > shared/gate.sh
    ln -sf ../../../shared/gate.sh "$FIXTURE_DIR/skills/demo/scripts/gate.sh"
    git add -A
    run_links_script
    [ "$status" -eq 1 ]
    assert_output_contains "skills/demo/scripts/gate.sh escapes skills/demo"
}

@test "check-skill-links fails on an absolute link target" {
    cd "$FIXTURE_DIR"
    ln -sf /bin/sh "$FIXTURE_DIR/skills/demo/scripts/gate.sh"
    git add -A
    run_links_script
    [ "$status" -eq 1 ]
    assert_output_contains "escapes skills/demo"
}

@test "check-skill-links fails on a dangling link" {
    cd "$FIXTURE_DIR"
    ln -sf nowhere.sh "$FIXTURE_DIR/skills/demo/scripts/gate.sh"
    git add -A
    run_links_script
    [ "$status" -eq 1 ]
    assert_output_contains "points at missing location"
}

@test "check-skill-links checks each skill against its own folder" {
    cd "$FIXTURE_DIR"
    mkdir -p "$FIXTURE_DIR/skills/other/scripts"
    printf '# Skill\n' > "$FIXTURE_DIR/skills/other/SKILL.md"
    printf '#!/bin/bash\n' > "$FIXTURE_DIR/skills/other/scripts/gate.sh"
    ln -sf ../../demo/scripts/gate.sh "$FIXTURE_DIR/skills/other/scripts/gate.sh"
    git add -A
    run_links_script
    [ "$status" -eq 1 ]
    assert_output_contains "skills/other/scripts/gate.sh escapes skills/other"
}
