import unittest
from pathlib import Path

from repair_ecos_macro_hold import (declarations, expand, library_model, repair,
                                   verify)

MACRO = "ics55_ecos_sram_256x128_m4_ww"
LIB = """
type (Data_127_0) { bit_width: 128; bit_from: 127; bit_to: 0; downto: true; }
type (Addr_7_0) { bit_width: 8; bit_from: 7; bit_to: 0; downto: true; }
type (MAR_3_0) { bit_width: 4; bit_from: 3; bit_to: 0; downto: true; }
cell (DLY4X2H7L) {
 area: 2.8;
 pin (A) { direction: input; }
 pin (Y) { direction: output; function: "A"; }
}
cell (DFFQX1H7L) {
 area: 4;
 ff (IQ, IQN) { next_state: "D"; clocked_on: "CK"; }
 pin (D) { direction: input; }
 pin (CK) { direction: input; }
 pin (Q) { direction: output; function: "IQ"; }
}
cell (ics55_ecos_sram_256x128_m4_ww) {
 area: 100;
 pin (CLK) { direction: input; clock: true; }
 pin (CEB) { direction: input; timing() { related_pin: "CLK"; timing_type: hold_rising; } }
 pin (GWEB) { direction: input; timing() { related_pin: "CLK"; timing_type: hold_rising; } }
 pin (MARE) { direction: input; }
 bus (A) { bus_type: Addr_7_0; direction: input;
  pin(A[7:0]) { timing() { related_pin: "CLK"; timing_type: hold_rising; } }
 }
 bus (MAR) { bus_type: MAR_3_0; direction: input; }
 bus (D) { bus_type: Data_127_0; direction: input;
  memory_write() { address: A; clocked_on: "CLK"; }
  pin(D[127:0]) {
   timing() { related_pin: "CLK"; when: "!CEB & !GWEB"; timing_type: hold_rising; }
  }
 }
 bus (Q) { bus_type: Data_127_0; direction: output; }
}
"""
NET = """module top(clk, data, q0, q1);
  input clk;
  input data;
  output [127:0] q0;
  output [127:0] q1;
  wire [63:0] low;
  wire [63:0] high;
  wire shared;
  DFFQX1H7L low_ff0 (.CK(clk), .D(data), .Q(low[0]));
  DFFQX1H7L low_ff63 (.CK(clk), .D(data), .Q(low[63]));
  DFFQX1H7L high_ff63 (.CK(clk), .D(data), .Q(high[63]));
  DFFQX1H7L spectator (.CK(clk), .D(low[0]), .Q(shared));
  ics55_ecos_sram_256x128_m4_ww way0 (
    .CLK(clk), .CEB(1'b0), .GWEB(1'b0), .MARE(1'b0),
    .A(8'h00), .MAR(4'h0), .D({ high, low }), .Q(q0)
  );
  ics55_ecos_sram_256x128_m4_ww way1 (
    .CLK(clk), .CEB(1'b0), .GWEB(1'b0), .MARE(1'b0),
    .A(8'h00), .MAR(4'h0), .D({ high, low }), .Q(q1)
  );
endmodule
"""


def path(bit=0, way="way0"):
    ff, net = {0: ("low_ff0", "low[0]"), 63: ("low_ff63", "low[63]"),
               127: ("high_ff63", "high[63]")}[bit]
    endpoint = f"{way}/D[{bit}]"
    return {"path_type": "min", "slack": -3.1e-10, "startpoint": ff + "/Q",
            "endpoint": endpoint, "source_path": [
                {"instance": ff, "cell": "DFFQX1H7L", "pin": ff + "/Q", "net": net},
                {"instance": way, "cell": MACRO, "pin": endpoint, "net": net}]}


