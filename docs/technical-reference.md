# Technical Reference: Spec First

## Overview

3 commands orchestrate 13 agent invocations. 7 research agents run on Haiku; 5 synthesis/implementation agents use the caller's model. 1 built-in Explore subagent handles pattern discovery. All output goes to `.claude/.sf/research/` (gitignored).

## Commands

Commands are defined as skills in `skills/`. Each `SKILL.md` is the source of truth for agent orchestration, batching, and gates.

- `/sf:spec [REQUIREMENTS]` — parallel research → synthesis into `spec.md`
- `/sf:implement [SPEC_OR_PATH]` — Explore subagent for patterns → `implement-minimal` for code
- `/sf:document [PATHS]` — parallel analysis → parallel doc generation → integration into `docs/`

## Agents

Agent files live in `agents/`. Each has YAML frontmatter: `name`, `description`, `tools` (required), `model` (optional, only `haiku`), `maxTurns` (optional turn limit). See agent files for details — they are the source of truth.

## Integration Contracts

### pattern-example.md

`.claude/.sf/research/pattern-example.md` is the handoff between Explore (Step 1) and `implement-minimal` (Step 2) in `/sf:implement`. Free-form markdown. Referenced in `skills/implement/SKILL.md` and `agents/implement-minimal.md`.

### plugin.json

`.claude-plugin/plugin.json` declares the framework's component inventory: agents, skills, and hooks. `validate-plugin.sh` reads it to enumerate files instead of maintaining separate lists.

Schema:

```json
{
  "name": "string",
  "version": "string (must match VERSION)",
  "description": "string",
  "hooks": "string — relative path to hooks.json"
}
```

Agents and skills use default directory auto-discovery (`agents/`, `skills/`) and are not listed in the manifest.

**Fallback behavior:** If the manifest is missing, invalid JSON, or `jq` is not installed, `validate-plugin.sh` falls back to hardcoded arrays.

**Version drift:** `validate-plugin.sh` checks that `plugin.json` version matches `VERSION` and fails validation if they differ. This check only runs in repository mode.

### marketplace.json

`.claude-plugin/marketplace.json` — marketplace catalog for plugin discovery. Enables `claude plugin add bitcraft-apps/spec-first`.

Schema:

```json
{
  "name": "string (marketplace identifier)",
  "owner": { "name": "string" },
  "plugins": [{
    "name": "string (plugin identifier)",
    "source": { "source": "github", "repo": "owner/repo" },
    "description": "string",
    "version": "string (must match VERSION)"
  }]
}
```

Plugin version is auto-synced by release-please alongside `plugin.json`. `validate-plugin.sh` checks consistency.

**Relationship to plugin.json:** `marketplace.json` is the catalog (how users discover and install the plugin). `plugin.json` is the manifest (what the plugin provides). Both have version fields kept in sync automatically.

### hooks.json

`hooks/hooks.json` declares hook commands in Claude Code's plugin-native format.

Schema:

```json
{
  "hooks": {
    "<EventName>": [{
      "matcher": "string (optional — glob pattern for SubagentStop)",
      "hooks": [{
        "type": "command",
        "command": "string"
      }]
    }]
  }
}
```

Hook commands use `${CLAUDE_PLUGIN_ROOT}` as a path prefix. Claude Code resolves this to the plugin's install directory at runtime, so hook scripts do not contain absolute paths.

Current events: `Stop` (2 hooks: validate-spec, validate-implementation), `SubagentStop` (1 hook: validate-subagent, matcher `*`).

## Setup

- Claude Code CLI with `Agent` tool support (`subagent_type`)
- Haiku model access for research agents
- LSP is optional — `analyze-implementation` falls back to Grep/Glob

### .gitignore

```gitignore
.sf/
.claude/.sf/
```

Both entries prevent SF artifacts from being committed.

### Validation

```bash
bash scripts/validate-plugin.sh
```

## Cross-References

- [CLAUDE.md](../CLAUDE.md) — framework philosophy and rules
- [CHANGELOG.md](../CHANGELOG.md)
