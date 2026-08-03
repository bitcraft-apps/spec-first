---
name: document
description: Generate minimal documentation through parallel agents
disable-model-invocation: true
argument-hint: "[SPECIFICATION_AND_IMPLEMENTATION_PATHS]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh:*)
---

# Document Command

Creates minimal, proportional documentation. Match doc weight to change weight.

## Usage
```
/sf:document [SPECIFICATION_AND_IMPLEMENTATION_PATHS]
```

---

## Project Context
- Implementation summary: !`test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"`

## Input Resolution

**Input Resolution:**

1. If $ARGUMENTS provided: Use as artifact/implementation paths
2. Else if `.sf/spec.md` and `.sf/implementation-summary.md` exist: Use them
3. Else: Use **AskUserQuestion** tool to ask for artifact locations

## Execution

After input resolution, run agents in 3 batches:

**Batch 1 (Parallel):**
- Task: analyze-artifacts with requirements: $ARTIFACT_PATHS
- Task: analyze-implementation with requirements: $IMPLEMENTATION_PATHS
- Task: analyze-existing-docs (scans project for existing documentation inventory)

**Gate 1 — Post-Analysis:**
- Bash: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh analysis ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
- **If doc-gates.sh fails (non-zero exit), halt immediately — do not run Batch 2.**

**Batch 2 (Parallel):**
- Task: create-technical-docs (reads $SF_DIR/research/artifacts-summary.md, $SF_DIR/research/implementation-summary.md)
- Task: create-user-docs (reads $SF_DIR/research/artifacts-summary.md, $SF_DIR/research/implementation-summary.md)

**Gate 2 — Post-Generation:**
- Bash: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh generation ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
- **If doc-gates.sh fails (non-zero exit), halt immediately — do not run Batch 3.**

**Batch 3:**
- Task: integrate-docs (reads docs-inventory.md to update existing files or create new ones)

Output: Documentation updates (if any) + terminal summary

## Gate Failure Behavior
On a non-zero gate exit: halt, report which gate failed and the reason it printed, and keep the output for inspection.
