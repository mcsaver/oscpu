#!/usr/bin/env python3
"""Fail-closed executable architecture gates for the RV64 OoO core."""

from __future__ import annotations

import argparse
import dataclasses
import datetime
import hashlib
import json
import math
import pathlib
import re
import sys
from typing import Any


RESULT_SCHEMA = "npc-rv64-architecture-hard-gates-result-v2"
EVIDENCE_SCHEMA = "npc-rv64-architecture-directed-suite-v2"
CONTRACT_REL = "npc/rv64/design/arch/rv64-architecture-ppa-contract.md"
GATE_IDS = (
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
)
EVIDENCE_TEST = {
    "DI-1": "frontend_ii1",
    "DI-2": "width_continuity",
    "DI-3": "pair_matrix",
    "DI-4": "no_static_lane_semantics",
    "DI-5": "dual_memory_issue",
    "OOO-1": "true_ooo_long_latency",
    "OOO-2": "selective_scheduling",
    "OOO-3": "memory_ordering",
    "OOO-4": "speculation_recovery",
}
PAIR_MATRIX = (
    "alu_alu", "alu_branch", "branch_alu", "alu_jal", "jal_alu",
    "alu_jalr", "jalr_alu", "alu_load", "load_alu", "alu_store",
    "store_alu", "load_load", "load_store", "store_load", "store_store",
)
WIDTH_BOUNDARIES = (
    "fetch", "decode", "rename", "dispatch", "issue", "execute", "retire",
)
SELECTIVE_EVIDENCE_COMMAND = "make -C npc/rv64 check-selective-scheduling"
FRONTEND_II1_EVIDENCE_COMMAND = "make -C npc/rv64 check-frontend-ii1"
WIDTH_CONTINUITY_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-width-continuity")
LONG_LATENCY_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-true-ooo-long-latency")
NO_STATIC_LANE_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-no-static-lane-semantics")
PAIR_MATRIX_EVIDENCE_COMMAND = "make -C npc/rv64 check-pair-matrix"
DUAL_MEMORY_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-dual-memory-sustained-issue")
MEMORY_ORDERING_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-memory-ordering")
SPECULATION_RECOVERY_EVIDENCE_COMMAND = (
    "make -C npc/rv64 check-speculation-recovery")
FRONTEND_II1_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "contract-review-v1-result.json",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "contract-review-v2-result.json",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "run-v8z-mutations.py",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "subagent-contracts/v8z-frontend-ii1-contract-review-v2.json",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_frontend_ii1_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/frontend_ii1_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/cache/OooFetchPacketCache.v",
    "npc/rv64/vsrc/frontend/OooFetchFlowControl.v",
    "npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v",
    "npc/rv64/vsrc/frontend/OooFetchRequestMux.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontendActionGate.v",
)
FRONTEND_II1_PROVENANCE_PATHS = FRONTEND_II1_SOURCE_PATHS + (
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/suite-run-id.txt",
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
        f"evidence/final-run/focused/{profile}/{test}/logs/{name}.log"
        for profile in ("assert", "release")
        for test, name in (
            ("frontend", "tb_ooo_core_top_glue_v8z_frontend_ii1"),
            ("bridge", "tb_ooo_fetch_axi_bridge"),
        )
    ),
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/mutations/summary.json",
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
        f"evidence/mutations/{name}.log"
        for name in (
            "bridge_h1_ready_cut",
            "bridge_h1_state_turnover_cut",
            "bridge_semantic_lookup_cut",
            "flow_outstanding_turnover_cut",
            "flow_enqueue_credit_cut",
            "sequencer_replacement_clear",
            "sink_dequeue_cut",
            "successor_pc_old_owner",
            "blocked_response_tail_ghost",
        )
    ),
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
        f"evidence/final-run/regressions/logs/{name}.log"
        for name in (
            "tb_ooo_core_top_glue",
            "tb_ooo_fetch_flow_control",
            "tb_ooo_fetch_pc_outstanding_sequencer",
            "tb_ooo_fetch_packet_fifo",
            "tb_ooo_fetch_request_mux",
            "tb_ooo_frontend_action_gate",
        )
    ),
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/static/architecture-unit.log",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/static/check-contract.log",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/static/diff-check.log",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/static/same-design-predecessors.log",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/sources.pre.sha256",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "evidence/final-run/sources.post.sha256",
)
FRONTEND_II1_TASK_RUN_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/"
    "run-v8z-mutations.py",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_frontend_ii1_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/frontend_ii1_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/cache/OooFetchPacketCache.v",
    "npc/rv64/vsrc/frontend/OooFetchFlowControl.v",
    "npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v",
    "npc/rv64/vsrc/frontend/OooFetchRequestMux.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontendActionGate.v",
)
FRONTEND_II1_MUTATION_NAMES = (
    "bridge_h1_ready_cut",
    "bridge_h1_state_turnover_cut",
    "bridge_semantic_lookup_cut",
    "flow_outstanding_turnover_cut",
    "flow_enqueue_credit_cut",
    "sequencer_replacement_clear",
    "sink_dequeue_cut",
    "successor_pc_old_owner",
    "blocked_response_tail_ghost",
)
FRONTEND_II1_REGRESSION_NAMES = (
    "tb_ooo_core_top_glue",
    "tb_ooo_fetch_flow_control",
    "tb_ooo_fetch_pc_outstanding_sequencer",
    "tb_ooo_fetch_packet_fifo",
    "tb_ooo_fetch_request_mux",
    "tb_ooo_frontend_action_gate",
)
FRONTEND_II1_TASK_RUN_PROOF_ROLES = (
    "scope_receipt",
    "simulator_config",
    "frontend_assert",
    "frontend_release",
    "bridge_assert",
    "bridge_release",
    *tuple(f"regression_{name}" for name in FRONTEND_II1_REGRESSION_NAMES),
    "mutation_summary",
    *tuple(f"mutation_{name}" for name in FRONTEND_II1_MUTATION_NAMES),
    "sources_pre",
    "sources_post",
    "architecture_unit",
)
WIDTH_CONTINUITY_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "holder-census-delta.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/dispatch-log.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "run-v9a-mutations.py",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "subagent-contracts/v9a-di2-contract-review-v1.json",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/design/arch/ooo-core-architecture.md",
    "npc/rv64/design/arch/pipeline-stage-boundary.md",
    "npc/rv64/design/specs/ooo-int-issue-queue.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_width_continuity_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/width_continuity_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv",
    "npc/rv64/testbench/tests/tb_ooo_alu_decode_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_dispatch_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_rob.sv",
    "npc/rv64/testbench/tests/tb_pipe_stage_reg.sv",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/decode/DecodeStage.v",
    "npc/rv64/vsrc/decode/ImmGen.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooRenameMap.v",
    "npc/rv64/vsrc/rename_allocate/OooFreeList.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "npc/rv64/vsrc/pipeline/PipeStageReg.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
)
WIDTH_CONTINUITY_MUTATION_NAMES = (
    "fetch_lane1_payload_alias",
    "decode_lane1_backend_cut",
    "rename_lane1_sink_cut",
    "rob_lane1_sink_cut",
    "iq_lane1_sink_cut",
    "issue_lane1_terminal_cut",
    "ex1_stage_capture_cut",
    "ex1_stage_payload_alias",
    "wb1_rob_sink_cut",
    "retire_lane1_event_cut",
    "lane1_immediate_alias",
)
WIDTH_CONTINUITY_REGRESSION_NAMES = (
    "tb_ooo_core_top_glue",
    "tb_ooo_fetch_packet_fifo",
    "tb_ooo_alu_decode_backend",
    "tb_ooo_dispatch_backend",
    "tb_ooo_int_issue_queue",
    "tb_ooo_int_backend",
    "tb_ooo_rob",
    "tb_pipe_stage_reg",
)
WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "holder-census-delta.md",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "run-v9a-mutations.py",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/design/arch/ooo-core-architecture.md",
    "npc/rv64/design/arch/pipeline-stage-boundary.md",
    "npc/rv64/design/specs/ooo-int-issue-queue.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_width_continuity_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/width_continuity_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv",
    "npc/rv64/testbench/tests/tb_ooo_alu_decode_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_dispatch_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_rob.sv",
    "npc/rv64/testbench/tests/tb_pipe_stage_reg.sv",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/decode/DecodeStage.v",
    "npc/rv64/vsrc/decode/ImmGen.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooRenameMap.v",
    "npc/rv64/vsrc/rename_allocate/OooFreeList.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "npc/rv64/vsrc/pipeline/PipeStageReg.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
)
WIDTH_CONTINUITY_TASK_RUN_PROOF_ROLES = (
    "scope_receipt",
    "simulator_config",
    "width_assert",
    "width_release",
    "stall_probe",
    *tuple(
        f"regression_{name}" for name in WIDTH_CONTINUITY_REGRESSION_NAMES),
    "mutation_summary",
    *tuple(f"mutation_{name}" for name in WIDTH_CONTINUITY_MUTATION_NAMES),
    "sources_pre",
    "sources_post",
    "architecture_unit",
)
WIDTH_CONTINUITY_PROVENANCE_PATHS = WIDTH_CONTINUITY_SOURCE_PATHS + (
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/suite-run-id.txt",
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
        f"evidence/final-run/focused/{profile}/logs/"
        "tb_ooo_core_top_glue_v9a_width_continuity.log"
        for profile in ("assert", "release")
    ),
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/stall-probe/logs/"
    "tb_ooo_core_top_glue_v9a_width_stall_probe.log",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/mutations/summary.json",
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
        f"evidence/mutations/{name}.log"
        for name in WIDTH_CONTINUITY_MUTATION_NAMES
    ),
    *tuple(
        ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
        f"evidence/final-run/regressions/logs/{name}.log"
        for name in WIDTH_CONTINUITY_REGRESSION_NAMES
    ),
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/architecture-unit.log",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/check-contract.log",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/diff-check.log",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/static/same-design-predecessors.log",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/sources.pre.sha256",
    ".github/task-runs/2026-07-21-rv64-v9a-width-continuity/"
    "evidence/final-run/sources.post.sha256",
)
PAIR_MATRIX_PROVENANCE_PATHS = (
    ".github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/"
    "contract.md",
    ".github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/"
    "mutate-v8p-pair-matrix.py",
    ".github/task-runs/2026-07-20-rv64-v8p-dual-memory-terminal-owners/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/design/specs/ooo-dual-memory-terminal-owners.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/pair_matrix_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_owner_terminal_collector.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv",
)
SELECTIVE_PROVENANCE_PATHS = (
    ".github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/contract.md",
    ".github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/"
    "mutate-v8m-selective-scheduling.py",
    ".github/task-runs/2026-07-20-rv64-v8m-selective-scheduling/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/selective_scheduling_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
)
LONG_LATENCY_PROVENANCE_PATHS = (
    ".github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/contract.md",
    ".github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/"
    "mutate-v8n-true-ooo-long-latency.py",
    ".github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/true_ooo_long_latency_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
)
LONG_LATENCY_SOURCE_PATHS = LONG_LATENCY_PROVENANCE_PATHS + (
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/execute/OooMulDivUnit.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
)
LONG_LATENCY_MUTATION_NAMES = (
    "serial_issue1",
    "miq_issue1_freeze",
    "muldiv_issue1_freeze",
    "retire_before_head_done",
    "load_owner_pid_truncate",
    "muldiv_owner_pid_truncate",
    "muldiv_resp_pid_truncate",
)
LONG_LATENCY_TASK_RUN_PROOF_ROLES = (
    "baseline_release",
    "baseline_assert",
    "mutation_summary",
    "sources_pre",
    "sources_post",
    "simulator_config",
    *tuple(f"mutator_{name}" for name in LONG_LATENCY_MUTATION_NAMES),
    *tuple(f"simulation_{name}" for name in LONG_LATENCY_MUTATION_NAMES),
)
NO_STATIC_LANE_PROVENANCE_PATHS = (
    ".github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/"
    "contract.md",
    ".github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/"
    "mutate-v8o-no-static-lane.py",
    ".github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/no_static_lane_semantics_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
)
DUAL_MEMORY_PROVENANCE_PATHS = (
    ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/"
    "contract.md",
    ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/"
    "mutate-v8u-f4.py",
    ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/"
    "run-mutations.sh",
    ".github/task-runs/2026-07-20-rv64-v8u-dual-memory-sustained-issue/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/dual_memory_issue_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_dual_memory_sustained_issue.sv",
)
DUAL_MEMORY_SOURCE_PATHS = DUAL_MEMORY_PROVENANCE_PATHS + (
    "npc/rv64/eval/ppa/tests/test_dual_memory_issue_evidence.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
)
DUAL_MEMORY_MUTATION_NAMES = (
    "backend_next_requires_response_fire",
    "backend_turnover_accepts_partial",
    "backend_peek_dequeue_without_capture",
    "bridge_station_query_requires_ready",
    "bridge_station_lookup_ignores_ready",
    "iq_pair_pop_only_entry0",
    "iq_pair_exposes_regular_issue1",
)
DUAL_MEMORY_TASK_RUN_PROOF_ROLES = (
    "system",
    "miq",
    "iq",
    "bridge",
    "backend",
    "backend_partial",
    "mutation_result",
    "mutation_summary",
    "baseline_cone_result",
    "baseline_verilator_log",
    "feedback_verilator_log",
    "sources_pre",
    "sources_post",
    "simulator_config",
    "f2_replay_origin",
    "f2_source_architecture_manifest",
    "f1_current_result",
    "f1_current_sources_pre",
    "f1_current_sources_post",
    "f1_current_mutation_summary",
    "f1_current_profile_summary",
    "f1_current_final",
    "f2_result",
    "f2_sources_pre",
    "f2_sources_post",
    "f2_mutation_summary",
    *tuple(f"activation_{name}" for name in DUAL_MEMORY_MUTATION_NAMES),
    *tuple(f"receipt_{name}" for name in DUAL_MEMORY_MUTATION_NAMES),
    *tuple(f"mutator_{name}" for name in DUAL_MEMORY_MUTATION_NAMES),
    *tuple(f"simulation_{name}" for name in DUAL_MEMORY_MUTATION_NAMES),
)
MEMORY_ORDERING_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/dispatch-log.md",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "run-lq-mutations.py",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/run-focused.sh",
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "mutate-v8s-dual-memory-core.py",
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "run-focused.sh",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/design/arch/producer-holder-census.json",
    "npc/rv64/design/specs/ooo-load-queue.md",
    "npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_memory_ordering_evidence.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/dual_memory_issue_evidence.py",
    "npc/rv64/eval/ppa/tools/memory_ordering_evidence.py",
    "npc/rv64/eval/ppa/tools/producer_holder_census.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/tests/tb_ooo_load_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/testbench/tests/tb_ooo_dual_memory_sustained_issue.sv",
    "npc/rv64/vsrc/include/define.v",
    "npc/rv64/vsrc/control/OooCoreSliceControlGate.v",
    "npc/rv64/vsrc/control/OooControlFlushSequencer.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "npc/rv64/vsrc/memory/OooLoadQueue.v",
    "npc/rv64/vsrc/memory/OooMemoryAccess.v",
    "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
    "npc/rv64/vsrc/memory/OooMemOwnerTracker.v",
    "npc/rv64/vsrc/memory/OooMemoryRequestGate.v",
    "npc/rv64/vsrc/memory/OooStoreQueue.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
)
MEMORY_ORDERING_PROVENANCE_PATHS = MEMORY_ORDERING_SOURCE_PATHS + (
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/result.json",
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/mutation-summary.log",
    ".github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/"
    "evidence/focused/mutations/raw_checkpoint_local_flush_bypass.run.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/lq/logs/tb_ooo_load_queue.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/sq/logs/tb_ooo_store_queue.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/backend/logs/tb_ooo_int_backend.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/backend-dual/logs/tb_ooo_int_backend.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/glue/logs/tb_ooo_core_top_glue.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/sustained/logs/tb_ooo_dual_memory_sustained_issue.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/static/architecture-unit.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/static/mutations.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/static/same-design-predecessors.log",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "mutation-results.json",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/sources.pre.sha256",
    ".github/task-runs/2026-07-21-rv64-v8v-memory-ordering/"
    "evidence/final-run/sources.post.sha256",
)
MEMORY_ORDERING_TASK_RUN_PROOF_ROLES = (
    "lq_log",
    "sq_log",
    "backend_log",
    "backend_dual_log",
    "glue_log",
    "sustained_log",
    "lq_mutations",
    "sources_pre",
    "sources_post",
    "f2_result",
    "f2_mutation_summary",
    "f2_control_gate_log",
)
SPECULATION_RECOVERY_SOURCE_PATHS = (
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/contract.md",
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "contract-review-result.json",
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "run-v8y-mutations.py",
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
    "subagent-contracts/"
    "v8y-speculation-recovery-contract-review-v1.json",
    "npc/rv64/Makefile",
    "npc/rv64/design/arch/rv64-architecture-ppa-contract.md",
    "npc/rv64/design/arch/producer-holder-census.json",
    "npc/rv64/design/specs/ooo-branch-resolve-producer-authorization.md",
    "npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tests/test_speculation_recovery_evidence.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/directed_evidence_manifest.py",
    "npc/rv64/eval/ppa/tools/speculation_recovery_evidence.py",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_int_backend_v8x_bridge.svh",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueQueue.v",
    "npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v",
    "npc/rv64/vsrc/writeback/OooRob.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v",
    "npc/rv64/vsrc/memory/OooDualMemAxiArbiter.v",
)
SPECULATION_RECOVERY_PROVENANCE_PATHS = (
    SPECULATION_RECOVERY_SOURCE_PATHS + (
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/suite-run-id.txt",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/focused/assert/logs/"
        "tb_ooo_int_backend_v8y_speculation_recovery.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/focused/release/logs/"
        "tb_ooo_int_backend_v8y_speculation_recovery.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/mutations/summary.json",
        *tuple(
            ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
            f"evidence/mutations/{name}.log"
            for name in (
                "control_admit_b",
                "youngest_control_select",
                "resolve_issue_close_bypass",
                "rob_tail_boundary_off_by_one",
                "completion_replay_one_cycle",
                "retire1_owner_remap",
                "iq_kill_holder_bypass",
                "mask_active_recovery_while_station_valid",
                "block_killed_station_promotion",
            )
        ),
        *tuple(
            ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
            f"evidence/final-run/regressions/logs/{name}.log"
            for name in (
                "tb_ooo_int_backend",
                "tb_ooo_core_top_glue",
                "tb_ooo_redirect_arbiter",
                "tb_ooo_branch_bpu_update_gate",
                "tb_ooo_mem_axi_bridge",
                "tb_ooo_dual_mem_bridge_wrapper",
            )
        ),
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/static/architecture-unit.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/static/check-contract.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/static/diff-check.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/static/same-design-predecessors.log",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/sources.pre.sha256",
        ".github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/"
        "evidence/final-run/sources.post.sha256",
    )
)
SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES = (
    "focused_assert",
    "focused_release",
    "mutation_summary",
    "suite_run_id",
    "sources_pre",
    "sources_post",
    "simulator_config",
    "regression_int_backend",
    "regression_core_top_glue",
    "regression_redirect_arbiter",
    "regression_branch_bpu_update_gate",
    "regression_mem_axi_bridge",
    "regression_dual_mem_bridge_wrapper",
    "mutation_control_admit_b",
    "mutation_youngest_control_select",
    "mutation_resolve_issue_close_bypass",
    "mutation_rob_tail_boundary_off_by_one",
    "mutation_completion_replay_one_cycle",
    "mutation_retire1_owner_remap",
    "mutation_iq_kill_holder_bypass",
    "mutation_mask_active_recovery_while_station_valid",
    "mutation_block_killed_station_promotion",
)


