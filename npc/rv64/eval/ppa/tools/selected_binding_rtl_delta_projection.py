#!/usr/bin/env python3
"""Capture/verify a fail-closed selected-binding RTL delta receipt.

``capture`` is the only mode which reads Git.  It freezes two RTL blobs from
an exact commit, records a self-contained reversible line edit, proves that
the census-declared pre-existing holder nonblocking writes did not change,
and binds the V14R positive/mutation evidence to the live Backend/SQ bytes.
``verify`` deliberately has no Git dependency.
"""

from __future__ import annotations

import argparse
import base64
import difflib
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from typing import Any, Iterable


SCHEMA = "rv64-selected-binding-rtl-delta-projection-v2"
RTL_PATHS = (
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooStoreQueue.v",
)
CONSUMER_PATHS = (
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
)
CENSUS = "npc/rv64/design/arch/producer-holder-census.json"
COVERAGE = "npc/rv64/design/arch/producer-holder-semantic-coverage.json"
POLICY = "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
EVIDENCE = (
    ".github/task-runs/2026-08-06-rv64-v15h-architecture-debt-current-f7a/"
    "evidence/v14r-current"
)
NEW_UNITS = {
    "memory-request-hold0-token": "mem_req_hold_owner_token_q",
    "memory-request-hold1-token": "mem1_req_hold_owner_token_q",
}
NEW_STATE = {
    "mem_req_hold_valid_q": 3,
    "mem_req_hold_sel_q": 3,
    "mem_req_hold_owner_kind_q": 2,
    "mem_req_hold_owner_token_q": 2,
    "mem_req_hold_mmu_epoch_q": 2,
    "mem1_req_hold_valid_q": 3,
    "mem1_req_hold_sel_q": 3,
    "mem1_req_hold_owner_kind_q": 2,
    "mem1_req_hold_owner_token_q": 2,
    "mem1_req_hold_mmu_epoch_q": 2,
}
POSITIVE_LOGS = {
    "focused/logs/tb_ooo_int_backend_v14r_memory_request_hold.log": (
        "[V14R-MEMORY-REQUEST-HOLD] holder_ff=29 payload_bits=217 ",
        "[PASS] tb_ooo_int_backend_v14r_memory_request_hold",
    ),
    "single-bank/logs/tb_ooo_int_backend_v14r_single_bank_probe_order.log": (
        "[V14R-SINGLE-BANK-PROBE-ORDER] older_probe=1 ",
        "[PASS] tb_ooo_int_backend_v14r_single_bank_probe_order",
    ),
    "store-queue/logs/tb_ooo_store_queue.log": (
        "[V8T-F3-SQ-QUERY]",
        "[PASS] tb_ooo_store_queue",
    ),
    "dual-memory/logs/tb_ooo_int_backend_v8s_dual_memory.log": (
        "[PASS] tb_ooo_int_backend_v8s_dual_memory",
    ),
    "linked-regressions/logs/tb_ooo_int_backend.log": (
        "[PASS] tb_ooo_int_backend",
    ),
    "linked-regressions/logs/tb_ooo_int_backend_v11l_memory_retry_holder.log": (
        "[PASS] tb_ooo_int_backend_v11l_memory_retry_holder",
    ),
    "linked-regressions/logs/tb_ooo_int_backend_v11m_memory_reservation_holder.log": (
        "[PASS] tb_ooo_int_backend_v11m_memory_reservation_holder",
    ),
}
MUTATIONS = {
    "holder-bypass": "[V14R-H2-BANK0-PAYLOAD-HOLD]",
    "cancel-fallback": "[V14R-H4-BANK0-CANCEL-BUBBLE]",
    "consume-miq-live-split": "[CHECK-FAIL] V14R bank0 exact reservation consumes",
    "single-bank-probe-order": "[CHECK-FAIL] V14R younger probe has zero VALID",
    "sq-held-launch-residency": "[V14R-H4-BANK0-SOURCE-LOSS]",
    "amo-held-launch-authorization": "[V8G-AMO-LAUNCH-AUTH]",
}
CLAIM = (
    "This receipt projects only the census-declared pre-existing holder write "
    "statements across the Backend/SQ delta, requires the two selected legacy "
    "testbench deltas to be additive-only, and binds the two new bank-local "
    "request-hold tokens plus current testbench bytes to retained V14R "
    "evidence. It does not promote full architecture, system, synthesis, STA, "
    "power, CPI, or PPA status."
)
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)
HUNK_RE = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


