#!/usr/bin/env python3
"""Regressions for real RTL log framing, rejection, and timing comparison."""
import argparse
import csv
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

MODEL = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("compare", MODEL/"compare.py")
compare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compare)
spec_runs = importlib.util.spec_from_file_location("compare_runs", MODEL/"compare_runs.py")
compare_runs = importlib.util.module_from_spec(spec_runs)
spec_runs.loader.exec_module(compare_runs)
LINE = "C 45 pc=0000000080000000 raw=0000000000100293 next=0000000080000004 rd=5 fp=0 data=0000000000000001\n"
PASS = "[PASS] r64_core_program cycles=50 commits=1\n"
LIMIT = "[FAIL] core cycle=100 commits=1: timeout: pc=0000000080000004 ROB=0 commits=1\n"


class ToolTests(unittest.TestCase):
    def collect(self, path, text, status=None):
        command = [str(BUILD/"import-rtl"), str(path/"trace"), str(path/"cycles")]
        if status is not None:
            (path/"status").write_text(status)
            command.append(f"--cycle-limit-status={path/'status'}")
        return subprocess.run(command, input=text, text=True, capture_output=True)

    def test_uart_prefix_keeps_retirement(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            result = self.collect(p, "hello!"+LINE+PASS)
            self.assertEqual(result.returncode, 0, result.stderr)
            magic, count, flags = struct.unpack("<8sQQ", (p/"trace").read_bytes()[:24])
            self.assertEqual((magic, count, flags), (b"R64TRC1\0", 1, 1))
            self.assertEqual((p/"cycles").read_bytes(), struct.pack("<Q", 45))

    def test_explicit_limit_is_prefix(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            result = self.collect(p, LINE, LIMIT)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(struct.unpack("<8sQQ", (p/"trace").read_bytes()[:24])[2], 0)

    def test_actual_failure_or_missing_lines_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            for status in (None, "[FAIL] GPR mismatch\n", LIMIT.replace("commits=1", "commits=2")):
                result = self.collect(p, LINE, status)
                self.assertNotEqual(result.returncode, 0, status)

    def test_prefixed_nonterminal_trap_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            result = self.collect(Path(d), LINE+"xT 46 cause=2 pc=80000004 "+PASS)
            self.assertNotEqual(result.returncode, 0)

    def test_comparison_checks_pc(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            self.assertEqual(self.collect(p, LINE+PASS).returncode, 0)
            (p/"stages").write_text("id,pc,retire\n0,0x80000000,45\n")
            result = compare.compare(p/"trace", p/"cycles", p/"stages")
            self.assertEqual(result["span_error_percent"], 0)
            (p/"stages").write_text("id,pc,retire\n0,0x80000004,45\n")
            with self.assertRaisesRegex(ValueError, "instruction mismatch"):
                compare.compare(p/"trace", p/"cycles", p/"stages")

    def test_equal_cpi_does_not_hide_retirement_errors(self):
        for rtl, model in (([45, 50, 55], [46, 51, 56]),
                           ([45, 50, 55], [45, 51, 55])):
            report = compare.timing_metrics(rtl, model)
            self.assertEqual(report["span_error_percent"], 0)
            self.assertFalse(report["cycle_exact"])
            self.assertEqual(report["absolute_cycle_error_max"], 1)
        self.assertTrue(compare.timing_metrics([45, 45, 52], [45, 45, 52])["cycle_exact"])

    def test_strict_cli_rejects_prefix_and_offset(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            command = ["python3", str(MODEL/"compare.py"), "--trace", str(p/"trace"),
                       "--rtl-cycles", str(p/"cycles"), "--stages", str(p/"stages"),
                       "--require-exact"]
            self.assertEqual(self.collect(p, LINE+PASS).returncode, 0)
            (p/"stages").write_text("id,pc,retire\n0,0x80000000,46\n")
            self.assertEqual(subprocess.run(command, capture_output=True).returncode, 2)
            (p/"stages").write_text("id,pc,retire\n0,0x80000000,45\n")
            self.assertEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(self.collect(p, LINE, LIMIT).returncode, 0)
            self.assertEqual(subprocess.run(command, capture_output=True).returncode, 2)
            self.assertEqual(subprocess.run(command+["--allow-prefix"],
                                           capture_output=True).returncode, 0)

    def test_independent_runs_include_terminal_and_functional_stream(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for name in ("reference", "candidate"):
                p = root/name
                p.mkdir()
                self.assertEqual(self.collect(p, LINE+PASS).returncode, 0)
                (p/"trace").rename(p/"functional.trace")
                (p/"cycles").rename(p/"rtl.cycles")
                (p/"rtl.log").write_text(PASS)
                (p/"collection.json").write_text(json.dumps({
                    "collector_exit_code": 0, "rtl_exit_code": 0, "host_seconds": 1.0}))
            a, b = root/"reference", root/"candidate"
            self.assertTrue(compare_runs.compare_runs(a, b)["accepted"])
            (b/"rtl.log").write_text(PASS.replace("cycles=50", "cycles=51"))
            self.assertFalse(compare_runs.compare_runs(a, b)["accepted"])
            (b/"rtl.log").write_text(PASS)
            (b/"rtl.cycles").write_bytes(struct.pack("<Q", 46))
            report = compare_runs.compare_runs(a, b)
            self.assertFalse(report["accepted"])
            self.assertEqual(report["first_cycle_mismatch"]["difference"], 1)
            (b/"rtl.cycles").write_bytes(struct.pack("<Q", 45))
            trace = bytearray((b/"functional.trace").read_bytes())
            trace[24] ^= 4
            (b/"functional.trace").write_bytes(trace)
            report = compare_runs.compare_runs(a, b)
            self.assertFalse(report["accepted"])
            self.assertFalse(report["same_instruction_stream"])

    def test_host_timeout_does_not_keep_a_success_receipt(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)
            sim=p/"fake-simulator"
            sim.write_text("#!/usr/bin/env python3\nimport time\ntime.sleep(10)\n")
            sim.chmod(0o700)
            out=p/"run"
            out.mkdir()
            (out/"collection.json").write_text('{"rtl_exit_code":0,"collector_exit_code":0}')
            result=subprocess.run(["python3",str(MODEL/"collect_rtl.py"),
                "--sim",str(sim),"--image",str(p/"unused.bin"),"--out",str(out),
                "--host-timeout","0.1"],capture_output=True)
            self.assertNotEqual(result.returncode,0)
            report=json.loads((out/"collection.json").read_text())
            self.assertEqual(report["collection_error"],"TimeoutExpired")
            self.assertFalse(report["trace_natural_end"])
            self.assertNotEqual(report["rtl_exit_code"],0)

    def test_sweep_writes_each_configuration(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            self.assertEqual(self.collect(p, LINE+PASS).returncode, 0)
            result = subprocess.run([
                "python3", str(MODEL/"sweep.py"), str(p/"trace"),
                "--model", str(BUILD/"r64-model"), "--vary", "iq=8,16",
                "--vary", "wb_width=1,2", "--out", str(p/"sweep"),
            ], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            with (p/"sweep/summary.csv").open() as stream:
                rows = list(csv.DictReader(stream))
            self.assertEqual(len(rows), 4)
            for row in rows:
                report = json.loads(Path(row["report"]).read_text())
                self.assertEqual(report["config"]["iq"], int(row["iq"]))
                self.assertEqual(report["config"]["wb_width"], int(row["wb_width"]))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--build", type=Path, required=True)
    args, remaining = p.parse_known_args()
    BUILD = args.build.resolve()
    unittest.main(argv=["test_tools.py", *remaining])
