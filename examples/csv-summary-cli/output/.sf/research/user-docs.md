# CSV Summary CLI

Print per-column statistics for a CSV file, in the terminal.

## Install

Copy `csv_summary.py` next to your data. The tool needs Python 3.9 or later, and no
packages.

## Use it

Summarize every column:

```bash
python3 csv_summary.py demo.csv
```

```
city (text)
  rows: 3  missing: 0
  unique: 3  most common: Berlin
price (numeric)
  rows: 3  missing: 0
  min: 10  max: 30  mean: 20
tag (text)
  rows: 3  missing: 0
  unique: 2  most common: b
```

Summarize one column. Repeat the flag for more columns:

```bash
python3 csv_summary.py demo.csv --column price --column city
```

Print JSON for another program to read:

```bash
python3 csv_summary.py demo.csv --json
```

## What the numbers mean

- `rows` — the number of data rows in the file
- `missing` — the empty cells in the column, which no statistic counts
- A numeric column shows `min`, `max` and `mean`
- A text column shows `unique` and the `most common` value

The tool decides the type from the data. A column is numeric only when every value is a
number. One text value in a number column makes the column text.

## Limits

- The file must have a header row.
- The tool reads one file, with commas and UTF-8.
- The tool holds the file in memory. Very large files fail.

## Exit codes

- `0` — the summary printed
- `2` — the file does not open, or `--column` names a column that the file does not have

## Run the tests

```bash
python3 -m unittest
```
