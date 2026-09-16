#!/usr/bin/env python3
"""Build source-bound semantic evidence for StoreQueue resident holders.

V11G closes only ``store-queue-producers`` and
``store-queue-owner-tokens``.  Positive profiles use one stimulus-owned
four-entry edge model with generation widths 1 and 4, with and without
``OOO_ASSERT``.  Compile-success RTL variants run with ``OOO_ASSERT``
disabled, so the raw-Q testbench oracle must reject every identity,
lifetime, recovery, bypass, or knownness defect.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
from typing import Any


SCHEMA = "rv64-v11g-store-queue-holder-semantic-evidence-v1"
MUTANT_SCHEMA = "rv64-v11g-store-queue-holder-mutant-v1"
TEST = "tb_ooo_store_queue"
RTL_PATH = "npc/rv64/vsrc/memory/OooStoreQueue.v"
TB_PATH = "npc/rv64/testbench/tests/tb_ooo_store_queue.sv"
EXPECTED_RTL_SHA256 = (
    "b6d3b77379fbfa6777df239f3c94ce62e31e75dfcbd60810f1e6f3ae968d5d2f"
)
EXPECTED_TB_SHA256 = (
    "6968ad0699be59e7166064bcf62033d655185c688cb52aa4cf80d8536cb67823"
)
UNIT_IDS = frozenset(
    {
        "store-queue-producers",
        "store-queue-owner-tokens",
    }
)
POSITIVE_PROFILES = {
    "assert-g1": (1, True),
    "release-g1": (1, False),
    "assert-g4": (4, True),
    "release-g4": (4, False),
}
POSITIVE_MARKERS = (
    "[V11G-SQ-BIRTH-BIND] GEN_W={generation_width} "
    "dual/full/asymmetric-tuple PASS",
    "[V11G-SQ-REQUEST-TERMINAL] GEN_W={generation_width} "
    "wrong-gen/resident/release/reuse PASS",
    "[V11G-SQ-RECOVERY] GEN_W={generation_width} "
    "selective/global/request-sent PASS",
    "[V11G-SQ-SAME-EDGE] GEN_W={generation_width} "
    "release-alloc/terminal-release/bind-terminal/dual-terminal PASS",
    "[V11G-SQ-ALL] GEN_W={generation_width} "
    "stimulus-owned raw-Q model PASS",
    "[PASS] tb_ooo_store_queue_v11g_holder_lifecycle",
)
MUTATION_CASES = (
    "alloc0-generation-zero",
    "alloc1-uses-alloc0-pid",
    "alloc0-pid-x",
    "alloc1-pid-x",
    "slot-reuse-keeps-old-pid",
    "request-full-pid-raw-only",
    "release-full-pid-raw-only",
    "request-clears-valid",
    "terminal-clears-valid",
    "release-keeps-valid",
    "flush-keeps-valid",
    "selective-kills-boundary",
    "global-kills-request-sent",
    "bind1-uses-bind0-tuple",
    "bind0-kind-x",
    "bind0-token-x",
    "bind0-epoch-x",
    "owner-valid-dies-on-request",
    "owner-valid-dies-on-terminal",
    "release-keeps-owner-valid",
    "flush-keeps-owner-valid",
    "release-mask-uses-rob-index",
    "bind-terminal-bypass-removed",
    "release-mask-bind-bypass-removed",
)
MUTATION_WIDTHS = (1, 4)
MUTATION_MARKER = "[V11G-SQ-HOLDER-ORACLE][FAIL]"


class EvidenceError(RuntimeError):
    """Raised when an evidence artifact is incomplete or ambiguous."""


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


def entry(
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
    request_update = (
        "      if (req_fire_i && req_valid_o)\n"
        "        request_sent_q[head_q] <= 1'b1;\n"
    )
    terminal_update = (
        "        if (terminal_hit_w[i] || terminal1_hit_w[i])\n"
        "          terminal_q[i] <= 1'b1;\n"
    )
    if case == "alloc0-generation-zero":
        return replace_once(
            text,
            "          producer_id_q[alloc0_idx_w] <= alloc0_producer_id_i;\n",
            "          producer_id_q[alloc0_idx_w] <= "
            "{{(PRODUCER_ID_W-ROB_INDEX_W){1'b0}}, "
            "alloc0_producer_id_i[ROB_INDEX_W-1:0]};\n",
            case,
        )
    if case == "alloc1-uses-alloc0-pid":
        return replace_once(
            text,
            "          producer_id_q[alloc1_idx_w] <= alloc1_producer_id_i;\n",
            "          producer_id_q[alloc1_idx_w] <= alloc0_producer_id_i;\n",
            case,
        )
    if case == "alloc0-pid-x":
        return replace_once(
            text,
            "          producer_id_q[alloc0_idx_w] <= alloc0_producer_id_i;\n",
            "          producer_id_q[alloc0_idx_w] <= "
            "{PRODUCER_ID_W{1'bx}};\n",
            case,
        )
    if case == "alloc1-pid-x":
        return replace_once(
            text,
            "          producer_id_q[alloc1_idx_w] <= alloc1_producer_id_i;\n",
            "          producer_id_q[alloc1_idx_w] <= "
            "{PRODUCER_ID_W{1'bx}};\n",
            case,
        )
    if case == "slot-reuse-keeps-old-pid":
        return replace_once(
            text,
            "          producer_id_q[alloc0_idx_w] <= alloc0_producer_id_i;\n",
            "          producer_id_q[alloc0_idx_w] <= "
            "producer_id_q[alloc0_idx_w];\n",
            case,
        )
    if case == "request-full-pid-raw-only":
        return replace_once(
            text,
            "      (producer_id_q[head_q] == rob_head_producer_id_i) &&\n",
            "      (producer_id_q[head_q][ROB_INDEX_W-1:0] ==\n"
            "       rob_head_producer_id_i[ROB_INDEX_W-1:0]) &&\n",
            case,
        )
    if case == "release-full-pid-raw-only":
        return replace_once(
            text,
            "      (producer_id_q[head_q] == release_producer_id_i) &&\n",
            "      (producer_id_q[head_q][ROB_INDEX_W-1:0] ==\n"
            "       release_producer_id_i[ROB_INDEX_W-1:0]) &&\n",
            case,
        )
    if case == "request-clears-valid":
        return replace_once(
            text,
            request_update,
            "      if (req_fire_i && req_valid_o) begin\n"
            "        request_sent_q[head_q] <= 1'b1;\n"
            "        valid_q[head_q] <= 1'b0;\n"
            "      end\n",
            case,
        )
    if case == "terminal-clears-valid":
        return replace_once(
            text,
            terminal_update,
            "        if (terminal_hit_w[i] || terminal1_hit_w[i]) begin\n"
            "          terminal_q[i] <= 1'b1;\n"
            "          valid_q[i] <= 1'b0;\n"
            "        end\n",
            case,
        )
    if case == "release-keeps-valid":
        return replace_once(
            text,
            "        valid_q[head_q] <= 1'b0;\n",
            "        valid_q[head_q] <= valid_q[head_q];\n",
            case,
        )
    if case == "flush-keeps-valid":
        return replace_once(
            text,
            "          if (valid_q[i] && !survive_r[i]) begin\n"
            "            valid_q[i] <= 1'b0;\n"
            "            owner_valid_q[i] <= 1'b0;\n",
            "          if (valid_q[i] && !survive_r[i]) begin\n"
            "            valid_q[i] <= valid_q[i];\n"
            "            owner_valid_q[i] <= 1'b0;\n",
            case,
        )
    if case == "selective-kills-boundary":
        return replace_once(
            text,
            "            (rob_dist(rob_idx_q[k], flush_rob_head_i) <=\n"
            "             rob_dist(flush_boundary_rob_i, flush_rob_head_i))));\n",
            "            (rob_dist(rob_idx_q[k], flush_rob_head_i) <\n"
            "             rob_dist(flush_boundary_rob_i, flush_rob_head_i))));\n",
            case,
        )
    if case == "global-kills-request-sent":
        return replace_once(
            text,
            "          (request_sent_q[k] ||\n",
            "          ((1'b0 && request_sent_q[k]) ||\n",
            case,
        )
    if case == "bind1-uses-bind0-tuple":
        mutated = replace_once(
            text,
            "          owner_kind_q[i] <= owner_bind1_kind_i;\n",
            "          owner_kind_q[i] <= owner_bind_kind_i;\n",
            case,
        )
        mutated = replace_once(
            mutated,
            "          owner_token_q[i] <= owner_bind1_token_i;\n",
            "          owner_token_q[i] <= owner_bind_token_i;\n",
            case,
        )
        return replace_once(
            mutated,
            "          mmu_epoch_q[i] <= owner_bind1_mmu_epoch_i;\n",
            "          mmu_epoch_q[i] <= owner_bind_mmu_epoch_i;\n",
            case,
        )
    if case == "bind0-kind-x":
        return replace_once(
            text,
            "          owner_kind_q[i] <= owner_bind_kind_i;\n",
            "          owner_kind_q[i] <= 2'bxx;\n",
            case,
        )
    if case == "bind0-token-x":
        return replace_once(
            text,
            "          owner_token_q[i] <= owner_bind_token_i;\n",
            "          owner_token_q[i] <= {OWNER_TOKEN_W{1'bx}};\n",
            case,
        )
    if case == "bind0-epoch-x":
        return replace_once(
            text,
            "          mmu_epoch_q[i] <= owner_bind_mmu_epoch_i;\n",
            "          mmu_epoch_q[i] <= {MMU_EPOCH_W{1'bx}};\n",
            case,
        )
    if case == "owner-valid-dies-on-request":
        return replace_once(
            text,
            request_update,
            "      if (req_fire_i && req_valid_o) begin\n"
            "        request_sent_q[head_q] <= 1'b1;\n"
            "        owner_valid_q[head_q] <= 1'b0;\n"
            "      end\n",
            case,
        )
    if case == "owner-valid-dies-on-terminal":
        return replace_once(
            text,
            terminal_update,
            "        if (terminal_hit_w[i] || terminal1_hit_w[i]) begin\n"
            "          terminal_q[i] <= 1'b1;\n"
            "          owner_valid_q[i] <= 1'b0;\n"
            "        end\n",
            case,
        )
    if case == "release-keeps-owner-valid":
        return replace_once(
            text,
            "        owner_valid_q[head_q] <= 1'b0;\n",
            "        owner_valid_q[head_q] <= owner_valid_q[head_q];\n",
            case,
        )
    if case == "flush-keeps-owner-valid":
        return replace_once(
            text,
            "          if (valid_q[i] && !survive_r[i]) begin\n"
            "            valid_q[i] <= 1'b0;\n"
            "            owner_valid_q[i] <= 1'b0;\n",
            "          if (valid_q[i] && !survive_r[i]) begin\n"
            "            valid_q[i] <= 1'b0;\n"
            "            owner_valid_q[i] <= owner_valid_q[i];\n",
            case,
        )
    if case == "release-mask-uses-rob-index":
        return replace_once(
            text,
            "          owner_release_mask_r[owner_token_q[owner_release_i]] = "
            "1'b1;\n",
            "          owner_release_mask_r[rob_idx_q[owner_release_i]] = "
            "1'b1;\n",
            case,
        )
    if case == "bind-terminal-bypass-removed":
        return replace_once(
            text,
            "           (owner_bind_hit_w[gc] &&\n"
            "            (owner_bind_kind_i == terminal1_owner_kind_i) &&\n"
            "            (owner_bind_token_i == terminal1_owner_token_i) &&\n"
            "            (owner_bind_mmu_epoch_i == "
            "terminal1_mmu_epoch_i)) ||\n",
            "",
            case,
        )
    if case == "release-mask-bind-bypass-removed":
        return replace_once(
            text,
            "        else if (owner_bind_hit_w[owner_release_i])\n"
            "          owner_release_mask_r[owner_bind_token_i] = 1'b1;\n",
            "        else if (1'b0 && owner_bind_hit_w[owner_release_i])\n"
            "          owner_release_mask_r[owner_bind_token_i] = 1'b1;\n",
            case,
        )
    raise EvidenceError(f"unsupported mutation case: {case}")


def parse_manifest(
    root: pathlib.Path,
    path: pathlib.Path,
) -> dict[str, str]:
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
        if line.startswith("[V11G-COMPILE]")
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
    tb = root / TB_PATH
    if sha256(rtl) != EXPECTED_RTL_SHA256:
        raise EvidenceError("production OooStoreQueue differs from review")
    if sha256(tb) != EXPECTED_TB_SHA256:
        raise EvidenceError("V11G testbench differs from reviewed source")

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
        mutant_path = case_dir / "OooStoreQueue.v"
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
            "module": "OooStoreQueue",
            "state": [
                "producer_id_q",
                "owner_valid_q",
                "owner_kind_q",
                "owner_token_q",
                "mmu_epoch_q",
            ],
            "classification": "verification",
            "excludes": [
                "upstream-illegal-input-reachability",
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
                "accepted testbench allocation and bind stimulus",
                "testbench-owned four-entry full-ProducerId/owner-tuple model",
                "directed request/terminal/release/flush/reset edge schedule",
            ],
            "forbidden_feedback": [
                "snoop_producer_id_o as expected identity",
                "snoop_owner_token_o as expected identity",
                "dut raw Q as expected state",
            ],
            "stimulus_owned_four_entry_model": True,
            "checks_every_directed_edge": True,
            "checks_all_entries": True,
            "checks_all_generation_bits": True,
            "checks_raw_producer_id_knownness": True,
            "checks_raw_owner_tuple_knownness": True,
            "uses_asymmetric_token_epoch": True,
        },
        "production": {
            "rtl": entry(root, rtl),
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
            "mutation input is not reviewed production OooStoreQueue"
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
