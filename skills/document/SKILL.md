---
name: document
description: Generate minimal documentation through parallel agents
disable-model-invocation: true
argument-hint: "[SPECIFICATION_AND_IMPLEMENTATION_PATHS]"
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

**Gate 1 — Post-Analysis:** run `scripts/doc-gates.sh analysis`, in this skill directory.
**If doc-gates.sh fails (non-zero exit), halt immediately — do not write the documents.**

4. `technical-docs.md` — what a developer needs to use or extend the change. Skip any section
   that does not apply.
5. `user-docs.md` — only what the user must do differently. Skip it if the change is invisible.

An empty file is a valid result. It means the change does not need that document.

**Gate 2 — Post-Generation:** run `scripts/doc-gates.sh generation`.
**If doc-gates.sh fails (non-zero exit), halt immediately — do not integrate.**

6. Integrate: for each topic in `docs-inventory.md` that matches, edit that file. Create a file
   only when none fits. Cut duplicate content. Then delete the research files.

Output: Documentation updates (if any) + terminal summary

## Gate Failure Behavior
On a non-zero gate exit: halt, report which gate failed and the reason it printed, and keep the output for inspection.

## On Claude Code

Claude Code runs the steps as the `sf-document` workflow — schema-checked, and with no shared
file between the analysis agents. The workflow applies both gates itself.

- Implementation summary: !`test -f .sf/implementation-summary.md && head -20 .sf/implementation-summary.md || echo "none"`
- Use the **AskUserQuestion** tool to ask for the artifact locations.
- Workflow tool, `name: "sf-document"`. Pass `args` as a JSON object, never as a string:
  `{"specPath": "<the artifact path>", "implementationPath": "<the implementation summary path>"}`
- Report the files the workflow says it changed. An empty list means the change needs no docs.
