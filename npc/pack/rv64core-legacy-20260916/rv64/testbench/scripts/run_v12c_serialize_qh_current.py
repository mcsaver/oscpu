#!/usr/bin/env python3
"""生成当前设计的 queue-head CSR C0/C1/C2 序列化证据。"""

from __future__ import annotations

import argparse
import hashlib
import json
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence


SCHEMA = "npc-rv64-v12c-serialize-qh-current-evidence-v1"
TEST = "tb_ooo_core_top_glue_v9o_csr_qh"
TEST_TOP = "tb_ooo_core_top_glue"
TB_REL = "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv"
APPLY_REL = "npc/rv64/vsrc/control/OooControlEventApplySequencer.v"
ROB_REL = "npc/rv64/vsrc/writeback/OooRob.v"
CSR_GLUE_REL = "npc/rv64/testbench/common/tb_ooo_core_top_glue_csr.svh"
DEFINE_REL = "npc/rv64/vsrc/include/define.v"
PRODUCT_MANIFEST_REL = "npc/rv64/configs/product-rtl-defaults.mk"
MAKEFILE_REL = "npc/rv64/testbench/Makefile"
FILELIST_REL = "npc/rv64/vsrc/filelist.mk"

COMMITTED_LABELS = (
    "ecall handler queue-head CSR",
    "older-store queue-head CSR",
    "CSR/JALR callback chain",
)
KILLED_LABELS = (
    "branch-recovery wrong-path CSR",
    "JALR-recovery wrong-path CSR",
)


class EvidenceError(RuntimeError):
    """证据不完整或行为与冻结合同不一致。"""


