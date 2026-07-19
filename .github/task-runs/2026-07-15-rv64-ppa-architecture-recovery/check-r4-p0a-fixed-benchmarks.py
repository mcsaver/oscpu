#!/usr/bin/env python3
"""P0-A CoreMark/Dhrystone ABBAAB runtime binding and result checker.

This task-local checker deliberately reuses the canonical PPA v3 raw-log
parser and policy.  It adds the experiment-level guarantees that are outside
the generic candidate-manifest checker: exact A-B-B-A-A-B ordering, one
immutable source/binary/image binding per window, and the P0-A requirement
that both selected fixed regions remain cycle-exact with R4-S0.
"""

from __future__ import annotations

import argparse
import functools
import hashlib
import json
import math
import pathlib
import re
import shlex
import subprocess
import sys
from typing import Any


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    for candidate in (start, *start.parents):
        if (candidate / ".git").exists():
            return candidate.resolve()
    raise RuntimeError("cannot locate repository root")


SCRIPT_PATH = pathlib.Path(__file__).resolve()
ROOT = find_repo_root(SCRIPT_PATH.parent)
PPA_DIR = ROOT / "npc/rv64/eval/ppa"
PPA_TOOLS = PPA_DIR / "tools"
sys.path.insert(0, str(PPA_TOOLS))
import check as ppa_check  # noqa: E402


POLICY_PATH = PPA_DIR / "policies/proxy-200mhz-v1.json"
S0_CHECKPOINT_PATH = PPA_DIR / "baselines/r4-s0-correctness-checkpoint.json"
SOURCE_INPUT_SCHEMA = "npc-rv64-sim-build-inputs-v2"
BINDING_SCHEMA = "npc-rv64-p0a-runtime-binding-v2"
RESULT_SCHEMA = "npc-rv64-p0a-abbaab-result-v2"
COMPILER_ATTESTATION_SCHEMA = "npc-rv64-cxx-object-attestation-v1"
EXPECTED_SEQUENCE = ("A", "B", "B", "A", "A", "B")
BENCHMARKS = ("coremark", "dhrystone_10000")
SHA256_RE = re.compile(r"[0-9a-f]{64}")


def fail(message: str) -> None:
    raise ValueError(message)


def read_json(path: pathlib.Path) -> dict[str, Any]:
    return ppa_check.read_json(path)


def canonical_digest(value: Any) -> str:
    encoded = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=True
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def digest(path: pathlib.Path) -> str:
    return ppa_check.digest(path)


def workspace_file(path: pathlib.Path | str) -> pathlib.Path:
    candidate = pathlib.Path(path)
    if not candidate.is_absolute():
        candidate = ROOT / candidate
    resolved = candidate.resolve(strict=True)
    if not resolved.is_file() or not resolved.is_relative_to(ROOT):
        fail(f"path is not a regular workspace file: {candidate}")
    relative = resolved.relative_to(ROOT)
    cursor = ROOT
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            fail(f"workspace input traverses a symlink: {relative.as_posix()}")
    return resolved


def workspace_output(path: pathlib.Path | str) -> pathlib.Path:
    candidate = pathlib.Path(path)
    if not candidate.is_absolute():
        candidate = ROOT / candidate
    parent = candidate.parent.resolve(strict=True)
    resolved = parent / candidate.name
    if not resolved.is_relative_to(ROOT):
        fail(f"output escapes workspace: {candidate}")
    if resolved.exists():
        fail(f"refusing stale output: {resolved}")
    return resolved


