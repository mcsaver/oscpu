#!/usr/bin/env python3
"""Fail-closed FP production-child OOC composite evidence tooling.

This module deliberately treats the generated Liberty files as
``OOC_STA_ABSTRACTION`` diagnostic models.  They make the five registered
sequential child boundaries visible to a single NpcTop OpenSTA graph; they are
not characterized signoff macros and never authorize a PPA promotion.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path
from typing import Any, Iterable

from npc.rv64.eval.ppa.tools import architecture_registry as registry


SCHEMA = "npc-rv64-fp-ooc-composite-v1"
CHILD_SCHEMA = "npc-rv64-fp-ooc-child-result-v1"
TOP_SCHEMA = "npc-rv64-fp-ooc-top-result-v1"
IDENTITY_SCHEMA = "npc-rv64-fp-ooc-run-identity-v1"
RECEIPT_SCHEMA = "npc-rv64-fp-ooc-composite-validation-receipt-v1"
TIMING_TSV_SCHEMA = "npc-rv64-fp-ooc-timing-inventory-v1"
QUERY_PROGRESS_SCHEMA = "npc-rv64-fp-ooc-query-progress-v1"
QUERY_BUDGET_COMPLETION_MARKER = "[FP-OOC-QUERY-BUDGET][PASS]"
NETLIST_MANIFEST_SCHEMA = "npc-rv64-fp-ooc-netlist-manifest-v1"
OUTPUT_BIT_DRIVER_CONTRACT_SCHEMA = (
    "npc-rv64-fp-ooc-output-bit-driver-contract-v1"
)
PORT_CANONICALIZATION_SCHEMA = (
    "npc-rv64-fp-ooc-post-split-port-canonicalization-v1"
)
STDLIB_WHITELIST_SCHEMA = "npc-rv64-fp-ooc-stdlib-leaf-whitelist-v1"
CONFIGURATION = registry.FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
PROFILE = registry.MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE
ABSTRACTION = registry.OOC_STA_ABSTRACTION
CHILDREN = tuple(registry.EXPECTED_FP_OOC_MACRO_MODULES)
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
RUN_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
FINITE_RE = re.compile(
    r"-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?"
)
RECEIPT_KEYS = {"path", "path_scope", "sha256", "size_bytes"}
IDENTITY_KEYS = {
    "schema",
    "run_id",
    "design_id",
    "physical_configuration_id",
    "physical_configuration_sha256",
    "mapped_projection_sha256",
    "mapped_artifact_profile",
    "abstraction_kind",
    "corner",
    "source_manifest_sha256",
    "tool_manifest_sha256",
    "standard_cell_lib_sha256",
    "yosys_sha256",
    "opensta_sha256",
}
PATH_CLASS_KEYS = {
    "status",
    "path_count",
    "negative_path_count",
    "worst_slack_ns",
    "startpoint",
    "endpoint",
    "startpoint_object_class",
    "endpoint_object_class",
    "from_objects",
    "to_objects",
}
ARC_RECORD_KEYS = {
    "arc_class",
    "port_family",
    "path_delay",
    "declared_cardinality",
    "observed_cardinality",
    "path_count",
    "worst_path_delay_ns",
    "worst_slack_ns",
    "source_object_class",
    "endpoint_object_class",
    "object_names",
    "startpoint",
    "endpoint",
}
CHILD_PATH_CLASSES = {
    "port_to_register",
    "register_to_register",
    "register_to_port",
    "synchronous_control_to_register",
}
ARC_CLASSES = {"setup", "hold", "clk_to_q"}
OUTPUT_BIT_CLASSES = {"DYNAMIC", "CONSTANT_0", "CONSTANT_1"}
OUTPUT_BIT_TIMING_KEYS = {
    "family", "index", "object_name", "classification", "constant_value",
    "path_delay", "path_count", "worst_path_delay_ns", "worst_slack_ns",
    "source_object_class", "endpoint_object_class", "startpoint", "endpoint",
    "driver_binding_sha256",
}
OUTPUT_BIT_DRIVER_KEYS = {
    "family", "index", "raw_port_name", "opensta_object_name", "net",
    "driver_instance", "driver_cell_type", "driver_pin", "stdlib_function",
    "stdlib_function_sha256", "classification", "value",
    "driver_binding_sha256",
}
QUERY_BUDGET_KEYS = {
    "schema", "artifact", "completion_marker", "complete",
    "expected_find_calls", "find_calls", "path_end_limit", "path_end_count",
    "validation_limit", "validation_count", "register_d_endpoints",
    "nonclock_input_bits", "output_bits", "dynamic_output_bits",
}
TCL_SAFE_ATOM_RE = re.compile(r"^[A-Za-z0-9_$\[\]./= \-]+$")
TCL_ROW_PROJECTION_CONTRACT = registry.EXPECTED_FP_OOC_MODEL_CONTRACT[
    "tcl_row_projection_contract"
]
OUTPUT_BIT_DRIVER_TCL_FIELDS = tuple(
    TCL_ROW_PROJECTION_CONTRACT["child_output_bit_driver"]["fields"]
)
TOP_BOUNDARY_TCL_FIELDS = tuple(
    TCL_ROW_PROJECTION_CONTRACT["top_boundary"]["fields"]
)
GENERIC_CELL_RE = re.compile(r"^\$(?:add|alu|and|anyconst|anyseq|assert|assume|"
                             r"dff|div|eq|ge|gt|le|logic|lt|mem|mod|mul|mux|"
                             r"neg|not|or|reduce|shift|sub|tribuf|xor)", re.I)
PERIOD_NS = 5.0
INPUT_DELAY_NS = 0.0


class EvidenceError(RuntimeError):
    """One exact identity, artifact, timing, or accounting check failed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, allow_nan=False, ensure_ascii=False, indent=2,
                   sort_keys=True) + "\n",
        encoding="utf-8",
    )


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise EvidenceError(f"cannot read JSON {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def finite_number(value: Any, label: str, *, positive: bool = False,
                  nonnegative: bool = False) -> float:
    require(not isinstance(value, bool) and isinstance(value, (int, float)),
            f"{label} must be numeric")
    result = float(value)
    require(math.isfinite(result), f"{label} must be finite")
    if positive:
        require(result > 0.0, f"{label} must be positive")
    if nonnegative:
        require(result >= 0.0, f"{label} must be non-negative")
    return result


def positive_integer(value: Any, label: str) -> int:
    require(not isinstance(value, bool) and isinstance(value, int) and value > 0,
            f"{label} must be a positive integer")
    return value


def canonical_evidence_dir(path: Path) -> Path:
    raw = Path(path)
    require(raw.is_absolute(), f"evidence_dir must be absolute: {raw}")
    try:
        resolved = raw.resolve(strict=True)
    except OSError as exc:
        raise EvidenceError(f"evidence_dir is missing: {raw}: {exc}") from exc
    require(raw == resolved and raw.is_dir() and not raw.is_symlink(),
            f"evidence_dir is an alias or symlink: {raw}")
    return raw


def artifact(path: Path, *, evidence_dir: Path | None = None) -> dict[str, Any]:
    raw = Path(path)
    require(raw.is_absolute(), f"artifact path must be absolute: {raw}")
    try:
        resolved = raw.resolve(strict=True)
    except OSError as exc:
        raise EvidenceError(f"artifact is missing: {raw}: {exc}") from exc
    require(raw == resolved and raw.is_file() and not raw.is_symlink(),
            f"artifact is an alias or symlink: {raw}")
    require(raw.stat().st_nlink == 1,
            f"artifact has multiple hard links and may be replayed: {raw}")
    require(raw.stat().st_size > 0, f"artifact is empty: {raw}")
    if evidence_dir is not None:
        root = canonical_evidence_dir(evidence_dir)
        try:
            recorded = raw.relative_to(root).as_posix()
        except ValueError as exc:
            raise EvidenceError(f"artifact escapes evidence_dir: {raw}") from exc
        scope = "evidence_relative"
    else:
        recorded = raw.as_posix()
        scope = "absolute"
    return {
        "path": recorded,
        "path_scope": scope,
        "sha256": sha256_file(raw),
        "size_bytes": raw.stat().st_size,
    }


def validate_receipt(record: Any, *, evidence_dir: Path) -> Path:
    require(isinstance(record, dict) and set(record) == RECEIPT_KEYS,
            "artifact receipt has an invalid key set")
    require(record.get("path_scope") == "evidence_relative",
            "retained artifact must be evidence-relative")
    relative = record.get("path")
    require(isinstance(relative, str) and relative and Path(relative).name,
            "artifact receipt path is invalid")
    require(not Path(relative).is_absolute() and ".." not in Path(relative).parts,
            "artifact receipt path escapes evidence_dir")
    root = canonical_evidence_dir(evidence_dir)
    selected = root / relative
    expected = artifact(selected, evidence_dir=root)
    require(record == expected, f"artifact receipt is stale or detached: {relative}")
    return selected


