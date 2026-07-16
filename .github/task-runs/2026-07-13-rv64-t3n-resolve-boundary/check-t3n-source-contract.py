#!/usr/bin/env python3
"""Fail-closed source contract for the T3N registered resolve boundary."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
FILES = {
    "int_backend": ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v",
    "dispatch": ROOT / "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "iq": ROOT / "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "recovery": ROOT / "npc/rv64/vsrc/frontend/OooBranchResolveRecoveryGate.v",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"[T3N-SOURCE] FAIL: {message}")


def main() -> None:
    text = {name: path.read_text(encoding="utf-8") for name, path in FILES.items()}
    ib = text["int_backend"]
    db = text["dispatch"]
    iq = text["iq"]
    recovery = text["recovery"]

    # Control flow has exactly one execution/resolve owner.  The IQ must skip a
    # ready branch/JAL/JALR as lane1 candidate, but continue scanning younger
    # non-control entries.
    for bit in ("CTRL_BRANCH_BIT", "CTRL_JAL_BIT", "CTRL_JALR_BIT"):
        require(
            f"!ctrl_q[scan_i][`{bit}]" in iq,
            f"lane1 candidate does not exclude {bit}",
        )
    require("[IQ-CTRL-LANE0-OWNER]" in iq, "IQ lane-owner assertion missing")
    require(
        "!issue1_is_ctrlflow_w &&" in ib,
        "IntBackend lane1 ready is not gated against control flow",
    )
    require(
        "issue0_is_ctrlflow_w ? issue0_ctrlflow_ready_w" in ib,
        "lane0 control-flow acceptance still reuses generic ready",
    )
    require(
        "wire issue0_ctrlflow_ready_w = !flush_i && !issue_block_w;" in ib,
        "lane0 control-flow ready contract changed",
    )
    require("[INT-CTRL-LANE0-OWNER]" in ib, "backend lane-owner assertion missing")

    # The complete packet must cross one PipeStageReg as a single ordered
    # bundle.  No lane1 resolve arbitration may remain.
    for forbidden in (
        "branch_resolve_pick1_w",
        "issue1_resolve_emit_w",
        "issue1_ctrlflow_next_pc_w",
        "issue1_mispredict_w",
    ):
        require(forbidden not in ib, f"forbidden lane1/live resolve path remains: {forbidden}")
    require(
        "localparam integer BRANCH_RESOLVE_PAYLOAD_W =\n"
        "      (2 * `XLEN) + ROB_INDEX_W + `BPU_BHT_INDEX_W + 5;" in ib,
        "resolve payload width no longer covers the coherent bundle",
    )
    payload = """  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      issue0_pc_w,
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      issue0_rob_idx_w,
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };"""
    require(payload in ib, "resolve payload fields/order changed or field omitted")
    for needle in (
        "PipeStageReg #(.WIDTH(BRANCH_RESOLVE_PAYLOAD_W)) u_branch_resolve_stage",
        ".flush_i(flush_i || checkpoint_restore_i)",
        ".up_valid_i(issue0_resolve_emit_w)",
        ".down_valid_o(branch_resolve_stage_valid_w)",
        ".down_ready_i(1'b1)",
    ):
        require(needle in ib, f"resolve stage connection missing: {needle}")

    # PipeStageReg keeps dirty payload when invalid.  Every public semantic
    # field and the internal kill pulse therefore needs the same effective
    # valid, including combinational cancellation by both flush sources.
    require(
        "wire branch_resolve_effective_valid_w =\n"
        "      branch_resolve_stage_valid_w && !flush_i && !checkpoint_restore_i;" in ib,
        "effective valid does not cover stage/flush/checkpoint",
    )
    require(
        ib.count("branch_resolve_effective_valid_w") >= 11,
        "not every resolve output is guarded by effective valid",
    )
    for output in (
        "branch_resolve_valid_o",
        "branch_resolve_pc_o",
        "branch_resolve_next_pc_o",
        "branch_resolve_misaligned_o",
        "branch_resolve_rob_idx_o",
        "branch_resolve_mispredict_w",
        "branch_resolve_is_branch_o",
        "branch_resolve_taken_o",
        "branch_resolve_pred_taken_o",
        "branch_resolve_bht_idx_o",
    ):
        require(f"assign {output}" in ib, f"resolve output assignment missing: {output}")
    require("[INT-RESOLVE-EX-COHERENT]" in ib, "resolve/EX identity assertion missing")
    require("[INT-RESOLVE-CANCEL-MASK]" in ib, "resolve cancel-mask assertion missing")

    # DispatchBackend receives an already-registered packet.  A second kill
    # register would add a recovery hole; direct q consumption must freeze
    # dispatch and drive both ROB and IQ in the same cycle.
    require(
        not re.search(r"\breg\s+(?:\[[^\]]+\]\s*)?kill_valid_q\b", db),
        "second kill-valid register reintroduced",
    )
    require(
        not re.search(r"\breg\s+(?:\[[^\]]+\]\s*)?kill_idx_q\b", db),
        "second kill-index register reintroduced",
    )
    require(
        "wire rob_kill_valid_w = rob_walk_mode_w && branch_mispredict_valid_i;" in db,
        "registered resolve valid is not consumed directly",
    )
    require(
        "wire [ROB_INDEX_W-1:0] rob_kill_idx_w = kill_rob_idx_i;" in db,
        "registered resolve index is not consumed directly",
    )
    require(
        "wire dispatch_freeze_w = rob_recover_active_w || rob_kill_valid_w;" in db,
        "kill cycle no longer freezes dispatch",
    )
    require(
        db.count(".kill_valid_i(rob_kill_valid_w)") == 2,
        "ROB and IQ are not driven by the same direct kill pulse",
    )

    # The mode-0 checkpoint domain is architecturally dead when ROB walk owns
    # recovery.  Local producer gating is required: parent-level constants are
    # insufficient under preserved hierarchy and recreate resolve-q feedback.
    for needle in (
        "!rob_walk_mode_w && branch_spec_active_i && pending_branch_i",
        "!rob_walk_mode_w && !core_branch_resolve_misaligned_i",
        "!rob_walk_mode_w && branch_spec_resolve_valid_o &&",
    ):
        require(needle in recovery, f"legacy restore isolation missing: {needle}")

    report = {
        "status": "PASS",
        "files": {name: str(path.relative_to(ROOT)) for name, path in FILES.items()},
        "control_flow_owner": "lane0",
        "resolve_boundary": "PipeStageReg/coherent-full-payload",
        "cancel_sources": ["flush_i", "checkpoint_restore_i"],
        "dispatch_kill_latency_from_resolve_q_cycles": 0,
        "legacy_checkpoint_outputs_in_rob_walk_mode": "structural-zero",
        "rob_iq_direct_kill_consumers": 2,
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
