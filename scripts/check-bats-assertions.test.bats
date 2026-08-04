#!/usr/bin/env bats

# Unit tests for scripts/check-bats-assertions.sh
# All tests invoke as subprocess against temp fixture git repositories

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

CHECK_SCRIPT="$PROJECT_ROOT/scripts/check-bats-assertions.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"
    mkdir -p "$FIXTURE_DIR/scripts"
    cp "$CHECK_SCRIPT" "$FIXTURE_DIR/scripts/check-bats-assertions.sh"
    chmod +x "$FIXTURE_DIR/scripts/check-bats-assertions.sh"
    cd "$FIXTURE_DIR"
    git init -q .
}

teardown() {
    rm -rf "$FIXTURE_DIR"
    # Set by the test that needs a directory outside any git repository. Cleaned up here so that
    # a failing assertion does not leak it.
    if [ -n "${SCRATCH_DIR:-}" ]; then
        rm -rf "$SCRATCH_DIR"
    fi
}

# The script reads the index, so a fixture file has to be tracked to be seen.
write_test_file() {
    local name="$1"
    shift
    printf '%s\n' "$@" > "$FIXTURE_DIR/$name"
    git add -A
}

@test "check-bats-assertions passes on a body with no [[ ]]" {
    write_test_file clean.bats \
        '@test "a" {' \
        '    run true' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
    assert_output_contains "PASS: 1 test body/bodies in 1 file(s)"
}

@test "check-bats-assertions allows a [[ ]] in final position" {
    write_test_file final.bats \
        '@test "a" {' \
        '    run true' \
        '    [ "$status" -eq 0 ]' \
        '    [[ "$output" == *ok* ]]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
}

@test "check-bats-assertions fails and names the non-final line" {
    write_test_file bad.bats \
        '@test "a" {' \
        '    run true' \
        '    [[ "$output" == *ok* ]]' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 1 ]
    assert_output_contains "bad.bats:3: non-final [[ ]] cannot fail this test"
    assert_output_contains "assert_output_contains"
}

@test "check-bats-assertions reports every offender in one run" {
    write_test_file bad.bats \
        '@test "a" {' \
        '    [[ "$output" == *one* ]]' \
        '    [[ "$output" == *two* ]]' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 1 ]
    assert_output_contains "bad.bats:2:"
    assert_output_contains "bad.bats:3:"
}

@test "check-bats-assertions ignores a trailing comment when finding the last line" {
    write_test_file comment.bats \
        '@test "a" {' \
        '    run true' \
        '    [[ "$output" == *ok* ]]' \
        '    # the assertion above is still the last significant line' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
}

@test "check-bats-assertions ignores [[ ]] inside a heredoc body" {
    write_test_file heredoc.bats \
        '@test "a" {' \
        "    cat > f <<'DOC'" \
        '    [[ this is data, not an assertion ]]' \
        '    DOC' \
        '    run true' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
}

@test "check-bats-assertions ignores [[ ]] inside a quoted argument" {
    # This file writes its own fixtures as quoted strings full of [[ ]], and the failure message
    # names the construct too. Neither is a conditional construct, so neither may be flagged.
    write_test_file quoted.bats \
        '@test "a" {' \
        '    printf "%s\n" '"'"'    [[ "$output" == *ok* ]]'"'"' > fixture.bats' \
        '    assert_output_contains "non-final [[ ]] cannot fail"' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
}

@test "check-bats-assertions ignores [[ ]] outside a test body" {
    write_test_file helper.bats \
        'setup() {' \
        '    [[ -n "$HOME" ]]' \
        '    export READY=1' \
        '}' \
        '' \
        '@test "a" {' \
        '    run true' \
        '    [ "$status" -eq 0 ]' \
        '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
}

@test "check-bats-assertions counts every tracked file" {
    write_test_file one.bats '@test "a" {' '    run true' '    [ "$status" -eq 0 ]' '}'
    write_test_file two.bats '@test "b" {' '    run true' '    [ "$status" -eq 0 ]' '}'

    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 0 ]
    assert_output_contains "2 test body/bodies in 2 file(s)"
}

@test "check-bats-assertions fails when no test files are tracked" {
    run ./scripts/check-bats-assertions.sh
    [ "$status" -eq 1 ]
    assert_output_contains "no tracked *.bats files found"
}

@test "check-bats-assertions fails outside a git repository" {
    SCRATCH_DIR="$(mktemp -d)"
    cp "$CHECK_SCRIPT" "$SCRATCH_DIR/check-bats-assertions.sh"
    cd "$SCRATCH_DIR"
    run env -u GIT_DIR -u GIT_WORK_TREE bash ./check-bats-assertions.sh
    [ "$status" -eq 1 ]
    assert_output_contains "not inside a git repository"
}
