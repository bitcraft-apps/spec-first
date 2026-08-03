#!/usr/bin/env bats

# Unit tests for scripts/validate-implementation.sh

bats_require_minimum_version 1.5.0

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
VALIDATE_IMPL_SH="$PROJECT_ROOT/scripts/validate-implementation.sh"
export VALIDATE_IMPL_SH

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    mkdir -p "$TEST_DIR/.sf"
    unset SF_DIR
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Run the script from $1 with the remaining arguments, and no stdin
run_validate_impl() {
    local cwd="$1"; shift
    (cd "$cwd" && bash "$VALIDATE_IMPL_SH" "$@" < /dev/null)
}

write_spec() {
    printf '%s\n' "$@" > "$TEST_DIR/.sf/spec.md"
}

write_impl() {
    echo "summary" > "$TEST_DIR/.sf/implementation-summary.md"
}

# --- Guard: missing files exit early ---

@test "a missing spec exits 0 with no output" {
    write_impl

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ -z "$stderr" ]
}

@test "a missing implementation summary exits 0 with no output" {
    write_spec "- [ ] unchecked criterion"

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "both files missing exits 0 with no output" {
    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

# --- The count ---

@test "an unchecked criterion fails" {
    write_spec "- [ ] unchecked criterion"
    write_impl

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    [ "$stderr" = "1 acceptance criteria unchecked in spec" ]
}

@test "all criteria checked passes" {
    write_spec "- [x] done" "- [x] also done"
    write_impl

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "a spec with no criteria passes" {
    write_spec "# Spec" "No criteria here."
    write_impl

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "a checked criterion that quotes an unchecked marker passes" {
    write_spec '- [x] Spec has one `- [ ]` criterion -> exit 0.'
    write_impl

    run run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
}

@test "it counts only the unchecked criteria in a mixed spec" {
    write_spec \
        "- [x] first done" \
        '- [x] second done, and it mentions `- [ ]` in its text' \
        "- [ ] third not done" \
        "- [ ] fourth not done"
    write_impl

    run --separate-stderr run_validate_impl "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    [ "$stderr" = "2 acceptance criteria unchecked in spec" ]
}

# --- Directory resolution ---

@test "the directory argument wins over SF_DIR" {
    export SF_DIR="$TEST_DIR/from-env"
    mkdir -p "$TEST_DIR/from-arg"
    printf '%s\n' "- [x] done" > "$TEST_DIR/from-arg/spec.md"
    echo "summary" > "$TEST_DIR/from-arg/implementation-summary.md"

    run run_validate_impl "$TEST_DIR" "$TEST_DIR/from-arg"
    [ "$status" -eq 0 ]
}

@test "an empty directory argument falls back to SF_DIR" {
    export SF_DIR="$TEST_DIR/custom"
    mkdir -p "$SF_DIR"
    printf '%s\n' "- [ ] not done" > "$SF_DIR/spec.md"
    echo "summary" > "$SF_DIR/implementation-summary.md"

    run run_validate_impl "$TEST_DIR" ""
    [ "$status" -eq 1 ]
}

@test "without a directory it reads .sf in the current directory" {
    write_spec "- [ ] not done"
    write_impl

    run run_validate_impl "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "script has no syntax error" {
    run bash -n "$VALIDATE_IMPL_SH"
    [ "$status" -eq 0 ]
}
