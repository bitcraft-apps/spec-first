# Technical Reference: Spec First

## Overview

- 3 commands. Each one is a skill that states the steps and the gates for one agent to run in order.
- On Claude Code, `/sf:spec` and `/sf:document` run as workflow scripts, which start 4 and 6
  agents. `/sf:implement` runs the built-in Explore subagent, then `implement-minimal`.
- `agents/` registers 1 subagent. The workflow scripts hold the other prompts, so those agents
  cost no session context.
- Steps that write research output write it to `.sf/research/`. Git ignores this directory. The
  workflows pass results in memory instead.

## Commands

The `skills/` directory defines the commands. Each `SKILL.md` gives the steps and the gates twice: first as one sequential path that any host can run, then as the subagent path under `## On Claude Code`. The subagent path is an optimization.

The steps below are the Claude Code path.

- `/sf:spec [REQUIREMENTS]` runs the `sf-spec` workflow. The workflow researches scope, criteria and risks in parallel, then writes `spec.md`.
- `/sf:implement [SPEC_OR_PATH]` runs the Explore subagent to find patterns. Then it runs `implement-minimal` to write the code.
- `/sf:document [PATHS]` runs the `sf-document` workflow. The workflow analyzes the change, drafts the documents, then integrates them into `docs/`.

### Every skill runs inline

Skill frontmatter accepts `context: fork`, which runs the skill in a subagent. No sf skill sets
it. Each of the three stops to ask the user a question: `/sf:spec` asks about vague requirements
and about update-or-new, `/sf:implement` asks where the specification is, and `/sf:document`
asks where the artifacts are. A fork cannot ask, and by default it reports back as a background
task instead of holding the turn. So all three stay inline, and they hand the parallel work to
a workflow instead.

## Agents

Agent files live in `agents/`. Each file has YAML frontmatter: `name`, `description`, `tools` (required), `model` (optional, only `haiku`), `maxTurns` (optional turn limit). Read the agent files for the details.

`agents/` holds `implement-minimal` only. A registered subagent appears in the agent inventory
of every session that has the plugin installed, used or not. An agent a workflow script starts
needs no registration, so every prompt the workflows own lives in the script instead.

### Model and effort routing

| Agent | Model | Effort |
| --- | --- | --- |
| `scope`, `criteria`, `risks` in `sf-spec` | caller/host policy | `low` |
| `artifacts`, `implementation`, `inventory` in `sf-document` | caller/host policy | `low` |
| `synthesize-spec` in `sf-spec` | the caller's | the caller's |
| `technical-docs`, `user-docs`, `integrate-docs` in `sf-document` | the caller's | the caller's |
| `implement-minimal` | the caller's | the caller's |

The six extraction agents produce short structured output from text they are given at low effort.
They inherit the caller's or host's model policy and do not require Haiku access. The others make
judgment calls about what to build and what to write. They inherit the caller's tier, because that
tier is the user's choice for the session. A named tier would downgrade a user on Opus and raise
the bill for a user on Haiku.

`effort` accepts `low`, `medium`, `high`, `xhigh`, `max`, or an integer.

### Fields to leave out

- `permissionMode`, `hooks` and `mcpServers` do nothing in a plugin agent file. Claude Code
  logs a warning and points to `.claude/agents/` for that level of control.
- `isolation: worktree` is valid frontmatter, but it is static. `--isolate` is a per-run flag,
  so `/sf:implement` passes `isolation` to the Agent tool instead.
- `skills` preloads a skill into a subagent. No agent needs it: `sf-spec` passes the template
  path in `args`, and the synthesis agent reads the file.

## Workflows

Workflow scripts live in `workflows/`. Claude Code loads them from that directory, so the
manifest does not list them. Each file must end in `.js`, and `export const meta = {...}` must
be its first statement. A script has no filesystem access: every file write happens inside an
agent, and the skill runs the gate scripts after the workflow returns.

The **Workflow** tool finds a script by its `meta.name`, without a plugin prefix. Names carry
the `sf-` prefix for that reason.

### sf-spec

`workflows/spec.js`. Arguments:

```json
{
  "requirements": "string — what to specify",
  "specPath": "string — where to write spec.md",
  "templatePath": "string — the spec-template.md to follow"
}
```

Returns `{ specPath, criteria, risks }`, where the last two are counts. The three research
agents return validated objects, so this path writes no files under `research/`.

### sf-document

`workflows/document.js`. Arguments — one of the two paths is enough:

```json
{
  "specPath": "string — the spec or other artifact to read",
  "implementationPath": "string — the implementation summary to read"
}
```

Returns `{ changed }`, the list of documentation files written or edited. An empty list means
the change needs no documentation. On a failure it returns `{ error }` and integrates nothing.

The workflow applies both gates that `doc-gates.sh` applies for other hosts: the schemas take
the place of the analysis gate, and a placeholder-marker test on each draft takes the place of
the generation gate.

## Integration Contracts

### pattern-example.md

In `/sf:implement`, Explore (Step 1) writes `.sf/research/pattern-example.md`. Then `implement-minimal` (Step 2) reads it. The file uses free-form markdown. `skills/implement/SKILL.md` and `agents/implement-minimal.md` refer to it.

### plugin.json

`.claude-plugin/plugin.json` is the plugin manifest. It holds the name, the version and the
metadata. It does not list components.

Schema:

```json
{
  "$schema": "string — https://anthropic.com/claude-code/plugin.schema.json",
  "name": "string",
  "version": "string (must match VERSION)",
  "description": "string",
  "author": { "name": "string", "url": "string" },
  "repository": "string",
  "homepage": "string",
  "license": "string",
  "keywords": ["string"]
}
```

Claude Code finds every component in its default directory: `agents/`, `skills/` and
`hooks/hooks.json`. `validate-plugin.sh` finds them the same way.

`claude plugin validate --strict .claude-plugin/plugin.json` checks the manifest. CI runs it,
so an unrecognized field or missing metadata fails the build instead of the install.

**Version drift:** `validate-plugin.sh` compares the `plugin.json` version to `VERSION`. If the two versions differ, the validation fails. This check runs only in repository mode.

### marketplace.json

`.claude-plugin/marketplace.json` is the catalog that users search to find the plugin. It makes the command `claude plugin add bitcraft-apps/spec-first` possible.

Schema:

```json
{
  "name": "string (marketplace identifier)",
  "description": "string — what the marketplace offers",
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
same checks. The skills do not pre-approve these scripts, so the host asks for permission the
first time each one runs.

## Setup

- A host that reads skills from `.agents/skills`, or from a directory you pass to
  `scripts/install.sh --dir`. [Supported hosts](supported-hosts.md) gives the directory each host
  reads. On Claude Code, install the plugin instead.
- A shell. The skills call the scripts in `scripts/`.
- Subagents are optional. `Agent` tool support (`subagent_type`) makes the commands run the steps
  in parallel. Without it, the skills run the same steps in order.
- Hooks are optional. Only Claude Code loads `hooks/hooks.json`. The skills call the same scripts.
- Workflow research agents inherit the caller's or host's model policy and do not require Haiku access
- LSP is optional. Without it, the implementation analysis in `sf-document` uses Grep and Glob.

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

- [AGENTS.md](../AGENTS.md) — framework philosophy and rules
- [CHANGELOG.md](../CHANGELOG.md)
