#!/usr/bin/env python3
"""Derive one C0->C1 V9P bridge counterexample from the frozen V9R testbench."""

from __future__ import annotations

import hashlib
import json
import pathlib


ROOT = pathlib.Path(__file__).resolve().parents[3]
RUN = pathlib.Path(
    ".github/task-runs/2026-08-05-rv64-v15g-v9p-terminal-root-cause-backfill"
)
BASE = RUN / (
    "evidence/v9p-exact-source/testbench/npc/rv64/testbench/tests/"
    "tb_ooo_mem_axi_bridge.sv"
)
OUTPUT = RUN / "evidence/v9p-bridge-counterexample/derived/tb_ooo_mem_axi_bridge.sv"
RECEIPT = RUN / "evidence/v9p-bridge-counterexample/derived/receipt.json"
EXPECTED_BASE_SHA256 = (
    "fc6d14ad406c8758dbd87238b05f2e962fabd52ef28a61bc204c4df1ccdac7b2"
)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def publish_exact(path: pathlib.Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.is_symlink() or not path.is_file() or path.read_bytes() != data:
            raise RuntimeError(f"existing generated artifact differs: {path}")
        return
    path.write_bytes(data)


def main() -> None:
    base_bytes = (ROOT / BASE).read_bytes()
    if digest(base_bytes) != EXPECTED_BASE_SHA256:
        raise RuntimeError("frozen diagnostic testbench hash drifted")
    text = base_bytes.decode("utf-8")
    task_start = text.index("  task automatic final_pa_sq_query_decisions;")
    block_start = text.index("`ifdef V9R_SQ_RETRY_C0_FOCUSED", task_start)
    block_end = text.index("`endif", block_start) + len("`endif")
    original = text[block_start:block_end]
    if original.count("`ifdef") != 1 or original.count("`endif") != 1:
        raise RuntimeError("focused C0 block shape drifted")

    replacement = r'''`ifdef V9R_SQ_RETRY_C0_FOCUSED
      // V15G historical reconstruction: the V9P bridge incorrectly exposes
      // retry fire in C0 while its sequential barrier branch retains the same
      // S_SQ_QUERY owner.  C1 flush then emits drop0 for that retained owner;
      // the exact backend equations cancel the captured retry holder in lane10.
      control_full_flush_barrier = 1'b1;
      mem0_sq_query_retry_ready = 1'b1;
      #1;
      tb_check1("V15G V9P C0 replay query remains valid",
                mem0_sq_query_valid, 1'b1);
      tb_check32("V15G V9P C0 replay token",
                 {27'b0, mem0_sq_query_owner_token},
                 {27'b0, replay_token});
      tb_check1("V15G V9P C0 exposes backend retry capture",
                dut.sq_query_retry_fire_w, 1'b1);
      tick();
      #1;
      tb_check1("V15G V9P C0 edge retains bridge owner",
                mem0_sq_query_valid, 1'b1);
      tb_check32("V15G V9P retained bridge token",
                 {27'b0, mem0_sq_query_owner_token},
                 {27'b0, replay_token});
      control_full_flush_barrier = 1'b0;
      mem0_sq_query_retry_ready = 1'b0;
      flush = 1'b1;
      #1;
      tb_check1("V15G V9P C1 retained bridge emits drop0",
                mem0_drop0_valid, 1'b1);
      tb_check32("V15G V9P C1 drop0 token",
                 {27'b0, mem0_drop0_owner_token},
                 {27'b0, replay_token});
      tb_check1("V15G V9P C1 drop has no response",
                mem0_rsp_valid, 1'b0);
      $display("[V15G-V9P-C0-C1-HANDOFF][PASS] bank0_lanes=2,10 token=%0d C0_retry=1 C0_bridge_hold=1 C1_drop0=1",
               replay_token);
      flush = 1'b0;
      disable final_pa_sq_query_decisions;
`else
      mem0_sq_query_retry_ready = 1'b1;
`endif'''
    derived = (text[:block_start] + replacement + text[block_end:]).encode("utf-8")
    publish_exact(ROOT / OUTPUT, derived)

    receipt = {
        "schema": "npc-rv64-v9p-derived-bridge-counterexample-v1",
        "status": "PASS",
        "base": {
            "path": BASE.as_posix(),
            "sha256": digest(base_bytes),
        },
        "derived": {
            "path": OUTPUT.as_posix(),
            "sha256": digest(derived),
        },
        "transformation": {
            "scope": "final_pa_sq_query_decisions V9R focused branch only",
            "old_block_sha256": digest(original.encode("utf-8")),
            "new_block_sha256": digest(replacement.encode("utf-8")),
            "expected_cycle": "C0 retry capture plus bridge hold; C1 drop0",
            "bank0_collector_lanes": [2, 10],
        },
    }
    receipt_bytes = (
        json.dumps(receipt, indent=2, sort_keys=True).encode("utf-8") + b"\n"
    )
    publish_exact(ROOT / RECEIPT, receipt_bytes)
    print(
        "[RV64-V9P-BRIDGE-COUNTEREXAMPLE-DERIVE][PASS] "
        f"sha256={digest(derived)}"
    )


if __name__ == "__main__":
    main()
