# Implementation Summary: CSV Summary CLI

## Files Created

- `csv_summary.py` — the tool: `summarize`, `parse_numbers`, `format_text`, `read_csv`, `main`
- `test_csv_summary.py` — 11 unit tests, all acceptance criteria and every edge case
- `demo.csv` — a three column sample file for the commands in the docs

No existing patterns found - used minimal approach. The project was empty, so the code
follows the Python standard library defaults.

## Acceptance Criteria Status

- [x] Text output names every column with its row count and missing count
- [x] A numeric column reports min, max and mean
- [x] A text column reports unique count and most common value
- [x] `--column` limits the output to the named columns
- [x] `--json` prints valid JSON with one key for each summarized column
- [x] A missing file exits with code 2 and a message
- [x] An unknown column name exits with code 2 and names the column
- [x] A file with only a header reports 0 rows and no statistics

## Design Decisions

- `main(argv=None)` takes the argument list, so the tests call it without a subprocess
- `parse_numbers` returns `None` for a column that holds one non-numeric value
- A column of only empty cells is text, with `unique: 0` and `most_common: null`
- `fail()` prints to standard error and raises `SystemExit(2)`, for both user errors
- `csv.DictReader` skips blank lines, so a missing value needs an empty cell in a row
