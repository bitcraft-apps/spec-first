---
name: implement
description: Implement through pattern learning
disable-model-invocation: true
argument-hint: "[--isolate] [SPECIFICATION_OR_PATH]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-implementation.sh:*)
---

# Implement Command

Creates a minimal implementation that follows the existing patterns. One agent does the steps
in order.

## Usage
```
/sf:implement [--isolate] [SPECIFICATION_OR_PATH]
```

## Context

Read the current branch. Check whether `.sf/spec.md` exists.

## Input Resolution

1. If the skill has arguments: use them as a specification path or as inline requirements
2. Else if `.sf/spec.md` exists: use it
3. Else: ask the user where the specification is. Wait for the answer.

## Execution

**Step 1 — Learn**
- Search the codebase for the closest existing pattern for this specification. Stop when you
  have one good example. Do not survey the whole repository.
- Write the example to `.sf/research/pattern-example.md`.

**Step 2 — Implement**
- Follow the pattern you found. No creativity.
- Write the simplest change that works. No abstractions for later. One feature at a time.
- Test that it works.
- Write `.sf/implementation-summary.md`.

**Gate — Post-Implementation:** run `scripts/validate-implementation.sh`, in this skill directory.
**If validate-implementation.sh fails (non-zero exit), check every criterion the spec meets, or
finish the work it names. Do not report the implementation as done.**

Output: Implementation + `.sf/implementation-summary.md`

If Step 1 finds no pattern: create the basic file structure the language expects, implement only
the core requirement, and note in the summary: "No existing patterns found - used minimal approach".

## Philosophy

This command enforces:
- Pattern consistency over creativity
- Working code over perfect code
- Minimal solution over extensible solution

## On Claude Code

Claude Code has subagents. Use them for both steps.

Context arrives for free:
- Branch: !`git branch --show-current 2>/dev/null`
- Spec exists: !`test -f .sf/spec.md && echo "yes" || echo "no"`

- Parse $ARGUMENTS. `--isolate` is a Claude-only flag: strip it and set ISOLATE=true.
- Use the **AskUserQuestion** tool to ask for the specification location.
- Step 1: use the Agent tool with subagent_type="Explore" to find the pattern for $SPECIFICATION
  (request "medium" thoroughness in the prompt).
- Step 2: Task: implement-minimal with spec: $SPECIFICATION. If ISOLATE is true, add
  isolation: "worktree".
- Gate: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-implementation.sh ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
