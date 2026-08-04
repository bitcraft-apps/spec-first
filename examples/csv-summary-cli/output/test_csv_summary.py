"""Tests for the CSV summary CLI."""

import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

import csv_summary

SAMPLE = "city,price,tag\nBerlin,10,a\nParis,20,b\nRome,30,b\n"


def write_csv(text):
    """Write the text to a temporary CSV file and return its path."""
    directory = tempfile.mkdtemp()
    path = Path(directory) / "data.csv"
    path.write_text(text, encoding="utf-8")
    return str(path)


def run(*argv):
    """Run the CLI and return its standard output."""
    out = io.StringIO()
    with redirect_stdout(out):
        csv_summary.main(list(argv))
    return out.getvalue()


class SummaryOutputTest(unittest.TestCase):
    def test_names_every_column_with_counts(self):
        output = run(write_csv(SAMPLE))
        self.assertIn("city", output)
        self.assertIn("price", output)
        self.assertIn("tag", output)
        self.assertIn("rows: 3  missing: 0", output)

    def test_numeric_column_reports_min_max_mean(self):
        output = run(write_csv(SAMPLE), "--column", "price")
        self.assertIn("min: 10  max: 30  mean: 20", output)

    def test_text_column_reports_unique_and_most_common(self):
        output = run(write_csv(SAMPLE), "--column", "tag")
        self.assertIn("unique: 2  most common: b", output)

    def test_column_flag_limits_the_output(self):
        output = run(write_csv(SAMPLE), "--column", "price", "--column", "city")
        self.assertIn("price", output)
        self.assertIn("city", output)
        self.assertNotIn("tag", output)

    def test_json_output_has_one_key_per_column(self):
        summaries = json.loads(run(write_csv(SAMPLE), "--json"))
        self.assertEqual(sorted(summaries), ["city", "price", "tag"])
        self.assertEqual(summaries["price"]["mean"], 20)


class UserErrorTest(unittest.TestCase):
    def test_missing_file_exits_with_code_2(self):
        err = io.StringIO()
        with redirect_stderr(err), self.assertRaises(SystemExit) as raised:
            csv_summary.main(["no-such-file.csv"])
        self.assertEqual(raised.exception.code, 2)
        self.assertIn("Cannot read", err.getvalue())

    def test_unknown_column_exits_with_code_2(self):
        err = io.StringIO()
        with redirect_stderr(err), self.assertRaises(SystemExit) as raised:
            csv_summary.main([write_csv(SAMPLE), "--column", "colour"])
        self.assertEqual(raised.exception.code, 2)
        self.assertIn("colour", err.getvalue())


class EdgeCaseTest(unittest.TestCase):
    def test_header_only_file_reports_zero_rows(self):
        output = run(write_csv("city,price\n"))
        self.assertIn("rows: 0  missing: 0", output)
        self.assertNotIn("mean", output)

    def test_empty_cells_count_as_missing(self):
        summaries = json.loads(run(write_csv("price,tag\n10,a\n,b\n30,c\n"), "--json"))
        self.assertEqual(summaries["price"]["missing"], 1)
        self.assertEqual(summaries["price"]["mean"], 20)

    def test_column_of_empty_cells_has_no_statistics(self):
        summaries = json.loads(run(write_csv("note,tag\n,a\n,b\n"), "--json"))
        self.assertEqual(summaries["note"]["type"], "text")
        self.assertEqual(summaries["note"]["unique"], 0)
        self.assertIsNone(summaries["note"]["most_common"])

    def test_one_text_value_makes_the_column_text(self):
        summaries = json.loads(run(write_csv("price\n10\nfree\n"), "--json"))
        self.assertEqual(summaries["price"]["type"], "text")


if __name__ == "__main__":
    unittest.main()
