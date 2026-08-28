---
name: spec
description: Create specifications from requirements
disable-model-invocation: true
argument-hint: "[REQUIREMENTS]"
---

# Spec Command

Creates a specification from requirements. One agent does the steps in order.

## Usage

`/sf:spec [REQUIREMENTS]`

## Context

Read the current branch, the last 5 commits, and the working tree.
Check whether `.sf/spec.md` exists.

## Clarification Check

If the requirements are vague (fewer than 15 words, or unclear), ask the user before you start.
Wait for the answer. Do not assume. Ask about:

- What specific problem are you solving?
- Who are the users?
- What's the desired outcome?
- Any technical constraints?
- What's the minimal viable version?

## Directory Management

The working directory is `.sf/`. `$SF_DIR` overrides it.

Pick the mode:
- No `.sf/spec.md` → `first`
- `.sf/spec.md` exists → ask the user: "Update existing" / "Create new" → `update` / `new`

Run `scripts/spec-dir.sh <first|update|new>`, in this skill directory.
**If spec-dir.sh fails (non-zero exit), halt immediately — do not do the work below.**

## Execution

Write each file in turn. The requirements are the input to this skill.

1. `.sf/research/scope.md` — the narrowest viable change. Exclude what is not needed now.
2. `.sf/research/criteria.md` — the simplest testable pass/fail conditions.
3. `.sf/research/risks.md` — blockers only, not every possible risk.
4. `$SF_DIR/spec.md` — merge the three files. Keep it under 50 lines. Use the structure in
   `spec-template.md`, next to this file.

**Gate — Post-Spec:** run `scripts/validate-spec.sh`, in this skill directory.
**If it fails (non-zero exit), add the sections it names, then run it again. Do not report done.**

Output: `$SF_DIR/spec.md` (direct file or symlink to timestamped spec)

Say: "Spec written to `{output path}`. Run `/sf:implement` to build it."

## On Claude Code

Claude Code runs one schema-checked combined research call by default, then synthesis. The
combined result supplies scope, criteria, and risks without research files. Set
`parallelResearch: true` in the workflow input to run steps 1 to 3 as three parallel research
calls.

Context arrives for free:
- Branch: !`git branch --show-current 2>/dev/null`
- Recent commits: !`git log --oneline -5 2>/dev/null`
- Working tree: !`git status --short 2>/dev/null | head -20`
- Existing spec: !`test -f .sf/spec.md && echo "yes" || echo "no"`

- Use the **AskUserQuestion** tool for both questions above, so execution pauses for the answer.
- Bash: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-dir.sh $MODE ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
- Workflow tool, `name: "sf-spec"`. Pass `args` as a JSON object, never as a string:
  `{"requirements": "$ARGUMENTS", "specPath": "<the spec.md path above>", "templatePath": "${CLAUDE_SKILL_DIR}/spec-template.md"}`.
  `parallelResearch` is a boolean and defaults to `false`; set it to `true` for three parallel
  research calls.
- Gate: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-spec.sh ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
