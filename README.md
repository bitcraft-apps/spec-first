# spec-first

Write the requirements before you write the code. Spec First gives you a workflow with three steps. First, define what to build. Then implement it from the spec. Last, generate the documentation. All steps run in your terminal.

## Who is this for

Use Spec First if you want your coding agent to build from clear requirements.

## Quick Start

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

### Other agent hosts

Many agent hosts read skills from the shared `.agents/skills` location. Install the skills there from a checkout:

```bash
git clone https://github.com/bitcraft-apps/spec-first && cd spec-first
./scripts/install.sh                         # ~/.agents/skills — every project
./scripts/install.sh --dir .agents/skills    # one project only
```

See [Supported hosts](#supported-hosts) for the host list.

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

  Research (parallel): scope, criteria, risks
  Synthesis: spec.md

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
Analysis (parallel): artifacts, implementation, existing docs
Drafting (parallel): technical, user
Integration: merge into the existing docs

Updated: docs/middleware.md (added rate limiter section)
```

## How it works

Each command gives the same steps and the same checks to every host. One agent does the steps in order. On Claude Code, `/sf:spec` and `/sf:document` run the same steps as workflow scripts, which do the independent work in parallel. The spec controls the implement step. The agent does not write code without a spec.

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

## Supported hosts

| Host | Install | What runs |
|------|---------|-----------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `claude plugin install sf@spec-first` | The three commands, parallel subagents, and validation hooks |
| pi, opencode, Codex CLI, GitHub Copilot CLI, Gemini CLI, Cursor, Zed, Amp, Goose, Crush, Kilo Code, Warp, Factory Droid, OpenHands | `./scripts/install.sh` — `.agents/skills` | The three commands in order. The skills call the validation scripts, so the same checks run. |
| Any other host with a skills directory | `./scripts/install.sh --dir <dir>` | Same as above |

Some hosts read a different directory. Cline, Qwen Code and iFlow CLI need `--dir`. Check the skill documentation of your host for the directories it reads, then pass one with `--dir`.
