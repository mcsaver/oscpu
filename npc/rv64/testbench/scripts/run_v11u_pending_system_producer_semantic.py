#!/usr/bin/env python3
"""Run current-source pending-system ProducerId lifecycle evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shlex
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA = "npc-rv64-v11u-pending-system-producer-semantic-evidence-v2"
UNIT_IDS = ("pending-system-producer",)
PRODUCT_INSTANCE = (
    "NpcTop.u_core.u_ooo_core.u_control_plane."
    "u_pending_system_sequencer"
)
GEN_WIDTHS = (1, 4)
BASE_IVFLAGS = "-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon"

SEQUENCER = "npc/rv64/vsrc/control/OooPendingSystemSequencer.v"
CSR_MUX = "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v"
CONTROL_PLANE = "npc/rv64/vsrc/control/OooControlPlane.v"
CORE_TOP_GLUE = "npc/rv64/vsrc/core/OooCoreTopGlue.v"
EXECUTE_BACKEND = "npc/rv64/vsrc/execute/OooExecuteBackend.v"
ALU_CORE_SLICE = "npc/rv64/vsrc/execute/OooAluCoreSlice.v"
ALU_DECODE_BACKEND = "npc/rv64/vsrc/decode/OooAluDecodeBackend.v"
INT_BACKEND = "npc/rv64/vsrc/execute/OooIntBackend.v"
DISPATCH_BACKEND = "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v"
ROB = "npc/rv64/vsrc/writeback/OooRob.v"
PENDING_DISPATCH_ARBITER = (
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v"
)
PENDING_DRAIN_RESOLVE_GATE = (
    "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v"
)
PENDING_SYSTEM_ADMISSION_CANCEL_GATE = (
    "npc/rv64/vsrc/control/OooPendingSystemAdmissionCancelGate.v"
)
DEFINE = "npc/rv64/vsrc/include/define.v"
TB_SEQUENCER = "npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv"
TB_LEASE_PROBE = (
    "npc/rv64/testbench/tests/tb_ooo_pending_system_lease_probe.sv"
)
TB_CSR_MUX = "npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv"
TB_INT_BACKEND = "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
TB_PRIV_SYSTEM = "npc/rv64/testbench/tests/tb_ooo_priv_system.sv"
MAKEFILE = "npc/rv64/testbench/Makefile"
FILELIST = "npc/rv64/vsrc/filelist.mk"
RESULT_CHECKER = "npc/rv64/testbench/scripts/check_tb_result.py"
COMMON_TB = "npc/rv64/testbench/common/tb_common.svh"
COMMON_ENCODE = "npc/rv64/testbench/common/rv32_encode.svh"

TEST_SEQUENCER = "tb_ooo_pending_system_sequencer"
TEST_LEASE_PROBE = "tb_ooo_pending_system_lease_probe"
TEST_CSR_MUX = "tb_ooo_csr_access_request_mux"
TEST_INT_BACKEND = "tb_ooo_int_backend"
TEST_PRIV_SYSTEM = "tb_ooo_priv_system"

PARENT_RTL = (
    CONTROL_PLANE,
    CORE_TOP_GLUE,
    EXECUTE_BACKEND,
    ALU_CORE_SLICE,
    ALU_DECODE_BACKEND,
    DISPATCH_BACKEND,
)

COMPILE_CLAIM_RTL = (
    ROB,
    PENDING_DISPATCH_ARBITER,
    PENDING_DRAIN_RESOLVE_GATE,
    PENDING_SYSTEM_ADMISSION_CANCEL_GATE,
)

REGRESSIONS = (
    TEST_SEQUENCER,
    TEST_CSR_MUX,
    "tb_ooo_pending_system_admission_cancel_gate",
    "tb_ooo_pending_drain_resolve_gate",
)


@dataclass(frozen=True)
class Replacement:
    anchor: str
    replacement: str
    purpose: str


@dataclass(frozen=True)
class Mutation:
    name: str
    source: str
    override: str
    test: str
    expected_marker: str
    replacements: tuple[Replacement, ...]
    widths: tuple[int, ...] = (4,)
    extra_defines: tuple[str, ...] = ()
    assertions: bool = False


@dataclass(frozen=True)
class Profile:
    name: str
    kind: str
    tests: tuple[str, ...]
    gen_width: int
    assertions: bool = False
    extra_defines: tuple[str, ...] = ()
    required_markers: tuple[tuple[str, str, int], ...] = ()
    expected_failure_marker: str | None = None
    mutation: str | None = None


def replacement(anchor: str, value: str, purpose: str) -> Replacement:
    return Replacement(anchor, value, purpose)


DISPATCH_BIRTH = """\
  wire dispatch_birth_w =
      dispatch_fire_i && valid_q && (kind_q == SERIAL_KIND_CSR) && !dispatched_q &&
      !producer_valid_q && !clear_i;
"""
PENDING_MASK_UNION = """\
      clmul_owner_producer_live_mask_w |
      fp_producer_live_mask_w |
      pending_system_producer_live_mask_w |
      transient_producer_live_mask_w;
"""
CORE_TOP_EXECUTE_PENDING_VALID = """\
    .pending_branch_rs2_data_w(pending_branch_rs2_data_w),
    .pending_system_producer_valid_w(pending_system_producer_valid_w),
    .pending_system_producer_id_w(pending_system_producer_id_w),
"""
INT_BACKEND_INITIAL_ANCHOR = """\
`elsif V11I_TERMINAL_LIFECYCLE_FOCUSED
    run_v11i_terminal_lifecycle_after_lq_clear();
"""
INT_BACKEND_FINISH_ANCHOR = """\
`elsif V11I_TERMINAL_LIFECYCLE_FOCUSED
        tb_finish("tb_ooo_int_backend_v11i_terminal_lifecycle");
"""
PRIV_DECLARATION_ANCHOR = """\
  integer cycle_count;
  integer commit_total;
"""
PRIV_RESET_ANCHOR = """\
      cycle_count = 0;
      commit_total = 0;
"""
PRIV_INITIAL_ANCHOR = """\
    reset_dut(MODE_ECALL_MRET);
    run_until_exit(500);
