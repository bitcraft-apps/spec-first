#!/usr/bin/env bats

# Unit Tests for scripts/validate-plugin.sh
# All tests invoke as subprocess against temp fixture directories

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
VALIDATE_SCRIPT="$PROJECT_ROOT/scripts/validate-plugin.sh"
SYNC_SCRIPT="$PROJECT_ROOT/scripts/check-version-sync.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"

    # Build minimal valid plugin structure
    echo "1.0.0" > "$FIXTURE_DIR/VERSION"
    mkdir -p "$FIXTURE_DIR/agents"
    mkdir -p "$FIXTURE_DIR/skills/test-skill"
    mkdir -p "$FIXTURE_DIR/scripts"
    mkdir -p "$FIXTURE_DIR/.claude-plugin"

    # Copy the validation script so it can find SCRIPT_DIR/../VERSION
    cp "$VALIDATE_SCRIPT" "$FIXTURE_DIR/scripts/validate-plugin.sh"
    chmod +x "$FIXTURE_DIR/scripts/validate-plugin.sh"

    # validate-plugin.sh delegates version checks to this script
    cp "$SYNC_SCRIPT" "$FIXTURE_DIR/scripts/check-version-sync.sh"
    chmod +x "$FIXTURE_DIR/scripts/check-version-sync.sh"

    # Version references, all agreeing with VERSION above
    printf '{"name":"sf","version":"1.0.0"}\n' > "$FIXTURE_DIR/.claude-plugin/plugin.json"
    printf '{"plugins":[{"name":"sf","version":"1.0.0"}]}\n' > "$FIXTURE_DIR/.claude-plugin/marketplace.json"
    printf '{".":"1.0.0"}\n' > "$FIXTURE_DIR/.release-please-manifest.json"

    # Minimal valid agent
    cat > "$FIXTURE_DIR/agents/test-agent.md" <<'AGENT'
---
name: test-agent
description: A test agent
tools: Read, Write
---

# Test Agent

Does test things.
AGENT

    # Minimal valid skill referencing the agent
    cat > "$FIXTURE_DIR/skills/test-skill/SKILL.md" <<'SKILL'
---
name: test-skill
description: A test skill
---

# Test Skill

Uses test-agent to do things.
SKILL

    # Required doc files
    cat > "$FIXTURE_DIR/AGENTS.md" <<'EOF'
# AGENTS.md

Spec First — minimalist development workflow.

## Core Philosophy

## Principles
EOF

    printf "# README\n\n## Quick Start\n\n## Command Reference\n" > "$FIXTURE_DIR/README.md"
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

# Update every version reference at once, so the sync check keeps passing
set_fixture_version() {
    echo "$1" > "$FIXTURE_DIR/VERSION"
    printf '{"name":"sf","version":"%s"}\n' "$1" > "$FIXTURE_DIR/.claude-plugin/plugin.json"
    printf '{"plugins":[{"name":"sf","version":"%s"}]}\n' "$1" > "$FIXTURE_DIR/.claude-plugin/marketplace.json"
    printf '{".":"%s"}\n' "$1" > "$FIXTURE_DIR/.release-please-manifest.json"
}

# --- Repo root detection ---

@test "validate-plugin exits 1 when not at repo root" {
    cd "$(mktemp -d)"
    run "$VALIDATE_SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Must be run from the repository root"* ]]
}

# --- Valid structure ---

@test "validate-plugin exits 0 for valid plugin structure" {
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASSED"* ]]
}

# --- VERSION file checks ---

@test "validate-plugin detects missing VERSION file" {
    rm "$FIXTURE_DIR/VERSION"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
}

@test "validate-plugin detects invalid version format" {
    echo "not-a-version" > "$FIXTURE_DIR/VERSION"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"valid format"* ]]
}

@test "validate-plugin accepts valid version format" {
    set_fixture_version "2.5.9"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"VERSION file has valid format"* ]]
}

@test "validate-plugin reports version references in sync" {
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version references are in sync (1.0.0)"* ]]
}

@test "validate-plugin fails when a version reference drifts" {
    printf '{"name":"sf","version":"9.9.9"}\n' > "$FIXTURE_DIR/.claude-plugin/plugin.json"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"plugin.json version is 9.9.9, expected 1.0.0"* ]]
}

# --- Directory structure ---

@test "validate-plugin detects missing agents directory" {
    rm -rf "$FIXTURE_DIR/agents"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
}

@test "validate-plugin detects missing skills directory" {
    rm -rf "$FIXTURE_DIR/skills"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
}

# --- Agent validation ---

@test "validate-plugin checks agent frontmatter" {
    # Agent without frontmatter
    echo "# No frontmatter agent" > "$FIXTURE_DIR/agents/bad-agent.md"
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [[ "$output" == *"frontmatter"* ]]
}

@test "validate-plugin counts agents" {
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [[ "$output" == *"1 agent"* ]]
}

@test "validate-plugin counts multiple agents" {
    cat > "$FIXTURE_DIR/agents/second-agent.md" <<'AGENT'
---
name: second-agent
description: Another agent
tools: Read
---

# Second Agent

Does other things.
AGENT
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [[ "$output" == *"2 agent"* ]]
}

# --- Skill validation ---

@test "validate-plugin counts skills" {
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [[ "$output" == *"1 skill"* ]]
}

# --- Summary output ---

@test "validate-plugin shows summary with pass/fail counts" {
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [[ "$output" == *"Validation Summary"* ]]
    [[ "$output" == *"Passed:"* ]]
    [[ "$output" == *"Failed:"* ]]
}

@test "validate-plugin exit code reflects failures" {
    # Create an agent with missing name field to trigger a failure
    cat > "$FIXTURE_DIR/agents/broken.md" <<'AGENT'
---
description: no name field
tools: Read
---

# Broken
AGENT
    cd "$FIXTURE_DIR"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 1 ]
}
