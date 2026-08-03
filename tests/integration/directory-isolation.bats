#!/usr/bin/env bats

# Directory Isolation Feature Tests
# Tests the new directory isolation functionality added in v0.12.0

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    # Create clean test environment if needed
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    # Clean up test environment
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

@test "manage-spec-directory agent exists and is properly configured" {
    [ -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]

    # Check agent has required metadata
    grep -q "name: manage-spec-directory" "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q "tools: Bash" "$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check agent handles the three modes
    grep -q '"first"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q '"update"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
    grep -q '"new"' "$PROJECT_ROOT/agents/manage-spec-directory.md"
}

@test "manage-spec-directory agent follows framework constraints" {
    # Agent should be under 45 lines (allowing for root resolution + gitignore logic)
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"
    local code_lines=$(sed -n '/```bash/,/```/p' "$agent_file" | grep -v '```' | grep -v '^#' | grep -v '^$' | wc -l)
    [ "$code_lines" -le 45 ]
}

@test "manage-spec-directory agent includes error recovery" {
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check for cleanup on symlink failure
    grep -q "rm -rf.*specs.*timestamp" "$agent_file"

    # Check for mode file cleanup
    grep -q "rm -f.*mode" "$agent_file"
}

# Extract the agent's bash block and run it in $1, without any Claude variable
run_spec_dir() {
    sed -n '/```bash/,/```/p' "$PROJECT_ROOT/agents/manage-spec-directory.md" \
        | grep -v '```' > "$TEST_DIR/spec-dir.sh"
    (cd "$1" && env -u CLAUDE_PROJECT_DIR bash "$TEST_DIR/spec-dir.sh")
}

@test "manage-spec-directory resolves the root from AGENTS.md" {
    mkdir -p "$TEST_DIR/repo/sub"
    touch "$TEST_DIR/repo/AGENTS.md"

    run run_spec_dir "$TEST_DIR/repo/sub"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/repo/.sf/research" ]
}

@test "manage-spec-directory names the markers when no root exists" {
    run run_spec_dir "$TEST_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" == *".git"* ]]
    [[ "$output" == *"AGENTS.md"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "manage-spec-directory uses SF_DIR when the caller sets it" {
    export SF_DIR="$TEST_DIR/custom"

    run run_spec_dir "$TEST_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/custom/research" ]
}

@test "manage-spec-directory agent validates directory is writable" {
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check for writable directory validation with stderr output
    grep -q 'Cannot create or write to' "$agent_file"
}

@test "spec skill halts on manage-spec-directory failure" {
    local skill_file="$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check that spec skill documents halting on failure
    grep -q 'manage-spec-directory fails.*halt' "$skill_file"
}

@test "spec skill includes directory management step" {
    # Check spec skill references the new agent
    grep -q "manage-spec-directory" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check it explains directory management workflow
    grep -q "Directory Management" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '"Update existing" / "Create new"' "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "directory isolation maintains backward compatibility" {
    # Check that synthesize-spec agent mentions symlink awareness
    grep -q "active.*directory\|symlink-aware" "$PROJECT_ROOT/agents/synthesize-spec.md"

    # Check output paths are documented correctly (now uses $SF_DIR variable)
    grep -q "SF_DIR/spec\.md.*direct file or symlink" "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "manage-spec-directory agent includes gitignore protection" {
    local agent_file="$PROJECT_ROOT/agents/manage-spec-directory.md"

    # Check it guards on .git existence
    grep -q '\.git"' "$agent_file"

    # Check it appends exact pattern .sf/
    grep -qF '.sf/' "$agent_file"

    # Check it skips if already present (negated grep guard)
    grep -q '! grep -qF .*.sf/' "$agent_file"
}

@test "framework validation recognizes manage-spec-directory agent" {
    # Run framework validation and check it counts the correct number of agents (12 total)
    cd "$PROJECT_ROOT"
    ./scripts/validate-plugin.sh 2>&1 | grep -q "Found 12 agent files"

    # Also verify the agent file is actually detected in the agents directory
    [ -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]
}