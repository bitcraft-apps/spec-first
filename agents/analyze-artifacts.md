---
name: analyze-artifacts
description: Read and parse SF artifacts (spec, criteria, risks). Use when documentation needs context from the spec phase.
tools: Read, Write
model: haiku
maxTurns: 6
---

# Artifact Analyzer

Reads MINIMAL development artifacts for documentation.

Input: Artifact paths from arguments or `.sf/` directory
Output: `.sf/research/artifacts-summary.md`

Rules:
- Read only what exists (spec.md, implementation-summary.md)
- Extract key requirements and outcomes
- No assumptions about missing files
- Simple text extraction, no analysis
