#!/usr/bin/env bats

# Control-flow tests for workflows/*.js
# Each case runs a real workflow body through tests/workflow-harness.mjs, which stubs the injected
# globals. No model calls. These cover the paths a manual /sf: run never reaches: a JSON-string
# args, a missing argument, a draft with a placeholder marker and two empty drafts.

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

HARNESS="$PROJECT_ROOT/tests/workflow-harness.mjs"
export HARNESS

# Every research agent returns a valid result, so only the args handling decides the outcome.
SPEC_AGENTS='{"scope":{"include":["a flag"],"exclude":["a config file"]},"criteria":{"criteria":["the flag works"]},"risks":{"risks":["none"]},"synthesize-spec":"written"}'
export SPEC_AGENTS

# The three analysis results document.js needs before it drafts anything.
DOC_ANALYSIS='"artifacts":{"requirements":["a flag"],"outcomes":["the flag works"]},"implementation":{"files":["src/index.js"],"interfaces":["greet()"]},"inventory":{"docs":[{"path":"README.md","topic":"overview"}]}'
export DOC_ANALYSIS

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Runs a workflow with the given fixture JSON and leaves the harness output in $output.
run_workflow() {
    local workflow="$1" fixture="$2"
    printf '%s' "$fixture" > "$TEST_DIR/fixture.json"
    run node "$HARNESS" "$PROJECT_ROOT/workflows/$workflow" "$TEST_DIR/fixture.json"
}

@test "sf-spec runs every agent when args is an object" {
    run_workflow spec.js '{"args":{"requirements":"add a flag","specPath":"docs/spec.md","templatePath":"tpl.md"},"agents":'"$SPEC_AGENTS"'}'

    [ "$status" -eq 0 ]
    assert_output_contains '"specPath":"docs/spec.md"'
    assert_output_contains '"agents":["scope","criteria","risks","synthesize-spec"]'
    assert_output_contains '"phases":["Research","Synthesis"]'
}

@test "sf-spec treats a JSON-string args the same as an object" {
    # The caller is a model. This path shipped broken once: args arrived as a string, the script
    # read undefined off it and wrote a spec to the wrong directory.
    run_workflow spec.js '{"args":{"requirements":"add a flag","specPath":"docs/spec.md","templatePath":"tpl.md"},"agents":'"$SPEC_AGENTS"'}'
    [ "$status" -eq 0 ]
    local from_object="$output"

    run_workflow spec.js '{"args":"{\"requirements\":\"add a flag\",\"specPath\":\"docs/spec.md\",\"templatePath\":\"tpl.md\"}","agents":'"$SPEC_AGENTS"'}'
    [ "$status" -eq 0 ]
    [ "$output" = "$from_object" ]
}

@test "sf-spec errors and starts no agent when requirements is missing" {
    run_workflow spec.js '{"args":{"specPath":"docs/spec.md","templatePath":"tpl.md"},"agents":'"$SPEC_AGENTS"'}'

    [ "$status" -eq 0 ]
    assert_output_contains 'needs requirements, specPath and templatePath'
    assert_output_contains '"agents":[]'
}

@test "sf-spec skips synthesis when a research agent returns nothing" {
    # A dead subagent resolves to null, so the fixture omits the risks label.
    run_workflow spec.js '{"args":{"requirements":"add a flag","specPath":"docs/spec.md","templatePath":"tpl.md"},"agents":{"scope":{"include":["a flag"],"exclude":[]},"criteria":{"criteria":["it works"]}}}'

    [ "$status" -eq 0 ]
    assert_output_contains 'Research incomplete'
    refute_output_contains 'synthesize-spec'
}

@test "sf-document integrates the drafts on the happy path" {
    run_workflow document.js '{"args":{"specPath":"docs/spec.md"},"agents":{'"$DOC_ANALYSIS"',"technical-docs":{"markdown":"## API"},"user-docs":{"markdown":"Pass --flag."},"integrate-docs":{"changed":["README.md"]}}}'

    [ "$status" -eq 0 ]
    assert_output_contains '"changed":["README.md"]'
    assert_output_contains '"integrate-docs"'
    assert_output_contains '"phases":["Analysis","Drafting","Integration"]'
}

@test "sf-document errors and starts no agent without a source path" {
    run_workflow document.js '{"args":{},"agents":{'"$DOC_ANALYSIS"'}}'

    [ "$status" -eq 0 ]
    assert_output_contains 'needs specPath or implementationPath'
    assert_output_contains '"agents":[]'
}

@test "sf-document integrates nothing when a draft has a placeholder marker" {
    run_workflow document.js '{"args":{"specPath":"docs/spec.md"},"agents":{'"$DOC_ANALYSIS"',"technical-docs":{"markdown":"## API\nTODO: fill this in"},"user-docs":{"markdown":"Pass --flag."},"integrate-docs":{"changed":["README.md"]}}}'

    [ "$status" -eq 0 ]
    assert_output_contains 'placeholder marker: technical'
    refute_output_contains 'integrate-docs'
    assert_output_contains '"phases":["Analysis","Drafting"]'
}

@test "sf-document integrates nothing when both drafts are empty" {
    run_workflow document.js '{"args":{"implementationPath":"src/index.js"},"agents":{'"$DOC_ANALYSIS"',"technical-docs":{"markdown":"   "},"user-docs":{"markdown":""},"integrate-docs":{"changed":["README.md"]}}}'

    [ "$status" -eq 0 ]
    assert_output_contains '"changed":[]'
    assert_output_contains 'needs no documentation'
    refute_output_contains 'integrate-docs'
}
