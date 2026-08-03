---
name: document
description: Generate minimal documentation through parallel agents
disable-model-invocation: true
argument-hint: "[SPECIFICATION_AND_IMPLEMENTATION_PATHS]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh:*)
---

# Document Command

Creates minimal, proportional documentation. Match doc weight to change weight. One agent does
the steps in order.

## Usage
```
/sf:document [SPECIFICATION_AND_IMPLEMENTATION_PATHS]
```

## Context

Read `.sf/implementation-summary.md` if it exists.

## Input Resolution

1. If the skill has arguments: use them as artifact and implementation paths
2. Else if `.sf/spec.md` and `.sf/implementation-summary.md` exist: use them
3. Else: ask the user where the artifacts are. Wait for the answer.

## Execution

Write each file in turn. All paths are under `$SF_DIR/research/`.

1. `artifacts-summary.md` — the requirements and outcomes in the artifacts. Read only what exists.
2. `implementation-summary.md` — the real code structure: the main files, the changed interfaces.
3. `docs-inventory.md` — every existing doc as `filepath | primary topic`, from the headings only.

**Gate 1 — Post-Analysis:** run `doc-gates.sh analysis`. The script is at `../../scripts/`
relative to this skill directory.
**If doc-gates.sh fails (non-zero exit), halt immediately — do not write the documents.**

4. `technical-docs.md` — what a developer needs to use or extend the change. Skip any section
   that does not apply.
5. `user-docs.md` — only what the user must do differently. Skip it if the change is invisible.

An empty file is a valid result. It means the change does not need that document.

**Gate 2 — Post-Generation:** run `doc-gates.sh generation`.
**If doc-gates.sh fails (non-zero exit), halt immediately — do not integrate.**

6. Integrate: for each topic in `docs-inventory.md` that matches, edit that file. Create a file
   only when none fits. Cut duplicate content. Then delete the research files.

Output: Documentation updates (if any) + terminal summary

## Gate Failure Behavior
On a non-zero gate exit: halt, report which gate failed and the reason it printed, and keep the output for inspection.

## On Claude Code

Claude Code has subagents. Use them to run the steps in three batches.

- Implementation summary: !`test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"`
- Use the **AskUserQuestion** tool to ask for the artifact locations.
- Batch 1 (Parallel): analyze-artifacts, analyze-implementation, analyze-existing-docs
- Gate 1: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh analysis ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
- Batch 2 (Parallel): create-technical-docs, create-user-docs. They share terminology through
  `$SF_DIR/research/doc-context.md`. One agent working alone does not need that file.
- Gate 2: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/doc-gates.sh generation ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
- Batch 3: integrate-docs