class ProjectionGap(RuntimeError):
    pass


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()


def digest(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha_file(path: pathlib.Path) -> str:
    return sha_bytes(path.read_bytes())


def inside(root: pathlib.Path, value: str) -> pathlib.Path:
    path = (root / value).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as exc:
        raise ProjectionGap(f"path escapes root: {value}") from exc
    return path


def load_json(path: pathlib.Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ProjectionGap(f"JSON object required: {path}")
    return value


def git_show(root: pathlib.Path, *args: str) -> bytes:
    done = subprocess.run(
        ["git", "-C", str(root), "show", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if done.returncode:
        raise ProjectionGap(done.stderr.decode(errors="replace").strip())
    return done.stdout


def make_delta(path: str, baseline: bytes, current: bytes) -> dict[str, Any]:
    old = baseline.splitlines(keepends=True)
    new = current.splitlines(keepends=True)
    edits = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(
        None, old, new
    ).get_opcodes():
        if tag == "equal":
            continue
        old_chunk = b"".join(old[i1:i2])
        new_chunk = b"".join(new[j1:j2])
        edits.append(
            {
                "tag": tag,
                "baseline_start": i1,
                "baseline_end": i2,
                "current_start": j1,
                "current_end": j2,
                "baseline_b64": base64.b64encode(old_chunk).decode(),
                "current_b64": base64.b64encode(new_chunk).decode(),
                "baseline_chunk_sha256": sha_bytes(old_chunk),
                "current_chunk_sha256": sha_bytes(new_chunk),
            }
        )
    if not edits:
        raise ProjectionGap(f"baseline/current RTL are identical: {path}")
    return {
        "path": path,
        "baseline_sha256": sha_bytes(baseline),
        "current_sha256": sha_bytes(current),
        "baseline_size": len(baseline),
        "current_size": len(current),
        "edits": edits,
    }


def require_additive_delta(record: dict[str, Any]) -> None:
    edits = record.get("edits")
    if not isinstance(edits, list) or not edits:
        raise ProjectionGap("additive consumer delta is absent")
    for edit in edits:
        if edit.get("tag") != "insert" or _chunk(edit, "baseline") != b"":
            raise ProjectionGap(
                f"selected testbench changed existing lines: {record.get('path')}"
            )


def _chunk(edit: dict[str, Any], prefix: str) -> bytes:
    try:
        data = base64.b64decode(edit[f"{prefix}_b64"], validate=True)
    except Exception as exc:
        raise ProjectionGap(f"invalid {prefix} reversible edit") from exc
    if sha_bytes(data) != edit.get(f"{prefix}_chunk_sha256"):
        raise ProjectionGap(f"{prefix} reversible edit hash drift")
    return data


def reverse_delta(record: dict[str, Any], current: bytes) -> bytes:
    if sha_bytes(current) != record.get("current_sha256"):
        raise ProjectionGap(f"current RTL hash drift: {record.get('path')}")
    lines = current.splitlines(keepends=True)
    edits = record.get("edits")
    if not isinstance(edits, list) or not edits:
        raise ProjectionGap("reversible edits absent")
    for edit in reversed(edits):
        start, end = edit.get("current_start"), edit.get("current_end")
        if not isinstance(start, int) or not isinstance(end, int) or start > end:
            raise ProjectionGap("invalid current edit range")
        old_chunk, new_chunk = _chunk(edit, "baseline"), _chunk(edit, "current")
        if b"".join(lines[start:end]) != new_chunk:
            raise ProjectionGap("reverse edit does not match current RTL")
        lines[start:end] = old_chunk.splitlines(keepends=True)
    baseline = b"".join(lines)
    if sha_bytes(baseline) != record.get("baseline_sha256"):
        raise ProjectionGap("reverse reconstruction baseline hash mismatch")
    check = baseline.splitlines(keepends=True)
    for edit in reversed(edits):
        start, end = edit["baseline_start"], edit["baseline_end"]
        old_chunk, new_chunk = _chunk(edit, "baseline"), _chunk(edit, "current")
        if b"".join(check[start:end]) != old_chunk:
            raise ProjectionGap("forward edit does not match baseline RTL")
        check[start:end] = new_chunk.splitlines(keepends=True)
    if b"".join(check) != current:
        raise ProjectionGap("forward reconstruction current mismatch")
    return baseline


def assignments(data: bytes, symbol: str) -> list[str]:
    text = COMMENT_RE.sub(" ", data.decode("utf-8"))
    pattern = re.compile(
        rf"(?<![A-Za-z0-9_$]){re.escape(symbol)}"
        rf"(?:\s*\[[^;]*?\])?\s*<=\s*.*?;",
        re.DOTALL,
    )
    return sorted(re.sub(r"\s+", " ", item.group(0)).strip() for item in pattern.finditer(text))


def walk(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def write_record(writes: list[str]) -> dict[str, Any]:
    return {"count": len(writes), "sha256": digest(writes), "writes": writes}


def holder_projection(
    root: pathlib.Path,
    baseline: dict[str, bytes],
    current: dict[str, bytes],
    census_path: str,
    coverage_path: str,
    frozen_prior_coverage: dict[str, Any] | None = None,
) -> dict[str, Any]:
    census_file = inside(root, census_path)
    census = load_json(census_file)
    rows = [
        row for row in walk(census)
        if isinstance(row.get("id"), str)
        and row.get("path") in RTL_PATHS
        and isinstance(row.get("symbol"), str)
    ]
    by_id = {row["id"]: row for row in rows}
    for unit, symbol in NEW_UNITS.items():
        row = by_id.get(unit)
        if not row or row.get("path") != RTL_PATHS[0] or row.get("symbol") != symbol:
            raise ProjectionGap(f"new holder census unit drift: {unit}")
    old_records = []
    ignored = []
    for row in sorted(rows, key=lambda item: item["id"]):
        if row["id"] in NEW_UNITS:
            continue
        old_writes = assignments(baseline[row["path"]], row["symbol"])
        new_writes = assignments(current[row["path"]], row["symbol"])
        if not old_writes and not new_writes:
            ignored.append({"unit_id": row["id"], "path": row["path"], "symbol": row["symbol"]})
            continue
        if old_writes != new_writes:
            raise ProjectionGap(f"pre-existing holder write drift: {row['id']}")
        old_records.append(
            {
                "unit_id": row["id"],
                "path": row["path"],
                "symbol": row["symbol"],
                "fingerprint": write_record(old_writes),
            }
        )
    if not old_records:
        raise ProjectionGap("no pre-existing holder writes were proven")
    new_records = []
    for symbol, expected_count in NEW_STATE.items():
        if assignments(baseline[RTL_PATHS[0]], symbol):
            raise ProjectionGap(f"new holder state existed in baseline: {symbol}")
        writes = assignments(current[RTL_PATHS[0]], symbol)
        if len(writes) != expected_count:
            raise ProjectionGap(f"new holder write count drift: {symbol}")
        new_records.append({"path": RTL_PATHS[0], "symbol": symbol, "fingerprint": write_record(writes)})

    baseline_hashes = {path: sha_bytes(baseline[path]) for path in RTL_PATHS}
    if frozen_prior_coverage is None:
        coverage_file = inside(root, coverage_path)
        coverage = load_json(coverage_file)
        bound_counts = {}
        for path in RTL_PATHS:
            hashes = []
            for item in walk(coverage):
                source = item.get("source")
                if isinstance(source, dict) and source.get("path") == path:
                    hashes.append(source.get("sha256"))
                if item.get("path") == path and isinstance(item.get("evidence_sha256"), str):
                    hashes.append(item["evidence_sha256"])
            if not hashes or any(value != baseline_hashes[path] for value in hashes):
                raise ProjectionGap(f"frozen baseline is not the old semantic ledger source: {path}")
            bound_counts[path] = len(hashes)
        prior_coverage = {
            "path": coverage_path,
            "sha256_at_capture": sha_file(coverage_file),
            "design_id": coverage.get("design_id"),
            "baseline_binding_counts": bound_counts,
            "baseline_sha256": baseline_hashes,
        }
    else:
        prior_coverage = frozen_prior_coverage
        if (
            prior_coverage.get("path") != coverage_path
            or prior_coverage.get("baseline_sha256") != baseline_hashes
            or not isinstance(prior_coverage.get("baseline_binding_counts"), dict)
            or any(not isinstance(value, int) or value < 1 for value in prior_coverage["baseline_binding_counts"].values())
        ):
            raise ProjectionGap("frozen prior coverage baseline binding drift")
    result = {
        "census": {"path": census_path, "sha256": sha_file(census_file), "design_id": census.get("design_id")},
        # This is intentionally a capture-time snapshot.  A later ledger
        # rebuild may consume the receipt without creating a hash cycle.
        "prior_coverage": prior_coverage,
        "new_unit_ids": sorted(NEW_UNITS),
        "pre_existing_state_writes": old_records,
        "non_state_census_symbols": ignored,
        "new_holder_state_writes": sorted(new_records, key=lambda item: item["symbol"]),
        "pre_existing_writes_unchanged": True,
    }
    result["projection_sha256"] = digest(result)
    return result


def parse_kv(path: pathlib.Path) -> dict[str, str]:
    result = {}
    for line in path.read_text(encoding="utf-8", errors="strict").splitlines():
        if not line or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key in result:
            raise ProjectionGap(f"duplicate result key: {path}:{key}")
        result[key] = value
    return result


def artifact(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
    if not path.is_file():
        raise ProjectionGap(f"missing V14R artifact: {path}")
    rel = path.resolve().relative_to(root.resolve()).as_posix()
    return {"path": rel, "sha256": sha_file(path), "size_bytes": path.stat().st_size}


def manifest(path: pathlib.Path) -> dict[str, str]:
    result = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split(None, 1)
        if len(parts) != 2 or not SHA_RE.fullmatch(parts[0]):
            raise ProjectionGap(f"invalid V14R manifest: {path}")
        value = parts[1].replace("\\", "/")
        marker = "/npc/"
        if marker not in value:
            raise ProjectionGap(f"non-repository V14R manifest path: {value}")
        rel = "npc/" + value.rsplit(marker, 1)[1]
        if rel in result:
            raise ProjectionGap(f"duplicate V14R manifest path: {rel}")
        result[rel] = parts[0]
    return result


def apply_unified_diff(source: bytes, diff_data: bytes, variant: str) -> bytes:
    src = source.decode("utf-8").splitlines(keepends=True)
    lines = diff_data.decode("utf-8").splitlines(keepends=True)
    if len(lines) < 3 or lines[0].strip() != "--- production/OooIntBackend.v" or lines[1].strip() != f"+++ mutation/{variant}/OooIntBackend.v":
        raise ProjectionGap(f"mutation diff header drift: {variant}")
    out, cursor, index = [], 0, 2
    while index < len(lines):
        match = HUNK_RE.match(lines[index])
        if not match:
            raise ProjectionGap(f"mutation hunk header drift: {variant}")
        old_start = int(match.group(1)) - 1
        out.extend(src[cursor:old_start])
        cursor = old_start
        index += 1
        while index < len(lines) and not lines[index].startswith("@@ "):
            line = lines[index]
            if line.startswith("\\ No newline"):
                index += 1
                continue
            prefix, payload = line[:1], line[1:]
            if prefix in {" ", "-"}:
                if cursor >= len(src) or src[cursor] != payload:
                    raise ProjectionGap(f"mutation diff does not apply to current RTL: {variant}")
                if prefix == " ":
                    out.append(src[cursor])
                cursor += 1
            elif prefix == "+":
                out.append(payload)
            else:
                raise ProjectionGap(f"invalid mutation diff line: {variant}")
            index += 1
    out.extend(src[cursor:])
    mutated = "".join(out).encode()
    if mutated == source:
        raise ProjectionGap(f"mutation diff is empty: {variant}")
    return mutated


def policy_binding(root: pathlib.Path, policy_path: str, evidence_root: str) -> dict[str, Any]:
    path = inside(root, policy_path)
    policy = load_json(path)
    matches = [item for item in policy.get("evidence_sets", []) if item.get("binding_kind") == "v14r_memory_request_hold"]
    if len(matches) != 1:
        raise ProjectionGap("V14R policy entry missing or duplicated")
    item = matches[0]
    selected = {(entry.get("path"), entry.get("role")) for entry in item.get("current_selected_bindings", [])}
    if item.get("semantic_closure") is not True or set(item.get("unit_ids", [])) != set(NEW_UNITS) or any((path_value, "rtl") not in selected for path_value in RTL_PATHS) or item.get("summary") != f"{evidence_root}/result.txt":
        raise ProjectionGap("V14R policy binding is incomplete")
    # Do not hash the policy itself: the policy may later add this receipt,
    # and binding both directions would create an unverifiable hash cycle.
    return {"path": policy_path, "evidence_id": item.get("id"), "unit_ids": sorted(NEW_UNITS), "selected_bindings": sorted([{"path": p, "role": r} for p, r in selected], key=lambda entry: (entry["path"], entry["role"]))}


def evidence_projection(root: pathlib.Path, evidence_root: str, current: dict[str, bytes]) -> dict[str, Any]:
    base = inside(root, evidence_root)
    result_path = base / "result.txt"
    before_path, after_path = base / "production-before.sha256", base / "production-after.sha256"
    result = parse_kv(result_path)
    expected = {"RESULT": "PASS", "TIER": "link", "HOLDER_FF": "29", "PAYLOAD_SHADOW_BITS": "217", "MUTATION_TOTAL": "6", "MANIFEST_FILES": "9", "BUILD_RETAINED": "0", "CLEANUP": "PASS", "PPA": "UNQUALIFIED"}
    if any(result.get(key) != value for key, value in expected.items()):
        raise ProjectionGap("V14R result fields drift")
    before, after = manifest(before_path), manifest(after_path)
    selected_sources = (*RTL_PATHS, *CONSUMER_PATHS)
    if before != after or any(after.get(path) != sha_bytes(current[path]) for path in selected_sources) or result.get("MANIFEST_SHA256") != sha_file(after_path):
        raise ProjectionGap("V14R production manifest is not current")
    artifacts = [artifact(root, path) for path in (result_path, before_path, after_path)]
    positive = []
    for rel, markers in sorted(POSITIVE_LOGS.items()):
        path = base / rel
        text = path.read_text(encoding="utf-8", errors="replace")
        if text.count("[RESULT] PASS") != 1 or "[RESULT] FAIL" in text or any(marker not in text for marker in markers):
            raise ProjectionGap(f"V14R positive log drift: {rel}")
        artifacts.append(artifact(root, path))
        positive.append({"path": f"{evidence_root}/{rel}", "markers": list(markers)})
    mutation_root = base / "mutation"
    observed = {path.name for path in mutation_root.iterdir() if path.is_dir()}
    if observed != set(MUTATIONS):
        raise ProjectionGap("V14R mutation inventory drift")
    summary_path = mutation_root / "result.txt"
    summary = parse_kv(summary_path)
    backend_sha = sha_bytes(current[RTL_PATHS[0]])
    summary_expected = {"RESULT": "PASS", "VARIANT_TOTAL": "6", "VARIANT_PASS_COUNT": "6", "COMPILE_SUCCESS": "1", "MUTATION_DETECTED": "1", "PRODUCTION_SHA_BEFORE": backend_sha, "PRODUCTION_SHA_AFTER": backend_sha}
    if any(summary.get(key) != value for key, value in summary_expected.items()):
        raise ProjectionGap("V14R mutation summary drift")
    artifacts.append(artifact(root, summary_path))
    variants = []
    for name, marker in sorted(MUTATIONS.items()):
        variant_root = mutation_root / name
        result_file = variant_root / "result.txt"
        values = parse_kv(result_file)
        expected_variant = {"RESULT": "PASS", "MUTATION": name, "EXPECTED_MARKER": marker, "COMPILE_SUCCESS": "1", "MUTATION_DETECTED": "1", "EXPECTED_TEST_FAILURE": "1", "MAKE_RC": "2", "PRODUCTION_SHA_BEFORE": backend_sha, "PRODUCTION_SHA_AFTER": backend_sha}
        if any(values.get(key) != value for key, value in expected_variant.items()):
            raise ProjectionGap(f"V14R mutation result drift: {name}")
        log_file = variant_root / "mutation/logs" / ("tb_ooo_int_backend_v14r_single_bank_probe_order.log" if name == "single-bank-probe-order" else "tb_ooo_int_backend_v14r_memory_request_hold.log")
        diff_file = variant_root / f"{name}.diff"
        log_text = log_file.read_text(encoding="utf-8", errors="replace")
        if marker not in log_text or log_text.count("[RESULT] FAIL") != 1 or "[RESULT] PASS" in log_text:
            raise ProjectionGap(f"V14R mutation oracle drift: {name}")
        mutated = apply_unified_diff(current[RTL_PATHS[0]], diff_file.read_bytes(), name)
        artifacts.extend(artifact(root, path) for path in (result_file, log_file, diff_file))
        variants.append({"name": name, "marker": marker, "mutated_rtl_sha256": sha_bytes(mutated)})
    value = {"root": evidence_root, "positive_profiles": positive, "mutations": variants, "production_manifest": dict(sorted(after.items())), "bound_artifacts": sorted(artifacts, key=lambda item: item["path"]), "positive_count": 7, "compile_success_mutations_rejected": 6}
    value["projection_sha256"] = digest(value)
    return value


def build_receipt(args: argparse.Namespace) -> dict[str, Any]:
    root = args.root.resolve()
    commit = git_show(root, "-s", "--format=%H", args.baseline_ref).decode().strip()
    if not re.fullmatch(r"[0-9a-f]{40,64}", commit):
        raise ProjectionGap("baseline ref did not resolve to one commit")
    baseline = {path: git_show(root, f"{commit}:{path}") for path in RTL_PATHS}
    current = {path: inside(root, path).read_bytes() for path in RTL_PATHS}
    rtl = [make_delta(path, baseline[path], current[path]) for path in RTL_PATHS]
    consumer_commit = git_show(
        root, "-s", "--format=%H", args.consumer_baseline_ref
    ).decode().strip()
    if not re.fullmatch(r"[0-9a-f]{40,64}", consumer_commit):
        raise ProjectionGap("consumer baseline ref did not resolve to one commit")
    consumer_baseline = {
        path: git_show(root, f"{consumer_commit}:{path}")
        for path in CONSUMER_PATHS
    }
    consumer_current = {
        path: inside(root, path).read_bytes() for path in CONSUMER_PATHS
    }
    consumer_delta = [
        make_delta(path, consumer_baseline[path], consumer_current[path])
        for path in CONSUMER_PATHS
    ]
    for record in consumer_delta:
        require_additive_delta(record)
    current.update(consumer_current)
    holder = holder_projection(
        root, baseline, current, args.census, args.coverage
    )
    current_design_id = holder["census"].get("design_id")
    if not isinstance(current_design_id, str) or re.fullmatch(
        r"sha256:[0-9a-f]{64}", current_design_id
    ) is None:
        raise ProjectionGap("current census design identity is invalid")
    receipt = {
        "schema_version": SCHEMA,
        "status": "PASS",
        "current_design_id": current_design_id,
        "baseline": {"git_ref": args.baseline_ref, "commit": commit},
        "consumer_baseline": {
            "git_ref": args.consumer_baseline_ref,
            "commit": consumer_commit,
        },
        "rtl_delta": rtl,
        "rtl_delta_sha256": digest(rtl),
        "consumer_delta": consumer_delta,
        "consumer_delta_sha256": digest(consumer_delta),
        "holder_write_projection": holder,
        "policy_binding": policy_binding(root, args.policy, args.evidence_root),
        "v14r_evidence": evidence_projection(root, args.evidence_root, current),
        "claim_boundary": CLAIM,
    }
    return receipt


def verify_receipt(args: argparse.Namespace) -> dict[str, Any]:
    root = args.root.resolve()
    receipt = load_json(args.receipt.resolve())
    expected_keys = {"schema_version", "status", "current_design_id", "baseline", "consumer_baseline", "rtl_delta", "rtl_delta_sha256", "consumer_delta", "consumer_delta_sha256", "holder_write_projection", "policy_binding", "v14r_evidence", "claim_boundary"}
    if set(receipt) != expected_keys or receipt.get("schema_version") != SCHEMA or receipt.get("status") != "PASS" or re.fullmatch(r"sha256:[0-9a-f]{64}", str(receipt.get("current_design_id", ""))) is None or receipt.get("claim_boundary") != CLAIM:
        raise ProjectionGap("receipt envelope drift")
    rtl = receipt.get("rtl_delta")
    if not isinstance(rtl, list) or digest(rtl) != receipt.get("rtl_delta_sha256") or {item.get("path") for item in rtl if isinstance(item, dict)} != set(RTL_PATHS):
        raise ProjectionGap("RTL delta inventory or digest drift")
    current, baseline = {}, {}
    for record in rtl:
        path = record["path"]
        current[path] = inside(root, path).read_bytes()
        baseline[path] = reverse_delta(record, current[path])
    consumer_delta = receipt.get("consumer_delta")
    if not isinstance(consumer_delta, list) or digest(
        consumer_delta
    ) != receipt.get("consumer_delta_sha256") or {
        item.get("path") for item in consumer_delta if isinstance(item, dict)
    } != set(CONSUMER_PATHS):
        raise ProjectionGap("consumer delta inventory or digest drift")
    for record in consumer_delta:
        require_additive_delta(record)
        path = record["path"]
        current[path] = inside(root, path).read_bytes()
        reverse_delta(record, current[path])
    holder = holder_projection(
        root,
        baseline,
        current,
        receipt["holder_write_projection"]["census"]["path"],
        receipt["holder_write_projection"]["prior_coverage"]["path"],
        receipt["holder_write_projection"]["prior_coverage"],
    )
    if holder != receipt.get("holder_write_projection"):
        raise ProjectionGap("holder write projection drift")
    if holder["census"].get("design_id") != receipt.get("current_design_id"):
        raise ProjectionGap("current design identity drift")
    policy = policy_binding(root, receipt["policy_binding"]["path"], receipt["v14r_evidence"]["root"])
    if policy != receipt.get("policy_binding"):
        raise ProjectionGap("policy binding drift")
    evidence = evidence_projection(root, receipt["v14r_evidence"]["root"], current)
    if evidence != receipt.get("v14r_evidence"):
        raise ProjectionGap("V14R evidence projection drift")
    return receipt


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(path)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    sub = result.add_subparsers(dest="mode", required=True)
    for name in ("capture", "verify"):
        command = sub.add_parser(name)
        command.add_argument("--root", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[5])
        command.add_argument("--census", default=CENSUS)
        command.add_argument("--coverage", default=COVERAGE)
        command.add_argument("--policy", default=POLICY)
        command.add_argument("--evidence-root", default=EVIDENCE)
        if name == "capture":
            command.add_argument("--baseline-ref", required=True)
            command.add_argument("--consumer-baseline-ref", required=True)
            command.add_argument("--output", type=pathlib.Path, required=True)
        else:
            command.add_argument("--receipt", type=pathlib.Path, required=True)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if args.mode == "capture":
            receipt = build_receipt(args)
            write_json(args.output.resolve(), receipt)
            where = args.output
        else:
            receipt = verify_receipt(args)
            where = args.receipt
    except (OSError, UnicodeError, ValueError, json.JSONDecodeError, ProjectionGap) as exc:
        print(f"[RV64-RTL-DELTA-PROJECTION] GAP mode={args.mode} reason={exc}", file=sys.stderr)
        return 1
    print(f"[RV64-RTL-DELTA-PROJECTION] PASS mode={args.mode} rtl_files={len(receipt['rtl_delta'])} old_holder_writes={len(receipt['holder_write_projection']['pre_existing_state_writes'])} mutations={len(receipt['v14r_evidence']['mutations'])} receipt={where}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