@dataclass(frozen=True)
class TemporaryArtifact:
    path: Path
    kind: str


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def repo_path(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def artifact_record(path: Path, root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def atomic_write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise EvidenceError(f"{label}: expected one RTL/TB anchor, found {count}")
    return text.replace(old, new)


def current_design_id(root: Path) -> str:
    tools_dir = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture

        digest, paths = architecture.rtl_binding(root)
    finally:
        sys.path.pop(0)
    if not paths:
        raise EvidenceError("canonical RV64 RTL source set is empty")
    return f"sha256:{digest}"


def validate_product_configuration(root: Path) -> dict[str, object]:
    define = root / DEFINE_REL
    manifest = root / PRODUCT_MANIFEST_REL
    define_anchor = (
        "`ifndef OOO_CSR_QUEUE_HEAD\n"
        "`define OOO_CSR_QUEUE_HEAD 1'b1\n"
        "`endif"
    )
    if define.read_text(encoding="utf-8").count(define_anchor) != 1:
        raise EvidenceError("OOO_CSR_QUEUE_HEAD RTL fallback is not exactly one")
    if (
        manifest.read_text(encoding="utf-8").count(
            "OOO_CSR_QUEUE_HEAD ?= 1"
        )
        != 1
    ):
        raise EvidenceError("product manifest queue-head default is not exactly one")
    return {
        "OOO_CSR_QUEUE_HEAD": 1,
        "command_line_override": False,
        "define": artifact_record(define, root),
        "manifest": artifact_record(manifest, root),
    }


def validate_positive_markers(text: str) -> dict[str, int]:
    if text.count("[RESULT] PASS") != 1 or "[CHECK-FAIL]" in text:
        raise EvidenceError("queue-head CSR positive profile did not terminate cleanly")
    for label in COMMITTED_LABELS:
        marker = (
            f"[V10G-QH-CSR-RAW] {label} "
            "birth=1 lane1_fire=0 C0_commit=1 C0_barrier=1 "
            "CsrFile_request=1 C1_apply=1 C2_quiet=1 PASS"
        )
        if text.count(marker) != 1:
            raise EvidenceError(f"queue-head CSR committed marker drifted: {label}")
    for label in KILLED_LABELS:
        marker = (
            f"[V10G-QH-CSR-KILL] {label} birth=1 lane1_fire=0 "
            "selective_kill=1 C0=0 C1=0 PASS"
        )
        if text.count(marker) != 1:
            raise EvidenceError(f"queue-head CSR kill marker drifted: {label}")
    return {
        "committed": len(COMMITTED_LABELS),
        "selectively_killed": len(KILLED_LABELS),
    }


def validate_negative_markers(text: str, mutation: str) -> dict[str, int]:
    if text.count("[RESULT] FAIL") != 1 or text.count("[RESULT] PASS") != 0:
        raise EvidenceError(f"{mutation}: negative profile terminal marker drifted")
    expected = {
        "typed-apply-c2-replay": {
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
            "[CHECK-FAIL] V10G unowned/repeated queue-head CSR apply": 3,
        },
        "csrfile-request-c2-replay": {
            "[CHECK-FAIL] V10G unowned/repeated CsrFile CSR request": 3,
            "[CHECK-FAIL] V10G C2 repeated queue-head CSR request/apply": 3,
        },
        "rob-queue-head-selection-disabled": {
            "[CHECK-FAIL] V10G queue-head CSR C0 commit/barrier diverged": 1,
        },
    }[mutation]
    counts = {marker: text.count(marker) for marker in expected}
    if counts != expected:
        raise EvidenceError(f"{mutation}: rejection marker counts drifted: {counts}")
    return counts


def materialize_typed_apply_mutation(root: Path, output: Path) -> Path:
    source = root / APPLY_REL
    mutated = source.read_text(encoding="utf-8")
    mutated = replace_once(
        mutated,
        "  reg [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_q;\n",
        "  reg [`OOO_ROB_INDEX_W-1:0] apply_kill_idx_q;\n"
        "  reg csr_replay_valid_q;\n"
        "  reg [`OOO_ROB_INDEX_W-1:0] csr_replay_kill_idx_q;\n",
        "typed-apply-declarations",
    )
    mutated = replace_once(
        mutated,
        "      apply_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n",
        "      apply_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n"
        "      csr_replay_valid_q <= 1'b0;\n"
        "      csr_replay_kill_idx_q <= {`OOO_ROB_INDEX_W{1'b0}};\n",
        "typed-apply-reset",
    )
    mutated = replace_once(
        mutated,
        "    end else begin\n"
        "      apply_valid_q <= request_valid_i;\n",
        "    end else begin\n"
        "      apply_valid_q <= request_valid_i;\n"
        "      csr_replay_valid_q <=\n"
        "          apply_valid_q &&\n"
        "          (apply_reason_q == `REDIR_REASON_CSR_COMMIT);\n"
        "      if (apply_valid_q &&\n"
        "          (apply_reason_q == `REDIR_REASON_CSR_COMMIT))\n"
        "        csr_replay_kill_idx_q <= apply_kill_idx_q;\n",
        "typed-apply-replay-state",
    )
    mutated = replace_once(
        mutated,
        "  assign apply_valid_o = apply_valid_q;\n"
        "  assign apply_reason_o = apply_reason_q;\n"
        "  assign apply_kill_idx_o = apply_kill_idx_q;\n",
        "  assign apply_valid_o = apply_valid_q || csr_replay_valid_q;\n"
        "  assign apply_reason_o =\n"
        "      csr_replay_valid_q ? `REDIR_REASON_CSR_COMMIT :\n"
        "      apply_reason_q;\n"
        "  assign apply_kill_idx_o =\n"
        "      apply_valid_q ? apply_kill_idx_q : csr_replay_kill_idx_q;\n",
        "typed-apply-output",
    )
    target = output / "generated/mutations/typed-apply/OooControlEventApplySequencer.v"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(mutated, encoding="utf-8")
    return target


def materialize_csrfile_request_mutation(root: Path, output: Path) -> Path:
    source = root / CSR_GLUE_REL
    mutated = source.read_text(encoding="utf-8")
    mutated = replace_once(
        mutated,
        "  wire tb_csr_commit_w;\n",
        "  wire tb_csr_commit_w;\n"
        "  reg tb_qh_csrfile_replay_c1_q;\n"
        "  reg tb_qh_csrfile_replay_c2_q;\n",
        "csrfile-request-declarations",
    )
    mutated = replace_once(
        mutated,
        "  assign tb_csr_commit_w =\n"
        "      tb_pending_system_csr_commit_w || tb_head0_csr_commit_w;\n",
        "  // Verification-only mutation: replay an accepted queue-head CSR\n"
        "  // request at C2 while the production head0 owner is already clear.\n"
        "  always @(posedge clk) begin\n"
        "    if (rst) begin\n"
        "      tb_qh_csrfile_replay_c1_q <= 1'b0;\n"
        "      tb_qh_csrfile_replay_c2_q <= 1'b0;\n"
        "    end else begin\n"
        "      tb_qh_csrfile_replay_c1_q <= tb_head0_csr_commit_w;\n"
        "      tb_qh_csrfile_replay_c2_q <= tb_qh_csrfile_replay_c1_q;\n"
        "    end\n"
        "  end\n\n"
        "  assign tb_csr_commit_w =\n"
        "      tb_pending_system_csr_commit_w || tb_head0_csr_commit_w ||\n"
        "      tb_qh_csrfile_replay_c2_q;\n",
        "csrfile-request-replay",
    )
    target = output / "generated/mutations/csrfile-request/tb_ooo_core_top_glue_csr.svh"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(mutated, encoding="utf-8")
    return target


def materialize_rob_queue_head_selection_mutation(root: Path, output: Path) -> Path:
    source = root / ROB_REL
    mutated = replace_once(
        source.read_text(encoding="utf-8"),
        "  wire head0_queue_csr_w =\n"
        "      head0_is_csr_w && !head0_pending_csr_owner_match_w;\n",
        "  wire head0_queue_csr_w =\n"
        "      1'b0;\n",
        "rob-queue-head-selection-disabled",
    )
    target = output / "generated/mutations/rob-queue-head-selection/OooRob.v"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(mutated, encoding="utf-8")
    return target


def build_compiler_wrapper(output: Path, real_iverilog: Path) -> Path:
    wrapper = output / "generated/iverilog-dependency-wrapper.sh"
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        "#!/bin/sh\n"
        "set -u\n"
        f"real_iverilog={shlex.quote(str(real_iverilog.resolve()))}\n"
        "output=\n"
        "expect_output=0\n"
        "for argument do\n"
        "  if [ \"$expect_output\" -eq 1 ]; then output=$argument; break; fi\n"
        "  if [ \"$argument\" = \"-o\" ]; then expect_output=1; fi\n"
        "done\n"
        "if [ -z \"$output\" ]; then echo 'missing -o output' >&2; exit 2; fi\n"
        "profile_dir=$(dirname \"$(dirname \"$output\")\")\n"
        "dependency_dir=$profile_dir/dependencies\n"
        "test_name=$(basename \"$output\" .vvp)\n"
        "mkdir -p \"$dependency_dir\"\n"
        "dependency_path=$dependency_dir/$test_name.deps\n"
        "argv_path=$dependency_dir/$test_name.argv\n"
        "rc_path=$dependency_dir/$test_name.compile.rc\n"
        "printf '%s\\n' \"$real_iverilog\" \"-Mprefix=$dependency_path\" \"$@\" > \"$argv_path\"\n"
        "\"$real_iverilog\" \"-Mprefix=$dependency_path\" \"$@\"\n"
        "rc=$?\n"
        "printf '%s\\n' \"$rc\" > \"$rc_path\"\n"
        "exit \"$rc\"\n",
        encoding="utf-8",
    )
    wrapper.chmod(0o755)
    return wrapper


def resolve_compiler_input(value: str, compile_cwd: Path, root: Path) -> Path:
    candidate = Path(value)
    resolved = (
        candidate.resolve()
        if candidate.is_absolute()
        else (compile_cwd / candidate).resolve()
    )
    resolved.relative_to(root.resolve())
    if not resolved.is_file():
        raise EvidenceError(f"compiler input is missing: {resolved}")
    return resolved


def compile_input_record(
    *,
    test: str,
    log_text: str,
    profile_dir: Path,
    wrapper: Path,
    real_iverilog: Path,
    compile_cwd: Path,
    root: Path,
) -> tuple[dict[str, object], list[TemporaryArtifact]]:
    compile_lines = [
        line.removeprefix("[COMPILE] ")
        for line in log_text.splitlines()
        if line.startswith("[COMPILE] ")
    ]
    if len(compile_lines) != 1:
        raise EvidenceError("expected exactly one Makefile compile line")
    make_argv = shlex.split(compile_lines[0])
    dependency_dir = profile_dir / "dependencies"
    dependency_path = dependency_dir / f"{test}.deps"
    argv_path = dependency_dir / f"{test}.argv"
    rc_path = dependency_dir / f"{test}.compile.rc"
    expected_depflag = f"-Mprefix={dependency_path.resolve()}"
    if (
        not make_argv
        or Path(make_argv[0]).resolve() != wrapper.resolve()
        or not dependency_path.is_file()
        or not argv_path.is_file()
        or not rc_path.is_file()
        or rc_path.read_text(encoding="utf-8").strip() != "0"
    ):
        raise EvidenceError("compiler argv/dependency/return-code receipt is incomplete")
    compiler_argv = argv_path.read_text(encoding="utf-8").splitlines()
    expected_argv = [
        str(real_iverilog.resolve()),
        expected_depflag,
        *make_argv[1:],
    ]
    if compiler_argv != expected_argv:
        raise EvidenceError("actual compiler argv differs from Makefile compile line")

    dependencies: dict[tuple[str, str], dict[str, object]] = {}
    for line in dependency_path.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        prefix, separator, value = line.partition(" ")
        role = {"M": "module", "I": "include"}.get(prefix)
        if role is None or not separator or not value:
            raise EvidenceError(f"malformed Icarus dependency line: {line}")
        resolved = resolve_compiler_input(value, compile_cwd, root)
        key = (role, repo_path(resolved, root))
        dependencies[key] = {
            "path": key[1],
            "role": role,
            "sha256": sha256_file(resolved),
            "size_bytes": resolved.stat().st_size,
        }
    if not dependencies:
        raise EvidenceError("Icarus dependency list is empty")
    module_paths = {
        value["path"]
        for value in dependencies.values()
        if value["role"] == "module"
    }
    command_sources = {
        repo_path(resolve_compiler_input(token, compile_cwd, root), root)
        for token in compiler_argv
        if Path(token).suffix in {".v", ".sv"}
    }
    if command_sources - module_paths:
        raise EvidenceError(
            f"Icarus dependency list omitted compiler sources: "
            f"{sorted(command_sources - module_paths)}"
        )
    return (
        {
            "make_compile_argv": make_argv,
            "compiler_argv": compiler_argv,
            "compiler_argv_file": artifact_record(argv_path, root),
            "dependency_file": artifact_record(dependency_path, root),
            "compile_returncode_file": artifact_record(rc_path, root),
            "dependencies": [dependencies[key] for key in sorted(dependencies)],
        },
        [
            TemporaryArtifact(argv_path, "compiler-argv"),
            TemporaryArtifact(dependency_path, "compiler-dependencies"),
            TemporaryArtifact(rc_path, "compiler-return-code"),
        ],
    )


def base_ivflags(root: Path, assertions: bool, extra_include: Path | None) -> str:
    values = [
        "-g2012",
        "-Wall",
        f"-I{root / 'npc/rv64/vsrc'}",
        f"-I{root / 'npc/rv64/vsrc/include'}",
    ]
    if extra_include is not None:
        values.append(f"-I{extra_include}")
    values.append(f"-I{root / 'npc/rv64/testbench/common'}")
    if assertions:
        values.append("-DOOO_ASSERT")
    return " ".join(values)


def run_profile(
    *,
    name: str,
    root: Path,
    output: Path,
    wrapper: Path,
    real_iverilog: Path,
    real_vvp: Path,
    assertions: bool,
    expect_pass: bool,
    mutation: str | None = None,
    rtl_override: Path | None = None,
    rtl_override_var: str = "RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER",
    extra_include: Path | None = None,
) -> tuple[dict[str, object], list[TemporaryArtifact]]:
    testbench_dir = root / "npc/rv64/testbench"
    profile_dir = output / "profiles" / name
    build_dir = profile_dir / "build"
    result_dir = profile_dir
    log = profile_dir / "logs" / f"{TEST}.log"
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"RESULT_DIR={result_dir}",
        f"BUILD_DIR={build_dir}",
        f"IVERILOG={wrapper}",
        f"VVP={real_vvp}",
        f"IVFLAGS={base_ivflags(root, assertions, extra_include)}",
        f"TB_IVFLAGS_{TEST}=-DV9O_CSR_QH_FOCUSED",
    ]
    if rtl_override is not None:
        command.append(f"{rtl_override_var}={rtl_override}")
    command.append(str(log))
    completed = subprocess.run(
        command,
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=180,
    )
    profile_dir.mkdir(parents=True, exist_ok=True)
    make_log = profile_dir / "make.log"
    make_log.write_text(completed.stdout, encoding="utf-8")
    log_text = log.read_text(encoding="utf-8") if log.is_file() else ""
    markers = (
        validate_positive_markers(log_text)
        if expect_pass
        else validate_negative_markers(log_text, str(mutation))
    )
    expected_make_rc = completed.returncode == 0 if expect_pass else completed.returncode != 0
    if not expected_make_rc:
        raise EvidenceError(f"{name}: Makefile return code did not match expectation")
    compile_record, temporary = compile_input_record(
        test=TEST,
        log_text=log_text,
        profile_dir=profile_dir,
        wrapper=wrapper,
        real_iverilog=real_iverilog,
        compile_cwd=testbench_dir,
        root=root,
    )
    vvp = build_dir / f"{TEST}.vvp"
    if not vvp.is_file():
        raise EvidenceError(f"{name}: compiled image is missing before cleanup")
    temporary.append(TemporaryArtifact(vvp, "compiled-vvp"))
    return (
        {
            "name": name,
            "assertions": assertions,
            "expect_pass": expect_pass,
            "mutation": mutation,
            "make_returncode": completed.returncode,
            "result_log": artifact_record(log, root),
            "make_log": artifact_record(make_log, root),
            "markers": markers,
            "compile_input": compile_record,
            "passed": True,
        },
        temporary,
    )


