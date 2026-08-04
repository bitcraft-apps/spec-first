# SearchInput — Technical Docs

## Props

```typescript
import { SearchInput, type SearchInputProps } from "./SearchInput";

type SearchInputProps = {
  value: string;                        // the query, owned by the parent
  onChange: (value: string) => void;    // runs on every keystroke
  onSearch: (value: string) => void;    // runs delay ms after the last keystroke
  delay?: number;                       // default 300
  label?: string;                       // accessible name, default "Search"
};
```

## Behavior

- `onChange` runs for every keystroke, and for a click on the clear button.
- `onSearch` runs one time for each burst of keystrokes, with the final value.
- `onSearch` never runs for the initial `value`. The first render starts no timer.
- A new `value` restarts the timer. The old timer is cleared.
- Unmount clears the timer, so `onSearch` does not run after React removes the component.
- `onSearch` may change on every render. The component reads the current one when the
  timer fires, so the parent needs no `useCallback`.
- `delay={0}` still waits one tick. The call is always asynchronous.

## Markup

```html
<div>
  <input type="search" value="…" aria-label="Search" />
  <button type="button" aria-label="Clear search">×</button>
</div>
```

The field has the `searchbox` role, and `label` gives it its accessible name. The clear
button renders only when `value` is not empty. The component has no styles and no visible
label, so the caller adds them.

## Extend it

- Search on the Enter key: add `onKeyDown` and call `onSearch(value)` at once.
- A minimum length: return early in the effect when `value.length` is too small.
- A loading state: the parent owns it, because the parent runs the search.

## Constraints

- Controlled only. The component holds no state, so `value` and `onChange` are required.
- React 19 with the `react-jsx` transform.
- Tests need fake timers. Advance them inside `act` to flush the effect.
