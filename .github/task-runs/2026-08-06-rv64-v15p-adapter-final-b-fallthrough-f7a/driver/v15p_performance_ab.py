#!/usr/bin/env python3
"""Build-identity and PC-bounded A/B checker for the V15P RTL candidate."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys
from typing import Any


ROOT = pathlib.Path("/home/lyg/PA/ysyx-workbench").resolve()
TOOLS = ROOT / "npc/rv64/eval/ppa/tools"
sys.path.insert(0, str(TOOLS))

import check  # noqa: E402
import performance_baseline_current as baseline  # noqa: E402


ADAPTER_KEY = "npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v"
EXPECTED_PARENT_SHA = (
    "3f59eb66967afca26700a520fedba6372a0ab7f96464048a5493642df55ab3b6"
)
EXPECTED_CANDIDATE_SHA = (
    "6d81b143e92992dfdd02b31a5b72c57ca69d3ffcbc626d00e7bb5ad3fb3a0e22"
)
RUN_ORDER = ("parent", "candidate", "candidate", "parent", "parent", "candidate")
WORKLOADS = {
    "coremark": {
        "log_prefix": "coremark",
        "expected_retired": 3_183_617,
    },
    "dhrystone_10000": {
        "log_prefix": "dhrystone",
        "expected_retired": 4_250_000,
    },
}


class EvidenceError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def artifact(path: pathlib.Path) -> dict[str, Any]:
    require(path.is_file() and not path.is_symlink(), f"invalid artifact: {path}")
    return {
        "path": path.resolve().relative_to(ROOT).as_posix(),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    }


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def collect_sources(
    build_log: pathlib.Path,
    verilator_manifest: pathlib.Path,
    actual_adapter: pathlib.Path,
) -> tuple[dict[str, str], dict[str, str]]:
    texts = [
        build_log.read_text(encoding="utf-8", errors="replace"),
        verilator_manifest.read_text(encoding="utf-8", errors="replace"),
    ]
    tokens: set[str] = set()
    for text in texts:
        tokens.update(re.findall(r"[^\s\"'()]+", text))

    sources = {actual_adapter.resolve()}
    for token in tokens:
        token = token.rstrip("\\:;,")
        if token.startswith("-I"):
            token = token[2:]
        candidate = pathlib.Path(token)
        if not candidate.is_absolute():
            candidate = (ROOT / "npc/rv64" / candidate).resolve()
        else:
            candidate = candidate.resolve()
        if not candidate.is_file():
            continue
        try:
            relative = candidate.relative_to(ROOT).as_posix()
        except ValueError:
            continue
        if relative.startswith(("npc/rv64/vsrc/", "npc/rv64/csrc/")):
            sources.add(candidate)

    hashes: dict[str, str] = {}
    paths: dict[str, str] = {}
    for source in sorted(sources):
        if source == actual_adapter.resolve():
            key = ADAPTER_KEY
        else:
            key = source.relative_to(ROOT).as_posix()
        require(key not in hashes or paths[key] == str(source),
                f"duplicate canonical source key: {key}")
        hashes[key] = sha256(source)
        paths[key] = str(source)
    required = {
        ADAPTER_KEY,
        "npc/rv64/vsrc/sim/NpcSimTop.sv",
        "npc/rv64/csrc/cpu/cpu-exec.cpp",
    }
    require(len(hashes) >= 60 and required.issubset(hashes),
            f"incomplete actual compile source manifest: {len(hashes)}")
    return dict(sorted(hashes.items())), dict(sorted(paths.items()))


def build_identity(args: argparse.Namespace) -> None:
    parent_adapter = args.parent_adapter.resolve()
    candidate_adapter = args.candidate_adapter.resolve()
    require(sha256(parent_adapter) == EXPECTED_PARENT_SHA,
            "parent adapter SHA mismatch")
    require(sha256(candidate_adapter) == EXPECTED_CANDIDATE_SHA,
            "candidate adapter SHA mismatch")

    modes: dict[str, dict[str, Any]] = {}
    for mode, adapter, binary, build_log, verfiles in (
        ("parent", parent_adapter, args.parent_binary.resolve(),
         args.parent_build_log.resolve(), args.parent_verfiles.resolve()),
        ("candidate", candidate_adapter, args.candidate_binary.resolve(),
         args.candidate_build_log.resolve(), args.candidate_verfiles.resolve()),
    ):
        for path in (adapter, binary, build_log, verfiles):
            require(path.is_file() and not path.is_symlink(),
                    f"{mode} build artifact is invalid: {path}")
        text = build_log.read_text(encoding="utf-8", errors="replace")
        flags = {
            "verilator_assert": "--assert" in text,
            "ooo_assert_define": "+define+OOO_ASSERT" in text,
            "terminal_holder_assert_define":
                "+define+OOO_TERMINAL_HOLDER_ASSERT" in text,
            "ooo_stats_define": "+define+CONFIG_NPC_OOO_STATS" in text,
        }
        require(all(flags.values()), f"{mode} required build flags missing: {flags}")
        source_hashes, source_paths = collect_sources(build_log, verfiles, adapter)
        modes[mode] = {
            "adapter": artifact(adapter),
            "simulator": artifact(binary),
            "build_log": artifact(build_log),
            "verilator_manifest": artifact(verfiles),
            "build_flags": flags,
            "actual_compile_source_sha256": source_hashes,
            "actual_compile_source_paths": source_paths,
        }

    parent_sources = modes["parent"]["actual_compile_source_sha256"]
    candidate_sources = modes["candidate"]["actual_compile_source_sha256"]
    require(set(parent_sources) == set(candidate_sources),
            "parent/candidate source-key sets differ")
    source_differences = sorted(
        key for key in parent_sources
        if parent_sources[key] != candidate_sources[key]
    )
    require(source_differences == [ADAPTER_KEY],
            f"candidate is not a single-RTL-source experiment: {source_differences}")

    binding_paths = [
        args.config.resolve(),
        args.coremark_image.resolve(),
        args.dhrystone_image.resolve(),
        ROOT / "npc/rv64/Makefile",
        ROOT / "npc/rv64/vsrc/filelist.mk",
        ROOT / "npc/rv64/include/generated/autoconf.h",
        ROOT / "npc/rv64/include/config/auto.conf",
        ROOT / "npc/rv64/design/arch/performance-counter-schema-v4.json",
        ROOT / "npc/rv64/design/arch/performance-boundary-qualification-amendment-v2.json",
        ROOT / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json",
        ROOT / "npc/rv64/eval/ppa/tools/check.py",
        ROOT / "npc/rv64/eval/ppa/tools/performance_baseline_current.py",
        pathlib.Path(__file__).resolve(),
    ]
    binding = {path.relative_to(ROOT).as_posix(): artifact(path) for path in binding_paths}
    value = {
        "schema": "npc-rv64-v15p-performance-ab-build-identity-v1",
        "status": "PASS",
        "mechanism": "lsu_axi_adapter_final_b_fallthrough",
        "single_mechanism_source_difference": source_differences,
        "run_order": list(RUN_ORDER),
        "modes": modes,
        "binding": dict(sorted(binding.items())),
        "tools": {
            "verilator": subprocess.check_output(
                ["verilator", "--version"], text=True).strip(),
            "compiler": subprocess.check_output(
                ["c++", "--version"], text=True).splitlines()[0],
        },
    }
    write_json(args.output, value)


def verify_identity(identity: dict[str, Any]) -> None:
    require(identity.get("schema") == "npc-rv64-v15p-performance-ab-build-identity-v1",
            "build identity schema mismatch")
    require(identity.get("status") == "PASS", "build identity is not PASS")
    require(identity.get("single_mechanism_source_difference") == [ADAPTER_KEY],
            "build identity source-difference mismatch")
    require(identity.get("run_order") == list(RUN_ORDER), "run order mismatch")
    for mode in ("parent", "candidate"):
        record = identity["modes"][mode]
        for item_key in ("adapter", "simulator", "build_log", "verilator_manifest"):
            item = record[item_key]
            path = ROOT / item["path"]
            require(path.is_file() and sha256(path) == item["sha256"]
                    and path.stat().st_size == item["size_bytes"],
                    f"{mode} {item_key} drifted")
        for key, expected in record["actual_compile_source_sha256"].items():
            path = pathlib.Path(record["actual_compile_source_paths"][key])
            require(path.is_file() and sha256(path) == expected,
                    f"{mode} compile source drifted: {key}")
    for record in identity["binding"].values():
        path = ROOT / record["path"]
        require(path.is_file() and sha256(path) == record["sha256"]
                and path.stat().st_size == record["size_bytes"],
                f"binding drifted: {record['path']}")


def parse_one(
    path: pathlib.Path,
    workload: str,
    policy: dict[str, Any],
    counter_schema: dict[str, Any],
) -> dict[str, Any]:
    contract = policy["performance_evidence"]["benchmark_contracts"][workload]
    if workload == "dhrystone_10000":
        parsed = baseline.parse_endpoint_corrected_v8_log(path, workload, contract)
    else:
        parsed = check.parse_raw_benchmark_log(
            path,
            workload,
            "pc_bounded_region_v1",
            contract,
            "npc-rv64-performance-evidence-v8",
            counter_schema,
        )
        require(parsed["good_trap_count"] == 1 and parsed["exit_code"] == 0,
                "CoreMark terminal semantics mismatch")
        require(parsed["iterations"] == 10 and parsed["crc"] == "0xfcaf",
                "CoreMark iteration/CRC mismatch")
    require(parsed["retired_instructions"] == WORKLOADS[workload]["expected_retired"],
            f"{workload} retired instruction contract mismatch")
    require(parsed["cpi_stack"]["memory_lifecycle"]["lifecycle_unknown"] == 0,
            f"{workload} lifecycle unknown is nonzero")
    require(parsed["cpi_stack"]["memory_request_detail"]["detail_unknown"] == 0,
            f"{workload} request-detail unknown is nonzero")
    require(parsed["retire_slots"]["unknown"] == 0,
            f"{workload} retire-slot unknown is nonzero")
    return parsed


def summarized_run(parsed: dict[str, Any], log: pathlib.Path) -> dict[str, Any]:
    return {
        "cycles": parsed["cycles"],
        "retired_instructions": parsed["retired_instructions"],
        "cpi": parsed["cycles"] / parsed["retired_instructions"],
        "ipc": parsed["retired_instructions"] / parsed["cycles"],
        "region": parsed["region"],
        "cpi_stack": parsed["cpi_stack"],
        "retire_slots": parsed["retire_slots"],
        "log": artifact(log),
    }


def build_result(args: argparse.Namespace) -> None:
    identity = json.loads(args.identity.read_text(encoding="utf-8"))
    verify_identity(identity)
    policy = json.loads((ROOT / "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json")
                        .read_text(encoding="utf-8"))
    counter_schema = json.loads((ROOT / "npc/rv64/design/arch/performance-counter-schema-v4.json")
                                .read_text(encoding="utf-8"))

    parsed_by_workload: dict[str, dict[str, list[tuple[int, pathlib.Path, dict[str, Any]]]]] = {}
    for workload, workload_contract in WORKLOADS.items():
        prefix = workload_contract["log_prefix"]
        by_mode: dict[str, list[tuple[int, pathlib.Path, dict[str, Any]]]] = {
            "parent": [], "candidate": []}
        for index, mode in enumerate(RUN_ORDER, start=1):
            path = args.logs_dir / f"{prefix}-{index:02d}-{mode}.log"
            require(path.is_file() and not path.is_symlink(), f"missing A/B log: {path}")
            parsed = parse_one(path, workload, policy, counter_schema)
            by_mode[mode].append((index, path, parsed))
        for mode, runs in by_mode.items():
            require(len(runs) == 3, f"{workload}/{mode} repetition count mismatch")
            signatures = [baseline.stable_counter_signature(item[2]) for item in runs]
            require(signatures[1:] == [signatures[0], signatures[0]],
                    f"{workload}/{mode} repetitions are not bit-exact")
        parsed_by_workload[workload] = by_mode

    workload_results: dict[str, Any] = {}
    all_directional_gain = True
    for workload, by_mode in parsed_by_workload.items():
        parent = by_mode["parent"][0][2]
        candidate = by_mode["candidate"][0][2]
        region_match_keys = (
            "start_pc", "stop_pc", "start_marker_semantics", "start_hits",
            "stop_hits", "start_retired", "stop_retired", "start_lane",
            "stop_lane", "retired_instructions", "final_schema", "final_total_hits",
        )
        for key in region_match_keys:
            require(parent["region"][key] == candidate["region"][key],
                    f"{workload} parent/candidate region mismatch: {key}")
        require(parent["retired_instructions"] == candidate["retired_instructions"],
                f"{workload} parent/candidate retired mismatch")

        cycles_delta = candidate["cycles"] - parent["cycles"]
        cpi_delta = (candidate["cycles"] / candidate["retired_instructions"]
                     - parent["cycles"] / parent["retired_instructions"])
        response_delta = (
            candidate["cpi_stack"]["memory_lifecycle"]["response_terminal"]
            - parent["cpi_stack"]["memory_lifecycle"]["response_terminal"])
        write_response_delta = (
            candidate["cpi_stack"]["memory_request_detail"]["axi_write_response"]
            - parent["cpi_stack"]["memory_request_detail"]["axi_write_response"])
        directional = cycles_delta < 0 and cpi_delta < 0
        all_directional_gain = all_directional_gain and directional
        workload_results[workload] = {
            "run_order": list(RUN_ORDER),
            "repetitions_bit_exact": True,
            "parent": summarized_run(parent, by_mode["parent"][0][1]),
            "candidate": summarized_run(candidate, by_mode["candidate"][0][1]),
            "repetitions": {
                mode: [
                    {
                        "sequence_index": index,
                        "cycles": parsed["cycles"],
                        "retired_instructions": parsed["retired_instructions"],
                        "log": artifact(path),
                    }
                    for index, path, parsed in runs
                ]
                for mode, runs in by_mode.items()
            },
            "delta_candidate_minus_parent": {
                "cycles": cycles_delta,
                "cycles_percent": cycles_delta * 100.0 / parent["cycles"],
                "cpi": cpi_delta,
                "ipc": (candidate["retired_instructions"] / candidate["cycles"]
                        - parent["retired_instructions"] / parent["cycles"]),
                "memory_response_terminal_cycles": response_delta,
                "axi_write_response_cycles": write_response_delta,
            },
            "directional_cpi_gain": directional,
        }

    decision = ("ADVANCE_TO_200MHZ_MAPPED_STA"
                if all_directional_gain else "REJECT_CANDIDATE_NO_CPI_GAIN")
    result = {
        "schema": "npc-rv64-v15p-performance-ab-result-v1",
        "status": "PASS",
        "mechanism": "lsu_axi_adapter_final_b_fallthrough",
        "identity": artifact(args.identity),
        "single_mechanism_source_difference": [ADAPTER_KEY],
        "measurement": {
            "counter_scope": "pc_bounded_region_v1",
            "run_order": list(RUN_ORDER),
            "repetitions_per_design_per_workload": 3,
            "same_binary_configuration_and_workload": True,
            "bit_exact_repetitions": True,
        },
        "workloads": workload_results,
        "decision": decision,
        "promotion_state": "PPA_PENDING" if all_directional_gain else "REJECTED",
        "claim_boundary": (
            "deterministic bare-metal PC-bounded CPI/IPC A/B; mapped timing, area, "
            "power and system recertification are not claimed"
        ),
    }
    write_json(args.output, result)
    print(
        "[V15P-PERFORMANCE-AB][PASS] "
        f"decision={decision} "
        f"coremark_delta={workload_results['coremark']['delta_candidate_minus_parent']['cycles']} "
        f"dhrystone_delta={workload_results['dhrystone_10000']['delta_candidate_minus_parent']['cycles']}"
    )


def verify_result(args: argparse.Namespace) -> None:
    value = json.loads(args.input.read_text(encoding="utf-8"))
    require(value.get("schema") == "npc-rv64-v15p-performance-ab-result-v1",
            "result schema mismatch")
    require(value.get("status") == "PASS", "result status mismatch")
    identity_record = value.get("identity", {})
    require((ROOT / identity_record["path"]).is_file(), "identity artifact missing")
    require(sha256(ROOT / identity_record["path"]) == identity_record["sha256"],
            "identity artifact hash mismatch")
    for workload in WORKLOADS:
        record = value["workloads"][workload]
        require(record["repetitions_bit_exact"] is True,
                f"{workload} repeatability missing")
        require(len(record["repetitions"]["parent"]) == 3
                and len(record["repetitions"]["candidate"]) == 3,
                f"{workload} repetition inventory mismatch")
    print(
        "[V15P-PERFORMANCE-AB-VERIFY][PASS] "
        f"decision={value['decision']}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    identity = subparsers.add_parser("identity")
    identity.add_argument("--parent-adapter", type=pathlib.Path, required=True)
    identity.add_argument("--candidate-adapter", type=pathlib.Path, required=True)
    identity.add_argument("--parent-binary", type=pathlib.Path, required=True)
    identity.add_argument("--candidate-binary", type=pathlib.Path, required=True)
    identity.add_argument("--parent-build-log", type=pathlib.Path, required=True)
    identity.add_argument("--candidate-build-log", type=pathlib.Path, required=True)
    identity.add_argument("--parent-verfiles", type=pathlib.Path, required=True)
    identity.add_argument("--candidate-verfiles", type=pathlib.Path, required=True)
    identity.add_argument("--config", type=pathlib.Path, required=True)
    identity.add_argument("--coremark-image", type=pathlib.Path, required=True)
    identity.add_argument("--dhrystone-image", type=pathlib.Path, required=True)
    identity.add_argument("--output", type=pathlib.Path, required=True)

    result = subparsers.add_parser("result")
    result.add_argument("--identity", type=pathlib.Path, required=True)
    result.add_argument("--logs-dir", type=pathlib.Path, required=True)
    result.add_argument("--output", type=pathlib.Path, required=True)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.command == "identity":
            build_identity(args)
        elif args.command == "result":
            build_result(args)
        else:
            verify_result(args)
    except (EvidenceError, baseline.BaselineError, OSError, ValueError,
            KeyError, json.JSONDecodeError) as exc:
        print(f"[V15P-PERFORMANCE-AB][FAIL] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
