#!/usr/bin/env python3
"""Source-bound audit for v8k pending CSR ProducerId ownership."""

from __future__ import annotations

import json
import re
from pathlib import Path


RUN_DIR = Path(__file__).resolve().parent
REPO = RUN_DIR.parents[2]


FILES = {
    "seq": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    "mux": "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v",
    "drain": "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
    "admission": "npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v",
    "control": "npc/rv64/vsrc/control/OooControlPlane.v",
    "int": "npc/rv64/vsrc/execute/OooIntBackend.v",
    "decode": "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "slice": "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "execute": "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "glue": "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "tb_seq": "npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv",
    "tb_probe": "npc/rv64/testbench/tests/tb_ooo_pending_system_lease_probe.sv",
    "tb_mux": "npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv",
    "tb_drain": "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv",
    "tb_admission": "npc/rv64/testbench/tests/tb_ooo_pending_system_admission_cancel_gate.sv",
    "tb_int": "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "tb_priv": "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "make": "npc/rv64/testbench/Makefile",
    "spec": "npc/rv64/design/specs/ooo-pending-system-csr-producer-lease.md",
    "contract": ".github/task-runs/2026-07-20-rv64-v8k-pending-csr-producer-lease/contract.md",
}
TEXT = {
    name: (REPO / path).read_text(encoding="utf-8")
    for name, path in FILES.items()
}
checks: list[dict[str, object]] = []


def require(name: str, condition: bool, detail: str) -> None:
    checks.append({"name": name, "pass": bool(condition), "detail": detail})


def contains(scope: str, *needles: str) -> bool:
    return all(needle in TEXT[scope] for needle in needles)


def assignment(scope: str, lhs: str) -> str:
    match = re.search(
        rf"(?:assign|wire(?:\s+\[[^;]+\])?)\s+{re.escape(lhs)}\s*=.*?;",
        TEXT[scope], re.S,
    )
    return match.group(0) if match else ""


require(
    "raw-lease-is-authoritative-q",
    contains(
        "seq",
        "wire empty_w = !valid_q && !producer_valid_q;",
        "assign producer_valid_o = producer_valid_q;",
        "assign producer_id_o = producer_id_q;",
    ),
    "empty/census/output use raw registered lease without metadata gating",
)

birth = assignment("seq", "dispatch_birth_w")
require(
    "csr-dispatch-birth-exact-pid",
    all(term in birth for term in
        ("dispatch_fire_i", "valid_q", "csr_q", "!dispatched_q",
         "!producer_valid_q", "!clear_i"))
    and contains(
        "seq",
        "producer_valid_q <= 1'b1;",
        "producer_id_q <= dispatch_producer_id_i;",
    ),
    "only an uncancelled pre-ROB CSR dispatch captures the backend full PID",
)

require(
    "post-dispatch-death-allowlist",
    contains(
        "seq",
        "end else if (producer_valid_q) begin",
        "if (producer_death_i) begin",
        "end else if (clear_i) begin",
        "[V8K-PENDING-CSR-NO-RECAPTURE]",
        "[V8K-PENDING-CSR-LEASE-STABLE]",
    ),
    "live lease holds across ordinary clear/refresh/recapture and dies only by witness/reset",
)

logical = assignment("mux", "pending_system_csr_logical_claim_w")
seal = assignment("mux", "pending_system_csr_claim_seal_w")
pending_commit = assignment("mux", "pending_system_csr_commit_o")
head0_commit = assignment("mux", "head0_csr_commit_o")
require(
    "claim-seal-fail-closed",
    all(term in logical for term in
        ("pending_system_i", "pending_system_csr_i",
         "pending_system_dispatched_i"))
    and all(term in seal for term in
            ("pending_system_producer_valid_i",
             "pending_system_csr_logical_claim_w"))
    and "!pending_system_csr_claim_seal_w" in head0_commit,
    "raw lease or logical claim seals the queue-head fallback",
)
require(
    "pending-commit-full-pid-pc",
    all(term in pending_commit for term in
        ("pending_system_csr_logical_claim_w",
         "pending_system_producer_valid_i", "core_commit0_csr_o",
         "pending_system_csr_pid_match_w",
         "pending_system_csr_pc_match_w"))
    and contains(
        "mux",
        "core_commit0_producer_id_i == pending_system_producer_id_i",
        "core_commit0_pc_i == pending_system_pc_i",
    ),
    "pending CSR commit requires logical claim, raw lease, full PID and PC",
)

dispatch_valid = assignment("drain", "system_csr_dispatch_valid_o")
cancel = assignment("admission", "system_csr_dispatch_cancel_o")
admission_clear = assignment("admission", "system_csr_admission_clear_o")
jump_clear = assignment("admission", "pending_jump_clear_w")
require(
    "admission-cancel-before-enqueue",
    "!system_csr_dispatch_cancel_i" in dispatch_valid
    and all(term in cancel for term in
            ("rst_i", "core_local_flush_i", "system_csr_admission_clear_o"))
    and all(term in admission_clear for term in
            ("csr_trap_mem_valid_i", "branch_spec_resolve_valid_i",
             "pending_branch_commit_resolve_i", "pending_branch_match_clear_i",
             "branch_resolve_untracked_i", "pending_jump_clear_w",
             "pending_system_csr_commit_i", "head0_csr_commit_i"))
    and all(term in jump_clear for term in
            ("pending_jump_resolve_ready_i", "pending_jump_misaligned_i",
             "pending_jump_nolink_commit_i",
             "pending_jump_redirect_after_dispatch_i"))
    and "input direct_frontend_flush" not in TEXT["admission"]
    and "stuck ready without clear qualification" in TEXT["tb_admission"]
    and "[V8K-PENDING-CSR-DIRECT-FLUSH-MUTEX]" in TEXT["control"]
    and "u_pending_system_admission_cancel_gate" in TEXT["control"]
    and ".system_csr_dispatch_cancel_i(system_csr_dispatch_cancel_w)" in
        TEXT["control"],
    "only qualified feedback-free clear witnesses cancel admission; raw level-ready cannot self-lock replay",
)

