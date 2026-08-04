#!/usr/bin/env bats

# Unit tests for check-workflow-scripts.sh
# Each case is a workflow script the Claude Code loader accepts or rejects.

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

CHECKER="$PROJECT_ROOT/scripts/check-workflow-scripts.sh"
export CHECKER

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    mkdir -p "$TEST_DIR/workflows"
    cd "$TEST_DIR"
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

# Writes a workflow script whose meta body is the given text.
write_workflow() {
    local file="$1" body="$2"
    {
        echo "export const meta = {"
        echo "$body"
        echo "}"
        echo "log('hello')"
    } > "workflows/$file"
}

@test "a valid workflow script passes" {
    write_workflow "spec.js" "  name: 'sf-spec',
  description: 'does a thing',"

    run "$CHECKER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 1 workflow script(s) load"* ]]
}

@test "an empty workflows directory passes" {
    run "$CHECKER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 0 workflow script(s) load"* ]]
}

@test "a missing workflows directory fails" {
    rmdir workflows

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"workflows/ directory not found"* ]]
}

@test "meta not on the first line fails" {
    printf "const RULES = 'x'\nexport const meta = {\n  name: 'sf-spec',\n}\n" > workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"must start with 'export const meta = {'"* ]]
}

@test "unparseable JavaScript fails" {
    write_workflow "spec.js" "  name: 'sf-spec',"
    echo "const x = (" >> workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is not parseable JavaScript"* ]]
}

@test "top-level return and await are accepted" {
    printf "export const meta = {\n  name: 'sf-spec',\n}\nif (!args) return { error: 'no args' }\nconst r = await agent('do it')\n" > workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 1 workflow script(s) load"* ]]
}

@test "a type annotation fails" {
    write_workflow "spec.js" "  name: 'sf-spec',"
    echo "const items: string[] = []" >> workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"is not parseable JavaScript"* ]]
}

@test "a variable in meta fails" {
    write_workflow "spec.js" "  name: NAME,"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"pure literal"* ]]
}

@test "a function call in meta fails" {
    write_workflow "spec.js" "  name: 'sf-' + suffix(),"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"pure literal"* ]]
}

@test "a template string in meta fails" {
    write_workflow "spec.js" "  name: \`sf-spec\`,"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"template strings are not allowed"* ]]
}

@test "a spread in meta fails" {
    write_workflow "spec.js" "  name: 'sf-spec',
  ...{ description: 'x' },"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"spreads are not allowed"* ]]
}

@test "a missing name fails" {
    write_workflow "spec.js" "  description: 'does a thing',"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"meta.name is missing"* ]]
}

@test "a name without the sf- prefix fails" {
    write_workflow "spec.js" "  name: 'research',"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"^sf-[a-z0-9-]+\$"* ]]
}

@test "two scripts sharing a name fails" {
    write_workflow "spec.js" "  name: 'sf-spec',"
    write_workflow "other.js" "  name: 'sf-spec',"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"both use the name 'sf-spec'"* ]]
}

@test "a closing brace that is not on its own line fails" {
    printf "export const meta = {\n  name: 'sf-spec' }\n" > workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"meta block not found"* ]]
}

# Writes a workflow declaring the Research and Synthesis phases, with the given body appended.
write_phased_workflow() {
    write_workflow "spec.js" "  name: 'sf-spec',
  phases: [
    { title: 'Research', detail: 'look around' },
    { title: 'Synthesis', detail: 'write it up' },
  ],"
    echo "$1" >> workflows/spec.js
}

@test "declared phases that the body enters pass" {
    write_phased_workflow "phase('Research')
await agent('research it')
phase('Synthesis')
await agent('write it up')"

    run "$CHECKER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 1 workflow script(s) load"* ]]
}

@test "a renamed meta title fails" {
    write_workflow "spec.js" "  name: 'sf-spec',
  phases: [
    { title: 'Research' },
    { title: 'Merge' },
  ],"
    printf "phase('Research')\nphase('Synthesis')\n" >> workflows/spec.js

    run "$CHECKER"
    [ "$status" -eq 1 ]
    assert_output_contains 'phase("Synthesis") has no meta.phases entry'
    assert_output_contains 'meta.phases declares "Merge" but nothing enters it'
}

@test "a phase call with no meta entry fails" {
    write_phased_workflow "phase('Research')
phase('Synthesis')
phase('Cleanup')"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *'phase("Cleanup") has no meta.phases entry'* ]]
}

@test "a declared phase nothing enters fails" {
    write_phased_workflow "phase('Research')"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *'meta.phases declares "Synthesis" but nothing enters it'* ]]
}

@test "a phase entered only through agent opts passes" {
    write_phased_workflow "phase('Research')
await agent('write it up', { label: 'synthesize', phase: 'Synthesis' })"

    run "$CHECKER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 1 workflow script(s) load"* ]]
}

@test "an agent opts phase with no meta entry fails" {
    write_phased_workflow "phase('Research')
phase('Synthesis')
await agent('write it up', { label: 'synthesize', phase: 'Merge' })"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *'an agent opts phase "Merge" has no meta.phases entry'* ]]
}

@test "a computed phase argument fails" {
    write_phased_workflow "const title = 'Research'
phase(title)
phase('Synthesis')"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"phase() needs a string literal"* ]]
}

@test "a phase declared without a title fails" {
    write_workflow "spec.js" "  name: 'sf-spec',
  phases: [
    { detail: 'look around' },
  ],"

    run "$CHECKER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"needs a string title"* ]]
}