@dataclasses.dataclass(frozen=True)
class Check:
    check_id: str
    passed: bool
    detail: str

    def json(self) -> dict[str, Any]:
        return {
            "check_id": self.check_id,
            "status": "GREEN" if self.passed else "RED",
            "detail": self.detail,
        }


def repo_root(start: pathlib.Path) -> pathlib.Path:
    for path in (start, *start.parents):
        if (path / ".git").exists():
            return path.resolve()
    raise ValueError("cannot locate repository root")


def digest(path: pathlib.Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def canonical_digest(value: Any) -> str:
    raw = json.dumps(
        value, allow_nan=False, ensure_ascii=False,
        separators=(",", ":"), sort_keys=True).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def is_sha256(value: Any) -> bool:
    return (
        isinstance(value, str) and len(value) == 64
        and all(char in "0123456789abcdef" for char in value)
    )


def nonnegative_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def number(value: Any) -> bool:
    return (
        isinstance(value, (int, float)) and not isinstance(value, bool)
        and math.isfinite(value)
    )


def strip_comments(text: str) -> str:
    return re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.DOTALL)


def match(text: str, pattern: str) -> bool:
    return re.search(pattern, text, flags=re.DOTALL | re.MULTILINE) is not None


def assignment_expression(text: str, signal: str) -> str:
    found = re.search(
        rf"\bassign\s+{re.escape(signal)}\s*=\s*((?:(?!;).)*)\s*;",
        text,
        flags=re.DOTALL | re.MULTILINE,
    )
    return found.group(1) if found else ""


def assignment_expressions(text: str, signal: str) -> list[str]:
    return re.findall(
        rf"\bassign\s+{re.escape(signal)}\s*=\s*((?:(?!;).)*)\s*;",
        text,
        flags=re.DOTALL | re.MULTILINE,
    )


def concat_items(expression: str) -> list[str]:
    """Split one outer Verilog concatenation without splitting nested calls."""
    clean = expression.strip()
    if len(clean) < 2 or clean[0] != "{" or clean[-1] != "}":
        return []
    items: list[str] = []
    start = 1
    paren_depth = 0
    bracket_depth = 0
    brace_depth = 0
    for index in range(1, len(clean) - 1):
        char = clean[index]
        if char == "(":
            paren_depth += 1
        elif char == ")":
            paren_depth -= 1
        elif char == "[":
            bracket_depth += 1
        elif char == "]":
            bracket_depth -= 1
        elif char == "{":
            brace_depth += 1
        elif char == "}":
            brace_depth -= 1
        elif (
            char == "," and paren_depth == 0 and bracket_depth == 0
            and brace_depth == 0
        ):
            items.append(clean[start:index].strip())
            start = index + 1
    items.append(clean[start:-1].strip())
    if (
        paren_depth != 0 or bracket_depth != 0 or brace_depth != 0
        or any(not item for item in items)
    ):
        return []
    return items


def concat_lhs_items(text: str, rhs_pattern: str) -> list[str]:
    found = re.search(
        rf"(?P<lhs>\{{[^;]*\}})\s*=\s*{rhs_pattern}\s*;",
        text,
        flags=re.DOTALL | re.MULTILINE,
    )
    return concat_items(found.group("lhs")) if found else []


def compact_ws(value: str) -> str:
    return re.sub(r"\s+", "", value)


def tokens_in_order(value: str, tokens: tuple[str, ...]) -> bool:
    cursor = 0
    for token in tokens:
        position = value.find(token, cursor)
        if position < 0:
            return False
        cursor = position + len(token)
    return True


def packed_entry_field_facts(
    iq: str,
    q_field: str,
    next_field: str,
    dispatch0_value: str,
    dispatch1_value: str,
) -> dict[str, bool]:
    """Prove one field traverses the V13I packed IQ state path fail-closed."""
    resident = concat_items(assignment_expression(
        iq, "compact_source_state_w[compact_g]"))
    dispatch0 = concat_items(assignment_expression(iq, "dispatch0_state_w"))
    dispatch1 = concat_items(assignment_expression(iq, "dispatch1_state_w"))
    unpack = concat_lhs_items(
        iq, r"compact_next_state_w\[compact_i\]")
    bundles = (resident, dispatch0, dispatch1, unpack)
    normalized = tuple(
        [compact_ws(item) for item in bundle] for bundle in bundles)
    resident_n, dispatch0_n, dispatch1_n, unpack_n = normalized
    q_field_n = compact_ws(q_field)
    next_field_n = compact_ws(next_field)
    same_shape = (
        all(bundle for bundle in bundles)
        and len({len(bundle) for bundle in bundles}) == 1
    )
    resident_positions = [
        index for index, item in enumerate(resident_n) if item == q_field_n]
    unpack_positions = [
        index for index, item in enumerate(unpack_n) if item == next_field_n]
    field_aligned = (
        same_shape
        and len(resident_positions) == 1
        and len(unpack_positions) == 1
        and resident_positions[0] == unpack_positions[0]
    )
    field_index = resident_positions[0] if field_aligned else -1
    dispatch_capture = (
        field_aligned
        and dispatch0_n[field_index] == compact_ws(dispatch0_value)
        and dispatch1_n[field_index] == compact_ws(dispatch1_value)
    )

    survivor = [compact_ws(item) for item in assignment_expressions(
        iq, "compact_survivor_state_w[compact_g]")]
    survivor_route = (
        len(survivor) == 3
        and tokens_in_order(survivor[0], (
            "compact_source0_sel_w[compact_g]",
            "compact_source_state_w[compact_g]",
            "compact_source1_sel_w[compact_g]",
            "compact_source_state_w[compact_g+1]",
            "compact_source2_sel_w[compact_g]",
            "compact_source_state_w[compact_g+2]",
        ))
        and tokens_in_order(survivor[1], (
            "compact_source0_sel_w[compact_g]",
            "compact_source_state_w[compact_g]",
            "compact_source1_sel_w[compact_g]",
            "compact_source_state_w[compact_g+1]",
        ))
        and "compact_source2_sel_w[compact_g]" not in survivor[1]
        and tokens_in_order(survivor[2], (
            "compact_source0_sel_w[compact_g]",
            "compact_source_state_w[compact_g]",
        ))
        and "compact_source1_sel_w[compact_g]" not in survivor[2]
        and "compact_source2_sel_w[compact_g]" not in survivor[2]
    )
    next_mux = compact_ws(assignment_expression(
        iq, "compact_next_state_w[compact_next_g]"))
    next_route = tokens_in_order(next_mux, (
        "compact_survivor_valid_w[compact_next_g]",
        "compact_survivor_state_w[compact_next_g]",
        "compact_dispatch0_slot_w[compact_next_g]",
        "dispatch0_state_w",
        "compact_dispatch1_slot_w[compact_next_g]",
        "dispatch1_state_w",
    ))
    q_commit = match(
        iq,
        rf"{re.escape(q_field.replace('[compact_g]', '[reset_i]'))}\s*"
        rf"<=\s*{re.escape(next_field.replace('[compact_i]', '[reset_i]'))}"
        rf"\s*;",
    )
    return {
        "bundle_shape": same_shape,
        "resident_field": len(resident_positions) == 1,
        "dispatch_capture": dispatch_capture,
        "survivor_route": survivor_route,
        "next_route": next_route,
        "unpack_field": len(unpack_positions) == 1 and field_aligned,
        "q_commit": q_commit,
    }


def named_instance_body(text: str, module: str, instance: str) -> str:
    """Return one named Verilog instance port body with balanced parentheses."""
    clean = strip_comments(text)
    module_match = re.search(rf"\b{re.escape(module)}\b", clean)
    if module_match is None:
        return ""
    instance_match = re.search(
        rf"\b{re.escape(instance)}\s*\(", clean[module_match.end():])
    if instance_match is None:
        return ""
    opening = module_match.end() + instance_match.end() - 1
    depth = 0
    for index in range(opening, len(clean)):
        if clean[index] == "(":
            depth += 1
        elif clean[index] == ")":
            depth -= 1
            if depth == 0:
                return clean[opening + 1:index]
    return ""


def rtl_binding(root: pathlib.Path) -> tuple[str, dict[str, str]]:
    suffixes = {".v", ".sv", ".vh", ".svh", ".mk"}
    files = sorted(
        path for path in (root / "npc/rv64/vsrc").rglob("*")
        if path.is_file() and path.suffix.lower() in suffixes)
    if not files:
        raise ValueError("RTL source set is empty")
    entries = {
        path.relative_to(root).as_posix(): digest(path) for path in files
    }
    return canonical_digest(entries), entries


