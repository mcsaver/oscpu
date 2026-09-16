#!/usr/bin/env python3
"""Audit product reachability of the legacy OooIntBackend memory buffer.

The product NpcTop configuration enables the dual-memory datapath.  In that
configuration the legacy one-entry post-reservation buffer must have no birth
or request path.  This checker binds both the Verilog parameter chain and the
parameter-specialized Yosys graph; it does not claim that the holder is absent
from every legal OooIntBackend configuration.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import pathlib
import re
import sys
from datetime import datetime, timezone
from typing import Any, Mapping, Sequence


SCHEMA = "npc-rv64-memory-buffer-product-reachability-v1"
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
SOURCE_PATHS = (
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
)
PASS_THROUGH_PATHS = SOURCE_PATHS[1:5]
PRODUCT_ZERO_NETS = (
    "issue0_mem_buffer_fire_w",
    "issue1_mem_buffer_fire_w",
    "mem_buffer_req_valid_w",
)
SHA256_RE = re.compile(r"[0-9a-f]{64}")


class ReachabilityError(ValueError):
    """Raised when the product-inactive contract is not proven."""


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _require_count(
    text: str,
    pattern: str,
    expected: int,
    message: str,
    *,
    flags: int = 0,
) -> None:
    actual = len(re.findall(pattern, text, flags))
    if actual != expected:
        raise ReachabilityError(
            f"{message}: expected {expected}, observed {actual}"
        )


def audit_source_contract(sources: Mapping[str, str]) -> dict[str, Any]:
    """Validate the exact product parameter chain and legacy birth/capture RTL."""
    if set(sources) != set(SOURCE_PATHS):
        missing = sorted(set(SOURCE_PATHS) - set(sources))
        extra = sorted(set(sources) - set(SOURCE_PATHS))
        raise ReachabilityError(
            f"source set drifted: missing={missing} extra={extra}"
        )

    top_text = sources[SOURCE_PATHS[0]]
    _require_count(
        top_text,
        r"\.ENABLE_DUAL_MEM\s*\(\s*1\s*\)",
        1,
        "NpcCoreTop product ENABLE_DUAL_MEM binding",
    )
    for path in PASS_THROUGH_PATHS:
        text = sources[path]
        _require_count(
            text,
            r"\bparameter\s+ENABLE_DUAL_MEM\s*=\s*0\b",
            1,
            f"{path} legacy default parameter",
        )
        _require_count(
            text,
            r"\.ENABLE_DUAL_MEM\s*\(\s*ENABLE_DUAL_MEM\s*\)",
            1,
            f"{path} ENABLE_DUAL_MEM pass-through",
        )

    rtl = sources[SOURCE_PATHS[-1]]
    _require_count(
        rtl,
        r"\bparameter\s+ENABLE_DUAL_MEM\s*=\s*0\b",
        1,
        "OooIntBackend legacy default parameter",
    )
    _require_count(
        rtl,
        r"wire\s+mem_buffer_req_valid_w\s*=\s*"
        r"!ENABLE_DUAL_MEM\s*&&\s*mem_buffer_valid_q\s*&&\s*"
        r"mem_request_slot_open_w\s*;",
        1,
        "product buffer request gate",
        flags=re.S,
    )
    _require_count(
        rtl,
        r"assign\s+issue0_mem_buffer_fire_w\s*=\s*"
        r"!ENABLE_DUAL_MEM\s*&&\s*mem_issue_res_consume_fire_w\s*&&"
        r".*?!issue0_mem_request_fire_w\s*&&\s*!mem_buffer_valid_q\s*;",
        1,
        "lane0 legacy buffer birth gate",
        flags=re.S,
    )
    _require_count(
        rtl,
        r"assign\s+issue1_mem_buffer_fire_w\s*=\s*"
        r"!ENABLE_DUAL_MEM\s*&&\s*mem_issue1_res_consume_fire_w\s*&&"
        r".*?!issue1_mem_request_fire_w\s*&&\s*!mem_buffer_valid_q\s*;",
        1,
        "lane1 legacy buffer birth gate",
        flags=re.S,
    )
    _require_count(
        rtl,
        r"mem_buffer_valid_q\s*<=\s*1'b1\s*;",
        2,
        "legacy buffer valid-set inventory",
    )
    _require_count(
        rtl,
        r"if\s*\(\s*issue0_mem_buffer_fire_w\s*\)\s*begin.*?"
        r"mem_buffer_valid_q\s*<=\s*1'b1\s*;.*?"
        r"mem_buffer_owner_token_q\s*<=\s*"
        r"mem_issue_res_owner_token_q\s*;",
        1,
        "lane0 exact token capture",
        flags=re.S,
    )
    _require_count(
        rtl,
        r"if\s*\(\s*issue1_mem_buffer_fire_w\s*\)\s*begin.*?"
        r"mem_buffer_valid_q\s*<=\s*1'b1\s*;.*?"
        r"mem_buffer_owner_token_q\s*<=\s*"
        r"mem_issue1_res_owner_token_q\s*;",
        1,
        "lane1 exact token capture",
        flags=re.S,
    )

    return {
        "product_top_binding": 1,
        "parameter_pass_through_count": len(PASS_THROUGH_PATHS),
        "legacy_birth_gate_count": 2,
        "legacy_valid_set_count": 2,
        "exact_token_capture_count": 2,
    }


def _load_json(path: pathlib.Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _load_full_yosys_json(path: pathlib.Path) -> tuple[dict[str, Any], bytes]:
    payload = path.read_bytes()
    if path.suffix == ".gz":
        payload = gzip.decompress(payload)
    value = json.loads(payload.decode("utf-8"))
    if not isinstance(value, dict):
        raise ReachabilityError("full Yosys JSON is not an object")
    return value, payload


def audit_elaborated_contract(
    receipt: Mapping[str, Any],
    full_graph: Mapping[str, Any],
    full_graph_bytes: bytes,
) -> dict[str, Any]:
    """Validate the product instance and constant-zero specialized nets."""
    design_id = receipt.get("design_id")
    if (
        not isinstance(design_id, str)
        or not design_id.startswith("sha256:")
        or SHA256_RE.fullmatch(design_id.removeprefix("sha256:")) is None
    ):
        raise ReachabilityError("instance-graph receipt design_id is invalid")
    expected_graph_sha = receipt.get("full_yosys_json_sha256")
    actual_graph_sha = sha256_bytes(full_graph_bytes)
    if (
        not isinstance(expected_graph_sha, str)
        or expected_graph_sha != actual_graph_sha
    ):
        raise ReachabilityError("full Yosys JSON digest does not match receipt")

    instances = receipt.get("reachable_instances")
    if not isinstance(instances, list):
        raise ReachabilityError("reachable_instances is missing")
    matches = [
        row
        for row in instances
        if isinstance(row, dict) and row.get("path") == PRODUCT_INSTANCE
    ]
    if len(matches) != 1:
        raise ReachabilityError(
            f"product OooIntBackend instance count is {len(matches)}, not 1"
        )
    elaborated_type = matches[0].get("elaborated_type")
    if not isinstance(elaborated_type, str) or not elaborated_type:
        raise ReachabilityError("product OooIntBackend elaborated type is invalid")

    modules = full_graph.get("modules")
    if not isinstance(modules, dict):
        raise ReachabilityError("full Yosys JSON lacks modules")
    module = modules.get(elaborated_type)
    if not isinstance(module, dict):
        raise ReachabilityError(
            "product OooIntBackend specialized module is absent from Yosys JSON"
        )
    netnames = module.get("netnames")
    if not isinstance(netnames, dict):
        raise ReachabilityError(
            "product OooIntBackend specialized module lacks netnames"
        )
    observations: dict[str, list[Any]] = {}
    for net in PRODUCT_ZERO_NETS:
        row = netnames.get(net)
        bits = row.get("bits") if isinstance(row, dict) else None
        if bits != ["0"]:
            raise ReachabilityError(
                f"product specialized net {net} is not constant zero: {bits!r}"
            )
        observations[net] = bits

    return {
        "design_id": design_id,
        "product_instance": PRODUCT_INSTANCE,
        "elaborated_type": elaborated_type,
        "constant_zero_nets": observations,
        "full_yosys_json_sha256": actual_graph_sha,
    }


def build_receipt(
    repo_root: pathlib.Path,
    instance_receipt_path: pathlib.Path,
    full_graph_path: pathlib.Path,
) -> dict[str, Any]:
    sources: dict[str, str] = {}
    source_rows: list[dict[str, str]] = []
    for relative in SOURCE_PATHS:
        path = repo_root / relative
        text = path.read_text(encoding="utf-8")
        sources[relative] = text
        source_rows.append({"path": relative, "sha256": sha256_file(path)})
    source_contract = audit_source_contract(sources)

    instance_receipt = _load_json(instance_receipt_path)
    if not isinstance(instance_receipt, dict):
        raise ReachabilityError("instance-graph receipt is not an object")
    full_graph, full_graph_bytes = _load_full_yosys_json(full_graph_path)
    elaborated_contract = audit_elaborated_contract(
        instance_receipt, full_graph, full_graph_bytes
    )
    return {
        "schema": SCHEMA,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "PASS",
        "classification": "verification",
        "claim": (
            "The legacy memory buffer has no birth or request path in the "
            "current NpcTop ENABLE_DUAL_MEM=1 product instance."
        ),
        "claim_boundary": (
            "Product configuration reachability only.  Legacy "
            "ENABLE_DUAL_MEM=0 lifecycle semantics require independent "
            "dynamic evidence; whole architecture and PPA are not promoted."
        ),
        "design_id": elaborated_contract["design_id"],
        "source_contract": source_contract,
        "elaborated_contract": elaborated_contract,
        "sources": source_rows,
        "artifacts": {
            "instance_graph_receipt": {
                "path": instance_receipt_path.resolve().relative_to(
                    repo_root
                ).as_posix(),
                "sha256": sha256_file(instance_receipt_path),
            },
            "full_yosys_json": {
                "path": full_graph_path.resolve().relative_to(
                    repo_root
                ).as_posix(),
                "sha256": sha256_file(full_graph_path),
                "uncompressed_sha256": elaborated_contract[
                    "full_yosys_json_sha256"
                ],
            },
        },
    }


def write_json(path: pathlib.Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            payload,
            allow_nan=False,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    parser.add_argument("--instance-graph-receipt", required=True, type=pathlib.Path)
    parser.add_argument("--full-yosys-json", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        receipt = build_receipt(
            args.repo_root.resolve(),
            args.instance_graph_receipt.resolve(),
            args.full_yosys_json.resolve(),
        )
    except (
        OSError,
        UnicodeError,
        json.JSONDecodeError,
        ReachabilityError,
        ValueError,
    ) as exc:
        receipt = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "FAIL",
            "claim_boundary": "No product reachability claim is granted.",
            "errors": [str(exc)],
        }
        write_json(args.output.resolve(), receipt)
        print(f"[MEMORY-BUFFER-PRODUCT-REACHABILITY] FAIL: {exc}", file=sys.stderr)
        return 1
    write_json(args.output.resolve(), receipt)
    print(
        "[MEMORY-BUFFER-PRODUCT-REACHABILITY] PASS "
        "product_birth=0 product_request=0 legacy_dynamic_required=1"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
