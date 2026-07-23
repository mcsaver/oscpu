#!/usr/bin/env python3
"""Source-bound audit for v8j branch-resolve ProducerId authorization."""

from __future__ import annotations

import json
import re
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO = RUN_DIR.parents[2]


def read(relpath: str) -> str:
    return (REPO / relpath).read_text(encoding="utf-8")


FILES = {
    "int": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "dispatch": "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "rob": "npc/rv64/vsrc/writeback/OooRob.v",
    "tb_int": "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "tb_rob": "npc/rv64/testbench/tests/tb_ooo_rob.sv",
    "spec": "npc/rv64/design/specs/ooo-branch-resolve-producer-authorization.md",
    "contract": ".github/task-runs/2026-07-19-rv64-v8j-branch-resolve-producer-authorization/contract.md",
}
TEXT = {name: read(path) for name, path in FILES.items()}
checks: list[dict[str, object]] = []


def require(name: str, condition: bool, detail: str) -> None:
    checks.append({"name": name, "pass": bool(condition), "detail": detail})


def contains(scope: str, *needles: str) -> bool:
    return all(needle in TEXT[scope] for needle in needles)


def assignment(scope: str, lhs: str) -> str:
    match = re.search(
        rf"(?:assign|wire(?:\s+\[[^;]+\])?|localparam(?:\s+integer)?)\s+{re.escape(lhs)}\s*=.*?;",
        TEXT[scope],
        re.S,
    )
    return match.group(0) if match else ""


payload_width = assignment("int", "BRANCH_RESOLVE_PAYLOAD_W")
require(
    "full-pid-payload-width",
    "PRODUCER_ID_W" in payload_width and "ROB_INDEX_W" not in payload_width,
    "branch q reserves full ProducerId width rather than a raw ROB field",
)
require(
    "full-pid-payload-pack",
    contains(
        "int",
        "wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w",
        "      iq_issue0_producer_id_w,\n      issue0_mispredict_w,",
        "branch_resolve_payload_producer_id_w",
    ),
    "issue full PID is packed and unpacked in the registered resolve packet",
)

projection = assignment("int", "branch_resolve_payload_rob_idx_w")
require(
    "raw-index-is-projection",
    "branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0]" in projection,
    "raw age boundary is derived only from P.index",
)

candidate = assignment("int", "branch_resolve_candidate_valid_w")
require(
    "candidate-cancel-mask",
    all(term in candidate for term in
        ("branch_resolve_stage_valid_w", "!rst", "!flush_i",
         "!checkpoint_restore_i")),
    "raw candidate includes reset/global-flush/checkpoint death edges",
)
require(
    "query-plumbing",
    contains(
        "int",
        ".resolve_query_valid_i(branch_resolve_query_valid_w)",
        ".resolve_query_producer_id_i(branch_resolve_query_producer_id_w)",
        ".resolve_query_match_o(branch_resolve_rob_open_w)",
    )
    and contains(
        "dispatch",
        "input resolve_query_valid_i",
        "input [PRODUCER_ID_W-1:0] resolve_query_producer_id_i",
        "output resolve_query_match_o",
        ".resolve_query_valid_i(resolve_query_valid_i)",
        ".resolve_query_match_o(resolve_query_match_o)",
    )
    and contains(
        "rob",
        "input resolve_query_valid_i",
        "input [PRODUCER_ID_W-1:0] resolve_query_producer_id_i",
        "output resolve_query_match_o",
    ),
    "Int→Dispatch→ROB exposes one storage-free dedicated query",
)

resolve_query = assignment("rob", "resolve_query_match_o")
require(
    "resolve-exact-edge-old-gate",
    all(term in resolve_query for term in
        ("resolve_query_valid_i", "!rst", "!flush_i", "!recover_q",
         "valid_q[resolve_query_idx_w]", "!done_q[resolve_query_idx_w]",
         "resolve_query_exact_w")),
    "resolve query requires exact live unfinished P and prior-recovery clear",
)
require(
    "resolve-query-no-current-kill",
    not any(term in resolve_query for term in
            ("kill_valid_i", "recovering_w", "producer_target_killed_now")),
    "dedicated query does not read the self-generated current kill cone",
)

coherence = assignment("int", "branch_resolve_raw_ex0_coherent_w")
require(
    "raw-ex0-only-coherence",
    "ex0_valid_q" in coherence
    and "branch_resolve_payload_producer_id_w == ex0_producer_id_q" in coherence
    and not any(term in coherence for term in
                ("ex0_pre_auth_valid_w", "ex0_producer_open_w",
                 "ex0_wb_valid_w", "kill_valid_i")),
    "coherence reads only raw registered EX0 valid/P",
)

