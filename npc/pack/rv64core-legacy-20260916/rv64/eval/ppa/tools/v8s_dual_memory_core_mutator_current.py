#!/usr/bin/env python3
"""Current-design anchors for the immutable V8S compile-success mutations."""

from __future__ import annotations

import argparse
import importlib.util
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[5]
LEGACY_PATH = (
    ROOT
    / ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration"
    / "mutate-v8s-dual-memory-core.py"
)
SPEC = importlib.util.spec_from_file_location("v8s_legacy_mutator", LEGACY_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"cannot load immutable V8S mutator: {LEGACY_PATH}")
LEGACY = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = LEGACY
SPEC.loader.exec_module(LEGACY)


CURRENT_MUTATIONS: dict[str, tuple[str, str]] = {
    "singleton_priority_bypass": (
        "wire live_grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !mem_req_effective_singleton_w &&\n"
        "      !live_grant_retry1_w && issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !live_grant_mem1_issue0_w;",
        "wire live_grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !mem_req_effective_singleton_w && !live_grant_retry1_w &&\n"
        "       issue1_dual_selected_w && issue1_dual_bank1_w &&\n"
        "       !live_grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_amo_write_req_valid_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
    "legacy_release_lookthrough": (
        "wire live_grant_mem1_issue1_w = ENABLE_DUAL_MEM &&\n"
        "      mem_request_transport_open_w && !mem_req_effective_singleton_w &&\n"
        "      !live_grant_retry1_w && issue1_dual_selected_w &&\n"
        "      issue1_dual_bank1_w && !live_grant_mem1_issue0_w;",
        "wire live_grant_mem1_issue1_w =\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       !mem_req_effective_singleton_w && !live_grant_retry1_w &&\n"
        "       issue1_dual_selected_w && issue1_dual_bank1_w &&\n"
        "       !live_grant_mem1_issue0_w) ||\n"
        "      (ENABLE_DUAL_MEM && mem_request_transport_open_w &&\n"
        "       mem_rsp_final_fire_w && mem_issue1_res_valid_q &&\n"
        "       issue1_dual_bank1_w);",
    ),
}

# Consumers that reconstruct frozen compile-success mutations import the same
# interface as the immutable V8S mutator.  Only the two hold-aware anchors are
# replaced; the other sixteen identities and all phase alternatives remain
# byte-for-byte inherited from the historical asset.
MUTATIONS = dict(LEGACY.MUTATIONS)
MUTATIONS.update(CURRENT_MUTATIONS)
F3_MUTATIONS = LEGACY.F3_MUTATIONS
V8V_MUTATIONS = LEGACY.V8V_MUTATIONS


def candidates(name: str) -> list[tuple[str, str]]:
    result: list[tuple[str, str]] = []
    if name in CURRENT_MUTATIONS:
        result.append(CURRENT_MUTATIONS[name])
    result.append(LEGACY.MUTATIONS[name])
    if name in LEGACY.F3_MUTATIONS:
        result.append(LEGACY.F3_MUTATIONS[name])
    if name in LEGACY.V8V_MUTATIONS:
        result.append(LEGACY.V8V_MUTATIONS[name])
    return result


def mutate(name: str, source: pathlib.Path, output: pathlib.Path) -> None:
    expected_source = (
        "OooCoreSliceControlGate.v"
        if name == "raw_checkpoint_local_flush_bypass"
        else "OooIntBackend.v"
    )
    if source.name != expected_source:
        raise ValueError(f"expected {expected_source}, got {source.name}")
    text = source.read_text(encoding="utf-8")
    hits = [(old, new) for old, new in candidates(name) if text.count(old) == 1]
    if len(hits) != 1:
        counts = [text.count(old) for old, _ in candidates(name)]
        raise ValueError(f"{name}: expected one exact phase anchor, got {counts}")
    old, new = hits[0]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text.replace(old, new, 1), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mutation", choices=sorted(LEGACY.MUTATIONS))
    parser.add_argument("source", type=pathlib.Path)
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    try:
        mutate(args.mutation, args.source, args.output)
    except (OSError, ValueError) as exc:
        print(f"[V8S-MUTATOR][FAIL] {exc}", file=sys.stderr)
        return 1
    print(
        f"[V8S-MUTATOR][PASS] name={args.mutation} "
        f"source={args.source} output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
