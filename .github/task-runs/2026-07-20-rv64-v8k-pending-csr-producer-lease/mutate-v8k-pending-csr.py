#!/usr/bin/env python3
"""Create one exact, compile-success v8k pending-CSR ownership mutant."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8K-MUTATOR][FAIL] {message}")


@dataclass(frozen=True)
class Mutation:
    kind: str
    relpath: str
    old: str
    new: str


MUTATIONS: dict[str, Mutation] = {
    "lease_output_metadata_gated": Mutation(
        "sequencer", "control/OooPendingSystemSequencer.v",
        "  assign producer_valid_o = producer_valid_q;",
        "  assign producer_valid_o =\n"
        "      producer_valid_q && valid_q && csr_q && dispatched_q;",
    ),
    "ordinary_clear_kills_live": Mutation(
        "sequencer", "control/OooPendingSystemSequencer.v",
        "      if (producer_death_i) begin",
        "      if (producer_death_i || clear_i) begin",
    ),
    "clear_dispatched_kills_live": Mutation(
        "sequencer", "control/OooPendingSystemSequencer.v",
        "      if (producer_death_i) begin",
        "      if (producer_death_i || clear_dispatched_i) begin",
    ),
    "birth_drops_generation": Mutation(
        "sequencer", "control/OooPendingSystemSequencer.v",
        "      producer_id_q <= dispatch_producer_id_i;",
        "      producer_id_q <=\n"
        "          {{PRODUCER_GEN_W{1'b0}},\n"
        "           dispatch_producer_id_i[ROB_INDEX_W-1:0]};",
    ),
    "claim_seal_ignores_raw": Mutation(
        "mux", "control/OooCsrAccessRequestMux.v",
        "  wire pending_system_csr_claim_seal_w =\n"
        "      pending_system_producer_valid_i || pending_system_csr_logical_claim_w;",
        "  wire pending_system_csr_claim_seal_w =\n"
        "      pending_system_csr_logical_claim_w;",
    ),
    "pid_match_ignores_generation": Mutation(
        "mux", "control/OooCsrAccessRequestMux.v",
        "  wire pending_system_csr_pid_match_w =\n"
        "      core_commit0_producer_id_i == pending_system_producer_id_i;",
        "  wire pending_system_csr_pid_match_w =\n"
        "      core_commit0_producer_id_i[ROB_INDEX_W-1:0] ==\n"
        "      pending_system_producer_id_i[ROB_INDEX_W-1:0];",
    ),
    "pc_match_removed": Mutation(
        "mux", "control/OooCsrAccessRequestMux.v",
        "  wire pending_system_csr_pc_match_w =\n"
        "      core_commit0_pc_i == pending_system_pc_i;",
        "  wire pending_system_csr_pc_match_w = 1'b1;",
    ),
    "dispatch_cancel_removed": Mutation(
        "drain", "control/OooPendingDrainResolveGate.v",
        "  assign system_csr_dispatch_valid_o =\n"
        "      !system_csr_dispatch_cancel_i &&\n"
        "      stop_pending_i && pending_system_i && pending_system_csr_i &&",
        "  assign system_csr_dispatch_valid_o =\n"
        "      stop_pending_i && pending_system_i && pending_system_csr_i &&",
    ),
    "pending_jump_ready_overcancels": Mutation(
        "admission", "control/OooPendingSystemAdmissionCancelGate.v",
        "  wire pending_jump_clear_w =\n"
        "      pending_jump_resolve_ready_i &&\n"
        "      (pending_jump_misaligned_i ||\n"
        "       pending_jump_nolink_commit_i ||\n"
        "       pending_jump_redirect_after_dispatch_i);",
        "  wire pending_jump_clear_w = pending_jump_resolve_ready_i;",
    ),
    "pending_mask_removed": Mutation(
        "backend", "execute/OooIntBackend.v",
        "      clmul_owner_producer_live_mask_w |\n"
        "      fp_producer_live_mask_w |\n"
        "      pending_system_producer_live_mask_w;",
        "      clmul_owner_producer_live_mask_w |\n"
        "      fp_producer_live_mask_w;",
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case", required=True, choices=sorted(MUTATIONS))
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    run_dir = Path(__file__).resolve().parent
    repo = run_dir.parents[2]
    mutation = MUTATIONS[args.case]
    source = repo / "npc/rv64/vsrc" / mutation.relpath
    source_text = source.read_text(encoding="utf-8")
    count = source_text.count(mutation.old)
    if count != 1:
        fail(f"{args.case}: expected one source anchor, found {count}")
    mutated = source_text.replace(mutation.old, mutation.new, 1)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(mutated, encoding="utf-8")
    print(json.dumps({"case": args.case, "kind": mutation.kind,
                      "source": str(source), "output": str(args.out)},
                     sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
