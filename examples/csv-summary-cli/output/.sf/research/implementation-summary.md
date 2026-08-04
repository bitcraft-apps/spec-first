# Implementation Summary

## Files
- `csv_summary.py` (103 lines) — the tool, five functions, no classes
- `test_csv_summary.py` (98 lines) — 11 unittest tests in three test cases
- `demo.csv` (4 lines) — sample file for the documented commands

## Public API

**`main(argv=None) -> int`**
- Parses the arguments, prints the summary, returns 0
- Raises `SystemExit(2)` on a user error

**`summarize(rows, columns) -> dict`**
- `rows` is a list of dicts from `csv.DictReader`
- Returns one summary dict for each column name
- Numeric summary keys: `rows`, `missing`, `type`, `min`, `max`, `mean`
- Text summary keys: `rows`, `missing`, `type`, `unique`, `most_common`

**`format_text(summaries) -> str`**
- Returns the readable form of the output of `summarize`

## Design Decisions
- `argparse` with `action="append"` for the repeatable `--column`
- A column is numeric only when every non-empty value parses as a float
- `Counter.most_common` breaks a tie by first appearance, which `Counter` guarantees
- `fail()` centralizes both user errors: it prints to standard error, then exits 2
- No `pyproject.toml`. The tool has no dependencies and needs no install step.

## Test Coverage
All 8 acceptance criteria have tests. Three more tests cover empty cells, a column of
only empty cells, and a numeric column that holds one text value.
