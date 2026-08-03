# Testing Documentation

## Overview

Spec First uses **BATS (Bash Automated Testing System)** for comprehensive testing. This modern testing approach provides better structure, reporting, and CI/CD integration compared to the previous shell-based tests.

## Architecture

### Organized Test Structure

The framework uses a **well-organized directory structure** that separates different types of tests:

```
tests/
├── integration/                 # Integration tests
│   ├── directory-isolation.bats # Spec directory isolation
│   ├── framework.bats           # Framework structure tests
│   ├── hooks.bats               # Hook execution and output
│   ├── plugin-validation.bats   # Plugin artifact validation
│   └── workflow.bats            # Workflow integration
│
├── e2e/                        # End-to-end tests
│   └── error-recovery.bats      # Error handling tests
│
├── helpers/                    # Granular test helpers
│   ├── common.bash             # Common utilities
│   ├── assertions.bash         # Custom assertions
│   └── environment.bash        # Environment setup
│
├── bats-core/                  # Git submodule - BATS framework
├── test-helper.bash           # Master helper (loads all modules)
├── run-tests.sh               # Intelligent test runner
└── README.md                  # This documentation
```

### Test Organization Philosophy

**Integration Tests:**
- Test interactions between components and plugin artifacts
- Located in `tests/integration/`
- Run with: `make test-integration` or `./run-tests.sh --integration`

**End-to-End Tests (Comprehensive):**
- Test complete workflows from start to finish
- Located in `tests/e2e/`
- Run with: `make test-e2e` or `./run-tests.sh --e2e`
- Include error recovery and CI simulation

### Why BATS over Shell Scripts?

**Advantages of BATS:**
- **Structured Testing**: Clear test organization with `@test` annotations
- **Better Reporting**: Detailed pass/fail reporting with line numbers
- **CI Integration**: TAP (Test Anything Protocol) output for GitHub Actions
- **Parallel Execution**: Run tests concurrently for faster feedback
- **Error Handling**: Robust error reporting and debugging capabilities
- **Filtering**: Run specific test subsets during development

**Git Submodule Approach:**
- **Version Pinning**: Exact control over BATS version across environments
- **Self-Contained**: No external dependencies or package manager requirements
- **Offline Support**: Works without internet after initial clone
- **CI Consistency**: Same BATS version in GitHub Actions and local development

## Quick Start

### Setup
```bash
# Initialize the testing framework
make setup

# Or manually:
git submodule update --init --recursive
chmod +x tests/run-tests.sh
```

### Running Tests
```bash
# Run all tests
make test

# Run with detailed output  
make test-verbose

# Run specific test suite
make test-unit              # Unit tests (collocated with code)
make test-integration       # Integration tests (organized)
make test-e2e               # End-to-end tests (comprehensive)
make test-version           # Version utility tests only

# Run with filtering
make test FILTER=version    # Tests matching "version"
make test FILTER=validate   # Tests matching "validate"

# Parallel execution (faster)
make test-parallel
```

### Direct BATS Usage
```bash
cd tests

# Run all tests (organized discovery)
./run-tests.sh

# Run specific test types
./run-tests.sh --unit               # Unit tests only
./run-tests.sh --integration        # Integration tests only
./run-tests.sh --e2e                # E2E tests only

# Run with options
./run-tests.sh --verbose            # Detailed output
./run-tests.sh --parallel           # Parallel execution
./run-tests.sh --filter version     # Filter by pattern
./run-tests.sh --tap                # TAP output for CI

# Run tests directly with BATS
bats integration/framework.bats     # Single integration test
bats ../scripts/version.test.bats   # Unit test execution
bats e2e/                           # All E2E tests
```

## Test Suites

### Integration Tests (`tests/integration/`)

**Purpose**: Test component interactions, plugin artifacts, and workflows
**Files**:
- `directory-isolation.bats`: Spec directory isolation
- `framework.bats`: Framework structure and validation
- `hooks.bats`: Hook execution and output (requires BATS 1.5.0 or later)
- `plugin-validation.bats`: Plugin artifact validation (requires `python3`)
- `workflow.bats`: Workflow integration

### End-to-End Tests (`tests/e2e/`)

**Purpose**: Test error handling and edge cases
**Files**:
- `error-recovery.bats`: Error handling and recovery

## Helper System

The framework provides a modular helper system in `tests/helpers/`:

### Core Helper Modules

**`common.bash`**: Basic utilities and setup
- Project root detection
- Color codes and output functions
- Project validation

