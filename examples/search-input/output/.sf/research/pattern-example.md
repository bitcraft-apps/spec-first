# Pattern Example: none found

The project holds `package.json` and the installed dependencies. It has no components, no
tests and no build config.

Searched for:
- `*.tsx`, `*.jsx` — no results
- `*.test.*`, `__tests__/` — no results
- `tsconfig.json`, `vite.config.*`, `vitest.config.*` — no results

## Chosen conventions

No pattern exists, so the implementation follows the React and vitest defaults:

- One named export for each file, no default export
- A `Props` type above the component, props destructured in the signature
- `vitest.config.ts` with the React plugin and the `jsdom` environment
- Tests next to the component, as `SearchInput.test.tsx`
- `vi.useFakeTimers()` for the delay, and `act` to advance it
