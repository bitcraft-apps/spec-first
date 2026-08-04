# CSV Summary CLI — Technical Docs

## Module API

### `summarize(rows, columns) -> dict[str, dict]`

```python
import csv, csv_summary

with open("demo.csv", newline="") as handle:
    reader = csv.DictReader(handle)
    summaries = csv_summary.summarize(list(reader), reader.fieldnames)
```

Returns one summary for each name in `columns`. Every summary has `rows`, `missing` and
`type`. A `numeric` summary adds `min`, `max` and `mean`. A `text` summary adds `unique`
and `most_common`.

A column is numeric only when every non-empty value parses as a float. One text value in
the column makes the whole column text.

### `parse_numbers(values) -> list[float] | None`

Returns the values as floats. Returns `None` when one value is not a number. This is the
type test that `summarize` uses.

### `format_text(summaries) -> str`

Returns the readable form of the output of `summarize`. Two lines for each column, and a
third line for the statistics.

### `main(argv=None) -> int`

Parses the arguments, prints the output and returns 0. Raises `SystemExit(2)` when the
file does not open, or when `--column` names a column that the header does not have.
Pass `argv` as a list to call the tool without a subprocess:

```python
csv_summary.main(["demo.csv", "--json"])
```

## Extend it

- More statistics: add a key in the numeric branch of `summarize`, then a line in
  `format_text`. The JSON output needs no change.
- Another output format: add a flag in `main` and a formatter next to `format_text`.
- Another delimiter: pass `delimiter` to `csv.DictReader` in `read_csv`.

## Constraints

- Python 3.9 or later. No third-party packages.
- The file must have a header row.
- The tool reads the whole file into memory.
- Comma delimiter and UTF-8 encoding only.
- Two columns with the same name collide. `csv.DictReader` keeps the last one.
