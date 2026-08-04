import { useEffect, useRef } from "react";

export type SearchInputProps = {
  /** The current query. The parent owns it. */
  value: string;
  /** Runs on every keystroke. */
  onChange: (value: string) => void;
  /** Runs once, `delay` ms after the last keystroke. */
  onSearch: (value: string) => void;
  /** Milliseconds to wait after the last keystroke. */
  delay?: number;
  /** The accessible name of the field. */
  label?: string;
};

export function SearchInput({
  value,
  onChange,
  onSearch,
  delay = 300,
  label = "Search",
}: SearchInputProps) {
  const onSearchRef = useRef(onSearch);
  const searched = useRef(value);

  // Keep the callback current, so the timer never calls an old one.
  useEffect(() => {
    onSearchRef.current = onSearch;
  });

  useEffect(() => {
    if (searched.current === value) return;
    const timer = setTimeout(() => {
      searched.current = value;
      onSearchRef.current(value);
    }, delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return (
    <div>
      <input
        type="search"
        value={value}
        aria-label={label}
        onChange={(event) => onChange(event.target.value)}
      />
      {value && (
        <button type="button" aria-label="Clear search" onClick={() => onChange("")}>
          ×
        </button>
      )}
    </div>
  );
}
