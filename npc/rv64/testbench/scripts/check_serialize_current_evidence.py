#!/usr/bin/env python3
"""校验 SERIALIZE-G1 当前快门禁，并给出完整系统重认证边界。"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Sequence

import run_v12c_serialize_qh_current as common
import run_v12c_serialize_system_current as system_runner


SCHEMA = "npc-rv64-serialize-currentness-decision-v1"
QH_SCHEMA = "npc-rv64-v12c-serialize-qh-current-evidence-v1"
SYSTEM_SCHEMA = "npc-rv64-v12c-serialize-system-current-evidence-v1"
FUNCTIONAL_REPLAY_SCHEMA = "npc-rv64-full-core-functional-checker-replay-v1"
FUNCTIONAL_CURRENT_SCHEMA = "npc-rv64-full-core-functional-current-evidence-v1"
A3_REPLAY_SCHEMA = "npc-rv64-a3-checker-replay/v2"
A3_STATUS_TEXT = (
    "FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0"
)


class DecisionError(RuntimeError):
    """输入证据不能支持当前性边界。"""


def load_object(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise DecisionError(f"top-level JSON object required: {path}")
    return value


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DecisionError(message)


def profile_map(summary: dict[str, Any]) -> dict[str, dict[str, Any]]:
    profiles = summary.get("profiles")
    require(isinstance(profiles, list), "profiles must be a list")
    result: dict[str, dict[str, Any]] = {}
    for profile in profiles:
        require(isinstance(profile, dict), "profile must be an object")
        name = profile.get("name")
        require(isinstance(name, str) and name, "profile name is missing")
        require(name not in result, f"duplicate profile: {name}")
        result[name] = profile
    return result


def validate_live_artifact(
    root: Path, record: Any, *, label: str
) -> Path:
    require(isinstance(record, dict), f"artifact record is not an object: {label}")
    relative = record.get("path")
    digest = record.get("sha256")
    size = record.get("size_bytes")
    require(
        isinstance(relative, str)
        and isinstance(digest, str)
        and len(digest) == 64
        and isinstance(size, int),
        f"artifact receipt fields drifted: {label}",
    )
    path = (root / relative).resolve()
    path.relative_to(root.resolve())
    require(path.is_file(), f"retained artifact is missing: {label}")
    require(common.sha256_file(path) == digest, f"artifact hash drifted: {label}")
    require(path.stat().st_size == size, f"artifact size drifted: {label}")
    return path


def validate_physical_receipts(
    root: Path, summary_path: Path, summary: dict[str, Any]
) -> None:
    evidence_dir = summary_path.resolve().parent
    evidence_dir.relative_to(root.resolve())
    cleanup = summary.get("cleanup")
    require(isinstance(cleanup, dict), "cleanup receipt is missing")
    cleanup_copy_path = evidence_dir / "artifact-cleanup.json"
    require(cleanup_copy_path.is_file(), "artifact-cleanup.json is missing")
    require(
        load_object(cleanup_copy_path) == cleanup,
        "summary cleanup differs from artifact-cleanup.json",
    )

    profiles = profile_map(summary)
    cleanup_artifacts = cleanup.get("artifacts")
    require(isinstance(cleanup_artifacts, list), "cleanup artifacts must be a list")
    removed_paths: dict[str, dict[str, Any]] = {}
    recomputed_kinds: dict[str, int] = {}
    for index, artifact in enumerate(cleanup_artifacts):
        require(isinstance(artifact, dict), f"cleanup artifact {index} is malformed")
        relative = artifact.get("path")
        kind = artifact.get("kind")
        require(
            isinstance(relative, str)
            and isinstance(kind, str)
            and isinstance(artifact.get("sha256"), str)
            and len(artifact["sha256"]) == 64
            and isinstance(artifact.get("size_bytes"), int),
            f"cleanup artifact fields drifted: {index}",
        )
        require(relative not in removed_paths, f"duplicate cleanup path: {relative}")
        path = (root / relative).resolve()
        path.relative_to(evidence_dir)
        require(not path.exists(), f"temporary artifact still exists: {relative}")
        removed_paths[relative] = artifact
        recomputed_kinds[kind] = recomputed_kinds.get(kind, 0) + 1
    require(
        cleanup.get("removed") == len(cleanup_artifacts),
        "cleanup removed count drifted",
    )
    require(
        cleanup.get("kind_counts") == dict(sorted(recomputed_kinds.items())),
        "cleanup kind counts drifted",
    )

    for name, profile in profiles.items():
        validate_live_artifact(root, profile.get("result_log"), label=f"{name}.result")
        validate_live_artifact(root, profile.get("make_log"), label=f"{name}.make")
        compile_input = profile.get("compile_input")
        require(isinstance(compile_input, dict), f"compile input missing: {name}")
        make_argv = compile_input.get("make_compile_argv")
        compiler_argv = compile_input.get("compiler_argv")
        dependencies = compile_input.get("dependencies")
        require(
            isinstance(make_argv, list)
            and len(make_argv) > 4
            and isinstance(compiler_argv, list)
            and len(compiler_argv) > 5
            and isinstance(dependencies, list)
            and bool(dependencies),
            f"compiler argv/dependency receipt drifted: {name}",
        )
        dependency_keys: set[tuple[str, str]] = set()
        for dependency in dependencies:
            require(isinstance(dependency, dict), f"dependency malformed: {name}")
            key = (str(dependency.get("role")), str(dependency.get("path")))
            require(
                key[0] in {"module", "include"}
                and isinstance(dependency.get("sha256"), str)
                and len(dependency["sha256"]) == 64
                and isinstance(dependency.get("size_bytes"), int),
                f"dependency fields drifted: {name}: {key}",
            )
            require(key not in dependency_keys, f"duplicate dependency: {name}: {key}")
            dependency_keys.add(key)
        for field in (
            "compiler_argv_file",
            "dependency_file",
            "compile_returncode_file",
        ):
            receipt = compile_input.get(field)
            require(isinstance(receipt, dict), f"compile receipt missing: {name}.{field}")
            relative = receipt.get("path")
            require(
                isinstance(relative, str)
                and relative in removed_paths
                and all(
                    receipt.get(key) == removed_paths[relative].get(key)
                    for key in ("path", "sha256", "size_bytes")
                ),
                f"compile receipt is not bound to cleanup: {name}.{field}",
            )

    for pattern in ("*.vvp", "*.deps", "*.argv", "*.compile.rc"):
        require(
            not any(evidence_dir.rglob(pattern)),
            f"temporary artifact pattern remains: {pattern}",
        )
    require(
        not (evidence_dir / "generated").exists(),
        "generated mutation directory remains",
    )


def validate_common_current_summary(
    summary: dict[str, Any], *, schema: str, design_id: str
) -> None:
    require(summary.get("schema") == schema, f"schema drifted: {schema}")
    require(summary.get("status") == "PASS", f"evidence is not PASS: {schema}")
    require(summary.get("design_id") == design_id, f"design ID drifted: {schema}")
    product = summary.get("product_configuration")
    require(
        isinstance(product, dict)
        and product.get("OOO_CSR_QUEUE_HEAD") == 1
        and product.get("command_line_override") is False,
        f"queue-head product binding drifted: {schema}",
    )
    closure = summary.get("compile_input_closure")
    require(
        isinstance(closure, dict)
        and closure.get("status") == "PASS"
        and closure.get("actual_compiler_argv_bound") is True
        and closure.get("icarus_dependency_bound") is True,
        f"compiler input closure drifted: {schema}",
    )
    cleanup = summary.get("cleanup")
    require(
        isinstance(cleanup, dict)
        and cleanup.get("status") == "PASS"
        and cleanup.get("retained_temporary_artifacts") == 0,
        f"temporary artifact cleanup drifted: {schema}",
    )


def validate_queue_head(summary: dict[str, Any], design_id: str) -> None:
    validate_common_current_summary(summary, schema=QH_SCHEMA, design_id=design_id)
    require(
        summary.get("counts") == {
            "committed_transactions": 6,
            "compilations": 5,
            "compile_success_mutations": 3,
            "positive_profiles": 2,
            "selectively_killed_transactions": 4,
        },
        "queue-head transaction counts drifted",
    )
    profiles = profile_map(summary)
    require(
        set(profiles) == {
            "assert",
            "release",
            "mutation-typed-apply-c2-replay",
            "mutation-csrfile-request-c2-replay",
            "mutation-rob-queue-head-selection-disabled",
        },
        "queue-head profile set drifted",
    )
    for name in ("assert", "release"):
        profile = profiles[name]
        require(
            profile.get("make_returncode") == 0
            and profile.get("expect_pass") is True
            and profile.get("markers")
            == {"committed": 3, "selectively_killed": 2},
            f"queue-head positive profile drifted: {name}",
        )
    for name in (
        "mutation-typed-apply-c2-replay",
        "mutation-csrfile-request-c2-replay",
        "mutation-rob-queue-head-selection-disabled",
    ):
        profile = profiles[name]
        require(
            profile.get("make_returncode") != 0
            and profile.get("expect_pass") is False
            and isinstance(profile.get("markers"), dict)
            and bool(profile["markers"])
            and all(int(value) >= 1 for value in profile["markers"].values()),
            f"queue-head C2 negative profile drifted: {name}",
        )
    required_production = {
        "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    }
    for name, profile in profiles.items():
        compile_input = profile.get("compile_input", {})
        dependencies = compile_input.get("dependencies", [])
        module_paths = {
            item.get("path")
            for item in dependencies
            if isinstance(item, dict) and item.get("role") == "module"
        }
        require(
            required_production <= module_paths,
            f"queue-head production dependency closure drifted: {name}",
        )
        require(
            len(
                [path for path in module_paths if str(path).endswith("/OooRob.v")]
            ) == 1,
            f"queue-head ROB dependency is not unique: {name}",
        )
        require(
            not any(
                str(token).startswith("-DOOO_CSR_QUEUE_HEAD")
                for token in compile_input.get("compiler_argv", [])
            ),
            f"queue-head product default override appeared: {name}",
        )
    mutations = summary.get("mutations")
    require(isinstance(mutations, dict), "queue-head mutation receipts drifted")
    mutation_profiles = {
        "typed-apply-c2-replay": "mutation-typed-apply-c2-replay",
        "csrfile-request-c2-replay": "mutation-csrfile-request-c2-replay",
        "rob-queue-head-selection-disabled":
            "mutation-rob-queue-head-selection-disabled",
    }
    mutation_suffixes = {
        "typed-apply-c2-replay": "/OooControlEventApplySequencer.v",
        "csrfile-request-c2-replay": "/tb_ooo_core_top_glue_csr.svh",
        "rob-queue-head-selection-disabled": "/OooRob.v",
    }
    for mutation_name, profile_name in mutation_profiles.items():
        mutation = mutations.get(mutation_name)
        require(isinstance(mutation, dict), f"queue-head mutation missing: {mutation_name}")
        mutated = mutation.get("mutated")
        require(isinstance(mutated, dict), f"mutated artifact missing: {mutation_name}")
        require(
            str(mutated.get("path", "")).endswith(mutation_suffixes[mutation_name]),
            f"queue-head mutation class drifted: {mutation_name}",
        )
        matching = [
            item
            for item in profiles[profile_name]["compile_input"]["dependencies"]
            if item.get("path") == mutated.get("path")
            and item.get("sha256") == mutated.get("sha256")
        ]
        require(
            len(matching) == 1,
            f"queue-head mutation dependency is not exact: {mutation_name}",
        )


def validate_system(summary: dict[str, Any], design_id: str) -> None:
    validate_common_current_summary(
        summary, schema=SYSTEM_SCHEMA, design_id=design_id
    )
    require(
        summary.get("counts") == {
            "baseline_profiles": 3,
            "compilations": 18,
            "compile_success_mutations": 15,
            "dynamically_rejected_mutations": 15,
        },
        "pending-SYSTEM matrix counts drifted",
    )
    closure = summary["compile_input_closure"]
    require(
        closure.get("mutation_source_selection_bound") is True
        and closure.get("product_queue_head_command_override") is False,
        "pending-SYSTEM mutation/product binding drifted",
    )
    profiles = profile_map(summary)
    baseline_names = {
        "priv-system-assert",
        "priv-system-release",
        "csr-access-assert",
    }
    mutation_names = {mutation.name for mutation in system_runner.MUTATIONS}
    require(
        set(profiles) == baseline_names | mutation_names,
        "pending-SYSTEM profile set drifted",
    )
    for name in baseline_names:
        require(
            profiles[name].get("make_returncode") == 0
            and profiles[name].get("expect_pass") is True,
            f"pending-SYSTEM baseline drifted: {name}",
        )
    for mutation in system_runner.MUTATIONS:
        profile = profiles[mutation.name]
        markers = profile.get("markers")
        require(
            profile.get("make_returncode") != 0
            and profile.get("expect_pass") is False
            and profile.get("mutation") == mutation.name
            and isinstance(markers, dict)
            and int(markers.get(mutation.rejection_marker, 0)) >= 1,
            f"pending-SYSTEM negative profile drifted: {mutation.name}",
        )
        require(
            not any(
                str(token).startswith("-DOOO_CSR_QUEUE_HEAD")
                for token in profile["compile_input"]["compiler_argv"]
            ),
            f"pending-SYSTEM product default override appeared: {mutation.name}",
        )
    mutation_receipts = summary.get("mutations")
    require(isinstance(mutation_receipts, list), "SYSTEM mutation receipts drifted")
    receipt_map = {
        item.get("name"): item
        for item in mutation_receipts
        if isinstance(item, dict) and isinstance(item.get("name"), str)
    }
    require(set(receipt_map) == mutation_names, "SYSTEM mutation receipt set drifted")
    for mutation in system_runner.MUTATIONS:
        mutated = receipt_map[mutation.name].get("mutated")
        require(isinstance(mutated, dict), f"SYSTEM mutated artifact missing: {mutation.name}")
        matching = [
            item
            for item in profiles[mutation.name]["compile_input"]["dependencies"]
            if item.get("role") == "module"
            and item.get("path") == mutated.get("path")
            and item.get("sha256") == mutated.get("sha256")
        ]
        require(
            len(matching) == 1,
            f"SYSTEM mutation dependency is not exact: {mutation.name}",
        )


FUNCTIONAL_COUNTS = {
    "am_passed": 61,
    "am_required": 61,
    "difftest_mismatches": 0,
    "evidence_mutations_compiled": 11,
    "evidence_mutations_rejected": 11,
    "module_passed": 113,
    "module_required": 113,
    "official_passed": 177,
    "official_required": 177,
}


def validate_functional(
    summary: dict[str, Any],
    design_id: str,
    *,
    root: Path | None = None,
    summary_path: Path | None = None,
) -> None:
    schema = summary.get("schema")
    require(
        schema in {FUNCTIONAL_REPLAY_SCHEMA, FUNCTIONAL_CURRENT_SCHEMA},
        "functional schema drifted",
    )
    require(summary.get("status") == "PASS", "functional evidence is not PASS")
    require(summary.get("design_id") == design_id, "functional design ID drifted")
    require(
        summary.get("counts") == FUNCTIONAL_COUNTS,
        "functional current cohort counts drifted",
    )
    if schema == FUNCTIONAL_REPLAY_SCHEMA:
        return

    require(root is not None and summary_path is not None, "direct functional path missing")
    inputs = summary.get("inputs")
    require(
        isinstance(inputs, dict)
        and inputs.get("unchanged") is True
        and summary.get("inputs_unchanged") is True,
        "direct functional input binding drifted",
    )
    pre = inputs.get("pre")
    post = inputs.get("post")
    validate_live_artifact(root, pre, label="functional.inputs.pre")
    validate_live_artifact(root, post, label="functional.inputs.post")
    require(
        isinstance(pre, dict)
        and isinstance(post, dict)
        and pre.get("sha256") == post.get("sha256")
        and pre.get("size_bytes") == post.get("size_bytes"),
        "direct functional pre/post inputs differ",
    )

    validate_live_artifact(
        root, summary.get("module_result"), label="functional.module_result"
    )
    artifacts = summary.get("artifacts")
    require(isinstance(artifacts, dict), "direct functional artifacts missing")
    artifact_paths = {
        label: validate_live_artifact(
            root, artifacts.get(label), label=f"functional.{label}"
        )
        for label in (
            "aggregate",
            "aggregate_result",
            "aggregate_log",
            "simulator",
            "reference",
            "configuration",
        )
    }
    aggregate = load_object(artifact_paths["aggregate"])
    aggregate_result = load_object(artifact_paths["aggregate_result"])
    require(
        aggregate.get("schema") == "npc-rv64-functional-aggregate-v2"
        and aggregate.get("design_id") == design_id,
        "direct functional aggregate binding drifted",
    )
    require(
        aggregate_result.get("status") == "PASS"
        and aggregate_result.get("exit_code") == 0
        and aggregate_result.get("design_id") == design_id
        and aggregate_result.get("counts") == FUNCTIONAL_COUNTS,
        "direct functional aggregate result drifted",
    )
    benchmarks = aggregate.get("benchmarks")
    require(isinstance(benchmarks, dict), "direct functional benchmarks missing")
    coremark = benchmarks.get("coremark")
    dhrystone = benchmarks.get("dhrystone")
    require(
        isinstance(coremark, dict)
        and coremark.get("return_code") == 0
        and coremark.get("iterations") == 10
        and coremark.get("crc") == "0xfcaf"
        and coremark.get("good_traps") == 1,
        "CoreMark terminal semantics drifted",
    )
    require(
        isinstance(dhrystone, dict)
        and dhrystone.get("return_code") == 0
        and dhrystone.get("runs") == 10000
        and dhrystone.get("good_traps") == 1,
        "Dhrystone terminal semantics drifted",
    )
    difftest = aggregate.get("difftest")
    require(
        isinstance(difftest, dict)
        and difftest.get("applicable") is True
        and difftest.get("mismatches") == 0,
        "direct functional DiffTest semantics drifted",
    )
    require(
        summary.get("retention")
        == {
            "compiled_intermediates_retained": 0,
            "frozen_reference_retained": 1,
            "frozen_simulator_retained": 1,
            "module_simulation_reused": True,
            "program_images_retained": 240,
        },
        "direct functional retention boundary drifted",
    )
    require(summary.get("published_current") is False, "unexpected current publish")
    evidence_dir = summary_path.resolve().parent
    evidence_dir.relative_to(root.resolve())
    require(
        not any(evidence_dir.rglob("*.vvp")) and not any(evidence_dir.rglob("*.o")),
        "compiled functional intermediate remains",
    )


def parse_binding(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        key, separator, value = line.partition("=")
        if separator and key and key not in values:
            values[key] = value
    return values


def validate_a3(
    *,
    status_path: Path,
    binding_path: Path,
    transaction: dict[str, Any],
    replay: dict[str, Any],
) -> str:
    require(
        status_path.read_text(encoding="utf-8").strip() == A3_STATUS_TEXT,
        "A3 original FAIL status drifted",
    )
    binding = parse_binding(binding_path)
    a3_design_id = binding.get("rtl_design_id")
    require(
        isinstance(a3_design_id, str) and a3_design_id.startswith("sha256:"),
        "A3 RTL design ID is missing",
    )
    require(transaction.get("status") == "FAIL", "A3 raw transaction was rewritten")
    stages = transaction.get("stages")
    require(isinstance(stages, list) and len(stages) == 3, "A3 stage set drifted")
    strict = next(
        (stage for stage in stages if isinstance(stage, dict) and stage.get("name") == "strict"),
        None,
    )
    require(
        isinstance(strict, dict)
        and strict.get("status") == "FAIL"
        and strict.get("pass_observation_count") == 16
        and strict.get("done_rc") == 1,
        "A3 historical strict 16/17 state drifted",
    )
    require(replay.get("schema") == A3_REPLAY_SCHEMA, "A3 replay schema drifted")
    require(replay.get("status") == "PASS", "A3 checker replay is not PASS")
    base = replay.get("base_replay")
    require(isinstance(base, dict), "A3 base replay is missing")
    replay_binding = base.get("binding")
    require(
        isinstance(replay_binding, dict)
        and replay_binding.get("design_id_pre") == a3_design_id
        and replay_binding.get("design_id_post") == a3_design_id,
        "A3 replay design binding drifted",
    )
    system_transaction = base.get("system_transaction")
    terminal_counts = (
        system_transaction.get("terminal_counts")
        if isinstance(system_transaction, dict) else None
    )
    require(
        isinstance(system_transaction, dict)
        and system_transaction.get("classification")
        == "COMPLETE_WITH_LEGACY_ORACLE_FALSE_POSITIVE"
        and system_transaction.get("rtl_assertion_file_empty") is True
        and system_transaction.get("strict_historical_pass_count") == 16
        and system_transaction.get("strict_expected_pass_count") == 17
        and isinstance(terminal_counts, dict)
        and set(terminal_counts.values()) == {1},
        "A3 complete transaction/checker classification drifted",
    )
    marker = base.get("marker")
    require(
        isinstance(marker, str)
        and "cycles=5071521696" in marker
        and "commits=1223536213" in marker
        and marker.endswith(" PASS"),
        "A3 cycle/commit replay marker drifted",
    )
    return a3_design_id


def build_decision(
    *,
    root: Path,
    queue_head_path: Path,
    system_path: Path,
    functional_path: Path,
    a3_status_path: Path,
    a3_binding_path: Path,
    a3_transaction_path: Path,
    a3_replay_path: Path,
) -> dict[str, Any]:
    design_id = common.current_design_id(root)
    queue_head = load_object(queue_head_path)
    system = load_object(system_path)
    functional = load_object(functional_path)
    a3_transaction = load_object(a3_transaction_path)
    a3_replay = load_object(a3_replay_path)
    validate_queue_head(queue_head, design_id)
    validate_system(system, design_id)
    validate_functional(
        functional,
        design_id,
        root=root,
        summary_path=functional_path,
    )
    validate_physical_receipts(root, queue_head_path, queue_head)
    validate_physical_receipts(root, system_path, system)
    a3_design_id = validate_a3(
        status_path=a3_status_path,
        binding_path=a3_binding_path,
        transaction=a3_transaction,
        replay=a3_replay,
    )
    require(
        a3_design_id != design_id,
        "A3 design matches current design; rerun boundary requires re-evaluation",
    )
    artifacts = {
        "queue_head_current": common.artifact_record(queue_head_path, root),
        "pending_system_current": common.artifact_record(system_path, root),
        "functional_current": common.artifact_record(functional_path, root),
        "a3_original_status": common.artifact_record(a3_status_path, root),
        "a3_binding": common.artifact_record(a3_binding_path, root),
        "a3_raw_transaction": common.artifact_record(a3_transaction_path, root),
        "a3_checker_replay": common.artifact_record(a3_replay_path, root),
    }
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "debt_id": "SERIALIZE-G1",
        "ledger_status": "STALE_EVIDENCE",
        "current_design_id": design_id,
        "previous_full_system_design_id": a3_design_id,
        "fast_gates": {
            "status": "PASS",
            "current_design_bound": True,
            "queue_head": (
                "2/2 positive + 2/2 production RTL negatives + "
                "1/1 verification-only TB-wiring negative"
            ),
            "pending_system": "3/3 baseline + 15/15 compile-success negatives",
            "functional": "module 113/113; official 177/177; AM 61/61; mismatch=0",
        },
        "full_system_recertification": {
            "required": True,
            "reason": "production RTL design binding changed since A3",
            "a3_original_fail_preserved": True,
            "a3_execution_complete": True,
            "a3_legacy_oracle_false_positive": True,
            "current_design_system_transaction_present": False,
        },
        "architecture_boundary": {
            "serialize_g1_current_design_bound": False,
            "architecture_freeze": "GAP",
            "ppa": "UNPROMOTED",
            "promotion_eligible": False,
            "raw_terminal_events_counted": True,
            "deduplication_mask": False,
            "rtl_assertions_weakened": False,
        },
        "evidence": artifacts,
    }


def validate_ledger_boundary(
    *,
    root: Path,
    ledger_path: Path,
    decision_path: Path,
    queue_head_path: Path,
    system_path: Path,
    decision: dict[str, Any],
) -> None:
    ledger = load_object(ledger_path)
    debts = ledger.get("entries")
    require(isinstance(debts, list), "architecture debt list is missing")
    entries = [
        item for item in debts
        if isinstance(item, dict) and item.get("id") == "SERIALIZE-G1"
    ]
    require(len(entries) == 1, "SERIALIZE-G1 ledger entry is not unique")
    entry = entries[0]
    require(entry.get("status") == "STALE_EVIDENCE", "ledger status drifted")
    require(
        entry.get("current_design_bound") is False,
        "ledger current_design_bound must remain false",
    )
    require(
        entry.get("design_id") == decision.get("current_design_id"),
        "ledger current design ID drifted",
    )
    command = entry.get("canonical_command")
    required_command_tokens = (
        "npc/rv64/testbench/scripts/check_serialize_current_evidence.py",
        common.repo_path(queue_head_path, root),
        common.repo_path(system_path, root),
        common.repo_path(decision_path, root),
    )
    require(
        isinstance(command, str)
        and all(token in command for token in required_command_tokens),
        "SERIALIZE-G1 canonical command drifted",
    )
    serialized = (
        json.dumps(decision, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")
    expected_evidence = [
        {
            "kind": "serialize_currentness_decision",
            "path": common.repo_path(decision_path, root),
            "sha256": common.sha256_bytes(serialized),
        },
        {
            "kind": "queue_head_current_evidence",
            "path": common.repo_path(queue_head_path, root),
            "sha256": common.sha256_file(queue_head_path),
        },
        {
            "kind": "pending_system_current_evidence",
            "path": common.repo_path(system_path, root),
            "sha256": common.sha256_file(system_path),
        },
    ]
    require(
        entry.get("evidence") == expected_evidence,
        "SERIALIZE-G1 ledger evidence tuple drifted",
    )


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--queue-head", type=Path, required=True)
    parser.add_argument("--system", type=Path, required=True)
    parser.add_argument("--functional", type=Path, required=True)
    parser.add_argument("--a3-status", type=Path, required=True)
    parser.add_argument("--a3-binding", type=Path, required=True)
    parser.add_argument("--a3-transaction", type=Path, required=True)
    parser.add_argument("--a3-replay", type=Path, required=True)
    parser.add_argument(
        "--ledger",
        type=Path,
        default=Path("npc/rv64/design/arch/architecture-debt-ledger.json"),
    )
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def resolve_in_root(root: Path, path: Path) -> Path:
    resolved = path.resolve() if path.is_absolute() else (root / path).resolve()
    resolved.relative_to(root)
    return resolved


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    root = args.repo_root.resolve()
    output = resolve_in_root(root, args.output)
    try:
        queue_head_path = resolve_in_root(root, args.queue_head)
        system_path = resolve_in_root(root, args.system)
        decision = build_decision(
            root=root,
            queue_head_path=queue_head_path,
            system_path=system_path,
            functional_path=resolve_in_root(root, args.functional),
            a3_status_path=resolve_in_root(root, args.a3_status),
            a3_binding_path=resolve_in_root(root, args.a3_binding),
            a3_transaction_path=resolve_in_root(root, args.a3_transaction),
            a3_replay_path=resolve_in_root(root, args.a3_replay),
        )
        validate_ledger_boundary(
            root=root,
            ledger_path=resolve_in_root(root, args.ledger),
            decision_path=output,
            queue_head_path=queue_head_path,
            system_path=system_path,
            decision=decision,
        )
    except Exception as exc:
        common.atomic_write_json(
            output.with_suffix(output.suffix + ".failure.json"),
            {"schema": SCHEMA, "status": "FAIL", "error": str(exc)},
        )
        print(f"[SERIALIZE-CURRENTNESS][FAIL] {exc}", file=sys.stderr)
        return 1
    common.atomic_write_json(output, decision)
    output.with_name("currentness-result.txt").write_text(
        "[SERIALIZE-CURRENTNESS] "
        f"design_id={decision['current_design_id']} fast_gates=PASS "
        "full_system=RECERT_REQUIRED ledger=STALE_EVIDENCE "
        "arch_stable=GAP ppa=UNPROMOTED PASS\n",
        encoding="utf-8",
    )
    print(
        "[SERIALIZE-CURRENTNESS] "
        f"design_id={decision['current_design_id']} fast_gates=PASS "
        "full_system=RECERT_REQUIRED ledger=STALE_EVIDENCE "
        "arch_stable=GAP ppa=UNPROMOTED PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
