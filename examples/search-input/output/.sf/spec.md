# Debounced Search Input — controlled React component, one search per typing burst

## Problem

The search field calls the API on every keystroke. A five letter word sends five requests,
and the results flicker as the answers arrive out of order. The field needs to wait until
the user stops typing.

## Scope

### In

- `SearchInput.tsx` (~45 lines) — the component
  - Props: `value`, `onChange`, `onSearch`, `delay` (default 300), `label`
  - `onChange` runs on every keystroke, so the parent owns the value
  - `onSearch` runs once, `delay` ms after the last keystroke
  - No call to `onSearch` on the first render
  - Clear button, shown only when `value` is not empty, `aria-label="Clear search"`
  - Unmount cancels the pending call
- `SearchInput.test.tsx` (~90 lines) — tests with vitest fake timers

### Out

- Uncontrolled mode, or state inside the component
- Fetching, request cancellation, or a loading state
- Suggestions, autocomplete, or a results list
- Styles, icons, or animation
- Search on the Enter key before the delay ends
- A minimum query length

## Acceptance Criteria

- [x] `onSearch` runs 300 ms after the last keystroke, with the final value
- [x] A burst of five keystrokes runs `onSearch` one time
- [x] `onSearch` does not run on the first render
- [x] `onChange` runs on every keystroke, with no delay
- [x] The clear button calls `onChange` and then `onSearch` with the empty string
- [x] The clear button is absent when `value` is empty
- [x] The field shows the `value` from the parent
- [x] Unmount before the delay cancels the call

## Risks

1. **Search on the first render** — hold the last searched value in a ref.
2. **Stale `onSearch` in the timer** — hold the callback in a ref, update it every render.
3. **Timer fires after unmount** — clear the timer in the effect cleanup.
4. **`delay={0}` still waits one tick** — accepted. Document the asynchronous call.
