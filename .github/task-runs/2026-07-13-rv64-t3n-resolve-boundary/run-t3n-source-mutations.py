#!/usr/bin/env python3
"""Run four source mutants; each T3N regression must fail non-vacuously."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
RUN = Path(__file__).resolve().parent
TB = ROOT / "npc/rv64/testbench"
VSRC = ROOT / "npc/rv64/vsrc"
WORK = ROOT / "tmp/2026-07-13-rv64-t3n-resolve-boundary/mutation-work"
OUT = RUN / "evidence/mutations"


def replace_once(text: str, old: str, new: str, name: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"[{name}] mutation anchor count={count}, expected 1")
    return text.replace(old, new, 1)


def run_case(
    name: str,
    test: str,
    override_name: str,
    mutated_path: Path,
    markers: tuple[str, ...],
) -> dict[str, object]:
    result_dir = OUT / name
    build_dir = WORK / f"build-{name}"
    command = [
        "make",
        "-C",
        str(TB),
        "run",
        f"TESTS={test}",
        f"RESULT_DIR={result_dir}",
        f"BUILD_DIR={build_dir}",
        f"{override_name}={mutated_path}",
    ]
    proc = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    console = proc.stdout + proc.stderr
    (OUT / f"{name}.console.log").write_text(console, encoding="utf-8")
    test_log = result_dir / "logs" / f"{test}.log"
    log_text = test_log.read_text(encoding="utf-8") if test_log.exists() else ""
    seen = [marker for marker in markers if marker in (console + log_text)]
    killed = proc.returncode != 0 and bool(seen) and "[RESULT] FAIL" in log_text
    if not killed:
        raise SystemExit(
            f"[{name}] mutant survived or failed vacuously: "
            f"make_rc={proc.returncode} markers={seen} log={test_log}"
        )
    return {
        "name": name,
        "test": test,
        "make_rc": proc.returncode,
        "markers_seen": seen,
        "status": "KILLED",
    }


def main() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    iq_path = VSRC / "scheduling/OooIntIssueQueue.v"
    iq_text = iq_path.read_text(encoding="utf-8")
    ib_path = VSRC / "execute/OooIntBackend.v"
    ib_text = ib_path.read_text(encoding="utf-8")
    db_path = VSRC / "rename_allocate/OooDispatchBackend.v"
    db_text = db_path.read_text(encoding="utf-8")
    recovery_path = VSRC / "frontend/OooBranchResolveRecoveryGate.v"
    recovery_text = recovery_path.read_text(encoding="utf-8")

    lane1_ctrl = replace_once(
        iq_text,
        """                     !ctrl_q[scan_i][`CTRL_BRANCH_BIT] &&
                     !ctrl_q[scan_i][`CTRL_JAL_BIT] &&
                     !ctrl_q[scan_i][`CTRL_JALR_BIT] &&""",
        """                     // MUTANT: lane1 may incorrectly own control flow.
                     1'b1 &&""",
        "lane1-control-flow-owner",
    )
    lane1_ctrl_path = WORK / "OooIntIssueQueue.lane1-control-flow.v"
    lane1_ctrl_path.write_text(lane1_ctrl, encoding="utf-8")

    dirty_payload = replace_once(
        ib_text,
        """  wire branch_resolve_effective_valid_w =
      branch_resolve_stage_valid_w && !flush_i && !checkpoint_restore_i;""",
        """  // MUTANT: cancel sources no longer mask the dirty staged payload.
  wire branch_resolve_effective_valid_w = branch_resolve_stage_valid_w;""",
        "dirty-payload-cancel-bypass",
    )
    dirty_payload_path = WORK / "OooIntBackend.dirty-payload-cancel-bypass.v"
    dirty_payload_path.write_text(dirty_payload, encoding="utf-8")

    bht_drop = replace_once(
        ib_text,
        """      issue0_pred_taken_w,
      issue0_bht_idx_w
  };""",
        """      issue0_pred_taken_w,
      {`BPU_BHT_INDEX_W{1'b0}} // MUTANT: metadata omitted from bundle.
  };""",
        "resolve-bht-metadata-drop",
    )
    bht_drop_path = WORK / "OooIntBackend.resolve-bht-metadata-drop.v"
    bht_drop_path.write_text(bht_drop, encoding="utf-8")

    delayed_kill = replace_once(
        db_text,
        """  wire rob_kill_valid_w = rob_walk_mode_w && branch_mispredict_valid_i;
  wire [ROB_INDEX_W-1:0] rob_kill_idx_w = kill_rob_idx_i;""",
        """  // MUTANT: obsolete second recovery register reintroduced.
  reg kill_valid_q;
  reg [ROB_INDEX_W-1:0] kill_idx_q;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      kill_valid_q <= 1'b0;
      kill_idx_q <= {ROB_INDEX_W{1'b0}};
    end else begin
      kill_valid_q <= rob_walk_mode_w && branch_mispredict_valid_i;
      kill_idx_q <= kill_rob_idx_i;
    end
  end
  wire rob_kill_valid_w = kill_valid_q;
  wire [ROB_INDEX_W-1:0] rob_kill_idx_w = kill_idx_q;""",
        "dispatch-second-kill-register",
    )
    delayed_kill_path = WORK / "OooDispatchBackend.second-kill-register.v"
    delayed_kill_path.write_text(delayed_kill, encoding="utf-8")

    restore_feedback = replace_once(
        recovery_text,
        """      !rob_walk_mode_w && branch_spec_active_i && pending_branch_i &&""",
        """      branch_spec_active_i && pending_branch_i && // MUTANT: mode-1 legacy resolve revived.""",
        "legacy-restore-feedback",
    )
    restore_feedback_path = WORK / "OooBranchResolveRecoveryGate.legacy-feedback.v"
    restore_feedback_path.write_text(restore_feedback, encoding="utf-8")

    results = [
        run_case(
            "lane1-control-flow-owner",
            "tb_ooo_int_issue_queue",
            "RTL_OOO_INT_ISSUE_QUEUE",
            lane1_ctrl_path,
            ("[IQ-CTRL-LANE0-OWNER]", "[CHECK-FAIL]"),
        ),
        run_case(
            "dirty-payload-cancel-bypass",
            "tb_ooo_int_backend",
            "RTL_OOO_INT_BACKEND",
            dirty_payload_path,
            ("[INT-RESOLVE-CANCEL-MASK]", "[CHECK-FAIL]"),
        ),
        run_case(
            "resolve-bht-metadata-drop",
            "tb_ooo_int_backend",
            "RTL_OOO_INT_BACKEND",
            bht_drop_path,
            ("[CHECK-FAIL]",),
        ),
        run_case(
            "dispatch-second-kill-register",
            "tb_ooo_dispatch_backend",
            "RTL_OOO_DISPATCH_BACKEND",
            delayed_kill_path,
            ("[CHECK-FAIL]",),
        ),
        run_case(
            "legacy-restore-feedback",
            "tb_ooo_branch_resolve_recovery_gate",
            "RTL_OOO_BRANCH_RESOLVE_RECOVERY_GATE",
            restore_feedback_path,
            ("[FAIL]",),
        ),
    ]
    summary = {"status": "PASS", "mutants": results}
    (OUT / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