authorized = assignment("int", "branch_resolve_authorized_w")
require(
    "single-actual-capability",
    all(term in authorized for term in
        ("branch_resolve_candidate_valid_w", "branch_resolve_rob_open_w",
         "branch_resolve_raw_ex0_coherent_w")),
    "one capability combines cancel, ROB authority and raw-holder coherence",
)

semantic_lhs = (
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
)
require(
    "all-semantics-use-capability",
    all("branch_resolve_authorized_w" in assignment("int", lhs)
        for lhs in semantic_lhs),
    "every public/kill semantic field is masked by the same capability",
)

query_ready_lines = [
    line for line in TEXT["int"].splitlines()
    if "branch_resolve_rob_open_w" in line and "ready" in line.lower()
]
require(
    "query-outside-transport-ready",
    not query_ready_lines and ".down_ready_i(1'b1)" in TEXT["int"],
    "query authority cannot retain the stage or enter ready/credit",
)

function_match = re.search(
    r"function automatic producer_target_killed_now;(?P<body>.*?)endfunction",
    TEXT["rob"],
    re.S,
)
function_body = function_match.group("body") if function_match else ""
require(
    "killed-now-explicit-sensitive-function",
    bool(function_match)
    and all(arg in function_body for arg in
            ("target_idx", "head_idx", "current_kill_valid",
             "current_kill_idx", "recovery_valid", "recovery_kill_idx"))
    and not any(global_name in function_body for global_name in
                ("head_q", "kill_valid_i", "kill_rob_idx_i",
                 "recover_q", "kill_idx_q")),
    "parallel killed-now calls are automatic and expose every sensitivity input",
)
require(
    "completion0-sensitivity-regression",
    contains(
        "rob",
        "wire completion0_query_killed_w",
        "producer_target_killed_now(completion0_query_idx_w, head_q",
        "kill_valid_i, kill_rob_idx_i",
        "recover_q, kill_idx_q",
    )
    and contains(
        "tb_rob",
        "v8j explicit kill masks unchanged younger completion",
        "v8j kill drop recomputes unchanged completion query",
    ),
    "the same-PID kill toggle counterexample is executable",
)

require(
    "assertion-markers",
    contains(
        "int",
        "[V8J-BRANCH-FULL-PID-COHERENT]",
        "[V8J-BRANCH-RESOLVE-AUTH]",
        "[V8J-BRANCH-STALE-SILENT]",
        "[V8J-BRANCH-PID-PROJECTION]",
    )
    and contains(
        "rob",
        "[V8J-ROB-RESOLVE-QUERY]",
        "[V8J-ROB-RESOLVE-SELF-KILL]",
    ),
    "runtime assertions bind full PID, authority, silence, projection and self-kill",
)
require(
    "focused-death-edge-tests",
    contains(
        "tb_int",
        "run_v8j_branch_resolve_authorization",
        "v8j stale generation is fully silent",
        "v8j EX0 mismatch is fully silent",
        "v8j raw-only capability survives semantic close",
        "V8J_BRANCH_RESOLVE_AUTH_FOCUSED",
    )
    and contains(
        "tb_rob",
        "exercise_v8j_resolve_query",
        "v8j done slot resolve closed",
        "v8j current self-kill keeps boundary resolve open",
        "v8j prior recovery closes resolve query",
    ),
    "focused benches cover positive, stale, mismatch and every death edge",
)
require(
    "spec-contract-disclaimers",
    contains(
        "spec",
        "raw registered `ex0_valid_q`",
        "不宣称 timing/PPA GREEN",
        "pending-system/CSR",
    )
    and contains(
        "contract",
        "promotion_eligible=false",
        "kill_valid_i` 唯一由本 capability 产生",
        "semantic EX0 valid",
    ),
    "scope, feedback preconditions and non-promotion language stay frozen",
)

failed = [check for check in checks if not check["pass"]]
print(json.dumps({"schema": "v8j-branch-resolve-audit-v1",
                  "checks": checks, "failed": failed},
                 indent=2, sort_keys=True))
if failed:
    raise SystemExit(f"[V8J-BRANCH-RESOLVE-AUDIT] FAIL: {len(failed)} checks")
print(f"[V8J-BRANCH-RESOLVE-AUDIT] PASS: {len(checks)} checks")
