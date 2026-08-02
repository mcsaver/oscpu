#!/usr/bin/env python3
"""Audit the elaborated NpcTop instance graph for ProducerId holders.

The source-level holder census deliberately treats a Verilog module definition
as one declaration site.  This companion proves how many live instances of
every holder-bearing module exist under the canonical ``NpcTop`` product
configuration.  It does not claim holder lifecycle semantics; those remain a
separate dynamic obligation.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable


SCHEMA = "rv64-producer-holder-instance-graph-v1"
RECEIPT_SCHEMA = "rv64-producer-holder-instance-graph-receipt-v1"
CONFIG_SCHEMA = "npc-rv64-product-rtl-config-v1"
TOP_MODULE = "NpcTop"
CLAIM_BOUNDARY = (
    "Current product NpcTop holder-module instance multiplicity only; "
    "field semantics, lifecycle semantics, whole architecture and PPA "
    "are not promoted by this result."
)
EVIDENCE_KINDS = {
    "result": "holder_instance_graph_result",
    "receipt": "holder_instance_graph_receipt",
    "full": "holder_instance_graph_yosys_canonical_full_json_gzip",
    "script": "holder_instance_graph_yosys_script",
    "log": "holder_instance_graph_yosys_log",
}
EVIDENCE_BASENAMES = {
    "result": "holder-instance-graph.json",
    "receipt": "yosys-instance-graph-receipt.json",
    "full": "yosys-instance-graph.full.json.gz",
    "script": "yosys-instance-graph.ys",
    "log": "yosys-instance-graph.log",
}
EVIDENCE_DIRECTORY = "current-holder-instance-graph"
# Compatibility name for callers that only need the primary result kind.
EVIDENCE_KIND = EVIDENCE_KINDS["result"]
YOSYS_JSON_PLACEHOLDER = "__RV64_HOLDER_INSTANCE_GRAPH_JSON_OUT__"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
TASK_RUN_ID_RE = re.compile(
    r"^[0-9]{4}-[0-9]{2}-[0-9]{2}-rv64-[a-z0-9][a-z0-9-]*$"
)
YOSYS_EPHEMERAL_KEY_RE = re.compile(
    r"(?<=\$)0x[0-9a-fA-F]+(?=:)"
)
RESULT_KEYS = {
    "schema_version",
    "status",
    "claim_boundary",
    "design_id",
    "top_module",
    "counts",
    "instance_counts",
    "bindings",
    "graph",
    "errors",
}
BINDING_KEYS = {
    "source_set_sha256",
    "source_files",
    "elaboration_sources",
    "elaboration_source_list_sha256",
    "product_config",
    "instance_declaration_sha256",
    "tool_sha256",
    "elaborator",
    "elaborator_full_json_sha256",
    "elaborator_script_sha256",
    "elaborator_log_sha256",
}
ELABORATOR_KEYS = {
    "name",
    "path",
    "version",
    "version_output_sha256",
    "executable_sha256",
    "source_count",
}
COUNT_KEYS = {
    "holder_modules",
    "holder_instances",
    "duplicate_holder_modules",
    "reachable_module_instances",
}
GRAPH_KEYS = {"sha256", "reachable_instances", "holder_instances"}
RECEIPT_KEYS = {
    "schema_version",
    "status",
    "claim_boundary",
    "design_id",
    "top_module",
    "elaborator",
    "source_list",
    "source_list_sha256",
    "script_sha256",
    "log_sha256",
    "full_yosys_json_sha256",
    "reachable_graph_sha256",
    "reachable_instances",
}
HOLDER_SECTIONS = (
    "direct_full_p_fields",
    "combinational_full_p_regs",
    "generation_authorities",
    "token_q_fields",
    "packed_full_p_stages",
    "token_set_holders",
)
CONFIG_PATH = "npc/rv64/configs/product-rtl-defaults.mk"
MAKEFILE_PATH = "npc/rv64/Makefile"
EXPECTED_CONFIG_DEFINES = {
    "OOO_CSR_QUEUE_HEAD": "1",
    "OOO_TERMINAL_HOLDER_ASSERT": "1",
}
RTL_SUFFIXES = {".v", ".sv", ".vh", ".svh", ".mk"}


def evidence_paths_for_run(run_id: str) -> dict[str, str]:
    """Return the exact five-role path set for one RV64 task-run."""
    if TASK_RUN_ID_RE.fullmatch(run_id) is None:
        raise ValueError(f"invalid RV64 task-run id: {run_id!r}")
    root = (
        f".github/task-runs/{run_id}/evidence/{EVIDENCE_DIRECTORY}"
    )
    return {
        role: f"{root}/{basename}"
        for role, basename in EVIDENCE_BASENAMES.items()
    }


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_sha256(value: Any) -> str:
    payload = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return sha256_bytes(payload)


def deterministic_gzip(data: bytes) -> bytes:
    output = io.BytesIO()
    with gzip.GzipFile(
        fileobj=output,
        mode="wb",
        filename="",
        mtime=0,
    ) as handle:
        handle.write(data)
    return output.getvalue()


def decompress_gzip(data: bytes) -> bytes:
    with gzip.GzipFile(fileobj=io.BytesIO(data), mode="rb") as handle:
        return handle.read()


def _normalize_yosys_ephemeral_keys(value: Any) -> Any:
    if isinstance(value, list):
        return [_normalize_yosys_ephemeral_keys(item) for item in value]
    if not isinstance(value, dict):
        return value
    normalized: dict[str, Any] = {}
    for key, item in value.items():
        normalized_key = YOSYS_EPHEMERAL_KEY_RE.sub(
            "0xADDR", key
        )
        if normalized_key in normalized:
            raise ValueError(
                "Yosys ephemeral-key canonicalization produced a collision: "
                f"{normalized_key}"
            )
        normalized[normalized_key] = _normalize_yosys_ephemeral_keys(item)
    return normalized


def canonicalize_full_yosys_json(data: bytes) -> bytes:
    """Preserve full JSON while normalizing process-local Yosys key tokens."""
    try:
        value = json.loads(data.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"full Yosys JSON is invalid: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError("full Yosys JSON root must be an object")
    value = _normalize_yosys_ephemeral_keys(value)
    payload = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    )
    return payload.encode("utf-8") + b"\n"


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return value


def rtl_binding(repo_root: Path) -> tuple[str, dict[str, str]]:
    source_root = repo_root / "npc/rv64/vsrc"
    files = sorted(
        path for path in source_root.rglob("*")
        if path.is_file() and path.suffix.lower() in RTL_SUFFIXES
    )
    if not files:
        raise ValueError("RTL source set is empty")
    entries = {
        path.relative_to(repo_root).as_posix(): sha256_file(path)
        for path in files
    }
    return canonical_sha256(entries), entries


def _parse_make_assignment(text: str, name: str) -> str | None:
    match = re.search(
        rf"(?m)^\s*{re.escape(name)}\s*(?:\?=|:=|=)\s*([^\s#]+)",
        text,
    )
    return match.group(1) if match else None


def config_binding(repo_root: Path) -> dict[str, Any]:
    config_path = repo_root / CONFIG_PATH
    config_text = config_path.read_text(encoding="utf-8")
    schema = _parse_make_assignment(
        config_text, "NPC_PRODUCT_RTL_CONFIG_SCHEMA"
    )
    defines = {
        name: _parse_make_assignment(config_text, name)
        for name in sorted(EXPECTED_CONFIG_DEFINES)
    }
    return {
        "schema": schema,
        "defines": defines,
        "inputs": [
            {
                "path": CONFIG_PATH,
                "sha256": sha256_file(config_path),
            },
        ],
    }


def holder_modules(manifest: dict[str, Any]) -> set[str]:
    modules: set[str] = set()
    for section in HOLDER_SECTIONS:
        rows = manifest.get(section)
        if not isinstance(rows, list):
            continue
        for row in rows:
            if isinstance(row, dict) and isinstance(row.get("module"), str):
                modules.add(row["module"])
    return modules


def original_module_name(elaborated_type: str) -> str:
    """Return the source module name from a Yosys parameterized type."""
    if elaborated_type.startswith("$paramod") and "\\" in elaborated_type:
        parts = elaborated_type.split("\\")
        if len(parts) >= 2 and parts[1]:
            return parts[1]
    return elaborated_type


def reachable_instances(
    yosys_json: dict[str, Any], top_module: str
) -> list[dict[str, str]]:
    modules = yosys_json.get("modules")
    if not isinstance(modules, dict) or top_module not in modules:
        raise ValueError(f"elaborated graph lacks top module {top_module}")
    records: list[dict[str, str]] = []

    def walk(module_type: str, parent_path: str, ancestors: tuple[str, ...]) -> None:
        if module_type in ancestors:
            raise ValueError(
                "recursive module hierarchy: "
                + " -> ".join((*ancestors, module_type))
            )
        module = modules.get(module_type)
        cells = module.get("cells") if isinstance(module, dict) else None
        if not isinstance(cells, dict):
            return
        for instance, cell in sorted(cells.items()):
            elaborated_type = cell.get("type") if isinstance(cell, dict) else None
            if not isinstance(elaborated_type, str) or elaborated_type not in modules:
                continue
            path = f"{parent_path}.{instance}"
            records.append({
                "module": original_module_name(elaborated_type),
                "path": path,
                "elaborated_type": elaborated_type,
            })
            walk(elaborated_type, path, (*ancestors, module_type))

    walk(top_module, top_module, ())
    return sorted(records, key=lambda row: (row["path"], row["module"]))


def declared_instances(
    manifest: dict[str, Any], errors: list[str]
) -> tuple[dict[str, Any] | None, list[dict[str, str]]]:
    declaration = manifest.get("elaborated_instance_graph")
    if not isinstance(declaration, dict):
        errors.append("elaborated_instance_graph must be an object")
        return None, []
    if set(declaration) != {
        "schema_version", "top_module", "product_config", "instances",
        "evidence",
    }:
        errors.append("elaborated_instance_graph keys are incomplete or drifted")
    if declaration.get("schema_version") != SCHEMA:
        errors.append(f"instance graph schema_version must be {SCHEMA}")
    if declaration.get("top_module") != TOP_MODULE:
        errors.append(f"instance graph top_module must be {TOP_MODULE}")
    rows = declaration.get("instances")
    if not isinstance(rows, list):
        errors.append("elaborated_instance_graph.instances must be a list")
        return declaration, []
    normalized: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for index, row in enumerate(rows):
        if not isinstance(row, dict) or set(row) != {"module", "path"}:
            errors.append(
                f"elaborated_instance_graph.instances[{index}] "
                "must contain exact module/path keys"
            )
            continue
        module = row.get("module")
        path = row.get("path")
        if not isinstance(module, str) or not module:
            errors.append(f"instance[{index}].module must be non-empty")
            continue
        if not isinstance(path, str) or not path.startswith(f"{TOP_MODULE}."):
            errors.append(
                f"instance[{index}].path must descend from {TOP_MODULE}"
            )
            continue
        key = (module, path)
        if key in seen:
            errors.append(f"duplicate declared holder instance: {module}::{path}")
            continue
        seen.add(key)
        normalized.append({"module": module, "path": path})
    return declaration, sorted(
        normalized, key=lambda row: (row["module"], row["path"])
    )


def validate_config_declaration(
    repo_root: Path,
    declaration: dict[str, Any] | None,
    errors: list[str],
) -> dict[str, Any] | None:
    if not isinstance(declaration, dict):
        return None
    declared = declaration.get("product_config")
    if not isinstance(declared, dict) or set(declared) != {
        "schema", "defines", "inputs",
    }:
        errors.append(
            "elaborated_instance_graph.product_config keys are incomplete or drifted"
        )
        return None
    observed = config_binding(repo_root)
    if observed["schema"] != CONFIG_SCHEMA:
        errors.append(f"live product config schema must be {CONFIG_SCHEMA}")
    if observed["defines"] != EXPECTED_CONFIG_DEFINES:
        errors.append(
            "live product config defines drifted: "
            f"observed={observed['defines']}"
        )
    if declared != observed:
        errors.append("declared product config differs from live bound inputs")
    return observed


def compare_holder_instances(
    actual: Iterable[dict[str, str]],
    declared: Iterable[dict[str, str]],
    modules: set[str],
    errors: list[str],
) -> None:
    actual_pairs = {
        (row["module"], row["path"])
        for row in actual
        if row["module"] in modules
    }
    declared_pairs = {
        (row["module"], row["path"])
        for row in declared
    }
    declared_modules = {module for module, _ in declared_pairs}
    for module in sorted(declared_modules - modules):
        errors.append(f"declared instance module is not a census holder: {module}")
    for module in sorted(modules - declared_modules):
        errors.append(f"census holder module lacks declared instance: {module}")
    for module, path in sorted(actual_pairs - declared_pairs):
        errors.append(f"undeclared live holder instance: {module}::{path}")
    for module, path in sorted(declared_pairs - actual_pairs):
        errors.append(f"stale/nonexistent holder instance: {module}::{path}")


def synth_source_records(repo_root: Path) -> list[dict[str, str]]:
    """Return the exact ordered source list consumed by canonical Yosys."""
    root = repo_root.resolve()
    records: list[dict[str, str]] = []
    seen: set[str] = set()
    for source in _synth_sources(root):
        resolved = source.resolve()
        try:
            relative = resolved.relative_to(root).as_posix()
        except ValueError as exc:
            raise ValueError(
                f"synthesis source escapes repository: {resolved}"
            ) from exc
        if not relative or any(char.isspace() for char in relative):
            raise ValueError(
                f"synthesis source path is empty or contains whitespace: {relative!r}"
            )
        if relative in seen:
            raise ValueError(f"duplicate synthesis source: {relative}")
        seen.add(relative)
        records.append({
            "path": relative,
            "sha256": sha256_file(resolved),
        })
    if not records:
        raise ValueError("canonical synthesis source list is empty")
    return records


def canonical_yosys_script(
    source_records: list[dict[str, str]],
) -> str:
    """Build a path-stable script whose output path is an explicit placeholder."""
    include_paths = (
        "npc/rv64/vsrc",
        "npc/rv64/vsrc/include",
    )
    source_paths: list[str] = []
    for index, row in enumerate(source_records):
        if not isinstance(row, dict) or set(row) != {"path", "sha256"}:
            raise ValueError(
                f"elaboration source[{index}] must contain exact path/sha256 keys"
            )
        path = row.get("path")
        digest = row.get("sha256")
        if not isinstance(path, str) or not path or any(
            char.isspace() for char in path
        ):
            raise ValueError(
                f"elaboration source[{index}].path is invalid"
            )
        if not isinstance(digest, str) or SHA256_RE.fullmatch(digest) is None:
            raise ValueError(
                f"elaboration source[{index}].sha256 is invalid"
            )
        source_paths.append(path)
    read_parts = [
        "read_verilog",
        "-sv",
        *(f"-I {path}" for path in include_paths),
        *(f"-D {name}={value}"
          for name, value in sorted(EXPECTED_CONFIG_DEFINES.items())),
        *source_paths,
    ]
    return (
        " ".join(read_parts)
        + f"\nhierarchy -check -top {TOP_MODULE}\n"
        + "proc\n"
        + f"write_json {YOSYS_JSON_PLACEHOLDER}\n"
    )


def _validate_elaborator(
    value: Any,
    expected_source_count: int,
    errors: list[str],
    *,
    prefix: str,
) -> dict[str, Any] | None:
    if not isinstance(value, dict) or set(value) != ELABORATOR_KEYS:
        errors.append(f"{prefix} must contain the exact elaborator key set")
        return None
    if value.get("name") != "yosys":
        errors.append(f"{prefix}.name must be yosys")
    path = value.get("path")
    if not isinstance(path, str) or not path or "\x00" in path:
        errors.append(f"{prefix}.path must be non-empty")
    version = value.get("version")
    if not isinstance(version, str) or not version.strip():
        errors.append(f"{prefix}.version must be non-empty")
    for field in ("version_output_sha256", "executable_sha256"):
        digest = value.get(field)
        if not isinstance(digest, str) or SHA256_RE.fullmatch(digest) is None:
            errors.append(f"{prefix}.{field} must be lowercase SHA-256")
    if value.get("source_count") != expected_source_count:
        errors.append(
            f"{prefix}.source_count must equal {expected_source_count}"
        )
    return value


def _validate_instance_rows(
    value: Any,
    errors: list[str],
    *,
    field: str,
    sort_key: Any,
) -> list[dict[str, str]]:
    if not isinstance(value, list):
        errors.append(f"{field} must be a list")
        return []
    rows: list[dict[str, str]] = []
    seen_paths: set[str] = set()
    for index, row in enumerate(value):
        if not isinstance(row, dict) or set(row) != {
            "module", "path", "elaborated_type",
        }:
            errors.append(
                f"{field}[{index}] must contain exact "
                "module/path/elaborated_type keys"
            )
            continue
        module = row.get("module")
        path = row.get("path")
        elaborated_type = row.get("elaborated_type")
        if not all(
            isinstance(item, str) and item
            for item in (module, path, elaborated_type)
        ):
            errors.append(f"{field}[{index}] contains an empty string")
            continue
        if not path.startswith(f"{TOP_MODULE}."):
            errors.append(f"{field}[{index}].path is outside {TOP_MODULE}")
            continue
        if path in seen_paths:
            errors.append(f"{field} contains duplicate path: {path}")
            continue
        seen_paths.add(path)
        rows.append({
            "module": module,
            "path": path,
            "elaborated_type": elaborated_type,
        })
    if rows != sorted(rows, key=sort_key):
        errors.append(f"{field} is not in canonical order")
    return rows


def _expected_counts(
    modules: set[str],
    reachable: list[dict[str, str]],
    holder_rows: list[dict[str, str]],
) -> tuple[dict[str, int], dict[str, int]]:
    instance_counts = {
        module: sum(row["module"] == module for row in holder_rows)
        for module in sorted(modules)
    }
    counts = {
        "holder_modules": len(modules),
        "holder_instances": len(holder_rows),
        "duplicate_holder_modules": sum(
            count > 1 for count in instance_counts.values()
        ),
        "reachable_module_instances": len(reachable),
    }
    return counts, instance_counts


def build_receipt(
    result: dict[str, Any],
    full_yosys_json: bytes,
) -> dict[str, Any]:
    """Create a receipt directly from the canonical full Yosys JSON."""
    bindings = result.get("bindings")
    graph = result.get("graph")
    if result.get("status") != "PASS" or not isinstance(bindings, dict) \
            or not isinstance(graph, dict):
        raise ValueError("cannot build receipt from a non-PASS result")
    try:
        full_value = json.loads(full_yosys_json.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"full Yosys JSON is invalid: {exc}") from exc
    if not isinstance(full_value, dict):
        raise ValueError("full Yosys JSON root must be an object")
    full_reachable = reachable_instances(full_value, TOP_MODULE)
    if full_reachable != graph.get("reachable_instances"):
        raise ValueError("full Yosys hierarchy differs from checker result")
    return {
        "schema_version": RECEIPT_SCHEMA,
        "status": "PASS",
        "claim_boundary": CLAIM_BOUNDARY,
        "design_id": result.get("design_id"),
        "top_module": TOP_MODULE,
        "elaborator": bindings.get("elaborator"),
        "source_list": bindings.get("elaboration_sources"),
        "source_list_sha256": bindings.get(
            "elaboration_source_list_sha256"
        ),
        "script_sha256": bindings.get("elaborator_script_sha256"),
        "log_sha256": bindings.get("elaborator_log_sha256"),
        "full_yosys_json_sha256": sha256_bytes(full_yosys_json),
        "reachable_graph_sha256": canonical_sha256(full_reachable),
        "reachable_instances": full_reachable,
    }


def audit_elaborated(
    repo_root: Path,
    manifest_path: Path,
    yosys_json_path: Path,
    *,
    elaborator: dict[str, Any] | None = None,
    elaboration_sources: list[dict[str, str]] | None = None,
    elaborator_full_json_sha256: str | None = None,
    elaborator_script_sha256: str | None = None,
    elaborator_log_sha256: str | None = None,
) -> dict[str, Any]:
    errors: list[str] = []
    manifest = load_json(manifest_path)
    yosys_json = load_json(yosys_json_path)
    declaration, declared = declared_instances(manifest, errors)
    observed_config = validate_config_declaration(
        repo_root, declaration, errors
    )
    modules = holder_modules(manifest)
    if not modules:
        errors.append("holder module set is empty")
    try:
        reachable = reachable_instances(yosys_json, TOP_MODULE)
    except ValueError as exc:
        errors.append(str(exc))
        reachable = []
    compare_holder_instances(reachable, declared, modules, errors)
    source_sha, source_files = rtl_binding(repo_root)
    live_elaboration_sources = synth_source_records(repo_root)
    if elaboration_sources != live_elaboration_sources:
        errors.append(
            "elaboration source list differs from live print-synth-rtl closure"
        )
    bound_elaboration_sources = (
        elaboration_sources
        if isinstance(elaboration_sources, list)
        else []
    )
    source_list_sha256 = canonical_sha256(bound_elaboration_sources)
    canonical_script_sha256 = sha256_bytes(
        canonical_yosys_script(live_elaboration_sources).encode("utf-8")
    )
    if elaborator_script_sha256 != canonical_script_sha256:
        errors.append("elaborator script SHA-256 is missing or non-canonical")
    if not isinstance(elaborator_full_json_sha256, str) or \
            SHA256_RE.fullmatch(elaborator_full_json_sha256) is None:
        errors.append(
            "elaborator canonical full JSON SHA-256 is missing or invalid"
        )
    if not isinstance(elaborator_log_sha256, str) or \
            SHA256_RE.fullmatch(elaborator_log_sha256) is None:
        errors.append("elaborator log SHA-256 is missing or invalid")
    _validate_elaborator(
        elaborator,
        len(live_elaboration_sources),
        errors,
        prefix="bindings.elaborator",
    )
    design_id = f"sha256:{source_sha}"
    if manifest.get("design_id") != design_id:
        errors.append("census design_id differs from live RTL source binding")
    holder_rows = sorted(
        (
            {
                "module": row["module"],
                "path": row["path"],
                "elaborated_type": row["elaborated_type"],
            }
            for row in reachable
            if row["module"] in modules
        ),
        key=lambda row: (row["module"], row["path"]),
    )
    counts, instance_counts = _expected_counts(
        modules, reachable, holder_rows
    )
    declaration_payload = {
        key: declaration.get(key)
        for key in (
            "schema_version", "top_module", "product_config", "instances"
        )
    } if isinstance(declaration, dict) else {}
    graph = {
        "sha256": canonical_sha256(reachable),
        "reachable_instances": reachable,
        "holder_instances": holder_rows,
    }
    return {
        "schema_version": SCHEMA,
        "status": "PASS" if not errors else "FAIL",
        "claim_boundary": CLAIM_BOUNDARY,
        "design_id": design_id,
        "top_module": TOP_MODULE,
        "counts": counts,
        "instance_counts": instance_counts,
        "bindings": {
            "source_set_sha256": source_sha,
            "source_files": source_files,
            "elaboration_sources": bound_elaboration_sources,
            "elaboration_source_list_sha256": source_list_sha256,
            "product_config": observed_config,
            "instance_declaration_sha256": canonical_sha256(
                declaration_payload
            ),
            "tool_sha256": sha256_file(Path(__file__).resolve()),
            "elaborator": elaborator,
            "elaborator_full_json_sha256": elaborator_full_json_sha256,
            "elaborator_script_sha256": elaborator_script_sha256,
            "elaborator_log_sha256": elaborator_log_sha256,
        },
        "graph": graph,
        "errors": errors,
    }


def _safe_evidence_path(repo_root: Path, relative: Any) -> Path | None:
    if not isinstance(relative, str) or not relative:
        return None
    candidate = (repo_root / relative).resolve()
    try:
        candidate.relative_to(repo_root.resolve())
    except ValueError:
        return None
    if not candidate.is_file() or candidate.is_symlink():
        return None
    return candidate


def _evidence_role_root(relative: Any, role: str) -> tuple[str | None, str | None]:
    if not isinstance(relative, str) or not relative:
        return None, "is empty"
    path = PurePosixPath(relative)
    parts = path.parts
    if path.is_absolute() or path.as_posix() != relative or any(
        part in {"", ".", ".."} for part in parts
    ):
        return None, "is not a canonical repository-relative path"
    if len(parts) != 6 or parts[:2] != (".github", "task-runs") or \
            parts[3:5] != ("evidence", EVIDENCE_DIRECTORY):
        return None, (
            "must match .github/task-runs/<rv64-run>/evidence/"
            f"{EVIDENCE_DIRECTORY}/<role-file>"
        )
    if TASK_RUN_ID_RE.fullmatch(parts[2]) is None:
        return None, "contains an invalid RV64 task-run id"
    if parts[5] != EVIDENCE_BASENAMES[role]:
        return None, f"must end with {EVIDENCE_BASENAMES[role]}"
    return "/".join(parts[:5]), None


def _load_evidence_bundle(
    repo_root: Path,
    evidence: Any,
    errors: list[str],
) -> tuple[dict[str, dict[str, str]], dict[str, Path]]:
    entries: dict[str, dict[str, str]] = {}
    paths: dict[str, Path] = {}
    if not isinstance(evidence, dict) or set(evidence) != set(EVIDENCE_KINDS):
        errors.append(
            "instance graph evidence must contain exact "
            "result/receipt/full/script/log roles"
        )
        return entries, paths
    seen_paths: set[str] = set()
    bundle_root: str | None = None
    for role, expected_kind in EVIDENCE_KINDS.items():
        entry = evidence.get(role)
        if not isinstance(entry, dict) or set(entry) != {
            "kind", "path", "sha256",
        }:
            errors.append(
                f"instance graph evidence.{role} must contain exact "
                "kind/path/sha256 keys"
            )
            continue
        if entry.get("kind") != expected_kind:
            errors.append(
                f"instance graph evidence.{role}.kind must be {expected_kind}"
            )
        relative = entry.get("path")
        if not isinstance(relative, str) or relative in seen_paths:
            errors.append(
                f"instance graph evidence.{role}.path is empty or duplicated"
            )
        else:
            seen_paths.add(relative)
        role_root, role_error = _evidence_role_root(relative, role)
        if role_error is not None:
            errors.append(
                f"instance graph evidence.{role}.path {role_error}"
            )
        elif bundle_root is None:
            bundle_root = role_root
        elif role_root != bundle_root:
            errors.append(
                "instance graph evidence roles must share one task-run "
                "evidence directory"
            )
        path = (
            _safe_evidence_path(repo_root, relative)
            if role_error is None else None
        )
        if path is None:
            errors.append(
                f"instance graph evidence.{role}.path is missing or unsafe"
            )
        else:
            digest = sha256_file(path)
            if entry.get("sha256") != digest:
                errors.append(
                    f"instance graph evidence.{role}.sha256 mismatch"
                )
            paths[role] = path
        entries[role] = entry
    return entries, paths


def _validate_frozen_result(
    *,
    repo_root: Path,
    manifest: dict[str, Any],
    declaration: dict[str, Any] | None,
    declared: list[dict[str, str]],
    observed_config: dict[str, Any] | None,
    result: dict[str, Any],
    source_sha: str,
    source_files: dict[str, str],
    live_elaboration_sources: list[dict[str, str]],
    full_reachable_instances: list[dict[str, str]],
    full_json_sha256: str | None,
    script_sha256: str | None,
    log_sha256: str | None,
    errors: list[str],
) -> dict[str, Any]:
    if set(result) != RESULT_KEYS:
        errors.append("frozen instance graph result key set drifted")
    design_id = f"sha256:{source_sha}"
    if result.get("schema_version") != SCHEMA:
        errors.append("frozen instance graph schema_version drifted")
    if result.get("status") != "PASS":
        errors.append("frozen instance graph result is not PASS")
    if result.get("claim_boundary") != CLAIM_BOUNDARY:
        errors.append("frozen instance graph claim boundary drifted")
    if result.get("design_id") != design_id:
        errors.append("frozen instance graph design_id is stale")
    if result.get("top_module") != TOP_MODULE:
        errors.append("frozen instance graph top_module drifted")
    if result.get("errors") != []:
        errors.append("frozen instance graph retains non-empty errors")

    modules = holder_modules(manifest)
    if not modules:
        errors.append("holder module set is empty")
    graph = result.get("graph")
    reachable: list[dict[str, str]] = []
    holder_rows: list[dict[str, str]] = []
    graph_sha256: str | None = None
    if not isinstance(graph, dict) or set(graph) != GRAPH_KEYS:
        errors.append("frozen instance graph payload key set drifted")
    else:
        reachable = _validate_instance_rows(
            graph.get("reachable_instances"),
            errors,
            field="graph.reachable_instances",
            sort_key=lambda row: (row["path"], row["module"]),
        )
        holder_rows = _validate_instance_rows(
            graph.get("holder_instances"),
            errors,
            field="graph.holder_instances",
            sort_key=lambda row: (row["module"], row["path"]),
        )
        graph_sha256 = canonical_sha256(reachable)
        if graph.get("sha256") != graph_sha256:
            errors.append("frozen reachable graph sha256 mismatch")
        expected_holder_rows = sorted(
            (
                row for row in reachable
                if row["module"] in modules
            ),
            key=lambda row: (row["module"], row["path"]),
        )
        if holder_rows != expected_holder_rows:
            errors.append("frozen holder subset differs from reachable graph")
        if reachable != full_reachable_instances:
            errors.append(
                "frozen result reachable graph differs from full Yosys JSON"
            )
        compare_holder_instances(
            expected_holder_rows, declared, modules, errors
        )

    expected_counts, expected_instance_counts = _expected_counts(
        modules, reachable, holder_rows
    )
    counts = result.get("counts")
    if not isinstance(counts, dict) or set(counts) != COUNT_KEYS:
        errors.append("frozen instance graph counts key set drifted")
    elif counts != expected_counts:
        errors.append("frozen instance graph counts differ from graph payload")
    instance_counts = result.get("instance_counts")
    if not isinstance(instance_counts, dict) or \
            instance_counts != expected_instance_counts:
        errors.append(
            "frozen instance_counts differ from holder graph payload"
        )

    declaration_payload = {
        key: declaration.get(key)
        for key in (
            "schema_version", "top_module", "product_config", "instances"
        )
    } if isinstance(declaration, dict) else {}
    bindings = result.get("bindings")
    if not isinstance(bindings, dict) or set(bindings) != BINDING_KEYS:
        errors.append("frozen instance graph bindings key set drifted")
    else:
        if bindings.get("source_set_sha256") != source_sha:
            errors.append("frozen instance graph source_set_sha256 is stale")
        if bindings.get("source_files") != source_files:
            errors.append("frozen instance graph source file closure is stale")
        if bindings.get("elaboration_sources") != live_elaboration_sources:
            errors.append(
                "frozen exact Yosys source list differs from print-synth-rtl"
            )
        if bindings.get("elaboration_source_list_sha256") != canonical_sha256(
            live_elaboration_sources
        ):
            errors.append("frozen Yosys source-list SHA-256 is stale")
        if bindings.get("product_config") != observed_config:
            errors.append("frozen instance graph product config is stale")
        if bindings.get("instance_declaration_sha256") != canonical_sha256(
            declaration_payload
        ):
            errors.append("frozen instance declaration binding is stale")
        if bindings.get("tool_sha256") != sha256_file(
            Path(__file__).resolve()
        ):
            errors.append("frozen instance graph tool binding is stale")
        if bindings.get("elaborator_full_json_sha256") != full_json_sha256:
            errors.append("frozen full Yosys JSON binding is stale")
        if bindings.get("elaborator_script_sha256") != script_sha256:
            errors.append("frozen Yosys script binding is stale")
        if bindings.get("elaborator_log_sha256") != log_sha256:
            errors.append("frozen Yosys log binding is stale")
        _validate_elaborator(
            bindings.get("elaborator"),
            len(live_elaboration_sources),
            errors,
            prefix="bindings.elaborator",
        )
    return {
        "counts": expected_counts,
        "graph_sha256": graph_sha256,
        "reachable_instances": reachable,
        "bindings": bindings,
    }


def _validate_frozen_receipt(
    *,
    receipt: dict[str, Any],
    result: dict[str, Any],
    validated_result: dict[str, Any],
    live_elaboration_sources: list[dict[str, str]],
    full_reachable_instances: list[dict[str, str]],
    full_json_sha256: str | None,
    script_sha256: str | None,
    log_sha256: str | None,
    errors: list[str],
) -> None:
    if set(receipt) != RECEIPT_KEYS:
        errors.append("frozen Yosys receipt key set drifted")
    if receipt.get("schema_version") != RECEIPT_SCHEMA:
        errors.append("frozen Yosys receipt schema_version drifted")
    if receipt.get("status") != "PASS":
        errors.append("frozen Yosys receipt is not PASS")
    if receipt.get("claim_boundary") != CLAIM_BOUNDARY:
        errors.append("frozen Yosys receipt claim boundary drifted")
    if receipt.get("design_id") != result.get("design_id"):
        errors.append("frozen Yosys receipt design_id differs from result")
    if receipt.get("top_module") != TOP_MODULE:
        errors.append("frozen Yosys receipt top_module drifted")
    if receipt.get("source_list") != live_elaboration_sources:
        errors.append("frozen Yosys receipt source list is stale")
    if receipt.get("source_list_sha256") != canonical_sha256(
        live_elaboration_sources
    ):
        errors.append("frozen Yosys receipt source-list SHA-256 is stale")
    if receipt.get("script_sha256") != script_sha256:
        errors.append("frozen Yosys receipt script SHA-256 is stale")
    if receipt.get("log_sha256") != log_sha256:
        errors.append("frozen Yosys receipt log SHA-256 is stale")
    if receipt.get("full_yosys_json_sha256") != full_json_sha256:
        errors.append("frozen Yosys receipt full JSON SHA-256 is stale")
    _validate_elaborator(
        receipt.get("elaborator"),
        len(live_elaboration_sources),
        errors,
        prefix="receipt.elaborator",
    )
    bindings = validated_result.get("bindings")
    if isinstance(bindings, dict) and \
            receipt.get("elaborator") != bindings.get("elaborator"):
        errors.append("frozen Yosys receipt elaborator differs from result")

    receipt_reachable = _validate_instance_rows(
        receipt.get("reachable_instances"),
        errors,
        field="receipt.reachable_instances",
        sort_key=lambda row: (row["path"], row["module"]),
    )
    expected_reachable = validated_result.get("reachable_instances")
    if receipt_reachable != expected_reachable:
        errors.append(
            "frozen Yosys receipt reachable graph differs from result"
        )
    if receipt_reachable != full_reachable_instances:
        errors.append(
            "frozen Yosys receipt reachable graph differs from full JSON"
        )
    expected_graph_sha = canonical_sha256(receipt_reachable)
    if receipt.get("reachable_graph_sha256") != expected_graph_sha:
        errors.append("frozen Yosys receipt graph SHA-256 mismatch")
    if receipt.get("reachable_graph_sha256") != validated_result.get(
        "graph_sha256"
    ):
        errors.append("frozen Yosys receipt graph binding differs from result")


def audit_frozen(
    repo_root: Path,
    manifest_path: Path,
) -> dict[str, Any]:
    errors: list[str] = []
    manifest = load_json(manifest_path)
    declaration, declared = declared_instances(manifest, errors)
    observed_config = validate_config_declaration(
        repo_root, declaration, errors
    )
    evidence = declaration.get("evidence") if isinstance(declaration, dict) else None
    evidence_entries, evidence_paths = _load_evidence_bundle(
        repo_root, evidence, errors
    )

    result: dict[str, Any] | None = None
    receipt: dict[str, Any] | None = None
    for role in ("result", "receipt"):
        path = evidence_paths.get(role)
        if path is None:
            continue
        try:
            value = load_json(path)
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
            errors.append(f"cannot read instance graph {role}: {exc}")
            continue
        if role == "result":
            result = value
        else:
            receipt = value

    full_reachable_instances: list[dict[str, str]] = []
    full_json_sha256: str | None = None
    full_path = evidence_paths.get("full")
    if full_path is not None:
        try:
            compressed_full = full_path.read_bytes()
            full_json = decompress_gzip(compressed_full)
            if compressed_full != deterministic_gzip(full_json):
                errors.append(
                    "frozen full Yosys JSON gzip bytes are non-canonical"
                )
            canonical_full = canonicalize_full_yosys_json(full_json)
            if full_json != canonical_full:
                errors.append(
                    "frozen full Yosys JSON map ordering is non-canonical"
                )
            full_json_sha256 = sha256_bytes(full_json)
            full_value = json.loads(full_json.decode("utf-8"))
            if not isinstance(full_value, dict):
                raise ValueError("full Yosys JSON root must be an object")
            full_reachable_instances = reachable_instances(
                full_value, TOP_MODULE
            )
        except (
            OSError,
            UnicodeError,
            gzip.BadGzipFile,
            EOFError,
            json.JSONDecodeError,
            ValueError,
        ) as exc:
            errors.append(f"cannot read full Yosys hierarchy JSON: {exc}")

    source_sha, source_files = rtl_binding(repo_root)
    design_id = f"sha256:{source_sha}"
    if manifest.get("design_id") != design_id:
        errors.append("census design_id differs from live RTL source binding")
    try:
        live_elaboration_sources = synth_source_records(repo_root)
        canonical_script = canonical_yosys_script(
            live_elaboration_sources
        ).encode("utf-8")
    except (OSError, ValueError) as exc:
        errors.append(f"cannot rebuild canonical Yosys inputs: {exc}")
        live_elaboration_sources = []
        canonical_script = b""
    script_path = evidence_paths.get("script")
    script_sha256 = (
        sha256_file(script_path) if script_path is not None else None
    )
    if script_path is not None and script_path.read_bytes() != canonical_script:
        errors.append(
            "frozen Yosys script differs from canonical live source closure"
        )
    log_path = evidence_paths.get("log")
    log_sha256 = sha256_file(log_path) if log_path is not None else None

    validated_result: dict[str, Any] = {
        "counts": None,
        "graph_sha256": None,
        "reachable_instances": [],
        "bindings": None,
    }
    if result is not None:
        validated_result = _validate_frozen_result(
            repo_root=repo_root,
            manifest=manifest,
            declaration=declaration,
            declared=declared,
            observed_config=observed_config,
            result=result,
            source_sha=source_sha,
            source_files=source_files,
            live_elaboration_sources=live_elaboration_sources,
            full_reachable_instances=full_reachable_instances,
            full_json_sha256=full_json_sha256,
            script_sha256=script_sha256,
            log_sha256=log_sha256,
            errors=errors,
        )
    if receipt is not None and result is not None:
        _validate_frozen_receipt(
            receipt=receipt,
            result=result,
            validated_result=validated_result,
            live_elaboration_sources=live_elaboration_sources,
            full_reachable_instances=full_reachable_instances,
            full_json_sha256=full_json_sha256,
            script_sha256=script_sha256,
            log_sha256=log_sha256,
            errors=errors,
        )
    elif receipt is None:
        errors.append("frozen Yosys receipt is missing")

    return {
        "schema_version": SCHEMA,
        "status": "PASS" if not errors else "FAIL",
        "design_id": design_id,
        "top_module": TOP_MODULE,
        "evidence": evidence_entries,
        "counts": validated_result.get("counts"),
        "graph_sha256": validated_result.get("graph_sha256"),
        "errors": errors,
    }


def _yosys_executable(repo_root: Path, requested: str | None) -> Path:
    if requested:
        candidate = Path(requested)
    else:
        bundled = repo_root / "oss-cad-suite/bin/yosys"
        candidate = bundled if bundled.is_file() else Path(
            shutil.which("yosys") or ""
        )
    if not candidate or not candidate.is_file():
        raise ValueError("Yosys executable is unavailable")
    return candidate.resolve()


def _synth_sources(repo_root: Path) -> list[Path]:
    completed = subprocess.run(
        ["make", "--no-print-directory", "-s",
         "-C", str(repo_root / "npc/rv64"),
         "print-synth-rtl"],
        check=False,
        capture_output=True,
        text=True,
        cwd=repo_root,
    )
    if completed.returncode != 0:
        raise ValueError(
            "print-synth-rtl failed: "
            + (completed.stderr.strip() or completed.stdout.strip())
        )
    paths = [Path(token).resolve() for token in completed.stdout.split()]
    if not paths or any(not path.is_file() for path in paths):
        raise ValueError("print-synth-rtl returned an invalid source list")
    return paths


def elaborate(
    repo_root: Path,
    *,
    yosys: str | None,
    timeout_seconds: int,
    work_dir: Path,
) -> tuple[
    Path,
    dict[str, Any],
    bytes,
    bytes,
    list[dict[str, str]],
]:
    executable = _yosys_executable(repo_root, yosys)
    version = subprocess.run(
        [str(executable), "-V"],
        check=False,
        capture_output=True,
        cwd=repo_root,
    )
    if version.returncode != 0:
        raise ValueError("Yosys version query failed")
    source_records = synth_source_records(repo_root)
    json_path = work_dir / "holder-instance-graph.yosys.json"
    script_path = work_dir / "holder-instance-graph.ys"
    canonical_script = canonical_yosys_script(source_records).encode(
        "utf-8"
    )
    runtime_script = canonical_script.decode("utf-8").replace(
        YOSYS_JSON_PLACEHOLDER,
        json_path.as_posix(),
    )
    script_path.write_text(runtime_script, encoding="utf-8")
    completed = subprocess.run(
        [str(executable), "-q", "-s", str(script_path)],
        check=False,
        capture_output=True,
        timeout=timeout_seconds,
        cwd=repo_root,
    )
    log = completed.stdout + completed.stderr
    if completed.returncode != 0 or not json_path.is_file():
        raise ValueError(
            f"Yosys hierarchy elaboration failed rc={completed.returncode}"
        )
    try:
        executable_path = executable.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        executable_path = executable.as_posix()
    metadata = {
        "name": "yosys",
        "path": executable_path,
        "version": (version.stdout + version.stderr).decode(
            "utf-8", errors="replace"
        ).strip(),
        "version_output_sha256": sha256_bytes(version.stdout + version.stderr),
        "executable_sha256": sha256_file(executable),
        "source_count": len(source_records),
    }
    return (
        json_path,
        metadata,
        log,
        canonical_script,
        source_records,
    )


def main() -> int:
    default_repo = Path(__file__).resolve().parents[5]
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=default_repo)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=default_repo / "npc/rv64/design/arch/producer-holder-census.json",
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--elaborate", action="store_true")
    mode.add_argument("--yosys-json", type=Path)
    mode.add_argument("--check-frozen", action="store_true")
    parser.add_argument("--yosys")
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--json-out", type=Path)
    parser.add_argument("--receipt-out", type=Path)
    parser.add_argument("--full-json-out", type=Path)
    parser.add_argument("--script-out", type=Path)
    parser.add_argument("--log-out", type=Path)
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    manifest_path = args.manifest.resolve()
    receipt: dict[str, Any] | None = None
    canonical_script = b""
    try:
        if args.check_frozen:
            result = audit_frozen(repo_root, manifest_path)
            log = b""
        elif args.yosys_json is not None:
            result = audit_elaborated(
                repo_root, manifest_path, args.yosys_json.resolve()
            )
            log = b""
        else:
            if not all((
                args.receipt_out,
                args.full_json_out,
                args.script_out,
                args.log_out,
            )):
                raise ValueError(
                    "--elaborate requires --receipt-out, --full-json-out, "
                    "--script-out and --log-out"
                )
            with tempfile.TemporaryDirectory(
                prefix="rv64-holder-instance-graph-"
            ) as temp:
                (
                    json_path,
                    metadata,
                    log,
                    canonical_script,
                    source_records,
                ) = elaborate(
                    repo_root,
                    yosys=args.yosys,
                    timeout_seconds=args.timeout_seconds,
                    work_dir=Path(temp),
                )
                if args.log_out:
                    args.log_out.parent.mkdir(parents=True, exist_ok=True)
                    args.log_out.write_bytes(log)
                raw_yosys_json = json_path.read_bytes()
                full_yosys_json = canonicalize_full_yosys_json(
                    raw_yosys_json
                )
                result = audit_elaborated(
                    repo_root,
                    manifest_path,
                    json_path,
                    elaborator=metadata,
                    elaboration_sources=source_records,
                    elaborator_full_json_sha256=sha256_bytes(
                        full_yosys_json
                    ),
                    elaborator_script_sha256=sha256_bytes(
                        canonical_script
                    ),
                    elaborator_log_sha256=sha256_bytes(log),
                )
                if result.get("status") == "PASS":
                    receipt = build_receipt(result, full_yosys_json)
                    compressed_full_yosys_json = deterministic_gzip(
                        full_yosys_json
                    )
    except (
        OSError, UnicodeError, json.JSONDecodeError, ValueError,
        subprocess.TimeoutExpired,
    ) as exc:
        result = {
            "schema_version": SCHEMA,
            "status": "FAIL",
            "claim_boundary": "No instance-graph claim is granted.",
            "errors": [str(exc)],
        }
        log = b""

    payload = json.dumps(
        result, allow_nan=False, ensure_ascii=False, indent=2, sort_keys=True
    ) + "\n"
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(payload, encoding="utf-8")
    if args.receipt_out and receipt is not None:
        receipt_payload = json.dumps(
            receipt,
            allow_nan=False,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        ) + "\n"
        args.receipt_out.parent.mkdir(parents=True, exist_ok=True)
        args.receipt_out.write_text(receipt_payload, encoding="utf-8")
    if args.full_json_out and receipt is not None:
        args.full_json_out.parent.mkdir(parents=True, exist_ok=True)
        args.full_json_out.write_bytes(compressed_full_yosys_json)
    if args.script_out and canonical_script:
        args.script_out.parent.mkdir(parents=True, exist_ok=True)
        args.script_out.write_bytes(canonical_script)
    if args.log_out and not args.log_out.exists():
        args.log_out.parent.mkdir(parents=True, exist_ok=True)
        args.log_out.write_bytes(log)
    if result.get("status") == "PASS":
        counts = result.get("counts") or {}
        print(
            "[PRODUCER-HOLDER-INSTANCE-GRAPH] PASS "
            f"modules={counts.get('holder_modules')} "
            f"instances={counts.get('holder_instances')} "
            f"duplicates={counts.get('duplicate_holder_modules')}"
        )
        return 0
    print("[PRODUCER-HOLDER-INSTANCE-GRAPH] FAIL", file=sys.stderr)
    for error in result.get("errors", []):
        print(f"- {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
