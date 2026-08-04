# shellcheck shell=bash
#
# This file is sourced by bats, never executed.
#
# Shared bats assertions. Load with an absolute path, since test files live in
# several directories and bats resolves a bare `load` against $BATS_TEST_DIRNAME:
#
#     load "$PROJECT_ROOT/tests/helpers/assertions.bash"
#
# Every assertion here is a *function* on purpose. bats runs a test body under
# `set -eET` and detects failure through a DEBUG trap, and `[[ ... ]]` is a bash
# conditional construct rather than a simple command — so a failing `[[ ... ]]`
# that is not the last line of a test body does not fail the test, it asserts
# nothing at all. A function call is a simple command, so it does fail.
#
# Do not inline `[[ ... ]]` in a test body. scripts/check-bats-assertions.sh
# enforces this.

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

assert_success() {
    [ "$status" -eq 0 ] || {
        echo "expected success (exit code 0), got: $status" >&2
        echo "actual output: $output" >&2
        return 1
    }
}

assert_failure() {
    [ "$status" -ne 0 ] || {
        echo "expected failure (non-zero exit code), got: $status" >&2
        echo "actual output: $output" >&2
        return 1
    }
}