def iter_receipts(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        if set(value) == RECEIPT_KEYS:
            yield value
        else:
            for child in value.values():
                yield from iter_receipts(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_receipts(child)


def projection(catalog: dict[str, Any] | None = None) -> dict[str, Any]:
    selected = catalog if catalog is not None else registry.load_json(
        registry.CATALOG_PATH
    )
    result = registry.mapped_projection(selected, CONFIGURATION)
    require(result.get("mapped_artifact_profile") == PROFILE,
            "Registry OOC artifact profile drifted")
    require(result.get("abstraction_kind") == ABSTRACTION,
            "Registry OOC abstraction kind drifted")
    require(result.get("inline_modules") == ["OooFpArithGate"],
            "Registry OOC wrapper must remain inline")
    require(result.get("known_ooc_macro_modules") == list(CHILDREN),
            "Registry OOC child macro set drifted")
    require(result.get("implementation_classes") ==
            registry.EXPECTED_FP_OOC_IMPLEMENTATION_CLASSES,
            "Registry OOC implementation classes drifted")
    require(result.get("expected_unknown_macro_instances") ==
            registry.EXPECTED_UNKNOWN_MACRO_INSTANCES[CONFIGURATION],
            "Registry OOC unknown-placeholder census drifted")
    require(result.get("expected_known_ooc_macro_instances") ==
            registry.EXPECTED_FP_OOC_MACRO_INSTANCES,
            "Registry OOC known-macro census drifted")
    require(result.get("ooc_model_contract") ==
            registry.EXPECTED_FP_OOC_MODEL_CONTRACT,
            "Registry OOC model contract drifted")
    require(result.get("child_contracts") ==
            registry.EXPECTED_FP_OOC_CHILD_CONTRACTS,
            "Registry OOC child timing contract drifted")
    return result


def validate_identity(identity: Any, *, expected_projection: dict[str, Any] | None = None) -> None:
    require(isinstance(identity, dict) and set(identity) == IDENTITY_KEYS,
            "OOC run identity has an invalid key set")
    require(identity.get("schema") == IDENTITY_SCHEMA,
            "OOC run identity schema is invalid")
    require(isinstance(identity.get("run_id"), str) and
            RUN_ID_RE.fullmatch(identity["run_id"]) is not None,
            "OOC run_id is not canonical")
    require(isinstance(identity.get("design_id"), str) and
            DESIGN_ID_RE.fullmatch(identity["design_id"]) is not None,
            "OOC design_id is invalid")
    require(identity["design_id"] == registry.EXPECTED_LIVE_DESIGN_ID,
            "OOC design_id differs from the registered live RTL")
    require(identity.get("physical_configuration_id") == CONFIGURATION,
            "OOC physical configuration differs from the registered profile")
    require(identity.get("mapped_artifact_profile") == PROFILE,
            "OOC mapped artifact profile differs from the registered profile")
    require(identity.get("abstraction_kind") == ABSTRACTION,
            "OOC abstraction kind is invalid")
    for key in (
        "physical_configuration_sha256",
        "mapped_projection_sha256",
        "source_manifest_sha256",
        "tool_manifest_sha256",
        "standard_cell_lib_sha256",
        "yosys_sha256",
        "opensta_sha256",
    ):
        require(isinstance(identity.get(key), str) and
                SHA256_RE.fullmatch(identity[key]) is not None,
                f"OOC identity {key} is invalid")
    expected = expected_projection if expected_projection is not None else projection()
    catalog = registry.load_json(registry.CATALOG_PATH)
    config = registry.selected_physical_configuration(catalog, CONFIGURATION)
    require(identity["physical_configuration_sha256"] ==
            registry.physical_configuration_sha256(CONFIGURATION, config),
            "OOC physical configuration hash is stale")
    require(identity["mapped_projection_sha256"] == canonical_sha256(expected),
            "OOC mapped projection hash is stale")
    require(identity["corner"] == expected["ooc_model_contract"]["corner"],
            "OOC corner differs from Registry")


def build_identity(*, run_id: str, source_manifest: Path, tool_manifest: Path,
                   standard_cell_lib: Path, yosys: Path, opensta: Path) -> dict[str, Any]:
    selected_projection = projection()
    catalog = registry.load_json(registry.CATALOG_PATH)
    design_digest, _ = registry.design_binding(
        registry.REPO_ROOT, catalog["scope"]["source_root"]
    )
    design_id = f"sha256:{design_digest}"
    require(design_id == registry.EXPECTED_LIVE_DESIGN_ID,
            "live RTL design identity differs from the registered OOC input")
    configuration = registry.selected_physical_configuration(catalog, CONFIGURATION)
    identity = {
        "schema": IDENTITY_SCHEMA,
        "run_id": run_id,
        "design_id": design_id,
        "physical_configuration_id": CONFIGURATION,
        "physical_configuration_sha256": registry.physical_configuration_sha256(
            CONFIGURATION, configuration
        ),
        "mapped_projection_sha256": canonical_sha256(selected_projection),
        "mapped_artifact_profile": PROFILE,
        "abstraction_kind": ABSTRACTION,
        "corner": selected_projection["ooc_model_contract"]["corner"],
        "source_manifest_sha256": sha256_file(source_manifest),
        "tool_manifest_sha256": sha256_file(tool_manifest),
        "standard_cell_lib_sha256": sha256_file(standard_cell_lib),
        "yosys_sha256": sha256_file(yosys),
        "opensta_sha256": sha256_file(opensta),
    }
    validate_identity(identity, expected_projection=selected_projection)
    return identity


def _fmt(value: float) -> str:
    return f"{value:.9g}"


def _table(values: list[float]) -> str:
    require(len(values) == 9, "Liberty 3x3 table must contain exactly nine values")
    rows = [
        ", ".join(_fmt(value) for value in values[index:index + 3])
        for index in (0, 3, 6)
    ]
    return ", ".join(f'\"{row}\"' for row in rows)


def _parse_port_object_family(name: str, family: str) -> tuple[str, int] | None:
    # Production exact_port_family is anchored at get_ports on the linked
    # child.  Preserve that ownership isomorphism: parse the complete object
    # name and never normalize away a hierarchical owner prefix.
    candidate = name
    if candidate == family:
        return ("scalar", 0)
    patterns = (
        ("bracket", rf"{re.escape(family)}\[([0-9]+)\]"),
        ("splitnets", rf"{re.escape(family)}__v([0-9]+)"),
        ("underscore", rf"{re.escape(family)}_([0-9]+)_"),
    )
    for style, pattern in patterns:
        match = re.fullmatch(pattern, candidate)
        if match is None:
            continue
        index_text = match.group(1)
        require(
            re.fullmatch(r"(?:0|[1-9][0-9]*)", index_text) is not None,
            f"port family {family} has noncanonical decimal index {index_text}",
        )
        return (style, int(index_text))
    return None


def _port_object_matches_family(name: str, family: str) -> bool:
    return _parse_port_object_family(name, family) is not None


def _validate_port_object_family_names(
        names: Any, *, family: str, width: int, label: str,
) -> str:
    require(isinstance(family, str) and family,
            f"{label} port family is invalid")
    positive_integer(width, f"{label}.width")
    require(isinstance(names, list) and names == sorted(set(names)),
            f"{label} object names are not unique and sorted")
    require(len(names) == width,
            f"{label} object-name cardinality differs from {width}")
    parsed: list[tuple[str, int]] = []
    for name in names:
        require(isinstance(name, str) and name,
                f"{label} contains an invalid object name")
        require("/" not in name,
                f"{label} PORT object must be a direct linked-child top-level port")
        item = _parse_port_object_family(name, family)
        require(item is not None,
                f"{label} object {name!r} is outside exact family {family}")
        parsed.append(item)
    styles = {style for style, _ in parsed}
    require(len(styles) == 1,
            f"{label} mixes indexed port-family styles")
    style = next(iter(styles))
    if width == 1:
        require(style == "scalar" and parsed == [("scalar", 0)],
                f"{label} width-one family must use exact scalar form")
        return style
    require(style in {"bracket", "splitnets", "underscore"},
            f"{label} vector family must use one indexed style")
    indices = [index for _, index in parsed]
    require(len(indices) == len(set(indices)),
            f"{label} contains a duplicate canonical index")
    require(set(indices) == set(range(width)),
            f"{label} indices do not continuously cover 0..{width - 1}")
    return style


def validate_output_bit_driver_partition(
    driver_contract: Any, *, module: str,
) -> dict[str, Any]:
    """Validate the complete, canonical structural partition used downstream."""

    require(isinstance(driver_contract, dict),
            f"{module} output-bit driver contract must be an object")
    contract_id = driver_contract.get("contract_id")
    bits = driver_contract.get("bits")
    summary = driver_contract.get("summary")
    require(isinstance(contract_id, str) and
            SHA256_RE.fullmatch(contract_id) is not None and
            isinstance(bits, list) and bits and isinstance(summary, dict),
            f"{module} output-bit driver partition is incomplete")
    output_ports = projection()["child_contracts"][module]["output_ports"]
    expected_keys = {
        (family, index)
        for family, width in output_ports.items() for index in range(width)
    }
    observed: dict[tuple[str, int], dict[str, Any]] = {}
    for position, bit in enumerate(bits):
        label = f"{module}.output_bit_driver[{position}]"
        require(isinstance(bit, dict) and set(bit) == OUTPUT_BIT_DRIVER_KEYS,
                f"{label} key set drifted")
        family = bit["family"]
        index = bit["index"]
        require(isinstance(family, str) and family in output_ports and
                isinstance(index, int) and not isinstance(index, bool),
                f"{label} family/index is invalid")
        key = (family, index)
        require(key in expected_keys and key not in observed,
                f"{label} is duplicate or undeclared")
        require(all(isinstance(bit[name], str) and bit[name]
                    for name in (
                        "raw_port_name", "opensta_object_name",
                        "driver_instance", "driver_cell_type", "driver_pin",
                        "stdlib_function",
                    )) and "/" not in bit["opensta_object_name"],
                f"{label} object/driver identity is invalid")
        require(isinstance(bit["net"], int) and
                not isinstance(bit["net"], bool) and bit["net"] >= 0,
                f"{label} mapped net is invalid")
        require(isinstance(bit["stdlib_function_sha256"], str) and
                SHA256_RE.fullmatch(bit["stdlib_function_sha256"]) is not None and
                bit["stdlib_function_sha256"] ==
                canonical_sha256(bit["stdlib_function"]) and
                isinstance(bit["driver_binding_sha256"], str) and
                SHA256_RE.fullmatch(bit["driver_binding_sha256"]) is not None,
                f"{label} function/driver binding digest is invalid")
        normalized_function = re.sub(r"\s+", "", bit["stdlib_function"])
        classification = bit["classification"]
        value = bit["value"]
        require(isinstance(classification, str) and
                classification in OUTPUT_BIT_CLASSES,
                f"{label} classification is invalid")
        if classification == "DYNAMIC":
            require(value is None and normalized_function not in {"0", "1"},
                    f"{label} dynamic classification uses a literal function")
        else:
            expected_value = 0 if classification == "CONSTANT_0" else 1
            require(isinstance(value, int) and not isinstance(value, bool) and
                    value == expected_value and
                    normalized_function == str(expected_value),
                    f"{label} constant classification/function disagree")
        observed[key] = bit
    require(set(observed) == expected_keys,
            f"{module} output-bit driver partition is incomplete")
    canonical = [observed[key] for key in sorted(observed)]
    require(bits == canonical,
            f"{module} output-bit driver partition order is non-canonical")
    expected_family_counts = {
        family: {
            name: sum(
                bit["family"] == family and bit["classification"] == name
                for bit in canonical
            )
            for name in sorted(OUTPUT_BIT_CLASSES)
        }
        for family in sorted(output_ports)
    }
    expected_summary = {
        "bit_count": len(canonical),
        "dynamic_count": sum(
            bit["classification"] == "DYNAMIC" for bit in canonical
        ),
        "constant_0_count": sum(
            bit["classification"] == "CONSTANT_0" for bit in canonical
        ),
        "constant_1_count": sum(
            bit["classification"] == "CONSTANT_1" for bit in canonical
        ),
        "family_counts": expected_family_counts,
    }
    require(summary == expected_summary,
            f"{module} output-bit driver summary is detached from its bits")
    return expected_summary


def validate_output_bit_timing_inventory(
    inventory: Any, *, module: str, analysis: str,
    driver_contract: dict[str, Any],
) -> dict[str, Any]:
    """Validate bit-exact dynamic-path/structural-constant observations."""

    validate_output_bit_driver_partition(driver_contract, module=module)
    require(isinstance(inventory, list),
            f"{module} {analysis} output-bit inventory must be a list")
    expected = {
        (bit["family"], bit["index"]): bit
        for bit in driver_contract["bits"]
    }
    observed: dict[tuple[str, int], dict[str, Any]] = {}
    for position, row in enumerate(inventory):
        label = f"{module}.{analysis}.output_bit[{position}]"
        require(isinstance(row, dict) and set(row) == OUTPUT_BIT_TIMING_KEYS,
                f"{label} key set drifted")
        key = (row["family"], row["index"])
        require(key in expected and key not in observed,
                f"{label} is duplicate or undeclared")
        contract_bit = expected[key]
        require(row["object_name"] == contract_bit["opensta_object_name"] and
                row["classification"] == contract_bit["classification"] and
                row["constant_value"] == contract_bit["value"] and
                row["driver_binding_sha256"] ==
                contract_bit["driver_binding_sha256"] and
                row["path_delay"] == analysis,
                f"{label} is detached from the structural driver contract")
        if row["classification"] == "DYNAMIC":
            require(row["path_count"] == 1,
                    f"{label}.path_count must equal endpoint_path_count=1")
            finite_number(row["worst_path_delay_ns"],
                          f"{label}.worst_path_delay_ns", nonnegative=True)
            finite_number(row["worst_slack_ns"], f"{label}.worst_slack_ns")
            require(row["source_object_class"] == "REGISTER_Q" and
                    row["endpoint_object_class"] == "PORT" and
                    isinstance(row["startpoint"], str) and row["startpoint"] and
                    row["endpoint"] == row["object_name"],
                    f"{label} lacks a real register-Q path to its exact bit")
        else:
            require(row["classification"] in {"CONSTANT_0", "CONSTANT_1"} and
                    row["path_count"] == 0 and
                    row["worst_path_delay_ns"] is None and
                    row["worst_slack_ns"] is None and
                    row["source_object_class"] == "STRUCTURAL_CONSTANT" and
                    row["endpoint_object_class"] == "PORT" and
                    row["startpoint"] is None and row["endpoint"] is None,
                    f"{label} structural constant carries a forged timing path")
        observed[key] = row
    require(set(observed) == set(expected),
            f"{module} {analysis} output-bit inventory is incomplete")
    canonical = [observed[key] for key in sorted(observed)]
    require(inventory == canonical,
            f"{module} {analysis} output-bit inventory order is non-canonical")
    return {
        "inventory_sha256": canonical_sha256(canonical),
        "bit_count": len(canonical),
        "dynamic_count": sum(
            row["classification"] == "DYNAMIC" for row in canonical
        ),
        "constant_0_count": sum(
            row["classification"] == "CONSTANT_0" for row in canonical
        ),
        "constant_1_count": sum(
            row["classification"] == "CONSTANT_1" for row in canonical
        ),
    }


def validate_arc_inventory(arc_inventory: Any, *, module: str,
                           analysis: str,
                           output_bit_inventory: list[dict[str, Any]] | None = None,
                           driver_contract: dict[str, Any] | None = None,
                           ) -> dict[str, Any]:
    """Validate complete measured port-family arcs and derive Liberty tables.

    The derivation intentionally uses only bound OpenSTA observations: setup is
    reconstructed from period/input-delay/slack, hold from input-delay/slack,
    and clk-to-Q from the measured register-Q-to-port path delay.  The complete
    inventory digest is retained so even a non-worst object-name/cardinality
    change changes the canonical Liberty artifact.
    """

    require(module in CHILDREN, f"unknown OOC child: {module}")
    require(analysis in {"max", "min"}, "arc inventory analysis is invalid")
    require(isinstance(arc_inventory, list), "arc inventory must be a list")
    contract = projection()["child_contracts"][module]
    expected_inputs = {
        name: width for name, width in contract["input_ports"].items()
        if name != contract["clock_port"]
    }
    expected_outputs = contract["output_ports"]
    expected_keys = {
        *(('setup', name) for name in expected_inputs),
        *(('hold', name) for name in expected_inputs),
        *(('clk_to_q', name) for name in expected_outputs),
    }
    observed: dict[tuple[str, str], dict[str, Any]] = {}
    for index, raw in enumerate(arc_inventory):
        label = f"{module}.{analysis}.arc[{index}]"
        require(isinstance(raw, dict) and set(raw) == ARC_RECORD_KEYS,
                f"{label} key set drifted")
        arc_class = raw["arc_class"]
        family = raw["port_family"]
        key = (arc_class, family)
        require(arc_class in ARC_CLASSES and key in expected_keys and
                key not in observed, f"{label} is duplicate or undeclared")
        width = (expected_outputs if arc_class == "clk_to_q" else
                 expected_inputs)[family]
        require(raw["path_delay"] == ({"setup": "max", "hold": "min"}.get(
                    arc_class, analysis)), f"{label} path-delay corner drifted")
        require(raw["declared_cardinality"] == width,
                f"{label} declared cardinality drifted")
        names = raw["object_names"]
        if arc_class in {"setup", "hold"}:
            require(raw["observed_cardinality"] == width,
                    f"{label} does not cover every declared input bit")
            require(raw["path_count"] == width,
                    f"{label} must retain exactly one path per input bit")
            finite_number(raw["worst_path_delay_ns"],
                          f"{label}.worst_path_delay_ns", nonnegative=True)
            finite_number(raw["worst_slack_ns"], f"{label}.worst_slack_ns")
            _validate_port_object_family_names(
                names, family=family, width=width, label=label,
            )
            require(isinstance(raw["startpoint"], str) and raw["startpoint"] and
                    isinstance(raw["endpoint"], str) and raw["endpoint"] and
                    raw["startpoint"] != raw["endpoint"],
                    f"{label} lacks a real measured endpoint pair")
            require(raw["source_object_class"] == "PORT" and
                    raw["endpoint_object_class"] == "REGISTER_D" and
                    raw["startpoint"] in names,
                    f"{label} is not a real input-port to register-D arc")
        elif output_bit_inventory is not None and driver_contract is not None:
            dynamic = [
                bit for bit in output_bit_inventory
                if bit["family"] == family and bit["classification"] == "DYNAMIC"
            ]
            dynamic_names = sorted(bit["object_name"] for bit in dynamic)
            require(raw["observed_cardinality"] == len(dynamic) and
                    raw["object_names"] == dynamic_names and
                    raw["path_count"] == sum(bit["path_count"] for bit in dynamic),
                    f"{label} aggregate is not derived from dynamic bits")
            require(raw["source_object_class"] == "REGISTER_Q" and
                    raw["endpoint_object_class"] == "PORT",
                    f"{label} object classes drifted")
            if dynamic:
                finite_number(raw["worst_path_delay_ns"],
                              f"{label}.worst_path_delay_ns", nonnegative=True)
                finite_number(raw["worst_slack_ns"], f"{label}.worst_slack_ns")
                require(raw["startpoint"] in {
                            bit["startpoint"] for bit in dynamic
                        } and raw["endpoint"] in dynamic_names,
                        f"{label} worst pair is detached from dynamic bits")
            else:
                require(raw["path_count"] == 0 and
                        raw["worst_path_delay_ns"] is None and
                        raw["worst_slack_ns"] is None and
                        raw["startpoint"] is None and raw["endpoint"] is None,
                        f"{label} all-constant family carries forged timing")
        else:
            require(raw["observed_cardinality"] == width,
                    f"{label} does not cover every declared output bit")
            positive_integer(raw["path_count"], f"{label}.path_count")
            require(raw["path_count"] >= width,
                    f"{label} has fewer paths than covered output objects")
            finite_number(raw["worst_path_delay_ns"],
                          f"{label}.worst_path_delay_ns", nonnegative=True)
            finite_number(raw["worst_slack_ns"], f"{label}.worst_slack_ns")
            _validate_port_object_family_names(
                names, family=family, width=width, label=label,
            )
            require(isinstance(raw["startpoint"], str) and raw["startpoint"] and
                    isinstance(raw["endpoint"], str) and raw["endpoint"] and
                    raw["startpoint"] != raw["endpoint"],
                    f"{label} lacks a real measured endpoint pair")
            require(raw["source_object_class"] == "REGISTER_Q" and
                    raw["endpoint_object_class"] == "PORT" and
                    raw["endpoint"] in names,
                    f"{label} is not a real register-Q to output-port arc")
        observed[key] = raw
    require(set(observed) == expected_keys,
            f"{module} {analysis} arc inventory omits a declared port family")
    canonical_inventory = [
        observed[key] for key in sorted(observed)
    ]
    require(arc_inventory == canonical_inventory,
            f"{module} {analysis} arc inventory order is non-canonical")
    setup = {
        name: max(0.0, PERIOD_NS - INPUT_DELAY_NS -
                  float(observed[("setup", name)]["worst_slack_ns"]))
        for name in sorted(expected_inputs)
    }
    hold = {
        name: max(0.0, INPUT_DELAY_NS -
                  float(observed[("hold", name)]["worst_slack_ns"]))
        for name in sorted(expected_inputs)
    }
    bit_summary = None
    clk_to_q: dict[str, Any] = {}
    clk_to_q_by_bit: dict[str, float] = {}
    if output_bit_inventory is not None and driver_contract is not None:
        bit_summary = validate_output_bit_timing_inventory(
            output_bit_inventory, module=module, analysis=analysis,
            driver_contract=driver_contract,
        )
        for bit in output_bit_inventory:
            if bit["classification"] == "DYNAMIC":
                key = f"{bit['family']}[{bit['index']}]"
                clk_to_q_by_bit[key] = max(
                    0.001, float(bit["worst_path_delay_ns"])
                )
        for name in sorted(expected_outputs):
            value = observed[("clk_to_q", name)]["worst_path_delay_ns"]
            clk_to_q[name] = None if value is None else max(0.001, float(value))
    else:
        clk_to_q = {
            name: max(0.001, float(
                observed[("clk_to_q", name)]["worst_path_delay_ns"]))
            for name in sorted(expected_outputs)
        }
    return {
        "period_ns": PERIOD_NS,
        "input_delay_ns": INPUT_DELAY_NS,
        "corner": projection()["ooc_model_contract"]["corner"],
        "path_measurement_basis": projection()["ooc_model_contract"][
            "path_measurement_basis"
        ],
        "setup_formula": "max(0,period_ns-input_delay_ns-worst_slack_ns)",
        "hold_formula": "max(0,input_delay_ns-worst_slack_ns)",
        "clk_to_q_formula": "max(0.001,worst_path_delay_ns)",
        "inventory_sha256": canonical_sha256(canonical_inventory),
        "setup_ns_by_input": setup,
        "hold_ns_by_input": hold,
        "clk_to_q_ns_by_output": clk_to_q,
        "clk_to_q_ns_by_output_bit": clk_to_q_by_bit,
        "output_bit_summary": bit_summary,
    }


def liberty_metadata(
    *, identity: dict[str, Any], module: str, analysis: str,
    source_closure_sha256: str, timing_evidence_sha256: str,
    area_um2: float, cell_count: int, arc_inventory: list[dict[str, Any]],
    output_bit_inventory: list[dict[str, Any]],
    output_bit_driver_contract: dict[str, Any],
) -> dict[str, Any]:
    validate_identity(identity)
    require(module in CHILDREN, f"unknown OOC child: {module}")
    require(analysis in {"max", "min"}, "Liberty analysis must be max or min")
    for digest, label in (
        (source_closure_sha256, "source closure"),
        (timing_evidence_sha256, "timing evidence"),
    ):
        require(isinstance(digest, str) and SHA256_RE.fullmatch(digest) is not None,
                f"{label} SHA-256 is invalid")
    derivation = validate_arc_inventory(
        arc_inventory, module=module, analysis=analysis,
        output_bit_inventory=output_bit_inventory,
        driver_contract=output_bit_driver_contract,
    )
    return {
        "schema": "npc-rv64-fp-ooc-liberty-metadata-v1",
        "abstraction_kind": ABSTRACTION,
        "run_identity": identity,
        "module": module,
        "analysis": analysis,
        "source_closure_sha256": source_closure_sha256,
        "timing_evidence_sha256": timing_evidence_sha256,
        "area_um2": finite_number(area_um2, "Liberty area", positive=True),
        "cell_count": positive_integer(cell_count, "Liberty cell_count"),
        "arc_inventory": arc_inventory,
        "output_bit_inventory": output_bit_inventory,
        "output_bit_driver_contract": {
            "contract_id": output_bit_driver_contract["contract_id"],
            "bits": output_bit_driver_contract["bits"],
            "summary": output_bit_driver_contract["summary"],
        },
        "arc_derivation": derivation,
        "power_model": "absent",
    }


def _timing_constraint(kind: str, value: float) -> list[str]:
    rows = [value] * 9
    return [
        "      timing () {",
        '        related_pin : "clk";',
        f"        timing_type : {kind};",
        "        rise_constraint (constraint_3x3) {",
        f"          values ({_table(rows)});",
        "        }",
        "        fall_constraint (constraint_3x3) {",
        f"          values ({_table(rows)});",
        "        }",
        "      }",
    ]


def _clock_to_q(value: float) -> list[str]:
    delays = [value] * 9
    transitions = [max(value * 0.25, 0.001)] * 9
    return [
        "      timing () {",
        '        related_pin : "clk";',
        "        timing_type : rising_edge;",
        "        cell_rise (delay_3x3) {",
        f"          values ({_table(delays)});",
        "        }",
        "        cell_fall (delay_3x3) {",
        f"          values ({_table(delays)});",
        "        }",
        "        rise_transition (delay_3x3) {",
        f"          values ({_table(transitions)});",
        "        }",
        "        fall_transition (delay_3x3) {",
        f"          values ({_table(transitions)});",
        "        }",
        "      }",
    ]


def _dynamic_state_name(family: str, index: int) -> str:
    require(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", family) is not None and
            isinstance(index, int) and index >= 0,
            "dynamic Liberty state identity is invalid")
    return f"fp_ooc_state__{family}__{index}"


def _dynamic_state_group(family: str, index: int) -> list[str]:
    state = _dynamic_state_name(family, index)
    return [
        f"    ff ({state}, {state}_n) {{",
        '      clocked_on : "clk";',
        f'      next_state : "{state}";',
        "    }",
    ]


def render_sequential_liberty(metadata: dict[str, Any], *,
                              child_contract: dict[str, Any] | None = None) -> str:
    module = metadata.get("module")
    contract = child_contract or projection()["child_contracts"].get(module)
    require(isinstance(contract, dict), f"missing child contract for {module}")
    expected = liberty_metadata(
        identity=metadata["run_identity"],
        module=module,
        analysis=metadata["analysis"],
        source_closure_sha256=metadata["source_closure_sha256"],
        timing_evidence_sha256=metadata["timing_evidence_sha256"],
        area_um2=metadata["area_um2"],
        cell_count=metadata["cell_count"],
        arc_inventory=metadata["arc_inventory"],
        output_bit_inventory=metadata["output_bit_inventory"],
        output_bit_driver_contract={
            "contract_id": metadata["output_bit_driver_contract"]["contract_id"],
            "bits": metadata["output_bit_driver_contract"]["bits"],
            "summary": metadata["output_bit_driver_contract"]["summary"],
        },
    )
    require(metadata == expected, "Liberty metadata key set or value drifted")
    model = projection()["ooc_model_contract"]
    inputs = contract["input_ports"]
    outputs = contract["output_ports"]
    require(inputs.get("clk") == 1 and set(contract["synchronous_controls"]) ==
            {"rst", "flush_i"}, "child sequential control contract drifted")
    widths = sorted({width for width in [*inputs.values(), *outputs.values()] if width > 1})
    library_name = f"{ABSTRACTION}__{module}__{metadata['analysis']}"
    lines = [
        "/* OOC_STA_ABSTRACTION_METADATA " +
        canonical_bytes(metadata).decode("utf-8") + " */",
        f"library ({library_name}) {{",
        f'  time_unit : "{model["time_unit"]}";',
        f'  capacitive_load_unit (1, {model["capacitive_load_unit"][1:]});',
        f"  nom_voltage : {_fmt(float(model['voltage_v']))};",
        f"  nom_temperature : {_fmt(float(model['temperature_c']))};",
        "  delay_model : table_lookup;",
        "  lu_table_template (delay_3x3) {",
        "    variable_1 : input_net_transition;",
        "    variable_2 : total_output_net_capacitance;",
        f"    index_1 (\"{', '.join(_fmt(float(v)) for v in model['slew_ns'])}\");",
        f"    index_2 (\"{', '.join(_fmt(float(v)) for v in model['load_pf'])}\");",
        "  }",
        "  lu_table_template (constraint_3x3) {",
        "    variable_1 : related_pin_transition;",
        "    variable_2 : constrained_pin_transition;",
        f"    index_1 (\"{', '.join(_fmt(float(v)) for v in model['slew_ns'])}\");",
        f"    index_2 (\"{', '.join(_fmt(float(v)) for v in model['slew_ns'])}\");",
        "  }",
    ]
    for width in widths:
        lines.extend([
            f"  type (bus_{width}) {{",
            "    base_type : array;",
            "    data_type : bit;",
            f"    bit_width : {width};",
            f"    bit_from : {width - 1};",
            "    bit_to : 0;",
            "    downto : true;",
            "  }",
        ])
    lines.extend([
        f"  cell ({module}) {{",
        f"    area : {_fmt(float(metadata['area_um2']))};",
        "    pin (clk) {",
        "      direction : input;",
        "      clock : true;",
        "      capacitance : 0.001;",
        "    }",
    ])
    for name, width in inputs.items():
        if name == "clk":
            continue
        opener = f"    pin ({name}) {{" if width == 1 else f"    bus ({name}) {{"
        lines.append(opener)
        if width > 1:
            lines.append(f"      bus_type : bus_{width};")
        lines.extend(["      direction : input;", "      capacitance : 0.001;"])
        derivation = metadata["arc_derivation"]
        lines.extend(_timing_constraint(
            "setup_rising", float(derivation["setup_ns_by_input"][name])
        ))
        lines.extend(_timing_constraint(
            "hold_rising", float(derivation["hold_ns_by_input"][name])
        ))
        lines.append("    }")
    output_bits = {
        (row["family"], row["index"]): row
        for row in metadata["output_bit_inventory"]
    }
    for family, index in sorted(output_bits):
        if output_bits[(family, index)]["classification"] == "DYNAMIC":
            lines.extend(_dynamic_state_group(family, index))
    for name, width in outputs.items():
        if width == 1:
            row = output_bits[(name, 0)]
            lines.extend([f"    pin ({name}) {{", "      direction : output;"])
            if row["classification"] == "DYNAMIC":
                lines.append(
                    f'      function : "{_dynamic_state_name(name, 0)}";'
                )
                lines.extend(_clock_to_q(float(
                    metadata["arc_derivation"]["clk_to_q_ns_by_output_bit"][
                        f"{name}[0]"
                    ]
                )))
            else:
                lines.append(f'      function : "{row["constant_value"]}";')
            lines.append("    }")
            continue
        lines.extend([
            f"    bus ({name}) {{",
            f"      bus_type : bus_{width};",
            "      direction : output;",
        ])
        for index in range(width):
            row = output_bits[(name, index)]
            lines.extend([
                f"      pin ({name}[{index}]) {{",
                "        direction : output;",
            ])
            if row["classification"] == "DYNAMIC":
                lines.append(
                    f'        function : "{_dynamic_state_name(name, index)}";'
                )
                for timing_line in _clock_to_q(float(
                    metadata["arc_derivation"]["clk_to_q_ns_by_output_bit"][
                        f"{name}[{index}]"
                    ]
                )):
                    lines.append("  " + timing_line)
            else:
                lines.append(
                    f'        function : "{row["constant_value"]}";'
                )
            lines.append("      }")
        lines.append("    }")
    lines.extend(["  }", "}", ""])
    return "\n".join(lines)


def parse_liberty_metadata(text: str) -> dict[str, Any]:
    first = text.splitlines()[0] if text else ""
    prefix = "/* OOC_STA_ABSTRACTION_METADATA "
    suffix = " */"
    require(first.startswith(prefix) and first.endswith(suffix),
            "Liberty lacks canonical OOC metadata")
    try:
        metadata = json.loads(first[len(prefix):-len(suffix)])
    except json.JSONDecodeError as exc:
        raise EvidenceError(f"Liberty metadata is invalid JSON: {exc}") from exc
    require(isinstance(metadata, dict), "Liberty metadata must be an object")
    return metadata


def validate_sequential_liberty(text: str, *, expected_identity: dict[str, Any],
                                expected_module: str, expected_analysis: str,
                                expected_timing_sha256: str | None = None,
                                expected_arc_inventory: list[dict[str, Any]] | None = None,
                                expected_output_bit_inventory: list[dict[str, Any]] | None = None,
                                expected_driver_contract_id: str | None = None,
                                ) -> dict[str, Any]:
    metadata = parse_liberty_metadata(text)
    require(metadata.get("run_identity") == expected_identity,
            "Liberty run identity replay/drift detected")
    require(metadata.get("module") == expected_module,
            "Liberty module replay/drift detected")
    require(metadata.get("analysis") == expected_analysis,
            "Liberty max/min corner replay detected")
    if expected_timing_sha256 is not None:
        require(metadata.get("timing_evidence_sha256") == expected_timing_sha256,
                "Liberty timing evidence replay detected")
    if expected_arc_inventory is not None:
        require(metadata.get("arc_inventory") == expected_arc_inventory,
                "Liberty arc inventory is detached from measured timing evidence")
    if expected_output_bit_inventory is not None:
        require(metadata.get("output_bit_inventory") ==
                expected_output_bit_inventory,
                "Liberty output-bit inventory is detached from measured timing")
    if expected_driver_contract_id is not None:
        require(metadata.get("output_bit_driver_contract", {}).get("contract_id") ==
                expected_driver_contract_id,
                "Liberty output-bit driver contract identity drifted")
    forbidden = (
        "timing_type : combinational",
        "timing_type : recovery",
        "timing_type : removal",
        "internal_power",
        "leakage_power",
        "three_state",
        "false_path",
        "multicycle_path",
    )
    require(not any(token in text for token in forbidden),
            "Liberty contains a forbidden PI-to-PO, exception, async, or power model")
    expected = render_sequential_liberty(metadata)
    require(text == expected,
            "Liberty differs from the canonical sequential setup/hold/clk-to-Q model")
    contract = projection()["child_contracts"][expected_module]
    non_clock_inputs = len(contract["input_ports"]) - 1
    require(text.count("timing_type : setup_rising;") == non_clock_inputs,
            "Liberty setup coverage is incomplete")
    require(text.count("timing_type : hold_rising;") == non_clock_inputs,
            "Liberty hold coverage is incomplete")
    dynamic_count = metadata["output_bit_driver_contract"]["summary"][
        "dynamic_count"
    ]
    constant_count = (
        metadata["output_bit_driver_contract"]["summary"]["constant_0_count"] +
        metadata["output_bit_driver_contract"]["summary"]["constant_1_count"]
    )
    require(text.count("timing_type : rising_edge;") == dynamic_count,
            "Liberty clk-to-Q coverage is incomplete")
    require(text.count('function : "0";') + text.count('function : "1";') ==
            constant_count,
            "Liberty literal constant coverage is incomplete")
    output_bits = metadata["output_bit_inventory"]
    pin_groups = dict(_extract_liberty_named_groups(text, "pin"))
    bus_groups = dict(_extract_liberty_named_groups(text, "bus"))
    for family, width in contract["output_ports"].items():
        if width > 1:
            outer = bus_groups[family].split("pin (")[0]
            require(not any(token in outer for token in (
                        "function :", "three_state", "timing (",
                    )), f"Liberty output bus {family} carries inherited behavior")
    for bit in output_bits:
        family = bit["family"]
        index = bit["index"]
        pin_name = family if contract["output_ports"][family] == 1 else (
            f"{family}[{index}]"
        )
        block = pin_groups[pin_name]
        if bit["classification"] == "DYNAMIC":
            require(
                f'function : "{_dynamic_state_name(family, index)}";' in block and
                block.count("timing_type : rising_edge;") == 1,
                f"Liberty dynamic output member {pin_name} lacks state/clk-to-Q",
            )
        else:
            require(
                f'function : "{bit["constant_value"]}";' in block and
                "timing_type" not in block,
                f"Liberty constant output member {pin_name} is not literal-only",
            )
    return metadata


def _validate_path_record(record: Any, *, label: str, required: bool) -> int:
    require(isinstance(record, dict) and set(record) == PATH_CLASS_KEYS,
            f"{label} path record has an invalid key set")
    if not required:
        require(record == {
            "status": "NOT_APPLICABLE",
            "path_count": 0,
            "negative_path_count": 0,
            "worst_slack_ns": None,
            "startpoint": None,
            "endpoint": None,
            "startpoint_object_class": None,
            "endpoint_object_class": None,
            "from_objects": [],
            "to_objects": [],
        }, f"{label} must be explicitly NOT_APPLICABLE")
        return 0
    require(record.get("status") == "OBSERVED", f"{label} is not observed")
    count = positive_integer(record.get("path_count"), f"{label}.path_count")
    negative = record.get("negative_path_count")
    require(not isinstance(negative, bool) and isinstance(negative, int) and
            0 <= negative <= count, f"{label}.negative_path_count is invalid")
    slack = finite_number(record.get("worst_slack_ns"), f"{label}.worst_slack_ns")
    require((negative > 0) == (slack < 0.0),
            f"{label} negative count and worst slack disagree")
    startpoint = record.get("startpoint")
    endpoint = record.get("endpoint")
    require(isinstance(startpoint, str) and startpoint and
            isinstance(endpoint, str) and endpoint and startpoint != endpoint,
            f"{label} lacks a real startpoint/endpoint pair")
    from_objects = record.get("from_objects")
    to_objects = record.get("to_objects")
    require(isinstance(from_objects, list) and from_objects == sorted(set(from_objects))
            and from_objects and isinstance(to_objects, list) and
            to_objects == sorted(set(to_objects)) and to_objects,
            f"{label} query object sets are not canonical and non-empty")
    require(startpoint in from_objects and endpoint in to_objects,
            f"{label} worst path escapes its queried object sets")
    endpoint_shapes = {
        "port_to_register": ("PORT", "REGISTER_D"),
        "register_to_register": ("REGISTER_Q", "REGISTER_D"),
        "register_to_port": ("REGISTER_Q", "PORT"),
        "synchronous_control_to_register": ("PORT", "REGISTER_D"),
    }
    if label.rsplit(".", 1)[-1] in endpoint_shapes:
        start_class, end_class = endpoint_shapes[label.rsplit(".", 1)[-1]]
        require(record.get("startpoint_object_class") == start_class and
                record.get("endpoint_object_class") == end_class,
                f"{label} actual endpoint object class is invalid")
        if label.endswith("synchronous_control_to_register"):
            require({name.rsplit("/", 1)[-1] for name in from_objects} ==
                    {"rst", "flush_i"},
                    f"{label} does not originate at a synchronous control")
    return negative


def _query_budget_expected_sequence(
    *, module: str, analysis: str, register_d_endpoints: int,
    dynamic_output_bits: int,
) -> list[tuple[str, str, str, int]]:
    """Return phase/kind/sense/group-cap for every production child query."""

    contract = projection()["child_contracts"][module]
    sequence = [
        ("path_class", "port_to_register", analysis, register_d_endpoints),
    ]
    if module != "OooFpMulProductPipe":
        sequence.append((
            "path_class", "register_to_register", analysis,
            register_d_endpoints,
        ))
    sequence.extend((
        ("path_class", "register_to_port", analysis, dynamic_output_bits),
        ("path_class", "synchronous_control_to_register", analysis,
         register_d_endpoints),
    ))
    for family in sorted(contract["input_ports"]):
        if family == contract["clock_port"]:
            continue
        width = contract["input_ports"][family]
        sequence.extend(
            ("input_arc", f"setup/{family}/{index}", "max", 1)
            for index in range(width)
        )
        sequence.extend(
            ("input_arc", f"hold/{family}/{index}", "min", 1)
            for index in range(width)
        )
    output_bits = sum(contract["output_ports"].values())
    sequence.append(("output_bulk", "all_outputs", analysis, output_bits))
    return sequence


def validate_query_budget(
    record: Any, *, module: str, analysis: str,
    path_classes: dict[str, Any], arc_inventory: list[dict[str, Any]],
    output_bit_inventory: list[dict[str, Any]],
    driver_contract: dict[str, Any], require_artifact: bool = True,
) -> None:
    """Bind the progress receipt to exact query and materialization budgets."""

    require(isinstance(record, dict) and set(record) == QUERY_BUDGET_KEYS,
            f"{module} {analysis} query-budget key set drifted")
    if require_artifact:
        require(isinstance(record["artifact"], dict) and
                set(record["artifact"]) == RECEIPT_KEYS,
                f"{module} {analysis} query-progress receipt is invalid")
    else:
        require(record["artifact"] == {},
                f"{module} {analysis} unsealed query-progress is invalid")
    require(record["schema"] == QUERY_PROGRESS_SCHEMA and
            record["completion_marker"] == QUERY_BUDGET_COMPLETION_MARKER and
            record["complete"] is True,
            f"{module} {analysis} query budget lacks its COMPLETE marker")
    for key in (
        "expected_find_calls", "find_calls", "path_end_limit",
        "path_end_count", "validation_limit", "validation_count",
        "register_d_endpoints", "nonclock_input_bits", "output_bits",
        "dynamic_output_bits",
    ):
        positive_integer(record[key], f"{module}.{analysis}.query_budget.{key}")

    contract = projection()["child_contracts"][module]
    expected_nonclock = sum(contract["input_ports"].values()) - 1
    expected_outputs = sum(contract["output_ports"].values())
    dynamic_outputs = driver_contract["summary"]["dynamic_count"]
    class_count = 3 if module == "OooFpMulProductPipe" else 4
    register_multiplier = 2 if module == "OooFpMulProductPipe" else 3
    expected_calls = class_count + 2 * expected_nonclock + 1
    expected_limit = (
        register_multiplier * record["register_d_endpoints"] +
        2 * dynamic_outputs + 2 * expected_nonclock
    )
    require(record["nonclock_input_bits"] == expected_nonclock and
            record["output_bits"] == expected_outputs and
            record["dynamic_output_bits"] == dynamic_outputs,
            f"{module} {analysis} query-budget dimensions drifted")
    require(record["expected_find_calls"] == expected_calls and
            record["find_calls"] == expected_calls,
            f"{module} {analysis} find_timing_paths count is not exact")
    require(record["path_end_limit"] == expected_limit and
            record["validation_limit"] == expected_limit and
            record["path_end_count"] <= expected_limit and
            record["validation_count"] <= expected_limit,
            f"{module} {analysis} PathEnd/validation budget drifted")
    if module == "OooFpAddSubPipe":
        addsub = projection()["ooc_model_contract"]["child_query_budget"][
            "current_addsub"
        ]
        require({
            "register_d_endpoints": record["register_d_endpoints"],
            "nonclock_input_bits": record["nonclock_input_bits"],
            "output_bits": record["output_bits"],
            "dynamic_output_bits": record["dynamic_output_bits"],
            "find_calls": record["find_calls"],
            "path_end_limit": record["path_end_limit"],
            "validation_limit": record["validation_limit"],
        } == addsub, "OooFpAddSubPipe 5.0ns query budget is not 273/2364")

    materialized = (
        sum(int(row["path_count"]) for row in path_classes.values()) +
        sum(int(row["path_count"]) for row in arc_inventory)
    )
    require(record["path_end_count"] == materialized and
            record["validation_count"] == materialized,
            f"{module} {analysis} progress counts are detached from timing rows")
    require(sum(
        int(row["path_count"]) for row in output_bit_inventory
        if row["classification"] == "DYNAMIC"
    ) == dynamic_outputs,
            f"{module} {analysis} output bulk does not cover every dynamic bit")


def validate_child_timing_mode(
    record: Any, *, module: str, analysis: str,
    driver_contract: dict[str, Any],
) -> int:
    require(isinstance(record, dict) and set(record) == {
        "analysis", "artifact", "path_classes", "arc_inventory",
        "output_bit_driver_contract_id", "output_bit_inventory",
        "query_budget", "negative_slack_count"
    }, f"{module} {analysis} timing result key set drifted")
    require(record["analysis"] == analysis, f"{module} timing analysis drifted")
    require(isinstance(record["artifact"], dict) and
            set(record["artifact"]) == RECEIPT_KEYS,
            f"{module} {analysis} timing artifact receipt is invalid")
    classes = record["path_classes"]
    require(isinstance(classes, dict) and set(classes) == CHILD_PATH_CLASSES,
            f"{module} {analysis} timing path-class set drifted")
    contract = projection()["child_contracts"][module]
    require(record["output_bit_driver_contract_id"] ==
            driver_contract["contract_id"],
            f"{module} {analysis} driver-contract identity drifted")
    validate_arc_inventory(
        record["arc_inventory"], module=module, analysis=analysis,
        output_bit_inventory=record["output_bit_inventory"],
        driver_contract=driver_contract,
    )
    validate_query_budget(
        record["query_budget"], module=module, analysis=analysis,
        path_classes=classes, arc_inventory=record["arc_inventory"],
        output_bit_inventory=record["output_bit_inventory"],
        driver_contract=driver_contract,
    )
    negative = 0
    for path_class in sorted(CHILD_PATH_CLASSES):
        required = not (
            path_class == "register_to_register" and
            contract["path_classes"][path_class] == "not_applicable_single_stage"
        )
        negative += _validate_path_record(
            classes[path_class], label=f"{module}.{analysis}.{path_class}",
            required=required,
        )
    require(record["negative_slack_count"] == negative,
            f"{module} {analysis} negative-slack aggregation is detached")
    return negative


def validate_child_result(result: Any, *, expected_identity: dict[str, Any]) -> int:
    required = {
        "schema", "status", "module", "run_identity", "source_closure_sha256",
        "synthesis", "timing", "liberty", "power",
    }
    require(isinstance(result, dict) and set(result) == required,
            "child result has an invalid key set")
    require(result["schema"] == CHILD_SCHEMA and result["status"] == "PASS",
            "child result is not a complete PASS receipt")
    module = result["module"]
    require(module in CHILDREN, f"child result names an unknown module: {module}")
    require(result["run_identity"] == expected_identity,
            f"{module} result replays a different run identity")
    validate_identity(result["run_identity"])
    require(isinstance(result["source_closure_sha256"], str) and
            SHA256_RE.fullmatch(result["source_closure_sha256"]) is not None,
            f"{module} source closure digest is invalid")
    synthesis = result["synthesis"]
    require(isinstance(synthesis, dict) and set(synthesis) == {
        "implementation_class", "cell_count", "area_um2", "netlist_sha256",
        "netlist_size_bytes", "synth_stat", "census_json", "netlist_manifest",
        "port_manifest", "output_bit_driver_contract",
        "output_bit_driver_contract_value", "census",
    }, f"{module} synthesis result key set drifted")
    require(synthesis["implementation_class"] == "known_ooc_macro_source_mapping",
            f"{module} synthesis implementation class is invalid")
    positive_integer(synthesis["cell_count"], f"{module} mapped cell count")
    finite_number(synthesis["area_um2"], f"{module} mapped area", positive=True)
    require(isinstance(synthesis["netlist_sha256"], str) and
            SHA256_RE.fullmatch(synthesis["netlist_sha256"]) is not None,
            f"{module} netlist digest is invalid")
    positive_integer(synthesis["netlist_size_bytes"], f"{module} netlist size")
    require(isinstance(synthesis["synth_stat"], dict) and
            set(synthesis["synth_stat"]) == RECEIPT_KEYS,
            f"{module} synth-stat receipt is invalid")
    for key in ("census_json", "netlist_manifest", "output_bit_driver_contract"):
        require(isinstance(synthesis[key], dict) and
                set(synthesis[key]) == RECEIPT_KEYS,
                f"{module} {key} receipt is invalid")
    port_manifest = synthesis["port_manifest"]
    require(isinstance(port_manifest, dict) and set(port_manifest) == {
        "schema", "raw_port_count", "raw_bit_count", "canonical_port_count",
        "canonical_bit_count", "mapping_count",
    } and port_manifest["schema"] == PORT_CANONICALIZATION_SCHEMA,
            f"{module} retained port summary is invalid")
    for key in (
        "raw_port_count", "raw_bit_count", "canonical_port_count",
        "canonical_bit_count", "mapping_count",
    ):
        positive_integer(port_manifest[key], f"{module} port_manifest.{key}")
    expected_contract = projection()["child_contracts"][module]
    expected_family_count = (
        len(expected_contract["input_ports"]) +
        len(expected_contract["output_ports"])
    )
    expected_bit_count = (
        sum(expected_contract["input_ports"].values()) +
        sum(expected_contract["output_ports"].values())
    )
    require(port_manifest["canonical_port_count"] == expected_family_count and
            port_manifest["canonical_bit_count"] == expected_bit_count and
            port_manifest["raw_bit_count"] == expected_bit_count and
            port_manifest["mapping_count"] == port_manifest["raw_port_count"],
            f"{module} retained port summary disagrees with Registry")
    require(synthesis["census"] == {module: 1},
            f"{module} OOC hierarchy census is not exactly one")
    timing = result["timing"]
    require(isinstance(timing, dict) and set(timing) == {"max", "min", "assessment"},
            f"{module} timing result key set drifted")
    driver_contract = synthesis["output_bit_driver_contract_value"]
    require(isinstance(driver_contract, dict) and
            driver_contract.get("contract_id") and
            driver_contract.get("summary") and driver_contract.get("bits"),
            f"{module} embedded output-bit driver contract is invalid")
    validate_output_bit_driver_partition(driver_contract, module=module)
    negative = sum(validate_child_timing_mode(
        timing[mode], module=module, analysis=mode,
        driver_contract=driver_contract,
    ) for mode in ("max", "min"))
    max_partition = [
        (row["family"], row["index"], row["classification"],
         row["constant_value"], row["driver_binding_sha256"])
        for row in timing["max"]["output_bit_inventory"]
    ]
    min_partition = [
        (row["family"], row["index"], row["classification"],
         row["constant_value"], row["driver_binding_sha256"])
        for row in timing["min"]["output_bit_inventory"]
    ]
    require(max_partition == min_partition,
            f"{module} max/min output-bit classifications drifted")
    expected_assessment = "VIOLATED" if negative else "CLEAN"
    require(timing["assessment"] == expected_assessment,
            f"{module} internal negative slack was masked")
    liberty = result["liberty"]
    require(isinstance(liberty, dict) and set(liberty) == {"max", "min"},
            f"{module} Liberty result key set drifted")
    for mode in ("max", "min"):
        row = liberty[mode]
        require(isinstance(row, dict) and set(row) == {
            "analysis", "artifact", "metadata_sha256"
        }, f"{module} {mode} Liberty record is invalid")
        require(row["analysis"] == mode and isinstance(row["artifact"], dict) and
                set(row["artifact"]) == RECEIPT_KEYS,
                f"{module} {mode} Liberty artifact is detached")
        require(isinstance(row["metadata_sha256"], str) and
                SHA256_RE.fullmatch(row["metadata_sha256"]) is not None,
                f"{module} {mode} Liberty metadata digest is invalid")
    require(result["power"] == {
        "model": "absent", "complete": False,
        "status": "INCOMPLETE_NO_OOC_POWER_MODEL",
    }, f"{module} falsely claims a complete OOC power model")
    return negative


def _top_object_family(name: str, *, instance_path: str | None,
                       families: Iterable[str]) -> str | None:
    candidate = name
    if instance_path is not None:
        prefix = f"{instance_path}/"
        if not candidate.startswith(prefix):
            return None
        candidate = candidate[len(prefix):]
    for family in families:
        if _port_object_matches_family(candidate, family):
            return family
        if re.search(rf"(?:^|[/._]){re.escape(family)}(?:$|\[|__v|[/._$])",
                     candidate):
            return family
    return None


def _require_exact_object_families(objects: list[str], *, label: str,
                                   instance_path: str | None,
                                   widths: dict[str, int]) -> None:
    counts = {family: 0 for family in widths}
    for name in objects:
        family = _top_object_family(
            name, instance_path=instance_path, families=widths
        )
        require(family is not None,
                f"{label} contains an object outside its exact contract: {name}")
        counts[family] += 1
    require(counts == widths,
            f"{label} exact object cardinality drifted: {counts} != {widths}")


def _boundary_endpoint_widths(endpoint: dict[str, Any],
                              contracts: dict[str, Any]
                              ) -> tuple[str | None, dict[str, int]]:
    if endpoint["kind"] == "known_ooc_macro_input":
        matches = [
            (target, target_contract) for target, target_contract in contracts.items()
            if endpoint["instance_path"].endswith(
                "/" + target_contract["top_instance"]
            )
        ]
        require(len(matches) == 1,
                "top boundary macro endpoint does not select one registered child")
        _, target_contract = matches[0]
        return endpoint["instance_path"], {
            name: target_contract["input_ports"][name]
            for name in endpoint["port_families"]
        }
    if endpoint["kind"] == "wrapper_register_d":
        return "u_fp_arith", endpoint["register_families"]
    if endpoint["kind"] == "backend_completion_register_d":
        require(
            endpoint.get("instance_path") ==
            registry.FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH,
            "backend completion endpoint hierarchy is not the linked NpcTop owner",
        )
        require(
            endpoint.get("register_families") ==
            registry.FP_OOC_BACKEND_COMPLETION_REGISTER_FAMILIES,
            "backend completion register-D family/cardinality drifted",
        )
        return endpoint["instance_path"], endpoint["register_families"]
    if endpoint["kind"] == "top_port":
        raise EvidenceError(
            "legacy OooFpArithGate out_value_o/out_fflags_o NpcTop top-port "
            "endpoint is forbidden"
        )
    raise EvidenceError("top boundary endpoint kind is invalid")


def _validate_boundary_record(record: Any, *, boundary: str,
                              module: str,
                              contracts: dict[str, Any]) -> int:
    negative = _validate_path_record(record, label=f"top.{boundary}", required=True)
    contract = contracts[module]
    exact = contract["top_boundary_contract"]
    require(record["startpoint_object_class"] == exact["source_object_class"],
            f"top boundary {boundary} source is not an actual macro output pin")
    _require_exact_object_families(
        record["from_objects"], label=f"top.{boundary}.from_objects",
        instance_path=exact["source_instance_path"],
        widths={name: contract["output_ports"][name]
                for name in exact["source_port_families"]},
    )
    endpoint = exact["endpoint"]
    require(record["endpoint_object_class"] == endpoint["object_class"],
            f"top boundary {boundary} endpoint object type is forged")
    instance_path, widths = _boundary_endpoint_widths(endpoint, contracts)
    _require_exact_object_families(
        record["to_objects"], label=f"top.{boundary}.to_objects",
        instance_path=instance_path, widths=widths,
    )
    return negative


def validate_top_timing_mode(record: Any, *, analysis: str,
                             contracts: dict[str, Any]) -> int:
    require(isinstance(record, dict) and set(record) == {
        "analysis", "artifact", "boundary_classes", "negative_slack_count"
    }, f"top {analysis} timing result key set drifted")
    require(record["analysis"] == analysis, "top timing max/min identity drifted")
    require(isinstance(record["artifact"], dict) and
            set(record["artifact"]) == RECEIPT_KEYS,
            f"top {analysis} timing artifact receipt is invalid")
    expected = {contract["path_classes"]["top_boundary"]: module
                for module, contract in contracts.items()}
    classes = record["boundary_classes"]
    require(isinstance(classes, dict) and set(classes) == set(expected),
            f"top {analysis} boundary-class set drifted")
    negative = 0
    for boundary, module in expected.items():
        negative += _validate_boundary_record(
            classes[boundary], boundary=boundary,
            module=module, contracts=contracts,
        )
    require(record["negative_slack_count"] == negative,
            f"top {analysis} negative-slack aggregation is detached")
    return negative


def validate_top_result(result: Any, *, expected_identity: dict[str, Any],
                        expected_projection: dict[str, Any]) -> int:
    require(isinstance(result, dict) and set(result) == {
        "schema", "status", "run_identity", "synthesis", "timing"
    }, "top result has an invalid key set")
    require(result["schema"] == TOP_SCHEMA and result["status"] == "PASS",
            "top result is not a complete PASS receipt")
    require(result["run_identity"] == expected_identity,
            "top result replays a different run identity")
    synthesis = result["synthesis"]
    require(isinstance(synthesis, dict) and set(synthesis) == {
        "implementation_class", "top_stdcell_cell_count", "top_stdcell_area_um2",
        "inline_rtl_instances", "known_ooc_macro_instances",
        "unknown_placeholder_instances", "standard_cell_module_census",
        "netlist_sha256", "netlist_size_bytes", "synth_stat", "census_json",
        "netlist_manifest",
    }, "top synthesis result key set drifted")
    require(synthesis["implementation_class"] ==
            "npctop_inline_wrapper_plus_known_ooc_macros",
            "top implementation class is invalid")
    positive_integer(synthesis["top_stdcell_cell_count"], "top stdcell count")
    finite_number(synthesis["top_stdcell_area_um2"], "top stdcell area", positive=True)
    require(synthesis["inline_rtl_instances"] == {"OooFpArithGate": 1},
            "top inline wrapper census drifted")
    require(synthesis["known_ooc_macro_instances"] ==
            expected_projection["expected_known_ooc_macro_instances"],
            "top known OOC macro census drifted")
    require(synthesis["unknown_placeholder_instances"] ==
            expected_projection["expected_unknown_macro_instances"],
            "top unknown-placeholder census drifted")
    standard_modules = synthesis["standard_cell_module_census"]
    require(isinstance(standard_modules, dict) and standard_modules and
            all(isinstance(key, str) and isinstance(value, int) and value > 0
                for key, value in standard_modules.items()),
            "top standard-cell module census is invalid")
    require(not set(CHILDREN) & set(standard_modules),
            "known OOC macro is duplicated as top standard-cell logic")
    require("OooFpArithGate" not in standard_modules,
            "inline wrapper is duplicated as a macro/standard-cell module")
    for key in ("netlist_sha256",):
        require(isinstance(synthesis[key], str) and SHA256_RE.fullmatch(synthesis[key]),
                f"top {key} is invalid")
    positive_integer(synthesis["netlist_size_bytes"], "top netlist size")
    for key in ("synth_stat", "census_json", "netlist_manifest"):
        require(isinstance(synthesis[key], dict) and
                set(synthesis[key]) == RECEIPT_KEYS,
                f"top {key} receipt is invalid")
    timing = result["timing"]
    require(isinstance(timing, dict) and set(timing) == {"max", "min", "assessment"},
            "top timing result key set drifted")
    negative = sum(validate_top_timing_mode(
        timing[mode], analysis=mode,
        contracts=expected_projection["child_contracts"])
        for mode in ("max", "min"))
    expected_assessment = "VIOLATED" if negative else "CLEAN"
    require(timing["assessment"] == expected_assessment,
            "top negative slack was masked")
    return negative


def build_composite_summary(*, identity: dict[str, Any], children: dict[str, Any],
                            top: dict[str, Any],
                            run_artifacts: dict[str, Any],
                            expected_projection: dict[str, Any] | None = None) -> dict[str, Any]:
    selected_projection = expected_projection or projection()
    validate_identity(identity, expected_projection=selected_projection)
    require(set(children) == set(CHILDREN),
            "composite child result set is missing or duplicated")
    child_negative = 0
    child_areas: dict[str, float] = {}
    for module in CHILDREN:
        result = children[module]
        require(result.get("module") == module,
                f"composite child result key/module mismatch: {module}")
        child_negative += validate_child_result(result, expected_identity=identity)
        child_areas[module] = float(result["synthesis"]["area_um2"])
    top_negative = validate_top_result(
        top, expected_identity=identity,
        expected_projection=selected_projection,
    )
    top_area = float(top["synthesis"]["top_stdcell_area_um2"])
    macro_area = sum(child_areas.values())
    timing_assessment = "VIOLATED" if child_negative + top_negative else "CLEAN"
    expected_artifact_keys = {
        "production_manifest_before", "production_manifest_after",
        "source_manifest", "tool_manifest", "run_identity", "registry_contract",
        "stdlib_leaf_whitelist", "top_boundary_contract_tcl",
    }
    require(isinstance(run_artifacts, dict) and
            set(run_artifacts) == expected_artifact_keys and
            all(isinstance(record, dict) and set(record) == RECEIPT_KEYS
                for record in run_artifacts.values()),
            "composite run artifact receipt set drifted")
    require(run_artifacts["production_manifest_before"]["sha256"] ==
            run_artifacts["production_manifest_after"]["sha256"],
            "production input manifest changed during the OOC composite run")
    require(run_artifacts["source_manifest"]["sha256"] ==
            identity["source_manifest_sha256"],
            "source manifest receipt is detached from run identity")
    require(run_artifacts["tool_manifest"]["sha256"] ==
            identity["tool_manifest_sha256"],
            "tool manifest receipt is detached from run identity")
    return {
        "schema": SCHEMA,
        "status": "PASS",
        "claim_scope": "DIAGNOSTIC_OOC_COMPOSITE_ONLY",
        "run_identity": identity,
        "projection": selected_projection,
        "artifacts": run_artifacts,
        "children": children,
        "top": top,
        "area_accounting": {
            "method": "top_excludes_known_ooc_macro_area_plus_each_child_once",
            "top_stdcell_area_um2": top_area,
            "child_ooc_area_um2": child_areas,
            "macro_area_sum_um2": macro_area,
            "composite_area_um2": top_area + macro_area,
            "double_counted_modules": [],
            "missing_modules": [],
        },
        "timing_accounting": {
            "assessment": timing_assessment,
            "child_negative_slack_count": child_negative,
            "top_boundary_negative_slack_count": top_negative,
            "zero_negative_slack_is_valid": True,
        },
        "power": {
            "status": "INCOMPLETE_NO_OOC_POWER_MODEL",
            "complete": False,
            "children_without_power_model": list(CHILDREN),
        },
        "physical_claim": {
            "measurement_status": "DIAGNOSTIC_ONLY",
            "physical_status": "GAP",
            "canonical": False,
            "champion": False,
            "signoff": False,
        },
    }


def validate_composite_summary(summary: Any, *,
                               expected_projection: dict[str, Any] | None = None) -> None:
    required = {
        "schema", "status", "claim_scope", "run_identity", "projection",
        "artifacts", "children", "top", "area_accounting", "timing_accounting", "power",
        "physical_claim",
    }
    require(isinstance(summary, dict) and set(summary) == required,
            "composite result key set drifted")
    require(summary["schema"] == SCHEMA and summary["status"] == "PASS",
            "composite result is not a complete PASS receipt")
    require(summary["claim_scope"] == "DIAGNOSTIC_OOC_COMPOSITE_ONLY",
            "composite claim scope is invalid")
    selected_projection = expected_projection or projection()
    require(summary["projection"] == selected_projection,
            "composite Registry projection is stale")
    rebuilt = build_composite_summary(
        identity=summary["run_identity"],
        children=summary["children"],
        top=summary["top"],
        run_artifacts=summary["artifacts"],
        expected_projection=selected_projection,
    )
    require(summary == rebuilt,
            "composite timing/area/power accounting is detached from child/top evidence")


def parse_query_progress(path: Path, *, identity: dict[str, Any],
                         module: str, analysis: str,
                         expected_sequence_override: list[
                             tuple[str, str, str, int]
                         ] | None = None) -> dict[str, Any]:
    """Parse the incrementally flushed BEGIN/COMPLETE query ledger."""

    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise EvidenceError(f"cannot read query progress {path}: {exc}") from exc
    require(text.endswith("\n") and "\r" not in text,
            f"query progress is not canonical LF text: {path}")
    lines = text.splitlines()
    headers = [
        f"schema\t{QUERY_PROGRESS_SCHEMA}",
        f"run_id\t{identity['run_id']}",
        f"design_id\t{identity['design_id']}",
        f"subject\t{module}",
        f"analysis\t{analysis}",
        "phase_marker\tpre_link\tBEGIN",
        "phase_marker\tlink\tCOMPLETE",
    ]
    require(lines[:len(headers)] == headers,
            f"query-progress identity/link markers drifted: {path}")
    position = len(headers)
    metadata_names = (
        "expected_find_calls", "pathend_limit", "validation_limit",
        "register_d_endpoints", "nonclock_input_bits", "output_bits",
        "dynamic_output_bits",
    )
    metadata: dict[str, int] = {}
    for name in metadata_names:
        require(position < len(lines), f"query progress lacks {name}: {path}")
        fields = lines[position].split("\t")
        require(len(fields) == 2 and fields[0] == name and fields[1].isdigit() and
                fields[1] == str(int(fields[1])) and int(fields[1]) > 0,
                f"query progress {name} is malformed: {path}")
        metadata[name] = int(fields[1])
        position += 1
    query_header = (
        "phase\tquery_index\tkind\tpath_delay\tendpoint_path_count\t"
        "group_path_count\tpathend_count\tcumulative_pathends\t"
        "cumulative_validations\tstatus"
    )
    require(position < len(lines) and lines[position] == query_header,
            f"query progress table header drifted: {path}")
    position += 1

    expected_sequence = expected_sequence_override
    if expected_sequence is None:
        require(module in CHILDREN,
                "production query progress names an unregistered child")
        expected_sequence = _query_budget_expected_sequence(
            module=module, analysis=analysis,
            register_d_endpoints=metadata["register_d_endpoints"],
            dynamic_output_bits=metadata["dynamic_output_bits"],
        )
    require(metadata["expected_find_calls"] == len(expected_sequence),
            f"query progress static find-call budget drifted: {path}")
    cumulative_paths = 0
    cumulative_validations = 0
    for query_index, expected in enumerate(expected_sequence, 1):
        require(position + 1 < len(lines),
                f"query progress stops before query {query_index}: {path}")
        begin = lines[position].split("\t")
        complete = lines[position + 1].split("\t")
        require(len(begin) == 10 and len(complete) == 10,
                f"query progress row {query_index} is malformed: {path}")
        phase, kind, path_delay, group_cap = expected
        prefix = [phase, str(query_index), kind, path_delay, "1", str(group_cap)]
        require(begin[:6] == prefix and complete[:6] == prefix and
                begin[6] == "-" and begin[7:] == [
                    str(cumulative_paths), str(cumulative_validations), "BEGIN"
                ] and complete[6].isdigit() and
                complete[6] == str(int(complete[6])) and
                complete[9] == "COMPLETE",
                f"query progress BEGIN/COMPLETE pair {query_index} drifted: {path}")
        path_count = int(complete[6])
        require(path_count <= group_cap,
                f"query {query_index} exceeds its group cap: {path}")
        if phase == "input_arc":
            require(path_count == 1,
                    f"input query {query_index} did not retain exactly one path")
        if phase == "output_bulk":
            require(path_count == metadata["dynamic_output_bits"],
                    f"output bulk query does not exactly cover dynamic endpoints")
        cumulative_paths += path_count
        cumulative_validations += path_count
        require(complete[7:] == [
                    str(cumulative_paths), str(cumulative_validations), "COMPLETE"
                ], f"query progress cumulative counts drift at {query_index}: {path}")
        position += 2
    terminal = [
        "phase_marker\treport\tBEGIN",
        "phase_marker\treport\tCOMPLETE",
        f"completion_marker\t{QUERY_BUDGET_COMPLETION_MARKER}",
    ]
    require(lines[position:] == terminal,
            f"query progress lacks its exact report/COMPLETE tail: {path}")
    require(cumulative_paths <= metadata["pathend_limit"] and
            cumulative_validations <= metadata["validation_limit"],
            f"query progress exceeds its PathEnd/validation limit: {path}")
    return {
        "schema": QUERY_PROGRESS_SCHEMA,
        "artifact": {},
        "completion_marker": QUERY_BUDGET_COMPLETION_MARKER,
        "complete": True,
        "expected_find_calls": metadata["expected_find_calls"],
        "find_calls": len(expected_sequence),
        "path_end_limit": metadata["pathend_limit"],
        "path_end_count": cumulative_paths,
        "validation_limit": metadata["validation_limit"],
        "validation_count": cumulative_validations,
        "register_d_endpoints": metadata["register_d_endpoints"],
        "nonclock_input_bits": metadata["nonclock_input_bits"],
        "output_bits": metadata["output_bits"],
        "dynamic_output_bits": metadata["dynamic_output_bits"],
    }


def parse_timing_inventory(path: Path, *, identity: dict[str, Any],
                           subject: str, analysis: str,
                           expected_classes: set[str],
                           driver_contract: dict[str, Any] | None = None,
                           ) -> dict[str, Any]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise EvidenceError(f"cannot read timing inventory {path}: {exc}") from exc
    require(text.endswith("\n") and "\r" not in text,
            f"timing inventory is not canonical LF text: {path}")
    lines = text.splitlines()
    require(len(lines) >= 7, f"timing inventory is incomplete: {path}")
    expected_headers = [
        f"schema\t{TIMING_TSV_SCHEMA}",
        f"run_id\t{identity['run_id']}",
        f"design_id\t{identity['design_id']}",
        f"subject\t{subject}",
        f"analysis\t{analysis}",
        "path_class\tstatus\tpath_count\tnegative_path_count\tworst_slack_ns\tstartpoint\tendpoint\tstartpoint_object_class\tendpoint_object_class\tfrom_objects\tto_objects",
    ]
    require(lines[:6] == expected_headers,
            f"timing inventory header identity drifted: {path}")
    try:
        arc_separator = lines.index("arc_inventory", 6)
    except ValueError:
        arc_separator = len(lines)
    records: dict[str, Any] = {}
    for number, line in enumerate(lines[6:arc_separator], 7):
        fields = line.split("\t")
        require(len(fields) == 11, f"timing inventory row {number} is malformed")
        (path_class, status, count_raw, negative_raw, slack_raw, start, end,
         start_class, end_class, from_raw, to_raw) = fields
        require(path_class in expected_classes and path_class not in records,
                f"timing inventory row {number} has duplicate/unknown class")
        require(count_raw.isdigit() and negative_raw.isdigit(),
                f"timing inventory row {number} count is non-canonical")
        if status == "NOT_APPLICABLE":
            require((count_raw, negative_raw, slack_raw, start, end) ==
                    ("0", "0", "-", "-", "-"),
                    f"timing inventory row {number} N/A payload is invalid")
            require((start_class, end_class, from_raw, to_raw) ==
                    ("-", "-", "-", "-"),
                    f"timing inventory row {number} N/A object payload is invalid")
            record = {
                "status": status, "path_count": 0, "negative_path_count": 0,
                "worst_slack_ns": None, "startpoint": None, "endpoint": None,
                "startpoint_object_class": None,
                "endpoint_object_class": None,
                "from_objects": [], "to_objects": [],
            }
        else:
            require(status == "OBSERVED" and FINITE_RE.fullmatch(slack_raw) is not None,
                    f"timing inventory row {number} observation is invalid")
            from_objects = from_raw.split(";")
            to_objects = to_raw.split(";")
            require(from_objects == sorted(set(from_objects)) and
                    to_objects == sorted(set(to_objects)) and
                    all(value and not re.search(r"[\t\r\n;]", value)
                        for value in [*from_objects, *to_objects]),
                    f"timing inventory row {number} object sets are invalid")
            record = {
                "status": status,
                "path_count": int(count_raw),
                "negative_path_count": int(negative_raw),
                "worst_slack_ns": float(slack_raw),
                "startpoint": start,
                "endpoint": end,
                "startpoint_object_class": start_class,
                "endpoint_object_class": end_class,
                "from_objects": from_objects,
                "to_objects": to_objects,
            }
        records[path_class] = record
    require(set(records) == expected_classes,
            f"timing inventory path-class set is incomplete: {path}")
    negative = sum(record["negative_path_count"] for record in records.values())
    arc_inventory: list[dict[str, Any]] = []
    if subject in CHILDREN:
        require(arc_separator < len(lines) - 1,
                f"child timing inventory lacks measured port arcs: {path}")
        arc_header = (
            "arc_class\tport_family\tpath_delay\tdeclared_cardinality\t"
            "observed_cardinality\tpath_count\tworst_path_delay_ns\t"
            "worst_slack_ns\tsource_object_class\tendpoint_object_class\t"
            "object_names\tstartpoint\tendpoint"
        )
        require(lines[arc_separator + 1] == arc_header,
                f"child timing arc header drifted: {path}")
        try:
            contract_line_index = next(
                index for index in range(arc_separator + 2, len(lines))
                if lines[index].startswith("output_bit_driver_contract_id\t")
            )
            bit_separator = lines.index("output_bit_inventory",
                                        contract_line_index + 1)
        except (StopIteration, ValueError):
            contract_line_index = len(lines)
            bit_separator = len(lines)
        require(driver_contract is not None and
                contract_line_index < bit_separator < len(lines) - 1,
                f"child timing inventory lacks output-bit evidence: {path}")
        contract_fields = lines[contract_line_index].split("\t")
        require(contract_fields == [
                    "output_bit_driver_contract_id",
                    driver_contract["contract_id"],
                ], f"child timing driver-contract identity drifted: {path}")
        for number, line in enumerate(
                lines[arc_separator + 2:contract_line_index], arc_separator + 3):
            fields = line.split("\t")
            require(len(fields) == 13,
                    f"timing arc row {number} is malformed")
            (arc_class, family, path_delay, declared_raw, observed_raw,
             count_raw, delay_raw, slack_raw, source_class, endpoint_class,
             objects_raw, startpoint, endpoint) = fields
            require(arc_class in ARC_CLASSES and declared_raw.isdigit() and
                    observed_raw.isdigit() and count_raw.isdigit() and
                    ((FINITE_RE.fullmatch(delay_raw) is not None and
                      FINITE_RE.fullmatch(slack_raw) is not None) or
                     (arc_class == "clk_to_q" and delay_raw == "-" and
                      slack_raw == "-" and startpoint == "-" and
                      endpoint == "-")),
                    f"timing arc row {number} has non-canonical numeric data")
            object_names = [] if objects_raw == "-" else objects_raw.split(";")
            require(object_names == sorted(set(object_names)) and
                    all(value and not re.search(r"[\t\r\n;]", value)
                        for value in object_names),
                    f"timing arc row {number} object list is invalid")
            arc_inventory.append({
                "arc_class": arc_class,
                "port_family": family,
                "path_delay": path_delay,
                "declared_cardinality": int(declared_raw),
                "observed_cardinality": int(observed_raw),
                "path_count": int(count_raw),
                "worst_path_delay_ns": (
                    None if delay_raw == "-" else float(delay_raw)
                ),
                "worst_slack_ns": None if slack_raw == "-" else float(slack_raw),
                "source_object_class": source_class,
                "endpoint_object_class": endpoint_class,
                "object_names": object_names,
                "startpoint": None if startpoint == "-" else startpoint,
                "endpoint": None if endpoint == "-" else endpoint,
            })
        bit_header = (
            "port_family\tindex\tobject_name\tclassification\tconstant_value\t"
            "path_delay\tpath_count\tworst_path_delay_ns\tworst_slack_ns\t"
            "source_object_class\tendpoint_object_class\tstartpoint\tendpoint\t"
            "driver_binding_sha256"
        )
        require(lines[bit_separator + 1] == bit_header,
                f"child output-bit timing header drifted: {path}")
        output_bits: list[dict[str, Any]] = []
        for number, line in enumerate(lines[bit_separator + 2:], bit_separator + 3):
            fields = line.split("\t")
            require(len(fields) == 14,
                    f"output-bit timing row {number} is malformed")
            (family, index_raw, object_name, classification, constant_raw,
             path_delay, count_raw, delay_raw, slack_raw, source_class,
             endpoint_class, startpoint, endpoint, binding_sha) = fields
            require(index_raw.isdigit() and index_raw == str(int(index_raw)) and
                    count_raw.isdigit() and classification in OUTPUT_BIT_CLASSES and
                    path_delay == analysis and SHA256_RE.fullmatch(binding_sha),
                    f"output-bit timing row {number} identity is malformed")
            if classification == "DYNAMIC":
                require(constant_raw == "-" and
                        FINITE_RE.fullmatch(delay_raw) is not None and
                        FINITE_RE.fullmatch(slack_raw) is not None,
                        f"dynamic output-bit row {number} lacks timing")
                constant_value: int | None = None
                delay_value: float | None = float(delay_raw)
                slack_value: float | None = float(slack_raw)
            else:
                expected_constant = "0" if classification == "CONSTANT_0" else "1"
                require(constant_raw == expected_constant and count_raw == "0" and
                        delay_raw == "-" and slack_raw == "-" and
                        startpoint == "-" and endpoint == "-",
                        f"constant output-bit row {number} carries timing")
                constant_value = int(constant_raw)
                delay_value = None
                slack_value = None
            output_bits.append({
                "family": family,
                "index": int(index_raw),
                "object_name": object_name,
                "classification": classification,
                "constant_value": constant_value,
                "path_delay": path_delay,
                "path_count": int(count_raw),
                "worst_path_delay_ns": delay_value,
                "worst_slack_ns": slack_value,
                "source_object_class": source_class,
                "endpoint_object_class": endpoint_class,
                "startpoint": None if startpoint == "-" else startpoint,
                "endpoint": None if endpoint == "-" else endpoint,
                "driver_binding_sha256": binding_sha,
            })
        validate_arc_inventory(
            arc_inventory, module=subject, analysis=analysis,
            output_bit_inventory=output_bits, driver_contract=driver_contract,
        )
        query_budget = parse_query_progress(
            path.with_name(f"child-query-progress-{analysis}.tsv"),
            identity=identity, module=subject, analysis=analysis,
        )
        validate_query_budget(
            query_budget, module=subject, analysis=analysis,
            path_classes=records, arc_inventory=arc_inventory,
            output_bit_inventory=output_bits, driver_contract=driver_contract,
            require_artifact=False,
        )
    else:
        require(arc_separator == len(lines),
                f"top timing inventory unexpectedly carries child arcs: {path}")
    return {
        "analysis": analysis,
        "artifact": {},
        "path_classes": records,
        **({
            "arc_inventory": arc_inventory,
            "output_bit_driver_contract_id": driver_contract["contract_id"],
            "output_bit_inventory": output_bits,
            "query_budget": query_budget,
        } if subject in CHILDREN else {}),
        "negative_slack_count": negative,
    }


def _normalized_yosys_name(value: str) -> str:
    return value[1:] if value.startswith("\\") else value


def _registered_module_alias(value: str) -> str | None:
    targets = {
        "OooFpArithGate",
        *CHILDREN,
        *registry.EXPECTED_FP_OOC_UNKNOWN_PLACEHOLDERS,
    }
    for target in targets:
        if value == target or re.search(
            rf"(?:^|\\){re.escape(target)}(?:$|\\|\$)", value
        ):
            return target
    return None


def parse_yosys_census(path: Path) -> dict[str, dict[str, Any]]:
    value = load_json(path)
    raw_modules = value.get("modules")
    require(isinstance(raw_modules, dict) and raw_modules,
            "Yosys census JSON lacks modules")
    modules: dict[str, dict[str, Any]] = {}
    for raw_name, raw_record in raw_modules.items():
        name = _normalized_yosys_name(raw_name)
        require(name not in modules and isinstance(raw_record, dict),
                f"Yosys census duplicates/invalidates module {name}")
        raw_types = raw_record.get("num_cells_by_type", {})
        require(isinstance(raw_types, dict),
                f"Yosys census module {name} lacks num_cells_by_type")
        cell_types: dict[str, int] = {}
        for raw_type, raw_count in raw_types.items():
            cell_type = _normalized_yosys_name(raw_type)
            require(cell_type not in cell_types and
                    not isinstance(raw_count, bool) and isinstance(raw_count, int) and
                    raw_count >= 0,
                    f"Yosys census cell type is invalid: {name}/{cell_type}")
            cell_types[cell_type] = raw_count
        raw_cells = raw_record.get("num_cells", sum(cell_types.values()))
        require(not isinstance(raw_cells, bool) and isinstance(raw_cells, int) and
                raw_cells == sum(cell_types.values()),
                f"Yosys census num_cells is detached: {name}")
        area = raw_record.get("area")
        if area is not None:
            area = finite_number(area, f"Yosys census {name}.area", nonnegative=True)
        modules[name] = {
            "num_cells": raw_cells,
            "num_cells_by_type": cell_types,
            "area": area,
        }
    return modules


def recursive_design_census(modules: dict[str, dict[str, Any]],
                            *, top: str,
                            boundary_modules: set[str] | None = None
                            ) -> tuple[dict[str, int], dict[str, int]]:
    require(top in modules, f"Yosys census lacks top module {top}")
    module_instances: dict[str, int] = {top: 1}
    leaf_cells: dict[str, int] = {}
    visiting: set[str] = set()

    boundaries = boundary_modules or set()

    def walk(module: str, multiplier: int) -> None:
        require(module not in visiting, f"Yosys hierarchy cycle at {module}")
        visiting.add(module)
        for cell_type, count in modules[module]["num_cells_by_type"].items():
            total = multiplier * count
            alias = _registered_module_alias(cell_type)
            if cell_type in modules or cell_type in boundaries or alias in boundaries:
                module_instances[cell_type] = module_instances.get(cell_type, 0) + total
                if (cell_type in modules and alias not in boundaries and
                        cell_type not in boundaries and
                        modules[cell_type]["num_cells"] > 0):
                    walk(cell_type, total)
            else:
                leaf_cells[cell_type] = leaf_cells.get(cell_type, 0) + total
        visiting.remove(module)

    walk(top, 1)
    return module_instances, leaf_cells


def parse_standard_cell_library(path: Path) -> set[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise EvidenceError(f"cannot read bound standard-cell Liberty: {exc}") from exc
    cells = {
        match.group(1) for match in re.finditer(
            r"(?m)^\s*cell\s*\(\s*\"?([^\"\s()]+)\"?\s*\)\s*\{", text
        )
    }
    require(cells and all(not name.startswith("$") for name in cells),
            "bound standard-cell Liberty has no canonical leaf whitelist")
    return cells


def build_stdlib_whitelist(*, identity: dict[str, Any],
                           standard_cell_lib: Path) -> dict[str, Any]:
    validate_identity(identity)
    require(sha256_file(standard_cell_lib) ==
            identity["standard_cell_lib_sha256"],
            "standard-cell Liberty differs from run identity")
    payload = {
        "schema": STDLIB_WHITELIST_SCHEMA,
        "status": "PASS",
        "run_identity": identity,
        "standard_cell_lib_sha256": sha256_file(standard_cell_lib),
        "cells": sorted(parse_standard_cell_library(standard_cell_lib)),
    }
    payload["whitelist_id"] = canonical_sha256(payload)
    return payload


def validate_stdlib_whitelist(value: Any, *, expected_identity: dict[str, Any]
                              ) -> set[str]:
    require(isinstance(value, dict) and set(value) == {
        "schema", "status", "run_identity", "standard_cell_lib_sha256",
        "cells", "whitelist_id",
    }, "standard-cell leaf whitelist key set drifted")
    require(value["schema"] == STDLIB_WHITELIST_SCHEMA and
            value["status"] == "PASS" and
            value["run_identity"] == expected_identity and
            value["standard_cell_lib_sha256"] ==
            expected_identity["standard_cell_lib_sha256"],
            "standard-cell leaf whitelist identity is detached")
    cells = value["cells"]
    require(isinstance(cells, list) and cells == sorted(set(cells)) and cells and
            all(isinstance(name, str) and name and not name.startswith("$")
                for name in cells), "standard-cell leaf whitelist is invalid")
    unsigned = dict(value)
    identifier = unsigned.pop("whitelist_id")
    require(identifier == canonical_sha256(unsigned),
            "standard-cell leaf whitelist identifier is stale")
    return set(cells)


def _mapped_leaf_census(modules: dict[str, dict[str, Any]], *, top: str,
                        whitelist: set[str], boundary_modules: set[str]
                        ) -> dict[str, int]:
    _, leaves = recursive_design_census(
        modules, top=top, boundary_modules=boundary_modules
    )
    for cell_type in leaves:
        require(not cell_type.startswith("$") and
                GENERIC_CELL_RE.match(cell_type) is None,
                f"unmapped dollar generic cell remains: {cell_type}")
        require(cell_type in whitelist,
                f"mapped leaf is absent from the bound stdlib: {cell_type}")
    require(leaves, f"{top} mapped leaf census is empty")
    return dict(sorted(leaves.items()))


def _normalized_design_modules(path: Path) -> dict[str, dict[str, Any]]:
    value = load_json(path)
    raw_modules = value.get("modules")
    require(isinstance(raw_modules, dict) and raw_modules,
            "Yosys retained design JSON lacks modules")
    modules: dict[str, dict[str, Any]] = {}
    for raw_name, record in raw_modules.items():
        name = _normalized_yosys_name(raw_name)
        require(name not in modules and isinstance(record, dict),
                f"retained design JSON duplicates module {name}")
        modules[name] = record
    return modules


def _raw_port_rows(subject: str, ports_raw: Any) -> list[dict[str, Any]]:
    """Retain every Yosys port record without losing split-bit metadata."""

    require(isinstance(ports_raw, dict) and ports_raw,
            f"retained design JSON lacks {subject} ports")
    allowed_keys = {"direction", "bits", "offset", "upto", "signed"}
    normalized_names: set[str] = set()
    rows: list[dict[str, Any]] = []
    for raw_name, record in sorted(ports_raw.items()):
        require(isinstance(raw_name, str) and raw_name and
                isinstance(record, dict) and set(record) <= allowed_keys,
                f"retained design port record is invalid: {subject}/{raw_name}")
        name = _normalized_yosys_name(raw_name)
        require(name and name not in normalized_names,
                f"retained design duplicates normalized port {subject}/{name}")
        normalized_names.add(name)
        direction = record.get("direction")
        bits = record.get("bits")
        require(direction in {"input", "output", "inout"} and
                isinstance(bits, list) and bits and all(
                    (isinstance(bit, int) and not isinstance(bit, bool)) or
                    (isinstance(bit, str) and bit in {"0", "1", "x", "z"})
                    for bit in bits
                ), f"retained design port is invalid: {subject}/{name}")
        row: dict[str, Any] = {
            "name": raw_name,
            "normalized_name": name,
            "direction": direction,
            "width": len(bits),
            "bits": list(bits),
        }
        if "offset" in record:
            offset = record["offset"]
            require(isinstance(offset, int) and not isinstance(offset, bool) and
                    offset >= 0,
                    f"retained design port offset is invalid: {subject}/{name}")
            row["offset"] = offset
        for attribute in ("upto", "signed"):
            if attribute in record:
                value = record[attribute]
                require(isinstance(value, int) and not isinstance(value, bool) and
                        value in {0, 1},
                        f"retained design port {attribute} is invalid: "
                        f"{subject}/{name}")
                row[attribute] = value
        rows.append(row)
    return rows


def canonicalize_retained_ports(
    *, subject: str, ports_raw: Any,
    child_contract: dict[str, Any] | None = None,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    """Canonicalize Yosys post-split child ports from the Registry contract.

    ``splitnets -format __v -ports`` is serialized by Yosys JSON as
    ``family_<decimal-index>_``.  The raw representation remains in the
    manifest; this function only creates a deterministic family view after it
    has proved complete zero-based coverage and offset agreement.
    """

    raw_ports = _raw_port_rows(subject, ports_raw)
    if subject not in CHILDREN:
        ports = [{
            "name": row["normalized_name"],
            "direction": row["direction"],
            "width": row["width"],
            "bits": row["bits"],
        } for row in raw_ports]
        mapping = [{
            "raw_name": row["name"],
            "normalized_raw_name": row["normalized_name"],
            "canonical_name": row["normalized_name"],
            "representation": "identity_no_child_contract",
            "indices": list(range(row["width"])),
        } for row in raw_ports]
        return raw_ports, ports, {
            "schema": PORT_CANONICALIZATION_SCHEMA,
            "mode": "identity_no_child_contract",
            "raw_port_count": len(raw_ports),
            "raw_bit_count": sum(row["width"] for row in raw_ports),
            "canonical_port_count": len(ports),
            "canonical_bit_count": sum(row["width"] for row in ports),
            "raw_to_canonical": mapping,
        }

    contract = child_contract or projection()["child_contracts"][subject]
    expected = {
        **{name: ("input", width)
           for name, width in contract["input_ports"].items()},
        **{name: ("output", width)
           for name, width in contract["output_ports"].items()},
    }
    require(expected and all(
        isinstance(name, str) and name and
        direction in {"input", "output"} and
        isinstance(width, int) and not isinstance(width, bool) and width > 0
        for name, (direction, width) in expected.items()
    ), f"Registry {subject} port-family contract is invalid")
    family_state = {
        family: {"unsplit": None, "split": {}}
        for family in expected
    }
    raw_to_canonical: list[dict[str, Any]] = []
    for row in raw_ports:
        name = row["normalized_name"]
        if name in expected:
            family = name
            direction, declared_width = expected[family]
            require(row["direction"] == direction,
                    f"retained {subject} port direction drifted: {name}")
            require(row["width"] == declared_width,
                    f"retained {subject} unsplit port width drifted: {name}")
            require(row.get("offset", 0) == 0,
                    f"retained {subject} unsplit port offset drifted: {name}")
            require(row.get("upto", 0) == 0 and row.get("signed", 0) == 0,
                    f"retained {subject} unsplit port orientation/sign drifted: "
                    f"{name}")
            state = family_state[family]
            require(state["unsplit"] is None and not state["split"],
                    f"retained {subject} split/unsplit collision: {family}")
            state["unsplit"] = row
            raw_to_canonical.append({
                "raw_name": row["name"],
                "normalized_raw_name": name,
                "canonical_name": family,
                "representation": "unsplit",
                "indices": list(range(declared_width)),
            })
            continue

        matches: list[tuple[str, str]] = []
        for family in expected:
            match = re.fullmatch(rf"{re.escape(family)}_([0-9]+)_", name)
            if match is not None:
                matches.append((family, match.group(1)))
        require(len(matches) == 1,
                f"retained {subject} port is outside Registry families: {name}")
        family, index_text = matches[0]
        index = int(index_text)
        require(index_text == str(index),
                f"retained {subject} split index is noncanonical: {name}")
        direction, declared_width = expected[family]
        require(index < declared_width,
                f"retained {subject} split index is out of range: {name}")
        require(row["direction"] == direction,
                f"retained {subject} split direction drifted: {name}")
        require(row["width"] == 1,
                f"retained {subject} split port is not scalar: {name}")
        offset = row.get("offset")
        require((index == 0 and offset in {None, 0}) or
                (index > 0 and offset == index),
                f"retained {subject} split offset/index drifted: {name}")
        state = family_state[family]
        require(state["unsplit"] is None,
                f"retained {subject} split/unsplit collision: {family}")
        require(index not in state["split"],
                f"retained {subject} duplicate split index: {family}[{index}]")
        state["split"][index] = row
        raw_to_canonical.append({
            "raw_name": row["name"],
            "normalized_raw_name": name,
            "canonical_name": family,
            "representation": "split_bit",
            "indices": [index],
        })

    ports: list[dict[str, Any]] = []
    for family in sorted(expected):
        direction, declared_width = expected[family]
        state = family_state[family]
        if state["unsplit"] is not None:
            bits = list(state["unsplit"]["bits"])
        else:
            expected_indices = set(range(declared_width))
            actual_indices = set(state["split"])
            require(actual_indices == expected_indices,
                    f"retained {subject} split coverage drifted: {family} "
                    f"missing={sorted(expected_indices - actual_indices)} "
                    f"extra={sorted(actual_indices - expected_indices)}")
            bits = [state["split"][index]["bits"][0]
                    for index in range(declared_width)]
        ports.append({
            "name": family,
            "direction": direction,
            "width": declared_width,
            "bits": bits,
        })
    raw_bit_count = sum(row["width"] for row in raw_ports)
    canonical_bit_count = sum(row["width"] for row in ports)
    expected_bit_count = sum(width for _, width in expected.values())
    require(raw_bit_count == expected_bit_count == canonical_bit_count,
            f"retained {subject} canonical port bit accounting drifted")
    return raw_ports, ports, {
        "schema": PORT_CANONICALIZATION_SCHEMA,
        "mode": "registry_child_family_contract",
        "raw_port_count": len(raw_ports),
        "raw_bit_count": raw_bit_count,
        "canonical_port_count": len(ports),
        "canonical_bit_count": canonical_bit_count,
        "raw_to_canonical": sorted(
            raw_to_canonical,
            key=lambda row: (row["normalized_raw_name"], row["raw_name"]),
        ),
    }


def port_manifest_summary(manifest: dict[str, Any]) -> dict[str, Any]:
    canonicalization = manifest["port_canonicalization"]
    return {
        "schema": canonicalization["schema"],
        "raw_port_count": canonicalization["raw_port_count"],
        "raw_bit_count": canonicalization["raw_bit_count"],
        "canonical_port_count": canonicalization["canonical_port_count"],
        "canonical_bit_count": canonicalization["canonical_bit_count"],
        "mapping_count": len(canonicalization["raw_to_canonical"]),
    }


YOSYS_CANONICAL_TRUE = "00000000000000000000000000000001"


def _validate_stdlib_blackbox_definition(
    *, cell_type: str, definition: dict[str, Any],
) -> None:
    """Prove that a retained same-name stdlib module is only a leaf shell."""

    attributes = definition.get("attributes")
    require(isinstance(attributes, dict) and
            attributes.get("blackbox") == YOSYS_CANONICAL_TRUE,
            f"retained stdlib definition is not a canonical blackbox: "
            f"{cell_type}")
    cells = definition.get("cells")
    require(isinstance(cells, dict) and not cells,
            f"retained stdlib blackbox has an implementation body: {cell_type}")


def _manifest_payload(*, identity: dict[str, Any], subject: str,
                      netlist_sha256: str, netlist_size_bytes: int,
                      design_json: Path, census_json: Path,
                      stdlib_whitelist: Path, evidence_dir: Path
                      ) -> dict[str, Any]:
    root = canonical_evidence_dir(evidence_dir)
    require(isinstance(netlist_sha256, str) and
            SHA256_RE.fullmatch(netlist_sha256) is not None,
            f"{subject} retained netlist digest is invalid")
    positive_integer(netlist_size_bytes, f"{subject} retained netlist size")
    whitelist_value = load_json(stdlib_whitelist)
    whitelist = validate_stdlib_whitelist(
        whitelist_value, expected_identity=identity
    )
    design_modules = _normalized_design_modules(design_json)
    stdlib_blackbox_definitions = sorted(set(design_modules) & whitelist)
    for cell_type in stdlib_blackbox_definitions:
        _validate_stdlib_blackbox_definition(
            cell_type=cell_type, definition=design_modules[cell_type],
        )
    census_modules = parse_yosys_census(census_json)
    require(subject in design_modules and subject in census_modules,
            f"retained mapped design lacks subject {subject}")
    selected_projection = projection()
    boundary_modules = (
        set() if subject in CHILDREN else
        set(CHILDREN) |
        set(selected_projection["expected_unknown_macro_instances"])
    )
    census_leaves = _mapped_leaf_census(
        census_modules, top=subject, whitelist=whitelist,
        boundary_modules=boundary_modules,
    )
    ports_raw = design_modules[subject].get("ports")
    child_contract = (
        selected_projection["child_contracts"][subject]
        if subject in CHILDREN else None
    )
    raw_ports, ports, port_canonicalization = canonicalize_retained_ports(
        subject=subject, ports_raw=ports_raw, child_contract=child_contract,
    )
    if subject in CHILDREN:
        contract = child_contract
        require(contract is not None,
                f"Registry lacks retained port contract for {subject}")
        actual = {row["name"]: (row["direction"], row["width"]) for row in ports}
        expected = {
            **{name: ("input", width) for name, width in
               contract["input_ports"].items()},
            **{name: ("output", width) for name, width in
               contract["output_ports"].items()},
        }
        require(actual == expected,
                f"retained {subject} port manifest differs from Registry")
    else:
        require(any(row["name"] == "clk" and row["direction"] == "input"
                    for row in ports), "NpcTop retained port manifest lacks clk")

    instances: list[dict[str, str]] = []
    leaf_cells: list[dict[str, str]] = []
    visiting: set[str] = set()

    def walk(module: str, prefix: str) -> None:
        require(module not in visiting, f"retained design hierarchy cycle at {module}")
        visiting.add(module)
        cells = design_modules[module].get("cells", {})
        require(isinstance(cells, dict),
                f"retained design module {module} lacks a cell dictionary")
        for raw_instance, record in sorted(cells.items()):
            require(isinstance(record, dict) and isinstance(record.get("type"), str),
                    f"retained instance is invalid: {module}/{raw_instance}")
            instance = _normalized_yosys_name(raw_instance)
            cell_type = _normalized_yosys_name(record["type"])
            path = f"{prefix}/{instance}" if prefix else instance
            alias = _registered_module_alias(cell_type)
            if alias in boundary_modules:
                implementation_class = (
                    "known_ooc_macro" if alias in CHILDREN else
                    "unknown_placeholder"
                )
            elif cell_type in whitelist:
                implementation_class = "standard_cell_leaf"
                leaf_cells.append({"instance_path": path, "cell_type": cell_type})
            elif cell_type in design_modules:
                attributes = design_modules[cell_type].get("attributes", {})
                require(not isinstance(attributes, dict) or
                        "blackbox" not in attributes,
                        f"retained blackbox cell is absent from bound stdlib whitelist: {cell_type}")
                implementation_class = "hierarchical_rtl"
            else:
                require(not cell_type.startswith("$") and
                        GENERIC_CELL_RE.match(cell_type) is None,
                        f"retained manifest contains dollar generic {cell_type}")
                require(cell_type in whitelist,
                        f"retained manifest contains non-stdlib leaf {cell_type}")
                implementation_class = "standard_cell_leaf"
                leaf_cells.append({"instance_path": path, "cell_type": cell_type})
            instances.append({
                "instance_path": path,
                "cell_type": cell_type,
                "implementation_class": implementation_class,
            })
            if implementation_class == "hierarchical_rtl":
                walk(cell_type, path)
        visiting.remove(module)

    walk(subject, subject)
    require(instances and leaf_cells,
            f"retained {subject} manifest lacks instances or mapped leaves")
    manifest_census: dict[str, int] = {}
    for row in leaf_cells:
        manifest_census[row["cell_type"]] = manifest_census.get(row["cell_type"], 0) + 1
    require(dict(sorted(manifest_census.items())) == census_leaves,
            f"retained {subject} leaf instances disagree with Yosys census")
    payload = {
        "schema": NETLIST_MANIFEST_SCHEMA,
        "status": "PASS",
        "subject": subject,
        "run_identity": identity,
        "netlist_sha256": netlist_sha256,
        "netlist_size_bytes": netlist_size_bytes,
        "inputs": {
            "design_json": artifact(design_json, evidence_dir=root),
            "census_json": artifact(census_json, evidence_dir=root),
            "stdlib_whitelist": artifact(stdlib_whitelist, evidence_dir=root),
        },
        "raw_ports": raw_ports,
        "ports": ports,
        "port_canonicalization": port_canonicalization,
        "instances": instances,
        "leaf_cells": leaf_cells,
        "leaf_cell_census": dict(sorted(manifest_census.items())),
    }
    payload["manifest_id"] = canonical_sha256(payload)
    return payload


def validate_netlist_manifest(
    value: Any, *, expected_identity: dict[str, Any], expected_subject: str,
    evidence_dir: Path, expected_netlist_sha256: str | None = None,
    expected_netlist_size_bytes: int | None = None,
) -> dict[str, Any]:
    required = {
        "schema", "status", "subject", "run_identity", "netlist_sha256",
        "netlist_size_bytes", "inputs", "raw_ports", "ports",
        "port_canonicalization", "instances", "leaf_cells",
        "leaf_cell_census", "manifest_id",
    }
    require(isinstance(value, dict) and value.get("schema") ==
            NETLIST_MANIFEST_SCHEMA and value.get("status") == "PASS" and
            value.get("subject") == expected_subject and
            value.get("run_identity") == expected_identity and
            set(value) == required,
            f"{expected_subject} retained netlist manifest identity is detached")
    if expected_netlist_sha256 is not None:
        require(value.get("netlist_sha256") == expected_netlist_sha256,
                f"{expected_subject} retained manifest netlist digest drifted")
    if expected_netlist_size_bytes is not None:
        require(value.get("netlist_size_bytes") == expected_netlist_size_bytes,
                f"{expected_subject} retained manifest netlist size drifted")
    for record in value.get("inputs", {}).values():
        validate_receipt(record, evidence_dir=evidence_dir)
    root = canonical_evidence_dir(evidence_dir)
    expected = _manifest_payload(
        identity=expected_identity, subject=expected_subject,
        netlist_sha256=value.get("netlist_sha256"),
        netlist_size_bytes=value.get("netlist_size_bytes"),
        design_json=root / value["inputs"]["design_json"]["path"],
        census_json=root / value["inputs"]["census_json"]["path"],
        stdlib_whitelist=root / value["inputs"]["stdlib_whitelist"]["path"],
        evidence_dir=root,
    )
    require(value == expected,
            f"{expected_subject} retained netlist manifest drifted")
    return value


def _extract_liberty_named_groups(text: str, group: str) -> list[tuple[str, str]]:
    """Extract complete Liberty groups without trusting line-local regexes."""

    heading = re.compile(
        rf'^\s*{re.escape(group)}\s*\(\s*"?([^"\s()]+)"?\s*\)\s*\{{'
    )
    result: list[tuple[str, str]] = []
    active_name: str | None = None
    active_lines: list[str] = []
    depth = 0
    for line in text.splitlines(keepends=True):
        if active_name is None:
            match = heading.fullmatch(line.rstrip("\n"))
            if match is None:
                continue
            active_name = match.group(1)
            active_lines = [line]
            depth = line.count("{") - line.count("}")
        else:
            active_lines.append(line)
            depth += line.count("{") - line.count("}")
        if active_name is not None and depth == 0:
            result.append((active_name, "".join(active_lines)))
            active_name = None
            active_lines = []
    require(active_name is None, f"truncated Liberty {group} group")
    return result


def _strip_liberty_comments(text: str) -> str:
    """Remove Liberty comments without changing quoted string contents."""

    result: list[str] = []
    index = 0
    in_string = False
    while index < len(text):
        char = text[index]
        if in_string:
            result.append(char)
            if char == "\\" and index + 1 < len(text):
                index += 1
                result.append(text[index])
            elif char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            result.append(char)
            index += 1
            continue
        if text.startswith("//", index):
            end = text.find("\n", index + 2)
            if end < 0:
                result.extend(" " * (len(text) - index))
                break
            result.extend(" " * (end - index))
            index = end
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            require(end >= 0, "unterminated Liberty block comment")
            comment = text[index:end + 2]
            result.extend(
                "\n" if comment_char == "\n" else " "
                for comment_char in comment
            )
            index = end + 2
            continue
        result.append(char)
        index += 1
    require(not in_string, "unterminated Liberty quoted string")
    return "".join(result)


def _extract_liberty_group_blocks(text: str, group: str) -> list[str]:
    """Extract anonymous/named Liberty groups across arbitrary trivia.

    Unlike the legacy line-oriented helper, this scanner treats whitespace and
    comments between ``group``, ``(...)`` and ``{...}`` identically.  That is
    required for security-bearing timing-group classification: ``timing()``,
    ``timing ( )`` and a newline/comment-separated heading must not produce
    different evidence.
    """

    cleaned = _strip_liberty_comments(text)

    def skip_space(position: int) -> int:
        while position < len(cleaned) and cleaned[position].isspace():
            position += 1
        return position

    def matching(position: int, opening: str, closing: str) -> int:
        require(position < len(cleaned) and cleaned[position] == opening,
                f"Liberty {group} group lacks {opening}")
        depth = 0
        in_string = False
        cursor = position
        while cursor < len(cleaned):
            char = cleaned[cursor]
            if in_string:
                if char == "\\" and cursor + 1 < len(cleaned):
                    cursor += 2
                    continue
                if char == '"':
                    in_string = False
            elif char == '"':
                in_string = True
            elif char == opening:
                depth += 1
            elif char == closing:
                depth -= 1
                if depth == 0:
                    return cursor
            cursor += 1
        raise EvidenceError(f"truncated Liberty {group} group")

    result: list[str] = []
    token = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
    index = 0
    while index < len(cleaned):
        if cleaned[index] == '"':
            index += 1
            while index < len(cleaned):
                if cleaned[index] == "\\" and index + 1 < len(cleaned):
                    index += 2
                    continue
                if cleaned[index] == '"':
                    index += 1
                    break
                index += 1
            continue
        match = token.match(cleaned, index)
        if match is None:
            index += 1
            continue
        index = match.end()
        if match.group(0) != group:
            continue
        heading_start = match.start()
        cursor = skip_space(index)
        if cursor >= len(cleaned) or cleaned[cursor] != "(":
            continue
        close_paren = matching(cursor, "(", ")")
        cursor = skip_space(close_paren + 1)
        if cursor >= len(cleaned) or cleaned[cursor] != "{":
            continue
        close_brace = matching(cursor, "{", "}")
        result.append(cleaned[heading_start:close_brace + 1])
        index = close_brace + 1
    return result


def _validate_literal_output_timing_groups(
        block: str, *, cell_type: str, pin: str) -> None:
    """Accept only absent or isolated Liberty ``tied_off`` SI groups."""

    timing_groups = _extract_liberty_group_blocks(block, "timing")
    forbidden_attributes = (
        "related_pin", "timing_type", "when", "sdf_cond", "sdf_edges",
    )
    forbidden_groups = (
        "cell_rise", "cell_fall", "rise_transition", "fall_transition",
        "rise_constraint", "fall_constraint", "retaining_rise",
        "retaining_fall",
    )
    allowed_si_groups = (
        "output_current_rise", "output_current_fall",
        "steady_state_current_high", "steady_state_current_low",
    )
    allowed_si_attributes = (
        "steady_state_resistance_high", "steady_state_resistance_low",
    )
    for timing in timing_groups:
        for attribute in forbidden_attributes:
            require(re.search(
                rf"\b{re.escape(attribute)}\s*:", timing
            ) is None,
                    "literal stdlib tied_off group carries ordinary timing "
                    f"attribute {attribute}: {cell_type}/{pin}")
        for nested_group in forbidden_groups:
            require(not _extract_liberty_group_blocks(timing, nested_group),
                    "literal stdlib tied_off group carries ordinary timing "
                    f"group {nested_group}: {cell_type}/{pin}")

        opening = timing.find("{")
        closing = timing.rfind("}")
        require(opening >= 0 and closing > opening,
                f"literal stdlib timing group is malformed: {cell_type}/{pin}")
        residual = timing[opening + 1:closing]
        for nested_group in allowed_si_groups:
            for nested in _extract_liberty_group_blocks(
                    residual, nested_group):
                residual = residual.replace(nested, " ", 1)
        tied_off = re.findall(
            r"\btied_off\s*:\s*([^;]+);", residual, re.IGNORECASE
        )
        require(len(tied_off) == 1 and tied_off[0].strip().lower() == "true",
                "literal stdlib output timing must be an isolated "
                f"tied_off:true SI group: {cell_type}/{pin}")
        residual, tied_count = re.subn(
            r"\btied_off\s*:\s*true\s*;", " ", residual,
            flags=re.IGNORECASE,
        )
        require(tied_count == 1,
                "literal stdlib timing group has a non-canonical tied_off "
                f"attribute: {cell_type}/{pin}")
        for attribute in allowed_si_attributes:
            values = re.findall(
                rf"\b{attribute}\s*:\s*([^;]+);", residual,
                re.IGNORECASE,
            )
            for value in values:
                try:
                    numeric = float(value.strip())
                except ValueError as exc:
                    raise EvidenceError(
                        "literal stdlib tied_off resistance is not numeric: "
                        f"{cell_type}/{pin}/{attribute}"
                    ) from exc
                require(math.isfinite(numeric) and numeric >= 0.0,
                        "literal stdlib tied_off resistance is invalid: "
                        f"{cell_type}/{pin}/{attribute}")
            residual = re.sub(
                rf"\b{attribute}\s*:\s*[^;]+;", " ", residual,
                flags=re.IGNORECASE,
            )
        require(not residual.strip(),
                f"literal stdlib tied_off group carries unsupported or ordinary semantics: {cell_type}/{pin}")


def _stdlib_output_pin_functions(
    standard_cell_lib: Path, cell_types: set[str],
) -> dict[str, dict[str, str]]:
    """Return exact bound output-pin functions for the requested stdcells."""

    try:
        text = standard_cell_lib.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise EvidenceError(f"cannot read bound standard-cell Liberty: {exc}") from exc
    cells = dict(_extract_liberty_named_groups(text, "cell"))
    require(cell_types <= set(cells),
            f"driver cell types missing from bound stdlib: {sorted(cell_types - set(cells))}")
    result: dict[str, dict[str, str]] = {}
    for cell_type in sorted(cell_types):
        pins = dict(_extract_liberty_named_groups(cells[cell_type], "pin"))
        require(pins, f"bound stdlib cell has no signal pins: {cell_type}")
        outputs: dict[str, str] = {}
        for pin, block in pins.items():
            direction = re.search(
                r"^\s*direction\s*:\s*([^;]+);", block, re.MULTILINE
            )
            if direction is None or direction.group(1).strip() != "output":
                continue
            require(re.search(r"^\s*three_state\s*:", block, re.MULTILINE) is None,
                    f"tri-state stdlib output is not a deterministic driver: "
                    f"{cell_type}/{pin}")
            function = re.search(
                r'^\s*function\s*:\s*"([^"]+)"\s*;', block, re.MULTILINE
            )
            require(function is not None,
                    f"stdlib output pin lacks a bound function: {cell_type}/{pin}")
            function_text = function.group(1).strip()
            if re.sub(r"\s+", "", function_text) in {"0", "1"}:
                _validate_literal_output_timing_groups(
                    block, cell_type=cell_type, pin=pin,
                )
            outputs[pin] = function_text
        require(outputs, f"bound stdlib cell has no output functions: {cell_type}")
        result[cell_type] = outputs
    return result


def _canonical_output_bit_map(
    manifest: dict[str, Any], *, module: str,
) -> dict[tuple[str, int], dict[str, Any]]:
    """Map every Registry output member to its raw/OpenSTA object and net."""

    contract = projection()["child_contracts"][module]
    outputs = contract["output_ports"]
    canonical_ports = {
        row["name"]: row for row in manifest["ports"]
        if row["direction"] == "output"
    }
    mapping: dict[tuple[str, int], dict[str, Any]] = {}
    for row in manifest["port_canonicalization"]["raw_to_canonical"]:
        family = row["canonical_name"]
        if family not in outputs:
            continue
        representation = row["representation"]
        normalized_raw = row["normalized_raw_name"]
        for index in row["indices"]:
            key = (family, index)
            require(key not in mapping,
                    f"{module} output bit maps to multiple raw ports: {family}[{index}]")
            object_name = (
                family if outputs[family] == 1 else
                normalized_raw if representation == "split_bit" else
                f"{family}[{index}]"
            )
            mapping[key] = {
                "raw_port_name": normalized_raw,
                "opensta_object_name": object_name,
                "net": canonical_ports[family]["bits"][index],
            }
    expected = {
        (family, index)
        for family, width in outputs.items() for index in range(width)
    }
    require(set(mapping) == expected,
            f"{module} output-bit raw/OpenSTA mapping is incomplete")
    return mapping


def classify_retained_output_bits(
    *, module: str, manifest: dict[str, Any], design_json: Path,
    standard_cell_lib: Path, whitelist: set[str], bindings: dict[str, Any],
) -> list[dict[str, Any]]:
    """Pure structural classifier used by production and frozen-run tests."""

    design_modules = _normalized_design_modules(design_json)
    require(module in design_modules, f"retained design lacks child {module}")
    cells = design_modules[module].get("cells")
    require(isinstance(cells, dict) and cells,
            f"{module} retained design lacks mapped cells")
    bit_map = _canonical_output_bit_map(manifest, module=module)
    output_nets = {entry["net"] for entry in bit_map.values()}
    drivers_by_net: dict[Any, list[dict[str, str]]] = {}
    for raw_instance, raw_cell in sorted(cells.items()):
        require(isinstance(raw_cell, dict),
                f"{module} retained cell is malformed: {raw_instance}")
        cell_type = _normalized_yosys_name(raw_cell.get("type", ""))
        directions = raw_cell.get("port_directions")
        connections = raw_cell.get("connections")
        require(isinstance(directions, dict) and isinstance(connections, dict),
                f"{module} retained cell lacks port directions/connections: "
                f"{raw_instance}")
        for raw_pin, direction in directions.items():
            if direction != "output":
                continue
            pin = _normalized_yosys_name(raw_pin)
            connected = connections.get(raw_pin)
            require(isinstance(connected, list) and connected,
                    f"{module} output pin connection is malformed: "
                    f"{raw_instance}/{pin}")
            require(len(connected) == 1,
                    f"{module} stdlib output pin is not scalar: "
                    f"{raw_instance}/{pin}")
            if connected[0] in output_nets:
                drivers_by_net.setdefault(connected[0], []).append({
                    "driver_instance": _normalized_yosys_name(raw_instance),
                    "driver_cell_type": cell_type,
                    "driver_pin": pin,
                })
    used_cell_types = {
        row["driver_cell_type"]
        for rows in drivers_by_net.values() for row in rows
    }
    require(used_cell_types <= whitelist,
            f"{module} output driver is absent from bound stdlib whitelist: "
            f"{sorted(used_cell_types - whitelist)}")
    functions = _stdlib_output_pin_functions(standard_cell_lib, used_cell_types)
    bits: list[dict[str, Any]] = []
    for (family, index), mapped in sorted(bit_map.items()):
        net = mapped["net"]
        require(isinstance(net, int) and not isinstance(net, bool),
                f"{module} output bit is not driven by a mapped net: "
                f"{family}[{index}]")
        drivers = drivers_by_net.get(net, [])
        require(len(drivers) == 1,
                f"{module} output bit has {len(drivers)} mapped drivers: "
                f"{family}[{index}]")
        driver = drivers[0]
        pin_functions = functions.get(driver["driver_cell_type"], {})
        require(driver["driver_pin"] in pin_functions,
                f"{module} output driver pin lacks a bound stdlib function: "
                f"{driver['driver_cell_type']}/{driver['driver_pin']}")
        function = pin_functions[driver["driver_pin"]]
        normalized_function = re.sub(r"\s+", "", function)
        if normalized_function == "0":
            classification, value = "CONSTANT_0", 0
        elif normalized_function == "1":
            classification, value = "CONSTANT_1", 1
        else:
            classification, value = "DYNAMIC", None
        bit = {
            "family": family,
            "index": index,
            **mapped,
            **driver,
            "stdlib_function": function,
            "stdlib_function_sha256": canonical_sha256(function),
            "classification": classification,
            "value": value,
        }
        bit["driver_binding_sha256"] = canonical_sha256({
            "bindings": bindings, "bit": bit,
        })
        bits.append(bit)
    return bits


def build_output_bit_driver_contract(
    *, identity: dict[str, Any], module: str, design_json: Path,
    netlist_manifest: Path, stdlib_whitelist: Path,
    standard_cell_lib: Path, evidence_dir: Path,
) -> dict[str, Any]:
    """Classify every mapped output bit from one retained, bound driver."""

    validate_identity(identity)
    require(module in CHILDREN, f"unknown OOC child: {module}")
    root = canonical_evidence_dir(evidence_dir)
    manifest = validate_netlist_manifest(
        load_json(netlist_manifest), expected_identity=identity,
        expected_subject=module, evidence_dir=root,
    )
    require(manifest["inputs"]["design_json"] ==
            artifact(design_json.resolve(), evidence_dir=root),
            f"{module} driver contract design JSON is detached from retained manifest")
    whitelist_value = load_json(stdlib_whitelist)
    whitelist = validate_stdlib_whitelist(
        whitelist_value, expected_identity=identity
    )
    require(manifest["inputs"]["stdlib_whitelist"] ==
            artifact(stdlib_whitelist.resolve(), evidence_dir=root),
            f"{module} driver contract whitelist is detached from retained manifest")
    require(sha256_file(standard_cell_lib) ==
            identity["standard_cell_lib_sha256"],
            "driver contract stdlib differs from run identity")
    bindings = {
        "run_identity_sha256": canonical_sha256(identity),
        "netlist_sha256": manifest["netlist_sha256"],
        "netlist_size_bytes": manifest["netlist_size_bytes"],
        "netlist_manifest": artifact(netlist_manifest.resolve(), evidence_dir=root),
        "design_json": artifact(design_json.resolve(), evidence_dir=root),
        "stdlib_whitelist": artifact(stdlib_whitelist.resolve(), evidence_dir=root),
        "whitelist_id": whitelist_value["whitelist_id"],
        "standard_cell_lib_sha256": identity["standard_cell_lib_sha256"],
    }
    bits = classify_retained_output_bits(
        module=module, manifest=manifest, design_json=design_json,
        standard_cell_lib=standard_cell_lib, whitelist=whitelist,
        bindings=bindings,
    )

    family_counts: dict[str, dict[str, int]] = {}
    for family in sorted(projection()["child_contracts"][module]["output_ports"]):
        selected = [bit for bit in bits if bit["family"] == family]
        family_counts[family] = {
            name: sum(bit["classification"] == name for bit in selected)
            for name in sorted(OUTPUT_BIT_CLASSES)
        }
    summary = {
        "bit_count": len(bits),
        "dynamic_count": sum(bit["classification"] == "DYNAMIC" for bit in bits),
        "constant_0_count": sum(
            bit["classification"] == "CONSTANT_0" for bit in bits
        ),
        "constant_1_count": sum(
            bit["classification"] == "CONSTANT_1" for bit in bits
        ),
        "family_counts": family_counts,
    }
    payload = {
        "schema": OUTPUT_BIT_DRIVER_CONTRACT_SCHEMA,
        "status": "PASS",
        "module": module,
        "run_identity": identity,
        "classification_basis": (
            "retained_unique_driver_plus_bound_stdlib_output_pin_function"
        ),
        "bindings": bindings,
        "bits": bits,
        "summary": summary,
    }
    payload["contract_id"] = canonical_sha256(payload)
    return payload


def validate_output_bit_driver_contract(
    value: Any, *, identity: dict[str, Any], module: str,
    standard_cell_lib: Path, evidence_dir: Path,
) -> dict[str, Any]:
    required = {
        "schema", "status", "module", "run_identity", "classification_basis",
        "bindings", "bits", "summary", "contract_id",
    }
    require(isinstance(value, dict) and set(value) == required and
            value.get("schema") == OUTPUT_BIT_DRIVER_CONTRACT_SCHEMA and
            value.get("status") == "PASS" and value.get("module") == module and
            value.get("run_identity") == identity,
            f"{module} output-bit driver contract identity is detached")
    validate_output_bit_driver_partition(value, module=module)
    root = canonical_evidence_dir(evidence_dir)
    bindings = value.get("bindings")
    require(isinstance(bindings, dict) and set(bindings) == {
        "run_identity_sha256", "netlist_sha256", "netlist_size_bytes",
        "netlist_manifest", "design_json", "stdlib_whitelist", "whitelist_id",
        "standard_cell_lib_sha256",
    }, f"{module} output-bit driver bindings drifted")
    for key in ("netlist_manifest", "design_json", "stdlib_whitelist"):
        validate_receipt(bindings[key], evidence_dir=root)
    rebuilt = build_output_bit_driver_contract(
        identity=identity, module=module,
        design_json=root / bindings["design_json"]["path"],
        netlist_manifest=root / bindings["netlist_manifest"]["path"],
        stdlib_whitelist=root / bindings["stdlib_whitelist"]["path"],
        standard_cell_lib=standard_cell_lib,
        evidence_dir=root,
    )
    require(value == rebuilt,
            f"{module} output-bit driver contract drifted or was replayed")
    return value


def validate_tcl_row_table(
    rows: Any,
    *,
    field_names: tuple[str, ...],
    expected_rows: int,
    label: str,
) -> list[tuple[str, ...]]:
    """Freeze one Tcl list-of-lists before source/OpenSTA consumes it."""

    require(isinstance(rows, (list, tuple)), f"{label} rows must be a sequence")
    require(
        isinstance(expected_rows, int) and not isinstance(expected_rows, bool)
        and expected_rows > 0,
        f"{label} expected row count is invalid",
    )
    require(
        bool(field_names) and all(
            isinstance(name, str) and name for name in field_names
        ),
        f"{label} field contract is invalid",
    )
    require(
        len(rows) == expected_rows,
        f"{label} row count drifted: {len(rows)} != {expected_rows}",
    )
    validated: list[tuple[str, ...]] = []
    for row_index, row in enumerate(rows):
        require(
            isinstance(row, (list, tuple)),
            f"{label} row {row_index} is flattened or not a sequence",
        )
        require(
            len(row) == len(field_names),
            f"{label} row {row_index} field count drifted: "
            f"{len(row)} != {len(field_names)}",
        )
        atoms: list[str] = []
        for field_name, atom in zip(field_names, row):
            require(
                isinstance(atom, str) and TCL_SAFE_ATOM_RE.fullmatch(atom) is not None,
                f"{label} row {row_index} field {field_name} contains a "
                "non-Tcl-safe atom",
            )
            atoms.append(atom)
        validated.append(tuple(atoms))
    return validated


def render_tcl_row_table(
    variable: str,
    rows: Any,
    *,
    field_names: tuple[str, ...],
    expected_rows: int,
    label: str,
) -> str:
    """Encode rows as one outer Tcl list whose elements are row sublists."""

    require(
        re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", variable) is not None,
        f"{label} Tcl variable name is invalid",
    )
    validated = validate_tcl_row_table(
        rows, field_names=field_names, expected_rows=expected_rows, label=label
    )
    rendered_rows = [
        "  {" + " ".join(f"{{{atom}}}" for atom in row) + "}"
        for row in validated
    ]
    return f"set {variable} {{\n" + "\n".join(rendered_rows) + "\n}\n"


def render_output_bit_driver_contract_tcl(value: dict[str, Any]) -> str:
    """Emit a nested Tcl-row projection; JSON remains the run-bound authority."""

    rows: list[tuple[str, ...]] = []
    for bit in value["bits"]:
        rows.append((
            bit["family"], str(bit["index"]), bit["opensta_object_name"],
            bit["classification"],
            "-" if bit["value"] is None else str(bit["value"]),
            bit["driver_binding_sha256"],
        ))
    return (
        f"set fp_ooc_output_bit_driver_contract_id "
        f"{{{value['contract_id']}}}\n"
        + render_tcl_row_table(
            "fp_ooc_output_bit_driver_contract",
            rows,
            field_names=OUTPUT_BIT_DRIVER_TCL_FIELDS,
            expected_rows=value["summary"]["bit_count"],
            label="output-bit driver contract",
        )
    )


def parse_area_from_stat(path: Path, *, module: str) -> float:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise EvidenceError(f"cannot read synth_stat {path}: {exc}") from exc
    patterns = (
        rf"Chip area for (?:top )?module ['\\]*{re.escape(module)}[':]?\s*:?\s*"
        rf"({FINITE_RE.pattern})",
        rf"Chip area for module ['\\]*{re.escape(module)}[':]?\s*:?\s*"
        rf"({FINITE_RE.pattern})",
    )
    matches: list[str] = []
    for pattern in patterns:
        matches.extend(re.findall(pattern, text))
    require(bool(matches), f"synth_stat lacks mapped area for {module}")
    return finite_number(float(matches[-1]), f"{module} mapped area", positive=True)


def build_child_result_from_artifacts(
    *, identity: dict[str, Any], module: str, source_closure_sha256: str,
    netlist: Path, synth_stat: Path, census_json: Path, netlist_manifest: Path,
    output_bit_driver_contract: Path, standard_cell_lib: Path,
    timing_max: Path, timing_min: Path, liberty_max: Path, liberty_min: Path,
    evidence_dir: Path,
) -> dict[str, Any]:
    validate_identity(identity)
    require(module in CHILDREN, f"unknown OOC child: {module}")
    root = canonical_evidence_dir(evidence_dir)
    modules = parse_yosys_census(census_json)
    require(module in modules, f"child census lacks {module}")
    manifest = validate_netlist_manifest(
        load_json(netlist_manifest), expected_identity=identity,
        expected_subject=module, evidence_dir=root,
        expected_netlist_sha256=sha256_file(netlist),
        expected_netlist_size_bytes=netlist.stat().st_size,
    )
    require(manifest["netlist_sha256"] == sha256_file(netlist) and
            manifest["netlist_size_bytes"] == netlist.stat().st_size,
            f"{module} retained manifest is detached from mapped netlist")
    driver_contract = validate_output_bit_driver_contract(
        load_json(output_bit_driver_contract), identity=identity, module=module,
        standard_cell_lib=standard_cell_lib, evidence_dir=root,
    )
    cell_count = positive_integer(
        len(manifest["leaf_cells"]), f"{module} mapped leaf-cell count"
    )
    area = parse_area_from_stat(synth_stat, module=module)
    timing: dict[str, Any] = {}
    liberty: dict[str, Any] = {}
    negative = 0
    for mode, timing_path, liberty_path in (
        ("max", timing_max, liberty_max),
        ("min", timing_min, liberty_min),
    ):
        timing_row = parse_timing_inventory(
            timing_path, identity=identity, subject=module, analysis=mode,
            expected_classes=CHILD_PATH_CLASSES,
            driver_contract=driver_contract,
        )
        timing_row["artifact"] = artifact(timing_path, evidence_dir=root)
        timing_row["query_budget"]["artifact"] = artifact(
            timing_path.with_name(f"child-query-progress-{mode}.tsv"),
            evidence_dir=root,
        )
        negative += timing_row["negative_slack_count"]
        timing[mode] = timing_row
        text = liberty_path.read_text(encoding="utf-8")
        metadata = validate_sequential_liberty(
            text, expected_identity=identity, expected_module=module,
            expected_analysis=mode,
            expected_timing_sha256=sha256_file(timing_path),
            expected_arc_inventory=timing_row["arc_inventory"],
            expected_output_bit_inventory=timing_row["output_bit_inventory"],
            expected_driver_contract_id=driver_contract["contract_id"],
        )
        require(float(metadata["area_um2"]) == float(area) and
                metadata["cell_count"] == cell_count and
                metadata["source_closure_sha256"] == source_closure_sha256,
                f"{module} {mode} Liberty mapping inputs are detached")
        liberty[mode] = {
            "analysis": mode,
            "artifact": artifact(liberty_path, evidence_dir=root),
            "metadata_sha256": canonical_sha256(metadata),
        }
    result = {
        "schema": CHILD_SCHEMA,
        "status": "PASS",
        "module": module,
        "run_identity": identity,
        "source_closure_sha256": source_closure_sha256,
        "synthesis": {
            "implementation_class": "known_ooc_macro_source_mapping",
            "cell_count": cell_count,
            "area_um2": area,
            "netlist_sha256": sha256_file(netlist),
            "netlist_size_bytes": netlist.stat().st_size,
            "synth_stat": artifact(synth_stat, evidence_dir=root),
            "census_json": artifact(census_json, evidence_dir=root),
            "netlist_manifest": artifact(netlist_manifest, evidence_dir=root),
            "port_manifest": port_manifest_summary(manifest),
            "output_bit_driver_contract": artifact(
                output_bit_driver_contract, evidence_dir=root
            ),
            "output_bit_driver_contract_value": driver_contract,
            "census": {module: 1},
        },
        "timing": {
            "max": timing["max"],
            "min": timing["min"],
            "assessment": "VIOLATED" if negative else "CLEAN",
        },
        "liberty": liberty,
        "power": {
            "model": "absent",
            "complete": False,
            "status": "INCOMPLETE_NO_OOC_POWER_MODEL",
        },
    }
    validate_child_result(result, expected_identity=identity)
    return result


def build_top_result_from_artifacts(
    *, identity: dict[str, Any], netlist: Path, synth_stat: Path,
    census_json: Path, netlist_manifest: Path,
    timing_max: Path, timing_min: Path,
    evidence_dir: Path,
) -> dict[str, Any]:
    selected_projection = projection()
    validate_identity(identity, expected_projection=selected_projection)
    root = canonical_evidence_dir(evidence_dir)
    modules = parse_yosys_census(census_json)
    manifest = validate_netlist_manifest(
        load_json(netlist_manifest), expected_identity=identity,
        expected_subject="NpcTop", evidence_dir=root,
        expected_netlist_sha256=sha256_file(netlist),
        expected_netlist_size_bytes=netlist.stat().st_size,
    )
    require(manifest["netlist_sha256"] == sha256_file(netlist) and
            manifest["netlist_size_bytes"] == netlist.stat().st_size,
            "NpcTop retained manifest is detached from mapped netlist")
    boundary_modules = set(CHILDREN) | set(
        selected_projection["expected_unknown_macro_instances"]
    )
    module_instances, leaf_cells = recursive_design_census(
        modules, top="NpcTop", boundary_modules=boundary_modules
    )
    def registered_count(module: str) -> int:
        return sum(
            count for name, count in module_instances.items()
            if _registered_module_alias(name) == module
        )

    inline = {"OooFpArithGate": registered_count("OooFpArithGate")}
    known = {module: registered_count(module) for module in CHILDREN}
    unknown = {
        module: registered_count(module)
        for module in selected_projection["expected_unknown_macro_instances"]
    }
    standard = manifest["leaf_cell_census"]
    cell_count = sum(standard.values())
    positive_integer(cell_count, "top stdcell count")
    area = parse_area_from_stat(synth_stat, module="NpcTop")
    expected_boundaries = {
        contract["path_classes"]["top_boundary"]
        for contract in selected_projection["child_contracts"].values()
    }
    timing: dict[str, Any] = {}
    negative = 0
    for mode, timing_path in (("max", timing_max), ("min", timing_min)):
        row = parse_timing_inventory(
            timing_path, identity=identity, subject="NpcTop", analysis=mode,
            expected_classes=expected_boundaries,
        )
        row["boundary_classes"] = row.pop("path_classes")
        row["artifact"] = artifact(timing_path, evidence_dir=root)
        negative += row["negative_slack_count"]
        timing[mode] = row
    result = {
        "schema": TOP_SCHEMA,
        "status": "PASS",
        "run_identity": identity,
        "synthesis": {
            "implementation_class": "npctop_inline_wrapper_plus_known_ooc_macros",
            "top_stdcell_cell_count": cell_count,
            "top_stdcell_area_um2": area,
            "inline_rtl_instances": inline,
            "known_ooc_macro_instances": known,
            "unknown_placeholder_instances": unknown,
            "standard_cell_module_census": standard,
            "netlist_sha256": sha256_file(netlist),
            "netlist_size_bytes": netlist.stat().st_size,
            "synth_stat": artifact(synth_stat, evidence_dir=root),
            "census_json": artifact(census_json, evidence_dir=root),
            "netlist_manifest": artifact(netlist_manifest, evidence_dir=root),
        },
        "timing": {
            "max": timing["max"],
            "min": timing["min"],
            "assessment": "VIOLATED" if negative else "CLEAN",
        },
    }
    validate_top_result(
        result, expected_identity=identity,
        expected_projection=selected_projection,
    )
    return result


def validate_retained_summary(summary_path: Path, receipt_path: Path,
                              evidence_dir: Path) -> dict[str, Any]:
    root = canonical_evidence_dir(evidence_dir)
    summary = load_json(summary_path)
    validate_composite_summary(summary)
    for record in iter_receipts(summary):
        validate_receipt(record, evidence_dir=root)
    registry_contract_path = root / summary["artifacts"]["registry_contract"]["path"]
    registry_contract = load_json(registry_contract_path)
    expected_contract = {
        field: summary["projection"][field]
        for field in (
            "abstraction_kind", "implementation_classes",
            "expected_known_ooc_macro_instances", "ooc_model_contract",
            "child_contracts",
        )
    }
    require(registry_contract == expected_contract,
            "retained Registry OOC contract is detached from the summary projection")
    whitelist_path = root / summary["artifacts"]["stdlib_leaf_whitelist"]["path"]
    validate_stdlib_whitelist(
        load_json(whitelist_path), expected_identity=summary["run_identity"]
    )
    for module, child in summary["children"].items():
        manifest_path = root / child["synthesis"]["netlist_manifest"]["path"]
        validate_netlist_manifest(
            load_json(manifest_path), expected_identity=summary["run_identity"],
            expected_subject=module, evidence_dir=root,
            expected_netlist_sha256=child["synthesis"]["netlist_sha256"],
            expected_netlist_size_bytes=child["synthesis"]["netlist_size_bytes"],
        )
        manifest = load_json(manifest_path)
        require(child["synthesis"]["port_manifest"] ==
                port_manifest_summary(manifest),
                f"{module} retained port summary is detached from manifest")
        driver_path = root / child["synthesis"][
            "output_bit_driver_contract"
        ]["path"]
        require(load_json(driver_path) ==
                child["synthesis"]["output_bit_driver_contract_value"],
                f"{module} retained output-bit contract value is detached")
    top_manifest_path = root / summary["top"]["synthesis"]["netlist_manifest"]["path"]
    validate_netlist_manifest(
        load_json(top_manifest_path), expected_identity=summary["run_identity"],
        expected_subject="NpcTop", evidence_dir=root,
        expected_netlist_sha256=summary["top"]["synthesis"]["netlist_sha256"],
        expected_netlist_size_bytes=summary["top"]["synthesis"][
            "netlist_size_bytes"
        ],
    )
    receipt = load_json(receipt_path)
    require(set(receipt) == {"schema", "status", "summary", "receipt_id"},
            "composite validation receipt key set drifted")
    require(receipt["schema"] == RECEIPT_SCHEMA and receipt["status"] == "PASS",
            "composite validation receipt is not PASS")
    expected_summary_receipt = artifact(summary_path, evidence_dir=root)
    require(receipt["summary"] == expected_summary_receipt,
            "composite validation receipt is detached")
    expected_id = canonical_sha256({
        "schema": RECEIPT_SCHEMA,
        "summary": expected_summary_receipt,
        "run_identity": summary["run_identity"],
    })
    require(receipt["receipt_id"] == expected_id,
            "composite validation receipt_id is stale")
    return receipt


def command_projection(args: argparse.Namespace) -> int:
    value = projection()
    if args.output:
        write_json(args.output.resolve(), value)
    else:
        print(json.dumps(value, allow_nan=False, sort_keys=True))
    return 0


def command_identity(args: argparse.Namespace) -> int:
    identity = build_identity(
        run_id=args.run_id,
        source_manifest=args.source_manifest.resolve(),
        tool_manifest=args.tool_manifest.resolve(),
        standard_cell_lib=args.standard_cell_lib.resolve(),
        yosys=args.yosys.resolve(),
        opensta=args.opensta.resolve(),
    )
    write_json(args.output.resolve(), identity)
    return 0


def command_emit_stdlib_whitelist(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    value = build_stdlib_whitelist(
        identity=identity, standard_cell_lib=args.standard_cell_lib.resolve()
    )
    write_json(args.output.resolve(), value)
    return 0


def command_emit_netlist_manifest(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    netlist = args.netlist.resolve()
    value = _manifest_payload(
        identity=identity, subject=args.subject,
        netlist_sha256=sha256_file(netlist),
        netlist_size_bytes=netlist.stat().st_size,
        design_json=args.design_json.resolve(), census_json=args.census_json.resolve(),
        stdlib_whitelist=args.stdlib_whitelist.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    write_json(args.output.resolve(), value)
    return 0


def command_emit_output_bit_driver_contract(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    value = build_output_bit_driver_contract(
        identity=identity, module=args.module,
        design_json=args.design_json.resolve(),
        netlist_manifest=args.netlist_manifest.resolve(),
        stdlib_whitelist=args.stdlib_whitelist.resolve(),
        standard_cell_lib=args.standard_cell_lib.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    write_json(args.output.resolve(), value)
    return 0


def command_emit_output_bit_driver_contract_tcl(
    args: argparse.Namespace,
) -> int:
    value = load_json(args.driver_contract.resolve())
    identity = load_json(args.identity.resolve())
    validate_output_bit_driver_contract(
        value, identity=identity, module=args.module,
        standard_cell_lib=args.standard_cell_lib.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    args.output.resolve().write_text(
        render_output_bit_driver_contract_tcl(value), encoding="utf-8"
    )
    return 0


def command_emit_child_port_contract(args: argparse.Namespace) -> int:
    contract = projection()["child_contracts"][args.module]
    ports = (contract["input_ports"] if args.direction == "input" else
             contract["output_ports"])
    print(" ".join(f"{name}={width}" for name, width in sorted(ports.items())))
    return 0


def render_top_boundary_contract_tcl(
    contracts: dict[str, Any] | None = None,
) -> str:
    """Project the five Registry boundaries as exact eight-field Tcl rows."""

    selected = contracts if contracts is not None else projection()["child_contracts"]
    rows: list[tuple[str, ...]] = []
    for module in CHILDREN:
        contract = selected[module]
        exact = contract["top_boundary_contract"]
        endpoint = exact["endpoint"]
        endpoint_instance, endpoint_widths = _boundary_endpoint_widths(
            endpoint, selected
        )
        source_widths = {
            name: contract["output_ports"][name]
            for name in exact["source_port_families"]
        }
        encode = lambda values: " ".join(
            f"{name}={width}" for name, width in sorted(values.items())
        )
        rows.append((
            contract["path_classes"]["top_boundary"],
            exact["source_instance_path"],
            exact["source_object_class"],
            encode(source_widths),
            endpoint["kind"],
            endpoint_instance or "-",
            endpoint["object_class"],
            encode(endpoint_widths),
        ))
    expected_rows = TCL_ROW_PROJECTION_CONTRACT["top_boundary"]["row_count"]
    require(
        expected_rows == len(CHILDREN),
        "Registry top boundary Tcl row-count contract drifted",
    )
    return render_tcl_row_table(
        "fp_ooc_boundary_contract",
        rows,
        field_names=TOP_BOUNDARY_TCL_FIELDS,
        expected_rows=expected_rows,
        label="Registry top boundary contract",
    )


def command_emit_top_boundary_contract_tcl(args: argparse.Namespace) -> int:
    args.output.resolve().write_text(
        render_top_boundary_contract_tcl(), encoding="utf-8"
    )
    return 0


def command_render_liberty_from_artifacts(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    module = args.module
    modules = parse_yosys_census(args.census_json.resolve())
    require(module in modules, f"child census lacks {module}")
    manifest = validate_netlist_manifest(
        load_json(args.netlist_manifest.resolve()), expected_identity=identity,
        expected_subject=module, evidence_dir=args.evidence_dir.resolve(),
    )
    cell_count = positive_integer(
        len(manifest["leaf_cells"]), f"{module} mapped leaf-cell count"
    )
    area = parse_area_from_stat(args.synth_stat.resolve(), module=module)
    timing_path = args.timing.resolve()
    driver_contract = validate_output_bit_driver_contract(
        load_json(args.output_bit_driver_contract.resolve()), identity=identity,
        module=module, standard_cell_lib=args.standard_cell_lib.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    timing_row = parse_timing_inventory(
        timing_path, identity=identity, subject=module, analysis=args.analysis,
        expected_classes=CHILD_PATH_CLASSES,
        driver_contract=driver_contract,
    )
    metadata = liberty_metadata(
        identity=identity,
        module=module,
        analysis=args.analysis,
        source_closure_sha256=args.source_closure_sha256,
        timing_evidence_sha256=sha256_file(timing_path),
        area_um2=area,
        cell_count=cell_count,
        arc_inventory=timing_row["arc_inventory"],
        output_bit_inventory=timing_row["output_bit_inventory"],
        output_bit_driver_contract=driver_contract,
    )
    args.output.resolve().write_text(render_sequential_liberty(metadata), encoding="utf-8")
    return 0


def command_emit_child_sources(args: argparse.Namespace) -> int:
    print(" ".join(projection()["child_contracts"][args.module]["source_closure"]))
    return 0


def command_emit_child_compile_sources(args: argparse.Namespace) -> int:
    print(" ".join(
        projection()["child_contracts"][args.module]["compile_sources"]
    ))
    return 0


def command_validate_liberty(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    text = args.liberty.resolve().read_text(encoding="utf-8")
    timing_path = args.timing.resolve()
    driver_contract = validate_output_bit_driver_contract(
        load_json(args.output_bit_driver_contract.resolve()), identity=identity,
        module=args.module, standard_cell_lib=args.standard_cell_lib.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    timing_row = parse_timing_inventory(
        timing_path, identity=identity, subject=args.module,
        analysis=args.analysis, expected_classes=CHILD_PATH_CLASSES,
        driver_contract=driver_contract,
    )
    metadata = validate_sequential_liberty(
        text,
        expected_identity=identity,
        expected_module=args.module,
        expected_analysis=args.analysis,
        expected_timing_sha256=sha256_file(timing_path),
        expected_arc_inventory=timing_row["arc_inventory"],
        expected_output_bit_inventory=timing_row["output_bit_inventory"],
        expected_driver_contract_id=driver_contract["contract_id"],
    )
    print(json.dumps({"status": "PASS", "metadata_sha256": canonical_sha256(metadata)},
                     sort_keys=True))
    return 0


def command_compose(args: argparse.Namespace) -> int:
    identity = load_json(args.identity.resolve())
    children = {
        module: load_json((args.children_dir.resolve() / module / "child-result.json"))
        for module in CHILDREN
    }
    top = load_json(args.top_result.resolve())
    root = canonical_evidence_dir(args.evidence_dir.resolve())
    run_artifacts = {
        "production_manifest_before": artifact(
            root / "production-manifest-before.sha256", evidence_dir=root
        ),
        "production_manifest_after": artifact(
            root / "production-manifest-after.sha256", evidence_dir=root
        ),
        "source_manifest": artifact(
            root / "synthesis-sources.sha256", evidence_dir=root
        ),
        "tool_manifest": artifact(root / "tool-inputs.sha256", evidence_dir=root),
        "run_identity": artifact(root / "run-identity.json", evidence_dir=root),
        "registry_contract": artifact(
            root / "ooc-composite-contract.json", evidence_dir=root
        ),
        "stdlib_leaf_whitelist": artifact(
            root / "stdlib-leaf-whitelist.json", evidence_dir=root
        ),
        "top_boundary_contract_tcl": artifact(
            root / "top-boundary-contract.tcl", evidence_dir=root
        ),
    }
    summary = build_composite_summary(
        identity=identity, children=children, top=top,
        run_artifacts=run_artifacts,
    )
    write_json(args.output.resolve(), summary)
    summary_receipt = artifact(args.output.resolve(), evidence_dir=root)
    receipt = {
        "schema": RECEIPT_SCHEMA,
        "status": "PASS",
        "summary": summary_receipt,
        "receipt_id": canonical_sha256({
            "schema": RECEIPT_SCHEMA,
            "summary": summary_receipt,
            "run_identity": identity,
        }),
    }
    write_json(args.receipt.resolve(), receipt)
    return 0


def command_parse_child(args: argparse.Namespace) -> int:
    result = build_child_result_from_artifacts(
        identity=load_json(args.identity.resolve()),
        module=args.module,
        source_closure_sha256=args.source_closure_sha256,
        netlist=args.netlist.resolve(),
        synth_stat=args.synth_stat.resolve(),
        census_json=args.census_json.resolve(),
        netlist_manifest=args.netlist_manifest.resolve(),
        output_bit_driver_contract=args.output_bit_driver_contract.resolve(),
        standard_cell_lib=args.standard_cell_lib.resolve(),
        timing_max=args.timing_max.resolve(),
        timing_min=args.timing_min.resolve(),
        liberty_max=args.liberty_max.resolve(),
        liberty_min=args.liberty_min.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    write_json(args.output.resolve(), result)
    return 0


def command_parse_top(args: argparse.Namespace) -> int:
    result = build_top_result_from_artifacts(
        identity=load_json(args.identity.resolve()),
        netlist=args.netlist.resolve(),
        synth_stat=args.synth_stat.resolve(),
        census_json=args.census_json.resolve(),
        netlist_manifest=args.netlist_manifest.resolve(),
        timing_max=args.timing_max.resolve(),
        timing_min=args.timing_min.resolve(),
        evidence_dir=args.evidence_dir.resolve(),
    )
    write_json(args.output.resolve(), result)
    return 0


def command_validate(args: argparse.Namespace) -> int:
    receipt = validate_retained_summary(
        args.summary.resolve(), args.receipt.resolve(), args.evidence_dir.resolve()
    )
    print(json.dumps({"status": "PASS", "receipt_id": receipt["receipt_id"]},
                     sort_keys=True))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    projection_parser = subparsers.add_parser("projection")
    projection_parser.add_argument("--output", type=Path)
    projection_parser.set_defaults(function=command_projection)
    identity = subparsers.add_parser("identity")
    identity.add_argument("--run-id", required=True)
    identity.add_argument("--source-manifest", type=Path, required=True)
    identity.add_argument("--tool-manifest", type=Path, required=True)
    identity.add_argument("--standard-cell-lib", type=Path, required=True)
    identity.add_argument("--yosys", type=Path, required=True)
    identity.add_argument("--opensta", type=Path, required=True)
    identity.add_argument("--output", type=Path, required=True)
    identity.set_defaults(function=command_identity)
    whitelist = subparsers.add_parser("emit-stdlib-whitelist")
    whitelist.add_argument("--identity", type=Path, required=True)
    whitelist.add_argument("--standard-cell-lib", type=Path, required=True)
    whitelist.add_argument("--output", type=Path, required=True)
    whitelist.set_defaults(function=command_emit_stdlib_whitelist)
    manifest = subparsers.add_parser("emit-netlist-manifest")
    manifest.add_argument("--identity", type=Path, required=True)
    manifest.add_argument("--subject", choices=("NpcTop", *CHILDREN), required=True)
    manifest.add_argument("--netlist", type=Path, required=True)
    manifest.add_argument("--design-json", type=Path, required=True)
    manifest.add_argument("--census-json", type=Path, required=True)
    manifest.add_argument("--stdlib-whitelist", type=Path, required=True)
    manifest.add_argument("--evidence-dir", type=Path, required=True)
    manifest.add_argument("--output", type=Path, required=True)
    manifest.set_defaults(function=command_emit_netlist_manifest)
    driver = subparsers.add_parser("emit-output-bit-driver-contract")
    driver.add_argument("--identity", type=Path, required=True)
    driver.add_argument("--module", choices=CHILDREN, required=True)
    driver.add_argument("--design-json", type=Path, required=True)
    driver.add_argument("--netlist-manifest", type=Path, required=True)
    driver.add_argument("--stdlib-whitelist", type=Path, required=True)
    driver.add_argument("--standard-cell-lib", type=Path, required=True)
    driver.add_argument("--evidence-dir", type=Path, required=True)
    driver.add_argument("--output", type=Path, required=True)
    driver.set_defaults(function=command_emit_output_bit_driver_contract)
    driver_tcl = subparsers.add_parser(
        "emit-output-bit-driver-contract-tcl"
    )
    driver_tcl.add_argument("--identity", type=Path, required=True)
    driver_tcl.add_argument("--module", choices=CHILDREN, required=True)
    driver_tcl.add_argument("--driver-contract", type=Path, required=True)
    driver_tcl.add_argument("--standard-cell-lib", type=Path, required=True)
    driver_tcl.add_argument("--evidence-dir", type=Path, required=True)
    driver_tcl.add_argument("--output", type=Path, required=True)
    driver_tcl.set_defaults(
        function=command_emit_output_bit_driver_contract_tcl
    )
    liberty_from = subparsers.add_parser("render-liberty-from-artifacts")
    liberty_from.add_argument("--identity", type=Path, required=True)
    liberty_from.add_argument("--module", choices=CHILDREN, required=True)
    liberty_from.add_argument("--analysis", choices=("max", "min"), required=True)
    liberty_from.add_argument("--source-closure-sha256", required=True)
    liberty_from.add_argument("--synth-stat", type=Path, required=True)
    liberty_from.add_argument("--census-json", type=Path, required=True)
    liberty_from.add_argument("--netlist-manifest", type=Path, required=True)
    liberty_from.add_argument("--output-bit-driver-contract", type=Path,
                              required=True)
    liberty_from.add_argument("--standard-cell-lib", type=Path, required=True)
    liberty_from.add_argument("--evidence-dir", type=Path, required=True)
    liberty_from.add_argument("--timing", type=Path, required=True)
    liberty_from.add_argument("--output", type=Path, required=True)
    liberty_from.set_defaults(function=command_render_liberty_from_artifacts)
    emit_sources = subparsers.add_parser("emit-child-sources")
    emit_sources.add_argument("--module", choices=CHILDREN, required=True)
    emit_sources.set_defaults(function=command_emit_child_sources)
    emit_compile_sources = subparsers.add_parser("emit-child-compile-sources")
    emit_compile_sources.add_argument("--module", choices=CHILDREN, required=True)
    emit_compile_sources.set_defaults(
        function=command_emit_child_compile_sources
    )
    emit_ports = subparsers.add_parser("emit-child-port-contract")
    emit_ports.add_argument("--module", choices=CHILDREN, required=True)
    emit_ports.add_argument("--direction", choices=("input", "output"), required=True)
    emit_ports.set_defaults(function=command_emit_child_port_contract)
    top_contract = subparsers.add_parser("emit-top-boundary-contract-tcl")
    top_contract.add_argument("--output", type=Path, required=True)
    top_contract.set_defaults(function=command_emit_top_boundary_contract_tcl)
    validate_liberty = subparsers.add_parser("validate-liberty")
    validate_liberty.add_argument("--identity", type=Path, required=True)
    validate_liberty.add_argument("--module", choices=CHILDREN, required=True)
    validate_liberty.add_argument("--analysis", choices=("max", "min"), required=True)
    validate_liberty.add_argument("--timing", type=Path, required=True)
    validate_liberty.add_argument("--liberty", type=Path, required=True)
    validate_liberty.add_argument("--output-bit-driver-contract", type=Path,
                                  required=True)
    validate_liberty.add_argument("--standard-cell-lib", type=Path,
                                  required=True)
    validate_liberty.add_argument("--evidence-dir", type=Path, required=True)
    validate_liberty.set_defaults(function=command_validate_liberty)
    child = subparsers.add_parser("parse-child")
    child.add_argument("--identity", type=Path, required=True)
    child.add_argument("--module", choices=CHILDREN, required=True)
    child.add_argument("--source-closure-sha256", required=True)
    child.add_argument("--netlist", type=Path, required=True)
    child.add_argument("--synth-stat", type=Path, required=True)
    child.add_argument("--census-json", type=Path, required=True)
    child.add_argument("--netlist-manifest", type=Path, required=True)
    child.add_argument("--output-bit-driver-contract", type=Path, required=True)
    child.add_argument("--standard-cell-lib", type=Path, required=True)
    child.add_argument("--timing-max", type=Path, required=True)
    child.add_argument("--timing-min", type=Path, required=True)
    child.add_argument("--liberty-max", type=Path, required=True)
    child.add_argument("--liberty-min", type=Path, required=True)
    child.add_argument("--evidence-dir", type=Path, required=True)
    child.add_argument("--output", type=Path, required=True)
    child.set_defaults(function=command_parse_child)
    top = subparsers.add_parser("parse-top")
    top.add_argument("--identity", type=Path, required=True)
    top.add_argument("--netlist", type=Path, required=True)
    top.add_argument("--synth-stat", type=Path, required=True)
    top.add_argument("--census-json", type=Path, required=True)
    top.add_argument("--netlist-manifest", type=Path, required=True)
    top.add_argument("--timing-max", type=Path, required=True)
    top.add_argument("--timing-min", type=Path, required=True)
    top.add_argument("--evidence-dir", type=Path, required=True)
    top.add_argument("--output", type=Path, required=True)
    top.set_defaults(function=command_parse_top)
    compose = subparsers.add_parser("compose")
    compose.add_argument("--identity", type=Path, required=True)
    compose.add_argument("--children-dir", type=Path, required=True)
    compose.add_argument("--top-result", type=Path, required=True)
    compose.add_argument("--evidence-dir", type=Path, required=True)
    compose.add_argument("--output", type=Path, required=True)
    compose.add_argument("--receipt", type=Path, required=True)
    compose.set_defaults(function=command_compose)
    validate = subparsers.add_parser("validate")
    validate.add_argument("--summary", type=Path, required=True)
    validate.add_argument("--receipt", type=Path, required=True)
    validate.add_argument("--evidence-dir", type=Path, required=True)
    validate.set_defaults(function=command_validate)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        return int(args.function(args))
    except (EvidenceError, OSError, KeyError, ValueError) as exc:
        print(f"[FP-OOC-COMPOSITE][FAIL] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
