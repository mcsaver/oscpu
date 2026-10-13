#!/usr/bin/env python3
"""Safety and evidence-preservation tests for completed-round cleanup."""
import contextlib
import gzip
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import finish_round as finish


class FinishRound(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.workspace = Path(self.temporary.name)
        self.round = self.workspace / "build/batch/sta/R64CoreTop-500MHz"
        self.round.mkdir(parents=True)

    def tearDown(self):
        self.temporary.cleanup()

    def run_finish(self, *extra, directory=None):
        output, errors = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            code = finish.main(["--round-dir", str(directory or self.round), *extra],
                               workspace=self.workspace)
        return code, output.getvalue(), errors.getvalue()

    def make_netlist(self, compressed=False):
        names = [("ics55_ecos_sram_256x64_m4_bw",
                  f"memory_unit_physical_cache_g_data_bank_{i//2}_data_way{i%2}_macro")
                 for i in range(4)]
        names += [("ics55_ecos_sram_256x128_m4_ww",
                   f"frontend_access_u_cache_data_way{i}_g_ecos_macro") for i in range(2)]
        contents = "module R64CoreTop(clk_i);\n"
        contents += "".join(f"  {cell} {name} (\n    .CLK(clk_i)\n  );\n"
                            for cell, name in names)
        contents += "endmodule\n"
        path = self.round / ("R64CoreTop.sta.v.gz" if compressed else "R64CoreTop.sta.v")
        if compressed:
            with gzip.open(path, "wt") as stream:
                stream.write(contents)
        else:
            path.write_text(contents)
        return path

    def test_only_known_products_are_removed_and_results_are_unchanged(self):
        keep = ["opensta.sdc", "abc.sdc", "synthesis-config.txt", "synth_stat.txt",
                "synth_check.txt", "sta_area.txt", "opensta.rpt", "opensta.log",
                "opensta.json", "opensta-min-period.rpt", "timing-summary.json",
                "runner-exit-code.txt", "failed.log", "source.v", "oracle.json",
                "R64CoreTop.original.v", "other.netlist.v", "R64CoreTop.netlist.json"]
        for name in keep:
            (self.round / name).write_text("original FAIL diagnostics: " + name)
        before = {name: (self.round / name).read_bytes() for name in keep}
        products = []
        for suffix in finish.NETLIST_SUFFIXES:
            for gzip_suffix in ("", ".gz"):
                product = self.round / ("R64CoreTop" + suffix + gzip_suffix)
                product.write_bytes(b"generated intermediate")
                products.append(product)
        self.make_netlist()
        expected_bytes = sum(path.stat().st_size for path in products)
        code, output, _ = self.run_finish("--upstream-exit-code", "2")
        self.assertEqual(code, 2)
        report = json.loads(output)
        self.assertEqual(report["reclaimed_bytes"], expected_bytes)
        self.assertEqual(report["upstream_exit_code"], 2)
        self.assertTrue(report["cleanup_complete"])
        self.assertTrue(all(not path.exists() for path in products))
        self.assertEqual(before, {name: (self.round / name).read_bytes() for name in keep})
        inventory = json.loads((self.round / "ecos-macro-instances.json").read_text())
        self.assertEqual(inventory["count"], 6)
        self.assertEqual(inventory["by_owner"], {"DCache": 4, "ICache": 2, "unclassified": 0})
        self.assertEqual(inventory["status"], "collected")
        self.assertEqual(inventory["by_cell"], {"ics55_ecos_sram_256x64_m4_bw": 4,
                                                "ics55_ecos_sram_256x128_m4_ww": 2})
        self.assertNotIn("PASS", report)

    def test_dry_run_never_writes_or_deletes(self):
        product = self.make_netlist(compressed=True)
        before = list(self.round.iterdir())
        code, output, _ = self.run_finish("--dry-run")
        self.assertEqual(code, 0)
        self.assertEqual(list(self.round.iterdir()), before)
        self.assertTrue(product.exists())
        self.assertGreater(json.loads(output)["planned_bytes"], 0)

    def test_gzip_is_streamed_before_deletion(self):
        self.make_netlist(compressed=True)
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        inventory = json.loads((self.round / "ecos-macro-instances.json").read_text())
        self.assertEqual(inventory["count"], 6)
        self.assertEqual(inventory["source"], "R64CoreTop.sta.v.gz")

    def test_existing_inventory_and_missing_netlist_are_not_reclassified_pass(self):
        inventory = self.round / "ecos-macro-instances.json"
        inventory.write_text('{"status":"incomplete","count":null}\n')
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        self.assertEqual(inventory.read_text(), '{"status":"incomplete","count":null}\n')

    def test_resynthesis_preserves_previous_inventory_and_writes_fresh_observation(self):
        previous = self.round / "ecos-macro-instances.json"
        previous.write_text('{"status":"incomplete","count":null}\\n')
        original = previous.read_bytes()
        self.make_netlist()
        code, output, _ = self.run_finish()
        self.assertEqual(code, 0)
        current = self.round / json.loads(output)["macro_inventory"]
        self.assertNotEqual(current, previous)
        self.assertEqual(json.loads(current.read_text())["count"], 6)
        self.assertEqual(previous.read_bytes(), original)

    def test_corrupt_gzip_records_incomplete_instead_of_pass(self):
        (self.round / "R64CoreTop.sta.v.gz").write_bytes(b"corrupt gzip")
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        inventory = json.loads((self.round / "ecos-macro-instances.json").read_text())
        self.assertEqual(inventory["status"], "incomplete")
        self.assertIsNone(inventory["count"])

    def test_no_netlist_records_unavailable(self):
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        inventory = json.loads((self.round / "ecos-macro-instances.json").read_text())
        self.assertEqual(inventory["status"], "unavailable")
        self.assertIsNone(inventory["count"])

    def test_reject_roots_source_and_external_paths(self):
        source = self.workspace / "npc/rv64/vsrc/memory"
        source.mkdir(parents=True)
        rvbuild = self.workspace / "npc/rv64/build"
        rvbuild.mkdir()
        with tempfile.TemporaryDirectory() as outside:
            for path in (Path("/"), self.workspace, self.workspace / "build",
                         self.workspace / "build/batch", rvbuild, source, Path(outside)):
                with self.subTest(path=path):
                    code, _, _ = self.run_finish(directory=path)
                    self.assertNotEqual(code, 0)
        self.assertEqual(list(self.round.iterdir()), [])

    def test_both_workspace_build_roots_supported(self):
        other = self.workspace / "npc/rv64/build/batch/sta"
        other.mkdir(parents=True)
        self.assertEqual(finish.validate_round_dir(other, self.workspace), other)

    def test_directory_symlink_escape_and_in_root_alias_are_rejected(self):
        with tempfile.TemporaryDirectory() as outside:
            external_link = self.workspace / "build/batch/escape"
            external_link.symlink_to(outside, target_is_directory=True)
            alias = self.workspace / "build/batch/alias"
            alias.symlink_to(self.round, target_is_directory=True)
            for directory in (external_link, alias):
                code, _, _ = self.run_finish(directory=directory)
                self.assertNotEqual(code, 0)

    def test_generated_file_symlink_is_rejected_before_any_deletion(self):
        product = self.make_netlist()
        outside = self.workspace / "important.v"
        outside.write_text("source")
        (self.round / "R64CoreTop.netlist.v").symlink_to(outside)
        code, _, _ = self.run_finish()
        self.assertNotEqual(code, 0)
        self.assertTrue(product.exists())
        self.assertEqual(outside.read_text(), "source")

    def test_confirmed_abc_products_removed_but_logs_and_unknowns_retained(self):
        abc = self.round / "_tmp_yosys-abc-Ab12"
        abc.mkdir()
        (abc / "abc.script").write_text("read_blif input.blif; write_blif output.blif")
        (abc / "input.blif").write_text("generated")
        (abc / "output.blif").write_text("generated")
        (abc / "abc.log").write_text("ABC error diagnostic")
        (abc / "unknown.json").write_text("keep")
        unconfirmed = self.round / "yosys-abc-unknown"
        unconfirmed.mkdir()
        (unconfirmed / "output.blif").write_text("unconfirmed")
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        self.assertEqual(sorted(path.name for path in abc.iterdir()), ["abc.log", "unknown.json"])
        self.assertTrue((unconfirmed / "output.blif").exists())

    def test_empty_confirmed_abc_directory_removed(self):
        abc = self.round / "_tmp_yosys-abc-X1"
        abc.mkdir()
        (abc / "abc.script").write_text("read_blif input.blif")
        (abc / "input.blif").write_text("generated")
        code, _, _ = self.run_finish()
        self.assertEqual(code, 0)
        self.assertFalse(abc.exists())

    def test_active_build_is_rejected(self):
        product = self.make_netlist()
        process = subprocess.Popen(["yosys", "30"], executable="/bin/sleep", cwd=self.round)
        try:
            code, _, errors = self.run_finish()
            self.assertNotEqual(code, 0)
            self.assertIn("still reference this round", errors)
            self.assertTrue(product.exists())
        finally:
            process.terminate()
            process.wait(timeout=5)

    def test_nested_other_round_is_not_traversed(self):
        other = self.round / "old-round"
        other.mkdir()
        product = other / "R64CoreTop.sta.v"
        product.write_text("preserve other round")
        self.run_finish()
        self.assertTrue(product.exists())


if __name__ == "__main__":
    unittest.main()
