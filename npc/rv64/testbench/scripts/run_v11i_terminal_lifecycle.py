#!/usr/bin/env python3
"""Run the V11I RV64 memory-owner terminal lifecycle matrix."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v11i-terminal-lifecycle-evidence-v1"
TOP = "tb_ooo_int_backend"
TB_PASS = "[PASS] tb_ooo_int_backend_v11i_terminal_lifecycle"
WRAP_PASS = "[V11I-TERMINAL-WRAP]"
STALE_ACTIVE = "[V11I-STALE-SOURCE-ACTIVE]"
HOLDER_ASSERT = "[V9Y-HOLDER-TERMINAL-NEXT]"
ASSERT_ESCAPED = "[V11I-HOLDER-ASSERTION-ESCAPED][FAIL]"
ABA_FAIL = "[V11I-LATE-TUPLE-ABA][FAIL]"
ABA_OBSERVATION_FAIL = "[V11I-LATE-TUPLE-OBSERVATION][FAIL]"


@dataclass(frozen=True)
class Profile:
    name: str
    assertions: bool
    stale_tuple_variant: bool


PROFILES = (
    Profile("production-assert", assertions=True, stale_tuple_variant=False),
    Profile("production-release", assertions=False, stale_tuple_variant=False),
    Profile("stale-tuple-assert", assertions=True, stale_tuple_variant=True),
    Profile("stale-tuple-release", assertions=False, stale_tuple_variant=True),
)


TERMINAL_ANCHOR = """\
  wire mem_issue_res_tagged_terminal_w =
      (mem_issue_res_owner_kind_q != MEM_OWNER_STORE) &&
      (mem_issue_res_local_complete_w || mem_issue_res_kill_w ||
       mem_issue_res_global_cancel_w);
