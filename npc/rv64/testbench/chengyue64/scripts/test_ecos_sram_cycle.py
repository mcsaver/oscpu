#!/usr/bin/env python3
"""Compare the untimed ECOS cycle view with the vendor delayed core."""
import argparse
from pathlib import Path
import re
import subprocess

RV64 = Path(__file__).resolve().parents[3]
MACRO = "ics55_ecos_sram_256x128_m4_ww"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path,
                        default=RV64 / "build" / "ecos-sram-cycle-test")
    parser.add_argument("--vendor-core", type=Path, default=RV64 / "third_party" /
                        "ics55_ecos_sram" / MACRO / "verilog" / (MACRO + "_core.v"))
    args = parser.parse_args()
    out = args.build_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    original = args.vendor_core.read_text()
    renamed, count = re.subn(r"\bmodule\s+" + MACRO + r"\b",
                             "module " + MACRO + "_reference", original)
    if count != 1:
        raise RuntimeError("expected exactly one vendor module declaration")
    reference = out / (MACRO + "_reference.v")
    # Core-only source has no timescale; use the full vendor view's 10ps/1ps.
    # Vendor statements stay unchanged except for the module declaration.
    reference.write_text("`timescale 10ps/1ps\n" + renamed)
    image = out / "tb_ics55_ecos_sram_cycle.vvp"
    command = [
        "iverilog", "-g2012", "-s", "tb_ics55_ecos_sram_cycle", "-o", str(image),
        str(RV64 / "sim" / "vsrc" / (MACRO + ".v")), str(reference),
        str(RV64 / "testbench" / "chengyue64" / "modules" /
            "tb_ics55_ecos_sram_cycle.sv"),
    ]
    subprocess.run(command, check=True)
    result = subprocess.run(["vvp", str(image)], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out / "result.log").write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode or "[PASS] tb_ics55_ecos_sram_cycle " not in result.stdout:
        raise RuntimeError("vendor cycle comparison failed")


if __name__ == "__main__":
    main()
