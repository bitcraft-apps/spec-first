#!/usr/bin/env python3
"""Print per-column summary statistics for one CSV file."""

import argparse
import csv
import json
import sys
from collections import Counter
from typing import NoReturn


def summarize(rows, columns):
    """Return one summary dict per column name."""
    summaries = {}
    for column in columns:
        values = [row.get(column) or "" for row in rows]
        present = [value for value in values if value.strip()]
        summary: dict[str, object] = {
            "rows": len(values),
            "missing": len(values) - len(present),
        }
        numbers = parse_numbers(present)
        if numbers is not None and numbers:
            summary["type"] = "numeric"
            summary["min"] = min(numbers)
            summary["max"] = max(numbers)
            summary["mean"] = sum(numbers) / len(numbers)
        else:
            summary["type"] = "text"
            counts = Counter(present)
            summary["unique"] = len(counts)
            summary["most_common"] = counts.most_common(1)[0][0] if counts else None
        summaries[column] = summary
    return summaries


def parse_numbers(values):
    """Return the values as floats, or None when one value is not a number."""
    numbers = []
    for value in values:
        try:
            numbers.append(float(value))
        except ValueError:
            return None
    return numbers


def format_text(summaries):
    """Return the summaries as lines of readable text."""
    lines = []
    for column, summary in summaries.items():
        lines.append(f"{column} ({summary['type']})")
        lines.append(f"  rows: {summary['rows']}  missing: {summary['missing']}")
        if summary["type"] == "numeric":
            lines.append(
                f"  min: {summary['min']:g}  max: {summary['max']:g}"
                f"  mean: {summary['mean']:g}"
            )
        elif summary["unique"]:
            lines.append(
                f"  unique: {summary['unique']}  most common: {summary['most_common']}"
            )
    return "\n".join(lines)


def fail(message) -> NoReturn:
    """Print the message to standard error and exit with code 2."""
    print(message, file=sys.stderr)
    raise SystemExit(2)


def read_csv(path):
    """Return the header names and the rows of the file."""
    try:
        with open(path, newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            return reader.fieldnames or [], list(reader)
    except OSError as error:
        fail(f"Cannot read {path}: {error.strerror}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", help="the CSV file to read")
    parser.add_argument(
        "--column", action="append", metavar="NAME", help="summarize only this column"
    )
    parser.add_argument("--json", action="store_true", help="print JSON output")
    args = parser.parse_args(argv)

    header, rows = read_csv(args.file)
    columns = args.column or header
    for column in columns:
        if column not in header:
            fail(f"No column named {column} in {args.file}")

    summaries = summarize(rows, columns)
    print(json.dumps(summaries, indent=2) if args.json else format_text(summaries))
    return 0


if __name__ == "__main__":
    sys.exit(main())
