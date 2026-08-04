#!/usr/bin/env bats

# Error Recovery and Edge Case E2E Tests
# Tests how the system handles various error conditions and edge cases

# Detect project root directory
PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

# Require minimum BATS version for run flags
bats_require_minimum_version 1.5.0

# Create a mock repo structure that validate-plugin.sh can run against
setup_mock_repo() {
    local repo_dir="$1"
    mkdir -p "$repo_dir/agents" "$repo_dir/skills" "$repo_dir/scripts"

    # Copy VERSION
    cp "$PROJECT_ROOT/VERSION" "$repo_dir/"

    # Copy validation script
    cp "$PROJECT_ROOT/scripts/validate-plugin.sh" "$repo_dir/scripts/"
    chmod +x "$repo_dir/scripts/validate-plugin.sh"

    # Copy agents
    for f in "$PROJECT_ROOT/agents/"*.md; do
        [ -f "$f" ] && cp "$f" "$repo_dir/agents/"
    done

    # Copy skills
    for d in "$PROJECT_ROOT/skills/"*/; do
        [ -d "$d" ] && mkdir -p "$repo_dir/skills/$(basename "$d")" && \
            cp "$d/SKILL.md" "$repo_dir/skills/$(basename "$d")/"
    done

    # Copy docs needed for validation
    [ -f "$PROJECT_ROOT/AGENTS.md" ] && cp "$PROJECT_ROOT/AGENTS.md" "$repo_dir/"
    [ -f "$PROJECT_ROOT/README.md" ] && cp "$PROJECT_ROOT/README.md" "$repo_dir/"
    # Skip .claude-plugin/ — tests manipulate VERSION, so copying plugin.json/marketplace.json
    # would cause version mismatch failures. Version-match checks are conditional on file existence.
}

assert_success() {
    [ "$status" -eq 0 ] || {
        echo "Expected success (exit code 0), got: $status" >&2
        echo "Output: $output" >&2
        return 1
    }
}

assert_failure() {
    [ "$status" -ne 0 ] || {
        echo "Expected failure (non-zero exit code), got: $status" >&2
        echo "Output: $output" >&2
        return 1
    }
}

assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected" >&2
        echo "Actual output: $output" >&2
        return 1
    fi
}

test_info() {
    echo "INFO: $*" >&2
}

test_error() {
    echo "ERROR: $*" >&2
}

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export ORIGINAL_PWD="$(pwd)"
}

teardown() {
    if [ -n "$ORIGINAL_PWD" ] && [ -d "$ORIGINAL_PWD" ]; then
        cd "$ORIGINAL_PWD"
    fi
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

@test "recover from corrupted VERSION file" {
    MOCK_REPO="$TEST_DIR/repo"
    setup_mock_repo "$MOCK_REPO"
    cd "$MOCK_REPO"

    # Corrupt the VERSION file
    echo "invalid.version.format" > VERSION

    run ./scripts/validate-plugin.sh
    assert_failure
    assert_output_contains "Plugin Version: invalid.version.format"
    assert_output_contains "Plugin validation FAILED"
    test_info "Plugin validation detects corrupted VERSION"

    # Recovery: Fix the VERSION file
    echo "1.0.0" > VERSION

    run ./scripts/validate-plugin.sh
    assert_success
    assert_output_contains "Plugin Version: 1.0.0"
    assert_output_contains "Plugin validation PASSED"
    test_info "Recovery successful after fixing VERSION file"
}

@test "handle missing critical files gracefully" {
    MOCK_REPO="$TEST_DIR/repo"
    setup_mock_repo "$MOCK_REPO"
    cd "$MOCK_REPO"

    # Test missing VERSION file
    mv VERSION VERSION.backup

    run ./scripts/validate-plugin.sh
    assert_failure
    assert_output_contains "Must be run from the repository root"
    test_info "Validation detects missing VERSION file"

    # Restore VERSION file
    mv VERSION.backup VERSION

    run ./scripts/validate-plugin.sh
    assert_success
    assert_output_contains "Plugin Version:"
    test_info "Handles missing VERSION file gracefully"
}

@test "handle permission issues gracefully" {
    MOCK_REPO="$TEST_DIR/repo"
    setup_mock_repo "$MOCK_REPO"
    cd "$MOCK_REPO"

    # Remove execute permissions from validation script
    chmod -x scripts/validate-plugin.sh

    run -126 ./scripts/validate-plugin.sh 2>/dev/null
    [ "$status" -eq 126 ]
    test_info "Handles missing execute permissions"

    # Restore permissions
    chmod +x scripts/validate-plugin.sh

    run ./scripts/validate-plugin.sh
    assert_success
    test_info "Recovers after fixing permissions"
}

@test "handle read-only directory gracefully" {
    MOCK_REPO="$TEST_DIR/repo"
    setup_mock_repo "$MOCK_REPO"
    cd "$MOCK_REPO"

    # Make scripts directory read-only
    chmod 555 scripts/

    # Validation should still work (it only reads)
    run ./scripts/validate-plugin.sh
    assert_success
    assert_output_contains "Plugin Version:"
    test_info "Handles read-only directory gracefully"

    # Restore permissions
    chmod 755 scripts/
}

@test "handle concurrent access scenarios" {
    MOCK_REPO="$TEST_DIR/repo"
    setup_mock_repo "$MOCK_REPO"
    cd "$MOCK_REPO"

    local pids=()

    # Start multiple background processes running validation
    for i in {1..5}; do
        (
            sleep 0.1
            ./scripts/validate-plugin.sh > "$TEST_DIR/result_$i.txt" 2>&1
            echo $? > "$TEST_DIR/status_$i.txt"
        ) &
        pids+=($!)
    done

    # Wait for all processes to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Check that all processes succeeded and got consistent results
    local first_result
    local all_consistent=true

    for i in {1..5}; do
        local status=$(cat "$TEST_DIR/status_$i.txt")
        local result=$(cat "$TEST_DIR/result_$i.txt")

        [ "$status" -eq 0 ] || {
            test_error "Process $i failed with status $status"
            all_consistent=false
        }

        if [ -z "$first_result" ]; then
            first_result="$result"
        elif [ "$result" != "$first_result" ]; then
            test_error "Inconsistent results: '$result' != '$first_result'"
            all_consistent=false
        fi
    done

    [ "$all_consistent" = true ]
    test_info "Concurrent access handled consistently"
}
