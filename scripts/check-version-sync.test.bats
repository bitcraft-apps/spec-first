#!/usr/bin/env bats

# Unit Tests for scripts/check-version-sync.sh
# All tests invoke as subprocess against temp fixture directories

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
SYNC_SCRIPT="$PROJECT_ROOT/scripts/check-version-sync.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"

    # Build a fixture where every version reference agrees
    mkdir -p "$FIXTURE_DIR/scripts" "$FIXTURE_DIR/.claude-plugin"
    cp "$SYNC_SCRIPT" "$FIXTURE_DIR/scripts/check-version-sync.sh"
    chmod +x "$FIXTURE_DIR/scripts/check-version-sync.sh"

    echo "1.0.0" > "$FIXTURE_DIR/VERSION"
    printf '{"name":"sf","version":"1.0.0"}\n' > "$FIXTURE_DIR/.claude-plugin/plugin.json"
    printf '{"plugins":[{"name":"sf","version":"1.0.0"}]}\n' > "$FIXTURE_DIR/.claude-plugin/marketplace.json"
    printf '{".":"1.0.0"}\n' > "$FIXTURE_DIR/.release-please-manifest.json"
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

# --- Happy path ---

@test "check-version-sync passes when all four references match" {
    cd "$FIXTURE_DIR"
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: all version references match 1.0.0"* ]]
}

@test "check-version-sync tolerates trailing whitespace in VERSION" {
    cd "$FIXTURE_DIR"
    printf "  1.0.0  \n" > VERSION
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 0 ]
}

# --- Mismatches ---

@test "check-version-sync fails when plugin.json drifts" {
    cd "$FIXTURE_DIR"
    printf '{"name":"sf","version":"9.9.9"}\n' > .claude-plugin/plugin.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"plugin.json version is 9.9.9, expected 1.0.0"* ]]
}

@test "check-version-sync fails when marketplace.json drifts" {
    cd "$FIXTURE_DIR"
    printf '{"plugins":[{"name":"sf","version":"9.9.9"}]}\n' > .claude-plugin/marketplace.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"marketplace.json version is 9.9.9"* ]]
}

@test "check-version-sync fails when release-please manifest drifts" {
    cd "$FIXTURE_DIR"
    printf '{".":"9.9.9"}\n' > .release-please-manifest.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *".release-please-manifest.json version is 9.9.9"* ]]
}

@test "check-version-sync reports every mismatch in one run" {
    cd "$FIXTURE_DIR"
    printf '{"name":"sf","version":"9.9.9"}\n' > .claude-plugin/plugin.json
    printf '{".":"8.8.8"}\n' > .release-please-manifest.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"plugin.json version is 9.9.9"* ]]
    [[ "$output" == *".release-please-manifest.json version is 8.8.8"* ]]
}

# --- Missing or malformed sources are hard failures, not skips ---

@test "check-version-sync fails when plugin.json is missing" {
    cd "$FIXTURE_DIR"
    rm .claude-plugin/plugin.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"plugin.json not found"* ]]
}

@test "check-version-sync fails when a version key is absent" {
    cd "$FIXTURE_DIR"
    printf '{"name":"sf"}\n' > .claude-plugin/plugin.json
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"has no version at"* ]]
}

@test "check-version-sync fails on malformed VERSION" {
    cd "$FIXTURE_DIR"
    echo "1.3" > VERSION
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"VERSION is not a valid semver"* ]]
}

@test "check-version-sync fails when VERSION is missing" {
    cd "$FIXTURE_DIR"
    rm VERSION
    run ./scripts/check-version-sync.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"VERSION file not found"* ]]
}
