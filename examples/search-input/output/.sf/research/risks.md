# Debounced Search Input Risks

## Blockers

### 1. Search On The First Render
**Risk**: A `useEffect` on `value` runs after the first render. The component then searches
for the initial value, which the parent did not ask for.
**Impact**: One wasted request for every mount of the component.
**Solution**: Hold the last searched value in a ref, and start it at the initial `value`.
The effect returns early while the two are equal.

### 2. A Stale Callback In The Timer
**Risk**: The timer holds the `onSearch` from the render that started it. A parent that
passes a new function on every render either fires the old one, or restarts the timer.
**Impact**: The search never runs, or it runs with old state.
**Solution**: Keep `onSearch` in a ref, and update the ref on every render. The effect
depends on `value` and `delay` only.

## Edge Cases

### 1. Unmount With A Pending Timer
**Risk**: The timer fires after React removes the component.
**Solution**: Clear the timer in the cleanup of the effect.

### 2. Delay Of Zero
**Risk**: `delay={0}` looks like "no debounce" but `setTimeout` still waits one tick.
**Solution**: Accept the one tick. Document that `onSearch` runs asynchronously.

### 3. The Clear Button And The Debounce
**Risk**: Clear empties the field, then the debounce delays the empty search by 300 ms.
The old results stay on screen for that time.
**Solution**: Accept it for the MVP. The behavior is the same as a keystroke.

### 4. Accessible Name For The Clear Button
**Risk**: An icon-only button has no name for a screen reader.
**Solution**: Give the button `aria-label="Clear search"` and `type="button"`.

## Assumptions to Validate

- **Controlled only?** The MVP requires `value` and `onChange` from the parent.
- **Who calls the API?** The parent. The component does not fetch.

## Simple MVP Approach

- One `useEffect` with `setTimeout`, cleared in the cleanup
- A ref for `onSearch` to avoid a stale callback
- A ref for the last searched value to skip the first render
- The clear button renders only when `value` is not empty