BIT_MACRO = "ics55_ecos_sram_256x64_m4"
BIT_LIB = """
type (Data_63_0) { bit_width: 64; bit_from: 63; bit_to: 0; downto: true; }
""" + LIB[LIB.index("cell (" + MACRO + ")"):].replace(
    MACRO, BIT_MACRO).replace("Data_127_0", "Data_63_0").replace(
    "D[127:0]", "D[63:0]").replace(" bus (Q)", """
 bus (WEB) { bus_type: Data_63_0; direction: input;
  pin(WEB[63:0]) { timing() { related_pin: "CLK"; timing_type: hold_rising; } }
 }
 bus (Q)""")
CONTROL_NET = NET.replace(".A(8'h00)", ".A({7'h0, low[0]})").replace(
    ".CEB(1'b0)", ".CEB(low[0])").replace(".GWEB(1'b0)", ".GWEB(low[0])")
_left, _right = CONTROL_NET.split("  " + MACRO + " way1", 1)
MIXED_NET = (_left + "  " + BIT_MACRO + " way1" + _right.replace(
    ".D({ high, low })", ".D(low), .WEB(low)").replace(".Q(q1)", ".Q(q1[63:0])"))


def input_path(pin, bit=None, way="way0", macro=MACRO, source_bit=0):
    check = path(source_bit, way)
    endpoint = way + "/" + pin + ("" if bit is None else "[" + str(bit) + "]")
    check["endpoint"] = check["source_path"][-1]["pin"] = endpoint
    check["source_path"][-1]["cell"] = macro
    return check


