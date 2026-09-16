import unittest
from repair_input_hold import repair

LIB = '''
cell (BUF) {
 area : 1.2;
 pin (A) { direction : input; capacitance : 0.001; }
 pin (Y) { direction : output; function : "A"; }
}
cell (DFF) {
 area : 4.0;
 ff (Q, QN) { next_state : "D"; clocked_on : "CK"; }
 pin (D) { direction : input; }
 pin (CK) { direction : input; }
 pin (Q) { direction : output; function : "Q"; }
}
'''
NET = '''module top(clk, a, y);
  input clk;
  input a;
  output y;
  wire a;
  DFF reg0 (
    .CK(clk),
    .D(a),
    .Q(y)
  );
endmodule
'''
CHECK = {"path_type": "min", "slack": -0.03, "startpoint": "a",
         "endpoint": "reg0/D", "source_path": [{}, {}]}


class HoldBranchTests(unittest.TestCase):
    def transform(self, paths=None, lib=LIB, source=NET):
        return repair(source, {"checks": paths or [CHECK]}, [lib], "BUF", 2)

    def test_direct_data_branch_deduplicated(self):
        out, info = self.transform([CHECK, dict(CHECK)])
        self.assertEqual(info["buffer_count"], 2)
        self.assertAlmostEqual(info["repaired_cell_area_um2"], 6.4)
        self.assertIn(".CK(clk)", out)
        self.assertIn(".Q(y)", out)
        self.assertIn("input a;", out)

    def test_no_clock_repair(self):
        out, info = self.transform([dict(CHECK, endpoint="reg0/CK", startpoint="clk")])
        self.assertEqual(out, NET)
        self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_no_internal_or_mismatched_source(self):
        for path in [dict(CHECK, source_path=[{}, {}, {}]),
                     dict(CHECK, startpoint="clk")]:
            out, info = self.transform([path])
            self.assertEqual(out, NET)
            self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_positive_checks_untouched(self):
        out, info = self.transform([dict(CHECK, slack=0.001)])
        self.assertEqual(out, NET)
        self.assertEqual(info["buffer_count"], 0)

    def test_inverter_and_unknown_cell_rejected(self):
        with self.assertRaises(ValueError):
            self.transform(lib=LIB.replace('function : "A"', 'function : "!A"'))
        with self.assertRaises(ValueError):
            self.transform(source=NET.replace('DFF reg0', 'UNKNOWN reg0'))

    def test_optional_input_logic_and_internal_source_boundary(self):
        lib = LIB + """
cell (INV) {
 area : 1.0;
 pin (A) { direction : input; }
 pin (Y) { direction : output; function : "!A"; }
}
"""
        source = NET.replace(".D(a)", ".D(n)").replace("endmodule", """  wire n;
  INV inv0 (
    .A(a),
    .Y(n)
  );
endmodule""")
        path = dict(CHECK, source_path=[{}, {}, {}, {}])
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2, True)
        self.assertEqual(info["buffer_count"], 2)
        self.assertIn(".A(a)", out)
        self.assertAlmostEqual(info["repaired_cell_area_um2"], 7.4)
        # A register launch point must remain outside this input-only flow.
        out, info = repair(source, {"checks": [dict(path, startpoint="reg0/Q")]},
                           [lib], "BUF", 2, True)
        self.assertEqual(out, source)
        self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_openroad_cell_format_preserves_ports(self):
        source = NET.replace("  input", " input").replace(
            "  DFF reg0 (\\n    .CK(clk),", " DFF reg0 (.CK(clk),").replace(
            "    .Q(y)\\n  );", "    .Q(y));")
        out, info = self.transform(source=source)
        self.assertEqual(info["buffer_count"], 2)
        self.assertAlmostEqual(info["original_cell_area_um2"], 4.0)
        self.assertIn(".CK(clk)", out)

    def test_liberty_gate_enable_requires_explicit_option(self):
        lib = LIB + """
cell (ICG) {
 area : 3.0;
 clock_gating_integrated_cell : latch_negedge;
 latch (IQ, IQN) { data_in : "E"; enable : "!CK"; }
 pin (CK) { direction : input; clock_gate_clock_pin : true; }
 pin (E) { direction : input; clock_gate_enable_pin : true; }
 pin (ECK) { direction : output; function : "IQ & CK"; }
}
"""
        source = NET.replace("DFF reg0", "ICG reg0").replace(".D(a)", ".E(a)").replace(".Q(y)", ".ECK(y)")
        path = dict(CHECK, endpoint="reg0/E")
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2)
        self.assertEqual(out, source)
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2, False, True)
        self.assertEqual(info["buffer_count"], 2)
        self.assertIn(".CK(clk)", out)
        self.assertAlmostEqual(info["repaired_cell_area_um2"], 5.4)
        # The clock itself and an unmarked pin are never inferred to be enables.
        for denied, marked in [
            (dict(path, endpoint="reg0/CK", startpoint="clk"), lib),
            (path, lib.replace("clock_gate_enable_pin : true", "clock_gate_enable_pin : false"))]:
            out, info = repair(source, {"checks": [denied]}, [marked], "BUF", 2, False, True)
            self.assertEqual(out, source)
            self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_non_d_register_rejected(self):
        out, info = self.transform(lib=LIB.replace('next_state : "D"', 'next_state : "!D"'))
        self.assertEqual(out, NET)
        self.assertEqual(len(info["unhandled_negative_checks"]), 1)


    def source_fixture(self):
        lib = LIB + """
cell (AND2) {
 area : 2.0;
 pin (A) { direction : input; }
 pin (B) { direction : input; }
 pin (Y) { direction : output; function : "A & B"; }
}
"""
        source = """module top(clk, a, late, y, z);
  input clk;
  input a;
  input late;
  output y;
  output z;
  wire n0;
  wire n1;
  AND2 g0 (.A(a), .B(late), .Y(n0));
  AND2 g1 (.A(a), .B(late), .Y(n1));
  DFF reg0 (.CK(clk), .D(n0), .Q(y));
  DFF reg1 (.CK(clk), .D(n1), .Q(z));
endmodule
"""
        paths = [dict(CHECK, endpoint=f"reg{i}/D",
                      source_path=[{}, {"pin": f"g{i}/A"}, {}, {}])
                 for i in range(2)]
        return lib, source, paths

    def test_source_shared_branch_preserves_late_data_path(self):
        lib, source, paths = self.source_fixture()
        out, info = repair(source, {"checks": paths + paths}, [lib], "BUF", 2,
                           source_branches=True, source_fanout=2)
        self.assertEqual(info["buffer_count"], 2)
        self.assertEqual(len(info["endpoints"][0]["endpoints"]), 2)
        self.assertEqual(out.count(".B(late)"), 2)
        self.assertIn(".D(n0)", out)
        self.assertIn(".D(n1)", out)
        self.assertEqual(out.count(".A(r64_input_hold_net_0_1)"), 2)
        self.assertEqual(info["unhandled_negative_checks"], [])

    def test_source_fanout_split_and_two_pins_in_one_cell(self):
        lib, source, paths = self.source_fixture()
        _, info = repair(source, {"checks": paths}, [lib], "BUF", 2,
                         source_branches=True, source_fanout=1)
        self.assertEqual(info["buffer_count"], 4)
        source = source.replace(".B(late)", ".B(a)")
        paths = [paths[0], dict(paths[0], source_path=[{}, {"pin": "g0/B"}, {}, {}])]
        out, info = repair(source, {"checks": paths}, [lib], "BUF", 2,
                           source_branches=True)
        self.assertEqual(info["buffer_count"], 2)
        self.assertIn(".A(r64_input_hold_net_0_1), .B(r64_input_hold_net_0_1)", out)

    def test_source_rejects_clock_wrong_net_output_and_missing_pin(self):
        lib, source, paths = self.source_fixture()
        for first, start in [("reg0/CK", "clk"), ("g0/B", "a"),
                             ("g0/Y", "a"), ("missing/A", "a")]:
            path = dict(paths[0], startpoint=start,
                        source_path=[{}, {"pin": first}, {}, {}])
            out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                               source_branches=True)
            self.assertEqual(out, source)
            self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_source_gate_enable_keeps_explicit_authorization(self):
        lib = LIB + """
cell (ICG) {
 area : 3.0;
 clock_gating_integrated_cell : latch_negedge;
 latch (IQ, IQN) { data_in : "E"; enable : "!CK"; }
 pin (CK) { direction : input; clock_gate_clock_pin : true; }
 pin (E) { direction : input; clock_gate_enable_pin : true; }
 pin (ECK) { direction : output; function : "IQ & CK"; }
}
"""
        source = NET.replace("DFF reg0", "ICG reg0").replace(".D(a)", ".E(a)").replace(".Q(y)", ".ECK(y)")
        path = dict(CHECK, endpoint="reg0/E",
                    source_path=[{}, {"pin": "reg0/E"}])
        for enabled in [False, True]:
            out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                               clock_enable=enabled, source_branches=True)
            self.assertEqual(info["buffer_count"], 2 if enabled else 0)
            self.assertIn(".CK(clk)", out)



    def test_output_source_branch_preserves_late_valid_cone(self):
        lib, source, _ = self.source_fixture()
        source = source.replace(".Y(n0)", ".Y(y)").replace(".Q(y)", ".Q(n0)")
        path = dict(CHECK, endpoint="y",
                    source_path=[{"pin": "a"}, {"pin": "g0/A"},
                                 {"pin": "g0/Y"}, {"pin": "y"}])
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                           source_branches=True)
        self.assertEqual(out, source)
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                           source_branches=True, output_branches=True)
        self.assertEqual(info["buffer_count"], 2)
        self.assertIn(".B(late), .Y(y)", out)
        self.assertIn(".D(n0)", out)
        self.assertEqual(info["unhandled_negative_checks"], [])

    def test_output_rejects_unknown_internal_or_mismatched_path(self):
        lib, source, _ = self.source_fixture()
        for start, end, last in [("reg0/Q", "y", "y"), ("a", "missing", "missing"),
                                 ("a", "y", "z")]:
            path = dict(CHECK, startpoint=start, endpoint=end,
                        source_path=[{}, {"pin": "g0/A"}, {}, {"pin": last}])
            out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                               source_branches=True, output_branches=True)
            self.assertEqual(out, source)
            self.assertEqual(len(info["unhandled_negative_checks"]), 1)
        with self.assertRaises(ValueError):
            repair(source, {"checks": []}, [lib], "BUF", 2, output_branches=True)

    def test_buffered_clock_root_never_repaired_as_output_data(self):
        lib, source, _ = self.source_fixture()
        source = source.replace(".CK(clk)", ".CK(c)").replace(".A(a)", ".A(clk)")
        source = source.replace("endmodule", "  wire c;\n  BUF clock_buf (.A(clk), .Y(c));\nendmodule")
        path = dict(CHECK, startpoint="clk", endpoint="y",
                    source_path=[{}, {"pin": "g0/A"}, {}, {"pin": "y"}])
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                           source_branches=True, output_branches=True)
        self.assertEqual(out, source)
        self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_statetable_clock_gate_keeps_enable_as_data(self):
        lib = LIB + """
cell (ICG) {
 area : 3.0;
 clock_gating_integrated_cell : latch_negedge;
 statetable ("CK E", "IQ") { table : "L L : - : L"; }
 pin (CK) { direction : input; clock_gate_clock_pin : true; }
 pin (E) { direction : input; clock_gate_enable_pin : true; }
 pin (ECK) { direction : output; function : "IQ & CK"; }
}
"""
        source = NET.replace("endmodule", "  ICG gate0 (.CK(clk), .E(a), .ECK(c));\n  wire c;\nendmodule")
        source = source.replace(".CK(clk),\n    .D(a)", ".CK(c),\n    .D(a)")
        path = dict(CHECK, endpoint="gate0/E",
                    source_path=[{}, {"pin": "gate0/E"}])
        out, info = repair(source, {"checks": [path]}, [lib], "BUF", 2,
                           source_branches=True, clock_enable=True)
        self.assertEqual(info["buffer_count"], 2)
        self.assertIn(".CK(clk)", out)
        self.assertIn(".CK(c)", out)


    def test_output_stages_preserve_register_budget_and_shared_branch(self):
        lib, source, paths = self.source_fixture()
        source = source.replace(".Y(n0)", ".Y(y)").replace(".Q(y)", ".Q(n0)")
        output_path = dict(CHECK, endpoint="y",
            source_path=[{"pin": "a"}, {"pin": "g0/A"}, {"pin": "g0/Y"}, {"pin": "y"}])
        out, info = repair(source, {"checks": [output_path, paths[1]]}, [lib], "BUF", 2,
                           source_branches=True, output_branches=True, output_stages=1)
        self.assertEqual(info["buffer_count"], 3)
        budgets = {e["endpoint"]:len(e["chain"]) for e in info["endpoints"]}
        self.assertEqual(budgets, {"y":1, "reg1/D":2})
        self.assertIn(".B(late), .Y(y)", out)
        shared = source.replace(".D(n0)", ".D(y)")
        reg_path = dict(paths[0], source_path=output_path["source_path"][:-1]+[{"pin":"reg0/D"}])
        for order in [[output_path, reg_path], [reg_path, output_path]]:
            _, info = repair(shared, {"checks":order}, [lib], "BUF", 2,
                             source_branches=True, output_branches=True, output_stages=1)
            self.assertEqual(info["buffer_count"], 2)
            self.assertEqual(info["endpoints"][0]["endpoints"], ["reg0/D", "y"])

    def test_output_stage_option_requires_explicit_scope_and_valid_count(self):
        for count, enabled in [(1, False), (0, True), (9, True)]:
            with self.assertRaises(ValueError):
                repair(NET, {"checks":[]}, [LIB], "BUF", 2, source_branches=True,
                       output_branches=enabled, output_stages=count)

    def test_cli_accepts_multiple_source_reports(self):
        import json
        import subprocess
        import sys
        import tempfile
        from pathlib import Path
        lib, source, paths = self.source_fixture()
        with tempfile.TemporaryDirectory() as directory:
            d = Path(directory)
            (d / "design.v").write_text(source)
            (d / "library.lib").write_text(lib)
            for i, path in enumerate(paths):
                (d / f"paths{i}.json").write_text(json.dumps({"checks": [path]}))
            command = [sys.executable, str(Path(__file__).with_name("repair_input_hold.py")),
                       "--netlist", str(d / "design.v"), "--liberty", str(d / "library.lib"),
                       "--checks", str(d / "paths0.json"), "--checks", str(d / "paths1.json"),
                       "--buffer", "BUF", "--source-branches", "--output-branches", "--output-stages", "1",
                       "--output", str(d / "out.v"), "--manifest", str(d / "changes.json")]
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            info = json.loads((d / "changes.json").read_text())
            self.assertEqual(info["buffer_count"], 2)
            self.assertEqual(info["endpoints"][0]["endpoints"], ["reg0/D", "reg1/D"])


if __name__ == "__main__":
    unittest.main()
