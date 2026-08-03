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

@test "agents exist and are properly configured" {
    # Check all 4 spec agents exist
    [ -f "$PROJECT_ROOT/agents/define-scope.md" ]
    [ -f "$PROJECT_ROOT/agents/create-criteria.md" ]
    [ -f "$PROJECT_ROOT/agents/identify-risks.md" ]
    [ -f "$PROJECT_ROOT/agents/synthesize-spec.md" ]
    
    # Check YAML frontmatter for define-scope
    grep -q "name: define-scope" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "description:" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "tools: Write" "$PROJECT_ROOT/agents/define-scope.md"
}

@test "spec skill delegates to agents properly" {
    [ -f "$PROJECT_ROOT/skills/spec/SKILL.md" ]

    # Check YAML frontmatter
    grep -q "description:" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check delegation to agents
    grep -q "define-scope" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q "create-criteria" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q "identify-risks" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q "synthesize-spec" "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '\$ARGUMENTS' "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "agents have file persistence instructions" {
    # Verify agents write to research directory using literal paths
    grep -q "Output:" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "\.claude/\.sf/research.*scope.md" "$PROJECT_ROOT/agents/define-scope.md"

    # Verify synthesize-spec reads from research
    grep -q "Inputs:" "$PROJECT_ROOT/agents/synthesize-spec.md"
    grep -q "\.claude/\.sf/research.*\.md" "$PROJECT_ROOT/agents/synthesize-spec.md"

    # Verify agents are focused (small instruction sets)
    line_count=$(wc -l < "$PROJECT_ROOT/agents/define-scope.md")
    [ "$line_count" -le 50 ]
}

@test "agents specify correct file output locations" {
    # Verify all agents use literal .claude/.sf/research/ paths (not function calls)

    # Test core research agents output to .claude/.sf/research/
    grep -q "Output: \`\.claude/\.sf/research/scope\.md\`" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "Output: \`\.claude/\.sf/research/criteria\.md\`" "$PROJECT_ROOT/agents/create-criteria.md"
    grep -q "Output: \`\.claude/\.sf/research/risks\.md\`" "$PROJECT_ROOT/agents/identify-risks.md"

    # Test analysis agents output to .claude/.sf/research/
    grep -q "Output: \`\.claude/\.sf/research/implementation-summary\.md\`" "$PROJECT_ROOT/agents/analyze-implementation.md"
    grep -q "Output: \`\.claude/\.sf/research/artifacts-summary\.md\`" "$PROJECT_ROOT/agents/analyze-artifacts.md"

    # Test documentation agents output to .claude/.sf/research/
    grep -q "Output: \`\.claude/\.sf/research/technical-docs\.md\`" "$PROJECT_ROOT/agents/create-technical-docs.md"
    grep -q "Output: \`\.claude/\.sf/research/user-docs\.md\`" "$PROJECT_ROOT/agents/create-user-docs.md"

    # Test synthesis agents use .claude/.sf/ directly
    grep -q "Output: \`\.claude/\.sf/spec\.md\`" "$PROJECT_ROOT/agents/synthesize-spec.md"
    grep -q "Output: Working code + \`\.claude/\.sf/implementation-summary\.md\`" "$PROJECT_ROOT/agents/implement-minimal.md"

    # Verify NO agents use function calls like $(get_research_dir)
    ! grep -r "\$(get_research_dir)" "$PROJECT_ROOT/agents/"
    ! grep -r "\$(get_csf_dir)" "$PROJECT_ROOT/agents/"
}

