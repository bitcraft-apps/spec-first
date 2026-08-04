import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { SearchInput } from "./SearchInput";

/** A parent that owns the value, as the real caller does. */
function Harness(props: {
  onSearch: (value: string) => void;
  initial?: string;
  delay?: number;
}) {
  const [value, setValue] = useState(props.initial ?? "");
  return (
    <SearchInput
      value={value}
      onChange={setValue}
      onSearch={props.onSearch}
      delay={props.delay}
    />
  );
}

function field() {
  return screen.getByRole("searchbox") as HTMLInputElement;
}

/** Type the text one character at a time, `gap` ms apart. */
function type(text: string, gap = 0) {
  for (const character of text) {
    fireEvent.change(field(), { target: { value: field().value + character } });
    if (gap) advance(gap);
  }
}

function advance(ms: number) {
  act(() => {
    vi.advanceTimersByTime(ms);
  });
}

describe("SearchInput", () => {
  const onSearch = vi.fn();

  beforeEach(() => {
    vi.useFakeTimers();
    onSearch.mockClear();
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

  it("searches 300 ms after the last keystroke", () => {
    render(<Harness onSearch={onSearch} />);
    type("abc");
    advance(299);
    expect(onSearch).not.toHaveBeenCalled();
    advance(1);
    expect(onSearch).toHaveBeenCalledWith("abc");
  });

  it("searches one time for a burst of keystrokes", () => {
    render(<Harness onSearch={onSearch} />);
    type("shoes", 50);
    advance(300);
    expect(onSearch).toHaveBeenCalledTimes(1);
    expect(onSearch).toHaveBeenCalledWith("shoes");
  });

  it("does not search on the first render", () => {
    render(<Harness onSearch={onSearch} initial="shoes" />);
    advance(1000);
    expect(onSearch).not.toHaveBeenCalled();
  });

  it("reports every keystroke to the parent, with no delay", () => {
    const onChange = vi.fn();
    render(<SearchInput value="" onChange={onChange} onSearch={onSearch} />);
    fireEvent.change(field(), { target: { value: "a" } });
    fireEvent.change(field(), { target: { value: "ab" } });
    expect(onChange).toHaveBeenCalledTimes(2);
    expect(onChange).toHaveBeenLastCalledWith("ab");
  });

  it("clears the field and searches for the empty string", () => {
    render(<Harness onSearch={onSearch} initial="shoes" />);
    fireEvent.click(screen.getByRole("button", { name: "Clear search" }));
    expect(field().value).toBe("");
    advance(300);
    expect(onSearch).toHaveBeenCalledWith("");
  });

  it("hides the clear button when the field is empty", () => {
    render(<Harness onSearch={onSearch} />);
    expect(screen.queryByRole("button", { name: "Clear search" })).toBeNull();
  });

  it("shows the value the parent passes", () => {
    render(<SearchInput value="shoes" onChange={() => {}} onSearch={onSearch} />);
    expect(field().value).toBe("shoes");
    type("x");
    expect(field().value).toBe("shoes");
  });

  it("cancels the pending search on unmount", () => {
    const view = render(<Harness onSearch={onSearch} />);
    type("abc");
    view.unmount();
    advance(1000);
    expect(onSearch).not.toHaveBeenCalled();
  });

  it("uses the delay prop instead of the default", () => {
    render(<Harness onSearch={onSearch} delay={1000} />);
    type("abc");
    advance(700);
    expect(onSearch).not.toHaveBeenCalled();
    advance(300);
    expect(onSearch).toHaveBeenCalledWith("abc");
  });
});