def cleanup_artifacts(
    artifacts: Sequence[TemporaryArtifact], root: Path, output: Path
) -> dict[str, object]:
    unique: dict[Path, str] = {}
    records: list[dict[str, object]] = []
    for item in artifacts:
        path = item.path.resolve()
        path.relative_to(output.resolve())
        if path in unique:
            continue
        unique[path] = item.kind
        if path.is_file():
            record = artifact_record(path, root)
            record["kind"] = item.kind
            records.append(record)
            path.unlink()
    for directory in sorted(
        (path for path in output.rglob("*") if path.is_dir()),
        key=lambda value: len(value.parts),
        reverse=True,
    ):
        try:
            directory.rmdir()
        except OSError:
            pass
    retained = [path for path in unique if path.exists()]
    if retained:
        raise EvidenceError(f"temporary artifacts remain: {retained}")
    kinds: dict[str, int] = {}
    for record in records:
        kind = str(record["kind"])
        kinds[kind] = kinds.get(kind, 0) + 1
    return {
        "status": "PASS",
        "removed": len(records),
        "kind_counts": dict(sorted(kinds.items())),
        "artifacts": records,
        "retained_temporary_artifacts": 0,
    }


def cleanup_failed_run(output: Path) -> dict[str, object]:
    """失败时只删除本 runner 明确生成的重型/临时文件。"""
    patterns = (
        "generated/iverilog-dependency-wrapper.sh",
        "generated/mutations/typed-apply/OooControlEventApplySequencer.v",
        "generated/mutations/csrfile-request/tb_ooo_core_top_glue_csr.svh",
        "generated/mutations/rob-queue-head-selection/OooRob.v",
        "profiles/*/build/*.vvp",
        "profiles/*/dependencies/*.deps",
        "profiles/*/dependencies/*.argv",
        "profiles/*/dependencies/*.compile.rc",
    )
    removed: list[str] = []
    for pattern in patterns:
        for path in output.glob(pattern):
            resolved = path.resolve()
            resolved.relative_to(output.resolve())
            if resolved.is_file():
                removed.append(resolved.relative_to(output.resolve()).as_posix())
                resolved.unlink()
    for directory in sorted(
        (path for path in output.rglob("*") if path.is_dir()),
        key=lambda value: len(value.parts),
        reverse=True,
    ):
        try:
            directory.rmdir()
        except OSError:
            pass
    return {
        "status": "PASS",
        "removed": len(removed),
        "paths": sorted(removed),
    }


