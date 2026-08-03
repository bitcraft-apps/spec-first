---
name: spec
description: Create specifications through parallel analysis
disable-model-invocation: true
argument-hint: "[REQUIREMENTS]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-dir.sh:*)
---

# Spec Command

Creates specifications with intelligent clarification.

## Usage
```
/sf:spec [REQUIREMENTS]
```

---

## Project Context
- Branch: !`git branch --show-current 2>/dev/null`
- Recent commits: !`git log --oneline -5 2>/dev/null`
- Working tree: !`git status --short 2>/dev/null | head -20`
- Existing spec: !`test -f .sf/spec.md && echo "yes" || echo "no"`

## Clarification Check

If requirements are vague (< 15 words or unclear), use the **AskUserQuestion** tool to gather missing context. Do NOT output questions as plain text — always use the tool so execution pauses for the user's answer.

**Questions to consider asking:**
- What specific problem are you solving?
- Who are the users?
- What's the desired outcome?
- Any technical constraints?
- What's the minimal viable version?

## Directory Management

Claude Code will use `.sf/` as the working directory.

**Command-level logic:**

```
If Existing spec is "yes":
    Use AskUserQuestion tool: "Existing spec found. What would you like to do?"
      Options: "Update existing" / "Create new"
    "Update existing" → MODE=update
    "Create new" → MODE=new
Else:
    MODE=first
```

## Execution

After directory setup and clarification (if needed), run agents:

**Pre-execution:**
- Bash: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/spec-dir.sh $MODE ${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.sf}`
  The script finds the project root itself if `CLAUDE_PROJECT_DIR` is not set.
- **If spec-dir.sh fails (non-zero exit), halt immediately — do not run downstream agents.**

**Batch 1 (Parallel):**
- Task: define-scope with requirements: $ARGUMENTS
- Task: create-criteria with requirements: $ARGUMENTS
- Task: identify-risks with requirements: $ARGUMENTS

**Batch 2:**
- Task: synthesize-spec to combine all research, following the structure in `${CLAUDE_SKILL_DIR}/spec-template.md`

Output: `$SF_DIR/spec.md` (direct file or symlink to timestamped spec)

## Error Recovery

If any agent fails:
1. Claude Code shows the specific error
2. Fix the issue (usually unclear requirements)
3. Re-run /sf:spec with clearer input
4. No partial state - each run starts fresh
