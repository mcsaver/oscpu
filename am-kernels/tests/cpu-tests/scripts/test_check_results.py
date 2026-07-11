import contextlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import check_results


class CheckResultsTest(unittest.TestCase):
  def run_checker(self, content, expected):
    with tempfile.TemporaryDirectory() as tmpdir:
      result = Path(tmpdir) / ".result"
      result.write_text(content, encoding="utf-8")
      stdout = io.StringIO()
      stderr = io.StringIO()
      with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        rc = check_results.main([
          "--result", str(result), "--expected", *expected,
        ])
      return rc, stdout.getvalue(), stderr.getvalue()

  def assert_failure(self, content, expected, **overrides):
    fields = {
      "failed": "-",
      "missing": "-",
      "duplicate": "-",
      "unexpected": "-",
      "malformed": "-",
    }
    fields.update(overrides)
    rc, stdout, stderr = self.run_checker(content, expected)
    self.assertEqual(rc, 1)
    self.assertEqual(stderr, "")
    self.assertEqual(stdout, "result check failed\n" + "".join(
      f"{name}: {value}\n" for name, value in fields.items()
    ))

  def test_all_expected_tests_pass(self):
    rc, stdout, stderr = self.run_checker(
      "[         alpha] PASS\n[          beta] PASS\n",
      ["alpha", "beta"],
    )
    self.assertEqual((rc, stdout, stderr),
                     (0, "result check passed: 2 test(s)\n", ""))

  def test_ansi_colored_pass_is_accepted(self):
    rc, _, _ = self.run_checker(
      "[         alpha] \x1b[1;32mPASS\x1b[0m\n", ["alpha"])
    self.assertEqual(rc, 0)

  def test_failed_test_is_reported(self):
    self.assert_failure("[           bad] ***FAIL***\n", ["bad"], failed="bad")

  def test_missing_test_is_reported(self):
    self.assert_failure("[            ok] PASS\n", ["ok", "gone"], missing="gone")

  def test_duplicate_test_is_reported(self):
    self.assert_failure(
      "[           dup] PASS\n[           dup] PASS\n", ["dup"], duplicate="dup")

  def test_unexpected_test_is_reported(self):
    self.assert_failure(
      "[            ok] PASS\n[         extra] PASS\n", ["ok"], unexpected="extra")

  def test_empty_file_reports_all_expected_as_missing(self):
    self.assert_failure("", ["beta", "alpha"], missing="alpha, beta")

  def test_malformed_line_is_reported_with_line_number(self):
    self.assert_failure(
      "damaged result\n[            ok] PASS\n", ["ok"],
      malformed="1: 'damaged result'")

  def test_summary_is_sorted_and_contains_every_failure_class(self):
    self.assert_failure(
      "[             z] ***FAIL***\n[             a] ***FAIL***\n"
      "[           dup] PASS\n[           dup] PASS\n"
      "[         extra] PASS\nbroken\n",
      ["z", "a", "dup", "missing"],
      failed="a, z", missing="missing", duplicate="dup",
      unexpected="extra", malformed="6: 'broken'",
    )

  def test_missing_file_is_an_operational_error(self):
    completed = subprocess.run(
      [sys.executable, check_results.__file__, "--result", "/does/not/exist",
       "--expected", "ok"], text=True, capture_output=True, check=False)
    self.assertEqual(completed.returncode, 2)
    self.assertIn("cannot read result file", completed.stderr)

  def test_duplicate_expected_argument_is_a_parameter_error(self):
    with tempfile.TemporaryDirectory() as tmpdir:
      result = Path(tmpdir) / ".result"
      result.write_text("[            ok] PASS\n", encoding="utf-8")
      completed = subprocess.run(
        [sys.executable, check_results.__file__, "--result", str(result),
         "--expected", "ok", "ok"], text=True, capture_output=True, check=False)
    self.assertEqual(completed.returncode, 2)
    self.assertIn("duplicate --expected", completed.stderr)


if __name__ == "__main__":
  unittest.main()
