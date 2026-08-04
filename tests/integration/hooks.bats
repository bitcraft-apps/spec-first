#!/usr/bin/env bats

# Hook Integration Tests
# Tests the hook adapters in hooks/ against JSON payloads on stdin

bats_require_minimum_version 1.5.0

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    mkdir -p "$TEST_DIR/.sf"
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Runs a hook with a payload that points at TEST_DIR.
# Keeps stderr out of $output so that tests can assert on each stream.
run_hook() {
    local hook="$1" active="${2:-false}"
    run --separate-stderr bash "$PROJECT_ROOT/hooks/$hook" \
        <<< "{\"cwd\":\"$TEST_DIR\",\"stop_hook_active\":$active}"
}

# Substring assertions live in functions on purpose: a bare `[[ ... ]]` that is not the
# last command of a test body does not fail the test, so it would assert nothing.
assert_output_contains() {
    case "$output" in *"$1"*) return 0 ;; esac
    echo "expected output to contain: $1" >&2
    echo "actual output: $output" >&2
    return 1
}

refute_output_contains() {
    case "$output" in *"$1"*)
        echo "expected output not to contain: $1" >&2
        echo "actual output: $output" >&2
        return 1
        ;;
    esac
    return 0
}

write_spec() {
    printf '%s\n' "$@" > "$TEST_DIR/.sf/spec.md"
}

# A spec with every section validate-spec.sh looks for.
write_full_spec() {
    write_spec "## Problem" "..." "## Acceptance Criteria" "- [x] done" "## Risks" "none"
}

write_impl() {
    echo "summary" > "$TEST_DIR/.sf/implementation-summary.md"
}

# --- validate-implementation.sh: guard, missing files exit early ---

@test "spec missing and implementation present exits 0 with no output" {
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "spec present and implementation missing exits 0 with no output" {
    write_spec "- [ ] unchecked criterion"
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "both files missing exits 0 with no output" {
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- validate-implementation.sh: decision output ---

@test "unchecked criterion blocks" {
    write_spec "- [ ] unchecked criterion"
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    assert_output_contains '"decision":"block"'
    assert_output_contains "1 acceptance criteria unchecked"
}

@test "all criteria checked produces no decision" {
    write_spec "- [x] done" "- [x] also done"
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "spec with no criteria produces no decision" {
    write_spec "# Spec" "No criteria here."
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "checked criterion that quotes an unchecked marker produces no decision" {
    write_spec '- [x] Spec has one `- [ ]` criterion -> exit 0.'
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "counts only the unchecked criteria in a mixed spec" {
    write_spec \
        "- [x] first done" \
        '- [x] second done, and it mentions `- [ ]` in its text' \
        "- [ ] third not done" \
        "- [ ] fourth not done"
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    assert_output_contains "2 acceptance criteria unchecked"
}

# --- validate-implementation.sh: stderr ---

@test "all criteria checked writes nothing to stderr" {
    write_spec "- [x] done"
    write_impl
    run_hook validate-implementation.sh
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

# --- validate-implementation.sh: re-entry guard ---

@test "stop_hook_active true exits 0 with no output" {
    write_spec "- [ ] unchecked criterion"
    write_impl
    run_hook validate-implementation.sh true
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- validate-spec.sh ---

@test "no spec produces no decision" {
    run_hook validate-spec.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "spec missing every section blocks and names them all" {
    write_spec "# Notes" "nothing useful"
    run_hook validate-spec.sh
    [ "$status" -eq 0 ]
    assert_output_contains '"decision":"block"'
    assert_output_contains "scope/problem"
    assert_output_contains "acceptance criteria"
    assert_output_contains "risks"
}

@test "spec missing only risks blocks naming just that section" {
    write_spec "## Problem" "..." "## Acceptance Criteria" "- [x] done"
    run_hook validate-spec.sh
    [ "$status" -eq 0 ]
    assert_output_contains '"decision":"block"'
    assert_output_contains "risks"
    refute_output_contains "scope/problem"
    refute_output_contains "acceptance criteria"
}

@test "complete spec produces no decision" {
    write_full_spec
    run_hook validate-spec.sh
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "complete spec writes nothing to stderr" {
    write_full_spec
    run_hook validate-spec.sh
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "stop_hook_active true skips the spec check" {
    write_spec "# Notes" "nothing useful"
    run_hook validate-spec.sh true
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- Static checks ---

@test "validate-implementation hook has no syntax error" {
    run bash -n "$PROJECT_ROOT/hooks/validate-implementation.sh"
    [ "$status" -eq 0 ]
}

@test "validate-spec hook has no syntax error" {
    run bash -n "$PROJECT_ROOT/hooks/validate-spec.sh"
    [ "$status" -eq 0 ]
}
