#!/usr/bin/env python3
"""Prepare observation-equivalent RTL copies for word-level model backends.

Only testbench observations and simulator assertion syntax are adapted.
The production source tree is never edited.
"""

from pathlib import Path
import json
import re
import subprocess
from cxxrtl_observation import adapt_checks, sub_once

ROOT = Path(__file__).resolve().parents[3]


def prepare_sources(out, root=ROOT):
    out = Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    top = root / "npc/rv64/sim/vsrc/R64SystemTestTop.sv"
    src = top.read_text()
    # Keep every DUT connection, registered retirement and exact CSR observation.
    # Optional textual debug and occupancy reporting are outside this adapter.
    debug = re.search(
        r"(?m)^[ \t]*always\s*@\(\s*posedge\s+clk_i\s*\)\s*if\s*\(\s*!\s*rst_i\s*&&\s*\$test\$plusargs",
        src,
    )
    if debug is None:
        raise ValueError("Missing optional debug block")
    src = src[: debug.start()] + '\nendmodule\n' + chr(96) + 'undef R64_SYSTEM_HIER\n'
    # 按完整赋值提取，保留换行后的 RHS，范围止于本条赋值的分号。
    snapshot_pattern = r"(?m)^[ \t]*assign\s+csr_snapshot_o\s*\[[^\]\n]+\]\s*=[^;]+;"
    snapshot = "\n".join(re.findall(snapshot_pattern, src))
    if not snapshot:
        raise ValueError("Missing CSR snapshot assignments")
    snapshot = snapshot.replace("csr_snapshot_o", "model_snapshot_o")
    snapshot = snapshot.replace(chr(96) + "R64_SYSTEM_HIER.core.csr.", "")
    snapshot = snapshot.replace(chr(96) + "R64_SYSTEM_HIER.core.", "")
    snapshot = snapshot.replace("trigger_address;", "trigger_address_o;")
    src = re.sub(snapshot_pattern, "", src)
    src = src.replace(
        "  .clk_i(clk_i),", "  .model_snapshot_o(csr_snapshot_o),\n  .clk_i(clk_i),", 1
    )
    (out / "R64SystemTestTop.sv").write_text(src)
    files = subprocess.check_output(
        ["make", "-s", "-C", str(root / "npc/rv64"), "print-synth-rtl"], text=True
    ).split()
    incs = [
        root / "npc/rv64/vsrc/include",
        root / "npc/rv64/vsrc/backend",
        root / "npc/rv64/vsrc/platform",
    ]
    adapted = []
    assertions = []
    for name in files:
        f = Path(name)
        data = f.read_text()

        def adapt(m):
            assertions.append(
                {
                    "source": str(f.relative_to(root)),
                    "line": data[: m.start()].count("\n") + 1,
                    "message": m.group(1),
                }
            )
            return "assert (1'b0)"

        data, n = re.subn(
            r'\$fatal\(\s*1\s*,\s*("(?:[^"\\\\]|\\\\.)*")(?:\s*,[^;]*)?\s*\)', adapt, data
        )
        if "$fatal" in data:
            print([line for line in data.splitlines() if "$fatal" in line])
            raise RuntimeError("Unsupported fatal form in " + name)
        data = re.sub(
            r'\$onehot\((\w+)\)',
            lambda m: "((" + m[1] + "!=0) && ((" + m[1] + " & (" + m[1] + "-1'b1))==0))",
            data,
        )
        if f.name in ("R64Csr.v", "R64CoreTop.v", "R64SystemTop.v"):
            data = sub_once(
                r"(?m)^([ \t]*)input\s+clk_i\s*,",
                lambda m: m[1] + "output [1727:0] model_snapshot_o,\n" + m[0],
                data,
            )
            if f.name == "R64Csr.v":
                data = data.replace("endmodule", snapshot + "\nendmodule")
            elif f.name == "R64CoreTop.v":
                data = sub_once(
                    r"\bR64Csr\s+csr\s*\(",
                    lambda m: m[0] + ".model_snapshot_o(model_snapshot_o),",
                    data,
                )
            else:
                data = sub_once(
                    r"\bR64CoreTop\s+core\s*\(",
                    lambda m: m[0] + ".model_snapshot_o(model_snapshot_o),",
                    data,
                )
        if f.name in (
            "R64Rob.v",
            "R64Rename.v",
            "R64Issue.v",
            "R64RegRead.v",
            "R64Execute.v",
            "R64NumericOwner.v",
            "R64Alu.v",
        ):
            data = re.sub(r'(?m)^module ', '(* keep_hierarchy = 0 *) module ', data)
        data = adapt_checks(data, f.name)
        target = out / "sources" / f.relative_to(root)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(data)
        adapted.append(str(target))
    # Source-only adaptation, retaining each failure condition and clocking.
    (out / "assertions.json").write_text(json.dumps(assertions, indent=2))
    files = adapted
    return files, incs
