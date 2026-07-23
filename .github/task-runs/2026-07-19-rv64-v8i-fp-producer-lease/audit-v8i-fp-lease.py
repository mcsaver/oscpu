#!/usr/bin/env python3
"""Source-bound v8i FP ProducerId/pending-owner/credit audit."""

from __future__ import annotations

import json
import re
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO = RUN_DIR.parents[2]


def read(relpath: str) -> str:
    return (REPO / relpath).read_text(encoding="utf-8")


FILES = {
    "iq": "npc/rv64/vsrc/scheduling/OooFpIssueQueue.v",
    "arith": "npc/rv64/vsrc/execute/OooFpArithGate.v",
    "fp": "npc/rv64/vsrc/execute/OooFpBackend.v",
    "int": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "dispatch": "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "rob": "npc/rv64/vsrc/writeback/OooRob.v",
    "macro_gen": "npc/rv64/syn/macro-lib/gen_macro_libs.py",
    "macro_lib": "npc/rv64/syn/macro-lib/OooFpArithGate.lib",
    "tb": "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
}
TEXT = {name: read(path) for name, path in FILES.items()}
checks: list[dict[str, object]] = []


def require(name: str, condition: bool, detail: str) -> None:
    checks.append({"name": name, "pass": bool(condition), "detail": detail})


def contains(scope: str, *needles: str) -> bool:
    return all(needle in TEXT[scope] for needle in needles)


def assignment(scope: str, lhs: str) -> str:
    match = re.search(rf"(?:assign|wire(?:\s+\[[^;]+\])?)\s+{re.escape(lhs)}\s*=.*?;",
                      TEXT[scope], re.S)
    return match.group(0) if match else ""


require("iq-full-pid-state",
        contains("iq", "reg [PRODUCER_ID_W-1:0] producer_id_q",
                 "dispatch_producer_id_i", "issue_producer_id_o") and
        "reg [ROB_INDEX_W-1:0] rob_idx_q" not in TEXT["iq"],
        "FP IQ stores full PID and has no parallel raw ROB identity")
require("arith-full-pid-state",
        contains("arith", "meta_producer_id_q", "launch_producer_id_i",
                 "out_producer_id_o", "owner_producer_id_o") and
        "meta_rob_q" not in TEXT["arith"] and
        "launch_rob_idx_i" not in TEXT["arith"],
        "arith five-stage metadata stores only full PID")
require("backend-full-pid-holders",
        contains("fp", "issue_producer_id_w", "exec1_producer_id_q",
                 "long_producer_id_q", "df_producer_id_q",
                 "fpwb_producer_id_o") and
        "long_rob_q" not in TEXT["fp"] and "df_rob_q" not in TEXT["fp"],
        "issue/exec1/long/FIFO carry full PID")

require("pending-is-fifo-q",
        contains("fp", "if (df_valid_q[pk])",
                 "completion_pending_mask_r[df_producer_id_q[pk]] = 1'b1",
                 "assign completion_pending_mask_o = completion_pending_mask_r"),
        "occupied FIFO Q entries alone decode completion pending capability")
require("pending-fences-all-nonformal",
        contains("int", "!ex0_fp_pending_owned_w", "!ex1_fp_pending_owned_w",
                 "!mem_fp_pending_owned_w", "!muldiv_fp_pending_owned_w",
                 "!clmul_fp_pending_owned_w", "!fp_result_pending_owned_w"),
        "EX0/EX1/memory/longops/new FP result all read pending fence")
require("formal-bound-to-token",
        contains("int", "fpwb_pending_owner_w",
                 "fp_formal_completion_rob_open_w && fpwb_pending_owner_w",
                 "fpwb_to_wb0_w && fpwb_completion_authorized_w",
                 "fpwb_to_wb1_w && fpwb_completion_authorized_w"),
        "formal actual WB requires exact-open token owner")
require("result-side-effects-one-actual",
        contains("fp", "fp_result_raw_valid_w && result_authorized_i",
                 "wire df_push_w = fp_result_wb_valid_w",
                 "wire fp_fpr_complete_w = fp_result_wb_valid_w"),
        "one authorized result fact drives PRF/Busy/wake/FIFO push")

issue_ready = assignment("fp", "issue_ready_w")
require("launch-credit-exact-q",
        contains("fp", "done_fifo_count_q} + arith_owner_count_w",
                 "exec1_valid_q", "long_meta_valid_q",
                 "execution_credit_used_w < DONE_FIFO_N") and
        "execution_credit_open_w" in issue_ready and
        not any(word in issue_ready for word in
                ("result_authorized", "query", "fpwb_ready")),
        "post-launch Q occupancy gates launch without authority/ready")
require("live-mask-six-holder-union",
        contains("fp", "fp_iq_producer_live_mask_w |",
                 "issue_stage_producer_live_mask_w |",
                 "arith_producer_live_mask_r |",
                 "exec1_producer_live_mask_w |",
                 "long_producer_live_mask_w |",
                 "completion_pending_mask_r"),
        "all six FP Q holder classes feed local lease union")
require("global-live-mask-includes-fp",
        contains("int", "clmul_owner_producer_live_mask_w |",
                 "fp_producer_live_mask_w;"),
        "FP lease reaches dispatch birth fence")

fp_ready = assignment("int", "fpwb_ready_w")
require("formal-ready-is-raw-route",
        "fpwb_to_wb0_w || fpwb_to_wb1_w" in fp_ready and
        not any(word in fp_ready for word in
                ("authorized", "query", "pending", "open")),
        "formal raw READY is independent of authority")
require("raw-source-release-independent",
        contains("fp", "assign long_take_pre_w = long_take_w",
                 ".down_ready_i(!arith_out_valid_w)") and
        "result_authorized_i" not in assignment("fp", "long_take_pre_w"),
        "exec1/long raw terminal does not read result authority")

require("rob-two-fp-queries",
        contains("rob", "completion5_query_match_o",
                 "completion6_query_match_o", "completion5_query_exact_w",
                 "completion6_query_exact_w") and
        contains("dispatch", "completion5_query_match_o",
                 "completion6_query_match_o"),
        "ROB/Dispatch expose independent result and formal exact-open queries")
require("macro-interface-synchronized",
        contains("macro_gen", "launch_producer_id_i", "out_producer_id_o",
                 "owner_valid_o", "owner_producer_id_o") and
        contains("macro_lib", "launch_producer_id_i", "out_producer_id_o",
                 "owner_valid_o", "owner_producer_id_o"),
        "non-signoff arith macro placeholder matches RTL interface")
require("fifo-replacement-atomic-review",
        contains("fp", "[V8I-FP-FIFO-PUSH-ATOMIC]",
                 "df_push_check_producer_id_q",
                 "df_push_check_killed_q") and
        contains("tb", "run_v8i_fifo_same_slot_case",
                 "V8I full replacement tombstone belongs to new PID"),
        "push survival assertion and full-slot pop/push/kill directed cases bind new token state")
require("generation-separated-raw-transport",
        contains("tb", "run_v8i_generation_separated_transport",
                 "V8I newer generation EX0 remains actual",
                 "V8I newer generation FP result remains authorized"),
        "stale formal raw route cannot suppress a newer generation sharing the raw index")

failed = [check for check in checks if not check["pass"]]
print(json.dumps({"schema": "v8i-fp-lease-audit-v1", "checks": checks,
                  "failed": failed}, indent=2, sort_keys=True))
if failed:
    raise SystemExit(f"[V8I-FP-LEASE-AUDIT] FAIL: {len(failed)} checks")
print(f"[V8I-FP-LEASE-AUDIT] PASS: {len(checks)} checks")
