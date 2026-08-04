#!/bin/bash

# Verifies the plugin version is identical in every file that carries it.
# release-please writes all four in one PR, so any divergence is drift.
# Must be run from the repository root.

set -euo pipefail

SIMPLE_VERSION_REGEX='^[0-9]+\.[0-9]+\.[0-9]+$'

if ! command -v jq >/dev/null 2>&1; then
    echo "FAIL: jq is required for version sync validation"
    exit 1
fi

if [ ! -f "./VERSION" ]; then
    echo "FAIL: VERSION file not found (run from the repository root)"
    exit 1
fi

VERSION=$(tr -d '\n\r' < "./VERSION" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if ! echo "$VERSION" | grep -Eq "$SIMPLE_VERSION_REGEX"; then
    echo "FAIL: VERSION is not a valid semver: '$VERSION'"
    exit 1
fi

failed=0

check_version() {
    local file="$1" path="$2" found

    if [ ! -f "$file" ]; then
        echo "FAIL: $file not found"
        failed=1
        return
    fi

    if ! found=$(jq -re "$path" "$file" 2>/dev/null); then
        echo "FAIL: $file has no version at $path"
        failed=1
        return
    fi

    if [ "$found" != "$VERSION" ]; then
        echo "FAIL: $file version is $found, expected $VERSION (from VERSION)"
        failed=1
    fi
}

check_version ".claude-plugin/plugin.json" '.version'
check_version ".claude-plugin/marketplace.json" '.plugins[0].version'
check_version ".release-please-manifest.json" '.["."]'

if [ "$failed" -eq 1 ]; then
    exit 1
fi

echo "PASS: all version references match $VERSION"
