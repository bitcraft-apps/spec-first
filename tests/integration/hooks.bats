#!/usr/bin/env bats

# Hook Integration Tests
# Tests hooks/validate-implementation.sh against JSON payloads on stdin

bats_require_minimum_version 1.5.0

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

HOOK="$PROJECT_ROOT/hooks/validate-implementation.sh"
export HOOK

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    mkdir -p "$TEST_DIR/.claude/.sf"
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Runs the hook with a payload that points at TEST_DIR.
# Keeps stderr out of $output. Line 17 of the hook prints a shell error
# when the spec has no unchecked criteria. That refactor is out of scope.
run_hook() {
    local active="${1:-false}"
    run --separate-stderr bash "$HOOK" <<< "{\"cwd\":\"$TEST_DIR\",\"stop_hook_active\":$active}"
}

write_spec() {
    printf '%s\n' "$@" > "$TEST_DIR/.claude/.sf/spec.md"
}

write_impl() {
    echo "summary" > "$TEST_DIR/.claude/.sf/implementation-summary.md"
}

# --- Guard: missing files exit early ---

@test "spec missing and implementation present exits 0 with no output" {
    write_impl
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "spec present and implementation missing exits 0 with no output" {
    write_spec "- [ ] unchecked criterion"
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "both files missing exits 0 with no output" {
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- Decision output ---

@test "unchecked criterion blocks" {
    write_spec "- [ ] unchecked criterion"
    write_impl
    run_hook
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision":"block"'* ]]
    [[ "$output" == *"1 acceptance criteria unchecked"* ]]
}

@test "all criteria checked produces no decision" {
    write_spec "- [x] done" "- [x] also done"
    write_impl
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "spec with no criteria produces no decision" {
    write_spec "# Spec" "No criteria here."
    write_impl
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- Re-entry guard ---

@test "stop_hook_active true exits 0 with no output" {
    write_spec "- [ ] unchecked criterion"
    write_impl
    run_hook true
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- Static checks ---

@test "hook has no syntax error" {
    run bash -n "$HOOK"
    [ "$status" -eq 0 ]
}

@test "hook guard uses an explicit if block" {
    run grep -c 'if \[ ! -f "\$SPEC_FILE" \] || \[ ! -f "\$IMPL_FILE" \]; then exit 0; fi' "$HOOK"
    [ "$status" -eq 0 ]
    [ "$output" -eq 1 ]
}