"""

TERMINAL_MUTATION = """\
  // V11I compile-success sensitivity variant.  It captures the first
  // token-0 LOAD terminal tuple, retains it after the source has ended, and
  // re-emits that old tuple only after token 0 is bound to a different full
  // ProducerId.  This block exists only in the generated evidence copy.
  reg v11i_stale_tuple_wait_q;
  reg v11i_stale_tuple_pulse_q;
  reg [1:0] v11i_stale_tuple_kind_q;
  reg [4:0] v11i_stale_tuple_token_q;
  reg [1:0] v11i_stale_tuple_epoch_q;
  reg [PRODUCER_ID_W-1:0] v11i_stale_tuple_pid_q;
  always @(posedge clk) begin
    if (rst) begin
      v11i_stale_tuple_wait_q <= 1'b0;
      v11i_stale_tuple_pulse_q <= 1'b0;
      v11i_stale_tuple_kind_q <= MEM_OWNER_RESERVED;
      v11i_stale_tuple_token_q <= 5'b0;
      v11i_stale_tuple_epoch_q <= MEM_OWNER_EPOCH_BASE;
      v11i_stale_tuple_pid_q <= {PRODUCER_ID_W{1'b0}};
    end else begin
      v11i_stale_tuple_pulse_q <= 1'b0;
      if (!v11i_stale_tuple_wait_q &&
          mem_issue_res_valid_q &&
          (mem_issue_res_owner_kind_q == MEM_OWNER_LOAD) &&
          (mem_issue_res_owner_token_q == 5'd0) &&
          mem_issue_res_local_complete_w) begin
        v11i_stale_tuple_wait_q <= 1'b1;
        v11i_stale_tuple_kind_q <= mem_issue_res_owner_kind_q;
        v11i_stale_tuple_token_q <= mem_issue_res_owner_token_q;
        v11i_stale_tuple_epoch_q <= mem_issue_res_mmu_epoch_q;
        v11i_stale_tuple_pid_q <= mem_issue_res_producer_id_q;
      end
      if (v11i_stale_tuple_wait_q &&
          mem_issue_res_valid_q &&
          (mem_issue_res_owner_token_q == v11i_stale_tuple_token_q) &&
          (mem_issue_res_producer_id_q != v11i_stale_tuple_pid_q) &&
          mem_owner_live_mask_w[v11i_stale_tuple_token_q] &&
          !mem_terminal_pending_mask_w[v11i_stale_tuple_token_q]) begin
        v11i_stale_tuple_wait_q <= 1'b0;
        v11i_stale_tuple_pulse_q <= 1'b1;
      end
    end
  end
  wire [1:0] v11i_lane6_terminal_kind_w =
      v11i_stale_tuple_pulse_q ? v11i_stale_tuple_kind_q :
                                 mem_issue_res_owner_kind_q;
  wire [4:0] v11i_lane6_terminal_token_w =
      v11i_stale_tuple_pulse_q ? v11i_stale_tuple_token_q :
                                 mem_issue_res_owner_token_q;
  wire [1:0] v11i_lane6_terminal_epoch_w =
      v11i_stale_tuple_pulse_q ? v11i_stale_tuple_epoch_q :
                                 mem_issue_res_mmu_epoch_q;
  wire mem_issue_res_tagged_terminal_w =
      ((mem_issue_res_owner_kind_q != MEM_OWNER_STORE) &&
       (mem_issue_res_local_complete_w || mem_issue_res_kill_w ||
        mem_issue_res_global_cancel_w)) ||
      v11i_stale_tuple_pulse_q;
"""

MUTATION_REPLACEMENTS = (
    (
        TERMINAL_ANCHOR,
        TERMINAL_MUTATION,
        "capture-and-delay-old-lane6-tuple",
    ),
    (
        """\
      mem_issue1_res_owner_kind_q,
      mem_issue_res_owner_kind_q,
      mem1_drop1_owner_kind_i,
""",
        """\
      mem_issue1_res_owner_kind_q,
      v11i_lane6_terminal_kind_w,
      mem1_drop1_owner_kind_i,
""",
        "lane6-kind-selects-old-tuple",
    ),
    (
        """\
      mem_issue1_res_owner_token_q,
      mem_issue_res_owner_token_q,
      mem1_drop1_owner_token_i,
""",
        """\
      mem_issue1_res_owner_token_q,
      v11i_lane6_terminal_token_w,
      mem1_drop1_owner_token_i,
""",
        "lane6-token-selects-old-tuple",
    ),
    (
        """\
      mem_issue1_res_mmu_epoch_q,
      mem_issue_res_mmu_epoch_q,
      mem1_drop1_mmu_epoch_i,
""",
        """\
      mem_issue1_res_mmu_epoch_q,
      v11i_lane6_terminal_epoch_w,
      mem1_drop1_mmu_epoch_i,
""",
        "lane6-epoch-selects-old-tuple",
    ),
    (
        """\
  assign mem_terminal_ingress6_mask_w =
      mem_issue_res_tagged_terminal_w ?
      (32'b1 << mem_issue_res_owner_token_q) : 32'b0;
""",
        """\
  assign mem_terminal_ingress6_mask_w =
      mem_issue_res_tagged_terminal_w ?
      (32'b1 << v11i_lane6_terminal_token_w) : 32'b0;
""",
        "lane6-mask-selects-old-token",
    ),
)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return sha256_bytes(raw)


def canonical_rtl_binding(repo_root: Path) -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path
        for path in (repo_root / "npc" / "rv64" / "vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes
    )
    if not files:
        raise ValueError("local RV64 RTL source set is empty")
    entries = {
        path.relative_to(repo_root).as_posix(): sha256_file(path)
        for path in files
    }
    return canonical_digest(entries), entries


def repo_path(path: Path, repo_root: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(resolved)


def write_json(path: Path, value: Any) -> None:
    path.write_text(
        json.dumps(
            value,
            allow_nan=False,
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def atomic_status(path: Path, value: str) -> None:
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    temporary.replace(path)


def command_identity(command: Path, version_args: Sequence[str]) -> dict[str, str]:
    completed = subprocess.run(
        [str(command), *version_args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    lines = completed.stdout.splitlines()
    resolved = command.resolve()
    return {
        "path": str(resolved),
        "sha256": sha256_file(resolved),
        "version_first_line": lines[0] if lines else "",
    }


def resolve_tools() -> tuple[Path, Path]:
    iverilog_raw = shutil.which("iverilog")
    if not iverilog_raw:
        raise FileNotFoundError("iverilog is not available")
    iverilog = Path(iverilog_raw).resolve()
    sibling_vvp = iverilog.with_name("vvp")
    if sibling_vvp.is_file():
        vvp = sibling_vvp.resolve()
    else:
        vvp_raw = shutil.which("vvp")
        if not vvp_raw:
            raise FileNotFoundError("vvp is not available")
        vvp = Path(vvp_raw).resolve()
    return iverilog, vvp


def load_make_context(testbench_dir: Path) -> tuple[Path, list[Path]]:
    completed = subprocess.run(
        [
            "make",
            "--no-print-directory",
            "-s",
            "print-v11i-terminal-lifecycle-context",
        ],
        cwd=testbench_dir,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "cannot resolve V11I testbench source context:\n"
            + completed.stderr
        )
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.removeprefix("RTL_INCLUDE_DIR=")).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.removeprefix("SOURCE=")).resolve())
    if include_dir is None or not include_dir.is_dir():
        raise RuntimeError("resolved RTL include directory is invalid")
    if not sources or any(not path.is_file() for path in sources):
        raise RuntimeError("resolved V11I source set is incomplete")
    if len(sources) != len(set(sources)):
        raise RuntimeError("resolved V11I source set contains duplicates")
    return include_dir, sources


def build_mutant(source: str) -> tuple[str, list[dict[str, object]]]:
    mutated = source
    receipts: list[dict[str, object]] = []
    for old, new, mutation_id in MUTATION_REPLACEMENTS:
        count = mutated.count(old)
        if count != 1:
            raise ValueError(
                f"{mutation_id}: expected one RTL anchor, observed {count}"
            )
        mutated = mutated.replace(old, new, 1)
        receipts.append(
            {
                "mutation_id": mutation_id,
                "anchor_count": count,
                "old_sha256": sha256_bytes(old.encode("utf-8")),
                "new_sha256": sha256_bytes(new.encode("utf-8")),
            }
        )
    return mutated, receipts


def run_command(
    command: Sequence[str],
    *,
    cwd: Path,
    timeout_seconds: int,
) -> tuple[int, str, str, float, bool]:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            list(command),
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout_seconds,
        )
        return (
            completed.returncode,
            completed.stdout,
            completed.stderr,
            time.monotonic() - started,
            False,
        )
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (
            error.stdout or ""
        )
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (
            error.stderr or ""
        )
        return 124, stdout, stderr, time.monotonic() - started, True


def marker_count(text: str, marker: str) -> int:
    return sum(marker in line for line in text.splitlines())


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    sim_rc: int | None,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    counts = {
        "wrap_pass": marker_count(log_text, WRAP_PASS),
        "tb_pass": marker_count(log_text, TB_PASS),
        "stale_active": marker_count(log_text, STALE_ACTIVE),
        "holder_assert": marker_count(log_text, HOLDER_ASSERT),
        "assertion_escaped": marker_count(log_text, ASSERT_ESCAPED),
        "aba_fail": marker_count(log_text, ABA_FAIL),
        "aba_observation_fail": marker_count(
            log_text, ABA_OBSERVATION_FAIL
        ),
        "v11i_fail_total": sum(
            "[V11I-" in line and "[FAIL]" in line
            for line in log_text.splitlines()
        ),
    }
    compile_ok = compile_rc == 0 and artifact_exists
    if not profile.stale_tuple_variant:
        passed = (
            compile_ok
            and sim_rc == 0
            and counts["wrap_pass"] == 1
            and counts["tb_pass"] == 1
            and counts["stale_active"] == 0
            and counts["holder_assert"] == 0
            and counts["v11i_fail_total"] == 0
        )
    elif profile.assertions:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and counts["stale_active"] == 1
            and counts["holder_assert"] == 1
            and counts["assertion_escaped"] == 0
            and counts["aba_fail"] == 0
            and counts["aba_observation_fail"] == 0
            and counts["tb_pass"] == 0
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and counts["stale_active"] == 1
            and counts["holder_assert"] == 0
            and counts["assertion_escaped"] == 0
            and counts["aba_fail"] == 1
            and counts["aba_observation_fail"] == 0
            and counts["tb_pass"] == 0
        )
    return passed, counts


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    backend_path: Path,
    mutant_path: Path,
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    build_dir = profile_dir / "build"
    profile_dir.mkdir(parents=True, exist_ok=True)
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{TOP}.vvp"

    sources = [
        mutant_path if profile.stale_tuple_variant and path == backend_path
        else path
        for path in production_sources
    ]
    defines = ["-DV11I_TERMINAL_LIFECYCLE_FOCUSED"]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    if profile.stale_tuple_variant:
        defines.append("-DV11I_STALE_TERMINAL_MUTATION")
    compile_command = [
        str(iverilog),
        "-g2012",
        "-Wall",
        f"-I{repo_root / 'npc' / 'rv64' / 'vsrc'}",
        f"-I{include_dir}",
        f"-I{testbench_dir / 'common'}",
        *defines,
        "-s",
        TOP,
        "-o",
        str(artifact),
        *(str(path) for path in sources),
    ]
    compile_rc, compile_out, compile_err, compile_seconds, compile_timeout = (
        run_command(
            compile_command,
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    )
    (profile_dir / "compile.stdout").write_text(
        compile_out, encoding="utf-8"
    )
    (profile_dir / "compile.stderr").write_text(
        compile_err, encoding="utf-8"
    )
    (profile_dir / "compile.rc").write_text(
        f"{compile_rc}\n", encoding="utf-8"
    )

    sim_rc: int | None = None
    sim_out = ""
    sim_err = ""
    sim_seconds = 0.0
    sim_timeout = False
    sim_command = [str(vvp), str(artifact)]
    if compile_rc == 0 and artifact.is_file():
        sim_rc, sim_out, sim_err, sim_seconds, sim_timeout = run_command(
            sim_command,
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    (profile_dir / "sim.stdout").write_text(sim_out, encoding="utf-8")
    (profile_dir / "sim.stderr").write_text(sim_err, encoding="utf-8")
    (profile_dir / "sim.log").write_text(
        sim_out + sim_err, encoding="utf-8"
    )
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if sim_rc is None else f"{sim_rc}\n",
        encoding="utf-8",
    )
    artifact_exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, counts = evaluate_profile(
        profile,
        compile_rc=compile_rc,
        sim_rc=sim_rc,
        log_text=sim_out + sim_err,
        artifact_exists=artifact_exists,
    )
    command_record = {
        "compile": {
            "command": compile_command,
            "mode": (
                "local-rv64-iverilog-assert"
                if profile.assertions
                else "local-rv64-iverilog-release"
            ),
            "purpose": (
                "compile the RV64 IntBackend token-wrap terminal lifecycle "
                "profile"
            ),
        },
        "simulate": {
            "command": sim_command,
            "mode": "local-rv64-vvp-cycle-simulation",
            "purpose": (
                "observe collector ingress, tracker free, LQ terminal_seen, "
                "and holder assertion markers"
            ),
        },
    }
    write_json(profile_dir / "commands.json", command_record)
    return {
        "profile": profile.name,
        "assertions": profile.assertions,
        "stale_tuple_variant": profile.stale_tuple_variant,
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": compile_rc,
            "timeout": compile_timeout,
            "elapsed_seconds": round(compile_seconds, 6),
            "artifact": repo_path(artifact, repo_root),
            "artifact_exists": artifact_exists,
            "artifact_sha256": (
                sha256_file(artifact) if artifact_exists else None
            ),
        },
        "simulation": {
            "rc": sim_rc,
            "timeout": sim_timeout,
            "elapsed_seconds": round(sim_seconds, 6),
            "log": repo_path(profile_dir / "sim.log", repo_root),
        },
        "markers": counts,
    }


def source_manifest(paths: Sequence[Path], repo_root: Path) -> dict[str, str]:
    unique = sorted({path.resolve() for path in paths})
    if any(not path.is_file() for path in unique):
        raise ValueError("runner input manifest contains a missing file")
    return {repo_path(path, repo_root): sha256_file(path) for path in unique}


def write_sha256_manifest(path: Path, entries: dict[str, str]) -> None:
    path.write_text(
        "".join(f"{digest}  {name}\n" for name, digest in entries.items()),
        encoding="utf-8",
    )


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run assert/release RV64 token-wrap terminal lifecycle profiles "
            "against production RTL and a compile-success stale-tuple variant"
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument(
        "--timeout-seconds",
        type=int,
        default=180,
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="replace files in a non-empty result directory",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    backend_path = (
        repo_root / "npc" / "rv64" / "vsrc" / "execute" / "OooIntBackend.v"
    ).resolve()
    status_path = result_dir / "runner.status"

    if args.timeout_seconds <= 0:
        print("timeout must be positive", file=sys.stderr)
        return 2
    if result_dir.exists() and any(result_dir.iterdir()):
        if not args.overwrite:
            print(
                f"result directory is not empty: {result_dir}",
                file=sys.stderr,
            )
            return 2
        shutil.rmtree(result_dir)
    result_dir.mkdir(parents=True, exist_ok=True)
    atomic_status(status_path, "RUNNING")

    try:
        iverilog, vvp = resolve_tools()
        include_dir, production_sources = load_make_context(testbench_dir)
        if backend_path not in production_sources:
            raise RuntimeError("production OooIntBackend.v is absent from TB")

        backend_source = backend_path.read_text(encoding="utf-8")
        mutant_source, mutation_receipts = build_mutant(backend_source)
        mutant_path = result_dir / "variant" / "OooIntBackend.v"
        mutant_path.parent.mkdir(parents=True, exist_ok=True)
        mutant_path.write_text(mutant_source, encoding="utf-8")

        runner_inputs = [
            *production_sources,
            testbench_dir / "Makefile",
            testbench_dir / "common" / "tb_common.svh",
            repo_root / "npc" / "rv64" / "vsrc" / "filelist.mk",
            Path(__file__).resolve(),
        ]
        input_pre = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "sources.pre.sha256", input_pre)
        design_sha_pre, rtl_files_pre = canonical_rtl_binding(repo_root)

        profiles = [
            run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                backend_path=backend_path,
                mutant_path=mutant_path,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            for profile in PROFILES
        ]

        input_post = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "sources.post.sha256", input_post)
        design_sha_post, rtl_files_post = canonical_rtl_binding(repo_root)
        source_unchanged = input_pre == input_post
        rtl_unchanged = (
            design_sha_pre == design_sha_post
            and rtl_files_pre == rtl_files_post
        )
        all_profiles_pass = all(
            profile["status"] == "PASS" for profile in profiles
        )
        status = (
            "PASS"
            if all_profiles_pass and source_unchanged and rtl_unchanged
            else "FAIL"
        )
        summary = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": status,
            "contract": {
                "rtl_objects": [
                    "npc/rv64/vsrc/execute/OooIntBackend.v",
                    "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
                    "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
                    "npc/rv64/vsrc/memory/OooLoadQueue.v",
                ],
                "cycle_configuration": (
                    "33 sequential LOAD owners; tracker token 0..31 then "
                    "token-0 reuse with a different full ProducerId"
                ),
                "testbench_observation": (
                    "lane6 collector ingress/accept, tracker live/table, "
                    "LQ valid/terminal_seen raw Q, holder-next assertion"
                ),
                "profiles": [profile.name for profile in PROFILES],
                "prohibited_shortcut": (
                    "no raw-terminal deduplication and no assertion weakening"
                ),
            },
            "tools": {
                "python": {
                    "path": sys.executable,
                    "version": sys.version.splitlines()[0],
                },
                "iverilog": command_identity(iverilog, ["-V"]),
                "vvp": command_identity(vvp, ["-V"]),
            },
            "rtl_source_binding": {
                "design_id": f"sha256:{design_sha_pre}",
                "design_id_after": f"sha256:{design_sha_post}",
                "file_count": len(rtl_files_pre),
                "files": rtl_files_pre,
                "unchanged": rtl_unchanged,
            },
            "runner_inputs": {
                "pre": input_pre,
                "post": input_post,
                "unchanged": source_unchanged,
            },
            "stale_tuple_variant": {
                "path": repo_path(mutant_path, repo_root),
                "sha256": sha256_file(mutant_path),
                "production_backend_sha256": sha256_file(backend_path),
                "compile_success_required": True,
                "receipts": mutation_receipts,
            },
            "profiles": profiles,
            "summary": {
                "profile_total": len(profiles),
                "profile_passed": sum(
                    profile["status"] == "PASS" for profile in profiles
                ),
                "production_profiles_passed": sum(
                    profile["status"] == "PASS"
                    and not profile["stale_tuple_variant"]
                    for profile in profiles
                ),
                "stale_tuple_profiles_rejected": sum(
                    profile["status"] == "PASS"
                    and profile["stale_tuple_variant"]
                    for profile in profiles
                ),
                "source_pre_post_identical": source_unchanged,
                "rtl_pre_post_identical": rtl_unchanged,
            },
            "scope_boundary": {
                "closed": (
                    "local IntBackend terminal lifecycle through one complete "
                    "32-token tracker wrap"
                ),
                "not_promoted": [
                    "full-system behavior",
                    "architecture aggregate",
                    "frequency",
                    "power",
                    "PPA",
                ],
                "full_system_run_launched": False,
            },
        }
        write_json(result_dir / "summary.json", summary)
        atomic_status(status_path, status)
        print(
            "[V11I-TERMINAL-LIFECYCLE] "
            f"profiles={len(profiles)} "
            f"passed={summary['summary']['profile_passed']} "
            f"design_id=sha256:{design_sha_pre} "
            f"source_unchanged={int(source_unchanged)} "
            f"rtl_unchanged={int(rtl_unchanged)} "
            f"{status}"
        )
        print(result_dir / "summary.json")
        return 0 if status == "PASS" else 1
    except (
        FileNotFoundError,
        OSError,
        RuntimeError,
        UnicodeError,
        ValueError,
    ) as error:
        write_json(
            result_dir / "runner-error.json",
            {
                "schema": SCHEMA,
                "status": "FAIL",
                "error_type": type(error).__name__,
                "error": str(error),
            },
        )
        atomic_status(status_path, "FAIL")
        print(f"V11I runner failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
