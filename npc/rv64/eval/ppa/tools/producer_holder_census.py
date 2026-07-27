#!/usr/bin/env python3
"""Fail-closed census for finite-generation ProducerId holders.

The checker is intentionally narrower than a Verilog elaborator.  It proves
that every source-level full-P Q field, every ProducerId-bearing PipeStageReg,
and every registered memory owner-token field in the current production RTL is
classified by the manifest.  Semantic/runtime closure remains a separate TB
and mutation gate.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


SCHEMA = "rv64-producer-holder-census-v1"
EXPECTED_SCOPE = {
    "source_root": "npc/rv64/vsrc",
    "topology_root": "NpcTop->NpcCoreTop->OooCoreTopGlue->OooIntBackend",
    "coverage_granularity": "field-plus-packed-stage",
    "field_level_complete": True,
    "instance_graph_complete": False,
    "semantic_complete": False,
}
EXPECTED_LEDGER = {
    "current_production_holder_census": "STATIC_FIELD_COMPLETE",
    "global_no_live_reuse": "DYNAMIC_EVIDENCE_REQUIRED",
    "whole_architecture": "RED",
    "ppa_promotion": "UNPROMOTED",
}
DIRECT_CLASSES = {
    "IDENTITY_AUTHORITY",
    "DIRECT_HOLDER",
    "PACKED_ALIAS",
    "TRACKER_MAP",
    "REDUNDANT_IDENTITY_CACHE",
}
TOKEN_CLASSES = {
    "INDIRECT_HOLDER",
    "DERIVED_ALIAS",
    "ALLOCATOR_CURSOR_EXEMPT",
}
COMBINATIONAL_FULL_P_CLASSES = {"COMBINATIONAL_NEXT_EXEMPT"}
REQUIRED_ANCHOR_IDS = {
    "dispatch-complete-union",
    "dispatch-lane0-full-p-guard",
    "dispatch-pair-full-p-guard",
    "dispatch-lane1-full-p-guard",
    "intiq-q-only-mask",
    "intbackend-transient-union",
    "intbackend-external-union",
    "mem-tracker-q-mask",
    "fp-complete-mask",
    "rob-generation-wide-add",
    "rob-allocation-stores-candidate",
    "storequeue-owner-snoop",
    "v8l-mem-handoff-assert",
    "v8l-indirect-tracker-assert",
    "v8l-sq-global-assert",
    "v9r-backend-retry0-c0-gate",
    "v9r-backend-retry1-c0-gate",
    "v9r-backend-retry-c0-assert",
    "v9r-bridge-retry-fire-c0-gate",
    "v9r-bridge-retry-fire-c0-assert",
}
FORBIDDEN_ANCHOR_IDS = {
    "intiq-next-state-mask",
    "dispatch-lane0-raw-index-guard",
    "dispatch-lane1-raw-index-guard",
    "dispatch-pair-raw-index-guard",
}

MODULE_RE = re.compile(
    r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)\b|\bendmodule\b"
)
FULL_P_DECL_RE = re.compile(
    r"\b(?P<kind>reg|logic|wire)\s*"
    r"\[\s*PRODUCER_ID_W\s*-\s*1\s*:\s*0\s*\]\s*"
    r"(?P<body>[^;]+);",
    re.DOTALL,
)
GEN_DECL_RE = re.compile(
    r"\b(?P<kind>reg|logic|wire)\s*"
    r"\[\s*PRODUCER_GEN_W\s*-\s*1\s*:\s*0\s*\]\s*"
    r"(?P<body>[^;]+);",
    re.DOTALL,
)
TOKEN_DECL_RE = re.compile(
    r"\b(?:reg|logic|wire)\b(?P<body>[^;]+);", re.DOTALL
)
LOCALPARAM_RE = re.compile(
    r"\blocalparam(?:\s+integer)?(?:\s+\[[^;=]+\])?\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_$]*)\s*=\s*(?P<expr>[^;]+);",
    re.DOTALL,
)
PIPE_RE = re.compile(
    r"\bPipeStageReg\s*#\s*\(\s*\.WIDTH\s*\(\s*"
    r"(?P<width>[^)]+?)\s*\)\s*\)\s*"
    r"(?P<instance>[A-Za-z_][A-Za-z0-9_$]*)\s*\(",
    re.DOTALL,
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def strip_comments_and_strings(text: str) -> str:
    """Remove comments/strings while preserving newlines and positions."""
    out = list(text)
    state = "code"
    i = 0
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "code":
            if ch == "/" and nxt == "/":
                out[i] = out[i + 1] = " "
                state = "line"
                i += 2
                continue
            if ch == "/" and nxt == "*":
                out[i] = out[i + 1] = " "
                state = "block"
                i += 2
                continue
            if ch == '"':
                out[i] = " "
                state = "string"
                i += 1
                continue
        elif state == "line":
            if ch == "\n":
                state = "code"
            else:
                out[i] = " "
        elif state == "block":
            if ch == "*" and nxt == "/":
                out[i] = out[i + 1] = " "
                state = "code"
                i += 2
                continue
            if ch != "\n":
                out[i] = " "
        else:
            if ch == "\\" and nxt:
                out[i] = out[i + 1] = " "
                i += 2
                continue
            if ch == '"':
                out[i] = " "
                state = "code"
            elif ch != "\n":
                out[i] = " "
        i += 1
    return "".join(out)


def strip_ooo_assert_blocks(text: str) -> str:
    """Remove `ifdef OOO_ASSERT regions; production declarations remain."""
    lines = text.splitlines(keepends=True)
    output: list[str] = []
    depth = 0
    for line in lines:
        directive = re.match(r"\s*`(ifdef|ifndef|endif)\b\s*(\w+)?", line)
        if depth == 0 and directive and directive.group(1) == "ifdef" and \
                directive.group(2) == "OOO_ASSERT":
            depth = 1
            output.append("\n" if line.endswith("\n") else "")
            continue
        if depth:
            if directive and directive.group(1) in {"ifdef", "ifndef"}:
                depth += 1
            elif directive and directive.group(1) == "endif":
                depth -= 1
            output.append("\n" if line.endswith("\n") else "")
            continue
        output.append(line)
    return "".join(output)


