#!/usr/bin/env python3

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
BRIDGE_PATH = ROOT / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v"
TB_PATH = ROOT / "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv"


def region(text: str, start: str, end: str) -> str:
    begin = text.index(start)
    finish = text.index(end, begin + len(start))
    return text[begin:finish]


def audit(bridge: str, tb: str) -> list[str]:
    errors: list[str] = []

    for forbidden in ("fetch_ctx_sel_q", "fetch_ctx0_", "fetch_ctx1_"):
        if forbidden in bridge:
            errors.append(f"T3Z selector/bank state restored: {forbidden}")

    try:
        context_block = region(
            bridge,
            "// Fixed-role context pipeline is deliberately outside",
            "\n  always @(posedge clk) begin\n    if (rst) begin\n      // rst 代表",
        )
        candidate_writes = region(
            context_block,
            "fetch_ctx_candidate_paging_q <= req_paging_w;",
            "if (state_q == S_CACHE_READ) begin",
        )
        exec_capture = region(
            context_block,
            "if (state_q == S_CACHE_READ) begin",
            "\n      end\n    end\n  end",
        )
    except ValueError as exc:
        errors.append(f"context pipeline block not recoverable: {exc}")
        context_block = ""
        candidate_writes = ""
        exec_capture = ""

    if "fetch_req_fire_w" in context_block:
        errors.append("context pipeline regained request-fire control")

    candidate_rhs = {
        "paging": "req_paging_w",
        "priv": "priv_mode_i",
        "satp": "satp_i",
        "svpbmt_en": "svpbmt_en_i",
        "pc": "fetch_req_pc_i",
    }
    for field, rhs in candidate_rhs.items():
        token = f"fetch_ctx_candidate_{field}_q <= {rhs};"
        if token not in candidate_writes:
            errors.append(f"missing unconditional candidate write: {token}")
    for forbidden in ("fetch_req_fire_w", "fetch_req_ready_o", "mmu_flush_i",
                      "state_q", "fetch_rsp_fire_w"):
        if forbidden in candidate_writes:
            errors.append(f"candidate D regained control dependency: {forbidden}")

    for field in candidate_rhs:
        token = (
            f"fetch_ctx_exec_{field}_q <= "
            f"fetch_ctx_candidate_{field}_q;"
        )
        if token not in exec_capture:
            errors.append(f"missing candidate-to-exec capture: {token}")
    for forbidden in ("fetch_req_fire_w", "fetch_req_ready_o", "mmu_flush_i",
                      "fetch_rsp_fire_w", "fetch_req_pc_i", "satp_i",
                      "priv_mode_i", "svpbmt_en_i"):
        if forbidden in exec_capture:
            errors.append(f"exec capture escaped local registered boundary: {forbidden}")

    required_owner = [
        "wire fetch_ctx_owner_candidate_w = (state_q == S_CACHE_READ);",
        "fetch_ctx_candidate_pc_q : fetch_ctx_exec_pc_q;",
        "assign fetch_req_owner_pc_o = pc_q;",
        "[T4A-CANDIDATE-TRACK]",
        "[T4A-FIRE-CANDIDATE]",
        "[T4A-EXEC-HANDOFF]",
        "[T4A-EXEC-HOLD]",
        "[T4A-OWNER-MUX]",
        "[T4A-OWNER-HANDOFF]",
        "[T4A-ATOMIC-REPLACE]",
    ]
    for token in required_owner:
        if token not in bridge:
            errors.append(f"missing T4A owner contract token: {token}")

    lookup_tokens = [
        ".lookup_paging_i(fetch_ctx_candidate_paging_q)",
        ".lookup_priv_i(fetch_ctx_candidate_priv_q)",
        ".lookup_satp_i(fetch_ctx_candidate_satp_q)",
        ".lookup_pc_i(fetch_ctx_candidate_pc_q)",
        ".lookup_valid_i(fetch_ctx_candidate_paging_q)",
        ".lookup_vaddr_i(fetch_ctx_candidate_pc_q)",
        ".lookup_satp_i(fetch_ctx_candidate_satp_q)",
        "fetch_ctx_candidate_svpbmt_en_q,",
        "fetch_ctx_candidate_priv_q));",
        "req_itlb_paddr_w : fetch_ctx_candidate_pc_q;",
        "paddr0_q <= fetch_ctx_candidate_pc_q;",
    ]
    for token in lookup_tokens:
        if token not in bridge:
            errors.append(f"lookup no longer consumes candidate context: {token}")

    exec_tokens = [
        ".fill_paging_i(fetch_ctx_exec_paging_q)",
        ".fill_priv_i(fetch_ctx_exec_priv_q)",
        ".fill_satp_i(fetch_ctx_exec_satp_q)",
        ".fill_pc_i(fetch_ctx_exec_pc_q)",
        ".fill_satp_i(fetch_ctx_exec_satp_q)",
        "fetch_ctx_exec_satp_q[43:0]",
        "canonical_sv39(fetch_ctx_exec_pc_q)",
        "fetch_ctx_exec_svpbmt_en_q,",
    ]
    for token in exec_tokens:
        if token not in bridge:
            errors.append(f"transaction path no longer consumes exec context: {token}")
    if bridge.count(".priv_mode_i(fetch_ctx_exec_priv_q)") != 5:
        errors.append("not all five PMP checkers consume frozen exec privilege")
    if ".priv_mode_i(fetch_ctx_candidate_priv_q)" in bridge:
        errors.append("a PMP checker consumes mutable candidate privilege")

    try:
        post_owner = bridge.split("assign fetch_req_owner_pc_o = pc_q;", 1)[1]
        functional_tail = post_owner.split("`ifdef OOO_ASSERT", 1)[0]
        for alias in ("pc_q", "paging_q", "req_priv_q", "req_satp_q",
                      "req_svpbmt_en_q"):
            if re.search(rf"\b{re.escape(alias)}\b", functional_tail):
                errors.append(f"internal transaction path reused owner mux alias: {alias}")
    except IndexError:
        errors.append("owner output/OOO_ASSERT boundary not recoverable")

    required_ptw = [
        "localparam [3:0] S_WALK_CHECK = 4'd12;",
        "walk_pte_addr_q <= walk_pte_addr_w;",
        "walk_pte_pmp_fault_q <= walk_pte_pmp_fault_w;",
        "((state_q == S_WALK_AR) && !walk_pte_pmp_fault_q)",
        "ifu_axi_walk_ar_owner_w ? walk_pte_addr_q :",
        "assign ifu_axi_awaddr_o = walk_pte_addr_q;",
        "debug_last_pte_addr_q <= walk_pte_addr_q;",
        "[T4A-PTW-CHECK-QUIET]",
        "[T4A-PTW-AR-PREDECESSOR]",
        "[T4A-PTW-AUTH-CAPTURE]",
    ]
    for token in required_ptw:
        if token not in bridge:
            errors.append(f"missing registered PTW authorization token: {token}")
    if bridge.count("state_q <= S_WALK_CHECK;") != 4:
        errors.append("not every PTW entry/re-walk transition uses S_WALK_CHECK")
    if bridge.count("state_q <= S_WALK_AR;") != 1:
        errors.append("S_WALK_AR has a predecessor other than S_WALK_CHECK")
    if "((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w)" in bridge:
        errors.append("PTW ARVALID regained combinational PMP dependency")
    if "(state_q == S_WALK_AR) ? walk_pte_addr_w" in bridge:
        errors.append("PTW ARADDR regained combinational PTE-address dependency")

    required_ar_drop = [
        "localparam [3:0] S_WALK_AR_DROP = 4'd13;",
        "localparam [3:0] S_FETCH_AR_DROP = 4'd14;",
        "(state_q == S_WALK_AR) || (state_q == S_WALK_AR_DROP)",
        "(state_q == S_WALK_AR_DROP) ||",
        "(state_q == S_FETCH_AR_DROP));",
        "state_q <= S_WALK_AR_DROP;",
        "state_q <= S_FETCH_AR_DROP;",
        "S_WALK_AR_DROP, S_FETCH_AR_DROP: begin",
        "[IFU-AR-HOLD]",
        "[IFU-AR-DROP-OWNER]",
        "[IFU-AR-DROP-DRAIN]",
    ]
    for token in required_ar_drop:
        if token not in bridge:
            errors.append(f"missing AR drop-owner contract token: {token}")
    try:
        arvalid_block = region(
            bridge,
            "assign ifu_axi_arvalid_o =",
            "assign ifu_axi_araddr_o =",
        )
        if "mmu_flush_i" in arvalid_block:
            errors.append("ARVALID regained a combinational MMU-flush gate")
    except ValueError as exc:
        errors.append(f"ARVALID block not recoverable: {exc}")

    tb_tokens = [
        "candidate captures request-fire pc",
        "cache-read hands request pc into frozen exec",
        "replacement candidate owns new pc in cache-read",
        "A-update poison reaches candidate only",
        "A-update flush retains exec PC",
        "PTW deny registers exact PTE address",
        "PTW deny registers read-side PMP fault",
        "walk AR remains valid on flush",
        "direct dropped owner keeps address",
        "flush-ready keeps ARVALID",
    ]
    for token in tb_tokens:
        if token not in tb:
            errors.append(f"missing directed T4A test evidence: {token}")

    return errors


