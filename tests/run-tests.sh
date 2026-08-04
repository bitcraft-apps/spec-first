#!/bin/bash

# Test Runner for Spec First
# Orchestrates execution of BATS test suites with proper setup and reporting

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATS_EXECUTABLE="$SCRIPT_DIR/bats-core/bin/bats"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
VERBOSE=0
PARALLEL=0
FILTER=""
TAP_OUTPUT=0
TEST_TYPE=""  # unit, integration, e2e, or empty for all

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -p|--parallel)
                PARALLEL=1
                shift
                ;;
            -f|--filter)
                FILTER="$2"
                shift 2
                ;;
            -t|--tap)
                TAP_OUTPUT=1
                shift
                ;;
            --unit)
                TEST_TYPE="unit"
                shift
                ;;
            --integration)
                TEST_TYPE="integration"
                shift
                ;;
            --e2e)
                TEST_TYPE="e2e"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "Test Runner for Spec First"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Enable verbose output"
    echo "  -p, --parallel    Run tests in parallel"
    echo "  -f, --filter STR  Filter tests by name pattern"
    echo "  -t, --tap         Output in TAP format"
    echo "  --unit            Run only unit tests (collocated)"
    echo "  --integration     Run only integration tests"
    echo "  --e2e             Run only E2E tests"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Run all tests"
    echo "  $0 -v                       # Run with verbose output"
    echo "  $0 -f 'version'             # Run only version-related tests"
    echo "  $0 --unit                   # Run only unit tests"
    echo "  $0 --integration            # Run only integration tests"
    echo "  $0 --e2e                    # Run only E2E tests"
    echo "  $0 -p                       # Run tests in parallel"
    echo "  $0 -t                       # Output in TAP format for CI"
}

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking test prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "$PROJECT_ROOT/AGENTS.md" ]; then
        echo -e "${RED}❌ Not in Spec First repository${NC}" >&2
        exit 1
    fi
    
    # Check if bats-core submodule is initialized
    if [ ! -f "$BATS_EXECUTABLE" ]; then
        echo "📦 Initializing bats-core submodule..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive
        
        if [ ! -f "$BATS_EXECUTABLE" ]; then
            echo -e "${RED}❌ Failed to initialize bats-core submodule${NC}" >&2
            echo "Please run: git submodule update --init --recursive" >&2
            exit 1
        fi
    fi

    # Check if test files exist - organized directory approach
    local test_files_found=0
    
    # Check for unit tests (collocated)
    for unit_test in "$PROJECT_ROOT/scripts"/*.test.bats; do
        if [ -f "$unit_test" ]; then
            test_files_found=1
            break
        fi
    done
    
    # Check for integration tests
    if [ $test_files_found -eq 0 ]; then
        for integration_test in "$SCRIPT_DIR/integration"/*.bats; do
            if [ -f "$integration_test" ]; then
                test_files_found=1
                break
            fi
        done
    fi
    
    # Check for E2E tests
    if [ $test_files_found -eq 0 ]; then
        for e2e_test in "$SCRIPT_DIR/e2e"/*.bats; do
            if [ -f "$e2e_test" ]; then
                test_files_found=1
                break
            fi
        done
    fi
    
    # Check for any remaining tests in root
    if [ $test_files_found -eq 0 ]; then
        for root_test in "$SCRIPT_DIR"/*.bats; do
            if [ -f "$root_test" ]; then
                test_files_found=1
                break
            fi
        done
    fi
    
    if [ $test_files_found -eq 0 ]; then
        echo -e "${RED}❌ No test files found${NC}" >&2
        echo "Expected test files in:" >&2
        echo "  - $PROJECT_ROOT/scripts/*.test.bats (unit tests)" >&2
        echo "  - $SCRIPT_DIR/integration/*.bats (integration tests)" >&2
        echo "  - $SCRIPT_DIR/e2e/*.bats (E2E tests)" >&2
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Initialize git submodules if needed
init_submodules() {
    if [ ! -d "$SCRIPT_DIR/bats-core/.git" ]; then
        echo "🔄 Initializing git submodules..."
        cd "$PROJECT_ROOT"
        git submodule update --init --recursive
    fi
}

# Build BATS command
build_bats_command() {
    local cmd="$BATS_EXECUTABLE"
    
    # Add verbose flag if requested
    if [ $VERBOSE -eq 1 ]; then
        cmd="$cmd --verbose-run"
    fi
    
    # Add TAP output if requested
    if [ $TAP_OUTPUT -eq 1 ]; then
        cmd="$cmd --tap"
    fi
    
    # Add filter if specified
    if [ -n "$FILTER" ]; then
        cmd="$cmd --filter '$FILTER'"
    fi
    
    echo "$cmd"
}

# Run test suite
run_tests() {
    local suite_name="Spec First Test Suite"
    case "$TEST_TYPE" in
        "unit")
            suite_name="$suite_name (Unit Tests)"
            ;;
        "integration")
            suite_name="$suite_name (Integration Tests)"
            ;;
        "e2e")
            suite_name="$suite_name (E2E Tests)"
            ;;
    esac
    
    echo "🧪 Running $suite_name"
    echo "=================================================="
    echo ""
    
    # Set up environment
    export PROJECT_ROOT
    cd "$SCRIPT_DIR"
    
    # Build test file list - organized directory approach
    local test_files=()
    
    # Filter by test type if specified
    case "$TEST_TYPE" in
        "unit")
            # Add only unit tests (collocated with scripts)
            for unit_test in "$PROJECT_ROOT/scripts"/*.test.bats; do
                if [ -f "$unit_test" ]; then
                    test_files+=("$unit_test")
                fi
            done
            ;;
        "integration")
            # Add only integration tests
            for integration_test in "$SCRIPT_DIR/integration"/*.bats; do
                if [ -f "$integration_test" ]; then
                    test_files+=("$integration_test")
                fi
            done
            ;;
        "e2e")
            # Add only E2E tests
            for e2e_test in "$SCRIPT_DIR/e2e"/*.bats; do
                if [ -f "$e2e_test" ]; then
                    test_files+=("$e2e_test")
                fi
            done
            ;;
        *)
            # Add all tests (default behavior)
            # Unit tests (collocated with scripts)
            for unit_test in "$PROJECT_ROOT/scripts"/*.test.bats; do
                if [ -f "$unit_test" ]; then
                    test_files+=("$unit_test")
                fi
            done
            
            # Integration tests (organized in tests/integration/)
            for integration_test in "$SCRIPT_DIR/integration"/*.bats; do
                if [ -f "$integration_test" ]; then
                    test_files+=("$integration_test")
                fi
            done
            
            # E2E tests (organized in tests/e2e/)
            for e2e_test in "$SCRIPT_DIR/e2e"/*.bats; do
                if [ -f "$e2e_test" ]; then
                    test_files+=("$e2e_test")
                fi
            done
            
            # Any remaining .bats files in tests root (for backward compatibility)
            for root_test in "$SCRIPT_DIR"/*.bats; do
                if [ -f "$root_test" ]; then
                    test_files+=("$root_test")
                fi
            done
            ;;
    esac
    
    # Filter test files if pattern specified
    if [ -n "$FILTER" ]; then
        local filtered_files=()
        for file in "${test_files[@]}"; do
            if [[ "$file" == *"$FILTER"* ]]; then
                filtered_files+=("$file")
            fi
        done
        test_files=("${filtered_files[@]}")
    fi
    
    # Check if we have tests to run
    if [ ${#test_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No test files match the filter: $FILTER${NC}"
        exit 0
    fi
    
    # Build and execute BATS command
    local cmd
    cmd=$(build_bats_command)
    
    if [ $PARALLEL -eq 1 ] && [ ${#test_files[@]} -gt 1 ]; then
        echo "🚀 Running tests in parallel..."
        cmd="$cmd --jobs 4"
    fi
    
    # Add test files to command
    for file in "${test_files[@]}"; do
        cmd="$cmd $file"
    done
    
    echo "💻 Executing: $cmd"
    echo ""
    
    # Execute tests
    if eval "$cmd"; then
        echo ""
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        local exit_code=$?
        echo ""
        echo -e "${RED}❌ Some tests failed!${NC}"
        return $exit_code
    fi
}


# Generate test report
generate_report() {
    echo ""
    echo "📊 Test Execution Summary"
    echo "========================="
    echo "Test runner: BATS (Bash Automated Testing System)"
    echo "Framework: Spec First"
    echo "Date: $(date)"
    echo "Project: $PROJECT_ROOT"
    echo ""
}

# Main execution
main() {
    parse_args "$@"
    
    # Show header
    echo -e "${BLUE}Spec First - Test Suite${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Run prerequisite checks
    check_prerequisites
    init_submodules
    
    # Execute tests
    local test_result=0
    if ! run_tests; then
        test_result=1
    fi
    
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    exit $test_result
}

# Execute main function with all arguments
main "$@"