#!/usr/bin/env python3
"""Run the current-design V14G global ProducerId owner fence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v14g-global-producer-owner-fence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV14G_GLOBAL_OWNER_FENCE_FOCUSED"
ORACLE_FAIL = "[V14G-GLOBAL-OWNER-ORACLE][FAIL]"
TB_PASS = "[PASS] tb_ooo_int_backend_v14g_global_owner_fence"
GLOBAL_PASS = "[V14G-GLOBAL-PRODUCER-OWNER][PASS]"
BASELINE_MARKERS = (
    "[V14G-BIRTH-EDGE-OLD][PASS]",
    "[V14G-OWNER-BIRTH][PASS]",
    "[V14G-UNION-ISOLATION][PASS]",
    "[V14G-DISPATCH-LANE-MATRIX][PASS]",
    "[V14G-OWNER-ONLY-LIVE][PASS]",
    "[V14G-DEATH-EDGE-OLD][PASS]",
    "[V14G-PENDING-SYSTEM-UNION][PASS]",
    GLOBAL_PASS,
    TB_PASS,
)
GEN_WIDTHS = (4, 1)
MAX_LOG_BYTES = 64 * 1024
BASE_TB_REL = "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
OVERLAY_REL = (
    "npc/rv64/testbench/tests/"
    "tb_ooo_int_backend_v14g_global_owner_fence.svh"
)


@dataclass(frozen=True)
class Mutation:
    name: str
    target: str
    anchor: str
    replacement: str
    expected_stage: str
    purpose: str


@dataclass(frozen=True)
class Profile:
    name: str
    generation_width: int
    assertions: bool
    kind: str
    mutation: str | None = None
    expected_stage: str | None = None


MUTATIONS = (
    Mutation(
        "int-iq-mask-drops-on-fire",
        "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
        """\
      if (valid_q[lease_i])
        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;
""",
        """\
      if (valid_q[lease_i] && !compact_remove_w[lease_i])
        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;
""",
        "memory-capture-int-iq-holder",
        "remove the firing IntIQ Q holder before the capture candidate",
    ),
    Mutation(
        "dispatch-drops-external-union",
        "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] complete_producer_live_mask_w =
      producer_live_mask_i | int_iq_producer_live_mask_w;
""",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] complete_producer_live_mask_w =
      int_iq_producer_live_mask_w;
""",
        "birth-owner-only",
        "disconnect every external registered holder from dispatch",
    ),
    Mutation(
        "backend-drops-load-queue-union",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] external_producer_live_mask_w =
      mem_owner_producer_live_mask_w |
      lq_producer_live_mask_w |
      muldiv_owner_producer_live_mask_w |
""",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] external_producer_live_mask_w =
      mem_owner_producer_live_mask_w |
      muldiv_owner_producer_live_mask_w |
""",
        "load-queue-union",
        "drop the retire-resident LOAD full-P holder from the global union",
    ),
    Mutation(
        "backend-drops-reservation-union",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] transient_producer_live_mask_w =
      mem_res_producer_live_mask_w |
      ex0_producer_live_mask_w |
""",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] transient_producer_live_mask_w =
      ex0_producer_live_mask_w |
