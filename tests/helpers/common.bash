#!/usr/bin/env bash

# Common Test Utilities
# Provides basic setup, project detection, and color codes

# Determine project root directory
if [ -z "$PROJECT_ROOT" ]; then
    # Handle different execution contexts (direct, via test runner, from subdirs)
    if [ -n "${BASH_SOURCE[0]}" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    else
        # Fallback: search upward for AGENTS.md
        CURRENT_DIR="$(pwd)"
        while [ "$CURRENT_DIR" != "/" ]; do
            if [ -f "$CURRENT_DIR/AGENTS.md" ]; then
                PROJECT_ROOT="$CURRENT_DIR"
                break
            fi
            CURRENT_DIR="$(dirname "$CURRENT_DIR")"
        done
    fi
    export PROJECT_ROOT
fi

# Color codes for test output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Test output functions
test_info() {
    echo -e "${BLUE}INFO:${NC} $*" >&2
}

test_success() {
    echo -e "${GREEN}SUCCESS:${NC} $*" >&2
}

test_warning() {
    echo -e "${YELLOW}WARNING:${NC} $*" >&2
}

test_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

# Project validation
validate_project_root() {
    if [ -z "$PROJECT_ROOT" ] || [ ! -f "$PROJECT_ROOT/AGENTS.md" ]; then
        test_error "Cannot find Spec First project root"
        return 1
    fi
}