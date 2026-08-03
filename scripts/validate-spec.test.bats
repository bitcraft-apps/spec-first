#!/usr/bin/env bats

# Unit tests for scripts/validate-spec.sh

bats_require_minimum_version 1.5.0

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
VALIDATE_SPEC_SH="$PROJECT_ROOT/scripts/validate-spec.sh"
export VALIDATE_SPEC_SH

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
run_validate_spec() {
    local cwd="$1"; shift
    (cd "$cwd" && bash "$VALIDATE_SPEC_SH" "$@" < /dev/null)
}

# Write a spec that has every section
write_complete_spec() {
    printf '%s\n' "## Scope" "## Acceptance Criteria" "## Risks" > "$1"
}

@test "a missing spec exits 0 with no output" {
    run --separate-stderr run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ -z "$stderr" ]
}

@test "a complete spec passes" {
    write_complete_spec "$TEST_DIR/.sf/spec.md"

    run --separate-stderr run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}

@test "a spec with no sections names all three" {
    printf '# Spec\nnothing useful here\n' > "$TEST_DIR/.sf/spec.md"

    run --separate-stderr run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    [ "$stderr" = "Spec missing sections: scope/problem, acceptance criteria, risks" ]
}

@test "the scope section also matches the word problem" {
    printf '%s\n' "## Problem" "## Acceptance Criteria" "## Risks" > "$TEST_DIR/.sf/spec.md"

    run run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
}

@test "it names only the missing section" {
    printf '%s\n' "## Scope" "## Risks" > "$TEST_DIR/.sf/spec.md"

    run --separate-stderr run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    [ "$stderr" = "Spec missing sections: acceptance criteria" ]
}

@test "section names match in any case" {
    printf '%s\n' "## SCOPE" "## acceptance" "## RiSk" > "$TEST_DIR/.sf/spec.md"

    run run_validate_spec "$TEST_DIR" "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
}

@test "the directory argument wins over SF_DIR" {
    export SF_DIR="$TEST_DIR/from-env"
    mkdir -p "$TEST_DIR/from-arg"
    write_complete_spec "$TEST_DIR/from-arg/spec.md"

    run run_validate_spec "$TEST_DIR" "$TEST_DIR/from-arg"
    [ "$status" -eq 0 ]
}

@test "an empty directory argument falls back to SF_DIR" {
    export SF_DIR="$TEST_DIR/custom"
    mkdir -p "$SF_DIR"
    printf '# Spec\nnothing useful here\n' > "$SF_DIR/spec.md"

    run run_validate_spec "$TEST_DIR" ""
    [ "$status" -eq 1 ]
}

@test "without a directory it reads .sf in the current directory" {
    printf '# Spec\nnothing useful here\n' > "$TEST_DIR/.sf/spec.md"

    run run_validate_spec "$TEST_DIR"
    [ "$status" -eq 1 ]
}

@test "script has no syntax error" {
    run bash -n "$VALIDATE_SPEC_SH"
    [ "$status" -eq 0 ]
}
