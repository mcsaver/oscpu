#!/usr/bin/env python3

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PATHS = {
    "bridge": ROOT / "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "mux": ROOT / "npc/rv64/vsrc/frontend/OooFetchRequestMux.v",
    "sequencer": ROOT / "npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v",
    "frontend": ROOT / "npc/rv64/vsrc/frontend/OooFrontend.v",
    "glue": ROOT / "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "core": ROOT / "npc/rv64/vsrc/core/NpcCoreTop.v",
}


def region(text: str, start: str, end: str) -> str:
    begin = text.index(start)
    finish = text.index(end, begin + len(start))
    return text[begin:finish]


def audit(src: dict[str, str]) -> list[str]:
    errors: list[str] = []
    bridge = src["bridge"]
    mux = src["mux"]
    sequencer = src["sequencer"]

    try:
        bank_block = region(
            bridge,
            "// Payload banks are deliberately outside the FSM/mmu_flush priority tree.",
            "\n  always @(posedge clk) begin\n    if (rst) begin\n      // rst 代表 bridge+xbar/slave",
        )
        payload_block = bank_block[: bank_block.index("if (fetch_req_fire_w)")]
    except ValueError as exc:
        errors.append(f"context-bank block not uniquely recoverable: {exc}")
        bank_block = ""
        payload_block = ""

    complete_fields = ["paging", "priv", "satp", "svpbmt_en", "pc"]
    live_rhs = {
        "paging": "req_paging_w",
        "priv": "priv_mode_i",
        "satp": "satp_i",
        "svpbmt_en": "svpbmt_en_i",
        "pc": "fetch_req_pc_i",
    }
    for bank in (0, 1):
        for field in complete_fields:
            token = (
                f"fetch_ctx{bank}_{field}_q <= {live_rhs[field]};"
            )
            if token not in payload_block:
                errors.append(f"missing unconditional live-bank assignment: {token}")

    for forbidden in ("mmu_flush_i", "fetch_req_ready_o", "state_q",
                      "fetch_req_fire_w"):
        if forbidden in payload_block:
            errors.append(f"wide payload write regained control dependency: {forbidden}")

    if bridge.count("fetch_ctx_sel_q <=") != 2:
        errors.append("selector has writers beyond reset and request-fire toggle")
    if "fetch_ctx_sel_q <= ~fetch_ctx_sel_q;" not in bank_block:
        errors.append("request fire no longer toggles the context selector")

    old_regs = (
        "reg paging_q;",
        "reg [1:0] req_priv_q;",
        "reg [`XLEN-1:0] req_satp_q;",
        "reg req_svpbmt_en_q;",
        "reg [`XLEN-1:0] pc_q;",
    )
    for token in old_regs:
        if token in bridge:
            errors.append(f"old single-bank context state restored: {token}")

    required_bridge = [
        "assign fetch_req_owner_pc_o = pc_q;",
        "wire [`XLEN-1:0] pc_q = fetch_ctx_sel_q ?",
        "[T3Z-CTX-INACTIVE-TRACK]",
        "[T3Z-CTX-FIRE-SWAP]",
        "[T3Z-CTX-ACTIVE-HOLD]",
        "[T3Z-CTX-FLUSH-NO-SWAP]",
        "[T3Z-CTX-RSP-STALL]",
        "[T3Z-CTX-ATOMIC-REPLACE]",
    ]
    for token in required_bridge:
        if token not in bridge:
            errors.append(f"missing Bridge owner token: {token}")

    if "input fetch_rsp_fire_i" in mux:
        errors.append("RequestMux still exposes response fire")
    if "input fetch_rsp_valid_i" not in mux:
        errors.append("RequestMux lacks registered response presence")
    mux_select = "(outstanding_valid_i && fetch_rsp_valid_i) ?"
    if mux_select not in mux:
        errors.append("sequential request candidate is not response-valid preloaded")

    forbidden_seq = ("reg [`XLEN-1:0] outstanding_pc_q;",
                     "outstanding_pc_q <=")
    for token in forbidden_seq:
        if token in sequencer:
            errors.append(f"duplicate Sequencer PC owner restored: {token}")
    required_seq = [
        "input [`XLEN-1:0] fetch_req_owner_pc_i",
        "assign outstanding_pc_o = fetch_req_owner_pc_i;",
        "[T3Z-SPECIAL-OWNER-PC]",
    ]
    for token in required_seq:
        if token not in sequencer:
            errors.append(f"missing Sequencer single-owner token: {token}")

    chain_tokens = {
        "core": [
            ".fetch_req_owner_pc_o(ooo_fetch_req_owner_pc_w)",
            ".fetch_req_owner_pc_i(ooo_fetch_req_owner_pc_w)",
        ],
        "glue": [
            "input [`XLEN-1:0] fetch_req_owner_pc_i",
            ".fetch_req_owner_pc_i(fetch_req_owner_pc_i)",
        ],
        "frontend": [
            "input [`XLEN-1:0] fetch_req_owner_pc_i",
            ".fetch_req_owner_pc_i(fetch_req_owner_pc_i)",
            ".fetch_rsp_valid_i(fetch_rsp_valid_i)",
        ],
    }
    for owner, tokens in chain_tokens.items():
        for token in tokens:
            if token not in src[owner]:
                errors.append(f"broken active-PC port chain in {owner}: {token}")

    return errors


