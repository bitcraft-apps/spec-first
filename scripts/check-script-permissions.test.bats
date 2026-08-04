#!/usr/bin/env bats

# Unit Tests for scripts/check-script-permissions.sh
# All tests invoke as subprocess against temp fixture git repositories

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT
PERMS_SCRIPT="$PROJECT_ROOT/scripts/check-script-permissions.sh"

setup() {
    FIXTURE_DIR="$(mktemp -d)"

    # Build a fixture repo where every tracked script is committed executable
    mkdir -p "$FIXTURE_DIR/scripts"
    cp "$PERMS_SCRIPT" "$FIXTURE_DIR/scripts/check-script-permissions.sh"
    chmod +x "$FIXTURE_DIR/scripts/check-script-permissions.sh"

    printf '#!/bin/bash\necho ok\n' > "$FIXTURE_DIR/scripts/good.sh"
    chmod +x "$FIXTURE_DIR/scripts/good.sh"

    cd "$FIXTURE_DIR"
    git init -q .
    git add -A
}

teardown() {
    rm -rf "$FIXTURE_DIR"
}

# --- Happy path ---

@test "check-script-permissions passes when every tracked script is 100755" {
    cd "$FIXTURE_DIR"
    run ./scripts/check-script-permissions.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 2 shell script(s) are committed executable"* ]]
}

@test "check-script-permissions accepts symlinked scripts" {
    cd "$FIXTURE_DIR"
    ln -s ../scripts/good.sh "$FIXTURE_DIR/scripts/linked.sh"
    git add -A
    run ./scripts/check-script-permissions.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 3 shell script(s)"* ]]
}

@test "check-script-permissions finds scripts in nested directories" {
    cd "$FIXTURE_DIR"
    mkdir -p hooks
    printf '#!/bin/bash\n' > hooks/nested.sh
    chmod +x hooks/nested.sh
    git add -A
    run ./scripts/check-script-permissions.sh
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASS: 3 shell script(s)"* ]]
}

# --- Missing executable bit ---

@test "check-script-permissions fails and names a non-executable script" {
    cd "$FIXTURE_DIR"
    git update-index --chmod=-x scripts/good.sh
    run ./scripts/check-script-permissions.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"scripts/good.sh is mode 100644, expected 100755"* ]]
    [[ "$output" == *"git update-index --chmod=+x scripts/good.sh"* ]]
}

@test "check-script-permissions reports every offender in one run" {
    cd "$FIXTURE_DIR"
    printf '#!/bin/bash\n' > scripts/other.sh
    git add -A
    git update-index --chmod=-x scripts/good.sh
    git update-index --chmod=-x scripts/other.sh
    run ./scripts/check-script-permissions.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"scripts/good.sh is mode 100644"* ]]
    [[ "$output" == *"scripts/other.sh is mode 100644"* ]]
}

@test "check-script-permissions ignores the working tree mode" {
    cd "$FIXTURE_DIR"
    # Index says executable, filesystem does not — a fresh clone would still be fine
    chmod -x scripts/good.sh
    run bash ./scripts/check-script-permissions.sh
    [ "$status" -eq 0 ]
}

# --- Wrong working directory ---

@test "check-script-permissions fails outside a git repository" {
    NON_REPO="$(mktemp -d)"
    cp "$PERMS_SCRIPT" "$NON_REPO/check-script-permissions.sh"
    cd "$NON_REPO"
    run env -u GIT_DIR -u GIT_WORK_TREE bash ./check-script-permissions.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"not inside a git repository"* ]]
    rm -rf "$NON_REPO"
}

@test "check-script-permissions fails when no tracked scripts exist" {
    EMPTY_REPO="$(mktemp -d)"
    cp "$PERMS_SCRIPT" "$EMPTY_REPO/check-script-permissions.sh"
    cd "$EMPTY_REPO"
    git init -q .
    run bash ./check-script-permissions.sh
    [ "$status" -eq 1 ]
    [[ "$output" == *"no tracked *.sh files found"* ]]
    rm -rf "$EMPTY_REPO"
}
