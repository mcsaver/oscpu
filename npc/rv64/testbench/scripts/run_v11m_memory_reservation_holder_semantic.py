#!/usr/bin/env python3
"""Run V11M dual memory-reservation holder semantic evidence."""

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


SCHEMA = "npc-rv64-v11m-memory-reservation-holder-semantic-evidence-v2"
TOP = "tb_ooo_int_backend"
FOCUSED_DEFINE = "-DV11M_MEMORY_RESERVATION_HOLDER_FOCUSED"
TB_PASS = "[PASS] tb_ooo_int_backend_v11m_memory_reservation_holder"
MATRIX_PASS = "[V11M-RESERVATION-HOLDER-MATRIX][PASS]"
ORACLE_FAIL = "[V11M-RESERVATION-HOLDER-ORACLE][FAIL]"
UNIT_IDS = (
    "memory-reservation-producer",
    "memory-reservation-token",
    "memory-reservation1-producer",
    "memory-reservation1-token",
)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
    "u_decode_backend.u_int_backend"
)
REGRESSIONS = (
    "tb_ooo_int_backend",
    "tb_ooo_int_backend_v11l_memory_retry_holder",
    "tb_ooo_int_backend_v11i_terminal_lifecycle",
)
BASELINE_MARKERS = {
    "[V11M-BIRTH-CREDIT-ATOMIC][PASS]": 1,
    "[V11M-FULL-WIDTH-IDENTITY][PASS]": 1,
    "[V11M-HOLD-TUPLE][PASS]": 1,
    "[V11M-ASYMMETRIC-TRANSFER][PASS]": 1,
    "[V11M-LOCAL0-LANE6-EXACT][PASS]": 1,
    "[V11M-LOCAL1-LANE7-EXACT][PASS]": 1,
    "[V11M-SELECTIVE-RECOVERY][PASS]": 1,
    "[V11M-GLOBAL-FLUSH][PASS]": 1,
    "[V11M-PAIR-TURNOVER][PASS]": 1,
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


R0_PRODUCER = "memory-reservation-producer"
R0_TOKEN = "memory-reservation-token"
R1_PRODUCER = "memory-reservation1-producer"
R1_TOKEN = "memory-reservation1-token"
R0_UNITS = (R0_PRODUCER, R0_TOKEN)
R1_UNITS = (R1_PRODUCER, R1_TOKEN)


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


R0_HOLD_TAIL = """\
    end else if (mem_issue_res_consume_fire_w) begin
      mem_issue_res_valid_q <= 1'b0;
    end
  end

  always @(posedge clk) begin
"""
R1_HOLD_TAIL = """\
    end else if (mem_issue1_res_consume_fire_w) begin
      mem_issue1_res_valid_q <= 1'b0;
    end
  end

`ifdef OOO_ASSERT
"""
R0_CONSUME = """\
  assign mem_issue_res_consume_fire_w =
      ENABLE_DUAL_MEM ?
      (mem_issue_res_dual_local_consume_w || issue0_mem_request_fire_w) :
      (mem_issue_res_valid_q && mem_issue_res_ready_w);
"""
R1_CONSUME = """\
  assign mem_issue1_res_consume_fire_w =
      ENABLE_DUAL_MEM ?
      (mem_issue1_res_dual_local_consume_w || issue1_mem_request_fire_w) :
      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&
       mem_issue1_res_ready_w);
"""
R0_REQUEST_TOKEN = """\
  assign mem_req_owner_token_o = grant_sq_w ? sq_drain_owner_token_w :
      grant_amo_write_w ? mem_owner_token_q :
      grant_buffer_w ? mem_buffer_owner_token_q :
      grant_retry0_w ? mem_retry0_owner_token_q :
      grant_issue0_w ? mem_issue_res_owner_token_q :
                       mem_issue1_res_owner_token_q;
"""
R1_REQUEST_TOKEN = """\
  assign mem1_req_owner_token_o = grant_retry1_w ?
      mem_retry1_owner_token_q : grant_mem1_issue0_w ?
      mem_issue_res_owner_token_q : mem_issue1_res_owner_token_q;
"""
R0_TERMINAL = """\
  wire mem_issue_res_tagged_terminal_w =
      (mem_issue_res_owner_kind_q != MEM_OWNER_STORE) &&
      (mem_issue_res_local_complete_w || mem_issue_res_kill_w ||
       mem_issue_res_global_cancel_w);
"""
R1_TERMINAL = """\
  wire mem_issue1_res_tagged_terminal_w =
      (mem_issue1_res_owner_kind_q != MEM_OWNER_STORE) &&
      (mem_issue1_res_local_complete_w || mem_issue1_res_kill_w ||
       mem_issue1_res_global_cancel_w);
"""
R0_KILL = """\
  wire mem_issue_res_kill_w =
      branch_resolve_mispredict_w && mem_issue_res_valid_q &&
      ((mem_issue_res_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
"""
R1_KILL = """\
  wire mem_issue1_res_kill_w =
      branch_resolve_mispredict_w && mem_issue1_res_valid_q &&
      ((mem_issue1_res_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
"""
R0_DUAL_CANDIDATE = """\
  wire issue0_dual_transport_candidate_w = ENABLE_DUAL_MEM &&
      mem_issue_res_valid_q && issue0_mem_issue_eligible_w &&
      !issue0_mem_exception_w && !issue0_sq_fwd_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w;
"""
R1_DUAL_CANDIDATE = """\
  wire issue1_dual_transport_candidate_w = ENABLE_DUAL_MEM &&
      mem_issue1_res_valid_q && issue1_is_mem_w && !issue1_is_amo_w &&
      !mem_issue_block_w && issue1_mem_order_ready_w &&
      (!issue1_is_load_w || lq_issue1_open_w) &&
      !issue1_mem_exception_w && !issue1_sq_fwd_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w;
"""


MUTATIONS = (
    Mutation(
        "pair-capture0-ignores-credit1",
        R0_UNITS,
        "pair-credit-atomic",
        (
            replacement(
                """\
  wire mem_issue_res_capture_w =
      mem_issue_res_capture_candidate_w && mem_owner_alloc0_ready_w &&
      (!mem_issue1_res_capture_candidate_w || mem_owner_alloc1_ready_w);
""",
                """\
  wire mem_issue_res_capture_w =
      mem_issue_res_capture_candidate_w && mem_owner_alloc0_ready_w;
""",
                "allow lane0 reservation birth without lane1 tracker credit",
            ),
        ),
    ),
    Mutation(
        "reservation0-producer-cross-lane",
        (R0_PRODUCER,),
        "reservation0-holder-tuple",
        (
            replacement(
                "      mem_issue_res_producer_id_q <= "
                "iq_issue0_producer_id_w;\n",
                "      mem_issue_res_producer_id_q <= "
                "issue1_producer_id_w;\n",
                "capture lane1 full ProducerId in reservation0",
            ),
        ),
    ),
    Mutation(
        "reservation1-producer-cross-lane",
        (R1_PRODUCER,),
        "reservation1-holder-tuple",
        (
            replacement(
                "      mem_issue1_res_producer_id_q <= "
                "issue1_producer_id_w;\n",
                "      mem_issue1_res_producer_id_q <= "
                "iq_issue0_producer_id_w;\n",
                "capture lane0 full ProducerId in reservation1",
            ),
        ),
    ),
    Mutation(
        "reservation0-token-cross-lane",
        (R0_TOKEN,),
        "reservation0-holder-tuple",
        (
            replacement(
                "      mem_issue_res_owner_token_q <= "
                "mem_owner_alloc0_token_w;\n",
                "      mem_issue_res_owner_token_q <= "
                "mem_owner_alloc1_token_w;\n",
                "capture lane1 token in reservation0",
            ),
        ),
    ),
    Mutation(
        "reservation1-token-cross-lane",
        (R1_TOKEN,),
        "reservation1-holder-tuple",
        (
            replacement(
                "      mem_issue1_res_owner_token_q <= "
                "mem_owner_alloc1_token_w;\n",
                "      mem_issue1_res_owner_token_q <= "
                "mem_owner_alloc0_token_w;\n",
                "capture lane0 token in reservation1",
            ),
        ),
    ),
    Mutation(
        "reservation0-producer-generation-truncate",
        (R0_PRODUCER,),
        "reservation0-holder-tuple",
        (
            replacement(
                "      mem_issue_res_producer_id_q <= "
                "iq_issue0_producer_id_w;\n",
                "      mem_issue_res_producer_id_q <= "
                "{{PRODUCER_GEN_W{1'b0}}, "
                "iq_issue0_producer_id_w[ROB_INDEX_W-1:0]};\n",
                "truncate reservation0 ProducerId generation bits",
            ),
        ),
    ),
    Mutation(
        "reservation1-producer-generation-truncate",
        (R1_PRODUCER,),
        "reservation1-holder-tuple",
        (
            replacement(
                "      mem_issue1_res_producer_id_q <= "
                "issue1_producer_id_w;\n",
                "      mem_issue1_res_producer_id_q <= "
                "{{PRODUCER_GEN_W{1'b0}}, "
                "issue1_producer_id_w[ROB_INDEX_W-1:0]};\n",
                "truncate reservation1 ProducerId generation bits",
            ),
        ),
    ),
    Mutation(
        "reservation0-token-high-truncate",
        (R0_TOKEN,),
        "reservation0-holder-tuple",
        (
            replacement(
                "      mem_issue_res_owner_token_q <= "
                "mem_owner_alloc0_token_w;\n",
                "      mem_issue_res_owner_token_q <= "
                "{3'b000, mem_owner_alloc0_token_w[1:0]};\n",
                "truncate reservation0 owner-token high bits",
            ),
        ),
    ),
    Mutation(
        "reservation1-token-high-truncate",
        (R1_TOKEN,),
        "reservation1-holder-tuple",
        (
            replacement(
                "      mem_issue1_res_owner_token_q <= "
                "mem_owner_alloc1_token_w;\n",
                "      mem_issue1_res_owner_token_q <= "
                "{3'b000, mem_owner_alloc1_token_w[1:0]};\n",
                "truncate reservation1 owner-token high bits",
            ),
        ),
    ),
    *tuple(
        Mutation(
            f"reservation{lane}-{field}-{state}",
            (unit,),
            f"reservation{lane}-holder-tuple",
            (
                replacement(
                    anchor,
                    value,
                    f"inject {state.upper()} into reservation{lane} {field}",
                ),
            ),
        )
        for lane, field, unit, anchor, x_value, z_value in (
            (
                0,
                "producer",
                R0_PRODUCER,
                "      mem_issue_res_producer_id_q <= "
                "iq_issue0_producer_id_w;\n",
                "      mem_issue_res_producer_id_q <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "      mem_issue_res_producer_id_q <= "
                "{PRODUCER_ID_W{1'bz}};\n",
            ),
            (
                0,
                "token",
                R0_TOKEN,
                "      mem_issue_res_owner_token_q <= "
                "mem_owner_alloc0_token_w;\n",
                "      mem_issue_res_owner_token_q <= 5'bxxxxx;\n",
                "      mem_issue_res_owner_token_q <= 5'bzzzzz;\n",
            ),
            (
                1,
                "producer",
                R1_PRODUCER,
                "      mem_issue1_res_producer_id_q <= "
                "issue1_producer_id_w;\n",
                "      mem_issue1_res_producer_id_q <= "
                "{PRODUCER_ID_W{1'bx}};\n",
                "      mem_issue1_res_producer_id_q <= "
                "{PRODUCER_ID_W{1'bz}};\n",
            ),
            (
                1,
                "token",
                R1_TOKEN,
                "      mem_issue1_res_owner_token_q <= "
                "mem_owner_alloc1_token_w;\n",
                "      mem_issue1_res_owner_token_q <= 5'bxxxxx;\n",
                "      mem_issue1_res_owner_token_q <= 5'bzzzzz;\n",
            ),
        )
        for state, value in (("x", x_value), ("z", z_value))
    ),
    *tuple(
        Mutation(
            f"reservation{lane}-{field}-hold-drift",
            (unit,),
            f"reservation{lane}-holder-tuple",
            (
                replacement(
                    tail,
                    tail.replace(
                        "    end\n  end\n",
                        f"    end else if ({valid}) begin\n"
                        f"      {target} <= {expr};\n"
                        "    end\n  end\n",
                        1,
                    ),
                    f"drift reservation{lane} {field} under READY=00",
                ),
            ),
        )
        for lane, field, unit, tail, valid, target, expr in (
            (
                0,
                "producer",
                R0_PRODUCER,
                R0_HOLD_TAIL,
                "mem_issue_res_valid_q",
                "mem_issue_res_producer_id_q",
                "mem_issue_res_producer_id_q ^ "
                "{{(PRODUCER_ID_W-1){1'b0}}, 1'b1}",
            ),
            (
                0,
                "token",
                R0_TOKEN,
                R0_HOLD_TAIL,
                "mem_issue_res_valid_q",
                "mem_issue_res_owner_token_q",
                "mem_issue_res_owner_token_q ^ 5'b00001",
            ),
            (
                1,
                "producer",
                R1_PRODUCER,
                R1_HOLD_TAIL,
                "mem_issue1_res_valid_q",
                "mem_issue1_res_producer_id_q",
                "mem_issue1_res_producer_id_q ^ "
                "{{(PRODUCER_ID_W-1){1'b0}}, 1'b1}",
            ),
            (
                1,
                "token",
                R1_TOKEN,
                R1_HOLD_TAIL,
                "mem_issue1_res_valid_q",
                "mem_issue1_res_owner_token_q",
                "mem_issue1_res_owner_token_q ^ 5'b00001",
            ),
        )
    ),
    Mutation(
        "reservation0-early-valid-death",
        R0_UNITS,
        "reservation0-holder-tuple",
        (
            replacement(
                "    end else if (mem_issue_res_consume_fire_w) begin\n",
                "    end else if (mem_issue_res_consume_fire_w || "
                "mem_issue_res_valid_q) begin\n",
                "clear reservation0 without a terminal event",
            ),
        ),
    ),
    Mutation(
        "reservation1-early-valid-death",
        R1_UNITS,
        "reservation1-holder-tuple",
        (
            replacement(
                "    end else if (mem_issue1_res_consume_fire_w) begin\n",
                "    end else if (mem_issue1_res_consume_fire_w || "
                "mem_issue1_res_valid_q) begin\n",
                "clear reservation1 without a terminal event",
            ),
        ),
    ),
    Mutation(
        "reservation0-consumes-on-valid",
        R0_UNITS,
        "ready00-hold-event",
        (
            replacement(
                R0_CONSUME,
                R0_CONSUME.replace(
                    "issue0_mem_request_fire_w",
                    "issue0_mem_req_valid_w",
                ),
                "consume reservation0 on request valid instead of fire",
            ),
        ),
    ),
    Mutation(
        "reservation1-consumes-on-valid",
        R1_UNITS,
        "ready00-hold-event",
        (
            replacement(
                R1_CONSUME,
                R1_CONSUME.replace(
                    "issue1_mem_request_fire_w",
                    "issue1_mem_req_valid_w",
                ),
                "consume reservation1 on request valid instead of fire",
            ),
        ),
    ),
    Mutation(
        "request0-token-cross-lane",
        (R0_TOKEN,),
        "request0-transfer",
        (
            replacement(
                R0_REQUEST_TOKEN,
                R0_REQUEST_TOKEN.replace(
                    "grant_issue0_w ? mem_issue_res_owner_token_q",
                    "grant_issue0_w ? mem_issue1_res_owner_token_q",
                ),
                "drive lane0 request with reservation1 token",
            ),
        ),
    ),
    Mutation(
        "request1-token-cross-lane",
        (R1_TOKEN,),
        "request1-transfer",
        (
            replacement(
                R1_REQUEST_TOKEN,
                R1_REQUEST_TOKEN.replace(
                    ": mem_issue1_res_owner_token_q;",
                    ": mem_issue_res_owner_token_q;",
                ),
                "drive lane1 request with reservation0 token",
            ),
        ),
    ),
    Mutation(
        "reservation0-terminal-tieoff",
        R0_UNITS,
        "local0-terminal",
        (
            replacement(
                R0_TERMINAL,
                "  wire mem_issue_res_tagged_terminal_w = 1'b0;\n",
                "remove reservation0 collector terminal",
            ),
        ),
    ),
    Mutation(
        "reservation1-terminal-tieoff",
        R1_UNITS,
        "local1-terminal",
        (
            replacement(
                R1_TERMINAL,
                "  wire mem_issue1_res_tagged_terminal_w = 1'b0;\n",
                "remove reservation1 collector terminal",
            ),
        ),
    ),
    Mutation(
        "reservation-terminal-token-swap",
        (R0_TOKEN, R1_TOKEN),
        "local0-terminal",
        (
            replacement(
                """\
      mem_issue1_res_owner_token_q,
      mem_issue_res_owner_token_q,
""",
                """\
      mem_issue_res_owner_token_q,
      mem_issue1_res_owner_token_q,
""",
                "swap collector lane6/lane7 reservation tokens",
            ),
        ),
    ),
    Mutation(
        "reservation1-selective-kill-disabled",
        R1_UNITS,
        "selective-recovery",
        (
            replacement(
                R1_KILL,
                "  wire mem_issue1_res_kill_w = 1'b0;\n",
                "retain younger reservation1 across selective recovery",
            ),
        ),
    ),
    Mutation(
        "reservation0-selective-survivor-killed",
        R0_UNITS,
        "selective-recovery",
        (
            replacement(
                R0_KILL,
                R0_KILL.replace(
                    ") >\n       (branch_resolve_rob_idx_o",
                    ") >=\n       (branch_resolve_rob_idx_o",
                ),
                "kill the inclusive selective-recovery boundary",
            ),
        ),
    ),
    Mutation(
        "reservation0-global-cancel-disabled",
        R0_UNITS,
        "selective-survivor-flush",
        (
            replacement(
                """\
  wire mem_issue_res_global_cancel_w =
      (flush_i || checkpoint_restore_apply_w) && mem_issue_res_valid_q;
""",
                "  wire mem_issue_res_global_cancel_w = 1'b0;\n",
                "remove reservation0 global cancel terminal",
            ),
        ),
    ),
    Mutation(
        "reservation1-global-cancel-disabled",
        R1_UNITS,
        "global-flush-priority",
        (
            replacement(
                """\
  wire mem_issue1_res_global_cancel_w =
      (flush_i || checkpoint_restore_apply_w) && mem_issue1_res_valid_q;
""",
                "  wire mem_issue1_res_global_cancel_w = 1'b0;\n",
                "remove reservation1 global cancel terminal",
            ),
        ),
    ),
    Mutation(
        "reservation0-recovery-request-open",
        R0_UNITS,
        "selective-recovery",
        (
            replacement(
                R0_DUAL_CANDIDATE,
                R0_DUAL_CANDIDATE.replace(
                    "      !branch_resolve_mispredict_w && !issue_block_w;\n",
                    "      !issue_block_w;\n",
                ),
                "allow survivor lane0 request during recovery",
            ),
        ),
    ),
    Mutation(
        "reservation1-recovery-request-open",
        R1_UNITS,
        "selective-recovery",
        (
            replacement(
                R1_DUAL_CANDIDATE,
                R1_DUAL_CANDIDATE.replace(
                    "      !branch_resolve_mispredict_w && !issue_block_w;\n",
                    "      !issue_block_w;\n",
                ),
                "allow killed lane1 request during recovery",
            ),
        ),
    ),
    Mutation(
        "pair-turnover-disabled",
        UNIT_IDS,
        "pair-turnover",
        (
            replacement(
                """\
  wire mem_issue_pair_turnover_capture_w =
      mem_issue_pair_turnover_capture_candidate_w &&
      mem_owner_alloc0_ready_w && mem_owner_alloc1_ready_w;
""",
                "  wire mem_issue_pair_turnover_capture_w = 1'b0;\n",
                "disable exact dual reservation turnover",
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


def artifact_record(path: Path, repo_root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, repo_root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


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
        result[marker] = text.count(marker)
    return result


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
    markers = marker_counts(log_text)
    stages = oracle_failure_stages(log_text)
    compile_ok = (
        compile_rc == 0
        and not compile_timeout
        and artifact_exists
    )
    if profile.kind == "baseline":
        passed = (
            compile_ok
            and sim_rc == 0
            and not sim_timeout
            and markers["tb_pass"] == 1
            and markers["matrix_pass"] == 1
            and markers["oracle_fail"] == 0
            and not stages
            and all(
                markers[marker] == count
                for marker, count in BASELINE_MARKERS.items()
            )
        )
    else:
        passed = (
            compile_ok
            and sim_rc not in (None, 0)
            and not sim_timeout
            and markers["oracle_fail"] == 1
            and stages == [profile.expected_stage]
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
    sibling = iverilog.parent / "vvp"
    vvp_raw = str(sibling) if sibling.is_file() else shutil.which("vvp")
    if not vvp_raw:
        raise RuntimeError("vvp was not found")
    return iverilog, Path(vvp_raw).resolve()


def load_make_context(
    testbench_dir: Path,
) -> tuple[Path, tuple[Path, ...]]:
    completed = subprocess.run(
        ["make", "-s", "print-v11m-memory-reservation-holder-context"],
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
        raise RuntimeError("V11M Makefile context is incomplete")
    return include_dir, tuple(sources)


def load_regression_context(
    testbench_dir: Path,
) -> dict[str, tuple[Path, ...]]:
    completed = subprocess.run(
        [
            "make",
            "-s",
            "print-v11m-memory-reservation-holder-regression-context",
        ],
        cwd=testbench_dir,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip())
    common: list[Path] = []
    sources = {test: [] for test in REGRESSIONS}
    prefix = "REGRESSION_SOURCE_"
    for line in completed.stdout.splitlines():
        if line.startswith("REGRESSION_COMMON="):
            common.append(Path(line.split("=", 1)[1]).resolve())
        elif line.startswith(prefix):
            key, raw = line.split("=", 1)
            test = key[len(prefix):]
            if test not in sources:
                raise RuntimeError(f"unknown regression context: {test}")
            sources[test].append(Path(raw).resolve())
    result = {
        test: tuple(sorted({*paths, *common}))
        for test, paths in sources.items()
    }
    if not common or any(not paths for paths in result.values()):
        raise RuntimeError("V11M regression context is incomplete")
    return result


def source_manifest(
    paths: Sequence[Path], repo_root: Path
) -> dict[str, str]:
    return {
        repo_path(path, repo_root): sha256_file(path)
        for path in sorted({item.resolve() for item in paths})
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
    variants: dict[str, Path],
    iverilog: Path,
    vvp: Path,
    timeout_seconds: int,
) -> dict[str, object]:
    profile_dir = result_dir / "profiles" / profile.name
    profile_dir.mkdir(parents=True, exist_ok=True)
    artifact = profile_dir / f"{TOP}.vvp"
    sources = [
        variants[profile.mutation]
        if profile.mutation and path == rtl_path
        else path
        for path in production_sources
    ]
    defines = [FOCUSED_DEFINE]
    if profile.assertions:
        defines.append("-DOOO_ASSERT")
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
    crc, cout, cerr, cseconds, ctimeout = run_command(
        compile_command, cwd=testbench_dir, timeout_seconds=timeout_seconds
    )
    (profile_dir / "compile.stdout").write_text(cout, encoding="utf-8")
    (profile_dir / "compile.stderr").write_text(cerr, encoding="utf-8")
    (profile_dir / "compile.rc").write_text(f"{crc}\n", encoding="utf-8")
    src, sout, serr, sseconds, stimeout = (None, "", "", 0.0, False)
    if crc == 0 and artifact.is_file():
        src, sout, serr, sseconds, stimeout = run_command(
            [str(vvp), str(artifact)],
            cwd=testbench_dir,
            timeout_seconds=timeout_seconds,
        )
    log = profile_dir / "sim.log"
    log.write_text(sout + serr, encoding="utf-8")
    (profile_dir / "sim.rc").write_text(
        "NOT_RUN\n" if src is None else f"{src}\n", encoding="utf-8"
    )
    exists = artifact.is_file() and artifact.stat().st_size > 0
    passed, markers = evaluate_profile(
        profile,
        compile_rc=crc,
        compile_timeout=ctimeout,
        sim_rc=src,
        sim_timeout=stimeout,
        log_text=sout + serr,
        artifact_exists=exists,
    )
    record = {
        "profile": profile.name,
        "kind": profile.kind,
        "assertions": profile.assertions,
        "mutation": profile.mutation,
        "expected_stage": profile.expected_stage,
        "status": "PASS" if passed else "FAIL",
        "compile": {
            "rc": crc,
            "timeout": ctimeout,
            "elapsed_seconds": round(cseconds, 6),
            "command": compile_command,
            "defines": defines,
            "artifact": repo_path(artifact, repo_root),
            "artifact_exists": exists,
            "artifact_sha256": sha256_file(artifact) if exists else None,
        },
        "simulation": {
            "rc": src,
            "timeout": stimeout,
            "elapsed_seconds": round(sseconds, 6),
            "log": repo_path(log, repo_root),
            "log_sha256": sha256_file(log),
        },
        "markers": markers,
        "compile_source_manifest": source_manifest(sources, repo_root),
    }
    write_json(profile_dir / "profile.json", record)
    return record


def run_regressions(
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    contexts: dict[str, tuple[Path, ...]],
    timeout_seconds: int,
) -> tuple[bool, list[dict[str, object]]]:
    regression_dir = result_dir / "regressions"
    build_dir = regression_dir / "build"
    log_dir = regression_dir / "logs"
    targets = [log_dir / f"{test}.log" for test in REGRESSIONS]
    before = {
        test: source_manifest(contexts[test], repo_root)
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
        command, cwd=repo_root, timeout_seconds=timeout_seconds
    )
    regression_dir.mkdir(parents=True, exist_ok=True)
    (regression_dir / "make.stdout").write_text(stdout, encoding="utf-8")
    (regression_dir / "make.stderr").write_text(stderr, encoding="utf-8")
    records: list[dict[str, object]] = []
    for test, log in zip(REGRESSIONS, targets):
        text = (
            log.read_text(encoding="utf-8", errors="replace")
            if log.is_file()
            else ""
        )
        after = source_manifest(contexts[test], repo_root)
        image = build_dir / f"{test}.vvp"
        image_exists = image.is_file() and image.stat().st_size > 0
        passed = (
            rc == 0
            and log.is_file()
            and image_exists
            and before[test] == after
            and text.count(f"[PASS] {test}") == 1
            and text.count("[RESULT] PASS") == 1
            and "[RESULT] FAIL" not in text
        )
        records.append(
            {
                "test": test,
                "status": "PASS" if passed else "FAIL",
                "source_pre_post_match": before[test] == after,
                "compile_source_manifest": before[test],
                "compile_source_post_manifest": after,
                "log": artifact_record(log, repo_root)
                if log.is_file()
                else None,
                "compile_artifact": artifact_record(image, repo_root)
                if image_exists
                else None,
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
            "command": command,
            "command_rc": rc,
            "timeout": timed_out,
            "elapsed_seconds": round(elapsed, 6),
            "tests": records,
            "all_source_pre_post_match": all(
                item["source_pre_post_match"] for item in records
            ),
        },
    )
    return overall, records


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
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
    if result_dir.exists() and any(result_dir.iterdir()):
        if not args.overwrite:
            print(f"result directory is not empty: {result_dir}")
            return 2
        shutil.rmtree(result_dir)
    result_dir.mkdir(parents=True, exist_ok=True)
    atomic_status(status_path, "RUNNING")
    try:
        iverilog, vvp = resolve_tools()
        include_dir, production_sources = load_make_context(testbench_dir)
        regressions = load_regression_context(testbench_dir)
        if rtl_path not in production_sources:
            raise RuntimeError("production OooIntBackend.v is absent")
        runner_inputs = [
            *production_sources,
            include_dir / "define.v",
            testbench_dir / "Makefile",
            Path(__file__).resolve(),
            Path(__file__).with_name(
                "test_run_v11m_memory_reservation_holder_semantic.py"
            ).resolve(),
            *(path for test in REGRESSIONS for path in regressions[test]),
        ]
        before = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-before.sha256", before)
        variants, variant_records = build_variants(
            result_dir=result_dir,
            rtl_path=rtl_path,
            repo_root=repo_root,
        )
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            record = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                include_dir=include_dir,
                production_sources=production_sources,
                rtl_path=rtl_path,
                variants=variants,
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
            contexts=regressions,
            timeout_seconds=args.timeout_seconds,
        )
        after = source_manifest(runner_inputs, repo_root)
        write_sha256_manifest(result_dir / "source-after.sha256", after)
        binding_match = before == after
        profiles_pass = sum(
            item["status"] == "PASS" for item in profile_records
        )
        regressions_pass = sum(
            item["status"] == "PASS" for item in regression_records
        )
        overall = (
            binding_match
            and profiles_pass == len(profile_records)
            and regression_ok
        )
        summary = {
            "schema": SCHEMA,
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "status": "PASS" if overall else "FAIL",
            "classification": "verification",
            "design_id": current_design_id(repo_root),
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
                "expected_tuple_uses_reservation_dut_state": False,
                "four_state_exact_comparison": True,
                "nonzero_lane_distinct_producer_generation": True,
                "owner_token_high_bits_exercised": True,
                "pair_credit_atomicity": True,
                "ready00_full_tuple_hold": True,
                "asymmetric_ready_10_and_01": True,
                "request_to_miq_exact_transfer": True,
                "collector_lane6_lane7_acceptance": True,
                "selective_and_global_recovery": True,
                "pair_turnover_old_and_new_identity": True,
                "raw_producer_token_x_z_rejected": True,
                "release_mode_mutation_rejection": True,
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": profiles_pass,
                "profiles_fail": len(profile_records) - profiles_pass,
                "mutations_total": len(MUTATIONS),
                "regressions_total": len(regression_records),
                "regressions_pass": regressions_pass,
            },
            "variants": variant_records,
            "profiles": profile_records,
            "regressions": regression_records,
            "scope": {
                "semantic_units": list(UNIT_IDS),
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_frozen_evidence_unchanged": True,
                "system_rerun": {
                    "triggered_by_v11m": False,
                    "reason": (
                        "production RTL is unchanged; V11M adds only "
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
        (result_dir / "summary.md").write_text(
            "\n".join(
                [
                    "# V11M dual memory-reservation holder evidence",
                    "",
                    f"- status: {summary['status']}",
                    f"- profiles: {profiles_pass}/{len(profile_records)} PASS",
                    f"- release mutations: {len(MUTATIONS)}",
                    (
                        "- regressions: "
                        f"{regressions_pass}/{len(regression_records)} PASS"
                    ),
                    (
                        "- source pre/post: "
                        f"{'MATCH' if binding_match else 'DRIFT'}"
                    ),
                    "- production RTL change: none",
                    "- full-system run: not executed; A3 remains frozen",
                    "- whole architecture: RED",
                    "- PPA: UNPROMOTED",
                ]
            )
            + "\n",
            encoding="utf-8",
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
        print(f"V11M runner failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
