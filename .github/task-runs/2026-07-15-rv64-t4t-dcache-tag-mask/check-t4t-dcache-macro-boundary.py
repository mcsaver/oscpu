#!/usr/bin/env python3
"""Audit the synthesized D-cache tag-mask owner boundary."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
from pathlib import Path


def require_regular(path: Path) -> None:
    if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
        raise SystemExit(f"invalid regular input: {path}")


def extract_bus(instance: str, port: str) -> list[str]:
    match = re.search(
        rf"\.{re.escape(port)}\(\{{\s*(.*?)\s*\}}\)",
        instance,
        flags=re.DOTALL,
    )
    if not match:
        raise SystemExit(f"missing braced port: {port}")
    return [token.strip() for token in match.group(1).split(",")]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("netlist", type=Path)
    parser.add_argument("--json-out", required=True, type=Path)
    args = parser.parse_args()

    require_regular(args.netlist)
    text = args.netlist.read_text(encoding="utf-8")
    modules = re.findall(
        r"^module OooDataWordCache\(.*?^endmodule\s*$",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    if len(modules) != 1:
        raise SystemExit(f"expected one OooDataWordCache module, got {len(modules)}")
    module = modules[0]

    macro_matches = re.findall(
        r"^\s*Sram4096x113\s+u_sram\s*\(\s*(.*?)^\s*\);",
        module,
        flags=re.MULTILINE | re.DOTALL,
    )
    if len(macro_matches) != 1:
        raise SystemExit(
            "expected one Sram4096x113 u_sram instance, "
            f"got {len(macro_matches)}"
        )
    macro = macro_matches[0]
    wdata = extract_bus(macro, "wdata_i")
    wmask = extract_bus(macro, "wmask_i")
    if len(wdata) != 113 or len(wmask) != 113:
        raise SystemExit(
            f"unexpected SRAM bus widths: wdata={len(wdata)} wmask={len(wmask)}"
        )

    tie_high_nets = {
        token.strip()
        for token in re.findall(
            r"^\s*TIEHI\w*\s+\S+\s*\(\s*\.Z\(([^)]+)\)\s*\);",
            module,
            flags=re.MULTILINE | re.DOTALL,
        )
    }
    literal_high = {"1'b1", "1'h1", "1'd1"}
    tag_wmask = wmask[:49]  # emitted MSB first: SRAM bits 112:64
    tag_wdata = wdata[:49]
    non_high_tag_mask = [
        {"bit": 112 - index, "token": token}
        for index, token in enumerate(tag_wmask)
        if token not in tie_high_nets and token not in literal_high
    ]
    if non_high_tag_mask:
        raise SystemExit(f"tag wmask is not entirely tie-high: {non_high_tag_mask[:4]}")

    direct_fill_wmask_bits = [
        112 - index for index, token in enumerate(wmask) if token == "fill_we_w"
    ]
    direct_fill_wdata_bits = [
        112 - index for index, token in enumerate(wdata) if token == "fill_we_w"
    ]
    if direct_fill_wmask_bits or direct_fill_wdata_bits:
        raise SystemExit(
            "fill_we_w still directly drives SRAM payload/mask pins: "
            f"wmask={direct_fill_wmask_bits} wdata={direct_fill_wdata_bits}"
        )

    bridge_modules = re.findall(
        r"^module OooMemAxiBridge\(.*?^endmodule\s*$",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    if len(bridge_modules) != 1:
        raise SystemExit(f"expected one OooMemAxiBridge module, got {len(bridge_modules)}")
    bridge = bridge_modules[0]
    dcache_instances = re.findall(
        r"^\s*OooDataWordCache\s+u_dcache\s*\(\s*(.*?)^\s*\);",
        bridge,
        flags=re.MULTILINE | re.DOTALL,
    )
    if len(dcache_instances) != 1:
        raise SystemExit(
            f"expected one OooDataWordCache u_dcache instance, got {len(dcache_instances)}"
        )
    fill_connection = re.search(
        r"\.fill_valid_i\(([^)]+)\)", dcache_instances[0]
    )
    if not fill_connection:
        raise SystemExit("missing OooDataWordCache fill_valid_i connection")
    fill_control_net = fill_connection.group(1).strip()

    instance_re = re.compile(
        r"^\s*(?P<cell>[A-Za-z0-9_$\\]+)\s+(?P<inst>\\?\S+)\s*"
        r"\(\s*(?P<body>.*?)^\s*\);",
        flags=re.MULTILINE | re.DOTALL,
    )
    drivers: list[tuple[str, str, str]] = []
    for match in instance_re.finditer(bridge):
        if match.group("cell") == "module":
            continue
        output = re.search(
            rf"\.([YQZ])\({re.escape(fill_control_net)}\)",
            match.group("body"),
        )
        if output:
            drivers.append((match.group("cell"), match.group("inst"), output.group(1)))
    if len(drivers) != 1:
        raise SystemExit(
            f"expected one {fill_control_net} producer driver, got {drivers}"
        )
    driver_cell, driver_inst, driver_port = drivers[0]
    driver_pin = f"u_core/u_ooo_mem_bridge/{driver_inst}/{driver_port}"

    result = {
        "schema": "t4t-dcache-macro-boundary-v1",
        "netlist": str(args.netlist.resolve()),
        "netlist_sha256": hashlib.sha256(args.netlist.read_bytes()).hexdigest(),
        "driver_cell": driver_cell,
        "driver_pin": driver_pin,
        "driver_role": "dcache_fill_valid_producer",
        "fill_control_net": fill_control_net,
        "direct_fill_wmask_bits": direct_fill_wmask_bits,
        "direct_fill_wdata_bits": direct_fill_wdata_bits,
        "tag_wmask_tied_high": True,
        "tag_wmask_width": len(tag_wmask),
        "tag_wdata_direct_fill_count": sum(token == "fill_we_w" for token in tag_wdata),
        "tie_high_net_count": len(tie_high_nets),
    }
    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        "[T4T-DCACHE-MACRO] PASS "
        f"fill_producer={driver_pin} tag_mask=tie-high direct_fill_macro_loads=0"
    )


if __name__ == "__main__":
    main()