def module_spans(clean: str) -> tuple[list[tuple[str, int, int]], list[str]]:
    spans: list[tuple[str, int, int]] = []
    errors: list[str] = []
    opened: tuple[str, int] | None = None
    for match in MODULE_RE.finditer(clean):
        name = match.group(1)
        if name is not None:
            if opened is not None:
                errors.append(f"nested module before {name}")
            opened = (name, match.start())
        elif opened is None:
            errors.append("endmodule without module")
        else:
            spans.append((opened[0], opened[1], match.end()))
            opened = None
    if opened is not None:
        errors.append(f"module without endmodule: {opened[0]}")
    return spans, errors


def module_at(spans: list[tuple[str, int, int]], pos: int) -> str | None:
    for name, start, end in spans:
        if start <= pos < end:
            return name
    return None


def width_contains_producer(
    expression: str, params: dict[str, str], seen: set[str] | None = None
) -> bool:
    if re.search(r"\bPRODUCER_(?:ID|GEN)_W\b", expression):
        return True
    seen = set() if seen is None else seen
    for token in re.findall(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", expression):
        if token in params and token not in seen:
            seen.add(token)
            if width_contains_producer(params[token], params, seen):
                return True
    return False


def declared_q_symbols(body: str, suffix_pattern: str) -> list[str]:
    """Return declarator names only; ignore Q names referenced by an RHS."""
    lhs = body.split("=", 1)[0]
    return re.findall(
        rf"\b([A-Za-z_][A-Za-z0-9_$]*{suffix_pattern})\b", lhs
    )


def declared_symbols(body: str) -> list[str]:
    """Return one declarator name per comma-separated declaration arm."""
    lhs = body.split("=", 1)[0]
    result: list[str] = []
    for arm in lhs.split(","):
        match = re.search(r"\b([A-Za-z_][A-Za-z0-9_$]*)\b", arm)
        if match:
            result.append(match.group(1))
    return result


def source_inventory(repo_root: Path, source_root: Path) -> dict[str, Any]:
    direct: set[tuple[str, str, str]] = set()
    full_p_regs: set[tuple[str, str, str]] = set()
    generation: set[tuple[str, str, str]] = set()
    generation_regs: set[tuple[str, str, str]] = set()
    token_q: set[tuple[str, str, str]] = set()
    packed: set[tuple[str, str, str]] = set()
    modules: dict[tuple[str, str], str] = {}
    modules_all: dict[tuple[str, str], str] = {}
    source_hashes: dict[str, str] = {}
    errors: list[str] = []

    for path in sorted(source_root.rglob("*.v")):
        if path.is_symlink():
            errors.append(f"source symlink is forbidden: {path}")
            continue
        rel = path.relative_to(repo_root).as_posix()
        raw_bytes = path.read_bytes()
        source_hashes[rel] = sha256_bytes(raw_bytes)
        try:
            raw = raw_bytes.decode("utf-8")
        except UnicodeDecodeError as exc:
            errors.append(f"cannot decode {rel}: {exc}")
            continue
        clean_all = strip_comments_and_strings(raw)
        clean = strip_ooo_assert_blocks(clean_all)
        spans, span_errors = module_spans(clean)
        spans_all, span_all_errors = module_spans(clean_all)
        errors.extend(f"{rel}: {item}" for item in span_errors)
        errors.extend(f"{rel}: full view: {item}" for item in span_all_errors)
        for module, start, end in spans_all:
            modules_all[(rel, module)] = clean_all[start:end]
        for module, start, end in spans:
            body = clean[start:end]
            modules[(rel, module)] = body
            params = {
                match.group("name"): match.group("expr")
                for match in LOCALPARAM_RE.finditer(body)
            }
            for match in PIPE_RE.finditer(body):
                if width_contains_producer(match.group("width"), params):
                    packed.add((rel, module, match.group("instance")))

        for match in FULL_P_DECL_RE.finditer(clean):
            module = module_at(spans, match.start())
            if module is None:
                continue
            for symbol in declared_q_symbols(match.group("body"), r"_q"):
                direct.add((rel, module, symbol))
            if match.group("kind") in {"reg", "logic"}:
                for symbol in declared_symbols(match.group("body")):
                    full_p_regs.add((rel, module, symbol))
        for match in GEN_DECL_RE.finditer(clean):
            module = module_at(spans, match.start())
            if module is None:
                continue
            for symbol in declared_q_symbols(match.group("body"), r"_q"):
                generation.add((rel, module, symbol))
            if match.group("kind") in {"reg", "logic"}:
                for symbol in declared_symbols(match.group("body")):
                    generation_regs.add((rel, module, symbol))
        for match in TOKEN_DECL_RE.finditer(clean):
            module = module_at(spans, match.start())
            if module is None:
                continue
            for symbol in declared_q_symbols(match.group("body"), r"_token_q"):
                token_q.add((rel, module, symbol))

    digest_material = "".join(
        f"{path}\0{digest}\n" for path, digest in sorted(source_hashes.items())
    ).encode("utf-8")
    return {
        "direct": direct,
        "combinational_full_p_regs": full_p_regs - direct,
        "generation": generation,
        "unclassified_generation_regs": generation_regs - generation,
        "token_q": token_q,
        "packed": packed,
        "modules": modules,
        "modules_all": modules_all,
        "source_hashes": source_hashes,
        "source_set_sha256": sha256_bytes(digest_material),
        "errors": errors,
    }


def section_keys(
    manifest: dict[str, Any], section: str, key_fields: tuple[str, ...],
    errors: list[str]
) -> set[tuple[str, ...]]:
    rows = manifest.get(section)
    if not isinstance(rows, list):
        errors.append(f"{section} must be a list")
        return set()
    result: set[tuple[str, ...]] = set()
    ids: set[str] = set()
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            errors.append(f"{section}[{index}] must be an object")
            continue
        if not isinstance(row.get("id"), str) or not row["id"]:
            errors.append(f"{section}[{index}].id must be non-empty")
        elif row["id"] in ids:
            errors.append(f"duplicate {section} id: {row['id']}")
        ids.add(row.get("id", ""))
        missing = [field for field in key_fields if not isinstance(row.get(field), str)]
        if missing:
            errors.append(f"{section}[{index}] missing string fields: {missing}")
            continue
        key = tuple(row[field] for field in key_fields)
        if key in result:
            errors.append(f"duplicate {section} key: {key}")
        result.add(key)
    return result


def compare_exact(
    label: str, discovered: set[tuple[str, ...]], declared: set[tuple[str, ...]],
    errors: list[str]
) -> None:
    for item in sorted(discovered - declared):
        errors.append(f"unclassified {label}: {'::'.join(item)}")
    for item in sorted(declared - discovered):
        errors.append(f"stale/nonexistent {label}: {'::'.join(item)}")


def validate_manifest(
    manifest: dict[str, Any], inventory: dict[str, Any]
) -> list[str]:
    errors = list(inventory["errors"])
    if manifest.get("schema_version") != SCHEMA:
        errors.append(f"schema_version must be {SCHEMA}")
    if manifest.get("scope") != EXPECTED_SCOPE:
        errors.append("scope must retain the exact bounded completeness declaration")
    if manifest.get("status_ledger") != EXPECTED_LEDGER:
        errors.append("status_ledger overclaim/drift: architecture and PPA must remain closed")

    direct = section_keys(
        manifest, "direct_full_p_fields", ("path", "module", "symbol"), errors
    )
    combinational_full_p = section_keys(
        manifest, "combinational_full_p_regs", ("path", "module", "symbol"),
        errors,
    )
    generation = section_keys(
        manifest, "generation_authorities", ("path", "module", "symbol"), errors
    )
    token_q = section_keys(
        manifest, "token_q_fields", ("path", "module", "symbol"), errors
    )
    packed = section_keys(
        manifest, "packed_full_p_stages", ("path", "module", "instance"), errors
    )
    compare_exact("full-P Q field", inventory["direct"], direct, errors)
    compare_exact(
        "combinational full-P register exemption",
        inventory["combinational_full_p_regs"], combinational_full_p, errors,
    )
    compare_exact("generation authority", inventory["generation"], generation, errors)
    compare_exact("owner-token Q field", inventory["token_q"], token_q, errors)
    compare_exact("ProducerId-bearing PipeStageReg", inventory["packed"], packed, errors)
    for item in sorted(inventory["unclassified_generation_regs"]):
        errors.append(f"unclassified generation register: {'::'.join(item)}")

    for section, allowed in (
        ("direct_full_p_fields", DIRECT_CLASSES),
        ("token_q_fields", TOKEN_CLASSES),
        ("combinational_full_p_regs", COMBINATIONAL_FULL_P_CLASSES),
    ):
        for index, row in enumerate(manifest.get(section, [])):
            if isinstance(row, dict) and row.get("classification") not in allowed:
                errors.append(
                    f"{section}[{index}].classification invalid: {row.get('classification')!r}"
                )

    for section in (
        "direct_full_p_fields", "combinational_full_p_regs",
        "generation_authorities", "token_q_fields", "packed_full_p_stages",
        "token_set_holders",
    ):
        for index, row in enumerate(manifest.get(section, [])):
            if not isinstance(row, dict):
                continue
            path = row.get("path")
            module = row.get("module")
            anchor = row.get("coverage_anchor")
            if not all(isinstance(value, str) for value in (path, module, anchor)):
                errors.append(f"{section}[{index}] requires path/module/coverage_anchor")
                continue
            body = inventory["modules"].get((path, module))
            if body is None:
                errors.append(f"{section}[{index}] module missing: {path}::{module}")
                continue
            try:
                matched = re.search(anchor, body, re.DOTALL) is not None
            except re.error as exc:
                errors.append(f"{section}[{index}] invalid coverage_anchor: {exc}")
                continue
            if not matched:
                errors.append(f"{section}[{index}] coverage anchor missing: {row.get('id')}")

    anchors = manifest.get("required_anchors")
    if not isinstance(anchors, list):
        errors.append("required_anchors must be a list")
    else:
        anchor_ids: set[str] = set()
        for index, row in enumerate(anchors):
            if not isinstance(row, dict):
                errors.append(f"required_anchors[{index}] must be an object")
                continue
            anchor_id = row.get("id")
            if not isinstance(anchor_id, str) or not anchor_id:
                errors.append(f"required_anchors[{index}].id must be non-empty")
            elif anchor_id in anchor_ids:
                errors.append(f"duplicate required anchor id: {anchor_id}")
            anchor_ids.add(anchor_id)
            key = (row.get("path"), row.get("module"))
            pattern = row.get("pattern")
            view = row.get("view", "production")
            module_map = inventory["modules_all"] if view == "all" else inventory["modules"]
            if view not in {"production", "all"}:
                errors.append(f"required_anchors[{index}] has invalid view: {view!r}")
                continue
            if key not in module_map or not isinstance(pattern, str):
                errors.append(f"required_anchors[{index}] has invalid module/pattern")
                continue
            try:
                if re.search(pattern, module_map[key], re.DOTALL) is None:
                    errors.append(f"required anchor missing: {anchor_id}")
            except re.error as exc:
                errors.append(f"required anchor {anchor_id} has invalid regex: {exc}")
        if anchor_ids != REQUIRED_ANCHOR_IDS:
            errors.append(
                "required anchor id set drifted: "
                f"missing={sorted(REQUIRED_ANCHOR_IDS-anchor_ids)} "
                f"extra={sorted(anchor_ids-REQUIRED_ANCHOR_IDS)}"
            )

    forbidden = manifest.get("forbidden_anchors")
    if not isinstance(forbidden, list):
        errors.append("forbidden_anchors must be a list")
    else:
        forbidden_ids: set[str] = set()
        for index, row in enumerate(forbidden):
            if not isinstance(row, dict):
                errors.append(f"forbidden_anchors[{index}] must be an object")
                continue
            anchor_id = row.get("id")
            if isinstance(anchor_id, str):
                forbidden_ids.add(anchor_id)
            key = (row.get("path"), row.get("module"))
            pattern = row.get("pattern")
            if key not in inventory["modules"] or not isinstance(pattern, str):
                errors.append(f"forbidden_anchors[{index}] has invalid module/pattern")
                continue
            try:
                if re.search(pattern, inventory["modules"][key], re.DOTALL) is not None:
                    errors.append(f"forbidden anchor matched: {anchor_id}")
            except re.error as exc:
                errors.append(f"forbidden anchor {anchor_id} has invalid regex: {exc}")
        if forbidden_ids != FORBIDDEN_ANCHOR_IDS:
            errors.append(
                "forbidden anchor id set drifted: "
                f"missing={sorted(FORBIDDEN_ANCHOR_IDS-forbidden_ids)} "
                f"extra={sorted(forbidden_ids-FORBIDDEN_ANCHOR_IDS)}"
            )

    evidence = manifest.get("dynamic_evidence_contract")
    expected_markers = {
        "V8L-INTIQ-DEATH-EDGE",
        "V8L-FINITE-GENERATION-WRAP",
        "V8L-TRANSIENT-HOLDER-CENSUS",
        "V8L-MEM-HANDOFF-BACKPRESSURE",
        "V8L-MEM-INDIRECT-TRACKER",
    }
    if not isinstance(evidence, dict) or \
            set(evidence.get("required_markers", [])) != expected_markers or \
            evidence.get("required_generation_width") != 1 or \
            evidence.get("compile_success_mutations_required") is not True:
        errors.append("dynamic_evidence_contract is incomplete or weakened")
    return errors


def audit(repo_root: Path, manifest_path: Path, source_root: Path) -> dict[str, Any]:
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes.decode("utf-8"))
    inventory = source_inventory(repo_root, source_root)
    errors = validate_manifest(manifest, inventory)
    checker_path = Path(__file__).resolve()
    return {
        "schema_version": SCHEMA,
        "status": "PASS" if not errors else "FAIL",
        "scope": EXPECTED_SCOPE,
        "status_ledger": manifest.get("status_ledger"),
        "counts": {
            "direct_full_p_fields": len(inventory["direct"]),
            "combinational_full_p_regs": len(
                inventory["combinational_full_p_regs"]
            ),
            "generation_authorities": len(inventory["generation"]),
            "token_q_fields": len(inventory["token_q"]),
            "packed_full_p_stages": len(inventory["packed"]),
        },
        "hashes": {
            "manifest_sha256": sha256_bytes(manifest_bytes),
            "checker_sha256": sha256_bytes(checker_path.read_bytes()),
            "source_set_sha256": inventory["source_set_sha256"],
            "source_files": inventory["source_hashes"],
        },
        "discovered": {
            "direct_full_p_fields": [list(item) for item in sorted(inventory["direct"])],
            "combinational_full_p_regs": [
                list(item)
                for item in sorted(inventory["combinational_full_p_regs"])
            ],
            "generation_authorities": [list(item) for item in sorted(inventory["generation"])],
            "token_q_fields": [list(item) for item in sorted(inventory["token_q"])],
            "packed_full_p_stages": [list(item) for item in sorted(inventory["packed"])],
        },
        "errors": errors,
    }


def main() -> int:
    default_repo = Path(__file__).resolve().parents[5]
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=default_repo)
    parser.add_argument(
        "--manifest", type=Path,
        default=default_repo / "npc/rv64/design/arch/producer-holder-census.json",
    )
    parser.add_argument(
        "--source-root", type=Path,
        default=default_repo / "npc/rv64/vsrc",
    )
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    result = audit(
        args.repo_root.resolve(), args.manifest.resolve(), args.source_root.resolve()
    )
    payload = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(payload, encoding="utf-8")
    if result["status"] == "PASS":
        counts = result["counts"]
        print(
            "[PRODUCER-HOLDER-CENSUS] PASS "
            f"direct={counts['direct_full_p_fields']} "
            f"packed={counts['packed_full_p_stages']} "
            f"token_q={counts['token_q_fields']} "
            f"generation={counts['generation_authorities']}"
        )
        return 0
    print("[PRODUCER-HOLDER-CENSUS] FAIL", file=sys.stderr)
    for error in result["errors"]:
        print(f"- {error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
