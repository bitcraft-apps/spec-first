# Artifacts Summary

**Project**: Debounced Search Input — controlled React component, one search per typing burst

## Requirements
- One controlled React component, `SearchInput`
- The parent owns the value and passes `value` and `onChange`
- `onSearch` runs once, `delay` ms after the last keystroke, default 300
- `onChange` runs on every keystroke, with no delay
- No call to `onSearch` on the first render
- A clear button, shown only when the field has text
- Unmount cancels the pending call

## Acceptance Criteria (All Passed)
1. `onSearch` runs 300 ms after the last keystroke, with the final value
2. A burst of five keystrokes runs `onSearch` one time
3. `onSearch` does not run on the first render
4. `onChange` runs on every keystroke, with no delay
5. The clear button calls `onChange` and then `onSearch` with the empty string
6. The clear button is absent when `value` is empty
7. The field shows the `value` from the parent
8. Unmount before the delay cancels the call

## Scope Boundaries
- **In**: the component, the debounce, the clear button, unit tests
- **Out**: uncontrolled mode, fetching, loading state, suggestions, styles,
  search on the Enter key, a minimum query length

## Risks
1. Search on the first render → a ref holds the last searched value
2. A stale `onSearch` in the timer → a ref holds the callback
3. The timer fires after unmount → the effect cleanup clears it
4. `delay={0}` still waits one tick → documented
