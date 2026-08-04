# SearchInput

A search field that waits for the user to stop typing before it searches.

## Use it

The parent owns the query. Pass `value` and `onChange`, and do the search in `onSearch`.

```tsx
import { useState } from "react";
import { SearchInput } from "./SearchInput";
import { searchProducts } from "./api";

function ProductSearch() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<string[]>([]);

  return (
    <>
      <SearchInput
        value={query}
        onChange={setQuery}
        onSearch={async (value) => setResults(await searchProducts(value))}
      />
      <ul>{results.map((item) => <li key={item}>{item}</li>)}</ul>
    </>
  );
}
```

## Props

| Prop | Type | Default | Purpose |
|------|------|---------|---------|
| `value` | `string` | required | The query the field shows |
| `onChange` | `(value: string) => void` | required | Runs on every keystroke |
| `onSearch` | `(value: string) => void` | required | Runs after the user stops typing |
| `delay` | `number` | `300` | Milliseconds to wait after the last keystroke |
| `label` | `string` | `"Search"` | The accessible name of the field |

## What to expect

- Type five letters fast → `onSearch` runs one time, with all five letters.
- Stop typing for 300 ms → `onSearch` runs.
- Open the page → `onSearch` does not run, even when `value` has text.
- Click the clear button → the field empties, then `onSearch` runs with the empty string.
- The clear button appears only when the field has text.

## Limits

- The component keeps no state. It needs `value` and `onChange` from the parent.
- The component does not fetch. The parent runs the search in `onSearch`.
- The component has no styles and no visible label. Add your own.

## Run the tests

```bash
npm install
npm test
```
