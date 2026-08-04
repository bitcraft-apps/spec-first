# CSV Summary CLI — per-column statistics for one CSV file, standard library only

## Problem

Nobody can see what is in a CSV file without opening it in a spreadsheet. A quick check of
row counts, missing values and value ranges needs a tool that runs in the terminal.

## Scope

### In

- `csv_summary.py` (~90 lines) — the command line tool
  - `csv_summary.py <file>` summarizes every column
  - `--column NAME` limits the output, repeatable
  - `--json` prints one JSON object instead of text
  - Numeric column: count, missing, min, max, mean
  - Text column: count, missing, unique values, most common value
  - Numeric when every non-empty value parses as a float
  - Exit code 2 with a message on standard error for a user error
- `test_csv_summary.py` (~90 lines) — unit tests for all acceptance criteria

### Out

- More than one input file, or input from standard input
- Files with no header row, custom delimiters, other encodings
- Median, standard deviation, percentiles, histograms
- Explicit column type overrides
- Streaming reads for files larger than memory
- Table or CSV output formats

## Acceptance Criteria

- [x] Text output names every column with its row count and missing count
- [x] A numeric column reports min, max and mean
- [x] A text column reports unique count and most common value
- [x] `--column` limits the output to the named columns
- [x] `--json` prints valid JSON with one key for each summarized column
- [x] A missing file exits with code 2 and a message
- [x] An unknown column name exits with code 2 and names the column
- [x] A file with only a header reports 0 rows and no statistics

## Risks

1. **One bad cell makes a numeric column text** — accepted. Document the rule.
2. **Whole file in memory** — accepted for the MVP. Keep counts, not rows.
3. **Empty cells break the statistics** — count them as missing and exclude them.
4. **Duplicate header names collide** — out of scope. `csv.DictReader` keeps the last one.
