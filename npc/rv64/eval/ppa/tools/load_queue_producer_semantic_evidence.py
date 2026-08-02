#!/usr/bin/env python3
"""Build source-bound V11H LoadQueue producer-holder evidence.

The V11H proof closes only ``load-queue-producers``.  It binds the pre-fix
prior-terminal/recovery failure, the minimal ``terminal_seen_q`` architecture
repair, four positive GEN_W/assertion profiles, and compile-success
assertion-off RTL variants rejected by one stimulus-owned raw-Q oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11h-load-queue-producer-semantic-evidence-v2"
MUTANT_SCHEMA = "rv64-v11h-load-queue-producer-mutant-v1"
TEST = "tb_ooo_load_queue_producer_semantic"
RTL_PATH = "npc/rv64/vsrc/memory/OooLoadQueue.v"
TB_PATH = (
    "npc/rv64/testbench/tests/"
    "tb_ooo_load_queue_producer_semantic.sv"
)
ORDINARY_TB_PATH = "npc/rv64/testbench/tests/tb_ooo_load_queue.sv"
EXPECTED_PRE_FIX_RTL_SHA256 = (
    "82b22c8bf873b26863676823dd677fa8389ca96465e5611ac19e991d92a9752e"
)
EXPECTED_RTL_SHA256 = (
    "5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f"
)
EXPECTED_TB_SHA256 = (
    "fba6eade2179bd1c9fe350b437a951efd0522bf6980f814761c0bf7d7e87a780"
)
UNIT_IDS = frozenset({"load-queue-producers"})
POSITIVE_PROFILES = {
    "assert-g1": (1, True),
    "release-g1": (1, False),
    "assert-g4": (4, True),
    "release-g4": (4, False),
}
POSITIVE_MARKERS = (
    "[V11H-LQ-BIRTH-CAM] GEN_W={generation_width} "
    "dual/full-P/query/response PASS",
    "[V11H-LQ-TERMINAL-RECOVERY] GEN_W={generation_width} "
    "prior-terminal-clear/killed-drain PASS",
    "[V11H-LQ-RETIRE-REUSE] GEN_W={generation_width} "
    "completion/release/no-borrow/reuse PASS",
    "[V11H-LQ-RECOVERY-PRIORITY] GEN_W={generation_width} "
    "wrap/launch/completion/terminal PASS",
    "[V11H-LQ-ALL] GEN_W={generation_width} "
    "stimulus-owned raw-Q model PASS",
    "[PASS] tb_ooo_load_queue_producer_semantic",
)
MUTATION_CASES = (
    "alloc0-generation-zero",
    "alloc1-uses-alloc0-pid",
    "alloc0-pid-x",
    "alloc1-pid-x",
    "slot-reuse-keeps-old-pid",
    "issue-full-pid-index-only",
    "launch-full-pid-index-only",
    "query-full-pid-index-only",
    "response-full-pid-index-only",
    "completion-full-pid-index-only",
    "terminal-full-pid-index-only",
    "release-full-pid-index-only",
    "terminal-not-recorded",
    "terminal-seen-x",
    "recovery-ignores-prior-terminal",
    "normal-terminal-clears-valid",
    "killed-terminal-keeps-valid",
    "release-keeps-valid",
    "launched-recovery-drops-entry",
    "recovery-keeps-cleared-entry",
    "selective-includes-boundary",
    "same-edge-launch-ignored",
    "same-edge-completion-ignored",
    "same-edge-terminal-ignored",
    "dual-alloc-same-slot",
    "dual-query-same-pid-bypass",
    "issue-terminal-gate-removed",
    "query-terminal-gate-removed",
    "response-terminal-gate-removed",
    "release-before-completion",
    "alloc-borrows-same-edge-release",
)
MUTATION_WIDTHS = (1, 4)
MUTATION_MARKER = "[V11H-LQ-PRODUCER-ORACLE][FAIL]"
ASSERTION_PROBE_MARKER = "[V11H-LQ-PID-KNOWN]"
SYSTEM_RERUN_SCOPE = {
    "required_for_local_closure": False,
    "required_before_system_promotion": True,
    "run": False,
}


class EvidenceError(RuntimeError):
    """Raised when a V11H artifact is missing or semantically incomplete."""


def repository_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[5]


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise EvidenceError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise EvidenceError(f"JSON root is not an object: {path}")
    return payload


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def artifact(
    root: pathlib.Path,
    path: pathlib.Path,
) -> dict[str, Any]:
    try:
        relative = path.resolve().relative_to(root).as_posix()
    except ValueError as exc:
        raise EvidenceError(f"artifact escapes repository root: {path}") from exc
    if not path.is_file():
        raise EvidenceError(f"artifact is missing: {relative}")
    if path.stat().st_size == 0:
        raise EvidenceError(f"artifact is empty: {relative}")
    return {
        "path": relative,
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def read_rc(path: pathlib.Path, label: str) -> int:
    try:
        return int(path.read_text(encoding="utf-8").strip())
    except (OSError, ValueError) as exc:
        raise EvidenceError(f"{label} return code is unreadable") from exc


def require_once(text: str, marker: str, label: str) -> None:
    count = text.count(marker)
    if count != 1:
        raise EvidenceError(
            f"{label} marker count mismatch: {marker!r} count={count}"
        )


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise EvidenceError(
            f"mutation {label} anchor count={count} expected=1"
        )
    return text.replace(old, new, 1)


def replace_cam_pair(text: str, family: str, signal: str) -> str:
    mutated = text
    for lane in (0, 1):
        old = f"(producer_id_q[g] == {signal}{lane}_producer_id_i)"
        new = (
            "(producer_id_q[g][ROB_INDEX_W-1:0] == "
            f"{signal}{lane}_producer_id_i[ROB_INDEX_W-1:0])"
        )
        mutated = replace_once(
            mutated, old, new, f"{family}/lane{lane}"
        )
    return mutated


def mutate_source(text: str, case: str) -> str:
    if case == "alloc0-generation-zero":
        return replace_once(
            text,
            "        producer_id_q[alloc0_idx_r] <= alloc0_producer_id_i;\n",
            "        producer_id_q[alloc0_idx_r] <= "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "alloc0_producer_id_i[ROB_INDEX_W-1:0]};\n",
            case,
        )
    if case == "alloc1-uses-alloc0-pid":
        return replace_once(
            text,
            "        producer_id_q[alloc1_idx_r] <= alloc1_producer_id_i;\n",
            "        producer_id_q[alloc1_idx_r] <= alloc0_producer_id_i;\n",
            case,
        )
    if case == "alloc0-pid-x":
        return replace_once(
            text,
            "        producer_id_q[alloc0_idx_r] <= alloc0_producer_id_i;\n",
            "        producer_id_q[alloc0_idx_r] <= "
            "{PRODUCER_ID_W{1'bx}};\n",
            case,
        )
    if case == "alloc1-pid-x":
        return replace_once(
            text,
            "        producer_id_q[alloc1_idx_r] <= alloc1_producer_id_i;\n",
            "        producer_id_q[alloc1_idx_r] <= "
            "{PRODUCER_ID_W{1'bx}};\n",
            case,
        )
    if case == "slot-reuse-keeps-old-pid":
        return replace_once(
            text,
            "        producer_id_q[alloc0_idx_r] <= alloc0_producer_id_i;\n",
            "        producer_id_q[alloc0_idx_r] <= "
            "producer_id_q[alloc0_idx_r];\n",
            case,
        )
    if case == "issue-full-pid-index-only":
        return replace_cam_pair(text, case, "issue")
    if case == "launch-full-pid-index-only":
        return replace_cam_pair(text, case, "launch")
    if case == "query-full-pid-index-only":
        return replace_cam_pair(text, case, "query")
    if case == "response-full-pid-index-only":
        return replace_cam_pair(text, case, "response")
    if case == "completion-full-pid-index-only":
        return replace_cam_pair(text, case, "completion")
    if case == "terminal-full-pid-index-only":
        return replace_cam_pair(text, case, "terminal")
    if case == "release-full-pid-index-only":
        return replace_cam_pair(text, case, "release")
    terminal_record = (
        "          if (terminal0_hit_w[i] || terminal1_hit_w[i])\n"
        "            terminal_seen_q[i] <= 1'b1;\n"
    )
    if case == "terminal-not-recorded":
        return replace_once(
            text,
            terminal_record,
            "          if (terminal0_hit_w[i] || terminal1_hit_w[i])\n"
            "            terminal_seen_q[i] <= terminal_seen_q[i];\n",
            case,
        )
    if case == "terminal-seen-x":
        return replace_once(
            text,
            terminal_record,
            "          if (terminal0_hit_w[i] || terminal1_hit_w[i])\n"
            "            terminal_seen_q[i] <= 1'bx;\n",
            case,
        )
    if case == "recovery-ignores-prior-terminal":
        return replace_once(
            text,
            "               !completion1_hit_w[i] && "
            "!terminal_seen_q[i]) &&\n",
            "               !completion1_hit_w[i]) &&\n",
            case,
        )
    if case == "normal-terminal-clears-valid":
        return replace_once(
            text,
            terminal_record,
            "          if (terminal0_hit_w[i] || terminal1_hit_w[i]) begin\n"
            "            terminal_seen_q[i] <= 1'b1;\n"
            "            valid_q[i] <= 1'b0;\n"
            "          end\n",
            case,
        )
    if case == "killed-terminal-keeps-valid":
        return replace_once(
            text,
            "            ((terminal0_hit_w[i] || terminal1_hit_w[i]) "
            "&& killed_q[i])) begin\n",
            "            ((terminal0_hit_w[i] || terminal1_hit_w[i]) "
            "&& 1'b0)) begin\n",
            case,
        )
    if case == "release-keeps-valid":
        return replace_once(
            text,
            "        if ((release0_fire_o && release0_match_w[i]) ||\n"
            "            (release1_fire_o && release1_match_w[i]) ||\n"
            "            ((terminal0_hit_w[i] || terminal1_hit_w[i]) "
            "&& killed_q[i])) begin\n",
            "        if ((1'b0 && release0_fire_o && release0_match_w[i]) ||\n"
            "            (1'b0 && release1_fire_o && release1_match_w[i]) ||\n"
            "            ((terminal0_hit_w[i] || terminal1_hit_w[i]) "
            "&& killed_q[i])) begin\n",
            case,
        )
    if case == "launched-recovery-drops-entry":
        return replace_once(
            text,
            "            launched_q[i] <= 1'b1;\n"
            "            completed_q[i] <= 1'b0;\n"
            "            killed_q[i] <= 1'b1;\n"
            "            terminal_seen_q[i] <= 1'b0;\n",
            "            valid_q[i] <= 1'b0;\n"
            "            launched_q[i] <= 1'b0;\n"
            "            completed_q[i] <= 1'b0;\n"
            "            killed_q[i] <= 1'b0;\n"
            "            terminal_seen_q[i] <= 1'b0;\n",
            case,
        )
    if case == "recovery-keeps-cleared-entry":
        return replace_once(
            text,
            "          end else begin\n"
            "            valid_q[i] <= 1'b0;\n"
            "            launched_q[i] <= 1'b0;\n",
            "          end else begin\n"
            "            valid_q[i] <= valid_q[i];\n"
            "            launched_q[i] <= 1'b0;\n",
            case,
        )
    if case == "selective-includes-boundary":
        return replace_once(
            text,
            "           (rob_dist(rob_idx_q[g], flush_rob_head_i) >\n"
            "            rob_dist(flush_boundary_rob_i, "
            "flush_rob_head_i)));\n",
            "           (rob_dist(rob_idx_q[g], flush_rob_head_i) >=\n"
            "            rob_dist(flush_boundary_rob_i, "
            "flush_rob_head_i)));\n",
            case,
        )
    if case == "same-edge-launch-ignored":
        return replace_once(
            text,
            "          if (((launched_q[i] || launch0_hit_w[i] || "
            "launch1_hit_w[i]) &&\n",
            "          if ((launched_q[i] &&\n",
            case,
        )
    if case == "same-edge-completion-ignored":
        return replace_once(
            text,
            "               !completed_q[i] && !completion0_hit_w[i] &&\n"
            "               !completion1_hit_w[i] && "
            "!terminal_seen_q[i]) &&\n",
            "               !completed_q[i] && "
            "!terminal_seen_q[i]) &&\n",
            case,
        )
    if case == "same-edge-terminal-ignored":
        return replace_once(
            text,
            "              !(terminal0_hit_w[i] || terminal1_hit_w[i])) "
            "begin\n",
            "              1'b1) begin\n",
            case,
        )
    if case == "dual-alloc-same-slot":
        return replace_once(
            text,
            "  assign alloc1_free_w = alloc_free_w & ~alloc0_onehot_w;\n",
            "  assign alloc1_free_w = alloc_free_w;\n",
            case,
        )
    if case == "dual-query-same-pid-bypass":
        return replace_once(
            text,
            "  wire query_pair_same_pid_w = query0_valid_i && "
            "query1_valid_i &&\n"
            "      (query0_producer_id_i == query1_producer_id_i);\n",
            "  wire query_pair_same_pid_w = 1'b0;\n",
            case,
        )
    if case == "issue-terminal-gate-removed":
        mutated = text
        for lane in (0, 1):
            mutated = replace_once(
                mutated,
                f"      assign issue{lane}_open_hit_w[g] = "
                f"issue{lane}_hit_w[g] &&\n"
                "          !killed_q[g] && !terminal_seen_q[g] && "
                "!completed_q[g];\n",
                f"      assign issue{lane}_open_hit_w[g] = "
                f"issue{lane}_hit_w[g] &&\n"
                "          !killed_q[g] && !completed_q[g];\n",
                f"{case}/lane{lane}",
            )
        return mutated
    if case == "query-terminal-gate-removed":
        mutated = text
        for lane in (0, 1):
            mutated = replace_once(
                mutated,
                f"      assign query{lane}_open_hit_w[g] = "
                f"query{lane}_hit_w[g] && launched_q[g] &&\n"
                "          !killed_q[g] && !terminal_seen_q[g] && "
                "!completed_q[g] &&\n",
                f"      assign query{lane}_open_hit_w[g] = "
                f"query{lane}_hit_w[g] && launched_q[g] &&\n"
                "          !killed_q[g] && !completed_q[g] &&\n",
                f"{case}/lane{lane}",
            )
        return mutated
    if case == "response-terminal-gate-removed":
        mutated = text
        for lane in (0, 1):
            mutated = replace_once(
                mutated,
                f"      assign response{lane}_open_hit_w[g] = "
                f"response{lane}_hit_w[g] &&\n"
                "          launched_q[g] && !killed_q[g] && "
                "!terminal_seen_q[g] &&\n",
                f"      assign response{lane}_open_hit_w[g] = "
                f"response{lane}_hit_w[g] &&\n"
                "          launched_q[g] && !killed_q[g] &&\n",
                f"{case}/lane{lane}",
            )
        return mutated
    if case == "release-before-completion":
        mutated = text
        for lane in (0, 1):
            old = (
                f"      assign release{lane}_ready_hit_w[g] = "
                f"release{lane}_match_w[g] &&\n"
                "          (completed_q[g] || completion0_hit_w[g] || "
                "completion1_hit_w[g]);\n"
            )
            new = (
                f"      assign release{lane}_ready_hit_w[g] = "
                f"release{lane}_match_w[g];\n"
            )
            mutated = replace_once(
                mutated, old, new, f"{case}/lane{lane}"
            )
        return mutated
    if case == "alloc-borrows-same-edge-release":
        return replace_once(
            text,
            "  assign alloc0_ready_o = |alloc0_onehot_w;\n",
            "  assign alloc0_ready_o = |alloc0_onehot_w || "
            "release0_fire_o;\n",
            case,
        )
    raise EvidenceError(f"unsupported mutation case: {case}")


def build_positive_record(
    root: pathlib.Path,
    evidence_dir: pathlib.Path,
    profile: str,
    generation_width: int,
    assertions_enabled: bool,
) -> dict[str, Any]:
    run_dir = evidence_dir / "profiles" / profile
    compile_rc = read_rc(run_dir / "compile.rc", f"profile {profile} compile")
    sim_rc = read_rc(run_dir / "sim.rc", f"profile {profile} simulation")
    if compile_rc != 0 or sim_rc != 0:
        raise EvidenceError(
            f"positive profile {profile} failed: "
            f"compile={compile_rc} sim={sim_rc}"
        )
    sim_log = (run_dir / "sim.log").read_text(
        encoding="utf-8", errors="replace"
    )
    for template in POSITIVE_MARKERS:
        require_once(
            sim_log,
            template.format(generation_width=generation_width),
            f"profile {profile}",
        )
    image = run_dir / "build" / f"{TEST}.vvp"
    return {
        "generation_width": generation_width,
        "assertions_enabled": assertions_enabled,
        "compile_rc": compile_rc,
        "simulation_rc": sim_rc,
        "compile_log": artifact(root, run_dir / "compile.log"),
        "simulation_log": artifact(root, run_dir / "sim.log"),
        "compiled_image": artifact(root, image),
    }


def build_assertion_probe_record(
    root: pathlib.Path,
    evidence_dir: pathlib.Path,
) -> dict[str, Any]:
    run_dir = evidence_dir / "assertion-probes" / "producer-id-known-g4"
    compile_rc = read_rc(run_dir / "compile.rc", "PID known probe compile")
    sim_rc = read_rc(run_dir / "sim.rc", "PID known probe simulation")
    if compile_rc != 0 or sim_rc == 0:
        raise EvidenceError(
            "raw-Q PID knownness assertion probe did not reject the "
            f"unknown generation: compile={compile_rc} sim={sim_rc}"
        )
    sim_log = (run_dir / "sim.log").read_text(
        encoding="utf-8", errors="replace"
    )
    require_once(
        sim_log,
        ASSERTION_PROBE_MARKER,
        "raw-Q PID knownness assertion probe",
    )
    if "[V11H-LQ-PID-KNOWN-PROBE][FAIL]" in sim_log:
        raise EvidenceError("raw-Q PID knownness assertion probe fell through")
    return {
        "generation_width": 4,
        "assertions_enabled": True,
        "unknown_generation_injected": True,
        "compile_rc": compile_rc,
        "simulation_rc": sim_rc,
        "expected_marker": ASSERTION_PROBE_MARKER,
        "compile_log": artifact(root, run_dir / "compile.log"),
        "simulation_log": artifact(root, run_dir / "sim.log"),
        "compiled_image": artifact(
            root, run_dir / "build" / f"{TEST}.vvp"
        ),
    }


def build_mutation_record(
    root: pathlib.Path,
    evidence_dir: pathlib.Path,
    case: str,
) -> dict[str, Any]:
    case_dir = evidence_dir / "mutations" / case
    receipt = load_json(case_dir / "mutator.json")
    if (
        receipt.get("schema") != MUTANT_SCHEMA
        or receipt.get("case") != case
        or receipt.get("source_sha256") != EXPECTED_RTL_SHA256
        or receipt.get("mutant_sha256")
        != sha256(case_dir / "OooLoadQueue.v")
    ):
        raise EvidenceError(f"mutation receipt mismatch: {case}")
    runs: dict[str, Any] = {}
    for generation_width in MUTATION_WIDTHS:
        profile = f"g{generation_width}"
        run_dir = case_dir / profile
        compile_rc = read_rc(
            run_dir / "compile.rc", f"mutation {case}/{profile} compile"
        )
        sim_rc = read_rc(
            run_dir / "sim.rc", f"mutation {case}/{profile} simulation"
        )
        if compile_rc != 0:
            raise EvidenceError(
                f"mutation did not compile: {case}/{profile}"
            )
        if sim_rc == 0:
            raise EvidenceError(
                f"mutation unexpectedly passed: {case}/{profile}"
            )
        sim_log = (run_dir / "sim.log").read_text(
            encoding="utf-8", errors="replace"
        )
        if MUTATION_MARKER not in sim_log:
            raise EvidenceError(
                f"mutation lacks raw-Q oracle marker: {case}/{profile}"
            )
        runs[profile] = {
            "generation_width": generation_width,
            "assertions_enabled": False,
            "negative_stimulus_enabled": True,
            "compile_rc": compile_rc,
            "simulation_rc": sim_rc,
            "compile_log": artifact(root, run_dir / "compile.log"),
            "simulation_log": artifact(root, run_dir / "sim.log"),
            "compiled_image": artifact(
                root, run_dir / "build" / f"{TEST}.vvp"
            ),
        }
    return {
        "case": case,
        "mutant_source": artifact(root, case_dir / "OooLoadQueue.v"),
        "receipt": artifact(root, case_dir / "mutator.json"),
        "runs": runs,
    }


def build_summary(args: argparse.Namespace) -> dict[str, Any]:
    root = pathlib.Path(args.root).resolve()
    evidence_dir = pathlib.Path(args.evidence_dir).resolve()
    pre_fix_dir = pathlib.Path(args.pre_fix_dir).resolve()
    rtl = root / RTL_PATH
    tb = root / TB_PATH
    ordinary_tb = root / ORDINARY_TB_PATH
    if sha256(rtl) != EXPECTED_RTL_SHA256:
        raise EvidenceError("current OooLoadQueue source is not reviewed V11H RTL")
    if sha256(tb) != EXPECTED_TB_SHA256:
        raise EvidenceError("V11H semantic testbench source drifted")

    pre_fix_compile_rc = read_rc(
        pre_fix_dir / "compile.rc", "pre-fix compile"
    )
    pre_fix_sim_rc = read_rc(
        pre_fix_dir / "sim.rc", "pre-fix simulation"
    )
    pre_fix_log = (pre_fix_dir / "sim.log").read_text(
        encoding="utf-8", errors="replace"
    )
    if pre_fix_compile_rc != 0 or pre_fix_sim_rc == 0:
        raise EvidenceError("pre-fix reproducer result shape is invalid")
    require_once(
        pre_fix_log,
        "[V11H-LQ-PRIOR-TERMINAL-RECOVERY][FAIL]",
        "pre-fix reproducer",
    )
    pre_fix_sources = (pre_fix_dir / "sources.sha256").read_text(
        encoding="utf-8"
    )
    if EXPECTED_PRE_FIX_RTL_SHA256 not in pre_fix_sources:
        raise EvidenceError("pre-fix source manifest lacks reviewed RTL hash")

    positives = {
        profile: build_positive_record(
            root,
            evidence_dir,
            profile,
            generation_width,
            assertions_enabled,
        )
        for profile, (generation_width, assertions_enabled)
        in POSITIVE_PROFILES.items()
    }
    assertion_probe = build_assertion_probe_record(root, evidence_dir)
    mutations = [
        build_mutation_record(root, evidence_dir, case)
        for case in MUTATION_CASES
    ]

    pre_binding = load_json(evidence_dir / "rtl-source-binding.pre.json")
    post_binding = load_json(evidence_dir / "rtl-source-binding.post.json")
    if pre_binding != post_binding:
        raise EvidenceError("full RTL source binding changed during V11H run")
    design_id = pre_binding.get("design_id")
    if not isinstance(design_id, str) or not design_id.startswith("sha256:"):
        raise EvidenceError("full RTL binding lacks design_id")

    return {
        "schema": SCHEMA,
        "status": "PASS",
        "classification": "architecture",
        "design_id": design_id,
        "unit_ids": sorted(UNIT_IDS),
        "production": {
            "rtl": artifact(root, rtl),
            "semantic_testbench": artifact(root, tb),
            "ordinary_regression_testbench": artifact(root, ordinary_tb),
            "pre_fix_rtl_sha256": EXPECTED_PRE_FIX_RTL_SHA256,
            "post_fix_rtl_sha256": EXPECTED_RTL_SHA256,
            "raw_q_producer_id_knownness_assertion": True,
            "raw_q_producer_id_knownness_marker": ASSERTION_PROBE_MARKER,
            "mechanism": "terminal_seen_q records normal owner terminal until completion/release or recovery clear",
        },
        "pre_fix_reproducer": {
            "assertions_enabled": False,
            "generation_width": 4,
            "compile_rc": pre_fix_compile_rc,
            "simulation_rc": pre_fix_sim_rc,
            "source_manifest": artifact(
                root, pre_fix_dir / "sources.sha256"
            ),
            "compile_log": artifact(root, pre_fix_dir / "compile.log"),
            "simulation_log": artifact(root, pre_fix_dir / "sim.log"),
            "observed_first_bad_state": {
                "count": 1,
                "producer_live": 1,
                "killed": 1,
            },
        },
        "root_cause": {
            "confirmed": True,
            "sequence": [
                "normal exact terminal while completion is pending",
                "later selective or global recovery targets the entry",
                "old RTL inferred owner pending only from launched and incomplete",
                "entry became a killed tombstone after its terminal was already consumed",
            ],
            "competing_hypothesis_rejected": (
                "V8V evidence gap only; production RTL is correct"
            ),
        },
        "independent_oracle": {
            "stimulus_owned_four_entry_model": True,
            "checks_every_directed_edge": True,
            "checks_all_entries": True,
            "checks_all_generation_bits": True,
            "checks_raw_producer_id_knownness": True,
            "checks_raw_terminal_history": True,
            "checks_raw_lifecycle_bits": [
                "valid_q",
                "launched_q",
                "pa_valid_q",
                "ordered_q",
                "completed_q",
                "killed_q",
                "terminal_seen_q",
            ],
            "dut_outputs_are_observations_only": True,
            "mutation_assertions_enabled": False,
            "marker": MUTATION_MARKER,
        },
        "positive_profiles": positives,
        "rtl_assertion_probe": assertion_probe,
        "mutations": mutations,
        "counts": {
            "positive_profiles": len(positives),
            "raw_q_knownness_assertion_probes": 1,
            "compile_success_mutation_cases": len(mutations),
            "mutation_simulations": len(mutations) * len(MUTATION_WIDTHS),
            "rejected_mutation_simulations": len(mutations)
            * len(MUTATION_WIDTHS),
        },
        "focused_source_binding": {
            "pre": artifact(root, evidence_dir / "sources.pre.sha256"),
            "post": artifact(root, evidence_dir / "sources.post.sha256"),
        },
        "full_rtl_binding": {
            "pre": artifact(
                root, evidence_dir / "rtl-source-binding.pre.json"
            ),
            "post": artifact(
                root, evidence_dir / "rtl-source-binding.post.json"
            ),
            "rtl_file_count": len(pre_binding.get("rtl_files", [])),
        },
        "tools": {
            "iverilog": artifact(root, evidence_dir / "iverilog.version"),
            "vvp": artifact(root, evidence_dir / "vvp.version"),
        },
        "scope": {
            "semantic_unit": "load-queue-producers",
            "global_no_live_reuse": "NOT_PROVEN",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
            "system_rerun": dict(SYSTEM_RERUN_SCOPE),
        },
    }


def command_mutate(args: argparse.Namespace) -> int:
    source = pathlib.Path(args.input)
    output = pathlib.Path(args.output)
    receipt_path = pathlib.Path(args.receipt)
    text = source.read_text(encoding="utf-8")
    if sha256(source) != EXPECTED_RTL_SHA256:
        raise EvidenceError("mutation input is not reviewed V11H RTL")
    mutated = mutate_source(text, args.case)
    if mutated == text:
        raise EvidenceError(f"mutation did not change RTL: {args.case}")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(mutated, encoding="utf-8")
    write_json(
        receipt_path,
        {
            "schema": MUTANT_SCHEMA,
            "case": args.case,
            "source": RTL_PATH,
            "source_sha256": EXPECTED_RTL_SHA256,
            "mutant_sha256": sha256(output),
        },
    )
    return 0


def command_build(args: argparse.Namespace) -> int:
    payload = build_summary(args)
    write_json(pathlib.Path(args.output), payload)
    return 0


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    subcommands = root.add_subparsers(dest="command", required=True)
    mutate = subcommands.add_parser("mutate")
    mutate.add_argument("--case", choices=MUTATION_CASES, required=True)
    mutate.add_argument("--input", required=True)
    mutate.add_argument("--output", required=True)
    mutate.add_argument("--receipt", required=True)
    mutate.set_defaults(handler=command_mutate)
    build = subcommands.add_parser("build")
    build.add_argument("--root", required=True)
    build.add_argument("--evidence-dir", required=True)
    build.add_argument("--pre-fix-dir", required=True)
    build.add_argument("--output", required=True)
    build.set_defaults(handler=command_build)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        return args.handler(args)
    except EvidenceError as exc:
        print(f"[V11H-EVIDENCE][FAIL] {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
