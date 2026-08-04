# spec-first

Write the requirements before you write the code. Spec First gives you a workflow with three steps. First, define what to build. Then implement it from the spec. Last, generate the documentation. All steps run in your terminal.

## Who is this for

Give an agent a vague prompt, and the agent decides the requirements for you. You find out what it
decided when you read the diff. A wrong decision then costs you the whole change.

Spec First puts the requirements in a file first. You read that file and correct it. The agent
builds from the file you approved.

Use Spec First if you want your coding agent to build from clear requirements.

## Quick Start

On Claude Code, add the marketplace. Then install the plugin:

```bash
claude plugin marketplace add bitcraft-apps/spec-first
claude plugin install sf@spec-first
```

On another host, install the skills with `./scripts/install.sh`. The [host
table](#supported-hosts) below gives the command for each host.

New to Spec First? [Getting Started](docs/getting-started.md) walks through your first spec.

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
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — reads `~/.claude/skills` | `claude plugin install sf@spec-first` | The three commands, parallel subagents, and validation hooks |
| Hosts that read `.agents/skills`: pi, opencode, Codex CLI, GitHub Copilot CLI, Gemini CLI, Cursor, Zed, Amp, Goose, Crush, Kilo Code, Warp, Factory Droid, OpenHands | `./scripts/install.sh` | The three commands in order. The skills call the validation scripts, so the same checks run. |
| Hosts that read their own directory: Cline (`~/.cline/skills`), Qwen Code (`~/.qwen/skills`), iFlow CLI (`~/.iflow/skills`) | `./scripts/install.sh --dir <that directory>` | Same as above |
| Any other host with a skills directory | `./scripts/install.sh --dir <dir>` | Same as above |

[Supported hosts](docs/supported-hosts.md) gives the directory each host reads, the documentation it
came from, and the version it was read at. A host not listed there: check its skill documentation
for the directory it reads, then pass that with `--dir`.
