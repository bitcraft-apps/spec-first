#!/usr/bin/env bats

# Dynamic Context Injection Integration Tests
# Tests the shell commands embedded in skill Project Context sections

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

setup() {
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
}

teardown() {
    [ -d "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# --- Git commands in a real repo ---

@test "git branch --show-current produces output in a git repo" {
    cd "$TEST_DIR"
    git init -b test-branch . >/dev/null 2>&1
    run git branch --show-current 2>/dev/null
    [ "$status" -eq 0 ]
    [ "$output" = "test-branch" ]
}

@test "git log --oneline -5 produces output in a repo with commits" {
    cd "$TEST_DIR"
    git init . >/dev/null 2>&1
    git -c user.name="test" -c user.email="test@test" commit --allow-empty -m "first" >/dev/null 2>&1
    git -c user.name="test" -c user.email="test@test" commit --allow-empty -m "second" >/dev/null 2>&1
    run git log --oneline -5 2>/dev/null
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "git status --short | head -20 caps output at 20 lines" {
    cd "$TEST_DIR"
    git init . >/dev/null 2>&1
    for i in $(seq 1 30); do touch "file-$i.txt"; done
    run bash -c 'git status --short 2>/dev/null | head -20'
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 20 ]
}

# --- Git commands in a non-git directory ---

@test "git branch produces no stderr in non-git directory" {
    cd "$TEST_DIR"
    run bash -c 'git branch --show-current 2>/dev/null'
    [ -z "$output" ]
}

@test "git log produces no stderr in non-git directory" {
    cd "$TEST_DIR"
    run bash -c 'git log --oneline -5 2>/dev/null'
    [ -z "$output" ]
}

@test "git status produces no stderr in non-git directory" {
    cd "$TEST_DIR"
    run bash -c 'git status --short 2>/dev/null | head -20'
    [ -z "$output" ]
}

# --- File existence fallbacks (implement skill) ---

@test "spec exists check returns yes when file present" {
    mkdir -p "$TEST_DIR/.sf"
    touch "$TEST_DIR/.sf/spec.md"
    cd "$TEST_DIR"
    run bash -c 'test -f .sf/spec.md && echo "yes" || echo "no"'
    [ "$output" = "yes" ]
}

@test "spec exists check returns no when file missing" {
    cd "$TEST_DIR"
    run bash -c 'test -f .sf/spec.md && echo "yes" || echo "no"'
    [ "$output" = "no" ]
}

# --- File existence fallbacks (document skill) ---

@test "implementation summary shows content when file exists" {
    mkdir -p "$TEST_DIR/.sf"
    echo "summary line 1" > "$TEST_DIR/.sf/implementation-summary.md"
    cd "$TEST_DIR"
    run bash -c 'test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"'
    [ "$output" = "summary line 1" ]
}

@test "implementation summary returns none when file missing" {
    cd "$TEST_DIR"
    run bash -c 'test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"'
    [ "$output" = "none" ]
}

@test "implementation summary caps at 20 lines" {
    mkdir -p "$TEST_DIR/.sf"
    for i in $(seq 1 30); do echo "line $i"; done > "$TEST_DIR/.sf/implementation-summary.md"
    cd "$TEST_DIR"
    run bash -c 'test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"'
    [ "${#lines[@]}" -eq 20 ]
}

# --- Skills keep the injection under the Claude Code section ---

@test "spec skill has Project Context with dynamic injection" {
    grep -q '## On Claude Code' "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '!`git branch --show-current 2>/dev/null`' "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '!`git log --oneline -5 2>/dev/null`' "$PROJECT_ROOT/skills/spec/SKILL.md"
    grep -q '!`git status --short 2>/dev/null | head -20`' "$PROJECT_ROOT/skills/spec/SKILL.md"
}

@test "implement skill has Project Context with dynamic injection" {
    grep -q '## On Claude Code' "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q '!`git branch --show-current 2>/dev/null`' "$PROJECT_ROOT/skills/implement/SKILL.md"
    grep -q '!`test -f .sf/spec.md && echo "yes" || echo "no"`' "$PROJECT_ROOT/skills/implement/SKILL.md"
}

@test "document skill has Project Context with dynamic injection" {
    grep -q '## On Claude Code' "$PROJECT_ROOT/skills/document/SKILL.md"
    grep -q '!`test -f .sf/implementation-summary.md' "$PROJECT_ROOT/skills/document/SKILL.md"
}
