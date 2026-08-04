# Implementation Summary

## Files
- `SearchInput.tsx` (55 lines) — one function component, one exported type
- `SearchInput.test.tsx` (123 lines) — 9 vitest tests with fake timers
- `vitest.config.ts` (7 lines) — React plugin, `jsdom` environment
- `tsconfig.json` (13 lines) — strict mode, `react-jsx`, no emit
- `package.json` — `npm test` runs vitest, `npm run typecheck` runs tsc

## Public API

**`SearchInput(props: SearchInputProps)`**

```typescript
type SearchInputProps = {
  value: string;
  onChange: (value: string) => void;
  onSearch: (value: string) => void;
  delay?: number;  // default 300
  label?: string;  // default "Search"
};
```

Renders a `div` that holds an `input` with `type="search"`, and a clear button when
`value` is not empty. The field takes `label` as its `aria-label`. The button has
`aria-label="Clear search"`.

## Design Decisions
- Two refs: `onSearchRef` for the current callback, `searched` for the last searched value
- `searched` starts at the initial `value`, so the first render does not search
- One `useEffect` on `[value, delay]` with `setTimeout`, cleared in the cleanup
- The clear button calls `onChange("")`, so the empty search also waits for the delay
- No internal state. The component holds no copy of the query.

## Test Coverage
All 8 acceptance criteria have tests. One more test covers a `delay` of 1000 ms.
