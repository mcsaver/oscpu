#!/usr/bin/env python3
"""Build source-bound semantic evidence for ``OooRob.slot_generation_q``.

The evidence closes only ``rob-slot-generation``.  Positive profiles exercise
the same independent edge model with generation widths 1 and 4, both with and
without ``OOO_ASSERT``.  Every compile-success RTL variant is simulated with
``OOO_ASSERT`` disabled so an assertion cannot substitute for the directed
testbench oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11e-rob-slot-generation-semantic-evidence-v1"
MUTANT_SCHEMA = "rv64-v11e-rob-slot-generation-mutant-v1"
TEST = "tb_ooo_rob"
ROB_PATH = "npc/rv64/vsrc/writeback/OooRob.v"
TB_PATH = "npc/rv64/testbench/tests/tb_ooo_rob.sv"
EXPECTED_ROB_SHA256 = (
    "bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561"
)
EXPECTED_TB_SHA256 = (
    "6c5881089fc1437d40f15532279dde1e0c8b1359d4bd5c47ff03b4886a87f4f5"
)
UNIT_IDS = frozenset({"rob-slot-generation"})
POSITIVE_PROFILES = {
    "assert-g1": (1, True),
    "release-g1": (1, False),
    "assert-g4": (4, True),
    "release-g4": (4, False),
}
POSITIVE_MARKERS = (
    "[V11E-SLOT-GEN-CANDIDATE] GEN_W={generation_width} "
    "lane0/lane1/pair source PASS",
    "[V11E-SLOT-GEN-QUERY-CARRIER] GEN_W={generation_width} "
    "exact/all-generation-bit/done/commit/flush PASS",
    "[V11E-SLOT-GEN-LIFECYCLE] GEN_W={generation_width} "
    "flush/kill/recovery/commit/reuse PASS",
    "[V11E-SLOT-GEN-FULL-REUSE] GEN_W={generation_width} "
    "two-edge reject/full-commit/reuse PASS",
    "[V11E-SLOT-GEN-WRAP] GEN_W={generation_width} "
    "width-bounded modulo behavior PASS",
    "[V11E-SLOT-GEN-ALL] GEN_W={generation_width} "
    "independent edge model PASS",
    "[PASS] tb_ooo_rob_v11e_slot_generation",
)
MUTATION_CASES = (
    "reset-seed-zero",
    "flush-resets-generation",
    "candidate-no-increment",
    "candidate-step-two",
    "lane1-uses-lane0-generation",
    "pair-uses-actual-lane1-slot",
    "lane0-write-on-valid",
    "lane1-write-lane0-slot",
    "commit-advances-generation",
    "recovery-resets-generation",
    "full-borrows-commit-slot",
    "head-carrier-zero-generation",
    "commit-carrier-zero-generation",
    "walk-carrier-zero-generation",
    "current-query-ignore-generation",
    "completion-query-ignore-generation",
    "resolve-query-ignore-generation",
)
MUTATION_WIDTHS = (1, 4)
MUTATION_MARKER = "[V11E-SLOT-GEN-ORACLE][FAIL]"


class EvidenceError(RuntimeError):
    """Raised when a mutation or evidence record is not auditable."""


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


def entry(root: pathlib.Path, path: pathlib.Path) -> dict[str, Any]:
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


def require_present(text: str, marker: str, label: str) -> None:
    if marker not in text:
        raise EvidenceError(f"{label} lacks marker: {marker!r}")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise EvidenceError(
            f"mutation {label} anchor count={count} expected=1"
        )
    return text.replace(old, new, 1)


def mutate_source(text: str, case: str) -> str:
    one = "{{(PRODUCER_GEN_W-1){1'b0}}, 1'b1}"
    if case == "reset-seed-zero":
        return replace_once(
            text,
            "          slot_generation_q[idx] <= "
            "{PRODUCER_GEN_W{1'b1}};\n",
            "          slot_generation_q[idx] <= "
            "{PRODUCER_GEN_W{1'b0}};\n",
            case,
        )
    if case == "flush-resets-generation":
        return replace_once(
            text,
            "        if (rst)\n"
            "          slot_generation_q[idx] <= "
            "{PRODUCER_GEN_W{1'b1}};\n",
            "        slot_generation_q[idx] <= "
            "{PRODUCER_GEN_W{1'b1}};\n",
            case,
        )
    if case == "candidate-no-increment":
        return replace_once(
            text,
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch0_generation_candidate_w =\n"
            "      slot_generation_q[dispatch0_rob_idx_o] +\n"
            f"      {one};\n",
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch0_generation_candidate_w =\n"
            "      slot_generation_q[dispatch0_rob_idx_o];\n",
            case,
        )
    if case == "candidate-step-two":
        return replace_once(
            text,
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch0_generation_candidate_w =\n"
            "      slot_generation_q[dispatch0_rob_idx_o] +\n"
            f"      {one};\n",
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch0_generation_candidate_w =\n"
            "      slot_generation_q[dispatch0_rob_idx_o] +\n"
            f"      {one} +\n"
            f"      {one};\n",
            case,
        )
    if case == "lane1-uses-lane0-generation":
        return replace_once(
            text,
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch1_generation_candidate_w =\n"
            "      slot_generation_q[dispatch1_rob_idx_o] +\n"
            f"      {one};\n",
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch1_generation_candidate_w =\n"
            "      slot_generation_q[dispatch0_rob_idx_o] +\n"
            f"      {one};\n",
            case,
        )
    if case == "pair-uses-actual-lane1-slot":
        return replace_once(
            text,
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch1_pair_generation_candidate_w =\n"
            "      slot_generation_q[dispatch1_pair_idx_w] +\n"
            f"      {one};\n",
            "  wire [PRODUCER_GEN_W-1:0] "
            "dispatch1_pair_generation_candidate_w =\n"
            "      slot_generation_q[dispatch1_rob_idx_o] +\n"
            f"      {one};\n",
            case,
        )
    if case == "lane0-write-on-valid":
        return replace_once(
            text,
            "      if (dispatch0_fire_w) begin\n"
            "        slot_generation_q[dispatch0_rob_idx_o] <=\n"
            "            dispatch0_generation_candidate_w;\n",
            "      if (dispatch0_valid_i) begin\n"
            "        slot_generation_q[dispatch0_rob_idx_o] <=\n"
            "            dispatch0_generation_candidate_w;\n",
            case,
        )
    if case == "lane1-write-lane0-slot":
        return replace_once(
            text,
            "        slot_generation_q[dispatch1_rob_idx_o] <=\n"
            "            dispatch1_generation_candidate_w;\n",
            "        slot_generation_q[dispatch0_rob_idx_o] <=\n"
            "            dispatch1_generation_candidate_w;\n",
            case,
        )
    if case == "commit-advances-generation":
        return replace_once(
            text,
            "      if (commit0_fire_w) begin\n"
            "        valid_q[head_q] <= 1'b0;\n",
            "      if (commit0_fire_w) begin\n"
            "        slot_generation_q[head_q] <= "
            f"slot_generation_q[head_q] + {one};\n"
            "        valid_q[head_q] <= 1'b0;\n",
            case,
        )
    if case == "recovery-resets-generation":
        return replace_once(
            text,
            "      valid_q[walk_ptr_q] <= 1'b0;\n"
            "      done_q[walk_ptr_q] <= 1'b0;\n",
            "      slot_generation_q[walk_ptr_q] <= "
            "{PRODUCER_GEN_W{1'b1}};\n"
            "      if (lane1_sq_w)\n"
            "        slot_generation_q[wptr_m1_w] <= "
            "{PRODUCER_GEN_W{1'b1}};\n"
            "      valid_q[walk_ptr_q] <= 1'b0;\n"
            "      done_q[walk_ptr_q] <= 1'b0;\n",
            case,
        )
    if case == "full-borrows-commit-slot":
        return replace_once(
            text,
            "  assign free_slots_w = "
            "ROB_ENTRIES[ROB_COUNT_W-1:0] - count_q;\n",
            "  assign free_slots_w = "
            "ROB_ENTRIES[ROB_COUNT_W-1:0] - count_q + commit_count_w;\n",
            case,
        )
    if case == "head-carrier-zero-generation":
        return replace_once(
            text,
            "  assign head0_producer_id_o = "
            "{slot_generation_q[head_q], head_q};\n",
            "  assign head0_producer_id_o = "
            "{{PRODUCER_GEN_W{1'b0}}, head_q};\n",
            case,
        )
    if case == "commit-carrier-zero-generation":
        return replace_once(
            text,
            "  assign commit0_producer_id_o = "
            "{slot_generation_q[head_q], head_q};\n",
            "  assign commit0_producer_id_o = "
            "{{PRODUCER_GEN_W{1'b0}}, head_q};\n",
            case,
        )
    if case == "walk-carrier-zero-generation":
        mutated = replace_once(
            text,
            "  assign walk0_producer_id_o = "
            "{slot_generation_q[walk_ptr_q], walk_ptr_q};\n",
            "  assign walk0_producer_id_o = "
            "{{PRODUCER_GEN_W{1'b0}}, walk_ptr_q};\n",
            case,
        )
        return replace_once(
            mutated,
            "  assign walk1_producer_id_o = "
            "{slot_generation_q[wptr_m1_w], wptr_m1_w};\n",
            "  assign walk1_producer_id_o = "
            "{{PRODUCER_GEN_W{1'b0}}, wptr_m1_w};\n",
            case,
        )
    if case == "current-query-ignore-generation":
        mutated = text
        for lane in (0, 1):
            mutated = replace_once(
                mutated,
                f"  wire current{lane}_query_exact_w =\n"
                f"      {{slot_generation_q[current{lane}_query_idx_w], "
                f"current{lane}_query_idx_w}} ==\n"
                f"      current{lane}_query_producer_id_i;\n",
                f"  wire current{lane}_query_exact_w = 1'b1;\n",
                case,
            )
        return mutated
    if case == "completion-query-ignore-generation":
        mutated = text
        for lane in range(8):
            mutated = replace_once(
                mutated,
                f"  wire completion{lane}_query_exact_w =\n"
                f"      {{slot_generation_q[completion{lane}_query_idx_w], "
                f"completion{lane}_query_idx_w}} ==\n"
                f"      completion{lane}_query_producer_id_i;\n",
                f"  wire completion{lane}_query_exact_w = 1'b1;\n",
                case,
            )
        return mutated
    if case == "resolve-query-ignore-generation":
        return replace_once(
            text,
            "  wire resolve_query_exact_w =\n"
            "      {slot_generation_q[resolve_query_idx_w], "
            "resolve_query_idx_w} ==\n"
            "      resolve_query_producer_id_i;\n",
            "  wire resolve_query_exact_w = 1'b1;\n",
            case,
        )
    raise EvidenceError(f"unsupported mutation case: {case}")


def parse_manifest(root: pathlib.Path, path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for lineno, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        if not line:
            continue
        try:
            digest, raw = line.split(None, 1)
        except ValueError as exc:
            raise EvidenceError(
                f"malformed manifest line {path}:{lineno}"
            ) from exc
        source = pathlib.Path(raw.strip())
        if not source.is_absolute():
            source = root / source
        try:
            key = source.resolve().relative_to(root).as_posix()
        except ValueError as exc:
            raise EvidenceError(
                f"manifest path escapes repository root: {source}"
            ) from exc
        if key in result:
            raise EvidenceError(f"duplicate manifest path: {key}")
        result[key] = digest
    return result


def current_design_id(root: pathlib.Path) -> str:
    sys.path.insert(0, str(root / "npc/rv64/eval/ppa/tools"))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def validate_full_rtl_snapshot(
    root: pathlib.Path,
    path: pathlib.Path,
    design_id: str,
) -> dict[str, Any]:
    payload = load_json(path)
    if (
        payload.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1"
        or payload.get("design_id") != design_id
    ):
        raise EvidenceError("full RTL snapshot schema/design mismatch")
    rtl_files = payload.get("rtl_files")
    if not isinstance(rtl_files, dict) or not rtl_files:
        raise EvidenceError("full RTL snapshot has no source records")
    for value, expected in rtl_files.items():
        source = root / value
        if not source.is_file() or sha256(source) != expected:
            raise EvidenceError(f"live RTL differs from snapshot: {value}")
    return payload


def validate_compile_log(
    path: pathlib.Path,
    generation_width: int,
    assertions_enabled: bool,
    label: str,
) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    lines = [
        line for line in text.splitlines()
        if line.startswith("[V11E-COMPILE]")
    ]
    if len(lines) != 1:
        raise EvidenceError(f"{label} compile command count={len(lines)}")
    command = lines[0]
    required = f"-DOOO_PRODUCER_GEN_W={generation_width}"
    if required not in command:
        raise EvidenceError(f"{label} compile command lacks {required}")
    if assertions_enabled and "-DOOO_ASSERT" not in command:
        raise EvidenceError(f"{label} did not enable OOO_ASSERT")
    if not assertions_enabled and "-DOOO_ASSERT" in command:
        raise EvidenceError(f"{label} unexpectedly enabled OOO_ASSERT")
    return {"command": command, "log": path}


def build_summary(
    root: pathlib.Path,
    evidence: pathlib.Path,
) -> dict[str, Any]:
    rob = root / ROB_PATH
    tb = root / TB_PATH
    if sha256(rob) != EXPECTED_ROB_SHA256:
        raise EvidenceError("production OooRob differs from reviewed source")
    if sha256(tb) != EXPECTED_TB_SHA256:
        raise EvidenceError("V11E testbench differs from reviewed source")

    design_id = current_design_id(root)
    rtl_pre_path = evidence / "rtl-source-binding.pre.json"
    rtl_post_path = evidence / "rtl-source-binding.post.json"
    rtl_pre = validate_full_rtl_snapshot(root, rtl_pre_path, design_id)
    rtl_post = validate_full_rtl_snapshot(root, rtl_post_path, design_id)
    if rtl_pre != rtl_post:
        raise EvidenceError("full RTL pre/post snapshots differ")

    source_pre_path = evidence / "sources.pre.sha256"
    source_post_path = evidence / "sources.post.sha256"
    source_pre = parse_manifest(root, source_pre_path)
    source_post = parse_manifest(root, source_post_path)
    if source_pre != source_post:
        raise EvidenceError("focused source manifest changed during execution")
    for value, expected in source_pre.items():
        source = root / value
        if not source.is_file() or sha256(source) != expected:
            raise EvidenceError(f"live focused source differs: {value}")

    positives: dict[str, Any] = {}
    for profile, (generation_width, assertions_enabled) in (
        POSITIVE_PROFILES.items()
    ):
        profile_dir = evidence / "profiles" / profile
        compile_rc = read_rc(profile_dir / "compile.rc", profile)
        sim_rc = read_rc(profile_dir / "sim.rc", profile)
        if compile_rc != 0 or sim_rc != 0:
            raise EvidenceError(
                f"{profile} baseline rc compile={compile_rc} sim={sim_rc}"
            )
        compile_record = validate_compile_log(
            profile_dir / "compile.log",
            generation_width,
            assertions_enabled,
            profile,
        )
        sim_path = profile_dir / "sim.log"
        sim_text = sim_path.read_text(encoding="utf-8")
        if MUTATION_MARKER in sim_text:
            raise EvidenceError(f"{profile} baseline contains oracle failure")
        for marker in POSITIVE_MARKERS:
            require_once(
                sim_text,
                marker.format(generation_width=generation_width),
                profile,
            )
        positives[profile] = {
            "generation_width": generation_width,
            "assertions_enabled": assertions_enabled,
            "compile_command": compile_record["command"],
            "compile_log": entry(root, profile_dir / "compile.log"),
            "simulation_log": entry(root, sim_path),
            "compiled_image": entry(
                root, profile_dir / "build" / f"{TEST}.vvp"
            ),
        }

    mutations: list[dict[str, Any]] = []
    production_text = rob.read_text(encoding="utf-8")
    for case in MUTATION_CASES:
        case_dir = evidence / "mutations" / case
        mutant_path = case_dir / "OooRob.v"
        expected_mutant = mutate_source(production_text, case)
        if mutant_path.read_text(encoding="utf-8") != expected_mutant:
            raise EvidenceError(f"mutation source mismatch: {case}")
        receipt_path = case_dir / "mutator.json"
        receipt = load_json(receipt_path)
        expected_receipt = {
            "case": case,
            "mutant_sha256": sha256(mutant_path),
            "production_path": ROB_PATH,
            "production_sha256": EXPECTED_ROB_SHA256,
            "schema": MUTANT_SCHEMA,
        }
        if receipt != expected_receipt:
            raise EvidenceError(f"mutation receipt mismatch: {case}")

        runs: dict[str, Any] = {}
        for generation_width in MUTATION_WIDTHS:
            label = f"{case}/g{generation_width}"
            run_dir = case_dir / f"g{generation_width}"
            compile_rc = read_rc(run_dir / "compile.rc", label)
            sim_rc = read_rc(run_dir / "sim.rc", label)
            if compile_rc != 0:
                raise EvidenceError(f"{label} did not compile successfully")
            if sim_rc == 0:
                raise EvidenceError(f"{label} unexpectedly passed")
            compile_record = validate_compile_log(
                run_dir / "compile.log",
                generation_width,
                False,
                label,
            )
            sim_path = run_dir / "sim.log"
            sim_text = sim_path.read_text(encoding="utf-8")
            require_present(sim_text, MUTATION_MARKER, label)
            runs[f"g{generation_width}"] = {
                "generation_width": generation_width,
                "assertions_enabled": False,
                "compile_command": compile_record["command"],
                "compile_log": entry(root, run_dir / "compile.log"),
                "simulation_log": entry(root, sim_path),
                "compiled_image": entry(
                    root, run_dir / "build" / f"{TEST}.vvp"
                ),
                "simulation_rc": sim_rc,
            }
        mutations.append(
            {
                "case": case,
                "mutant_source": entry(root, mutant_path),
                "receipt": entry(root, receipt_path),
                "runs": runs,
            }
        )

    return {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "unit_ids": sorted(UNIT_IDS),
        "scope": {
            "module": "OooRob",
            "state": "slot_generation_q",
            "classification": "verification",
            "excludes": [
                "global-holder-collision-fence",
                "whole-architecture",
                "system",
                "synthesis",
                "sta",
                "power",
                "ppa",
            ],
        },
        "independent_oracle": {
            "expected_inputs": [
                "testbench stimulus",
                "edge-old expected generation",
                "edge-old expected valid/done/head/tail/count/recovery",
            ],
            "forbidden_feedback": [
                "dut.slot_generation_q",
                "dut dispatch/head/commit/walk ProducerId",
            ],
            "checks_every_edge": True,
            "checks_all_slots": True,
            "checks_all_generation_bits": True,
        },
        "production": {
            "rtl": entry(root, rob),
            "testbench": entry(root, tb),
        },
        "full_rtl_binding": {
            "pre": entry(root, rtl_pre_path),
            "post": entry(root, rtl_post_path),
            "rtl_file_count": len(rtl_pre["rtl_files"]),
        },
        "focused_source_binding": {
            "pre": entry(root, source_pre_path),
            "post": entry(root, source_post_path),
            "source_count": len(source_pre),
        },
        "positive_profiles": positives,
        "mutations": mutations,
        "counts": {
            "positive_profiles": len(positives),
            "compile_success_mutation_cases": len(mutations),
            "mutation_simulations": (
                len(mutations) * len(MUTATION_WIDTHS)
            ),
            "rejected_mutation_simulations": (
                len(mutations) * len(MUTATION_WIDTHS)
            ),
        },
    }


def command_mutate(args: argparse.Namespace) -> int:
    root = repository_root()
    source_path = pathlib.Path(args.input).resolve()
    output_path = pathlib.Path(args.output).resolve()
    receipt_path = pathlib.Path(args.receipt).resolve()
    try:
        source_path.relative_to(root)
        output_path.relative_to(root)
        receipt_path.relative_to(root)
    except ValueError as exc:
        raise EvidenceError("mutation paths must stay inside repository") from exc
    if sha256(source_path) != EXPECTED_ROB_SHA256:
        raise EvidenceError("mutation input is not reviewed production OooRob")
    mutated = mutate_source(
        source_path.read_text(encoding="utf-8"),
        args.case,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(mutated, encoding="utf-8")
    write_json(
        receipt_path,
        {
            "case": args.case,
            "mutant_sha256": sha256(output_path),
            "production_path": ROB_PATH,
            "production_sha256": EXPECTED_ROB_SHA256,
            "schema": MUTANT_SCHEMA,
        },
    )
    print(
        f"PASS mutation={args.case} "
        f"sha256={sha256(output_path)}"
    )
    return 0


def command_build(args: argparse.Namespace) -> int:
    root = pathlib.Path(args.root).resolve()
    if root != repository_root():
        raise EvidenceError("root does not match tool repository")
    evidence = pathlib.Path(args.evidence_dir).resolve()
    try:
        evidence.relative_to(root)
    except ValueError as exc:
        raise EvidenceError("evidence directory escapes repository") from exc
    summary = build_summary(root, evidence)
    output = pathlib.Path(args.output).resolve()
    try:
        output.relative_to(evidence)
    except ValueError as exc:
        raise EvidenceError("summary output must stay in evidence directory") from exc
    write_json(output, summary)
    print(
        "PASS "
        f"profiles={summary['counts']['positive_profiles']} "
        f"mutations={summary['counts']['compile_success_mutation_cases']} "
        f"simulations={summary['counts']['mutation_simulations']}"
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    mutate = subparsers.add_parser("mutate")
    mutate.add_argument("--case", choices=MUTATION_CASES, required=True)
    mutate.add_argument("--input", required=True)
    mutate.add_argument("--output", required=True)
    mutate.add_argument("--receipt", required=True)
    mutate.set_defaults(func=command_mutate)

    build = subparsers.add_parser("build")
    build.add_argument("--root", required=True)
    build.add_argument("--evidence-dir", required=True)
    build.add_argument("--output", required=True)
    build.set_defaults(func=command_build)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        return args.func(args)
    except EvidenceError as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