**`assertions.bash`**: Domain-specific assertions
- `assert_version_format()`: Validate semantic version strings
- `assert_executable()`: Check file permissions
- `assert_directory_structure()`: Verify directory trees
- `assert_files_exist()`: Check required files
- `assert_output_contains()`: Verify command output

**`environment.bash`**: Test lifecycle management
- `setup_integration_test()`: Standard integration setup
- `setup_e2e_test()`: Comprehensive E2E setup  
- `teardown_*()`: Cleanup functions
- `run_with_timeout()`: Command timeout wrapper

### Usage

**In test files:**
```bash
# Load master helper (includes all modules)
load '../test-helper'

# Use helper functions
setup() {
    setup_integration_test
}

teardown() {
    teardown_integration_test
}

@test "example test" {
    create_mock_home "$TEST_DIR/home"
    assert_files_exist "$HOME/.claude" "VERSION"
}
```

## Benefits of Organized Structure

### 🎯 **Clear Separation of Concerns**
- Unit tests focus on individual functions
- Integration tests focus on component interactions  
- E2E tests focus on complete user workflows

### 📁 **Easy Navigation**
- Tests organized by purpose in logical directories
- Collocated unit tests for discoverability
- Granular helpers for reusability

### ⚡ **Flexible Execution**
- Run specific test types: `--unit`, `--integration`, `--e2e`
- Filter by patterns: `--filter version`
- Parallel execution: `--parallel`
- CI-ready TAP output: `--tap`

### 🔧 **Maintainable Helpers**
- Modular helper functions
- Domain-specific assertions
- Standardized setup/teardown
- Reusable test fixtures

### 🚀 **Scalable Architecture**
- Easy to add new test categories
- Simple to extend helper modules  
- Backward compatible structure
- CI/CD integration ready

## Performance Metrics

- **Unit Tests**: ~5-15 seconds (39 tests)
- **Integration Tests**: ~10-30 seconds (12 tests)  
- **E2E Tests**: ~30-60 seconds (11 tests)
- **Full Suite**: ~45-90 seconds (62 tests total)
- **Parallel Mode**: ~20-40% faster

## Migration from Old Structure

The new organized structure maintains **100% backward compatibility**:

✅ **Existing commands work**:
- `make test` runs all tests
- `make test-integration` uses new structure
- `./run-tests.sh` discovers all organized tests

✅ **Legacy test-helper.bash** loads all new modules

✅ **Collocated unit tests** work from any execution context

✅ **GitHub Actions** updated for new test categories
    HOME_DIR="$TEST_DIR/home"
    setup_mock_installation "$HOME_DIR"
    
    cd "$HOME_DIR/.claude"
    run ./utils/version.sh get
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
```

## Test Utilities

### Test Helper Functions (`test-helper.bash`)

Common utilities shared across all test suites:
- **Environment Setup**: Temporary directories and mock installations
- **Validation Helpers**: Version format checking, output pattern matching
- **Mock Functions**: Override framework directories for isolated testing
- **Debugging Tools**: Test failure investigation utilities

**Key Functions:**
```bash
create_mock_home()         # Setup isolated installation environment
is_valid_version()         # Validate semantic version format
override_framework_dir()   # Redirect framework operations to test directory
debug_test_failure()       # Debug information for failing tests
```

### Test Runner (`run-tests.sh`)

Advanced test execution with multiple options:
- **Filtering**: Run specific test patterns
- **Parallel Execution**: Concurrent test execution
- **Output Formats**: Human-readable or TAP for CI
- **Legacy Integration**: Run old shell-based tests for comparison

**Command Line Options:**
```bash
./run-tests.sh --help               # Show all options
./run-tests.sh --verbose            # Detailed output
./run-tests.sh --parallel           # Concurrent execution  
./run-tests.sh --filter "version"   # Pattern filtering
./run-tests.sh --tap                # TAP output for CI
```

## GitHub Actions Integration

### Workflow Structure (`.github/workflows/bats-tests.yml`)

**Multi-Matrix Testing:**
- **Test Suites**: Parallel execution of different test suites
- **Cross-Platform**: Ubuntu and macOS testing
- **Integration Levels**: Unit tests → Integration tests → Full validation

**Workflow Jobs:**
1. **bats-tests**: Matrix execution of individual test suites
2. **integration-tests**: Complete framework validation
3. **cross-platform-tests**: Multi-OS compatibility testing

**Features:**
- Automatic submodule initialization
- TAP output for GitHub's test reporting
- Test result summaries in GitHub UI
- Failure investigation with detailed logs

## Development Workflow

### Writing New Tests

1. **Create Test File**: Use `.bats` extension
2. **Add Test Helper**: Load common utilities with `load 'test_helper'`
3. **Write Test Functions**: Use `@test "description" { ... }` format
4. **Use Assertions**: `[ condition ]` for success, check `$status` and `$output`
5. **Add to Runner**: Update `run-tests.sh` if needed

**Test Template:**
```bash
#!/usr/bin/env bats

