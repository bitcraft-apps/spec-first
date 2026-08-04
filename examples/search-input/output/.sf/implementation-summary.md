# Implementation Summary: Debounced Search Input

## Files Created

- `SearchInput.tsx` — the component and the `SearchInputProps` type
- `SearchInput.test.tsx` — 9 vitest tests, all acceptance criteria plus the delay prop
- `vitest.config.ts` — React plugin, `jsdom` environment
- `tsconfig.json` — strict mode, `react-jsx`
- `package.json` — react, react-dom, vitest, Testing Library, typescript

No existing patterns found - used minimal approach. The project held only `package.json`,
so the code follows the React and vitest defaults.

## Acceptance Criteria Status

- [x] `onSearch` runs 300 ms after the last keystroke, with the final value
- [x] A burst of five keystrokes runs `onSearch` one time
- [x] `onSearch` does not run on the first render
- [x] `onChange` runs on every keystroke, with no delay
- [x] The clear button calls `onChange` and then `onSearch` with the empty string
- [x] The clear button is absent when `value` is empty
- [x] The field shows the `value` from the parent
- [x] Unmount before the delay cancels the call

## Design Decisions

- `onSearchRef` holds the callback, so the timer never calls an old one
- `searched` ref starts at the initial `value`, which stops the search on the first render
- The effect depends on `value` and `delay` only, and clears the timer in its cleanup
- The clear button calls `onChange("")`. The empty search then waits for the delay.
- `type="search"` gives the field the `searchbox` role, so the tests need no test id
