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

    # Check spec skill calls the script and allows the Bash command
    grep -q 'scripts/spec-dir.sh \$MODE' "$skill_file"
    grep -q 'allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-dir.sh:\*)' "$skill_file"

    # Check it explains directory management workflow
    grep -q "Directory Management" "$skill_file"
    grep -q '"Update existing" / "Create new"' "$skill_file"
}

@test "directory isolation maintains backward compatibility" {
    # Check that synthesize-spec agent mentions symlink awareness
    grep -q "active.*directory\|symlink-aware" "$PROJECT_ROOT/agents/synthesize-spec.md"

    # Check output paths are documented correctly (now uses $SF_DIR variable)
    grep -q "SF_DIR/spec\.md.*direct file or symlink" "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "framework validation counts the agents without the directory agent" {
    # Run framework validation and check it counts the correct number of agents (11 total)
    cd "$PROJECT_ROOT"
    ./scripts/validate-plugin.sh 2>&1 | grep -q "Found 11 agent files"

    # The directory work is a script now, not an agent
    [ ! -f "$PROJECT_ROOT/agents/manage-spec-directory.md" ]
    [ -x "$PROJECT_ROOT/scripts/spec-dir.sh" ]
}
