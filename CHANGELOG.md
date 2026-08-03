# Changelog

All notable changes to Spec First will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1](https://github.com/bitcraft-apps/spec-first/compare/v1.3.0...v1.3.1) (2026-08-03)


### Bug Fixes

* **hooks:** count only unchecked criteria ([#231](https://github.com/bitcraft-apps/spec-first/issues/231)) ([c8c38d3](https://github.com/bitcraft-apps/spec-first/commit/c8c38d381e1c10123ca135788b7604cacc061a9b))
* move maxTurns from skill prose to agent frontmatter ([#222](https://github.com/bitcraft-apps/spec-first/issues/222)) ([a231767](https://github.com/bitcraft-apps/spec-first/commit/a231767f0b87623f46bbd4016768cd1b48d70c3f))


### Code Refactoring

* make validate-implementation guard explicit ([#225](https://github.com/bitcraft-apps/spec-first/issues/225)) ([6938e70](https://github.com/bitcraft-apps/spec-first/commit/6938e70558b811ad75eda41a8ace4baddca2261b))


### Documentation

* adopt Simplified Technical English (ASD-STE100) for English prose ([#205](https://github.com/bitcraft-apps/spec-first/issues/205)) ([dd79dcd](https://github.com/bitcraft-apps/spec-first/commit/dd79dcdaec4cf10ab7bb4d799476e00daf8aa64c))


### Miscellaneous

* remove dead validate-subagent.sh hook ([#223](https://github.com/bitcraft-apps/spec-first/issues/223)) ([7fcaebb](https://github.com/bitcraft-apps/spec-first/commit/7fcaebb41ea20cf94796d532b05f415b3bb2884b))

## [1.3.0](https://github.com/bitcraft-apps/spec-first/compare/v1.2.0...v1.3.0) (2026-03-16)


### Features

* add generated output examples to rate-limiter ([#199](https://github.com/bitcraft-apps/spec-first/issues/199)) ([5ce61ec](https://github.com/bitcraft-apps/spec-first/commit/5ce61ec112f3e015e0aa38e40d827d7f23d59e58))


### Documentation

* add token usage guidance to README ([#195](https://github.com/bitcraft-apps/spec-first/issues/195)) ([510480c](https://github.com/bitcraft-apps/spec-first/commit/510480c7867ef9c58b67f22fc72ae70568dd2d21))

## [1.2.0](https://github.com/bitcraft-apps/spec-first/compare/v1.1.0...v1.2.0) (2026-03-15)


### Features

* add BATS unit tests for validate-plugin.sh and version.sh ([#193](https://github.com/bitcraft-apps/spec-first/issues/193)) ([3b9d042](https://github.com/bitcraft-apps/spec-first/commit/3b9d042b5826528fb36cdf19f54a04f7007c9dce))


### Bug Fixes

* add failure handling to manage-spec-directory ([#194](https://github.com/bitcraft-apps/spec-first/issues/194)) ([b3a2770](https://github.com/bitcraft-apps/spec-first/commit/b3a2770ef273c80beb04b096b89e88f480e57dde))
* allow empty analysis files in document skill Gate 1 ([#190](https://github.com/bitcraft-apps/spec-first/issues/190)) ([f14deca](https://github.com/bitcraft-apps/spec-first/commit/f14deca253e3a739fb07082da29f0f20e2c89c74))

## [1.1.0](https://github.com/bitcraft-apps/spec-first/compare/v1.0.3...v1.1.0) (2026-03-15)


### Features

* add ShellCheck CI workflow and fix existing violations ([#187](https://github.com/bitcraft-apps/spec-first/issues/187)) ([3553309](https://github.com/bitcraft-apps/spec-first/commit/3553309972c62fd59baae78217720bb25d2a1a3d))


### Bug Fixes

* prompt user for mode when spec exists without mode file ([#189](https://github.com/bitcraft-apps/spec-first/issues/189)) ([2a47a90](https://github.com/bitcraft-apps/spec-first/commit/2a47a9076972644306761b4098a5caa154fe2622))
## [1.0.3](https://github.com/bitcraft-apps/spec-first/compare/v1.0.2...v1.0.3) (2026-03-15)


### Miscellaneous

* add Dependabot for GitHub Actions and submodule updates ([#163](https://github.com/bitcraft-apps/spec-first/issues/163)) ([8b366e0](https://github.com/bitcraft-apps/spec-first/commit/8b366e0fc9fd0e930a63b76431df3988c2effceb))
* **deps:** bump actions/cache from 4 to 5 ([#165](https://github.com/bitcraft-apps/spec-first/issues/165)) ([c44a9b4](https://github.com/bitcraft-apps/spec-first/commit/c44a9b43ad4e276b782cb639e1f14c46a532d382))
* **deps:** bump actions/checkout from 4 to 6 ([#166](https://github.com/bitcraft-apps/spec-first/issues/166)) ([af0ef1e](https://github.com/bitcraft-apps/spec-first/commit/af0ef1e80c5990b85b532ef4cf20a16c27541379))
* **deps:** bump tests/bats-core from `855844b` to `3bca150` ([#167](https://github.com/bitcraft-apps/spec-first/issues/167)) ([250be60](https://github.com/bitcraft-apps/spec-first/commit/250be60af386781753e66e9bc71eeda0bfa8216c))

## [1.0.2](https://github.com/bitcraft-apps/spec-first/compare/v1.0.1...v1.0.2) (2026-03-15)


### Bug Fixes

* add completion instructions to synthesize-spec agent ([#160](https://github.com/bitcraft-apps/spec-first/issues/160)) ([6a2a0c8](https://github.com/bitcraft-apps/spec-first/commit/6a2a0c80e6ef0ae9f5ac25cb0df2cd3f4d6a18aa))

## [1.0.1](https://github.com/bitcraft-apps/spec-first/compare/v1.0.0...v1.0.1) (2026-03-14)


### Bug Fixes

* correct plugin installation instructions ([#155](https://github.com/bitcraft-apps/spec-first/issues/155)) ([20d88d7](https://github.com/bitcraft-apps/spec-first/commit/20d88d7e078f51d603dd2f0e310338b95c10814e))
* polish marketplace metadata for Anthropic submission ([#158](https://github.com/bitcraft-apps/spec-first/issues/158)) ([5c9361a](https://github.com/bitcraft-apps/spec-first/commit/5c9361a09cf818bae1ee8342d66ed87b20ca13cf))
* remove one-time release bootstrapping config ([#157](https://github.com/bitcraft-apps/spec-first/issues/157)) ([5f7c489](https://github.com/bitcraft-apps/spec-first/commit/5f7c48932c7160426fbda8c6499c862ca2b874af))

## [1.0.0](https://github.com/bitcraft-apps/spec-first/compare/v0.31.1...v1.0.0) (2026-03-14)


### ⚠ BREAKING CHANGES

* rename plugin from csf to sf for marketplace ([#150](https://github.com/bitcraft-apps/spec-first/issues/150))

### Features

* marketplace listing - README rewrite and metadata ([#152](https://github.com/bitcraft-apps/spec-first/issues/152)) ([a8e05b7](https://github.com/bitcraft-apps/spec-first/commit/a8e05b7eac86315141de9d497c58de914fa13659))
* rename plugin from csf to sf for marketplace ([#150](https://github.com/bitcraft-apps/spec-first/issues/150)) ([448bff5](https://github.com/bitcraft-apps/spec-first/commit/448bff5bf711b983702a1f5e36c134e4f9cfa5a2))


### Miscellaneous

* force next release as 1.0.0 ([#154](https://github.com/bitcraft-apps/spec-first/issues/154)) ([227c5eb](https://github.com/bitcraft-apps/spec-first/commit/227c5ebab81db3f53dfc3796f94756121012f098))

## [Unreleased]

### BREAKING CHANGES

* Plugin renamed from `csf` to `sf`. Commands are now `/sf:spec`, `/sf:implement`, `/sf:document`.
* Working directory moved from `.claude/.csf/` to `.claude/.sf/`.

### Migration

1. Move existing specs: `mv .claude/.csf .claude/.sf`
2. Reinstall: `claude plugin remove csf && claude plugin add bitcraft-apps/spec-first`

## [0.31.1](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.31.0...v0.31.1) (2026-03-13)


### Bug Fixes

* align marketplace plugin name with plugin.json ([#147](https://github.com/bitcraft-apps/claude-spec-first/issues/147)) ([60e89ef](https://github.com/bitcraft-apps/claude-spec-first/commit/60e89efb200c43684a3fa4b575cb84ef69f8c234))

## [0.31.0](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.30.2...v0.31.0) (2026-03-13)


### Features

* Add --isolate flag to /csf:implement ([#144](https://github.com/bitcraft-apps/claude-spec-first/issues/144)) ([ee093a7](https://github.com/bitcraft-apps/claude-spec-first/commit/ee093a74f744c2327774a82777db43b61bcf9240))
* Add structural template for synthesize-spec ([#103](https://github.com/bitcraft-apps/claude-spec-first/issues/103)) ([#143](https://github.com/bitcraft-apps/claude-spec-first/issues/143)) ([1f218b4](https://github.com/bitcraft-apps/claude-spec-first/commit/1f218b44fc1ef6dfa9acd2888dc4b2eea1b93bf5))
* Archive legacy v0.x installation docs ([#108](https://github.com/bitcraft-apps/claude-spec-first/issues/108)) ([#141](https://github.com/bitcraft-apps/claude-spec-first/issues/141)) ([d65522e](https://github.com/bitcraft-apps/claude-spec-first/commit/d65522e99835bee4da6e6306718a26cbdff9a54f))


### Bug Fixes

* Use explicit AskUserQuestion tool in skills ([#146](https://github.com/bitcraft-apps/claude-spec-first/issues/146)) ([b5e6a3f](https://github.com/bitcraft-apps/claude-spec-first/commit/b5e6a3ff332f8fded7bad4c9ce5227c012e42867))

## [0.30.2](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.30.1...v0.30.2) (2026-03-13)


### Bug Fixes

* Remove duplicate hooks reference from plugin.json ([#139](https://github.com/bitcraft-apps/claude-spec-first/issues/139)) ([40ea6b2](https://github.com/bitcraft-apps/claude-spec-first/commit/40ea6b27be696d2019816f832985e01d45c6ea58))

## [0.30.1](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.30.0...v0.30.1) (2026-03-13)


### Bug Fixes

* Include all commit types in release-please changelog ([#136](https://github.com/bitcraft-apps/claude-spec-first/issues/136)) ([9d85d1a](https://github.com/bitcraft-apps/claude-spec-first/commit/9d85d1a7c72b08bb5e3de541dd7be8ae7d9965d2))


### Code Refactoring

* Align plugin structure with Anthropic conventions ([#135](https://github.com/bitcraft-apps/claude-spec-first/issues/135)) ([35399b7](https://github.com/bitcraft-apps/claude-spec-first/commit/35399b7cb71afd5fba766bc6382efbebf88d61cb))

## [0.30.0](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.29.0...v0.30.0) (2026-03-12)


### Features

* Add dynamic context injection to CSF skills ([#133](https://github.com/bitcraft-apps/claude-spec-first/issues/133)) ([5ab89db](https://github.com/bitcraft-apps/claude-spec-first/commit/5ab89db4e6ae8a8c84e18e6a53e637947c650845))
* Namespace skills under csf/ for plugin discovery ([#134](https://github.com/bitcraft-apps/claude-spec-first/issues/134)) ([bc32c79](https://github.com/bitcraft-apps/claude-spec-first/commit/bc32c79cb0545013c3125de732ba2f1202199dd7))


### Bug Fixes

* Use individual file paths in plugin.json for CLI compatibility ([#131](https://github.com/bitcraft-apps/claude-spec-first/issues/131)) ([2e946e7](https://github.com/bitcraft-apps/claude-spec-first/commit/2e946e73fc43e58438db701ddcfc839017395c58))

## [0.29.0](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.28.0...v0.29.0) (2026-03-12)


### Features

* Add marketplace.json for GitHub-based plugin installation ([#125](https://github.com/bitcraft-apps/claude-spec-first/issues/125)) ([8c09c94](https://github.com/bitcraft-apps/claude-spec-first/commit/8c09c94a15c1f9e6b14eef1c5e6c5c208404aed5))


### Bug Fixes

* Move marketplace.json to .claude-plugin/ for CLI discovery ([#128](https://github.com/bitcraft-apps/claude-spec-first/issues/128)) ([0dc75f4](https://github.com/bitcraft-apps/claude-spec-first/commit/0dc75f4db48b341b3f8cf15d3ff0b8412cf934e1))
* Use path strings in plugin.json manifest ([#130](https://github.com/bitcraft-apps/claude-spec-first/issues/130)) ([65ef07b](https://github.com/bitcraft-apps/claude-spec-first/commit/65ef07bfebf359c146579df93497963139256eb5))

## [0.28.0](https://github.com/bitcraft-apps/claude-spec-first/compare/v0.27.1...v0.28.0) (2026-03-12)


### Features

* Add release-please for automated releases ([#121](https://github.com/bitcraft-apps/claude-spec-first/issues/121)) ([e7a9912](https://github.com/bitcraft-apps/claude-spec-first/commit/e7a99121bf578249e799c0cab781ebe48626abca))

## [0.27.1] - 2026-03-11

### Changed
- Update CI pipeline for plugin structure: replace deleted install-test job with plugin-validation and format-checks jobs (#98)
- Migrate test suite for plugin structure: delete 5 obsolete test files, add `plugin-validation.bats` (#99)

## [0.27.0] - 2026-03-11

### Changed
- Migrate hooks from `settings.json` injection to plugin-native `hooks.json` format
- Use `${CLAUDE_PLUGIN_ROOT}` for hook command paths per Claude Code plugin spec
- Add `cleanup_old_hooks()` to remove legacy CSF hook entries from `settings.json` on upgrade

### Fixed
- Fix flaky test 19 ("works without git repository") failing on broken symlinks in local `.csf/` state

## [0.26.0] - 2026-03-11

### Changed
- Migrate commands to skills format — `framework/commands/*.md` → `framework/skills/*/SKILL.md` with YAML frontmatter (#95)
- Update `validate-framework.sh` to validate skills in repo mode, commands in installed mode
- Update `plugin.json` key from `commands` to `skills`
- Update integration tests for new skill paths
- Update stale "command files" reference in AGENTS.md

## [0.25.3] - 2026-03-10

### Fixed
- Add `manage-spec-directory` to fallback agent list in `validate-framework.sh`
- Add plugin.json vs VERSION file consistency check to catch version drift

## [0.25.2] - 2026-03-10

### Changed
- Trim `manage-spec-directory` agent from 63 to 49 lines — collapse gitignore logic, remove legacy `.csf/` warning (#112)

## [0.25.1] - 2026-03-10

### Changed
- **Standardize agent description frontmatter**: All 12 agent descriptions now follow a consistent two-sentence pattern: `[Verb phrase]. Use when [condition].` No behavior changes (#111).

## [0.25.0] - 2026-03-10

### Added
- `maxTurns` limits on all 13 agent invocations to prevent runaway execution

### Changed
- Rewrite doc agents with exclusion language — mandatory sections replaced with "include only if warranted"
- AGENTS.md is now the single source of truth; CLAUDE.md references it via `@AGENTS.md`
- Trim all project docs 63% (945→351 lines) — cut speculative content, redundancy, verbose changelog
- Validation checks AGENTS.md instead of CLAUDE.md for project rules

(#110)

## [0.24.0] - 2026-03-10

### Changed
- Route 7 research agents to Haiku for faster, cheaper execution (#90)
- Add model field validation to `validate-framework.sh`

## [0.23.0] - 2026-03-09

### Changed
- Replace `explore-patterns` agent with Claude Code's built-in Explore subagent (#54)
- Add LSP support to `analyze-implementation` agent (#53)
- Add `.claude/.csf/` to `.gitignore`

### Fixed
- Same-version update message shows "reinstalled" instead of misleading arrow (#86)

## [0.22.2] - 2026-03-09

### Fixed
- Suppress false positive legacy `.csf/` warning in installed mode (#71)

## [0.22.1] - 2026-03-09

### Fixed
- `$ARGUMENTS` placeholder in implement and document commands

## [0.22.0] - 2026-03-09

### Added
- Auto-append `.claude/.csf/` to `.gitignore` when creating spec directory

## [0.21.0] - 2026-03-09

### Changed
- Collapse 3-tier size constraints into 2: agents (50 lines) and commands (75 lines)

## [0.20.0] - 2026-03-09

### Changed
- Raise doc agent line limit from 25 to 50
- Add dedup checks via `docs-inventory.md` and shared `doc-context.md`

## [0.19.1] - 2026-03-09

### Fixed
- Gate 2: downgrade missing sections from block to warn
- Include gate warnings in terminal summary

## [0.19.0] - 2026-03-09

### Added
- `analyze-existing-docs` agent for doc inventory, enabling update-or-create behavior

## [0.18.0] - 2026-03-09

### Changed
- Add required-sections contracts to `create-technical-docs` and `create-user-docs`

## [0.17.0] - 2026-03-09

### Changed
- Rewrite `integrate-docs` for content synthesis via Edit/MultiEdit

## [0.16.1] - 2026-03-09

### Fixed
- Install script repo URL: `bitcraft-labs` → `bitcraft-apps`
- Temp directory leak on early exit
- Install test for download fallback behavior

## [0.16.0] - 2026-03-09

### Added
- SubagentStop hook (`validate-subagent.sh`) for non-empty output validation
- Installer configures both Stop and SubagentStop hooks

### Fixed
- Hook scripts explicitly `exit 0` on happy path

## [0.15.1] - 2025-09-24

### Fixed
- Agent paths: use literal `.claude/.csf/research/` instead of bash function calls
- Remove unnecessary `csf-paths.sh` utility (300+ lines removed)

## [0.15.0] - 2025-09-23

### Added
- Centralized path utility `csf-paths.sh` for CSF directory management

## [0.14.0] - 2025-09-16

### Fixed
- Framework installs globally (`~/.claude/`), outputs project-locally (`./.claude/.csf/`)

## [0.13.0] - 2025-09-16

### Changed
- Migrate CSF storage from `.csf/` to `.claude/.csf/`

## [0.12.0] - 2025-09-13

### Added
- Spec directory isolation: prompts update/create-new on subsequent runs (#36)
- `manage-spec-directory` agent

## [0.11.0] - 2025-09-01

### Changed
- Split monolithic `/csf:document` into 5 parallel micro-agents (#30)

## [0.10.0] - 2025-09-01

### Changed
- Split monolithic `/csf:implement` into sequential `explore-patterns` + `implement-minimal` (#34)

## [0.9.0] - 2025-09-01

### Changed
- Split monolithic `/csf:spec` into 4 parallel micro-agents (#28)
- Simplify CLAUDE.md from 296 to 93 lines (69% reduction)

## [0.8.0] - 2025-08-29

### Added
- File persistence system (`.csf/` directory)

## [0.7.0] - 2025-08-28

### Added
- Planning phase and `csf-plan` agent (later merged into spec)

## [0.6.0] - 2025-08-27

### Added
- Validation script, version management, test infrastructure

## [0.5.0] - 2025-08-26

### Changed
- **BREAKING**: 6 agents → 3, 9 commands → 4

## [0.4.0] - 2025-08-26

### Changed
- Smart command routing via `/csf:spec-init`
- Removed overengineered GitHub automation

## [0.3.0] - 2025-08-25

### Changed
- **BREAKING**: Agent namespacing with `csf-` prefix

## [0.2.0] - 2025-08-25

### Added
- MVP workflow commands, configurable LOC limits

## [0.1.0] - 2025-08-25

### Added
- Semantic versioning system, dual-mode validation
