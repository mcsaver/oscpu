#!/usr/bin/env python3
"""Build hash-bound OOO-3 memory-ordering evidence from live RTL tests."""

from __future__ import annotations

import argparse
import datetime
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
from typing import Any

from directed_evidence_manifest import merge_directed_record


ARCH_TOOL = pathlib.Path(__file__).with_name("architecture_hard_gates.py")
SPEC = importlib.util.spec_from_file_location("architecture_hard_gates", ARCH_TOOL)
assert SPEC is not None and SPEC.loader is not None
arch = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = arch
SPEC.loader.exec_module(arch)

RUN_ID = "2026-07-21-rv64-v8v-memory-ordering"
REQUIRED_MUTATIONS = {
    "pid_index_only",
    "issue_killed_bypass",
    "query_metadata_bypass",
    "response_order_bypass",
    "terminal_releases_normal",
    "flush_drops_launched",
    "release_before_completion",
    "dual_alloc_same_slot",
    "dual_query_same_pid_bypass",
}
F2_RESULT = pathlib.Path(
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/result.json"
)
F2_MUTATION_SUMMARY = pathlib.Path(
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/mutation-summary.log"
)
F2_MUTATOR = pathlib.Path(
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "mutate-v8s-dual-memory-core.py"
)
F2_CONTROL_GATE_MUTATION_LOG = pathlib.Path(
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/mutations/"
    "raw_checkpoint_local_flush_bypass.run.log"
)
F2_REQUIRED_MUTATIONS = {
    "bank1_tieoff",
    "swap_bank_mapping",
    "invert_same_bank_age",
    "alias_miq1_completion_head",
    "double_claim_wb0",
    "tieoff_sq_terminal1",
    "duplicate_bridge_drop_token",
    "allow_killed_mem1_wb",
    "ordinary_store_direct_write",
    "singleton_priority_bypass",
    "legacy_release_lookthrough",
    "omit_checkpoint_lq_recovery",
    "omit_checkpoint_dispatch_recovery",
    "omit_checkpoint_sq_recovery",
    "bypass_lq_retire_permit",
    "bypass_checkpoint_irrevocable_guard",
    "bypass_checkpoint_commit1_block",
    "raw_checkpoint_local_flush_bypass",
}
DI5_METRIC = (
    "[V8U-DI5-METRIC] trace_cycles=64 memory_issue_ipc_milli=2000 "
    "dual_issue_cycles=64 agu_accepts=64,64 translation_accepts=64,64 "
    "physical_lsq_queries=64,64 cache_admissions=64,64 "
    "completions=64,64"
)
PRECISE_B_RE = re.compile(
    r"^\[T4N-B-ERROR-PRECISE\] "
    r"va=0x0000000040001040 pa=0x0000000080001240 cause=7$",
    flags=re.MULTILINE,
)


def clean_simulation(path: pathlib.Path) -> str:
    text = path.read_text(encoding="utf-8")
    if text.count("[RESULT] PASS") != 1:
        raise ValueError(f"{path}: expected exactly one [RESULT] PASS")
    for marker in ("[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"):
        if marker in text:
            raise ValueError(f"{path}: unexpected failure marker {marker}")
    return text


def require_once(text: str, marker: str, label: str) -> None:
    if text.count(marker) != 1:
        raise ValueError(f"{label}: expected unique marker {marker}")