""",
        "reservation-union",
        "drop the real memory reservation Q holder from the transient union",
    ),
    Mutation(
        "backend-drops-memory-owner-union",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] external_producer_live_mask_w =
      mem_owner_producer_live_mask_w |
      lq_producer_live_mask_w |
""",
        """\
  wire [(1 << PRODUCER_ID_W)-1:0] external_producer_live_mask_w =
      lq_producer_live_mask_w |
""",
        "collector-pending-owner-only",
        "drop the tracker token-to-full-P owner mapping from dispatch",
    ),
    Mutation(
        "backend-lane6-corrupts-reservation-token",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        """\
      mem_issue1_res_owner_token_q,
      mem_issue_res_owner_token_q,
      mem1_drop1_owner_token_i,
""",
        """\
      mem_issue1_res_owner_token_q,
      (mem_issue_res_owner_token_q ^ 5'b00001),
      mem1_drop1_owner_token_i,
""",
        "terminal-lane6-ingress",
        "corrupt the reservation0 terminal token on collector ingress lane6",
    ),
    Mutation(
        "backend-drops-pending-system-union",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        """\
      fp_producer_live_mask_w |
      pending_system_producer_live_mask_w |
      transient_producer_live_mask_w;
""",
        """\
      fp_producer_live_mask_w |
      transient_producer_live_mask_w;
""",
        "pending-system-union",
        "drop the registered pending-system full-P lease",
    ),
    Mutation(
        "dispatch-lane0-truncates-generation",
        "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        """\
                             !complete_producer_live_mask_w[
                                 rob_dispatch0_producer_id_w] &&
""",
        """\
                             !complete_producer_live_mask_w[
                                 {{PRODUCER_GEN_W{1'b0}},
                                  rob_dispatch0_producer_id_w[
                                      ROB_INDEX_W-1:0]}] &&
""",
        "birth-edge-old",
        "query the lane0 lease with raw ROB index instead of full P",
    ),
    Mutation(
        "dispatch-mandatory-lane1-truncates-generation",
        "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        """\
       !complete_producer_live_mask_w[
           rob_dispatch1_pair_producer_id_w]);
""",
        """\
       !complete_producer_live_mask_w[
           {{PRODUCER_GEN_W{1'b0}},
            rob_dispatch1_pair_producer_id_w[ROB_INDEX_W-1:0]}]);
""",
        "lane1-mandatory",
        "truncate the mandatory lane1 pair candidate generation",
    ),
    Mutation(
        "dispatch-optional-lane1-truncates-generation",
        "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
        """\
                             !complete_producer_live_mask_w[
                                 rob_dispatch1_producer_id_w];
""",
        """\
                             !complete_producer_live_mask_w[
                                 {{PRODUCER_GEN_W{1'b0}},
                                  rob_dispatch1_producer_id_w[
                                      ROB_INDEX_W-1:0]}];
""",
        "lane1-optional",
        "truncate the optional lane1 actual candidate generation",
    ),
    Mutation(
        "tracker-clears-producer-on-death-edge",
        "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
        "  assign producer_live_mask_o = producer_live_q;\n",
        "  assign producer_live_mask_o = producer_live_next_r;\n",
        "death-edge-old",
        "expose tracker next-state and open dispatch on the exact free edge",
    ),
)


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def display_path(path: Path, repo_root: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(resolved)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def atomic_status(path: Path, value: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    temporary.replace(path)


def bounded_text(text: str, limit: int = MAX_LOG_BYTES) -> str:
    encoded = text.encode("utf-8", errors="replace")
    if len(encoded) <= limit:
        return text
    marker = b"\n[V14G-LOG-TRUNCATED] retained_tail_bytes="
    suffix = encoded[-(limit - len(marker) - 16) :]
    return (marker + str(len(suffix)).encode("ascii") + b"\n" + suffix).decode(
        "utf-8", errors="replace"
    )


def apply_mutation(source: str, mutation: Mutation) -> tuple[str, dict[str, Any]]:
    count = source.count(mutation.anchor)
    if count != 1:
        raise ValueError(
            f"mutation anchor count must be one: {mutation.name} count={count}"
        )
    mutated = source.replace(mutation.anchor, mutation.replacement, 1)
    if mutated == source:
        raise ValueError(f"mutation did not change source: {mutation.name}")
    return mutated, {
        "name": mutation.name,
        "target": mutation.target,
        "expected_stage": mutation.expected_stage,
        "purpose": mutation.purpose,
        "anchor_count": count,
        "anchor_sha256": sha256_bytes(mutation.anchor.encode("utf-8")),
        "replacement_sha256": sha256_bytes(
            mutation.replacement.encode("utf-8")
        ),
        "mutated_source_sha256": sha256_bytes(mutated.encode("utf-8")),
        "compile_success_required": True,
    }


def inject_overlay(base_source: str, overlay_source: str) -> tuple[str, list[dict[str, Any]]]:
    insert_anchor = """\
  initial begin
    tb_errors = 0;
    reset_dut();
"""
    select_anchor = """\
`elsif V8P_PAIR_MATRIX_FOCUSED
    run_v8p_pair_matrix_contract();
"""
    finish_anchor = """\
`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
        tb_finish("tb_ooo_int_backend_hist_ser_qh_younger_store");
`elsif V11R_INT_LANE1_PACKET_FOCUSED
"""
    replacements = (
        (
            insert_anchor,
            overlay_source.rstrip() + "\n\n" + insert_anchor,
            "inject the source-bound V14G task before the base initial block",
        ),
        (
            select_anchor,
            """\
`elsif V14G_GLOBAL_OWNER_FENCE_FOCUSED
    run_v14g_global_producer_owner_fence();
`elsif V8P_PAIR_MATRIX_FOCUSED
    run_v8p_pair_matrix_contract();
""",
            "select V14G as an outer focused branch without default tail tests",
        ),
        (
            finish_anchor,
            """\
`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
        tb_finish("tb_ooo_int_backend_hist_ser_qh_younger_store");
`elsif V14G_GLOBAL_OWNER_FENCE_FOCUSED
        tb_finish("tb_ooo_int_backend_v14g_global_owner_fence");
`elsif V11R_INT_LANE1_PACKET_FOCUSED
""",
            "bind the exact V14G testbench PASS identity",
        ),
    )
    result = base_source
    receipts: list[dict[str, Any]] = []
    for anchor, replacement, purpose in replacements:
        count = result.count(anchor)
        if count != 1:
            raise ValueError(
                f"overlay anchor count must be one: {purpose} count={count}"
            )
        result = result.replace(anchor, replacement, 1)
        receipts.append(
            {
                "purpose": purpose,
                "anchor_count": count,
                "anchor_sha256": sha256_bytes(anchor.encode("utf-8")),
                "replacement_sha256": sha256_bytes(
                    replacement.encode("utf-8")
                ),
            }
        )
    return result, receipts


def build_profiles() -> tuple[Profile, ...]:
    baseline = tuple(
        Profile(
            f"gen{width}-production-{mode}",
            width,
            assertions,
            "baseline",
        )
        for width in GEN_WIDTHS
        for mode, assertions in (("assert", True), ("release", False))
    )
    mutation = tuple(
        Profile(
            f"gen{width}-{item.name}-release",
            width,
            False,
            "mutation",
            mutation=item.name,
            expected_stage=item.expected_stage,
        )
        for width in GEN_WIDTHS
        for item in MUTATIONS
    )
    return baseline + mutation


def oracle_failure_stages(text: str) -> list[str]:
    return re.findall(
        re.escape(ORACLE_FAIL)
        + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
        text,
    )


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    compile_timeout: bool,
    sim_rc: int | None,
    sim_timeout: bool,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    counts = {marker: log_text.count(marker) for marker in BASELINE_MARKERS}
    counts[ORACLE_FAIL] = log_text.count(ORACLE_FAIL)
    stages = oracle_failure_stages(log_text)
    compile_ok = compile_rc == 0 and not compile_timeout and artifact_exists
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and not sim_timeout
            and counts[ORACLE_FAIL] == 0
            and stages == []
            and all(counts[marker] == 1 for marker in BASELINE_MARKERS)
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and not sim_timeout
            and counts[ORACLE_FAIL] == 1
            and stages == [profile.expected_stage]
            and counts[GLOBAL_PASS] == 0
            and counts[TB_PASS] == 0
        )
    return passed, counts


def run_command(
    command: Sequence[str], *, cwd: Path, timeout_seconds: int
) -> tuple[int, str, str, float, bool]:
    start = time.monotonic()
    try:
        completed = subprocess.run(
            list(command),
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=timeout_seconds,
            check=False,
        )
        return (
            completed.returncode,
            completed.stdout,
            completed.stderr,
            time.monotonic() - start,
            False,
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout if isinstance(exc.stdout, str) else ""
        stderr = exc.stderr if isinstance(exc.stderr, str) else ""
        return 124, stdout, stderr, time.monotonic() - start, True


def resolve_tools() -> tuple[Path, Path]:
    raw_iverilog = shutil.which("iverilog")
    if not raw_iverilog:
        raise RuntimeError("iverilog was not found")
    iverilog = Path(raw_iverilog).resolve()
    sibling_vvp = iverilog.parent / "vvp"
    raw_vvp = str(sibling_vvp) if sibling_vvp.is_file() else shutil.which("vvp")
    if not raw_vvp:
        raise RuntimeError("matching vvp was not found")
    return iverilog, Path(raw_vvp).resolve()


def tool_version(tool: Path) -> str:
    completed = subprocess.run(
        [str(tool), "-V"], text=True, capture_output=True, check=False
    )
    text = (completed.stdout + completed.stderr).strip()
    return "\n".join(text.splitlines()[:4])


def load_make_context(testbench_dir: Path) -> tuple[Path, tuple[Path, ...]]:
    transient_rule = """\
v14g-print-context:
	@printf '%s\\n' "RTL_INCLUDE_DIR=$(abspath $(RTL_INCLUDE_DIR))"
	@printf '%s\\n' $(addprefix SOURCE=,$(abspath $(sort $(TB_SRCS_tb_ooo_int_backend))))
"""
    completed = subprocess.run(
        ["make", "-s", f"--eval={transient_rule}", "v14g-print-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.split("=", 1)[1]).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.split("=", 1)[1]).resolve())
    if include_dir is None or not sources:
        raise RuntimeError("V14G Makefile context is incomplete")
    return include_dir, tuple(sources)


def current_design_id(repo_root: Path) -> str:
    tools_dir = repo_root / "npc" / "rv64" / "eval" / "ppa" / "tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(repo_root)
    return f"sha256:{digest}"


def source_manifest(paths: Sequence[Path], repo_root: Path) -> dict[str, str]:
    return {
        display_path(path, repo_root): sha256_file(path)
        for path in sorted({item.resolve() for item in paths})
    }


def manifest_digest(manifest: dict[str, str]) -> str:
    payload = "".join(
        f"{name}\0{digest}\n" for name, digest in sorted(manifest.items())
    )
    return sha256_bytes(payload.encode("utf-8"))


def prepare_variants(
    repo_root: Path, work_dir: Path
) -> tuple[dict[str, Path], list[dict[str, Any]]]:
    variants: dict[str, Path] = {}
    receipts: list[dict[str, Any]] = []
    for mutation in MUTATIONS:
        target = repo_root / mutation.target
        source = target.read_text(encoding="utf-8")
        mutated, receipt = apply_mutation(source, mutation)
        variant = work_dir / "variants" / mutation.name / target.name
        variant.parent.mkdir(parents=True, exist_ok=True)
        variant.write_text(mutated, encoding="utf-8")
        receipt["production_sha256"] = sha256_file(target)
        receipt["variant_sha256"] = sha256_file(variant)
        variants[mutation.name] = variant
        receipts.append(receipt)
    return variants, receipts


def prepare_generated_tb(
    repo_root: Path, work_dir: Path
) -> tuple[Path, dict[str, Any]]:
    base_path = repo_root / BASE_TB_REL
    overlay_path = repo_root / OVERLAY_REL
    generated, receipts = inject_overlay(
        base_path.read_text(encoding="utf-8"),
        overlay_path.read_text(encoding="utf-8"),
    )
    generated_path = work_dir / "generated" / base_path.name
    generated_path.parent.mkdir(parents=True, exist_ok=True)
    generated_path.write_text(generated, encoding="utf-8")
    return generated_path, {
        "base": BASE_TB_REL,
        "base_sha256": sha256_file(base_path),
        "overlay": OVERLAY_REL,
        "overlay_sha256": sha256_file(overlay_path),
        "generated_sha256": sha256_file(generated_path),
        "receipts": receipts,
        "generated_is_intermediate": True,
    }


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    generated_tb: Path,
    variants: dict[str, Path],
    result_dir: Path,
    work_dir: Path,
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, Any]:
    mutation = next(
        (item for item in MUTATIONS if item.name == profile.mutation), None
    )
    base_tb = (repo_root / BASE_TB_REL).resolve()
    if list(production_sources).count(base_tb) != 1:
        raise RuntimeError("base IntBackend testbench must appear once")
    sources = [
        generated_tb if path == base_tb else path for path in production_sources
    ]
    if mutation is not None:
        target = (repo_root / mutation.target).resolve()
        if sources.count(target) != 1:
            raise RuntimeError(
                f"mutated target must appear once in source closure: {mutation.target}"
            )
        sources = [
            variants[mutation.name] if path == target else path for path in sources
        ]

    artifact = work_dir / "artifacts" / f"{profile.name}.vvp"
    artifact.parent.mkdir(parents=True, exist_ok=True)
    defines = [
        FOCUSED_DEFINE,
        f"-DOOO_PRODUCER_GEN_W={profile.generation_width}",
    ]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    command = [
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
    crc, cout, cerr, cseconds, ctimeout = run_command(
        command, cwd=testbench_dir, timeout_seconds=timeout_seconds
    )
    src: int | None = None
    sout = ""
    serr = ""
    sseconds = 0.0
    stimeout = False
    artifact_exists = artifact.is_file() and artifact.stat().st_size > 0
    artifact_sha256 = sha256_file(artifact) if artifact_exists else None
    if crc == 0 and artifact_exists:
        src, sout, serr, sseconds, stimeout = run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    combined = sout + serr
    passed, counts = evaluate_profile(
        profile,
        compile_rc=crc,
        compile_timeout=ctimeout,
        sim_rc=src,
        sim_timeout=stimeout,
        log_text=combined,
        artifact_exists=artifact_exists,
    )
    log_path = result_dir / "logs" / f"{profile.name}.log"
    log_text = "".join(
        (
            f"PROFILE={profile.name}\n",
            f"KIND={profile.kind}\n",
            f"GENERATION_WIDTH={profile.generation_width}\n",
            f"ASSERTIONS={int(profile.assertions)}\n",
            f"COMPILE_RC={crc}\n",
            f"COMPILE_TIMEOUT={int(ctimeout)}\n",
            f"SIM_RC={'NOT_RUN' if src is None else src}\n",
            f"SIM_TIMEOUT={int(stimeout)}\n",
            "[COMPILE-STDOUT]\n",
            cout,
            "[COMPILE-STDERR]\n",
            cerr,
            "[SIM]\n",
            combined,
        )
    )
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(bounded_text(log_text), encoding="utf-8")
    record = {
        "name": profile.name,
        "kind": profile.kind,
        "generation_width": profile.generation_width,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "expected_stage": profile.expected_stage,
        "compile_rc": crc,
        "compile_timeout": ctimeout,
        "compile_seconds": round(cseconds, 6),
        "compile_command_sha256": sha256_bytes(
            "\0".join(command).encode("utf-8")
        ),
        "artifact_generated": artifact_exists,
        "artifact_sha256": artifact_sha256,
        "sim_rc": src,
        "sim_timeout": stimeout,
        "sim_seconds": round(sseconds, 6),
        "marker_counts": counts,
        "oracle_stages": oracle_failure_stages(combined),
        "log": display_path(log_path, repo_root),
        "log_sha256": sha256_file(log_path),
        "pass": passed,
    }
    if artifact.exists():
        artifact.unlink()
    return record


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--result-dir", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=60)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = Path(__file__).resolve().parents[4]
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    result_dir = args.result_dir.resolve()
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"[V14G-GLOBAL-OWNER-RUNNER][FAIL] result directory is not empty: {result_dir}")
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)
    status_path = result_dir / "status"
    work_dir = result_dir / ".work"
    atomic_status(status_path, "RUNNING")
    started = datetime.now(timezone.utc)
    summary: dict[str, Any] = {
        "schema": SCHEMA,
        "started_at": started.isoformat(),
        "result": "FAIL",
    }
    try:
        include_dir, production_sources = load_make_context(testbench_dir)
        runner_path = Path(__file__).resolve()
        evidence_inputs = (
            *production_sources,
            include_dir / "define.v",
            repo_root
            / "npc/rv64/design/specs/ooo-global-producer-no-live-reuse.md",
            repo_root / "npc/rv64/Makefile",
            testbench_dir / "Makefile",
            testbench_dir / "common" / "tb_common.svh",
            testbench_dir / "common" / "rv32_encode.svh",
            repo_root / OVERLAY_REL,
            runner_path,
        )
        manifest_before = source_manifest(evidence_inputs, repo_root)
        source_digest_before = manifest_digest(manifest_before)
        design_id_before = current_design_id(repo_root)
        iverilog, vvp = resolve_tools()

        coverage_ledger = result_dir / "semantic-local-preflight.json"
        coverage_command = [
            sys.executable,
            "-B",
            str(
                repo_root
                / "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py"
            ),
            "build",
            "--local-only",
            "--output",
            str(coverage_ledger),
        ]
        cov_rc, cov_out, cov_err, cov_seconds, cov_timeout = run_command(
            coverage_command,
            cwd=repo_root,
            timeout_seconds=args.timeout_seconds,
        )
        coverage_log = result_dir / "semantic-coverage.log"
        coverage_log.write_text(
            bounded_text(cov_out + cov_err), encoding="utf-8"
        )
        if cov_rc != 0 or cov_timeout:
            raise RuntimeError("producer-holder semantic coverage preflight failed")

        work_dir.mkdir(parents=True, exist_ok=True)
        generated_tb, overlay_receipt = prepare_generated_tb(
            repo_root, work_dir
        )
        write_json(result_dir / "overlay-manifest.json", overlay_receipt)
        variants, mutation_receipts = prepare_variants(repo_root, work_dir)
        write_json(result_dir / "mutation-manifest.json", mutation_receipts)
        profiles = []
        for profile in build_profiles():
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                generated_tb=generated_tb,
                variants=variants,
                result_dir=result_dir,
                work_dir=work_dir,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            profiles.append(record)
            if not record["pass"]:
                raise RuntimeError(f"profile failed: {profile.name}")

        manifest_after = source_manifest(evidence_inputs, repo_root)
        source_digest_after = manifest_digest(manifest_after)
        design_id_after = current_design_id(repo_root)
        if manifest_after != manifest_before:
            raise RuntimeError("selected source or testbench changed during run")
        if design_id_after != design_id_before:
            raise RuntimeError("RTL design identity changed during run")

        write_json(result_dir / "source-manifest.json", manifest_before)
        baseline_count = sum(item["kind"] == "baseline" for item in profiles)
        mutation_count = sum(item["kind"] == "mutation" for item in profiles)
        summary.update(
            {
                "result": "PASS",
                "finished_at": datetime.now(timezone.utc).isoformat(),
                "design_id_pre": design_id_before,
                "design_id_post": design_id_after,
                "source_manifest_sha256_pre": source_digest_before,
                "source_manifest_sha256_post": source_digest_after,
                "top": TOP,
                "generation_widths": list(GEN_WIDTHS),
                "baseline_profiles_pass": baseline_count,
                "baseline_profiles_total": len(GEN_WIDTHS) * 2,
                "compile_success_mutations_rejected": mutation_count,
                "compile_success_mutations_total": len(GEN_WIDTHS)
                * len(MUTATIONS),
                "profiles": profiles,
                "semantic_coverage": {
                    "rc": cov_rc,
                    "timeout": cov_timeout,
                    "seconds": round(cov_seconds, 6),
                    "log": display_path(coverage_log, repo_root),
                    "log_sha256": sha256_file(coverage_log),
                    "ledger": display_path(coverage_ledger, repo_root),
                    "ledger_sha256": sha256_file(coverage_ledger),
                },
                "tools": {
                    "iverilog": {
                        "path": str(iverilog),
                        "sha256": sha256_file(iverilog),
                        "version": tool_version(iverilog),
                    },
                    "vvp": {
                        "path": str(vvp),
                        "sha256": sha256_file(vvp),
                        "version": tool_version(vvp),
                    },
                },
                "intermediate_products_retained": 0,
            }
        )
        write_json(result_dir / "summary.json", summary)
        atomic_status(status_path, "PASS")
        print(
            "[V14G-GLOBAL-OWNER-RUNNER][PASS] "
            f"design_id={design_id_before} baselines={baseline_count}/4 "
            f"mutations={mutation_count}/{len(GEN_WIDTHS) * len(MUTATIONS)}"
        )
        return 0
    except Exception as exc:  # fail closed with a bounded machine-readable record
        summary.update(
            {
                "finished_at": datetime.now(timezone.utc).isoformat(),
                "error": str(exc),
            }
        )
        write_json(result_dir / "summary.json", summary)
        atomic_status(status_path, "FAIL")
        print(f"[V14G-GLOBAL-OWNER-RUNNER][FAIL] {exc}", file=sys.stderr)
        return 1
    finally:
        if work_dir.exists():
            shutil.rmtree(work_dir)


if __name__ == "__main__":
    raise SystemExit(main())
