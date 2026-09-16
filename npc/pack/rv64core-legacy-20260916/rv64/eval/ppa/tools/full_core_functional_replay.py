#!/usr/bin/env python3
"""Replay a completed RV64 functional cohort rejected only by an input oracle.

The original attempt remains immutable.  This tool accepts only the exact
failure boundary produced after every execution phase passed, removes verified
build products from the recorded input manifests, revalidates every frozen
log/image pair, and emits an independent aggregate and replay receipt.
"""

from __future__ import annotations

import argparse
import copy
import pathlib
import re
import shutil
import sys
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS_DIR = ROOT / "npc/rv64/eval/ppa/tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import full_core_current_evidence as module_evidence  # noqa: E402
import full_core_functional_evidence as current  # noqa: E402


SCHEMA = "npc-rv64-full-core-functional-checker-replay-v1"
INPUT_REPLAY_SCHEMA = "npc-rv64-full-core-functional-input-replay-v1"
EXPECTED_FAILURE = "RTL/config/test/workflow inputs drifted during functional run"
BENCHMARK_ORACLE_FAILURE_RE = re.compile(
    r"^benchmark:(coremark|dhrystone): guest result markers drifted: "
    r"missing=\[\] duplicate=\[\] contradictory_values=\[\] "
    r"contradictory=\[\] good_traps=0$"
)
BENCHMARK_CHECKER_PATH = "npc/rv64/eval/ppa/tools/functional_aggregate.py"
BENCHMARK_REPLAY_SCHEMA = (
    "npc-rv64-full-core-functional-benchmark-oracle-replay-v1"
)
CONFIG_BINDING_PATHS = (
    "npc/rv64/configs/default_defconfig",
    "npc/rv64/include/config/auto.conf",
    "npc/rv64/include/generated/autoconf.h",
)


def resolve_repo_dir(raw: pathlib.Path) -> pathlib.Path:
    candidate = raw if raw.is_absolute() else ROOT / raw
    if candidate.is_symlink():
        raise RuntimeError(f"repository directory is a symlink: {raw}")
    resolved = candidate.resolve(strict=True)
    resolved.relative_to(ROOT.resolve())
    if not resolved.is_dir():
        raise RuntimeError(f"repository directory is not regular: {raw}")
    return resolved


def relative_repo_dir(path: pathlib.Path) -> str:
    if path.is_symlink():
        raise RuntimeError(f"repository directory is a symlink: {path}")
    resolved = path.resolve(strict=True)
    if not resolved.is_dir():
        raise RuntimeError(f"repository directory is not regular: {path}")
    return resolved.relative_to(ROOT.resolve()).as_posix()


def binding_hash(binding: dict[str, Any], relative_path: str) -> str:
    groups = binding.get("groups")
    if not isinstance(groups, dict):
        raise RuntimeError("functional input binding has no groups")
    matches = [
        records[relative_path]
        for records in groups.values()
        if isinstance(records, dict) and relative_path in records
    ]
    if len(matches) != 1 or not isinstance(matches[0], str):
        raise RuntimeError(f"input binding is missing unique path: {relative_path}")
    return matches[0]


def binding_changes(
    before: dict[str, Any], after: dict[str, Any]
) -> list[tuple[str, str]]:
    changed: list[tuple[str, str]] = []
    before_groups = before.get("groups", {})
    after_groups = after.get("groups", {})
    if not isinstance(before_groups, dict) or not isinstance(after_groups, dict):
        raise RuntimeError("functional input groups are malformed")
    for group in sorted(set(before_groups) | set(after_groups)):
        lhs = before_groups.get(group, {})
        rhs = after_groups.get(group, {})
        if not isinstance(lhs, dict) or not isinstance(rhs, dict):
            changed.append((group, "<group-shape>"))
            continue
        for path in sorted(set(lhs) | set(rhs)):
            if lhs.get(path) != rhs.get(path):
                changed.append((group, path))
    return changed