def mutate(base: dict[str, str], owner: str, old: str, new: str) -> dict[str, str]:
    changed = dict(base)
    if old not in changed[owner]:
        raise RuntimeError(f"mutation anchor missing in {owner}: {old}")
    changed[owner] = changed[owner].replace(old, new, 1)
    return changed


def main() -> int:
    sources = {name: path.read_text(encoding="utf-8")
               for name, path in PATHS.items()}
    errors = audit(sources)

    mutations = {
        "gate_inactive_bank_with_fire": mutate(
            sources, "bridge", "if (fetch_ctx_sel_q) begin",
            "if (fetch_req_fire_w && fetch_ctx_sel_q) begin"),
        "remove_selector_toggle": mutate(
            sources, "bridge", "fetch_ctx_sel_q <= ~fetch_ctx_sel_q;",
            "/* mutated: selector toggle removed */"),
        "gate_bank_with_flush": mutate(
            sources, "bridge", "if (fetch_ctx_sel_q) begin",
            "if (mmu_flush_i) begin\n"
            "        fetch_ctx0_pc_q <= {`XLEN{1'b0}};\n"
            "      end else if (fetch_ctx_sel_q) begin"),
        "restore_response_fire_select": mutate(
            mutate(sources, "mux", "input fetch_rsp_valid_i",
                   "input fetch_rsp_fire_i"),
            "mux", "outstanding_valid_i && fetch_rsp_valid_i",
            "outstanding_valid_i && fetch_rsp_fire_i"),
        "restore_duplicate_pc_owner": mutate(
            sources, "sequencer", "reg outstanding_valid_q;",
            "reg outstanding_valid_q;\n  reg [`XLEN-1:0] outstanding_pc_q;"),
        "delete_special_owner_guard": mutate(
            sources, "sequencer", "[T3Z-SPECIAL-OWNER-PC]", "[MUTATED]"),
        "break_core_owner_chain": mutate(
            sources, "core", ".fetch_req_owner_pc_i(ooo_fetch_req_owner_pc_w)",
            ".fetch_req_owner_pc_i({`XLEN{1'b0}})"),
    }

    mutation_results = {}
    for name, candidate in mutations.items():
        candidate_errors = audit(candidate)
        rejected = bool(candidate_errors)
        mutation_results[name] = {
            "rejected": rejected,
            "errors": candidate_errors,
        }
        if not rejected:
            errors.append(f"negative mutation escaped audit: {name}")

    result = {
        "status": "PASS" if not errors else "FAIL",
        "production_errors": errors,
        "negative_mutations": mutation_results,
        "files": {name: str(path) for name, path in PATHS.items()},
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
