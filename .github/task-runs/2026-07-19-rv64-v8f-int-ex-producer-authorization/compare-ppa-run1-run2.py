#!/usr/bin/env python3
"""Compare frozen pre/post v8f.1 synthesis and partial-constraint STA cohorts."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import NoReturn


RUN_DIR = Path(__file__).resolve().parent
ROOT = RUN_DIR.parents[2]
TMP_BASE = ROOT / "tmp/2026-07-19-rv64-v8f-int-ex-producer-authorization/evidence/ppa-current"
TASK_BASE = RUN_DIR / "evidence/ppa-current"


def fail(message: str) -> NoReturn:
    raise SystemExit(f"[V8F-PPA-AB][FAIL] {message}")


def load(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        fail(f"JSON object required: {path}")
    return data


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        digest, name = line.split(maxsplit=1)
        result[name] = digest
    return result


def kv(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            key, value = line.split("=", 1)
            result[key] = value
    return result


def main() -> int:
    synth_paths = {
        run: TASK_BASE / f"fresh-synth-{run}/evidence/synthesis/summary.json"
        for run in ("run1", "run2")
    }
    sta_paths = {
        run: TASK_BASE / f"fresh-synth-{run}/opensta-exact5ns/summary.json"
        for run in ("run1", "run2")
    }
    cone_summary_paths = {
        run: TASK_BASE / f"fresh-synth-{run}/opensta-credit-cone-v4/summary.kv"
        for run in ("run1", "run2")
    }
    cone_reachability_paths = {
        run: TASK_BASE / f"fresh-synth-{run}/opensta-credit-cone-v4/reachability.kv"
        for run in ("run1", "run2")
    }
    synth = {run: load(path) for run, path in synth_paths.items()}
    sta = {run: load(path) for run, path in sta_paths.items()}
    cone_summary = {run: kv(path) for run, path in cone_summary_paths.items()}
    cone_reachability = {
        run: kv(path) for run, path in cone_reachability_paths.items()
    }

    for field in (
        "schema",
        "abc_done",
        "module_count",
        "previous_netlist_sha256",
        "provenance_head",
        "tool_versions",
        "top",
        "vsrc_count",
    ):
        if synth["run1"][field] != synth["run2"][field]:
            fail(f"synthesis cohort field drifted: {field}")
    for field in ("schema", "claim_tier", "period_ns", "path_count"):
        if sta["run1"][field] != sta["run2"][field]:
            fail(f"STA cohort field drifted: {field}")
    if synth["run1"]["netlist_sha256"] == synth["run2"]["netlist_sha256"]:
        fail("pre/post netlists unexpectedly have the same hash")

    for field in (
        "semantic_start_pin",
        "structural_start_pin",
        "structural_method",
        "ready_targets",
        "authority_path_expected",
        "claim_tier",
        "promotion_eligible",
    ):
        if cone_summary["run1"][field] != cone_summary["run2"][field]:
            fail(f"credit-cone cohort field drifted: {field}")
    if cone_summary["run1"]["ready_path_expected"] != "1":
        fail("run1 credit-cone expectation must be reachable")
    if cone_summary["run2"]["ready_path_expected"] != "0":
        fail("run2 credit-cone expectation must be cut")
    ready_labels = ("mem_ready", "issue1_ready", "muldiv_ready", "clmul_ready", "fp_ready")
    for label in ready_labels:
        key = f"{label}_structural_start_hits"
        if cone_reachability["run1"][key] != "1":
            fail(f"run1 must retain ROB-generation reachability to {label}")
        if cone_reachability["run2"][key] != "0":
            fail(f"run2 must cut ROB-generation reachability to {label}")
    authority_key = "rob_wb0_authority_structural_start_hits"
    for run in ("run1", "run2"):
        if cone_reachability[run][authority_key] != "1":
            fail(f"{run} must retain ROB-generation reachability to exact WB authority")

    run_tmp = {
        run: TMP_BASE / f"fresh-synth-{run}" for run in ("run1", "run2")
    }
    rtl = {
        run: manifest(path / "synth-rtl-inputs.pre.sha256")
        for run, path in run_tmp.items()
    }
    if set(rtl["run1"]) != set(rtl["run2"]):
        fail("RTL manifest path set drifted")
    changed_rtl = sorted(
        path for path in rtl["run1"] if rtl["run1"][path] != rtl["run2"][path]
    )
    expected_changed = [str(ROOT / "npc/rv64/vsrc/execute/OooIntBackend.v")]
    if changed_rtl != expected_changed:
        fail(f"unexpected RTL A/B delta: {changed_rtl}")

    for filename in (
        "synth-liberty-inputs.pre.sha256",
        "synth-tool-versions.pre.kv",
        "synth-tool-binaries.pre.sha256",
    ):
        if (run_tmp["run1"] / filename).read_bytes() != (
            run_tmp["run2"] / filename
        ).read_bytes():
            fail(f"frozen cohort input drifted: {filename}")
    params = {
        run: kv(path / "synth-parameters.pre.kv")
        for run, path in run_tmp.items()
    }
    for values in params.values():
        values.pop("synth_result_root", None)
    if params["run1"] != params["run2"]:
        fail("synthesis parameters drifted beyond isolated result root")

    area1 = float(synth["run1"]["area"])
    area2 = float(synth["run2"]["area"])
    seq1 = float(synth["run1"]["sequential_area"])
    seq2 = float(synth["run2"]["sequential_area"])
    wns1 = float(sta["run1"]["wns_ns"])
    wns2 = float(sta["run2"]["wns_ns"])
    tns1 = float(sta["run1"]["tns_ns"])
    tns2 = float(sta["run2"]["tns_ns"])
    result = {
        "schema": "rv64-v8f-preauth-credit-diagnostic-ab-v2",
        "same_cohort": True,
        "isolated_rtl_delta": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "task_class": "architecture_closure_with_diagnostic_ppa_probe",
        "claim_tier": "diagnostic_rtl_proxy_partial_constraints",
        "area_claim": "logic_area_proxy_excluding_unknown_macros",
        "power_claim": "unqualified",
        "promotion_eligible": False,
        "target_200mhz_met": False,
        "verdict": "DIAGNOSTIC_PROXY_IMPROVED_TARGET_RED",
        "run1": {
            "role": "pre_fix_exact_open_credit",
            "area": area1,
            "sequential_area": seq1,
            "wns_ns": wns1,
            "tns_ns": tns1,
            "violated_path_count": sta["run1"]["violated_path_count"],
            "netlist_sha256": synth["run1"]["netlist_sha256"],
        },
        "run2": {
            "role": "post_fix_pre_auth_credit",
            "area": area2,
            "sequential_area": seq2,
            "wns_ns": wns2,
            "tns_ns": tns2,
            "violated_path_count": sta["run2"]["violated_path_count"],
            "netlist_sha256": synth["run2"]["netlist_sha256"],
        },
        "delta_run2_minus_run1": {
            "area": area2 - area1,
            "area_percent": 100.0 * (area2 - area1) / area1,
            "sequential_area": seq2 - seq1,
            "wns_ns": wns2 - wns1,
            "tns_ns": tns2 - tns1,
            "violated_path_count": int(sta["run2"]["violated_path_count"])
            - int(sta["run1"]["violated_path_count"]),
        },
        "credit_cone": {
            "semantic_start_pin": cone_summary["run1"]["semantic_start_pin"],
            "structural_start_pin": cone_summary["run1"]["structural_start_pin"],
            "structural_method": cone_summary["run1"]["structural_method"],
            "ready_targets": list(ready_labels),
            "run1_ready_hits_each": 1,
            "run2_ready_hits_each": 0,
            "run1_authority_hits": 1,
            "run2_authority_hits": 1,
            "interpretation": "ROB generation leaves shared ready/credit cones but remains on exact WB authorization",
        },
        "evidence_sha256": {
            **{f"synth_{run}": sha256(path) for run, path in synth_paths.items()},
            **{f"sta_{run}": sha256(path) for run, path in sta_paths.items()},
            **{
                f"cone_summary_{run}": sha256(path)
                for run, path in cone_summary_paths.items()
            },
            **{
                f"cone_reachability_{run}": sha256(path)
                for run, path in cone_reachability_paths.items()
            },
        },
    }
    if not (area2 < area1 and seq2 == seq1 and wns2 > wns1 and tns2 > tns1):
        fail("expected proxy improvement or zero-state property did not hold")
    if bool(sta["run2"]["target_200mhz_met"]):
        fail("comparison contract expects the observed 5ns target to remain RED")

    output = TASK_BASE / "run1-run2-comparison.json"
    output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    print(f"[V8F-PPA-AB] PASS verdict={result['verdict']} output={output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