def official_build_outputs(
    legacy: Any, official_test_ids: list[str]
) -> set[tuple[str, str]]:
    """Return the only source-tree build products this replay may exclude."""
    official_root = pathlib.PurePosixPath(
        module_evidence.relative(legacy.OFFICIAL_TREE / "isa")
    )
    return {
        ("official_program_sources", (official_root / name).as_posix())
        for test_id in official_test_ids
        for name in (test_id, f"{test_id}.dump")
    }


def filter_generated_inputs(
    binding: dict[str, Any], known_outputs: set[tuple[str, str]]
) -> tuple[dict[str, Any], list[tuple[str, str]]]:
    """Exclude only exact official outputs, without inspecting mutable files."""
    filtered = copy.deepcopy(binding)
    removed: list[tuple[str, str]] = []
    groups = filtered.get("groups")
    if not isinstance(groups, dict):
        raise RuntimeError("functional input binding has no groups")
    for group, records in groups.items():
        if not isinstance(records, dict):
            raise RuntimeError(f"functional input group is malformed: {group}")
        for relative_path in list(records):
            entry = (str(group), relative_path)
            if entry in known_outputs:
                del records[relative_path]
                removed.append(entry)
    return filtered, sorted(removed)


def phase_command(log_path: pathlib.Path) -> str:
    if log_path.is_symlink() or not log_path.is_file():
        raise RuntimeError(f"phase log is missing: {log_path}")
    command = ""
    return_code = None
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("command="):
            command = line.removeprefix("command=")
        elif line.startswith("phase_return_code="):
            return_code = line.removeprefix("phase_return_code=")
    if not command or return_code != "0":
        raise RuntimeError(f"phase log is not PASS-complete: {log_path}")
    return command


def paired_records(
    attempt_dir: pathlib.Path,
    category: str,
    expected: list[str],
) -> list[dict[str, Any]]:
    log_dir = attempt_dir / "raw" / category
    image_dir = attempt_dir / "images" / category
    logs = {path.stem: path for path in log_dir.glob("*.log")}
    images = {path.stem: path for path in image_dir.glob("*.bin")}
    required = set(expected)
    if set(logs) != required or set(images) != required:
        raise RuntimeError(
            f"{category} frozen inventory mismatch: "
            f"logs={len(logs)} images={len(images)} expected={len(required)}"
        )
    return [
        {
            "test_id": test_id,
            "return_code": 0,
            "image": module_evidence.relative(images[test_id]),
            "raw_log": module_evidence.relative(logs[test_id]),
        }
        for test_id in sorted(required)
    ]


def official_ids(attempt_dir: pathlib.Path) -> list[str]:
    status_path = attempt_dir / "raw/official-status.txt"
    if status_path.is_symlink() or not status_path.is_file():
        raise RuntimeError("official status evidence is missing")
    status = status_path.read_text(encoding="utf-8", errors="replace")
    if "177 tests attempted" not in status:
        raise RuntimeError("official status does not report 177 attempted tests")
    image_ids = sorted(path.stem for path in (attempt_dir / "images/official").glob("*.bin"))
    if len(image_ids) != 177:
        raise RuntimeError(f"official frozen image count is {len(image_ids)}, expected 177")
    for test_id in image_ids:
        if not re.search(rf"(?m)^{re.escape(test_id)}\s+PASS(?:\s|$)", status):
            raise RuntimeError(f"official status does not report PASS for {test_id}")
    return image_ids


