from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from npc.rv64.testbench.scripts.check_tb_result import classify, strip_ansi


TEST_NAME = "tb_example"
CHECKER = Path(__file__).with_name("check_tb_result.py")


class CheckTbResultTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        root = Path(self.temp_dir.name)
        self.source_path = root / f"{TEST_NAME}.sv"
        self.log_path = root / f"{TEST_NAME}.log"

    def classify_fixture(
        self,
        *,
        source: str = "initial $finish(0);\n",
        log: str = f"PASS {TEST_NAME}\n",
        compile_rc: int = 0,
        sim_rc: int = 0,
    ) -> list[str]:
        # 通过真实临时文件复现 runner 输入，避免文件系统 mock 掩盖编码/换行问题。
        self.source_path.write_text(source, encoding="utf-8")
        self.log_path.write_text(log, encoding="utf-8")
        return classify(
            TEST_NAME,
            self.source_path.read_text(encoding="utf-8"),
            self.log_path.read_text(encoding="utf-8"),
            compile_rc,
            sim_rc,
        )

    def run_cli(
        self,
        *,
        source: str = "initial $finish(0);\n",
        log: str = f"PASS {TEST_NAME}\n",
        compile_rc: int = 0,
        sim_rc: int = 0,
    ) -> subprocess.CompletedProcess[str]:
        self.source_path.write_text(source, encoding="utf-8")
        self.log_path.write_text(log, encoding="utf-8")
        return subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "--test",
                TEST_NAME,
                "--source",
                str(self.source_path),
                "--log",
                str(self.log_path),
                "--compile-rc",
                str(compile_rc),
                "--sim-rc",
                str(sim_rc),
            ],
            check=False,
            capture_output=True,
            text=True,
        )

    def test_compile_return_code_must_be_zero(self) -> None:
        reasons = self.classify_fixture(compile_rc=3)

        self.assertTrue(reasons)
        self.assertTrue(any("compile" in reason.lower() for reason in reasons))

    def test_simulation_return_code_must_be_zero(self) -> None:
        reasons = self.classify_fixture(sim_rc=7)

        self.assertTrue(reasons)
        self.assertTrue(any("simulation" in reason.lower() for reason in reasons))

    def test_each_failure_marker_rejects_the_log(self) -> None:
        for marker in ("FAIL", "[FAIL]", "[CHECK-FAIL]"):
            with self.subTest(marker=marker):
                reasons = self.classify_fixture(
                    log=f"{marker} mismatch\nPASS {TEST_NAME}\n"
                )
                self.assertTrue(reasons)
                self.assertTrue(any("fail" in reason.lower() for reason in reasons))

    def test_nonzero_error_count_rejects_the_log(self) -> None:
        reasons = self.classify_fixture(log=f"errors=2\nPASS {TEST_NAME}\n")

        self.assertTrue(reasons)
        self.assertTrue(any("errors=2" in reason.lower() for reason in reasons))

    def test_missing_exact_pass_line_rejects_runner_result(self) -> None:
        for log in (
            "[RESULT] PASS\n",
            f"prefix PASS {TEST_NAME}\n",
            f"PASS {TEST_NAME} suffix\n",
            "PASS another_test\n",
        ):
            with self.subTest(log=log):
                reasons = self.classify_fixture(log=log)
                self.assertTrue(reasons)
                self.assertTrue(any("pass" in reason.lower() for reason in reasons))

    def test_nonzero_and_expression_finish_arguments_are_legacy_failures(self) -> None:
        for finish in (
            "$finish(1);",
            "$finish(2);",
            "$finish(errors == 0 ? 0 : 1);",
        ):
            with self.subTest(finish=finish):
                reasons = self.classify_fixture(source=f"initial {finish}\n")
                self.assertTrue(reasons)
                self.assertTrue(any("$finish" in reason for reason in reasons))

    def test_comment_separated_failure_finish_calls_are_rejected(self) -> None:
        for source in (
            "initial $finish /* reviewer gap */ (1);\n",
            "initial $finish // reviewer gap\n(errors == 0 ? 0 : 1);\n",
        ):
            with self.subTest(source=source):
                reasons = self.classify_fixture(source=source)
                self.assertTrue(reasons)
                self.assertTrue(any("$finish" in reason for reason in reasons))

    def test_finish_text_inside_comments_and_strings_is_ignored(self) -> None:
        source = r'''
// $finish(1);
/* $finish(errors == 0 ? 0 : 1); */
initial begin
  $display("literal $finish(2)");
  $display("escaped quote: \" $finish(3)");
  $finish(0);
end
'''

        self.assertEqual([], self.classify_fixture(source=source))

    def test_comment_separated_zero_finish_is_allowed(self) -> None:
        for source in (
            "initial $finish /* allowed */ (0);\n",
            "initial $finish // allowed\n(0);\n",
        ):
            with self.subTest(source=source):
                self.assertEqual([], self.classify_fixture(source=source))

    def test_success_finish_forms_are_allowed(self) -> None:
        for finish in ("$finish;", "$finish();", "$finish(0);"):
            with self.subTest(finish=finish):
                self.assertEqual([], self.classify_fixture(source=f"initial {finish}\n"))

    def test_ansi_color_does_not_hide_pass_or_fail_markers(self) -> None:
        colored_pass = f"\x1b[32m[PASS] {TEST_NAME}\x1b[0m\n"
        self.assertEqual([], self.classify_fixture(log=colored_pass))

        colored_fail = (
            f"\x1b[31m[CHECK-FAIL]\x1b[0m mismatch\n{colored_pass}"
        )
        reasons = self.classify_fixture(log=colored_fail)
        self.assertTrue(reasons)
        self.assertEqual("plain", strip_ansi("\x1b[1;31mplain\x1b[0m"))

    def test_truthful_pass_fixture_succeeds(self) -> None:
        reasons = self.classify_fixture(
            source="module tb; initial begin $finish(0); end endmodule\n",
            log=f"checks complete\nerrors=0\nPASS {TEST_NAME}\n",
        )

        self.assertEqual([], reasons)

    def test_cli_maps_success_failure_and_file_errors_to_exit_codes(self) -> None:
        success = self.run_cli()
        self.assertEqual(0, success.returncode, success.stderr)
        self.assertEqual("", success.stderr)

        failure = self.run_cli(sim_rc=1)
        self.assertEqual(1, failure.returncode)
        self.assertIn("simulation", failure.stderr.lower())

        self.source_path.unlink()
        missing_source = subprocess.run(
            [
                sys.executable,
                str(CHECKER),
                "--test",
                TEST_NAME,
                "--source",
                str(self.source_path),
                "--log",
                str(self.log_path),
                "--compile-rc",
                "0",
                "--sim-rc",
                "0",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(2, missing_source.returncode)
        self.assertTrue(missing_source.stderr)


if __name__ == "__main__":
    unittest.main()
