# Supported hosts

Which skills directory each host reads, and where that claim comes from.

Every row is read from the host's own skill documentation or its source, not from a convention. A
row is a claim about one version. Hosts change their load paths, so a row goes stale: GitHub
Copilot CLI 0.0.346 had no skills feature at all, while 1.0.78 reads `~/.agents/skills`. Re-read
the source before trusting an old row.

This table says which directory a host reads. It does not say that the sf skills load there. That
check runs by hand before a release — see [Host Skill Loading Check](../tests/README.md#host-skill-loading-check).

## Hosts that read `.agents/skills`

`./scripts/install.sh` with no arguments installs into `~/.agents/skills`, which these hosts read.

| Host | Global directory | Project directory | Source | Version | Checked |
|------|------------------|-------------------|--------|---------|---------|
| pi | `~/.agents/skills/` | `.agents/skills/` | [docs/skills.md](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/skills.md) | 0.83.0 | 2026-08-04 |
| opencode | `~/.agents/skills/` | `.agents/skills/` | [opencode.ai/docs/skills](https://opencode.ai/docs/skills/) | 1.18.13 | 2026-08-04 |
| Codex CLI | `$HOME/.agents/skills` | `.agents/skills` in cwd, parents and repo root | [learn.chatgpt.com/docs/build-skills](https://learn.chatgpt.com/docs/build-skills) | 0.146.0 | 2026-08-04 |
| GitHub Copilot CLI | `~/.agents/skills` | `.agents/skills` | [docs.github.com — about agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) | 1.0.78 | 2026-08-04 |
| Gemini CLI | `~/.agents/skills/` | `.agents/skills/` | [geminicli.com/docs/cli/skills](https://geminicli.com/docs/cli/skills/) | 0.53.1 | 2026-08-04 |
| Cursor | `~/.agents/skills/` | `.agents/skills/` | [cursor.com/docs/context/skills](https://cursor.com/docs/context/skills) | undated docs | 2026-08-04 |
| Zed | `~/.agents/skills/` | `<worktree>/.agents/skills/` | [zed.dev/docs/ai/skills](https://zed.dev/docs/ai/skills) | v1.13.2 | 2026-08-04 |
| Amp | `~/.agents/skills/` | `.agents/skills/` | [ampcode.com/manual#agent-skills](https://ampcode.com/manual#agent-skills) | 0.0.1785846794 | 2026-08-04 |
| Goose | `~/.agents/skills/` | `.agents/skills/` | [using-skills.md](https://github.com/block/goose/blob/main/documentation/docs/guides/context-engineering/using-skills.md) | v1.45.0 | 2026-08-04 |
| Crush | `~/.agents/skills` | `.agents/skills` | [internal/config/load.go](https://github.com/charmbracelet/crush/blob/v0.88.0/internal/config/load.go) | v0.88.0 | 2026-08-04 |
| Kilo Code | `~/.agents/skills` | `.agents/skills/` | [kilo.ai/docs/customize/skills](https://kilo.ai/docs/customize/skills), [src/skill/index.ts](https://github.com/Kilo-Org/kilocode/blob/main/packages/opencode/src/skill/index.ts) | v7.4.20 | 2026-08-04 |
| Warp | `~/.agents/skills/` | `.agents/skills/` | [docs.warp.dev — skills](https://docs.warp.dev/agent-platform/capabilities/skills/) | undated docs | 2026-08-04 |
| Factory Droid | `~/.agents/skills/**/SKILL.md` | `<repo>/.agents/skills/**/SKILL.md` | [docs.factory.ai/cli/configuration/skills](https://docs.factory.ai/cli/configuration/skills) | 0.187.0 | 2026-08-04 |
| OpenHands | `~/.agents/skills/` | `.agents/skills/` | [docs.openhands.dev/overview/skills](https://docs.openhands.dev/overview/skills) | v1.9.0 | 2026-08-04 |

Notes on individual rows:

- **Crush** documents `~/.config/crush/skills` and `~/.config/agents/skills` only. `~/.agents/skills`
  is in the source, added for the Agent Skills spec
  ([issue #2072](https://github.com/charmbracelet/crush/issues/2072), closed 2026-01-31), so the
  source is cited instead of the docs.
- **Kilo Code** documents `.agents/skills/` as a project compatibility directory and `~/.kilo/skills/`
  as the global one. The global `~/.agents/skills` scan is in the source, so both are cited.
- **Cursor** and **Warp** publish undated documentation with no version, so the version column
  cannot be filled. Both were read on the date shown.

## Hosts that read somewhere else

Pass the directory with `--dir`. `install.sh` creates the directory if it is missing.

| Host | Global directory | Install | Source | Version | Checked |
|------|------------------|---------|--------|---------|---------|
| Claude Code | `~/.claude/skills` | `claude plugin install sf@spec-first` — use the plugin, not `install.sh` | [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills) | 2.1.220 | 2026-08-04 |
| Cline | `~/.cline/skills` | `./scripts/install.sh --dir ~/.cline/skills` | [docs.cline.bot/customization/skills](https://docs.cline.bot/customization/skills) | v4.1.3 | 2026-08-04 |
| Qwen Code | `~/.qwen/skills` | `./scripts/install.sh --dir ~/.qwen/skills` | [docs/users/features/skills.md](https://github.com/QwenLM/qwen-code/blob/main/docs/users/features/skills.md) | 0.21.5 | 2026-08-04 |
| iFlow CLI | `~/.iflow/skills` | `./scripts/install.sh --dir ~/.iflow/skills` | [platform.iflow.cn — skill](https://platform.iflow.cn/en/cli/examples/skill) | 0.5.19 | 2026-08-04 |

Claude Code reads `~/.claude/skills`, so `install.sh --dir ~/.claude/skills` would work, but the
plugin also brings the hooks and the parallel workflows. Install the plugin.

## A host that is not listed

Read the skill documentation of the host, find the directory it reads, and pass it:

```bash
./scripts/install.sh --dir <that directory>
```

The [Agent Skills client showcase](https://agentskills.io/clients) lists products that implement the
standard. It does not give their directories, so check the host's own documentation.
