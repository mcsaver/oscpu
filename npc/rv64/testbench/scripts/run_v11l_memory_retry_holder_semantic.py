#!/usr/bin/env python3
"""Run the V11L OooIntBackend dual retry-holder semantic matrix."""

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


SCHEMA = "npc-rv64-v11l-memory-retry-holder-semantic-evidence-v1"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11L_MEMORY_RETRY_HOLDER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11l_memory_retry_holder"
MATRIX_PASS = "[V11L-RETRY-HOLDER-MATRIX][PASS]"
ORACLE_FAIL = "[V11L-RETRY-HOLDER-ORACLE][FAIL]"
UNIT_IDS = (
    "memory-retry0-producer-cache",
    "memory-retry0-token",
    "memory-retry1-producer-cache",
    "memory-retry1-token",
)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = (
    "tb_ooo_int_backend",
    "tb_ooo_int_backend_v9r_sq_retry_c0",
    "tb_ooo_int_backend_v11i_terminal_lifecycle",
)
BASELINE_MARKERS = {
    "[V11L-RETRY0-CAPTURE-TUPLE][PASS]": 2,
    "[V11L-RETRY1-CAPTURE-TUPLE][PASS]": 2,
    "[V11L-LANE-DISTINCT][PASS]": 2,
    "[V11L-RETRY-HOLD][PASS]": 1,
    "[V11L-C0-HOLDER-PAUSE][PASS]": 1,
    "[V11L-RETRY0-FIRE-TRANSFER][PASS]": 1,
    "[V11L-RETRY1-FIRE-TRANSFER][PASS]": 1,
    "[V11L-RESPONSE-TERMINAL-EXACT][PASS]": 1,
    "[V11L-FLUSH-CANCEL-LANE10-EXACT][PASS]": 1,
    "[V11L-FLUSH-CANCEL-LANE11-EXACT][PASS]": 1,
}


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    unit_ids: tuple[str, ...]
    expected_stage: str
    replacements: tuple[Replacement, ...]


@dataclass(frozen=True)
class Profile:
    name: str
    assertions: bool
    kind: str
    mutation: str | None = None
    expected_stage: str | None = None


R0_PRODUCER = "memory-retry0-producer-cache"
R0_TOKEN = "memory-retry0-token"
R1_PRODUCER = "memory-retry1-producer-cache"
R1_TOKEN = "memory-retry1-token"
R0_UNITS = (R0_PRODUCER, R0_TOKEN)
R1_UNITS = (R1_PRODUCER, R1_TOKEN)

R0_READY = """\
  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""
R1_READY = """\
  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !control_full_flush_barrier_w;
"""
R0_REQ_VALID = """\
  wire mem_retry0_req_valid_w = mem_retry0_selected_w &&
      miq_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;
"""
R1_REQ_VALID = """\
  wire mem_retry1_req_valid_w = mem_retry1_selected_w &&
      miq1_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;
"""
R0_CANDIDATE = """\
  wire mem_retry0_candidate_w = ENABLE_DUAL_MEM &&
      mem_retry0_valid_q && mem_retry0_tracker_exact_w &&
      !mem_retry0_cancel_w && !mem_retry0_addr_q[3];
"""
R1_CANDIDATE = """\
  wire mem_retry1_candidate_w = ENABLE_DUAL_MEM &&
      mem_retry1_valid_q && mem_retry1_tracker_exact_w &&
      !mem_retry1_cancel_w && mem_retry1_addr_q[3];
"""
R0_GRANT = """\
  wire grant_retry0_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && mem_retry0_req_valid_w;
"""
R1_GRANT = """\
  wire grant_retry1_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && mem_retry1_req_valid_w;
"""
R0_CLEAR = """\
    end else if (mem_retry0_cancel_w || mem_retry0_req_fire_w) begin
      mem_retry0_valid_q <= 1'b0;
"""
R1_CLEAR = """\
    end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin
      mem_retry1_valid_q <= 1'b0;
"""
R0_HOLD_TAIL = """\
      mem_retry0_fault_tval_q <= miq_head_fault_tval_w;
    end
  end

  always @(posedge clk) begin
"""
R1_HOLD_TAIL = """\
      mem_retry1_fault_tval_q <= miq1_head_fault_tval_w;
    end
  end

  assign mem1_completion_query_valid_w = ENABLE_DUAL_MEM &&
