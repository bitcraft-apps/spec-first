#!/bin/bash

# Spec First - Version Change Validation
# Extracts and consolidates version validation logic from GitHub workflows
# Handles version comparison, changelog validation, and semantic versioning checks

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BASE_BRANCH="origin/main"
CHECK_CHANGELOG=1
VALIDATE_SEMANTICS=1
OUTPUT_FORMAT="human"  # human, github-actions

show_help() {
    echo "Version Change Validation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --base BRANCH     Base branch for comparison (default: origin/main)"
    echo "  --skip-changelog      Skip changelog validation"
    echo "  --skip-semantics      Skip semantic version validation"
    echo "  --github-actions      Output in GitHub Actions format"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Outputs:"
    echo "  - Detects version changes between branches"
    echo "  - Validates changelog entries for version bumps"
    echo "  - Checks semantic version progression"
    echo "  - Returns structured output for CI/CD workflows"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--base)
                BASE_BRANCH="$2"
                shift 2
                ;;
            --skip-changelog)
                CHECK_CHANGELOG=0
                shift
                ;;
            --skip-semantics)
                VALIDATE_SEMANTICS=0
                shift
                ;;
            --github-actions)
                OUTPUT_FORMAT="github-actions"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help >&2
                exit 1
                ;;
        esac
    done
}

# Output functions for different formats
output_info() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::notice::$1"
    else
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

output_success() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::notice::$1"
    else
        echo -e "${GREEN}✅ $1${NC}"
    fi
}

output_warning() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::warning::$1"
    else
        echo -e "${YELLOW}⚠️  $1${NC}"
    fi
}

output_error() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ]; then
        echo "::error::$1"
    else
        echo -e "${RED}❌ $1${NC}" >&2
    fi
}

set_github_output() {
    if [ "$OUTPUT_FORMAT" = "github-actions" ] && [ -n "$GITHUB_OUTPUT" ]; then
        echo "$1=$2" >> "$GITHUB_OUTPUT"
    fi
}

# Get version from framework VERSION file
get_version() {
    local branch="$1"
    local version
    
    if [ "$branch" = "HEAD" ]; then
        # Current working version
        version=$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "0.0.0")
    else
        # Version from git branch/commit
        version=$(git show "$branch:VERSION" 2>/dev/null || echo "0.0.0")
    fi
    
    echo "$version"
}

# Detect version changes
detect_version_changes() {
    output_info "Checking for version changes..."
    
    # Get versions
    local base_version current_version
    base_version=$(get_version "$BASE_BRANCH")
    current_version=$(get_version "HEAD")
    
    echo "Base version ($BASE_BRANCH): $base_version"
    echo "Current version: $current_version"
    
    # Set outputs for GitHub Actions
    set_github_output "base_version" "$base_version"
    set_github_output "current_version" "$current_version"
    
    # Check if version changed
    if [ "$base_version" != "$current_version" ]; then
        output_success "Version bump detected: $base_version → $current_version"
        set_github_output "version_bumped" "true"
        set_github_output "version_change" "$base_version → $current_version"
        return 0
    else
        output_info "No version change detected"
        set_github_output "version_bumped" "false"
        return 1
    fi
}

# Validate changelog requirements
validate_changelog() {
    local current_version="$1"
    
    output_info "Validating changelog for version $current_version..."
    
    # Check if CHANGELOG.md exists
    if [ ! -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
        output_error "CHANGELOG.md is required when version is bumped"
        echo "To fix: Create CHANGELOG.md following Keep a Changelog format"
        return 1
    fi
    
    output_success "CHANGELOG.md exists"
    
    # Validate changelog format structure
    output_info "Validating changelog format..."
    
    local format_errors=()
    
    # Check for title
    if ! grep -q "# Changelog" "$PROJECT_ROOT/CHANGELOG.md"; then
        format_errors+=("missing-title")
    fi
    
    # Check for version headers
    if ! grep -q "## \[" "$PROJECT_ROOT/CHANGELOG.md"; then
        format_errors+=("missing-version-headers")
    fi
    
    # Check for the new version in changelog
    if ! grep -q "## \[${current_version}\]" "$PROJECT_ROOT/CHANGELOG.md"; then
        format_errors+=("missing-current-version")
    fi
    
    if [ ${#format_errors[@]} -ne 0 ]; then
        output_error "Changelog format validation failed"
        echo "Issues: ${format_errors[*]}"
        echo "Required: Version $current_version must be documented in CHANGELOG.md"
        return 1
    fi
    
    output_success "Changelog format validation passed"
    
    # Check content quality
    if ! grep -A 20 "## \[${current_version}\]" "$PROJECT_ROOT/CHANGELOG.md" | grep -q "###"; then
        output_warning "No change categories found for version $current_version"
        echo "Consider adding: ### Added, ### Changed, ### Fixed, etc."
    else
        output_success "Changelog content quality validation passed"
    fi
    
    return 0
}

# Validate semantic versioning
validate_semantic_version() {
    local base_version="$1"
    local current_version="$2"
    
    output_info "Validating semantic versioning..."
    
    # Use project's version utilities for validation
    local version_script="$SCRIPT_DIR/version.sh"
    
    if [ ! -f "$version_script" ]; then
        output_error "Version utilities script not found: $version_script"
        return 1
    fi

    # Validate both versions are semantic
    if ! "$version_script" validate "$base_version" 2>/dev/null; then
        output_error "Invalid base version format: $base_version"
        return 1
    fi
    
    if ! "$version_script" validate "$current_version" 2>/dev/null; then
        output_error "Invalid current version format: $current_version"
        return 1
    fi
    
    # Check version progression
    local comparison
    comparison=$("$version_script" compare "$base_version" "$current_version" 2>/dev/null) || {
        output_error "Failed to compare versions"
        return 1
    }
    
    if [[ "$comparison" != *"<"* ]]; then
        output_error "Version must increment from $base_version to $current_version"
        echo "Current relationship: $comparison"
        return 1
    fi
    
    output_success "Semantic version validation passed"
    echo "Version progression: $base_version → $current_version"
    
    return 0
}

# Main execution
main() {
    parse_args "$@"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Show header
    output_info "Spec First - Version Change Validation"
    echo "================================================================"
    echo ""
    
    # Detect version changes
    local version_changed=0
    local base_version current_version
    
    if detect_version_changes; then
        version_changed=1
        base_version=$(get_version "$BASE_BRANCH")
        current_version=$(get_version "HEAD")
    else
        # No version change - exit successfully
        echo ""
        output_success "No version validation required"
        exit 0
    fi
    
    echo ""
    
    # Validate changelog if version changed
    if [ $version_changed -eq 1 ] && [ $CHECK_CHANGELOG -eq 1 ]; then
        if ! validate_changelog "$current_version"; then
            exit 1
        fi
        echo ""
    fi
    
    # Validate semantic versioning if version changed
    if [ $version_changed -eq 1 ] && [ $VALIDATE_SEMANTICS -eq 1 ]; then
        if ! validate_semantic_version "$base_version" "$current_version"; then
            exit 1
        fi
        echo ""
    fi
    
    # Success summary
    output_success "All version validation checks passed"
    
    if [ $version_changed -eq 1 ]; then
        echo "Version change: $base_version → $current_version"
        
        # Set final output for workflows
        set_github_output "validation_status" "passed"
        set_github_output "validation_summary" "Version validation completed successfully for $base_version → $current_version"
    fi
}

# Execute main function with all arguments
main "$@"