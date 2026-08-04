# Acceptance Criteria: CSV Summary CLI

## Must Pass

1. **Every column is summarized**
   - Run the tool on a three column file → the output names all three columns
   - Each column shows a row count and a count of missing values

2. **Numeric columns report min, max and mean**
   - Column with values 1, 2, 3 → min 1, max 3, mean 2
   - A column with one non-numeric value is treated as text

3. **Text columns report unique count and most common value**
   - Column with values a, b, b → unique 2, most common b
   - A tie picks the value that appears first in the file

4. **`--column` limits the output**
   - `--column price` → only `price` appears in the output
   - `--column price --column city` → both columns appear, no others

5. **`--json` prints machine-readable output**
   - The output parses with `json.loads`
   - The top level object has one key for each summarized column

6. **User errors exit with code 2**
   - Missing file → exit 2, message on standard error
   - Unknown column name → exit 2, message names the column

## Edge Cases (Must Not Fail)

- Header row and no data rows → every column reports 0 rows
- Empty cells → counted as missing, excluded from the statistics
- A column with only empty cells → reported, with no min, max or mean

## Definition of Done

All 6 "Must Pass" criteria pass in `test_csv_summary.py`. The edge cases have tests too.