class EcosMacroHoldTests(unittest.TestCase):
    def transform(self, paths=None, net=NET, libs=None, **kwargs):
        return repair(net, {"checks": paths or [path()]}, libs or [LIB], [MACRO], **kwargs)

    def test_vector_multibit_sink_only_and_actual_area(self):
        out, info = self.transform([path(0), path(63), path(127)])
        self.assertEqual(info["buffer_count"], 9)
        self.assertAlmostEqual(info["extra_cell_area_um2"], 25.2)
        self.assertAlmostEqual(info["original_cell_area_um2"], 216)
        self.assertAlmostEqual(info["repaired_cell_area_um2"], 241.2)
        self.assertGreater(info["checked_original_pin_bits"], 500)
        self.assertIn("DFFQX1H7L spectator (.CK(clk), .D(low[0]), .Q(shared));", out)
        self.assertEqual(out.count(".D({ high, low })"), 1)  # other way unchanged
        for original in ("low[0]", "low[63]", "high[63]"):
            self.assertEqual(sum(x["original"] == original for x in info["endpoints"]), 1)
        self.assertEqual(out.count(".CLK(clk)"), 2)
        # Explicit MSB ordering: bit 127 first, bit 63 at index 64, bit 0 last.
        from repair_input_hold import parse_cells
        expression = parse_cells(out)["way0"][1]["D"]
        bits = expand(expression, declarations(out))
        for entry in info["endpoints"]:
            bit = int(entry["endpoint"].split("[")[1][:-1])
            self.assertEqual(bits[127-bit], entry["chain"][-1]["y"])

    def test_same_endpoint_rise_fall_paths_share_one_chain(self):
        out, info = self.transform([path(), path()])
        self.assertEqual(info["buffer_count"], 3)
        self.assertEqual(len(info["endpoints"]), 1)

    def test_nested_concat_and_part_select_match_bus_bit(self):
        net = NET.replace("{ high, low }", "{ high[63:32], {high[31:0], low[63:1]}, low[0] }")
        _, info = self.transform([path(0), path(63), path(127)], net=net)
        self.assertEqual(info["buffer_count"], 9)

    def test_missing_or_illegal_bit_rejected(self):
        for bad in ["way0/D[128]", "way0/D[-1]"]:
            check = path()
            check["endpoint"] = check["source_path"][-1]["pin"] = bad
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                self.transform([check])

    def test_stale_source_cell_net_or_endpoint_rejected(self):
        cases = []
        p = path(); p["source_path"][-1]["net"] = "low[1]"; cases.append(p)
        p = path(); p["source_path"][0]["net"] = "low[1]"; cases.append(p)
        p = path(); p["source_path"][0]["cell"] = "OLD_FF"; cases.append(p)
        p = path(); p["startpoint"] = "old_ff/Q"; cases.append(p)
        p = path(); p["endpoint"] = "way0/D[63]"; cases.append(p)
        p = path(); p["endpoint"] = p["source_path"][-1]["pin"] = "old_way/D[0]"; cases.append(p)
        for check in cases:
            with self.subTest(check=check), self.assertRaises(ValueError):
                self.transform([check])

    def test_non_data_and_positive_paths_unchanged(self):
        for target in ["way0/CLK", "way0/A[0]", "spectator/D"]:
            p = path(); p["endpoint"] = target
            p["source_path"][-1]["pin"] = target
            if target.startswith("spectator/"):
                p["source_path"][-1]["cell"] = "DFFQX1H7L"
                p["source_path"][-1]["instance"] = "spectator"
            out, info = self.transform([p])
            self.assertEqual(out, NET)
            self.assertEqual(info["buffer_count"], 0)
            self.assertEqual(len(info["unhandled_negative_checks"]), 1)
        p = path(); p["slack"] = 0.1
        out, info = self.transform([p])
        self.assertEqual(out, NET)
        self.assertEqual(info["buffer_count"], 0)

    def test_width_unknown_expression_and_direction_rejected(self):
        for net in [NET.replace("{ high, low }", "low"),
                    NET.replace("{ high, low }", "{high, low ^ 64'h0}"),
                    NET.replace("{ high, low }", "{high, low[0:63]}")]:
            with self.subTest(net=net), self.assertRaises(ValueError):
                self.transform(net=net)

    def test_missing_driver_duplicate_driver_and_internal_clock_source_rejected(self):
        for net in [NET.replace(".Q(low[0])", ".Q(high[0])"),
                    NET.replace(".Q(shared)", ".Q(low[0])")]:
            with self.subTest(net=net), self.assertRaises(ValueError):
                self.transform(net=net)
        p = path(); p["startpoint"] = p["source_path"][0]["pin"] = "low_ff0/CK"
        p["source_path"][0]["net"] = "clk"
        with self.assertRaises(ValueError):
            self.transform([p])

    def test_inverter_sequential_delay_wrong_macro_contract_rejected(self):
        for lib in [LIB.replace('function: "A"', 'function: "!A"'),
                    LIB.replace("area: 2.8;", 'area: 2.8; ff(IQ, IQN) { next_state: "A"; }'),
                    LIB.replace("memory_write()", "memory_read()")]:
            with self.subTest(lib=lib), self.assertRaises(ValueError):
                self.transform(libs=[lib])

    def test_no_silent_repair_of_already_repaired_parent(self):
        out, _ = self.transform()
        with self.assertRaises(ValueError):
            self.transform(net=out)

    def test_escaped_identifiers_and_ascending_vector_expansion(self):
        nets = declarations("  wire [0:3] asc;\n  wire \\cell.net ;\n")
        self.assertEqual(expand("{asc, \\cell.net }", nets),
                         ["asc[0]", "asc[1]", "asc[2]", "asc[3]", "\\cell.net "])
        self.assertEqual(expand("4'h9", nets), ["1'b1", "1'b0", "1'b0", "1'b1"])
        self.assertEqual(expand("4'bxxxx", nets), ["1'bx"] * 4)

    def test_full_graph_checker_rejects_non_target_bit_swap(self):
        out, info = self.transform()
        from repair_input_hold import parse_cells
        before, after = parse_cells(NET), parse_cells(out)
        old, new = before["way0"][0][0], after["way0"][0][0]
        added = out[out.index("  wire r64_ecos_data_hold_net_0_0;"):out.index("endmodule")]
        # Pretend both modified cells were authorized text edits; connectivity
        # comparison must still catch a non-target vector swap.
        bad_old = before["way1"][0][0]
        bad_new = bad_old.replace("{ high, low }", "{low, high}")
        bad = out.replace(bad_old, bad_new)
        with self.assertRaisesRegex(ValueError, "Original cell/pin connectivity"):
            verify(NET, bad, library_model([LIB]), "DLY4X2H7L", info["endpoints"],
                   [(old, new), (bad_old, bad_new)], added)


    def test_explicit_top_input_launch_preserves_other_branches(self):
        net = NET.replace("  input data;", "  input data;\n  input [63:0] incoming;")
        net = net.replace("{ high, low }", "{ incoming, low }")
        check = path(127)
        check["startpoint"] = "incoming[63]"
        check["source_path"][0] = {"instance": "", "cell": "top", "pin": "incoming[63]"}
        check["source_path"][-1]["net"] = "incoming[63]"
        out, info = self.transform([check], net=net)
        self.assertEqual(info["buffer_count"], 3)
        self.assertIn(".D({ incoming, low })", out)
        self.assertEqual(info["endpoints"][0]["original"], "incoming[63]")
        for field, bad in [("cell", "old_top"), ("pin", "incoming[64]"), ("net", "data")]:
            altered = dict(check, source_path=[dict(node) for node in check["source_path"]])
            altered["source_path"][0][field] = bad
            if field == "pin":
                altered["startpoint"] = bad
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.transform([altered], net=net)

    def test_scalar_and_vector_controls_same_instance_only_selected_sinks_change(self):
        checks = [input_path("A", 0), input_path("CEB"), input_path("GWEB"), path()]
        out, info = self.transform(checks, net=CONTROL_NET, macro_pins=["A", "CEB", "GWEB"])
        self.assertEqual(info["buffer_count"], 9)
        self.assertEqual(info["macro_pins"], ["A", "CEB", "GWEB"])
        self.assertEqual(info["unhandled_negative_checks"][0]["endpoint"], "way0/D[0]")
        from repair_input_hold import parse_cells
        before, after = parse_cells(CONTROL_NET), parse_cells(out)
        self.assertEqual(before["way1"][0][0], after["way1"][0][0])
        for pin in ("D", "Q", "CLK", "MARE", "MAR"):
            self.assertEqual(before["way0"][1][pin], after["way0"][1][pin])
        for entry in info["endpoints"]:
            pin = entry["endpoint"].split("/")[1].split("[")[0]
            bits = expand(after["way0"][1][pin], declarations(out))
            self.assertEqual(bits[-1], entry["chain"][-1]["y"])
        self.assertIn("DFFQX1H7L spectator (.CK(clk), .D(low[0]), .Q(shared));", out)

    def test_mixed_macro_optional_web_and_multiple_pin_selection(self):
        checks = [path(), input_path("A", 0), input_path("GWEB", way="way1", macro=BIT_MACRO),
                  input_path("WEB", 0, "way1", BIT_MACRO),
                  input_path("WEB", 63, "way1", BIT_MACRO, 63)]
        out, info = repair(MIXED_NET, {"checks": checks}, [LIB + BIT_LIB],
                           [MACRO, BIT_MACRO], macro_pins=["D", "A", "WEB", "GWEB", "CEB"])
        self.assertEqual(info["buffer_count"], 15)
        self.assertEqual(len(info["unhandled_negative_checks"]), 0)
        from repair_input_hold import parse_cells
        self.assertNotIn("WEB", parse_cells(out)["way0"][1])
        web = expand(parse_cells(out)["way1"][1]["WEB"], declarations(out))
        entries = {entry["endpoint"]: entry for entry in info["endpoints"]}
        self.assertEqual(web[0], entries["way1/WEB[63]"]["chain"][-1]["y"])
        self.assertEqual(web[-1], entries["way1/WEB[0]"]["chain"][-1]["y"])
        # Requesting a valid heterogeneous pin with no actual negative endpoint is a no-op.
        out, info = repair(MIXED_NET, {"checks": [path()]}, [LIB + BIT_LIB],
                           [MACRO, BIT_MACRO], macro_pins=["WEB"])
        self.assertEqual(out, MIXED_NET)
        self.assertEqual(info["buffer_count"], 0)
        self.assertEqual(len(info["unhandled_negative_checks"]), 1)

    def test_requested_unknown_clock_output_empty_or_globally_absent_pin_rejected(self):
        for pins in [[], ["CLK"], ["Q"], ["MARE"], ["unknown"], ["D", "CLK"], ["WEB"]]:
            with self.subTest(pins=pins), self.assertRaises(ValueError):
                self.transform(macro_pins=pins)

    def test_reported_web_on_macro_without_that_port_rejected(self):
        check = input_path("WEB", 0)
        with self.assertRaisesRegex(ValueError, "absent from its actual Liberty"):
            repair(MIXED_NET, {"checks": [check]}, [LIB + BIT_LIB],
                   [MACRO, BIT_MACRO], macro_pins=["WEB"])

    def test_scalar_vector_report_shapes_and_hold_coverage_rejected(self):
        for check, pins in [(input_path("CEB", 0), ["CEB"]),
                            (input_path("A"), ["A"]),
                            (input_path("A", 8), ["A"]),
                            (input_path("A", -1), ["A"])]:
            with self.subTest(check=check), self.assertRaises(ValueError):
                self.transform([check], net=CONTROL_NET, macro_pins=pins)
        lib = LIB.replace("pin(A[7:0])", "pin(A[7:1])")
        with self.assertRaisesRegex(ValueError, "Endpoint bit lacks"):
            self.transform([input_path("A", 0)], net=CONTROL_NET, libs=[lib], macro_pins=["A"])

    def test_control_pin_direction_clock_and_actual_hold_related_pin_required(self):
        for lib in [LIB.replace('related_pin: "CLK"', 'related_pin: "CEB"'),
                    LIB.replace("timing_type: hold_rising", "timing_type: setup_rising"),
                    LIB.replace("Addr_7_0; direction: input", "Addr_7_0; direction: output"),
                    LIB.replace("Addr_7_0; direction: input", "Addr_7_0; clock: true; direction: input")]:
            with self.subTest(lib=lib), self.assertRaises(ValueError):
                self.transform([input_path("A", 0)], net=CONTROL_NET, libs=[lib], macro_pins=["A"])

    def test_explicit_controls_do_not_require_unselected_d_memory_write(self):
        _, info = self.transform([input_path("CEB")], net=CONTROL_NET,
                                 libs=[LIB.replace("memory_write()", "memory_read()")],
                                 macro_pins=["CEB"])
        self.assertEqual(info["buffer_count"], 3)
        with self.assertRaises(ValueError):
            self.transform(net=CONTROL_NET, libs=[LIB.replace("memory_write()", "memory_read()")],
                           macro_pins=["D", "CEB"])

    def test_control_top_input_through_logic_checks_entire_path(self):
        net = CONTROL_NET.replace(".CEB(low[0])", ".CEB(control)").replace(
            "  wire shared;", """  wire shared;
  wire control;
  DLY4X2H7L control_buffer (.A(data), .Y(control));""")
        check = input_path("CEB")
        check["startpoint"] = "data"
        check["source_path"] = [
            {"instance": "", "cell": "top", "pin": "data"},
            {"instance": "control_buffer", "cell": "DLY4X2H7L", "pin": "control_buffer/A", "net": "data"},
            {"instance": "control_buffer", "cell": "DLY4X2H7L", "pin": "control_buffer/Y", "net": "control"},
            {"instance": "way0", "cell": MACRO, "pin": "way0/CEB", "net": "control"}]
        out, info = self.transform([check], net=net, macro_pins=["CEB"])
        self.assertEqual(info["buffer_count"], 3)
        self.assertIn(".CEB(control)", out)  # second macro's branch unchanged
        altered = dict(check, source_path=[dict(node) for node in check["source_path"]])
        altered["source_path"][1]["net"] = "low[0]"
        with self.assertRaises(ValueError):
            self.transform([altered], net=net, macro_pins=["CEB"])
        # A second driver before the last buffer is invalid too, not just at the sink.
        bad_net = net.replace(".Q(shared)", ".Q(data)")
        with self.assertRaisesRegex(ValueError, "missing/multiple drivers"):
            self.transform([check], net=bad_net, macro_pins=["CEB"])

    def test_full_graph_checker_rejects_delaying_unselected_same_net_branch(self):
        out, info = self.transform([input_path("CEB")], net=CONTROL_NET, macro_pins=["CEB"])
        from repair_input_hold import parse_cells
        before, after = parse_cells(CONTROL_NET), parse_cells(out)
        old, new = before["way0"][0][0], after["way0"][0][0]
        # This unauthorized GWEB change contracts to the same original low[0].
        bad_new = new.replace(".GWEB(low[0])", ".GWEB(" + info["endpoints"][0]["chain"][-1]["y"] + ")")
        bad = out.replace(new, bad_new)
        added = out[out.index("  wire r64_ecos_data_hold_net_0_0;"):out.index("endmodule")]
        with self.assertRaisesRegex(ValueError, "Non-target sink changed"):
            verify(CONTROL_NET, bad, library_model([LIB]), "DLY4X2H7L", info["endpoints"],
                   [(old, bad_new)], added)

    def test_per_pin_mixed_scalar_vector_stages_and_area(self):
        checks = [path(), input_path("D", 63, "way1", BIT_MACRO, 63),
                  input_path("A", 0), input_path("WEB", 0, "way1", BIT_MACRO),
                  input_path("GWEB"), input_path("CEB")]
        out, info = repair(MIXED_NET, {"checks": checks}, [LIB + BIT_LIB],
                           [MACRO, BIT_MACRO], macro_pins=["D", "A", "WEB", "GWEB", "CEB"],
                           pin_stages=["A=1", "WEB=1", "GWEB=1", "CEB=1"])
        self.assertEqual(info["stages"], 3)
        self.assertEqual(info["effective_pin_stages"], {"D": 3, "A": 1, "WEB": 1, "GWEB": 1, "CEB": 1})
        self.assertEqual(info["pin_stages"], {"A": 1, "WEB": 1, "GWEB": 1, "CEB": 1})
        self.assertEqual(info["buffer_count"], 10)
        self.assertAlmostEqual(info["extra_cell_area_um2"], 28)
        for entry in info["endpoints"]:
            expected = 3 if entry["pin"] == "D" else 1
            self.assertEqual(entry["stages"], expected)
            self.assertEqual(len(entry["chain"]), expected)
        self.assertEqual(out.count(".CLK(clk)"), 2)
        self.assertIn("DFFQX1H7L spectator (.CK(clk), .D(low[0]), .Q(shared));", out)

    def test_per_pin_default_compatibility_bounds_and_same_duplicate(self):
        original, original_info = self.transform()
        repeated, repeated_info = self.transform(pin_stages=["D=3", "D=3"])
        self.assertEqual(original, repeated)
        self.assertEqual(original_info["effective_pin_stages"], {"D": 3})
        self.assertEqual(original_info["buffer_count"], repeated_info["buffer_count"])
        for stages in (1, 8):
            _, info = self.transform(pin_stages=["D=" + str(stages)])
            self.assertEqual(info["buffer_count"], stages)
            self.assertEqual(info["endpoints"][0]["stages"], stages)
        # A global override still applies to every pin without a per-pin value.
        _, info = self.transform([path(), input_path("CEB")], net=CONTROL_NET,
                                 macro_pins=["D", "CEB"], stages=2, pin_stages=["CEB=1"])
        self.assertEqual(info["effective_pin_stages"], {"D": 2, "CEB": 1})
        self.assertEqual(info["buffer_count"], 3)

    def test_per_pin_invalid_count_conflict_unknown_and_unselected_rejected(self):
        for values in [["D=0"], ["D=9"], ["D=-1"], ["D=1.5"], ["D=x"], ["D=1=2"],
                       ["D=1", "D=2"], ["CLK=1"], ["Q=1"], ["unknown=1"], ["A=1"]]:
            with self.subTest(values=values), self.assertRaises(ValueError):
                self.transform(pin_stages=values)
        for stages in (0, 9, 1.5, True):
            with self.subTest(stages=stages), self.assertRaises(ValueError):
                self.transform(stages=stages)

    def test_per_pin_selected_without_negative_endpoint_remains_noop(self):
        out, info = self.transform([path()], net=CONTROL_NET, macro_pins=["CEB"],
                                   pin_stages=["CEB=1"])
        self.assertEqual(out, CONTROL_NET)
        self.assertEqual(info["effective_pin_stages"], {"CEB": 1})
        self.assertEqual(info["buffer_count"], 0)
        self.assertEqual(info["endpoints"], [])
        # Invalid metadata must fail even though there would be no selected path.
        with self.assertRaises(ValueError):
            self.transform([path()], net=CONTROL_NET, macro_pins=["CEB"], pin_stages=["CEB=9"])

    def test_checker_rejects_stage_metadata_mismatch(self):
        out, info = self.transform(pin_stages=["D=1"])
        from repair_input_hold import parse_cells
        before, after = parse_cells(NET), parse_cells(out)
        old, new = before["way0"][0][0], after["way0"][0][0]
        added = out[out.index("  wire r64_ecos_data_hold_net_0_0;"):out.index("endmodule")]
        info["endpoints"][0]["stages"] = 3
        with self.assertRaisesRegex(ValueError, "Manifest stages differ"):
            verify(NET, out, library_model([LIB]), "DLY4X2H7L", info["endpoints"], [(old, new)], added)

    def test_real_tt_heterogeneous_control_contract_and_endpoints(self):
        root = Path(__file__).resolve().parents[3]
        standard = root / "yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        macros = list((root / "npc/rv64/third_party/ics55_ecos_sram").glob("*/lib/*tt1p2v25cctyp.lib"))
        libs = [p.read_text() for p in [standard, *macros]]
        checks = [path(), input_path("D", 63, "way1", BIT_MACRO, 63),
                  input_path("A", 0), input_path("A", 0, "way1", BIT_MACRO),
                  input_path("CEB"), input_path("GWEB", way="way1", macro=BIT_MACRO),
                  input_path("WEB", 0, "way1", BIT_MACRO),
                  input_path("WEB", 63, "way1", BIT_MACRO, 63)]
        _, info = repair(MIXED_NET, {"checks": checks}, libs, [MACRO, BIT_MACRO],
                         macro_pins=["D", "A", "WEB", "GWEB", "CEB"])
        self.assertEqual(info["buffer_count"], 24)
        self.assertAlmostEqual(info["extra_cell_area_um2"], 67.2)
        self.assertEqual(len(info["unhandled_negative_checks"]), 0)

    def test_real_tt_libraries_and_ecos_vector_fixture(self):
        root = Path(__file__).resolve().parents[3]
        standard = root / "yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
        macros = list((root / "npc/rv64/third_party/ics55_ecos_sram").glob("*/lib/*tt1p2v25cctyp.lib"))
        libs = [p.read_text() for p in [standard, *macros]]
        out, info = self.transform([path(0), path(63), path(127)], libs=libs)
        self.assertEqual(info["buffer_count"], 9)
        self.assertAlmostEqual(info["extra_cell_area_um2"], 25.2)
        self.assertIn("DLY4X2H7L r64_ecos_data_hold_buf_", out)


if __name__ == "__main__":
    unittest.main()
