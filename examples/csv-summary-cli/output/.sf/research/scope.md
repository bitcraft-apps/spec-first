# MVP Scope: CSV Summary CLI

## In Scope

### Core Functionality
- Read one CSV file that has a header row
- Print a summary for each column
- Numeric column: count, missing, min, max, mean
- Text column: count, missing, unique values, most common value
- Column type comes from the data, not from a flag

### Required Interface
- `csv_summary.py <file>` — summarize every column
- `--column NAME` — summarize only that column, repeatable
- `--json` — print one JSON object instead of text
- Exit code 0 on success, 2 on a user error

### Minimum Viable Behavior
- Standard library only, no dependencies to install
- Read the file one time, hold the values in memory
- Print to standard output, print errors to standard error

## Out of Scope (Future Considerations)

### Input
- Multiple input files
- Input from standard input
- Files with no header row
- Custom delimiters, quoting or encoding flags
- Excel or JSON input

### Statistics
- Median, mode, standard deviation, percentiles
- Correlation between columns
- Histograms or value distributions
- Explicit column type overrides

### Output
- CSV or table output formats
- Colour or aligned columns
- A progress indicator for large files

### Scale
- Streaming or chunked reads for files larger than memory
- Parallel processing

## Acceptance Criteria

1. Every column appears in the text output
2. Numeric columns report min, max and mean
3. Text columns report unique count and most common value
4. `--column` limits the output to the named columns
5. `--json` prints valid JSON keyed by column name
6. User errors exit with code 2 and a message

## Non-Functional

- Size: ~90 lines for the tool, ~90 lines for the tests
- Python 3.9 or later, standard library only
- Tests run with `python3 -m unittest`
