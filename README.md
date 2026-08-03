# spec-first

Write the requirements before you write the code. This Claude Code plugin gives you a workflow with three steps. First, define what to build. Then implement it from the spec. Last, generate the documentation. All steps run in your terminal.

## Who is this for

Use this plugin if you want Claude Code to build from clear requirements.

## Quick Start

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

### Other agent hosts

Many agent hosts read skills from the shared `.agents/skills` location. Install the skills there from a checkout:

```bash
git clone https://github.com/bitcraft-apps/spec-first && cd spec-first
./scripts/install.sh                         # ~/.agents/skills — every project
./scripts/install.sh --dir .agents/skills    # one project only
```

Hosts that read this location include pi, opencode, Codex CLI, GitHub Copilot CLI and Gemini CLI. More hosts add support over time. Check the skill documentation of your host for the directories it reads, then pass one with `--dir`.

A checkout installs by symlink. A downloaded release installs by copy. To remove the skills, delete them:

```bash
rm -rf ~/.agents/skills/{spec,implement,document}
```

Write your first spec:

```
/sf:spec Add a rate limiter to the API gateway
```

```
Researching requirements...

  Batch 1 (parallel): define-scope, create-criteria, identify-risks
  Batch 2: synthesize-spec

Spec written to .sf/spec.md
```

Implement it:

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

Document it:

```
/sf:document
```

```
Batch 1 (parallel): analyze-artifacts, analyze-implementation, analyze-existing-docs
Batch 2 (parallel): create-technical-docs, create-user-docs
Batch 3: integrate-docs

Updated: docs/middleware.md (added rate limiter section)
```

## How it works

Each command starts specialized agents. The agents run in parallel when possible. On a host without subagents, one agent does the same steps in order. The spec controls the implement step. Claude Code does not write code without a spec.

## Token Usage

The table shows the typical range for each phase. The example is a small CLI tool with approximately 500 lines.

| Phase | Input tokens | Output tokens |
|-------|-------------|---------------|
| spec | 10k–30k | 2k–6k |
| implement | 30k–120k | 5k–30k |
| document | 20k–60k | 3k–10k |

Your token counts change with the size of the codebase, the complexity of the feature, and the number of iterations. For current prices, see [Claude pricing](https://www.anthropic.com/pricing).

## Command Reference

| Command | Purpose |
|---------|---------|
| `/sf:spec [REQUIREMENTS]` | Define what to build and why |
| `/sf:implement [--isolate] [SPEC_OR_PATH]` | Build the minimal working solution |
| `/sf:document [PATHS]` | Generate documentation for the change |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
