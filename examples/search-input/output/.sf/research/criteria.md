# Acceptance Criteria: Debounced Search Input

## Must Pass

1. **`onSearch` waits for the delay**
   - Type `abc` → `onSearch` has no calls after 299 ms
   - Advance to 300 ms → `onSearch` has one call, with `abc`

2. **A burst of keystrokes searches one time**
   - Type five characters, 50 ms apart → `onSearch` has one call
   - The call holds the final value, not an earlier one

3. **No search on the first render**
   - Render with `value="shoes"` → `onSearch` has no calls after 300 ms

4. **`onChange` runs on every keystroke**
   - Type three characters → `onChange` has three calls
   - `onChange` runs before the delay ends

5. **The clear button clears and searches**
   - Click clear → `onChange` runs with the empty string
   - After the delay → `onSearch` runs with the empty string

6. **The clear button follows the value**
   - `value=""` → no clear button in the document
   - `value="shoes"` → a button with the accessible name "Clear search"

7. **The parent owns the value**
   - Render with `value="shoes"` → the field shows `shoes`
   - The parent does not update the value → the field text does not change

## Edge Cases (Must Not Fail)

- Unmount before the delay ends → no call to `onSearch`, no warning
- A new `delay` prop → the next keystroke uses the new delay
- `delay={0}` → `onSearch` runs on the next tick

## Definition of Done

All 7 "Must Pass" criteria pass in `SearchInput.test.tsx`. Fake timers control the delay.
