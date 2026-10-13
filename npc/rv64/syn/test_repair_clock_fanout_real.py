#!/usr/bin/env python3
"""Optional real TT/OpenSTA 1590-DFF experiment; keeps results and removes products."""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from repair_clock_fanout import repair

ROOT = Path(__file__).resolve().parents[3]
STD = ROOT / "yosys-sta/pdk/icsprout55/IP/STD_cell/ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    libs = [STD] + sorted((ROOT / "npc/rv64/third_party/ics55_ecos_sram").glob("*/lib/*tt1p2v25cctyp.lib"))
    assert len(libs) == 3, "Expected standard cells and both actual TT SRAM libraries"
    products = []
    def product(name, text):
        path = out / name
        assert not path.exists(), "Refuse to overwrite pre-existing experiment product " + str(path)
        products.append(path)
        path.write_text(text)
        return path
    try:
        source = """module clock_load_probe(clk_i, enable_i, d_i, q_o);
  input clk_i;
  input enable_i;
  input d_i;
  output q_o;
  wire gated;
  ICGX0P5H7L gate (.CK(clk_i), .E(enable_i), .ECK(gated));
"""
        for i in range(1590):
            d = "d_i" if i == 0 else f"q{i-1}"
            source += f"  wire q{i};\n  DFFQX1H7L ff{i} (.CK(gated), .D({d}), .Q(q{i}));\n"
        source += "  assign q_o = q1589;\nendmodule\n"
        baseline = product("baseline.v", source)
        updated, info = repair(source, [p.read_text() for p in libs])
        buffered = product("R64CoreTop.sta.v", updated)
        info["input_netlist"] = "Independent 1590-DFF gated shift-register probe, not a full-core census"
        info["liberty_files"] = [str(p.relative_to(ROOT)) for p in libs]
        (out / "cell-changes.json").write_text(json.dumps(info, indent=2) + "\n")
        sdc = product("probe.sdc", "")
        subprocess.run([sys.executable, str(ROOT / "npc/rv64/syn/prepare_sdc.py"),
                        "--netlist", str(baseline), "--template", str(ROOT / "npc/rv64/syn/chengyue64.sdc"),
                        "--output", str(sdc), "--top", "clock_load_probe", "--engine", "opensta"], check=True)
        results = {}
        for variant, netlist in [("baseline", baseline), ("buffered", buffered)]:
            for mode in ("ideal", "propagated"):
                tcl = "\n".join("read_liberty {" + str(p) + "}" for p in libs) + "\n"
                tcl += f"read_verilog {{{netlist}}}\nlink_design clock_load_probe\nread_sdc {{{sdc}}}\n"
                if mode == "propagated":
                    tcl += "set_propagated_clock [all_clocks]\n"
                tcl += """check_setup -verbose
report_worst_slack -max -digits 9
report_worst_slack -min -digits 9
report_checks -path_delay min_max -group_path_count 2 -format full_clock_expanded -fields {slew capacitance fanout} -digits 9
report_check_types -min_period -min_pulse_width -format end -digits 9 -no_line_splits
report_net -digits 9 gated
report_dcalc -from gate/CK -to gate/ECK -max -digits 9
report_slews -digits 9 gate/ECK
report_slews -digits 9 ff0/CK
report_slews -digits 9 ff1589/CK
"""
                if variant == "buffered":
                    leaf = info["trees"][0]["sample_leaf_buffer"]
                    tcl += f"report_slews -digits 9 {leaf}/Y\nreport_dcalc -from {leaf}/A -to {leaf}/Y -max -digits 9\n"
                tcl += "exit\n"
                tag = variant + "-" + mode
                tcl_path = product(tag + ".tcl", tcl)
                p = subprocess.run([str(ROOT / "tool/opensta/bin/sta"), "-exit", str(tcl_path)],
                                   capture_output=True, text=True)
                log = p.stdout + p.stderr
                (out / (tag + ".log")).write_text(log)
                assert p.returncode == 0 and not re.search(r"^Error", log, re.M), log[-3000:]
                pulse = re.search(r"^(ff\S+/CK) \((high|low)\)\s+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)", log, re.M)
                assert pulse, "Native pulse-width report missing"
                results[tag] = {
                    "setup_slack_ns": float(re.search(r"worst slack max ([\d.-]+)", log)[1]),
                    "hold_slack_ns": float(re.search(r"worst slack min ([\d.-]+)", log)[1]),
                    "pulse_pin": pulse[1], "pulse_edge": pulse[2],
                    "pulse_required_ns": float(pulse[3]), "pulse_actual_ns": float(pulse[4]),
                    "pulse_slack_ns": float(pulse[5]),
                    "slews": [line for line in log.splitlines() if re.match(r"^(gate/ECK|ff0/CK|ff1589/CK) \^", line)]}
        commands = ["read_liberty -lib " + str(p) for p in libs]
        commands += ["read_verilog " + str(buffered), "hierarchy -check -top clock_load_probe",
                     "check -mapped -assert", "tee -o " + str(out / "synth_stat.txt") +
                     " stat " + " ".join("-liberty " + str(p) for p in libs)]
        stat_script = product("verify-stat.ys", "\n".join(commands) + "\n")
        p = subprocess.run([str(ROOT / "oss-cad-suite/bin/yosys"), "-Q", "-T", "-s", str(stat_script)],
                           capture_output=True, text=True)
        (out / "stat.log").write_text(p.stdout + p.stderr)
        assert p.returncode == 0, p.stderr
        area = float(re.search(r"Chip area for module .*: ([\d.]+)", (out / "synth_stat.txt").read_text())[1])
        assert abs(area - info["repaired_cell_area_um2"]) < 1e-6
        summary = {
            "scope": "Independent 1590-DFF probe, TT 1.2V 25C, 2ns current SDC including all input/output/uncertainty constraints",
            "unit_tests": "Run test_repair_clock_fanout.py separately",
            "buffer_count": info["buffer_count"], "extra_area_um2": info["extra_cell_area_um2"],
            "yosys_verified_total_area_um2": area, "results": results,
            "limitations": "Pin capacitances without wire parasitics. Not physical CTS or CPU 500MHz closure. Propagated and ideal hold violations remain."}
        (out / "results.json").write_text(json.dumps(summary, indent=2) + "\n")
        print(json.dumps(summary, indent=2))
    finally:
        for path in products:
            path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
