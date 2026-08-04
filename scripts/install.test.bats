#!/usr/bin/env bats

# Unit tests for scripts/install.sh

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
export PROJECT_ROOT

load "$PROJECT_ROOT/tests/helpers/assertions.bash"

INSTALL_SH="$PROJECT_ROOT/scripts/install.sh"
export INSTALL_SH

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

@test "rejects an unknown option" {
    run bash "$INSTALL_SH" --bogus
    [ "$status" -eq 1 ]
    assert_output_contains "Usage:"
}

@test "installs every skill into --dir" {
    run bash "$INSTALL_SH" --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    for skill in spec implement document; do
        [ -f "$TEST_DIR/skills/$skill/SKILL.md" ]
    done
}

@test "defaults to ~/.agents/skills" {
    HOME="$TEST_DIR" run bash "$INSTALL_SH"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/.agents/skills/spec/SKILL.md" ]
}

@test "symlink mode links to the checkout and the script runs through the link" {
    run bash "$INSTALL_SH" --symlink --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    [ -L "$TEST_DIR/skills/spec" ]

    run bash "$TEST_DIR/skills/spec/scripts/spec-dir.sh" first "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.sf/research" ]
}

@test "copy mode leaves no symlinks and the copied script runs" {
    run bash "$INSTALL_SH" --copy --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    [ ! -L "$TEST_DIR/skills/spec" ]

    run find "$TEST_DIR/skills" -type l
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    run bash "$TEST_DIR/skills/spec/scripts/spec-dir.sh" first "$TEST_DIR/.sf"
    [ "$status" -eq 0 ]
    [ -d "$TEST_DIR/.sf/research" ]
}

@test "copy mode records the version" {
    run bash "$INSTALL_SH" --copy --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    [ -s "$TEST_DIR/skills/spec/.sf-install" ]
}

@test "refuses a directory sf did not install" {
    mkdir -p "$TEST_DIR/skills/spec"
    echo "mine" > "$TEST_DIR/skills/spec/SKILL.md"

    run bash "$INSTALL_SH" --dir "$TEST_DIR/skills"
    [ "$status" -eq 1 ]
    assert_output_contains "--force"
    [ "$(cat "$TEST_DIR/skills/spec/SKILL.md")" = "mine" ]
}

@test "--force replaces a foreign directory" {
    mkdir -p "$TEST_DIR/skills/spec"
    echo "mine" > "$TEST_DIR/skills/spec/SKILL.md"

    run bash "$INSTALL_SH" --force --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_DIR/skills/spec/SKILL.md")" != "mine" ]
}

@test "re-installs over an earlier copy install" {
    run bash "$INSTALL_SH" --copy --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]

    run bash "$INSTALL_SH" --copy --dir "$TEST_DIR/skills"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/skills/spec/SKILL.md" ]
}
