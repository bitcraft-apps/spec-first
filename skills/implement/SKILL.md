---
name: implement
description: Implement through pattern learning
disable-model-invocation: true
argument-hint: "[--isolate] [SPECIFICATION_OR_PATH]"
---

# Implement Command

Creates minimal implementation following existing patterns.

## Usage
```
/sf:implement [--isolate] [SPECIFICATION_OR_PATH]
```

---

## Project Context
- Branch: !`git branch --show-current 2>/dev/null`
- Spec exists: !`test -f .claude/.sf/spec.md && echo "yes" || echo "no"`

## Input Resolution

**Input Resolution:**

1. Parse $ARGUMENTS: If `--isolate` is present, set ISOLATE=true and strip it from remaining args
2. If remaining args provided: Use as specification path or inline requirements
3. Else if `.claude/.sf/spec.md` exists: Use it
4. Else: Use **AskUserQuestion** tool to ask for specification location

## Execution

After input resolution, run sequential agents:

**Step 1: Learn**
- Use Agent tool with subagent_type="Explore" to find similar patterns in the codebase for: $SPECIFICATION (request "medium" thoroughness in the prompt)
- Save findings to `.claude/.sf/research/pattern-example.md`

**Step 2: Implement**
- If ISOLATE is true: Task: implement-minimal with spec: $SPECIFICATION, isolation: "worktree"
- Else: Task: implement-minimal with spec: $SPECIFICATION

Output: Implementation + `.claude/.sf/implementation-summary.md`

## Philosophy

This command enforces:
- Pattern consistency over creativity
- Working code over perfect code
- Minimal solution over extensible solution

## Error Recovery

If exploration finds no patterns:
1. implement-minimal creates basic file structure following language conventions
2. Implements only the core requirement (no extras)
3. Uses standard naming patterns for the technology
4. Notes in summary: "No existing patterns found - used minimal approach"
