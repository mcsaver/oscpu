#!/usr/bin/env python3
"""Fail-closed aggregate audit for the frozen R4 P0-A checkpoint."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[3]
TASK = ROOT / ".github/task-runs/2026-07-15-rv64-ppa-architecture-recovery"
EVIDENCE = TASK / "evidence/r4-p0a-wb-valid"
TMP = ROOT / "tmp/2026-07-15-rv64-ppa-architecture-recovery/evidence/r4-p0a-wb-valid"
R3P6 = ROOT / "npc/rv64/eval/ppa/baselines/r3p6-recovery-baseline.json"
S0 = ROOT / "npc/rv64/eval/ppa/baselines/r4-s0-correctness-checkpoint.json"
GATE_NAMES = ["DI-1", "DI-2", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4"]


def fail(message: str) -> None:
    raise RuntimeError(message)


def load_json(path: pathlib.Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read JSON {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"JSON root is not an object: {path}")
    return value


def digest(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def record(path: pathlib.Path) -> dict:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(ROOT):
        fail(f"artifact escapes workspace: {resolved}")
    return {
        "path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def verify_sha256_manifest(path: pathlib.Path) -> int:
    count = 0
    seen: set[pathlib.Path] = set()
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if match is None:
            fail(f"malformed SHA256 row {path}:{number}")
        candidate = pathlib.Path(match.group(2))
        if not candidate.is_absolute():
            candidate = path.parent / candidate
        candidate = candidate.resolve(strict=True)
        if not candidate.is_relative_to(ROOT) or candidate in seen:
            fail(f"unsafe or duplicate SHA256 path: {candidate}")
        seen.add(candidate)
        if digest(candidate) != match.group(1):
            fail(f"SHA256 mismatch: {candidate}")
        count += 1
    if count == 0:
        fail(f"empty SHA256 manifest: {path}")
    return count


def parse_kv(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.count("=") != 1:
            fail(f"malformed key/value row {path}:{number}")
        key, value = line.split("=", 1)
        if not key or not value or key in result:
            fail(f"duplicate/empty key/value row {path}:{number}")
        result[key] = value
    return result


def require_close(actual: float, expected: float, label: str, tolerance: float = 1e-12) -> None:
    if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=tolerance):
        fail(f"{label}: actual={actual!r} expected={expected!r}")


def verify_synth_run(run: str) -> tuple[dict, list[dict], int]:
    public = EVIDENCE / f"fresh-synth-{run}/evidence/synthesis"
    frozen = TMP / f"fresh-synth-{run}"
    summary = load_json(public / "summary.json")
    expected = {
        "abc_done": 226,
        "module_count": 119,
        "vsrc_count": 140,
        "top": "NpcTop",
    }
    for key, value in expected.items():
        if summary.get(key) != value:
            fail(f"synth {run} {key} mismatch: {summary.get(key)!r}")
    freeze = parse_kv(public / "synth-input-hash-cmp.txt")
    if not freeze or set(freeze.values()) != {"PASS"}:
        fail(f"synth {run} input freeze is not all PASS")
    status = parse_kv(public / "status.txt")
    required_status = {
        "candidate_id": "r4-p0a-distributed-wb-valid",
        "candidate_role": "timing_recovery_only_not_architecture_seed",
        "run_id": run,
        "synthesis": "PASS",
        "audit": "PASS",
        "parent_netlist_binding": "PASS",
    }
    for key, value in required_status.items():
        if status.get(key) != value:
            fail(f"synth {run} status mismatch for {key}")
    pre = frozen / "synth-rtl-inputs.pre.sha256"
    post = frozen / "synth-rtl-inputs.post.sha256"
    if pre.read_bytes() != post.read_bytes():
        fail(f"synth {run} RTL pre/post manifests differ")
    # Comparing manifest bytes alone is insufficient: a stale manifest would
    # still compare equal after the live RTL changed.  Re-hash every frozen
    # input before accepting this checkpoint.
    pre_count = verify_sha256_manifest(pre)
    post_count = verify_sha256_manifest(post)
    # The synthesis manifest is the 117-file elaborated source closure.  The
    # summary's vsrc_count=140 deliberately describes the wider vsrc tree.
    if pre_count != post_count or pre_count != 117:
        fail(
            f"synth {run} RTL manifest cardinality mismatch: "
            f"pre={pre_count} post={post_count} expected=117"
        )
    if run == "run2":
        run1 = TMP / "fresh-synth-run1/synth-rtl-inputs.pre.sha256"
        if pre.read_bytes() != run1.read_bytes():
            fail("synth run1/run2 RTL input manifests differ")
    manifest_records = [record(pre), record(post)]
    return summary, manifest_records, pre_count


def verify_sta_run(run: str, expected_netlist: str) -> dict:
    directory = EVIDENCE / f"fresh-synth-{run}/opensta-exact5ns-v2"
    summary = load_json(directory / "summary.json")
    if summary.get("schema") != "ppa-r4-s0-opensta-exact5ns-v2":
        fail(f"STA {run} schema mismatch")
    if summary.get("netlist_sha256") != expected_netlist:
        fail(f"STA {run} netlist binding mismatch")
    if summary.get("claim_tier") != "rtl_proxy_partial_constraints":
        fail(f"STA {run} claim tier mismatch")
    boolean_true = [
        "completion_provenance_match",
        "console_clean",
        "hardening_mutations_passed",
        "opensta_input_freeze_match",
        "path_report_cardinality_match",
        "reserve_met",
        "setup_member_set_match",
        "setup_probe_match",
        "synthesis_binding_match",
        "target_200mhz_met",
        "timing_paths_met",
        "wns_tns_state_match",
    ]
    for key in boolean_true:
        if summary.get(key) is not True:
            fail(f"STA {run} {key} is not true")
    if summary.get("power_qualified") is not False:
        fail(f"STA {run} must keep power unqualified")
    require_close(float(summary.get("period_ns")), 5.0, f"STA {run} period")
    if float(summary.get("worst_path_slack_ns")) < 0.1:
        fail(f"STA {run} misses +0.10 ns reserve")
    require_close(float(summary.get("wns_ns")), 0.0, f"STA {run} WNS")
    require_close(float(summary.get("tns_ns")), 0.0, f"STA {run} TNS")
    if summary.get("violated_path_count") != 0 or summary.get("combinational_loops") != 0:
        fail(f"STA {run} reports violations or loops")
    if summary.get("path_count") != 40:
        fail(f"STA {run} top-path cardinality mismatch")
    status = parse_kv(directory / "status.txt")
    if status.get("candidate_id") != "r4-p0a-distributed-wb-valid" or status.get("reserve_met") != "true":
        fail(f"STA {run} candidate status mismatch")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT) or output.exists():
        fail("output must be a new path inside the workspace")

    r3p6 = load_json(R3P6)
    s0 = load_json(S0)
    matrix_dir = TASK / "evidence/p0-a-wb-valid-matrix22-v2"
    matrix_text = (matrix_dir / "summary.md").read_text(encoding="utf-8")
    if "focused: 22/22 PASS" not in matrix_text:
        fail("P0-A 22-point focused matrix is not PASS")
    matrix_manifest_count = verify_sha256_manifest(matrix_dir / "SHA256SUMS")

    module_summary = TASK / "evidence/r4-p0a-full-module-v2/summary.txt"
    module_text = module_summary.read_text(encoding="utf-8")
    for marker in ("- total: 102", "- passed: 102", "- failed: 0"):
        if marker not in module_text:
            fail(f"full module summary misses {marker!r}")

    synth1, rtl_manifests1, synth_manifest_count1 = verify_synth_run("run1")
    synth2, rtl_manifests2, synth_manifest_count2 = verify_synth_run("run2")
    if synth_manifest_count1 != synth_manifest_count2:
        fail("synthesis repetitions have different RTL manifest cardinality")
    synth_equal_keys = [
        "abc_done", "area", "module_count", "netlist_bytes", "netlist_sha256",
        "sequential_area", "vsrc_count",
    ]
    for key in synth_equal_keys:
        if synth1.get(key) != synth2.get(key):
            fail(f"synthesis repetitions differ for {key}")
    area = float(synth1["area"])
    r3_area = float(r3p6["area"]["logic_area"])
    s0_area = float(s0["area"]["logic_area"])
    strict_ceiling = float(s0["area"]["strict_area_efficiency_maximum"])
    if area > strict_ceiling:
        fail(f"candidate area {area} exceeds strict ceiling {strict_ceiling}")

    sta1 = verify_sta_run("run1", synth1["netlist_sha256"])
    sta2 = verify_sta_run("run2", synth2["netlist_sha256"])
    sta_equal_keys = [
        "combinational_loops", "diagnostic_vectorless_power_w", "netlist_sha256",
        "path_count", "power_qualified", "reserve_met", "setup_warning_counts",
        "target_200mhz_met", "tns_ns", "violated_path_count", "wns_ns",
        "worst_path_slack_ns",
    ]
    for key in sta_equal_keys:
        if sta1.get(key) != sta2.get(key):
            fail(f"STA repetitions differ for {key}")

    performance_dir = EVIDENCE / "performance-abbaab"
    performance_manifest_count = verify_sha256_manifest(performance_dir / "SHA256SUMS")
    performance = load_json(performance_dir / "summary.json")
    if performance.get("result") != "PASS" or performance.get("sequence") != ["A", "B", "B", "A", "A", "B"]:
        fail("ABBAAB performance result/sequence mismatch")
    workloads = performance.get("workloads")
    expected_counters = {
        "coremark": (4904511, 3183617),
        "dhrystone_10000": (9481620, 4250000),
    }
    for name, (cycles, retired) in expected_counters.items():
        measurement = workloads[name]["measurement"]
        if measurement.get("candidate_cycle_exact_with_s0") is not True:
            fail(f"{name} is not cycle-exact with S0")
        require_close(float(measurement.get("candidate_throughput_ratio")), 1.0, f"{name} ratio")
        candidate = measurement["candidate"]
        if candidate.get("cycles") != cycles or candidate.get("retired_instructions") != retired:
            fail(f"{name} candidate counters mismatch")
        windows = workloads[name].get("windows", [])
        if [window.get("design") for window in windows] != ["A", "B", "B", "A", "A", "B"]:
            fail(f"{name} window order mismatch")

    architecture_path = EVIDENCE / "architecture-no-directed-evidence.json"
    architecture = load_json(architecture_path)
    if architecture.get("exit_code") != 1 or architecture.get("overall_status") != "RED":
        fail("architecture snapshot is not fail-closed RED")
    gates = architecture.get("gates", {})
    if list(gates) != GATE_NAMES or any(gates[name].get("status") != "RED" for name in GATE_NAMES):
        fail("architecture nine-gate status mismatch")
    # Architecture evaluator hashes its canonical 136-file design set; the
    # synthesis freeze separately covers all 140 files under vsrc/.
    if architecture.get("rtl_source_set", {}).get("file_count") != 136:
        fail("architecture RTL source count mismatch")

    result = {
        "schema": "npc-rv64-r4-p0a-checkpoint-audit-v2",
        "result": "PASS",
        "candidate_id": "r4-p0a-distributed-wb-valid",
        "candidate_role": "timing_recovery_correctness_checkpoint_not_architecture_seed",
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "functional": {
            "focused_matrix_passed": 22,
            "focused_matrix_required": 22,
            "matrix_manifest_entries": matrix_manifest_count,
            "module_passed": 102,
            "module_required": 102,
        },
        "performance": {
            "sequence": ["A", "B", "B", "A", "A", "B"],
            "repetitions_per_design": 3,
            "cycle_exact_with_s0": True,
            "manifest_entries": performance_manifest_count,
            "coremark": {"cycles": 4904511, "retired_instructions": 3183617, "throughput_ratio": 1.0},
            "dhrystone_10000": {"cycles": 9481620, "retired_instructions": 4250000, "throughput_ratio": 1.0},
        },
        "area": {
            "logic_area": area,
            "sequential_area": synth1["sequential_area"],
            "delta_vs_s0": area - s0_area,
            "delta_vs_r3p6": area - r3_area,
            "strict_ceiling": strict_ceiling,
            "headroom_to_strict_ceiling": strict_ceiling - area,
            "independent_repetitions": 2,
            "netlist_byte_identical": True,
            "netlist_sha256": synth1["netlist_sha256"],
            "live_rtl_manifest_entries": synth_manifest_count1,
        },
        "timing": {
            "period_ns": 5.0,
            "worst_path_slack_ns": sta1["worst_path_slack_ns"],
            "delta_vs_s0_ns": sta1["worst_path_slack_ns"] - float(s0["timing"]["worst_path_slack_ns"]),
            "reserve_threshold_ns": 0.1,
            "reserve_met": True,
            "tns_ns": 0.0,
            "violated_path_count": 0,
            "combinational_loops": 0,
            "independent_repetitions": 2,
        },
        "architecture": {
            "overall_status": "RED",
            "blocking_gates": GATE_NAMES,
            "design_id": architecture["rtl_source_set"]["design_id"],
            "not_architecture_feasible": True,
        },
        "power": {
            "qualified": False,
            "diagnostic_vectorless_logic_proxy_w": sta1["diagnostic_vectorless_power_w"],
            "not_eligible_for_power_claim": True,
        },
        "artifacts": [
            record(matrix_dir / "summary.md"),
            record(matrix_dir / "SHA256SUMS"),
            record(module_summary),
            record(EVIDENCE / "fresh-synth-run1/evidence/synthesis/summary.json"),
            record(EVIDENCE / "fresh-synth-run2/evidence/synthesis/summary.json"),
            *rtl_manifests1,
            *rtl_manifests2,
            record(EVIDENCE / "fresh-synth-run1/opensta-exact5ns-v2/summary.json"),
            record(EVIDENCE / "fresh-synth-run2/opensta-exact5ns-v2/summary.json"),
            record(performance_dir / "summary.json"),
            record(performance_dir / "SHA256SUMS"),
            record(architecture_path),
        ],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"[R4-P0A-CHECKPOINT] PASS output={output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"[R4-P0A-CHECKPOINT] ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