require(
    "same-edge-backend-flush-death",
    contains(
        "control",
        ".rst(rst || core_local_flush_w)",
        ".producer_death_i(pending_system_csr_commit_w)",
    )
    and ".flush_i(core_local_flush_w)" in TEXT["execute"]
    and contains(
        "glue",
        ".core_local_flush_w(core_local_flush_w)",
        ".pending_system_producer_valid_w(pending_system_producer_valid_w)",
    ),
    "sequencer and ROB consume the same core_local_flush edge",
)

pending_mask = assignment("int", "pending_system_producer_live_mask_w")
full_mask = assignment("int", "producer_live_mask_w")
require(
    "q-only-onehot-holder-mask",
    all(term in pending_mask for term in
        ("pending_system_producer_valid_i",
         "pending_system_producer_id_i", "1'b1"))
    and "pending_system_producer_live_mask_w" in full_mask
    and not any(term in pending_mask.lower() for term in
                ("ready", "fire", "commit", "authorized", "match")),
    "raw Q valid/P decodes to onehot and joins the complete dispatch census",
)

transport_scopes = ("decode", "slice", "execute", "glue")
require(
    "producer-transport-no-index-reconstruction",
    all(contains(
        scope,
        "pending_system_producer_valid",
        "pending_system_producer_id",
        "dispatch0_producer_id",
        "commit0_producer_id",
    ) for scope in transport_scopes)
    and contains(
        "control",
        ".dispatch_producer_id_i(core_dispatch0_producer_id_w)",
        ".core_commit0_producer_id_i(core_commit0_producer_id_w)",
    ),
    "full PID is transported backend→control and raw lease control→backend",
)

require(
    "control-runtime-proof-markers",
    contains(
        "control",
        "[V8K-PENDING-CSR-CLAIM-WITHOUT-LEASE]",
        "[V8K-PENDING-CSR-LEASE-WITHOUT-CLAIM]",
        "[V8K-PENDING-CSR-ENQUEUE-BIRTH]",
        "[V8K-PENDING-CSR-FIRE-CLEAR-MUTEX]",
        "[V8K-PENDING-CSR-JUMP-CLEAR-COVER]",
        "[V8K-PENDING-CSR-BIRTH-MISSING]",
        "[V8K-PENDING-CSR-DEATH-WITNESS]",
        "[V8K-PENDING-CSR-ONE-WITNESS]",
    )
    and contains(
        "int",
        "[V8K-PENDING-CSR-LEASE-DECODE]",
        "[V8K-PENDING-CSR-NO-LIVE-REUSE]",
    ),
    "assertions bind shape, birth, death, single witness and reuse fence",
)

require(
    "leaf-counterexamples",
    contains(
        "tb_mux",
        "PID_STALE_GEN",
        "Raw-only and logical-only malformed states both fail closed",
        "pending_system_producer_valid_i",
    )
    and contains(
        "tb_seq",
        "exact producer death wins ordinary clear cross",
        "pre-ROB has no lease",
    )
    and contains(
        "tb_drain",
        "cancel suppresses system CSR dispatch valid",
    ),
    "leaf tests cover stale generation, PC mismatch, four shapes and cancel cross",
)

require(
    "negative-probe-and-make-discovery",
    contains(
        "tb_probe",
        "V8K_PROBE_PARTIAL_METADATA",
        "V8K_PROBE_LIVE_CLEAR",
        "V8K_ASSERT_PARTIAL_METADATA",
        "V8K_ASSERT_LIVE_CLEAR",
    )
    and "TB_SRCS_tb_ooo_pending_system_lease_probe" in TEXT["make"],
    "release mutation probes and assertion-negative probes are Make-discoverable",
)

require(
    "real-priv-forward-proof",
    contains(
        "tb_priv",
        "[V8K-PRIV-DISPATCH]",
        "[V8K-PRIV-BIRTH]",
        "[V8K-PRIV-EXACT-COMMIT]",
        "[V8K-PRIV-DEATH]",
        "V8K pending CSR exact lease birth count",
    ),
    "real lane1 CSRRW proves edge-old birth, census, exact commit and death",
)

require(
    "scope-and-promotion-disclaimer",
    contains(
        "spec",
        "ProducerId",
        "pending CSR",
        "PPA",
    )
    and contains(
        "contract",
        "promotion_eligible=false",
        "pending-system CSR",
    ),
    "the slice remains architecture-only and does not claim full-core/PPA green",
)

failed = [check for check in checks if not check["pass"]]
print(json.dumps({
    "schema": "v8k-pending-csr-audit-v1",
    "checks": checks,
    "failed": failed,
}, indent=2, sort_keys=True))
if failed:
    raise SystemExit(1)
print(f"[V8K-PENDING-CSR-AUDIT] PASS checks={len(checks)}")