load 'test_helper'

setup() {
    # Test-specific setup
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

@test "descriptive test name" {
    run your_command_here
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected content"* ]]
}
```

**Hook Tests:**

Hooks read a JSON payload on stdin and write a decision to stdout. To test a hook:

1. **Make a Temporary Directory**: Create `.sf/` in it during `setup()`
2. **Write Fixtures**: Add the files the hook reads, for example `spec.md` and `implementation-summary.md`
3. **Send the Payload**: Point the `cwd` field at the temporary directory
4. **Separate stderr**: Use `run --separate-stderr` to keep stderr out of `$output`
5. **Clean Up**: Remove the temporary directory in `teardown()`

```bash
run --separate-stderr bash "$HOOK" <<< "{\"cwd\":\"$TEST_DIR\",\"stop_hook_active\":false}"
```

The test runner finds `tests/integration/*.bats` automatically. A new file needs no registration. See `tests/integration/hooks.bats` for a full example.

### Debugging Failed Tests

1. **Run with Verbose Output**: `make test-verbose`
2. **Use Debug Helper**: Call `debug_test_failure` in test
3. **Isolate the Test**: Use filtering to run single test
4. **Check Environment**: Verify `$PROJECT_ROOT`, `$TEST_DIR` variables
5. **Manual Execution**: Run commands outside BATS for investigation

### Best Practices

- **Isolation**: Each test should be independent and cleanup after itself
- **Descriptive Names**: Test names should clearly describe expected behavior
- **Setup/Teardown**: Use setup() and teardown() for consistent test environment
- **Helper Functions**: Extract common patterns to test-helper.bash
- **Error Messages**: Include context in assertions for easier debugging

## Migration from Legacy Tests

### Legacy Test Support

The old shell-based tests (`integration.sh`, `version.sh`) are preserved for:
- **Backward Compatibility**: Ensure new BATS tests cover same scenarios
- **Transition Period**: Gradual migration without losing test coverage
- **Verification**: Cross-validate BATS results against established tests

### Migration Strategy

1. **Convert Gradually**: Move test cases one-by-one to BATS format
2. **Run Both**: Execute legacy and BATS tests in parallel during transition
3. **Validate Equivalence**: Ensure BATS tests catch same issues as legacy tests
4. **Remove Legacy**: Deprecate shell-based tests once BATS coverage is complete

## Continuous Integration

### Local Development
```bash
# Quick development cycle
make dev                    # Clean, setup, and run verbose tests

# Watch mode (requires fswatch)
make dev-watch             # Auto-run tests on file changes

# Release validation
make release-check         # Complete test suite for release
```

### CI/CD Pipeline
```bash
# CI execution
make ci-test               # TAP output for GitHub Actions
make ci-validate           # Plugin validation for CI

# Manual CI testing
export GITHUB_ACTIONS=true
cd tests && ./run-tests.sh --tap
```

## Troubleshooting

### Common Issues

**Submodule Not Initialized:**
```bash
# Fix: Initialize git submodules
git submodule update --init --recursive
make setup
```

**Permission Errors:**
```bash
# Fix: Make scripts executable
chmod +x tests/run-tests.sh
chmod +x tests/bats-core/bin/bats
chmod +x scripts/*.sh
```

**Test Environment Issues:**
```bash
# Fix: Clean and reset
make clean
make setup
```

**Legacy Test Compatibility:**
```bash
# Run legacy tests for comparison
make test-legacy
```

### Getting Help

- **Framework Issues**: Check `./scripts/validate-plugin.sh` output
- **Version Problems**: Run `./scripts/version.sh info` for diagnostics
- **Test Debugging**: Use `make test-verbose` and `debug_test_failure()`
- **CI Problems**: Check GitHub Actions logs and workflow configuration

## Performance

### Test Execution Times

- **Serial Execution**: ~30-60 seconds for complete suite
- **Parallel Execution**: ~15-30 seconds with `--parallel`
- **Individual Suites**: ~5-15 seconds each
- **CI Execution**: ~2-5 minutes including setup and validation

### Optimization Tips

- Use `make test-parallel` for faster local development
- Filter tests during development: `make test FILTER=specific`
- Run individual suites: `make test-version` or `make test-integration`
- Use `make dev` for clean development cycles