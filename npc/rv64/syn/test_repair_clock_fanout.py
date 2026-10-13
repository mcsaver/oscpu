import unittest

from repair_clock_fanout import repair, splice_spans

TABLES = """
  timing () {
    cell_rise (delay) { index_1 ("0.01, 0.8"); index_2 ("0.001, 0.08"); }
    cell_fall (delay) { index_1 ("0.01, 0.8"); index_2 ("0.001, 0.08"); }
    rise_transition (delay) { index_1 ("0.01, 0.8"); index_2 ("0.001, 0.08"); }
    fall_transition (delay) { index_1 ("0.01, 0.8"); index_2 ("0.001, 0.08"); }
  }
"""
LIB = """
library (test) {
 capacitive_load_unit (1, pf);
 time_unit : "1ns";
 lu_table_template (delay) {
  variable_1 : input_net_transition;
  variable_2 : total_output_net_capacitance;
 }
 cell (BUF) {
  area : 2.0;
  pin (A) { direction : input; capacitance : 0.003; }
  pin (Y) { direction : output; function : "A"; max_capacitance : 0.08;
""" + TABLES + """ }
 }
 cell (ICG) {
  area : 6.0;
  clock_gating_integrated_cell : latch_posedge;
  pin (CK) { direction : input; clock_gate_clock_pin : true; capacitance : 0.001; }
  pin (E) { direction : input; clock_gate_enable_pin : true; capacitance : 0.001; }
  pin (TE) { direction : input; capacitance : 0.001; }
  pin (ECK) { direction : output; clock_gate_out_pin : true; max_capacitance : 0.04;
""" + TABLES + """ }
 }
 cell (FF) {
  area : 4.0;
  ff (IQ, IQN) { clocked_on : "CK"; next_state : "D"; }
  pin (CK) { direction : input; clock : true; capacitance : 0.001; }
  pin (D) { direction : input; capacitance : 0.001; }
  pin (Q) { direction : output; }
 }
}
"""


def fixture(count=200, clock="gck"):
    return """module top(clk, en, d);
  input clk;
  input en;
  input d;
  wire gck;
  ICG gate (.CK(clk), .E(en), .TE(1'b0), .ECK(gck));
""" + "".join(f"  FF ff{i} (.CK({clock}), .D(d), .Q(q{i}));\n" for i in range(count)) + "endmodule\n"


class ClockLoadTests(unittest.TestCase):
    def run_repair(self, source=None, lib=LIB, **kwargs):
        return repair(source or fixture(), [lib], buffer="BUF", **kwargs)

    def test_recursive_balanced_tree_and_original_gate(self):
        out, info = self.run_repair()
        self.assertEqual(info["equivalence"].split(":")[0], "PASS")
        self.assertEqual(info["census"]["clock_sink_count"], 200)
        self.assertGreater(info["trees"][0]["depth"], 1)
        self.assertIn("ICG gate (.CK(clk), .E(en), .TE(1'b0), .ECK(gck));", out)
        self.assertLessEqual(max(info["trees"][0]["root_load_pf"]), 0.01)
        self.assertAlmostEqual(info["extra_cell_area_um2"], info["buffer_count"] * 2)

    def test_noop_below_conservative_budget(self):
        source = fixture(5)
        out, info = self.run_repair(source)
        self.assertEqual(out, source)
        self.assertEqual(info["buffer_count"], 0)

    def test_scalar_alias_and_escaped_clock_instance(self):
        source = fixture(clock="\\clock.alias ")
        source = source.replace("endmodule", "  assign \\clock.alias  = gck;\nendmodule")
        source = source.replace("FF ff0", "FF \\ff.escaped ")
        out, info = self.run_repair(source)
        self.assertIn("assign \\clock.alias  = gck;", out)
        self.assertEqual(info["census"]["clock_sink_count"], 200)

    def test_missing_cap_and_mixed_data_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "capacitance"):
            self.run_repair(lib=LIB.replace("clock : true; capacitance : 0.001", "clock : true"))
        with self.assertRaisesRegex(ValueError, "Mixed/non-clock"):
            self.run_repair(fixture().replace(".D(d)", ".D(gck)", 1))

    def test_multiple_drivers_and_opaque_clock_expression_fail(self):
        source = fixture().replace("endmodule", "  FF ffmore (.CK(clk), .D(d), .Q(gck));\nendmodule")
        with self.assertRaisesRegex(ValueError, "multiply driven"):
            self.run_repair(source)
        with self.assertRaisesRegex(ValueError, "Unknown"):
            self.run_repair(fixture().replace(".CK(gck)", ".CK({gck})", 1))

    def test_inverter_missing_cell_and_uncharacterized_fail(self):
        with self.assertRaisesRegex(ValueError, "positive combinational"):
            self.run_repair(lib=LIB.replace('function : "A"', 'function : "!A"'))
        with self.assertRaisesRegex(ValueError, "positive combinational"):
            self.run_repair(lib=LIB.replace('function : "A";', 'function : "A"; three_state : "!A";'))
        with self.assertRaisesRegex(ValueError, "absent"):
            self.run_repair(fixture().replace("FF ff0", "MISSING ff0"))
        with self.assertRaisesRegex(ValueError, "axes"):
            self.run_repair(lib=LIB.replace("total_output_net_capacitance", "related_pin_transition"))

    def test_exported_clock_and_depth_limit_fail(self):
        with self.assertRaisesRegex(ValueError, "exported"):
            self.run_repair(fixture().replace("  wire gck;", "  output gck;"))
        with self.assertRaisesRegex(ValueError, "depth"):
            self.run_repair(max_depth=1)

    def test_unparsed_instance_and_vector_top_fail(self):
        with self.assertRaisesRegex(ValueError, "Unparsed"):
            self.run_repair(fixture().replace("  FF ff0", "FF ff0"))
        with self.assertRaisesRegex(ValueError, "scalar top"):
            self.run_repair(fixture().replace("  input d;", "  input [1:0] d;"))

    def test_linear_span_splice_many_edits_and_exact_inverse(self):
        count = 50000
        source = "prelude;" + "abcdefgh\n" * count + "endmodule\n"
        changes = [(8 + 9 * i + 2, 8 + 9 * i + 5, str(i)) for i in range(count)]
        changes.append((8 + 9 * count, 8 + 9 * count, "added cells\n"))
        changed, reverse = splice_spans(source, changes)
        restored, _ = splice_spans(changed, reverse)
        self.assertEqual(restored, source)
        self.assertEqual(len(reverse), count + 1)
        with self.assertRaisesRegex(ValueError, "edit spans"):
            splice_spans("abc", [(1, 2, ""), (0, 1, "")])

    def test_units_scaled_to_pf_and_ns(self):
        _, a = self.run_repair()
        # Unit scale changes, retaining the same numeric tables/caps: compare
        # after an equivalent change of the explicit pF budget.
        _, b = self.run_repair(lib=LIB.replace("(1, pf)", "(1000, ff)")
                              .replace('"1ns"', '"1000ps"'))
        self.assertEqual(a["buffer_count"], b["buffer_count"])
        self.assertEqual(a["buffer_liberty_limit"], b["buffer_liberty_limit"])


if __name__ == "__main__":
    unittest.main()
