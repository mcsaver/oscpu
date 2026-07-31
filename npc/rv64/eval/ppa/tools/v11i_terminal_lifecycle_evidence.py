#!/usr/bin/env python3
"""Validate frozen V11I RV64 terminal-lifecycle evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v11i-terminal-lifecycle-evidence-v1"
RECEIPT_SCHEMA = "npc-rv64-v11i-terminal-lifecycle-validation-v1"
PROFILE_NAMES = (
    "production-assert",
    "production-release",
    "stale-tuple-assert",
    "stale-tuple-release",
)
TB_PASS = "[PASS] tb_ooo_int_backend_v11i_terminal_lifecycle"
WRAP_PASS = "[V11I-TERMINAL-WRAP]"
STALE_ACTIVE = "[V11I-STALE-SOURCE-ACTIVE]"
HOLDER_ASSERT = "[V9Y-HOLDER-TERMINAL-NEXT]"
ASSERT_ESCAPED = "[V11I-HOLDER-ASSERTION-ESCAPED][FAIL]"
ABA_FAIL = "[V11I-LATE-TUPLE-ABA][FAIL]"
ABA_OBSERVATION_FAIL = "[V11I-LATE-TUPLE-OBSERVATION][FAIL]"
FOCUSED_DEFINE = "-DV11I_TERMINAL_LIFECYCLE_FOCUSED"
ASSERT_DEFINE = "-DOOO_ASSERT"
MUTATION_DEFINE = "-DV11I_STALE_TERMINAL_MUTATION"
EXPECTED_CONTRACT = {
    "rtl_objects": [
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
        "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
        "npc/rv64/vsrc/memory/OooLoadQueue.v",
    ],
    "cycle_configuration": (
        "33 sequential LOAD owners; tracker token 0..31 then "
        "token-0 reuse with a different full ProducerId"
    ),
    "testbench_observation": (
        "lane0 response-terminal collector ingress/accept, tracker live/table, "
        "LQ valid/terminal_seen raw Q, holder-next assertion"
    ),
    "profiles": list(PROFILE_NAMES),
    "prohibited_shortcut": (
        "no raw-terminal deduplication and no assertion weakening"
    ),
}


class EvidenceError(RuntimeError):
    """Raised when a V11I evidence claim is not bound to its raw inputs."""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def canonical_rtl_binding(repo_root: Path) -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (repo_root / "npc" / "rv64" / "vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    if not files:
        raise EvidenceError("current RV64 RTL source set is empty")
    entries = {
        path.relative_to(repo_root).as_posix(): sha256_file(path)
        for path in files
    }
    return canonical_digest(entries), entries


def load_json(path: Path) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise EvidenceError(f"evidence is not a regular file: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise EvidenceError(f"invalid JSON evidence: {path}") from error
    if not isinstance(value, dict):
        raise EvidenceError("evidence root must be an object")
    return value


def resolve_repo_file(repo_root: Path, raw_path: Any) -> Path:
    if not isinstance(raw_path, str) or not raw_path:
        raise EvidenceError("evidence path is invalid")
    candidate = Path(raw_path)
    if candidate.is_absolute():
        resolved = candidate.resolve()
    else:
        resolved = (repo_root / candidate).resolve()
    try:
        resolved.relative_to(repo_root.resolve())
    except ValueError as error:
        raise EvidenceError(f"evidence path escapes repository: {raw_path}") from error
    if resolved.is_symlink() or not resolved.is_file():
        raise EvidenceError(f"evidence file is missing: {raw_path}")
    return resolved


def require_sha256(value: Any, label: str) -> str:
    if not isinstance(value, str) or re.fullmatch(r"[0-9a-f]{64}", value) is None:
        raise EvidenceError(f"{label} is not a SHA-256 digest")
    return value


def marker_counts(text: str) -> dict[str, int]:
    lines = text.splitlines()
    return {
        "wrap_pass": sum(WRAP_PASS in line for line in lines),
        "tb_pass": sum(TB_PASS in line for line in lines),
        "stale_active": sum(STALE_ACTIVE in line for line in lines),
        "holder_assert": sum(HOLDER_ASSERT in line for line in lines),
        "assertion_escaped": sum(ASSERT_ESCAPED in line for line in lines),
        "aba_fail": sum(ABA_FAIL in line for line in lines),
        "aba_observation_fail": sum(
            ABA_OBSERVATION_FAIL in line for line in lines
        ),
        "v11i_fail_total": sum(
            "[V11I-" in line and "[FAIL]" in line for line in lines
        ),
    }


def validate_profile(
    repo_root: Path,
    profile: dict[str, Any],
    *,
    expected_name: str,
) -> dict[str, Any]:
    if profile.get("profile") != expected_name or profile.get("status") != "PASS":
        raise EvidenceError(f"{expected_name}: profile status is not PASS")
    assertions = expected_name.endswith("-assert")
    stale = expected_name.startswith("stale-tuple-")
    if profile.get("assertions") is not assertions:
        raise EvidenceError(f"{expected_name}: assertion mode mismatch")
    if profile.get("stale_tuple_variant") is not stale:
        raise EvidenceError(f"{expected_name}: RTL selection mismatch")

    compile_value = profile.get("compile")
    simulation = profile.get("simulation")
    raw_evidence = profile.get("raw_evidence")
    if not isinstance(compile_value, dict) or not isinstance(simulation, dict):
        raise EvidenceError(f"{expected_name}: compile/simulation record missing")
    if not isinstance(raw_evidence, dict) or not raw_evidence:
        raise EvidenceError(f"{expected_name}: raw evidence binding missing")
    for raw_path, raw_digest in raw_evidence.items():
        recorded = require_sha256(raw_digest, f"{expected_name}:{raw_path}")
        path = resolve_repo_file(repo_root, raw_path)
        if sha256_file(path) != recorded:
            raise EvidenceError(f"{expected_name}: raw evidence hash drift: {raw_path}")

    command_paths = [
        raw_path for raw_path in raw_evidence if raw_path.endswith("/commands.json")
    ]
    if len(command_paths) != 1:
        raise EvidenceError(f"{expected_name}: commands.json binding is incomplete")
    commands = load_json(resolve_repo_file(repo_root, command_paths[0]))
    compile_command = commands.get("compile", {}).get("command")
    simulate_command = commands.get("simulate", {}).get("command")
    if (
        not isinstance(compile_command, list)
        or not all(isinstance(item, str) for item in compile_command)
        or not isinstance(simulate_command, list)
        or not all(isinstance(item, str) for item in simulate_command)
    ):
        raise EvidenceError(f"{expected_name}: command provenance is malformed")
    if FOCUSED_DEFINE not in compile_command:
        raise EvidenceError(f"{expected_name}: focused compile define is missing")
    if (ASSERT_DEFINE in compile_command) is not assertions:
        raise EvidenceError(f"{expected_name}: assertion compile define mismatch")
    if (MUTATION_DEFINE in compile_command) is not stale:
        raise EvidenceError(f"{expected_name}: mutation compile define mismatch")
    if any(
        "V11I_TERMINAL_LIFECYCLE_ONLY" in item
        for item in compile_command + simulate_command
    ):
        raise EvidenceError(f"{expected_name}: unexpected plusarg provenance")

    artifact = resolve_repo_file(repo_root, compile_value.get("artifact"))
    if (
        compile_value.get("rc") != 0
        or compile_value.get("timeout") is not False
        or compile_value.get("artifact_exists") is not True
        or sha256_file(artifact)
        != require_sha256(
            compile_value.get("artifact_sha256"),
            f"{expected_name}:compile artifact",
        )
    ):
        raise EvidenceError(f"{expected_name}: compile evidence is incomplete")

    sim_log = resolve_repo_file(repo_root, simulation.get("log"))
    if sha256_file(sim_log) != require_sha256(
        simulation.get("log_sha256"), f"{expected_name}:simulation log"
    ):
        raise EvidenceError(f"{expected_name}: simulation log hash drift")
    observed = marker_counts(sim_log.read_text(encoding="utf-8"))
    if profile.get("markers") != observed:
        raise EvidenceError(f"{expected_name}: marker summary differs from raw log")
    if simulation.get("timeout") is not False:
        raise EvidenceError(f"{expected_name}: simulation timed out")

    if not stale:
        valid = (
            simulation.get("rc") == 0
            and observed["wrap_pass"] == 1
            and observed["tb_pass"] == 1
            and observed["stale_active"] == 0
            and observed["holder_assert"] == 0
            and observed["v11i_fail_total"] == 0
        )
    elif assertions:
        valid = (
            isinstance(simulation.get("rc"), int)
            and simulation.get("rc") != 0
            and observed["stale_active"] == 1
            and observed["holder_assert"] == 1
            and observed["assertion_escaped"] == 0
            and observed["aba_fail"] == 0
            and observed["aba_observation_fail"] == 0
            and observed["tb_pass"] == 0
        )
    else:
        valid = (
            isinstance(simulation.get("rc"), int)
            and simulation.get("rc") != 0
            and observed["stale_active"] == 1
            and observed["holder_assert"] == 0
            and observed["assertion_escaped"] == 0
            and observed["aba_fail"] == 1
            and observed["aba_observation_fail"] == 0
            and observed["tb_pass"] == 0
        )
    if not valid:
        raise EvidenceError(f"{expected_name}: cycle markers do not meet contract")
    return {
        "profile": expected_name,
        "compile_rc": compile_value["rc"],
        "simulation_rc": simulation["rc"],
        "markers": observed,
    }


def validate(
    repo_root: Path,
    summary_path: Path,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    summary_path = summary_path.resolve()
    value = load_json(summary_path)
    if value.get("schema") != SCHEMA or value.get("status") != "PASS":
        raise EvidenceError("summary schema/status mismatch")
    if value.get("contract") != EXPECTED_CONTRACT:
        raise EvidenceError("terminal lifecycle contract binding mismatch")

    binding = value.get("rtl_source_binding")
    if not isinstance(binding, dict) or binding.get("unchanged") is not True:
        raise EvidenceError("RTL pre/post binding is incomplete")
    design_sha, rtl_files = canonical_rtl_binding(repo_root)
    design_id = f"sha256:{design_sha}"
    if (
        binding.get("design_id") != design_id
        or binding.get("design_id_after") != design_id
        or binding.get("file_count") != len(rtl_files)
        or binding.get("files") != rtl_files
    ):
        raise EvidenceError("summary is not bound to current RV64 RTL")

    runner_inputs = value.get("runner_inputs")
    if (
        not isinstance(runner_inputs, dict)
        or runner_inputs.get("unchanged") is not True
        or runner_inputs.get("pre") != runner_inputs.get("post")
        or not isinstance(runner_inputs.get("pre"), dict)
        or not runner_inputs["pre"]
    ):
        raise EvidenceError("runner input pre/post binding is incomplete")
    for raw_path, raw_digest in runner_inputs["pre"].items():
        recorded = require_sha256(raw_digest, f"runner input:{raw_path}")
        if sha256_file(resolve_repo_file(repo_root, raw_path)) != recorded:
            raise EvidenceError(f"runner input hash drift: {raw_path}")

    variant = value.get("stale_tuple_variant")
    if not isinstance(variant, dict) or variant.get("compile_success_required") is not True:
        raise EvidenceError("stale tuple variant contract is incomplete")
    variant_path = resolve_repo_file(repo_root, variant.get("path"))
    variant_sha = require_sha256(variant.get("sha256"), "variant")
    backend = repo_root / "npc" / "rv64" / "vsrc" / "execute" / "OooIntBackend.v"
    backend_sha = require_sha256(
        variant.get("production_backend_sha256"), "production backend"
    )
    if (
        sha256_file(variant_path) != variant_sha
        or sha256_file(backend) != backend_sha
        or variant_sha == backend_sha
    ):
        raise EvidenceError("stale tuple variant binding is invalid")
    receipts = variant.get("receipts")
    if (
        not isinstance(receipts, list)
        or len(receipts) != 5
        or len({item.get("mutation_id") for item in receipts}) != 5
        or any(item.get("anchor_count") != 1 for item in receipts)
    ):
        raise EvidenceError("stale tuple mutation receipts are incomplete")

    profiles = value.get("profiles")
    if (
        not isinstance(profiles, list)
        or [item.get("profile") for item in profiles] != list(PROFILE_NAMES)
    ):
        raise EvidenceError("profile set/order mismatch")
    profile_receipts = [
        validate_profile(repo_root, profile, expected_name=name)
        for name, profile in zip(PROFILE_NAMES, profiles, strict=True)
    ]

    summary = value.get("summary")
    if (
        not isinstance(summary, dict)
        or summary.get("profile_total") != 4
        or summary.get("profile_passed") != 4
        or summary.get("production_profiles_passed") != 2
        or summary.get("stale_tuple_profiles_rejected") != 2
        or summary.get("source_pre_post_identical") is not True
        or summary.get("rtl_pre_post_identical") is not True
    ):
        raise EvidenceError("aggregate profile counts are invalid")
    scope = value.get("scope_boundary")
    if (
        not isinstance(scope, dict)
        or scope.get("full_system_run_launched") is not False
        or not isinstance(scope.get("not_promoted"), list)
        or "PPA" not in scope["not_promoted"]
    ):
        raise EvidenceError("claim boundary is missing")

    return {
        "schema": RECEIPT_SCHEMA,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "PASS",
        "summary_path": summary_path.relative_to(repo_root).as_posix(),
        "summary_sha256": sha256_file(summary_path),
        "design_id": design_id,
        "profiles": profile_receipts,
        "scope": "local RV64 terminal lifecycle only",
        "full_system_run_launched": False,
    }


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate V11I terminal-lifecycle evidence and raw markers"
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[5],
    )
    parser.add_argument("--summary", type=Path, required=True)
    parser.add_argument("--receipt-out", type=Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        receipt = validate(args.repo_root, args.summary)
    except (EvidenceError, OSError, UnicodeError) as error:
        print(f"[V11I-EVIDENCE-VALIDATION][FAIL] {error}", file=sys.stderr)
        return 1
    if args.receipt_out is not None:
        args.receipt_out.parent.mkdir(parents=True, exist_ok=True)
        args.receipt_out.write_text(
            json.dumps(
                receipt,
                allow_nan=False,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
    print(
        "[V11I-EVIDENCE-VALIDATION][PASS] "
        f"design_id={receipt['design_id']} profiles=4 system_run=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
