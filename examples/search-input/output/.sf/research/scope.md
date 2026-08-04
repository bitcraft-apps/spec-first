# MVP Scope: Debounced Search Input

## In Scope

### Core Functionality
- One React component, `SearchInput`
- The parent owns the value, so the component is controlled
- `onSearch` runs 300 ms after the last keystroke
- A clear button empties the field
- The clear button shows only when the field has text

### Required Interface
- Props: `value`, `onChange`, `onSearch`, `delay`, `label`
- `onChange` runs on every keystroke, with no delay
- `onSearch` runs one time for a burst of keystrokes
- `delay` overrides the 300 ms default

### Minimum Viable Behavior
- No call to `onSearch` on the first render
- Unmount cancels the pending call
- Keyboard and screen reader users reach the clear button

## Out of Scope (Future Considerations)

### Behavior
- A search icon, a spinner, or a loading state
- Suggestions, autocomplete, or a results dropdown
- Search history or recent searches
- A minimum length before the search starts
- A cancel or abort for the search request itself
- Search on the Enter key before the delay ends

### Presentation
- Styles, themes, or a CSS file
- Size or variant props
- Animation for the clear button

### State
- Internal uncontrolled mode
- URL or storage persistence
- Global state integration

## Acceptance Criteria

1. `onSearch` runs 300 ms after the last keystroke
2. A burst of keystrokes runs `onSearch` one time
3. `onSearch` does not run on the first render
4. The clear button empties the field and searches for the empty string
5. The clear button is absent when the field is empty
6. The field shows the value from the parent

## Non-Functional

- Size: ~45 lines for the component, ~90 lines for the tests
- React 19, TypeScript, no other runtime dependency
- Tests run with vitest and Testing Library
