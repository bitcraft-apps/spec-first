# Getting Started

Your first run of Spec First, from install to a spec, an implementation and updated docs.

## Before you start

Pick a repository you work in. Pick one small change you can finish in one sitting.

Add the artifact directory to `.gitignore`. The three commands write their files there:

```gitignore
.sf/
```

[Setup](technical-reference.md#setup) gives the full list of prerequisites.

## Install

### Claude Code

Add the marketplace. Then install the plugin from your terminal:

```bash
claude plugin marketplace add bitcraft-apps/spec-first
claude plugin install sf@spec-first
```

Or run these commands in Claude Code:

```
/plugin marketplace add bitcraft-apps/spec-first
/plugin install sf@spec-first
```

The plugin adds the three commands, the validation hooks and the parallel workflows.

### Other hosts

Many agent hosts read skills from the shared `.agents/skills` location. Install the skills there
from a checkout:

```bash
git clone https://github.com/bitcraft-apps/spec-first && cd spec-first
./scripts/install.sh                         # ~/.agents/skills — every project
./scripts/install.sh --dir .agents/skills    # one project only
```

This installs the three commands. The skills call the same validation scripts, so the same checks
run. The parallel workflows are Claude Code only.

[Supported hosts](supported-hosts.md) gives the directory each host reads. A host that reads
somewhere else needs `--dir <that directory>`.

A checkout installs by symlink. A downloaded release installs by copy. To remove the skills,
delete them:

```bash
rm -rf ~/.agents/skills/{spec,implement,document}
```

## Write the spec

Give the command your requirement:

```
/sf:spec Add a rate limiter to the API gateway
```

```
Researching requirements...

  Research (parallel): scope, criteria, risks
  Synthesis: spec.md

Spec written to .sf/spec.md
```

Write more than 15 words. Below that the command asks you questions first, and waits for your
answers.

The command runs a validation script at the end. Your host asks for permission the first time
that script runs. Approve it.

## Read the spec before you go on

Open `.sf/spec.md`. It has four sections:

| Section | What to check |
|---------|---------------|
| Problem | The command understood the need. |
| Scope | `In` lists the files you expect. `Out` excludes the work you do not want now. |
| Acceptance Criteria | Each condition is testable, and you agree with it. |
| Risks | The blockers are real. |

This is where you steer the change. Fix the spec now, not the code later.

To change the spec, run `/sf:spec` again with your correction. The command asks "Update existing"
or "Create new". `Update existing` replaces the spec. `Create new` archives the old spec and
starts a new one.

## Implement

```
/sf:implement
```

```
Step 1: Learning patterns from codebase...
  Found: src/middleware/auth.ts (similar middleware pattern)

Step 2: Implementing...
  Created: src/middleware/rate-limiter.ts
  Updated: src/middleware/index.ts
  Created: src/middleware/rate-limiter.test.ts

Implementation summary written to .sf/implementation-summary.md
```

The command reads `.sf/spec.md`. It finds the closest pattern in your code first. Then it writes
the change to follow that pattern.

On Claude Code, `/sf:implement --isolate` does the work in a separate git worktree.

## Document

```
/sf:document
```

```
Analysis (parallel): artifacts, implementation, existing docs
Drafting (parallel): technical, user
Integration: merge into the existing docs
```

```
Updated: docs/middleware.md (added rate limiter section)
```

The command edits your existing docs. It creates a file only when no existing file fits. A change
that users cannot see gets no user documentation.

## What to expect

- The steps run in order. The agent does not write code without a spec.
- The spec is your review point. Read it before you run `/sf:implement`.
- The artifacts stay in `.sf/`, so you can read them again or run a command again.
- Each phase costs tokens. [Token Usage](../README.md#token-usage) gives the typical ranges.

## Next steps

- [Rate limiter example](../examples/rate-limiter/) — a spec, an implementation and docs from one
  complete run.
- [Technical Reference](technical-reference.md) — `$SF_DIR`, the scripts and the schemas.
- [Supported hosts](supported-hosts.md) — the skills directory each host reads.