def mutate(text: str, old: str, new: str) -> str:
    if old not in text:
        raise RuntimeError(f"mutation anchor missing: {old}")
    return text.replace(old, new, 1)


def main() -> int:
    bridge = BRIDGE_PATH.read_text(encoding="utf-8")
    tb = TB_PATH.read_text(encoding="utf-8")
    errors = audit(bridge, tb)

    mutations = {
        "gate_candidate_with_fire": mutate(
            bridge,
            "fetch_ctx_candidate_paging_q <= req_paging_w;",
            "if (fetch_req_fire_w) begin\n"
            "        fetch_ctx_candidate_paging_q <= req_paging_w;"),
        "capture_exec_from_live": mutate(
            bridge,
            "fetch_ctx_exec_pc_q <= fetch_ctx_candidate_pc_q;",
            "fetch_ctx_exec_pc_q <= fetch_req_pc_i;"),
        "lookup_uses_old_exec": mutate(
            bridge,
            ".lookup_pc_i(fetch_ctx_candidate_pc_q)",
            ".lookup_pc_i(fetch_ctx_exec_pc_q)"),
        "pmp_uses_candidate_priv": mutate(
            bridge,
            ".priv_mode_i(fetch_ctx_exec_priv_q)",
            ".priv_mode_i(fetch_ctx_candidate_priv_q)"),
        "owner_always_exec": mutate(
            bridge,
            "wire fetch_ctx_owner_candidate_w = (state_q == S_CACHE_READ);",
            "wire fetch_ctx_owner_candidate_w = 1'b0;"),
        "flush_gates_exec_capture": mutate(
            bridge,
            "if (state_q == S_CACHE_READ) begin",
            "if ((state_q == S_CACHE_READ) && !mmu_flush_i) begin"),
        "bypass_ptw_check": mutate(
            bridge,
            "state_q <= S_WALK_CHECK;",
            "state_q <= S_WALK_AR;"),
        "restore_comb_ptw_fault": mutate(
            bridge,
            "((state_q == S_WALK_AR) && !walk_pte_pmp_fault_q)",
            "((state_q == S_WALK_AR) && !walk_pte_pmp_fault_w)"),
        "restore_flush_arvalid_gate": mutate(
            bridge,
            "       (state_q == S_FETCH_AR_DROP));",
            "       (state_q == S_FETCH_AR_DROP)) && !mmu_flush_i;"),
        "drop_walk_metadata_decode": mutate(
            bridge,
            "(state_q == S_WALK_AR) || (state_q == S_WALK_AR_DROP)",
            "(state_q == S_WALK_AR)"),
    }

    mutation_results = {}
    for name, candidate in mutations.items():
        candidate_errors = audit(candidate, tb)
        mutation_results[name] = {
            "rejected": bool(candidate_errors),
            "errors": candidate_errors,
        }
        if not candidate_errors:
            errors.append(f"negative mutation escaped audit: {name}")

    result = {
        "status": "PASS" if not errors else "FAIL",
        "production_errors": errors,
        "negative_mutations": mutation_results,
        "files": {
            "bridge": str(BRIDGE_PATH),
            "testbench": str(TB_PATH),
        },
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