"""
PRIV_INTEGRATION_ANCHOR = """\
    tb_check32("V8K pending CSR exact lease death count", v8k_death_count, 32'd1);
    tb_check1("mret synthetic commit observed", saw_mret_commit, 1'b1);
"""

PRIV_FLUSH_FOCUSED = """\
    reset_dut(MODE_ECALL_MRET);
`ifdef V11U_PENDING_SYSTEM_FLUSH_FOCUSED
    while (!v8k_birth_check_pending_q &&
           (v11u_flush_wait_cycles < 500)) begin
      `TB_TICK(clk);
      v11u_flush_wait_cycles = v11u_flush_wait_cycles + 1;
    end
    if (!v8k_birth_check_pending_q) begin
      $fatal(1, "[V11U-PRIV-FLUSH] timeout before pending-system birth");
    end
    if (!dut.pending_system_producer_valid_w ||
        !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
            v8k_expected_pid_q]) begin
      $fatal(1, "[V11U-PRIV-FLUSH] raw lease or backend mask absent before flush pid=%h",
             v8k_expected_pid_q);
    end
    force dut.u_control_plane.core_local_flush_w = 1'b1;
    `TB_TICK(clk);
    release dut.u_control_plane.core_local_flush_w;
    #1;
    if (dut.pending_system_producer_valid_w ||
        dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
            v8k_expected_pid_q]) begin
      $fatal(1, "[V11U-PRIV-FLUSH] core-local flush did not release lease/mask pid=%h",
             v8k_expected_pid_q);
    end
    $display("[V11U-PRIV-FLUSH] birth=1 raw_lease=1 backend_mask=1 flush_death=1 PASS");
    tb_finish("tb_ooo_priv_system");
`endif
    run_until_exit(500);
"""
PRIV_INTEGRATION_FOCUSED = """\
    tb_check32("V8K pending CSR exact lease death count", v8k_death_count, 32'd1);
`ifdef V11U_PENDING_SYSTEM_INTEGRATION_FOCUSED
    if ((v8k_dispatch_count == 32'd1) &&
        (v8k_birth_count == 32'd1) &&
        (v8k_exact_commit_count == 32'd1) &&
        (v8k_death_count == 32'd1)) begin
      $display("[V11U-PRIV-INTEGRATION] dispatch=1 birth=1 exact_commit=1 death=1 PASS");
    end else begin
      $fatal(1, "[V11U-PRIV-INTEGRATION] dispatch=%0d birth=%0d exact_commit=%0d death=%0d FAIL",
             v8k_dispatch_count, v8k_birth_count,
             v8k_exact_commit_count, v8k_death_count);
    end
    tb_finish("tb_ooo_priv_system");
`endif
    tb_check1("mret synthetic commit observed", saw_mret_commit, 1'b1);
"""


MUTATIONS = (
    Mutation(
        "lease-output-metadata-gated",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-PARTIAL-METADATA]",
        (
            replacement(
                "  assign producer_valid_o = producer_valid_q;\n",
                "  assign producer_valid_o = producer_valid_q && valid_q &&\n"
                "      (kind_q == SERIAL_KIND_CSR) && dispatched_q;\n",
                "gate the raw lease output with mutable metadata",
            ),
        ),
        extra_defines=("-DV8K_PROBE_PARTIAL_METADATA",),
    ),
    Mutation(
        "ordinary-clear-kills-live",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-LIVE-CLEAR]",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (producer_death_i || clear_i) begin\n",
                "allow an ordinary pending clear to kill a live lease",
            ),
        ),
        extra_defines=("-DV8K_PROBE_LIVE_CLEAR",),
    ),
    Mutation(
        "clear-dispatched-kills-live",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V8K-PROBE-LIVE-CDISP]",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (producer_death_i || clear_dispatched_i) begin\n",
                "allow orphan cleanup to cut a live lease",
            ),
        ),
        extra_defines=("-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",),
    ),
    Mutation(
        "birth-drops-generation",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_SEQUENCER,
        "FAIL head0 lease pid",
        (
            replacement(
                "      producer_id_q <= dispatch_producer_id_i;\n",
                "      producer_id_q <= {{PRODUCER_GEN_W{1'b0}},\n"
                "          dispatch_producer_id_i[ROB_INDEX_W-1:0]};\n",
                "drop the generation at the exact ROB allocation edge",
            ),
        ),
        widths=GEN_WIDTHS,
    ),
    Mutation(
        "noncsr-dispatch-birth-widened",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_LEASE_PROBE,
        "[V11U-PROBE-NONCSR-DISPATCH]",
        (
            replacement(
                DISPATCH_BIRTH,
                DISPATCH_BIRTH.replace(
                    "(kind_q == SERIAL_KIND_CSR)",
                    "(kind_q != SERIAL_KIND_NONE)",
                ),
                "allow a non-CSR serialized kind to birth a ProducerId",
            ),
        ),
        extra_defines=("-DV11U_PROBE_NONCSR_DISPATCH",),
    ),
    Mutation(
        "exact-death-disabled",
        SEQUENCER,
        "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        TEST_SEQUENCER,
        "ordinary clear cross dispatched",
        (
            replacement(
                "      if (producer_death_i) begin\n",
                "      if (1'b0 && producer_death_i) begin\n",
                "disconnect exact pending-CSR death",
            ),
        ),
    ),
    Mutation(
        "claim-seal-ignores-raw",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_claim_seal_w =\n"
                "      pending_system_producer_valid_i || "
                "pending_system_csr_logical_claim_w;\n",
                "  wire pending_system_csr_claim_seal_w =\n"
                "      pending_system_csr_logical_claim_w;\n",
                "let a raw-only lease reopen queue-head CSR fallback",
            ),
        ),
        extra_defines=("-DOOO_CSR_QUEUE_HEAD=1",),
    ),
    Mutation(
        "pid-match-ignores-generation",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_pid_match_w =\n"
                "      core_commit0_producer_id_i == "
                "pending_system_producer_id_i;\n",
                "  wire pending_system_csr_pid_match_w =\n"
                "      core_commit0_producer_id_i[ROB_INDEX_W-1:0] ==\n"
                "      pending_system_producer_id_i[ROB_INDEX_W-1:0];\n",
                "authorize commit with a raw ROB index only",
            ),
        ),
        widths=GEN_WIDTHS,
    ),
    Mutation(
        "pc-coherence-removed",
        CSR_MUX,
        "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        TEST_CSR_MUX,
        "FAIL core=",
        (
            replacement(
                "  wire pending_system_csr_pc_match_w =\n"
                "      core_commit0_pc_i == pending_system_pc_i;\n",
                "  wire pending_system_csr_pc_match_w = 1'b1;\n",
                "remove the independent commit PC coherence check",
            ),
        ),
    ),
    Mutation(
        "pending-live-mask-removed",
        INT_BACKEND,
        "RTL_OOO_INT_BACKEND",
        TEST_INT_BACKEND,
        "v8k pending lease reaches full holder census",
        (
            replacement(
                PENDING_MASK_UNION,
                PENDING_MASK_UNION.replace(
                    "      pending_system_producer_live_mask_w |\n", ""
                ),
                "remove the pending CSR lease from the global live mask",
            ),
        ),
        widths=GEN_WIDTHS,
        extra_defines=("-DV11U_PENDING_CSR_LEASE_FOCUSED",),
    ),
    Mutation(
        "rob-dispatch0-generation-dropped",
        ROB,
        "RTL_OOO_ROB",
        TEST_PRIV_SYSTEM,
        "[V8E-PRODUCER-ID-DISPATCH0]",
        (
            replacement(
                "  assign dispatch0_producer_id_o =\n"
                "      {dispatch0_generation_candidate_w, "
                "dispatch0_rob_idx_o};\n",
                "  assign dispatch0_producer_id_o =\n"
                "      {{PRODUCER_GEN_W{1'b0}}, "
                "dispatch0_rob_idx_o};\n",
                "drop the ROB allocation generation on the production birth",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "rob-head0-generation-flipped",
        ROB,
        "RTL_OOO_ROB",
        TEST_PRIV_SYSTEM,
        "[V8E-PRODUCER-ID-HEAD]",
        (
            replacement(
                "  assign head0_producer_id_o = "
                "{slot_generation_q[head_q], head_q};\n",
                "  assign head0_producer_id_o = "
                "{slot_generation_q[head_q] ^ "
                "{{(PRODUCER_GEN_W-1){1'b0}}, 1'b1}, head_q};\n",
                "flip the ROB head generation on the exact death authorization",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "pending-drain-system-csr-fire-disconnected",
        PENDING_DRAIN_RESOLVE_GATE,
        "RTL_OOO_PENDING_DRAIN_RESOLVE_GATE",
        TEST_PRIV_SYSTEM,
        (
            "[V11U-PRIV-INTEGRATION] dispatch=0 birth=0 "
            "exact_commit=0 death=0 FAIL"
        ),
        (
            replacement(
                "  assign system_csr_dispatch_fire_o =\n"
                "      system_csr_dispatch_valid_o && dispatch0_ready_i;\n",
                "  assign system_csr_dispatch_fire_o = 1'b0;\n",
                "disconnect the drained pending CSR from ROB allocation",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "control-plane-dispatch-fire-disconnected",
        CONTROL_PLANE,
        "RTL_OOO_CONTROL_PLANE",
        TEST_PRIV_SYSTEM,
        "[V8K-PENDING-CSR-BIRTH-MISSING]",
        (
            replacement(
                "    .dispatch_fire_i(system_csr_dispatch_fire_w),\n",
                "    .dispatch_fire_i(1'b0),\n",
                "disconnect the real ROB allocation fire from lease birth",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "control-plane-birth-pid-corrupted",
        CONTROL_PLANE,
        "RTL_OOO_CONTROL_PLANE",
        TEST_PRIV_SYSTEM,
        "[V8K-PRIV-BIRTH]",
        (
            replacement(
                "    .dispatch_producer_id_i(core_dispatch0_producer_id_w),\n",
                "    .dispatch_producer_id_i(\n"
                "        core_dispatch0_producer_id_w ^\n"
                "        {1'b1, {(PRODUCER_ID_W-1){1'b0}}}),\n",
                "corrupt the full ProducerId at the production birth edge",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "control-plane-exact-death-disconnected",
        CONTROL_PLANE,
        "RTL_OOO_CONTROL_PLANE",
        TEST_PRIV_SYSTEM,
        "[V8K-PENDING-CSR-NO-RECAPTURE]",
        (
            replacement(
                "    .producer_death_i(pending_system_csr_commit_w),\n",
                "    .producer_death_i(1'b0),\n",
                "disconnect exact pending CSR retirement from lease death",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "control-plane-flush-reset-disconnected",
        CONTROL_PLANE,
        "RTL_OOO_CONTROL_PLANE",
        TEST_PRIV_SYSTEM,
        "[V11U-PRIV-FLUSH]",
        (
            replacement(
                "    .rst(rst || core_local_flush_w),\n",
                "    .rst(rst),\n",
                "disconnect core-local flush from pending-system lease reset",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_FLUSH_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "core-top-glue-pending-valid-disconnected",
        CORE_TOP_GLUE,
        "RTL_OOO_CORE_TOP_GLUE",
        TEST_PRIV_SYSTEM,
        "[V8K-PRIV-EXACT-COMMIT]",
        (
            replacement(
                CORE_TOP_EXECUTE_PENDING_VALID,
                CORE_TOP_EXECUTE_PENDING_VALID.replace(
                    ".pending_system_producer_valid_w("
                    "pending_system_producer_valid_w)",
                    ".pending_system_producer_valid_w(1'b0)",
                ),
                "disconnect the ControlPlane lease valid at ExecuteBackend",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "execute-backend-pending-valid-disconnected",
        EXECUTE_BACKEND,
        "RTL_OOO_EXECUTE_BACKEND",
        TEST_PRIV_SYSTEM,
        "[V8K-PRIV-EXACT-COMMIT]",
        (
            replacement(
                ".pending_system_producer_valid_i("
                "pending_system_producer_valid_w),",
                ".pending_system_producer_valid_i(1'b0),",
                "disconnect the pending lease valid at OooAluCoreSlice",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "alu-core-slice-pending-valid-disconnected",
        ALU_CORE_SLICE,
        "RTL_OOO_ALU_CORE_SLICE",
        TEST_PRIV_SYSTEM,
        "[V8K-PRIV-EXACT-COMMIT]",
        (
            replacement(
                ".pending_system_producer_valid_i("
                "pending_system_producer_valid_i),",
                ".pending_system_producer_valid_i(1'b0),",
                "disconnect the pending lease valid at OooAluDecodeBackend",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
    Mutation(
        "alu-decode-backend-pending-valid-disconnected",
        ALU_DECODE_BACKEND,
        "RTL_OOO_ALU_DECODE_BACKEND",
        TEST_PRIV_SYSTEM,
        "[V8K-PRIV-EXACT-COMMIT]",
        (
            replacement(
                ".pending_system_producer_valid_i("
                "pending_system_producer_valid_i),",
                ".pending_system_producer_valid_i(1'b0),",
                "disconnect the pending lease valid at OooIntBackend",
            ),
        ),
        extra_defines=("-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",),
        assertions=True,
    ),
)


def positive_profiles() -> tuple[Profile, ...]:
    profiles: list[Profile] = []
    for width in GEN_WIDTHS:
        for mode, assertions in (("release", False), ("assert", True)):
            profiles.append(
                Profile(
                    f"sequencer-mux-g{width}-{mode}",
                    "positive",
                    (TEST_SEQUENCER, TEST_CSR_MUX),
                    width,
                    assertions=assertions,
                    required_markers=(
                        (
                            TEST_SEQUENCER,
                            "[V9W-SERIAL-KIND-MATRIX]",
                            1,
                        ),
                    ),
                )
            )
        profiles.append(
            Profile(
                f"int-live-mask-g{width}-release",
                "positive",
                (TEST_INT_BACKEND,),
                width,
                extra_defines=("-DV11U_PENDING_CSR_LEASE_FOCUSED",),
                required_markers=(
                    (
                        TEST_INT_BACKEND,
                        f"[V11U-BACKEND-PENDING-LEASE] width={width} PASS",
                        1,
                    ),
                ),
            )
        )
    for width in GEN_WIDTHS:
        profiles.append(
            Profile(
                f"priv-integration-g{width}-assert",
                "positive",
                (TEST_PRIV_SYSTEM,),
                width,
                assertions=True,
                extra_defines=(
                    "-DV11U_PENDING_SYSTEM_INTEGRATION_FOCUSED",
                ),
                required_markers=(
                    (
                        TEST_PRIV_SYSTEM,
                        "[V11U-PRIV-INTEGRATION] dispatch=1 birth=1 "
                        "exact_commit=1 death=1 PASS",
                        1,
                    ),
                ),
            )
        )
    profiles.append(
        Profile(
            "priv-flush-g4-assert",
            "positive",
            (TEST_PRIV_SYSTEM,),
            4,
            assertions=True,
            extra_defines=("-DV11U_PENDING_SYSTEM_FLUSH_FOCUSED",),
            required_markers=(
                (
                    TEST_PRIV_SYSTEM,
                    "[V11U-PRIV-FLUSH] birth=1 raw_lease=1 "
                    "backend_mask=1 flush_death=1 PASS",
                    1,
                ),
            ),
        )
    )
    profiles.extend(
        (
            Profile(
                "raw-lease-partial-metadata-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_PARTIAL_METADATA",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-PARTIAL-METADATA][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "raw-lease-ordinary-clear-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_LIVE_CLEAR",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-ORDINARY-CLEAR-HOLD][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "raw-lease-clear-dispatched-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-RAW-LEASE-CDISP-HOLD][PASS]",
                        1,
                    ),
                ),
            ),
            Profile(
                "noncsr-dispatch-g4-release",
                "positive",
                (TEST_LEASE_PROBE,),
                4,
                extra_defines=("-DV11U_PROBE_NONCSR_DISPATCH",),
                required_markers=(
                    (
                        TEST_LEASE_PROBE,
                        "[V11U-PROBE-NONCSR-DISPATCH] PASS",
                        1,
                    ),
                ),
            ),
        )
    )
    return tuple(profiles)


def assertion_profiles() -> tuple[Profile, ...]:
    return (
        Profile(
            "assert-partial-metadata-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV8K_ASSERT_PARTIAL_METADATA",),
            expected_failure_marker="[V8K-PENDING-CSR-LEASE-SHAPE]",
        ),
        Profile(
            "assert-live-clear-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV8K_ASSERT_LIVE_CLEAR",),
            expected_failure_marker="[V8K-PENDING-CSR-NO-RECAPTURE]",
        ),
        Profile(
            "assert-noncsr-dispatch-g4",
            "assertion-negative",
            (TEST_LEASE_PROBE,),
            4,
            assertions=True,
            extra_defines=("-DV11U_ASSERT_NONCSR_DISPATCH",),
            expected_failure_marker="[V8K-PENDING-CSR-DISPATCH-BIRTH]",
        ),
    )


def mutation_profiles() -> tuple[Profile, ...]:
    return tuple(
        Profile(
            f"mutation-{mutation.name}-g{width}-release",
            "mutation",
            (mutation.test,),
            width,
            assertions=mutation.assertions,
            extra_defines=mutation.extra_defines,
            expected_failure_marker=mutation.expected_marker,
            mutation=mutation.name,
        )
        for mutation in MUTATIONS
        for width in mutation.widths
    )


def build_profiles() -> tuple[Profile, ...]:
    return positive_profiles() + assertion_profiles() + mutation_profiles()


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


def artifact_record(path: Path, repo_root: Path) -> dict[str, object]:
    return {
        "path": repo_path(path, repo_root),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def atomic_status(path: Path, value: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(value + "\n", encoding="utf-8")
    temporary.replace(path)


def source_manifest(
    paths: Sequence[Path], repo_root: Path
) -> dict[str, str]:
    return {
        repo_path(path, repo_root): sha256_file(path)
        for path in sorted(set(path.resolve() for path in paths))
    }


def write_manifest(path: Path, manifest: dict[str, str]) -> None:
    path.write_text(
        "".join(f"{digest}  {name}\n" for name, digest in sorted(manifest.items())),
        encoding="utf-8",
    )


def resolve_compiler_input(
    value: str, *, compile_cwd: Path, repo_root: Path
) -> Path:
    candidate = Path(value)
    resolved = (
        candidate.resolve()
        if candidate.is_absolute()
        else (compile_cwd / candidate).resolve()
    )
    resolved.relative_to(repo_root.resolve())
    if not resolved.is_file():
        raise RuntimeError(f"compiler input is missing: {resolved}")
    return resolved


def compile_input_record(
    *,
    test: str,
    log_text: str,
    dependency_path: Path,
    compiler_argv_path: Path,
    compiler_wrapper: Path,
    real_iverilog: Path,
    compile_cwd: Path,
    repo_root: Path,
) -> dict[str, object]:
    compile_lines = [
        line.removeprefix("[COMPILE] ")
        for line in log_text.splitlines()
        if line.startswith("[COMPILE] ")
    ]
    if len(compile_lines) != 1:
        raise RuntimeError(f"{test}: expected one compile command")
    make_argv = shlex.split(compile_lines[0])
    expected_depflag = f"-Mprefix={dependency_path.resolve()}"
    if (
        not make_argv
        or Path(make_argv[0]).resolve() != compiler_wrapper.resolve()
        or not compiler_argv_path.is_file()
        or not dependency_path.is_file()
    ):
        raise RuntimeError(f"{test}: compiler input receipt is missing")
    compiler_argv = compiler_argv_path.read_text(
        encoding="utf-8"
    ).splitlines()
    expected_compiler_argv = [
        str(real_iverilog.resolve()),
        expected_depflag,
        *make_argv[1:],
    ]
    if compiler_argv != expected_compiler_argv:
        raise RuntimeError(f"{test}: actual compiler argv drifted")

    dependencies: dict[tuple[str, str], dict[str, object]] = {}
    for line in dependency_path.read_text(encoding="utf-8").splitlines():
        if not line:
            continue
        prefix, separator, value = line.partition(" ")
        role = {"M": "module", "I": "include"}.get(prefix)
        if role is None or not separator or not value:
            raise RuntimeError(f"{test}: malformed compiler dependency: {line}")
        resolved = resolve_compiler_input(
            value, compile_cwd=compile_cwd, repo_root=repo_root
        )
        path_value = repo_path(resolved, repo_root)
        key = (role, path_value)
        dependencies[key] = {
            "path": path_value,
            "role": role,
            "sha256": sha256_file(resolved),
            "size_bytes": resolved.stat().st_size,
        }
    if not dependencies:
        raise RuntimeError(f"{test}: compiler dependency list is empty")

    module_paths = {
        record["path"]
        for record in dependencies.values()
        if record["role"] == "module"
    }
    command_sources = {
        repo_path(
            resolve_compiler_input(
                token, compile_cwd=compile_cwd, repo_root=repo_root
            ),
            repo_root,
        )
        for token in compiler_argv
        if Path(token).suffix in {".v", ".sv"}
    }
    missing_sources = command_sources - module_paths
    if missing_sources:
        raise RuntimeError(
            f"{test}: compiler dependency list omitted sources: "
            f"{sorted(missing_sources)}"
        )
    return {
        "make_compile_argv": make_argv,
        "compiler_argv": compiler_argv,
        "compiler_argv_file": artifact_record(
            compiler_argv_path, repo_root
        ),
        "dependency_file": artifact_record(dependency_path, repo_root),
        "dependencies": [
            dependencies[key] for key in sorted(dependencies)
        ],
    }


def build_iverilog_dependency_wrapper(
    *, repo_root: Path, result_dir: Path, real_iverilog: Path
) -> tuple[Path, dict[str, object], tuple[Path, str]]:
    generated_dir = result_dir / "generated"
    generated_dir.mkdir(parents=True, exist_ok=True)
    wrapper = generated_dir / "iverilog-dependency-wrapper.sh"
    wrapper.write_text(
        "#!/bin/sh\n"
        "set -eu\n"
        f"real_iverilog={shlex.quote(str(real_iverilog.resolve()))}\n"
        "output=\n"
        "expect_output=0\n"
        "for argument do\n"
        "  if [ \"$expect_output\" -eq 1 ]; then\n"
        "    output=$argument\n"
        "    break\n"
        "  fi\n"
        "  if [ \"$argument\" = \"-o\" ]; then\n"
        "    expect_output=1\n"
        "  fi\n"
        "done\n"
        "if [ -z \"$output\" ]; then\n"
        "  echo 'missing -o output for V11U compiler wrapper' >&2\n"
        "  exit 2\n"
        "fi\n"
        "profile_dir=$(dirname \"$(dirname \"$output\")\")\n"
        "dependency_dir=$profile_dir/dependencies\n"
        "test_name=$(basename \"$output\" .vvp)\n"
        "mkdir -p \"$dependency_dir\"\n"
        "dependency_path=$dependency_dir/$test_name.deps\n"
        "argv_path=$dependency_dir/$test_name.argv\n"
        "printf '%s\\n' \"$real_iverilog\" "
        "\"-Mprefix=$dependency_path\" \"$@\" > \"$argv_path\"\n"
        "exec \"$real_iverilog\" "
        "\"-Mprefix=$dependency_path\" \"$@\"\n",
        encoding="utf-8",
    )
    wrapper.chmod(0o755)
    return (
        wrapper,
        artifact_record(wrapper, repo_root),
        (wrapper, "generated-compiler-wrapper"),
    )


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


def render_int_backend_overlay(
    source: str,
) -> tuple[str, list[dict[str, object]]]:
    return apply_mutation(
        source,
        (
            replacement(
                INT_BACKEND_INITIAL_ANCHOR,
                INT_BACKEND_INITIAL_ANCHOR
                + "`elsif V11U_PENDING_CSR_LEASE_FOCUSED\n"
                "    run_v8k_pending_csr_lease_fence();\n"
                "    if (tb_errors == 0) begin\n"
                "      $display(\"[V11U-BACKEND-PENDING-LEASE] "
                "width=%0d PASS\", PRODUCER_GEN_W);\n"
                "    end\n",
                "insert the isolated V11U backend lease profile",
            ),
            replacement(
                INT_BACKEND_FINISH_ANCHOR,
                INT_BACKEND_FINISH_ANCHOR
                + "`elsif V11U_PENDING_CSR_LEASE_FOCUSED\n"
                "        tb_finish(\"tb_ooo_int_backend\");\n",
                "bind the focused branch to the canonical test result name",
            ),
        ),
    )


def render_priv_system_overlay(
    source: str,
) -> tuple[str, list[dict[str, object]]]:
    return apply_mutation(
        source,
        (
            replacement(
                PRIV_DECLARATION_ANCHOR,
                PRIV_DECLARATION_ANCHOR.replace(
                    "  integer commit_total;\n",
                    "  integer v11u_flush_wait_cycles;\n"
                    "  integer commit_total;\n",
                ),
                "add the bounded flush-profile cycle counter",
            ),
            replacement(
                PRIV_RESET_ANCHOR,
                PRIV_RESET_ANCHOR.replace(
                    "      commit_total = 0;\n",
                    "      v11u_flush_wait_cycles = 0;\n"
                    "      commit_total = 0;\n",
                ),
                "reset the focused flush-profile cycle counter",
            ),
            replacement(
                PRIV_INITIAL_ANCHOR,
                PRIV_FLUSH_FOCUSED,
                "observe production birth and core-local flush death",
            ),
            replacement(
                PRIV_INTEGRATION_ANCHOR,
                PRIV_INTEGRATION_FOCUSED,
                "terminate after exact production birth/commit/death counts",
            ),
        ),
    )


def build_testbench_overlays(
    *, repo_root: Path, result_dir: Path
) -> tuple[
    Path,
    list[dict[str, object]],
    dict[str, object],
    list[tuple[Path, str]],
]:
    generated_dir = result_dir / "generated"
    generated_dir.mkdir(parents=True, exist_ok=True)
    int_base = repo_root / TB_INT_BACKEND
    priv_base = repo_root / TB_PRIV_SYSTEM
    int_source, int_receipts = render_int_backend_overlay(
        int_base.read_text(encoding="utf-8")
    )
    priv_source, priv_receipts = render_priv_system_overlay(
        priv_base.read_text(encoding="utf-8")
    )
    int_overlay = generated_dir / "tb_ooo_int_backend_v11u.sv"
    priv_overlay = generated_dir / "tb_ooo_priv_system_v11u.sv"
    make_overlay = generated_dir / "v11u-source-overlay.mk"
    int_overlay.write_text(int_source, encoding="utf-8")
    priv_overlay.write_text(priv_source, encoding="utf-8")
    make_overlay.write_text(
        "V11U_BASE_INT_SRCS := $(TB_SRCS_tb_ooo_int_backend)\n"
        "override TB_SRCS_tb_ooo_int_backend := "
        "$(filter-out tests/tb_ooo_int_backend.sv,$(V11U_BASE_INT_SRCS)) "
        f"{int_overlay}\n"
        "V11U_BASE_PRIV_SRCS := $(TB_SRCS_tb_ooo_priv_system)\n"
        "override TB_SRCS_tb_ooo_priv_system := "
        "$(filter-out tests/tb_ooo_priv_system.sv,$(V11U_BASE_PRIV_SRCS)) "
        f"{priv_overlay}\n",
        encoding="utf-8",
    )
    overlay_records = [
        {
            "name": "int-backend",
            "base": TB_INT_BACKEND,
            "base_sha256": sha256_file(int_base),
            "generated": artifact_record(int_overlay, repo_root),
            "receipts": int_receipts,
        },
        {
            "name": "priv-system",
            "base": TB_PRIV_SYSTEM,
            "base_sha256": sha256_file(priv_base),
            "generated": artifact_record(priv_overlay, repo_root),
            "receipts": priv_receipts,
        },
    ]
    generated_support = [
        (int_overlay, "generated-focused-testbench"),
        (priv_overlay, "generated-focused-testbench"),
        (make_overlay, "generated-make-overlay"),
    ]
    return (
        make_overlay,
        overlay_records,
        artifact_record(make_overlay, repo_root),
        generated_support,
    )


def profile_defines(profile: Profile) -> tuple[str, ...]:
    values = [f"-DOOO_PRODUCER_GEN_W={profile.gen_width}"]
    if profile.assertions:
        values.append("-DOOO_ASSERT")
    values.extend(profile.extra_defines)
    return tuple(values)


COMPILE_FAILURE_MARKERS = (
    "compile returned nonzero",
    "syntax error",
    "error(s) during elaboration",
    "Unable to open input file",
)


def evaluate_profile(
    profile: Profile,
    *,
    make_rc: int,
    timed_out: bool,
    logs: dict[str, str],
    artifacts_exist: bool,
) -> bool:
    compile_ok = (
        not timed_out
        and artifacts_exist
        and set(logs) == set(profile.tests)
        and all("[COMPILE]" in text for text in logs.values())
        and not any(
            marker in text
            for text in logs.values()
            for marker in COMPILE_FAILURE_MARKERS
        )
    )
    if not compile_ok:
        return False
    if profile.kind in {"positive", "regression"}:
        return (
            make_rc == 0
            and all(text.count("[RESULT] PASS") == 1 for text in logs.values())
            and all("[RESULT] FAIL" not in text for text in logs.values())
            and all(
                logs[test].count(marker) == count
                for test, marker, count in profile.required_markers
            )
        )
    marker = profile.expected_failure_marker
    return (
        make_rc != 0
        and len(profile.tests) == 1
        and marker is not None
        and logs[profile.tests[0]].count("[RESULT] FAIL") == 1
        and "[RESULT] PASS" not in logs[profile.tests[0]]
        and marker in logs[profile.tests[0]]
    )


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


def build_variants(
    *, repo_root: Path, result_dir: Path
) -> tuple[dict[str, Path], list[dict[str, object]]]:
    variant_dir = result_dir / "variants"
    variant_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, Path] = {}
    records: list[dict[str, object]] = []
    for mutation in MUTATIONS:
        source_path = repo_root / mutation.source
        source = source_path.read_text(encoding="utf-8")
        mutated, receipts = apply_mutation(source, mutation.replacements)
        variant = variant_dir / f"{mutation.name}-{source_path.name}"
        variant.write_text(mutated, encoding="utf-8")
        paths[mutation.name] = variant
        records.append(
            {
                "name": mutation.name,
                "unit_ids": list(UNIT_IDS),
                "target": mutation.source,
                "target_sha256": sha256_file(source_path),
                "variant": repo_path(variant, repo_root),
                "variant_sha256": sha256_file(variant),
                "override": mutation.override,
                "test": mutation.test,
                "widths": list(mutation.widths),
                "extra_defines": list(mutation.extra_defines),
                "expected_marker": mutation.expected_marker,
                "compile_success_required": True,
                "assertions": mutation.assertions,
                "receipts": receipts,
            }
        )
    return paths, records


def run_profile(
    profile: Profile,
    *,
    repo_root: Path,
    testbench_dir: Path,
    result_dir: Path,
    variants: dict[str, Path],
    make_overlay: Path,
    compiler_wrapper: Path,
    real_iverilog: Path,
    real_vvp: Path,
    timeout_seconds: int,
    bucket: str = "profiles",
) -> tuple[dict[str, object], list[Path], list[Path], list[Path]]:
    profile_dir = result_dir / bucket / profile.name
    result_path = profile_dir / "results"
    build_path = profile_dir / "build"
    dependency_dir = profile_dir / "dependencies"
    profile_dir.mkdir(parents=True, exist_ok=False)
    flags = " ".join((BASE_IVFLAGS, *profile_defines(profile)))
    command = [
        "make",
        "-B",
        "-C",
        str(testbench_dir),
        "-f",
        "Makefile",
        "-f",
        str(make_overlay),
        f"IVERILOG={compiler_wrapper}",
        f"VVP={real_vvp}",
        f"TESTS={' '.join(profile.tests)}",
        f"BUILD_DIR={build_path}",
        f"RESULT_DIR={result_path}",
        f"IVFLAGS={flags}",
    ]
    if profile.mutation:
        mutation = next(item for item in MUTATIONS if item.name == profile.mutation)
        command.append(f"{mutation.override}={variants[mutation.name]}")
    command.append("run")
    rc, stdout, stderr, elapsed, timed_out = run_command(
        command, cwd=repo_root, timeout_seconds=timeout_seconds
    )
    (profile_dir / "make.stdout").write_text(stdout, encoding="utf-8")
    (profile_dir / "make.stderr").write_text(stderr, encoding="utf-8")
    logs: dict[str, str] = {}
    log_records: dict[str, object] = {}
    image_paths: list[Path] = []
    image_records: list[dict[str, object]] = []
    dependency_paths: list[Path] = []
    compiler_argv_paths: list[Path] = []
    compile_inputs: dict[str, object] = {}
    for test in profile.tests:
        log_path = result_path / "logs" / f"{test}.log"
        image_path = build_path / f"{test}.vvp"
        dependency_path = dependency_dir / f"{test}.deps"
        compiler_argv_path = dependency_dir / f"{test}.argv"
        if log_path.is_file():
            logs[test] = log_path.read_text(
                encoding="utf-8", errors="replace"
            )
            log_records[test] = artifact_record(log_path, repo_root)
            if dependency_path.is_file():
                compile_inputs[test] = compile_input_record(
                    test=test,
                    log_text=logs[test],
                    dependency_path=dependency_path,
                    compiler_argv_path=compiler_argv_path,
                    compiler_wrapper=compiler_wrapper,
                    real_iverilog=real_iverilog,
                    compile_cwd=testbench_dir,
                    repo_root=repo_root,
                )
                dependency_paths.append(dependency_path)
                compiler_argv_paths.append(compiler_argv_path)
        if image_path.is_file() and image_path.stat().st_size > 0:
            image_paths.append(image_path)
            image_records.append(artifact_record(image_path, repo_root))
    passed = evaluate_profile(
        profile,
        make_rc=rc,
        timed_out=timed_out,
        logs=logs,
        artifacts_exist=len(image_paths) == len(profile.tests),
    )
    passed = passed and set(compile_inputs) == set(profile.tests)
    record: dict[str, object] = {
        "profile": profile.name,
        "status": "PASS" if passed else "FAIL",
        "kind": profile.kind,
        "tests": list(profile.tests),
        "producer_gen_width": profile.gen_width,
        "assertions": profile.assertions,
        "defines": list(profile_defines(profile)),
        "mutation": profile.mutation,
        "expected_failure_marker": profile.expected_failure_marker,
        "required_markers": [list(item) for item in profile.required_markers],
        "command": command,
        "make_rc": rc,
        "timeout": timed_out,
        "elapsed_seconds": round(elapsed, 6),
        "logs": log_records,
        "compile_artifacts": image_records,
        "compile_inputs": compile_inputs,
    }
    write_json(profile_dir / "profile.json", record)
    return record, image_paths, dependency_paths, compiler_argv_paths


def cleanup_artifacts(
    *,
    repo_root: Path,
    result_dir: Path,
    compile_images: Sequence[tuple[Path, str]],
    variants: Sequence[Path],
    generated_support: Sequence[tuple[Path, str]],
    compiler_dependency_lists: Sequence[Path],
    compiler_argv_lists: Sequence[Path],
) -> dict[str, object]:
    removed: list[dict[str, object]] = []
    seen: set[Path] = set()
    for path, kind in (
        *compile_images,
        *((path, "compiler-dependency-list")
          for path in compiler_dependency_lists),
        *((path, "compiler-argv-list") for path in compiler_argv_lists),
        *((path, "generated-negative-rtl") for path in variants),
        *generated_support,
    ):
        resolved = path.resolve()
        resolved.relative_to(result_dir.resolve())
        if resolved in seen or not resolved.is_file():
            raise RuntimeError(f"cleanup artifact is missing or duplicate: {resolved}")
        seen.add(resolved)
        record = artifact_record(resolved, repo_root)
        record.update({"kind": kind, "removed_after_validation": True})
        removed.append(record)
        resolved.unlink()
    for directory in sorted(
        (path for path in result_dir.rglob("build") if path.is_dir()),
        reverse=True,
    ):
        shutil.rmtree(directory)
    variants_dir = result_dir / "variants"
    if variants_dir.is_dir() and not any(variants_dir.iterdir()):
        variants_dir.rmdir()
    generated_dir = result_dir / "generated"
    if generated_dir.is_dir() and not any(generated_dir.iterdir()):
        generated_dir.rmdir()
    for directory in sorted(
        (path for path in result_dir.rglob("dependencies") if path.is_dir()),
        reverse=True,
    ):
        if not any(directory.iterdir()):
            directory.rmdir()
    return {
        "status": "PASS",
        "policy": "retain-results-logs-hashes-and-summary-only",
        "removed_count": len(removed),
        "removed": sorted(removed, key=lambda item: str(item["path"])),
    }


def resolve_tool(name: str) -> Path:
    value = shutil.which(name)
    if not value:
        raise RuntimeError(f"required tool was not found: {name}")
    return Path(value).resolve()


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[4],
    )
    parser.add_argument("--result-dir", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=300)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    repo_root = args.repo_root.resolve()
    result_dir = args.result_dir.resolve()
    testbench_dir = repo_root / "npc" / "rv64" / "testbench"
    result_dir.relative_to(repo_root / ".github" / "task-runs")
    if result_dir.exists() and any(result_dir.iterdir()):
        print(f"result directory is not empty: {result_dir}")
        return 2
    result_dir.mkdir(parents=True, exist_ok=True)
    status_path = result_dir / "runner.status"
    atomic_status(status_path, "RUNNING")
    stage = "initialization"
    compile_images: list[tuple[Path, str]] = []
    compiler_dependency_lists: list[Path] = []
    compiler_argv_lists: list[Path] = []
    variant_paths: dict[str, Path] = {}
    generated_support: list[tuple[Path, str]] = []
    try:
        stage = "tool-resolution"
        tools = {
            name: resolve_tool(name) for name in ("make", "iverilog", "vvp")
        }
        runner_test = Path(__file__).with_name(
            "test_run_v11u_pending_system_producer_semantic.py"
        ).resolve()
        inputs = [
            repo_root / path
            for path in (
                SEQUENCER,
                CSR_MUX,
                *PARENT_RTL,
                *COMPILE_CLAIM_RTL,
                INT_BACKEND,
                DEFINE,
                TB_SEQUENCER,
                TB_LEASE_PROBE,
                TB_CSR_MUX,
                TB_INT_BACKEND,
                TB_PRIV_SYSTEM,
                MAKEFILE,
                FILELIST,
                RESULT_CHECKER,
                COMMON_TB,
                COMMON_ENCODE,
            )
        ] + [Path(__file__).resolve(), runner_test]
        stage = "source-binding-pre"
        before = source_manifest(inputs, repo_root)
        before_path = result_dir / "source-before.sha256"
        write_manifest(before_path, before)
        design_id = current_design_id(repo_root)

        stage = "testbench-overlay-generation"
        (
            make_overlay,
            overlay_records,
            make_overlay_record,
            generated_support,
        ) = build_testbench_overlays(
            repo_root=repo_root,
            result_dir=result_dir,
        )
        (
            compiler_wrapper,
            compiler_wrapper_record,
            compiler_wrapper_cleanup,
        ) = build_iverilog_dependency_wrapper(
            repo_root=repo_root,
            result_dir=result_dir,
            real_iverilog=tools["iverilog"],
        )
        generated_support.append(compiler_wrapper_cleanup)

        stage = "variant-generation"
        variant_paths, variant_records = build_variants(
            repo_root=repo_root, result_dir=result_dir
        )

        stage = "focused-profiles"
        profile_records: list[dict[str, object]] = []
        for profile in build_profiles():
            (
                record,
                images,
                dependency_lists,
                argv_lists,
            ) = run_profile(
                profile,
                repo_root=repo_root,
                testbench_dir=testbench_dir,
                result_dir=result_dir,
                variants=variant_paths,
                make_overlay=make_overlay,
                compiler_wrapper=compiler_wrapper,
                real_iverilog=tools["iverilog"],
                real_vvp=tools["vvp"],
                timeout_seconds=args.timeout_seconds,
            )
            profile_records.append(record)
            compile_images.extend(
                (path, "focused-compile-image") for path in images
            )
            compiler_dependency_lists.extend(dependency_lists)
            compiler_argv_lists.extend(argv_lists)
            print(f"{profile.name}: {record['status']}")

        stage = "regressions"
        regression_profile = Profile(
            "current-regressions",
            "regression",
            REGRESSIONS,
            4,
        )
        (
            regression_record,
            regression_images,
            regression_dependency_lists,
            regression_argv_lists,
        ) = run_profile(
            regression_profile,
            repo_root=repo_root,
            testbench_dir=testbench_dir,
            result_dir=result_dir,
            variants=variant_paths,
            make_overlay=make_overlay,
            compiler_wrapper=compiler_wrapper,
            real_iverilog=tools["iverilog"],
            real_vvp=tools["vvp"],
            timeout_seconds=args.timeout_seconds,
            bucket="regressions",
        )
        compile_images.extend(
            (path, "regression-compile-image")
            for path in regression_images
        )
        compiler_dependency_lists.extend(regression_dependency_lists)
        compiler_argv_lists.extend(regression_argv_lists)

        stage = "source-binding-post"
        after = source_manifest(inputs, repo_root)
        after_path = result_dir / "source-after.sha256"
        write_manifest(after_path, after)
        if before != after or current_design_id(repo_root) != design_id:
            raise RuntimeError("current source or design identity drifted")
        if any(record["status"] != "PASS" for record in profile_records):
            raise RuntimeError("one or more focused profiles failed")
        if regression_record["status"] != "PASS":
            raise RuntimeError("current regression profile failed")

        stage = "artifact-cleanup"
        cleanup = cleanup_artifacts(
            repo_root=repo_root,
            result_dir=result_dir,
            compile_images=compile_images,
            variants=list(variant_paths.values()),
            generated_support=generated_support,
            compiler_dependency_lists=compiler_dependency_lists,
            compiler_argv_lists=compiler_argv_lists,
        )
        cleanup_path = result_dir / "artifact-cleanup.json"
        write_json(cleanup_path, cleanup)

        stage = "summary"
        positive_count = len(positive_profiles())
        assertion_count = len(assertion_profiles())
        mutation_profile_count = len(mutation_profiles())
        all_profile_records = [*profile_records, regression_record]
        dependency_records = [
            dependency
            for record in all_profile_records
            for compile_input in record["compile_inputs"].values()
            for dependency in compile_input["dependencies"]
        ]
        unique_dependency_records = {
            (dependency["role"], dependency["path"]): dependency
            for dependency in dependency_records
        }
        build_control_paths = (
            MAKEFILE,
            FILELIST,
            RESULT_CHECKER,
            COMMON_TB,
            COMMON_ENCODE,
            repo_path(Path(__file__).resolve(), repo_root),
            repo_path(runner_test, repo_root),
        )
        summary = {
            "schema": SCHEMA,
            "status": "PASS",
            "classification": "verification",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "design_id": design_id,
            "unit_ids": list(UNIT_IDS),
            "configuration": {
                "producer_gen_widths": list(GEN_WIDTHS),
                "positive_profile_count": positive_count,
                "assertion_negative_profile_count": assertion_count,
                "mutation_count": len(MUTATIONS),
                "mutation_profile_count": mutation_profile_count,
                "profile_count": len(profile_records),
                "regression_count": len(REGRESSIONS),
                "assert_and_release_baseline": True,
                "mutations_release_mode": all(
                    not mutation.assertions for mutation in MUTATIONS
                ),
                "parent_mutations_assertion_mode": True,
                "full_system_run": False,
            },
            "independent_oracle": {
                "full_producer_id_four_state_comparison": True,
                "nonzero_generation_width_one_and_four": True,
                "pre_rob_has_no_lease": True,
                "csr_only_birth": True,
                "birth_hold_exact_death": True,
                "backend_global_flush_death": True,
                "ordinary_clear_holds_live_lease": True,
                "clear_dispatched_holds_live_lease": True,
                "raw_lease_is_metadata_independent": True,
                "exact_commit_requires_full_pid_and_pc": True,
                "raw_or_logical_claim_seals_fallback": True,
                "int_backend_live_mask_and_reuse_fence": True,
                "production_rob_birth_and_exact_death": True,
                "production_core_local_flush_death": True,
                "production_wrapper_chain": True,
                "actual_compiler_input_closure": True,
                "assertion_negative_rejection": True,
                "compile_success_release_mutation_rejection": True,
            },
            "production": {
                "product_instances": [PRODUCT_INSTANCE],
                "sequencer_rtl": SEQUENCER,
                "sequencer_rtl_sha256": before[SEQUENCER],
                "csr_mux_rtl": CSR_MUX,
                "csr_mux_rtl_sha256": before[CSR_MUX],
                "int_backend_rtl": INT_BACKEND,
                "int_backend_rtl_sha256": before[INT_BACKEND],
                "parent_rtl": {
                    path: before[path] for path in PARENT_RTL
                },
                "sequencer_testbench": TB_SEQUENCER,
                "sequencer_testbench_sha256": before[TB_SEQUENCER],
                "lease_probe_testbench": TB_LEASE_PROBE,
                "lease_probe_testbench_sha256": before[TB_LEASE_PROBE],
                "csr_mux_testbench": TB_CSR_MUX,
                "csr_mux_testbench_sha256": before[TB_CSR_MUX],
                "int_backend_testbench": TB_INT_BACKEND,
                "int_backend_testbench_sha256": before[TB_INT_BACKEND],
                "priv_system_testbench": TB_PRIV_SYSTEM,
                "priv_system_testbench_sha256": before[TB_PRIV_SYSTEM],
                "generated_testbench_overlays": overlay_records,
                "generated_make_overlay": make_overlay_record,
            },
            "binding": {
                "source_before": artifact_record(before_path, repo_root),
                "source_after": artifact_record(after_path, repo_root),
                "pre_post_match": True,
            },
            "compile_input_closure": {
                "status": "PASS",
                "dependency_mode": "iverilog-wrapper-Mprefix",
                "compiler_argv_bound": True,
                "make_source_selection_bound": True,
                "dependency_lists_retired": True,
                "compiler_argv_lists_retired": True,
                "compiler_wrapper": compiler_wrapper_record,
                "build_controls": {
                    path: before[path] for path in build_control_paths
                },
                "required_claim_rtl": sorted(COMPILE_CLAIM_RTL),
                "profile_records": len(all_profile_records),
                "compilations": sum(
                    len(record["compile_inputs"])
                    for record in all_profile_records
                ),
                "unique_inputs": len(unique_dependency_records),
                "module_inputs": sum(
                    role == "module"
                    for role, _ in unique_dependency_records
                ),
                "include_inputs": sum(
                    role == "include"
                    for role, _ in unique_dependency_records
                ),
            },
            "tools": {
                name: str(path)
                for name, path in tools.items()
            }
            | {
                f"{name}_sha256": sha256_file(path)
                for name, path in tools.items()
            },
            "counts": {
                "profiles_total": len(profile_records),
                "profiles_pass": sum(
                    record["status"] == "PASS" for record in profile_records
                ),
                "positive_profiles_total": positive_count,
                "assertion_negative_profiles_total": assertion_count,
                "mutations_total": len(MUTATIONS),
                "mutation_profiles_total": mutation_profile_count,
                "regressions_total": len(REGRESSIONS),
                "regressions_pass": len(REGRESSIONS),
                "retired_artifacts": cleanup["removed_count"],
            },
            "profiles": profile_records,
            "variants": variant_records,
            "regressions": regression_record,
            "artifact_cleanup": cleanup,
            "scope": {
                "mechanism": "pending-system-producer-lifecycle",
                "semantic_units": list(UNIT_IDS),
                "source_paths": [
                    "pre-rob-csr-holder",
                    "rob-allocation-birth",
                    "raw-q-lease-hold",
                    "exact-commit-and-flush-death",
                    "global-live-mask-reuse-fence",
                    "production-wrapper-chain",
                ],
                "excluded_units": ["floating-point-producer-paths"],
                "global_no_live_reuse": "NOT_PROVEN",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "production_rtl_change": False,
                "a3_original_status": "FAIL_RETAINED",
                "a3_execution_state": "COMPLETE",
                "a3_terminal_state": "COMPLETE",
                "a3_oracle_state": "OLD_ORACLE_INVALID",
                "a3_checker_replay": "PASS_INDEPENDENT",
                "system_rerun": {
                    "triggered_by_v11u": False,
                    "run": False,
                    "required_for_current_scope": False,
                },
            },
            "promotion": {
                "semantic_unit": "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS",
                "whole_architecture": "RED",
                "ppa": "UNPROMOTED",
                "system_recertification": "NOT_RUN",
            },
        }
        summary_path = result_dir / "summary.json"
        write_json(summary_path, summary)
        atomic_status(
            status_path,
            "PASS rc=0 stage=complete evidence_complete=1 cleanup_rc=0",
        )
        print(
            "[V11U-PENDING-SYSTEM-PRODUCER] PASS "
            f"profiles={len(profile_records)} mutations={len(MUTATIONS)} "
            f"regressions={len(REGRESSIONS)}"
        )
        return 0
    except Exception as exc:  # fail-closed evidence status
        cleanup_rc = 0
        try:
            for path, _kind in compile_images:
                if path.is_file() and result_dir in path.resolve().parents:
                    path.unlink()
            for path in variant_paths.values():
                if path.is_file() and result_dir in path.resolve().parents:
                    path.unlink()
            for path, _kind in generated_support:
                if path.is_file() and result_dir in path.resolve().parents:
                    path.unlink()
        except OSError:
            cleanup_rc = 1
        (result_dir / "error.txt").write_text(
            f"stage={stage}\nerror={exc}\n", encoding="utf-8"
        )
        atomic_status(
            status_path,
            f"FAIL rc=1 stage={stage} evidence_complete=0 "
            f"cleanup_rc={cleanup_rc}",
        )
        print(f"[V11U-PENDING-SYSTEM-PRODUCER] FAIL stage={stage}: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
