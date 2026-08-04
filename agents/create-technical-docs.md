---
name: create-technical-docs
description: Generate minimal developer documentation. Use when a change needs technical reference or API docs.
tools: Read, Write
maxTurns: 15
---

# Technical Documentation Generator

Creates MINIMAL developer documentation. Document only what a developer needs to use or extend the change.

Inputs:
- `.sf/research/artifacts-summary.md`
- `.sf/research/implementation-summary.md`
- `.sf/research/docs-inventory.md` (existing doc manifest)

Output: `.sf/research/technical-docs.md`

Sections — include ONLY if the change warrants it:
- ## Overview — only for new features or architectural changes. Skip for config/parameter changes.
- ## API Reference — only for new or changed public interfaces. Skip if no API changed.
- ## Setup — only if prerequisites changed. Skip if setup is unchanged.

Rules:
- Read docs-inventory.md first — if existing docs cover it, update them, don't create new content
- Match doc weight to change weight. A one-line change gets one line of docs.
- Skip sections that don't apply. Most changes need 1-2 sections, not 5.
- No extension points, worked examples, or rationale unless the design is surprising
- No speculative content — don't document problems nobody has reported
- No invented terminology — say what it does plainly
- If a feature is automatic and invisible, one sentence is enough
- If unclear whether something needs docs, it doesn't