def file_record(path: pathlib.Path | str) -> dict[str, Any]:
    resolved = workspace_file(path)
    return {
        "path": str(resolved),
        "workspace_path": resolved.relative_to(ROOT).as_posix(),
        "sha256": digest(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def historical_record(
    path: pathlib.Path, expected_sha256: str, size_bytes: int
) -> dict[str, Any]:
    resolved = workspace_file(path)
    if SHA256_RE.fullmatch(expected_sha256) is None:
        fail(f"invalid historical SHA-256 for {resolved}")
    if not isinstance(size_bytes, int) or isinstance(size_bytes, bool) or size_bytes < 0:
        fail(f"invalid historical size for {resolved}")
    return {
        "path": str(resolved),
        "workspace_path": resolved.relative_to(ROOT).as_posix(),
        "sha256": expected_sha256,
        "size_bytes": size_bytes,
    }


def validate_record_shape(record: Any, label: str) -> pathlib.Path:
    if not isinstance(record, dict):
        fail(f"{label} is not a file record")
    if set(record) != {"path", "workspace_path", "sha256", "size_bytes"}:
        fail(f"{label} file record fields drifted")
    resolved = workspace_file(record["path"])
    if record["path"] != str(resolved):
        fail(f"{label} path is not canonical")
    if record["workspace_path"] != resolved.relative_to(ROOT).as_posix():
        fail(f"{label} workspace path mismatch")
    if not isinstance(record["sha256"], str) or SHA256_RE.fullmatch(
        record["sha256"]
    ) is None:
        fail(f"{label} SHA-256 is invalid")
    size = record["size_bytes"]
    if not isinstance(size, int) or isinstance(size, bool) or size < 0:
        fail(f"{label} size is invalid")
    return resolved


def validate_live_record(record: Any, label: str) -> pathlib.Path:
    resolved = validate_record_shape(record, label)
    if resolved.stat().st_size != record["size_bytes"]:
        fail(f"{label} size changed")
    if digest(resolved) != record["sha256"]:
        fail(f"{label} SHA-256 changed")
    return resolved


def write_new_json(path: pathlib.Path | str, value: Any) -> None:
    output = workspace_output(path)
    with output.open("x", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")


@functools.lru_cache(maxsize=1)
def current_rtl_inventory() -> list[pathlib.Path]:
    completed = subprocess.run(
        ["make", "-s", "-C", str(ROOT / "npc/rv64"), "print-synth-rtl"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    words = shlex.split(completed.stdout)
    if not words:
        fail("print-synth-rtl returned an empty inventory")
    paths = [workspace_file(word) for word in words]
    if len(paths) != len(set(paths)):
        fail("print-synth-rtl returned duplicate paths")
    return paths


def fixed_input_paths(binary: pathlib.Path) -> tuple[list[pathlib.Path], list[pathlib.Path]]:
    config_and_probe = [
        workspace_file(binary),
        workspace_file(ROOT / "npc/rv64/.config"),
        workspace_file(ROOT / "npc/rv64/include/config/auto.conf"),
        workspace_file(ROOT / "npc/rv64/include/generated/autoconf.h"),
        workspace_file(ROOT / "npc/rv64/vsrc/filelist.mk"),
        workspace_file(ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp"),
    ]
    rtl = current_rtl_inventory()
    return config_and_probe, rtl


def parse_sha256_manifest(path: pathlib.Path | str) -> list[tuple[str, pathlib.Path]]:
    manifest = workspace_file(path)
    rows: list[tuple[str, pathlib.Path]] = []
    seen: set[pathlib.Path] = set()
    for line_number, line in enumerate(
        manifest.read_text(encoding="utf-8").splitlines(), start=1
    ):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            fail(f"malformed SHA256SUMS row {manifest}:{line_number}")
        resolved = workspace_file(match.group(2))
        if resolved in seen:
            fail(f"duplicate SHA256SUMS path: {resolved}")
        seen.add(resolved)
        rows.append((match.group(1), resolved))
    if not rows:
        fail(f"empty SHA256SUMS manifest: {manifest}")
    return rows


def parse_verfiles(path: pathlib.Path | str) -> dict[str, Any]:
    verfiles = workspace_file(path)
    command: str | None = None
    ledger: dict[pathlib.Path, dict[str, int]] = {}
    source_re = re.compile(
        r'^S\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+'
        r'([0-9]+)\s+([0-9]+)\s+"([^"]+)"$'
    )
    for line in verfiles.read_text(encoding="utf-8").splitlines():
        if line.startswith("C "):
            if command is not None:
                fail(f"multiple command rows in {verfiles}")
            try:
                decoded = json.loads(line[2:])
            except json.JSONDecodeError as exc:
                fail(f"malformed command row in {verfiles}: {exc}")
            if not isinstance(decoded, str):
                fail(f"command row is not a string in {verfiles}")
            command = decoded
            continue
        match = source_re.fullmatch(line)
        if match is None:
            continue
        source_candidate = pathlib.Path(match.group(7)).resolve(strict=True)
        # Verilator also records its own executable/runtime sources.  They are
        # toolchain provenance, not repository build inputs, so this checker
        # keeps only workspace members and separately binds verFiles.dat.
        if not source_candidate.is_relative_to(ROOT):
            continue
        source = workspace_file(source_candidate)
        entry = {
            "size_bytes": int(match.group(1)),
            "inode": int(match.group(2)),
            "ctime_ns": int(match.group(3)) * 1_000_000_000 + int(match.group(4)),
            "mtime_ns": int(match.group(5)) * 1_000_000_000 + int(match.group(6)),
        }
        if source in ledger and ledger[source] != entry:
            fail(f"conflicting Verilator source ledger rows: {source}")
        ledger[source] = entry
    if command is None:
        fail(f"missing command row in {verfiles}")
    tokens = shlex.split(command)
    outputs = [tokens[index + 1] for index, token in enumerate(tokens[:-1]) if token == "-o"]
    if len(outputs) != 1:
        fail(f"Verilator command does not have exactly one -o: {verfiles}")
    return {
        "path": verfiles,
        "record": file_record(verfiles),
        "command": command,
        "tokens": tokens,
        "output": pathlib.Path(outputs[0]).resolve(),
        "ledger": ledger,
    }


def validate_verfiles_contract(
    parsed: dict[str, Any], binary: pathlib.Path, rtl: list[pathlib.Path]
) -> None:
    if parsed["output"] != binary:
        fail(
            f"Verilator output mismatch: ledger={parsed['output']} requested={binary}"
        )
    tokens = set(parsed["tokens"])
    missing = [str(path) for path in rtl if str(path) not in tokens]
    if missing:
        fail(f"Verilator command omits bound RTL inputs: {missing[:3]}")
    probe = workspace_file(ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp")
    if str(probe) not in tokens:
        fail("Verilator command omits the performance-probe C++ input")


def parse_compiler_depfile(
    path: pathlib.Path | str, object_name: str, source: pathlib.Path
) -> list[pathlib.Path]:
    depfile = workspace_file(path)
    logical = depfile.read_text(encoding="utf-8").replace("\\\n", " ").strip()
    target, separator, prerequisites = logical.partition(":")
    if separator != ":" or "\n" in logical:
        fail(f"compiler dependency file is not one logical rule: {depfile}")
    if shlex.split(target) != [object_name]:
        fail(f"compiler dependency target is not {object_name}: {depfile}")
    words = shlex.split(prerequisites)
    if not words:
        fail(f"compiler dependency rule has no prerequisites: {depfile}")
    resolved: list[pathlib.Path] = []
    for word in words:
        candidate = pathlib.Path(word)
        if not candidate.is_absolute():
            candidate = depfile.parent / candidate
        resolved.append(candidate.resolve(strict=True))
    if resolved[0] != source or resolved.count(source) != 1:
        fail("cpu-exec.d does not name cpu-exec.cpp as its unique first dependency")
    return resolved


def capture_compiler_dependency_attestation(
    parsed_verfiles: dict[str, Any], binary: pathlib.Path
) -> dict[str, Any]:
    source = workspace_file(ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp")
    if parsed_verfiles["tokens"].count(str(source)) != 1:
        fail("Verilator command must contain the performance-probe C++ input once")
    object_file = workspace_file(parsed_verfiles["path"].parent / "cpu-exec.o")
    depfile = workspace_file(parsed_verfiles["path"].parent / "cpu-exec.d")
    parse_compiler_depfile(depfile, object_file.name, source)

    source_stat = source.stat()
    depfile_stat = depfile.stat()
    object_stat = object_file.stat()
    binary_stat = binary.stat()
    object_earliest_ns = min(object_stat.st_ctime_ns, object_stat.st_mtime_ns)
    binary_earliest_ns = min(binary_stat.st_ctime_ns, binary_stat.st_mtime_ns)
    if max(source_stat.st_ctime_ns, source_stat.st_mtime_ns) > object_earliest_ns:
        fail("cpu-exec.cpp is newer than cpu-exec.o")
    if max(depfile_stat.st_ctime_ns, depfile_stat.st_mtime_ns) > object_earliest_ns:
        fail("cpu-exec.d is newer than cpu-exec.o")
    if max(object_stat.st_ctime_ns, object_stat.st_mtime_ns) > binary_earliest_ns:
        fail("cpu-exec.o is newer than the candidate simulator binary")

    return {
        "schema": COMPILER_ATTESTATION_SCHEMA,
        "command_token_occurrences": 1,
        "source": file_record(source),
        "dependency_file": file_record(depfile),
        "object_file": file_record(object_file),
        "binary": file_record(binary),
        "timeline_ns": {
            "source_ctime_ns": source_stat.st_ctime_ns,
            "source_mtime_ns": source_stat.st_mtime_ns,
            "dependency_file_ctime_ns": depfile_stat.st_ctime_ns,
            "dependency_file_mtime_ns": depfile_stat.st_mtime_ns,
            "object_ctime_ns": object_stat.st_ctime_ns,
            "object_mtime_ns": object_stat.st_mtime_ns,
            "binary_ctime_ns": binary_stat.st_ctime_ns,
            "binary_mtime_ns": binary_stat.st_mtime_ns,
        },
    }


def validate_compiler_dependency_attestation(
    value: Any,
    binary: pathlib.Path,
    source: pathlib.Path,
    verfiles: pathlib.Path,
) -> None:
    if not isinstance(value, dict) or set(value) != {
        "schema",
        "command_token_occurrences",
        "source",
        "dependency_file",
        "object_file",
        "binary",
        "timeline_ns",
    }:
        fail("compiler dependency attestation fields are invalid")
    if value["schema"] != COMPILER_ATTESTATION_SCHEMA:
        fail("compiler dependency attestation schema mismatch")
    if value["command_token_occurrences"] != 1:
        fail("compiler dependency command-token count mismatch")
    if validate_live_record(value["source"], "compiler C++ source") != source:
        fail("compiler dependency source is not cpu-exec.cpp")
    if validate_live_record(value["binary"], "compiler-linked binary") != binary:
        fail("compiler dependency binary mismatch")
    depfile = validate_live_record(value["dependency_file"], "compiler depfile")
    object_file = validate_live_record(value["object_file"], "compiler object")
    expected_dir = verfiles.parent
    if depfile != expected_dir / "cpu-exec.d":
        fail("compiler depfile is not adjacent to VNpcSimTop__verFiles.dat")
    if object_file != expected_dir / "cpu-exec.o":
        fail("compiler object is not adjacent to VNpcSimTop__verFiles.dat")

    parsed = parse_verfiles(verfiles)
    if parsed["output"] != binary or parsed["tokens"].count(str(source)) != 1:
        fail("Verilator command no longer binds cpu-exec.cpp to the candidate binary")
    parse_compiler_depfile(depfile, object_file.name, source)
    source_stat = source.stat()
    depfile_stat = depfile.stat()
    object_stat = object_file.stat()
    binary_stat = binary.stat()
    expected_timeline = {
        "source_ctime_ns": source_stat.st_ctime_ns,
        "source_mtime_ns": source_stat.st_mtime_ns,
        "dependency_file_ctime_ns": depfile_stat.st_ctime_ns,
        "dependency_file_mtime_ns": depfile_stat.st_mtime_ns,
        "object_ctime_ns": object_stat.st_ctime_ns,
        "object_mtime_ns": object_stat.st_mtime_ns,
        "binary_ctime_ns": binary_stat.st_ctime_ns,
        "binary_mtime_ns": binary_stat.st_mtime_ns,
    }
    if value["timeline_ns"] != expected_timeline:
        fail("compiler dependency timeline changed")
    object_earliest_ns = min(object_stat.st_ctime_ns, object_stat.st_mtime_ns)
    binary_earliest_ns = min(binary_stat.st_ctime_ns, binary_stat.st_mtime_ns)
    if max(source_stat.st_ctime_ns, source_stat.st_mtime_ns) > object_earliest_ns:
        fail("cpu-exec.cpp is newer than cpu-exec.o")
    if max(depfile_stat.st_ctime_ns, depfile_stat.st_mtime_ns) > object_earliest_ns:
        fail("cpu-exec.d is newer than cpu-exec.o")
    if max(object_stat.st_ctime_ns, object_stat.st_mtime_ns) > binary_earliest_ns:
        fail("cpu-exec.o is newer than the candidate simulator binary")


def classify_records(
    entries: list[dict[str, Any]], binary: pathlib.Path, rtl: list[pathlib.Path]
) -> dict[str, Any]:
    by_path = {pathlib.Path(item["path"]): item for item in entries}
    configs = [
        ROOT / "npc/rv64/.config",
        ROOT / "npc/rv64/include/config/auto.conf",
        ROOT / "npc/rv64/include/generated/autoconf.h",
    ]
    filelist = ROOT / "npc/rv64/vsrc/filelist.mk"
    probe = ROOT / "npc/rv64/csrc/cpu/cpu-exec.cpp"
    expected = [binary, *configs, filelist, probe, *rtl]
    if list(by_path) != expected:
        fail("source-input record inventory/order does not match the fixed build contract")
    return {
        "binary": by_path[binary],
        "config": [by_path[path] for path in configs],
        "filelist": by_path[filelist],
        "performance_probe": by_path[probe],
        "rtl": [by_path[path] for path in rtl],
    }


def source_content_id(inputs: dict[str, Any]) -> str:
    return canonical_digest(
        {
            "config": inputs["config"],
            "filelist": inputs["filelist"],
            "performance_probe": inputs["performance_probe"],
            "rtl": inputs["rtl"],
        }
    )


def normalize_historical_inputs(
    binary_path: pathlib.Path | str,
    pre_manifest_path: pathlib.Path | str,
    post_manifest_path: pathlib.Path | str,
    verfiles_path: pathlib.Path | str,
) -> dict[str, Any]:
    binary = workspace_file(binary_path)
    pre_manifest = workspace_file(pre_manifest_path)
    post_manifest = workspace_file(post_manifest_path)
    if pre_manifest.read_bytes() != post_manifest.read_bytes():
        fail("R4-S0 historical pre/post source bindings are not byte-identical")
    rows = parse_sha256_manifest(pre_manifest)
    fixed, rtl = fixed_input_paths(binary)
    expected_paths = [*fixed, *rtl]
    if [path for _, path in rows] != expected_paths:
        fail("R4-S0 historical source manifest inventory drifted")
    parsed_verfiles = parse_verfiles(verfiles_path)
    validate_verfiles_contract(parsed_verfiles, binary, rtl)
    entries: list[dict[str, Any]] = []
    for expected_sha, path in rows:
        if path == binary:
            if digest(binary) != expected_sha:
                fail("R4-S0 binary no longer matches its historical source manifest")
            size = binary.stat().st_size
        elif path in parsed_verfiles["ledger"]:
            size = parsed_verfiles["ledger"][path]["size_bytes"]
        elif digest(path) == expected_sha:
            size = path.stat().st_size
        else:
            fail(f"historical build-time size is unavailable for {path}")
        entries.append(historical_record(path, expected_sha, size))
    inputs = classify_records(entries, binary, rtl)
    document = {
        "schema": SOURCE_INPUT_SCHEMA,
        "capture_mode": "historical_build_attestation",
        "live_validation_required": False,
        "compiler_dependency_attestation": None,
        "inputs": inputs,
        "input_content_id": source_content_id(inputs),
        "rtl_count": len(rtl),
        "verilator_build": {
            "output_binary_path": str(binary),
            "verfiles": parsed_verfiles["record"],
        },
        "provenance_artifacts": [
            file_record(pre_manifest),
            file_record(post_manifest),
            parsed_verfiles["record"],
        ],
    }
    validate_source_document(document)
    return document


def capture_live_inputs(
    binary_path: pathlib.Path | str, verfiles_path: pathlib.Path | str
) -> dict[str, Any]:
    binary = workspace_file(binary_path)
    if not binary.stat().st_mode & 0o111:
        fail(f"candidate binary is not executable: {binary}")
    fixed, rtl = fixed_input_paths(binary)
    parsed_verfiles = parse_verfiles(verfiles_path)
    validate_verfiles_contract(parsed_verfiles, binary, rtl)
    for source in rtl:
        ledger = parsed_verfiles["ledger"].get(source)
        if ledger is None:
            fail(f"candidate Verilator ledger omits build input: {source}")
        stat = source.stat()
        if (
            stat.st_size != ledger["size_bytes"]
            or stat.st_ino != ledger["inode"]
            or stat.st_ctime_ns != ledger["ctime_ns"]
            or stat.st_mtime_ns != ledger["mtime_ns"]
        ):
            fail(f"candidate source changed after Verilator captured it: {source}")
    compiler_attestation = capture_compiler_dependency_attestation(
        parsed_verfiles, binary
    )
    entries = [file_record(path) for path in [*fixed, *rtl]]
    inputs = classify_records(entries, binary, rtl)
    document = {
        "schema": SOURCE_INPUT_SCHEMA,
        "capture_mode": "live_build_inputs",
        "live_validation_required": True,
        "compiler_dependency_attestation": compiler_attestation,
        "inputs": inputs,
        "input_content_id": source_content_id(inputs),
        "rtl_count": len(rtl),
        "verilator_build": {
            "output_binary_path": str(binary),
            "verfiles": parsed_verfiles["record"],
        },
        "provenance_artifacts": [
            parsed_verfiles["record"],
            compiler_attestation["dependency_file"],
            compiler_attestation["object_file"],
        ],
    }
    validate_source_document(document)
    return document


def flattened_input_records(inputs: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        inputs["binary"],
        *inputs["config"],
        inputs["filelist"],
        inputs["performance_probe"],
        *inputs["rtl"],
    ]


def validate_source_document(document: Any) -> None:
    if not isinstance(document, dict) or document.get("schema") != SOURCE_INPUT_SCHEMA:
        fail("source-input document schema mismatch")
    mode = document.get("capture_mode")
    if mode not in {"historical_build_attestation", "live_build_inputs"}:
        fail("source-input capture mode is invalid")
    expected_live = mode == "live_build_inputs"
    if document.get("live_validation_required") is not expected_live:
        fail("source-input live-validation flag mismatch")
    compiler_attestation = document.get("compiler_dependency_attestation")
    if expected_live and compiler_attestation is None:
        fail("live source-input document lacks compiler dependency attestation")
    if not expected_live and compiler_attestation is not None:
        fail("historical source-input document must not claim live compiler evidence")
    inputs = document.get("inputs")
    if not isinstance(inputs, dict) or set(inputs) != {
        "binary",
        "config",
        "filelist",
        "performance_probe",
        "rtl",
    }:
        fail("source-input role inventory is invalid")
    if not isinstance(inputs["config"], list) or len(inputs["config"]) != 3:
        fail("source-input config inventory is invalid")
    if not isinstance(inputs["rtl"], list) or not inputs["rtl"]:
        fail("source-input RTL inventory is invalid")
    records = flattened_input_records(inputs)
    paths: list[pathlib.Path] = []
    for index, record in enumerate(records):
        path = validate_record_shape(record, f"source input {index}")
        paths.append(path)
        if expected_live or index == 0:
            validate_live_record(record, f"source input {index}")
    if len(paths) != len(set(paths)):
        fail("source-input document contains duplicate paths")
    binary = pathlib.Path(inputs["binary"]["path"])
    fixed, rtl = fixed_input_paths(binary)
    if paths != [*fixed, *rtl]:
        fail("source-input role/path inventory drifted from print-synth-rtl")
    if document.get("rtl_count") != len(inputs["rtl"]):
        fail("source-input RTL count mismatch")
    if document.get("input_content_id") != source_content_id(inputs):
        fail("source-input content identity mismatch")
    build = document.get("verilator_build")
    if not isinstance(build, dict) or set(build) != {
        "output_binary_path",
        "verfiles",
    }:
        fail("Verilator build binding is invalid")
    if build["output_binary_path"] != str(binary):
        fail("Verilator build output does not match the bound binary")
    verfiles = validate_live_record(build["verfiles"], "Verilator build ledger")
    if expected_live:
        validate_compiler_dependency_attestation(
            compiler_attestation,
            binary,
            pathlib.Path(inputs["performance_probe"]["path"]),
            verfiles,
        )
    provenance = document.get("provenance_artifacts")
    if not isinstance(provenance, list) or not provenance:
        fail("source-input provenance is missing")
    for index, record in enumerate(provenance):
        validate_live_record(record, f"source provenance {index}")


def load_policy_contract() -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    policy = read_json(POLICY_PATH)
    evidence = policy.get("performance_evidence")
    if not isinstance(evidence, dict):
        fail("PPA performance-evidence policy is missing")
    if evidence.get("schema") != "npc-rv64-performance-evidence-v3":
        fail("PPA policy no longer selects performance evidence v3")
    if evidence.get("minimum_repetitions") != 3:
        fail("PPA policy repetition count drifted from three")
    if evidence.get("require_bit_exact_repetition_counters") is not True:
        fail("PPA policy no longer requires bit-exact repetitions")
    contracts = evidence.get("benchmark_contracts")
    if not isinstance(contracts, dict) or set(contracts) != set(BENCHMARKS):
        fail("PPA benchmark-contract inventory drifted")
    for benchmark in BENCHMARKS:
        errors = ppa_check.policy_region_contract_errors(
            benchmark, contracts[benchmark]
        )
        if errors:
            fail("; ".join(errors))
        if contracts[benchmark].get("counter_scope") != "pc_bounded_region_v1":
            fail(f"{benchmark} is no longer a fixed-PC region contract")
    return policy, contracts


def checkpoint_counters() -> dict[str, dict[str, int]]:
    checkpoint = read_json(S0_CHECKPOINT_PATH)
    performance = checkpoint.get("performance")
    if not isinstance(performance, dict):
        fail("R4-S0 checkpoint performance section is missing")
    if performance.get("counter_scope") != "pc_bounded_region_v1":
        fail("R4-S0 checkpoint counter scope drifted")
    items = performance.get("benchmarks")
    if not isinstance(items, list):
        fail("R4-S0 checkpoint benchmark list is missing")
    result: dict[str, dict[str, int]] = {}
    for item in items:
        if not isinstance(item, dict) or item.get("name") not in BENCHMARKS:
            fail("R4-S0 checkpoint benchmark entry is invalid")
        cycles = item.get("cycles")
        retired = item.get("retired_instructions")
        if not ppa_check.strict_positive_int(cycles) or not ppa_check.strict_positive_int(retired):
            fail("R4-S0 checkpoint counters are invalid")
        result[item["name"]] = {"cycles": cycles, "retired_instructions": retired}
    if set(result) != set(BENCHMARKS):
        fail("R4-S0 checkpoint benchmark inventory drifted")
    return result


def checkpoint_images() -> dict[str, dict[str, Any]]:
    checkpoint = read_json(S0_CHECKPOINT_PATH)
    performance = checkpoint.get("performance")
    inventory = (
        performance.get("posthoc_current_image_inventory")
        if isinstance(performance, dict)
        else None
    )
    if not isinstance(inventory, dict):
        fail("R4-S0 checkpoint fixed-image inventory is missing")
    result: dict[str, dict[str, Any]] = {}
    for benchmark in BENCHMARKS:
        item = inventory.get(benchmark)
        if not isinstance(item, dict):
            fail(f"R4-S0 checkpoint image entry is missing: {benchmark}")
        path = workspace_file(item.get("path"))
        expected = {
            "path": str(path),
            "workspace_path": path.relative_to(ROOT).as_posix(),
            "sha256": item.get("sha256"),
            "size_bytes": item.get("size_bytes"),
        }
        validate_record_shape(expected, f"R4-S0 {benchmark} fixed image")
        result[benchmark] = expected
    return result


def benchmark_contract(benchmark: str) -> dict[str, Any]:
    if benchmark not in BENCHMARKS:
        fail(f"unsupported benchmark: {benchmark}")
    _, contracts = load_policy_contract()
    counters = checkpoint_counters()[benchmark]
    contract = contracts[benchmark]
    return {
        "benchmark": benchmark,
        "counter_scope": contract["counter_scope"],
        "start_pc": contract["region"]["start_pc"],
        "stop_pc": contract["region"]["stop_pc"],
        "fixed_image": checkpoint_images()[benchmark],
        **counters,
    }


def validate_semantics(parsed: dict[str, Any], benchmark: str) -> None:
    policy, _ = load_policy_contract()
    functional = policy["functional"]
    if parsed.get("pass") is not True or parsed.get("good_trap_count") != 1:
        fail(f"{benchmark} did not produce exactly one GOOD TRAP")
    if parsed.get("exit_code") != 0:
        fail(f"{benchmark} simulator exit record is nonzero")
    if benchmark == "coremark":
        if parsed.get("iterations") != functional["coremark_iterations"]:
            fail("CoreMark iteration count mismatch")
        if parsed.get("crc") != functional["coremark_crc"]:
            fail("CoreMark CRC mismatch")
    else:
        if parsed.get("runs") != functional["dhrystone_runs"]:
            fail("Dhrystone run count mismatch")


def parse_and_validate_log(
    path: pathlib.Path | str,
    benchmark: str,
    expected_cycles: int | None = None,
    expected_retired: int | None = None,
) -> dict[str, Any]:
    log = workspace_file(path)
    _, contracts = load_policy_contract()
    contract = contracts[benchmark]
    parsed = ppa_check.parse_raw_benchmark_log(
        log,
        benchmark,
        contract["counter_scope"],
        contract,
    )
    validate_semantics(parsed, benchmark)
    if expected_cycles is not None and parsed["cycles"] != expected_cycles:
        fail(
            f"{benchmark} fixed-region cycles drifted: "
            f"expected={expected_cycles} actual={parsed['cycles']}"
        )
    if expected_retired is not None and parsed["retired_instructions"] != expected_retired:
        fail(
            f"{benchmark} fixed-region retired count drifted: "
            f"expected={expected_retired} actual={parsed['retired_instructions']}"
        )
    return parsed


def build_runtime_binding(
    design: str,
    ordinal: int,
    benchmark: str,
    binary_path: pathlib.Path | str,
    image_path: pathlib.Path | str,
    source_inputs_path: pathlib.Path | str,
    runner_path: pathlib.Path | str,
    timeout_seconds: int,
    max_cycles: int,
) -> dict[str, Any]:
    if ordinal < 1 or ordinal > len(EXPECTED_SEQUENCE):
        fail("ABBAAB ordinal is outside 1..6")
    if design != EXPECTED_SEQUENCE[ordinal - 1]:
        fail("design does not match the fixed A-B-B-A-A-B sequence")
    if benchmark not in BENCHMARKS:
        fail(f"unsupported benchmark: {benchmark}")
    if timeout_seconds <= 0 or max_cycles <= 0:
        fail("runtime bounds must be positive")
    source_path = workspace_file(source_inputs_path)
    source_document = read_json(source_path)
    validate_source_document(source_document)
    binary = workspace_file(binary_path)
    if source_document["inputs"]["binary"]["path"] != str(binary):
        fail("runtime binary does not match its source-input document")
    contract = benchmark_contract(benchmark)
    policy_record = file_record(POLICY_PATH)
    parser_record = file_record(PPA_TOOLS / "check.py")
    validator_record = file_record(SCRIPT_PATH)
    runner_record = file_record(runner_path)
    image_record = file_record(image_path)
    if image_record != contract["fixed_image"]:
        fail(f"{benchmark} image does not match the R4-S0 fixed image")
    source_record = file_record(source_path)
    design_id = canonical_digest(
        {
            "binary": source_document["inputs"]["binary"],
            "input_content_id": source_document["input_content_id"],
        }
    )
    return {
        "schema": BINDING_SCHEMA,
        "sequence": list(EXPECTED_SEQUENCE),
        "ordinal": ordinal,
        "design": design,
        "benchmark": benchmark,
        "design_id": f"sha256:{design_id}",
        "binary": file_record(binary),
        "image": image_record,
        "source_inputs_file": source_record,
        "source_inputs": source_document,
        "contract": contract,
        "runtime": {
            "timeout_seconds": timeout_seconds,
            "max_cycles": max_cycles,
            "arguments": [str(binary), str(workspace_file(image_path)), "--no-progress", "--max-cycles", str(max_cycles)],
            "environment": {
                "NPC_REGION_START_PC": contract["start_pc"],
                "NPC_REGION_END_PC": contract["stop_pc"],
            },
        },
        "tooling": {
            "policy": policy_record,
            "canonical_parser": parser_record,
            "task_validator": validator_record,
            "runner": runner_record,
            "s0_checkpoint": file_record(S0_CHECKPOINT_PATH),
        },
    }


def validate_binding_snapshot(
    snapshot: dict[str, Any], ordinal: int, design: str, benchmark: str
) -> None:
    if snapshot.get("schema") != BINDING_SCHEMA:
        fail("runtime binding schema mismatch")
    if snapshot.get("sequence") != list(EXPECTED_SEQUENCE):
        fail("runtime binding sequence drifted")
    if snapshot.get("ordinal") != ordinal or snapshot.get("design") != design:
        fail("runtime binding window identity mismatch")
    if snapshot.get("benchmark") != benchmark:
        fail("runtime binding benchmark mismatch")
    source_document = snapshot.get("source_inputs")
    validate_source_document(source_document)
    source_path = validate_live_record(
        snapshot.get("source_inputs_file"), "source-input document"
    )
    if read_json(source_path) != source_document:
        fail("embedded source-input document differs from the bound file")
    binary = validate_live_record(snapshot.get("binary"), "runtime binary")
    if source_document["inputs"]["binary"] != snapshot["binary"]:
        fail("runtime binary record differs from source-input binary record")
    validate_live_record(snapshot.get("image"), "benchmark image")
    tooling = snapshot.get("tooling")
    if not isinstance(tooling, dict) or set(tooling) != {
        "policy",
        "canonical_parser",
        "task_validator",
        "runner",
        "s0_checkpoint",
    }:
        fail("runtime tooling binding is invalid")
    for key, record in tooling.items():
        validate_live_record(record, f"runtime tooling {key}")
    if snapshot.get("contract") != benchmark_contract(benchmark):
        fail("runtime fixed-region contract drifted")
    if snapshot.get("image") != snapshot["contract"]["fixed_image"]:
        fail("runtime image is not the contract-selected fixed image")
    runtime = snapshot.get("runtime")
    if not isinstance(runtime, dict) or set(runtime) != {
        "timeout_seconds",
        "max_cycles",
        "arguments",
        "environment",
    }:
        fail("runtime command contract is missing")
    if runtime.get("timeout_seconds", 0) <= 0 or runtime.get("max_cycles", 0) <= 0:
        fail("runtime bounds are invalid")
    expected_arguments = [
        str(binary),
        snapshot["image"]["path"],
        "--no-progress",
        "--max-cycles",
        str(runtime["max_cycles"]),
    ]
    if runtime.get("arguments") != expected_arguments:
        fail("runtime argument contract mismatch")
    if runtime.get("environment") != {
        "NPC_REGION_START_PC": snapshot["contract"]["start_pc"],
        "NPC_REGION_END_PC": snapshot["contract"]["stop_pc"],
    }:
        fail("runtime region environment contract mismatch")
    expected_design_id = canonical_digest(
        {
            "binary": source_document["inputs"]["binary"],
            "input_content_id": source_document["input_content_id"],
        }
    )
    if snapshot.get("design_id") != f"sha256:{expected_design_id}":
        fail("runtime design identity mismatch")
    if snapshot["binary"]["path"] != str(binary):
        fail("runtime binary path is not canonical")


def validate_measurement_matrix(
    rows: list[dict[str, Any]],
    benchmark: str,
    expected: dict[str, int],
    minimum_ratio: float,
    require_cycle_exact: bool,
) -> dict[str, Any]:
    if len(rows) != 6:
        fail(f"{benchmark} does not have six ABBAAB windows")
    if [row.get("design") for row in rows] != list(EXPECTED_SEQUENCE):
        fail(f"{benchmark} window ordering is not A-B-B-A-A-B")
    per_design: dict[str, list[tuple[int, int]]] = {"A": [], "B": []}
    for row in rows:
        cycles = row.get("cycles")
        retired = row.get("retired_instructions")
        if not ppa_check.strict_positive_int(cycles) or not ppa_check.strict_positive_int(retired):
            fail(f"{benchmark} contains invalid selected counters")
        per_design[row["design"]].append((cycles, retired))
    if len(per_design["A"]) != 3 or len(per_design["B"]) != 3:
        fail(f"{benchmark} does not have three repetitions per design")
    for design in ("A", "B"):
        if len(set(per_design[design])) != 1:
            fail(f"{benchmark} {design} selected counters are not bit-exact")
    baseline_cycles, baseline_retired = per_design["A"][0]
    candidate_cycles, candidate_retired = per_design["B"][0]
    if (baseline_cycles, baseline_retired) != (
        expected["cycles"],
        expected["retired_instructions"],
    ):
        fail(f"{benchmark} A counters do not match the R4-S0 checkpoint")
    if candidate_retired != baseline_retired:
        fail(f"{benchmark} fixed-image A/B retired counts differ")
    if require_cycle_exact and candidate_cycles != baseline_cycles:
        fail(f"{benchmark} P0-A fixed-region cycles are not cycle-exact")
    ratio = (candidate_retired / candidate_cycles) / (
        baseline_retired / baseline_cycles
    )
    if not math.isfinite(ratio) or ratio < minimum_ratio:
        fail(
            f"{benchmark} candidate throughput ratio is below policy: "
            f"{ratio:.12f} < {minimum_ratio:.12f}"
        )
    return {
        "baseline": {
            "cycles": baseline_cycles,
            "retired_instructions": baseline_retired,
            "cpi": baseline_cycles / baseline_retired,
        },
        "candidate": {
            "cycles": candidate_cycles,
            "retired_instructions": candidate_retired,
            "cpi": candidate_cycles / candidate_retired,
        },
        "candidate_throughput_ratio": ratio,
        "repetitions_per_design": 3,
        "bit_exact_per_design": True,
        "candidate_cycle_exact_with_s0": candidate_cycles == baseline_cycles,
    }


def validate_source_pair(
    baseline_path: pathlib.Path | str, candidate_path: pathlib.Path | str
) -> dict[str, str]:
    baseline = read_json(workspace_file(baseline_path))
    candidate = read_json(workspace_file(candidate_path))
    validate_source_document(baseline)
    validate_source_document(candidate)
    if baseline["capture_mode"] != "historical_build_attestation":
        fail("baseline source inputs are not the R4-S0 build attestation")
    if candidate["capture_mode"] != "live_build_inputs":
        fail("candidate source inputs are not a live fresh-build capture")
    if baseline["input_content_id"] == candidate["input_content_id"]:
        fail("candidate config/RTL/probe inputs are identical to R4-S0")
    return {
        "baseline_input_content_id": baseline["input_content_id"],
        "candidate_input_content_id": candidate["input_content_id"],
    }


def validate_runset(
    evidence_dir: pathlib.Path | str, require_cycle_exact: bool
) -> dict[str, Any]:
    evidence = pathlib.Path(evidence_dir)
    if not evidence.is_absolute():
        evidence = ROOT / evidence
    evidence = evidence.resolve(strict=True)
    if not evidence.is_dir() or not evidence.is_relative_to(ROOT):
        fail("evidence directory is not a workspace directory")
    policy, _ = load_policy_contract()
    minimum_ratio = policy["promotion"]["minimum_per_benchmark_ratio"]
    expected_counters = checkpoint_counters()
    design_ids: dict[str, set[str]] = {"A": set(), "B": set()}
    input_content_ids: dict[str, set[str]] = {"A": set(), "B": set()}
    tooling_ids: set[str] = set()
    summary_workloads: dict[str, Any] = {}
    raw_log_paths: set[pathlib.Path] = set()
    for benchmark in BENCHMARKS:
        rows: list[dict[str, Any]] = []
        image_records: list[dict[str, Any]] = []
        windows: list[dict[str, Any]] = []
        for ordinal, design in enumerate(EXPECTED_SEQUENCE, start=1):
            destination = evidence / benchmark / f"{ordinal:02d}-{design.lower()}"
            if not destination.is_dir():
                fail(f"missing ABBAAB window directory: {destination}")
            exit_status = workspace_file(destination / "run.exit-status.txt")
            if exit_status.read_text(encoding="utf-8") != "0\n":
                fail(f"nonzero or malformed process exit status: {exit_status}")
            pre_path = workspace_file(destination / "binding.pre.json")
            post_path = workspace_file(destination / "binding.post.json")
            if pre_path.read_bytes() != post_path.read_bytes():
                fail(f"runtime binding changed within window: {destination}")
            snapshot = read_json(pre_path)
            validate_binding_snapshot(snapshot, ordinal, design, benchmark)
            design_ids[design].add(snapshot["design_id"])
            input_content_ids[design].add(
                snapshot["source_inputs"]["input_content_id"]
            )
            tooling_ids.add(canonical_digest(snapshot["tooling"]))
            image_records.append(snapshot["image"])
            log = workspace_file(destination / "raw.log")
            if log in raw_log_paths:
                fail("raw-log path was reused by multiple repetitions")
            raw_log_paths.add(log)
            parsed = parse_and_validate_log(log, benchmark)
            parsed_path = workspace_file(destination / "parsed.json")
            if read_json(parsed_path) != parsed:
                fail(f"saved parsed result differs from canonical reparse: {parsed_path}")
            rows.append(
                {
                    "ordinal": ordinal,
                    "design": design,
                    "cycles": parsed["cycles"],
                    "retired_instructions": parsed["retired_instructions"],
                }
            )
            windows.append(
                {
                    "ordinal": ordinal,
                    "design": design,
                    "raw_log": file_record(log),
                    "binding": file_record(pre_path),
                    "parsed": file_record(parsed_path),
                    "whole_program": parsed["whole_program"],
                    "post_region": parsed["post_region"],
                }
            )
        if any(record != image_records[0] for record in image_records[1:]):
            fail(f"{benchmark} image identity changed between windows")
        measurement = validate_measurement_matrix(
            rows,
            benchmark,
            expected_counters[benchmark],
            minimum_ratio,
            require_cycle_exact,
        )
        summary_workloads[benchmark] = {
            "counter_scope": "pc_bounded_region_v1",
            "contract": benchmark_contract(benchmark),
            "image": image_records[0],
            "measurement": measurement,
            "windows": windows,
        }
    for design in ("A", "B"):
        if len(design_ids[design]) != 1:
            fail(f"design {design} identity changed between workload windows")
        if len(input_content_ids[design]) != 1:
            fail(f"design {design} source identity changed between windows")
    if input_content_ids["A"] == input_content_ids["B"]:
        fail("candidate source inputs are identical to the R4-S0 baseline")
    if len(tooling_ids) != 1:
        fail("policy/parser/runner tooling changed between windows")
    qualified_mhz = policy["timing"]["qualified_mhz"]
    candidate_benchmarks: list[dict[str, Any]] = []
    candidate_raw_artifacts: list[dict[str, Any]] = []
    weighted_log = 0.0
    for benchmark in BENCHMARKS:
        workload = summary_workloads[benchmark]
        measurement = workload["measurement"]["candidate"]
        cycles = measurement["cycles"]
        retired = measurement["retired_instructions"]
        cpi = cycles / retired
        ipc = retired / cycles
        throughput = qualified_mhz * ipc
        raw_kinds = policy["performance_evidence"]["benchmark_contracts"][benchmark][
            "raw_log_artifact_kinds"
        ]
        candidate_windows = [
            window for window in workload["windows"] if window["design"] == "B"
        ]
        if len(candidate_windows) != len(raw_kinds):
            fail(f"{benchmark} candidate raw-log inventory is incomplete")
        repetitions = []
        for kind, window in zip(raw_kinds, candidate_windows, strict=True):
            raw_record = window["raw_log"]
            repetitions.append(
                {
                    "cycles": cycles,
                    "retired_instructions": retired,
                    "counter_scope": "pc_bounded_region_v1",
                    "raw_log_artifact_kind": kind,
                    "raw_log_artifact_path": raw_record["workspace_path"],
                }
            )
            candidate_raw_artifacts.append({"kind": kind, **raw_record})
        candidate_benchmarks.append(
            {
                "name": benchmark,
                "counter_scope": "pc_bounded_region_v1",
                "cycles": cycles,
                "retired_instructions": retired,
                "cpi": cpi,
                "ipc": ipc,
                "throughput_mips": throughput,
                "repetitions": repetitions,
            }
        )
        weighted_log += policy["benchmarks"][benchmark] * math.log(throughput)
    candidate_fragment = {
        "evidence_schema": "npc-rv64-performance-evidence-v3",
        "qualified_mhz": qualified_mhz,
        "benchmarks": candidate_benchmarks,
        "weighted_throughput_mips": math.exp(weighted_log),
    }
    return {
        "schema": RESULT_SCHEMA,
        "result": "PASS",
        "performance_evidence_schema": "npc-rv64-performance-evidence-v3",
        "sequence": list(EXPECTED_SEQUENCE),
        "candidate_cycle_exact_required": require_cycle_exact,
        "policy": file_record(POLICY_PATH),
        "canonical_parser": file_record(PPA_TOOLS / "check.py"),
        "s0_checkpoint": file_record(S0_CHECKPOINT_PATH),
        "design_ids": {
            design: next(iter(values)) for design, values in design_ids.items()
        },
        "source_input_content_ids": {
            design: next(iter(values))
            for design, values in input_content_ids.items()
        },
        "candidate_performance_manifest_fragment": candidate_fragment,
        "candidate_raw_log_artifacts": candidate_raw_artifacts,
        "workloads": summary_workloads,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    normalize = subparsers.add_parser("normalize-historical")
    normalize.add_argument("--binary", required=True, type=pathlib.Path)
    normalize.add_argument("--pre-manifest", required=True, type=pathlib.Path)
    normalize.add_argument("--post-manifest", required=True, type=pathlib.Path)
    normalize.add_argument("--verfiles", required=True, type=pathlib.Path)
    normalize.add_argument("--output", required=True, type=pathlib.Path)

    capture = subparsers.add_parser("capture-live")
    capture.add_argument("--binary", required=True, type=pathlib.Path)
    capture.add_argument("--verfiles", required=True, type=pathlib.Path)
    capture.add_argument("--output", required=True, type=pathlib.Path)

    compare_inputs = subparsers.add_parser("compare-inputs")
    compare_inputs.add_argument("--baseline", required=True, type=pathlib.Path)
    compare_inputs.add_argument("--candidate", required=True, type=pathlib.Path)

    contract = subparsers.add_parser("contract")
    contract.add_argument("benchmark", choices=BENCHMARKS)

    snapshot = subparsers.add_parser("snapshot")
    snapshot.add_argument("--design", required=True, choices=("A", "B"))
    snapshot.add_argument("--ordinal", required=True, type=int)
    snapshot.add_argument("--benchmark", required=True, choices=BENCHMARKS)
    snapshot.add_argument("--binary", required=True, type=pathlib.Path)
    snapshot.add_argument("--image", required=True, type=pathlib.Path)
    snapshot.add_argument("--source-inputs", required=True, type=pathlib.Path)
    snapshot.add_argument("--runner", required=True, type=pathlib.Path)
    snapshot.add_argument("--timeout-seconds", required=True, type=int)
    snapshot.add_argument("--max-cycles", required=True, type=int)
    snapshot.add_argument("--output", required=True, type=pathlib.Path)

    validate_log = subparsers.add_parser("validate-log")
    validate_log.add_argument("--log", required=True, type=pathlib.Path)
    validate_log.add_argument("--benchmark", required=True, choices=BENCHMARKS)
    validate_log.add_argument("--expected-cycles", required=True, type=int)
    validate_log.add_argument("--expected-retired", required=True, type=int)
    validate_log.add_argument("--output", required=True, type=pathlib.Path)

    validate = subparsers.add_parser("validate-runset")
    validate.add_argument("--evidence-dir", required=True, type=pathlib.Path)
    validate.add_argument("--output", required=True, type=pathlib.Path)
    validate.add_argument("--require-cycle-exact", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "normalize-historical":
            value = normalize_historical_inputs(
                args.binary,
                args.pre_manifest,
                args.post_manifest,
                args.verfiles,
            )
            write_new_json(args.output, value)
        elif args.command == "capture-live":
            value = capture_live_inputs(args.binary, args.verfiles)
            write_new_json(args.output, value)
        elif args.command == "compare-inputs":
            value = validate_source_pair(args.baseline, args.candidate)
            print(json.dumps(value, sort_keys=True))
        elif args.command == "contract":
            value = benchmark_contract(args.benchmark)
            print(
                value["start_pc"],
                value["stop_pc"],
                value["cycles"],
                value["retired_instructions"],
                sep="\t",
            )
        elif args.command == "snapshot":
            value = build_runtime_binding(
                args.design,
                args.ordinal,
                args.benchmark,
                args.binary,
                args.image,
                args.source_inputs,
                args.runner,
                args.timeout_seconds,
                args.max_cycles,
            )
            write_new_json(args.output, value)
        elif args.command == "validate-log":
            value = parse_and_validate_log(
                args.log,
                args.benchmark,
                args.expected_cycles,
                args.expected_retired,
            )
            write_new_json(args.output, value)
        elif args.command == "validate-runset":
            value = validate_runset(args.evidence_dir, args.require_cycle_exact)
            write_new_json(args.output, value)
        else:
            fail(f"unsupported command: {args.command}")
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"[P0A-ABBAAB-CHECK] ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
