# CSV Summary CLI Risks

## Blockers

### 1. Column Type Detection
**Risk**: The tool guesses the type of each column from the values. One bad cell in a numeric column makes the whole column text.
**Impact**: A user sees "unique values" where they expect a mean.
**Solution**: Treat a column as numeric only when every non-empty value parses as a number. State the rule in the docs.

### 2. Whole File In Memory
**Risk**: The tool holds every value in memory to count unique values.
**Impact**: A file larger than memory stops the tool.
**Solution**: Accept the limit for the MVP. Keep counts and running totals, not the raw rows.

## Edge Cases

### 1. No Data Rows
**Risk**: A file with only a header divides by zero when it computes the mean.
**Solution**: Report 0 rows and omit min, max and mean.

### 2. Empty Cells
**Risk**: An empty cell parses as neither number nor useful text.
**Solution**: Count empty cells as missing. Exclude them from every statistic.

### 3. Duplicate Header Names
**Risk**: Two columns with the same name collide in the JSON output.
**Solution**: Out of scope. `csv.DictReader` keeps the last column, which is documented behavior.

### 4. Unknown Column Name
**Risk**: A typo in `--column` prints an empty summary and looks like a working run.
**Solution**: Exit with code 2 and name the column that does not exist.

## Assumptions to Validate

- **Header row always present?** The MVP requires one.
- **Comma delimiter only?** The MVP does not accept a delimiter flag.

## Simple MVP Approach

- `csv.DictReader` for the read, `argparse` for the flags
- One pass over the rows, one summary object for each column
- Numeric when every non-empty value parses as a float
- `print` for text output, `json.dumps` for `--json`
- `SystemExit(2)` with a message on standard error for user errors
