#!/usr/bin/env python3
"""Compose and verify the default L0+L1+L2+L3 RV64 system signoff.

The checker never launches a guest.  It recomputes the live production RTL
identity, independently revalidates current L0 directed evidence and the
frozen L1/L2/L3 observations, and requires every retained execution input
manifest to remain valid.  Ubuntu 22.04 remains an explicitly optional,
non-blocking layer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from typing import Any


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOLS_DIR = ROOT / "npc/rv64/eval/ppa/tools"
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import architecture_hard_gates as architecture  # noqa: E402
import full_core_functional_evidence as full_core  # noqa: E402
import full_core_functional_replay as full_core_replay  # noqa: E402
import lightweight_linux_run as l3_checker  # noqa: E402
import mini_system_run as l2_checker  # noqa: E402


SCHEMA = "npc-rv64-layered-system-signoff-current-v1"
POLICY_PATH = pathlib.PurePosixPath(
    "npc/rv64/design/arch/layered-system-signoff-policy-v1.json"
)
SCHEMA_PATH = pathlib.PurePosixPath(
    "npc/rv64/eval/ppa/schemas/layered-system-signoff-current-v1.schema.json"
)
DEFAULT_CONJUNCTION = [
    "L0_DIRECTED_RTL",
    "L1_FULL_CORE_DIFFTEST",
    "L2_MINI_SYSTEM",
    "L3_LIGHTWEIGHT_LINUX",
]
EXPECTED_L1_COUNTS = {
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
LAYER_EVIDENCE_FILES = {
    "artifact-binding.txt",
    "artifact-cache-state.txt",
    "binding.txt",
    "checker.log",
    "console.log",
    "input-hashes-after.sha256",
    "input-hashes-before.sha256",
    "layer-source-after.txt",
    "layer-source-before.txt",
    "npc.log",
    "rtl-assertion-failures.txt",
    "rtl-identity-after.json",
    "rtl-identity-after.log",
    "rtl-identity-before.json",
    "rtl-identity-before.log",
    "runtime-cleanup.txt",
    "simulator-binding.txt",
    "simulator-source-after.txt",
    "simulator-source-before.txt",
    "summary.json",
    "terminal-and-phase-markers.txt",
}
LAYER_IDENTITY_HELPER_REPLAY_PATHS = frozenset(
    {"npc/rv64/eval/ppa/tools/architecture_hard_gates.py"}
)
SHA_LINE_RE = re.compile(r"^(?P<sha>[0-9a-f]{64})  (?P<path>.+)$")
SOURCE_EXECUTION_FAIL_RE = re.compile(
    r"^FAIL rc=[0-9]+ stage=evidence-complete "
    r"evidence_complete=0 cleanup_rc=0\n$"
)


class SignoffError(RuntimeError):
    """The supplied evidence cannot support current layered signoff."""


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _lexical_parts(path: pathlib.PurePath) -> None:
    if any(part in {"", ".", ".."} for part in path.parts):
        raise SignoffError(f"non-canonical path: {path}")


def repo_path(
    raw: str | pathlib.Path,
    *,
    root: pathlib.Path = ROOT,
    require_file: bool = True,
) -> pathlib.Path:
    root = root.resolve(strict=True)
    value = pathlib.Path(raw)
    if value.is_absolute():
        try:
            relative = value.relative_to(root)
        except ValueError as exc:
            raise SignoffError(f"path leaves repository: {raw}") from exc
    else:
        relative = value
    _lexical_parts(relative)
    current = root
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            raise SignoffError(f"symlink is not accepted in evidence path: {raw}")
    if require_file and not current.is_file():
        raise SignoffError(f"evidence path is not a regular file: {raw}")
    if not require_file and not current.is_dir():
        raise SignoffError(f"evidence path is not a regular directory: {raw}")
    return current


def task_run_dir(raw: str | pathlib.Path, *, root: pathlib.Path = ROOT) -> pathlib.Path:
    path = repo_path(raw, root=root, require_file=False)
    relative = path.relative_to(root.resolve(strict=True))
    if len(relative.parts) < 3 or relative.parts[:2] != (".github", "task-runs"):
        raise SignoffError(f"evidence directory is outside task-runs: {raw}")
    return path


def relative(path: pathlib.Path, *, root: pathlib.Path = ROOT) -> str:
    return path.relative_to(root.resolve(strict=True)).as_posix()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SignoffError(f"cannot read JSON evidence: {path}") from exc
    if not isinstance(value, dict):
        raise SignoffError(f"JSON evidence is not an object: {path}")
    return value


def artifact(
    path: pathlib.Path,
    *,
    kind: str,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    checked = repo_path(path, root=root)
    return {
        "kind": kind,
        "path": relative(checked, root=root),
        "sha256": sha256_file(checked),
        "size_bytes": checked.stat().st_size,
    }


def verify_artifact(
    value: Any,
    *,
    expected_kind: str | None = None,
    root: pathlib.Path = ROOT,
) -> pathlib.Path:
    if not isinstance(value, dict) or set(value) != {
        "kind", "path", "sha256", "size_bytes"
    }:
        raise SignoffError("artifact receipt field set differs from exact contract")
    if expected_kind is not None and value.get("kind") != expected_kind:
        raise SignoffError(f"artifact kind mismatch: {value.get('kind')}")
    path = repo_path(str(value.get("path", "")), root=root)
    if value.get("sha256") != sha256_file(path):
        raise SignoffError(f"artifact hash mismatch: {value.get('path')}")
    if value.get("size_bytes") != path.stat().st_size:
        raise SignoffError(f"artifact size mismatch: {value.get('path')}")
    return path


def inspect_checksum_manifest(
    manifest_path: pathlib.Path,
    *,
    base: pathlib.Path,
    root: pathlib.Path = ROOT,
) -> list[dict[str, Any]]:
    manifest_path = repo_path(manifest_path, root=root)
    entries: list[dict[str, Any]] = []
    seen: set[str] = set()
    for number, line in enumerate(
        manifest_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        match = SHA_LINE_RE.fullmatch(line)
        if match is None:
            raise SignoffError(f"malformed checksum line {number}: {manifest_path}")
        name = match.group("path")
        if name in seen:
            raise SignoffError(f"duplicate checksum path: {name}")
        seen.add(name)
        raw = pathlib.Path(name)
        target = raw if raw.is_absolute() else base / raw
        checked = repo_path(target, root=root)
        observed = sha256_file(checked)
        entries.append(
            {
                "name": name,
                "path": checked,
                "recorded_sha256": match.group("sha"),
                "current_sha256": observed,
            }
        )
    if not entries:
        raise SignoffError(f"empty checksum manifest: {manifest_path}")
    return entries


def parse_checksum_manifest(
    manifest_path: pathlib.Path,
    *,
    base: pathlib.Path,
    root: pathlib.Path = ROOT,
) -> list[tuple[str, pathlib.Path, str]]:
    entries = inspect_checksum_manifest(manifest_path, base=base, root=root)
    result: list[tuple[str, pathlib.Path, str]] = []
    for entry in entries:
        if entry["recorded_sha256"] != entry["current_sha256"]:
            raise SignoffError(f"checksum mismatch: {entry['name']}")
        result.append((entry["name"], entry["path"], entry["current_sha256"]))
    return result


def verify_seal(
    evidence_dir: pathlib.Path,
    *,
    expected_names: set[str] | None = None,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    evidence_dir = task_run_dir(evidence_dir, root=root)
    seal_path = repo_path(evidence_dir / "evidence-seal.txt", root=root)
    manifest_path = repo_path(evidence_dir / "evidence-files.sha256", root=root)
    verify_log_path = repo_path(evidence_dir / "evidence-files.verify.log", root=root)
    fields: dict[str, str] = {}
    for line in seal_path.read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            raise SignoffError("evidence seal contains a malformed line")
        key, value = line.split("=", 1)
        if not key or key in fields:
            raise SignoffError(f"evidence seal key is invalid/duplicate: {key}")
        fields[key] = value
    if set(fields) != {
        "schema", "file_count", "manifest_sha256",
        "verification_log_sha256", "verification",
    }:
        raise SignoffError("evidence seal field set differs from exact contract")
    if (
        fields["schema"] != "npc-rv64-final-evidence-seal-v1"
        or fields["verification"] != "PASS"
        or fields["manifest_sha256"] != sha256_file(manifest_path)
        or fields["verification_log_sha256"] != sha256_file(verify_log_path)
    ):
        raise SignoffError("evidence seal hash/status binding mismatch")
    entries = parse_checksum_manifest(
        manifest_path, base=evidence_dir, root=root
    )
    if fields["file_count"] != str(len(entries)):
        raise SignoffError("evidence seal file_count mismatch")
    names = [name for name, _, _ in entries]
    if expected_names is not None and set(names) != expected_names:
        raise SignoffError("layer evidence manifest membership differs")
    verify_lines = verify_log_path.read_text(encoding="utf-8").splitlines()
    if verify_lines != [f"{name}: OK" for name in names]:
        raise SignoffError("evidence verification log differs from sealed manifest")
    return {
        "sealed_file_count": len(entries),
        "manifest": artifact(
            manifest_path, kind="evidence_manifest", root=root
        ),
        "seal": artifact(seal_path, kind="evidence_seal", root=root),
        "verification_log": artifact(
            verify_log_path, kind="evidence_verification_log", root=root
        ),
    }


def verify_current_inputs(
    evidence_dir: pathlib.Path,
    *,
    allowed_live_drift: frozenset[str] = frozenset(),
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    before = repo_path(evidence_dir / "input-hashes-before.sha256", root=root)
    after = repo_path(evidence_dir / "input-hashes-after.sha256", root=root)
    if before.read_bytes() != after.read_bytes():
        raise SignoffError("execution input manifests differ before/after")
    entries = inspect_checksum_manifest(
        after, base=root.resolve(strict=True), root=root
    )
    live_drift: list[dict[str, str]] = []
    for entry in entries:
        if entry["recorded_sha256"] == entry["current_sha256"]:
            continue
        path = relative(entry["path"], root=root)
        if path not in allowed_live_drift:
            raise SignoffError(f"checksum mismatch: {entry['name']}")
        live_drift.append(
            {
                "path": path,
                "recorded_sha256": entry["recorded_sha256"],
                "current_sha256": entry["current_sha256"],
                "classification": "rtl_identity_helper_only",
            }
        )
    observed_drift = {entry["path"] for entry in live_drift}
    if observed_drift != set(allowed_live_drift):
        raise SignoffError(
            "allowed RTL identity-helper drift set differs from observed drift"
        )
    return {
        "current_input_file_count": len(entries),
        "before": artifact(before, kind="input_manifest", root=root),
        "after": artifact(after, kind="input_manifest", root=root),
        "live_drift": live_drift,
        "execution_reused": bool(live_drift),
        "replay_scope": (
            "rtl-identity-helper-only" if live_drift else "exact-current-inputs"
        ),
    }


def read_kv(path: pathlib.Path, *, root: pathlib.Path = ROOT) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(
        repo_path(path, root=root).read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not line:
            continue
        if "=" not in line:
            raise SignoffError(f"key/value line {number} is malformed: {path}")
        key, value = line.split("=", 1)
        if not key or key in result:
            raise SignoffError(f"key/value key is invalid/duplicate: {key}")
        result[key] = value
    return result


def verify_cleanup(path: pathlib.Path, *, root: pathlib.Path = ROOT) -> None:
    value = read_kv(path, root=root)
    if (
        value.get("runtime_owned") != "1"
        or value.get("runtime_removed") != "1"
        or value.get("remove_rc") != "0"
    ):
        raise SignoffError("layer runtime cleanup receipt is not complete PASS")
    runtime_path = pathlib.Path(value.get("runtime_path", ""))
    expected_root = root.resolve(strict=True) / ".github/runtime-artifacts"
    try:
        runtime_path.relative_to(expected_root)
    except ValueError as exc:
        raise SignoffError("layer cleanup path leaves runtime-artifacts") from exc


def verify_l0(
    module_dir: pathlib.Path,
    *,
    design_id: str,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    """Verify the independently refreshable current L0 module layer."""

    module_dir = task_run_dir(module_dir, root=root)
    module_result = repo_path(module_dir / "result.json", root=root)
    _, module_records = full_core.validate_module_result(
        module_result,
        expected_design_id=design_id,
        require_current_inputs=True,
    )
    if len(module_records) != 113:
        raise SignoffError("L0 directed test count differs from exact inventory")
    for record in module_records:
        log_path = repo_path(record["raw_log"], root=root)
        if "-DOOO_ASSERT" not in log_path.read_text(
            encoding="utf-8", errors="replace"
        ):
            raise SignoffError(
                f"L0 assertion compile flag is absent: {record['test_id']}"
            )
    module_status = module_result.parent / "status.json"
    return {
        "claim": "L0_DIRECTED_RTL_PASS_CURRENT_IDENTITY",
        "status": "PASS",
        "design_id": design_id,
        "tests": {"passed": 113, "required": 113},
        "rtl_assertions": {"enabled": True, "failures": 0},
        "result": artifact(module_result, kind="module_current_result", root=root),
        "stage_status": artifact(
            module_status, kind="module_stage_status", root=root
        ),
    }


def verify_l1(
    replay_dir: pathlib.Path,
    *,
    design_id: str,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    replay_dir = task_run_dir(replay_dir, root=root)
    status_path = repo_path(
        replay_dir / "full-core-checker-replay.status", root=root
    )
    if status_path.read_text(encoding="utf-8") != "PASS\n":
        raise SignoffError("L1 checker-replay top status is not exact PASS")
    seal = verify_seal(replay_dir, root=root)
    inputs = verify_current_inputs(replay_dir, root=root)
    result_path = repo_path(
        replay_dir / "evidence/functional/replay-result.json", root=root
    )
    result = load_json(result_path)
    expected = {
        "schema": full_core_replay.SCHEMA,
        "status": "PASS",
        "claim": "L1_FULL_CORE_DIFFTEST_PASS_CURRENT_IDENTITY",
        "signoff_scope": "full-l1-checker-replay",
        "design_id": design_id,
        "classification": (
            "execution-complete-old-benchmark-terminal-oracle-false-positive"
        ),
        "source_inputs_unchanged": True,
        "live_drift_is_checker_only": True,
        "original_status_unchanged": True,
        "guest_rerun": False,
        "published_current": False,
    }
    for key, value in expected.items():
        if result.get(key) != value:
            raise SignoffError(f"L1 replay field mismatch: {key}")
    if result.get("counts") != EXPECTED_L1_COUNTS:
        raise SignoffError("L1 replay counts differ from exact cohort")

    module_result = verify_artifact(
        result.get("module_result"), expected_kind="module_current_result", root=root
    )
    source_attempt = task_run_dir(
        str(result.get("source_attempt", "")), root=root
    )
    expected_module_result = source_attempt.parent / "module/result.json"
    if module_result != expected_module_result:
        raise SignoffError("L0 module result is not owned by the L1 source run")
    source_status = verify_artifact(
        result.get("source_status"), expected_kind="original_fail_status", root=root
    )
    if source_status != source_attempt / "status.json":
        raise SignoffError("L1 source functional status path differs")
    source_status_json = load_json(source_status)
    detail = source_status_json.get("detail")
    if (
        source_status_json.get("state") != "FAIL"
        or source_status_json.get("design_id") != design_id
        or not isinstance(detail, str)
        or full_core_replay.BENCHMARK_ORACLE_FAILURE_RE.fullmatch(detail) is None
    ):
        raise SignoffError("L1 source status is not the exact benchmark oracle FAIL")
    source_execution = verify_artifact(
        result.get("source_execution_status"),
        expected_kind="original_full_core_fail_status",
        root=root,
    )
    if source_execution != source_attempt.parents[1] / "full-core-current.status":
        raise SignoffError("L1 source execution status is not owned by the source run")
    if SOURCE_EXECUTION_FAIL_RE.fullmatch(
        source_execution.read_text(encoding="utf-8")
    ) is None:
        raise SignoffError("L1 source execution status is not the exact FAIL boundary")

    checker_replay_path = verify_artifact(
        result.get("checker_replay"), expected_kind="checker_input_replay", root=root
    )
    checker_replay = load_json(checker_replay_path)
    changes = checker_replay.get("live_changes")
    if (
        checker_replay.get("source_inputs_unchanged") is not True
        or not isinstance(changes, list)
        or len(changes) != 1
        or changes[0].get("group") != "functional_workflow"
        or changes[0].get("path") != full_core_replay.BENCHMARK_CHECKER_PATH
    ):
        raise SignoffError("L1 replay is not limited to the benchmark checker")
    for name, expected_kind in (
        ("descriptor", "functional_run_descriptor"),
        ("aggregate", "functional_aggregate"),
        ("aggregate_result", "functional_aggregate_result"),
        ("aggregate_log", "functional_aggregate_log"),
        ("simulator", "simulator_binary"),
        ("reference", "reference_model_binary"),
        ("configuration", "kconfig"),
    ):
        verify_artifact(
            result.get("artifacts", {}).get(name),
            expected_kind=expected_kind,
            root=root,
        )

    _, module_records = full_core.validate_module_result(
        module_result,
        expected_design_id=design_id,
        require_current_inputs=False,
    )
    if len(module_records) != 113:
        raise SignoffError("L0 directed test count differs from exact inventory")
    for record in module_records:
        log_path = repo_path(record["raw_log"], root=root)
        if "-DOOO_ASSERT" not in log_path.read_text(
            encoding="utf-8", errors="replace"
        ):
            raise SignoffError(
                f"L0 assertion compile flag is absent: {record['test_id']}"
            )
    stage_status = load_json(
        repo_path(replay_dir / "evidence/functional/status.json", root=root)
    )
    if (
        stage_status.get("state") != "PASS"
        or stage_status.get("stage") != "complete"
        or stage_status.get("design_id") != design_id
    ):
        raise SignoffError("L1 replay stage status is not complete PASS")
    checker_tests = repo_path(replay_dir / "checker-tests.log", root=root).read_text(
        encoding="utf-8", errors="replace"
    )
    replay_log = repo_path(replay_dir / "replay.log", root=root).read_text(
        encoding="utf-8", errors="replace"
    )
    if "\nOK\n" not in f"\n{checker_tests}" or (
        "[FULL-CORE-FUNCTIONAL-REPLAY][PASS]" not in replay_log
    ):
        raise SignoffError("L1 checker tests or replay marker is missing")

    l1 = {
        "claim": result["claim"],
        "status": "PASS",
        "design_id": design_id,
        "signoff_scope": result["signoff_scope"],
        "classification": result["classification"],
        "counts": result["counts"],
        "guest_rerun": False,
        "published_current": False,
        "replay_result": artifact(
            result_path, kind="full_core_checker_replay_result", root=root
        ),
        "top_status": artifact(status_path, kind="task_run_status", root=root),
        "source_execution_status": artifact(
            source_execution, kind="original_full_core_fail_status", root=root
        ),
        "inputs": inputs,
        "seal": seal,
    }
    return l1


def verify_layer(
    result_dir: pathlib.Path,
    *,
    layer: str,
    design_id: str,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    result_dir = task_run_dir(result_dir, root=root)
    if layer == "L2":
        checker = l2_checker
        top_name = "mini-system.status"
        expected_case = "all"
        case_key = "l2_case"
        expected_claim = "L2_MINI_SYSTEM_PASS_CURRENT_IDENTITY"
        expected_scope = "full-l2"
        terminal_count = 5
        summary_schema = l2_checker.SCHEMA
    elif layer == "L3":
        checker = l3_checker
        top_name = "lightweight-linux.status"
        expected_case = "all"
        case_key = "l3_case"
        expected_claim = "L3_LIGHTWEIGHT_LINUX_PASS_CURRENT_IDENTITY"
        expected_scope = "full-l3"
        terminal_count = 6
        summary_schema = l3_checker.SCHEMA
    else:
        raise SignoffError(f"unsupported layer: {layer}")
    top_status = repo_path(result_dir.parent / top_name, root=root)
    if top_status.read_text(encoding="utf-8") != "PASS\n":
        raise SignoffError(f"{layer} top status is not exact PASS")
    seal = verify_seal(
        result_dir, expected_names=LAYER_EVIDENCE_FILES, root=root
    )
    inputs = verify_current_inputs(
        result_dir,
        allowed_live_drift=LAYER_IDENTITY_HELPER_REPLAY_PATHS,
        root=root,
    )
    binding_path = repo_path(result_dir / "binding.txt", root=root)
    binding = checker.read_binding(binding_path)
    checker.require_binding(binding)
    if (
        binding.get("rtl_design_id") != design_id
        or binding.get(case_key) != expected_case
        or binding.get("ubuntu2204_full_simulation") != "not_launched"
        or any(
            binding.get(name) != "1"
            for name in ("OOO_ASSERT", "OOO_CSR_QUEUE_HEAD", "OOO_TERMINAL_HOLDER_ASSERT")
        )
    ):
        raise SignoffError(f"{layer} binding identity/case/assertion mismatch")
    summary_path = repo_path(result_dir / "summary.json", root=root)
    summary = load_json(summary_path)
    recomputed = checker.parse_execution(
        repo_path(result_dir / "console.log", root=root),
        repo_path(result_dir / "npc.log", root=root),
        binding_path,
    )
    if recomputed != summary:
        raise SignoffError(f"{layer} semantic summary differs from replayed logs")
    if (
        summary.get("schema") != summary_schema
        or summary.get("status") != "PASS"
        or summary.get("claim") != expected_claim
        or summary.get("signoff_scope") != expected_scope
        or summary.get(case_key) != expected_case
        or summary.get("rtl_design_id") != design_id
        or summary.get("assertion_failures") != 0
        or len(summary.get("terminal_counts", {})) != terminal_count
        or any(value != 1 for value in summary.get("terminal_counts", {}).values())
    ):
        raise SignoffError(f"{layer} full-layer summary contract mismatch")
    if layer == "L3" and summary.get("critical_markers") != 0:
        raise SignoffError("L3 critical marker count is nonzero")
    if repo_path(
        result_dir / "rtl-assertion-failures.txt", root=root
    ).stat().st_size != 0:
        raise SignoffError(f"{layer} RTL assertion file is not empty")
    for before_name, after_name in (
        ("rtl-identity-before.json", "rtl-identity-after.json"),
        ("layer-source-before.txt", "layer-source-after.txt"),
        ("simulator-source-before.txt", "simulator-source-after.txt"),
    ):
        before = repo_path(result_dir / before_name, root=root)
        after = repo_path(result_dir / after_name, root=root)
        if before.read_bytes() != after.read_bytes():
            raise SignoffError(f"{layer} before/after identity differs: {before_name}")
    rtl_identity = load_json(
        repo_path(result_dir / "rtl-identity-after.json", root=root)
    )
    if (
        rtl_identity.get("rtl_design_id") != design_id
        or rtl_identity.get("production_rtl_file_count") != 146
    ):
        raise SignoffError(f"{layer} RTL identity receipt mismatch")
    verify_cleanup(result_dir / "runtime-cleanup.txt", root=root)
    return {
        "claim": expected_claim,
        "status": "PASS",
        "design_id": design_id,
        "case": expected_case,
        "signoff_scope": expected_scope,
        "cycles": summary["cycles"],
        "commits": summary["commits"],
        "cpi": summary["cpi"],
        "rtl_assertions": {"enabled": True, "failures": 0},
        "terminal_counts": summary["terminal_counts"],
        "simulator_sha256": binding["simulator_sha256"],
        "simulator_source_sha256": binding["simulator_source_sha256"],
        "layer_source_sha256": binding["layer_source_sha256"],
        "execution_reused": True,
        "guest_rerun": False,
        "identity_helper_replay": inputs["live_drift"],
        "summary": artifact(summary_path, kind=f"{layer.lower()}_summary", root=root),
        "binding": artifact(binding_path, kind=f"{layer.lower()}_binding", root=root),
        "top_status": artifact(top_status, kind="task_run_status", root=root),
        "inputs": inputs,
        "seal": seal,
    }


def compose_receipt(
    *,
    policy: dict[str, Any],
    policy_artifact: dict[str, Any],
    checker_artifact: dict[str, Any],
    schema_artifact: dict[str, Any],
    design_id: str,
    rtl_file_count: int,
    source_directories: dict[str, str],
    l0: dict[str, Any],
    l1: dict[str, Any],
    l2: dict[str, Any],
    l3: dict[str, Any],
) -> dict[str, Any]:
    if policy.get("default_signoff_conjunction") != DEFAULT_CONJUNCTION:
        raise SignoffError("layered policy default conjunction drifted")
    promotion = policy.get("promotion_boundary", {})
    if (
        promotion.get("required_default_claim")
        != "LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY"
        or promotion.get("ubuntu2204_full_recertification")
        != "OPTIONAL_NOT_IMPLIED"
    ):
        raise SignoffError("layered policy promotion boundary drifted")
    optional = policy.get("optional_full_ubuntu", {})
    if (
        optional.get("launch_policy") != "explicit-user-request-only"
        or optional.get("absence_blocks_default_signoff") is not False
    ):
        raise SignoffError("optional Ubuntu launch boundary drifted")
    for name, layer in (("L0", l0), ("L1", l1), ("L2", l2), ("L3", l3)):
        if layer.get("status") != "PASS" or layer.get("design_id") != design_id:
            raise SignoffError(f"{name} does not bind the common PASS design")
    if l2.get("case") != "all" or l3.get("case") != "all":
        raise SignoffError("directed L2/L3 case cannot claim a complete layer")
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "claim": "LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY",
        "rtl_design_id": design_id,
        "production_rtl_file_count": rtl_file_count,
        "default_signoff_conjunction": DEFAULT_CONJUNCTION,
        "source_directories": source_directories,
        "policy": policy_artifact,
        "checker": checker_artifact,
        "schema_contract": schema_artifact,
        "layers": {
            "L0_DIRECTED_RTL": l0,
            "L1_FULL_CORE_DIFFTEST": l1,
            "L2_MINI_SYSTEM": l2,
            "L3_LIGHTWEIGHT_LINUX": l3,
        },
        "optional_full_ubuntu": {
            "status": "NOT_RUN",
            "launch_policy": "explicit-user-request-only",
            "blocks_default_signoff": False,
            "claim": "OPTIONAL_NOT_IMPLIED",
        },
        "non_claims": [
            "Ubuntu 22.04 userland or systemd recertification",
            "ARCH_STABLE or PROMOTABLE maturity",
            "synthesis, STA, power, area, CPI or PPA qualification",
        ],
    }


def evaluate(
    *,
    l0_module_dir: pathlib.Path,
    l1_replay_dir: pathlib.Path,
    l2_result_dir: pathlib.Path,
    l3_result_dir: pathlib.Path,
    root: pathlib.Path = ROOT,
) -> dict[str, Any]:
    root = root.resolve(strict=True)
    design_hex, rtl_files = architecture.rtl_binding(root)
    design_id = f"sha256:{design_hex}"
    if len(rtl_files) != 146:
        raise SignoffError(f"production RTL file count drifted: {len(rtl_files)}")
    policy_path = repo_path(root / POLICY_PATH, root=root)
    schema_path = repo_path(root / SCHEMA_PATH, root=root)
    policy = load_json(policy_path)
    if policy.get("schema") != "npc-rv64-layered-system-signoff-policy-v1":
        raise SignoffError("layered system policy schema mismatch")
    l0_dir = task_run_dir(l0_module_dir, root=root)
    l1_dir = task_run_dir(l1_replay_dir, root=root)
    l2_dir = task_run_dir(l2_result_dir, root=root)
    l3_dir = task_run_dir(l3_result_dir, root=root)
    l0 = verify_l0(l0_dir, design_id=design_id, root=root)
    l1 = verify_l1(l1_dir, design_id=design_id, root=root)
    l2 = verify_layer(l2_dir, layer="L2", design_id=design_id, root=root)
    l3 = verify_layer(l3_dir, layer="L3", design_id=design_id, root=root)
    return compose_receipt(
        policy=policy,
        policy_artifact=artifact(policy_path, kind="layered_signoff_policy", root=root),
        checker_artifact=artifact(
            repo_path(pathlib.Path(__file__), root=root),
            kind="layered_signoff_checker",
            root=root,
        ),
        schema_artifact=artifact(
            schema_path, kind="layered_signoff_schema", root=root
        ),
        design_id=design_id,
        rtl_file_count=len(rtl_files),
        source_directories={
            "l0_module": relative(l0_dir, root=root),
            "l1_checker_replay": relative(l1_dir, root=root),
            "l2_mini_system": relative(l2_dir, root=root),
            "l3_lightweight_linux": relative(l3_dir, root=root),
        },
        l0=l0,
        l1=l1,
        l2=l2,
        l3=l3,
    )


def atomic_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink() or path.parent.is_symlink():
        raise SignoffError(f"refuse symlink output: {path}")
    temporary = path.with_name(path.name + ".tmp")
    if temporary.is_symlink():
        raise SignoffError(f"refuse symlink temporary output: {temporary}")
    temporary.write_text(
        json.dumps(value, allow_nan=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("create")
    create.add_argument("--l0-module-dir", type=pathlib.Path, required=True)
    create.add_argument("--l1-replay-dir", type=pathlib.Path, required=True)
    create.add_argument("--l2-result-dir", type=pathlib.Path, required=True)
    create.add_argument("--l3-result-dir", type=pathlib.Path, required=True)
    create.add_argument("--output", type=pathlib.Path, required=True)
    verify = commands.add_parser("verify")
    verify.add_argument("--receipt", type=pathlib.Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "create":
            result = evaluate(
                l0_module_dir=args.l0_module_dir,
                l1_replay_dir=args.l1_replay_dir,
                l2_result_dir=args.l2_result_dir,
                l3_result_dir=args.l3_result_dir,
            )
            output = args.output if args.output.is_absolute() else ROOT / args.output
            output.resolve(strict=False).relative_to(ROOT.resolve(strict=True))
            atomic_json(output, result)
        else:
            receipt_path = repo_path(args.receipt)
            receipt = load_json(receipt_path)
            directories = receipt.get("source_directories")
            if not isinstance(directories, dict) or set(directories) != {
                "l0_module",
                "l1_checker_replay",
                "l2_mini_system",
                "l3_lightweight_linux",
            }:
                raise SignoffError("receipt source directory set differs")
            result = evaluate(
                l0_module_dir=pathlib.Path(directories["l0_module"]),
                l1_replay_dir=pathlib.Path(directories["l1_checker_replay"]),
                l2_result_dir=pathlib.Path(directories["l2_mini_system"]),
                l3_result_dir=pathlib.Path(directories["l3_lightweight_linux"]),
            )
            if result != receipt:
                raise SignoffError("receipt differs from recomputed layered evidence")
        print(
            "[RV64-LAYERED-SYSTEM-SIGNOFF][PASS] "
            f"design_id={result['rtl_design_id']} L0=113/113 "
            "L1=177+61 L2=all L3=all Ubuntu=not-run PPA=not-implied"
        )
        return 0
    except (OSError, ValueError, KeyError, SignoffError) as exc:
        print(f"[RV64-LAYERED-SYSTEM-SIGNOFF][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
