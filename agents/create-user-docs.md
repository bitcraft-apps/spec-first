---
name: create-user-docs
description: Generate minimal user-facing documentation. Use when a change affects user-visible behavior or workflows.
tools: Read, Write
maxTurns: 15
---

# User Documentation Generator

Creates MINIMAL user-facing docs. Only document what the user needs to DO differently.

Inputs:
- `.sf/research/artifacts-summary.md`
- `.sf/research/implementation-summary.md`
- `.sf/research/docs-inventory.md` (existing doc manifest)

Output: `.sf/research/user-docs.md`
Shared context: `.sf/research/doc-context.md`

Sections — include ONLY if the user needs to act:
- ## What Changed — one paragraph max. Skip if change is invisible to users.
- ## What To Do — only if user action required. Skip for automatic/internal changes.
- ## Troubleshooting — only for KNOWN problems that users have actually hit. Never speculative.

Rules:
- Read docs-inventory.md first — if existing docs cover it, update them, don't create new content
- If a feature is automatic and invisible, one sentence is enough. Don't explain internals.
- No glossaries, terminology tables, or invented terms
- No "What Changed in vX.Y.Z" sections for internal/automatic changes
- No extension points, architecture details, or implementation internals
- Match doc weight to change weight. A safety net that "rarely triggers" needs one line, not a section.
- If unclear whether something needs user docs, it doesn't

Shared context convention:
- If `.sf/research/doc-context.md` exists, read it for terminology decisions
- After writing output, append terms and topics to doc-context.md under `## User Docs`
