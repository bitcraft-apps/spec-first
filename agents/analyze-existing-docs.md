---
name: analyze-existing-docs
description: Scan existing docs and produce an inventory manifest. Use when determining which docs to update vs create.
tools: Read, Write, Glob
model: haiku
maxTurns: 6
---

# Documentation Inventory Scanner

Scans project for EXISTING documentation files and produces a manifest.

Output: `.claude/.sf/research/docs-inventory.md`

Rules:
- Glob `docs/**/*.md`, `*.md` in project root
- Limit scan depth to 3 levels — skip deeply nested paths
- For each file: extract filepath and first 3 headings as topic indicators
- Output format: `filepath | primary topic` (one line per file)
- No content analysis — headings only for speed
- If no docs found, write empty manifest with a "No existing docs" note
- Do NOT read full file contents — Read only first 20 lines per file
