# Pattern Example: none found

The project holds `package.json` and the installed dependencies. It has no source files, no
tests and no build config.

Searched for:
- `*.ts` outside `node_modules` — no results
- `*.test.ts`, `*.spec.ts`, `test/` — no results
- `tsconfig.json`, `vitest.config.*` — no results

## Chosen conventions

No pattern exists, so the implementation follows the TypeScript and vitest defaults:

- Named exports, no default export
- An exported `interface` for the configuration, a `class` for the state
- `.js` in the import path, which the ES module resolution needs
- Tests next to the source, as `rate-limiter.test.ts`
- `vi.useFakeTimers()` for the clock, and `vi.advanceTimersByTime` to move it
