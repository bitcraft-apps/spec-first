#!/usr/bin/env bats

# Unit tests for check-workflow-scripts.sh
# Each case is a workflow script the Claude Code loader accepts or rejects.

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
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
