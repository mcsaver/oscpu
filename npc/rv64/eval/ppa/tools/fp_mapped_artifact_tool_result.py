#!/usr/bin/env python3
"""Generate and validate the FP mapped-artifact tool identity result.

The physical configuration ID and mapped-artifact profile are deliberately
separate Registry projections.  This tool never runs synthesis, OpenSTA, the
mapped parser main entry, or RTL simulation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


REPO_ROOT = pathlib.Path(__file__).resolve().parents[5]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from npc.rv64.eval.ppa.tools import architecture_registry as registry


RESULT_SCHEMA = "npc-rv64-fp-mapped-artifact-profile-tool-result-v1"
VALIDATION_RECEIPT_SCHEMA = (
    "npc-rv64-fp-mapped-artifact-profile-tool-validation-receipt-v4"
)
EXPECTED_CONFIGURATION_ID = (
    "mapped-5ns-fp-arith-production-children-inline-v1"
)
EXPECTED_PROFILE = "fp-arith-children-v1"
EXPECTED_DESIGN_ID = (
    "sha256:9d8bb6af7534717f6ed4b9f93b14f63aef407f5b2bc57feb43aef37ccbfbef5d"
)
EXPECTED_RESULT_SCHEMA_SHA256 = (
    "273d82ad1071a942fc559de333a98a25eb462eee4a22b4f7278783a23343626a"
)
EXPECTED_V4_CONTRACT_SHA256 = (
    "a8cf67fffdf31f7fb50ba9d65f0be82cec8900b83e99dbcc1c52283bfbeb9099"
)
SUPERSEDED_RESULT_SHA256 = (
    "d1edadb0b273c1937acc482a119dbfd93b167d1647450ccd5f41b5b415ce58f3"
)
SUPERSEDED_V2_RESULT_SHA256 = (
    "bf64542a3b4a3e54cebe8e7f96aaf53e1aa96a25a05091fba72b2d91700de4d0"
)
SUPERSEDED_V2_RECEIPT_SHA256 = (
    "572e5f0d8be3e9254ac14ae60f91d4d7a4f5fa392829ea6cdb3313aebeaeda1a"
)
SUPERSEDED_V2_RECEIPT_ID = (
    "sha256:5fec56b10128a7e7fae2ed9ad1a29ac062d493a8667113aa8966d848e315941a"
)
UNDISPATCHED_V3_CONTRACT_SHA256 = (
    "90e49ceb7ae95f4cd85d081eefed9a6359afc42620edb127dbb519d87cc8a87d"
)

REGISTRY_PATH = (
    REPO_ROOT / "npc/rv64/design/arch/rv64-architecture-registry-v1.json"
)
REGISTRY_SCHEMA_PATH = (
    REPO_ROOT / "npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json"
)
REGISTRY_TOOL_PATH = (
    REPO_ROOT / "npc/rv64/eval/ppa/tools/architecture_registry.py"
)
RESULT_SCHEMA_PATH = (
    REPO_ROOT
    / "npc/rv64/eval/ppa/schemas/"
    "fp-mapped-artifact-profile-tool-result-v1.schema.json"
)
GENERATOR_PATH = pathlib.Path(__file__).resolve()
V4_CONTRACT_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "subagent-contracts/"
    "fp-mapped-artifact-profile-inventory-tool-dependency-hardlink-fix-v4.json"
)
SUPERSEDED_RESULT_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/"
    "fp-mapped-artifact-profile-inventory-tool-v1/result.json"
)
SUPERSEDED_V2_RESULT_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/"
    "fp-mapped-artifact-profile-inventory-tool-v1/result-identity-v2.json"
)
SUPERSEDED_V2_RECEIPT_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/evidence/"
    "fp-mapped-artifact-profile-inventory-tool-v1/"
    "result-identity-v2.validation-receipt.json"
)
UNDISPATCHED_V3_CONTRACT_PATH = (
    REPO_ROOT
    / ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "subagent-contracts/"
    "fp-mapped-artifact-profile-inventory-tool-dependency-hardlink-fix-v3.json"
)

RESULT_KEYS = {
    "schema",
    "status",
    "scope",
    "design_id",
    "configuration_id",
    "profile",
    "clock",
    "lifecycle",
    "measurement_status",
    "physical_status",
    "canonical",
    "champion",
    "registry_projection",
    "source_receipts",
    "superseded_result",
    "superseded_v2_result",
    "undispatched_v3_contract",
    "execution_boundary",
    "unknowns",
    "scope_extension_request",
    "confidence",
}


class ToolResultError(RuntimeError):
    """A fail-closed identity, schema, or detached-receipt error."""


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return sha256_bytes(canonical_bytes(value))


def read_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ToolResultError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ToolResultError(f"JSON root must be an object: {path}")
    return value


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    raw = path if path.is_absolute() else pathlib.Path.cwd() / path
    if raw.is_symlink():
        raise ToolResultError(f"refusing symlink output: {raw}")
    raw.parent.mkdir(parents=True, exist_ok=True)
    resolved_parent = raw.parent.resolve(strict=True)
    if raw.parent != resolved_parent:
        raise ToolResultError(f"refusing aliased output directory: {raw.parent}")
    output = resolved_parent / raw.name
    output.write_text(
        json.dumps(value, allow_nan=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def strict_file(path: pathlib.Path, *, label: str) -> pathlib.Path:
    raw = path if path.is_absolute() else REPO_ROOT / path
    if raw.is_symlink():
        raise ToolResultError(f"{label} must not be a symlink: {raw}")
    try:
        resolved = raw.resolve(strict=True)
    except OSError as exc:
        raise ToolResultError(f"{label} is missing or unreadable: {raw}: {exc}") from exc
    if raw != resolved or not resolved.is_file():
        raise ToolResultError(f"{label} is not a canonical regular file: {raw}")
    return resolved


def artifact_receipt(path: pathlib.Path, *, label: str) -> dict[str, Any]:
    resolved = strict_file(path, label=label)
    try:
        recorded_path = resolved.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        recorded_path = resolved.as_posix()
    return {
        "path": recorded_path,
        "sha256": sha256_file(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def validate_result_schema_contract(
    schema_path: pathlib.Path = RESULT_SCHEMA_PATH,
) -> dict[str, Any]:
    receipt = artifact_receipt(schema_path, label="result schema")
    if receipt["sha256"] != EXPECTED_RESULT_SCHEMA_SHA256:
        raise ToolResultError(
            "result schema SHA-256 drifted: "
            f"expected={EXPECTED_RESULT_SCHEMA_SHA256} actual={receipt['sha256']}"
        )
    schema = read_json(strict_file(schema_path, label="result schema"))
    if (
        schema.get("$id") != "fp-mapped-artifact-profile-tool-result-v1.schema.json"
        or schema.get("additionalProperties") is not False
        or set(schema.get("required", [])) != RESULT_KEYS
        or schema.get("properties", {}).get("configuration_id", {}).get("const")
        != EXPECTED_CONFIGURATION_ID
        or schema.get("properties", {}).get("profile", {}).get("const")
        != EXPECTED_PROFILE
    ):
        raise ToolResultError("result schema identity contract drifted")
    return receipt


def registry_identity(
    configuration_id: str,
    *,
    registry_path: pathlib.Path = REGISTRY_PATH,
) -> tuple[dict[str, Any], dict[str, Any]]:
    catalog = read_json(strict_file(registry_path, label="Architecture Registry"))
    try:
        configuration = registry.selected_physical_configuration(
            catalog, configuration_id
        )
    except registry.RegistryError as exc:
        raise ToolResultError(str(exc)) from exc
    if configuration_id != EXPECTED_CONFIGURATION_ID:
        raise ToolResultError(
            "FP result physical configuration is not the canonical Registry key: "
            f"{configuration_id}"
        )
    profile = configuration.get("mapped_artifact_profile")
    if profile != EXPECTED_PROFILE:
        raise ToolResultError(
            f"FP result mapped artifact profile drifted: {profile!r}"
        )
    expected_state = {
        "source_lifecycle": "development",
        "measurement_status": "UNMEASURED",
        "physical_status": "GAP",
        "canonical": False,
        "champion": False,
    }
    for field, expected in expected_state.items():
        if configuration.get(field) != expected:
            raise ToolResultError(
                f"FP Registry physical state drifted: {field}={configuration.get(field)!r}"
            )
    contract = catalog.get("run_parameter_contract")
    design_id = (
        contract.get("expected_rtl_design_id")
        if isinstance(contract, dict)
        else None
    )
    if design_id != EXPECTED_DESIGN_ID:
        raise ToolResultError(f"FP Registry design identity drifted: {design_id!r}")
    return catalog, configuration


def build_result(
    *,
    configuration_id: str = EXPECTED_CONFIGURATION_ID,
    registry_path: pathlib.Path = REGISTRY_PATH,
    registry_schema_path: pathlib.Path = REGISTRY_SCHEMA_PATH,
    registry_tool_path: pathlib.Path = REGISTRY_TOOL_PATH,
    result_schema_path: pathlib.Path = RESULT_SCHEMA_PATH,
    generator_path: pathlib.Path = GENERATOR_PATH,
    contract_path: pathlib.Path = V4_CONTRACT_PATH,
    superseded_result_path: pathlib.Path = SUPERSEDED_RESULT_PATH,
    superseded_v2_result_path: pathlib.Path = SUPERSEDED_V2_RESULT_PATH,
    superseded_v2_receipt_path: pathlib.Path = SUPERSEDED_V2_RECEIPT_PATH,
    undispatched_v3_contract_path: pathlib.Path = UNDISPATCHED_V3_CONTRACT_PATH,
) -> dict[str, Any]:
    catalog, configuration = registry_identity(
        configuration_id, registry_path=registry_path
    )
    profile = str(configuration["mapped_artifact_profile"])
    schema_receipt = validate_result_schema_contract(result_schema_path)
    registry_receipt = artifact_receipt(
        registry_path, label="Architecture Registry"
    )
    registry_schema_receipt = artifact_receipt(
        registry_schema_path, label="Architecture Registry schema"
    )
    registry_tool = strict_file(
        registry_tool_path, label="imported Architecture Registry tool"
    )
    imported_registry_tool = pathlib.Path(registry.__file__).resolve(strict=True)
    if registry_tool != imported_registry_tool:
        raise ToolResultError(
            "bound Architecture Registry tool differs from the imported dependency: "
            f"bound={registry_tool} imported={imported_registry_tool}"
        )
    registry_tool_receipt = artifact_receipt(
        registry_tool, label="imported Architecture Registry tool"
    )
    generator_receipt = artifact_receipt(generator_path, label="result generator")
    contract_receipt = artifact_receipt(contract_path, label="v4 task contract")
    if contract_receipt["sha256"] != EXPECTED_V4_CONTRACT_SHA256:
        raise ToolResultError("v4 task contract SHA-256 drifted")
    superseded_receipt = artifact_receipt(
        superseded_result_path, label="superseded v1 result"
    )
    if superseded_receipt["sha256"] != SUPERSEDED_RESULT_SHA256:
        raise ToolResultError(
            "superseded v1 result identity drifted: "
            f"expected={SUPERSEDED_RESULT_SHA256} "
            f"actual={superseded_receipt['sha256']}"
        )
    superseded = read_json(
        strict_file(superseded_result_path, label="superseded v1 result")
    )
    superseded_configuration = superseded.get("physical_configuration")
    recorded_value = (
        superseded_configuration.get("configuration_id")
        if isinstance(superseded_configuration, dict)
        else None
    )
    if recorded_value != EXPECTED_PROFILE:
        raise ToolResultError(
            "superseded v1 result no longer contains the bound identity error"
        )
    superseded_v2_result_receipt = artifact_receipt(
        superseded_v2_result_path, label="superseded v2 result"
    )
    if superseded_v2_result_receipt["sha256"] != SUPERSEDED_V2_RESULT_SHA256:
        raise ToolResultError("superseded v2 result SHA-256 drifted")
    superseded_v2 = read_json(
        strict_file(superseded_v2_result_path, label="superseded v2 result")
    )
    if (
        superseded_v2.get("configuration_id") != EXPECTED_CONFIGURATION_ID
        or superseded_v2.get("profile") != EXPECTED_PROFILE
        or superseded_v2.get("physical_status") != "GAP"
    ):
        raise ToolResultError("superseded v2 result identity/state drifted")
    superseded_v2_receipt_receipt = artifact_receipt(
        superseded_v2_receipt_path, label="superseded v2 validation receipt"
    )
    if superseded_v2_receipt_receipt["sha256"] != SUPERSEDED_V2_RECEIPT_SHA256:
        raise ToolResultError("superseded v2 validation receipt SHA-256 drifted")
    superseded_v2_validation = read_json(
        strict_file(
            superseded_v2_receipt_path,
            label="superseded v2 validation receipt",
        )
    )
    if superseded_v2_validation.get("receipt_id") != SUPERSEDED_V2_RECEIPT_ID:
        raise ToolResultError("superseded v2 validation receipt ID drifted")
    v3_contract_receipt = artifact_receipt(
        undispatched_v3_contract_path, label="undispatched v3 contract"
    )
    if v3_contract_receipt["sha256"] != UNDISPATCHED_V3_CONTRACT_SHA256:
        raise ToolResultError("undispatched v3 contract SHA-256 drifted")
    v3_contract = read_json(
        strict_file(undispatched_v3_contract_path, label="undispatched v3 contract")
    )
    v3_deliverables = v3_contract.get("deliverables")
    if (
        v3_contract.get("task_id")
        != "fp-mapped-artifact-profile-inventory-tool-dependency-hardlink-fix-v3"
        or not isinstance(v3_deliverables, list)
        or len(v3_deliverables) != 3
        or "使  的 canonical path" not in v3_deliverables[0]
        or "parser  实参" not in v3_deliverables[2]
    ):
        raise ToolResultError(
            "undispatched v3 contract no longer contains the bound semantic distortion"
        )
    identity = {
        "configuration_id": configuration_id,
        "profile": profile,
    }
    physical_configuration_sha256 = registry.physical_configuration_sha256(
        configuration_id, configuration
    )
    return {
        "schema": RESULT_SCHEMA,
        "status": "PASS",
        "scope": "TOOL_DEPENDENCY_HARDLINK_PASS_PPA_GAP",
        "design_id": EXPECTED_DESIGN_ID,
        "configuration_id": configuration_id,
        "profile": profile,
        "clock": {"name": "core_clock", "period_ns": 5.0},
        "lifecycle": configuration["source_lifecycle"],
        "measurement_status": configuration["measurement_status"],
        "physical_status": configuration["physical_status"],
        "canonical": configuration["canonical"],
        "champion": configuration["champion"],
        "registry_projection": {
            "physical_configuration_sha256": physical_configuration_sha256,
            "configuration_profile_identity_sha256": canonical_sha256(identity),
            "artifact_family": list(registry.MAPPED_ARTIFACT_FILENAMES[profile]),
            "inline_modules": list(configuration["inline_modules"]),
            "expected_unknown_macro_instances": dict(
                configuration["expected_unknown_macro_instances"]
            ),
        },
        "source_receipts": {
            "architecture_registry": registry_receipt,
            "architecture_registry_schema": registry_schema_receipt,
            "architecture_registry_tool": registry_tool_receipt,
            "result_schema": schema_receipt,
            "generator": generator_receipt,
            "v4_contract": contract_receipt,
        },
        "superseded_result": {
            **superseded_receipt,
            "qualification": "SUPERSEDED_IDENTITY_ERROR",
            "identity_error_field": "physical_configuration.configuration_id",
            "recorded_value": recorded_value,
            "expected_value": EXPECTED_CONFIGURATION_ID,
        },
        "superseded_v2_result": {
            "qualification": "SUPERSEDED_DEPENDENCY_HARDLINK_GAP",
            "result": superseded_v2_result_receipt,
            "validation_receipt": superseded_v2_receipt_receipt,
            "receipt_id": SUPERSEDED_V2_RECEIPT_ID,
        },
        "undispatched_v3_contract": {
            **v3_contract_receipt,
            "qualification": "UNDISPATCHED_SEMANTIC_DISTORTION",
            "reason": (
                "shell command-substitution removed architecture_registry.py "
                "and --out-dir tokens from deliverables"
            ),
        },
        "execution_boundary": {
            "identity_path_unittest": "TARGETED_ONLY",
            "canonical_identity_gate": "GENERATE_VALIDATE_VERIFY",
            "scoped_audit": "NEW_AND_MODIFIED_PATHS_ONLY",
            "v2_gate": "NOT_RERUN",
            "prior_39_test_batch": "NOT_RERUN",
            "runner_bash_n": "NOT_RERUN",
            "production_synthesis": "NOT_RUN",
            "production_opensta": "NOT_RUN",
            "production_sta": "NOT_RUN",
            "production_parser_main": "NOT_RUN",
            "rtl_simulation": "NOT_RUN",
        },
        "unknowns": [
            "Real FP mapped cells, area, negative slack, and internal timing paths remain unmeasured.",
            "A future fresh run-id is still required before any NpcTop 5.0 ns mapped PPA claim.",
        ],
        "scope_extension_request": None,
        "confidence": {
            "tool_identity": "high",
            "physical_ppa": "none",
            "basis": (
                "Canonical Registry selection, imported Registry-tool dependency, "
                "strict result schema, detached hash receipt, and targeted hardlink/"
                "runner-path tests; no production EDA."
            ),
        },
    }


def validate_result(
    result: dict[str, Any],
    *,
    registry_path: pathlib.Path = REGISTRY_PATH,
    registry_schema_path: pathlib.Path = REGISTRY_SCHEMA_PATH,
    registry_tool_path: pathlib.Path = REGISTRY_TOOL_PATH,
    result_schema_path: pathlib.Path = RESULT_SCHEMA_PATH,
    generator_path: pathlib.Path = GENERATOR_PATH,
    contract_path: pathlib.Path = V4_CONTRACT_PATH,
    superseded_result_path: pathlib.Path = SUPERSEDED_RESULT_PATH,
    superseded_v2_result_path: pathlib.Path = SUPERSEDED_V2_RESULT_PATH,
    superseded_v2_receipt_path: pathlib.Path = SUPERSEDED_V2_RECEIPT_PATH,
    undispatched_v3_contract_path: pathlib.Path = UNDISPATCHED_V3_CONTRACT_PATH,
) -> None:
    if set(result) != RESULT_KEYS:
        raise ToolResultError(
            "result key set drifted: "
            f"missing={sorted(RESULT_KEYS - set(result))} "
            f"extra={sorted(set(result) - RESULT_KEYS)}"
        )
    configuration_id = result.get("configuration_id")
    if not isinstance(configuration_id, str):
        raise ToolResultError("result.configuration_id must be a string")
    expected = build_result(
        configuration_id=configuration_id,
        registry_path=registry_path,
        registry_schema_path=registry_schema_path,
        registry_tool_path=registry_tool_path,
        result_schema_path=result_schema_path,
        generator_path=generator_path,
        contract_path=contract_path,
        superseded_result_path=superseded_result_path,
        superseded_v2_result_path=superseded_v2_result_path,
        superseded_v2_receipt_path=superseded_v2_receipt_path,
        undispatched_v3_contract_path=undispatched_v3_contract_path,
    )
    if result != expected:
        changed = sorted(
            key for key in RESULT_KEYS if result.get(key) != expected.get(key)
        )
        raise ToolResultError(
            "result differs from the canonical Registry-generated value: "
            f"fields={changed}"
        )


def validate_result_file(
    result_path: pathlib.Path,
    **paths: pathlib.Path,
) -> dict[str, Any]:
    resolved = strict_file(result_path, label="final identity result")
    result = read_json(resolved)
    validate_result(result, **paths)
    return result


def build_validation_receipt(
    result_path: pathlib.Path,
    *,
    registry_path: pathlib.Path = REGISTRY_PATH,
    registry_schema_path: pathlib.Path = REGISTRY_SCHEMA_PATH,
    registry_tool_path: pathlib.Path = REGISTRY_TOOL_PATH,
    result_schema_path: pathlib.Path = RESULT_SCHEMA_PATH,
    generator_path: pathlib.Path = GENERATOR_PATH,
    contract_path: pathlib.Path = V4_CONTRACT_PATH,
    superseded_result_path: pathlib.Path = SUPERSEDED_RESULT_PATH,
    superseded_v2_result_path: pathlib.Path = SUPERSEDED_V2_RESULT_PATH,
    superseded_v2_receipt_path: pathlib.Path = SUPERSEDED_V2_RECEIPT_PATH,
    undispatched_v3_contract_path: pathlib.Path = UNDISPATCHED_V3_CONTRACT_PATH,
) -> dict[str, Any]:
    path_args = {
        "registry_path": registry_path,
        "registry_schema_path": registry_schema_path,
        "registry_tool_path": registry_tool_path,
        "result_schema_path": result_schema_path,
        "generator_path": generator_path,
        "contract_path": contract_path,
        "superseded_result_path": superseded_result_path,
        "superseded_v2_result_path": superseded_v2_result_path,
        "superseded_v2_receipt_path": superseded_v2_receipt_path,
        "undispatched_v3_contract_path": undispatched_v3_contract_path,
    }
    result = validate_result_file(result_path, **path_args)
    core = {
        "schema": VALIDATION_RECEIPT_SCHEMA,
        "status": "PASS",
        "configuration_id": result["configuration_id"],
        "profile": result["profile"],
        "artifacts": {
            "result": artifact_receipt(result_path, label="final identity result"),
            "result_schema": artifact_receipt(
                result_schema_path, label="result schema"
            ),
            "architecture_registry": artifact_receipt(
                registry_path, label="Architecture Registry"
            ),
            "architecture_registry_schema": artifact_receipt(
                registry_schema_path, label="Architecture Registry schema"
            ),
            "architecture_registry_tool": artifact_receipt(
                registry_tool_path, label="imported Architecture Registry tool"
            ),
            "generator": artifact_receipt(generator_path, label="result generator"),
            "v4_contract": artifact_receipt(contract_path, label="v4 task contract"),
        },
    }
    return {**core, "receipt_id": f"sha256:{canonical_sha256(core)}"}


def validate_validation_receipt(
    receipt: dict[str, Any],
    result_path: pathlib.Path,
    **paths: pathlib.Path,
) -> None:
    expected = build_validation_receipt(result_path, **paths)
    if receipt != expected:
        raise ToolResultError("detached validation receipt or bound artifact SHA drifted")


def command_generate(args: argparse.Namespace) -> int:
    result = build_result(configuration_id=args.physical_configuration)
    write_json(args.output, result)
    print(
        "[FP-MAPPED-TOOL-IDENTITY][GENERATED] "
        f"configuration={result['configuration_id']} profile={result['profile']}"
    )
    return 0


def command_validate(args: argparse.Namespace) -> int:
    receipt = build_validation_receipt(args.result)
    write_json(args.receipt, receipt)
    print(
        "[FP-MAPPED-TOOL-IDENTITY][VALIDATED] "
        f"configuration={receipt['configuration_id']} profile={receipt['profile']} "
        f"receipt={receipt['receipt_id']}"
    )
    return 0


def command_verify(args: argparse.Namespace) -> int:
    receipt = read_json(strict_file(args.receipt, label="validation receipt"))
    validate_validation_receipt(receipt, args.result)
    print(
        "[FP-MAPPED-TOOL-IDENTITY][RECEIPT-PASS] "
        f"configuration={receipt['configuration_id']} profile={receipt['profile']}"
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    generate = subparsers.add_parser("generate")
    generate.add_argument(
        "--physical-configuration",
        required=True,
    )
    generate.add_argument("--output", type=pathlib.Path, required=True)
    generate.set_defaults(function=command_generate)

    validate = subparsers.add_parser("validate")
    validate.add_argument("--result", type=pathlib.Path, required=True)
    validate.add_argument("--receipt", type=pathlib.Path, required=True)
    validate.set_defaults(function=command_validate)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--result", type=pathlib.Path, required=True)
    verify.add_argument("--receipt", type=pathlib.Path, required=True)
    verify.set_defaults(function=command_verify)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        return int(args.function(args))
    except (ToolResultError, OSError, UnicodeError, ValueError) as exc:
        print(f"[FP-MAPPED-TOOL-IDENTITY][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
