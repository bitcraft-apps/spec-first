# Technical Reference: Spec First

## Overview

- 3 commands start 13 agent invocations.
- 7 research agents use the Haiku model.
- 5 synthesis and implementation agents use the model of the caller.
- 1 built-in Explore subagent finds patterns.
- All agents write their output to `.sf/research/`. Git ignores this directory.

## Commands

The `skills/` directory defines the commands. Each `SKILL.md` gives the steps and the gates twice: first as one sequential path that any host can run, then as the subagent path under `## On Claude Code`. The subagent path is an optimization.

The steps below are the Claude Code path.

- `/sf:spec [REQUIREMENTS]` runs the research agents in parallel. Then it synthesizes `spec.md`.
- `/sf:implement [SPEC_OR_PATH]` runs the Explore subagent to find patterns. Then it runs `implement-minimal` to write the code.
- `/sf:document [PATHS]` runs the analysis agents in parallel. Then it generates the documents in parallel. Then it integrates the documents into `docs/`.

## Agents

Agent files live in `agents/`. Each file has YAML frontmatter: `name`, `description`, `tools` (required), `model` (optional, only `haiku`), `maxTurns` (optional turn limit). Read the agent files for the details.

## Integration Contracts

### pattern-example.md

In `/sf:implement`, Explore (Step 1) writes `.sf/research/pattern-example.md`. Then `implement-minimal` (Step 2) reads it. The file uses free-form markdown. `skills/implement/SKILL.md` and `agents/implement-minimal.md` refer to it.

### plugin.json

`.claude-plugin/plugin.json` declares the components of the framework: agents, skills, and hooks. `validate-plugin.sh` reads this file to find the component files. This removes the need for separate lists.

Schema:

```json
{
  "name": "string",
  "version": "string (must match VERSION)",
  "description": "string",
  "hooks": "string — relative path to hooks.json"
}
```

Claude Code finds the agents and the skills in their default directories: `agents/` and `skills/`. The manifest does not list them.

**Default behavior:** `validate-plugin.sh` uses hardcoded arrays in three conditions. The manifest is missing. The manifest holds invalid JSON. Or `jq` is not installed.

**Version drift:** `validate-plugin.sh` compares the `plugin.json` version to `VERSION`. If the two versions differ, the validation fails. This check runs only in repository mode.

### marketplace.json

`.claude-plugin/marketplace.json` is the catalog that users search to find the plugin. It makes the command `claude plugin add bitcraft-apps/spec-first` possible.

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

release-please updates the version field in `marketplace.json` and in `plugin.json`. `validate-plugin.sh` checks that the two versions agree.

**Relationship to plugin.json:** `marketplace.json` is the catalog. Users search it to find and install the plugin. `plugin.json` is the manifest. It declares what the plugin provides.

### hooks.json

`hooks/hooks.json` declares hook commands in Claude Code's plugin-native format.

Schema:

```json
{
  "hooks": {
    "<EventName>": [{
      "matcher": "string (optional — glob pattern that selects when the hook runs)",
      "hooks": [{
        "type": "command",
        "command": "string"
      }]
    }]
  }
}
```

Hook commands use `${CLAUDE_PLUGIN_ROOT}` as a path prefix. At run time, Claude Code replaces this prefix with the install directory of the plugin. Thus the hook scripts do not contain absolute paths.

The `Stop` event runs two hooks: validate-spec and validate-implementation. Each hook is an
adapter. It reads the hook JSON, calls the matching script in `scripts/`, and reports a non-zero
exit as a `block` decision. The skills call the same scripts, so hosts without hooks get the
same checks.

## Setup

- Claude Code CLI. `Agent` tool support (`subagent_type`) makes the commands run the steps in parallel. Without it, the skills run the same steps in order.
- Haiku model access for research agents
- LSP is optional. If LSP is not available, `analyze-implementation` uses Grep and Glob.

### Artifact directory

The artifact directory is `$SF_DIR` if you set that variable. If you do not set it, the
directory is `.sf/` in the project root.

`scripts/spec-dir.sh <first|update|new> [sf-dir]` prepares the directory. `first` creates it.
`update` backs up the spec and clears `research/`. `new` archives the spec under
`specs/<timestamp>/` and replaces `spec.md` and `research/` with symlinks. The script reads
the directory from its second argument, then `$SF_DIR`, then the project root.

`scripts/doc-gates.sh <analysis|generation> [sf-dir]` checks that a document batch wrote its
research files. It exits non-zero and prints the reason if a file is missing, or if a generated
doc contains a placeholder marker. The script reads the directory from its second argument,
then `$SF_DIR`, then `.sf` in the current directory.

`scripts/validate-spec.sh [sf-dir]` checks that `spec.md` has a scope, criteria and risks
section. `scripts/validate-implementation.sh [sf-dir]` counts the acceptance criteria that
`spec.md` still has unchecked. Both exit non-zero and print the reason to stderr. Both read the
directory from their first argument, then `$SF_DIR`, then `.sf` in the current directory.

### .gitignore

```gitignore
.sf/
```

This entry keeps SF artifacts out of the repository.

### Validation

```bash
bash scripts/validate-plugin.sh
```

## Cross-References

- [CLAUDE.md](../CLAUDE.md) — framework philosophy and rules
- [CHANGELOG.md](../CHANGELOG.md)