def read_mutations(path: pathlib.Path, lq_path: pathlib.Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    results = payload.get("results")
    if (
        payload.get("schema_version") != "rv64-lq-mutation-evidence-v1"
        or payload.get("all_passed") is not True
        or payload.get("mutation_count") != len(REQUIRED_MUTATIONS)
        or payload.get("compile_success_count") != len(REQUIRED_MUTATIONS)
        or payload.get("dynamic_rejected_count") != len(REQUIRED_MUTATIONS)
        or payload.get("passed_count") != len(REQUIRED_MUTATIONS)
        or not isinstance(results, list)
    ):
        raise ValueError("LQ mutation aggregate is incomplete")
    if {item.get("name") for item in results if isinstance(item, dict)} != REQUIRED_MUTATIONS:
        raise ValueError("LQ mutation identity set mismatch")
    for item in results:
        if not isinstance(item, dict) or any(
            item.get(field) is not True
            for field in (
                "compile_success", "oracle_seen", "dynamic_rejected", "passed"
            )
        ):
            raise ValueError(f"LQ mutation did not reject dynamically: {item}")
    if payload.get("source_sha256") != arch.digest(lq_path):
        raise ValueError("LQ mutation source digest is stale")
    return payload


def reconstruct_mutation_sha256(
    name: str,
    source_text: str,
    candidates: list[tuple[str, str]],
) -> str:
    """Rebuild one compile-success RTL mutation from one live source anchor."""
    hits = [
        (old, new) for old, new in candidates
        if source_text.count(old) == 1
    ]
    if len(hits) != 1:
        raise ValueError(f"F2 mutation {name} has {len(hits)} live anchors")
    old, new = hits[0]
    mutant_text = source_text.replace(old, new, 1)
    if old == new or mutant_text.encode("utf-8") == source_text.encode("utf-8"):
        raise ValueError(f"F2 mutation {name} is a byte-identical no-op")
    return hashlib.sha256(mutant_text.encode("utf-8")).hexdigest()


def read_f2_parent_mutations(root: pathlib.Path) -> dict[str, Any]:
    result_path = arch.safe_artifact(root, F2_RESULT.as_posix())
    summary_path = arch.safe_artifact(root, F2_MUTATION_SUMMARY.as_posix())
    mutator_path = arch.safe_artifact(root, F2_MUTATOR.as_posix())
    control_gate_log_path = arch.safe_artifact(
        root, F2_CONTROL_GATE_MUTATION_LOG.as_posix())
    payload = json.loads(result_path.read_text(encoding="utf-8"))
    expected_count = len(F2_REQUIRED_MUTATIONS)
    mutations = payload.get("mutations")
    profiles = payload.get("profiles")
    if (
        payload.get("schema") != "v8s-dual-memory-core-evidence/v1"
        or payload.get("status") != "PASS"
        or payload.get("claim") != "architecture_checkpoint"
        or payload.get("canonical_architecture_manifest_modified") is not False
        or payload.get("promotion_eligible") is not False
        or payload.get("ppa") != "UNQUALIFIED"
        or payload.get("architecture") != {
            "DI-5": "RED", "OOO-3": "RED", "overall": "RED"
        }
        or not isinstance(mutations, dict)
        or any(
            mutations.get(field) != expected_count
            for field in (
                "required", "detected", "compile_success", "elaborated",
                "activated",
            )
        )
        or not isinstance(profiles, dict)
        or set(profiles) != {
            "focused_assert", "focused_release", "legacy_assert",
            "npc_core_assert_lint", "npc_core_release_lint",
            "npc_sim_assert_stats_lint",
        }
        or any(value != "PASS" for value in profiles.values())
    ):
        raise ValueError("F2 integration evidence aggregate is incomplete")

    rtl = payload.get("rtl_sha256")
    backend = root / "npc/rv64/vsrc/execute/OooIntBackend.v"
    control_gate = root / "npc/rv64/vsrc/control/OooCoreSliceControlGate.v"
    tb = root / "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
    glue_tb = root / "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
    if (
        not isinstance(rtl, dict)
        or rtl.get("backend") != arch.digest(backend)
        or rtl.get("core_slice_control_gate") != arch.digest(control_gate)
        or payload.get("tb_sha256") != arch.digest(tb)
        or payload.get("core_glue_tb_sha256") != arch.digest(glue_tb)
    ):
        raise ValueError("F2 integration evidence is stale for live RTL/TB")

    row_re = re.compile(
        r"^\[V8S-MUTATION\]\[PASS\] run_id=(\S+) name=(\S+) "
        r"compile_success=true elaborated=true activated=true "
        r"target_rejected=true oracle=.+ mutant_sha256=([0-9a-f]{64}) "
        r"image_sha256=([0-9a-f]{64})$",
        flags=re.MULTILINE,
    )
    rows = row_re.findall(summary_path.read_text(encoding="utf-8"))
    if (
        len(rows) != expected_count
        or {row[1] for row in rows} != F2_REQUIRED_MUTATIONS
        or {row[0] for row in rows} != {payload.get("run_id")}
    ):
        raise ValueError("F2 integration mutation identities are incomplete")
    row_by_name = {row[1]: row for row in rows}
    mutator_spec = importlib.util.spec_from_file_location(
        "v8s_dual_memory_core_mutator", mutator_path)
    if mutator_spec is None or mutator_spec.loader is None:
        raise ValueError("F2 mutator module cannot be loaded")
    mutator = importlib.util.module_from_spec(mutator_spec)
    mutator_spec.loader.exec_module(mutator)
    if set(mutator.MUTATIONS) != F2_REQUIRED_MUTATIONS:
        raise ValueError("F2 live mutator identity set mismatch")
    backend_text = backend.read_text(encoding="utf-8")
    control_gate_text = control_gate.read_text(encoding="utf-8")
    for name in sorted(F2_REQUIRED_MUTATIONS):
        source_text = (
            control_gate_text
            if name == "raw_checkpoint_local_flush_bypass"
            else backend_text
        )
        candidates = [mutator.MUTATIONS[name]]
        if name in mutator.F3_MUTATIONS:
            candidates.append(mutator.F3_MUTATIONS[name])
        if name in mutator.V8V_MUTATIONS:
            candidates.append(mutator.V8V_MUTATIONS[name])
        expected_mutant_sha = reconstruct_mutation_sha256(
            name, source_text, candidates)
        if row_by_name[name][2] != expected_mutant_sha:
            raise ValueError(f"F2 mutation {name} digest is not reproducible")
    control_gate_log = control_gate_log_path.read_text(encoding="utf-8")
    if (
        control_gate_log.count(
            "raw checkpoint restore does not assert core local flush"
        ) != 1
        or control_gate_log.count("[RESULT] FAIL status=1") != 1
        or "[RESULT] PASS" in control_gate_log
        or "[COMPILE]" not in control_gate_log
    ):
        raise ValueError("F2 ControlGate dynamic rejection log is incomplete")
    return payload


def workspace_output(root: pathlib.Path, value: pathlib.Path) -> pathlib.Path:
    path = value if value.is_absolute() else root / value
    path = path.resolve()
    if not path.is_relative_to(root):
        raise ValueError(f"output escapes repository: {value}")
    if path.exists() and path.is_symlink():
        raise ValueError(f"output traverses symlink: {value}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=pathlib.Path)
    parser.add_argument("--lq-log", required=True, type=pathlib.Path)
    parser.add_argument("--sq-log", required=True, type=pathlib.Path)
    parser.add_argument("--backend-log", required=True, type=pathlib.Path)
    parser.add_argument("--backend-dual-log", required=True, type=pathlib.Path)
    parser.add_argument("--glue-log", required=True, type=pathlib.Path)
    parser.add_argument("--sustained-log", required=True, type=pathlib.Path)
    parser.add_argument("--mutation-results", required=True, type=pathlib.Path)
    parser.add_argument("--sources-pre", required=True, type=pathlib.Path)
    parser.add_argument("--sources-post", required=True, type=pathlib.Path)
    parser.add_argument("--gate-log", required=True, type=pathlib.Path)
    parser.add_argument("--manifest", required=True, type=pathlib.Path)
    args = parser.parse_args()

    root = args.repo_root.resolve(strict=True)
    lq_log = args.lq_log.resolve(strict=True)
    sq_log = args.sq_log.resolve(strict=True)
    backend_log = args.backend_log.resolve(strict=True)
    backend_dual_log = args.backend_dual_log.resolve(strict=True)
    sustained_log = args.sustained_log.resolve(strict=True)
    mutation_results = args.mutation_results.resolve(strict=True)
    sources_pre = args.sources_pre.resolve(strict=True)
    sources_post = args.sources_post.resolve(strict=True)
    pre_sources = arch.validate_source_manifest(
        root, sources_pre, arch.MEMORY_ORDERING_SOURCE_PATHS)
    post_sources = arch.validate_source_manifest(
        root, sources_post, arch.MEMORY_ORDERING_SOURCE_PATHS)
    if pre_sources != post_sources or sources_pre.read_bytes() != sources_post.read_bytes():
        raise ValueError("canonical OOO-3 proof sources changed during execution")
    f2_mutation_payload = read_f2_parent_mutations(root)

    lq_text = clean_simulation(lq_log)
    sq_text = clean_simulation(sq_log)
    backend_text = clean_simulation(backend_log)
    backend_dual_text = clean_simulation(backend_dual_log)
    glue_log = args.glue_log.resolve(strict=True)
    glue_text = clean_simulation(glue_log)
    sustained_text = clean_simulation(sustained_log)

    observations: dict[str, bool] = {"f2_parent_mutations": True}

    def bind(
        key: str, text: str, marker: str, label: str,
    ) -> None:
        require_once(text, marker, label)
        observations[key] = True

    for key, marker in (
        ("lq_dual_lifecycle",
         "[V8V-LQ-DUAL-LIFECYCLE] "
         "alloc/issue/query/replay/completion/retire PASS"),
        ("lq_wrap_recovery",
         "[V8V-LQ-WRAP-RECOVERY] "
         "wrap-age/unlaunched-drop/fired-drain PASS"),
        ("lq_dual_query_conflict",
         "[V8V-LQ-DUAL-QUERY-CONFLICT] same_pid_fail_closed=1 PASS"),
    ):
        bind(key, lq_text, marker, "LQ")
    for key, marker in (
        ("sq_final_pa_disposition",
         "[V8T-F3-SQ-QUERY] "
         "allow/forward/merge/youngest/partial/poison/terminal/dual PASS"),
        ("sq_post_launch_owner",
         "[V8G-SQ-POST-LAUNCH] request_sent retains live nonterminal "
         "full-PID owner until exact B PASS"),
        ("sq_success_b_owner",
         "[S2-G1-SQ-GLOBAL-SURVIVE-BOK] exact success-B terminal retained "
         "owner until release PASS"),
        ("sq_error_b_owner",
         "[S2-G1-SQ-GLOBAL-SURVIVE-BERR] exact error-B terminal retained "
         "owner until release PASS"),
        ("sq_flush_exact_release",
         "[T4N-SQ-TERMINAL-RELEASE-GLOBAL-FLUSH] accepted owner released "
         "exactly once PASS"),
    ):
        bind(key, sq_text, marker, "SQ")
    for key, marker in (
        ("checkpoint_sq_gate",
         "[T4N-CHECKPOINT-RESTORE-SQ-GATE] "
         "no fire/owner synchronized clear PASS"),
        ("two_store_order",
         "[T4N-TWO-STORE-ORDER] sq-priority/no-false-fire/order PASS"),
        ("store_before_device_translate1",
         "[T4N-T4M-STORE-BEFORE-DEVICE] translate=1 store write/B/commit "
         "precedes load release PASS"),
        ("store_before_device_translate0",
         "[T4N-T4M-STORE-BEFORE-DEVICE] translate=0 store write/B/commit "
         "precedes load release PASS"),
        ("sq_forward_exact_completion",
         "[S1-SQ-FORWARD-BYPASS] block=1 fwd=1 local-WB/commit "
         "exactly-once PASS"),
        ("killed_response_no_side_effect",
         "[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, "
         "WB/SQ side effects zero PASS"),
    ):
        bind(key, backend_text, marker, "backend")
    if len(PRECISE_B_RE.findall(backend_text)) != 1:
        raise ValueError("backend: exact late-B cause/tval/PA marker missing")
    observations["precise_late_b"] = True
    for key, marker in (
        ("dual_backend_core",
         "[V8S-DUAL-MEMORY-CORE] diff_bank_dual_req=1"),
        ("checkpoint_lq_drain",
         "[V8V-CHECKPOINT-LQ-DRAIN] launched=2 tombstones=2 "
         "exact_terminals=2 ghosts=0 PASS"),
        ("checkpoint_owner_recovery",
         "[V8V-CHECKPOINT-OWNER-RECOVERY] load_unlaunched_clear=1 "
         "sq_unlaunched_clear=1 launched_rob_clear=2 tombstones=2 "
         "exact_terminals=2 "
         "redispatch_retire=1 ghosts=0 PASS"),
        ("checkpoint_irrevocable_write",
         "[V8V-CHECKPOINT-IRREVOCABLE-WRITE] delayed_store_okay=1 "
         "same_edge_store_error=1 amo_write=1 request_exact=3 "
         "response_exact=3 commit_exact=3 sq_free_exact=2 "
         "apply_exact=3 redispatch_retire=2 PASS"),
        ("lq_retire_authority",
         "[V8V-LQ-RETIRE-AUTHORITY] lookup_ready_gates_commit=1 "
         "commit_free_coincident=1 PASS"),
        ("final_pa_retry_lifecycle",
         "[V8T-F3-BACKEND-RETRY] bank0/bank1 "
         "capture-hold-reissue-kill + age arbitration + retry fence/F4 "
         "real-capacity admission + int/FP sinks + ready/cancel races PASS"),
    ):
        bind(key, backend_dual_text, marker, "dual backend")
    bind(
        "checkpoint_raw_restore_no_local_flush",
        glue_text,
        "[V8V-CHECKPOINT-APPLY-GATE] raw_request=1 apply=0 "
        "local_flush=0 mem_flush=0,0 PASS",
        "core glue",
    )
    bind("sustained_dual_memory", sustained_text, DI5_METRIC,
         "sustained dual memory")

    lq_path = root / "npc/rv64/vsrc/memory/OooLoadQueue.v"
    mutation_payload = read_mutations(mutation_results, lq_path)
    metric_basis = {
        "nonalias_load_bypass": (
            "lq_dual_lifecycle", "sq_final_pa_disposition",
            "dual_backend_core"),
        "alias_forward_wait_replay": (
            "sq_final_pa_disposition", "sq_forward_exact_completion",
            "final_pa_retry_lifecycle"),
        "physical_disambiguation": (
            "sq_final_pa_disposition", "lq_dual_query_conflict",
            "sustained_dual_memory"),
        "stale_read_count": (
            "lq_dual_lifecycle", "sq_final_pa_disposition",
            "killed_response_no_side_effect"),
        "ghost_after_flush": (
            "lq_wrap_recovery", "checkpoint_lq_drain",
            "checkpoint_owner_recovery",
            "checkpoint_irrevocable_write", "sq_flush_exact_release",
            "checkpoint_raw_restore_no_local_flush", "f2_parent_mutations"),
        "store_side_effect_before_authorization": (
            "checkpoint_sq_gate", "two_store_order",
            "store_before_device_translate1", "store_before_device_translate0"),
        "store_authorization_fire_violations": (
            "two_store_order", "sq_post_launch_owner"),
        "store_b_terminal_violations": (
            "sq_success_b_owner", "sq_error_b_owner",
            "checkpoint_irrevocable_write"),
        "store_retire_before_b_success": (
            "sq_success_b_owner", "store_before_device_translate1",
            "store_before_device_translate0",
            "checkpoint_irrevocable_write"),
        "precise_b_error_trap": (
            "precise_late_b", "sq_error_b_owner",
            "checkpoint_irrevocable_write"),
        "fired_store_drain_exactly_once": (
            "sq_post_launch_owner", "sq_flush_exact_release",
            "checkpoint_lq_drain", "checkpoint_irrevocable_write",
            "lq_retire_authority"),
    }
    metric_pass = {
        name: all(observations.get(item, False) for item in basis)
        for name, basis in metric_basis.items()
    }
    metrics = {
        "nonalias_load_bypass": metric_pass["nonalias_load_bypass"],
        "alias_forward_wait_replay": metric_pass["alias_forward_wait_replay"],
        "physical_disambiguation": metric_pass["physical_disambiguation"],
        "stale_read_count": 0 if metric_pass["stale_read_count"] else 1,
        "ghost_after_flush": 0 if metric_pass["ghost_after_flush"] else 1,
        "store_side_effect_before_authorization": (
            0 if metric_pass["store_side_effect_before_authorization"] else 1),
        "store_authorization_fire_violations": (
            0 if metric_pass["store_authorization_fire_violations"] else 1),
        "store_b_terminal_violations": (
            0 if metric_pass["store_b_terminal_violations"] else 1),
        "store_retire_before_b_success": (
            0 if metric_pass["store_retire_before_b_success"] else 1),
        "precise_b_error_trap": metric_pass["precise_b_error_trap"],
        "fired_store_drain_exactly_once": metric_pass[
            "fired_store_drain_exactly_once"],
    }
    failed_metrics = [
        item.check_id
        for item in arch.metric_checks("memory_ordering", metrics)
        if not item.passed
    ]
    if failed_metrics:
        raise ValueError(f"OOO-3 metric mapping rejected: {failed_metrics}")

    gate_log = workspace_output(root, args.gate_log)
    manifest = workspace_output(root, args.manifest)
    source_sha, rtl_files = arch.rtl_binding(root)
    proof_paths = (
        lq_log,
        sq_log,
        backend_log,
        backend_dual_log,
        glue_log,
        sustained_log,
        mutation_results,
        sources_pre,
        sources_post,
        arch.safe_artifact(root, F2_RESULT.as_posix()),
        arch.safe_artifact(root, F2_MUTATION_SUMMARY.as_posix()),
        arch.safe_artifact(root, F2_CONTROL_GATE_MUTATION_LOG.as_posix()),
    )
    artifacts = {
        path.relative_to(root).as_posix(): arch.digest(path)
        for path in proof_paths
        if path.is_relative_to(root)
    }
    provenance_files = {
        rel: arch.digest(arch.safe_artifact(root, rel))
        for rel in arch.MEMORY_ORDERING_PROVENANCE_PATHS
    }
    provenance_sha = arch.canonical_digest(provenance_files)

    generated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate_lines = [
        "OOO-3 memory ordering evidence",
        f"run_id={RUN_ID}",
        f"generated_at_utc={generated_at}",
        f"design_id=sha256:{source_sha}",
        f"rtl_file_count={len(rtl_files)}",
        f"provenance_sha256={provenance_sha}",
        f"source_manifest_sha256={arch.canonical_digest(pre_sources)}",
        "lq_entry_count=16",
        f"lq_compile_success_mutations={mutation_payload['passed_count']}",
        "f2_compile_success_mutations="
        f"{f2_mutation_payload['mutations']['detected']}",
        "f2_reconstructed_non_noop_mutations="
        f"{len(F2_REQUIRED_MUTATIONS)}",
    ]
    gate_lines.extend(
        f"basis {name} {','.join(basis)}"
        for name, basis in sorted(metric_basis.items())
    )
    gate_lines.extend(
        f"metric {name} {json.dumps(value)}"
        for name, value in sorted(metrics.items())
    )
    gate_lines.extend(
        f"artifact_sha256 {path} {sha}"
        for path, sha in sorted(artifacts.items())
    )
    gate_lines.append(
        "[ARCH-GATE] memory_ordering PASS "
        f"run_id={RUN_ID} design_id=sha256:{source_sha} "
        f"mutations={mutation_payload['passed_count']}"
    )
    gate_log.write_text("\n".join(gate_lines) + "\n", encoding="utf-8")

    record = {
        "command": arch.MEMORY_ORDERING_EVIDENCE_COMMAND,
        "log": {
            "path": gate_log.relative_to(root).as_posix(),
            "sha256": arch.digest(gate_log),
        },
        "metrics": metrics,
        "metric_basis": {
            name: list(basis) for name, basis in sorted(metric_basis.items())
        },
        "mutation_audit": {
            "lq_compile_success_dynamic_reject": len(REQUIRED_MUTATIONS),
            "f2_compile_success_dynamic_reject": len(F2_REQUIRED_MUTATIONS),
            "f2_reconstructed_sha256": len(F2_REQUIRED_MUTATIONS),
            "f2_non_noop": len(F2_REQUIRED_MUTATIONS),
        },
        "provenance": {
            "files": provenance_files,
            "rtl_file_count": len(rtl_files),
            "rtl_sha256": source_sha,
            "sha256": provenance_sha,
        },
        "source_manifest": {
            "files": pre_sources,
            "sha256": arch.canonical_digest(pre_sources),
        },
        "scope": (
            "OOO-3 ordinary integer/FP load ordering and precise store "
            "request/B/retirement lifecycle; not DI-1, DI-2, OOO-4, overall "
            "architecture or PPA promotion"
        ),
        "status": "PASS",
    }
    merge_directed_record(
        manifest,
        schema=arch.EVIDENCE_SCHEMA,
        design_id=f"sha256:{source_sha}",
        generated_at_utc=generated_at,
        test_id="memory_ordering",
        record=record,
    )
    print(
        "[V8V-OOO3-EVIDENCE][PASS] memory_ordering "
        f"design_id=sha256:{source_sha} metrics={len(metrics)} "
        f"mutations={mutation_payload['passed_count']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        print(f"[V8V-OOO3-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        raise SystemExit(1)
