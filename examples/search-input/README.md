# Example: Debounced Search Input

Build a React component with the spec-first workflow.

## 1. Write the spec

```
/sf:spec
```

Describe what you need:

> Debounced search input component for React. Call onSearch 300 ms after typing stops.
> Show a clear button. Keep the field controlled by the parent.

Review the generated spec, then proceed to implementation.

## 2. Implement

```
/sf:implement
```

Generates working code from the spec, following existing patterns in your codebase.
This project held only `package.json`, so the code follows the React and vitest defaults.

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
- [`SearchInput.tsx`](output/SearchInput.tsx) — the controlled component
- [`SearchInput.test.tsx`](output/SearchInput.test.tsx) — 9 tests, run with `npm test`
- [`vitest.config.ts`](output/vitest.config.ts) — vitest with the `jsdom` environment
- [`docs.md`](output/docs.md) — user-facing documentation

**Pipeline artifacts** ([`output/.sf/`](output/.sf/)):
- [`spec.md`](output/.sf/spec.md) — specification
- [`implementation-summary.md`](output/.sf/implementation-summary.md) — what implement produced
- [`research/`](output/.sf/research/) — the analysis behind each step

Generated on 2026-08-04 by running `/sf:spec` → `/sf:implement` → `/sf:document` sequentially.