"""


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


MUTATIONS = (
    Mutation(
        "retry0-producer-cross-lane",
        (R0_PRODUCER,),
        "retry0-holder-tuple",
        (
            replacement(
                "      mem_retry0_producer_id_q <= "
                "mem_sq_query_producer_id_w;\n",
                "      mem_retry0_producer_id_q <= "
                "mem1_sq_query_producer_id_w;\n",
                "capture retry0 ProducerId from lane1",
            ),
        ),
    ),
    Mutation(
        "retry0-token-cross-lane",
        (R0_TOKEN,),
        "retry0-holder-tuple",
        (
            replacement(
                "      mem_retry0_owner_token_q <= "
                "miq_head_owner_token_w;\n",
                "      mem_retry0_owner_token_q <= "
                "miq1_head_owner_token_w;\n",
                "capture retry0 owner token from lane1",
            ),
        ),
    ),
    Mutation(
        "retry1-producer-cross-lane",
        (R1_PRODUCER,),
        "retry1-holder-tuple",
        (
            replacement(
                "      mem_retry1_producer_id_q <= "
                "mem1_sq_query_producer_id_w;\n",
                "      mem_retry1_producer_id_q <= "
                "mem_sq_query_producer_id_w;\n",
                "capture retry1 ProducerId from lane0",
            ),
        ),
    ),
    Mutation(
        "retry1-token-cross-lane",
        (R1_TOKEN,),
        "retry1-holder-tuple",
        (
            replacement(
                "      mem_retry1_owner_token_q <= "
                "miq1_head_owner_token_w;\n",
                "      mem_retry1_owner_token_q <= "
                "miq_head_owner_token_w;\n",
                "capture retry1 owner token from lane0",
            ),
        ),
    ),
    *tuple(
        Mutation(
            f"retry{lane}-{field}-{state}",
            (unit,),
            f"retry{lane}-holder-tuple",
            (
                replacement(
                    anchor,
                    value,
                    f"capture {state.upper()} in retry{lane} {field}",
                ),
            ),
        )
        for lane, field, unit, anchor, x_value, z_value in (
            (
                0,
                "producer",
                R0_PRODUCER,
                "      mem_retry0_producer_id_q <= "
                "mem_sq_query_producer_id_w;\n",
                "      mem_retry0_producer_id_q <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "      mem_retry0_producer_id_q <= "
                "{PRODUCER_ID_W{1'bz}};\n",
            ),
            (
                0,
                "token",
                R0_TOKEN,
                "      mem_retry0_owner_token_q <= "
                "miq_head_owner_token_w;\n",
                "      mem_retry0_owner_token_q <= 5'bxxxxx;\n",
                "      mem_retry0_owner_token_q <= 5'bzzzzz;\n",
            ),
            (
                1,
                "producer",
                R1_PRODUCER,
                "      mem_retry1_producer_id_q <= "
                "mem1_sq_query_producer_id_w;\n",
                "      mem_retry1_producer_id_q <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "      mem_retry1_producer_id_q <= "
                "{PRODUCER_ID_W{1'bz}};\n",
            ),
            (
                1,
                "token",
                R1_TOKEN,
                "      mem_retry1_owner_token_q <= "
                "miq1_head_owner_token_w;\n",
                "      mem_retry1_owner_token_q <= 5'bxxxxx;\n",
                "      mem_retry1_owner_token_q <= 5'bzzzzz;\n",
            ),
        )
        for state, value in (("x", x_value), ("z", z_value))
    ),
    Mutation(
        "retry0-producer-hold-drift",
        (R0_PRODUCER,),
        "retry0-holder-tuple",
        (
            replacement(
                R0_HOLD_TAIL,
                """\
      mem_retry0_fault_tval_q <= miq_head_fault_tval_w;
    end else if (mem_retry0_valid_q) begin
      mem_retry0_producer_id_q <=
          mem_retry0_producer_id_q ^ {{(PRODUCER_ID_W-1){1'b0}}, 1'b1};
    end
  end

  always @(posedge clk) begin
""",
                "drift retry0 ProducerId during a no-event hold",
            ),
        ),
    ),
    Mutation(
        "retry0-token-hold-drift",
        (R0_TOKEN,),
        "retry0-holder-tuple",
        (
            replacement(
                R0_HOLD_TAIL,
                """\
      mem_retry0_fault_tval_q <= miq_head_fault_tval_w;
    end else if (mem_retry0_valid_q) begin
      mem_retry0_owner_token_q <= mem_retry0_owner_token_q ^ 5'b00001;
    end
  end

  always @(posedge clk) begin
""",
                "drift retry0 token during a no-event hold",
            ),
        ),
    ),
    Mutation(
        "retry1-producer-hold-drift",
        (R1_PRODUCER,),
        "retry1-holder-tuple",
        (
            replacement(
                R1_HOLD_TAIL,
                """\
      mem_retry1_fault_tval_q <= miq1_head_fault_tval_w;
    end else if (mem_retry1_valid_q) begin
      mem_retry1_producer_id_q <=
          mem_retry1_producer_id_q ^ {{(PRODUCER_ID_W-1){1'b0}}, 1'b1};
    end
  end

  assign mem1_completion_query_valid_w = ENABLE_DUAL_MEM &&
""",
                "drift retry1 ProducerId during a no-event hold",
            ),
        ),
    ),
    Mutation(
        "retry1-token-hold-drift",
        (R1_TOKEN,),
        "retry1-holder-tuple",
        (
            replacement(
                R1_HOLD_TAIL,
                """\
      mem_retry1_fault_tval_q <= miq1_head_fault_tval_w;
    end else if (mem_retry1_valid_q) begin
      mem_retry1_owner_token_q <= mem_retry1_owner_token_q ^ 5'b00001;
    end
  end

  assign mem1_completion_query_valid_w = ENABLE_DUAL_MEM &&
""",
                "drift retry1 token during a no-event hold",
            ),
        ),
    ),
    Mutation(
        "retry0-early-valid-death",
        R0_UNITS,
        "retry0-holder-tuple",
        (
            replacement(
                R0_CLEAR,
                """\
    end else if (mem_retry0_cancel_w || mem_retry0_req_fire_w ||
                 mem_retry0_valid_q) begin
      mem_retry0_valid_q <= 1'b0;
""",
                "clear retry0 valid during backpressure hold",
            ),
        ),
    ),
    Mutation(
        "retry1-early-valid-death",
        R1_UNITS,
        "retry1-holder-tuple",
        (
            replacement(
                R1_CLEAR,
                """\
    end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w ||
                 mem_retry1_valid_q) begin
      mem_retry1_valid_q <= 1'b0;
""",
                "clear retry1 valid during backpressure hold",
            ),
        ),
    ),
    Mutation(
        "retry0-fire-retains-holder",
        R0_UNITS,
        "retry0-next-cycle-miq",
        (
            replacement(
                R0_CLEAR,
                """\
    end else if (mem_retry0_cancel_w || mem_retry0_req_fire_w) begin
      mem_retry0_valid_q <= mem_retry0_req_fire_w;
""",
                "retain retry0 holder after request fire",
            ),
        ),
    ),
    Mutation(
        "retry1-fire-retains-holder",
        R1_UNITS,
        "retry1-next-cycle-miq",
        (
            replacement(
                R1_CLEAR,
                """\
    end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin
      mem_retry1_valid_q <= mem_retry1_req_fire_w;
""",
                "retain retry1 holder after request fire",
            ),
        ),
    ),
    Mutation(
        "retry0-fire-suppresses-miq-push",
        R0_UNITS,
        "retry0-fire-transfer",
        (
            replacement(
                "  wire push_retry0_w = mem_retry0_req_fire_w;\n",
                "  wire push_retry0_w = 1'b0;\n",
                "suppress retry0 same-edge MIQ push",
            ),
        ),
    ),
    Mutation(
        "retry1-fire-suppresses-miq-push",
        R1_UNITS,
        "retry1-fire-transfer",
        (
            replacement(
                "  wire push_retry1_w = mem_retry1_req_fire_w;\n",
                "  wire push_retry1_w = 1'b0;\n",
                "suppress retry1 same-edge MIQ push",
            ),
        ),
    ),
    Mutation(
        "retry0-cancel-suppresses-terminal",
        R0_UNITS,
        "flush-cancel-terminal-priority",
        (
            replacement(
                "  wire mem_retry0_tagged_terminal_w = "
                "mem_retry0_cancel_w;\n",
                "  wire mem_retry0_tagged_terminal_w = 1'b0;\n",
                "suppress retry0 cancel terminal lane10",
            ),
        ),
    ),
    Mutation(
        "retry1-cancel-suppresses-terminal",
        R1_UNITS,
        "flush-cancel-terminal-priority",
        (
            replacement(
                "  wire mem_retry1_tagged_terminal_w = "
                "mem_retry1_cancel_w;\n",
                "  wire mem_retry1_tagged_terminal_w = 1'b0;\n",
                "suppress retry1 cancel terminal lane11",
            ),
        ),
    ),
    Mutation(
        "retry0-fire-premature-terminal",
        R0_UNITS,
        "tracker0-not-exact-live",
        (
            replacement(
                "  wire mem_retry0_tagged_terminal_w = "
                "mem_retry0_cancel_w;\n",
                "  wire mem_retry0_tagged_terminal_w = "
                "mem_retry0_cancel_w || mem_retry0_req_fire_w;\n",
                "terminalize retry0 tracker at nonterminal re-push",
            ),
        ),
    ),
    Mutation(
        "retry1-fire-premature-terminal",
        R1_UNITS,
        "dual-response-terminal-accept",
        (
            replacement(
                "  wire mem_retry1_tagged_terminal_w = "
                "mem_retry1_cancel_w;\n",
                "  wire mem_retry1_tagged_terminal_w = "
                "mem_retry1_cancel_w || mem_retry1_req_fire_w;\n",
                "terminalize retry1 tracker at nonterminal re-push",
            ),
        ),
    ),
    Mutation(
        "retry0-c0-capture-open",
        R0_UNITS,
        "c0-empty-holder-capture-barrier",
        (
            replacement(
                R0_READY,
                R0_READY.replace(
                    "      !control_full_flush_barrier_w;\n",
                    "      1'b1;\n",
                ),
                "admit retry0 capture during C0 barrier",
            ),
        ),
    ),
    Mutation(
        "retry1-c0-capture-open",
        R1_UNITS,
        "c0-empty-holder-capture-barrier",
        (
            replacement(
                R1_READY,
                R1_READY.replace(
                    "      !control_full_flush_barrier_w;\n",
                    "      1'b1;\n",
                ),
                "admit retry1 capture during C0 barrier",
            ),
        ),
    ),
    Mutation(
        "retry0-c0-resident-fire-open",
        R0_UNITS,
        "c0-filled-holder-pause",
        (
            replacement(
                R0_REQ_VALID,
                R0_REQ_VALID.replace(
                    "      !branch_resolve_mispredict_w && "
                    "!issue_block_w &&\n"
                    "      !mem_issue_block_w;\n",
                    "      !branch_resolve_mispredict_w;\n",
                ),
                "remove both retry0 C0 issue barriers",
            ),
        ),
    ),
    Mutation(
        "retry1-c0-resident-fire-open",
        R1_UNITS,
        "c0-filled-holder-pause",
        (
            replacement(
                R1_REQ_VALID,
                R1_REQ_VALID.replace(
                    "      !branch_resolve_mispredict_w && "
                    "!issue_block_w &&\n"
                    "      !mem_issue_block_w;\n",
                    "      !branch_resolve_mispredict_w;\n",
                ),
                "remove both retry1 C0 issue barriers",
            ),
        ),
    ),
    Mutation(
        "retry0-flush-fire-open",
        R0_UNITS,
        "flush-cancel-terminal-priority",
        (
            replacement(
                R0_CANDIDATE,
                R0_CANDIDATE.replace(
                    "      !mem_retry0_cancel_w && ",
                    "      ",
                ),
                "keep retry0 selectable during flush cancellation",
            ),
            replacement(
                R0_REQ_VALID,
                R0_REQ_VALID.replace(
                    "miq_slot_open_w && !flush_i && ",
                    "miq_slot_open_w && ",
                ),
                "remove retry0 flush cut from source valid",
            ),
            replacement(
                R0_GRANT,
                R0_GRANT.replace(
                    "      mem_request_transport_open_w && ",
                    "      ",
                ),
                "remove retry0 flush cut from bank grant",
            ),
        ),
    ),
    Mutation(
        "retry1-flush-fire-open",
        R1_UNITS,
        "flush-cancel-terminal-priority",
        (
            replacement(
                R1_CANDIDATE,
                R1_CANDIDATE.replace(
                    "      !mem_retry1_cancel_w && ",
                    "      ",
                ),
                "keep retry1 selectable during flush cancellation",
            ),
            replacement(
                R1_REQ_VALID,
                R1_REQ_VALID.replace(
                    "miq1_slot_open_w && !flush_i && ",
                    "miq1_slot_open_w && ",
                ),
                "remove retry1 flush cut from source valid",
            ),
            replacement(
                R1_GRANT,
                R1_GRANT.replace(
                    "      mem_request_transport_open_w && ",
                    "      ",
                ),
                "remove retry1 flush cut from bank grant",
            ),
        ),
    ),
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_path(path: Path, repo_root: Path) -> str:
    return path.resolve().relative_to(repo_root.resolve()).as_posix()


def artifact_record(path: Path, repo_root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, repo_root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


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


def current_design_id(repo_root: Path) -> str:
    tools_dir = repo_root / "npc" / "rv64" / "eval" / "ppa" / "tools"
    sys.path.insert(0, str(tools_dir))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(repo_root)
    return f"sha256:{digest}"


def apply_mutation(
    source: str, replacements: Sequence[Replacement]
) -> tuple[str, list[dict[str, object]]]:
    result = source
    receipts: list[dict[str, object]] = []
    for item in replacements:
        count = result.count(item.anchor)
        if count != 1:
            raise ValueError(
                f"mutation anchor count must be 1, got {count}: "
                f"{item.purpose}"
            )
        result = result.replace(item.anchor, item.replacement, 1)
        receipts.append(
            {
                "purpose": item.purpose,
                "anchor_count": count,
                "anchor_sha256": hashlib.sha256(
                    item.anchor.encode("utf-8")
                ).hexdigest(),
                "replacement_sha256": hashlib.sha256(
                    item.replacement.encode("utf-8")
                ).hexdigest(),
            }
        )
    return result, receipts


def build_profiles() -> tuple[Profile, ...]:
    return (
        Profile("production-assert", True, "baseline"),
        Profile("production-release", False, "baseline"),
        *(
            Profile(
                f"{mutation.name}-release",
                False,
                "mutation",
                mutation=mutation.name,
                expected_stage=mutation.expected_stage,
            )
            for mutation in MUTATIONS
        ),
    )


def marker_counts(text: str) -> dict[str, int]:
    result = {
        "tb_pass": text.count(TB_PASS),
        "matrix_pass": text.count(MATRIX_PASS),
        "oracle_fail": text.count(ORACLE_FAIL),
    }
    for marker in BASELINE_MARKERS:
        key = (
            marker.strip("[]")
            .lower()
            .replace("][", "_")
            .replace("-", "_")
        )
        result[key] = text.count(marker)
    return result


def evaluate_profile(
    profile: Profile,
    *,
    compile_rc: int,
    sim_rc: int | None,
    log_text: str,
    artifact_exists: bool,
) -> tuple[bool, dict[str, int]]:
    markers = marker_counts(log_text)
    compile_ok = compile_rc == 0 and artifact_exists
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and markers["tb_pass"] == 1
            and markers["matrix_pass"] == 1
            and markers["oracle_fail"] == 0
            and all(
                log_text.count(marker) == count
                for marker, count in BASELINE_MARKERS.items()
            )
        )
    else:
        stage_marker = (
            f"{ORACLE_FAIL} stage={profile.expected_stage}"
            if profile.expected_stage
            else ""
        )
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and markers["oracle_fail"] >= 1
            and stage_marker in log_text
            and markers["tb_pass"] == 0
            and markers["matrix_pass"] == 0
        )
    return passed, markers


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
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        return 124, stdout, stderr, time.monotonic() - start, True


def resolve_tools() -> tuple[Path, Path]:
    iverilog_raw = shutil.which("iverilog")
    if not iverilog_raw:
        raise RuntimeError("iverilog was not found")
    iverilog = Path(iverilog_raw).resolve()
    sibling_vvp = iverilog.parent / "vvp"
    vvp_raw = (
        str(sibling_vvp)
        if sibling_vvp.is_file()
        else shutil.which("vvp")
    )
    if not vvp_raw:
        raise RuntimeError("vvp was not found")
    return iverilog, Path(vvp_raw).resolve()


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = subprocess.run(
        ["make", "-s", "print-v11l-memory-retry-holder-context"],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "failed to load V11L Makefile context: "
            + completed.stderr.strip()
        )
    include_dir: Path | None = None
    sources: list[Path] = []
    for line in completed.stdout.splitlines():
        if line.startswith("RTL_INCLUDE_DIR="):
            include_dir = Path(line.split("=", 1)[1]).resolve()
        elif line.startswith("SOURCE="):
            sources.append(Path(line.split("=", 1)[1]).resolve())
    if include_dir is None or not sources:
        raise RuntimeError("V11L Makefile context is incomplete")
    if any(not path.is_file() for path in sources):
        raise RuntimeError("V11L Makefile context names a missing source")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = subprocess.run(
        [
            "make",
            "-s",
            "print-v11l-memory-retry-holder-regression-context",
        ],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "failed to load V11L regression context: "
            + completed.stderr.strip()
        )
    common: list[Path] = []
    sources: dict[str, list[Path]] = {
        test: [] for test in REGRESSIONS
    }
    prefix = "REGRESSION_SOURCE_"
    for line in completed.stdout.splitlines():
        if line.startswith("REGRESSION_COMMON="):
            common.append(Path(line.split("=", 1)[1]).resolve())
        elif line.startswith(prefix):
            key, raw_path = line.split("=", 1)
            test = key[len(prefix):]
            if test not in sources:
                raise RuntimeError(
                    f"unknown V11L regression context: {test}"
                )
            sources[test].append(Path(raw_path).resolve())
    result = {
        test: tuple(sorted({*paths, *common}))
        for test, paths in sources.items()
    }
    if (
        not common
        or any(not paths for paths in result.values())
        or any(
            not path.is_file()
            for paths in result.values()
            for path in paths
        )
    ):
        raise RuntimeError("V11L regression context is incomplete")
    return result


def source_manifest(
    paths: Sequence[Path], repo_root: Path
) -> dict[str, str]:
    unique = sorted({path.resolve() for path in paths})
    if any(not path.is_file() for path in unique):
        raise ValueError("source manifest contains a missing file")
    return {
        repo_path(path, repo_root): sha256_file(path)
        for path in unique
    }


def write_sha256_manifest(path: Path, entries: dict[str, str]) -> None:
    path.write_text(
        "".join(
            f"{digest}  {name}\n"
            for name, digest in sorted(entries.items())
        ),
        encoding="utf-8",
    )


def build_variants(
    *,
    result_dir: Path,
    rtl_path: Path,
    repo_root: Path,
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    source = rtl_path.read_text(encoding="utf-8")
    variants: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = result_dir / "variants" / mutation.name / rtl_path.name
        variant.parent.mkdir(parents=True, exist_ok=True)
        variant.write_text(mutated, encoding="utf-8")
        variants[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_ids": list(mutation.unit_ids),
                "expected_stage": mutation.expected_stage,
                "target": repo_path(rtl_path, repo_root),
                "production_sha256": sha256_file(rtl_path),
                "variant": repo_path(variant, repo_root),
                "variant_sha256": sha256_file(variant),
                "compile_success_required": True,
                "assertions": False,
                "receipts": receipts,
            }
        )
    write_json(result_dir / "variants" / "manifest.json", records)
    return variants, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    include_dir: Path,
    production_sources: Sequence[Path],
    rtl_path: Path,
    variant_paths: dict[str, Path],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    build_dir = profile_dir / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{TOP}.vvp"
    sources = [
        (
            variant_paths[profile.mutation]
            if profile.mutation and path == rtl_path
            else path
        )
        for path in production_sources
    ]
    defines = [FOCUSED_DEFINE]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
    if profile.kind == "mutation":
        defines.append("-DV11L_NEGATIVE_PROFILE")
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
    (
        compile_rc,
        compile_stdout,
        compile_stderr,
        compile_seconds,
        compile_timeout,
    ) = run_command(
        compile_command,
        cwd=testbench_dir,
        timeout_seconds=timeout_seconds,
    )
    (profile_dir / "compile.stdout").write_text(
        compile_stdout, encoding="utf-8"
    )
    (profile_dir / "compile.stderr").write_text(
        compile_stderr, encoding="utf-8"
    )
    (profile_dir / "compile.rc").write_text(
        f"{compile_rc}\n", encoding="utf-8"
    )

    sim_rc: int | None = None
    sim_stdout = ""
    sim_stderr = ""
    sim_seconds = 0.0
    sim_timeout = False
    if compile_rc == 0 and artifact.is_file():
        (
            sim_rc,
            sim_stdout,
            sim_stderr,
            sim_seconds,
            sim_timeout,
        ) = run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    (profile_dir / "sim.stdout").write_text(
        sim_stdout, encoding="utf-8"
    )
    (profile_dir / "sim.stderr").write_text(
        sim_stderr, encoding="utf-8"
    )
    sim_log = profile_dir / "sim.log"
    sim_log.write_text(sim_stdout + sim_stderr, encoding="utf-8")
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if sim_rc is None else f"{sim_rc}\n",
        encoding="utf-8",
    )
    artifact_exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, markers = evaluate_profile(
        profile,
        compile_rc=compile_rc,
        sim_rc=sim_rc,
        log_text=sim_stdout + sim_stderr,
        artifact_exists=artifact_exists,
    )
    record = {
        "profile": profile.name,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "expected_stage": profile.expected_stage,
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": compile_rc,
            "timeout": compile_timeout,
            "elapsed_seconds": round(compile_seconds, 6),
            "command": compile_command,
            "defines": defines,
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
            "log": repo_path(sim_log, repo_root),
            "log_sha256": sha256_file(sim_log),
        },
        "markers": markers,
        "compile_source_manifest": source_manifest(sources, repo_root),
    }
    write_json(profile_dir / "profile.json", record)
    return record


def evaluate_regression_log(test: str, text: str) -> bool:
    return (
        text.count(f"[PASS] {test}") == 1
        and text.count("[RESULT] PASS") == 1
        and "[RESULT] FAIL" not in text
        and ORACLE_FAIL not in text
    )


def run_regressions(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    regression_sources: dict[str, tuple[Path, ...]],
    timeout_seconds: int,
) -> tuple[bool, list[dict[str, object]]]:
    regression_dir = result_dir / "regressions"
    build_dir = regression_dir / "build"
    log_dir = regression_dir / "logs"
    targets = [log_dir / f"{test}.log" for test in REGRESSIONS]
    source_before = {
        test: source_manifest(regression_sources[test], repo_root)
        for test in REGRESSIONS
    }
    command = [
        "make",
        "-C",
        str(testbench_dir),
        f"RESULT_DIR={regression_dir}",
        f"BUILD_DIR={build_dir}",
        *(str(target) for target in targets),
    ]
    rc, stdout, stderr, elapsed, timed_out = run_command(
        command,
        cwd=repo_root,
        timeout_seconds=timeout_seconds,
    )
    regression_dir.mkdir(parents=True, exist_ok=True)
    (regression_dir / "make.stdout").write_text(
        stdout, encoding="utf-8"
    )
    (regression_dir / "make.stderr").write_text(
        stderr, encoding="utf-8"
    )
    (regression_dir / "make.rc").write_text(
        f"{rc}\n", encoding="utf-8"
    )
    records: list[dict[str, object]] = []
    for test, log_path in zip(REGRESSIONS, targets):
        exists = log_path.is_file()
        image = build_dir / f"{test}.vvp"
        image_exists = image.is_file() and image.stat().st_size > 0
        source_after = source_manifest(
            regression_sources[test], repo_root
        )
        text = (
            log_path.read_text(encoding="utf-8", errors="replace")
            if exists
            else ""
        )
        source_match = source_before[test] == source_after
        passed = (
            rc == 0
            and exists
            and image_exists
            and source_match
            and evaluate_regression_log(test, text)
        )
        records.append(
            {
                "test": test,
                "status": "PASS" if passed else "FAIL",
                "log": (
                    artifact_record(log_path, repo_root)
                    if exists
                    else None
                ),
                "compile_artifact": (
                    artifact_record(image, repo_root)
                    if image_exists
                    else None
                ),
                "source_pre_post_match": source_match,
                "compile_source_manifest": source_before[test],
                "compile_source_post_manifest": source_after,
            }
        )
    overall = (
        rc == 0
        and not timed_out
        and all(item["status"] == "PASS" for item in records)
    )
    write_json(
        regression_dir / "summary.json",
        {
            "status": "PASS" if overall else "FAIL",
            "command_rc": rc,
            "command": command,
            "timeout": timed_out,
            "elapsed_seconds": round(elapsed, 6),
            "all_source_pre_post_match": all(
                item["source_pre_post_match"] for item in records
            ),
            "tests": records,
        },
    )
    return overall, records


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run assert/release OooIntBackend dual retry-holder "
            "lifecycle and release-mode mutation sensitivity"
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    rtl_path = (
        repo_root
        / "npc"
        / "rv64"
        / "vsrc"
        / "execute"
        / "OooIntBackend.v"
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
        regression_sources = load_regression_context(testbench_dir)
        if rtl_path not in production_sources:
            raise RuntimeError("production OooIntBackend.v is absent")
        design_id = current_design_id(repo_root)
        runner_inputs = [
            *production_sources,
            include_dir / "define.v",
            repo_root / "npc" / "rv64" / "vsrc" / "filelist.mk",
            testbench_dir / "Makefile",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11l_memory_retry_holder_semantic.py"
            ).resolve(),
            *(
                path
                for test in REGRESSIONS
                for path in regression_sources[test]
            ),
        ]
        before = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-before.sha256", before)
        variants, variant_records = build_variants(
            result_dir=result_dir,
            rtl_path=rtl_path,
            repo_root=repo_root,
        )
        profiles = build_profiles()
        profile_records: list[dict[str, object]] = []
        for profile in profiles:
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                rtl_path=rtl_path,
                variant_paths=variants,
                iverilog=iverilog,
                vvp=vvp,
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            print(f"{profile.name}: {record['status']}")

        regression_ok, regression_records = run_regressions(
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            regression_sources=regression_sources,
            timeout_seconds=args.timeout_seconds,
        )
        after = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-after.sha256", after)
        binding_match = before == after
        passed_count = sum(
            item["status"] == "PASS" for item in profile_records
        )
        regression_pass = sum(
            item["status"] == "PASS" for item in regression_records
        )
        overall = (
            binding_match
            and passed_count == len(profile_records)
            and regression_ok
        )
        summary = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": design_id,
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "top": TOP,
                "focused_define": FOCUSED_DEFINE,
                "profile_count": len(profile_records),
                "mutation_count": len(MUTATIONS),
                "regression_count": len(REGRESSIONS),
                "baseline_assert_and_release": True,
                "mutations_release_mode": True,
                "full_system_run": False,
            },
            "tools": {
                "iverilog": str(iverilog),
                "iverilog_sha256": sha256_file(iverilog),
                "vvp": str(vvp),
                "vvp_sha256": sha256_file(vvp),
            },
            "production": {
                "rtl": repo_path(rtl_path, repo_root),
                "rtl_sha256": sha256_file(rtl_path),
                "focused_testbench": repo_path(
                    testbench_dir / "tests" / "tb_ooo_int_backend.sv",
                    repo_root,
                ),
                "focused_testbench_sha256": sha256_file(
                    testbench_dir / "tests" / "tb_ooo_int_backend.sv"
                ),
                "product_instances": [PRODUCT_INSTANCE],
            },
            "binding": {
                "pre_post_match": binding_match,
                "source_before": artifact_record(
                    result_dir / "source-before.sha256", repo_root
                ),
                "source_after": artifact_record(
                    result_dir / "source-after.sha256", repo_root
                ),
            },
            "independent_oracle": {
                "stimulus_owned_reset_allocation_schedule": True,
                "expected_tuple_uses_retry_holder_dut_state": False,
                "four_state_exact_comparison": True,
                "lane_distinct_pid_token_size_address": True,
                "simultaneous_dual_capture": True,
                "source_miq_empty_during_hold": True,
                "asymmetric_ready_10_and_01": True,
                "checks_empty_destination_before_transfer": True,
                "checks_same_edge_push_and_unique_occupancy": True,
                "checks_tracker_live_until_terminal": True,
                "checks_response_terminal_once": True,
                "checks_flush_ready_cancel_priority": True,
                "checks_lane10_lane11_acceptance": True,
                "raw_producer_x_z_rejected": True,
                "raw_token_x_z_rejected": True,
                "release_mode_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": passed_count,
                "profiles_fail": len(profile_records) - passed_count,
                "mutations_total": len(MUTATIONS),
                "regressions_total": len(regression_records),
                "regressions_pass": regression_pass,
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "semantic_units": list(UNIT_IDS),
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_rerun": {
                    "triggered_by_v11l": False,
                    "reason": (
                        "production RTL is unchanged; this slice adds "
                        "macro-isolated testbench and evidence tooling"
                    ),
                    "run": False,
                },
            },
            "promotion": {
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        write_json(result_dir / "summary.json", summary)
        lines = [
            "# V11L OooIntBackend dual retry-holder semantic evidence",
            "",
            f"- status: {summary['status']}",
            f"- profiles: {passed_count}/{len(profile_records)} PASS",
            f"- release mutations: {len(MUTATIONS)}",
            (
                "- regressions: "
                f"{regression_pass}/{len(regression_records)} PASS"
            ),
            (
                "- source pre/post: "
                f"{'MATCH' if binding_match else 'DRIFT'}"
            ),
            "- production RTL change: none",
            "- full-system run: not executed",
            "- architecture/PPA promotion: stopped",
            "",
            "## Profiles",
            "",
            *(
                f"- {item['profile']}: {item['status']}"
                for item in profile_records
            ),
            "",
            "## Regressions",
            "",
            *(
                f"- {item['test']}: {item['status']}"
                for item in regression_records
            ),
        ]
        (result_dir / "summary.md").write_text(
            "\n".join(lines) + "\n", encoding="utf-8"
        )
        atomic_status(status_path, "PASS" if overall else "FAIL")
        return 0 if overall else 1
    except Exception as exc:
        write_json(
            result_dir / "runner-error.json",
            {
                "schema": SCHEMA,
                "error": type(exc).__name__,
                "message": str(exc),
            },
        )
        atomic_status(status_path, "FAIL")
        print(f"V11L runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
