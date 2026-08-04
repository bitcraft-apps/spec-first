#!/usr/bin/env bats

# Plugin Structure Integration Tests
# Tests core plugin structure and validation functionality

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    # Create clean test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    cd "$TEST_DIR"
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "framework directory structure exists" {
    [ -f "$PROJECT_ROOT/AGENTS.md" ]
    [ -f "$PROJECT_ROOT/VERSION" ]
    [ -d "$PROJECT_ROOT/skills" ]
    [ -d "$PROJECT_ROOT/agents" ]
    [ -x "$PROJECT_ROOT/scripts/validate-plugin.sh" ]
}

@test "framework validation includes version" {
    cd "$PROJECT_ROOT"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugin Version:"* ]]
}

@test "framework validation passes" {
    cd "$PROJECT_ROOT"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugin validation PASSED"* ]]
}

@test "the registered agent is configured" {
    # Only /sf:implement keeps a registered agent. The workflows hold the other prompts.
    [ -f "$PROJECT_ROOT/agents/implement-minimal.md" ]
    [ "$(find "$PROJECT_ROOT/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')" -eq 1 ]

    grep -q "name: implement-minimal" "$PROJECT_ROOT/agents/implement-minimal.md"
    grep -q "description:" "$PROJECT_ROOT/agents/implement-minimal.md"
    grep -q "^tools:.*Write" "$PROJECT_ROOT/agents/implement-minimal.md"
}

@test "spec skill delegates to the sf-spec workflow" {
    [ -f "$PROJECT_ROOT/skills/spec/SKILL.md" ]

    # Check YAML frontmatter
    grep -q "description:" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check delegation to the workflow
    grep -q 'name: "sf-spec"' "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '\$ARGUMENTS' "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "the registered agent names its inputs and outputs as literal paths" {
    local agent="$PROJECT_ROOT/agents/implement-minimal.md"

    grep -q "Inputs:" "$agent"
    grep -q "\.sf/research/pattern-example\.md" "$agent"
    grep -q "Output: Working code + \`\.sf/implementation-summary\.md\`" "$agent"

    # No agent resolves a path through a shell function
    ! grep -r "\$(get_research_dir)" "$PROJECT_ROOT/agents/"
    ! grep -r "\$(get_csf_dir)" "$PROJECT_ROOT/agents/"

    # Agents stay small
    [ "$(wc -l < "$agent")" -le 50 ]
}

@test "no tracked file outside CHANGELOG.md uses the old artifact path" {
    # Two string parts, so that this test file does not match its own needle
    local needle=".claude/"".sf"

    cd "$PROJECT_ROOT"
    # bats-core is a submodule, so git ls-files reports it as a directory
    run bash -c "git ls-files -z ':!:CHANGELOG.md' ':!:tests/bats-core' | xargs -0 grep -lF -- '$needle'"
    [ -z "$output" ]
}

