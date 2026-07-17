#!/usr/bin/env python3
"""Static exact-owner ABI continuity check with an in-memory mutation test."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


REPO = Path(__file__).resolve().parents[3]
FILES = {
    "decode": REPO / "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "slice": REPO / "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "execute": REPO / "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "glue": REPO / "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "top": REPO / "npc/rv64/vsrc/core/NpcCoreTop.v",
}

REQUEST = [
    "mem_req_owner_kind_o",
    "mem_req_owner_token_o",
    "mem_req_mmu_epoch_o",
    "mem_req_fault_tval_o",
]
RESPONSE = [
    "mem_rsp_owner_kind_i",
    "mem_rsp_owner_token_i",
    "mem_rsp_mmu_epoch_i",
    "mem_rsp_fault_tval_i",
]
EXPECTED = [
    "mem_expected_valid_o",
    "mem_expected_owner_kind_o",
    "mem_expected_owner_token_o",
    "mem_expected_mmu_epoch_o",
    "mem_expected_tval_valid_o",
    "mem_expected_fault_tval_o",
    "mem_expected_effective_killed_o",
]
OWNER_QUERY = ["mem_owner_query_valid_i", "mem_owner_query_token_i"]
TRACKER = [
    "mem_tracker_expected_valid_o",
    "mem_tracker_expected_owner_kind_o",
    "mem_tracker_expected_owner_token_o",
    "mem_tracker_expected_mmu_epoch_o",
]
STATION_QUERY = ["mem_station_query_valid_i", "mem_station_query_token_i"]
STATION = [
    "mem_station_expected_valid_o",
    "mem_station_expected_owner_kind_o",
    "mem_station_expected_owner_token_o",
    "mem_station_expected_mmu_epoch_o",
]
DROP0 = [
    "mem_drop0_valid_i",
    "mem_drop0_owner_kind_i",
    "mem_drop0_owner_token_i",
    "mem_drop0_mmu_epoch_i",
    "mem_drop0_fault_tval_i",
]
DROP1 = [name.replace("drop0", "drop1") for name in DROP0]
RESIDENCY = ["mem_bridge_owner_residency_mask_i"]
DIRECT = (REQUEST + RESPONSE + EXPECTED + OWNER_QUERY + TRACKER +
          STATION_QUERY + STATION + DROP0 + DROP1 + RESIDENCY)


def compact(text: str) -> str:
    return re.sub(r"\s+", "", text)


def connection(port: str, signal: str) -> str:
    return compact(f".{port}({signal})")


def evaluate(texts: dict[str, str]) -> tuple[list[str], int]:
    failures: list[str] = []
    checks = 0

    # The two inner wrappers must be transparent: every external exact-owner
    # port is connected to the identically named OooIntBackend port.
    for layer in ("decode", "slice"):
        body = compact(texts[layer])
        for port in DIRECT:
            checks += 1
            if connection(port, port) not in body:
                failures.append(f"{layer}: missing transparent {port}")

    # OooExecuteBackend renames only backend-produced outputs with core_mem_*;
    # bridge-produced inputs remain identically named.
    execute_body = compact(texts["execute"])
    execute_signals: dict[str, str] = {}
    for port in REQUEST + EXPECTED + TRACKER + STATION:
        execute_signals[port] = "core_" + port[:-2] + "_w"
    for port in RESPONSE + OWNER_QUERY + STATION_QUERY + DROP0 + DROP1 + RESIDENCY:
        execute_signals[port] = port
    for port, signal in execute_signals.items():
        checks += 1
        if connection(port, signal) not in execute_body:
            failures.append(f"execute: missing {port}->{signal}")

    # Core glue connects the execute wrapper's exact ABI without a mux or
    # constant reconstruction.  Produced values retain their core_mem_* names.
    glue_body = compact(texts["glue"])
    for port, signal in execute_signals.items():
        execute_port = signal if port in REQUEST + EXPECTED + TRACKER + STATION else port
        checks += 1
        if connection(execute_port, signal) not in glue_body:
            failures.append(f"glue: missing {execute_port}->{signal}")

    # NpcCoreTop is the only join point.  Each logical wire must appear once on
    # the core boundary and once on the bridge boundary with the correct
    # direction.  This rejects constant token/epoch tie-offs and crossed lanes.
    pairs: list[tuple[str, str, str]] = []
    req_fields = ["owner_kind", "owner_token", "mmu_epoch", "fault_tval"]
    rsp_fields = req_fields
    for field in req_fields:
        wire = f"ooo_mem0_req_{field}_w"
        pairs.append((f"mem0_req_{field}_i", f"mem_req_{field}_o", wire))
    for field in rsp_fields:
        wire = f"ooo_mem0_rsp_{field}_w"
        pairs.append((f"mem0_rsp_{field}_o", f"mem_rsp_{field}_i", wire))
    expected_fields = [
        "valid", "owner_kind", "owner_token", "mmu_epoch", "tval_valid",
        "fault_tval", "effective_killed",
    ]
    for field in expected_fields:
        wire = f"ooo_mem0_expected_{field}_w"
        pairs.append((f"mem0_expected_{field}_i", f"mem_expected_{field}_o", wire))
    for field in ["valid", "token"]:
        wire = f"ooo_mem0_owner_query_{field}_w"
        pairs.append((f"mem0_owner_query_{field}_o", f"mem_owner_query_{field}_i", wire))
    tracker_fields = ["valid", "owner_kind", "owner_token", "mmu_epoch"]
    for field in tracker_fields:
        wire = f"ooo_mem0_tracker_expected_{field}_w"
        pairs.append((f"mem0_tracker_expected_{field}_i",
                      f"mem_tracker_expected_{field}_o", wire))
    for field in ["valid", "token"]:
        wire = f"ooo_mem0_station_query_{field}_w"
        pairs.append((f"mem0_station_query_{field}_o",
                      f"mem_station_query_{field}_i", wire))
    for field in tracker_fields:
        wire = f"ooo_mem0_station_expected_{field}_w"
        pairs.append((f"mem0_station_expected_{field}_i",
                      f"mem_station_expected_{field}_o", wire))
    for lane in (0, 1):
        for field in ["valid", "owner_kind", "owner_token", "mmu_epoch", "fault_tval"]:
            wire = f"ooo_mem0_drop{lane}_{field}_w"
            pairs.append((f"mem0_drop{lane}_{field}_o",
                          f"mem_drop{lane}_{field}_i", wire))
    pairs.append(("mem0_owner_residency_mask_o",
                  "mem_bridge_owner_residency_mask_i",
                  "ooo_mem0_owner_residency_mask_w"))

    top_body = compact(texts["top"])
    for bridge_port, core_port, wire in pairs:
        for endpoint, port in (("bridge", bridge_port), ("core", core_port)):
            checks += 1
            if connection(port, wire) not in top_body:
                failures.append(f"top/{endpoint}: missing {port}->{wire}")
    return failures, checks


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    texts = {name: path.read_text(encoding="utf-8") for name, path in FILES.items()}
    failures, checks = evaluate(texts)
    if failures:
        for failure in failures:
            print(f"[S2-G1-WRAPPER-ABI][FAIL] {failure}")
        return 1
    print(f"[S2-G1-WRAPPER-ABI][PASS] checks={checks}")

    if args.self_test:
        mutant = dict(texts)
        exact = ".mem0_req_owner_token_i(ooo_mem0_req_owner_token_w)"
        if exact not in compact(mutant["top"]):
            print("[S2-G1-WRAPPER-ABI-MUTATION][FAIL] mutation anchor missing")
            return 1
        mutant["top"] = mutant["top"].replace(
            ".mem0_req_owner_token_i(ooo_mem0_req_owner_token_w)",
            ".mem0_req_owner_token_i(5'b00000)",
            1,
        )
        mutant_failures, _ = evaluate(mutant)
        if not any("mem0_req_owner_token_i" in item for item in mutant_failures):
            print("[S2-G1-WRAPPER-ABI-MUTATION][FAIL] constant-token mutant survived")
            return 1
        print("[S2-G1-WRAPPER-ABI-MUTATION][EXPECTED-FAIL] constant request token rejected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
