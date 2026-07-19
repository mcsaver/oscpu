#!/usr/bin/env python3
"""Permanent source gate for the production IFU coherence contract."""

import re
import sys
from pathlib import Path


class ContractError(RuntimeError):
    pass


def clean(text):
    text = re.sub(
        r"/\*.*?\*/",
        lambda match: "\n" * match.group(0).count("\n"),
        text,
        flags=re.S,
    )
    return re.sub(r"//[^\n]*", "", text)


def close_paren(text, opening):
    depth = 0
    for index in range(opening, len(text)):
        depth += text[index] == "("
        depth -= text[index] == ")"
        if depth == 0:
            return index
    raise ContractError("unbalanced instance parentheses")


def ports(text, instance):
    text = clean(text)
    hits = list(re.finditer(rf"\b{re.escape(instance)}\b\s*\(", text))
    if len(hits) != 1:
        raise ContractError(
            f"expected one {instance} instance, found {len(hits)}"
        )
    opening = text.find("(", hits[0].start())
    body = text[opening + 1 : close_paren(text, opening)]
    result = {}
    cursor = 0
    while True:
        hit = re.search(r"\.([A-Za-z_$][A-Za-z0-9_$]*)\s*\(", body[cursor:])
        if hit is None:
            return result
        name = hit.group(1)
        opening = cursor + hit.end() - 1
        closing = close_paren(body, opening)
        if name in result:
            raise ContractError(f"{instance} duplicates .{name}")
        result[name] = re.sub(r"\s+", "", body[opening + 1 : closing])
        cursor = closing + 1


def need(texts, key, instance, port, expected):
    found = ports(texts[key], instance)
    actual = found.get(port)
    expected = re.sub(r"\s+", "", expected)
    if actual != expected:
        raise ContractError(
            f"{key}: {instance}.{port}={actual!r}, expected {expected!r}"
        )


def check(texts):
    # Connectivity proof: no ordinary-store signal can reach the production
    # bridge invalidation ABI when both named-port expressions are constants.
    need(texts, "core", "u_ooo_fetch_bridge", "invalidate_valid_i", "1'b0")
    need(
        texts,
        "core",
        "u_ooo_fetch_bridge",
        "invalidate_addr_i",
        "{`XLEN{1'b0}}",
    )

    # Serialized FENCE.I owner and mmu_flush transport across integration.
    need(texts, "core", "u_ooo_core", "mmu_flush_o", "ooo_mmu_flush_w")
    need(
        texts,
        "core",
        "u_ooo_fetch_bridge",
        "mmu_flush_i",
        "ooo_mmu_flush_w",
    )
    need(
        texts, "core", "u_ooo_mem_bridge", "mmu_flush_i", "ooo_mmu_flush_w"
    )
    need(
        texts,
        "glue",
        "u_control_plane",
        "pending_system_fencei_commit_w",
        "pending_system_fencei_commit_w",
    )
    need(
        texts,
        "glue",
        "u_memory_access",
        "pending_system_fencei_commit_w",
        "pending_system_fencei_commit_w",
    )
    need(texts, "glue", "u_memory_access", "mmu_flush_o", "mmu_flush_o")
    need(
        texts,
        "access",
        "u_memory_request_gate",
        "pending_system_fencei_commit_i",
        "pending_system_fencei_commit_w",
    )
    need(
        texts, "access", "u_memory_request_gate", "mmu_flush_o", "mmu_flush_o"
    )
    need(
        texts, "bridge", "u_fetch_packet_cache", "clear_i", "mmu_flush_i"
    )
    need(texts, "bridge", "u_itlb", "clear_i", "mmu_flush_i")

    gate = clean(texts["gate"])
    rhs = re.findall(r"\bmmu_flush_q\s*<=\s*([^;]+);", gate)
    if len(rhs) != 1:
        raise ContractError("gate: mmu_flush_q must have one sequential owner")
    for token in (
        "pending_system_satp_write_commit_i",
        "pending_system_sfence_commit_i",
        "pending_system_fencei_commit_i",
    ):
        if token not in rhs[0]:
            raise ContractError(f"gate: mmu_flush_q lost {token}")

    control = clean(texts["control"])
    rhs = re.findall(
        r"\bassign\s+pending_system_fencei_commit_w\s*=\s*([^;]+);",
        control,
    )
    if len(rhs) != 1:
        raise ContractError("control: fence.i commit must have one owner")
    for token in (
        "stop_pending_q",
        "drain_complete_w",
        "pending_system_q",
        "pending_system_fencei_q",
    ):
        if token not in rhs[0]:
            raise ContractError(f"control: fence.i commit lost {token}")


def main():
    root = Path(__file__).resolve().parents[4]
    paths = {
        "core": "npc/rv64/vsrc/core/NpcCoreTop.v",
        "glue": "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "access": "npc/rv64/vsrc/memory/OooMemoryAccess.v",
        "gate": "npc/rv64/vsrc/memory/OooMemoryRequestGate.v",
        "control": "npc/rv64/vsrc/control/OooControlPlane.v",
        "bridge": "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    }
    texts = {
        key: (root / path).read_text(encoding="utf-8")
        for key, path in paths.items()
    }
    check(texts)

    retired = dict(texts)
    retired["core"] = retired["core"].replace(
        ".invalidate_valid_i(1'b0)",
        ".invalidate_valid_i(icache_inv_valid_q)",
        1,
    )
    try:
        check(retired)
    except ContractError:
        print("[NEGATIVE] ordinary-store invalidate topology rejected")
    else:
        raise ContractError("ordinary-store negative mutation was accepted")

    cut = dict(texts)
    cut["access"] = cut["access"].replace(
        ".pending_system_fencei_commit_i(pending_system_fencei_commit_w)",
        ".pending_system_fencei_commit_i(1'b0)",
        1,
    )
    try:
        check(cut)
    except ContractError:
        print("[NEGATIVE] cut FENCE.I/mmu_flush chain rejected")
    else:
        raise ContractError("FENCE.I chain-cut negative mutation was accepted")

    print("[PASS] IFU ordinary-store/FENCE.I coherence contract")


if __name__ == "__main__":
    try:
        main()
    except (ContractError, OSError) as error:
        print(f"[FAIL] {error}", file=sys.stderr)
        raise SystemExit(1)
