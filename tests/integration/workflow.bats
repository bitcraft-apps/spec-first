#!/usr/bin/env bats

# 4-Phase Workflow Integration Tests
# Tests the complete specification → planning → implementation → documentation workflow

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    # Create clean test environment
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    cd "$TEST_DIR"
    
    # Create a minimal project structure for testing
    mkdir -p src docs/specifications docs/plans
    
    # Create a simple package.json for testing
    cat > package.json << 'EOF'
{
    "name": "test-project",
    "version": "1.0.0",
    "scripts": {
        "test": "echo 'No tests specified'"
    }
}
EOF

    # Create a basic source file
    cat > src/index.js << 'EOF'
function greet(name) {
    return `Hello, ${name}!`;
}

module.exports = { greet };
EOF
}

teardown() {
    # Cleanup test environment
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "all phases have corresponding agents" {
    # Phase 1: Specification agents
    [ -f "$PROJECT_ROOT/agents/define-scope.md" ]
    grep -q "name: define-scope" "$PROJECT_ROOT/agents/define-scope.md"
    
    [ -f "$PROJECT_ROOT/agents/create-criteria.md" ]
    grep -q "name: create-criteria" "$PROJECT_ROOT/agents/create-criteria.md"
    
    [ -f "$PROJECT_ROOT/agents/identify-risks.md" ]
    grep -q "name: identify-risks" "$PROJECT_ROOT/agents/identify-risks.md"
    
    [ -f "$PROJECT_ROOT/agents/synthesize-spec.md" ]
    grep -q "name: synthesize-spec" "$PROJECT_ROOT/agents/synthesize-spec.md"
    
    # Phase 2: Implementation agents
    [ -f "$PROJECT_ROOT/agents/implement-minimal.md" ]
    grep -q "name: implement-minimal" "$PROJECT_ROOT/agents/implement-minimal.md"
    
    # Phase 3: Documentation agents
    [ -f "$PROJECT_ROOT/agents/analyze-artifacts.md" ]
    grep -q "name: analyze-artifacts" "$PROJECT_ROOT/agents/analyze-artifacts.md"
    [ -f "$PROJECT_ROOT/agents/analyze-implementation.md" ]
    grep -q "name: analyze-implementation" "$PROJECT_ROOT/agents/analyze-implementation.md"
    [ -f "$PROJECT_ROOT/agents/create-technical-docs.md" ]
    grep -q "name: create-technical-docs" "$PROJECT_ROOT/agents/create-technical-docs.md"
    [ -f "$PROJECT_ROOT/agents/create-user-docs.md" ]
    grep -q "name: create-user-docs" "$PROJECT_ROOT/agents/create-user-docs.md"
    [ -f "$PROJECT_ROOT/agents/integrate-docs.md" ]
    grep -q "name: integrate-docs" "$PROJECT_ROOT/agents/integrate-docs.md"
}

@test "all phases have corresponding skills" {
    # Phase 1: Specification
    [ -f "$PROJECT_ROOT/skills/spec/SKILL.md" ]
    grep -q "spec" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Phase 2: Implementation
    [ -f "$PROJECT_ROOT/skills/implement/SKILL.md" ]
    grep -q "Explore" "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q "implement-minimal" "$PROJECT_ROOT/skills/implement/SKILL.md"

    # Phase 3: Documentation
    [ -f "$PROJECT_ROOT/skills/document/SKILL.md" ]
    grep -q 'name: "sf-document"' "$PROJECT_ROOT/skills/document/SKILL.md"
    grep -q "label: 'artifacts'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'implementation'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'technical-docs'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'user-docs'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'integrate-docs'" "$PROJECT_ROOT/workflows/document.js"
}

# The body up to "## On Claude Code" must run on a host without subagents.
# Skips the frontmatter, which is host-specific by nature.
default_path() {
    awk 'NR>1 && /^---$/ {body=1; next} /^## On Claude Code/ {exit} body' \
        "$PROJECT_ROOT/skills/$1/SKILL.md"
}

@test "default path of every skill is host-neutral" {
    local pattern
    pattern="$(basename -a "$PROJECT_ROOT"/agents/*.md | sed 's/\.md$//' | paste -sd'|' -)"

    for skill in spec implement document; do
        grep -q '^## On Claude Code' "$PROJECT_ROOT/skills/$skill/SKILL.md"
        ! default_path "$skill" \
            | grep -qE 'Task:|subagent_type|AskUserQuestion|\$\{CLAUDE_|Explore'"|$pattern"
    done
}

@test "agents are properly configured for safe research" {
    # Verify agents have minimal tool sets
    grep -q "tools: Write" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "tools: Write" "$PROJECT_ROOT/agents/create-criteria.md"
    grep -q "tools: Write" "$PROJECT_ROOT/agents/identify-risks.md"
    grep -q "tools: Read, Write" "$PROJECT_ROOT/agents/synthesize-spec.md"
}

@test "implementation agents have appropriate tools" {
    # Verify implement-minimal has implementation tools
    grep -q "tools: Read, Write, Edit, Bash" "$PROJECT_ROOT/agents/implement-minimal.md"
    
    # Check that implement-minimal works with specifications
    grep -q -i "spec" "$PROJECT_ROOT/agents/implement-minimal.md"
}

@test "specification research runs in parallel" {
    # The spec skill hands the work to the workflow
    grep -q 'name: "sf-spec"' "$PROJECT_ROOT/skills/spec/SKILL.md"

    # The workflow fans out the three research agents with parallel()
    grep -q "await parallel(" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'scope'" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'criteria'" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'risks'" "$PROJECT_ROOT/workflows/spec.js"
}

@test "agents follow minimalist principles" {
    # Verify agents enforce MVP principles
    grep -q "MVP" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "YAGNI" "$PROJECT_ROOT/agents/define-scope.md"
    grep -q "KISS" "$PROJECT_ROOT/agents/create-criteria.md"
}

@test "synthesize-spec reads from research outputs" {
    # Verify synthesize-spec agent reads from agent outputs using literal paths
    grep -q "\.sf/research" "$PROJECT_ROOT/agents/synthesize-spec.md"
    grep -q "Inputs.*\.sf/research.*\.md" "$PROJECT_ROOT/agents/synthesize-spec.md"
}

@test "implementation follows sequential workflow" {
    # Verify implement skill uses sequential execution (Step 1, Step 2)
    grep -q "Step 1.*Learn" "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q "Step 2.*Implement" "$PROJECT_ROOT/skills/implement/SKILL.md"

    # Verify the philosophy of pattern-first implementation
    grep -q "Pattern consistency over creativity" "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q "Working code over perfect code" "$PROJECT_ROOT/skills/implement/SKILL.md"
}

@test "risk agent focuses on essential risks" {
    # Verify risk agent focuses on blockers, not comprehensive risks
    grep -q -i "essential risks" "$PROJECT_ROOT/agents/identify-risks.md"
    grep -q "blockers" "$PROJECT_ROOT/agents/identify-risks.md"
    grep -q "simple solutions" "$PROJECT_ROOT/agents/identify-risks.md"
}

@test "documentation phase includes specification and implementation" {
    # Verify documentation agents handle both specifications and implementation
    grep -q -i "artifacts" "$PROJECT_ROOT/agents/analyze-artifacts.md"
    grep -q -i "implementation" "$PROJECT_ROOT/agents/analyze-implementation.md"
    grep -q -i "technical" "$PROJECT_ROOT/agents/create-technical-docs.md"
    grep -q -i "user" "$PROJECT_ROOT/agents/create-user-docs.md"
}

@test "framework validation recognizes all agents" {
    cd "$PROJECT_ROOT"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]
    
    # Verify agents are validated
    [[ "$output" == *"define-scope"* ]]
    [[ "$output" == *"create-criteria"* ]]
    [[ "$output" == *"identify-risks"* ]]
    [[ "$output" == *"synthesize-spec"* ]]
}

@test "framework validation recognizes all 3 skills" {
    cd "$PROJECT_ROOT"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]

    # Check that framework finds 3 skill files (spec, implement, document)
    [[ "$output" == *"Found 3 skill files"* ]]
}

@test "specification maintains minimalist philosophy" {
    # Verify spec skill maintains specification-first philosophy
    grep -q "specification" "$PROJECT_ROOT/skills/spec/SKILL.md"

    # Verify synthesize-spec enforces line limits
    grep -q "under 50 lines" "$PROJECT_ROOT/agents/synthesize-spec.md"
}