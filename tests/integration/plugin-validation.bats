#!/usr/bin/env bats

# Plugin Artifact Validation Tests
# Validates plugin.json, agent frontmatter, skill frontmatter, and hooks.json

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

@test "plugin.json is valid JSON with required fields" {
    run cat "$PROJECT_ROOT/.claude-plugin/plugin.json"
    [ "$status" -eq 0 ]

    # Parse with python (available on macOS/CI)
    echo "$output" | python3 -c "
import sys, json
data = json.load(sys.stdin)
assert 'name' in data, 'missing name'
assert 'version' in data, 'missing version'
"
}

@test "agents directory contains agent files" {
    local count=0
    for f in "$PROJECT_ROOT/agents/"*.md; do
        [ -f "$f" ] || continue
        count=$((count + 1))
    done
    [ "$count" -gt 0 ]
}

@test "skills directory contains skill files" {
    local count=0
    for d in "$PROJECT_ROOT/skills/"*/; do
        [ -f "$d/SKILL.md" ] || continue
        count=$((count + 1))
    done
    [ "$count" -gt 0 ]
}

@test "agent frontmatter is parseable YAML" {
    for agent in "$PROJECT_ROOT/agents/"*.md; do
        # Extract YAML frontmatter between --- delimiters
        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent" | sed '1d;$d')

        # Must have name and tools fields
        echo "$frontmatter" | grep -q "^name:" || {
            echo "Missing 'name:' in $(basename "$agent")" >&2
            return 1
        }
        echo "$frontmatter" | grep -q "^tools:" || {
            echo "Missing 'tools:' in $(basename "$agent")" >&2
            return 1
        }
    done
}

@test "agents that declare an output file have Write" {
    for agent in "$PROJECT_ROOT/agents/"*.md; do
        # Only agents whose Output line names a .md file.
        grep -q "^Output:.*\.md" "$agent" || continue

        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent" | sed '1d;$d')

        echo "$frontmatter" | grep "^tools:" | grep -q "Write" || {
            echo "$(basename "$agent") declares an output file but has no Write tool" >&2
            return 1
        }
    done
}

@test "skill frontmatter is parseable YAML" {
    for skill_dir in "$PROJECT_ROOT/skills/"*/; do
        local skill_file="$skill_dir/SKILL.md"
        [ -f "$skill_file" ] || {
            echo "Missing SKILL.md in $(basename "$skill_dir")" >&2
            return 1
        }

        local frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

        echo "$frontmatter" | grep -q "^description:" || {
            echo "Missing 'description:' in $(basename "$skill_dir")/SKILL.md" >&2
            return 1
        }
    done
}

@test "hooks.json is valid JSON with expected structure" {
    run cat "$PROJECT_ROOT/hooks/hooks.json"
    [ "$status" -eq 0 ]

    echo "$output" | python3 -c "
import sys, json
data = json.load(sys.stdin)
assert 'hooks' in data, 'missing hooks key'
hooks = data['hooks']
assert 'Stop' in hooks, 'missing Stop hook event'
"
}

@test "hooks.json references existing shell scripts" {
    local hooks_dir="$PROJECT_ROOT/hooks"
    local referenced_scripts
    referenced_scripts=$(cat "$hooks_dir/hooks.json" | python3 -c "
import sys, json, os
data = json.load(sys.stdin)
for event in data['hooks'].values():
    for entry in event:
        hooks = entry.get('hooks', [entry]) if 'hooks' in entry else [entry]
        for h in hooks:
            cmd = h.get('command', '')
            # Extract script basename from command like 'bash .../validate-spec.sh'
            parts = cmd.split('/')
            if parts:
                print(parts[-1])
")
    for script in $referenced_scripts; do
        [ -f "$hooks_dir/$script" ] || {
            echo "Missing hook script: $script" >&2
            return 1
        }
    done
}
