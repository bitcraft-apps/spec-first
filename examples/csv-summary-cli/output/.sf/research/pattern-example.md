# Pattern Example: none found

The project is empty. It has no source files, no tests and no build config.

Searched for:
- `*.py` — no results
- `test_*.py`, `*_test.py`, `tests/` — no results
- `pyproject.toml`, `setup.py`, `requirements.txt` — no results

## Chosen conventions

No pattern exists, so the implementation follows the Python standard library defaults:

- `argparse` for the flags, with `main(argv)` so the tests can call it directly
- `csv.DictReader` for the read
- `unittest` for the tests, in `test_csv_summary.py` next to the module
- `if __name__ == "__main__": sys.exit(main())` as the entry point
