# Example: CSV Summary CLI

Build a command line tool with the spec-first workflow.

## 1. Write the spec

```
/sf:spec
```

Describe what you need:

> Command line tool that reads a CSV file and prints per-column summary statistics.
> Support --column to limit the output and --json for machine-readable output.

Review the generated spec, then proceed to implementation.

## 2. Implement

```
/sf:implement
```

Generates working code from the spec, following existing patterns in your codebase.
This project was empty, so the code follows the Python standard library defaults.

## 3. Document

```
/sf:document
```

Produces user-facing and technical docs based on the implementation.

## What to expect

Each command runs autonomously. Review the output, iterate if needed.
The workflow is sequential: **spec > implement > document**.

## Generated Output

The [`output/`](output/) directory contains the complete result of running this workflow end-to-end:

**Deliverables:**
- [`csv_summary.py`](output/csv_summary.py) — the command line tool
- [`test_csv_summary.py`](output/test_csv_summary.py) — 11 unit tests, run with `python3 -m unittest`
- [`demo.csv`](output/demo.csv) — sample data for the documented commands
- [`docs.md`](output/docs.md) — user-facing documentation

**Pipeline artifacts** ([`output/.sf/`](output/.sf/)):
- [`spec.md`](output/.sf/spec.md) — specification
- [`implementation-summary.md`](output/.sf/implementation-summary.md) — what implement produced
- [`research/`](output/.sf/research/) — the analysis behind each step

Generated on 2026-08-04 by running `/sf:spec` → `/sf:implement` → `/sf:document` sequentially.
