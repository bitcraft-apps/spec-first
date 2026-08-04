# Artifacts Summary

**Project**: CSV Summary CLI — per-column statistics for one CSV file, standard library only

## Requirements
- Read one CSV file that has a header row
- Print a summary for each column
- Numeric column: count, missing, min, max, mean
- Text column: count, missing, unique values, most common value
- `--column NAME` limits the output, repeatable
- `--json` prints one JSON object
- Exit code 2 with a message for a user error

## Acceptance Criteria (All Passed)
1. Text output names every column with its row count and missing count
2. A numeric column reports min, max and mean
3. A text column reports unique count and most common value
4. `--column` limits the output to the named columns
5. `--json` prints valid JSON with one key for each summarized column
6. A missing file exits with code 2 and a message
7. An unknown column name exits with code 2 and names the column
8. A file with only a header reports 0 rows and no statistics

## Scope Boundaries
- **In**: one file, two output formats, five numeric statistics, unit tests
- **Out**: many files, standard input, other delimiters, median and percentiles,
  type overrides, streaming reads, table output

## Risks
1. One non-numeric cell makes the column text → documented rule
2. Whole file in memory → accepted for the MVP
3. Empty cells → counted as missing, excluded from the statistics
4. Duplicate header names → out of scope
