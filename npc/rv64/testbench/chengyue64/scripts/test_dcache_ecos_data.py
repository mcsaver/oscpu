#!/usr/bin/env python3
"""Run the DCache ECOS adapter oracle against cycle and unmodified vendor views."""
import argparse
from pathlib import Path
import subprocess

RV64 = Path(__file__).resolve().parents[3]
MACRO = "ics55_ecos_sram_256x64_m4"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, default=RV64 / "build" / "dcache-ecos-data")
    args = parser.parse_args()
    out = args.build_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    vendor = RV64 / "third_party" / "ics55_ecos_sram" / MACRO / "verilog" / (MACRO + "_core.v")
    # The vendor core omits timescale; its full view uses 10ps/1ps.
    timed_vendor = out / (MACRO + "_vendor.v")
    timed_vendor.write_text("`timescale 10ps/1ps\n" + vendor.read_text())
    sources = [RV64 / "vsrc" / "lsu" / "R64DcacheData.v",
               RV64 / "testbench" / "chengyue64" / "modules" / "tb_r64_dcache_ecos_data.sv"]
    metrics = []
    for kind, macro in [("cycle", RV64 / "sim" / "vsrc" / (MACRO + ".v")),
                        ("vendor", timed_vendor)]:
        binary = out / (kind + ".vvp")
        subprocess.run(["iverilog", "-g2012", "-DR64_ASSERT", "-s",
                        "tb_r64_dcache_ecos_data", "-o", str(binary),
                        str(macro), *map(str, sources)], check=True)
        result = subprocess.run(["vvp", str(binary)], text=True, capture_output=True)
        text = result.stdout + result.stderr
        (out / (kind + ".log")).write_text(text)
        print(kind + ": " + text, end="")
        lines = [line for line in text.splitlines()
                 if line.startswith("[PASS] tb_r64_dcache_ecos_data ")]
        if result.returncode or len(lines) != 1:
            raise RuntimeError(kind + " adapter oracle failed")
        metrics.append(lines[0])
    if metrics[0] != metrics[1]:
        raise RuntimeError("cycle and vendor coverage differ")
    print("[PASS] DCache adapter cycle/vendor coverage identical")


if __name__ == "__main__":
    main()
