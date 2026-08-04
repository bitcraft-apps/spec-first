#!/usr/bin/env bats

# Directory Isolation Feature Tests
# Behaviour of scripts/spec-dir.sh lives in scripts/spec-dir.test.bats

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

@test "spec skill halts on spec-dir.sh failure" {
    local skill_file="$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check that spec skill documents halting on failure
    grep -q 'spec-dir.sh fails.*halt' "$skill_file"
}

@test "spec skill includes directory management step" {
    local skill_file="$PROJECT_ROOT/skills/spec/SKILL.md"

    # Check spec skill calls the script. No allowed-tools: the field is Claude-only.
    grep -q 'scripts/spec-dir.sh \$MODE' "$skill_file"
    ! grep -q 'allowed-tools' "$skill_file"

    # Check it explains directory management workflow
    grep -q "Directory Management" "$skill_file"
    grep -q '"Update existing" / "Create new"' "$skill_file"
}

@test "document skill delegates its gates to doc-gates.sh" {
    local skill_file="$PROJECT_ROOT/skills/document/SKILL.md"

    ! grep -q 'allowed-tools' "$skill_file"
    grep -q 'scripts/doc-gates.sh analysis' "$skill_file"
    grep -q 'scripts/doc-gates.sh generation' "$skill_file"
    grep -q 'doc-gates.sh fails.*halt' "$skill_file"

    # Gate 3 had no deterministic check, so it is gone
    ! grep -q 'Gate 3' "$skill_file"

    [ -x "$PROJECT_ROOT/scripts/doc-gates.sh" ]
}

@test "directory isolation maintains backward compatibility" {
    # Check output paths are documented correctly (now uses $SF_DIR variable)
    grep -q "SF_DIR/spec\.md.*direct file or symlink" "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "framework validation counts the one registered agent" {
    # The workflow scripts hold the other prompts, so they need no registration
    cd "$PROJECT_ROOT"
    ./scripts/validate-plugin.sh 2>&1 | grep -q "Found 1 agent files"

    # The directory work is a script now, not an agent
    [ ! -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]
    [ -x "$PROJECT_ROOT/scripts/spec-dir.sh" ]
}