def live_sources(root: pathlib.Path) -> dict[str, str]:
    names = (
        "scheduling/OooIntIssueQueue.v",
        "scheduling/OooIntIssueSelect8.v",
        "rename_allocate/OooDispatchBackend.v",
        "decode/OooAluDecodeBackend.v",
        "execute/OooAluCoreSlice.v",
        "execute/OooExecuteBackend.v",
        "execute/OooIntBackend.v",
        "control/OooCoreSliceControlGate.v",
        "control/OooControlFlushSequencer.v",
        "control/OooControlPlane.v",
        "core/OooCoreTopGlue.v",
        "memory/OooMemoryAccess.v",
        "memory/OooMemoryRequestGate.v",
        "memory/OooMemAxiBridge.v",
        "memory/OooDualMemBridgeWrapper.v",
        "memory/OooMemInflightQueue.v",
        "memory/OooMemOwnerTerminalCollector.v",
        "memory/OooMemOwnerTracker.v",
        "memory/OooStoreQueue.v",
        "memory/OooLoadQueue.v",
        "cache/OooDataWordCache.v",
        "core/NpcCoreTop.v",
    )
    result: dict[str, str] = {}
    for name in names:
        path = root / "npc/rv64/vsrc" / name
        if path.is_file():
            result[name] = strip_comments(path.read_text(encoding="utf-8"))
    return result