def copy_regular(source: pathlib.Path, destination: pathlib.Path) -> None:
    if source.is_symlink() or not source.is_file():
        raise RuntimeError(f"replay source is not a regular file: {source}")
    resolved = source.resolve(strict=True)
    if not resolved.is_file():
        raise RuntimeError(f"replay source is not a regular file: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(resolved, destination)


def replay(
    *,
    attempt_raw: pathlib.Path,
    module_result_raw: pathlib.Path,
    output_raw: pathlib.Path,
    publish_current: bool,
) -> int:
    attempt_dir = resolve_repo_dir(attempt_raw)
    output_dir = module_evidence.safe_output_dir(output_raw)
    output_dir.mkdir(parents=True)
    stage = "original-attempt"
    design_hex, _ = architecture.rtl_binding(ROOT)
    design_id = f"sha256:{design_hex}"
    try:
        original_status_path = attempt_dir / "status.json"
        original_status = current.load_json(original_status_path)
        source_detail = original_status.get("detail")
        benchmark_failure = (
            BENCHMARK_ORACLE_FAILURE_RE.fullmatch(source_detail)
            if isinstance(source_detail, str)
            else None
        )
        if (
            original_status.get("state") != "FAIL"
            or (
                source_detail != EXPECTED_FAILURE
                and benchmark_failure is None
            )
            or original_status.get("design_id") != design_id
        ):
            raise RuntimeError("source attempt is not the exact input-oracle FAIL boundary")

        stage = "module-result"
        module_result_path = current.resolve_repo_file(module_result_raw)
        expected_module_result = (attempt_dir.parent / "module/result.json").resolve(
            strict=True
        )
        if module_result_path != expected_module_result:
            raise RuntimeError("module result is not owned by the source full-core run")
        module_command, module_records = current.validate_module_result(
            module_result_path, expected_design_id=design_id
        )

        if benchmark_failure is not None:
            if publish_current:
                raise RuntimeError(
                    "benchmark checker replay cannot publish an execution binding"
                )
            source_run = attempt_dir.parents[1]
            source_execution_status = source_run / "full-core-current.status"
            if (
                source_execution_status.is_symlink()
                or not source_execution_status.is_file()
                or re.fullmatch(
                    r"FAIL rc=[0-9]+ stage=evidence-complete "
                    r"evidence_complete=0 cleanup_rc=0\n",
                    source_execution_status.read_text(encoding="utf-8"),
                )
                is None
            ):
                raise RuntimeError("source full-core status is not the exact FAIL boundary")

            stage = "benchmark-checker-input-binding"
            pre_path = attempt_dir / "inputs.pre.json"
            post_path = attempt_dir / "inputs.post.json"
            before = current.load_json(pre_path)
            after = current.load_json(post_path)
            if before != after:
                raise RuntimeError("source functional inputs changed during execution")
            legacy = current.load_legacy_runner()
            live = current.capture_functional_inputs(
                legacy, module_evidence.required_tests()
            )
            if before.get("design_id") != design_id or live.get("design_id") != design_id:
                raise RuntimeError("benchmark replay RTL design identity drifted")
            live_changes = binding_changes(before, live)
            expected_checker_change = [("functional_workflow", BENCHMARK_CHECKER_PATH)]
            if live_changes != expected_checker_change:
                raise RuntimeError(
                    "benchmark replay has non-checker live input drift: "
                    f"{live_changes[:8]}"
                )
            old_checker_sha = binding_hash(before, BENCHMARK_CHECKER_PATH)
            new_checker_sha = binding_hash(live, BENCHMARK_CHECKER_PATH)
            if old_checker_sha == new_checker_sha:
                raise RuntimeError("benchmark checker did not change")
            input_replay_path = output_dir / "checker-input-replay.json"
            module_evidence.write_json(
                input_replay_path,
                {
                    "schema": BENCHMARK_REPLAY_SCHEMA,
                    "classification": "exact-benchmark-terminal-line-checker-change",
                    "source": {
                        "pre": module_evidence.artifact(
                            pre_path, kind="recorded_input_binding"
                        ),
                        "post": module_evidence.artifact(
                            post_path, kind="recorded_input_binding"
                        ),
                    },
                    "source_inputs_unchanged": True,
                    "live_changes": [
                        {
                            "group": "functional_workflow",
                            "path": BENCHMARK_CHECKER_PATH,
                            "old_sha256": old_checker_sha,
                            "new_sha256": new_checker_sha,
                        }
                    ],
                },
            )

            stage = "benchmark-descriptor-replay"
            descriptor_path = attempt_dir / "functional-run-descriptor.json"
            aggregate_path = output_dir / "functional-aggregate.json"
            aggregate_result_path = output_dir / "functional-aggregate-result.json"
            aggregate_log_path = output_dir / "functional-aggregate.log"
            assembled = legacy.functional.assemble(
                root=ROOT,
                descriptor_path=descriptor_path,
                wrapper_dir=output_dir / "wrapped",
                aggregate_path=aggregate_path,
                mutation_summary_path=output_dir / "mutations/summary.json",
                raw_log_path=aggregate_log_path,
                result_path=aggregate_result_path,
                check_current_design=True,
            )
            if assembled.get("status") != "PASS" or assembled.get("exit_code") != 0:
                raise RuntimeError("replayed functional aggregate is not PASS")

            stage = "benchmark-replay-receipt"
            receipt = {
                "schema": SCHEMA,
                "status": "PASS",
                "claim": "L1_FULL_CORE_DIFFTEST_PASS_CURRENT_IDENTITY",
                "signoff_scope": "full-l1-checker-replay",
                "design_id": design_id,
                "classification": (
                    "execution-complete-old-benchmark-terminal-oracle-false-positive"
                ),
                "source_attempt": relative_repo_dir(attempt_dir),
                "source_status": module_evidence.artifact(
                    original_status_path, kind="original_fail_status"
                ),
                "source_execution_status": module_evidence.artifact(
                    source_execution_status, kind="original_full_core_fail_status"
                ),
                "module_result": module_evidence.artifact(
                    module_result_path, kind="module_current_result"
                ),
                "checker_replay": module_evidence.artifact(
                    input_replay_path, kind="checker_input_replay"
                ),
                "counts": assembled["counts"],
                "artifacts": {
                    "descriptor": module_evidence.artifact(
                        descriptor_path, kind="functional_run_descriptor"
                    ),
                    "aggregate": module_evidence.artifact(
                        aggregate_path, kind="functional_aggregate"
                    ),
                    "aggregate_result": module_evidence.artifact(
                        aggregate_result_path, kind="functional_aggregate_result"
                    ),
                    "aggregate_log": module_evidence.artifact(
                        aggregate_log_path, kind="functional_aggregate_log"
                    ),
                    "simulator": module_evidence.artifact(
                        attempt_dir / "frozen/NpcSimTop", kind="simulator_binary"
                    ),
                    "reference": module_evidence.artifact(
                        attempt_dir / "frozen/riscv64-nemu-interpreter-so",
                        kind="reference_model_binary",
                    ),
                    "configuration": module_evidence.artifact(
                        attempt_dir / "frozen/npc.config", kind="kconfig"
                    ),
                },
                "source_inputs_unchanged": True,
                "live_drift_is_checker_only": True,
                "original_status_unchanged": True,
                "guest_rerun": False,
                "published_current": False,
            }
            module_evidence.write_json(output_dir / "replay-result.json", receipt)
            module_evidence.write_status(
                output_dir,
                state="PASS",
                stage="complete",
                detail=(
                    f"module={assembled['counts']['module_passed']}/"
                    f"{assembled['counts']['module_required']} official=177/177 "
                    f"am={assembled['counts']['am_passed']}/"
                    f"{assembled['counts']['am_required']} checker_drift=1"
                ),
                design_id=design_id,
            )
            print(
                "[FULL-CORE-FUNCTIONAL-REPLAY][PASS] "
                f"design_id={design_id} module="
                f"{assembled['counts']['module_passed']}/"
                f"{assembled['counts']['module_required']} official=177/177 "
                f"am={assembled['counts']['am_passed']}/"
                f"{assembled['counts']['am_required']} checker_drift=1 guest_rerun=0",
                flush=True,
            )
            return 0

        stage = "input-oracle-replay"
        pre_path = attempt_dir / "inputs.pre.json"
        post_path = attempt_dir / "inputs.post.json"
        before = current.load_json(pre_path)
        after = current.load_json(post_path)
        legacy = current.load_legacy_runner()
        frozen_official_ids = official_ids(attempt_dir)
        known_outputs = official_build_outputs(legacy, frozen_official_ids)
        original_changes = binding_changes(before, after)
        if not original_changes:
            raise RuntimeError("source attempt does not contain the reported input drift")
        filtered_before, removed_before = filter_generated_inputs(
            before, known_outputs)
        filtered_after, removed_after = filter_generated_inputs(
            after, known_outputs)
        if removed_before != removed_after:
            raise RuntimeError("generated input exclusion differs between pre/post manifests")
        if set(removed_before) != known_outputs:
            raise RuntimeError(
                "recorded official build-output inventory is incomplete: "
                f"expected={len(known_outputs)} observed={len(removed_before)}"
            )
        if filtered_before != filtered_after:
            remaining = binding_changes(filtered_before, filtered_after)
            raise RuntimeError(f"real functional inputs still drifted: {remaining[:8]}")
        removed_set = set(removed_before)
        if any(change not in removed_set for change in original_changes):
            raise RuntimeError("input replay would hide a non-generated changed path")
        input_replay_path = output_dir / "input-oracle-replay.json"
        module_evidence.write_json(
            input_replay_path,
            {
                "schema": INPUT_REPLAY_SCHEMA,
                "classification": "exact-official-build-output-exclusion",
                "source": {
                    "pre": module_evidence.artifact(
                        pre_path, kind="recorded_input_binding"),
                    "post": module_evidence.artifact(
                        post_path, kind="recorded_input_binding"),
                },
                "rule": {
                    "group": "official_program_sources",
                    "root": module_evidence.relative(legacy.OFFICIAL_TREE / "isa"),
                    "test_count": len(frozen_official_ids),
                    "outputs_per_test": ["<test-id>", "<test-id>.dump"],
                },
                "counts": {
                    "changed_entries_before": len(original_changes),
                    "known_generated_entries": len(known_outputs),
                    "changed_entries_after": 0,
                },
                "changed_entries": [
                    {
                        "group": group,
                        "path": path,
                        "classification": "official-extensionless-build-target",
                    }
                    for group, path in original_changes
                ],
            },
        )

        stage = "configuration-binding"
        configuration_bindings: list[dict[str, Any]] = []
        for relative_path in CONFIG_BINDING_PATHS:
            expected_hash = binding_hash(before, relative_path)
            if expected_hash != binding_hash(after, relative_path):
                raise RuntimeError(f"configuration binding drifted: {relative_path}")
            if module_evidence.sha256_file(ROOT / relative_path) != expected_hash:
                raise RuntimeError(f"current configuration binding changed: {relative_path}")
            configuration_bindings.append(
                module_evidence.artifact(
                    ROOT / relative_path, kind="recorded_configuration_binding")
            )
        live_config = ROOT / "npc/rv64/.config"
        if "CONFIG_NPC_DIFFTEST=y" not in live_config.read_text(encoding="utf-8"):
            raise RuntimeError("current reconstructed configuration lacks DiffTest")
        frozen_config = output_dir / "frozen/npc.config"
        copy_regular(live_config, frozen_config)

        stage = "frozen-inventory"
        build_commands = [
            phase_command(attempt_dir / "raw/build-phases/npc-default-config.log"),
            phase_command(attempt_dir / "raw/build-phases/nemu-reference-build.log"),
            phase_command(attempt_dir / "raw/build-phases/npc-verilator-build.log"),
        ]
        official_command = phase_command(attempt_dir / "raw/official-run.log")
        am_command = phase_command(attempt_dir / "raw/am-run.log")
        coremark_command = phase_command(attempt_dir / "raw/coremark.log")
        dhrystone_command = phase_command(attempt_dir / "raw/dhrystone.log")
        official_records = paired_records(
            attempt_dir, "official", frozen_official_ids)
        am_ids = before.get("am_test_ids")
        if not isinstance(am_ids, list) or len(am_ids) != 61:
            raise RuntimeError("frozen AM input inventory is not exactly 61 tests")
        am_records = paired_records(attempt_dir, "am", [str(value) for value in am_ids])

        simulator = attempt_dir / "frozen/NpcSimTop"
        reference = attempt_dir / "frozen/riscv64-nemu-interpreter-so"
        profile = attempt_dir / "frozen/difftest-reference-profile.json"
        for artifact_path in (simulator, reference, profile):
            if artifact_path.is_symlink() or not artifact_path.is_file():
                raise RuntimeError(f"frozen execution artifact is missing: {artifact_path}")

        stage = "descriptor-replay"
        descriptor = {
            "schema": legacy.functional.DESCRIPTOR_SCHEMA,
            "design_id": design_id,
            "cohort_id": current.COHORT_ID,
            "simulator": module_evidence.relative(simulator),
            "configuration": module_evidence.relative(frozen_config),
            "build": {
                "command": " && ".join(build_commands),
                "return_code": 0,
                "raw_log": module_evidence.relative(attempt_dir / "raw/build.log"),
            },
            "module": {"command": module_command, "tests": module_records},
            "official": {"command": official_command, "tests": official_records},
            "am": {"command": am_command, "tests": am_records},
            "difftest": {
                "command": am_command,
                "mismatches": 0,
                "reference": module_evidence.relative(reference),
                "reference_profile": module_evidence.relative(profile),
            },
            "benchmarks": {
                "coremark": {
                    "command": coremark_command,
                    "return_code": 0,
                    "image": module_evidence.relative(
                        attempt_dir / "images/benchmarks/coremark.bin"),
                    "raw_log": module_evidence.relative(
                        attempt_dir / "raw/coremark.log"),
                    "iterations": 10,
                    "crc": "0xfcaf",
                    "good_traps": 1,
                },
                "dhrystone": {
                    "command": dhrystone_command,
                    "return_code": 0,
                    "image": module_evidence.relative(
                        attempt_dir / "images/benchmarks/dhrystone.bin"),
                    "raw_log": module_evidence.relative(
                        attempt_dir / "raw/dhrystone.log"),
                    "runs": 10000,
                    "good_traps": 1,
                },
            },
        }
        descriptor_path = output_dir / "functional-run-descriptor.json"
        module_evidence.write_json(descriptor_path, descriptor)
        aggregate_path = output_dir / "functional-aggregate.json"
        aggregate_result_path = output_dir / "functional-aggregate-result.json"
        aggregate_log_path = output_dir / "functional-aggregate.log"
        assembled = legacy.functional.assemble(
            root=ROOT,
            descriptor_path=descriptor_path,
            wrapper_dir=output_dir / "wrapped",
            aggregate_path=aggregate_path,
            mutation_summary_path=output_dir / "mutations/summary.json",
            raw_log_path=aggregate_log_path,
            result_path=aggregate_result_path,
            check_current_design=True,
        )
        if assembled.get("status") != "PASS" or assembled.get("exit_code") != 0:
            raise RuntimeError("replayed functional aggregate is not PASS")

        stage = "receipt"
        receipt = {
            "schema": SCHEMA,
            "status": "PASS",
            "design_id": design_id,
            "classification": "execution-complete-old-input-oracle-false-positive",
            "source_attempt": relative_repo_dir(attempt_dir),
            "source_status": module_evidence.artifact(
                original_status_path, kind="original_fail_status"),
            "module_result": module_evidence.artifact(
                module_result_path, kind="module_current_result"),
            "input_replay": {
                "pre": module_evidence.artifact(pre_path, kind="recorded_input_binding"),
                "post": module_evidence.artifact(post_path, kind="recorded_input_binding"),
                "changed_entries_before": len(original_changes),
                "excluded_generated_entries": len(removed_before),
                "changed_entries_after": 0,
                "detail": module_evidence.artifact(
                    input_replay_path, kind="input_oracle_replay"),
            },
            "configuration_reconstruction": {
                "mode": "current-dot-config-with-recorded-derived-bindings",
                "original_dot_config_frozen": False,
                "bindings": configuration_bindings,
            },
            "counts": assembled["counts"],
            "artifacts": {
                "aggregate": module_evidence.artifact(
                    aggregate_path, kind="functional_aggregate"),
                "aggregate_result": module_evidence.artifact(
                    aggregate_result_path, kind="functional_aggregate_result"),
                "aggregate_log": module_evidence.artifact(
                    aggregate_log_path, kind="functional_aggregate_log"),
                "simulator": module_evidence.artifact(
                    simulator, kind="simulator_binary"),
                "reference": module_evidence.artifact(
                    reference, kind="reference_model_binary"),
                "configuration": module_evidence.artifact(
                    frozen_config, kind="kconfig"),
            },
            "published_current": publish_current,
        }
        if publish_current:
            current.publish_generated(aggregate_path, current.CANONICAL_AGGREGATE)
            current.publish_generated(
                aggregate_result_path, current.CANONICAL_RESULT)
            current.publish_generated(aggregate_log_path, current.CANONICAL_LOG)
            receipt["canonical_artifacts"] = {
                "aggregate": module_evidence.artifact(
                    current.CANONICAL_AGGREGATE, kind="functional_aggregate"),
                "aggregate_result": module_evidence.artifact(
                    current.CANONICAL_RESULT, kind="functional_aggregate_result"),
                "aggregate_log": module_evidence.artifact(
                    current.CANONICAL_LOG, kind="functional_aggregate_log"),
            }
        module_evidence.write_json(output_dir / "replay-result.json", receipt)
        module_evidence.write_status(
            output_dir,
            state="PASS",
            stage="complete",
            detail=(
                f"module={assembled['counts']['module_passed']}/"
                f"{assembled['counts']['module_required']} official=177/177 "
                f"am={assembled['counts']['am_passed']}/"
                f"{assembled['counts']['am_required']} excluded_generated="
                f"{len(removed_before)}"
            ),
            design_id=design_id,
        )
        print(
            "[FULL-CORE-FUNCTIONAL-REPLAY][PASS] "
            f"design_id={design_id} module={assembled['counts']['module_passed']}/"
            f"{assembled['counts']['module_required']} official=177/177 "
            f"am={assembled['counts']['am_passed']}/{assembled['counts']['am_required']} "
            f"changed_after=0",
            flush=True,
        )
        return 0
    except (OSError, RuntimeError, ValueError) as exc:
        module_evidence.write_status(
            output_dir,
            state="FAIL",
            stage=stage,
            detail=str(exc),
            design_id=design_id,
        )
        print(f"[FULL-CORE-FUNCTIONAL-REPLAY][FAIL] {exc}", flush=True)
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Replay a completed RV64 functional input-oracle failure"
    )
    parser.add_argument("--attempt-dir", type=pathlib.Path, required=True)
    parser.add_argument("--module-result", type=pathlib.Path, required=True)
    parser.add_argument("--output-dir", type=pathlib.Path, required=True)
    parser.add_argument("--publish-current", action="store_true")
    args = parser.parse_args()
    return replay(
        attempt_raw=args.attempt_dir,
        module_result_raw=args.module_result,
        output_raw=args.output_dir,
        publish_current=args.publish_current,
    )


if __name__ == "__main__":
    raise SystemExit(main())
