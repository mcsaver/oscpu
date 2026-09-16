#!/usr/bin/env python3
"""Build source-bound semantic evidence for integer-IQ ProducerId holders.

The V11F evidence closes only ``integer-iq-producers``.  Positive profiles
run one stimulus-owned eight-entry model with generation widths 1 and 4,
both with and without ``OOO_ASSERT``.  Compile-success RTL variants run with
``OOO_ASSERT`` disabled, so the directed raw-Q oracle—not a production
assertion—must reject every carrier, lifetime, or knownness defect.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11f-int-iq-producer-semantic-evidence-v1"
MUTANT_SCHEMA = "rv64-v11f-int-iq-producer-mutant-v1"
TEST = "tb_ooo_int_issue_queue"
RTL_PATH = "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v"
SELECTOR_PATH = "npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v"
TB_PATH = "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv"
EXPECTED_RTL_SHA256 = (
    "a63a0f835deec88121d923f7b0c01d57c069ed333f7c66a883fdaf77c1ad8d70"
)
EXPECTED_SELECTOR_SHA256 = (
    "845d5dc474d8c8b5ebdee54afb54deebf3d588841562743bb351348d6e0e4879"
)
EXPECTED_TB_SHA256 = (
    "1ddf3eadf8dcab0c1ceaa7fcaf24fab3699e3c188e74e78929f1fa307c003319"
)
UNIT_IDS = frozenset({"integer-iq-producers"})
POSITIVE_PROFILES = {
    "assert-g1": (1, True),
    "release-g1": (1, False),
    "assert-g4": (4, True),
    "release-g4": (4, False),
}
POSITIVE_MARKERS = (
    "[V11F-INT-IQ-BIRTH-HOLD] GEN_W={generation_width} "
    "dual/full/ready/recover/reset PASS",
    "[V11F-INT-IQ-ISSUE-COMPACTION] GEN_W={generation_width} "
    "overtake/single/dual/replacement PASS",
    "[V11F-INT-IQ-PAIR-DEATH] GEN_W={generation_width} "
    "ready-hold/pop2/append PASS",
    "[V11F-INT-IQ-KILL-FLUSH-RESET] GEN_W={generation_width} "
    "wrap/kill/flush/reset PASS",
    "[V11F-INT-IQ-ALL] GEN_W={generation_width} "
    "independent edge model PASS",
    "[PASS] tb_ooo_int_issue_queue_v11f_producer_lifecycle",
)
MUTATION_CASES = (
    "dispatch0-generation-zero",
    "dispatch1-uses-lane0-pid",
    "compaction-uses-write-index-pid",
    "compaction-generation-zero",
    "issue0-generation-zero",
    "issue1-generation-zero",
    "issue0-raw-index-entry0",
    "issue1-raw-index-issue0",
    "issue0-fire-not-removed",
    "issue1-fire-not-removed",
    "pair-pop-only-entry0",
    "kill-boundary-inclusive",
    "flush-ignored",
    "reset-ignored",
    "regular-fire-dies-early-mask",
    "pair-fire-dies-early-mask",
    "mask-raw-rob-index",
    "dispatch0-pid-x",
    "dispatch1-pid-x",
    "compaction-pid-x",
)
MUTATION_WIDTHS = (1, 4)
MUTATION_MARKER = "[V11F-INT-IQ-ORACLE][FAIL]"


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
    compact_pid = (
        "        producer_id_q[compact_g],\n"
    )
    if case == "dispatch0-generation-zero":
        return replace_once(
            text,
            "    dispatch0_producer_id_i,\n",
            "    "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "dispatch0_producer_id_i[ROB_INDEX_W-1:0]},\n",
            case,
        )
    if case == "dispatch1-uses-lane0-pid":
        return replace_once(
            text,
            "    dispatch1_producer_id_i,\n",
            "    dispatch0_producer_id_i,\n",
            case,
        )
    if case == "compaction-uses-write-index-pid":
        return replace_once(
            text,
            compact_pid,
            "        producer_id_q[compact_g - "
            "compact_remove_prefix_count_w[compact_g]],\n",
            case,
        )
    if case == "compaction-generation-zero":
        return replace_once(
            text,
            compact_pid,
            "        "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "producer_id_q[compact_g][ROB_INDEX_W-1:0]},\n",
            case,
        )
    if case == "issue0-generation-zero":
        return replace_once(
            text,
            "  assign issue0_producer_id_o = producer_id_q[issue0_idx_w];\n",
            "  assign issue0_producer_id_o = "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "producer_id_q[issue0_idx_w][ROB_INDEX_W-1:0]};\n",
            case,
        )
    if case == "issue1-generation-zero":
        return replace_once(
            text,
            "  assign issue1_producer_id_o = producer_id_q[issue1_idx_w];\n",
            "  assign issue1_producer_id_o = "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "producer_id_q[issue1_idx_w][ROB_INDEX_W-1:0]};\n",
            case,
        )
    if case == "issue0-raw-index-entry0":
        return replace_once(
            text,
            "  assign issue0_rob_idx_o = "
            "issue0_producer_id_o[ROB_INDEX_W-1:0];\n",
            "  assign issue0_rob_idx_o = "
            "producer_id_q[0][ROB_INDEX_W-1:0];\n",
            case,
        )
    if case == "issue1-raw-index-issue0":
        return replace_once(
            text,
            "  assign issue1_rob_idx_o = "
            "issue1_producer_id_o[ROB_INDEX_W-1:0];\n",
            "  assign issue1_rob_idx_o = "
            "issue0_producer_id_o[ROB_INDEX_W-1:0];\n",
            case,
        )
    if case == "issue0-fire-not-removed":
        return replace_once(
            text,
            "      ({8{issue0_fire_w}} & issue0_onehot_w) |\n",
            "      ({8{1'b0 && issue0_fire_w}} & issue0_onehot_w) |\n",
            case,
        )
    if case == "issue1-fire-not-removed":
        return replace_once(
            text,
            "      ({8{issue1_fire_w}} & issue1_onehot_w) |\n",
            "      ({8{1'b0 && issue1_fire_w}} & issue1_onehot_w) |\n",
            case,
        )
    if case == "pair-pop-only-entry0":
        return replace_once(
            text,
            "      ({8{memory_pair_peek_fire_w}} & 8'b0000_0011);\n",
            "      ({8{memory_pair_peek_fire_w}} & 8'b0000_0001);\n",
            case,
        )
    if case == "kill-boundary-inclusive":
        mutated = replace_once(
            text,
            "          !((producer_id_q[kc_i][ROB_INDEX_W-1:0] - "
            "rob_head_idx_i) >\n"
            "            (kill_rob_idx_i - rob_head_idx_i))) begin\n",
            "          !((producer_id_q[kc_i][ROB_INDEX_W-1:0] - "
            "rob_head_idx_i) >=\n"
            "            (kill_rob_idx_i - rob_head_idx_i))) begin\n",
            case,
        )
        return replace_once(
            mutated,
            "            ((producer_id_q[reset_i][ROB_INDEX_W-1:0] - "
            "rob_head_idx_i) >\n"
            "             (kill_rob_idx_i - rob_head_idx_i))) begin\n",
            "            ((producer_id_q[reset_i][ROB_INDEX_W-1:0] - "
            "rob_head_idx_i) >=\n"
            "             (kill_rob_idx_i - rob_head_idx_i))) begin\n",
            case,
        )
    if case == "flush-ignored":
        return replace_once(
            text,
            "    if (rst || flush_i) begin\n",
            "    if (rst) begin\n",
            case,
        )
    if case == "reset-ignored":
        return replace_once(
            text,
            "    if (rst || flush_i) begin\n",
            "    if (flush_i) begin\n",
            case,
        )
    mask_body = (
        "      if (valid_q[lease_i])\n"
        "        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;\n"
    )
    if case == "regular-fire-dies-early-mask":
        return replace_once(
            text,
            mask_body,
            "      if (valid_q[lease_i] &&\n"
            "          !(issue0_fire_w &&\n"
            "            (lease_i[ENTRY_INDEX_W-1:0] == issue0_idx_w)) &&\n"
            "          !(issue1_fire_w &&\n"
            "            (lease_i[ENTRY_INDEX_W-1:0] == issue1_idx_w)))\n"
            "        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;\n",
            case,
        )
    if case == "pair-fire-dies-early-mask":
        return replace_once(
            text,
            mask_body,
            "      if (valid_q[lease_i] &&\n"
            "          !(memory_pair_peek_fire_w &&\n"
            "            ((lease_i == 0) || (lease_i == 1))))\n"
            "        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;\n",
            case,
        )
    if case == "mask-raw-rob-index":
        return replace_once(
            text,
            mask_body,
            "      if (valid_q[lease_i])\n"
            "        producer_live_mask_r["
            "producer_id_q[lease_i][ROB_INDEX_W-1:0]] = 1'b1;\n",
            case,
        )
    if case == "dispatch0-pid-x":
        return replace_once(
            text,
            "    dispatch0_producer_id_i,\n",
            "    {PRODUCER_ID_W{1'bx}},\n",
            case,
        )
    if case == "dispatch1-pid-x":
        return replace_once(
            text,
            "    dispatch1_producer_id_i,\n",
            "    {PRODUCER_ID_W{1'bx}},\n",
            case,
        )
    if case == "compaction-pid-x":
        return replace_once(
            text,
            compact_pid,
            "        {PRODUCER_ID_W{1'bx}},\n",
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
        if line.startswith("[V11F-COMPILE]")
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
    rtl = root / RTL_PATH
    selector = root / SELECTOR_PATH
    tb = root / TB_PATH
    if sha256(rtl) != EXPECTED_RTL_SHA256:
        raise EvidenceError("production OooIntIssueQueue differs from review")
    if sha256(selector) != EXPECTED_SELECTOR_SHA256:
        raise EvidenceError("production selector differs from review")
    if sha256(tb) != EXPECTED_TB_SHA256:
        raise EvidenceError("V11F testbench differs from reviewed source")

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
    production_text = rtl.read_text(encoding="utf-8")
    for case in MUTATION_CASES:
        case_dir = evidence / "mutations" / case
        mutant_path = case_dir / "OooIntIssueQueue.v"
        expected_mutant = mutate_source(production_text, case)
        if mutant_path.read_text(encoding="utf-8") != expected_mutant:
            raise EvidenceError(f"mutation source mismatch: {case}")
        receipt_path = case_dir / "mutator.json"
        receipt = load_json(receipt_path)
        expected_receipt = {
            "case": case,
            "mutant_sha256": sha256(mutant_path),
            "production_path": RTL_PATH,
            "production_sha256": EXPECTED_RTL_SHA256,
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
            "module": "OooIntIssueQueue",
            "state": "producer_id_q",
            "classification": "verification",
            "excludes": [
                "upstream-kill-flush-reachability",
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
                "accepted testbench dispatch stimulus",
                "testbench-owned eight-entry full-ProducerId list",
                "directed issue/pair/recovery/flush/reset edge schedule",
            ],
            "forbidden_feedback": [
                "producer_live_mask_o as expected state",
                "dut.valid_q as expected state",
                "dut.producer_id_q as expected identity",
            ],
            "checks_every_directed_edge": True,
            "checks_all_entries": True,
            "checks_all_generation_bits": True,
            "checks_raw_identity_knownness": True,
        },
        "production": {
            "rtl": entry(root, rtl),
            "selector": entry(root, selector),
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
    if sha256(source_path) != EXPECTED_RTL_SHA256:
        raise EvidenceError(
            "mutation input is not reviewed production OooIntIssueQueue"
        )
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
            "production_path": RTL_PATH,
            "production_sha256": EXPECTED_RTL_SHA256,
            "schema": MUTANT_SCHEMA,
        },
    )
    print(f"PASS mutation={args.case} sha256={sha256(output_path)}")
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
        raise EvidenceError(
            "summary output must stay in evidence directory"
        ) from exc
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
