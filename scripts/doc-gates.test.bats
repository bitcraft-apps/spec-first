#!/usr/bin/env bats

# Unit tests for scripts/doc-gates.sh

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

DOC_GATES_SH="$PROJECT_ROOT/scripts/doc-gates.sh"
export DOC_GATES_SH

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    mkdir -p "$TEST_DIR/.sf/research"
    unset SF_DIR
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Run the script from $1 with the remaining arguments
run_doc_gates() {
    local cwd="$1"; shift
    (cd "$cwd" && bash "$DOC_GATES_SH" "$@")
}

# Create the analysis files the script expects
write_analysis_files() {
    touch "$1/artifacts-summary.md" "$1/implementation-summary.md" "$1/docs-inventory.md"
}

@test "rejects a missing mode" {
    run run_doc_gates "$TEST_DIR"
    [ "$status" -eq 1 ]
    assert_output_contains "Usage:"
}

@test "rejects an unknown mode" {
    run run_doc_gates "$TEST_DIR" bogus "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    assert_output_contains "Usage:"
}

@test "analysis passes when all three files exist" {
    write_analysis_files "$TEST_DIR/.sf/research"

    run run_doc_gates "$TEST_DIR" analysis "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    assert_output_contains "PASS artifacts-summary.md"
    assert_output_contains "PASS implementation-summary.md"
    assert_output_contains "PASS docs-inventory.md"
}

@test "analysis names the missing file" {
    touch "$TEST_DIR/.sf/research/artifacts-summary.md"

    run run_doc_gates "$TEST_DIR" analysis "$TEST_DIR/.sf"
    [ "$status" -eq 1 ]
    assert_output_contains "FAIL implementation-summary.md: missing from $TEST_DIR/.sf/research"
    assert_output_contains "FAIL docs-inventory.md"
}

@test "analysis ignores placeholder markers" {
    write_analysis_files "$TEST_DIR/.sf/research"
    echo "The spec says TODO for the retry policy" > "$TEST_DIR/.sf/research/artifacts-summary.md"

    run run_doc_gates "$TEST_DIR" analysis "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
}

@test "generation passes when both docs exist" {
    echo "# Reference" > "$TEST_DIR/.sf/research/technical-docs.md"
    echo "# Guide" > "$TEST_DIR/.sf/research/user-docs.md"

    run run_doc_gates "$TEST_DIR" generation "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    assert_output_contains "PASS technical-docs.md"
    assert_output_contains "PASS user-docs.md"
}

@test "generation blocks every placeholder marker" {
    for marker in TODO TBD PLACEHOLDER "[INSERT name]" todo; do
        echo "$marker" > "$TEST_DIR/.sf/research/technical-docs.md"
        touch "$TEST_DIR/.sf/research/user-docs.md"

        run run_doc_gates "$TEST_DIR" generation "$TEST_DIR/.sf"
        [ "$status" -eq 1 ]
        assert_output_contains "FAIL technical-docs.md: contains a placeholder marker"
    done
}

@test "an empty file passes" {
    touch "$TEST_DIR/.sf/research/technical-docs.md" "$TEST_DIR/.sf/research/user-docs.md"

    run run_doc_gates "$TEST_DIR" generation "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
}

@test "the directory argument wins over SF_DIR" {
    export SF_DIR="$TEST_DIR/from-env"
    mkdir -p "$TEST_DIR/from-arg/research"
    write_analysis_files "$TEST_DIR/from-arg/research"

    run run_doc_gates "$TEST_DIR" analysis "$TEST_DIR/from-arg"
    [ "$status" -eq 0 ]
}

@test "an empty directory argument falls back to SF_DIR" {
    export SF_DIR="$TEST_DIR/custom"
    mkdir -p "$SF_DIR/research"
    write_analysis_files "$SF_DIR/research"

    run run_doc_gates "$TEST_DIR" analysis ""
    [ "$status" -eq 0 ]
}

@test "without a directory it reads .sf in the current directory" {
    write_analysis_files "$TEST_DIR/.sf/research"

    run run_doc_gates "$TEST_DIR" analysis
    [ "$status" -eq 0 ]
}
