# AGENTS.md

Spec First — minimalist development workflow.

## Core Philosophy

**Build the smallest thing that works.** Challenge assumptions. Deliver incrementally.

## Principles

- **YAGNI**: Don't build it until you need it
- **KISS**: Simplest solution that works
- **SRP**: Each component does one thing
- **MVP First**: Deliver narrowest viable change

## Anti-Patterns

- Enterprise solutions without justification
- Blind pattern following
- Assumptions without clarification
- Features without immediate need
- Complexity without clear value

## Size Constraints

- Agents: 50 lines max
- Skills: 75 lines max
- Workflow scripts: 200 lines max
- Self-documenting through clear naming

## Development Checklist

1. **Can it be smaller?** → Make it smaller
2. **Is it needed now?** → If no, skip it
3. **Does it assume?** → Make it ask instead
4. **Is it complex?** → Simplify or remove
5. **Does it work?** → Ship it, iterate later

## Documentation Rules

1. **Minimum viable docs.** Document what the user needs to know. If a feature is automatic and invisible, one sentence is enough.
2. **No duplication.** Agent files are the source of truth for agent details. Do not re-list agent names, tools, or descriptions in docs that readers can find in `agents/`.
3. **No speculative content.** Do not add troubleshooting for problems nobody has reported. Do not document rationale unless the design is surprising.
4. **Proportional to the change.** A one-line config change does not need a new section, glossary entries, ASCII diagrams, or worked examples. Match doc weight to change weight.
5. **No branding internal mechanics.** Do not invent terms for simple concepts. Say what it does plainly.
6. **User guide = user actions only.** If the user doesn't need to do anything, don't explain the internals.
7. **Technical reference = contract surface.** Document interfaces and schemas. Do not duplicate orchestration flows already defined in skill files.

## PR Rules

1. **Every PR must reference a GitHub issue.** Use `Closes #<number>` in the PR body to auto-close the issue on merge. If no issue exists, create one first.

## Code Rules

1. **YAGNI, KISS, SRP** — always.
2. **No validation for things that can't go wrong.** Trust internal contracts.
3. **No abstractions for one-off operations.**

## Writing style

English prose — docs, code comments, commit and PR text, issues, user-visible strings —
follows [Simplified Technical English](https://www.asd-ste100.org/) (ASD-STE100): one
meaning per word, active voice, imperative for instructions, simple tenses, one
instruction per sentence (max 20 words), no jargon or metaphor. Code identifiers are exempt.