def di4_checks(src: dict[str, str]) -> list[Check]:
    iq = src.get("scheduling/OooIntIssueQueue.v", "")
    selector = src.get("scheduling/OooIntIssueSelect8.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    issue = iq + "\n" + selector + "\n" + backend
    generic_predicate = match(
        issue,
        r"\b(?:ctrl_is_lane[01]_simple_alu|is_lane[01]_simple_alu_ctrl|"
        r"(?:lane|terminal|issue)[01]_(?:is_)?simple_alu_capable|"
        r"(?:simple_alu|alu)_capability_predicate)"
        r"(?:_[A-Za-z0-9]+)?\b")
    generic_entry_capability = match(
        issue,
        r"\b(?:entry_capability|capability_q|entry_fu_mask|fu_mask_q)"
        r"(?:_[A-Za-z0-9]+)?\b")
    generic_dynamic_steering = match(
        issue,
        r"\b(?:issue_pair_swapped(?:_[A-Za-z0-9]+)?|"
        r"pair_swap(?:ped)?(?:_[A-Za-z0-9]+)?|"
        r"promote_to_lane0(?:_[A-Za-z0-9]+)?|"
        r"[A-Za-z0-9_]*promotion[A-Za-z0-9_]*)\b")

    def count(pattern: str, text: str) -> int:
        return len(re.findall(pattern, text, flags=re.DOTALL | re.MULTILINE))

    packed_alu = packed_entry_field_facts(
        iq,
        "alu_terminal_capable_q[compact_g]",
        "alu_terminal_capable_next_r[compact_i]",
        "ctrl_is_alu_terminal_capable(dispatch0_ctrl_i) && "
        "!dispatch0_fp_pdest_i && !dispatch0_fp_st_src_en_i",
        "ctrl_is_alu_terminal_capable(dispatch1_ctrl_i) && "
        "!dispatch1_fp_pdest_i && !dispatch1_fp_st_src_en_i",
    )
    actual_counts = {
        "predicate_ref": count(r"\bctrl_is_alu_terminal_capable\b", iq),
        "predicate_def": count(
            r"\bfunction\s+(?:automatic\s+)?ctrl_is_alu_terminal_capable\s*;",
            iq),
        "metadata_decl": count(
            r"\breg\s+alu_terminal_capable_q\s*\[[^;]+;", iq),
        "dispatch_capture": count(
            r"alu_terminal_capable_next_r\[write_i\]\s*=\s*"
            r"ctrl_is_alu_terminal_capable\(dispatch[01]_ctrl_i\)", iq),
        "compaction_copy": count(
            r"alu_terminal_capable_next_r\[write_i\]\s*=\s*"
            r"alu_terminal_capable_q\[compact_i\]\s*;", iq),
        "selector_projection": count(
            r"assign\s+select_alu_capable_w\[select_g\]\s*=\s*"
            r"alu_terminal_capable_q\[select_g\]\s*;", iq),
        "selector_input": count(
            r"\.alu_capable_i\(select_alu_capable_w\)", iq),
        "swap_def": count(
            r"\bwire\s+swap_w\s*=\s*!universal_owner_present_i\s*&&"
            r".*?first_req_is_alu_w\s*&&.*?partner_valid_w\s*&&"
            r"\s*!partner_is_alu_w\s*;", selector),
        "swap_issue0": count(
            r"(?:assign\s+|wire\s+\[7:0\]\s+)issue0_onehot_w\s*=.*?"
            r"swap_w\s*\?\s*partner_onehot_w\s*:\s*first_req_onehot_w",
            selector),
        "swap_issue1": count(
            r"(?:assign\s+|wire\s+\[7:0\]\s+)issue1_onehot_w\s*=.*?"
            r"swap_w\s*\?\s*first_req_onehot_w\s*:\s*partner_onehot_w",
            selector),
        "swap_output": count(
            r"assign\s+issue_pair_swapped_o\s*=\s*swap_w\s*;", selector),
        "swap_iq_binding": count(
            r"\.issue_pair_swapped_o\(issue_pair_swapped_w\)", iq),
    }
    actual_counts.update({
        f"packed_{name}": int(passed)
        for name, passed in packed_alu.items()
    })
    actual_path_present = any(actual_counts.values())
    if actual_path_present:
        legacy_entry_path = (
            actual_counts["dispatch_capture"] == 2
            and actual_counts["compaction_copy"] == 1
        )
        packed_entry_path = all(packed_alu.values())
        entry_capability = (
            actual_counts["predicate_def"] == 1
            and actual_counts["predicate_ref"] >= 3
            and actual_counts["metadata_decl"] == 1
            and (legacy_entry_path or packed_entry_path)
            and actual_counts["selector_projection"] == 1
            and actual_counts["selector_input"] == 1
        )
        dynamic_steering = all(
            actual_counts[name] == 1 for name in (
                "predicate_def", "selector_input", "swap_def",
                "swap_issue0", "swap_issue1", "swap_output",
                "swap_iq_binding",
            )
        )
        capability_predicate = True
    else:
        entry_capability = generic_entry_capability
        dynamic_steering = generic_dynamic_steering
        capability_predicate = generic_predicate
    count_detail = ",".join(
        f"{name}={value}" for name, value in sorted(actual_counts.items())
    ) if actual_path_present else "generic_or_symmetric_path"
    return [
        Check(
            "source.capability_predicate_has_entry_metadata",
            not capability_predicate or entry_capability,
            "a simple/ALU capability restriction is tracked per entry; "
            f"matches={count_detail}"),
        Check(
            "source.capability_predicate_has_dynamic_steering",
            not capability_predicate or dynamic_steering,
            "a restricted asymmetric terminal has explicit swap or promotion; "
            f"matches={count_detail}"),
    ]


def di3_checks(src: dict[str, str]) -> list[Check]:
    iq = src.get("scheduling/OooIntIssueQueue.v", "")
    selector = src.get("scheduling/OooIntIssueSelect8.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    tracker = src.get("memory/OooMemOwnerTracker.v", "")
    collector = src.get("memory/OooMemOwnerTerminalCollector.v", "")
    sq = src.get("memory/OooStoreQueue.v", "")

    plain_function = re.search(
        r"\bfunction\s+(?:automatic\s+)?"
        r"ctrl_is_plain_memory_terminal_capable\s*;(?P<body>.*?)"
        r"\bendfunction\b",
        iq,
        flags=re.DOTALL | re.MULTILINE,
    )
    plain_body = plain_function.group("body") if plain_function else ""
    plain_predicate = all(token in plain_body for token in (
        "`CTRL_VALID_BIT", "`CTRL_NEED_MEM_BIT", "`CTRL_LOAD_BIT",
        "`CTRL_STORE_BIT", "!ctrl[`CTRL_AMO_BIT]",
    ))
    legacy_capture_ok = all(match(
        iq,
        rf"plain_memory_terminal_capable_next_r\[write_i\]\s*=\s*"
        rf"ctrl_is_plain_memory_terminal_capable\(dispatch{lane}_ctrl_i\)"
        rf"\s*&&\s*!dispatch{lane}_is_fp_i\s*&&\s*"
        rf"!dispatch{lane}_fp_pdest_i\s*&&\s*"
        rf"!dispatch{lane}_fp_st_src_en_i\s*;",
    ) for lane in (0, 1))
    legacy_capability = all((
        plain_predicate,
        legacy_capture_ok,
        match(iq, r"plain_memory_terminal_capable_next_r\[write_i\]\s*=\s*"
                  r"plain_memory_terminal_capable_q\[compact_i\]\s*;"),
        match(iq, r"assign\s+select_plain_memory_capable_w\[select_g\]\s*=\s*"
                  r"plain_memory_terminal_capable_q\[select_g\]\s*;"),
        match(iq, r"\.plain_memory_capable_i\s*\(\s*"
                  r"select_plain_memory_capable_w\s*\)"),
    ))
    packed_plain = packed_entry_field_facts(
        iq,
        "plain_memory_terminal_capable_q[compact_g]",
        "plain_memory_terminal_capable_next_r[compact_i]",
        "ctrl_is_plain_memory_terminal_capable(dispatch0_ctrl_i) && "
        "!dispatch0_is_fp_i && !dispatch0_fp_pdest_i && "
        "!dispatch0_fp_st_src_en_i",
        "ctrl_is_plain_memory_terminal_capable(dispatch1_ctrl_i) && "
        "!dispatch1_is_fp_i && !dispatch1_fp_pdest_i && "
        "!dispatch1_fp_st_src_en_i",
    )
    packed_capability = all((
        plain_predicate,
        all(packed_plain.values()),
        match(iq, r"assign\s+select_plain_memory_capable_w\[select_g\]\s*=\s*"
                  r"plain_memory_terminal_capable_q\[select_g\]\s*;"),
        match(iq, r"\.plain_memory_capable_i\s*\(\s*"
                  r"select_plain_memory_capable_w\s*\)"),
    ))
    capability = legacy_capability or packed_capability

    selector_pair = all((
        match(selector, r"\bwire\s+memory_pair_w\s*=\s*"
              r"!universal_owner_present_i\s*&&.*?eligible_w\[0\]\s*&&"
              r".*?eligible_w\[1\]\s*&&.*?"
              r"plain_memory_capable_i\[0\]\s*&&\s*"
              r"plain_memory_capable_i\[1\]\s*;"),
        match(selector, r"issue0_onehot_w\s*=.*?memory_pair_w\s*\?\s*"
              r"8'b0000_0001"),
        match(selector, r"issue1_onehot_w\s*=.*?memory_pair_w\s*\?\s*"
              r"8'b0000_0010"),
        match(selector, r"assign\s+issue1_found_o\s*=.*?"
              r"memory_pair_w\s*\|\|\s*partner_valid_w"),
    ))

    reservations = all((
        match(backend, r"\breg\s+mem_issue_res_valid_q\s*;"),
        match(backend, r"\breg\s+mem_issue1_res_valid_q\s*;"),
        match(backend, r"else\s+if\s*\(mem_issue_res_capture_w\)\s*begin"
              r".*?mem_issue_res_valid_q\s*<=\s*1'b1\s*;"),
        match(backend, r"else\s+if\s*\(mem_issue1_res_capture_w\)\s*begin"
              r".*?mem_issue1_res_valid_q\s*<=\s*1'b1\s*;"),
    ))
    atomic_capture = all((
        match(backend, r"\bwire\s+mem_issue_pair_capture_w\s*=\s*"
              r"mem_issue_pair_capture_candidate_w\s*&&\s*"
              r"mem_owner_alloc0_ready_w\s*&&\s*"
              r"mem_owner_alloc1_ready_w\s*;"),
        match(backend, r"\bwire\s+mem_issue1_res_capture_w\s*=\s*"
              r"mem_issue1_res_capture_candidate_w\s*&&\s*"
              r"mem_owner_alloc0_ready_w\s*&&\s*"
              r"mem_owner_alloc1_ready_w\s*;"),
        match(backend, r"\.alloc_pair_atomic_i\s*\(\s*1'b1\s*\)"),
        match(tracker, r"\bwire\s+alloc_pair_commit_w\s*=\s*"
              r"alloc_pair_present_w\s*&&\s*alloc0_ready_o\s*&&\s*"
              r"alloc1_ready_o\s*;"),
        match(tracker, r"\bwire\s+alloc0_fire_w\s*=\s*"
              r"alloc_pair_present_w\s*\?\s*alloc_pair_commit_w"),
        match(tracker, r"\bwire\s+alloc1_fire_w\s*=\s*"
              r"alloc_pair_present_w\s*\?\s*alloc_pair_commit_w"),
    ))

    two_agus = all((
        match(backend, r"\bwire\s+\[`XLEN-1:0\]\s+"
              r"mem_issue_res_eff_addr_w\s*=\s*"
              r"mem_issue_res_src1_data_q\s*\+\s*mem_issue_res_imm_q\s*;"),
        match(backend, r"\bwire\s+\[`XLEN-1:0\]\s+"
              r"mem_issue1_res_eff_addr_w\s*=\s*"
              r"mem_issue1_res_src1_data_q\s*\+\s*"
              r"mem_issue1_res_imm_q\s*;"),
        len(re.findall(r"\bLSU\s+u_issue0_lsu\s*\(", backend)) == 1,
        len(re.findall(r"\bLSU\s+u_issue1_lsu\s*\(", backend)) == 1,
        match(backend, r"\bLSU\s+u_issue1_lsu\s*\(.*?"
              r"\.eff_addr_i\s*\(mem_issue1_res_eff_addr_w\)"),
    ))

    age_serialized = all((
        match(backend, r"\bwire\s+grant_issue1_w\s*=.*?"
              r"!grant_issue0_w\s*&&.*?issue1_mem_req_valid_w\s*&&"),
        match(backend, r"\bwire\s+grant_mem1_issue1_w\s*=.*?"
              r"issue1_dual_bank1_w\s*&&\s*!grant_mem1_issue0_w\s*;"),
    ))
    dual_sq_bind = all((
        match(backend, r"\bwire\s+sq_owner_bind1_valid_w\s*=\s*"
              r"mem_issue1_res_capture_w\s*&&.*?MEM_OWNER_STORE"),
        match(backend, r"\.owner_bind1_valid_i\s*\("
              r"sq_owner_bind1_valid_w\s*\)"),
        match(backend, r"\.owner_bind1_producer_id_i\s*\("
              r"issue1_producer_id_w\s*\)"),
        match(backend, r"\.owner_bind1_token_i\s*\("
              r"mem_owner_alloc1_token_w\s*\)"),
        "owner_bind1_valid_i" in sq and "owner_bind1_token_i" in sq,
    ))
    ingress_width = re.search(
        r"\bwire\s+\[(\d+):0\]\s+mem_terminal_ingress_valid_w\s*;",
        backend,
    )
    ingress_parameter = re.search(
        r"\.INGRESS_N\s*\(\s*(\d+)\s*\)", backend)
    ingress_width_n = int(ingress_width.group(1)) + 1 if ingress_width else 0
    ingress_parameter_n = int(
        ingress_parameter.group(1)) if ingress_parameter else 0
    twelve_ingress = all((
        ingress_width_n == 12,
        ingress_parameter_n == ingress_width_n,
        match(backend, r"assign\s+mem_terminal_ingress_valid_w\s*=\s*"
              r"\{\s*mem_retry1_tagged_terminal_w\s*,\s*"
              r"mem_retry0_tagged_terminal_w\s*,\s*"
              r"mem_amo_interphase_cancel_w\s*,\s*"
              r"mem_buffer_tagged_terminal_w\s*,\s*"
              r"mem_issue1_res_tagged_terminal_w\s*,\s*"
              r"mem_issue_res_tagged_terminal_w\s*,\s*"
              r"mem1_drop1_valid_i\s*,\s*mem1_drop0_valid_i\s*,\s*"
              r"mem_drop1_valid_i\s*,\s*mem_drop0_valid_i\s*,\s*"
              r"mem1_terminal_rsp_valid_w\s*,\s*"
              r"mem_terminal_rsp_valid_w\s*\}\s*;"),
        "module OooMemOwnerTerminalCollector" in collector,
        match(collector, r"PARAM_SHAPE_VALID\s*=\s*\(INGRESS_N\s*>=\s*6\)"),
    ))
    full_pid = all((
        match(backend, r"\breg\s+\[PRODUCER_ID_W-1:0\]\s+"
              r"mem_issue1_res_producer_id_q\s*;"),
        match(backend, r"mem_issue1_res_producer_id_q\s*<=\s*"
              r"issue1_producer_id_w\s*;"),
        match(backend, r"\.alloc1_producer_id_i\s*\("
              r"issue1_producer_id_w\s*\)"),
    ))

    facts = (
        ("source.plain_memory_capability_resident", capability,
         "plain integer memory capability is resident and excludes AMO/FP"),
        ("source.memory_pair_selector_atomic", selector_pair,
         "packed entries 0/1 select two physical terminals as one pair"),
        ("source.two_registered_memory_reservations", reservations,
         "both memory terminals own non-fallthrough reservation state"),
        ("source.atomic_dual_owner_birth", atomic_capture,
         "pair capture and tracker token births are atomic"),
        ("source.two_captured_data_agus", two_agus,
         "two named AGUs consume only their captured reservation payloads"),
        ("source.memory_bank_age_serialized", age_serialized,
         "a younger terminal cannot pass the older terminal on either bank"),
        ("source.dual_store_exact_owner_bind", dual_sq_bind,
         "store-store capture has a distinct exact owner-bind1 path"),
        ("source.twelve_ingress_terminal_collector", twelve_ingress,
         "all twelve ordered terminal sources feed token-indexed collector storage"),
        ("source.full_pid_dual_owner", full_pid,
         "bank1 and tracker retain the complete ProducerId"),
    )
    checks = [Check(*fact) for fact in facts]
    checks.append(Check(
        "source.memory_pairs_two_terminals",
        all(item.passed for item in checks),
        "LL/LS/SL/SS have two atomic registered terminal owners",
    ))
    return checks


def second_memory_terminal_live(backend: str) -> bool:
    found = re.search(
        r"\b(?:assign\s+|wire(?:\s+\[[^\]]+\])?\s+)"
        r"issue1_mem_req_valid_w\s*=\s*([^;]+)\s*;",
        backend,
        flags=re.DOTALL | re.MULTILINE,
    )
    request_expr = found.group(1) if found else ""
    return (
        bool(request_expr)
        and "mem_issue1_res_valid_q" in request_expr
        and len(re.findall(r"\bLSU\s+u_issue1_lsu\s*\(", backend)) == 1
    )


def di5_checks(src: dict[str, str]) -> list[Check]:
    backend = src.get("execute/OooIntBackend.v", "")
    bridge = src.get("memory/OooMemAxiBridge.v", "")
    wrapper = src.get("memory/OooDualMemBridgeWrapper.v", "")
    miq = src.get("memory/OooMemInflightQueue.v", "")
    sq = src.get("memory/OooStoreQueue.v", "")
    cache = src.get("cache/OooDataWordCache.v", "")
    core = src.get("core/NpcCoreTop.v", "")
    backend_flat = re.sub(r"\s+", "", backend)
    wrapper_flat = re.sub(r"\s+", "", wrapper)
    bridge_flat = re.sub(r"\s+", "", bridge)
    core_flat = re.sub(r"\s+", "", core)
    live_second = second_memory_terminal_live(backend)
    two_agu = (
        match(backend, r"\bLSU\s+(?:#\s*\(.*?\)\s*)?u_issue0_lsu\b")
        and match(backend,
                  r"\bLSU\s+(?:#\s*\(.*?\)\s*)?u_issue1_lsu\b"))
    direct_translation = all(
        token in bridge for token in (
            "mem0_req_valid_i", "mem0_req_ready_o",
            "mem1_req_valid_i", "mem1_req_ready_o"))
    dual_bridge_instances = all((
        len(re.findall(r"\bu_bridge0\s*\(", wrapper)) == 1,
        len(re.findall(r"\bu_bridge1\s*\(", wrapper)) == 1,
        len(re.findall(r"\bOooMemAxiBridge\b", wrapper)) == 2,
        len(re.findall(r"\bu_ooo_dual_mem_bridge\s*\(", core)) == 1,
    ))
    canonical_translation = dual_bridge_instances and all(
        token in wrapper_flat for token in (
            ".mem0_req_valid_i(lane0_req_valid_i)",
            ".mem0_req_ready_o(lane0_req_ready_w)",
            ".mem0_req_valid_i(lane1_req_valid_i)",
            ".mem0_req_ready_o(lane1_req_ready_w)",
        )) and all(token in core_flat for token in (
            ".lane0_req_valid_i(ooo_mem0_req_valid_w)",
            ".lane0_req_ready_o(ooo_mem0_req_ready_w)",
            ".lane1_req_valid_i(ooo_mem1_req_valid_w)",
            ".lane1_req_ready_o(ooo_mem1_req_ready_w)",
        ))
    translation = direct_translation or canonical_translation
    direct_physical = (
        match(sq, r"\boutput\b[^;]*(?:snoop|query)[^;]*paddr[^;]*;")
        and match(backend, r"\bissue0_[A-Za-z0-9_]*paddr\w*\b")
        and match(backend, r"\bissue1_[A-Za-z0-9_]*paddr\w*\b"))
    store_queue_instance_flat = re.sub(
        r"\s+", "", named_instance_body(
            backend, "OooStoreQueue", "u_store_queue"))
    canonical_physical = dual_bridge_instances and all(
        token in wrapper_flat for token in (
            ".mem0_sq_query_paddr_o(lane0_sq_query_paddr_o)",
            ".mem0_sq_query_paddr_o(lane1_sq_query_paddr_o)",
        )) and all(token in core_flat for token in (
            ".lane0_sq_query_paddr_o(ooo_mem0_sq_query_paddr_w)",
            ".lane1_sq_query_paddr_o(ooo_mem1_sq_query_paddr_w)",
            ".mem_sq_query_paddr_i(ooo_mem0_sq_query_paddr_w)",
            ".mem1_sq_query_paddr_i(ooo_mem1_sq_query_paddr_w)",
        )) and all(token in store_queue_instance_flat for token in (
            ".query0_paddr_i(mem_sq_query_paddr_i)",
            ".query1_paddr_i(mem1_sq_query_paddr_i)",
        ))
    physical = direct_physical or canonical_physical
    direct_cache_faces = (
        all(match(cache + bridge,
                  rf"\b(?:req|mem){lane}_\w*(?:valid|admit)\w*\b")
            for lane in (0, 1))
        or (match(cache + bridge, r"\bu_dcache(?:_bank)?0\b")
            and match(cache + bridge, r"\bu_dcache(?:_bank)?1\b")))
    canonical_cache_faces = dual_bridge_instances and all((
        len(re.findall(r"\bu_dcache\s*\(", bridge)) == 1,
        "OooDataWordCache" in bridge,
        "moduleOooDataWordCache" in re.sub(r"\s+", "", cache),
    ))
    cache_faces = direct_cache_faces or canonical_cache_faces
    direct_completion = all(
        token in bridge for token in (
            "mem0_rsp_valid_o", "mem0_rsp_ready_i",
            "mem1_rsp_valid_o", "mem1_rsp_ready_i"))
    canonical_completion = dual_bridge_instances and all(
        token in wrapper_flat for token in (
            ".mem0_rsp_valid_o(lane0_rsp_valid_w)",
            ".mem0_rsp_ready_i(lane0_rsp_ready_i)",
            ".mem0_rsp_valid_o(lane1_rsp_valid_w)",
            ".mem0_rsp_ready_i(lane1_rsp_ready_i)",
        )) and all(token in core_flat for token in (
            ".lane0_rsp_valid_o(ooo_mem0_rsp_valid_w)",
            ".lane0_rsp_ready_i(ooo_mem0_rsp_ready_w)",
            ".lane1_rsp_valid_o(ooo_mem1_rsp_valid_w)",
            ".lane1_rsp_ready_i(ooo_mem1_rsp_ready_w)",
        ))
    completion = direct_completion or canonical_completion
    direct_credit = (
        all(token in miq for token in ("push0_valid_i", "push1_valid_i"))
        or all(match(backend, rf"\bmem_(?:issue)?{lane}_\w*credit\w*\b")
               for lane in (0, 1))
        or (match(backend, r"\bOooMemInflightQueue\b.*?\bu_miq0\b")
            and match(backend, r"\bOooMemInflightQueue\b.*?\bu_miq1\b")))
    canonical_credit = all((
        len(re.findall(r"\bOooMemInflightQueue\b", backend)) == 2,
        len(re.findall(r"\bu_mem_inflight_queue\s*\(", backend)) == 1,
        len(re.findall(r"\bu_mem1_inflight_queue\s*\(", backend)) == 1,
        ".push_valid_i(miq_push_valid_w)" in backend_flat,
        ".push_valid_i(miq1_push_valid_w)" in backend_flat,
    ))
    credit = direct_credit or canonical_credit
    facts = (
        ("source.two_live_memory_issue_terminals", live_second,
         "both issue terminals carry nonconstant memory requests"),
        ("source.two_agu", two_agu, "two distinct issue AGUs exist"),
        ("source.two_translation_admissions", translation,
         "mem0/mem1 translation valid-ready faces exist"),
        ("source.two_physical_lsq_queries", physical,
         "both terminals query physical LSQ/SQ addresses"),
        ("source.two_cache_admissions", cache_faces,
         "two cache admissions or two named banks exist"),
        ("source.two_completions", completion,
         "mem0/mem1 response valid-ready faces exist"),
        ("source.two_memory_credits", credit,
         "two memory issue credits or queue pushes exist"),
    )
    return [Check(*fact) for fact in facts]


def ooo2_checks(src: dict[str, str]) -> list[Check]:
    iq = src.get("scheduling/OooIntIssueQueue.v", "")
    selector = src.get("scheduling/OooIntIssueSelect8.v", "")
    dispatch = src.get("rename_allocate/OooDispatchBackend.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    older_block = match(
        iq, r"entry_mem_order_block_r\s*=\s*(?:(?!;).)*older_valid_seen_r")
    freeze = match(
        backend, r"assign\s+iq_issue0_ready_w\s*=\s*(?:(?!;).)*"
        r"mem_issue_res_valid_q\s*\?\s*1'b0")

    reservation_arch_present = (
        "mem_issue_res_valid_q" in backend
        or "universal_owner_present_i" in dispatch
        or "universal_owner_present_i" in iq
        or "universal_owner_present_i" in selector
    )
    backend_owner_matches = re.findall(
        r"\.universal_owner_present_i\s*\(\s*([^\)]+?)\s*\)",
        backend,
        flags=re.DOTALL | re.MULTILINE,
    )
    backend_owner_expr = re.sub(
        r"\s+", "", backend_owner_matches[0]
    ) if len(backend_owner_matches) == 1 else ""
    backend_owner_binding = backend_owner_expr in {
        "mem_issue_res_valid_q||mem_issue1_res_valid_q",
        "mem_issue1_res_valid_q||mem_issue_res_valid_q",
    }
    dispatch_owner_forwarding = match(
        dispatch,
        r"\.universal_owner_present_i\s*\(\s*"
        r"universal_owner_present_i\s*\)",
    )
    iq_owner_forwarding = match(
        iq,
        r"\.universal_owner_present_i\s*\(\s*"
        r"universal_owner_present_i\s*\)",
    )
    selector_owner_to_alu = (
        match(
            selector,
            r"\bissue1_onehot_w\s*=\s*(?:(?!;).)*?"
            r"\buniversal_owner_present_i\s*\?\s*"
            r"first_alu_onehot_w\b",
        )
        and match(
            selector,
            r"assign\s+issue1_found_o\s*=\s*(?:(?!;).)*?"
            r"\buniversal_owner_present_i\s*\?\s*"
            r"(?:\(\s*!owner_memory_pair_peek_w\s*&&\s*)?"
            r"first_alu_valid_w\b",
        )
    )
    iq_issue1_expr = assignment_expression(iq, "issue1_valid_o")
    iq_issue1_independent = (
        "issue1_found_w" in iq_issue1_expr
        and "universal_owner_present_i" not in iq_issue1_expr
    )
    backend_issue1_ready_expr = assignment_expression(
        backend, "issue1_ready_w")
    backend_issue1_independent = (
        "!flush_i" in backend_issue1_ready_expr
        and "!checkpoint_restore_hold_w" in backend_issue1_ready_expr
        and "mem_issue_res_valid_q" not in backend_issue1_ready_expr
        and match(
            backend,
            r"assign\s+issue1_fire_w\s*=\s*"
            r"issue1_valid_w\s*&&\s*issue1_ready_w\s*;",
        )
    )
    full_independent_path = all((
        backend_owner_binding,
        dispatch_owner_forwarding,
        iq_owner_forwarding,
        selector_owner_to_alu,
        iq_issue1_independent,
        backend_issue1_independent,
    ))

    def owner_check(check_id: str, passed: bool, detail: str) -> Check:
        return Check(
            check_id,
            not reservation_arch_present or passed,
            detail,
        )

    return [
        Check("source.no_arbitrary_older_valid_block", not older_block,
              "memory scheduling ignores unrelated older-valid uops"),
        owner_check(
            "source.reservation_owner_backend_binding",
            backend_owner_binding,
            "registered memory reservation drives the Universal owner fact"),
        owner_check(
            "source.reservation_owner_forwarding",
            dispatch_owner_forwarding and iq_owner_forwarding,
            "the Universal owner fact reaches the resident IQ selector"),
        owner_check(
            "source.reservation_owner_alu_steering",
            selector_owner_to_alu,
            "an owner-resident selector routes the oldest ready ALU to issue1"),
        owner_check(
            "source.reservation_owner_issue1_valid_independent",
            iq_issue1_independent,
            "the owner masks issue0, not the independent issue1 valid"),
        owner_check(
            "source.reservation_owner_issue1_ready_independent",
            backend_issue1_independent,
            "issue1 fire readiness has no reservation dependency"),
        Check(
            "source.no_single_reservation_global_freeze",
            not freeze or full_independent_path,
            "a Universal-local reservation stop is legal only with a complete "
            "independent ALU issue path"),
    ]


def ooo3_checks(src: dict[str, str]) -> list[Check]:
    lq = src.get("memory/OooLoadQueue.v", "")
    sq = src.get("memory/OooStoreQueue.v", "")
    backend = src.get("execute/OooIntBackend.v", "")
    decode = src.get("decode/OooAluDecodeBackend.v", "")
    core_slice = src.get("execute/OooAluCoreSlice.v", "")
    execute = src.get("execute/OooExecuteBackend.v", "")
    control = src.get("control/OooControlPlane.v", "")
    control_gate = src.get("control/OooCoreSliceControlGate.v", "")
    glue = src.get("core/OooCoreTopGlue.v", "")
    memory_access = src.get("memory/OooMemoryAccess.v", "")
    memory_gate = src.get("memory/OooMemoryRequestGate.v", "")
    lq_body = named_instance_body(backend, "OooLoadQueue", "u_load_queue")
    dispatch_body = named_instance_body(
        backend, "OooDispatchBackend", "u_dispatch_backend")
    phys_reg_body = named_instance_body(
        backend, "OooPhysRegFile", "u_phys_reg_file")
    fp_body = named_instance_body(backend, "OooFpBackend", "u_fp_backend")
    sq_body = named_instance_body(
        backend, "OooStoreQueue", "u_store_queue")
    int_body = named_instance_body(
        decode, "OooIntBackend", "u_int_backend")
    decode_body = named_instance_body(
        core_slice, "OooAluDecodeBackend", "u_decode_backend")
    slice_body = named_instance_body(
        execute, "OooAluCoreSlice", "u_core_slice")
    execute_body = named_instance_body(
        glue, "OooExecuteBackend", "u_execute_backend")
    control_body = named_instance_body(
        glue, "OooControlPlane", "u_control_plane")
    flush_seq_body = named_instance_body(
        control, "OooControlFlushSequencer", "u_control_flush_sequencer")
    control_gate_body = named_instance_body(
        control, "OooCoreSliceControlGate", "u_core_slice_control_gate")
    memory_gate_body = named_instance_body(
        memory_access, "OooMemoryRequestGate", "u_memory_request_gate")
    miq0_body = named_instance_body(
        backend, "OooMemInflightQueue", "u_mem_inflight_queue")
    miq1_body = named_instance_body(
        backend, "OooMemInflightQueue", "u_mem1_inflight_queue")
    ex0_body = named_instance_body(backend, "PipeStageReg", "u_ex0_stage")
    ex1_body = named_instance_body(backend, "PipeStageReg", "u_ex1_stage")
    muldiv_body = named_instance_body(
        backend, "OooMulDivUnit", "u_muldiv_unit")
    clmul_body = named_instance_body(
        backend, "OooClmulUnit", "u_clmul_unit")
    branch_stage_body = named_instance_body(
        backend, "PipeStageReg", "u_branch_resolve_stage")
    memory0_body = named_instance_body(
        glue, "OooMemoryAccess", "u_memory_access")
    memory1_body = named_instance_body(
        glue, "OooMemoryAccess", "u_memory_access1")

    def port(name: str, expression: str) -> bool:
        return match(
            lq_body,
            rf"\.{re.escape(name)}\s*\(\s*{expression}\s*\)",
        )

    depth_value = re.search(
        r"parameter\s+(?:integer\s+)?ENTRY_N\s*=\s*(\d+)", lq)
    depth = bool(depth_value and int(depth_value.group(1)) >= 4)
    instantiated = all((
        bool(lq_body),
        match(
            backend,
            r"\bOooLoadQueue\s*#\s*\(.*?"
            r"\.ENTRY_N\s*\(\s*LQ_ENTRY_N\s*\).*?"
            r"\)\s*u_load_queue\s*\(",
        ),
        match(backend, r"localparam\s+integer\s+LQ_ENTRY_N\s*=\s*"
              r"\(\s*1\s*<<\s*ROB_INDEX_W\s*\)\s*;"),
    ))
    allocation = all((
        port("alloc0_valid_i", r"lq_alloc0_valid_w"),
        port("alloc0_ready_o", r"lq_alloc0_ready_w"),
        port("alloc0_rob_idx_i", r"lq_alloc0_rob_w"),
        port("alloc0_producer_id_i", r"lq_alloc0_producer_id_w"),
        port("alloc1_valid_i", r"lq_alloc1_valid_w"),
        port("alloc1_ready_o", r"lq_alloc1_ready_w"),
        port("alloc1_rob_idx_i", r"dispatch1_rob_idx_w"),
        port("alloc1_producer_id_i", r"dispatch1_producer_id_w"),
        match(backend, r"assign\s+lq_alloc0_valid_w\s*=\s*"
              r"lq_d0_load_w\s*\|\|\s*lq_d1_load_w\s*;"),
        match(backend, r"assign\s+lq_alloc1_valid_w\s*=\s*"
              r"lq_d0_load_w\s*&&\s*lq_d1_load_w\s*;"),
        match(dispatch_body, r"\.lq_alloc0_ready_i\s*\(\s*"
              r"lq_alloc0_ready_w\s*\)"),
        match(dispatch_body, r"\.lq_alloc1_ready_i\s*\(\s*"
              r"lq_alloc1_ready_w\s*\)"),
    ))
    issue_launch = all((
        port("issue0_producer_id_i", r"mem_issue_res_producer_id_q"),
        port("issue0_open_o", r"lq_issue0_open_w"),
        port("issue1_producer_id_i", r"mem_issue1_res_producer_id_q"),
        port("issue1_open_o", r"lq_issue1_open_w"),
        port("launch0_valid_i", r"lq_launch0_valid_w"),
        port("launch0_producer_id_i", r"lq_launch0_producer_id_w"),
        port("launch1_valid_i", r"lq_launch1_valid_w"),
        port("launch1_producer_id_i", r"lq_launch1_producer_id_w"),
        match(backend, r"issue0_mem_issue_eligible_w\s*=.*?"
              r"lq_issue0_open_w"),
        match(backend, r"issue1_dual_transport_candidate_w\s*=.*?"
              r"lq_issue1_open_w"),
        match(backend, r"assign\s+lq_launch0_valid_w\s*=\s*"
              r"miq_push_valid_w\s*&&.*?MIQ_KIND_LOAD"),
        match(backend, r"assign\s+lq_launch1_valid_w\s*=\s*"
              r"ENABLE_DUAL_MEM\s*&&\s*miq1_push_valid_w\s*&&.*?"
              r"MIQ_KIND_LOAD"),
    ))
    final_pa = all((
        port("query0_producer_id_i", r"mem_sq_query_producer_id_w"),
        port("query0_paddr_i", r"mem_sq_query_paddr_i"),
        port("query0_open_o", r"lq_query0_open_w"),
        port("query0_update_i", r"lq_query0_update_w"),
        port("query0_allow_i", r"sq_query0_allow_w"),
        port("query0_forward_i", r"sq_query0_forward_w"),
        port("query0_replay_i", r"sq_query0_replay_w"),
        port("query1_producer_id_i", r"mem1_sq_query_producer_id_w"),
        port("query1_paddr_i", r"mem1_sq_query_paddr_i"),
        port("query1_open_o", r"lq_query1_open_w"),
        port("query1_update_i", r"lq_query1_update_w"),
        port("query1_allow_i", r"sq_query1_allow_w"),
        port("query1_forward_i", r"sq_query1_forward_w"),
        port("query1_replay_i", r"sq_query1_replay_w"),
        match(backend, r"mem_sq_query_exact_w\s*=\s*"
              r"mem_sq_query_pre_lq_exact_w\s*&&\s*lq_query0_open_w"),
        match(backend, r"mem1_sq_query_exact_w\s*=\s*"
              r"mem1_sq_query_pre_lq_exact_w\s*&&\s*lq_query1_open_w"),
        match(backend, r"assign\s+lq_query0_update_w\s*=.*?"
              r"sq_query0_allow_w.*?sq_query0_forward_w.*?"
              r"sq_query0_replay_w"),
        match(backend, r"assign\s+lq_query1_update_w\s*=.*?"
              r"sq_query1_allow_w.*?sq_query1_forward_w.*?"
              r"sq_query1_replay_w"),
    ))
    response_completion_terminal = all((
        port("response0_valid_i", r"lq_response0_query_valid_w"),
        port("response0_producer_id_i", r"mem_completion_producer_id_w"),
        port("response0_open_o", r"lq_response0_open_w"),
        port("response1_valid_i", r"lq_response1_query_valid_w"),
        port("response1_producer_id_i", r"mem1_completion_producer_id_w"),
        port("response1_open_o", r"lq_response1_open_w"),
        port("completion0_valid_i", r"wb0_valid_w"),
        port("completion0_producer_id_i", r"wb0_producer_id_w"),
        port("completion1_valid_i", r"wb1_valid_w"),
        port("completion1_producer_id_i", r"wb1_producer_id_w"),
        port("terminal0_valid_i", r"lq_terminal0_valid_w"),
        port("terminal0_producer_id_i", r"lq_terminal0_producer_id_w"),
        port("terminal1_valid_i", r"lq_terminal1_valid_w"),
        port("terminal1_producer_id_i", r"lq_terminal1_producer_id_w"),
        match(backend, r"mem_owner_open_w\s*=\s*mem_owner_base_open_w\s*&&"
              r"\s*\(\s*!miq_head_load_w\s*\|\|\s*"
              r"lq_response0_open_w\s*\)"),
        match(backend, r"mem1_owner_open_w\s*=\s*"
              r"mem1_owner_base_open_w\s*&&\s*"
              r"\(\s*!miq1_head_load_w\s*\|\|\s*"
              r"lq_response1_open_w\s*\)"),
        match(lq, r"\(terminal0_hit_w\[i\]\s*\|\|\s*"
              r"terminal1_hit_w\[i\]\)\s*&&\s*killed_q\[i\]"),
    ))
    recovery = all((
        port("flush_valid_i", r"flush_i\s*\|\|\s*checkpoint_restore_apply_w\s*"
             r"\|\|\s*branch_resolve_mispredict_w"),
        port("flush_all_i", r"flush_i\s*\|\|\s*checkpoint_restore_apply_w"),
        match(lq, r"launched_q\[i\].*?killed_q\[i\]\s*<=\s*1'b1"),
    ))
    checkpoint_hold_admission = all((
        match(backend, r"wire\s+checkpoint_restore_hold_w\s*=\s*"
              r"checkpoint_restore_i\s*\|\|\s*"
              r"checkpoint_restore_pending_q\s*;"),
        match(backend, r"assign\s+dispatch0_ready_o\s*="
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(backend, r"assign\s+dispatch1_ready_o\s*="
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(dispatch_body, r"\.dispatch0_valid_i\s*\(\s*"
              r"dispatch0_valid_i\s*&&\s*d0_fp_ok_w\s*&&\s*"
              r"!checkpoint_restore_hold_w\s*\)"),
        match(dispatch_body, r"\.dispatch1_valid_i\s*\(\s*"
              r"dispatch1_valid_i\s*&&\s*d1_fp_ok_w\s*&&\s*"
              r"!checkpoint_restore_hold_w\s*\)"),
        match(backend, r"wire\s+mem_issue_res_credit_w\s*=\s*"
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(backend, r"wire\s+mem_issue1_res_credit_w\s*=\s*"
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(backend, r"wire\s+issue0_global_ready_w\s*=\s*"
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(backend, r"assign\s+issue1_ready_w\s*=\s*"
              r"(?:(?!;).)*!checkpoint_restore_hold_w(?:(?!;).)*;"),
        match(backend, r"wire\s+mem_request_transport_open_w\s*=\s*"
              r"!flush_i\s*&&\s*!checkpoint_restore_hold_w\s*;"),
    ))
    checkpoint_irrevocable_write_drain = all((
        match(backend, r"wire\s+checkpoint_restore_new_req_w\s*=\s*"
              r"checkpoint_restore_i\s*&&\s*!checkpoint_restore_seen_q\s*;"),
        match(backend, r"wire\s+checkpoint_irrevocable_write_launch_w\s*=\s*"
              r"mem_req_fire_any_w\s*&&\s*mem_req_write_o\s*&&\s*"
              r"!mem_req_probe_o\s*;"),
        match(backend, r"checkpoint_irrevocable_write_launch_pid_w\s*=\s*"
              r"mem_owner_producer_id_table_w\s*\[\s*"
              r"mem_req_owner_token_o\s*\*\s*PRODUCER_ID_W\s*\+:\s*"
              r"PRODUCER_ID_W\s*\]\s*;"),
        match(backend, r"wire\s+checkpoint_irrevocable_write_retire_w\s*=\s*"
              r"commit0_valid_o\s*&&\s*checkpoint_irrevocable_write_q\s*&&\s*"
              r"\(\s*rob_commit0_producer_id_w\s*==\s*"
              r"checkpoint_irrevocable_write_pid_q\s*\)\s*;"),
        match(backend, r"checkpoint_irrevocable_write_live_mask_w\s*=\s*"
              r"checkpoint_irrevocable_write_q\s*\?.*?"
              r"checkpoint_irrevocable_write_pid_q.*?;"),
        match(backend, r"transient_producer_live_mask_w\s*=.*?"
              r"checkpoint_irrevocable_write_live_mask_w\s*;"),
        match(backend, r"assign\s+checkpoint_restore_apply_w\s*=\s*"
              r"\(\s*checkpoint_restore_new_req_w\s*\|\|\s*"
              r"checkpoint_restore_pending_q\s*\)\s*&&\s*"
              r"!checkpoint_irrevocable_write_q\s*&&\s*"
              r"sq_no_active_write_w\s*&&\s*!drain_inflight_q\s*;"),
        match(backend, r"if\s*\(checkpoint_restore_apply_w\)\s*"
              r"checkpoint_restore_pending_q\s*<=\s*1'b0\s*;\s*"
              r"else\s+if\s*\(checkpoint_restore_new_req_w\)\s*"
              r"checkpoint_restore_pending_q\s*<=\s*1'b1\s*;"),
        match(dispatch_body, r"\.commit_ready_i\s*\(.*?"
              r"!checkpoint_restore_apply_w.*?lq_retire0_permit_w.*?\)"),
        match(dispatch_body, r"\.commit1_block_i\s*\(\s*commit1_block_i\s*"
              r"\|\|\s*!lq_retire1_permit_w\s*\|\|\s*"
              r"checkpoint_restore_hold_w\s*\)"),
    ))
    checkpoint_owner_domain = all((
        match(dispatch_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(phys_reg_body, r"\.recover_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(fp_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(backend, r"wire\s+sq_flush_valid_w\s*=\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\|\|\s*"
              r"branch_resolve_mispredict_w\s*;"),
        match(sq_body, r"\.flush_all_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(miq0_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(miq1_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(ex0_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(ex1_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(muldiv_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(clmul_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(branch_stage_body, r"\.flush_i\s*\(\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\s*\)"),
        match(backend, r"if\s*\(rst\s*\|\|\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\)\s*begin\s*"
              r"mem_issue_res_valid_q\s*<=\s*1'b0"),
        match(backend, r"if\s*\(rst\s*\|\|\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\)\s*begin\s*"
              r"mem_issue1_res_valid_q\s*<=\s*1'b0"),
        match(backend, r"if\s*\(rst\s*\|\|\s*flush_i\s*\|\|\s*"
              r"checkpoint_restore_apply_w\)\s*begin\s*"
              r"mem_pending_q\s*<=\s*1'b0"),
        match(backend, r"mem_retry0_global_cancel_w\s*=.*?"
              r"checkpoint_restore_apply_w"),
        match(backend, r"mem_retry1_global_cancel_w\s*=.*?"
              r"checkpoint_restore_apply_w"),
    ))
    checkpoint_restore_apply_broadcast = all((
        match(backend, r"assign\s+checkpoint_restore_apply_o\s*=\s*"
              r"checkpoint_restore_apply_w\s*;"),
        match(int_body, r"\.checkpoint_restore_apply_o\s*\(\s*"
              r"checkpoint_restore_apply_o\s*\)"),
        match(decode_body, r"\.checkpoint_restore_apply_o\s*\(\s*"
              r"checkpoint_restore_apply_o\s*\)"),
        match(slice_body, r"\.checkpoint_restore_apply_o\s*\(\s*"
              r"core_checkpoint_restore_apply_w\s*\)"),
        match(execute_body, r"\.core_checkpoint_restore_apply_w\s*\(\s*"
              r"core_checkpoint_restore_apply_w\s*\)"),
        match(control_body, r"\.core_checkpoint_restore_apply_i\s*\(\s*"
              r"core_checkpoint_restore_apply_w\s*\)"),
        match(flush_seq_body, r"\.checkpoint_restore_i\s*\(\s*"
              r"core_checkpoint_restore_apply_i\s*\)"),
        match(memory0_body, r"\.checkpoint_mem_flush_q\s*\(\s*"
              r"checkpoint_mem_flush_q\s*\)"),
        match(memory1_body, r"\.checkpoint_mem_flush_q\s*\(\s*"
              r"checkpoint_mem_flush_q\s*\)"),
        match(memory_gate_body, r"\.checkpoint_mem_flush_i\s*\(\s*"
              r"checkpoint_mem_flush_q\s*\)"),
        match(memory_gate, r"assign\s+mem_flush_o\s*=\s*"
              r"core_local_flush_i\s*\|\|\s*checkpoint_mem_flush_i\s*;"),
    ))
    checkpoint_raw_restore_fail_closed = all((
        match(control_gate_body, r"\.branch_spec_restore_i\s*\(\s*"
              r"branch_spec_restore_w\s*\)"),
        match(control_gate_body, r"\.core_checkpoint_restore_o\s*\(\s*"
              r"core_checkpoint_restore_w\s*\)"),
        match(control_gate_body, r"\.core_local_flush_o\s*\(\s*"
              r"core_local_flush_w\s*\)"),
        match(control_gate, r"assign\s+core_checkpoint_restore_o\s*=\s*"
              r"branch_spec_restore_i\s*;"),
        match(control_gate, r"assign\s+core_local_flush_o\s*=\s*"
              r"flush_i\s*\|\|\s*core_trap_flush_i\s*\|\|\s*"
              r"core_serial_flush_i\s*;"),
    ))
    retire = all((
        port("release0_valid_i", r"lq_release0_valid_w"),
        port("release0_producer_id_i", r"rob_commit0_producer_id_w"),
        port("release0_commit_i", r"lq_release0_commit_w"),
        port("release0_ready_o", r"lq_release0_ready_w"),
        port("release0_fire_o", r"lq_release0_fire_w"),
        port("release1_valid_i", r"lq_release1_valid_w"),
        port("release1_producer_id_i", r"rob_commit1_producer_id_w"),
        port("release1_commit_i", r"lq_release1_commit_w"),
        port("release1_ready_o", r"lq_release1_ready_w"),
        port("release1_fire_o", r"lq_release1_fire_w"),
        match(backend, r"assign\s+lq_release0_valid_w\s*=\s*"
              r"head0_retire_candidate_valid_o\s*&&\s*"
              r"rob_head0_plain_load_w"),
        match(backend, r"assign\s+lq_release0_commit_w\s*=\s*"
              r"commit0_valid_o\s*&&\s*rob_head0_plain_load_w"),
        match(backend, r"assign\s+lq_retire0_permit_w\s*=\s*"
              r"!lq_release0_valid_w\s*\|\|\s*lq_release0_ready_w"),
        match(backend, r"assign\s+lq_retire1_permit_w\s*=\s*"
              r"!lq_release1_valid_w\s*\|\|\s*lq_release1_ready_w"),
        match(dispatch_body, r"\.commit_ready_i\s*\(.*?"
              r"lq_retire0_permit_w.*?\)"),
        match(dispatch_body, r"\.commit1_block_i\s*\(\s*"
              r"commit1_block_i\s*\|\|\s*!lq_retire1_permit_w\s*\|\|\s*"
              r"checkpoint_restore_hold_w\s*\)"),
        match(lq, r"assign\s+release0_fire_o\s*=\s*release0_valid_i\s*&&"
              r"\s*release0_ready_o\s*&&\s*release0_commit_i\s*;"),
        match(lq, r"assign\s+release1_fire_o\s*=\s*release1_valid_i\s*&&"
              r"\s*release1_ready_o\s*&&\s*release1_commit_i\s*;"),
    ))
    live_identity = all((
        port("producer_live_mask_o", r"lq_producer_live_mask_w"),
        match(backend, r"external_producer_live_mask_w\s*=\s*"
              r"(?:(?!;).)*\blq_producer_live_mask_w\b(?:(?!;).)*;"),
        match(dispatch_body, r"\.producer_live_mask_i\s*\(\s*"
              r"external_producer_live_mask_w\s*\)"),
        match(lq, r"producer_id_q\[g\]\s*==\s*issue0_producer_id_i"),
        match(lq, r"producer_id_q\[g\]\s*==\s*query0_producer_id_i"),
        match(lq, r"producer_id_q\[g\]\s*==\s*response0_producer_id_i"),
        match(lq, r"producer_id_q\[g\]\s*==\s*release0_producer_id_i"),
    ))
    dual_query_conflict = all((
        match(lq, r"query_pair_same_pid_w\s*=\s*query0_valid_i\s*&&\s*"
              r"query1_valid_i\s*&&\s*\(\s*query0_producer_id_i\s*==\s*"
              r"query1_producer_id_i\s*\)"),
        len(re.findall(r"!query_pair_same_pid_w", lq)) >= 2,
    ))
    return [
        Check("source.load_queue_at_least_four",
              "module OooLoadQueue" in lq and depth and instantiated,
              "a >=4-entry shared LQ is instantiated at canonical backend"),
        Check("source.lq_dispatch_allocation_credits", allocation,
              "both dispatch lanes allocate exact full-PID LQ entries and "
              "consume real LQ credits"),
        Check("source.lq_issue_launch_authority", issue_launch,
              "both memory terminals require LQ issue ownership and record "
              "the exact request-fire launch"),
        Check("source.lq_dual_final_pa_disposition", final_pa,
              "both final-PA SQ queries pass through the LQ and record one "
              "allow/forward/replay disposition"),
        Check("source.lq_response_completion_terminal",
              response_completion_terminal,
              "both response/WB/terminal paths retain exact LQ ownership"),
        Check("source.lq_checkpoint_recovery", recovery,
              "flush, accepted checkpoint recovery and branch recovery preserve "
              "launched loads as drainable tombstones"),
        Check("source.checkpoint_restore_hold_admission",
              checkpoint_hold_admission,
              "a raw or pending checkpoint request blocks dispatch, issue, "
              "reservation capture and request transport"),
        Check("source.checkpoint_irrevocable_write_drain",
              checkpoint_irrevocable_write_drain,
              "a physical store/AMO request carries one exact ProducerId lease "
              "through B, ROB lane0 retirement and restore apply"),
        Check("source.checkpoint_owner_recovery_domain",
              checkpoint_owner_domain,
              "the accepted restore pulse recovers ROB/IQ/rename/PRF/FP, "
              "execution holders, MIQs, retries, SQ and LQ as one domain"),
        Check("source.checkpoint_restore_apply_broadcast",
              checkpoint_restore_apply_broadcast,
              "the accepted backend restore pulse reaches both memory request "
              "gates through the core control flush sequencer"),
        Check("source.checkpoint_raw_restore_fail_closed",
              checkpoint_raw_restore_fail_closed,
              "a raw branch checkpoint restore remains separate from the "
              "global/trap/serial local-flush plane"),
        Check("source.lq_retire_authority", retire,
              "Q-only retire lookup actively gates ROB commit and only the "
              "commit edge frees the entry"),
        Check("source.lq_full_pid_live_mask", live_identity,
              "complete ProducerId residency participates in global identity "
              "reuse exclusion"),
        Check("source.lq_dual_query_same_pid_fail_closed",
              dual_query_conflict,
              "two final-PA lanes cannot update one ProducerId in one cycle"),
        Check("source.sq_physical_disambiguation",
              match(sq, r"\boutput\b[^;]*(?:snoop|query)[^;]*paddr[^;]*;"),
              "SQ exposes physical-address ordering queries"),
    ]


def source_checks(src: dict[str, str]) -> dict[str, list[Check]]:
    lane = di4_checks(src)
    pair = di3_checks(src)
    memory = di5_checks(src)
    return {
        "DI-1": [],
        "DI-2": [],
        "DI-3": [
            Check("source.pairing_not_static_lane",
                  all(item.passed for item in lane),
                  "pair formation is not limited by lane role"),
            *pair,
        ],
        "DI-4": lane,
        "DI-5": memory,
        "OOO-1": [],
        "OOO-2": ooo2_checks(src),
        "OOO-3": ooo3_checks(src),
        "OOO-4": [],
    }


def safe_artifact(root: pathlib.Path, rel: Any) -> pathlib.Path:
    if not isinstance(rel, str) or not rel or "\\" in rel:
        raise ValueError("artifact path must be workspace-relative POSIX")
    pure = pathlib.PurePosixPath(rel)
    if pure.is_absolute() or ".." in pure.parts:
        raise ValueError("artifact path escapes workspace")
    cursor = root
    for part in pure.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError("artifact path traverses symlink")
    path = (root / pure).resolve(strict=True)
    if not path.is_relative_to(root) or not path.is_file():
        raise ValueError("artifact is not a workspace file")
    return path


def validate_source_manifest(
    root: pathlib.Path,
    manifest_path: pathlib.Path,
    expected_paths: tuple[str, ...],
) -> dict[str, str]:
    """Validate a sha256sum manifest against the exact current file set."""
    root = root.resolve(strict=True)
    manifest_path = manifest_path.resolve(strict=True)
    if not manifest_path.is_relative_to(root) or not manifest_path.is_file():
        raise ValueError("source manifest is not a workspace file")
    expected = set(expected_paths)
    if len(expected) != len(expected_paths):
        raise ValueError("source manifest inventory contains duplicate paths")
    entries: dict[str, str] = {}
    lines = manifest_path.read_text(encoding="utf-8").splitlines()
    if not lines or any(not line.strip() for line in lines):
        raise ValueError("source manifest is empty or contains blank records")
    for line in lines:
        fields = line.split(maxsplit=1)
        if len(fields) != 2 or not is_sha256(fields[0]):
            raise ValueError(f"invalid source manifest record: {line!r}")
        expected_sha, raw_path = fields
        if raw_path.startswith("*"):
            raw_path = raw_path[1:]
        candidate = pathlib.Path(raw_path)
        candidate = candidate if candidate.is_absolute() else root / candidate
        resolved = candidate.resolve(strict=True)
        if not resolved.is_relative_to(root):
            raise ValueError(f"source manifest path escapes workspace: {raw_path}")
        rel = resolved.relative_to(root).as_posix()
        artifact = safe_artifact(root, rel)
        if rel in entries:
            raise ValueError(f"duplicate source manifest path: {rel}")
        actual_sha = digest(artifact)
        if actual_sha != expected_sha:
            raise ValueError(f"source manifest hash mismatch: {rel}")
        entries[rel] = expected_sha
    if set(entries) != expected:
        missing = sorted(expected - set(entries))
        extra = sorted(set(entries) - expected)
        raise ValueError(
            f"source manifest inventory mismatch: missing={missing} extra={extra}")
    return entries


def load_evidence(path: pathlib.Path | None) -> tuple[dict[str, Any], list[str]]:
    if path is None or not path.is_file():
        return {}, ["directed evidence manifest is missing"]
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            parse_constant=lambda item: (_ for _ in ()).throw(
                ValueError(f"non-finite constant {item}")))
    except (OSError, UnicodeDecodeError, ValueError, json.JSONDecodeError) as exc:
        return {}, [f"directed evidence cannot be parsed: {exc}"]
    return (
        (value, []) if isinstance(value, dict)
        else ({}, ["directed evidence top level is not an object"])
    )


def evidence_checks(
    root: pathlib.Path,
    evidence: dict[str, Any],
    source_sha: str,
    test_id: str,
) -> tuple[list[Check], dict[str, Any]]:
    base = [
        Check("evidence.schema", evidence.get("schema") == EVIDENCE_SCHEMA,
              f"schema is {EVIDENCE_SCHEMA}"),
        Check("evidence.design_binding",
              evidence.get("design_id") == f"sha256:{source_sha}",
              "design_id binds the complete RTL source set"),
    ]
    tests = evidence.get("tests")
    record = tests.get(test_id) if isinstance(tests, dict) else None
    if not isinstance(record, dict):
        return base + [
            Check(f"evidence.{test_id}.record", False,
                  "dedicated directed evidence is missing")
        ], {}
    command = record.get("command")
    command_ok = isinstance(command, str) and bool(command.strip())
    command_detail = "exact directed-test command is recorded"
    if test_id == "frontend_ii1":
        command_ok = command == FRONTEND_II1_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {FRONTEND_II1_EVIDENCE_COMMAND}")
    elif test_id == "width_continuity":
        command_ok = command == WIDTH_CONTINUITY_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {WIDTH_CONTINUITY_EVIDENCE_COMMAND}")
    elif test_id == "pair_matrix":
        command_ok = command == PAIR_MATRIX_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {PAIR_MATRIX_EVIDENCE_COMMAND}")
    elif test_id == "true_ooo_long_latency":
        command_ok = command == LONG_LATENCY_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {LONG_LATENCY_EVIDENCE_COMMAND}")
    elif test_id == "selective_scheduling":
        command_ok = command == SELECTIVE_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {SELECTIVE_EVIDENCE_COMMAND}")
    elif test_id == "no_static_lane_semantics":
        command_ok = command == NO_STATIC_LANE_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {NO_STATIC_LANE_EVIDENCE_COMMAND}")
    elif test_id == "dual_memory_issue":
        command_ok = command == DUAL_MEMORY_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {DUAL_MEMORY_EVIDENCE_COMMAND}")
    elif test_id == "memory_ordering":
        command_ok = command == MEMORY_ORDERING_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {MEMORY_ORDERING_EVIDENCE_COMMAND}")
    elif test_id == "speculation_recovery":
        command_ok = command == SPECULATION_RECOVERY_EVIDENCE_COMMAND
        command_detail = (
            f"command is exactly {SPECULATION_RECOVERY_EVIDENCE_COMMAND}")
    checks = base + [
        Check(f"evidence.{test_id}.status", record.get("status") == "PASS",
              "status is exactly PASS"),
        Check(f"evidence.{test_id}.command",
              command_ok, command_detail),
    ]
    log_ok = False
    log_text = ""
    detail = "log/hash/marker is missing"
    log = record.get("log")
    if isinstance(log, dict) and is_sha256(log.get("sha256")):
        try:
            path = safe_artifact(root, log.get("path"))
            text = path.read_text(encoding="utf-8")
            log_text = text
            pass_marker = f"[ARCH-GATE] {test_id} PASS"
            fail_marker = f"[ARCH-GATE] {test_id} FAIL"
            log_ok = (
                digest(path) == log["sha256"]
                and text.count(pass_marker) == 1
                and fail_marker not in text)
            detail = "log hash matches and has exactly one PASS marker"
        except (OSError, UnicodeDecodeError, ValueError) as exc:
            detail = f"invalid log: {exc}"
    checks.append(Check(f"evidence.{test_id}.log", log_ok, detail))
    if test_id in {
        "frontend_ii1", "width_continuity", "pair_matrix",
        "true_ooo_long_latency", "selective_scheduling",
        "no_static_lane_semantics", "dual_memory_issue", "memory_ordering",
        "speculation_recovery",
    }:
        provenance = record.get("provenance")
        files = provenance.get("files") if isinstance(
            provenance, dict) else None
        required_paths = {
            "frontend_ii1": FRONTEND_II1_PROVENANCE_PATHS,
            "width_continuity": WIDTH_CONTINUITY_PROVENANCE_PATHS,
            "pair_matrix": PAIR_MATRIX_PROVENANCE_PATHS,
            "true_ooo_long_latency": LONG_LATENCY_PROVENANCE_PATHS,
            "selective_scheduling": SELECTIVE_PROVENANCE_PATHS,
            "no_static_lane_semantics": NO_STATIC_LANE_PROVENANCE_PATHS,
            "dual_memory_issue": DUAL_MEMORY_PROVENANCE_PATHS,
            "memory_ordering": MEMORY_ORDERING_PROVENANCE_PATHS,
            "speculation_recovery": SPECULATION_RECOVERY_PROVENANCE_PATHS,
        }[test_id]
        task_run_source_paths = {
            "frontend_ii1": FRONTEND_II1_TASK_RUN_SOURCE_PATHS,
            "width_continuity": WIDTH_CONTINUITY_TASK_RUN_SOURCE_PATHS,
            "dual_memory_issue": DUAL_MEMORY_SOURCE_PATHS,
            "true_ooo_long_latency": LONG_LATENCY_SOURCE_PATHS,
            "memory_ordering": MEMORY_ORDERING_SOURCE_PATHS,
            "speculation_recovery": SPECULATION_RECOVERY_SOURCE_PATHS,
        }
        task_run_proof_roles = {
            "frontend_ii1": FRONTEND_II1_TASK_RUN_PROOF_ROLES,
            "width_continuity": WIDTH_CONTINUITY_TASK_RUN_PROOF_ROLES,
            "dual_memory_issue": DUAL_MEMORY_TASK_RUN_PROOF_ROLES,
            "true_ooo_long_latency": LONG_LATENCY_TASK_RUN_PROOF_ROLES,
            "memory_ordering": MEMORY_ORDERING_TASK_RUN_PROOF_ROLES,
            "speculation_recovery": SPECULATION_RECOVERY_TASK_RUN_PROOF_ROLES,
        }
        task_run_proof_mode = (
            test_id in task_run_source_paths
            and isinstance(provenance, dict)
            and provenance.get("mode") == "task-run-v1"
        )
        if task_run_proof_mode:
            required_paths = task_run_source_paths[test_id]
        expected_paths = set(required_paths)
        inventory_ok = (
            isinstance(files, dict) and set(files) == expected_paths
            and all(is_sha256(value) for value in files.values())
        )
        content_ok = inventory_ok
        provenance_detail = "required harness/proof inventory and hashes match"
        if inventory_ok:
            try:
                for rel, expected_sha in files.items():
                    if digest(safe_artifact(root, rel)) != expected_sha:
                        content_ok = False
                        provenance_detail = f"provenance hash mismatch: {rel}"
                        break
            except (OSError, ValueError) as exc:
                content_ok = False
                provenance_detail = f"invalid provenance artifact: {exc}"
        checks.extend([
            Check(
                f"evidence.{test_id}.provenance_inventory",
                inventory_ok,
                f"the exact {test_id} proof inventory is bound",
            ),
            Check(
                f"evidence.{test_id}.provenance_files",
                content_ok,
                provenance_detail,
            ),
            Check(
                f"evidence.{test_id}.provenance_digest",
                content_ok and isinstance(provenance, dict)
                and provenance.get("sha256") == canonical_digest(files),
                "the provenance aggregate digest matches its file map",
            ),
        ])
        if task_run_proof_mode:
            proof_files = provenance.get("proof_files")
            proof_role_order = task_run_proof_roles[test_id]
            proof_roles = set(proof_role_order)
            proof_inventory_ok = (
                isinstance(proof_files, dict)
                and set(proof_files) == proof_roles
                and all(
                    isinstance(item, dict)
                    and isinstance(item.get("path"), str)
                    and item["path"].startswith(".github/task-runs/")
                    and "/evidence/" in item["path"]
                    and is_sha256(item.get("sha256"))
                    for item in proof_files.values()
                )
            )
            proof_content_ok = proof_inventory_ok
            proof_log_ok = proof_inventory_ok and log_ok
            proof_detail = "task-run proof roles, hashes and gate-log bindings match"
            if proof_inventory_ok:
                try:
                    for role in proof_role_order:
                        item = proof_files[role]
                        artifact = safe_artifact(root, item["path"])
                        if digest(artifact) != item["sha256"]:
                            proof_content_ok = False
                            proof_detail = f"proof hash mismatch: {role}"
                            break
                        marker = (
                            f"artifact_sha256 {item['path']} "
                            f"{item['sha256']}"
                        )
                        if log_text.count(marker) != 1:
                            proof_log_ok = False
                            proof_detail = (
                                f"proof gate-log binding mismatch: {role}")
                            break
                except (OSError, ValueError) as exc:
                    proof_content_ok = False
                    proof_log_ok = False
                    proof_detail = f"invalid task-run proof artifact: {exc}"
            proof_digest_map = (
                {
                    role: (
                        f"{proof_files[role]['path']}:"
                        f"{proof_files[role]['sha256']}"
                    )
                    for role in proof_role_order
                }
                if proof_inventory_ok else {}
            )
            checks.extend([
                Check(
                    f"evidence.{test_id}.proof_inventory",
                    proof_inventory_ok,
                    "the exact task-run proof role inventory is bound",
                ),
                Check(
                    f"evidence.{test_id}.proof_files",
                    proof_content_ok,
                    proof_detail,
                ),
                Check(
                    f"evidence.{test_id}.proof_log_binding",
                    proof_content_ok and proof_log_ok,
                    "every proof path and hash appears exactly once in the gate log",
                ),
                Check(
                    f"evidence.{test_id}.proof_digest",
                    proof_content_ok
                    and provenance.get("proof_sha256")
                    == canonical_digest(proof_digest_map),
                    "the task-run proof aggregate digest matches its role map",
                ),
            ])
    metrics = record.get("metrics")
    checks.append(Check(
        f"evidence.{test_id}.metrics", isinstance(metrics, dict),
        "metrics is an object"))
    return checks, metrics if isinstance(metrics, dict) else {}


def metric(check_id: str, passed: bool, detail: str) -> Check:
    return Check(f"metric.{check_id}", passed, detail)


def metric_checks(test_id: str, m: dict[str, Any]) -> list[Check]:
    if test_id == "frontend_ii1":
        window = m.get("preheated_cycles")
        packets = m.get("packets_observed")
        accepted = m.get("accepted_packets")
        produced = m.get("produced_packets")
        initiation_interval = m.get("max_initiation_interval")
        valid_window = nonnegative_int(window) and window >= 64
        return [
            metric("frontend.packets",
                   nonnegative_int(packets) and packets >= 64,
                   "at least 64 packets are observed"),
            metric("frontend.window", valid_window,
                   "the post-warmup measurement window is at least 64 cycles"),
            metric("frontend.accept_every_cycle",
                   valid_window and nonnegative_int(accepted)
                   and accepted == window,
                   "one packet is accepted on every post-warmup cycle"),
            metric("frontend.produce_every_cycle",
                   valid_window and nonnegative_int(produced)
                   and produced == window,
                   "one packet is produced on every post-warmup cycle"),
            metric("frontend.ii1",
                   number(initiation_interval)
                   and 0 < initiation_interval <= 1,
                   "maximum initiation interval is at most one cycle"),
        ]
    if test_id == "width_continuity":
        trace = m.get("trace_cycles")
        activity = m.get("boundary_activity")
        trace_ok = nonnegative_int(trace) and trace >= 64
        minimum_total = math.ceil(1.90 * trace) if trace_ok else None
        maximum_total = 2 * trace if trace_ok else None
        result = [
            metric("width.trace", trace_ok,
                   "at least 64 non-vacuum trace cycles"),
            metric("width.independent_alu_ipc",
                   number(m.get("independent_alu_ipc"))
                   and m["independent_alu_ipc"] >= 1.90,
                   "independent integer ALU IPC is at least 1.90"),
        ]
        for boundary in WIDTH_BOUNDARIES:
            record = activity.get(boundary) if isinstance(
                activity, dict) else None
            peak = record.get("peak_uops_per_cycle") if isinstance(
                record, dict) else None
            total = record.get("total_uops") if isinstance(
                record, dict) else None
            result.extend([
                metric(
                    f"width.{boundary}.peak",
                    number(peak) and peak == 2,
                    f"{boundary} demonstrates a two-uop cycle"),
                metric(
                    f"width.{boundary}.total",
                    trace_ok and nonnegative_int(total)
                    and minimum_total <= total <= maximum_total,
                    f"{boundary} sustains 1.90..2.00 uop/cycle over the trace"),
            ])
        return result
    if test_id == "pair_matrix":
        matrix = m.get("pair_matrix")
        result = [
            metric(f"pair.{name}",
                   isinstance(matrix, dict) and matrix.get(name) is True,
                   f"{name} pairs in one cycle")
            for name in PAIR_MATRIX
        ]
        result.append(metric(
            "pair.exact_key_set",
            isinstance(matrix, dict) and set(matrix) == set(PAIR_MATRIX),
            "pair matrix has exactly the fifteen normative keys"))
        exact_fields = (
            ("same_cycle_pair_fires", 15,
             "all fifteen pair classes have one canonical dual fire"),
            ("same_cycle_memory_pair_fires", 4,
             "LL/LS/SL/SS each have one canonical dual fire"),
            ("distinct_nonzero_generation_memory_pids", 8,
             "four memory pairs retain eight distinct nonzero-generation PIDs"),
            ("dual_reservation_observations", 4,
             "both registered reservation owners appear for every memory pair"),
            ("distinct_owner_token_pairs", 4,
             "every memory pair receives two different tracker tokens"),
            ("captured_agu_matches", 8,
             "both captured-data AGUs match for all four memory pairs"),
            ("store_store_exact_owner_binds", 2,
             "store-store binds both exact SQ owners"),
            ("special_memory_exclusions", 10,
             "AMO/LR/SC/FP load/store are excluded in both orders"),
            ("atomic_scarcity_zero_births", 1,
             "one-token pressure causes zero partial owner births"),
            ("collector_ingress_peak", 12,
             "twelve exact terminal ingresses coexist under dequeue stall"),
            ("collector_exact_drains", 12,
             "all twelve terminal tuples drain exactly once"),
            ("raw_fallthrough_violations", 0,
             "captured AGU outputs ignore live raw source changes"),
            ("bank1_age_bypass_violations", 0,
             "bank1 never passes edge-old bank0"),
            ("owner_ghosts_after_cancel", 0,
             "pair cancellation leaves no tracker or collector ghost"),
        )
        result.extend(metric(
            f"pair.{field}",
            nonnegative_int(m.get(field)) and m[field] == expected,
            detail,
        ) for field, expected, detail in exact_fields)
        return result
    if test_id == "no_static_lane_semantics":
        perm = m.get("program_slot_permutation")
        result = [
            metric(f"perm.{kind}.{slot}",
                   isinstance(perm, dict)
                   and isinstance(perm.get(kind), dict)
                   and perm[kind].get(slot) is True,
                   f"{kind} from {slot} reaches a capable terminal")
            for kind in ("branch", "jal", "jalr", "load", "store", "muldiv")
            for slot in ("slot0", "slot1")
        ]
        result.append(metric(
            "perm.static_violations",
            nonnegative_int(m.get("static_lane_role_violations"))
            and m["static_lane_role_violations"] == 0,
            "no static lane-role violation"))
        result.extend([
            metric(
                "perm.same_cycle_pair_fires",
                nonnegative_int(m.get("same_cycle_pair_fires"))
                and m["same_cycle_pair_fires"] == 12,
                "all twelve permutations fire both terminals on one edge"),
            metric(
                "perm.exact_full_pid_matches",
                nonnegative_int(m.get("exact_full_pid_matches"))
                and m["exact_full_pid_matches"] == 24,
                "all twenty-four accepted uops retain exact full identity"),
        ])
        return result
    if test_id == "dual_memory_issue":
        result = [
            metric("dual.trace", nonnegative_int(m.get("trace_cycles"))
                   and m["trace_cycles"] >= 64, "at least 64 steady cycles"),
            metric("dual.ipc", number(m.get("memory_issue_ipc"))
                   and m["memory_issue_ipc"] >= 1.90, "memory IPC >= 1.90"),
            metric("dual.cycles", nonnegative_int(m.get("dual_issue_cycles"))
                   and m["dual_issue_cycles"] >= 58,
                   "at least 58 dual-memory cycles"),
        ]
        for name in ("agu_accepts", "translation_accepts",
                     "physical_lsq_queries", "cache_admissions", "completions"):
            values = m.get(name)
            result.append(metric(
                f"dual.{name}",
                isinstance(values, list) and len(values) == 2
                and all(nonnegative_int(value) and value >= 58
                        for value in values),
                f"two active {name} faces"))
        return result
    if test_id == "true_ooo_long_latency":
        younger = m.get("younger_completed_before_old")
        issued = m.get("younger_issue_accepted_under_owner")
        dual = m.get("dual_issue_cycles_under_owner")
        owner_live = m.get("owner_live_younger_completions")
        result = [
            metric(f"long.{kind}",
                   isinstance(younger, dict)
                   and nonnegative_int(younger.get(kind))
                   and younger[kind] >= 8,
                   f"old {kind} bypassed by >=8 younger uops")
            for kind in ("load_miss", "mul", "div")
        ]
        result.extend(
            metric(f"long.issue.{kind}",
                   isinstance(issued, dict)
                   and nonnegative_int(issued.get(kind))
                   and issued[kind] >= 8,
                   f"old {kind} overlaps eight accepted younger issues")
            for kind in ("load_miss", "mul", "div")
        )
        result.extend(
            metric(f"long.dual.{kind}",
                   isinstance(dual, dict)
                   and nonnegative_int(dual.get(kind))
                   and dual[kind] >= 4,
                   f"old {kind} overlaps four dual-issue cycles")
            for kind in ("load_miss", "mul", "div")
        )
        result.extend(
            metric(f"long.owner_live.{kind}",
                   isinstance(owner_live, dict)
                   and nonnegative_int(owner_live.get(kind))
                   and owner_live[kind] >= 8,
                   f"all younger completions retain the exact old {kind} owner")
            for kind in ("load_miss", "mul", "div")
        )
        result.extend([
            metric("long.rob", nonnegative_int(m.get("rob_peak"))
                   and m["rob_peak"] >= 9,
                   "ROB peak >=9 (one old plus eight younger)"),
            metric("long.rob_valid",
                   nonnegative_int(m.get("rob_valid_entries_peak"))
                   and m["rob_valid_entries_peak"] >= 9,
                   "at least nine distinct full-PID ROB entries coexist"),
            metric("long.retire", nonnegative_int(
                m.get("retire_order_violations"))
                and m["retire_order_violations"] == 0,
                "in-order retire"),
        ])
        return result
    if test_id == "selective_scheduling":
        return [
            metric("selective.dependent", m.get("blocked_dependents_only") is True,
                   "only dependent/same-resource work waits"),
            metric("selective.younger",
                   m.get("younger_independent_issued") is True,
                   "younger independent work issues"),
            metric("selective.resource",
                   m.get("different_resource_issued") is True,
                   "different resource keeps issuing"),
            metric("selective.freeze",
                   nonnegative_int(m.get("global_freeze_cycles"))
                   and m["global_freeze_cycles"] == 0,
                   "no arbitrary global freeze"),
        ]
    if test_id == "memory_ordering":
        return [
            metric("order.nonalias", m.get("nonalias_load_bypass") is True,
                   "non-alias younger load bypasses older store"),
            metric("order.alias", m.get("alias_forward_wait_replay") is True,
                   "alias forwards, waits, or replays"),
            metric("order.physical", m.get("physical_disambiguation") is True,
                   "physical byte disambiguation"),
            metric("order.stale", nonnegative_int(m.get("stale_read_count"))
                   and m["stale_read_count"] == 0, "zero stale reads"),
            metric("order.ghost", nonnegative_int(m.get("ghost_after_flush"))
                   and m["ghost_after_flush"] == 0, "zero post-flush ghosts"),
            metric("order.store_pre_auth", nonnegative_int(
                       m.get("store_side_effect_before_authorization"))
                   and m["store_side_effect_before_authorization"] == 0,
                   "zero store side effects before ROB-head authorization"),
            metric("order.store_exactly_once_fire", nonnegative_int(
                       m.get("store_authorization_fire_violations"))
                   and m["store_authorization_fire_violations"] == 0,
                   "every authorized store fires exactly once"),
            metric("order.store_b_terminal", nonnegative_int(
                       m.get("store_b_terminal_violations"))
                   and m["store_b_terminal_violations"] == 0,
                   "every fired store has exactly one aggregated B terminal"),
            metric("order.store_retire_after_b", nonnegative_int(
                       m.get("store_retire_before_b_success"))
                   and m["store_retire_before_b_success"] == 0,
                   "no successful store retires before B success"),
            metric("order.store_precise_b_error",
                   m.get("precise_b_error_trap") is True,
                   "SLVERR/DECERR produces a precise store-PC trap"),
            metric("order.store_drain_exactly_once",
                   m.get("fired_store_drain_exactly_once") is True,
                   "flush drains each already-fired store exactly once"),
        ]
    if test_id == "speculation_recovery":
        return [
            metric("recovery.multiple_controls",
                   m.get("multiple_controls_inflight") is True,
                   "multiple control-flow operations are simultaneously in flight"),
            metric("recovery.oldest_mispredict",
                   m.get("oldest_mispredict_wins") is True,
                   "the oldest mispredict determines recovery"),
            metric("recovery.selective_squash",
                   m.get("wrong_path_selective_squash") is True,
                   "only wrong-path uops and requests are squashed"),
            metric("recovery.axi_drain",
                   m.get("fired_axi_drained") is True,
                   "already-fired AXI transactions are drained"),
            metric("recovery.exactly_once_complete",
                   nonnegative_int(m.get(
                       "exactly_once_complete_violations"))
                   and m["exactly_once_complete_violations"] == 0,
                   "zero exactly-once completion violations"),
            metric("recovery.exactly_once_retire",
                   nonnegative_int(m.get(
                       "exactly_once_retire_violations"))
                   and m["exactly_once_retire_violations"] == 0,
                   "zero exactly-once retirement violations"),
            metric("recovery.ghost",
                   nonnegative_int(m.get("ghost_after_recovery"))
                   and m["ghost_after_recovery"] == 0,
                   "zero ghosts after recovery"),
        ]
    return [metric("known_test", False, "unknown evidence test")]


def evaluate(root: pathlib.Path, evidence_path: pathlib.Path | None) -> dict[str, Any]:
    contract_path = root / CONTRACT_REL
    contract = contract_path.read_text(encoding="utf-8")
    source_sha, source_files = rtl_binding(root)
    src_checks = source_checks(live_sources(root))
    evidence, evidence_errors = load_evidence(evidence_path)
    gates: dict[str, Any] = {}
    for gate_id in GATE_IDS:
        test_id = EVIDENCE_TEST[gate_id]
        checks = [
            Check("contract.clause", f"**{gate_id} " in contract,
                  f"normative {gate_id} clause exists"),
            *src_checks[gate_id],
        ]
        evidence_part, metrics = evidence_checks(
            root, evidence, source_sha, test_id)
        checks.extend(evidence_part)
        checks.extend(metric_checks(test_id, metrics))
        passed = not evidence_errors and all(item.passed for item in checks)
        gates[gate_id] = {
            "status": "GREEN" if passed else "RED",
            "evidence_test": test_id,
            "checks": [item.json() for item in checks],
        }
    green = all(value["status"] == "GREEN" for value in gates.values())
    return {
        "schema": RESULT_SCHEMA,
        "generated_at_utc": datetime.datetime.now(
            datetime.timezone.utc).isoformat(),
        "overall_status": "GREEN" if green else "RED",
        "exit_code": 0 if green else 1,
        "contract": {"path": CONTRACT_REL, "sha256": digest(contract_path)},
        "rtl_source_set": {
            "design_id": f"sha256:{source_sha}",
            "sha256": source_sha,
            "file_count": len(source_files),
            "files": source_files,
        },
        "evidence_manifest": str(evidence_path) if evidence_path else None,
        "evidence_errors": evidence_errors,
        "gates": gates,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path)
    parser.add_argument("--evidence-manifest", type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    args = parser.parse_args()
    try:
        root = args.repo_root.resolve() if args.repo_root else repo_root(
            pathlib.Path(__file__).resolve())
        evidence = args.evidence_manifest.resolve(
        ) if args.evidence_manifest else None
        result = evaluate(root, evidence)
        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_suffix(output.suffix + ".tmp")
        temporary.write_text(
            json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True)
            + "\n", encoding="utf-8")
        temporary.replace(output)
    except (OSError, UnicodeDecodeError, ValueError) as exc:
        print(f"ARCHITECTURE HARD GATE ERROR: {exc}", file=sys.stderr)
        return 2
    for gate_id in GATE_IDS:
        gate = result["gates"][gate_id]
        red = sum(check["status"] == "RED" for check in gate["checks"])
        print(f"{gate_id}: {gate['status']} ({red} red checks)")
    print(f"OVERALL: {result['overall_status']}")
    print(f"RESULT: {output}")
    return int(result["exit_code"])


if __name__ == "__main__":
    raise SystemExit(main())
