# Example: Rate Limiter

Build a token-bucket rate limiter using the spec-first workflow.

## 1. Write the spec

```
/sf:spec
```

Describe what you need:

> Token-bucket rate limiter. 100 requests per minute per API key.
> Returns 429 when exceeded. Configurable burst allowance.

Review the generated spec, then proceed to implementation.

## 2. Implement

```
/sf:implement
```

Generates working code from the spec, following existing patterns in your codebase.

## 3. Document

```
/sf:document
```

Produces user-facing and technical docs based on the implementation.

## What to expect

Each command runs autonomously. Review the output, iterate if needed.
The workflow is sequential: **spec > implement > document**.

## Generated Output

The [`output/`](output/) directory contains the complete result of running this workflow end-to-end:

**Deliverables:**
- [`rate-limiter.ts`](output/rate-limiter.ts) — token-bucket implementation
- [`rate-limiter.test.ts`](output/rate-limiter.test.ts) — tests
- [`rate-limiter-middleware.ts`](output/rate-limiter-middleware.ts) — HTTP middleware
- [`docs.md`](output/docs.md) — user-facing documentation

**Pipeline artifacts** ([`output/.sf/`](output/.sf/)):
- [`spec.md`](output/.sf/spec.md) — specification
- [`research/`](output/.sf/research/) — scope, criteria, risks, doc drafts
- [`implementation-summary.md`](output/.sf/implementation-summary.md) — what implement produced

Generated on 2026-03-16 by running `/sf:spec` → `/sf:implement` → `/sf:document` sequentially.
