#!/usr/bin/env python3
"""Unit cases for canonical and normalized current-RTL warning paths."""

from __future__ import annotations

import importlib.util
import pathlib
import sys


HERE = pathlib.Path(__file__).resolve().parent
ADAPTER = HERE / "f0-warning-audit.py"


def main() -> int:
    spec = importlib.util.spec_from_file_location("v14e_f0_warning_adapter_test", ADAPTER)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load F0 warning path adapter")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    base = module.load_base()
    normalized = (
        "<REPO>/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: returning 'bx "
        "for out of bounds array access entry_addr_w[-1]."
    )
    canonical, adapted = module.canonicalize_line(normalized)
    if not adapted or base.classify_warning_line(canonical) != "ICARUS_CONSTANT_UNSELECTED_GENVAR_ARRAY_INDEX":
        raise RuntimeError("normalized PmpChecker warning did not bind to the canonical source")
    absolute, adapted_absolute = module.canonicalize_line(base.PMP_OOB)
    if adapted_absolute or absolute != base.PMP_OOB:
        raise RuntimeError("canonical warning path was modified")
    array_line = (
        "<REPO>/npc/rv64/vsrc/memory/OooMemInflightQueue.v:191: warning: "
        "@* is sensitive to all 4 words in array 'valid_q'."
    )
    canonical_array, adapted_array = module.canonicalize_line(array_line)
    if not adapted_array or base.classify_warning_line(canonical_array) != "ICARUS_CURRENT_RTL_ARRAY_SENSITIVITY":
        raise RuntimeError("normalized array-sensitivity warning did not bind to current RTL")
    ambiguous = normalized + " " + normalized
    try:
        module.canonicalize_line(ambiguous)
    except ValueError:
        pass
    else:
        raise RuntimeError("ambiguous normalized paths were accepted")
    extended = {
        "<REPO>/npc/rv64/vsrc/memory/OooPmaChecker.v:7: warning: timescale for OooPmaChecker inherited from another file.": "ICARUS_CURRENT_SOURCE_INHERITED_TIMESCALE",
        "tests/tb_ooo_busy_table.sv:28: warning: Instantiating module OooBusyTable with dangling input port 20 (query_raw_preg_i) floating.": "ICARUS_CURRENT_TESTBENCH_DANGLING_INPUT",
        "tests/tb_ooo_alu_core_slice.sv:77: warning: Port 59 (mem_req_wstrb_o) of OooAluCoreSlice expects 8 bits, got 4.": "ICARUS_CURRENT_TESTBENCH_OUTPUT_WIDTH_DIAGNOSTIC",
    }
    for line, expected in extended.items():
        canonical_line, _ = module.canonicalize_line(line)
        if module.classify_extended_warning_line(canonical_line, base) != expected:
            raise RuntimeError(f"extended warning did not bind structurally: {line}")
    malformed = (
        "tests/tb_ooo_busy_table.sv:28: warning: Instantiating module OooBusyTable "
        "with dangling input port 20 (nonexistent_port_i) floating."
    )
    if module.classify_extended_warning_line(malformed, base) is not None:
        raise RuntimeError("nonexistent production input was classified")
    print(
        "[V14E-F0-WARNING-PATH-ADAPTER][PASS] canonical=1/1 normalized_pmp=1/1 "
        "normalized_array=1/1 extended=3/3 malformed_rejected=1/1 "
        "ambiguous_rejected=1/1"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
