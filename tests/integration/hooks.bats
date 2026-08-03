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
    mkdir -p "$TEST_DIR/.sf"
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Runs the hook with a payload that points at TEST_DIR.
# Keeps stderr out of $output so that tests can assert on each stream.
run_hook() {
    local active="${1:-false}"
    run --separate-stderr bash "$HOOK" <<< "{\"cwd\":\"$TEST_DIR\",\"stop_hook_active\":$active}"
}

write_spec() {
    printf '%s\n' "$@" > "$TEST_DIR/.sf/spec.md"
}

write_impl() {
    echo "summary" > "$TEST_DIR/.sf/implementation-summary.md"
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

@test "checked criterion that quotes an unchecked marker produces no decision" {
    write_spec '- [x] Spec has one `- [ ]` criterion -> exit 0.'
    write_impl
    run_hook
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
    run_hook
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 acceptance criteria unchecked"* ]]
}

# --- stderr ---

@test "all criteria checked writes nothing to stderr" {
    write_spec "- [x] done"
    write_impl
    run_hook
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
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
