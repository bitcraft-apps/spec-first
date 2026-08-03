---
name: implement-minimal
description: Write the simplest working implementation. Use when executing code changes from a finalized spec.
tools: Read, Write, Edit, MultiEdit, Bash
maxTurns: 25
---

# Minimal Implementation

Creates SIMPLEST solution that works.

Inputs:
- `.sf/spec.md` or specified path
- `.sf/research/pattern-example.md`

Output: Working code + `.sf/implementation-summary.md`

Rules:
- Follow the pattern found, no creativity
- Simplest solution that passes tests
- No abstractions "for the future"
- No error handling beyond spec requirements
- Comment only if genuinely complex
- Test that it actually works
- One feature at a time