def execute(root: Path, output: Path) -> dict[str, object]:
    if (output / "summary.json").exists():
        raise EvidenceError(f"refusing to overwrite completed evidence: {output}")
    real_iverilog_text = shutil.which("iverilog")
    if real_iverilog_text is None:
        raise EvidenceError("iverilog is unavailable")
    real_iverilog = Path(real_iverilog_text).resolve()
    sibling_vvp = real_iverilog.parent / "vvp"
    real_vvp_text = str(sibling_vvp) if sibling_vvp.is_file() else shutil.which("vvp")
    if real_vvp_text is None:
        raise EvidenceError("matching vvp is unavailable")
    real_vvp = Path(real_vvp_text).resolve()

    output.mkdir(parents=True, exist_ok=True)
    product = validate_product_configuration(root)
    design_id = current_design_id(root)
    wrapper = build_compiler_wrapper(output, real_iverilog)
    typed_mutation = materialize_typed_apply_mutation(root, output)
    csrfile_mutation = materialize_csrfile_request_mutation(root, output)
    rob_selection_mutation = materialize_rob_queue_head_selection_mutation(
        root, output
    )
    temporary: list[TemporaryArtifact] = [
        TemporaryArtifact(wrapper, "compiler-wrapper"),
        TemporaryArtifact(typed_mutation, "typed-apply-rtl-mutation"),
        TemporaryArtifact(csrfile_mutation, "csrfile-request-tb-mutation"),
        TemporaryArtifact(rob_selection_mutation, "rob-selection-rtl-mutation"),
    ]
    mutation_records = {
        "typed-apply-c2-replay": {
            "source": artifact_record(root / APPLY_REL, root),
            "mutated": artifact_record(typed_mutation, root),
            "compile_success_required": True,
        },
        "csrfile-request-c2-replay": {
            "source": artifact_record(root / CSR_GLUE_REL, root),
            "mutated": artifact_record(csrfile_mutation, root),
            "compile_success_required": True,
        },
        "rob-queue-head-selection-disabled": {
            "source": artifact_record(root / ROB_REL, root),
            "mutated": artifact_record(rob_selection_mutation, root),
            "compile_success_required": True,
        },
    }
    profiles: list[dict[str, object]] = []
    for kwargs in (
        dict(name="assert", assertions=True, expect_pass=True),
        dict(name="release", assertions=False, expect_pass=True),
        dict(
            name="mutation-typed-apply-c2-replay",
            assertions=True,
            expect_pass=False,
            mutation="typed-apply-c2-replay",
            rtl_override=typed_mutation,
        ),
        dict(
            name="mutation-csrfile-request-c2-replay",
            assertions=True,
            expect_pass=False,
            mutation="csrfile-request-c2-replay",
            extra_include=csrfile_mutation.parent,
        ),
        dict(
            name="mutation-rob-queue-head-selection-disabled",
            assertions=True,
            expect_pass=False,
            mutation="rob-queue-head-selection-disabled",
            rtl_override=rob_selection_mutation,
            rtl_override_var="RTL_OOO_ROB",
        ),
    ):
        record, profile_temporary = run_profile(
            root=root,
            output=output,
            wrapper=wrapper,
            real_iverilog=real_iverilog,
            real_vvp=real_vvp,
            **kwargs,
        )
        profiles.append(record)
        temporary.extend(profile_temporary)

    cleanup = cleanup_artifacts(temporary, root, output)
    build_controls = {
        path: artifact_record(root / path, root)
        for path in (
            MAKEFILE_REL,
            FILELIST_REL,
            DEFINE_REL,
            PRODUCT_MANIFEST_REL,
            TB_REL,
            APPLY_REL,
            CSR_GLUE_REL,
            "npc/rv64/testbench/scripts/check_tb_result.py",
            "npc/rv64/testbench/common/tb_common.svh",
            "npc/rv64/testbench/common/rv32_encode.svh",
        )
    }
    result = {
        "schema": SCHEMA,
        "status": "PASS",
        "design_id": design_id,
        "scope": "SERIALIZE-G1 Phase1 queue-head CSR local C0/C1/C2",
        "product_configuration": product,
        "build_controls": build_controls,
        "profiles": profiles,
        "mutations": mutation_records,
        "counts": {
            "positive_profiles": 2,
            "compile_success_mutations": 3,
            "compilations": 5,
            "committed_transactions": 6,
            "selectively_killed_transactions": 4,
        },
        "compile_input_closure": {
            "status": "PASS",
            "actual_compiler_argv_bound": True,
            "icarus_dependency_bound": True,
            "make_source_selection_bound": True,
        },
        "cleanup": cleanup,
        "non_claims": [
            "pending-SYSTEM current matrix",
            "full architecture freeze",
            "full-system current-design recertification",
            "PPA promotion",
        ],
    }
    atomic_write_json(output / "artifact-cleanup.json", cleanup)
    atomic_write_json(output / "summary.json", result)
    (output / "result.txt").write_text(
        "[V12C-SERIALIZE-QH-CURRENT] "
        f"design_id={design_id} positive=2/2 mutations=3/3 "
        f"cleanup={cleanup['removed']} PASS\n",
        encoding="utf-8",
    )
    return result


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output-dir", type=Path, required=True)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    root = args.repo_root.resolve()
    output = (
        args.output_dir.resolve()
        if args.output_dir.is_absolute()
        else (root / args.output_dir).resolve()
    )
    output.relative_to(root)
    try:
        result = execute(root, output)
    except Exception as exc:
        output.mkdir(parents=True, exist_ok=True)
        failure_cleanup = cleanup_failed_run(output)
        atomic_write_json(
            output / "failure.json",
            {
                "schema": SCHEMA,
                "status": "FAIL",
                "error": str(exc),
                "cleanup": failure_cleanup,
            },
        )
        print(f"[V12C-SERIALIZE-QH-CURRENT] FAIL {exc}", file=sys.stderr)
        return 1
    print(
        "[V12C-SERIALIZE-QH-CURRENT] "
        f"design_id={result['design_id']} positive=2/2 mutations=3/3 "
        f"cleanup={result['cleanup']['removed']} PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
