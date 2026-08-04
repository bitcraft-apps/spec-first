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

@test "every phase has an agent, registered or in a workflow" {
    # Phase 1: the spec workflow owns the research and the synthesis prompts
    grep -q "label: 'scope'" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'criteria'" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'risks'" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "label: 'synthesize-spec'" "$PROJECT_ROOT/workflows/spec.js"

    # Phase 2: the only registered agent
    [ -f "$PROJECT_ROOT/agents/implement-minimal.md" ]
    grep -q "name: implement-minimal" "$PROJECT_ROOT/agents/implement-minimal.md"

    # Phase 3: the document workflow owns the analysis, drafting and integration prompts
    grep -q "label: 'artifacts'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'implementation'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'inventory'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'technical-docs'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'user-docs'" "$PROJECT_ROOT/workflows/document.js"
    grep -q "label: 'integrate-docs'" "$PROJECT_ROOT/workflows/document.js"
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

@test "research agents touch no files" {
    # A workflow agent takes no tools field, so the prompt states the rule
    grep -q "Do not read or write files" "$PROJECT_ROOT/workflows/spec.js"

    # And each research result is a validated object, not a file
    grep -q "schema: SCOPE" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "schema: CRITERIA" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "schema: RISKS" "$PROJECT_ROOT/workflows/spec.js"
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

@test "workflow prompts follow minimalist principles" {
    grep -q "YAGNI, KISS, SRP" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "narrowest viable scope" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "Match doc weight to change weight" "$PROJECT_ROOT/workflows/document.js"
}

@test "the workflows pass results in memory" {
    # No stage writes or reads a research file
    ! grep -qE 'research/|research\.md' "$PROJECT_ROOT/workflows/spec.js"
    ! grep -qE 'research/|research\.md' "$PROJECT_ROOT/workflows/document.js"
}

@test "implementation follows sequential workflow" {
    # Verify implement skill uses sequential execution (Step 1, Step 2)
    grep -q "Step 1.*Learn" "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q "Step 2.*Implement" "$PROJECT_ROOT/skills/implement/SKILL.md"

    # Verify the philosophy of pattern-first implementation
    grep -q "Pattern consistency over creativity" "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q "Working code over perfect code" "$PROJECT_ROOT/skills/implement/SKILL.md"
}

@test "the risk prompt asks for blockers only" {
    grep -q "Blockers only, not every possible risk" "$PROJECT_ROOT/workflows/spec.js"
    grep -q "Essential edge " "$PROJECT_ROOT/workflows/spec.js"
}

@test "framework validation recognizes the registered agent" {
    cd "$PROJECT_ROOT"
    run ./scripts/validate-plugin.sh
    [ "$status" -eq 0 ]

    [[ "$output" == *"implement-minimal"* ]]
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

    # Verify the synthesis prompt enforces the line limit
    grep -q "under 50 lines" "$PROJECT_ROOT/workflows/spec.js"
}