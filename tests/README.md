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
│   ├── dynamic-context.bats     # Shell commands in skill context sections
│   ├── hooks.bats               # Hook execution and output
│   ├── plugin.bats              # Plugin structure
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
bats integration/plugin.bats        # Single integration test
bats ../scripts/version.test.bats   # Unit test execution
bats e2e/                           # All E2E tests
```

## Test Suites

### Integration Tests (`tests/integration/`)

**Purpose**: Test component interactions, plugin artifacts, and workflows
**Files**:
- `directory-isolation.bats`: Spec directory isolation
- `dynamic-context.bats`: Shell commands embedded in skill Project Context sections
- `hooks.bats`: Hook execution and output (requires BATS 1.5.0 or later)
- `plugin.bats`: Plugin structure
- `plugin-validation.bats`: Plugin artifact validation (requires `python3`)
- `workflow.bats`: Workflow integration

### End-to-End Tests (`tests/e2e/`)

**Purpose**: Test error handling and edge cases
**Files**:
- `error-recovery.bats`: Error handling and recovery

## Helper System

`tests/helpers/` holds three helper modules. **No test loads them today, and no test can.** Each
module starts with `load 'common'`, and BATS resolves `load` against the directory of the test
file, not the directory of the helper. A test in `tests/integration/` therefore fails with
`Could not find .../tests/integration/common`. Every current test file instead sets its own
`PROJECT_ROOT` and defines its own `setup` and `teardown`. See the test template below.

Fixing the modules means replacing `load 'common'` with a path relative to the module itself.
Until then, treat this section as an inventory, not as instructions.

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
- `setup_unit_test()`: Standard unit setup
- `setup_e2e_test()`: Comprehensive E2E setup
- `teardown_*()`: Cleanup functions
- `run_with_timeout()`: Command timeout wrapper

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

## Test Utilities

### Test Runner (`run-tests.sh`)

Advanced test execution with multiple options:
- **Filtering**: Run specific test patterns
- **Parallel Execution**: Concurrent test execution
- **Output Formats**: Human-readable or TAP for CI

**Command Line Options:**
```bash
./run-tests.sh --help               # Show all options
./run-tests.sh --verbose            # Detailed output
./run-tests.sh --parallel           # Concurrent execution  
./run-tests.sh --filter "version"   # Pattern filtering
./run-tests.sh --tap                # TAP output for CI
```

## GitHub Actions Integration

### Workflow Structure (`.github/workflows/ci.yml`)

**Workflow Jobs:**
1. **tests**: Runs `run-tests.sh` over a matrix of `unit`, `integration` and `e2e`
2. **plugin-validation**: Checks `plugin.json`, `hooks.json`, and that skill and agent files exist
3. **shellcheck**: Runs ShellCheck over every `*.sh` file outside `bats-core`
4. **format-checks**: Checks frontmatter fields, agent prompt length, and placeholder text

Every job runs on `ubuntu-latest`.

**Features:**
- Automatic submodule initialization
- TAP output for GitHub's test reporting
- A `$GITHUB_STEP_SUMMARY` block per matrix leg

## Development Workflow

### Writing New Tests

1. **Create Test File**: Use `.bats` extension
2. **Set the Project Root**: Derive it from `$BATS_TEST_FILENAME`
3. **Write Test Functions**: Use `@test "description" { ... }` format
4. **Use Assertions**: `[ condition ]` for success, check `$status` and `$output`
5. **Add to Runner**: Update `run-tests.sh` if needed

**Test Template:**
```bash
#!/usr/bin/env bats

PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
export PROJECT_ROOT

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
2. **Isolate the Test**: Use filtering to run single test
3. **Check Environment**: Verify `$PROJECT_ROOT`, `$TEST_DIR` variables
4. **Manual Execution**: Run commands outside BATS for investigation

### Best Practices

- **Isolation**: Each test should be independent and cleanup after itself
- **Descriptive Names**: Test names should clearly describe expected behavior
- **Setup/Teardown**: Use setup() and teardown() for consistent test environment
- **Error Messages**: Include context in assertions for easier debugging

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

`make release-check` runs only the automated tests. Before a release, also do the
[Host Skill Loading Check](#host-skill-loading-check) by hand.

### CI/CD Pipeline
```bash
# CI execution
make ci-test               # TAP output for GitHub Actions
make ci-validate           # Plugin validation for CI

# Manual CI testing
export GITHUB_ACTIONS=true
cd tests && ./run-tests.sh --tap
```

## Host Skill Loading Check

The automated tests check that the install script writes the files. They do not check that a host
loads them. Do this check by hand before a release.

**Use an interactive session.** A headless print mode is not a valid substitute. GitHub Copilot
CLI 0.0.346 in `-p` mode loaded no skill at all, not even a minimal probe skill placed in the
directory it reads. A pass in print mode therefore proves nothing.

sf reaches hosts by two separate paths. Check the path you changed.

### Plugin path — Claude Code

Claude Code reads `~/.claude/skills`, not `.agents/skills`, and installs sf as a plugin. Do not
use `install.sh` to check this path.

1. `claude plugin install sf@spec-first`
2. Start Claude Code. Run `/sf:spec add a hello command` in a throwaway git repository.
3. Confirm that `.sf/spec.md` appears.

### Skills directory path — every other host

1. Install the skills. Check the skill documentation of your host for the directory it reads,
   then pass it with `--dir` if it is not `.agents/skills`:

   ```bash
   ./scripts/install.sh                       # .agents/skills
   ./scripts/install.sh --dir <host-skill-dir>
   ```

2. Start the host interactively. List its skills with the command of that host. Confirm that
   `spec`, `implement` and `document` appear with their descriptions.
3. Run the spec command in a throwaway git repository. Confirm that `.sf/spec.md` appears.

### Record

| sf version | Path | Host | Host version | Date |
|------------|------|------|--------------|------|
|            |      |      |              |      |

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

### Getting Help

- **Framework Issues**: Check `./scripts/validate-plugin.sh` output
- **Version Problems**: Run `./scripts/version.sh info` for diagnostics
- **Test Debugging**: Use `make test-verbose`
- **CI Problems**: Check GitHub Actions logs and workflow configuration

## Optimization Tips

- Use `make test-parallel` for faster local development
- Filter tests during development: `make test FILTER=specific`
- Run individual suites: `make test-version` or `make test-integration`
- Use `make dev` for clean development cycles