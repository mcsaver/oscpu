#!/usr/bin/env python3
"""Build and verify a fail-closed RV64 full-core ARCH_STABLE audit.

The tool is intentionally architecture-first.  ``audit`` always emits an
auditable result when the declaration is structurally readable; a current
GAP is therefore a successful audit, not a stable freeze.  ``--require-stable``
is the promotion-facing mode and returns non-zero until every prerequisite is
closed under one design id and one exact input cohort.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.util
import json
import math
import os
import pathlib
import re
import shutil
import subprocess
import sys
from typing import Any, Iterable

import jsonschema


CANDIDATE_SCHEMA = "npc-rv64-arch-stable-candidate-v2"
LEDGER_SCHEMA = "npc-rv64-architecture-debt-ledger-v2"
HISTORICAL_DEFECT_SCHEMA = (
    "npc-rv64-historical-defect-backfill-ledger-v1"
)
HISTORICAL_CURRENT_SCHEMA = "npc-rv64-historical-defect-current-v1"
RESULT_SCHEMA = "npc-rv64-arch-stable-result-v1"
INDEPENDENT_REVIEW_SCHEMA = (
    "npc-rv64-arch-stable-independent-review-v1"
)
ARCH_EVIDENCE_SCHEMA = "npc-rv64-architecture-directed-suite-v2"
ARCH_RESULT_SCHEMA = "npc-rv64-architecture-hard-gates-result-v2"
CENSUS_SCHEMA = "rv64-producer-holder-census-v1"
SEMANTIC_COVERAGE_SCHEMA = "rv64-producer-holder-semantic-coverage-v1"
SEMANTIC_COVERAGE_PATH = (
    "npc/rv64/design/arch/producer-holder-semantic-coverage.json"
)
SEMANTIC_COVERAGE_POLICY_PATH = (
    "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json"
)
GLOBAL_NO_LIVE_REUSE_SCHEMA = (
    "npc-rv64-global-producer-no-live-reuse-receipt-v2"
)
GLOBAL_NO_LIVE_REUSE_PATH = (
    "npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json"
)
FUNCTIONAL_SCHEMA = "npc-rv64-functional-aggregate-v2"
PROGRAM_IMAGE_CANONICALIZATION = "npc-rv64-program-image-map-v1"
DIFFTEST_PROFILE_SCHEMA = "npc-rv64-difftest-reference-profile-v1"
FUNCTIONAL_RESULT_SCHEMA = "npc-rv64-functional-aggregate-result-v1"
COHORT_SCHEMA = "npc-rv64-arch-stable-cohort-inventory-v1"
CURRENT_DEBT_SCHEMA = "npc-rv64-architecture-debt-current-v2"
CURRENT_DEBT_RECEIPT_KIND = "architecture_debt_current_receipt"
CURRENT_DEBT_TOOL_PATH = (
    "npc/rv64/eval/ppa/tools/architecture_debt_current.py"
)
SYSTEM_RECERTIFICATION_SCHEMA = (
    "npc-rv64-system-recertification-current-v2"
)
SYSTEM_RECERTIFICATION_PATH = (
    "npc/rv64/eval/ppa/evidence/system-recertification-current.json"
)
SYSTEM_RECERTIFICATION_TOOL_PATH = (
    "npc/rv64/eval/ppa/tools/system_recertification_current.py"
)
LAYERED_SYSTEM_SIGNOFF_PATH = (
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json"
)

GATE_IDS = {
    "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
    "OOO-1", "OOO-2", "OOO-3", "OOO-4",
}
UNRESOLVED_DEBT = {
    "OPEN", "UNKNOWN", "STALE_EVIDENCE", "SCOPE_DECISION_REQUIRED",
}
RESOLVED_DEBT = {"CLOSED", "EXCLUDED_BY_COHORT"}
ALL_DEBT_STATUSES = UNRESOLVED_DEBT | RESOLVED_DEBT
REQUIRED_FREEZE_GROUPS = {
    "config",
    "generated_headers",
    "filelists",
    "specifications",
    "test_sources",
    "tool_versions",
    "liberty",
    "macros",
    "constraints",
    "images",
    "binaries",
    "workflow",
}
DEBT_MARKER_RE = re.compile(
    r"<!--\s*ARCH-DEBT-(P[01])\s*:\s*([^>]+?)\s*-->")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
SCHEMA_PATHS = {
    CANDIDATE_SCHEMA: "npc/rv64/eval/ppa/schemas/arch-stable-candidate-v2.schema.json",
    LEDGER_SCHEMA: "npc/rv64/eval/ppa/schemas/architecture-debt-ledger-v2.schema.json",
    HISTORICAL_DEFECT_SCHEMA: (
        "npc/rv64/eval/ppa/schemas/"
        "historical-defect-backfill-ledger-v1.schema.json"
    ),
    HISTORICAL_CURRENT_SCHEMA: (
        "npc/rv64/eval/ppa/schemas/"
        "historical-defect-current-v1.schema.json"
    ),
    RESULT_SCHEMA: "npc/rv64/eval/ppa/schemas/arch-stable-result-v1.schema.json",
    INDEPENDENT_REVIEW_SCHEMA: (
        "npc/rv64/eval/ppa/schemas/"
        "arch-stable-independent-review-v1.schema.json"
    ),
    FUNCTIONAL_SCHEMA: "npc/rv64/eval/ppa/schemas/functional-aggregate-v2.schema.json",
    DIFFTEST_PROFILE_SCHEMA: "npc/rv64/eval/ppa/schemas/difftest-reference-profile-v1.schema.json",
    FUNCTIONAL_RESULT_SCHEMA: "npc/rv64/eval/ppa/schemas/functional-aggregate-result-v1.schema.json",
    COHORT_SCHEMA: "npc/rv64/eval/ppa/schemas/arch-stable-cohort-inventory-v1.schema.json",
    CURRENT_DEBT_SCHEMA: (
        "npc/rv64/eval/ppa/schemas/architecture-debt-current-v2.schema.json"
    ),
}
WORKFLOW_BINDING_PATHS = (
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/historical_defect_backfill.py",
    "npc/rv64/eval/ppa/tools/historical_defect_current.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tools/architecture_provenance_replay.py",
    "npc/rv64/eval/ppa/tools/functional_archive_rehydrate.py",
    "npc/rv64/eval/ppa/tools/arch_stable_current_candidate.py",
    "npc/rv64/eval/ppa/tools/functional_aggregate.py",
    "npc/rv64/eval/ppa/tools/producer_holder_census.py",
    "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py",
    "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py",
    "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py",
    "npc/rv64/eval/ppa/tools/system_recertification_current.py",
    "npc/rv64/eval/ppa/tools/layered_system_signoff.py",
    "npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py",
    "npc/rv64/eval/ppa/tools/architecture_debt_current.py",
    "npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py",
    "npc/rv64/eval/ppa/tools/memory_tracker_semantic_evidence.py",
    "npc/rv64/eval/ppa/tools/memory_tracker_cursor_semantic_evidence.py",
    "npc/rv64/eval/ppa/tools/fdg_arch_trap_evidence.py",
    "npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py",
    "npc/rv64/eval/ppa/tools/instret_retirement_evidence.py",
    "npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py",
    "npc/rv64/eval/ppa/tools/irrevocable_owner_residency_evidence.py",
    "npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py",
    "npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py",
    "npc/rv64/eval/ppa/tools/vectored_trap_evidence.py",
    "npc/rv64/eval/ppa/tests/test_architecture_debt_current.py",
    "npc/rv64/eval/ppa/tests/test_architecture_debt_delta_rebind.py",
    "npc/rv64/eval/ppa/architecture-debt-current-evidence.mk",
    "npc/rv64/eval/ppa/historical-defect-current-evidence.mk",
    "npc/rv64/eval/ppa/evidence/historical-defect-current.json",
    "npc/rv64/eval/ppa/run-arch-stable-audit.sh",
    "npc/rv64/design/arch/rv64-soc-delivery-gates.tsv",
    "npc/rv64/design/arch/rv64-soc-maturity-stages.tsv",
    ".github/instructions/rv64-ppa-optimization-workflow.instructions.md",
    "scripts/check-rv64-soc-delivery-gates.sh",
    "scripts/tests/test-rv64-soc-delivery-gates.sh",
    ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/run-focused.sh",
    ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/build-current-census-evidence.py",
    ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/mutate-v8l-global-lease.py",
    ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/run-focused.sh",
    ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/run-functional-aggregate.py",
    ".github/task-runs/2026-07-29-rv64-v11a-producer-holder-instance-graph/run-instance-graph.sh",
    ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/run-terminal-collector-focused.sh",
    ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/build-terminal-collector-evidence.py",
    ".github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/mutate-terminal-collector.py",
    ".github/task-runs/2026-07-29-rv64-v11c-memory-tracker-semantic-coverage/run-memory-tracker-focused.sh",
    ".github/task-runs/2026-07-30-rv64-v11d-memory-tracker-cursor-semantic-coverage/run-memory-tracker-cursor-focused.sh",
    "scripts/task-run-status.sh",
    "scripts/tests/test-task-run-status.sh",
    "npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_architecture_provenance_replay.py",
    "npc/rv64/eval/ppa/tests/test_functional_archive_rehydrate.py",
    "npc/rv64/eval/ppa/tests/test_arch_stable_current_candidate.py",
    "npc/rv64/eval/ppa/tests/test_historical_defect_backfill.py",
    "npc/rv64/eval/ppa/tests/test_historical_defect_current.py",
    "npc/rv64/design/arch/historical-defect-backfill-ledger.json",
    "npc/rv64/eval/ppa/tests/test_functional_aggregate.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
    "npc/rv64/eval/ppa/tests/test_v8l_current_census_evidence.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py",
    "npc/rv64/eval/ppa/tests/test_v11a_instance_graph_runner.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_semantic_coverage.py",
    "npc/rv64/eval/ppa/tests/test_global_producer_no_live_reuse.py",
    "npc/rv64/eval/ppa/tests/test_system_recertification_current.py",
    "npc/rv64/eval/ppa/tests/test_layered_system_signoff.py",
    "npc/rv64/eval/ppa/tests/test_terminal_collector_lane_contract.py",
    "npc/rv64/eval/ppa/tests/test_memory_tracker_semantic_evidence.py",
    "npc/rv64/eval/ppa/tests/test_memory_tracker_cursor_semantic_evidence.py",
    "npc/rv64/design/arch/producer-holder-semantic-coverage-policy.json",
    "npc/rv64/design/arch/producer-holder-semantic-coverage.json",
    "npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json",
    "npc/rv64/eval/ppa/evidence/system-recertification-current.json",
    "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json",
    "npc/rv64/design/arch/layered-system-signoff-policy-v1.json",
    "npc/rv64/eval/ppa/schemas/layered-system-signoff-current-v1.schema.json",
    "npc/rv64/eval/ppa/tests/test_fdg_arch_trap_evidence.py",
    "npc/rv64/eval/ppa/tests/test_xret_current_mode_evidence.py",
    "npc/rv64/eval/ppa/tests/test_instret_retirement_evidence.py",
    "npc/rv64/eval/ppa/tests/test_memory_issue_lifecycle_evidence.py",
    "npc/rv64/eval/ppa/tests/test_irrevocable_owner_residency_evidence.py",
    "npc/rv64/eval/ppa/tests/test_ifu_axi_flush_drain_evidence.py",
    "npc/rv64/eval/ppa/tests/test_ifu_fetch_provenance_evidence.py",
    "npc/rv64/eval/ppa/tests/test_vectored_trap_evidence.py",
    ".github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/run-focused.sh",
    *tuple(SCHEMA_PATHS.values()),
)
GROUP_KINDS = {
    "config": {"kconfig"},
    "generated_headers": {"generated_header"},
    "filelists": {"rtl_filelist", "test_inventory"},
    "specifications": {"architecture_spec", "module_spec"},
    "test_sources": {"module_test_source", "test_common", "test_runner"},
    "tool_versions": {"tool_version_manifest"},
    "liberty": {"standard_cell_liberty", "macro_liberty"},
    "macros": {"macro_inventory"},
    "constraints": {"primary_sdc"},
    "images": {"program_image"},
    "binaries": {"simulator_binary", "reference_model_binary"},
    "workflow": {
        "audit_checker", "canonical_architecture_checker",
        "holder_census_checker", "holder_instance_graph_checker",
        "holder_semantic_checker", "holder_lane_contract_checker",
        "holder_semantic_policy",
        "holder_census_test",
        "holder_lifecycle_runner", "holder_lifecycle_builder",
        "holder_lifecycle_mutator", "holder_lifecycle_test",
        "holder_instance_graph_runner", "holder_instance_graph_test",
        "holder_semantic_test", "holder_lane_contract_test",
        "terminal_collector_runner", "terminal_collector_builder",
        "terminal_collector_mutator",
        "memory_tracker_semantic_checker",
        "memory_tracker_semantic_test", "memory_tracker_semantic_runner",
        "memory_tracker_cursor_semantic_checker",
        "memory_tracker_cursor_semantic_test",
        "memory_tracker_cursor_semantic_runner",
        "task_run_status_helper", "task_run_status_test",
        "audit_runner", "audit_test", "json_schema",
    },
}
TOOL_VERSION_ARGS = {
    "python3": ("--version",),
    "iverilog": ("-V",),
    "vvp": ("-V",),
    "verilator": ("--version",),
    "yosys": ("-V",),
    "sta": ("-version",),
}

CONTROL_EVENT_RUN_ID = "2026-07-23-rv64-v9o-control-event-current-design"
CONTROL_EVENT_COMMAND = (
    "python3 .github/task-runs/"
    f"{CONTROL_EVENT_RUN_ID}/build-evidence-index.py --verify"
)
CONTROL_EVENT_INDEX_PATH = (
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/evidence-index.json"
)
CONTROL_EVENT_MUTATION_PATH = (
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/mutations/summary.json"
)
CONTROL_EVENT_SOURCE_HELPER = (
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/evidence_source_set.py"
)
CONTROL_EVENT_INDEX_SCHEMA = "npc-rv64-control-event-evidence-index-v1"
CONTROL_EVENT_MUTATION_SCHEMA = "npc-rv64-control-event-rtl-mutations-v3"
CONTROL_EVENT_PROVENANCE_PATHS = {
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/build-evidence-index.py",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/evidence_source_set.py",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/run-focused.sh",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/run-v9o-config-variants.sh",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/"
    "run-control-event-rtl-mutations.py",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/run-module-aggregate.sh",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/"
    "refresh-architecture-evidence.sh",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/run-arch-stable-boundary.sh",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/contract.md",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/completion-definition.md",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/rtl-derivation.md",
    "npc/rv64/design/specs/ooo-control-event-apply-sequencer.md",
    "npc/rv64/design/specs/ooo-core-top-glue.md",
    "npc/rv64/design/specs/ooo-flush-redirect-contract.md",
    "npc/rv64/design/specs/ooo-frontend-action-gate.md",
    "npc/rv64/design/specs/ooo-load-queue.md",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-redirect-arbiter.md",
    "npc/rv64/design/specs/ooo-rob.md",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py",
    "npc/rv64/eval/ppa/schemas/architecture-debt-ledger-v2.schema.json",
}
CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS = {
    CONTROL_EVENT_INDEX_PATH,
    "npc/rv64/design/arch/architecture-debt-ledger.json",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/gates/"
    "arch-stable-audit.json",
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/gates/"
    "arch-stable-boundary.log",
}
CONTROL_EVENT_ARCHITECTURE_RESULT_PATH = (
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/gates/"
    "final-architecture-hard-gates.json"
)
CONTROL_EVENT_ARCHITECTURE_MANIFEST_PATH = (
    "npc/rv64/eval/ppa/evidence/architecture-current.json"
)
CONTROL_EVENT_ARCHITECTURE_REFRESH_LOG_PATH = (
    f".github/task-runs/{CONTROL_EVENT_RUN_ID}/gates/"
    "architecture-evidence-refresh.log"
)
V9R_SQ_RETRY_RUN_ID = "2026-07-24-rv64-v9r-sq-retry-c0-handoff"
V9R_SQ_RETRY_SUMMARY_PATH = (
    f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/evidence/summary.json"
)
V9R_SQ_RETRY_SCHEMA = "npc-rv64-v9r-sq-retry-c0-evidence-v2"
CONTROL_EVENT_CURRENT_TOOL_PATH = (
    "npc/rv64/eval/ppa/tools/control_event_current_evidence.py"
)
CONTROL_EVENT_SQ_RETRY_TOOL_PATH = (
    "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py"
)
CONTROL_EVENT_CURRENT_RESULT_PATH = (
    "npc/rv64/eval/ppa/evidence/control-event-current.json"
)
V9R_SQ_RETRY_CURRENT_RESULT_PATH = (
    "npc/rv64/eval/ppa/evidence/control-event-sq-retry-current.json"
)
CONTROL_EVENT_CURRENT_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/control-event-evidence.mk check-control-event-current "
    "check-control-event-sq-retry"
)
V9R_SQ_RETRY_SOURCE_PATHS = {
    f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/run-v9r-evidence.sh",
    f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/"
    "mutate-v9r-sq-retry-c0.py",
    f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/"
    "close-control-event-current-design.py",
    f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/contract.md",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/design/specs/ooo-mem-axi-bridge-fsm.md",
    "npc/rv64/design/specs/ooo-memory-producer-lease.md",
    "npc/rv64/design/specs/ooo-dual-memory-datapath.md",
    "npc/rv64/eval/ppa/tools/producer_holder_census.py",
    "npc/rv64/eval/ppa/tests/test_producer_holder_census.py",
}
V9R_SQ_RETRY_BASELINE_MARKERS = {
    "tb_ooo_int_backend_v9r_sq_retry_c0": (
        "[V9R-SQ-RETRY-C0-HANDOFF-PASS] "
        "banks=2 forced=2 natural_trap=1 PASS",
        "[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS",
    ),
    "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0": (
        "[V9R-MEM-SQ-RETRY-C0-HANDOFF-PASS] "
        "state=S_SQ_QUERY held=1 release=1 PASS",
    ),
}
V9R_SQ_RETRY_VARIANTS = {
    "backend-bank0-ready-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v9r_sq_retry_c0",
        "mutated_rtl": "OooIntBackend.v",
        "assertion_marker": (
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier"
        ),
    },
    "backend-bank1-ready-open": {
        "production_source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend_v9r_sq_retry_c0",
        "mutated_rtl": "OooIntBackend.v",
        "assertion_marker": (
            "[V9R-SQ-RETRY-C0-HANDOFF] retry holder transfer exposed "
            "during full-flush barrier"
        ),
    },
    "bridge-retry-fire-open": {
        "production_source": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "test_name": "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0",
        "mutated_rtl": "OooMemAxiBridge.v",
        "assertion_marker": (
            "[V9R-MEM-SQ-RETRY-C0-HANDOFF] bridge released SQ-query "
            "owner during full-flush barrier"
        ),
    },
}
CONTROL_EVENT_FOCUSED_TESTS = {
    "tb_ooo_control_event_apply_sequencer",
    "tb_ooo_redirect_arbiter",
    "tb_ooo_frontend_action_gate",
    "tb_ooo_load_queue",
    "tb_ooo_rob",
    "tb_ooo_dispatch_backend",
    "tb_ooo_int_backend",
    "tb_ooo_mem_axi_bridge",
    "tb_ooo_dual_mem_bridge_wrapper",
    "tb_ooo_core_top_glue",
}
CONTROL_EVENT_CONFIG_TESTS = {
    "tb_ooo_rob",
    "tb_ooo_core_top_glue_v9o_csr_qh",
    "tb_ooo_core_top_glue",
}
CONTROL_EVENT_MUTATIONS = {
    "strict_younger_changed_to_greater_equal",
    "c0_request_does_not_reach_c1",
    "typed_reason_is_not_latched",
    "c0_request_is_reconstructed_from_trap_pulse",
    "pending_csr_owner_ignores_producer_id",
    "head0_pregrant_does_not_mask_branch_event",
    "head0_pregrant_does_not_mask_branch_recovery",
    "queue_head_mode_requires_both_memory_pair_ids_at_head",
    "registered_read_address_valid_is_barrier_gated",
    "registered_write_valids_are_barrier_gated",
    "pregrant_reads_current_completion_ready",
}
CONTROL_EVENT_MUTATION_CONTRACTS = {
    "strict_younger_changed_to_greater_equal": {
        "source": "npc/rv64/vsrc/writeback/OooRob.v",
        "test_name": "tb_ooo_rob",
        "make_variable": "RTL_OOO_ROB",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "v8f kill boundary remains completion-open",
            "v8f recovery preserves boundary completion query",
            "v8j generic completion also keeps equal boundary open",
        ),
    },
    "c0_request_does_not_reach_c1": {
        "source": "npc/rv64/vsrc/control/OooControlEventApplySequencer.v",
        "test_name": "tb_ooo_control_event_apply_sequencer",
        "make_variable": "RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": ("trap apply C1 valid got=0 exp=1",),
    },
    "typed_reason_is_not_latched": {
        "source": "npc/rv64/vsrc/control/OooControlEventApplySequencer.v",
        "test_name": "tb_ooo_control_event_apply_sequencer",
        "make_variable": "RTL_OOO_CONTROL_EVENT_APPLY_SEQUENCER",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": ("trap apply C1 reason got=0 exp=3",),
    },
    "c0_request_is_reconstructed_from_trap_pulse": {
        "source": "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "test_name": "tb_ooo_core_top_glue_v9o_csr_qh",
        "make_variable": "RTL_OOO_CORE_TOP_GLUE",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "V9O macro-on real queue-head CSR emits C1 typed apply",
        ),
    },
    "pending_csr_owner_ignores_producer_id": {
        "source": "npc/rv64/vsrc/writeback/OooRob.v",
        "test_name": "tb_ooo_rob",
        "make_variable": "RTL_OOO_ROB",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "V9O mismatched pending owner keeps queue-head full pregrant",
        ),
    },
    "head0_pregrant_does_not_mask_branch_event": {
        "source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend",
        "make_variable": "RTL_OOO_INT_BACKEND",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "V9O C0 suppresses younger branch event",
            "V9O pending CSR pregrant suppresses younger branch event",
        ),
    },
    "head0_pregrant_does_not_mask_branch_recovery": {
        "source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_int_backend",
        "make_variable": "RTL_OOO_INT_BACKEND",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "V9O C0 suppresses younger branch recovery",
            "V9O pending CSR pregrant suppresses younger branch recovery",
        ),
    },
    "queue_head_mode_requires_both_memory_pair_ids_at_head": {
        "source": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "test_name": "tb_ooo_core_top_glue",
        "make_variable": "RTL_OOO_INT_BACKEND",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": (
            "[CHECK-FAIL] memory program reaches ebreak got=0 expected=1",
        ),
    },
    "registered_read_address_valid_is_barrier_gated": {
        "source": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "test_name": "tb_ooo_mem_axi_bridge",
        "make_variable": "RTL_OOO_MEM_AXI_BRIDGE",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": ("V9O C0 keeps registered ARVALID",),
    },
    "registered_write_valids_are_barrier_gated": {
        "source": "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
        "test_name": "tb_ooo_mem_axi_bridge",
        "make_variable": "RTL_OOO_MEM_AXI_BRIDGE",
        "rejection_mode": "dynamic",
        "make_returncode": 2,
        "lint_returncode": None,
        "expected_markers": ("V9O C0 keeps registered AWVALID",),
    },
    "pregrant_reads_current_completion_ready": {
        "source": "npc/rv64/vsrc/writeback/OooRob.v",
        "test_name": "tb_ooo_rob",
        "make_variable": "RTL_OOO_ROB",
        "rejection_mode": "lint-unoptflat",
        "make_returncode": 0,
        "lint_returncode": 0,
        "expected_markers": (
            "%Warning-UNOPTFLAT: <LOCAL-TEMP>/OooRob.v:361:26:",
        ),
    },
}
CONTROL_EVENT_MUTATION_TOP_LEVEL_KEYS = {
    "schema", "suite_run_id", "required", "compile_success",
    "dynamic_rejected", "lint_rejected", "rejected",
    "baseline_unoptflat", "baseline_lint", "design_id", "rtl_source_set",
    "full_rtl_source_unchanged", "verification_source_set",
    "verification_source_unchanged", "source_unchanged",
    "source_sha256_before", "source_sha256_after", "results",
}
CONTROL_EVENT_MUTATION_RESULT_KEYS = {
    "compile_success", "dynamic_rejected", "expected_markers",
    "extra_ivflags", "lint_rejected", "lint_returncode", "log",
    "make_returncode", "make_variable", "mutation_sha256", "name",
    "observed_markers", "oracle_family", "original_sha256", "purpose",
    "rejected", "rejection_mode", "source", "test_name",
}
CONTROL_EVENT_CSR_QUEUE_HEAD_MUTATIONS = {
    "pending_csr_owner_ignores_producer_id",
    "queue_head_mode_requires_both_memory_pair_ids_at_head",
}
CONTROL_EVENT_STATIC_CONTRACT = {
    "single_c0_request_valid_source": True,
    "single_c0_request_reason_source": True,
    "trap_pregrant_bidirectional_assertion": True,
    "csr_pregrant_bidirectional_assertion": True,
    "completion_matrix_has_eight_classes": True,
    "dual_registered_ar_barrier_oracle": True,
}
CONTROL_EVENT_CRITICAL_LOG_MARKERS = {
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
        "tb_ooo_rob.log"
    ): (
        "[V9O-FULL-C0-COMPLETION-MATRIX] "
        "classes=8 wrap_head=15 wrap_younger=0 PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
        "tb_ooo_int_backend.log"
    ): (
        "[V9O-BACKEND-C0-BARRIER] "
        "younger branch/dispatch/memory actions held PASS",
        "[V9O-PENDING-CSR-BRANCH-PRIORITY] "
        "older action-NONE commit suppresses younger branch PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
        "tb_ooo_mem_axi_bridge.log"
    ): (
        "[V9O-MEM-C0-BARRIER] "
        "pre-owner held; registered AR/AW/W owners preserved PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
        "tb_ooo_dual_mem_bridge_wrapper.log"
    ): (
        "[V9O-DUAL-REGISTERED-AR-BARRIER] "
        "lanes=2 hold_cycles=4 terminals=2 PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
        "tb_ooo_core_top_glue.log"
    ): (
        "[V9O-CONTROL-EVENT-C0-C1] "
        "source-to-typed-apply timing PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/config-variants/logs/"
        "tb_ooo_rob.log"
    ): (
        "[V9O-FULL-C0-COMPLETION-MATRIX] "
        "classes=8 wrap_head=15 wrap_younger=0 PASS",
        "[V9O-CSR-OWNER-CLASS-PASS] "
        "exact pending CSR ProducerId classified without full flush",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/config-variants/logs/"
        "tb_ooo_core_top_glue_v9o_csr_qh.log"
    ): (
        "[V9O-CSR-QH-CORE-INTEGRATION] "
        "real queue-head CSR C0/C1 PASS",
        "[V9O-PENDING-CSR-OWNER-INTEGRATION] "
        "exact type/PID action-NONE path PASS",
        "[V9O-CSR-MEMORY-ORDER-INTEGRATION] "
        "older drain/younger refetch PASS",
    ),
    (
        f".github/task-runs/{CONTROL_EVENT_RUN_ID}/config-variants/logs/"
        "tb_ooo_core_top_glue.log"
    ): (
        "[V9O-CONTROL-EVENT-C0-C1] "
        "source-to-typed-apply timing PASS",
    ),
}


def reject_json_constant(value: str) -> None:
    raise ValueError(f"non-finite JSON constant is forbidden: {value}")


def load_json(path: pathlib.Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle, parse_constant=reject_json_constant)
    if not isinstance(value, dict):
        raise ValueError(f"{path}: top-level JSON must be an object")
    return value


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return sha256_bytes(encoded)


def find_repo_root(start: pathlib.Path) -> pathlib.Path:
    current = start.resolve()
    for path in (current, *current.parents):
        if (path / ".git").exists():
            return path
    raise RuntimeError("cannot locate repository root")


def safe_regular_file(root: pathlib.Path, relative: Any) -> tuple[pathlib.Path | None, str | None]:
    if not isinstance(relative, str) or not relative:
        return None, "path must be a non-empty workspace-relative string"
    pure = pathlib.PurePosixPath(relative)
    if pure.is_absolute() or ".." in pure.parts or "\\" in relative:
        return None, f"path escapes workspace or is not POSIX-relative: {relative!r}"
    canonical_relative = pure.as_posix()
    if relative != canonical_relative or "." in relative.split("/"):
        return None, f"path is not canonical workspace-relative POSIX form: {relative!r}"
    path = root.joinpath(*pure.parts)
    cursor = root
    for part in pure.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            return None, f"path contains a symlink component: {relative}"
    try:
        resolved = path.resolve(strict=True)
        resolved.relative_to(root.resolve())
    except (FileNotFoundError, OSError, ValueError):
        return None, f"path is missing or escapes workspace: {relative}"
    if path.is_symlink() or not resolved.is_file():
        return None, f"path must be a regular non-symlink file: {relative}"
    return resolved, None


def artifact_observation(root: pathlib.Path, relative: Any) -> tuple[dict[str, Any], list[str]]:
    path, error = safe_regular_file(root, relative)
    if error:
        return {"path": relative, "status": "INVALID"}, [error]
    assert path is not None
    return {
        "path": relative,
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
        "status": "PRESENT",
    }, []


def schema_errors(
    root: pathlib.Path,
    value: Any,
    schema_name: str,
) -> list[str]:
    relative = SCHEMA_PATHS.get(schema_name)
    if relative is None:
        return [f"no registered JSON schema for {schema_name}"]
    path, error = safe_regular_file(root, relative)
    if error or path is None:
        return [error or f"schema is missing: {relative}"]
    try:
        schema = load_json(path)
        validator = jsonschema.Draft202012Validator(schema)
        return [
            f"{'.'.join(str(item) for item in issue.absolute_path) or '<root>'}: "
            f"{issue.message}"
            for issue in sorted(
                validator.iter_errors(value),
                key=lambda issue: tuple(str(item) for item in issue.absolute_path),
            )
        ]
    except (OSError, ValueError, json.JSONDecodeError, jsonschema.SchemaError) as exc:
        return [f"cannot validate {schema_name}: {exc}"]


def artifact_entry_observation(
    root: pathlib.Path,
    entry: Any,
    *,
    allowed_kinds: set[str],
) -> tuple[dict[str, Any], list[str]]:
    if not isinstance(entry, dict):
        return {"status": "INVALID"}, ["artifact entry must be an object"]
    errors: list[str] = []
    if set(entry) != {"kind", "path", "sha256"}:
        errors.append(
            "artifact entry keys must be exactly kind/path/sha256")
    kind = entry.get("kind")
    if kind not in allowed_kinds:
        errors.append(f"artifact kind {kind!r} is not allowed")
    artifact, path_errors = artifact_observation(root, entry.get("path"))
    errors.extend(path_errors)
    if not path_errors and entry.get("sha256") != artifact.get("sha256"):
        errors.append("artifact sha256 does not match current file")
    return {"kind": kind, **artifact}, errors


def load_workspace_module(root: pathlib.Path, relative: str, label: str) -> Any:
    path, error = safe_regular_file(root, relative)
    if error or path is None:
        raise ValueError(error or f"missing workspace module: {relative}")
    module_name = f"_{label}_{sha256_file(path)[:16]}_{id(root)}"
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load workspace module: {relative}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


_CURRENT_DEBT_TOOL_CACHE: dict[tuple[str, str], Any] = {}


def load_current_debt_tool(root: pathlib.Path) -> Any:
    path, error = safe_regular_file(root, CURRENT_DEBT_TOOL_PATH)
    if error or path is None:
        raise ValueError(error or "current architecture-debt tool is missing")
    key = (str(root.resolve()), sha256_file(path))
    module = _CURRENT_DEBT_TOOL_CACHE.get(key)
    if module is None:
        module = load_workspace_module(
            root,
            CURRENT_DEBT_TOOL_PATH,
            "architecture_debt_current",
        )
        _CURRENT_DEBT_TOOL_CACHE[key] = module
    return module


def add_check(
    checks: list[dict[str, Any]],
    blockers: list[str],
    check_id: str,
    passed: bool,
    detail: str,
) -> None:
    checks.append({
        "check_id": check_id,
        "status": "PASS" if passed else "GAP",
        "detail": detail,
    })
    if not passed:
        blockers.append(f"{check_id}: {detail}")


def parse_debt_markers(text: str) -> tuple[dict[str, str], list[str]]:
    found: dict[str, str] = {}
    errors: list[str] = []
    marker_count = 0
    for match in DEBT_MARKER_RE.finditer(text):
        marker_count += 1
        priority = match.group(1)
        ids = [item.strip() for item in match.group(2).split(",")]
        if not ids or any(not item for item in ids):
            errors.append(f"ARCH-DEBT-{priority} marker contains an empty id")
            continue
        for debt_id in ids:
            if debt_id in found:
                errors.append(f"duplicate ROADMAP debt id: {debt_id}")
            else:
                found[debt_id] = priority
    if marker_count != 2:
        errors.append(f"ROADMAP must contain exactly two debt markers, found {marker_count}")
    if not any(priority == "P0" for priority in found.values()):
        errors.append("ROADMAP debt marker has no P0 entries")
    if not any(priority == "P1" for priority in found.values()):
        errors.append("ROADMAP debt marker has no P1 entries")
    return found, errors


def _is_nonempty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_store_bresp_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    errors: list[str] = []
    if entry.get("canonical_command") != "make -C npc/rv64 check-memory-ordering":
        errors.append("STORE-BRESP-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    required_kinds = {
        "architecture_directed_suite",
        "raw_log",
        "irrevocable_owner_residency_result",
        "irrevocable_owner_residency_raw",
    }
    if set(by_kind) != required_kinds:
        errors.append(
            "STORE-BRESP-G1 requires exact directed-suite, memory raw, "
            "owner-residency result and owner-residency raw evidence")
        return errors
    suite_path, suite_error = safe_regular_file(
        root, by_kind["architecture_directed_suite"].get("path"))
    log_path, log_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if suite_error or suite_path is None:
        errors.append(suite_error or "directed suite is missing")
        return errors
    if log_error or log_path is None:
        errors.append(log_error or "raw log is missing")
        return errors
    suite = load_json(suite_path)
    record = suite.get("tests", {}).get("memory_ordering")
    metrics = record.get("metrics") if isinstance(record, dict) else None
    mutation = record.get("mutation_audit") if isinstance(record, dict) else None
    provenance = record.get("provenance") if isinstance(record, dict) else None
    suite_ok = (
        suite.get("schema") == ARCH_EVIDENCE_SCHEMA
        and suite.get("design_id") == expected_design_id
        and isinstance(record, dict)
        and record.get("status") == "PASS"
        and record.get("command") == "make -C npc/rv64 check-memory-ordering"
        and isinstance(metrics, dict)
        and metrics.get("precise_b_error_trap") is True
        and metrics.get("store_retire_before_b_success") == 0
        and metrics.get("store_b_terminal_violations") == 0
        and metrics.get("store_side_effect_before_authorization") == 0
        and isinstance(mutation, dict)
        and mutation.get("lq_compile_success_dynamic_reject", 0) > 0
        and mutation.get("f2_compile_success_dynamic_reject", 0) > 0
        and isinstance(provenance, dict)
        and provenance.get("rtl_sha256") == expected_design_id.removeprefix("sha256:")
        and isinstance(provenance.get("files"), dict)
        and bool(provenance["files"])
    )
    if not suite_ok:
        errors.append("STORE-BRESP-G1 directed suite semantics are incomplete or cross-design")
    text = log_path.read_text(encoding="utf-8")
    required_log_markers = (
        f"design_id={expected_design_id}",
        "metric precise_b_error_trap true",
        "metric store_retire_before_b_success 0",
        "metric store_b_terminal_violations 0",
        "lq_compile_success_mutations=9",
        "[ARCH-GATE] memory_ordering PASS",
    )
    missing = [marker for marker in required_log_markers if marker not in text]
    if missing:
        errors.append(f"STORE-BRESP-G1 raw log missing markers={missing}")

    owner_result_path, owner_result_error = safe_regular_file(
        root, by_kind["irrevocable_owner_residency_result"].get("path"))
    owner_raw_path, owner_raw_error = safe_regular_file(
        root, by_kind["irrevocable_owner_residency_raw"].get("path"))
    if owner_result_error or owner_result_path is None:
        errors.append(owner_result_error or "owner-residency result is missing")
        return errors
    if owner_raw_error or owner_raw_path is None:
        errors.append(owner_raw_error or "owner-residency raw log is missing")
        return errors

    owner = load_json(owner_result_path)
    owner_claim = owner.get("claim")
    focused = owner.get("focused")
    mutation = owner.get("mutation_audit")
    owner_provenance = owner.get("provenance")
    expected_mutations = {
        "sq_clear_owner_valid_on_request_fire",
        "amo_clear_kind_on_write_fire",
    }
    owner_ok = (
        owner.get("schema") ==
            "npc-rv64-irrevocable-owner-residency-evidence-v1"
        and owner.get("run_id") ==
            "2026-07-23-rv64-v9n-irrevocable-write-owner-residency"
        and owner.get("status") == "PASS"
        and owner.get("design_id") == expected_design_id
        and owner.get("canonical_command") ==
            "make -C npc/rv64 check-memory-ordering"
        and owner.get("ppa") == "UNQUALIFIED"
        and owner.get("promotion_eligible") is False
        and owner_claim == {
            "store_next_edge_owner_residency": True,
            "amo_next_edge_owner_residency": True,
            "canonical_top_global_flush_static_low": True,
            "canonical_top_global_flush_binding":
                "NpcCoreTop.u_ooo_core.flush_i=1'b0",
        }
        and isinstance(focused, dict)
        and set(focused) == {"store", "amo"}
        and isinstance(mutation, dict)
        and mutation.get("required") == 2
        and mutation.get("compile_success") == 2
        and mutation.get("dynamic_rejected") == 2
        and mutation.get("old_same_edge_assertion_quiet") == 2
        and set(mutation.get("identities", [])) == expected_mutations
        and isinstance(owner_provenance, dict)
        and owner_provenance.get("rtl_sha256") ==
            expected_design_id.removeprefix("sha256:")
        and isinstance(owner_provenance.get("rtl_file_count"), int)
        and owner_provenance.get("rtl_file_count", 0) > 0
        and isinstance(owner_provenance.get("files"), dict)
        and len(owner_provenance.get("files", {})) >= 4
    )
    if not owner_ok:
        errors.append(
            "STORE-BRESP-G1 owner-residency result semantics are incomplete")
        return errors

    focused_specs = {
        "store": (
            "tb_v9n_sq_owner_residency",
            "[V9N-SQ-NEXT-EDGE-OWNER] "
            "launch=1 preserved=1 exact_terminal=1 PASS",
        ),
        "amo": (
            "tb_v9n_amo_owner_residency",
            "[V9N-AMO-NEXT-EDGE-OWNER] "
            "launch=1 preserved=1 exact_terminal=1 PASS",
        ),
    }
    bound_artifact_paths: set[str] = set()
    for name, (test_name, marker) in focused_specs.items():
        row = focused.get(name)
        log_record = row.get("log") if isinstance(row, dict) else None
        path, error = safe_regular_file(
            root, log_record.get("path") if isinstance(log_record, dict) else None)
        if (
            not isinstance(row, dict)
            or row.get("test") != test_name
            or row.get("marker") != marker
            or not isinstance(log_record, dict)
            or error
            or path is None
            or log_record.get("sha256") != sha256_file(path)
        ):
            errors.append(
                f"STORE-BRESP-G1 {name} owner-residency focused binding is stale")
            continue
        bound_artifact_paths.add(log_record["path"])
        focused_text = path.read_text(encoding="utf-8")
        focused_required = (
            marker,
            f"[PASS] {test_name}",
            "[RESULT] PASS",
            f"[RTL-DESIGN-ID] {expected_design_id}",
        )
        if (
            any(focused_text.count(item) != 1 for item in focused_required)
            or any(item in focused_text for item in (
                "[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:"))
        ):
            errors.append(
                f"STORE-BRESP-G1 {name} next-edge simulation is not a clean pass")

    summary_record = mutation.get("summary")
    summary_path, summary_error = safe_regular_file(
        root,
        summary_record.get("path") if isinstance(summary_record, dict) else None,
    )
    if (
        not isinstance(summary_record, dict)
        or summary_error
        or summary_path is None
        or summary_record.get("sha256") != sha256_file(summary_path)
    ):
        errors.append("STORE-BRESP-G1 owner-residency variant summary is stale")
    else:
        bound_artifact_paths.add(summary_record["path"])
        summary = load_json(summary_path)
        rows = summary.get("results")
        source_before = summary.get("source_sha256_before")
        source_after = summary.get("source_sha256_after")
        summary_ok = (
            summary.get("schema") ==
                "npc-rv64-irrevocable-owner-residency-rtl-variants-v1"
            and summary.get("suite_run_id") ==
                "2026-07-23-rv64-v9n-irrevocable-write-owner-residency"
            and summary.get("required") == 2
            and summary.get("compile_success") == 2
            and summary.get("dynamic_rejected") == 2
            and summary.get("source_unchanged") is True
            and isinstance(rows, list)
            and {row.get("name") for row in rows if isinstance(row, dict)} ==
                expected_mutations
            and isinstance(source_before, dict)
            and source_before == source_after
        )
        if not summary_ok:
            errors.append(
                "STORE-BRESP-G1 owner-residency variant aggregate is incomplete")
        else:
            runner = load_workspace_module(
                root,
                ".github/task-runs/2026-07-23-rv64-v9n-"
                "irrevocable-write-owner-residency/"
                "run-owner-residency-rtl-variants.py",
                "v9n_owner_residency_variants",
            )
            specs = {spec.name: spec for spec in runner.VARIANTS}
            if set(specs) != expected_mutations:
                errors.append(
                    "STORE-BRESP-G1 live owner-residency variant set drifted")
            for row in rows:
                if not isinstance(row, dict) or row.get("name") not in specs:
                    errors.append("STORE-BRESP-G1 owner-residency variant row invalid")
                    continue
                spec = specs[row["name"]]
                original, variant = runner.reconstruct_variant(root, spec)
                live_original_sha = sha256_bytes(original.encode("utf-8"))
                live_variant_sha = sha256_bytes(variant.encode("utf-8"))
                log_record = row.get("log")
                variant_log, variant_log_error = safe_regular_file(
                    root,
                    log_record.get("path")
                    if isinstance(log_record, dict) else None,
                )
                if (
                    row.get("source") != spec.source_rel
                    or row.get("make_variable") != spec.make_variable
                    or row.get("test_name") != spec.test_name
                    or row.get("original_sha256") != live_original_sha
                    or row.get("variant_sha256") != live_variant_sha
                    or live_original_sha == live_variant_sha
                    or source_before.get(spec.source_rel) != live_original_sha
                    or row.get("expected_marker") != spec.expected_marker
                    or row.get("marker_observed") is not True
                    or row.get("old_same_edge_assertion_quiet") is not True
                    or row.get("compile_success") is not True
                    or row.get("dynamic_rejected") is not True
                    or not isinstance(log_record, dict)
                    or variant_log_error
                    or variant_log is None
                    or log_record.get("sha256") != sha256_file(variant_log)
                ):
                    errors.append(
                        "STORE-BRESP-G1 owner-residency variant binding is "
                        f"incomplete: {row.get('name')}")
                    continue
                bound_artifact_paths.add(log_record["path"])
                variant_text = variant_log.read_text(encoding="utf-8")
                check_fail_lines = [
                    line for line in variant_text.splitlines()
                    if line.startswith("[CHECK-FAIL] ")
                ]
                fail_lines = [
                    line for line in variant_text.splitlines()
                    if line.startswith("[FAIL] ")
                ]
                result_lines = [
                    line for line in variant_text.splitlines()
                    if line.startswith("[RESULT] ")
                ]
                compile_lines = [
                    line for line in variant_text.splitlines()
                    if line.startswith("[COMPILE] ")
                ]
                if (
                    len(compile_lines) != 1
                    or check_fail_lines != [spec.expected_marker]
                    or fail_lines != [f"[FAIL] {spec.test_name} errors=1"]
                    or result_lines != ["[RESULT] FAIL status=1"]
                    or spec.superseded_same_edge_marker in variant_text
                    or "[RESULT] PASS" in variant_text
                    or "[TIMEOUT]" in variant_text
                    or "FATAL:" in variant_text
                ):
                    errors.append(
                        "STORE-BRESP-G1 owner-residency dynamic rejection "
                        f"is not exact: {row.get('name')}")

    artifacts = owner.get("artifacts")
    if not isinstance(artifacts, dict) or set(artifacts) != bound_artifact_paths:
        errors.append("STORE-BRESP-G1 owner-residency artifact inventory drifted")
    elif any(
        (lambda observed: observed[0] is None or observed[1] is not None or
         sha256_file(observed[0]) != digest)(safe_regular_file(root, rel))
        for rel, digest in artifacts.items()
    ):
        errors.append("STORE-BRESP-G1 owner-residency artifact digest is stale")

    owner_files = owner_provenance.get("files")
    required_owner_sources = {
        ".github/task-runs/2026-07-23-rv64-v9n-"
        "irrevocable-write-owner-residency/"
        "run-owner-residency-rtl-variants.py",
        "npc/rv64/vsrc/memory/OooStoreQueue.v",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
        "npc/rv64/vsrc/core/NpcCoreTop.v",
    }
    if (
        not isinstance(owner_files, dict)
        or not required_owner_sources.issubset(owner_files)
    ):
        errors.append("STORE-BRESP-G1 owner-residency provenance inventory drifted")
    elif any(
        (lambda observed: observed[0] is None or observed[1] is not None or
         sha256_file(observed[0]) != digest)(safe_regular_file(root, rel))
        for rel, digest in owner_files.items()
    ):
        errors.append("STORE-BRESP-G1 owner-residency provenance file is stale")
    elif owner_provenance.get("sha256") != canonical_sha256(owner_files):
        errors.append("STORE-BRESP-G1 owner-residency provenance digest is stale")

    top_path, top_error = safe_regular_file(root, "npc/rv64/vsrc/core/NpcCoreTop.v")
    top_binding = (
        "  ) u_ooo_core (\n"
        "    .clk(clk),\n"
        "    .rst(rst),\n"
        "    .flush_i(1'b0),"
    )
    if (
        top_error
        or top_path is None
        or top_path.read_text(encoding="utf-8").count(top_binding) != 1
    ):
        errors.append("STORE-BRESP-G1 canonical top flush binding drifted")

    owner_raw = owner_raw_path.read_text(encoding="utf-8")
    owner_raw_markers = (
        f"design_id={expected_design_id}",
        "store_next_edge_owner_residency=true",
        "amo_next_edge_owner_residency=true",
        "canonical_top_global_flush_static_low=true",
        "focused_passed=2",
        "compile_success_variants=2",
        "dynamic_rejected_variants=2",
        "old_same_edge_assertion_quiet=2",
        "[STORE-BRESP-G1-OWNER-RESIDENCY] PASS",
        "ppa=UNQUALIFIED",
    )
    owner_raw_missing = [
        item for item in owner_raw_markers if owner_raw.count(item) != 1
    ]
    if owner_raw_missing:
        errors.append(
            "STORE-BRESP-G1 owner-residency raw log missing unique "
            f"markers={owner_raw_missing}")
    return errors


FDG_RESULT_SCHEMA = "npc-rv64-fdg-arch-trap-evidence-v1"
FDG_MUTATION_SCHEMA = "npc-rv64-fdg-rtl-mutations-v1"
FDG_RUN_ID = "2026-07-21-rv64-v9d-fdg-arch-trap"
FDG_COMMAND = "make -C npc/rv64 check-fdg-arch-trap"
FDG_FOCUSED_RE = re.compile(
    r"^\[FDG-G1-FOCUSED\] illegal_fp_cases=4 illegal_classified=4 "
    r"arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 "
    r"legal_backend_present=1 PASS$",
    re.MULTILINE,
)
FDG_PROGRAM_RE = re.compile(
    r"^\[FDG-G1-PROGRAM\] arch_trap_capture=1 "
    r"capture_pc_match=1 capture_tval_match=1 "
    r"ordinary_backend_present=0 core_backend_present=0 "
    r"commit_oracle_hits=1 illegal_fp_commit=0 handler=1 mret=1 cause=2 "
    r"csr_mepc_match=1 csr_mtval_match=1 PASS$",
    re.MULTILINE,
)
FDG_MUTATION_SPECS = {
    "ordinary_arch_trap_exclusion_removed": {
        "source": "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
        "make_variable": "RTL_OOO_FRONTEND_DISPATCH_GATE",
        "test_name": "tb_ooo_fp_legality_dispatch_path",
        "old": (
            "      !dispatch0_arch_trap_i &&\n"
            "      // 【B-FP 簇】FP 迁域 A"),
        "new": "      // 【B-FP 簇】FP 迁域 A",
        "marker": "blocked before backend got=1 expected=0",
    },
    "lane1_arch_trap_exclusion_removed": {
        "source": "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
        "make_variable": "RTL_OOO_FRONTEND_DISPATCH_GATE",
        "test_name": "tb_ooo_frontend_dispatch_gate",
        "old": (
            "      !dispatch0_exit_i &&\n"
            "      !dispatch0_arch_trap_i &&\n"
            "      !dispatch0_system_i &&\n"
            "      // pred-NT branch"),
        "new": (
            "      !dispatch0_exit_i &&\n"
            "      !dispatch0_system_i &&\n"
            "      // pred-NT branch"),
        "marker": "head0 arch trap blocks dual dispatch got=1 expected=0",
    },
    "ordinary_admission_forced_closed": {
        "source": "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
        "make_variable": "RTL_OOO_FRONTEND_DISPATCH_GATE",
        "test_name": "tb_ooo_fp_legality_dispatch_path",
        "old": (
            "      !dispatch1_control_unsupported_o && "
            "!dispatch1_mem_unsupported_o;"),
        "new": (
            "      !dispatch1_control_unsupported_o && "
            "!dispatch1_mem_unsupported_o && 1'b0;"),
        "marker": "legal FADD.S reaches backend got=0 expected=1",
    },
    "final_backend_arch_trap_leak": {
        "source": "npc/rv64/vsrc/frontend/OooFrontend.v",
        "make_variable": "RTL_OOO_FRONTEND",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "    .frontend_dispatch_to_backend_valid_i(\n"
            "        frontend_dispatch_to_backend_valid_w),"),
        "new": (
            "    .frontend_dispatch_to_backend_valid_i(\n"
            "        frontend_dispatch_to_backend_valid_w || "
            "dispatch0_arch_trap_w),"),
        "marker": "[INT-DISPATCH-PACKET-PACKED] lane1 valid without lane0",
    },
    "trap_ex_pc_corrupted": {
        "source": "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        "make_variable": "RTL_OOO_CSR_TRAP_REQUEST_MUX",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_pc_i : "
            "pending_system_pc_i;"),
        "new": (
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? "
            "(pending_trap_pc_i + 64'd4) : pending_system_pc_i;"),
        "marker": "FDG illegal FP mepc got=",
    },
    "trap_ex_tval_forced_zero": {
        "source": "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        "make_variable": "RTL_OOO_CSR_TRAP_REQUEST_MUX",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_tval_i : "
            "{`XLEN{1'b0}};"),
        "new": (
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? {`XLEN{1'b0}} : "
            "{`XLEN{1'b0}};"),
        "marker": "FDG illegal FP mtval got=",
    },
}
FDG_ORACLE_PROBE_SPECS = {
    "commit_observer_known_transaction": {
        "test_name": "tb_ooo_priv_system",
        "ivflags": "-DFDG_COMMIT_ORACLE_SENSITIVITY",
        "marker": "FDG illegal FP commit count got=",
    },
}
FDG_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/testbench/tests/tb_ooo_fp_legality_dispatch_path.sv",
    "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/contract.md",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v9d-fdg-arch-trap/run-fdg-mutations.py",
    "npc/rv64/eval/ppa/tools/fdg_arch_trap_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_fdg_arch_trap_evidence.py",
}


def fdg_required_module_tests(path: pathlib.Path) -> list[str]:
    tests: list[str] = []
    collecting = False
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not collecting:
            if not stripped.startswith("TESTS :="):
                continue
            collecting = True
            stripped = stripped.removeprefix("TESTS :=").strip()
        continued = stripped.endswith("\\")
        payload = stripped[:-1].strip() if continued else stripped
        if payload:
            tests.extend(payload.split())
        if not continued:
            break
    if not tests or len(tests) != len(set(tests)):
        raise ValueError("module TESTS inventory is empty or duplicated")
    return tests


def validate_fdg_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate current-design FDG-G1 source-to-sink evidence."""

    errors: list[str] = []
    if entry.get("canonical_command") != FDG_COMMAND:
        errors.append("FDG-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"fdg_arch_trap_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append("FDG-G1 requires exact fdg_arch_trap_result/raw_log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["fdg_arch_trap_result"].get("path"))
    log_path, log_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or "FDG-G1 result is missing")
        return errors
    if log_error or log_path is None:
        errors.append(log_error or "FDG-G1 raw log is missing")
        return errors

    result = load_json(result_path)
    expected_metrics = {
        "focused": {
            "illegal_fp_cases": 4,
            "illegal_classified": 4,
            "arch_trap": 4,
            "fp_disabled": 4,
            "backend_blocked": 4,
            "legal_fp_cases": 1,
            "legal_backend_present": 1,
        },
        "program": {
            "arch_trap_capture": 1,
            "capture_pc_match": 1,
            "capture_tval_match": 1,
            "ordinary_backend_present": 0,
            "core_backend_present": 0,
            "commit_oracle_hits": 1,
            "illegal_fp_commit": 0,
            "handler": 1,
            "mret": 1,
            "cause": 2,
            "csr_mepc_match": 1,
            "csr_mtval_match": 1,
        },
    }
    expected_invariants = {
        "illegal_fp_never_reaches_ordinary_admission": True,
        "illegal_fp_never_reaches_final_backend_dispatch": True,
        "illegal_fp_never_commits": True,
        "commit_observer_is_nonvacuous": True,
        "precise_trap_pc_tval_are_exact": True,
        "precise_trap_capture_and_return": True,
        "legal_fp_reaches_backend": True,
        "classification_source_is_not_redecoded_in_dispatch_gate": True,
    }
    focused_tests = result.get("focused_tests")
    focused_ok = (
        isinstance(focused_tests, dict)
        and set(focused_tests) == {"legality_dispatch", "privileged_program"}
        and all(
            isinstance(record, dict) and record.get("status") == "PASS"
            and isinstance(record.get("log_sha256"), str)
            for record in focused_tests.values()
        )
    )
    if not (
        result.get("schema") == FDG_RESULT_SCHEMA
        and result.get("suite_run_id") == FDG_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == FDG_COMMAND
        and result.get("metrics") == expected_metrics
        and result.get("invariants") == expected_invariants
        and focused_ok
        and result.get("claim") == {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append("FDG-G1 result metrics, invariants or claim are incomplete")

    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings") if isinstance(provenance, dict) else None)
    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "fdg_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"FDG-G1 cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    binding_ok = (
        isinstance(provenance, dict)
        and provenance.get("rtl_sha256") == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == FDG_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append("FDG-G1 source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_artifact_kinds = {
        "focused_legality_dispatch_log", "program_log",
        "module_aggregate_summary", "rtl_mutation_summary",
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifacts_ok = (
        len(artifact_list) == len(expected_artifact_kinds)
        and set(artifacts_by_kind) == expected_artifact_kinds
    )
    if artifacts_ok:
        for kind, item in artifacts_by_kind.items():
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifacts_ok = False
                break
            artifact_paths[kind] = path
    if not artifacts_ok:
        errors.append("FDG-G1 artifact inventory or hashes are incomplete")
        return errors

    focused_text = artifact_paths["focused_legality_dispatch_log"].read_text(
        encoding="utf-8")
    program_text = artifact_paths["program_log"].read_text(encoding="utf-8")
    focused_log_ok = (
        len(FDG_FOCUSED_RE.findall(focused_text)) == 1
        and focused_text.count("[PASS] tb_ooo_fp_legality_dispatch_path") == 1
        and focused_text.count("[RESULT] PASS") == 1
        and "[CHECK-FAIL]" not in focused_text
        and "[RESULT] FAIL" not in focused_text
    )
    program_log_ok = (
        len(FDG_PROGRAM_RE.findall(program_text)) == 1
        and program_text.count("[PASS] tb_ooo_priv_system") == 1
        and program_text.count("[RESULT] PASS") == 1
        and "[CHECK-FAIL]" not in program_text
        and "[RESULT] FAIL" not in program_text
    )
    if not focused_log_ok:
        errors.append("FDG-G1 focused legality/admission matrix is incomplete")
    if not program_log_ok:
        errors.append("FDG-G1 full-core trap program is incomplete")
    if focused_ok:
        focused_log_ok = focused_log_ok and (
            focused_tests["legality_dispatch"].get("log_sha256")
            == sha256_file(artifact_paths["focused_legality_dispatch_log"])
            and focused_tests["privileged_program"].get("log_sha256")
            == sha256_file(artifact_paths["program_log"])
        )
        if not focused_log_ok:
            errors.append("FDG-G1 focused test log binding is stale")

    try:
        module_tests = fdg_required_module_tests(
            root / "npc/rv64/testbench/Makefile")
    except (OSError, ValueError) as exc:
        errors.append(f"FDG-G1 cannot parse module inventory: {exc}")
        module_tests = []
    module = result.get("module_aggregate")
    module_records = module.get("tests") if isinstance(module, dict) else None
    module_ok = (
        bool(module_tests)
        and isinstance(module, dict)
        and module.get("required") == len(module_tests)
        and module.get("passed") == len(module_tests)
        and module.get("failed") == 0
        and isinstance(module_records, dict)
        and set(module_records) == set(module_tests)
    )
    if module_ok:
        for test_name, record in module_records.items():
            path, error = safe_regular_file(root, record.get("path"))
            if (
                error or path is None
                or record.get("sha256") != sha256_file(path)
                or path.name != f"{test_name}.log"
            ):
                module_ok = False
                break
    if not module_ok:
        errors.append("FDG-G1 module aggregate is incomplete or stale")

    mutation = load_json(artifact_paths["rtl_mutation_summary"])
    rows = mutation.get("results")
    mutation_by_name = {
        row.get("name"): row
        for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(rows, list) else {}
    oracle_rows = mutation.get("oracle_probes")
    oracle_by_name = {
        row.get("name"): row
        for row in oracle_rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(oracle_rows, list) else {}
    mutation_ok = (
        mutation.get("schema") == FDG_MUTATION_SCHEMA
        and mutation.get("suite_run_id") == FDG_RUN_ID
        and mutation.get("required") == len(FDG_MUTATION_SPECS)
        and mutation.get("compile_success") == len(FDG_MUTATION_SPECS)
        and mutation.get("dynamic_rejected") == len(FDG_MUTATION_SPECS)
        and mutation.get("source_unchanged") is True
        and mutation.get("source_sha256_before")
            == mutation.get("source_sha256_after")
        and set(mutation_by_name) == set(FDG_MUTATION_SPECS)
        and mutation.get("oracle_probes_required")
            == len(FDG_ORACLE_PROBE_SPECS)
        and mutation.get("oracle_probes_compile_success")
            == len(FDG_ORACLE_PROBE_SPECS)
        and mutation.get("oracle_probes_dynamic_rejected")
            == len(FDG_ORACLE_PROBE_SPECS)
        and set(oracle_by_name) == set(FDG_ORACLE_PROBE_SPECS)
    )
    if mutation_ok:
        for name, spec in FDG_MUTATION_SPECS.items():
            source_path, source_error = safe_regular_file(root, spec["source"])
            row = mutation_by_name[name]
            log = row.get("log")
            if source_error or source_path is None or not isinstance(log, dict):
                mutation_ok = False
                break
            source_text = source_path.read_text(encoding="utf-8")
            if source_text.count(spec["old"]) != 1:
                mutation_ok = False
                break
            mutated = source_text.replace(spec["old"], spec["new"], 1)
            live_sha = hashlib.sha256(source_text.encode("utf-8")).hexdigest()
            mutant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
            variant_log, variant_error = safe_regular_file(root, log.get("path"))
            if variant_error or variant_log is None:
                mutation_ok = False
                break
            variant_text = variant_log.read_text(encoding="utf-8")
            if not (
                row.get("source") == spec["source"]
                and row.get("make_variable") == spec["make_variable"]
                and row.get("test_name") == spec["test_name"]
                and row.get("original_sha256") == live_sha
                and row.get("mutant_sha256") == mutant_sha
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(variant_log)
                and spec["marker"] in variant_text
                and "[RESULT] FAIL status=" in variant_text
                and "[RESULT] PASS" not in variant_text
            ):
                mutation_ok = False
                break
    if mutation_ok:
        for name, spec in FDG_ORACLE_PROBE_SPECS.items():
            row = oracle_by_name[name]
            log = row.get("log")
            if not isinstance(log, dict):
                mutation_ok = False
                break
            probe_log, probe_error = safe_regular_file(root, log.get("path"))
            if probe_error or probe_log is None:
                mutation_ok = False
                break
            probe_text = probe_log.read_text(encoding="utf-8")
            if not (
                row.get("test_name") == spec["test_name"]
                and row.get("ivflags") == spec["ivflags"]
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(probe_log)
                and spec["marker"] in probe_text
                and "[RESULT] FAIL status=" in probe_text
                and "[RESULT] PASS" not in probe_text
            ):
                mutation_ok = False
                break
    if not mutation_ok:
        errors.append(
            "FDG-G1 compile-success RTL source variants or commit oracle probe "
            "are incomplete")

    raw_text = log_path.read_text(encoding="utf-8")
    expected_module_count = len(module_tests)
    required_raw_markers = (
        f"schema={FDG_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={FDG_COMMAND}",
        "focused_illegal_fp_cases=4",
        "focused_backend_blocked=4",
        "focused_legal_backend_present=1",
        "program_arch_trap_capture=1",
        "program_capture_pc_match=1",
        "program_capture_tval_match=1",
        "program_ordinary_backend_present=0",
        "program_core_backend_present=0",
        "program_commit_oracle_hits=1",
        "program_illegal_fp_commit=0",
        "program_csr_mepc_match=1",
        "program_csr_mtval_match=1",
        f"compile_success_rtl_variants={len(FDG_MUTATION_SPECS)}",
        f"dynamic_rejected_rtl_variants={len(FDG_MUTATION_SPECS)}",
        f"compile_success_oracle_probes={len(FDG_ORACLE_PROBE_SPECS)}",
        f"dynamic_rejected_oracle_probes={len(FDG_ORACLE_PROBE_SPECS)}",
        "focused_tests=2/2",
        f"module_aggregate={expected_module_count}/{expected_module_count}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[FDG-G1-GATE] PASS",
    )
    missing = [marker for marker in required_raw_markers if raw_text.count(marker) != 1]
    if missing:
        errors.append(f"FDG-G1 raw log missing exact markers={missing}")
    return errors


XRET_RESULT_SCHEMA = "npc-rv64-xret-current-mode-evidence-v1"
XRET_MUTATION_SCHEMA = "npc-rv64-xret-rtl-mutations-v1"
XRET_RUN_ID = "2026-07-21-rv64-v9e-xret-current-design"
XRET_COMMAND = "make -C npc/rv64 check-xret-current-mode"
XRET_FOCUSED_RE = re.compile(
    r"^\[XRET-G1-FOCUSED\] cases=7 legal=3 illegal=4 "
    r"raw_preserved=7 legal_system=3 illegal_arch_trap=4 PASS$",
    re.MULTILINE,
)
XRET_PROGRAM_RES = (
    re.compile(
        r"^\[XRET-G1-PROGRAM-LEGAL-MRET\] csr_request=1 commit=1 "
        r"return=1 backend_drained=1 PASS$", re.MULTILINE),
    re.compile(
        r"^\[XRET-G1-PROGRAM-LEGAL-SRET\] csr_request=1 commit=1 "
        r"return=1 backend_drained=1 PASS$", re.MULTILINE),
    re.compile(
        r"^\[XRET-G1-PROGRAM-ILLEGAL-MRET\] arch_trap_capture=1 "
        r"capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 "
        r"csr_request=0 commit_oracle_hits=1 commit=0 handler=1 cause=2 "
        r"csr_mepc_match=1 csr_mtval_match=1 return=1 "
        r"backend_drained=1 PASS$", re.MULTILINE),
    re.compile(
        r"^\[XRET-G1-PROGRAM-ILLEGAL-SRET\] arch_trap_capture=1 "
        r"capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 "
        r"csr_request=0 commit_oracle_hits=1 commit=0 handler=1 cause=2 "
        r"csr_mepc_match=1 csr_mtval_match=1 older_lane0=1 return=1 "
        r"backend_drained=1 PASS$", re.MULTILINE),
)
XRET_MUTATION_SPECS = {
    "mret_mode_legality_removed": {
        "source": "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        "make_variable": "RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        "test_name": "tb_ooo_fetch_head_classify_gate",
        "old": (
            "  wire mret_mode_illegal_w =\n"
            "      mret_raw_o && (priv_mode_i != `PRIV_M);"),
        "new": "  wire mret_mode_illegal_w = 1'b0;",
        "marker": "mret in S-mode illegal got=0 expected=1",
    },
    "sret_u_mode_legality_removed": {
        "source": "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        "make_variable": "RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        "test_name": "tb_ooo_fetch_head_classify_gate",
        "old": (
            "  wire sret_mode_illegal_w =\n"
            "      sret_raw_o && (priv_mode_i == `PRIV_U);"),
        "new": "  wire sret_mode_illegal_w = 1'b0;",
        "marker": "sret in U-mode illegal got=0 expected=1",
    },
    "sret_tsr_legality_removed": {
        "source": "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        "make_variable": "RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        "test_name": "tb_ooo_fetch_head_classify_gate",
        "old": (
            "  wire sret_tsr_illegal_w =\n"
            "      sret_raw_o && (priv_mode_i == `PRIV_S) &&\n"
            "      ((mstatus_i & `MSTATUS_TSR) != {`XLEN{1'b0}});"),
        "new": "  wire sret_tsr_illegal_w = 1'b0;",
        "marker": "sret under tsr illegal got=0 expected=1",
    },
    "legal_mret_overgated": {
        "source": "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
        "make_variable": "RTL_OOO_FETCH_HEAD_CLASSIFY_GATE",
        "test_name": "tb_ooo_fetch_head_classify_gate",
        "old": (
            "  wire mret_mode_illegal_w =\n"
            "      mret_raw_o && (priv_mode_i != `PRIV_M);"),
        "new": "  wire mret_mode_illegal_w = mret_raw_o;",
        "marker": "mret in M-mode legal got=1 expected=0",
    },
    "head0_arch_trap_system_exclusion_removed": {
        "source": "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
        "make_variable": "RTL_OOO_PENDING_DISPATCH_ARBITER",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign pending_system_capture_head0_o =\n"
            "      capture_base_w &&\n"
            "      !csr_irq_pending_i &&\n"
            "      !head_fetch_fault0_i &&\n"
            "      !dispatch0_arch_trap_w &&\n"
            "      !dispatch0_exit_w &&\n"
            "      dispatch0_system_w && !dispatch0_csr_w && "
            "!head0_csr_illegal_i;"),
        "new": (
            "  assign pending_system_capture_head0_o =\n"
            "      capture_base_w &&\n"
            "      !csr_irq_pending_i &&\n"
            "      !head_fetch_fault0_i &&\n"
            "      !dispatch0_exit_w &&\n"
            "      dispatch0_system_w && !dispatch0_csr_w && "
            "!head0_csr_illegal_i;"),
        "marker": "[FLUSH-CONTRACT INV-7]",
    },
    "lane1_arch_trap_system_exclusion_removed": {
        "source": "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
        "make_variable": "RTL_OOO_PENDING_LANE1_CAPTURE_GATE",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign system_capture_o =\n"
            "      barrier_base_i && system_raw_w && !csr_illegal_i &&\n"
            "      !arch_trap_raw_w;"),
        "new": (
            "  assign system_capture_o =\n"
            "      barrier_base_i && system_raw_w && !csr_illegal_i;"),
        "marker": (
            "[V10A-SERIAL-OWNER-ONEHOT] arch and system holders overlap"),
    },
    "precise_trap_pc_offset": {
        "source": "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        "make_variable": "RTL_OOO_CSR_TRAP_REQUEST_MUX",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_pc_i : "
            "pending_system_pc_i;"),
        "new": (
            "  assign trap_ex_pc_o =\n"
            "      pending_arch_trap_fire_o ? "
            "(pending_trap_pc_i + 64'd4) : pending_system_pc_i;"),
        "marker": "s-mode mret mepc got=",
    },
    "precise_trap_tval_forced_zero": {
        "source": "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
        "make_variable": "RTL_OOO_CSR_TRAP_REQUEST_MUX",
        "test_name": "tb_ooo_priv_system",
        "old": (
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? pending_trap_tval_i : "
            "{`XLEN{1'b0}};"),
        "new": (
            "  assign trap_ex_tval_o =\n"
            "      pending_arch_trap_fire_o ? {`XLEN{1'b0}} : "
            "{`XLEN{1'b0}};"),
        "marker": "s-mode mret mtval got=",
    },
}
XRET_ORACLE_PROBE_SPECS = {
    "csr_request_observer_known_transaction": {
        "test_name": "tb_ooo_priv_system",
        "ivflags": "-DXRET_CSR_REQUEST_ORACLE_SENSITIVITY",
        "marker": (
            "s-mode illegal mret CSR request count got=0x00000001 "
            "expected=0x00000000"),
    },
    "commit_observer_known_transaction": {
        "test_name": "tb_ooo_priv_system",
        "ivflags": "-DXRET_COMMIT_ORACLE_SENSITIVITY",
        "marker": (
            "s-mode illegal mret commit count got=0x00000001 "
            "expected=0x00000000"),
    },
}
XRET_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/common/OooSlotFacts.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/core/CsrFile.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_head_classify_gate.sv",
    "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{XRET_RUN_ID}/contract.md",
    f".github/task-runs/{XRET_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{XRET_RUN_ID}/run-focused.sh",
    f".github/task-runs/{XRET_RUN_ID}/run-xret-mutations.py",
    "npc/rv64/eval/ppa/tools/xret_current_mode_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_xret_current_mode_evidence.py",
}


def validate_xret_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate current-design XRET-G1 architectural evidence."""

    errors: list[str] = []
    if entry.get("canonical_command") != XRET_COMMAND:
        errors.append("XRET-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"xret_current_mode_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(
            "XRET-G1 requires exact xret_current_mode_result/raw_log evidence")
        return errors
    result_path, result_error = safe_regular_file(
        root, by_kind["xret_current_mode_result"].get("path"))
    log_path, log_error = safe_regular_file(
        root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or "XRET-G1 result is missing")
        return errors
    if log_error or log_path is None:
        errors.append(log_error or "XRET-G1 raw log is missing")
        return errors
    if (
        by_kind["xret_current_mode_result"].get("sha256")
        != sha256_file(result_path)
        or by_kind["raw_log"].get("sha256") != sha256_file(log_path)
    ):
        errors.append("XRET-G1 ledger evidence hashes are stale")

    result = load_json(result_path)
    legal = {
        "csr_request": 1, "commit": 1, "return": 1, "backend_drained": 1,
    }
    illegal = {
        "arch_trap_capture": 1,
        "capture_pc_match": 1,
        "capture_tval_match": 1,
        "request_oracle_hits": 1,
        "csr_request": 0,
        "commit_oracle_hits": 1,
        "commit": 0,
        "handler": 1,
        "cause": 2,
        "csr_mepc_match": 1,
        "csr_mtval_match": 1,
        "return": 1,
        "backend_drained": 1,
    }
    illegal_sret = dict(illegal)
    illegal_sret["older_lane0"] = 1
    expected_metrics = {
        "focused": {
            "cases": 7, "legal": 3, "illegal": 4, "raw_preserved": 7,
            "legal_system": 3, "illegal_arch_trap": 4,
        },
        "program": {
            "legal_mret": legal,
            "legal_sret": legal,
            "illegal_mret": illegal,
            "illegal_sret": illegal_sret,
        },
    }
    expected_invariants = {
        "mret_only_legal_in_m_mode": True,
        "sret_illegal_in_u_mode": True,
        "sret_tsr_only_blocks_s_mode": True,
        "illegal_xret_selects_precise_trap_owner": True,
        "illegal_xret_never_requests_csr_return": True,
        "illegal_xret_never_commits": True,
        "zero_oracles_are_nonvacuous": True,
        "precise_trap_pc_tval_are_exact": True,
        "lane1_older_instruction_retires": True,
        "legal_mret_sret_request_commit_return": True,
        "legality_source_not_redecoded_in_csr_file": True,
    }
    focused_tests = result.get("focused_tests")
    focused_ok = (
        isinstance(focused_tests, dict)
        and set(focused_tests) == {"current_mode_matrix", "privileged_programs"}
        and all(
            isinstance(record, dict) and record.get("status") == "PASS"
            and isinstance(record.get("log_sha256"), str)
            for record in focused_tests.values())
    )
    if not (
        result.get("schema") == XRET_RESULT_SCHEMA
        and result.get("suite_run_id") == XRET_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == XRET_COMMAND
        and result.get("metrics") == expected_metrics
        and result.get("invariants") == expected_invariants
        and focused_ok
        and result.get("claim") == {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append("XRET-G1 result metrics, invariants or claim are incomplete")

    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings") if isinstance(provenance, dict)
        else None)
    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "xret_architecture_binding")
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"XRET-G1 cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    binding_ok = (
        isinstance(provenance, dict)
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == XRET_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append("XRET-G1 source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    by_artifact = {
        item.get("kind"): item for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_artifacts = {
        "focused_current_mode_log", "program_log",
        "module_aggregate_summary", "rtl_mutation_summary",
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifacts_ok = (
        len(artifact_list) == len(expected_artifacts)
        and set(by_artifact) == expected_artifacts)
    if artifacts_ok:
        for kind, item in by_artifact.items():
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifacts_ok = False
                break
            artifact_paths[kind] = path
    if not artifacts_ok:
        errors.append("XRET-G1 artifact inventory or hashes are incomplete")
        return errors

    focused_text = artifact_paths["focused_current_mode_log"].read_text(
        encoding="utf-8")
    program_text = artifact_paths["program_log"].read_text(encoding="utf-8")
    focused_log_ok = (
        len(XRET_FOCUSED_RE.findall(focused_text)) == 1
        and focused_text.count("[PASS] tb_ooo_fetch_head_classify_gate") == 1
        and focused_text.count("[RESULT] PASS") == 1
        and "[CHECK-FAIL]" not in focused_text
        and "[RESULT] FAIL" not in focused_text)
    program_log_ok = (
        all(len(regex.findall(program_text)) == 1 for regex in XRET_PROGRAM_RES)
        and program_text.count("[PASS] tb_ooo_priv_system") == 1
        and program_text.count("[RESULT] PASS") == 1
        and "[CHECK-FAIL]" not in program_text
        and "[RESULT] FAIL" not in program_text)
    if not focused_log_ok:
        errors.append("XRET-G1 focused current-mode matrix is incomplete")
    if not program_log_ok:
        errors.append("XRET-G1 full-core program matrix is incomplete")
    if focused_ok and not (
        focused_tests["current_mode_matrix"].get("log_sha256")
            == sha256_file(artifact_paths["focused_current_mode_log"])
        and focused_tests["privileged_programs"].get("log_sha256")
            == sha256_file(artifact_paths["program_log"])
    ):
        errors.append("XRET-G1 focused test log binding is stale")

    try:
        module_tests = fdg_required_module_tests(
            root / "npc/rv64/testbench/Makefile")
    except (OSError, ValueError) as exc:
        errors.append(f"XRET-G1 cannot parse module inventory: {exc}")
        module_tests = []
    module = result.get("module_aggregate")
    records = module.get("tests") if isinstance(module, dict) else None
    module_ok = (
        bool(module_tests) and isinstance(module, dict)
        and module.get("required") == len(module_tests)
        and module.get("passed") == len(module_tests)
        and module.get("failed") == 0
        and isinstance(records, dict) and set(records) == set(module_tests))
    if module_ok:
        for test_name, record in records.items():
            path, error = safe_regular_file(root, record.get("path"))
            if (
                error or path is None
                or record.get("sha256") != sha256_file(path)
                or path.name != f"{test_name}.log"
            ):
                module_ok = False
                break
    if not module_ok:
        errors.append("XRET-G1 module aggregate is incomplete or stale")

    mutation = load_json(artifact_paths["rtl_mutation_summary"])
    rows = mutation.get("results")
    mutation_by_name = {
        row.get("name"): row for row in rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(rows, list) else {}
    oracle_rows = mutation.get("oracle_probes")
    oracle_by_name = {
        row.get("name"): row for row in oracle_rows
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(oracle_rows, list) else {}
    mutation_ok = (
        mutation.get("schema") == XRET_MUTATION_SCHEMA
        and mutation.get("suite_run_id") == XRET_RUN_ID
        and mutation.get("required") == len(XRET_MUTATION_SPECS)
        and mutation.get("compile_success") == len(XRET_MUTATION_SPECS)
        and mutation.get("dynamic_rejected") == len(XRET_MUTATION_SPECS)
        and mutation.get("source_unchanged") is True
        and mutation.get("source_sha256_before")
            == mutation.get("source_sha256_after")
        and set(mutation_by_name) == set(XRET_MUTATION_SPECS)
        and mutation.get("oracle_probes_required")
            == len(XRET_ORACLE_PROBE_SPECS)
        and mutation.get("oracle_probes_compile_success")
            == len(XRET_ORACLE_PROBE_SPECS)
        and mutation.get("oracle_probes_dynamic_rejected")
            == len(XRET_ORACLE_PROBE_SPECS)
        and set(oracle_by_name) == set(XRET_ORACLE_PROBE_SPECS))
    if mutation_ok:
        for name, spec in XRET_MUTATION_SPECS.items():
            source, source_error = safe_regular_file(root, spec["source"])
            row = mutation_by_name[name]
            log = row.get("log")
            if source_error or source is None or not isinstance(log, dict):
                mutation_ok = False
                break
            source_text = source.read_text(encoding="utf-8")
            if source_text.count(spec["old"]) != 1:
                mutation_ok = False
                break
            mutated = source_text.replace(spec["old"], spec["new"], 1)
            live_sha = hashlib.sha256(source_text.encode("utf-8")).hexdigest()
            mutant_sha = hashlib.sha256(mutated.encode("utf-8")).hexdigest()
            variant_log, variant_error = safe_regular_file(root, log.get("path"))
            if variant_error or variant_log is None:
                mutation_ok = False
                break
            text = variant_log.read_text(encoding="utf-8")
            if not (
                row.get("source") == spec["source"]
                and row.get("make_variable") == spec["make_variable"]
                and row.get("test_name") == spec["test_name"]
                and row.get("original_sha256") == live_sha
                and row.get("mutant_sha256") == mutant_sha
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(variant_log)
                and spec["marker"] in text
                and "[RESULT] FAIL status=" in text
                and "[RESULT] PASS" not in text
            ):
                mutation_ok = False
                break
    if mutation_ok:
        for name, spec in XRET_ORACLE_PROBE_SPECS.items():
            row = oracle_by_name[name]
            log = row.get("log")
            if not isinstance(log, dict):
                mutation_ok = False
                break
            probe_log, probe_error = safe_regular_file(root, log.get("path"))
            if probe_error or probe_log is None:
                mutation_ok = False
                break
            text = probe_log.read_text(encoding="utf-8")
            if not (
                row.get("test_name") == spec["test_name"]
                and row.get("ivflags") == spec["ivflags"]
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(probe_log)
                and spec["marker"] in text
                and "[RESULT] FAIL status=" in text
                and "[RESULT] PASS" not in text
            ):
                mutation_ok = False
                break
    if not mutation_ok:
        errors.append(
            "XRET-G1 compile-success RTL verification variants or oracle "
            "probes are incomplete")

    raw_text = log_path.read_text(encoding="utf-8")
    count = len(module_tests)
    required_raw_markers = (
        f"schema={XRET_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={XRET_COMMAND}",
        "focused_cases=7", "focused_legal=3", "focused_illegal=4",
        "focused_raw_preserved=7", "focused_legal_system=3",
        "focused_illegal_arch_trap=4",
        "legal_mret_csr_request=1", "legal_mret_commit=1",
        "legal_sret_csr_request=1", "legal_sret_commit=1",
        "illegal_mret_arch_trap_capture=1", "illegal_mret_csr_request=0",
        "illegal_mret_commit=0", "illegal_sret_arch_trap_capture=1",
        "illegal_sret_csr_request=0", "illegal_sret_commit=0",
        f"compile_success_rtl_variants={len(XRET_MUTATION_SPECS)}",
        f"dynamic_rejected_rtl_variants={len(XRET_MUTATION_SPECS)}",
        f"compile_success_oracle_probes={len(XRET_ORACLE_PROBE_SPECS)}",
        f"dynamic_rejected_oracle_probes={len(XRET_ORACLE_PROBE_SPECS)}",
        "focused_tests=2/2", f"module_aggregate={count}/{count}",
        "ppa=UNQUALIFIED", "promotion_eligible=false",
        "[XRET-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing:
        errors.append(f"XRET-G1 raw log missing exact markers={missing}")
    return errors


INSTRET_RESULT_SCHEMA = "npc-rv64-instret-retirement-evidence-v1"
INSTRET_MUTATION_SCHEMA = "npc-rv64-instret-rtl-mutations-v1"
INSTRET_COMMAND = "make -C npc/rv64 check-instret-retirement"
INSTRET_PROGRAM_RE = re.compile(
    r"^\[INSTRET-G1-PROGRAM\] exception_lanes=2 exception_zero_delta=2 "
    r"mret=1 sret=6 sfence_vma=1 control_exact=8 control_total=8 "
    r"csr_delta_checks=(\d+) PASS$",
    re.MULTILINE,
)
INSTRET_MUTATION_SPECS = {
    "exception_filter_removed": {
        "source": "npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
        "make_variable": "RTL_OOO_COMMIT_OUTPUT_MUX",
        "old": (
            "wire commit0_isa_retire_w = "
            "commit0_valid_o && !commit0_exception_o;"),
        "new": "wire commit0_isa_retire_w = commit0_valid_o;",
        "marker": "[INSTRET-G1-FINAL-EQ]",
    },
    "final_control_source_removed": {
        "source": "npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
        "make_variable": "RTL_OOO_COMMIT_OUTPUT_MUX",
        "old": (
            "wire commit0_isa_retire_w = "
            "commit0_valid_o && !commit0_exception_o;"),
        "new": (
            "wire commit0_isa_retire_w = "
            "core_commit0_valid_i && !core_commit0_exception_i;"),
        "marker": "[INSTRET-G1-FINAL-EQ]",
    },
    "csr_uses_core_count": {
        "source": "npc/rv64/vsrc/core/NpcCoreTop.v",
        "make_variable": "RTL_NPC_CORE_TOP",
        "old": ".instret_inc_i(retire_count_o),",
        "new": ".instret_inc_i(ooo_core_retire_count_w),",
        "marker": "[CHECK-FAIL] INSTRET CsrFile edge delta",
    },
}
INSTRET_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/writeback/OooCommitOutputMux.v",
    "npc/rv64/vsrc/writeback/OooWriteback.v",
    "npc/rv64/vsrc/core/NpcCoreTop.v",
    "npc/rv64/vsrc/core/CsrFile.v",
    "npc/rv64/testbench/tests/tb_ooo_sv39_boot.sv",
    "npc/rv64/testbench/tests/tb_ooo_commit_output_mux.sv",
    "npc/rv64/testbench/tests/tb_ooo_alu_core_slice.sv",
    "npc/rv64/testbench/tests/tb_csr_file.sv",
    "npc/rv64/Makefile",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py",
    ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/contract.md",
    ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/rtl-derivation.md",
    ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-focused.sh",
    ".github/task-runs/2026-07-21-rv64-v9c-instret-retirement/run-instret-mutations.py",
    "npc/rv64/eval/ppa/tools/instret_retirement_evidence.py",
}


def validate_instret_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate current-design INSTRET-G1 program evidence."""

    errors: list[str] = []
    if entry.get("canonical_command") != INSTRET_COMMAND:
        errors.append("INSTRET-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"instret_retirement_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(
            "INSTRET-G1 requires exact instret_retirement_result/raw_log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["instret_retirement_result"].get("path"))
    log_path, log_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or "INSTRET-G1 result is missing")
        return errors
    if log_error or log_path is None:
        errors.append(log_error or "INSTRET-G1 raw log is missing")
        return errors

    result = load_json(result_path)
    metrics = result.get("metrics")
    invariants = result.get("invariants")
    focused = result.get("focused_tests")
    module_aggregate = result.get("module_aggregate")
    mutation_audit = result.get("mutation_audit")
    provenance = result.get("provenance")
    claim = result.get("claim")
    expected_metrics = {
        "exception_lanes": 2,
        "exception_zero_delta": 2,
        "mret": 1,
        "sret": 6,
        "sfence_vma": 1,
        "control_exact": 8,
        "control_total": 8,
    }
    expected_invariants = {
        "exception_lane_delta_zero": True,
        "control_pseudo_commit_delta_one": True,
        "control_lane1_suppressed": True,
        "csr_uses_final_retire_count": True,
        "final_count_range_zero_to_two": True,
    }
    if not (
        result.get("schema") == INSTRET_RESULT_SCHEMA
        and result.get("suite_run_id")
            == "2026-07-21-rv64-v9c-instret-retirement"
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == INSTRET_COMMAND
        and isinstance(metrics, dict)
        and set(metrics) == {*expected_metrics, "csr_delta_checks"}
        and all(metrics.get(name) == value for name, value in expected_metrics.items())
        and isinstance(metrics.get("csr_delta_checks"), int)
        and not isinstance(metrics.get("csr_delta_checks"), bool)
        and metrics["csr_delta_checks"] >= 1000
        and invariants == expected_invariants
        and claim == {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append("INSTRET-G1 result metrics, invariants or claim are incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "instret_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"INSTRET-G1 cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    source_bindings = provenance.get("source_bindings") if isinstance(provenance, dict) else None
    binding_ok = (
        isinstance(provenance, dict)
        and provenance.get("rtl_sha256") == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == INSTRET_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append("INSTRET-G1 source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    expected_artifact_kinds = {
        "program_log", "module_aggregate_summary", "rtl_mutation_summary",
        "focused_commit_output_mux_log", "focused_alu_core_slice_log",
        "focused_csr_file_log",
    }
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(expected_artifact_kinds)
        and set(artifacts_by_kind) == expected_artifact_kinds
    )
    if artifact_ok:
        for kind, item in artifacts_by_kind.items():
            if set(item) != {"kind", "path", "sha256"}:
                artifact_ok = False
                break
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append("INSTRET-G1 nested artifact inventory or hash is stale")
        return errors

    program_text = artifact_paths["program_log"].read_text(encoding="utf-8")
    program_matches = list(INSTRET_PROGRAM_RE.finditer(program_text))
    if not (
        len(program_matches) == 1
        and int(program_matches[0].group(1), 10) >= 1000
        and program_text.count("[PASS] tb_ooo_sv39_boot") == 1
        and program_text.count("[RESULT] PASS") == 1
        and "[CHECK-FAIL]" not in program_text
        and "[RESULT] FAIL" not in program_text
    ):
        errors.append("INSTRET-G1 program event marker is missing or malformed")

    focused_names = {
        "commit_output_mux": (
            "focused_commit_output_mux_log", "tb_ooo_commit_output_mux"),
        "alu_core_slice": (
            "focused_alu_core_slice_log", "tb_ooo_alu_core_slice"),
        "csr_file": ("focused_csr_file_log", "tb_csr_file"),
    }
    focused_ok = isinstance(focused, dict) and set(focused) == set(focused_names)
    if focused_ok:
        for name, (kind, test_name) in focused_names.items():
            text = artifact_paths[kind].read_text(encoding="utf-8")
            accepted = {f"PASS {test_name}", f"[PASS] {test_name}"}
            pass_lines = [line for line in text.splitlines() if line in accepted]
            compile_lines = [
                line for line in text.splitlines()
                if line.startswith("[COMPILE] ")]
            design_marker = f"[RTL-DESIGN-ID] {expected_design_id}"
            record = focused[name]
            if not (
                isinstance(record, dict)
                and set(record) == {"status", "log_sha256"}
                and record.get("status") == "PASS"
                and record.get("log_sha256") == sha256_file(artifact_paths[kind])
                and len(pass_lines) == 1
                and text.count("[RESULT] PASS") == 1
                and "[RESULT] FAIL" not in text
                and "[CHECK-FAIL]" not in text
            ):
                focused_ok = False
                break
    if not focused_ok:
        errors.append("INSTRET-G1 focused retirement tests are incomplete")

    module_ok = isinstance(module_aggregate, dict) and set(module_aggregate) == {
        "required", "passed", "failed", "tests",
    }
    try:
        makefile_path, makefile_error = safe_regular_file(
            root, "npc/rv64/testbench/Makefile")
        if makefile_error or makefile_path is None:
            raise ValueError(makefile_error or "module Makefile is missing")
        required_tests, inventory_errors = parse_required_tests(
            makefile_path.read_text(encoding="utf-8"))
        if inventory_errors:
            raise ValueError("; ".join(inventory_errors))
    except (OSError, ValueError) as exc:
        required_tests = []
        module_ok = False
        errors.append(f"INSTRET-G1 cannot derive module inventory: {exc}")
    module_records = (
        module_aggregate.get("tests") if isinstance(module_aggregate, dict) else None)
    module_ok = module_ok and (
        bool(required_tests)
        and module_aggregate.get("required") == len(required_tests)
        and module_aggregate.get("passed") == len(required_tests)
        and module_aggregate.get("failed") == 0
        and isinstance(module_records, dict)
        and set(module_records) == set(required_tests)
    )
    module_summary_path = artifact_paths["module_aggregate_summary"]
    module_summary_text = module_summary_path.read_text(encoding="utf-8")
    module_summary_lines = module_summary_text.splitlines()
    module_markers = (
        "# NPC single module testbench summary",
        f"- total: {len(required_tests)}",
        f"- passed: {len(required_tests)}",
        "- failed: 0",
    )
    module_ok = module_ok and all(
        module_summary_text.count(marker) == 1 for marker in module_markers)
    if module_ok:
        for test_name in required_tests:
            record = module_records[test_name]
            expected_path = (
                module_summary_path.parent / "logs" / f"{test_name}.log")
            expected_relative = expected_path.relative_to(root).as_posix()
            log_path_value, log_error_value = safe_regular_file(
                root, record.get("path") if isinstance(record, dict) else None)
            if log_error_value or log_path_value is None:
                module_ok = False
                break
            log_text = log_path_value.read_text(encoding="utf-8")
            accepted = {f"PASS {test_name}", f"[PASS] {test_name}"}
            pass_lines = [line for line in log_text.splitlines() if line in accepted]
            if not (
                isinstance(record, dict)
                and set(record) == {"path", "sha256"}
                and record.get("path") == expected_relative
                and record.get("sha256") == sha256_file(log_path_value)
                and module_summary_lines.count(f"- PASS {test_name}") == 1
                and len(pass_lines) == 1
                and log_text.count("[RESULT] PASS") == 1
                and "[RESULT] FAIL" not in log_text
            ):
                module_ok = False
                break
    if not module_ok:
        errors.append("INSTRET-G1 current module aggregate is incomplete")

    mutation_path = artifact_paths["rtl_mutation_summary"]
    mutation = load_json(mutation_path)
    rows = mutation.get("results")
    row_list = rows if isinstance(rows, list) else []
    rows_by_name = {
        row.get("name"): row
        for row in row_list
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    mutation_ok = (
        mutation.get("schema") == INSTRET_MUTATION_SCHEMA
        and mutation.get("suite_run_id")
            == "2026-07-21-rv64-v9c-instret-retirement"
        and mutation.get("required") == 3
        and mutation.get("compile_success") == 3
        and mutation.get("dynamic_rejected") == 3
        and mutation.get("source_unchanged") is True
        and mutation.get("source_sha256_before")
            == mutation.get("source_sha256_after")
        and len(row_list) == 3
        and set(rows_by_name) == set(INSTRET_MUTATION_SPECS)
    )
    reconstructed: dict[str, str] = {}
    if mutation_ok:
        for name, spec in INSTRET_MUTATION_SPECS.items():
            row = rows_by_name[name]
            source_path, source_error = safe_regular_file(root, spec["source"])
            log = row.get("log")
            if source_error or source_path is None or not isinstance(log, dict):
                mutation_ok = False
                break
            source_text = source_path.read_text(encoding="utf-8")
            if source_text.count(spec["old"]) != 1:
                mutation_ok = False
                break
            mutant_sha = sha256_bytes(
                source_text.replace(spec["old"], spec["new"], 1).encode("utf-8"))
            reconstructed[name] = mutant_sha
            log_path_value, log_error_value = safe_regular_file(root, log.get("path"))
            if log_error_value or log_path_value is None:
                mutation_ok = False
                break
            log_text = log_path_value.read_text(encoding="utf-8")
            if not (
                row.get("source") == spec["source"]
                and row.get("make_variable") == spec["make_variable"]
                and row.get("original_sha256") == sha256_file(source_path)
                and row.get("mutant_sha256") == mutant_sha
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(log_path_value)
                and spec["marker"] in log_text
                and "[RESULT] FAIL status=" in log_text
                and "[RESULT] PASS" not in log_text
            ):
                mutation_ok = False
                break
    audit_variants = (
        mutation_audit.get("variants") if isinstance(mutation_audit, dict) else None)
    audit_by_name = {
        row.get("name"): row
        for row in audit_variants
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(audit_variants, list) else {}
    mutation_ok = mutation_ok and (
        isinstance(mutation_audit, dict)
        and mutation_audit.get("required") == 3
        and mutation_audit.get("compile_success") == 3
        and mutation_audit.get("dynamic_rejected") == 3
        and mutation_audit.get("source_unchanged") is True
        and set(audit_by_name) == set(INSTRET_MUTATION_SPECS)
        and all(
            audit_by_name[name].get("mutant_sha256") == reconstructed.get(name)
            for name in INSTRET_MUTATION_SPECS
        )
    )
    if not mutation_ok:
        errors.append("INSTRET-G1 compile-success RTL source variants are incomplete")

    raw_text = log_path.read_text(encoding="utf-8")
    required_raw_markers = (
        f"schema={INSTRET_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={INSTRET_COMMAND}",
        "metric exception_lanes 2",
        "metric exception_zero_delta 2",
        "metric mret_control_delta_one 1",
        "metric sret_control_delta_one 6",
        "metric sfence_vma_control_delta_one 1",
        "metric control_exact 8",
        "compile_success_rtl_mutations=3",
        "dynamic_rejected_rtl_mutations=3",
        "focused_tests=3/3",
        f"module_aggregate={len(required_tests)}/{len(required_tests)}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[INSTRET-G1-GATE] PASS",
    )
    missing = [marker for marker in required_raw_markers if raw_text.count(marker) != 1]
    if missing:
        errors.append(f"INSTRET-G1 raw log missing exact markers={missing}")
    return errors


FENCE_RESULT_SCHEMA = "npc-rv64-fence-ordering-evidence-v2"
FENCE_VARIANT_SCHEMA = "npc-rv64-fence-rtl-variants-v2"
FENCE_RUN_ID = "2026-07-23-rv64-v9m-fence-ordering-current-design"
FENCE_COMMAND = "make -C npc/rv64 check-fence-ordering"
FENCE_PROGRAM_RE = re.compile(
    r"^\[FENCE-G1-PROGRAM\] "
    r"exit=1 ebreak=1 trap=0 lane1_capture=1 full_memory_wait=1 "
    r"mem_idle_binding=1 "
    r"fence_commit=1 store_probe=1 store_drain=1 device_read=1 "
    r"fence_before_store=0 device_before_store=0 device_before_fence=0 "
    r"readback_match=1 backend_drained=1 PASS$",
    re.MULTILINE,
)
FENCE_PROGRAM_METRICS = {
    "exit": 1,
    "ebreak": 1,
    "trap": 0,
    "lane1_capture": 1,
    "full_memory_wait": 1,
    "mem_idle_binding": 1,
    "fence_commit": 1,
    "store_probe": 1,
    "store_drain": 1,
    "device_read": 1,
    "fence_before_store": 0,
    "device_before_store": 0,
    "device_before_fence": 0,
    "readback_match": 1,
    "backend_drained": 1,
}
FENCE_INVARIANTS = {
    "ordinary_fence_requires_full_memory_idle": True,
    "older_store_probe_and_drain_exact_once": True,
    "ordinary_fence_retirement_exact_once": True,
    "younger_device_read_after_store_drain": True,
    "younger_device_read_after_fence_retirement": True,
    "non_fence_pending_system_contract_preserved": True,
}
FENCE_VARIANT_SPECS = {
    "fence_full_memory_idle_removed": {
        "source": "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
        "make_variable": "RTL_OOO_PENDING_DRAIN_RESOLVE_GATE",
        "test_name": "tb_ooo_pending_drain_resolve_gate",
        "old": (
            "wire pending_fence_mem_quiet_w =\n"
            "      !pending_system_fence_i || mem_idle_i;"),
        "new": "wire pending_fence_mem_quiet_w = 1'b1;",
        "marker": (
            "[CHECK-FAIL] fence waits for MIQ bridge reservation idle "
            "got=1 expected=0"),
    },
    "core_glue_fence_mem_idle_binding_constantized": {
        "source": "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "make_variable": "RTL_OOO_CORE_TOP_GLUE",
        "test_name": "tb_ooo_priv_system",
        "old": ".mem_idle_i(core_mem_idle_w),",
        "new": ".mem_idle_i(1'b1),",
        "marker": (
            "[CHECK-FAIL] fence control plane consumes core memory idle "
            "got=0 expected=1"),
    },
}
FENCE_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v",
    "npc/rv64/vsrc/control/OooPendingDrainResolveGate.v",
    "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
    "npc/rv64/vsrc/control/OooControlPlane.v",
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
    "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
    "npc/rv64/vsrc/execute/OooExecuteBackend.v",
    "npc/rv64/vsrc/core/OooCoreTopGlue.v",
    "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/sim/NpcSimTop.sv",
    "npc/rv64/testbench/tests/tb_ooo_priv_system.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_drain_resolve_gate.sv",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/Makefile",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    f".github/task-runs/{FENCE_RUN_ID}/completion-definition.md",
    f".github/task-runs/{FENCE_RUN_ID}/contract.md",
    f".github/task-runs/{FENCE_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{FENCE_RUN_ID}/run-focused.sh",
    f".github/task-runs/{FENCE_RUN_ID}/run-fence-rtl-variants.py",
    "npc/rv64/eval/ppa/tools/fence_ordering_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_fence_ordering_evidence.py",
}


def validate_fence_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate current-design ordinary-FENCE ordering."""

    errors: list[str] = []
    if entry.get("canonical_command") != FENCE_COMMAND:
        errors.append("FENCE-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"fence_ordering_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(
            "FENCE-G1 requires exact fence_ordering_result/raw_log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["fence_ordering_result"].get("path"))
    raw_path, raw_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or "FENCE-G1 result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or "FENCE-G1 raw log is missing")
        return errors
    if (
        by_kind["fence_ordering_result"].get("sha256")
            != sha256_file(result_path)
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append("FENCE-G1 outer evidence hash is stale")

    result = load_json(result_path)
    metrics = result.get("metrics")
    invariants = result.get("invariants")
    focused = result.get("focused_tests")
    module_aggregate = result.get("module_aggregate")
    variant_audit = result.get("variant_audit")
    provenance = result.get("provenance")
    claim = result.get("claim")
    if not (
        result.get("schema") == FENCE_RESULT_SCHEMA
        and result.get("suite_run_id") == FENCE_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == FENCE_COMMAND
        and metrics == FENCE_PROGRAM_METRICS
        and invariants == FENCE_INVARIANTS
        and claim == {
            "architecture_debt": "CLOSED_ELIGIBLE",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append("FENCE-G1 result metrics, invariants or claim are incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "fence_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"FENCE-G1 cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    source_bindings = (
        provenance.get("source_bindings") if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and provenance.get("runtime_log_design_id") == expected_design_id
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == FENCE_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append("FENCE-G1 source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    expected_artifact_kinds = {
        "program_log", "drain_gate_log", "module_aggregate_summary",
        "rtl_variant_summary",
    }
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(expected_artifact_kinds)
        and set(artifacts_by_kind) == expected_artifact_kinds
    )
    if artifact_ok:
        for kind, item in artifacts_by_kind.items():
            if set(item) != {"kind", "path", "sha256"}:
                artifact_ok = False
                break
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append("FENCE-G1 nested artifact inventory or hash is stale")
        return errors

    focused_names = {
        "program": ("program_log", "tb_ooo_priv_system"),
        "drain_gate": (
            "drain_gate_log", "tb_ooo_pending_drain_resolve_gate"),
    }
    focused_ok = isinstance(focused, dict) and set(focused) == set(focused_names)
    if focused_ok:
        for name, (kind, test_name) in focused_names.items():
            path = artifact_paths[kind]
            text = path.read_text(encoding="utf-8")
            lines = text.splitlines()
            accepted = {f"PASS {test_name}", f"[PASS] {test_name}"}
            pass_lines = [line for line in lines if line in accepted]
            compile_lines = [
                line for line in lines if line.startswith("[COMPILE] ")]
            result_lines = [
                line for line in lines if line.startswith("[RESULT] ")]
            design_marker = f"[RTL-DESIGN-ID] {expected_design_id}"
            record = focused[name]
            if not (
                isinstance(record, dict)
                and set(record) == {"status", "log_sha256"}
                and record.get("status") == "PASS"
                and record.get("log_sha256") == sha256_file(path)
                and len(pass_lines) == 1
                and len(compile_lines) == 1
                and lines.count(design_marker) == 1
                and result_lines == ["[RESULT] PASS"]
                and "[RESULT] FAIL" not in text
                and "[CHECK-FAIL]" not in text
                and "FATAL:" not in text
                and not any(line.startswith("ERROR:") for line in lines)
                and "compile returned nonzero status" not in text
            ):
                focused_ok = False
                break
    if not focused_ok:
        errors.append("FENCE-G1 focused ordering tests are incomplete")

    program_text = artifact_paths["program_log"].read_text(encoding="utf-8")
    if not (
        len(list(FENCE_PROGRAM_RE.finditer(program_text))) == 1
        and program_text.count("[FENCE-G1-PROGRAM]") == 1
        and program_text.count("[RESULT] PASS") == 1
        and program_text.splitlines().count(
            f"[RTL-DESIGN-ID] {expected_design_id}") == 1
        and "[FENCE-G1-PROGRAM] " in program_text
        and "[FENCE-G1-PROGRAM] exit=1" in program_text
        and "[FENCE-G1-PROGRAM] exit=0" not in program_text
        and "[RESULT] FAIL" not in program_text
        and "[CHECK-FAIL]" not in program_text
        and "FATAL:" not in program_text
    ):
        errors.append("FENCE-G1 program ordering marker is missing or malformed")

    drain_text = artifact_paths["drain_gate_log"].read_text(encoding="utf-8")
    if not (
        "[PASS] tb_ooo_pending_drain_resolve_gate" in drain_text
        and "[RESULT] PASS" in drain_text
        and drain_text.splitlines().count(
            f"[RTL-DESIGN-ID] {expected_design_id}") == 1
        and "[CHECK-FAIL]" not in drain_text
        and "FATAL:" not in drain_text
    ):
        errors.append("FENCE-G1 full-memory-idle drain oracle is incomplete")

    module_ok = isinstance(module_aggregate, dict) and set(module_aggregate) == {
        "required", "passed", "failed", "tests",
    }
    try:
        makefile_path, makefile_error = safe_regular_file(
            root, "npc/rv64/testbench/Makefile")
        if makefile_error or makefile_path is None:
            raise ValueError(makefile_error or "module Makefile is missing")
        required_tests, inventory_errors = parse_required_tests(
            makefile_path.read_text(encoding="utf-8"))
        if inventory_errors:
            raise ValueError("; ".join(inventory_errors))
    except (OSError, ValueError) as exc:
        required_tests = []
        module_ok = False
        errors.append(f"FENCE-G1 cannot derive module inventory: {exc}")
    module_records = (
        module_aggregate.get("tests") if isinstance(module_aggregate, dict) else None)
    module_ok = module_ok and (
        bool(required_tests)
        and module_aggregate.get("required") == len(required_tests)
        and module_aggregate.get("passed") == len(required_tests)
        and module_aggregate.get("failed") == 0
        and isinstance(module_records, dict)
        and set(module_records) == set(required_tests)
    )
    summary_path = artifact_paths["module_aggregate_summary"]
    summary_text = summary_path.read_text(encoding="utf-8")
    summary_lines = summary_text.splitlines()
    module_markers = (
        "# NPC single module testbench summary",
        f"- total: {len(required_tests)}",
        f"- passed: {len(required_tests)}",
        "- failed: 0",
    )
    module_ok = module_ok and all(
        summary_text.count(marker) == 1 for marker in module_markers)
    expected_log_names = {f"{name}.log" for name in required_tests}
    actual_log_names = {
        path.name for path in (summary_path.parent / "logs").glob("*.log")
        if path.is_file()
    }
    module_ok = module_ok and actual_log_names == expected_log_names
    if module_ok:
        for test_name in required_tests:
            record = module_records[test_name]
            expected_path = summary_path.parent / "logs" / f"{test_name}.log"
            log_path, log_error = safe_regular_file(
                root, record.get("path") if isinstance(record, dict) else None)
            if log_error or log_path is None:
                module_ok = False
                break
            log_text = log_path.read_text(encoding="utf-8")
            log_lines = log_text.splitlines()
            accepted = {f"PASS {test_name}", f"[PASS] {test_name}"}
            pass_lines = [line for line in log_lines if line in accepted]
            compile_lines = [
                line for line in log_lines if line.startswith("[COMPILE] ")]
            result_lines = [
                line for line in log_lines if line.startswith("[RESULT] ")]
            if not (
                isinstance(record, dict)
                and set(record) == {"path", "sha256"}
                and record.get("path") == expected_path.relative_to(root).as_posix()
                and record.get("sha256") == sha256_file(log_path)
                and summary_lines.count(f"- PASS {test_name}") == 1
                and len(pass_lines) == 1
                and len(compile_lines) == 1
                and log_lines.count(
                    f"[RTL-DESIGN-ID] {expected_design_id}") == 1
                and result_lines == ["[RESULT] PASS"]
                and "[RESULT] FAIL" not in log_text
                and "[CHECK-FAIL]" not in log_text
                and "FATAL:" not in log_text
                and not any(line.startswith("ERROR:") for line in log_lines)
                and "compile returned nonzero status" not in log_text
            ):
                module_ok = False
                break
    if not module_ok:
        errors.append("FENCE-G1 current module aggregate is incomplete")

    variant_path = artifact_paths["rtl_variant_summary"]
    variant = load_json(variant_path)
    rows = variant.get("results")
    row_list = rows if isinstance(rows, list) else []
    rows_by_name = {
        row.get("name"): row
        for row in row_list
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    }
    source_before = variant.get("source_sha256_before")
    variant_ok = (
        variant.get("schema") == FENCE_VARIANT_SCHEMA
        and variant.get("suite_run_id") == FENCE_RUN_ID
        and variant.get("required") == len(FENCE_VARIANT_SPECS)
        and variant.get("compile_success") == len(FENCE_VARIANT_SPECS)
        and variant.get("dynamic_rejected") == len(FENCE_VARIANT_SPECS)
        and variant.get("source_unchanged") is True
        and isinstance(source_before, dict)
        and source_before == variant.get("source_sha256_after")
        and set(source_before) == {
            spec["source"] for spec in FENCE_VARIANT_SPECS.values()}
        and len(row_list) == len(FENCE_VARIANT_SPECS)
        and set(rows_by_name) == set(FENCE_VARIANT_SPECS)
    )
    reconstructed: dict[str, str] = {}
    if variant_ok:
        for name, spec in FENCE_VARIANT_SPECS.items():
            row = rows_by_name[name]
            source_path, source_error = safe_regular_file(root, spec["source"])
            log = row.get("log")
            if source_error or source_path is None or not isinstance(log, dict):
                variant_ok = False
                break
            source_text = source_path.read_text(encoding="utf-8")
            if source_text.count(spec["old"]) != 1:
                variant_ok = False
                break
            variant_sha = sha256_bytes(
                source_text.replace(spec["old"], spec["new"], 1).encode("utf-8"))
            reconstructed[name] = variant_sha
            log_path, log_error = safe_regular_file(root, log.get("path"))
            if log_error or log_path is None:
                variant_ok = False
                break
            log_text = log_path.read_text(encoding="utf-8")
            log_lines = log_text.splitlines()
            compile_lines = [
                line for line in log_lines if line.startswith("[COMPILE] ")]
            check_fail_lines = [
                line for line in log_lines if line.startswith("[CHECK-FAIL] ")]
            fail_lines = [
                line for line in log_lines if line.startswith("[FAIL] ")]
            result_lines = [
                line for line in log_lines if line.startswith("[RESULT] ")]
            if not (
                source_before.get(spec["source"]) == sha256_file(source_path)
                and row.get("source") == spec["source"]
                and row.get("make_variable") == spec["make_variable"]
                and row.get("test_name") == spec["test_name"]
                and row.get("original_sha256") == sha256_file(source_path)
                and row.get("variant_sha256") == variant_sha
                and row.get("expected_marker") == spec["marker"]
                and row.get("marker_observed") is True
                and row.get("compile_success") is True
                and row.get("dynamic_rejected") is True
                and log.get("sha256") == sha256_file(log_path)
                and len(compile_lines) == 1
                and "compile returned nonzero status" not in log_text
                and check_fail_lines == [spec["marker"]]
                and fail_lines == [
                    f"[FAIL] {spec['test_name']} errors=1"]
                and result_lines == ["[RESULT] FAIL status=1"]
                and not any(line.startswith("ERROR:") for line in log_lines)
                and "[RESULT] PASS" not in log_text
            ):
                variant_ok = False
                break
    audit_variants = (
        variant_audit.get("variants") if isinstance(variant_audit, dict) else None)
    audit_by_name = {
        row.get("name"): row
        for row in audit_variants
        if isinstance(row, dict) and isinstance(row.get("name"), str)
    } if isinstance(audit_variants, list) else {}
    variant_ok = variant_ok and (
        isinstance(variant_audit, dict)
        and variant_audit.get("required") == len(FENCE_VARIANT_SPECS)
        and variant_audit.get("compile_success") == len(FENCE_VARIANT_SPECS)
        and variant_audit.get("dynamic_rejected") == len(FENCE_VARIANT_SPECS)
        and variant_audit.get("source_unchanged") is True
        and set(audit_by_name) == set(FENCE_VARIANT_SPECS)
        and all(
            audit_by_name[name].get("variant_sha256") == reconstructed.get(name)
            and audit_by_name[name].get("source")
                == FENCE_VARIANT_SPECS[name]["source"]
            and audit_by_name[name].get("test_name")
                == FENCE_VARIANT_SPECS[name]["test_name"]
            for name in FENCE_VARIANT_SPECS)
    )
    if not variant_ok:
        errors.append("FENCE-G1 compile-success RTL source variants are incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    required_raw_markers = (
        f"schema={FENCE_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"runtime_log_design_id={expected_design_id}",
        f"canonical_command={FENCE_COMMAND}",
        "program_exit=1", "lane1_fence_capture=1",
        "full_memory_wait_observed=1", "fence_commit_exact=1",
        "mem_idle_binding_observed=1",
        "store_probe_exact=1", "store_drain_exact=1",
        "device_read_exact=1", "early_fence_before_store=0",
        "early_device_before_store=0", "early_device_before_fence=0",
        f"compile_success_rtl_variants={len(FENCE_VARIANT_SPECS)}",
        f"dynamic_rejected_rtl_variants={len(FENCE_VARIANT_SPECS)}",
        "focused_tests=2/2",
        f"module_aggregate={len(required_tests)}/{len(required_tests)}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false", "[FENCE-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.splitlines().count(marker) != 1
    ]
    if missing or any(marker in raw_text for marker in (
        "[FENCE-G1-GATE] FAIL", "[RESULT] FAIL", "[CHECK-FAIL]")):
        errors.append(f"FENCE-G1 raw log missing exact markers={missing}")
    return errors


MEMORY_LIFECYCLE_RESULT_SCHEMA = (
    "npc-rv64-memory-issue-lifecycle-evidence-v1")
MEMORY_LIFECYCLE_COMMAND = "make -C npc/rv64 check-memory-issue-lifecycle"
MEMORY_LIFECYCLE_RUN_ID = "2026-07-22-rv64-v9f-memory-issue-lifecycle"
MEMORY_LIFECYCLE_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/execute/OooIntBackend.v",
    "npc/rv64/vsrc/memory/OooMemInflightQueue.v",
    "npc/rv64/vsrc/memory/OooStoreQueue.v",
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{MEMORY_LIFECYCLE_RUN_ID}/contract.md",
    f".github/task-runs/{MEMORY_LIFECYCLE_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{MEMORY_LIFECYCLE_RUN_ID}/run-focused.sh",
    (
        f".github/task-runs/{MEMORY_LIFECYCLE_RUN_ID}/"
        "run-memory-lifecycle-variants.py"
    ),
    "npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_memory_issue_lifecycle_evidence.py",
}
MEMORY_LIFECYCLE_INVARIANTS = {
    "memory_pair_capture_is_atomic": True,
    "terminal1_has_no_edge_old_terminal0_lookthrough": True,
    "terminal_consume_request_fire_and_miq_birth_agree": True,
    "terminal_consume_and_miq_identity_are_request_owner_qualified": True,
    "request_owner_identity_is_preserved": True,
    "backpressure_holds_terminal_without_miq_birth": True,
    "post_launch_quiet_window_has_no_repeated_request_or_birth": True,
    "flush_subtracts_exact_fired_drain_head": True,
    "flush_preserves_valid_drain_head_without_pop_fire": True,
    "flush_preserves_unconsumed_drain_identity": True,
    "flush_compaction_preserves_fifo_order": True,
}
MEMORY_LIFECYCLE_STATIC_AUDIT = {
    "miq_birth_uses_request_fire": True,
    "drain_birth_uses_sq_request_fire": True,
    "sq_request_requires_exact_rob_head_launch_open": True,
    "sq_request_identity_echo_is_asserted": True,
    "drain_is_transport_irrevocable_not_assumed_retired": True,
    "focused_configuration_is_single_memory_port": True,
    "issue1_request_fire_uses_its_own_grant_and_selected_port_ready": True,
    "bank0_global_fire_has_no_independent_accept_condition": True,
    "miq_pop_fire_requires_valid_head_and_exact_owner_match": True,
    "miq_has_no_independent_pop_ready_port": True,
    "miq_pop_valid_owner_mismatch_is_asserted_illegal": True,
}
MEMORY_LIFECYCLE_MEM_METRICS = {
    "phase0": {
        "pair_capture": 2,
        "terminal0_local": 1,
        "terminal1_hold": 1,
        "request_fire": 0,
        "miq_birth": 0,
    },
    "phase1": {
        "terminal0_empty": 1,
        "terminal1_request_fire": 1,
        "terminal1_consume": 1,
        "request_mux_owner": 1,
        "miq_birth": 1,
        "identity_match": 1,
        "identity_fields": 15,
    },
    "post_launch": {
        "terminal_cleared": 1,
        "repeated_request_fire": 0,
        "repeated_miq_birth": 0,
        "miq_resident": 1,
        "quiet_cycles": 3,
    },
    "owner_arbitration": {
        "other_request_fire": 1,
        "terminal1_hold": 1,
        "terminal1_consume": 0,
        "terminal1_birth": 0,
        "other_identity_match": 1,
        "identity_fields": 5,
        "terminal1_release_fire": 1,
    },
    "backpressure": {
        "valid_hold_cycles": 2,
        "request_fire_while_blocked": 0,
        "terminal_consume_while_blocked": 0,
        "miq_birth_while_blocked": 0,
        "release_fire": 1,
    },
    "summary": {
        "pair_capture": 2,
        "terminal0_local": 1,
        "terminal1_hold": 1,
        "request_fire": 1,
        "terminal1_consume": 1,
        "miq_birth": 1,
        "identity_match": 1,
        "identity_fields": 15,
        "backpressure_hold": 2,
        "owner_arbitration": 1,
        "no_repeat": 1,
        "quiet_cycles": 3,
    },
}
MEMORY_LIFECYCLE_MIQ_METRICS = {
    "consumed_drain_removed": 1,
    "stalled_head_no_pop_preserved": 1,
    "unconsumed_drain_preserved": 1,
    "survivor_identity_match": 1,
    "wrapped_order": 1,
}


def _validate_memory_lifecycle_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
    debt_id: str,
) -> list[str]:
    """Independently validate current-design memory lifecycle evidence."""

    errors: list[str] = []
    if entry.get("canonical_command") != MEMORY_LIFECYCLE_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_evidence_kinds = {
        "memory_issue_lifecycle_result", "raw_log"}
    if (len(evidence_list) != 2
            or set(by_kind) != expected_evidence_kinds):
        errors.append(
            f"{debt_id} requires exact memory lifecycle result/raw log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["memory_issue_lifecycle_result"].get("path"))
    raw_path, raw_error = safe_regular_file(
        root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    metrics = result.get("metrics")
    metrics_ok = (
        isinstance(metrics, dict)
        and set(metrics) == {"mem_issue", "miq_flush"}
        and metrics.get("mem_issue") == MEMORY_LIFECYCLE_MEM_METRICS
        and metrics.get("miq_flush") == MEMORY_LIFECYCLE_MIQ_METRICS
    )
    result_ok = (
        set(result) == exact_result_keys
        and result.get("schema") == MEMORY_LIFECYCLE_RESULT_SCHEMA
        and result.get("suite_run_id") == MEMORY_LIFECYCLE_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == MEMORY_LIFECYCLE_COMMAND
        and result.get("scope") == (
            "local RV64 OooIntBackend single-port memory reservation terminal "
            "launch and OooMemInflightQueue same-cycle DRAIN response/flush")
        and metrics_ok
        and result.get("invariants") == MEMORY_LIFECYCLE_INVARIANTS
        and result.get("static_audit") == MEMORY_LIFECYCLE_STATIC_AUDIT
        and result.get("claim") == {
            "architecture_debts": {
                "MEM-ISSUE-G1": "CLOSED_ELIGIBLE",
                "MIQ-FLUSH-G1": "CLOSED_ELIGIBLE",
            },
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    )
    if not result_ok:
        errors.append(
            f"{debt_id} result metrics, invariants, scope or claim are incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            f"{debt_id.lower()}_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == MEMORY_LIFECYCLE_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    expected_artifact_kinds = {
        "mem_issue_focused_log",
        "miq_flush_focused_log",
        "module_aggregate_summary",
        "rtl_variant_summary",
    }
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(expected_artifact_kinds)
        and set(artifacts_by_kind) == expected_artifact_kinds
    )
    if artifact_ok:
        for kind, item in artifacts_by_kind.items():
            if set(item) != {"kind", "path", "sha256"}:
                artifact_ok = False
                break
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        evidence_tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/memory_issue_lifecycle_evidence.py",
            f"{debt_id.lower()}_memory_lifecycle_evidence",
        )
        parsed_mem = evidence_tool.parse_mem_focused_log(
            artifact_paths["mem_issue_focused_log"])
        parsed_miq = evidence_tool.parse_miq_focused_log(
            artifact_paths["miq_flush_focused_log"])
        parsed_module = evidence_tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = evidence_tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = evidence_tool.validate_drain_birth_topology(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    focused = result.get("focused_tests")
    focused_ok = (
        isinstance(focused, dict)
        and focused == {
            "mem_issue_lifecycle": {
                "status": "PASS",
                "log_sha256": sha256_file(
                    artifact_paths["mem_issue_focused_log"]),
            },
            "miq_flush_lifecycle": {
                "status": "PASS",
                "log_sha256": sha256_file(
                    artifact_paths["miq_flush_focused_log"]),
            },
        }
    )
    if not focused_ok:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if not (
        parsed_mem == MEMORY_LIFECYCLE_MEM_METRICS
        and parsed_mem == metrics.get("mem_issue")
        and parsed_miq == MEMORY_LIFECYCLE_MIQ_METRICS
        and parsed_miq == metrics.get("miq_flush")
    ):
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    if parsed_static != MEMORY_LIFECYCLE_STATIC_AUDIT:
        errors.append(f"{debt_id} DRAIN request-fire topology drifted")

    expected_variant_count = 8 if debt_id == "MEM-ISSUE-G1" else 3
    debt_variant = parsed_variants.get("by_debt", {}).get(debt_id)
    if debt_variant != {
        "required": expected_variant_count,
        "compile_success": expected_variant_count,
        "dynamic_rejected": expected_variant_count,
    }:
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={MEMORY_LIFECYCLE_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={MEMORY_LIFECYCLE_COMMAND}",
        "mem_pair_capture=2",
        "mem_terminal0_local=1",
        "mem_terminal1_hold=1",
        "mem_request_fire=1",
        "mem_terminal1_consume=1",
        "mem_miq_birth=1",
        "mem_identity_match=1",
        "mem_identity_fields=15",
        "mem_backpressure_hold=2",
        "mem_owner_arbitration=1",
        "mem_no_repeat=1",
        "mem_quiet_cycles=3",
        "miq_consumed_drain_removed=1",
        "miq_stalled_head_no_pop_preserved=1",
        "miq_unconsumed_drain_preserved=1",
        "miq_survivor_identity_match=1",
        "miq_wrapped_order=1",
        "compile_success_rtl_variants=11",
        "dynamic_rejected_rtl_variants=11",
        "mem_issue_variants=8/8",
        "miq_flush_variants=3/3",
        f"module_aggregate={module_count}/{module_count}",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[MEM-ISSUE-G1-GATE] PASS",
        "[MIQ-FLUSH-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


def validate_mem_issue_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    return _validate_memory_lifecycle_debt(
        root, entry, expected_design_id, "MEM-ISSUE-G1")


def validate_miq_flush_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    return _validate_memory_lifecycle_debt(
        root, entry, expected_design_id, "MIQ-FLUSH-G1")


IFU_AXI_RESULT_SCHEMA = "npc-rv64-ifu-axi-flush-drain-evidence-v1"
IFU_AXI_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/ifu-evidence.mk check-ifu-axi-flush-drain"
)
IFU_AXI_RUN_ID = "2026-07-22-rv64-v9g-ifu-axi-current-design"
IFU_AXI_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/design/specs/ooo-fetch-axi-bridge.md",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge_xbar.sv",
    "npc/rv64/testbench/tests/tb_axi_xbar.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/eval/ppa/ifu-evidence.mk",
    f".github/task-runs/{IFU_AXI_RUN_ID}/contract.md",
    f".github/task-runs/{IFU_AXI_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{IFU_AXI_RUN_ID}/run-focused.sh",
    f".github/task-runs/{IFU_AXI_RUN_ID}/run-ifu-axi-variants.py",
    (
        f".github/task-runs/{IFU_AXI_RUN_ID}/subagent-contracts/"
        "v9g-ifu-axi-coverage-review-v1.json"
    ),
    "npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_ifu_axi_flush_drain_evidence.py",
}
IFU_AXI_METRICS = {
    "bridge": {
        "aw_first": 1,
        "w_first": 1,
        "first_aw_with_flush": 1,
        "first_w_with_flush": 1,
        "last_aw_b_with_flush": 1,
        "last_w_b_with_flush": 1,
        "all_aw_w_b_with_flush": 1,
        "both_done_flush_b_error": 1,
        "both_stalled_flush_cycles": 2,
        "dropped_bresp_error": 1,
        "normal_bresp_error": 1,
        "payload_stability": 1,
        "drop_quiet": 1,
    },
    "xbar_integration": {
        "ifu_b_owner_release": 1,
        "later_master_progress": 1,
        "later_master_payload": 1,
        "later_master_b": 1,
    },
    "xbar_backpressure": {
        "bvalid_hold_cycles": 2,
        "early_release": 0,
        "aw_first": 1,
        "w_first": 1,
        "payload_stability": 1,
    },
}
IFU_AXI_INVARIANTS = {
    "aw_and_w_channels_accept_independently": True,
    "flush_preserves_pending_channel_valid_and_payload": True,
    "flush_cycle_aw_and_w_fire_are_recorded": True,
    "completion_uses_current_cycle_aw_and_w_fire": True,
    "current_cycle_flush_dominates_bresp_at_completion": True,
    "semantic_drop_is_sticky_until_b_completion": True,
    "drop_owner_blocks_fetch_response_and_read_address": True,
    "drop_completion_returns_idle_without_rewalk": True,
    "non_drop_bresp_error_remains_instruction_access_fault": True,
    "xbar_releases_write_owner_only_on_exact_b_fire": True,
    "xbar_accepts_aw_first_and_w_first_master_presentation": True,
    "later_master_progress_preserves_address_data_and_response": True,
}
IFU_AXI_STATIC_AUDIT = {
    "bridge_write_owner_excludes_ordinary_flush_clear": True,
    "bridge_aw_w_valid_are_independent_done_gated": True,
    "bridge_bready_spans_complete_write_owner": True,
    "bridge_completion_uses_both_accepted_next_values": True,
    "bridge_effective_drop_includes_current_flush": True,
    "bridge_port_shadow_is_present": True,
    "bridge_focused_matrix_has_first_last_all_and_both_done_cases": True,
    "bridge_drop_quiet_and_payload_oracles_are_explicit": True,
    "xbar_b_route_uses_recorded_owner": True,
    "xbar_release_requires_exact_b_fire": True,
    "xbar_generic_oracle_has_two_cycle_b_backpressure": True,
    "xbar_generic_oracle_has_aw_first_and_w_first": True,
    "xbar_integration_oracle_has_later_master_progress": True,
    "canonical_make_dispatch_is_exact": True,
    "canonical_make_dispatch_file_is_restricted": True,
    "canonical_make_environment_is_sanitized": True,
    "canonical_make_effective_recipe_is_exact": True,
}
IFU_AXI_ARTIFACT_PATHS = {
    "ifu_axi_bridge_focused_log": (
        f".github/task-runs/{IFU_AXI_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_axi_bridge.log"
    ),
    "ifu_axi_bridge_xbar_focused_log": (
        f".github/task-runs/{IFU_AXI_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_axi_bridge_xbar.log"
    ),
    "axi_xbar_backpressure_log": (
        f".github/task-runs/{IFU_AXI_RUN_ID}/evidence/focused/logs/"
        "tb_axi_xbar.log"
    ),
    "module_aggregate_summary": (
        f".github/task-runs/{IFU_AXI_RUN_ID}/evidence/"
        "module-aggregate/summary.txt"
    ),
    "rtl_variant_summary": (
        f".github/task-runs/{IFU_AXI_RUN_ID}/evidence/mutations/summary.json"
    ),
}


def validate_ifu_axi_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct IFU-AXI-G1 current-design evidence."""

    debt_id = "IFU-AXI-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != IFU_AXI_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"ifu_axi_flush_drain_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(
            f"{debt_id} requires exact IFU AXI result/raw log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["ifu_axi_flush_drain_result"].get("path"))
    raw_path, raw_error = safe_regular_file(
        root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors
    if (
        set(by_kind["ifu_axi_flush_drain_result"])
            != {"kind", "path", "sha256"}
        or by_kind["ifu_axi_flush_drain_result"].get("sha256")
            != sha256_file(result_path)
        or set(by_kind["raw_log"]) != {"kind", "path", "sha256"}
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append(f"{debt_id} ledger evidence hashes are stale")

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    result_ok = (
        set(result) == exact_result_keys
        and result.get("schema") == IFU_AXI_RESULT_SCHEMA
        and result.get("suite_run_id") == IFU_AXI_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == IFU_AXI_COMMAND
        and result.get("scope") == (
            "local RV64 instruction-fetch PTE A-update AW/W/B lifecycle "
            "through OooFetchAxiBridge and AxiCrossbar"
        )
        and result.get("metrics") == IFU_AXI_METRICS
        and result.get("invariants") == IFU_AXI_INVARIANTS
        and result.get("static_audit") == IFU_AXI_STATIC_AUDIT
        and result.get("claim") == {
            "architecture_debts": {"IFU-AXI-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    )
    if not result_ok:
        errors.append(
            f"{debt_id} result metrics, invariants, scope or claim are incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "ifu_axi_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == IFU_AXI_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(IFU_AXI_ARTIFACT_PATHS)
        and set(artifacts_by_kind) == set(IFU_AXI_ARTIFACT_PATHS)
    )
    if artifact_ok:
        for kind, expected_path in IFU_AXI_ARTIFACT_PATHS.items():
            item = artifacts_by_kind[kind]
            path, error = safe_regular_file(root, item.get("path"))
            if (
                set(item) != {"kind", "path", "sha256"}
                or item.get("path") != expected_path
                or error or path is None
                or item.get("sha256") != sha256_file(path)
            ):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        evidence_tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/ifu_axi_flush_drain_evidence.py",
            "ifu_axi_flush_drain_evidence_reconstruct",
        )
        parsed_bridge = evidence_tool.parse_bridge_log(
            artifact_paths["ifu_axi_bridge_focused_log"])
        parsed_xbar = evidence_tool.parse_xbar_integration_log(
            artifact_paths["ifu_axi_bridge_xbar_focused_log"])
        parsed_backpressure = evidence_tool.parse_xbar_backpressure_log(
            artifact_paths["axi_xbar_backpressure_log"])
        parsed_module = evidence_tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = evidence_tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = evidence_tool.validate_static_contract(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    focused_expected = {
        "bridge": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ifu_axi_bridge_focused_log"]),
        },
        "bridge_xbar": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ifu_axi_bridge_xbar_focused_log"]),
        },
        "xbar_backpressure": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["axi_xbar_backpressure_log"]),
        },
    }
    if result.get("focused_tests") != focused_expected:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if {
        "bridge": parsed_bridge,
        "xbar_integration": parsed_xbar,
        "xbar_backpressure": parsed_backpressure,
    } != IFU_AXI_METRICS or result.get("metrics") != IFU_AXI_METRICS:
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    expected_variant_by_source = {
        "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v": {
            "required": 14, "compile_success": 14, "dynamic_rejected": 14,
        },
        "npc/rv64/vsrc/bus/AxiCrossbar.v": {
            "required": 4, "compile_success": 4, "dynamic_rejected": 4,
        },
    }
    if (
        parsed_variants.get("required") != 18
        or parsed_variants.get("compile_success") != 18
        or parsed_variants.get("dynamic_rejected") != 18
        or parsed_variants.get("by_source") != expected_variant_by_source
    ):
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")
    if parsed_static != IFU_AXI_STATIC_AUDIT:
        errors.append(f"{debt_id} static contract topology drifted")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={IFU_AXI_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={IFU_AXI_COMMAND}",
        "bridge_aw_first=1",
        "bridge_w_first=1",
        "bridge_first_aw_with_flush=1",
        "bridge_first_w_with_flush=1",
        "bridge_last_aw_b_with_flush=1",
        "bridge_last_w_b_with_flush=1",
        "bridge_all_aw_w_b_with_flush=1",
        "bridge_both_done_flush_b_error=1",
        "bridge_both_stalled_flush_cycles=2",
        "bridge_payload_stability=1",
        "bridge_drop_quiet=1",
        "xbar_ifu_b_owner_release=1",
        "xbar_later_master_progress=1",
        "xbar_bvalid_hold_cycles=2",
        "xbar_early_release=0",
        "xbar_aw_first=1",
        "xbar_w_first=1",
        "compile_success_rtl_variants=18",
        "dynamic_rejected_rtl_variants=18",
        "bridge_rtl_variants=14/14",
        "xbar_rtl_variants=4/4",
        f"module_aggregate={module_count}/{module_count}",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[IFU-AXI-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


IFU_FETCH_RESULT_SCHEMA = "npc-rv64-ifu-fetch-provenance-evidence-v1"
IFU_FETCH_COMMAND = "make -C npc/rv64 check-ifu-fetch-provenance"
IFU_FETCH_RUN_ID = "2026-07-22-rv64-v9h-ifu-fetch-provenance-current-design"
IFU_FETCH_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/cache/OooFetchPacketCache.v",
    "npc/rv64/design/specs/ooo-fetch-axi-bridge.md",
    "npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/testbench/scripts/check_ifu_icache_coherence_contract.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{IFU_FETCH_RUN_ID}/contract.md",
    f".github/task-runs/{IFU_FETCH_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{IFU_FETCH_RUN_ID}/review-summary.md",
    f".github/task-runs/{IFU_FETCH_RUN_ID}/run-focused.sh",
    f".github/task-runs/{IFU_FETCH_RUN_ID}/run-ifu-fetch-variants.py",
    (
        f".github/task-runs/{IFU_FETCH_RUN_ID}/subagent-contracts/"
        "v9h-ifu-fetch-coverage-review-v1.json"
    ),
    "npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
    "npc/rv64/eval/ppa/tests/test_ifu_fetch_provenance_evidence.py",
}
IFU_FETCH_METRICS = {
    "page_end": {
        "matrix_rows": 13,
        "fault_rows": 9,
        "frontier_f0_rows": 1,
        "frontier_f2_rows": 5,
        "frontier_f4_rows": 3,
        "frontier_f6_rows": 1,
        "stall_rows": 9,
        "stall_cycles": 18,
        "post_accept_quiet_cycles": 18,
        "payload_stability": 1,
        "stale_prefill": 1,
        "positive_instruction_ar": 4,
        "positive_cache_fill": 1,
        "positive_sram_write": 1,
        "fault_instruction_ar_after_f0": 0,
        "fault_younger_ar": 0,
        "fault_cache_fill": 0,
        "fault_sram_write": 0,
    },
    "packet_decode": {
        "poison_split": 4,
        "poison_resp": 2,
        "poison_sanitized": 1,
        "poison_forged": 0,
        "f0_split": 0,
        "f0_slot0_resp": 2,
        "f0_slot1_resp": 2,
        "f0_slot0_sanitized": 1,
        "f0_slot1_sanitized": 1,
        "f0_tval_is_pc": 1,
    },
}
IFU_FETCH_INVARIANTS = {
    "frontier_is_first_failing_halfword_offset": True,
    "frontier_reference_is_computed_from_pc_not_dut_split": True,
    "successful_prefix_bytes_are_retained": True,
    "fault_suffix_bytes_are_zero": True,
    "f0_has_no_successful_instruction_bytes": True,
    "decoder_reads_length_only_after_prefix_success": True,
    "decoder_uses_complete_instruction_byte_range": True,
    "faulted_instruction_is_sanitized_to_nop": True,
    "slot1_has_no_independent_owner_after_slot0_fault": True,
    "stalled_response_tuple_is_stable": True,
    "stalled_response_blocks_alternate_request_accept": True,
    "fault_frontier_blocks_younger_address_offers": True,
    "fault_transaction_never_fills_packet_cache": True,
    "fault_transaction_never_writes_packet_sram": True,
    "post_accept_quiet_window_excludes_late_side_effects": True,
    "positive_control_observes_ar_fill_and_sram_write": True,
}
IFU_FETCH_STATIC_AUDIT = {
    "bridge_registered_frontier_output": True,
    "bridge_new_transaction_clears_packet_scratch": True,
    "bridge_halfword_lane_two_is_exact": True,
    "bridge_cache_fill_requires_complete_non_cross_packet": True,
    "decoder_uses_strict_half_open_end_boundary": True,
    "decoder_slot1_start_uses_slot0_length": True,
    "decoder_slot0_full_range_sanitizes": True,
    "decoder_slot1_effective_range_sanitizes": True,
    "page_tb_independent_page_boundary_reference": True,
    "page_tb_independent_frontier_reference": True,
    "page_tb_stale_prefill_is_no_reset": True,
    "page_tb_positive_monitor_is_non_vacuous": True,
    "page_tb_bridge_f0_is_reachable": True,
    "page_tb_post_accept_quiet_is_explicit": True,
    "decode_tb_fault_tail_poison_is_explicit": True,
    "decode_tb_f0_is_explicit": True,
}
IFU_FETCH_ARTIFACT_PATHS = {
    "ifu_fetch_page_end_focused_log": (
        f".github/task-runs/{IFU_FETCH_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_page_end_fault.log"
    ),
    "ifu_fetch_packet_decode_focused_log": (
        f".github/task-runs/{IFU_FETCH_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_packet_decode.log"
    ),
    "module_aggregate_summary": (
        f".github/task-runs/{IFU_FETCH_RUN_ID}/evidence/"
        "module-aggregate/summary.txt"
    ),
    "rtl_variant_summary": (
        f".github/task-runs/{IFU_FETCH_RUN_ID}/evidence/mutations/summary.json"
    ),
}


def validate_ifu_fetch_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct IFU-FETCH-G2 current-design evidence."""

    debt_id = "IFU-FETCH-G2"
    errors: list[str] = []
    if entry.get("canonical_command") != IFU_FETCH_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"ifu_fetch_provenance_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(
            f"{debt_id} requires exact IFU fetch result/raw log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["ifu_fetch_provenance_result"].get("path"))
    raw_path, raw_error = safe_regular_file(
        root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors
    if (
        set(by_kind["ifu_fetch_provenance_result"])
            != {"kind", "path", "sha256"}
        or by_kind["ifu_fetch_provenance_result"].get("sha256")
            != sha256_file(result_path)
        or set(by_kind["raw_log"]) != {"kind", "path", "sha256"}
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append(f"{debt_id} ledger evidence hashes are stale")

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    result_ok = (
        set(result) == exact_result_keys
        and result.get("schema") == IFU_FETCH_RESULT_SCHEMA
        and result.get("suite_run_id") == IFU_FETCH_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == IFU_FETCH_COMMAND
        and result.get("scope") == (
            "local RV64 fetch bridge to packet decoder first-failing-halfword "
            "byte provenance for page faults"
        )
        and result.get("metrics") == IFU_FETCH_METRICS
        and result.get("invariants") == IFU_FETCH_INVARIANTS
        and result.get("static_audit") == IFU_FETCH_STATIC_AUDIT
        and result.get("claim") == {
            "architecture_debts": {"IFU-FETCH-G2": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    )
    if not result_ok:
        errors.append(
            f"{debt_id} result metrics, invariants, scope or claim are incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "ifu_fetch_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == IFU_FETCH_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(IFU_FETCH_ARTIFACT_PATHS)
        and set(artifacts_by_kind) == set(IFU_FETCH_ARTIFACT_PATHS)
    )
    if artifact_ok:
        for kind, expected_path in IFU_FETCH_ARTIFACT_PATHS.items():
            item = artifacts_by_kind[kind]
            path, error = safe_regular_file(root, item.get("path"))
            if (
                set(item) != {"kind", "path", "sha256"}
                or item.get("path") != expected_path
                or error or path is None
                or item.get("sha256") != sha256_file(path)
            ):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        evidence_tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/ifu_fetch_provenance_evidence.py",
            "ifu_fetch_provenance_evidence_reconstruct",
        )
        parsed_page = evidence_tool.parse_page_log(
            artifact_paths["ifu_fetch_page_end_focused_log"])
        parsed_decode = evidence_tool.parse_decode_log(
            artifact_paths["ifu_fetch_packet_decode_focused_log"])
        parsed_module = evidence_tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = evidence_tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = evidence_tool.validate_static_contract(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    focused_expected = {
        "page_end": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ifu_fetch_page_end_focused_log"]),
        },
        "packet_decode": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ifu_fetch_packet_decode_focused_log"]),
        },
    }
    if result.get("focused_tests") != focused_expected:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if {
        "page_end": parsed_page,
        "packet_decode": parsed_decode,
    } != IFU_FETCH_METRICS or result.get("metrics") != IFU_FETCH_METRICS:
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    expected_variant_by_source = {
        "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v": {
            "required": 8, "compile_success": 8, "dynamic_rejected": 8,
        },
        "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v": {
            "required": 8, "compile_success": 8, "dynamic_rejected": 8,
        },
    }
    if (
        parsed_variants.get("required") != 16
        or parsed_variants.get("compile_success") != 16
        or parsed_variants.get("dynamic_rejected") != 16
        or parsed_variants.get("by_source") != expected_variant_by_source
    ):
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")
    if parsed_static != IFU_FETCH_STATIC_AUDIT:
        errors.append(f"{debt_id} static contract topology drifted")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={IFU_FETCH_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={IFU_FETCH_COMMAND}",
        "matrix_rows=13", "fault_rows=9", "frontier_f0_rows=1",
        "frontier_f2_rows=5", "frontier_f4_rows=3",
        "frontier_f6_rows=1", "stall_cycles=18",
        "post_accept_quiet_cycles=18", "positive_instruction_ar=4",
        "positive_cache_fill=1", "positive_sram_write=1",
        "fault_younger_ar=0", "fault_cache_fill=0", "fault_sram_write=0",
        "decode_poison_forged=0", "decode_f0_split=0",
        "compile_success_rtl_variants=16",
        "dynamic_rejected_rtl_variants=16",
        "bridge_rtl_variants=8/8", "decoder_rtl_variants=8/8",
        f"module_aggregate={module_count}/{module_count}",
        "production_rtl_changed=false", "ppa=UNQUALIFIED",
        "promotion_eligible=false", "[IFU-FETCH-G2-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


IFU_ACCESS_RESULT_SCHEMA = "npc-rv64-ifu-access-evidence-v1"
IFU_ACCESS_RUN_ID = "2026-07-22-rv64-v9i-ifu-access-current-design"
IFU_ACCESS_COMMAND = (
    "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
    "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
    "-f eval/ppa/ifu-evidence.mk check-ifu-access"
)
IFU_ACCESS_SCOPE = (
    "local RV64 instruction-fetch exact halfword access, execute PMP, "
    "AXI ARSIZE/ARPROT, AxiCrossbar ARPROT[2] default-slave selection, "
    "bounded PMEM DPI reads and precise lane fault owner"
)
IFU_ACCESS_ARTIFACT_PATHS = {
    "ifu_access_footprint_focused_log": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_access_footprint.log"
    ),
    "ifu_access_attributes_focused_log": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_axi_access_attrs.log"
    ),
    "ifu_access_firewall_focused_log": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/focused/logs/"
        "tb_axi_exec_firewall.log"
    ),
    "ifu_access_lane_owner_focused_log": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_ifu_lane1_fault_owner.log"
    ),
    "ifu_access_sized_dpi_log": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/sized-dpi/run.log"
    ),
    "module_aggregate_summary": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/"
        "module-aggregate/summary.txt"
    ),
    "rtl_variant_summary": (
        f".github/task-runs/{IFU_ACCESS_RUN_ID}/evidence/mutations/summary.json"
    ),
}
IFU_ACCESS_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/vsrc/memory/PmpChecker.v",
    "npc/rv64/vsrc/bus/AxiCrossbar.v",
    "npc/rv64/vsrc/sim/AxiDpiSlave.sv",
    "npc/rv64/csrc/dpi.c",
    "npc/rv64/csrc/memory/paddr.c",
    "npc/rv64/testbench/tests/tb_ooo_fetch_access_footprint.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_access_attrs.sv",
    "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
    "npc/rv64/testbench/tests/tb_axi_exec_firewall.sv",
    "npc/rv64/testbench/cpp/axi_dpi_slave_sized_tb.cpp",
    "npc/rv64/testbench/cpp/sized_dpi_guard_tb.cpp",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/eval/ppa/ifu-evidence.mk",
    f".github/task-runs/{IFU_ACCESS_RUN_ID}/contract.md",
    f".github/task-runs/{IFU_ACCESS_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{IFU_ACCESS_RUN_ID}/review-summary.md",
    f".github/task-runs/{IFU_ACCESS_RUN_ID}/run-focused.sh",
    f".github/task-runs/{IFU_ACCESS_RUN_ID}/run-ifu-access-variants.py",
    "npc/rv64/eval/ppa/tools/ifu_access_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ifu_access_evidence.py",
}


def validate_ifu_access_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct IFU-ACCESS-G1 current-design evidence."""

    debt_id = "IFU-ACCESS-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != IFU_ACCESS_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"ifu_access_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(f"{debt_id} requires exact IFU access result/raw log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["ifu_access_result"].get("path"))
    raw_path, raw_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors
    if (
        set(by_kind["ifu_access_result"]) != {"kind", "path", "sha256"}
        or by_kind["ifu_access_result"].get("sha256") != sha256_file(result_path)
        or set(by_kind["raw_log"]) != {"kind", "path", "sha256"}
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append(f"{debt_id} ledger evidence hashes are stale")

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    result_header_ok = (
        set(result) == exact_result_keys
        and result.get("schema") == IFU_ACCESS_RESULT_SCHEMA
        and result.get("suite_run_id") == IFU_ACCESS_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == IFU_ACCESS_COMMAND
        and result.get("scope") == IFU_ACCESS_SCOPE
        and result.get("claim") == {
            "architecture_debts": {"IFU-ACCESS-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    )
    if not result_header_ok:
        errors.append(f"{debt_id} result header, scope or claim is incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "ifu_access_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == IFU_ACCESS_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(IFU_ACCESS_ARTIFACT_PATHS)
        and set(artifacts_by_kind) == set(IFU_ACCESS_ARTIFACT_PATHS)
    )
    if artifact_ok:
        for kind, expected_path in IFU_ACCESS_ARTIFACT_PATHS.items():
            item = artifacts_by_kind[kind]
            path, error = safe_regular_file(root, item.get("path"))
            if (
                set(item) != {"kind", "path", "sha256"}
                or item.get("path") != expected_path
                or error or path is None
                or item.get("sha256") != sha256_file(path)
            ):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/ifu_access_evidence.py",
            "ifu_access_evidence_reconstruct",
        )
        parsed_metrics = {
            "footprint": tool.parse_footprint_log(
                artifact_paths["ifu_access_footprint_focused_log"]),
            "attributes": tool.parse_attrs_log(
                artifact_paths["ifu_access_attributes_focused_log"]),
            "firewall": tool.parse_firewall_log(
                artifact_paths["ifu_access_firewall_focused_log"]),
            "lane_owner": tool.parse_lane_log(
                artifact_paths["ifu_access_lane_owner_focused_log"]),
            "dpi": tool.parse_dpi_log(
                artifact_paths["ifu_access_sized_dpi_log"]),
        }
        parsed_module = tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = tool.validate_static_contract(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    expected_metrics = {
        "footprint": {
            "footprint_rows": 4, "poison_rows": 4, "alignment_rows": 16,
            "rresp_rows": 36, "rresp_lane0_rows": 18,
            "rresp_lane1_rows": 18, "rresp_exokay_rows": 12,
            "rresp_slverr_rows": 12, "rresp_decerr_rows": 12,
            "walk_rows": 12, "pmp_rows": 14, "pmp_lane0_rows": 6,
            "pmp_lane1_rows": 6, "lifecycle_rows": 2,
            "sequence_rows": 1, "success_side_effect_rows": 4,
            "fault_side_effect_rows": 36, "rresp_valid_gate_rows": 1,
            "dual_source_priority_rows": 1,
            "back_to_back_no_reset_rows": 1,
        },
        "attributes": {
            "instruction_size": 1, "instruction_prot": 4,
            "ptw_size": 3, "ptw_prot": 0,
            "instruction_stall_cycles": 2, "ptw_stall_cycles": 2,
        },
        "firewall": {
            "stall_cycles": 4, "ifu_redirect_rows": 1,
            "uart_side_effects": 0, "default_error": 2,
            "lsu_data_control_rows": 1,
        },
        "lane_owner": {
            "legacy_rows": 9, "terminal_rows": 4, "squash_rows": 2,
            "poison_rows": 2, "pseudo_rows": 1, "owner_map_rows": 12,
            "owner_map_lane0_rows": 6, "owner_map_lane1_rows": 6,
            "owner_map_capture_rows": 12, "owner_map_pending_rows": 12,
            "owner_map_drain_rows": 12,
        },
        "dpi": {
            "ifetch_lanes": 4, "data_lanes": 2, "invalid_read": 1,
            "write_lanes": 4, "invalid_writes": 3, "read_calls": 6,
            "write_calls": 4, "tail_bytes": 2,
            "guard_probe_sigsegv": 1,
        },
    }
    if parsed_metrics != expected_metrics or result.get("metrics") != expected_metrics:
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")

    focused_expected = {
        "footprint": {
            "status": "PASS", "log_sha256": sha256_file(
                artifact_paths["ifu_access_footprint_focused_log"])},
        "attributes": {
            "status": "PASS", "log_sha256": sha256_file(
                artifact_paths["ifu_access_attributes_focused_log"])},
        "firewall": {
            "status": "PASS", "log_sha256": sha256_file(
                artifact_paths["ifu_access_firewall_focused_log"])},
        "lane_owner": {
            "status": "PASS", "log_sha256": sha256_file(
                artifact_paths["ifu_access_lane_owner_focused_log"])},
        "dpi": {
            "status": "PASS", "log_sha256": sha256_file(
                artifact_paths["ifu_access_sized_dpi_log"])},
    }
    if result.get("focused_tests") != focused_expected:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    expected_by_source = {
        "npc/rv64/vsrc/bus/AxiCrossbar.v": {
            "required": 3, "compile_success": 3, "dynamic_rejected": 3},
        "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v": {
            "required": 9, "compile_success": 9, "dynamic_rejected": 9},
        "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v": {
            "required": 2, "compile_success": 2, "dynamic_rejected": 2},
        "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/memory/PmpChecker.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
    }
    if (
        parsed_variants.get("required") != 19
        or parsed_variants.get("compile_success") != 19
        or parsed_variants.get("dynamic_rejected") != 19
        or parsed_variants.get("by_source") != expected_by_source
    ):
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")
    if result.get("static_audit") != parsed_static or not all(parsed_static.values()):
        errors.append(f"{debt_id} static contract topology drifted")
    invariants = result.get("invariants")
    if (
        not isinstance(invariants, dict) or len(invariants) != 19
        or set(invariants.values()) != {True}
    ):
        errors.append(f"{debt_id} invariant inventory is incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={IFU_ACCESS_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={IFU_ACCESS_COMMAND}",
        "footprint_rows=4", "alignment_rows=16", "rresp_rows=36",
        "rresp_owner_rows=18/18", "rresp_source_rows=12/12/12",
        "pmp_rows=14", "pmp_owner_rows=6/6", "lifecycle_rows=2",
        "instruction_arsize=1", "instruction_arprot=4",
        "ptw_arsize=3", "ptw_arprot=0", "firewall_stall_cycles=4",
        "uart_side_effects=0", "lane_owner_rows=12",
        "lane_owner_split=6/6", "dpi_ifetch_lanes=4",
        "dpi_tail_bytes=2", "compile_success_rtl_variants=19",
        "dynamic_rejected_rtl_variants=19",
        f"module_aggregate={module_count}/{module_count}",
        "production_rtl_changed=false", "ppa=UNQUALIFIED",
        "promotion_eligible=false", "[IFU-ACCESS-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


IFU_TVAL_RESULT_SCHEMA = "npc-rv64-ifu-tval-evidence-v2"
IFU_TVAL_RUN_ID = "2026-07-22-rv64-v9j-ifu-tval-current-design"
IFU_TVAL_COMMAND = "make -C npc/rv64 check-ifu-tval"
IFU_TVAL_SCOPE = (
    "local RV64 instruction-fetch fault PC/cause/tval ownership across "
    "decoder, packet FIFO, compressed-control visibility, pending storage "
    "and drained CSR request"
)
IFU_TVAL_ARTIFACT_PATHS = {
    "ifu_tval_decoder_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_packet_decode.log"
    ),
    "ifu_tval_page_end_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_page_end_fault.log"
    ),
    "ifu_tval_fifo_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_packet_fifo.log"
    ),
    "ifu_tval_lane1_capture_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_pending_lane1_capture_gate.log"
    ),
    "ifu_tval_arbiter_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_pending_dispatch_arbiter.log"
    ),
    "ifu_tval_pending_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_pending_trap_exit_sequencer.log"
    ),
    "ifu_tval_csr_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_csr_trap_request_mux.log"
    ),
    "ifu_tval_lifecycle_focused_log": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_ifu_lane1_fault_owner.log"
    ),
    "module_aggregate_summary": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/"
        "module-aggregate/summary.txt"
    ),
    "rtl_variant_summary": (
        f".github/task-runs/{IFU_TVAL_RUN_ID}/evidence/mutations/summary.json"
    ),
}
IFU_TVAL_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v",
    "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v",
    "npc/rv64/vsrc/frontend/OooFrontend.v",
    "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v",
    "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v",
    "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v",
    "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v",
    "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v",
    "npc/rv64/vsrc/control/OooStopPendingSequencer.v",
    "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv",
    "npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_lane1_capture_gate.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_dispatch_arbiter.sv",
    "npc/rv64/testbench/tests/tb_ooo_pending_trap_exit_sequencer.sv",
    "npc/rv64/testbench/tests/tb_ooo_csr_trap_request_mux.sv",
    "npc/rv64/testbench/tests/tb_ooo_ifu_lane1_fault_owner.sv",
    "npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{IFU_TVAL_RUN_ID}/contract.md",
    f".github/task-runs/{IFU_TVAL_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{IFU_TVAL_RUN_ID}/run-focused.sh",
    f".github/task-runs/{IFU_TVAL_RUN_ID}/run-ifu-tval-variants.py",
    "npc/rv64/eval/ppa/tools/ifu_tval_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ifu_tval_evidence.py",
}


def validate_ifu_tval_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct IFU-TVAL-G1 current-design evidence."""

    debt_id = "IFU-TVAL-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != IFU_TVAL_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"ifu_tval_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(f"{debt_id} requires exact IFU tval result/raw log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["ifu_tval_result"].get("path"))
    raw_path, raw_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors
    if (
        set(by_kind["ifu_tval_result"]) != {"kind", "path", "sha256"}
        or by_kind["ifu_tval_result"].get("sha256")
            != sha256_file(result_path)
        or set(by_kind["raw_log"]) != {"kind", "path", "sha256"}
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append(f"{debt_id} ledger evidence hashes are stale")

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "manifests", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    if not (
        set(result) == exact_result_keys
        and result.get("schema") == IFU_TVAL_RESULT_SCHEMA
        and result.get("suite_run_id") == IFU_TVAL_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == IFU_TVAL_COMMAND
        and result.get("scope") == IFU_TVAL_SCOPE
        and result.get("claim") == {
            "architecture_debts": {"IFU-TVAL-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append(f"{debt_id} result header, scope or claim is incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "ifu_tval_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == IFU_TVAL_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(IFU_TVAL_ARTIFACT_PATHS)
        and set(artifacts_by_kind) == set(IFU_TVAL_ARTIFACT_PATHS)
    )
    if artifact_ok:
        for kind, expected_path in IFU_TVAL_ARTIFACT_PATHS.items():
            item = artifacts_by_kind[kind]
            path, error = safe_regular_file(root, item.get("path"))
            if (
                set(item) != {"kind", "path", "sha256"}
                or item.get("path") != expected_path
                or error or path is None
                or item.get("sha256") != sha256_file(path)
            ):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/ifu_tval_evidence.py",
            "ifu_tval_evidence_reconstruct",
        )
        parsed_lifecycle = tool.parse_lifecycle_log(
            artifact_paths["ifu_tval_lifecycle_focused_log"])
        parsed_metrics = {
            "decoder": tool.parse_decoder_log(
                artifact_paths["ifu_tval_decoder_focused_log"]),
            "page_end": tool.parse_page_end_log(
                artifact_paths["ifu_tval_page_end_focused_log"]),
            "fifo": tool.parse_fifo_log(
                artifact_paths["ifu_tval_fifo_focused_log"]),
            "stages": tool.parse_stage_logs(
                artifact_paths["ifu_tval_lane1_capture_focused_log"],
                artifact_paths["ifu_tval_arbiter_focused_log"],
                artifact_paths["ifu_tval_pending_focused_log"],
                artifact_paths["ifu_tval_csr_focused_log"],
            ),
            "fault_matrix": parsed_lifecycle["fault_matrix"],
            "compressed_control": parsed_lifecycle["compressed_control"],
            "dispatch_stall": parsed_lifecycle["dispatch_stall"],
        }
        parsed_module = tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = tool.validate_static_contract(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    expected_metrics = {
        "decoder": {
            "frontier_rows": 4, "frontier_f0_rows": 1,
            "frontier_f2_rows": 1, "frontier_f4_rows": 1,
            "frontier_f6_rows": 1,
        },
        "page_end": {
            "page_fault_rows": 9, "frontier_f2_rows": 5,
            "frontier_f4_rows": 3, "frontier_f6_rows": 1,
        },
        "fifo": {
            "offset_rows": 3, "frontier_f2_rows": 1,
            "frontier_f4_rows": 1, "frontier_f6_rows": 1,
        },
        "stages": {
            "capture_causes": 2, "arbiter_lanes": 2,
            "pending_capture": 1, "pending_hold_valid_clear": 1,
            "pending_squash_clear": 1, "pending_late_clear": 1,
            "csr_pending_owner": 1, "csr_pc_tval_split": 1,
            "csr_system_tval_zero": 1,
        },
        "fault_matrix": {
            "rows": 24, "page_fault_rows": 12, "access_fault_rows": 12,
            "lane0_rows": 12, "lane1_rows": 12,
            "frontier_f0_rows": 8, "frontier_f2_rows": 8,
            "frontier_f4_rows": 6, "frontier_f6_rows": 2,
            "capture_rows": 24, "pending_rows": 24, "drain_rows": 24,
        },
        "compressed_control": {
            "rows": 6, "terminal_rows": 2, "squash_rows": 2,
            "poison_rows": 2, "frontier": 4,
            "xepc_delta": 2, "tval_delta": 4,
        },
        "dispatch_stall": {
            "rows": 1, "blocked_rows": 1, "accepted_rows": 1,
            "pending_rows": 1, "drain_rows": 1,
        },
    }
    if parsed_metrics != expected_metrics or result.get("metrics") != expected_metrics:
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")
    expected_manifests = {
        "lifecycle_rows": parsed_lifecycle["lifecycle_manifest"],
    }
    if (
        parsed_lifecycle["lifecycle_manifest"]
            != tool.EXPECTED_LIFECYCLE_MANIFEST
        or result.get("manifests") != expected_manifests
    ):
        errors.append(f"{debt_id} lifecycle joint manifest is incomplete")

    focused_kinds = {
        "decoder": "ifu_tval_decoder_focused_log",
        "page_end": "ifu_tval_page_end_focused_log",
        "fifo": "ifu_tval_fifo_focused_log",
        "capture": "ifu_tval_lane1_capture_focused_log",
        "arbiter": "ifu_tval_arbiter_focused_log",
        "pending": "ifu_tval_pending_focused_log",
        "csr": "ifu_tval_csr_focused_log",
        "lifecycle": "ifu_tval_lifecycle_focused_log",
    }
    focused_expected = {
        name: {
            "status": "PASS",
            "log_sha256": sha256_file(artifact_paths[kind]),
        }
        for name, kind in focused_kinds.items()
    }
    if result.get("focused_tests") != focused_expected:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    expected_by_source = {
        "npc/rv64/vsrc/control/OooCsrTrapRequestMux.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/control/OooPendingDispatchArbiter.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v": {
            "required": 2, "compile_success": 2, "dynamic_rejected": 2},
        "npc/rv64/vsrc/control/OooStopPendingSequencer.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFetchPacketDecode.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFetchPacketFifo.v": {
            "required": 2, "compile_success": 2, "dynamic_rejected": 2},
        "npc/rv64/vsrc/frontend/OooFrontend.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
        "npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v": {
            "required": 1, "compile_success": 1, "dynamic_rejected": 1},
    }
    if (
        parsed_variants.get("required") != 12
        or parsed_variants.get("compile_success") != 12
        or parsed_variants.get("dynamic_rejected") != 12
        or parsed_variants.get("by_source") != expected_by_source
    ):
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")
    if result.get("static_audit") != parsed_static or not all(parsed_static.values()):
        errors.append(f"{debt_id} static contract topology drifted")
    invariants = result.get("invariants")
    if (
        not isinstance(invariants, dict) or len(invariants) != 18
        or set(invariants.values()) != {True}
    ):
        errors.append(f"{debt_id} invariant inventory is incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={IFU_TVAL_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={IFU_TVAL_COMMAND}",
        "decoder_frontier_rows=4", "page_end_pf_rows=9",
        "page_end_offsets=5/3/1", "fifo_offset_rows=3",
        "lifecycle_rows=24", "lifecycle_causes=12/12",
        "lifecycle_lanes=12/12", "lifecycle_offsets=8/8/6/2",
        "compressed_control_rows=6",
        "compressed_control_terminal_squash_poison=2/2/2",
        "lifecycle_manifest_rows=24", "dispatch_stall_rows=1",
        "compile_success_rtl_variants=12",
        "dynamic_rejected_rtl_variants=12",
        f"module_aggregate={module_count}/{module_count}",
        "production_rtl_changed=false", "ppa=UNQUALIFIED",
        "promotion_eligible=false", "[IFU-TVAL-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


PTW_PMP_RESULT_SCHEMA = "npc-rv64-ptw-pmp-evidence-v4"
PTW_PMP_RUN_ID = "2026-07-22-rv64-v9k-ptw-pmp-current-design"
PTW_PMP_COMMAND = "make -C npc/rv64 check-ptw-pmp"
PTW_PMP_SCOPE = (
    "local RV64 IFU and LSU page-table walker PTE 8B S-mode WRITE PMP "
    "decision, checker-address-to-AW binding, independent AXI AW/W "
    "handshakes, access-fault response through handshake, A/D update allow "
    "path and registered transaction ownership; downstream IFU lane owner "
    "and tval propagation remain in IFU-ACCESS-G1 and IFU-TVAL-G1"
)
PTW_PMP_ARTIFACT_PATHS = {
    "ptw_pmp_ifu_focused_log": (
        f".github/task-runs/{PTW_PMP_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_fetch_axi_bridge.log"
    ),
    "ptw_pmp_lsu_focused_log": (
        f".github/task-runs/{PTW_PMP_RUN_ID}/evidence/focused/logs/"
        "tb_ooo_mem_axi_bridge.log"
    ),
    "module_aggregate_summary": (
        f".github/task-runs/{PTW_PMP_RUN_ID}/evidence/"
        "module-aggregate/summary.txt"
    ),
    "rtl_variant_summary": (
        f".github/task-runs/{PTW_PMP_RUN_ID}/evidence/mutations/summary.json"
    ),
}
PTW_PMP_SOURCE_BINDINGS = {
    "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v",
    "npc/rv64/vsrc/memory/OooMemAxiBridge.v",
    "npc/rv64/vsrc/memory/PmpChecker.v",
    "npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv",
    "npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv",
    "npc/rv64/testbench/Makefile",
    "npc/rv64/testbench/common/tb_common.svh",
    "npc/rv64/testbench/scripts/check_tb_result.py",
    "npc/rv64/Makefile",
    f".github/task-runs/{PTW_PMP_RUN_ID}/contract.md",
    f".github/task-runs/{PTW_PMP_RUN_ID}/rtl-derivation.md",
    f".github/task-runs/{PTW_PMP_RUN_ID}/run-focused.sh",
    f".github/task-runs/{PTW_PMP_RUN_ID}/run-ptw-pmp-variants.py",
    "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
    "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
    "npc/rv64/eval/ppa/tests/test_ptw_pmp_evidence.py",
}


def validate_ptw_pmp_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct PTW-PMP-G1 current-design evidence."""

    debt_id = "PTW-PMP-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != PTW_PMP_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {"ptw_pmp_result", "raw_log"}
    if len(evidence_list) != 2 or set(by_kind) != expected_kinds:
        errors.append(f"{debt_id} requires exact PTW PMP result/raw log evidence")
        return errors
    result_path, result_error = safe_regular_file(
        root, by_kind["ptw_pmp_result"].get("path"))
    raw_path, raw_error = safe_regular_file(root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or f"{debt_id} result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or f"{debt_id} raw log is missing")
        return errors
    if (
        set(by_kind["ptw_pmp_result"]) != {"kind", "path", "sha256"}
        or by_kind["ptw_pmp_result"].get("sha256") != sha256_file(result_path)
        or set(by_kind["raw_log"]) != {"kind", "path", "sha256"}
        or by_kind["raw_log"].get("sha256") != sha256_file(raw_path)
    ):
        errors.append(f"{debt_id} ledger evidence hashes are stale")

    result = load_json(result_path)
    exact_result_keys = {
        "schema", "suite_run_id", "status", "design_id",
        "canonical_command", "scope", "metrics", "manifests", "invariants",
        "focused_tests", "module_aggregate", "variant_audit",
        "static_audit", "provenance", "artifacts", "claim",
    }
    if not (
        set(result) == exact_result_keys
        and result.get("schema") == PTW_PMP_RESULT_SCHEMA
        and result.get("suite_run_id") == PTW_PMP_RUN_ID
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == PTW_PMP_COMMAND
        and result.get("scope") == PTW_PMP_SCOPE
        and result.get("claim") == {
            "architecture_debts": {"PTW-PMP-G1": "CLOSED_ELIGIBLE"},
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append(f"{debt_id} result header, scope or claim is incomplete")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "ptw_pmp_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    provenance = result.get("provenance")
    source_bindings = (
        provenance.get("source_bindings")
        if isinstance(provenance, dict) else None)
    binding_ok = (
        isinstance(provenance, dict)
        and set(provenance) == {"rtl_sha256", "files", "source_bindings"}
        and provenance.get("rtl_sha256")
            == expected_design_id.removeprefix("sha256:")
        and rtl_sha == expected_design_id.removeprefix("sha256:")
        and provenance.get("files") == rtl_files
        and isinstance(source_bindings, dict)
        and set(source_bindings) == PTW_PMP_SOURCE_BINDINGS
    )
    if binding_ok:
        for relative, declared_sha in source_bindings.items():
            path, error = safe_regular_file(root, relative)
            if error or path is None or declared_sha != sha256_file(path):
                binding_ok = False
                break
    if not binding_ok:
        errors.append(f"{debt_id} source or full RTL binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifact_ok = (
        len(artifact_list) == len(PTW_PMP_ARTIFACT_PATHS)
        and set(artifacts_by_kind) == set(PTW_PMP_ARTIFACT_PATHS)
    )
    if artifact_ok:
        for kind, expected_path in PTW_PMP_ARTIFACT_PATHS.items():
            item = artifacts_by_kind[kind]
            path, error = safe_regular_file(root, item.get("path"))
            if (
                set(item) != {"kind", "path", "sha256"}
                or item.get("path") != expected_path
                or error or path is None
                or item.get("sha256") != sha256_file(path)
            ):
                artifact_ok = False
                break
            artifact_paths[kind] = path
    if not artifact_ok:
        errors.append(f"{debt_id} nested artifact inventory or hash is stale")
        return errors

    try:
        tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/ptw_pmp_evidence.py",
            "ptw_pmp_evidence_reconstruct",
        )
        parsed_ifu = tool.parse_ifu_log(
            artifact_paths["ptw_pmp_ifu_focused_log"])
        parsed_lsu = tool.parse_lsu_log(
            artifact_paths["ptw_pmp_lsu_focused_log"])
        parsed_module = tool.parse_module_aggregate(
            root, artifact_paths["module_aggregate_summary"])
        parsed_variants = tool.validate_variants(
            root, artifact_paths["rtl_variant_summary"])
        parsed_static = tool.validate_static_contract(root)
        lsu_deny_quiet_structure = (
            tool.validate_lsu_unbounded_deny_quiet_structure(
                (root / "npc/rv64/vsrc/memory/OooMemAxiBridge.v")
                .read_text(encoding="utf-8")))
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot reconstruct semantic evidence: {exc}")
        return errors

    expected_metrics = {
        "ifu": {
            "allow_rows": 1, "deny_f0_rows": 1,
            "deny_frontier_rows": 3, "frontier_f2_rows": 1,
            "frontier_f4_rows": 1, "frontier_f6_rows": 1,
            "partial_cover_rows": 1,
            "allow_awaddr_bound_rows": 1,
            "allow_split_aw_first_rows": 1,
            "allow_stall_cycles": 2,
            "allow_payload_stable_rows": 1,
            "allow_exact_once_rows": 1,
        },
        "lsu": {
            "deny_rows": 15, "deny_scenarios": 3,
            "readonly_load_rows": 5,
            "readonly_store_rows": 5, "partial_cover_rows": 5,
            "allow_rows": 2, "owner_stable_rows": 15,
            "response_delay_rows": 15,
            "response_delay_zero_rows": 3,
            "response_delay_nonzero_rows": 12,
            "response_stall_cycles": 33,
            "closed_interval_quiet_rows": 15,
            "ready_high_quiet_rows": 15,
            "allow_awaddr_bound_rows": 2,
            "allow_split_aw_first_rows": 1,
            "allow_split_w_first_rows": 1,
            "allow_stall_cycles": 4,
            "allow_payload_stable_rows": 2,
            "allow_exact_once_rows": 2,
        },
    }
    parsed_metrics = {
        "ifu": parsed_ifu["metrics"], "lsu": parsed_lsu["metrics"]}
    if parsed_metrics != expected_metrics or result.get("metrics") != expected_metrics:
        errors.append(f"{debt_id} focused metrics cannot be reconstructed")
    expected_manifests = {
        "ifu_frontier_denies": parsed_ifu["frontier_manifest"],
        "lsu_denies": parsed_lsu["deny_manifest"],
        "lsu_allows": parsed_lsu["allow_manifest"],
        "lsu_deny_quiet_structure": lsu_deny_quiet_structure,
    }
    if (
        parsed_ifu["frontier_manifest"] != tool.EXPECTED_IFU_FRONTIERS
        or parsed_lsu["deny_manifest"] != tool.EXPECTED_LSU_DENIES
        or parsed_lsu["allow_manifest"] != tool.EXPECTED_LSU_ALLOWS
        or result.get("manifests") != expected_manifests
    ):
        errors.append(f"{debt_id} joint deny/allow manifests are incomplete")

    focused_expected = {
        "ifu_bridge": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ptw_pmp_ifu_focused_log"]),
        },
        "lsu_bridge": {
            "status": "PASS",
            "log_sha256": sha256_file(
                artifact_paths["ptw_pmp_lsu_focused_log"]),
        },
    }
    if result.get("focused_tests") != focused_expected:
        errors.append(f"{debt_id} focused test binding is incomplete")
    if result.get("module_aggregate") != parsed_module:
        errors.append(f"{debt_id} module aggregate cannot be reconstructed")
    if result.get("variant_audit") != parsed_variants:
        errors.append(f"{debt_id} RTL verification variants cannot be reconstructed")
    expected_by_source = {
        "npc/rv64/vsrc/frontend/OooFetchAxiBridge.v": {
            "required": 12, "compile_success": 12, "dynamic_rejected": 12},
        "npc/rv64/vsrc/memory/OooMemAxiBridge.v": {
            "required": 16, "compile_success": 16, "dynamic_rejected": 16},
    }
    if (
        parsed_variants.get("required") != 28
        or parsed_variants.get("compile_success") != 28
        or parsed_variants.get("dynamic_rejected") != 28
        or parsed_variants.get("by_source") != expected_by_source
    ):
        errors.append(f"{debt_id} compile-success RTL variant coverage is incomplete")
    if result.get("static_audit") != parsed_static or not all(parsed_static.values()):
        errors.append(f"{debt_id} static contract topology drifted")
    invariants = result.get("invariants")
    if (
        not isinstance(invariants, dict) or len(invariants) != 28
        or set(invariants.values()) != {True}
    ):
        errors.append(f"{debt_id} invariant inventory is incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    module_count = parsed_module["required"]
    required_raw_markers = (
        f"schema={PTW_PMP_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={PTW_PMP_COMMAND}",
        "ifu_allow_rows=1", "ifu_deny_f0_rows=1",
        "ifu_deny_frontier_rows=3", "ifu_deny_frontiers=2/4/6",
        "ifu_partial_cover_rows=1", "ifu_allow_awaddr_bound_rows=1",
        "ifu_allow_split_aw_first_rows=1", "ifu_allow_stall_cycles=2",
        "lsu_deny_rows=15", "lsu_deny_scenarios=3",
        "lsu_allow_rows=2", "lsu_owner_stable_rows=15",
        "lsu_response_delay_rows=15",
        "lsu_response_delay_sweep=0/1/2/3/5",
        "lsu_response_stall_cycles=33",
        "lsu_closed_interval_quiet_rows=15",
        "lsu_ready_high_quiet_rows=15",
        "lsu_unbounded_deny_quiet_structure=PASS",
        "lsu_allow_split_aw_first_rows=1",
        "lsu_allow_split_w_first_rows=1", "lsu_allow_stall_cycles=4",
        "lsu_partial_cover_rows=5",
        "compile_success_rtl_variants=28",
        "dynamic_rejected_rtl_variants=28",
        f"module_aggregate={module_count}/{module_count}",
        "production_rtl_changed=false", "ppa=UNQUALIFIED",
        "promotion_eligible=false", "[PTW-PMP-G1-GATE] PASS",
    )
    missing = [
        marker for marker in required_raw_markers
        if raw_text.count(marker) != 1]
    if missing or any(marker in raw_text for marker in (
        "[RESULT] FAIL", "[CHECK-FAIL]", "FATAL:", "ERROR:")):
        errors.append(
            f"{debt_id} raw log markers are incomplete or contradictory: "
            f"missing={missing}")
    return errors


F0_COMMAND = "make -C npc/rv64 check-functional-aggregate"
F0_AGGREGATE_PATH = (
    "npc/rv64/eval/ppa/evidence/functional-aggregate-current.json")
F0_RESULT_PATH = (
    "npc/rv64/eval/ppa/evidence/functional-aggregate-result.json")
F0_RAW_PATH = "npc/rv64/eval/ppa/evidence/functional-aggregate.log"
F0_BINDING_PATH = (
    "npc/rv64/eval/ppa/evidence/functional-aggregate-current.binding.json")
F0_MUTATION_SCHEMA = "npc-rv64-functional-evidence-mutations-v1"
F0_PUBLICATION_SCHEMA = "npc-rv64-full-core-functional-current-publication-v1"
F0_RUN_RESULT_SCHEMA = "npc-rv64-full-core-functional-current-evidence-v1"
F0_COHORT_ID = "full-core-single-hart-rv64-dual-issue-ooo-v1"
F0_MODULE_INPUT_SCHEMA = "npc-rv64-full-core-module-input-binding-v1"
F0_FUNCTIONAL_INPUT_SCHEMA = "npc-rv64-full-core-functional-input-binding-v2"
F0_GENERATED_INPUT_PARTS = frozenset({
    ".git", ".cache", "__pycache__", "build", "obj_dir",
})
F0_GENERATED_INPUT_NAMES = frozenset({".result"})
F0_GENERATED_INPUT_SUFFIXES = frozenset({
    ".a", ".bin", ".dump", ".elf", ".o", ".so", ".vvp",
})
F0_SCHEMA_VALID_MUTATION_IDS = (
    "official_test_to_image_swap",
    "official_duplicate_image_file_identity",
    "official_stale_image_set_digest",
    "difftest_am_map_mismatch",
    "stale_simulator_digest",
    "stale_configuration_digest",
    "stale_reference_digest",
    "stale_reference_profile_digest",
    "module_log_file_reuse",
    "module_duplicate_pass_marker",
    "official_membership_substitution",
)
F0_SCHEMA_INVALID_MUTATION_IDS = (
    "official_missing_image_record",
    "am_duplicate_inventory_id",
    "coremark_crc_change",
)
F0_CANONICAL_MUTATION_IDS = (
    *F0_SCHEMA_VALID_MUTATION_IDS,
    *F0_SCHEMA_INVALID_MUTATION_IDS,
)


def f0_repository_input_is_generated(path: pathlib.Path) -> bool:
    """Recognize local RV64 build products beside source inputs."""

    if path.suffix.lower() in F0_GENERATED_INPUT_SUFFIXES:
        return True
    try:
        with path.open("rb") as handle:
            return handle.read(4) == b"\x7fELF"
    except OSError as exc:
        raise RuntimeError(f"cannot inspect functional input candidate: {path}") from exc


def f0_collect_repository_files(
    root: pathlib.Path, entries: list[pathlib.Path]
) -> list[str]:
    """Return the exact source/control closure, excluding secondary products."""

    root_resolved = root.resolve(strict=True)
    collected: set[str] = set()
    for raw in entries:
        candidate = raw if raw.is_absolute() else root / raw
        if candidate.is_symlink():
            raise RuntimeError(f"functional input root is a symlink: {candidate}")
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(root_resolved)
        if resolved.is_file():
            if not f0_repository_input_is_generated(resolved):
                collected.add(resolved.relative_to(root_resolved).as_posix())
            continue
        if not resolved.is_dir():
            raise RuntimeError(f"functional input root is not regular: {candidate}")
        for path in resolved.rglob("*"):
            local_parts = path.relative_to(resolved).parts
            if any(part in F0_GENERATED_INPUT_PARTS for part in local_parts):
                continue
            if (
                path.name in F0_GENERATED_INPUT_NAMES
                or path.name.startswith("Makefile.")
                or path.is_symlink()
                or not path.is_file()
                or f0_repository_input_is_generated(path)
            ):
                continue
            collected.add(path.relative_to(root_resolved).as_posix())
    return sorted(collected)


def f0_official_test_ids(root: pathlib.Path) -> list[str]:
    """Derive the exact official RV64 suite membership from live sources."""

    runner_path, error = safe_regular_file(
        root, "npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh")
    if error or runner_path is None:
        raise RuntimeError(error or "official regression runner is missing")
    text = runner_path.read_text(encoding="utf-8")

    def parse_array(name: str) -> list[str]:
        matches = re.findall(
            rf"(?m)^{re.escape(name)}=\(([^\n()]*)\)$", text)
        if len(matches) != 1:
            raise RuntimeError(f"official runner {name} array is not unique")
        raw = matches[0].strip()
        if not raw:
            return []
        tokens = re.findall(r"[A-Za-z0-9_]+", raw)
        if " ".join(tokens) != " ".join(raw.split()):
            raise RuntimeError(f"official runner {name} array is not canonical")
        return tokens

    suites = parse_array("RISCV_SUITES_DEFAULT") + parse_array(
        "RISCV_PRIVILEGED_SUITES")
    if not suites or len(suites) != len(set(suites)):
        raise RuntimeError("official suite inventory is empty or duplicated")
    isa_root = root / "npc/rv64/testsuites/core-tests/src/riscv-tests/isa"
    test_ids = sorted(
        f"{suite}-p-{source.stem}"
        for suite in suites
        for source in (isa_root / suite).glob("*.S")
        if source.is_file() and not source.is_symlink()
    )
    if len(test_ids) != 177 or len(test_ids) != len(set(test_ids)):
        raise RuntimeError(
            f"official source inventory requires 177 unique tests, got {len(test_ids)}")
    return test_ids


def f0_capture_module_inputs(
    root: pathlib.Path, tests: list[str], architecture: Any
) -> dict[str, Any]:
    """Capture the exact current module RTL/TB/workflow input closure."""

    design_hex, rtl_files = architecture.rtl_binding(root)
    if not rtl_files:
        raise RuntimeError("canonical RTL source closure is empty")
    expected = expected_input_sets(root, tests)
    grouped_paths: dict[str, list[str]] = {
        "rtl": sorted(rtl_files),
        "generated_headers": sorted(expected["generated_headers"]),
        "filelists": sorted(expected["filelists"]),
        "test_sources": sorted(expected["test_sources"]),
        "workflow": [
            "npc/rv64/eval/ppa/tools/full_core_current_evidence.py",
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "npc/rv64/eval/ppa/tools/arch_stable_freeze.py",
        ],
    }
    groups: dict[str, dict[str, str]] = {}
    seen: set[str] = set()
    for group, paths in grouped_paths.items():
        records: dict[str, str] = {}
        for relative in paths:
            if relative in seen:
                continue
            path, error = safe_regular_file(root, relative)
            if error or path is None:
                raise RuntimeError(error or f"module input is missing: {relative}")
            records[relative] = sha256_file(path)
            seen.add(relative)
        if not records:
            raise RuntimeError(f"module input group is empty: {group}")
        groups[group] = records
    return {
        "schema": F0_MODULE_INPUT_SCHEMA,
        "design_id": f"sha256:{design_hex}",
        "required_tests": tests,
        "groups": groups,
    }


def f0_capture_functional_inputs(
    root: pathlib.Path, tests: list[str], architecture: Any
) -> dict[str, Any]:
    """Capture exact full-core program/reference/tool inputs for replay."""

    value = f0_capture_module_inputs(root, tests, architecture)
    value["schema"] = F0_FUNCTIONAL_INPUT_SCHEMA
    groups = value["groups"]
    seen = {path for records in groups.values() for path in records}
    source_groups = {
        "functional_workflow": [
            root / "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py",
            root / (
                ".github/task-runs/"
                "2026-07-22-rv64-v9l-functional-aggregate-current-design/"
                "run-functional-aggregate.py"),
            root / "npc/rv64/eval/ppa/run-full-core-current.sh",
            root / "npc/rv64/design/arch/full-core-functional-run-policy-v1.json",
            root / "scripts/task-run-status.sh",
            root / "npc/rv64/eval/ppa/tools/functional_aggregate.py",
            root / "npc/rv64/eval/ppa/schemas/functional-aggregate-v2.schema.json",
            root / "npc/rv64/eval/ppa/schemas/functional-aggregate-result-v1.schema.json",
            root / "npc/rv64/eval/ppa/schemas/difftest-reference-profile-v1.schema.json",
            root / "npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh",
            root / "am-kernels/tests/cpu-tests/scripts/check_results.py",
        ],
        "npc_host_harness_sources": [
            root / "npc/rv64/Makefile",
            root / "npc/rv64/Kconfig",
            root / "npc/rv64/.config",
            root / "npc/rv64/configs/default_defconfig",
            root / "npc/rv64/csrc",
        ],
        "official_program_sources": [
            root / "npc/rv64/testsuites/core-tests/src/riscv-tests"],
        "am_program_sources": [
            root / "am-kernels/tests/cpu-tests/Makefile",
            root / "am-kernels/tests/cpu-tests/tests",
            root / "am-kernels/tests/cpu-tests/scripts",
            root / "abstract-machine/Makefile",
            root / "abstract-machine/am",
            root / "abstract-machine/klib",
            root / "abstract-machine/scripts",
        ],
        "benchmark_program_sources": [
            root / "am-kernels/benchmarks/coremark",
            root / "am-kernels/benchmarks/dhrystone",
        ],
        "reference_model_sources": [
            root / "nemu/Makefile",
            root / "nemu/Kconfig",
            root / "nemu/.config",
            root / "nemu/configs/riscv64-npc_defconfig",
            root / "nemu/src",
            root / "nemu/include",
            root / "nemu/scripts",
        ],
    }
    for group, entries in source_groups.items():
        records: dict[str, str] = {}
        for relative in f0_collect_repository_files(root, entries):
            if relative in seen:
                continue
            path, error = safe_regular_file(root, relative)
            if error or path is None:
                raise RuntimeError(error or f"functional input is missing: {relative}")
            records[relative] = sha256_file(path)
            seen.add(relative)
        if not records:
            raise RuntimeError(f"functional input group is empty: {group}")
        groups[group] = records

    tools: dict[str, dict[str, str]] = {}
    for name in ("make", "verilator", "g++", "python3"):
        located = shutil.which(name)
        if located is None:
            raise RuntimeError(f"required functional tool is missing: {name}")
        resolved = pathlib.Path(located).resolve(strict=True)
        tools[name] = {"path": resolved.as_posix(), "sha256": sha256_file(resolved)}
    for name in ("riscv64-linux-gnu-gcc", "riscv64-unknown-elf-gcc"):
        located = shutil.which(name)
        if located is not None:
            resolved = pathlib.Path(located).resolve(strict=True)
            tools[name] = {
                "path": resolved.as_posix(), "sha256": sha256_file(resolved)}
    value["toolchain"] = tools
    am_tests = root / "am-kernels/tests/cpu-tests/tests"
    value["am_test_ids"] = sorted(
        path.stem for path in am_tests.glob("*.c")
        if path.is_file() and not path.is_symlink())
    if not value["am_test_ids"]:
        raise RuntimeError("functional AM source inventory is empty")
    value["official_test_ids"] = f0_official_test_ids(root)
    return value


def f0_load_source_run_verifier(root: pathlib.Path) -> Any:
    """Load the full-core verifier from this root without cross-run module cache."""
    module_names = (
        "architecture_hard_gates",
        "arch_stable_freeze",
        "full_core_current_evidence",
    )
    saved_modules = {name: sys.modules.pop(name, None) for name in module_names}
    saved_path = list(sys.path)
    tools_dir = str(root / "npc/rv64/eval/ppa/tools")
    try:
        sys.path.insert(0, tools_dir)
        return load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py",
            "f0_source_run_verifier",
        )
    finally:
        sys.path[:] = saved_path
        for name in module_names:
            sys.modules.pop(name, None)
            if saved_modules[name] is not None:
                sys.modules[name] = saved_modules[name]


def f0_aggregate_log_text(
    aggregate: dict[str, Any], counts: dict[str, int], checks: list[dict[str, Any]]
) -> str:
    """Reconstruct the exact non-PPA F0 terminal receipt."""
    lines = [
        f"schema={FUNCTIONAL_RESULT_SCHEMA}",
        f"aggregate_schema={FUNCTIONAL_SCHEMA}",
        f"design_id={aggregate['design_id']}",
        f"cohort_id={aggregate['cohort_id']}",
        f"canonical_command={F0_COMMAND}",
        f"module_aggregate={counts['module_passed']}/{counts['module_required']}",
        f"official_aggregate={counts['official_passed']}/{counts['official_required']}",
        f"am_aggregate={counts['am_passed']}/{counts['am_required']}",
        f"difftest_mismatches={counts['difftest_mismatches']}",
        f"compile_success_evidence_mutations={counts['evidence_mutations_compiled']}",
        f"rejected_evidence_mutations={counts['evidence_mutations_rejected']}",
        "coremark_iterations=10",
        "coremark_crc=0xfcaf",
        "dhrystone_runs=10000",
        "production_rtl_changed=false",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
    ]
    lines.extend(
        f"check[{item['check_id']}]={item['status']}" for item in checks
    )
    lines.append("[F0-G1-GATE] PASS")
    return "\n".join(lines) + "\n"


def f0_mutation_summary_errors(
    value: Any,
    *,
    expected_design_id: str,
    cohort_id: str,
    counts: Any,
) -> list[str]:
    """Validate the exact canonical 14-case F0 mutation receipt."""
    errors: list[str] = []
    summary = value if isinstance(value, dict) else {}
    expected_keys = {
        "schema", "design_id", "cohort_id", "aggregate_schema", "total",
        "schema_valid", "schema_invalid", "schema_valid_rejected",
        "all_rejected", "mutations",
    }
    if set(summary) != expected_keys:
        errors.append("mutation summary field set differs from exact contract")
    if (
        summary.get("schema") != F0_MUTATION_SCHEMA
        or summary.get("design_id") != expected_design_id
        or summary.get("cohort_id") != cohort_id
        or summary.get("aggregate_schema") != FUNCTIONAL_SCHEMA
    ):
        errors.append("mutation summary design/cohort/schema binding drifted")
    records = summary.get("mutations")
    records_list = records if isinstance(records, list) else []
    observed_ids = [
        item.get("mutation_id") for item in records_list
        if isinstance(item, dict)
    ]
    if observed_ids != list(F0_CANONICAL_MUTATION_IDS):
        errors.append("mutation summary canonical inventory drifted")
    valid_ids = set(F0_SCHEMA_VALID_MUTATION_IDS)
    for index, item in enumerate(records_list):
        if not isinstance(item, dict):
            errors.append(f"mutation record {index} is not an object")
            continue
        mutation_id = item.get("mutation_id")
        expected_record_keys = {
            "mutation_id", "schema_valid", "rejected",
            "mutant_canonical_sha256", "reasons",
        }
        if set(item) != expected_record_keys:
            errors.append(f"mutation record field set drifted: {mutation_id}")
        if item.get("schema_valid") is not (mutation_id in valid_ids):
            errors.append(f"mutation schema class drifted: {mutation_id}")
        if item.get("rejected") is not True:
            errors.append(f"mutation was not rejected: {mutation_id}")
        digest = item.get("mutant_canonical_sha256")
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
            errors.append(f"mutation digest is invalid: {mutation_id}")
        reasons = item.get("reasons")
        if (
            not isinstance(reasons, list)
            or not reasons
            or any(not isinstance(reason, str) or not reason for reason in reasons)
        ):
            errors.append(f"mutation rejection reasons are missing: {mutation_id}")
    expected_summary = {
        "total": len(F0_CANONICAL_MUTATION_IDS),
        "schema_valid": len(F0_SCHEMA_VALID_MUTATION_IDS),
        "schema_invalid": len(F0_SCHEMA_INVALID_MUTATION_IDS),
        "schema_valid_rejected": len(F0_SCHEMA_VALID_MUTATION_IDS),
        "all_rejected": True,
    }
    for key, expected in expected_summary.items():
        if summary.get(key) != expected:
            errors.append(
                f"mutation summary {key}={summary.get(key)} expected={expected}")
    count_map = counts if isinstance(counts, dict) else {}
    if (
        count_map.get("evidence_mutations_compiled")
        != len(F0_SCHEMA_VALID_MUTATION_IDS)
        or count_map.get("evidence_mutations_rejected")
        != len(F0_SCHEMA_VALID_MUTATION_IDS)
    ):
        errors.append("functional result mutation counts drifted")
    return errors


def _f0_bound_artifact(
    root: pathlib.Path,
    value: Any,
    *,
    expected_kind: str,
    label: str,
) -> tuple[pathlib.Path | None, list[str]]:
    """Resolve one immutable full-core artifact receipt."""

    errors: list[str] = []
    entry = value if isinstance(value, dict) else {}
    if set(entry) != {"kind", "path", "sha256", "size_bytes"}:
        errors.append(f"{label} artifact field set drifted")
    if entry.get("kind") != expected_kind:
        errors.append(f"{label} artifact kind drifted")
    path, error = safe_regular_file(root, entry.get("path"))
    if error or path is None:
        errors.append(error or f"{label} artifact is missing")
        return None, errors
    if entry.get("sha256") != sha256_file(path):
        errors.append(f"{label} artifact hash is stale")
    if entry.get("size_bytes") != path.stat().st_size:
        errors.append(f"{label} artifact size is stale")
    return path, errors


def validate_f0_publication_binding(
    root: pathlib.Path,
    *,
    expected_design_id: str,
    result: dict[str, Any],
    resolved: dict[str, pathlib.Path],
) -> tuple[list[str], pathlib.Path | None]:
    """Bind canonical F0 files to one completed immutable full-core run."""

    debt_id = "F0-G1"
    errors: list[str] = []
    binding_path, error = safe_regular_file(root, F0_BINDING_PATH)
    if error or binding_path is None:
        errors.append(error or f"{debt_id} publication binding is missing")
        return errors, None
    try:
        binding = load_json(binding_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} publication binding is unreadable: {exc}")
        return errors, None
    expected_binding_keys = {
        "schema", "status", "design_id", "cohort_id", "source_run_result",
        "execution_status", "artifacts",
    }
    if set(binding) != expected_binding_keys:
        errors.append(f"{debt_id} publication binding field set drifted")
    if not (
        binding.get("schema") == F0_PUBLICATION_SCHEMA
        and binding.get("status") == "PASS"
        and binding.get("design_id") == expected_design_id
        and binding.get("cohort_id") == F0_COHORT_ID
        and result.get("cohort_id") == F0_COHORT_ID
    ):
        errors.append(f"{debt_id} publication identity/status/cohort drifted")

    source_result_path, artifact_errors = _f0_bound_artifact(
        root,
        binding.get("source_run_result"),
        expected_kind="functional_run_result",
        label=f"{debt_id} source run result",
    )
    errors.extend(artifact_errors)
    if source_result_path is None:
        return errors, None
    source_relative = source_result_path.relative_to(root).as_posix()
    source_parts = pathlib.PurePosixPath(source_relative).parts
    if not (
        len(source_parts) == 6
        and source_parts[:2] == (".github", "task-runs")
        and source_parts[2] not in {"", ".", ".."}
        and source_parts[3:] == ("evidence", "functional", "run-result.json")
    ):
        errors.append(f"{debt_id} source result is not an exact task-run output")
        return errors, None
    source_output_dir = source_result_path.parent
    run_dir = source_output_dir.parents[1]

    execution_path, artifact_errors = _f0_bound_artifact(
        root,
        binding.get("execution_status"),
        expected_kind="full_core_execution_status",
        label=f"{debt_id} execution status",
    )
    errors.extend(artifact_errors)
    expected_execution_path = run_dir / "full-core-current.status"
    if execution_path != expected_execution_path.resolve(strict=False):
        errors.append(f"{debt_id} execution status points to another run")
    elif execution_path.read_text(encoding="utf-8") != "PASS\n":
        errors.append(f"{debt_id} execution status is not exact PASS")

    publication_path, publication_error = safe_regular_file(
        root,
        (run_dir / "full-core-publication.status").relative_to(root).as_posix(),
    )
    if publication_error or publication_path is None:
        errors.append(
            publication_error or f"{debt_id} publication status is missing")
    elif publication_path.read_text(encoding="utf-8") != "PASS\n":
        errors.append(f"{debt_id} publication status is not exact PASS")

    canonical_artifacts = binding.get("artifacts")
    canonical_map = canonical_artifacts if isinstance(canonical_artifacts, dict) else {}
    expected_canonical = {
        "aggregate": (
            "functional_aggregate", resolved["functional_aggregate"],
        ),
        "aggregate_result": (
            "functional_aggregate_result",
            resolved["functional_aggregate_result"],
        ),
        "aggregate_log": ("functional_aggregate_log", resolved["raw_log"]),
    }
    if set(canonical_map) != set(expected_canonical):
        errors.append(f"{debt_id} canonical publication inventory drifted")
    canonical_paths: dict[str, pathlib.Path] = {}
    for name, (kind, expected_path) in expected_canonical.items():
        path, artifact_errors = _f0_bound_artifact(
            root,
            canonical_map.get(name),
            expected_kind=kind,
            label=f"{debt_id} canonical {name}",
        )
        errors.extend(artifact_errors)
        if path is not None:
            canonical_paths[name] = path
            if path != expected_path:
                errors.append(f"{debt_id} canonical {name} path drifted")

    try:
        source_result = load_json(source_result_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} source run result is unreadable: {exc}")
        return errors, source_output_dir
    if not (
        source_result.get("schema") == F0_RUN_RESULT_SCHEMA
        and source_result.get("status") == "PASS"
        and source_result.get("design_id") == expected_design_id
        and source_result.get("counts") == result.get("counts")
        and source_result.get("published_current") is False
    ):
        errors.append(f"{debt_id} immutable source run result contract drifted")
    source_artifacts = source_result.get("artifacts")
    source_map = source_artifacts if isinstance(source_artifacts, dict) else {}
    expected_source = {
        "aggregate": ("functional_aggregate", "functional-aggregate.json"),
        "aggregate_result": (
            "functional_aggregate_result", "functional-aggregate-result.json",
        ),
        "aggregate_log": (
            "functional_aggregate_log", "functional-aggregate.log",
        ),
    }
    for name, (kind, filename) in expected_source.items():
        path, artifact_errors = _f0_bound_artifact(
            root,
            source_map.get(name),
            expected_kind=kind,
            label=f"{debt_id} source {name}",
        )
        errors.extend(artifact_errors)
        expected_path = source_output_dir / filename
        if path is not None and path != expected_path.resolve(strict=False):
            errors.append(f"{debt_id} source {name} path drifted")
        canonical_path = canonical_paths.get(name)
        if path is not None and canonical_path is not None:
            if sha256_file(path) != sha256_file(canonical_path):
                errors.append(f"{debt_id} source/canonical {name} hash drifted")
    return errors, source_output_dir


def validate_f0_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently reconstruct F0-G1 local functional evidence."""

    debt_id = "F0-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != F0_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_kinds = {
        "functional_aggregate_result", "functional_aggregate",
        "raw_log", "mutation_summary",
    }
    if len(evidence_list) != 4 or set(by_kind) != expected_kinds:
        errors.append(
            f"{debt_id} requires exact result/aggregate/raw/mutation evidence")
        return errors

    resolved: dict[str, pathlib.Path] = {}
    for kind in sorted(expected_kinds):
        item = by_kind[kind]
        path, error = safe_regular_file(root, item.get("path"))
        if error or path is None:
            errors.append(error or f"{debt_id} {kind} artifact is missing")
            continue
        if (
            set(item) != {"kind", "path", "sha256"}
            or item.get("sha256") != sha256_file(path)
        ):
            errors.append(f"{debt_id} {kind} artifact hash is stale")
        resolved[kind] = path
    if len(resolved) != len(expected_kinds):
        return errors
    if resolved["functional_aggregate"].relative_to(root).as_posix() \
            != F0_AGGREGATE_PATH:
        errors.append(f"{debt_id} current aggregate path drifted")
    if resolved["functional_aggregate_result"].relative_to(root).as_posix() \
            != F0_RESULT_PATH:
        errors.append(f"{debt_id} current result path drifted")
    if resolved["raw_log"].relative_to(root).as_posix() != F0_RAW_PATH:
        errors.append(f"{debt_id} current raw-log path drifted")

    try:
        result = load_json(resolved["functional_aggregate_result"])
        aggregate = load_json(resolved["functional_aggregate"])
        mutations = load_json(resolved["mutation_summary"])
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot read structured evidence: {exc}")
        return errors
    result_schema_errors = schema_errors(root, result, FUNCTIONAL_RESULT_SCHEMA)
    if result_schema_errors:
        errors.append(
            f"{debt_id} result schema failed: "
            + "; ".join(result_schema_errors[:3]))
    if not (
        result.get("schema") == FUNCTIONAL_RESULT_SCHEMA
        and result.get("design_id") == expected_design_id
        and result.get("cohort_id") == F0_COHORT_ID
        and result.get("status") == "PASS"
        and result.get("exit_code") == 0
        and result.get("canonical_command") == F0_COMMAND
    ):
        errors.append(f"{debt_id} result identity/status/command is incomplete")

    binding_errors, source_output_dir = validate_f0_publication_binding(
        root,
        expected_design_id=expected_design_id,
        result=result,
        resolved=resolved,
    )
    errors.extend(binding_errors)
    if source_output_dir is None:
        return errors

    result_artifacts = {
        "aggregate": (
            "functional_aggregate",
            source_output_dir / "functional-aggregate.json",
            resolved["functional_aggregate"],
        ),
        "raw_log": (
            "raw_log",
            source_output_dir / "functional-aggregate.log",
            resolved["raw_log"],
        ),
        "mutation_summary": (
            "mutation_summary",
            source_output_dir / "mutations/summary.json",
            resolved["mutation_summary"],
        ),
    }
    for key, (kind, expected_source, published_path) in result_artifacts.items():
        item = result.get(key)
        entry = item if isinstance(item, dict) else {}
        source_path, source_error = safe_regular_file(root, entry.get("path"))
        expected_entry = {
            "kind": kind,
            "path": expected_source.relative_to(root).as_posix(),
            "sha256": sha256_file(published_path),
        }
        if (
            source_error
            or source_path != expected_source.resolve(strict=False)
            or entry != expected_entry
            or (
                source_path is not None
                and sha256_file(source_path) != sha256_file(published_path)
            )
        ):
            errors.append(f"{debt_id} result {key} artifact binding drifted")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "f0_functional_rtl_binding",
        )
        rtl_sha, _ = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute current RTL design id: {exc}")
        rtl_sha = ""
    if f"sha256:{rtl_sha}" != expected_design_id:
        errors.append(f"{debt_id} result is not bound to current local RV64 RTL")

    makefile, makefile_error = safe_regular_file(
        root, "npc/rv64/testbench/Makefile")
    required_tests: list[str] = []
    if makefile_error or makefile is None:
        errors.append(makefile_error or f"{debt_id} module Makefile is missing")
    else:
        required_tests, inventory_errors = parse_required_tests(
            makefile.read_text(encoding="utf-8"))
        errors.extend(f"{debt_id} {error}" for error in inventory_errors)
    if required_tests:
        try:
            # F0 不只消费三份 publication 文件；复用正式 verifier 深验同一
            # task-run 的 module/status/input/retention/guest/mutation 闭包。
            functional_verifier = f0_load_source_run_verifier(root)
            functional_verifier.verify_functional_result(
                source_output_dir / "run-result.json",
                require_current_design=True,
                require_canonical_current=False,
            )
        except Exception as exc:  # checker boundary must convert all drift to GAP
            errors.append(f"{debt_id} immutable source run deep validation failed: {exc}")
    images: list[dict[str, Any]] = []
    for suite_name in ("official", "am"):
        suite = aggregate.get(suite_name)
        records = suite.get("images") if isinstance(suite, dict) else None
        if isinstance(records, list):
            images.extend(
                item.get("image") for item in records
                if isinstance(item, dict) and isinstance(item.get("image"), dict)
            )
    benchmarks = aggregate.get("benchmarks")
    if isinstance(benchmarks, dict):
        for name in ("coremark", "dhrystone"):
            record = benchmarks.get(name)
            if isinstance(record, dict) and isinstance(record.get("image"), dict):
                images.append(record["image"])
    difftest = aggregate.get("difftest")
    freeze_groups = {
        "config": [aggregate.get("configuration")],
        "binaries": [
            aggregate.get("simulator"),
            difftest.get("reference") if isinstance(difftest, dict) else None,
        ],
        "images": images,
    }
    functional_checks, functional_blockers, _ = validate_functional(
        root=root,
        functional=aggregate,
        expected_design_id=expected_design_id,
        cohort_id=result.get("cohort_id", ""),
        required_tests=required_tests,
        freeze_groups=freeze_groups,
    )
    if functional_blockers:
        errors.append(
            f"{debt_id} aggregate reconstruction failed: "
            + "; ".join(functional_blockers[:3]))
    if result.get("checks") != functional_checks:
        errors.append(f"{debt_id} published checks differ from reconstruction")

    counts = result.get("counts")
    am_suite = aggregate.get("am")
    am_required = (
        am_suite.get("required") if isinstance(am_suite, dict) else None
    )
    expected_counts = {
        "module_required": len(required_tests),
        "module_passed": len(required_tests),
        "official_required": 177,
        "official_passed": 177,
        "am_required": am_required,
        "am_passed": am_required,
        "difftest_mismatches": 0,
        "evidence_mutations_compiled": len(F0_SCHEMA_VALID_MUTATION_IDS),
        "evidence_mutations_rejected": len(F0_SCHEMA_VALID_MUTATION_IDS),
    }
    if counts != expected_counts:
        errors.append(f"{debt_id} exact module/official/AM/DiffTest counts drifted")
    errors.extend(
        f"{debt_id} {error}"
        for error in f0_mutation_summary_errors(
            mutations,
            expected_design_id=expected_design_id,
            cohort_id=result.get("cohort_id", ""),
            counts=counts,
        )
    )

    raw_text = resolved["raw_log"].read_text(encoding="utf-8")
    try:
        expected_raw_text = f0_aggregate_log_text(
            aggregate,
            counts if isinstance(counts, dict) else {},
            functional_checks,
        )
    except (KeyError, TypeError, ValueError) as exc:
        errors.append(f"{debt_id} cannot reconstruct terminal receipt: {exc}")
        expected_raw_text = None
    if expected_raw_text is not None and raw_text != expected_raw_text:
        errors.append(f"{debt_id} raw log differs from exact terminal receipt")
    return errors


def control_event_forbidden_references(value: Any) -> set[str]:
    """Return boundary-generated artifact paths referenced by a JSON value."""

    references: set[str] = set()
    if isinstance(value, dict):
        for key, child in value.items():
            if key in CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS:
                references.add(key)
            if key == "path" and child in CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS:
                references.add(child)
            references.update(control_event_forbidden_references(child))
    elif isinstance(value, list):
        for child in value:
            references.update(control_event_forbidden_references(child))
    return references


def validate_control_event_architecture_payload(
    architecture_result: dict[str, Any],
    architecture_manifest: dict[str, Any],
    expected_rtl: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    """Validate the canonical 9-gate JSON pair consumed by CONTROL-EVENT-G1."""

    debt_id = "CONTROL-EVENT-G1"
    errors: list[str] = []
    result_keys = {
        "schema", "generated_at_utc", "overall_status", "exit_code",
        "contract", "rtl_source_set", "evidence_manifest",
        "evidence_errors", "gates",
    }
    manifest_keys = {"schema", "generated_at_utc", "design_id", "tests"}
    if set(architecture_result) != result_keys:
        errors.append(f"{debt_id} architecture result field set drifted")
    if set(architecture_manifest) != manifest_keys:
        errors.append(f"{debt_id} architecture manifest field set drifted")

    references = (
        control_event_forbidden_references(architecture_result)
        | control_event_forbidden_references(architecture_manifest)
    )
    for relative in sorted(references):
        errors.append(
            f"{debt_id} architecture evidence references a "
            f"boundary-generated artifact: {relative}")

    gate_ids = {
        "DI-1", "DI-2", "DI-3", "DI-4", "DI-5",
        "OOO-1", "OOO-2", "OOO-3", "OOO-4",
    }
    gates = architecture_result.get("gates")
    if not (
        architecture_result.get("schema")
            == "npc-rv64-architecture-hard-gates-result-v2"
        and architecture_result.get("overall_status") == "GREEN"
        and architecture_result.get("exit_code") == 0
        and architecture_result.get("rtl_source_set") == expected_rtl
        and architecture_result.get("evidence_errors") == []
        and isinstance(gates, dict)
        and set(gates) == gate_ids
        and all(
            isinstance(gate, dict) and gate.get("status") == "GREEN"
            for gate in gates.values()
        )
    ):
        errors.append(f"{debt_id} directed architecture result drifted")
    if not (
        architecture_manifest.get("schema")
            == "npc-rv64-architecture-directed-suite-v2"
        and architecture_manifest.get("design_id") == bound_design_id
        and isinstance(architecture_manifest.get("tests"), dict)
        and len(architecture_manifest["tests"]) == 9
    ):
        errors.append(f"{debt_id} architecture manifest drifted")
    return errors


def validate_control_event_payload(
    root: pathlib.Path,
    index: dict[str, Any],
    mutations: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    """Validate the frozen CONTROL-EVENT-G1 counts and semantic boundaries."""

    debt_id = "CONTROL-EVENT-G1"
    errors: list[str] = []
    expected_index_keys = {
        "schema", "run_id", "generated_at_utc", "status", "claim_scope",
        "design_id", "rtl_source_set", "verification_source_set",
        "static_contract", "focused", "config_variants", "rtl_mutations",
        "module_aggregate", "architecture_hard_gates", "contract_gate",
        "full_core_boundary", "provenance", "provenance_sha256",
    }
    if set(index) != expected_index_keys:
        errors.append(f"{debt_id} evidence-index field set drifted")
    if set(mutations) != CONTROL_EVENT_MUTATION_TOP_LEVEL_KEYS:
        errors.append(f"{debt_id} mutation-summary field set drifted")

    forbidden_references = (
        control_event_forbidden_references(index)
        | control_event_forbidden_references(mutations)
    )
    for relative in sorted(forbidden_references):
        errors.append(
            f"{debt_id} self-referential artifact is forbidden: {relative}")

    if not (
        index.get("schema") == CONTROL_EVENT_INDEX_SCHEMA
        and index.get("run_id") == CONTROL_EVENT_RUN_ID
        and index.get("status") == "PASS"
        and index.get("claim_scope")
            == "CONTROL-EVENT-G1 current-design review candidate"
        and index.get("design_id") == bound_design_id
    ):
        errors.append(f"{debt_id} evidence-index identity/status drifted")

    provenance = index.get("provenance")
    if not (
        isinstance(provenance, dict)
        and set(provenance) == CONTROL_EVENT_PROVENANCE_PATHS
        and all(
            isinstance(record, dict)
            and set(record) == {"path", "sha256", "size_bytes"}
            and record.get("path") == relative
            for relative, record in provenance.items()
        )
    ):
        errors.append(f"{debt_id} exact provenance inventory drifted")

    rtl_source_set = index.get("rtl_source_set")
    rtl_files = (
        rtl_source_set.get("files")
        if isinstance(rtl_source_set, dict) else None
    )
    if not (
        isinstance(rtl_source_set, dict)
        and set(rtl_source_set)
            == {"design_id", "file_count", "files", "sha256"}
        and rtl_source_set.get("design_id") == bound_design_id
        and rtl_source_set.get("sha256")
            == bound_design_id.removeprefix("sha256:")
        and isinstance(rtl_files, dict)
        and rtl_source_set.get("file_count") == len(rtl_files)
        and all(
            isinstance(path, str)
            and isinstance(digest, str)
            and SHA256_RE.fullmatch(digest)
            for path, digest in rtl_files.items()
        )
    ):
        errors.append(f"{debt_id} exact RTL source set drifted")

    verification_source_set = index.get("verification_source_set")
    verification_files = (
        verification_source_set.get("files")
        if isinstance(verification_source_set, dict) else None
    )
    verification_sha = (
        verification_source_set.get("sha256")
        if isinstance(verification_source_set, dict) else None
    )
    if not (
        isinstance(verification_source_set, dict)
        and set(verification_source_set)
            == {"file_count", "files", "sha256"}
        and isinstance(verification_files, dict)
        and verification_source_set.get("file_count") == len(verification_files)
        and isinstance(verification_sha, str)
        and SHA256_RE.fullmatch(verification_sha)
        and all(
            isinstance(path, str)
            and isinstance(digest, str)
            and SHA256_RE.fullmatch(digest)
            for path, digest in verification_files.items()
        )
    ):
        errors.append(f"{debt_id} exact verification source set drifted")

    if index.get("static_contract") != CONTROL_EVENT_STATIC_CONTRACT:
        errors.append(f"{debt_id} static source contract is incomplete")

    focused = index.get("focused")
    focused_logs = focused.get("logs") if isinstance(focused, dict) else None
    if not (
        isinstance(focused, dict)
        and set(focused) == {"required", "passed", "logs"}
        and focused.get("required") == 10
        and focused.get("passed") == 10
        and isinstance(focused_logs, dict)
        and set(focused_logs) == CONTROL_EVENT_FOCUSED_TESTS
        and all(
            isinstance(record, dict)
            and set(record) == {"path", "sha256", "size_bytes"}
            and record.get("path") == (
                f".github/task-runs/{CONTROL_EVENT_RUN_ID}/focused/logs/"
                f"{test_name}.log"
            )
            for test_name, record in focused_logs.items()
        )
        and len({
            record["path"] for record in focused_logs.values()
        }) == len(focused_logs)
    ):
        errors.append(f"{debt_id} focused 10/10 inventory drifted")

    config = index.get("config_variants")
    config_logs = config.get("logs") if isinstance(config, dict) else None
    if not (
        isinstance(config, dict)
        and set(config)
            == {"configuration", "required", "passed", "logs"}
        and config.get("configuration") == "OOO_CSR_QUEUE_HEAD=1"
        and config.get("required") == 3
        and config.get("passed") == 3
        and isinstance(config_logs, dict)
        and set(config_logs) == CONTROL_EVENT_CONFIG_TESTS
        and all(
            isinstance(record, dict)
            and set(record) == {"path", "sha256", "size_bytes"}
            and record.get("path") == (
                f".github/task-runs/{CONTROL_EVENT_RUN_ID}/"
                f"config-variants/logs/{test_name}.log"
            )
            for test_name, record in config_logs.items()
        )
        and len({
            record["path"] for record in config_logs.values()
        }) == len(config_logs)
    ):
        errors.append(f"{debt_id} CSR queue-head 3/3 inventory drifted")

    module = index.get("module_aggregate")
    module_inventory = (
        module.get("inventory") if isinstance(module, dict) else None
    )
    module_logs = module.get("logs") if isinstance(module, dict) else None
    try:
        makefile_path, makefile_error = safe_regular_file(
            root, "npc/rv64/testbench/Makefile")
        if makefile_error or makefile_path is None:
            raise ValueError(makefile_error or "module Makefile is missing")
        required_tests, inventory_errors = parse_required_tests(
            makefile_path.read_text(encoding="utf-8"))
        if inventory_errors:
            raise ValueError("; ".join(inventory_errors))
    except (OSError, ValueError) as exc:
        required_tests = []
        errors.append(
            f"{debt_id} cannot derive current module inventory: {exc}")
    if not (
        isinstance(module, dict)
        and bool(required_tests)
        and module.get("required") == len(required_tests)
        and module.get("passed") == len(required_tests)
        and module.get("failed") == 0
        and isinstance(module_inventory, list)
        and len(module_inventory) == len(required_tests)
        and len(set(module_inventory)) == len(required_tests)
        and set(module_inventory) == set(required_tests)
        and isinstance(module_logs, dict)
        and set(module_logs) == set(module_inventory)
        and all(
            isinstance(record, dict)
            and set(record) == {"path", "sha256", "size_bytes"}
            and record.get("path") == (
                f".github/task-runs/{CONTROL_EVENT_RUN_ID}/"
                f"module-aggregate-current/logs/{test_name}.log"
            )
            for test_name, record in module_logs.items()
        )
        and len({
            record["path"] for record in module_logs.values()
        }) == len(module_logs)
        and {
            "tb_ooo_control_event_apply_sequencer",
            "tb_ooo_rob",
            "tb_ooo_mem_axi_bridge",
        } <= set(module_inventory)
    ):
        errors.append(f"{debt_id} exact current module aggregate drifted")

    mutation_index = index.get("rtl_mutations")
    mutation_logs = (
        mutation_index.get("logs")
        if isinstance(mutation_index, dict) else None
    )
    mutation_summary = (
        mutation_index.get("summary")
        if isinstance(mutation_index, dict) else None
    )
    if not (
        isinstance(mutation_index, dict)
        and mutation_index.get("required") == 11
        and mutation_index.get("compile_success") == 11
        and mutation_index.get("rejected") == 11
        and mutation_index.get("dynamic_rejected") == 10
        and mutation_index.get("lint_rejected") == 1
        and isinstance(mutation_logs, dict)
        and set(mutation_logs) == CONTROL_EVENT_MUTATIONS
        and all(
            isinstance(record, dict)
            and set(record) == {"path", "sha256", "size_bytes"}
            and record.get("path") == (
                f".github/task-runs/{CONTROL_EVENT_RUN_ID}/mutations/logs/"
                f"{name}.log"
            )
            for name, record in mutation_logs.items()
        )
        and len({
            record["path"] for record in mutation_logs.values()
        }) == len(mutation_logs)
        and isinstance(mutation_summary, dict)
        and mutation_summary.get("path") == CONTROL_EVENT_MUTATION_PATH
    ):
        errors.append(f"{debt_id} mutation index 11/11 drifted")

    architecture = index.get("architecture_hard_gates")
    architecture_result_record = (
        architecture.get("result") if isinstance(architecture, dict) else None
    )
    architecture_manifest_record = (
        architecture.get("manifest") if isinstance(architecture, dict) else None
    )
    architecture_refresh_record = (
        architecture.get("refresh_log")
        if isinstance(architecture, dict) else None
    )
    if not (
        isinstance(architecture, dict)
        and set(architecture) == {
            "required", "green", "negative_unit_tests",
            "result", "manifest", "refresh_log",
        }
        and architecture.get("required") == 9
        and architecture.get("green") == 9
        and architecture.get("negative_unit_tests") == 30
        and isinstance(architecture_result_record, dict)
        and set(architecture_result_record) == {"path", "sha256", "size_bytes"}
        and architecture_result_record.get("path")
            == CONTROL_EVENT_ARCHITECTURE_RESULT_PATH
        and isinstance(architecture_manifest_record, dict)
        and set(architecture_manifest_record)
            == {"path", "sha256", "size_bytes"}
        and architecture_manifest_record.get("path")
            == CONTROL_EVENT_ARCHITECTURE_MANIFEST_PATH
        and isinstance(architecture_refresh_record, dict)
        and set(architecture_refresh_record)
            == {"path", "sha256", "size_bytes"}
        and architecture_refresh_record.get("path")
            == CONTROL_EVENT_ARCHITECTURE_REFRESH_LOG_PATH
    ):
        errors.append(f"{debt_id} directed architecture 9/9 binding drifted")

    if index.get("contract_gate") != {
        "holder_census": "PASS",
        "immediate_assertions": 471,
        "unit_tests": 13,
    }:
        errors.append(f"{debt_id} RTL contract gate counts drifted")

    boundary = index.get("full_core_boundary")
    if not (
        isinstance(boundary, dict)
        and set(boundary) == {
            "architecture_freeze", "blockers", "ppa",
            "promotion_eligible", "candidate_design_id",
            "current_design_match",
        }
        and boundary.get("architecture_freeze") == "GAP"
        and isinstance(boundary.get("blockers"), int)
        and boundary.get("blockers", 0) > 0
        and boundary.get("ppa") == "UNQUALIFIED"
        and boundary.get("promotion_eligible") is False
        and boundary.get("current_design_match") is True
        and boundary.get("candidate_design_id") == bound_design_id
    ):
        errors.append(f"{debt_id} full-core GAP/PPA boundary drifted")

    results = mutations.get("results")
    result_names = {
        item.get("name")
        for item in results
        if isinstance(item, dict) and isinstance(item.get("name"), str)
    } if isinstance(results, list) else set()
    dynamic_count = sum(
        1 for item in results
        if isinstance(item, dict)
        and item.get("dynamic_rejected") is True
    ) if isinstance(results, list) else 0
    lint_count = sum(
        1 for item in results
        if isinstance(item, dict)
        and item.get("lint_rejected") is True
    ) if isinstance(results, list) else 0
    mutation_contracts_ok = (
        isinstance(results, list)
        and all(
            isinstance(item, dict)
            and set(item) == CONTROL_EVENT_MUTATION_RESULT_KEYS
            and isinstance(item.get("name"), str)
            and item["name"] in CONTROL_EVENT_MUTATION_CONTRACTS
            and item.get("source")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]]["source"]
            and item.get("test_name")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]]["test_name"]
            and item.get("make_variable")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]][
                    "make_variable"
                ]
            and item.get("rejection_mode")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]][
                    "rejection_mode"
                ]
            and item.get("make_returncode")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]][
                    "make_returncode"
                ]
            and item.get("lint_returncode")
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]][
                    "lint_returncode"
                ]
            and tuple(item.get("expected_markers", ()))
                == CONTROL_EVENT_MUTATION_CONTRACTS[item["name"]][
                    "expected_markers"
                ]
            and item.get("observed_markers") == {
                marker: True
                for marker in CONTROL_EVENT_MUTATION_CONTRACTS[
                    item["name"]
                ]["expected_markers"]
            }
            and isinstance(item.get("log"), dict)
            and set(item["log"]) == {"path", "sha256"}
            and item["log"].get("path") == (
                f".github/task-runs/{CONTROL_EVENT_RUN_ID}/mutations/logs/"
                f"{item['name']}.log"
            )
            and isinstance(item.get("purpose"), str)
            and bool(item["purpose"].strip())
            and isinstance(item.get("oracle_family"), str)
            and bool(item["oracle_family"].strip())
            and item.get("extra_ivflags") == (
                ["-DOOO_CSR_QUEUE_HEAD=1"]
                if item["name"] in CONTROL_EVENT_CSR_QUEUE_HEAD_MUTATIONS
                else []
            )
            and isinstance(item.get("original_sha256"), str)
            and SHA256_RE.fullmatch(item["original_sha256"])
            and isinstance(rtl_files, dict)
            and item["original_sha256"] == rtl_files.get(item["source"])
            and isinstance(item.get("mutation_sha256"), str)
            and SHA256_RE.fullmatch(item["mutation_sha256"])
            and item["mutation_sha256"] != item["original_sha256"]
            for item in results
        )
    )
    mutation_sources = {
        contract["source"]
        for contract in CONTROL_EVENT_MUTATION_CONTRACTS.values()
    }
    source_sha256_before = mutations.get("source_sha256_before")
    source_sha256_after = mutations.get("source_sha256_after")
    mutation_source_maps_ok = (
        isinstance(source_sha256_before, dict)
        and isinstance(source_sha256_after, dict)
        and set(source_sha256_before) == mutation_sources
        and source_sha256_after == source_sha256_before
        and isinstance(rtl_files, dict)
        and all(
            source_sha256_before.get(relative) == rtl_files.get(relative)
            for relative in mutation_sources
        )
    )
    mutation_baseline = mutations.get("baseline_lint")
    index_baseline = (
        mutation_index.get("baseline_lint")
        if isinstance(mutation_index, dict) else None
    )
    mutation_baseline_ok = (
        isinstance(mutation_baseline, dict)
        and set(mutation_baseline) == {"path", "returncode", "sha256"}
        and mutation_baseline.get("path") == (
            f".github/task-runs/{CONTROL_EVENT_RUN_ID}/"
            "mutations/baseline-verilator.log"
        )
        and mutation_baseline.get("returncode") == 0
        and isinstance(mutation_baseline.get("sha256"), str)
        and SHA256_RE.fullmatch(mutation_baseline["sha256"])
        and isinstance(index_baseline, dict)
        and mutation_baseline.get("path") == index_baseline.get("path")
        and mutation_baseline.get("sha256") == index_baseline.get("sha256")
    )
    results_ok = (
        isinstance(results, list)
        and len(results) == 11
        and result_names == CONTROL_EVENT_MUTATIONS
        and dynamic_count == 10
        and lint_count == 1
        and mutation_contracts_ok
        and all(
            isinstance(item, dict)
            and item.get("compile_success") is True
            and item.get("rejected") is True
            and (
                (
                    item.get("rejection_mode") == "dynamic"
                    and item.get("dynamic_rejected") is True
                    and item.get("lint_rejected") is False
                )
                or (
                    item.get("rejection_mode") == "lint-unoptflat"
                    and item.get("dynamic_rejected") is False
                    and item.get("lint_rejected") is True
                )
            )
            for item in results
        )
    )
    if not (
        mutations.get("schema") == CONTROL_EVENT_MUTATION_SCHEMA
        and mutations.get("suite_run_id") == CONTROL_EVENT_RUN_ID
        and mutations.get("design_id") == bound_design_id
        and mutations.get("required") == 11
        and mutations.get("compile_success") == 11
        and mutations.get("rejected") == 11
        and mutations.get("dynamic_rejected") == 10
        and mutations.get("lint_rejected") == 1
        and mutations.get("baseline_unoptflat") is False
        and mutations.get("source_unchanged") is True
        and mutations.get("full_rtl_source_unchanged") is True
        and mutations.get("verification_source_unchanged") is True
        and mutation_source_maps_ok
        and mutation_baseline_ok
        and mutations.get("rtl_source_set") == rtl_source_set
        and mutations.get("verification_source_set")
            == verification_source_set
        and results_ok
    ):
        errors.append(
            f"{debt_id} compile-success RTL mutation semantics drifted")
    return errors


def _validate_legacy_v9r_sq_retry_c0_payload(
    root: pathlib.Path,
    payload: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    """Validate the V9R C0 SQ-query retry owner-transfer evidence."""

    debt_id = "CONTROL-EVENT-G1"
    errors: list[str] = []
    expected_keys = {
        "schema", "result", "design_id", "full_rtl_source_unchanged",
        "rtl_design_id_before", "rtl_design_id_after", "source_binding",
        "positive", "baseline", "compile_success_rtl_variants",
        "promotion_eligible", "ppa_status",
    }
    if set(payload) != expected_keys:
        errors.append(f"{debt_id} V9R summary field set drifted")

    if not (
        payload.get("schema") == V9R_SQ_RETRY_SCHEMA
        and payload.get("result") == "PASS"
        and payload.get("design_id") == bound_design_id
        and payload.get("full_rtl_source_unchanged") is True
        and payload.get("rtl_design_id_before") == bound_design_id
        and payload.get("rtl_design_id_after") == bound_design_id
        and payload.get("promotion_eligible") is False
        and payload.get("ppa_status") == "diagnostic_unqualified"
    ):
        errors.append(f"{debt_id} V9R identity/status boundary drifted")

    artifact_paths: set[str] = set()

    def check_artifact(
        record: Any,
        expected_path: str,
        label: str,
    ) -> pathlib.Path | None:
        if not isinstance(record, dict) or set(record) != {
            "path", "sha256", "size_bytes",
        }:
            errors.append(f"{debt_id} V9R malformed artifact: {label}")
            return None
        if record.get("path") != expected_path:
            errors.append(f"{debt_id} V9R artifact path drifted: {label}")
            return None
        path, error = safe_regular_file(root, record.get("path"))
        if (
            error
            or path is None
            or record.get("sha256") != sha256_file(path)
            or record.get("size_bytes") != path.stat().st_size
        ):
            errors.append(
                error or f"{debt_id} V9R artifact hash drifted: {label}")
            return None
        if expected_path in artifact_paths:
            errors.append(
                f"{debt_id} V9R artifact path reused: {expected_path}")
        artifact_paths.add(expected_path)
        return path

    source_binding = payload.get("source_binding")
    source_files = (
        source_binding.get("files")
        if isinstance(source_binding, dict) else None
    )
    source_records_ok = (
        isinstance(source_binding, dict)
        and set(source_binding) == {"sha256", "file_count", "files"}
        and source_binding.get("file_count")
            == len(V9R_SQ_RETRY_SOURCE_PATHS)
        and isinstance(source_files, dict)
        and set(source_files) == V9R_SQ_RETRY_SOURCE_PATHS
    )
    if not source_records_ok:
        errors.append(f"{debt_id} V9R exact source binding drifted")
    elif isinstance(source_files, dict):
        for relative in sorted(V9R_SQ_RETRY_SOURCE_PATHS):
            check_artifact(
                source_files.get(relative),
                relative,
                f"source:{relative}",
            )
        if source_binding.get("sha256") != canonical_sha256(source_files):
            errors.append(f"{debt_id} V9R source binding hash drifted")

    if payload.get("positive") != {
        "backend_banks": 2,
        "forced_barrier_cases": 2,
        "natural_trap_head_cases": 1,
        "bridge_query_hold_cases": 1,
        "barrier_release_cases": 1,
    }:
        errors.append(f"{debt_id} V9R positive coverage drifted")

    baseline = payload.get("baseline")
    baseline_tests = (
        baseline.get("tests") if isinstance(baseline, dict) else None
    )
    if not (
        isinstance(baseline, dict)
        and set(baseline) == {"required", "passed", "tests", "status"}
        and baseline.get("required") == 2
        and baseline.get("passed") == 2
        and isinstance(baseline_tests, dict)
        and set(baseline_tests) == set(V9R_SQ_RETRY_BASELINE_MARKERS)
    ):
        errors.append(f"{debt_id} V9R baseline inventory drifted")
    else:
        prefix = (
            f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/"
            "evidence/baseline"
        )
        status_path = check_artifact(
            baseline.get("status"),
            f"{prefix}/status",
            "baseline-status",
        )
        if status_path is not None and status_path.read_text(
            encoding="utf-8"
        ) != "PASS\n":
            errors.append(f"{debt_id} V9R baseline status drifted")
        for test_name, markers in V9R_SQ_RETRY_BASELINE_MARKERS.items():
            record = baseline_tests.get(test_name)
            if not isinstance(record, dict) or set(record) != {
                "compiled_image", "log",
            }:
                errors.append(
                    f"{debt_id} V9R baseline record drifted: {test_name}")
                continue
            check_artifact(
                record.get("compiled_image"),
                f"{prefix}/build/{test_name}.vvp",
                f"baseline-image:{test_name}",
            )
            log_path = check_artifact(
                record.get("log"),
                f"{prefix}/result/logs/{test_name}.log",
                f"baseline-log:{test_name}",
            )
            if log_path is None:
                continue
            text = log_path.read_text(encoding="utf-8")
            required = (
                "[RESULT] PASS",
                f"[RTL-DESIGN-ID] {bound_design_id}",
                *markers,
            )
            if (
                any(text.count(marker) != 1 for marker in required)
                or any(marker in text for marker in (
                    "[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:",
                ))
            ):
                errors.append(
                    f"{debt_id} V9R baseline markers drifted: {test_name}")

    variants = payload.get("compile_success_rtl_variants")
    variant_by_id = {
        item.get("id"): item
        for item in variants
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    } if isinstance(variants, list) else {}
    if not (
        isinstance(variants, list)
        and len(variants) == len(V9R_SQ_RETRY_VARIANTS)
        and len(variant_by_id) == len(variants)
        and set(variant_by_id) == set(V9R_SQ_RETRY_VARIANTS)
    ):
        errors.append(f"{debt_id} V9R variant inventory drifted")
    else:
        expected_variant_keys = {
            "id", "production_source", "test_name", "result",
            "make_returncode", "assertion_marker", "mutated_rtl",
            "compiled_image", "log", "status",
        }
        for case_id, contract in V9R_SQ_RETRY_VARIANTS.items():
            item = variant_by_id[case_id]
            test_name = contract["test_name"]
            prefix = (
                f".github/task-runs/{V9R_SQ_RETRY_RUN_ID}/"
                f"evidence/{case_id}"
            )
            if not (
                set(item) == expected_variant_keys
                and item.get("production_source")
                    == contract["production_source"]
                and item.get("test_name") == test_name
                and item.get("result") == "REJECTED"
                and item.get("make_returncode") == 2
                and item.get("assertion_marker")
                    == contract["assertion_marker"]
            ):
                errors.append(
                    f"{debt_id} V9R variant contract drifted: {case_id}")
                continue
            mutant_path = check_artifact(
                item.get("mutated_rtl"),
                f"{prefix}/{contract['mutated_rtl']}",
                f"variant-rtl:{case_id}",
            )
            check_artifact(
                item.get("compiled_image"),
                f"{prefix}/build/{test_name}.vvp",
                f"variant-image:{case_id}",
            )
            log_path = check_artifact(
                item.get("log"),
                f"{prefix}/result/logs/{test_name}.log",
                f"variant-log:{case_id}",
            )
            status_path = check_artifact(
                item.get("status"),
                f"{prefix}/status",
                f"variant-status:{case_id}",
            )
            production_path, production_error = safe_regular_file(
                root, contract["production_source"])
            if (
                mutant_path is None
                or production_error
                or production_path is None
                or sha256_file(mutant_path) == sha256_file(production_path)
            ):
                errors.append(
                    production_error
                    or f"{debt_id} V9R mutation is not source-changing: "
                    f"{case_id}"
                )
            if status_path is not None and status_path.read_text(
                encoding="utf-8"
            ) != "REJECTED_COMPILE_SUCCESS_VARIANT rc=2\n":
                errors.append(
                    f"{debt_id} V9R variant status drifted: {case_id}")
            if log_path is not None:
                text = log_path.read_text(encoding="utf-8")
                if (
                    "[COMPILE]" not in text
                    or text.count(contract["assertion_marker"]) != 1
                    or text.count("[RESULT] FAIL") != 1
                    or "[RESULT] PASS" in text
                ):
                    errors.append(
                        f"{debt_id} V9R rejection markers drifted: "
                        f"{case_id}"
                    )
    return errors


def _validate_legacy_control_event_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate the current-design CONTROL-EVENT-G1 evidence."""

    del expected_design_id  # Cohort equality is checked by closed_binding.
    debt_id = "CONTROL-EVENT-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != CONTROL_EVENT_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")

    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_evidence = {
        "control_event_evidence_index": CONTROL_EVENT_INDEX_PATH,
        "control_event_rtl_mutations": CONTROL_EVENT_MUTATION_PATH,
        "v9r_sq_retry_c0_evidence": V9R_SQ_RETRY_SUMMARY_PATH,
    }
    if (
        len(evidence_list) != len(expected_evidence)
        or set(by_kind) != set(expected_evidence)
        or any(
            by_kind[kind].get("path") != path
            for kind, path in expected_evidence.items()
        )
    ):
        errors.append(
            f"{debt_id} requires exact V9O index/mutation and V9R artifacts")
        return errors

    resolved: dict[str, pathlib.Path] = {}
    for kind, expected_path in expected_evidence.items():
        item = by_kind[kind]
        path, error = safe_regular_file(root, item.get("path"))
        if (
            error
            or path is None
            or set(item) != {"kind", "path", "sha256"}
            or item.get("path") != expected_path
            or item.get("sha256") != sha256_file(path)
        ):
            errors.append(error or f"{debt_id} {kind} hash/path drifted")
        elif path is not None:
            resolved[kind] = path
    if len(resolved) != len(expected_evidence):
        return errors

    try:
        index = load_json(resolved["control_event_evidence_index"])
        mutations = load_json(resolved["control_event_rtl_mutations"])
        v9r_sq_retry = load_json(resolved["v9r_sq_retry_c0_evidence"])
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot load evidence JSON: {exc}")
        return errors

    bound_design_id = entry.get("design_id")
    if not isinstance(bound_design_id, str) or not DESIGN_ID_RE.fullmatch(
        bound_design_id
    ):
        errors.append(f"{debt_id} ledger design id is invalid")
        return errors
    errors.extend(
        validate_control_event_payload(
            root, index, mutations, bound_design_id))
    errors.extend(
        _validate_legacy_v9r_sq_retry_c0_payload(
            root,
            v9r_sq_retry,
            bound_design_id,
        )
    )

    canonical_payload = dict(index)
    declared_provenance_sha = canonical_payload.pop(
        "provenance_sha256", None)
    if declared_provenance_sha != canonical_sha256(canonical_payload):
        errors.append(f"{debt_id} evidence-index provenance hash is invalid")

    try:
        source_helper = load_workspace_module(
            root, CONTROL_EVENT_SOURCE_HELPER, "control_event_source_set")
        rtl_sha, rtl_files = source_helper.rtl_binding(root)
        verification_sha, verification_files = (
            source_helper.verification_binding(root)
        )
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(f"{debt_id} cannot recompute source sets: {exc}")
        rtl_sha, rtl_files = "", {}
        verification_sha, verification_files = "", {}
    expected_rtl = {
        "design_id": f"sha256:{rtl_sha}",
        "file_count": len(rtl_files),
        "files": rtl_files,
        "sha256": rtl_sha,
    }
    expected_verification = {
        "file_count": len(verification_files),
        "files": verification_files,
        "sha256": verification_sha,
    }
    if (
        index.get("rtl_source_set") != expected_rtl
        or bound_design_id != f"sha256:{rtl_sha}"
        or mutations.get("rtl_source_set") != expected_rtl
    ):
        errors.append(f"{debt_id} live RTL source binding is stale")
    if (
        index.get("verification_source_set") != expected_verification
        or mutations.get("verification_source_set") != expected_verification
    ):
        errors.append(f"{debt_id} live verification source binding is stale")

    live_inventory: list[str] = []
    inventory_is_valid = False
    makefile_path, makefile_error = safe_regular_file(
        root, "npc/rv64/testbench/Makefile")
    if makefile_error or makefile_path is None:
        errors.append(
            makefile_error or f"{debt_id} test inventory Makefile is missing")
    else:
        live_inventory, inventory_errors = parse_required_tests(
            makefile_path.read_text(encoding="utf-8"))
        inventory_is_valid = not inventory_errors
        indexed_inventory = index.get(
            "module_aggregate", {}).get("inventory")
        if inventory_errors or indexed_inventory != live_inventory:
            errors.append(
                f"{debt_id} live module inventory drifted: "
                + "; ".join(inventory_errors[:2]))

    indexed_artifacts: dict[str, str] = {}

    def validate_indexed_artifacts(value: Any) -> None:
        if isinstance(value, dict):
            artifact_keys = {"path", "sha256", "size_bytes"}
            if artifact_keys <= set(value):
                relative = value.get("path")
                if relative in CONTROL_EVENT_FORBIDDEN_ARTIFACT_PATHS:
                    errors.append(
                        f"{debt_id} self-referential artifact is forbidden: "
                        f"{relative}")
                    return
                path, error = safe_regular_file(root, relative)
                if (
                    set(value) != artifact_keys
                    or error
                    or path is None
                    or value.get("sha256") != sha256_file(path)
                    or value.get("size_bytes") != path.stat().st_size
                ):
                    errors.append(
                        error or f"{debt_id} indexed artifact drifted: {relative}")
                elif isinstance(relative, str):
                    previous = indexed_artifacts.setdefault(
                        relative, value["sha256"])
                    if previous != value["sha256"]:
                        errors.append(
                            f"{debt_id} conflicting artifact id: {relative}")
            for child in value.values():
                validate_indexed_artifacts(child)
        elif isinstance(value, list):
            for child in value:
                validate_indexed_artifacts(child)

    validate_indexed_artifacts(index)
    expected_artifact_count = (
        len(CONTROL_EVENT_FOCUSED_TESTS)
        + len(CONTROL_EVENT_CONFIG_TESTS)
        + len(CONTROL_EVENT_MUTATIONS)
        + len(CONTROL_EVENT_PROVENANCE_PATHS)
        + len(live_inventory)
        + 7
    )
    if (
        inventory_is_valid
        and len(indexed_artifacts) != expected_artifact_count
    ):
        errors.append(
            f"{debt_id} exact artifact count drifted: "
            f"expected={expected_artifact_count} "
            f"observed={len(indexed_artifacts)}")

    verification_id = (
        index.get("verification_source_set", {}).get("sha256")
        if isinstance(index.get("verification_source_set"), dict) else None
    )
    log_groups = (
        index.get("focused", {}).get("logs"),
        index.get("config_variants", {}).get("logs"),
        index.get("module_aggregate", {}).get("logs"),
    )
    for records in log_groups:
        if not isinstance(records, dict):
            continue
        for test_name, record in records.items():
            relative = record.get("path") if isinstance(record, dict) else None
            path, error = safe_regular_file(root, relative)
            if error or path is None:
                errors.append(
                    error or f"{debt_id} missing PASS log for {test_name}")
                continue
            text = path.read_text(encoding="utf-8")
            required_markers = (
                "[RESULT] PASS",
                f"[RTL-DESIGN-ID] {bound_design_id}",
                f"[V9O-VERIFICATION-SOURCE-ID] sha256:{verification_id}",
            )
            native_pass_lines = [
                line
                for line in text.splitlines()
                if line in {f"[PASS] {test_name}", f"PASS {test_name}"}
            ]
            if (
                any(text.count(marker) != 1 for marker in required_markers)
                or len(native_pass_lines) != 1
                or any(marker in text for marker in (
                    "[RESULT] FAIL", "[CHECK-FAIL]", "[TIMEOUT]", "FATAL:",
                ))
            ):
                errors.append(
                    f"{debt_id} PASS/source markers drifted: {relative}")

    for relative, markers in CONTROL_EVENT_CRITICAL_LOG_MARKERS.items():
        path, error = safe_regular_file(root, relative)
        if error or path is None:
            errors.append(error or f"{debt_id} critical log is missing")
            continue
        text = path.read_text(encoding="utf-8")
        if any(text.count(marker) != 1 for marker in markers):
            errors.append(
                f"{debt_id} critical RTL marker drifted: {relative}")

    results = mutations.get("results")
    if isinstance(results, list):
        for result in results:
            if not isinstance(result, dict):
                continue
            log = result.get("log")
            relative = log.get("path") if isinstance(log, dict) else None
            path, error = safe_regular_file(root, relative)
            if (
                error
                or path is None
                or not isinstance(log, dict)
                or log.get("sha256") != sha256_file(path)
            ):
                errors.append(
                    error or f"{debt_id} mutation log drifted: {relative}")
                continue
            text = path.read_text(encoding="utf-8")
            expected_markers = result.get("expected_markers")
            if (
                not isinstance(expected_markers, list)
                or not expected_markers
                or any(
                    not isinstance(marker, str) or text.count(marker) != 1
                    for marker in expected_markers
                )
            ):
                errors.append(
                    f"{debt_id} mutation oracle marker drifted: {relative}")

    baseline = index.get("rtl_mutations", {}).get("baseline_lint")
    baseline_path, baseline_error = safe_regular_file(
        root, baseline.get("path") if isinstance(baseline, dict) else None)
    if (
        baseline_error
        or baseline_path is None
        or "%Warning-UNOPTFLAT" in baseline_path.read_text(
            encoding="utf-8", errors="replace")
    ):
        errors.append(
            baseline_error
            or f"{debt_id} baseline unexpectedly contains UNOPTFLAT")

    architecture_record = index.get(
        "architecture_hard_gates", {}).get("result")
    manifest_record = index.get(
        "architecture_hard_gates", {}).get("manifest")
    try:
        architecture_result = load_json(
            root / architecture_record["path"])
        architecture_manifest = load_json(root / manifest_record["path"])
        candidate = load_json(
            root / "npc/rv64/eval/ppa/arch-stable/full-core-current.json")
    except (KeyError, TypeError, OSError, ValueError, json.JSONDecodeError) as exc:
        errors.append(f"{debt_id} cannot load architecture artifacts: {exc}")
        return errors

    errors.extend(validate_control_event_architecture_payload(
        architecture_result,
        architecture_manifest,
        expected_rtl,
        bound_design_id,
    ))
    boundary = index.get("full_core_boundary")
    if not (
        isinstance(boundary, dict)
        and candidate.get("schema") == CANDIDATE_SCHEMA
        and boundary.get("candidate_design_id") == candidate.get("design_id")
    ):
        errors.append(f"{debt_id} live full-core candidate identity drifted")
    return errors


def validate_v9r_sq_retry_c0_payload(
    root: pathlib.Path,
    payload: dict[str, Any],
    bound_design_id: str,
) -> list[str]:
    """Validate compact current-design SQ-query retry evidence."""

    try:
        tool = load_workspace_module(
            root,
            CONTROL_EVENT_SQ_RETRY_TOOL_PATH,
            "control_event_sq_retry_evidence",
        )
        if (
            tool.RESULT_PATH != V9R_SQ_RETRY_CURRENT_RESULT_PATH
            or not isinstance(tool.CANONICAL_COMMAND, str)
        ):
            return ["CONTROL-EVENT-G1 V9R checker contract drifted"]
        delegated = tool.validate_payload(root, payload, bound_design_id)
    except (OSError, ValueError, AttributeError, TypeError) as exc:
        return [f"CONTROL-EVENT-G1 cannot validate V9R evidence: {exc}"]
    return [f"CONTROL-EVENT-G1 V9R {error}" for error in delegated]


def validate_control_event_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Validate the compact, current-design CONTROL-EVENT evidence pair."""

    del expected_design_id  # Cohort equality is checked by closed_binding.
    debt_id = "CONTROL-EVENT-G1"
    errors: list[str] = []
    if entry.get("canonical_command") != CONTROL_EVENT_CURRENT_COMMAND:
        errors.append(f"{debt_id} canonical command drifted")

    bound_design_id = entry.get("design_id")
    if (
        not isinstance(bound_design_id, str)
        or not DESIGN_ID_RE.fullmatch(bound_design_id)
    ):
        errors.append(f"{debt_id} ledger design id is invalid")
        return errors

    expected_evidence = {
        "control_event_current_evidence": CONTROL_EVENT_CURRENT_RESULT_PATH,
        "v9r_sq_retry_c0_evidence": V9R_SQ_RETRY_CURRENT_RESULT_PATH,
    }
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    if (
        len(evidence_list) != len(expected_evidence)
        or set(by_kind) != set(expected_evidence)
        or any(
            by_kind[kind].get("path") != path
            for kind, path in expected_evidence.items()
        )
    ):
        errors.append(
            f"{debt_id} requires exact current V9O and V9R result artifacts"
        )
        return errors

    payloads: dict[str, dict[str, Any]] = {}
    for kind, relative in expected_evidence.items():
        record = by_kind[kind]
        path, error = safe_regular_file(root, record.get("path"))
        if (
            error
            or path is None
            or set(record) != {"kind", "path", "sha256"}
            or record.get("sha256") != sha256_file(path)
        ):
            errors.append(error or f"{debt_id} {kind} hash/path drifted")
            continue
        try:
            payloads[kind] = load_json(path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"{debt_id} cannot load {kind}: {exc}")
    if len(payloads) != len(expected_evidence):
        return errors

    try:
        current_tool = load_workspace_module(
            root,
            CONTROL_EVENT_CURRENT_TOOL_PATH,
            "control_event_current_evidence",
        )
        if current_tool.RESULT_PATH != CONTROL_EVENT_CURRENT_RESULT_PATH:
            errors.append(f"{debt_id} current checker contract drifted")
        errors.extend(
            f"{debt_id} V9O {error}"
            for error in current_tool.validate_payload(
                root,
                payloads["control_event_current_evidence"],
                bound_design_id,
            )
        )
    except (OSError, ValueError, AttributeError, TypeError) as exc:
        errors.append(f"{debt_id} cannot validate current evidence: {exc}")

    errors.extend(
        validate_v9r_sq_retry_c0_payload(
            root,
            payloads["v9r_sq_retry_c0_evidence"],
            bound_design_id,
        )
    )
    return errors


VECTORED_TRAP_RESULT_SCHEMA = "npc-rv64-vectored-trap-evidence-v1"
VECTORED_TRAP_COMMAND = "make -C npc/rv64 check-vectored-trap"
VECTORED_TRAP_FOCUSED_MARKER = (
    "[VECTORED-TRAP-G1-CSR-FILE] cases=13 warl=3 irq_routing=3 "
    "m_irq=2 m_sync=1 source_priority=2 s_irq=1 s_sync=1 PASS"
)
VECTORED_TRAP_PROGRAM_MARKERS = (
    "[VECTORED-TRAP-G2-M-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 "
    "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
    "wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
    "cause=7 handler_body=1 backend_drained=1 PASS",
    "[VECTORED-TRAP-G3-S-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 "
    "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
    "wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
    "cause=9 handler_body=1 backend_drained=1 PASS",
    "[VECTORED-TRAP-G4-M-SYNC] trap_mem=0 trap_ex=1 trap_irq=0 "
    "target_match=1 target_mismatch=0 exact_handler_fetch=1 "
    "wrong_vector_fetch=0 xret_request=1 xret_commit=1 return_commit=1 "
    "cause=11 handler_body=1 backend_drained=1 PASS",
)


def validate_vectored_trap_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Independently validate CsrFile vector targeting and full-core return."""

    errors: list[str] = []
    if entry.get("canonical_command") != VECTORED_TRAP_COMMAND:
        errors.append("VECTORED-TRAP-G1 canonical command drifted")
    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    if len(evidence_list) != 2 or set(by_kind) != {
        "vectored_trap_result", "raw_log",
    }:
        errors.append(
            "VECTORED-TRAP-G1 requires exact result/raw-log evidence")
        return errors

    result_path, result_error = safe_regular_file(
        root, by_kind["vectored_trap_result"].get("path"))
    raw_path, raw_error = safe_regular_file(
        root, by_kind["raw_log"].get("path"))
    if result_error or result_path is None:
        errors.append(result_error or "VECTORED-TRAP-G1 result is missing")
        return errors
    if raw_error or raw_path is None:
        errors.append(raw_error or "VECTORED-TRAP-G1 raw log is missing")
        return errors

    result = load_json(result_path)
    expected_metrics = {
        "focused": {
            "cases": 13,
            "warl_cases": 3,
            "irq_routing_cases": 3,
            "m_irq_cases": 2,
            "m_sync_cases": 1,
            "source_priority_cases": 2,
            "s_irq_cases": 1,
            "s_sync_cases": 1,
        },
        "full_core": {
            "m_irq_exact": 1,
            "s_irq_exact": 1,
            "m_sync_exact": 1,
            "raw_duplicate_terminal_events": 0,
            "wrong_target_fetches": 0,
            "xret_requests": 3,
            "xret_commits": 3,
            "return_commits": 3,
        },
        "mutations": {
            "required": 7,
            "compile_succeeded": 7,
            "dynamic_rejected": 7,
        },
        "csr_regression_passed": 1,
    }
    expected_invariants = {
        "tvec_modes_0_1_preserved": True,
        "tvec_modes_2_3_clamped_direct": True,
        "interrupt_target_is_base_plus_four_cause": True,
        "synchronous_target_is_base": True,
        "trap_source_priority_mem_ex_irq": True,
        "state_and_redirect_share_selected_record": True,
        "nondelegated_supervisor_interrupts_route_to_m": True,
        "assertions_enabled": True,
    }
    if not (
        result.get("schema") == VECTORED_TRAP_RESULT_SCHEMA
        and result.get("status") == "PASS"
        and result.get("design_id") == expected_design_id
        and result.get("canonical_command") == VECTORED_TRAP_COMMAND
        and result.get("metrics") == expected_metrics
        and result.get("invariants") == expected_invariants
        and result.get("claim") == {
            "scope": "local RV64 CsrFile and full OoO trap/return control path",
            "ppa": "UNQUALIFIED",
            "promotion_eligible": False,
        }
    ):
        errors.append(
            "VECTORED-TRAP-G1 metrics, invariants or PPA claim drifted")

    try:
        architecture = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "vectored_trap_architecture_binding",
        )
        rtl_sha, rtl_files = architecture.rtl_binding(root)
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(
            f"VECTORED-TRAP-G1 cannot recompute RTL binding: {exc}")
        rtl_sha, rtl_files = "", {}
    expected_source_set = {
        "design_id": expected_design_id,
        "sha256": expected_design_id.removeprefix("sha256:"),
        "file_count": len(rtl_files),
        "files": rtl_files,
    }
    if not (
        rtl_sha == expected_design_id.removeprefix("sha256:")
        and result.get("rtl_source_set") == expected_source_set
    ):
        errors.append("VECTORED-TRAP-G1 live RTL source binding is stale")

    artifacts = result.get("artifacts")
    artifact_list = artifacts if isinstance(artifacts, list) else []
    artifacts_by_kind = {
        item.get("kind"): item
        for item in artifact_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    expected_mutation_kinds = {
        f"mutation_log:{name}" for name in (
            "direct_only_target",
            "vector_sync_exception",
            "force_machine_tvec",
            "reserved_mode_passthrough",
            "exception_over_memory_priority",
            "vector_offset_plus_four",
            "drop_nondelegated_supervisor_irq",
        )
    }
    expected_artifact_kinds = {
        "focused_csr_log",
        "full_core_program_log",
        "csr_regression_log",
        "mutation_manifest",
        *expected_mutation_kinds,
    }
    artifact_paths: dict[str, pathlib.Path] = {}
    artifacts_ok = (
        len(artifact_list) == len(expected_artifact_kinds)
        and set(artifacts_by_kind) == expected_artifact_kinds
    )
    if artifacts_ok:
        for kind, item in artifacts_by_kind.items():
            path, error = safe_regular_file(root, item.get("path"))
            if error or path is None or item.get("sha256") != sha256_file(path):
                artifacts_ok = False
                break
            artifact_paths[kind] = path
    if not artifacts_ok:
        errors.append(
            "VECTORED-TRAP-G1 artifact inventory or hashes are incomplete")
        return errors

    design_marker = f"[RTL-DESIGN-ID] {expected_design_id}"
    positive_logs = (
        ("focused_csr_log", "tb_csr_file_vectored_trap",
         (VECTORED_TRAP_FOCUSED_MARKER,)),
        ("full_core_program_log", "tb_ooo_priv_system",
         VECTORED_TRAP_PROGRAM_MARKERS),
        ("csr_regression_log", "tb_csr_file", ()),
    )
    for kind, test_name, markers in positive_logs:
        text = artifact_paths[kind].read_text(encoding="utf-8")
        if not (
            text.splitlines().count(f"[PASS] {test_name}") == 1
            and text.splitlines().count("[RESULT] PASS") == 1
            and text.splitlines().count(design_marker) == 1
            and all(text.splitlines().count(marker) == 1 for marker in markers)
            and "[RESULT] FAIL" not in text
            and "[CHECK-FAIL]" not in text
            and "FATAL:" not in text
            and "ERROR:" not in text
        ):
            errors.append(
                f"VECTORED-TRAP-G1 positive log {test_name} drifted")

    mutation = load_json(artifact_paths["mutation_manifest"])
    try:
        mutation_runner = load_workspace_module(
            root,
            "npc/rv64/testbench/scripts/run_csr_vectored_trap_mutations.py",
            "vectored_trap_mutation_contract",
        )
        mutation_specs = {
            spec.mutation_id: spec for spec in mutation_runner.MUTATIONS
        }
    except (OSError, ValueError, AttributeError) as exc:
        errors.append(
            f"VECTORED-TRAP-G1 cannot load mutation contract: {exc}")
        mutation_specs = {}
    rows = mutation.get("mutations")
    by_id = {
        row.get("mutation_id"): row
        for row in rows
        if isinstance(row, dict) and isinstance(row.get("mutation_id"), str)
    } if isinstance(rows, list) else {}
    source_path = root / "npc/rv64/vsrc/core/CsrFile.v"
    source_text = source_path.read_text(encoding="utf-8")
    source_sha = sha256_file(source_path)
    mutation_ok = isinstance(rows, list) and (
        mutation.get("schema_version") == 1
        and mutation.get("source_sha256_before") == source_sha
        and mutation.get("source_sha256_after") == source_sha
        and mutation.get("source_unchanged") is True
        and mutation.get("rtl_design_id_before") == expected_design_id
        and mutation.get("rtl_design_id_after") == expected_design_id
        and mutation.get("rtl_source_set") == expected_source_set
        and mutation.get("rtl_source_set_unchanged") is True
        and mutation.get("summary") == {
            "all_rejected": True,
            "compile_succeeded": len(mutation_specs),
            "rejected": len(mutation_specs),
            "total": len(mutation_specs),
        }
        and len(rows) == len(mutation_specs)
    )
    mutation_ok = mutation_ok and set(by_id) == set(mutation_specs)
    if mutation_ok:
        for name, spec in mutation_specs.items():
            row = by_id[name]
            if source_text.count(spec.old) != 1:
                mutation_ok = False
                break
            mutated = source_text.replace(spec.old, spec.new, 1)
            mutant_path, mutant_error = safe_regular_file(
                root, row.get("mutant_path"))
            vvp_path, vvp_error = safe_regular_file(
                root, row.get("compile_artifact"))
            log_path, log_error = safe_regular_file(root, row.get("log_path"))
            assertions = row.get("required_assertion_counts")
            if mutant_error or vvp_error or log_error or any(
                path is None for path in (mutant_path, vvp_path, log_path)
            ):
                mutation_ok = False
                break
            assert mutant_path is not None
            assert vvp_path is not None
            assert log_path is not None
            log_text = log_path.read_text(encoding="utf-8")
            if not (
                row.get("mutant_sha256")
                    == hashlib.sha256(mutated.encode("utf-8")).hexdigest()
                    == sha256_file(mutant_path)
                and row.get("compile_succeeded") is True
                and row.get("compile_artifact_sha256") == sha256_file(vvp_path)
                and row.get("driver_rc") != 0
                and row.get("rejected") is True
                and row.get("functional_fail_marker_count") == 1
                and row.get("functional_check_fail_count", 0) > 0
                and row.get("result_fail_count") == 1
                and row.get("exact_test_pass_count") == 0
                and row.get("result_pass_count") == 0
                and isinstance(assertions, dict)
                and set(assertions) == set(spec.required_assertions)
                and all(
                    isinstance(value, int) and value > 0
                    for value in assertions.values()
                )
                and log_text.splitlines().count("[RESULT] FAIL status=1") == 1
                and all(marker in log_text for marker in spec.required_assertions)
                and artifact_paths[f"mutation_log:{name}"] == log_path
                and "[RESULT] PASS" not in log_text
            ):
                mutation_ok = False
                break
    if not mutation_ok:
        errors.append(
            "VECTORED-TRAP-G1 compile-success RTL variants are incomplete")

    raw_text = raw_path.read_text(encoding="utf-8")
    raw_markers = (
        f"schema={VECTORED_TRAP_RESULT_SCHEMA}",
        f"design_id={expected_design_id}",
        f"canonical_command={VECTORED_TRAP_COMMAND}",
        "focused_cases=13/13",
        "full_core_paths=3/3",
        "raw_duplicate_terminal_events=0",
        "compile_success_rtl_mutations=7",
        "dynamic_rejected_rtl_mutations=7",
        "csr_regression=1/1",
        "ppa=UNQUALIFIED",
        "promotion_eligible=false",
        "[VECTORED-TRAP-GATE] PASS",
    )
    missing = [
        marker for marker in raw_markers
        if raw_text.splitlines().count(marker) != 1
    ]
    if missing:
        errors.append(
            f"VECTORED-TRAP-G1 raw log missing exact markers={missing}")
    return errors


SERIALIZE_G1_COMMAND = (
    "python3 .github/task-runs/"
    "2026-07-28-rv64-v10g-serialize-currentness-closure/"
    "verify_serialize_g1_closure.py"
)
SERIALIZE_G1_EVIDENCE = {
    "serialize_closure_candidate": (
        ".github/task-runs/"
        "2026-07-28-rv64-v10g-serialize-currentness-closure/"
        "serialize-g1-closure-candidate-v2.json"
    ),
    "independent_review_contract": (
        ".github/task-runs/"
        "2026-07-28-rv64-v10g-serialize-currentness-closure/"
        "subagent-contracts/serialize-currentness-final-review-v2.json"
    ),
    "independent_review_report": (
        ".github/task-runs/"
        "2026-07-28-rv64-v10g-serialize-currentness-closure/"
        "final-reviewer-report-v2.md"
    ),
}


def validate_serialize_g1_debt(
    root: pathlib.Path,
    entry: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    """Validate product-default serialize ownership and its review decision."""

    errors: list[str] = []
    if entry.get("canonical_command") != SERIALIZE_G1_COMMAND:
        errors.append("SERIALIZE-G1 canonical command drifted")

    evidence = entry.get("evidence")
    evidence_list = evidence if isinstance(evidence, list) else []
    by_kind = {
        item.get("kind"): item
        for item in evidence_list
        if isinstance(item, dict) and isinstance(item.get("kind"), str)
    }
    if not (
        len(evidence_list) == len(SERIALIZE_G1_EVIDENCE)
        and set(by_kind) == set(SERIALIZE_G1_EVIDENCE)
        and all(
            by_kind[kind].get("path") == path
            for kind, path in SERIALIZE_G1_EVIDENCE.items()
        )
    ):
        errors.append(
            "SERIALIZE-G1 requires exact candidate/contract/review evidence")
        return errors

    try:
        verifier = load_workspace_module(
            root,
            ".github/task-runs/"
            "2026-07-28-rv64-v10g-serialize-currentness-closure/"
            "verify_serialize_g1_closure.py",
            "serialize_g1_closure_verifier",
        )
        verifier_errors = verifier.validate(root)
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        errors.append(f"SERIALIZE-G1 verifier could not run: {exc}")
        return errors

    if verifier.DESIGN_ID != expected_design_id:
        errors.append(
            "SERIALIZE-G1 verifier is not bound to the current design_id")
    if verifier_errors:
        errors.extend(
            f"SERIALIZE-G1 {message}" for message in verifier_errors[:8])
    return errors


DEBT_SEMANTIC_VALIDATORS = {
    "F0-G1": validate_f0_debt,
    "FDG-G1": validate_fdg_debt,
    "XRET-G1": validate_xret_debt,
    "STORE-BRESP-G1": validate_store_bresp_debt,
    "INSTRET-G1": validate_instret_debt,
    "FENCE-G1": validate_fence_debt,
    "MEM-ISSUE-G1": validate_mem_issue_debt,
    "MIQ-FLUSH-G1": validate_miq_flush_debt,
    "IFU-AXI-G1": validate_ifu_axi_debt,
    "IFU-FETCH-G2": validate_ifu_fetch_debt,
    "IFU-ACCESS-G1": validate_ifu_access_debt,
    "IFU-TVAL-G1": validate_ifu_tval_debt,
    "PTW-PMP-G1": validate_ptw_pmp_debt,
    "CONTROL-EVENT-G1": validate_control_event_debt,
    "SERIALIZE-G1": validate_serialize_g1_debt,
    "VECTORED-TRAP-G1": validate_vectored_trap_debt,
}


def validate_debt_ledger(
    *,
    root: pathlib.Path,
    ledger: dict[str, Any],
    expected_design_id: str,
    cohort_id: str,
    excluded_debt_ids: set[str],
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {}

    ledger_schema_errors = schema_errors(root, ledger, LEDGER_SCHEMA)
    add_check(
        checks, blockers, "debt.json_schema",
        not ledger_schema_errors,
        "valid Draft 2020-12 ledger schema"
        if not ledger_schema_errors else "; ".join(ledger_schema_errors[:4]),
    )

    add_check(
        checks, blockers, "debt.schema",
        ledger.get("schema") == LEDGER_SCHEMA,
        f"expected {LEDGER_SCHEMA}",
    )
    add_check(
        checks, blockers, "debt.design_id",
        ledger.get("design_id") == expected_design_id,
        "ledger and architecture evidence must use the same design_id",
    )

    roadmap_ref = ledger.get("roadmap")
    roadmap_path = roadmap_ref.get("path") if isinstance(roadmap_ref, dict) else None
    roadmap, roadmap_errors = artifact_observation(root, roadmap_path)
    observed["roadmap"] = roadmap
    for error in roadmap_errors:
        add_check(checks, blockers, "debt.roadmap.path", False, error)
    marker_map: dict[str, str] = {}
    if not roadmap_errors:
        claimed_sha = roadmap_ref.get("sha256")
        add_check(
            checks, blockers, "debt.roadmap.sha256",
            claimed_sha == roadmap.get("sha256"),
            "ledger ROADMAP hash must match the current file",
        )
        roadmap_file, _ = safe_regular_file(root, roadmap_path)
        assert roadmap_file is not None
        marker_map, marker_errors = parse_debt_markers(
            roadmap_file.read_text(encoding="utf-8"))
        for error in marker_errors:
            add_check(checks, blockers, "debt.roadmap.inventory", False, error)

    entries = ledger.get("entries")
    entries_list = entries if isinstance(entries, list) else []
    add_check(
        checks, blockers, "debt.entries.type",
        isinstance(entries, list) and bool(entries),
        "ledger entries must be a non-empty array",
    )
    entry_map: dict[str, dict[str, Any]] = {}
    duplicate_ids: set[str] = set()
    for entry in entries_list:
        if not isinstance(entry, dict) or not _is_nonempty_string(entry.get("id")):
            add_check(
                checks, blockers, "debt.entry.shape", False,
                "every debt entry must be an object with a non-empty id",
            )
            continue
        debt_id = entry["id"]
        if debt_id in entry_map:
            duplicate_ids.add(debt_id)
        else:
            entry_map[debt_id] = entry
    add_check(
        checks, blockers, "debt.entries.unique",
        not duplicate_ids,
        "duplicate ids=" + ",".join(sorted(duplicate_ids)) if duplicate_ids else "all ids unique",
    )
    if marker_map:
        missing = sorted(set(marker_map) - set(entry_map))
        extra = sorted(set(entry_map) - set(marker_map))
        add_check(
            checks, blockers, "debt.entries.exact_membership",
            not missing and not extra,
            f"missing={missing} extra={extra}",
        )

    status_counts: dict[str, int] = {}
    for debt_id, entry in sorted(entry_map.items()):
        priority = entry.get("priority")
        if debt_id in marker_map:
            add_check(
                checks, blockers, f"debt.{debt_id}.priority",
                priority == marker_map[debt_id],
                f"ledger priority={priority!r}, ROADMAP priority={marker_map[debt_id]!r}",
            )
        status = entry.get("status")
        status_counts[str(status)] = status_counts.get(str(status), 0) + 1
        add_check(
            checks, blockers, f"debt.{debt_id}.status_known",
            status in ALL_DEBT_STATUSES,
            f"status={status!r}",
        )
        owners = entry.get("owner_paths")
        owner_errors: list[str] = []
        if isinstance(owners, list):
            for owner in owners:
                _, error = safe_regular_file(root, owner)
                if error:
                    owner_errors.append(error)
        add_check(
            checks, blockers, f"debt.{debt_id}.owner",
            isinstance(owners, list) and bool(owners)
            and all(_is_nonempty_string(item) for item in owners)
            and not owner_errors,
            "owner_paths must identify existing regular local RTL/spec owners"
            if not owner_errors else "; ".join(owner_errors[:3]),
        )
        requirements = entry.get("closure_requirements")
        add_check(
            checks, blockers, f"debt.{debt_id}.requirements",
            isinstance(requirements, list) and bool(requirements)
            and all(_is_nonempty_string(item) for item in requirements),
            "closure_requirements must be explicit and non-empty",
        )

        if status == "CLOSED":
            evidence = entry.get("evidence")
            evidence_list = evidence if isinstance(evidence, list) else []
            coverage = entry.get("coverage")
            mutation_fields = (
                "compile_success_rtl_mutation",
                "compile_success_evidence_mutation",
            )
            selected_mutations = (
                [name for name in mutation_fields if name in coverage]
                if isinstance(coverage, dict) else []
            )
            coverage_ok = (
                isinstance(coverage, dict)
                and coverage.get("positive") is True
                and coverage.get("counterexample") is True
                and len(selected_mutations) == 1
                and coverage.get(selected_mutations[0]) is True
            )
            add_check(
                checks, blockers, f"debt.{debt_id}.closed_binding",
                entry.get("current_design_bound") is True
                and entry.get("design_id") == expected_design_id
                and _is_nonempty_string(entry.get("canonical_command"))
                and bool(evidence_list) and coverage_ok,
                "CLOSED requires current design, canonical command, artifact evidence and one domain-appropriate compile-success mutation class",
            )
            for index, artifact in enumerate(evidence_list):
                if not isinstance(artifact, dict):
                    add_check(
                        checks, blockers, f"debt.{debt_id}.evidence.{index}",
                        False, "evidence item must be an artifact object",
                    )
                    continue
                exact_keys = set(artifact) == {"kind", "path", "sha256"}
                obs, errors = artifact_observation(root, artifact.get("path"))
                ok = exact_keys and not errors and artifact.get("sha256") == obs.get("sha256")
                add_check(
                    checks, blockers, f"debt.{debt_id}.evidence.{index}",
                    ok,
                    errors[0] if errors else "evidence hash must match current artifact",
                )
            current_receipt_mode = any(
                isinstance(item, dict)
                and item.get("kind") == CURRENT_DEBT_RECEIPT_KIND
                for item in evidence_list
            )
            if current_receipt_mode:
                try:
                    current_tool = load_current_debt_tool(root)
                    semantic_errors = current_tool.validate_entry(
                        root, entry, expected_design_id
                    )
                except (OSError, ValueError, AttributeError, TypeError) as exc:
                    semantic_errors = [
                        f"current architecture-debt receipt could not be validated: {exc}"
                    ]
            else:
                validator = DEBT_SEMANTIC_VALIDATORS.get(debt_id)
                semantic_errors = (
                    ["no registered debt-specific semantic validator"]
                    if validator is None
                    else validator(root, entry, expected_design_id)
                )
            add_check(
                checks, blockers, f"debt.{debt_id}.semantic_evidence",
                not semantic_errors,
                "debt-specific markers, command, mutations and design binding verified"
                if not semantic_errors else "; ".join(semantic_errors[:3]),
            )
        elif status == "EXCLUDED_BY_COHORT":
            contract = entry.get("scope_contract")
            contract_ok = False
            contract_detail = "scope_contract must be an exact path/hash artifact"
            if isinstance(contract, dict) and set(contract) == {"path", "sha256"}:
                obs, errors = artifact_observation(root, contract.get("path"))
                contract_ok = not errors and contract.get("sha256") == obs.get("sha256")
                if errors:
                    contract_detail = errors[0]
                elif contract_ok:
                    contract_path, _ = safe_regular_file(root, contract.get("path"))
                    assert contract_path is not None
                    try:
                        declaration = load_json(contract_path)
                        expected_keys = {
                            "schema", "debt_id", "design_id", "cohort_id", "rationale"
                        }
                        contract_ok = (
                            set(declaration) == expected_keys
                            and declaration.get("schema")
                            == "npc-rv64-architecture-debt-exclusion-v1"
                            and declaration.get("debt_id") == debt_id
                            and declaration.get("design_id") == expected_design_id
                            and declaration.get("cohort_id") == cohort_id
                            and _is_nonempty_string(declaration.get("rationale"))
                            and declaration.get("rationale")
                            == entry.get("scope_rationale")
                        )
                        if not contract_ok:
                            contract_detail = (
                                "scope contract must exactly bind debt/design/cohort/rationale")
                    except (OSError, ValueError, json.JSONDecodeError) as exc:
                        contract_ok = False
                        contract_detail = str(exc)
            add_check(
                checks, blockers, f"debt.{debt_id}.cohort_exclusion",
                priority == "P1"
                and debt_id in excluded_debt_ids
                and _is_nonempty_string(entry.get("scope_rationale"))
                and contract_ok,
                contract_detail,
            )
        elif status in UNRESOLVED_DEBT:
            add_check(
                checks, blockers, f"debt.{debt_id}.resolved",
                False, f"unresolved status={status}",
            )

    ledger_exclusions = {
        debt_id for debt_id, entry in entry_map.items()
        if entry.get("status") == "EXCLUDED_BY_COHORT"
    }
    unexpected_exclusions = sorted(excluded_debt_ids ^ ledger_exclusions)
    add_check(
        checks, blockers, "debt.cohort_exclusions.exact",
        not unexpected_exclusions,
        f"candidate/ledger exclusion symmetric_difference={unexpected_exclusions}",
    )
    observed["entry_count"] = len(entry_map)
    observed["status_counts"] = dict(sorted(status_counts.items()))
    observed["roadmap_inventory"] = dict(sorted(marker_map.items()))
    return checks, blockers, observed


def _join_make_continuations(text: str) -> list[str]:
    logical: list[str] = []
    current = ""
    for raw_line in text.splitlines():
        line = raw_line.split("#", 1)[0].rstrip()
        if not current and not line:
            continue
        continuation = line.endswith("\\")
        piece = line[:-1].rstrip() if continuation else line
        current = f"{current} {piece}".strip()
        if not continuation:
            logical.append(current)
            current = ""
    if current:
        logical.append(current)
    return logical


def parse_required_tests(makefile_text: str) -> tuple[list[str], list[str]]:
    assignments = []
    for line in _join_make_continuations(makefile_text):
        match = re.match(r"^TESTS\s*:=\s*(.*)$", line)
        if match:
            assignments.append(match.group(1).split())
    errors: list[str] = []
    if len(assignments) != 1:
        errors.append(f"expected exactly one TESTS := assignment, found {len(assignments)}")
        return [], errors
    tests = assignments[0]
    duplicates = sorted({item for item in tests if tests.count(item) > 1})
    if duplicates:
        errors.append(f"duplicate required tests: {duplicates}")
    invalid = [item for item in tests if not re.fullmatch(r"tb_[A-Za-z0-9_]+", item)]
    if invalid:
        errors.append(f"invalid required test names: {invalid}")
    if not tests:
        errors.append("required test inventory is empty")
    return tests, errors


def expected_input_sets(root: pathlib.Path, tests: list[str]) -> dict[str, set[str]]:
    def relative_files(base: pathlib.Path, pattern: str = "*") -> set[str]:
        if not base.is_dir():
            return set()
        return {
            path.relative_to(root).as_posix()
            for path in base.rglob(pattern)
            if path.is_file() and not path.is_symlink()
        }

    generated = relative_files(root / "npc/rv64/include/generated")
    generated |= relative_files(root / "npc/rv64/include/config")
    specifications = {
        path.relative_to(root).as_posix()
        for base in (
            root / "npc/rv64/design/arch",
            root / "npc/rv64/design/specs",
        )
        if base.is_dir()
        for path in base.glob("*.md")
        if path.is_file() and not path.is_symlink()
    }
    test_support = set()
    for base in (
        root / "npc/rv64/testbench/common",
        root / "npc/rv64/testbench/scripts",
        root / "npc/rv64/testbench/tests",
    ):
        test_support |= {
            path.relative_to(root).as_posix()
            for path in base.rglob("*")
            if path.is_file() and not path.is_symlink()
            and "__pycache__" not in path.parts and path.suffix != ".pyc"
        }
    return {
        "config": {"npc/rv64/.config"},
        "generated_headers": generated,
        "filelists": {
            "npc/rv64/vsrc/filelist.mk",
            "npc/rv64/testbench/Makefile",
        },
        "specifications": specifications,
        "test_sources": test_support,
    }


def validate_architecture(
    *,
    root: pathlib.Path,
    evidence: dict[str, Any] | None,
    result: dict[str, Any] | None,
    evidence_path: pathlib.Path | None,
    expected_design_id: str,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {}
    if evidence is None or result is None:
        add_check(
            checks, blockers, "architecture.artifacts", False,
            "architecture evidence and executable result are both required",
        )
        return checks, blockers, observed

    tests = evidence.get("tests")
    test_map = tests if isinstance(tests, dict) else {}
    evidence_ok = (
        evidence.get("schema") == ARCH_EVIDENCE_SCHEMA
        and evidence.get("design_id") == expected_design_id
        and set(test_map) == {
            "frontend_ii1",
            "width_continuity",
            "pair_matrix",
            "no_static_lane_semantics",
            "dual_memory_issue",
            "true_ooo_long_latency",
            "selective_scheduling",
            "memory_ordering",
            "speculation_recovery",
        }
        and all(
            isinstance(record, dict) and record.get("status") == "PASS"
            for record in test_map.values()
        )
    )
    add_check(
        checks, blockers, "architecture.directed_suite",
        evidence_ok,
        "nine exact directed records must be PASS under the candidate design_id",
    )

    gates = result.get("gates")
    gate_map = gates if isinstance(gates, dict) else {}
    source_set = result.get("rtl_source_set")
    source_map = source_set.get("files") if isinstance(source_set, dict) else None
    result_ok = (
        result.get("schema") == ARCH_RESULT_SCHEMA
        and result.get("overall_status") == "GREEN"
        and result.get("exit_code") == 0
        and set(gate_map) == GATE_IDS
        and all(
            isinstance(record, dict) and record.get("status") == "GREEN"
            for record in gate_map.values()
        )
        and isinstance(source_set, dict)
        and source_set.get("design_id") == expected_design_id
        and isinstance(source_map, dict)
        and bool(source_map)
        and source_set.get("file_count") == len(source_map)
        and source_set.get("sha256") == expected_design_id.removeprefix("sha256:")
    )
    add_check(
        checks, blockers, "architecture.hard_gates",
        result_ok,
        "executable result must be 9/9 GREEN with the same exact RTL source set",
    )

    drift: list[str] = []
    if isinstance(source_map, dict):
        for relative, expected_sha in sorted(source_map.items()):
            path, error = safe_regular_file(root, relative)
            if error or not isinstance(expected_sha, str) or path is None:
                drift.append(relative)
            elif sha256_file(path) != expected_sha:
                drift.append(relative)
    add_check(
        checks, blockers, "architecture.rtl_source_drift",
        isinstance(source_map, dict) and not drift,
        f"drifted_or_missing={drift[:12]} total={len(drift)}",
    )

    provenance_drift: list[str] = []
    for record in test_map.values():
        if not isinstance(record, dict):
            continue
        for section_name in ("provenance", "source_manifest"):
            section = record.get(section_name)
            if section_name == "source_manifest" and section is None:
                continue
            files = section.get("files") if isinstance(section, dict) else None
            if not isinstance(files, dict):
                provenance_drift.append(f"{section_name}:missing")
                continue
            for relative, expected_sha in files.items():
                path, error = safe_regular_file(root, relative)
                if error or path is None or sha256_file(path) != expected_sha:
                    provenance_drift.append(relative)
    add_check(
        checks, blockers, "architecture.provenance_drift",
        not provenance_drift,
        f"drifted_or_missing={sorted(set(provenance_drift))[:12]} total={len(set(provenance_drift))}",
    )

    live_result: dict[str, Any] | None = None
    reevaluate_errors: list[str] = []
    try:
        if evidence_path is None:
            raise ValueError("architecture evidence path is missing")
        evaluator = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            "architecture_hard_gates",
        )
        live_source_sha, live_source_files = evaluator.rtl_binding(root)
        if not live_source_files:
            raise ValueError("canonical architecture evaluator returned an empty RTL set")
        live_result = evaluator.evaluate(root, evidence_path)
        stored_comparable = {
            key: result.get(key)
            for key in (
                "schema", "overall_status", "exit_code", "contract",
                "rtl_source_set", "evidence_errors", "gates",
            )
        }
        live_comparable = {
            key: live_result.get(key)
            for key in stored_comparable
        }
        if stored_comparable != live_comparable:
            reevaluate_errors.append(
                "stored architecture result differs from canonical live evaluation")
        if live_result.get("overall_status") != "GREEN" or live_result.get("exit_code") != 0:
            reevaluate_errors.append("canonical live architecture evaluation is not GREEN")
        if live_source_sha != expected_design_id.removeprefix("sha256:"):
            reevaluate_errors.append("canonical RTL aggregate digest differs from design_id")
        if source_map != live_source_files:
            reevaluate_errors.append("stored RTL exact-membership differs from canonical closure")
        if canonical_sha256(live_source_files) != live_source_sha:
            reevaluate_errors.append("canonical RTL aggregate digest does not match its file map")
    except (
        OSError, ValueError, AttributeError, json.JSONDecodeError,
        ImportError, SyntaxError, RuntimeError,
    ) as exc:
        reevaluate_errors.append(str(exc))
    add_check(
        checks, blockers, "architecture.canonical_reevaluation",
        not reevaluate_errors,
        "canonical evaluator, non-empty exact source closure and complete gate result match"
        if not reevaluate_errors else "; ".join(reevaluate_errors[:4]),
    )
    observed["design_id"] = expected_design_id
    observed["gate_statuses"] = {
        gate_id: gate_map.get(gate_id, {}).get("status")
        if isinstance(gate_map.get(gate_id), dict) else None
        for gate_id in sorted(GATE_IDS)
    }
    observed["rtl_file_count"] = len(source_map) if isinstance(source_map, dict) else 0
    if live_result is not None:
        observed["canonical_result_sha256"] = canonical_sha256({
            key: live_result.get(key)
            for key in (
                "schema", "overall_status", "exit_code", "contract",
                "rtl_source_set", "evidence_errors", "gates",
            )
        })
    return checks, blockers, observed


def validate_census(
    root: pathlib.Path,
    census: dict[str, Any] | None,
    census_path: pathlib.Path | None,
    expected_design_id: str,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    scope = census.get("scope") if isinstance(census, dict) else None
    ledger = census.get("status_ledger") if isinstance(census, dict) else None
    static_declared = (
        isinstance(census, dict)
        and census.get("schema_version") == CENSUS_SCHEMA
        and census.get("design_id") == expected_design_id
        and isinstance(scope, dict)
        and scope.get("field_level_complete") is True
        and scope.get("instance_graph_complete") is True
        and scope.get("semantic_complete") is False
        and isinstance(ledger, dict)
        and ledger.get("current_production_holder_census")
        == "ELABORATED_INSTANCE_COMPLETE"
        and ledger.get("global_no_live_reuse") == "SEMANTIC_COVERAGE_REQUIRED"
        and ledger.get("whole_architecture") == "RED"
        and ledger.get("ppa_promotion") == "UNPROMOTED"
    )
    add_check(
        checks, blockers, "census.static_scope_boundary", static_declared,
        "static census is current-design field/instance complete and leaves semantic, architecture and PPA promotion to independent receipts",
    )

    static_errors: list[str] = []
    static_result: dict[str, Any] | None = None
    instance_observation: dict[str, Any] | None = None
    try:
        if census_path is None:
            raise ValueError("census manifest path is missing")
        evaluator = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/producer_holder_census.py",
            "producer_holder_census",
        )
        static_result = evaluator.audit(
            root,
            census_path,
            root / "npc/rv64/vsrc",
        )
        hashes = static_result.get("hashes")
        if static_result.get("status") != "PASS":
            static_errors.append("canonical static census audit is not PASS")
        if not isinstance(hashes, dict) or not isinstance(hashes.get("source_files"), dict) \
                or not hashes["source_files"]:
            static_errors.append("canonical static census source closure is empty")
        if isinstance(hashes, dict) and hashes.get("manifest_sha256") != sha256_file(census_path):
            static_errors.append("canonical static census manifest hash mismatch")
        if static_result.get("scope") != census.get("scope"):
            static_errors.append("canonical static census scope differs from manifest")
        if static_result.get("status_ledger") != census.get("status_ledger"):
            static_errors.append("canonical static census status ledger differs from manifest")
        instance_observation = static_result.get("instance_graph")
        if not isinstance(instance_observation, dict) or \
                instance_observation.get("status") != "PASS":
            static_errors.append(
                "canonical census elaborated instance graph is not PASS"
            )
    except (
        OSError, ValueError, AttributeError, json.JSONDecodeError,
        ImportError, SyntaxError, RuntimeError,
    ) as exc:
        static_errors.append(str(exc))
    add_check(
        checks, blockers, "census.canonical_static_audit",
        not static_errors,
        "canonical census checker rebuilt a non-empty exact source inventory "
        "and verified the bound elaborated holder instance graph"
        if not static_errors else "; ".join(static_errors[:4]),
    )

    semantic_errors: list[str] = []
    semantic_result: dict[str, Any] | None = None
    semantic_expected: dict[str, Any] | None = None
    semantic_path: pathlib.Path | None = None
    try:
        semantic_path, error = safe_regular_file(root, SEMANTIC_COVERAGE_PATH)
        if error or semantic_path is None:
            raise ValueError(error or "semantic coverage ledger is missing")
        if census_path is None:
            raise ValueError("census manifest path is missing")
        policy_path, error = safe_regular_file(
            root, SEMANTIC_COVERAGE_POLICY_PATH)
        if error or policy_path is None:
            raise ValueError(error or "semantic coverage policy is missing")
        semantic_result = load_json(semantic_path)
        semantic_tool = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/producer_holder_semantic_coverage.py",
            "producer_holder_semantic_coverage",
        )
        try:
            graph_path = semantic_tool.manifest_instance_graph_path(
                root, census_path)
            semantic_expected = semantic_tool.build_ledger(
                root, census_path, graph_path, policy_path)
        except semantic_tool.CoverageError as exc:
            raise ValueError(str(exc)) from exc
        if semantic_result != semantic_expected:
            semantic_errors.append(
                "semantic coverage ledger differs from canonical current-input evaluation")
        counts = semantic_result.get("counts")
        expected_counts = {
            "holder_instances": 17,
            "semantic_units": 46,
            "unit_instance_bindings": 52,
            "units_semantic_gap": 0,
            "units_semantic_pass": 46,
        }
        if not isinstance(counts, dict) or any(
            counts.get(key) != value for key, value in expected_counts.items()
        ):
            semantic_errors.append(
                "semantic coverage counts are not 17 instances, 46/46 units and 52 bindings")
        expected_promotion = {
            "global_no_live_reuse": "GREEN",
            "whole_architecture": "RED",
            "system_recertification": "PASS_CURRENT_CONFIG",
            "ppa": "UNPROMOTED",
        }
        if not (
            semantic_result.get("schema_version") == SEMANTIC_COVERAGE_SCHEMA
            and semantic_result.get("status") == "PASS"
            and semantic_result.get("design_id") == expected_design_id
            and semantic_result.get("promotion") == expected_promotion
        ):
            semantic_errors.append(
                "semantic coverage identity, status or promotion boundary drifted")
    except (
        OSError, ValueError, AttributeError, json.JSONDecodeError,
        ImportError, SyntaxError, RuntimeError,
    ) as exc:
        semantic_errors.append(str(exc))
    add_check(
        checks, blockers, "census.semantic_coverage",
        not semantic_errors,
        "canonical semantic evaluator reproduced 17 holder instances, 46/46 units and 52 exact instance bindings"
        if not semantic_errors else "; ".join(semantic_errors[:4]),
    )

    dynamic_errors: list[str] = []
    global_receipt: dict[str, Any] | None = None
    global_path: pathlib.Path | None = None
    try:
        global_path, error = safe_regular_file(root, GLOBAL_NO_LIVE_REUSE_PATH)
        if error or global_path is None:
            raise ValueError(error or "global no-live-reuse receipt is missing")
        global_receipt = load_json(global_path)
        expected_promotion = {
            "global_no_live_reuse": "GREEN",
            "whole_architecture": "RED",
            "system_recertification": "REQUIRED",
            "ppa": "UNPROMOTED",
        }
        if not (
            global_receipt.get("schema_version") == GLOBAL_NO_LIVE_REUSE_SCHEMA
            and global_receipt.get("status") == "PASS"
            and global_receipt.get("design_id") == expected_design_id
            and global_receipt.get("promotion") == expected_promotion
        ):
            dynamic_errors.append(
                "global no-live-reuse receipt identity, status or promotion boundary drifted")
        support = global_receipt.get("semantic_support")
        support_counts = support.get("counts") if isinstance(support, dict) else None
        if not (
            isinstance(support, dict)
            and support.get("status") == "PASS"
            and support.get("design_id") == expected_design_id
            and isinstance(support_counts, dict)
            and support_counts.get("holder_instances") == 17
            and support_counts.get("semantic_units") == 46
            and support_counts.get("unit_instance_bindings") == 52
            and support_counts.get("units_semantic_gap") == 0
            and support_counts.get("units_semantic_pass") == 46
        ):
            dynamic_errors.append(
                "global receipt semantic support does not match 17/46/52 closure")
        dynamic = global_receipt.get("v14g_dynamic_fence")
        if not (
            isinstance(dynamic, dict)
            and dynamic.get("status") == "PASS"
            and dynamic.get("design_id") == expected_design_id
            and dynamic.get("baseline_profiles_pass") == 4
            and isinstance(dynamic.get("baselines"), list)
            and len(dynamic["baselines"]) == 4
            and dynamic.get("compile_success_mutations_rejected") == 22
            and isinstance(dynamic.get("mutations"), list)
            and len(dynamic["mutations"]) == 22
            and dynamic.get("generation_widths") == [1, 4]
            and isinstance(dynamic.get("intermediate_products_retained"), int)
            and not isinstance(
                dynamic.get("intermediate_products_retained"), bool)
            and dynamic.get("intermediate_products_retained") == 0
        ):
            dynamic_errors.append(
                "V14G dynamic fence is not 4/4 baseline plus 22/22 compile-success mutation closure at GEN_W 1/4")
        if not isinstance(semantic_result, dict):
            dynamic_errors.append("semantic coverage ledger is unavailable")
        else:
            closure = semantic_result.get("global_closure")
            expected_closure = {
                "status": "PASS",
                "design_id": expected_design_id,
                "semantic_units": 46,
                "unit_instance_bindings": 52,
                "v14g_baselines": 4,
                "v14g_compile_success_mutations_rejected": 22,
                "global_no_live_reuse": "GREEN",
                "whole_architecture": "RED",
                "system_recertification": "REQUIRED",
                "ppa": "UNPROMOTED",
            }
            if not isinstance(closure, dict) or any(
                closure.get(key) != value
                for key, value in expected_closure.items()
            ):
                dynamic_errors.append(
                    "semantic ledger global-closure summary drifted")
            global_sha = sha256_file(global_path)
            global_size = global_path.stat().st_size
            expected_input_binding = {
                "path": GLOBAL_NO_LIVE_REUSE_PATH,
                "sha256": global_sha,
                "size_bytes": global_size,
            }
            inputs = semantic_result.get("inputs")
            if not isinstance(inputs, dict) or inputs.get(
                "global_closure_receipt") != expected_input_binding:
                dynamic_errors.append(
                    "semantic ledger does not exact-bind the global no-live-reuse receipt")
            expected_closure_binding = {
                "kind": "global-producer-no-live-reuse-receipt",
                **expected_input_binding,
            }
            if not isinstance(closure, dict) or closure.get(
                "receipt") != expected_closure_binding:
                dynamic_errors.append(
                    "semantic global-closure summary receipt binding drifted")
    except (
        OSError, ValueError, AttributeError, json.JSONDecodeError,
        ImportError, SyntaxError, RuntimeError,
    ) as exc:
        dynamic_errors.append(str(exc))
    add_check(
        checks, blockers, "census.dynamic_lifecycle_evidence",
        not dynamic_errors,
        "current V14G fence binds 4/4 baseline profiles, 22/22 compile-success mutations and generation widths 1/4"
        if not dynamic_errors else "; ".join(dynamic_errors[:4]),
    )

    complete = (
        static_declared
        and not static_errors
        and not semantic_errors
        and not dynamic_errors
    )
    add_check(
        checks, blockers, "census.full_core_complete", complete,
        "static field/instance census, canonical 46/46 semantic coverage and current V14G lifecycle fence compose without premature architecture/PPA promotion",
    )
    return checks, blockers, {
        "design_id": census.get("design_id") if isinstance(census, dict) else None,
        "scope": scope,
        "status_ledger": ledger,
        "static_audit_sha256": canonical_sha256(static_result)
        if static_result is not None else None,
        "instance_graph": instance_observation,
        "semantic_coverage_sha256": sha256_file(semantic_path)
        if semantic_path is not None else None,
        "semantic_counts": semantic_result.get("counts")
        if isinstance(semantic_result, dict) else None,
        "semantic_evaluation_sha256": canonical_sha256(semantic_expected)
        if semantic_expected is not None else None,
        "global_no_live_reuse_sha256": sha256_file(global_path)
        if global_path is not None else None,
        "v14g_dynamic_fence": global_receipt.get("v14g_dynamic_fence")
        if isinstance(global_receipt, dict) else None,
    }


def validate_system_recertification(
    *,
    root: pathlib.Path,
    receipt: dict[str, Any] | None,
    receipt_path: pathlib.Path | None,
    expected_design_id: str,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    """Recompute and exact-bind the default L0+L1+L2+L3 signoff.

    This is deliberately a checker replay.  It consumes retained, sealed
    evidence and never launches the DUT, while still making a missing or
    replaced L2/L3 receipt fail closed at the ARCH_STABLE boundary.
    """

    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {}

    canonical_path_ok = False
    if receipt_path is not None:
        try:
            canonical_path_ok = (
                receipt_path.resolve().relative_to(root.resolve()).as_posix()
                == SYSTEM_RECERTIFICATION_PATH
            )
        except ValueError:
            canonical_path_ok = False
    add_check(
        checks,
        blockers,
        "system_recertification.canonical_path",
        canonical_path_ok,
        f"candidate must bind {SYSTEM_RECERTIFICATION_PATH}",
    )

    layers = receipt.get("layers") if isinstance(receipt, dict) else None
    optional = (
        receipt.get("optional_full_ubuntu")
        if isinstance(receipt, dict) else None
    )
    promotion = receipt.get("promotion") if isinstance(receipt, dict) else None
    expected_layers = {
        "L0_DIRECTED_RTL",
        "L1_FULL_CORE_DIFFTEST",
        "L2_MINI_SYSTEM",
        "L3_LIGHTWEIGHT_LINUX",
    }
    contract_errors: list[str] = []
    if not (
        isinstance(receipt, dict)
        and receipt.get("schema_version") == SYSTEM_RECERTIFICATION_SCHEMA
        and receipt.get("status") == "PASS"
        and receipt.get("design_id") == expected_design_id
        and receipt.get("default_signoff_conjunction") == [
            "L0_DIRECTED_RTL",
            "L1_FULL_CORE_DIFFTEST",
            "L2_MINI_SYSTEM",
            "L3_LIGHTWEIGHT_LINUX",
        ]
    ):
        contract_errors.append(
            "system receipt schema/status/design/default conjunction drifted")
    if not isinstance(layers, dict) or set(layers) != expected_layers:
        contract_errors.append("system receipt does not contain exactly L0-L3")
    else:
        for name in sorted(expected_layers):
            layer = layers.get(name)
            if not isinstance(layer, dict) or layer.get("status") != "PASS":
                contract_errors.append(f"{name} is not PASS")
        l0 = layers.get("L0_DIRECTED_RTL")
        l1 = layers.get("L1_FULL_CORE_DIFFTEST")
        l2 = layers.get("L2_MINI_SYSTEM")
        l3 = layers.get("L3_LIGHTWEIGHT_LINUX")
        if not isinstance(l0, dict) or l0.get("tests") != {
            "passed": 113, "required": 113,
        } or l0.get("rtl_assertion_failures") != 0:
            contract_errors.append("L0 is not 113/113 with zero RTL assertions")
        if not isinstance(l1, dict) or any(
            l1.get(key) != value
            for key, value in {
                "official_passed": 177,
                "official_required": 177,
                "am_passed": 61,
                "am_required": 61,
                "difftest_mismatches": 0,
            }.items()
        ):
            contract_errors.append("L1 official/AM/DiffTest counts drifted")
        for name, layer in (("L2", l2), ("L3", l3)):
            if not isinstance(layer, dict) or (
                layer.get("case") != "all"
                or layer.get("rtl_assertion_failures") != 0
                or not isinstance(layer.get("commits"), int)
                or layer.get("commits", 0) <= 0
                or not isinstance(layer.get("cycles"), int)
                or layer.get("cycles", 0) <= 0
            ):
                contract_errors.append(
                    f"{name} is not full-case positive execution with zero RTL assertions")
    if optional != {
        "status": "NOT_RUN",
        "launch_policy": "explicit-user-request-only",
        "blocks_default_signoff": False,
        "claim": "OPTIONAL_NOT_IMPLIED",
    }:
        contract_errors.append("optional Ubuntu boundary drifted")
    if promotion != {
        "system_recertification": "PASS_CURRENT_CONFIG",
        "default_layered_signoff": "PASS",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
    }:
        contract_errors.append("system/PPA promotion boundary drifted")
    add_check(
        checks,
        blockers,
        "system_recertification.layer_contract",
        not contract_errors,
        "same-design L0+L1+L2+L3 PASS, zero RTL assertions, Ubuntu NOT_RUN optional and PPA unpromoted"
        if not contract_errors else "; ".join(contract_errors[:4]),
    )

    replay_errors: list[str] = []
    replay: dict[str, Any] | None = None
    try:
        if receipt_path is None:
            raise ValueError("system recertification receipt path is missing")
        evaluator = load_workspace_module(
            root,
            SYSTEM_RECERTIFICATION_TOOL_PATH,
            "system_recertification_current_for_arch_stable",
        )
        replay = evaluator.validate_receipt(
            root,
            receipt_path,
            expected_design_id=expected_design_id,
        )
        expected_replay = {
            "status": "PASS",
            "design_id": expected_design_id,
            "system_recertification": "PASS_CURRENT_CONFIG",
            "default_signoff_conjunction": [
                "L0_DIRECTED_RTL",
                "L1_FULL_CORE_DIFFTEST",
                "L2_MINI_SYSTEM",
                "L3_LIGHTWEIGHT_LINUX",
            ],
            "l0_passed": 113,
            "l0_required": 113,
            "l1_official_passed": 177,
            "l1_official_required": 177,
            "l1_am_passed": 61,
            "l1_am_required": 61,
            "l2_case": "all",
            "l3_case": "all",
            "rtl_assertion_failures": 0,
            "optional_ubuntu": "NOT_RUN_OPTIONAL",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
        }
        if replay != expected_replay:
            replay_errors.append(
                "canonical system checker returned an unexpected summary")
    except (
        OSError, ValueError, KeyError, AttributeError, json.JSONDecodeError,
        ImportError, SyntaxError, RuntimeError,
    ) as exc:
        replay_errors.append(str(exc))
    add_check(
        checks,
        blockers,
        "system_recertification.canonical_reevaluation",
        not replay_errors,
        "canonical checker replayed sealed L0-L3 evidence and exact Ubuntu boundary without DUT execution"
        if not replay_errors else "; ".join(replay_errors[:4]),
    )

    layered_errors: list[str] = []
    layered_observation: dict[str, Any] = {"status": "INVALID"}
    layered_binding = (
        receipt.get("layered_signoff_receipt")
        if isinstance(receipt, dict) else None
    )
    if not isinstance(layered_binding, dict) or set(layered_binding) != {
        "path", "sha256", "size_bytes",
    }:
        layered_errors.append("layered receipt binding is malformed")
    else:
        layered_observation, errors = artifact_observation(
            root, layered_binding.get("path"))
        layered_errors.extend(errors)
        if layered_binding.get("path") != LAYERED_SYSTEM_SIGNOFF_PATH:
            layered_errors.append("layered receipt path is not canonical")
        if not errors and any(
            layered_binding.get(key) != layered_observation.get(key)
            for key in ("path", "sha256", "size_bytes")
        ):
            layered_errors.append("layered receipt hash/size binding drifted")
    add_check(
        checks,
        blockers,
        "system_recertification.layered_receipt_binding",
        not layered_errors,
        "system receipt exact-binds the canonical layered L0-L3 receipt"
        if not layered_errors else "; ".join(layered_errors[:4]),
    )

    observed.update({
        "design_id": receipt.get("design_id")
        if isinstance(receipt, dict) else None,
        "layers": layers,
        "optional_full_ubuntu": optional,
        "promotion": promotion,
        "canonical_replay": replay,
        "layered_signoff_receipt": layered_observation,
    })
    return checks, blockers, observed


def _functional_artifact_bound(
    root: pathlib.Path,
    entry: Any,
    *,
    kind: str,
    frozen_entries: Any,
) -> tuple[dict[str, Any], list[str]]:
    observation, errors = artifact_entry_observation(
        root, entry, allowed_kinds={kind})
    frozen = frozen_entries if isinstance(frozen_entries, list) else []
    if entry not in frozen:
        errors.append(f"artifact is not an exact member of frozen {kind} inputs")
    return observation, errors


def _functional_log(
    root: pathlib.Path,
    entry: Any,
    *,
    kind: str,
    required_markers: Iterable[str],
    forbidden_markers: Iterable[str] = (),
) -> tuple[dict[str, Any], list[str], str]:
    observation, errors = artifact_entry_observation(
        root, entry, allowed_kinds={kind})
    text = ""
    if not errors:
        path, _ = safe_regular_file(root, observation.get("path"))
        assert path is not None
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            errors.append(str(exc))
    if not errors:
        lines = text.splitlines()
        bad_counts = [
            (marker, lines.count(marker))
            for marker in required_markers
            if lines.count(marker) != 1
        ]
        forbidden = [
            marker for marker in forbidden_markers if marker in lines
        ]
        if bad_counts:
            errors.append(
                f"log required marker counts must equal one: {bad_counts[:8]}")
        if forbidden:
            errors.append(f"log contains forbidden markers={forbidden[:8]}")
    return observation, errors, text


def _register_unique_functional_log(
    root: pathlib.Path,
    observation: dict[str, Any],
    label: str,
    identities: dict[tuple[int, int], str],
    errors: list[str],
) -> None:
    path, path_error = safe_regular_file(root, observation.get("path"))
    if path_error or path is None:
        return
    stat = path.stat()
    identity = (stat.st_dev, stat.st_ino)
    previous = identities.get(identity)
    if previous is not None:
        errors.append(f"functional log {label} reuses file identity from {previous}")
    else:
        identities[identity] = label


def validate_functional(
    *,
    root: pathlib.Path,
    functional: dict[str, Any] | None,
    expected_design_id: str,
    cohort_id: str,
    required_tests: list[str],
    freeze_groups: Any,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {"required_module_tests": required_tests}
    if functional is None:
        add_check(
            checks, blockers, "functional.aggregate", False,
            f"current same-design functional aggregate is missing; derived module inventory={len(required_tests)}",
        )
        return checks, blockers, observed

    schema_issues = schema_errors(root, functional, FUNCTIONAL_SCHEMA)
    add_check(
        checks, blockers, "functional.json_schema",
        not schema_issues,
        "valid Draft 2020-12 functional aggregate"
        if not schema_issues else "; ".join(schema_issues[:4]),
    )
    identity_ok = (
        functional.get("schema") == FUNCTIONAL_SCHEMA
        and functional.get("design_id") == expected_design_id
        and functional.get("cohort_id") == cohort_id
        and functional.get("program_image_canonicalization")
        == PROGRAM_IMAGE_CANONICALIZATION
    )
    add_check(
        checks, blockers, "functional.schema_design_cohort", identity_ok,
        "functional aggregate schema/design/cohort/image canonicalization must match",
    )

    group_map = freeze_groups if isinstance(freeze_groups, dict) else {}
    simulator = functional.get("simulator")
    configuration = functional.get("configuration")
    sim_obs, sim_errors = _functional_artifact_bound(
        root, simulator, kind="simulator_binary",
        frozen_entries=group_map.get("binaries"))
    config_obs, config_errors = _functional_artifact_bound(
        root, configuration, kind="kconfig",
        frozen_entries=group_map.get("config"))
    add_check(
        checks, blockers, "functional.simulator_binding", not sim_errors,
        "functional simulator is an exact frozen executable artifact"
        if not sim_errors else "; ".join(sim_errors[:3]),
    )
    add_check(
        checks, blockers, "functional.configuration_binding", not config_errors,
        "functional configuration is an exact frozen input"
        if not config_errors else "; ".join(config_errors[:3]),
    )
    simulator_sha = simulator.get("sha256") if isinstance(simulator, dict) else None
    config_sha = configuration.get("sha256") if isinstance(configuration, dict) else None
    common_markers = (
        f"design_id={expected_design_id}",
        f"cohort_id={cohort_id}",
        f"program_image_canonicalization={PROGRAM_IMAGE_CANONICALIZATION}",
        f"simulator_sha256={simulator_sha}",
        f"config_sha256={config_sha}",
    )
    observed["simulator"] = sim_obs
    observed["configuration"] = config_obs
    functional_log_identities: dict[tuple[int, int], str] = {}

    build = functional.get("build")
    build_map = build if isinstance(build, dict) else {}
    build_command = build_map.get("command")
    build_errors: list[str] = []
    if not _is_nonempty_string(build_command) or build_map.get("return_code") != 0:
        build_errors.append("simulator build command/return code is invalid")
    build_log_obs, errors, _ = _functional_log(
        root, build_map.get("log"), kind="simulator_build_log",
        required_markers=(
            *common_markers,
            f"command_sha256={sha256_bytes(str(build_command).encode('utf-8'))}",
            "return_code=0",
            "[RESULT] PASS",
        ),
        forbidden_markers=("[RESULT] FAIL",),
    )
    _register_unique_functional_log(
        root, build_log_obs, "simulator-build",
        functional_log_identities, errors)
    build_errors.extend(errors)
    add_check(
        checks, blockers, "functional.simulator_build", not build_errors,
        "fresh simulator build log is bound to the current design/config/binary"
        if not build_errors else "; ".join(build_errors[:4]),
    )
    observed["build"] = {"log": build_log_obs}

    module = functional.get("module")
    module_map = module if isinstance(module, dict) else {}
    module_command = module_map.get("command")
    module_records = module_map.get("tests")
    records = module_records if isinstance(module_records, list) else []
    test_ids = [
        record.get("test_id") for record in records if isinstance(record, dict)
    ]
    duplicates = sorted({item for item in test_ids if test_ids.count(item) > 1})
    module_errors: list[str] = []
    if not _is_nonempty_string(module_command):
        module_errors.append("module command is empty")
    if len(test_ids) != len(records):
        module_errors.append("module test record is not an object with test_id")
    if duplicates:
        module_errors.append(f"duplicate module test ids={duplicates}")
    if set(test_ids) != set(required_tests):
        module_errors.append(
            f"module exact-membership missing={sorted(set(required_tests) - set(test_ids))[:8]} "
            f"extra={sorted(set(test_ids) - set(required_tests))[:8]}")
    if not (
        module_map.get("required") == len(required_tests)
        and module_map.get("passed") == len(required_tests)
        and module_map.get("failed") == 0
    ):
        module_errors.append("module summary counts do not match derived inventory")
    module_logs: list[dict[str, Any]] = []
    command_sha = sha256_bytes(str(module_command).encode("utf-8"))
    for record in records:
        if not isinstance(record, dict):
            continue
        test_id = record.get("test_id")
        markers = (
            *common_markers,
            f"command_sha256={command_sha}",
            f"test_id={test_id}",
            "compile_rc=0",
            "simulation_rc=0",
            "[RESULT] PASS",
        )
        log_obs, log_errors, log_text = _functional_log(
            root, record.get("log"), kind="module_test_log",
            required_markers=markers, forbidden_markers=("[RESULT] FAIL",))
        _register_unique_functional_log(
            root, log_obs, f"module:{test_id}",
            functional_log_identities, log_errors)
        module_logs.append(log_obs)
        if record.get("compile_rc") != 0 or record.get("simulation_rc") != 0:
            log_errors.append("module compile/simulation return code is non-zero")
        pass_count = log_text.splitlines().count("[RESULT] PASS")
        fail_count = log_text.splitlines().count("[RESULT] FAIL")
        if record.get("pass_markers") != pass_count \
                or record.get("fail_markers") != fail_count \
                or pass_count != 1 or fail_count != 0:
            log_errors.append(
                "module aggregate marker counts differ from raw PASS=1/FAIL=0")
        module_errors.extend(f"{test_id}: {error}" for error in log_errors)
    add_check(
        checks, blockers, "functional.module_dynamic_inventory",
        not module_errors,
        f"{len(required_tests)} module tests have exact set coverage and bound compile/simulation logs"
        if not module_errors else "; ".join(module_errors[:4]),
    )
    observed["reported_module_inventory"] = test_ids
    observed["module_logs"] = module_logs

    difftest = functional.get("difftest")
    diff = difftest if isinstance(difftest, dict) else {}
    diff_reference = diff.get("reference")
    diff_reference_obs, diff_reference_errors = _functional_artifact_bound(
        root, diff_reference, kind="reference_model_binary",
        frozen_entries=group_map.get("binaries"))
    diff_reference_sha = (
        diff_reference.get("sha256")
        if isinstance(diff_reference, dict) else None
    )
    diff_profile = diff.get("reference_profile")
    diff_profile_obs, diff_profile_errors = artifact_entry_observation(
        root, diff_profile, allowed_kinds={"reference_model_profile"})
    diff_profile_sha = (
        diff_profile.get("sha256") if isinstance(diff_profile, dict) else None
    )
    if not diff_profile_errors:
        profile_path, _ = safe_regular_file(root, diff_profile_obs.get("path"))
        assert profile_path is not None
        try:
            profile_value = load_json(profile_path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            diff_profile_errors.append(str(exc))
        else:
            diff_profile_errors.extend(
                schema_errors(root, profile_value, DIFFTEST_PROFILE_SCHEMA))
            if profile_value.get("reference_sha256") != diff_reference_sha:
                diff_profile_errors.append(
                    "reference profile does not bind the exact reference binary")
            profile_sources = profile_value.get("source_artifacts")
            if isinstance(profile_sources, list):
                for source in profile_sources:
                    _, source_errors = artifact_entry_observation(
                        root, source,
                        allowed_kinds={
                            "reference_config", "reference_model_source",
                            "comparison_policy_source",
                        },
                    )
                    diff_profile_errors.extend(source_errors)

    def validate_image_set(
        label: str,
        value: Any,
        inventory_list: list[str],
        *,
        test_log_kind: str,
        require_difftest: bool,
    ) -> tuple[list[str], list[dict[str, Any]], str, str, list[dict[str, Any]]]:
        errors: list[str] = []
        items = value if isinstance(value, list) else []
        image_ids: list[Any] = []
        observations: list[dict[str, Any]] = []
        identity_records: list[dict[str, Any]] = []
        file_identities: dict[tuple[int, int], str] = {}
        for item in items:
            if not isinstance(item, dict) or set(item) != {
                "test_id", "load_address", "entry_pc", "image", "log"
            }:
                errors.append(f"{label} image record field set differs from contract")
                continue
            test_id = item.get("test_id")
            image_ids.append(test_id)
            if item.get("load_address") != "0x0000000080000000" \
                    or item.get("entry_pc") != "0x0000000080000000":
                errors.append(f"{test_id}: program load/reset address drifted")
            image = item.get("image")
            image_obs, image_errors = _functional_artifact_bound(
                root, image, kind="program_image",
                frozen_entries=group_map.get("images"))
            observations.append({
                "test_id": test_id,
                "load_address": item.get("load_address"),
                "entry_pc": item.get("entry_pc"),
                "image": image_obs,
            })
            image_path, image_path_error = safe_regular_file(
                root, image_obs.get("path"))
            if image_path_error is None and image_path is not None:
                stat = image_path.stat()
                identity = (stat.st_dev, stat.st_ino)
                previous = file_identities.get(identity)
                if previous is not None:
                    image_errors.append(
                        f"program image reuses file identity from {previous}")
                else:
                    file_identities[identity] = str(test_id)
            errors.extend(f"{test_id}: {error}" for error in image_errors)
            image_sha = image.get("sha256") if isinstance(image, dict) else None
            test_markers = [
                *common_markers,
                f"suite={label}",
                f"test_id={test_id}",
                f"image_sha256={image_sha}",
                f"load_address={item.get('load_address')}",
                f"entry_pc={item.get('entry_pc')}",
            ]
            if require_difftest:
                test_markers.extend((
                    f"difftest_reference_sha256={diff_reference_sha}",
                    f"difftest_reference_profile_sha256={diff_profile_sha}",
                ))
            test_log_obs, test_log_errors, _ = _functional_log(
                root, item.get("log"), kind=test_log_kind,
                required_markers=(*test_markers, "[RESULT] PASS"),
                forbidden_markers=("[RESULT] FAIL", "[TEST] FAIL"),
            )
            _register_unique_functional_log(
                root, test_log_obs, f"{label}:{test_id}",
                functional_log_identities, test_log_errors)
            errors.extend(
                f"{test_id}: {error}" for error in test_log_errors)
            observations[-1]["log"] = test_log_obs
            identity_records.append({
                "suite": label,
                "test_id": test_id,
                "image_sha256": image_sha,
                "load_address": item.get("load_address"),
                "entry_pc": item.get("entry_pc"),
            })
        valid_image_ids = [item for item in image_ids if isinstance(item, str)]
        duplicate_ids = sorted({
            item for item in valid_image_ids
            if valid_image_ids.count(item) > 1
        })
        if duplicate_ids:
            errors.append(f"duplicate image test ids={duplicate_ids[:8]}")
        if len(valid_image_ids) != len(items) \
                or set(valid_image_ids) != set(inventory_list):
            errors.append(
                f"image map differs from suite inventory missing="
                f"{sorted(set(inventory_list) - set(valid_image_ids))[:8]} extra="
                f"{sorted(set(valid_image_ids) - set(inventory_list))[:8]}")
        canonical_records = sorted(
            identity_records, key=lambda item: str(item.get("test_id")))
        image_set_sha = canonical_sha256({
            "schema": PROGRAM_IMAGE_CANONICALIZATION,
            "suite": label,
            "images": canonical_records,
        })
        inventory_sha = canonical_sha256({
            "schema": "npc-rv64-test-inventory-v1",
            "suite": label,
            "test_ids": sorted(inventory_list),
        })
        return errors, observations, inventory_sha, image_set_sha, canonical_records

    def validate_suite(
        label: str,
        value: Any,
        *,
        expected_count: int,
        log_kind: str,
        require_difftest: bool,
    ) -> tuple[list[str], dict[str, Any]]:
        suite = value if isinstance(value, dict) else {}
        errors: list[str] = []
        expected_suite_keys = {
            "command", "required", "passed", "failed", "inventory",
            "inventory_sha256", "image_set_sha256", "images", "log",
        }
        if require_difftest:
            expected_suite_keys.add("difftest_enabled")
        if set(suite) != expected_suite_keys:
            errors.append(
                f"{label} suite keys differ from exact contract")
        inventory = suite.get("inventory")
        inventory_list = inventory if isinstance(inventory, list) else []
        if len(inventory_list) != len(set(inventory_list)):
            errors.append("suite inventory contains duplicates")
        if len(inventory_list) != expected_count:
            errors.append(f"suite inventory count is not {expected_count}")
        if not (
            suite.get("required") == expected_count
            and suite.get("passed") == expected_count
            and suite.get("failed") == 0
            and _is_nonempty_string(suite.get("command"))
        ):
            errors.append("suite command/count summary is incomplete")
        if require_difftest and suite.get("difftest_enabled") is not True:
            errors.append("AM suite did not enable DiffTest")
        image_errors, image_obs, inventory_sha, image_set_sha, canonical_images = (
            validate_image_set(
                label, suite.get("images"), inventory_list,
                test_log_kind=(
                    "am_test_log" if require_difftest else "official_test_log"),
                require_difftest=require_difftest,
            )
        )
        errors.extend(image_errors)
        if suite.get("inventory_sha256") != inventory_sha:
            errors.append("suite inventory_sha256 differs from recomputed exact test IDs")
        if suite.get("image_set_sha256") != image_set_sha:
            errors.append("suite image_set_sha256 differs from recomputed test-to-image map")
        suite_command_sha = sha256_bytes(
            str(suite.get("command")).encode("utf-8"))
        suite_markers = [
            *common_markers,
            f"suite={label}",
            f"inventory_sha256={inventory_sha}",
            f"image_set_sha256={image_set_sha}",
            f"command_sha256={suite_command_sha}",
        ]
        if require_difftest:
            suite_markers.extend((
                f"difftest_reference_sha256={diff_reference_sha}",
                f"difftest_reference_profile_sha256={diff_profile_sha}",
            ))
        log_obs, log_errors, log_text = _functional_log(
            root, suite.get("log"), kind=log_kind,
            required_markers=(
                *suite_markers,
                "[SUITE] PASS",
            ),
            forbidden_markers=("[SUITE] FAIL", "[TEST] FAIL"),
        )
        _register_unique_functional_log(
            root, log_obs, label, functional_log_identities, log_errors)
        errors.extend(log_errors)
        pass_ids = re.findall(r"(?m)^\[TEST\]\s+(\S+)\s+PASS\s*$", log_text)
        fail_ids = re.findall(r"(?m)^\[TEST\]\s+(\S+)\s+FAIL\s*$", log_text)
        if fail_ids:
            errors.append(f"suite raw log contains failed tests={fail_ids[:4]}")
        if len(pass_ids) != len(set(pass_ids)) or set(pass_ids) != set(inventory_list):
            errors.append("suite raw-log PASS ids differ from unique declared inventory")
        return errors, {
            "inventory": inventory_list,
            "inventory_sha256": inventory_sha,
            "image_set_sha256": image_set_sha,
            "canonical_images": canonical_images,
            "images": image_obs,
            "log": log_obs,
        }

    official_errors, official_observed = validate_suite(
        "official", functional.get("official"), expected_count=177,
        log_kind="official_suite_log", require_difftest=False)
    add_check(
        checks, blockers, "functional.official", not official_errors,
        "official RV64 suite has exact 177/177 raw-log coverage"
        if not official_errors else "; ".join(official_errors[:4]),
    )
    am_suite = functional.get("am")
    am_expected_count = (
        am_suite.get("required") if isinstance(am_suite, dict) else 0
    )
    if not isinstance(am_expected_count, int) or isinstance(am_expected_count, bool) \
            or am_expected_count < 1:
        am_expected_count = 0
    am_errors, am_observed = validate_suite(
        "am", am_suite, expected_count=am_expected_count,
        log_kind="am_suite_log", require_difftest=True)
    add_check(
        checks, blockers, "functional.am", not am_errors,
        f"AM suite has exact {am_expected_count}/{am_expected_count} "
        "raw-log coverage with DiffTest enabled"
        if not am_errors else "; ".join(am_errors[:4]),
    )
    observed["official"] = official_observed
    observed["am"] = am_observed

    diff_errors: list[str] = [
        *diff_reference_errors,
        *diff_profile_errors,
    ]
    if set(diff) != {
        "command", "applicable", "mismatches", "suite", "image_set_sha256",
        "reference", "reference_profile", "log",
    }:
        diff_errors.append("DiffTest field set differs from exact contract")
    diff_image_set_sha = am_observed.get("image_set_sha256")
    if diff.get("image_set_sha256") != diff_image_set_sha:
        diff_errors.append("DiffTest image_set_sha256 differs from the AM functional suite")
    diff_command = diff.get("command")
    diff_markers = (
        *common_markers,
        "suite=am",
        f"image_set_sha256={diff_image_set_sha}",
        f"difftest_reference_sha256={diff_reference_sha}",
        f"difftest_reference_profile_sha256={diff_profile_sha}",
        f"command_sha256={sha256_bytes(str(diff_command).encode('utf-8'))}",
        "mismatches=0",
        "[RESULT] PASS",
    )
    diff_log_obs, errors, _ = _functional_log(
        root, diff.get("log"), kind="difftest_log",
        required_markers=diff_markers, forbidden_markers=("[RESULT] FAIL",))
    _register_unique_functional_log(
        root, diff_log_obs, "difftest", functional_log_identities, errors)
    diff_errors.extend(errors)
    if not (
        diff.get("applicable") is True
        and diff.get("mismatches") == 0
        and diff.get("suite") == "am"
        and _is_nonempty_string(diff_command)
    ):
        diff_errors.append("DiffTest applicability/command/mismatch summary is invalid")
    add_check(
        checks, blockers, "functional.difftest", not diff_errors,
        "same-cohort DiffTest raw log reports zero architectural mismatches"
        if not diff_errors else "; ".join(diff_errors[:4]),
    )
    observed["difftest"] = {
        "reference": diff_reference_obs,
        "reference_profile": diff_profile_obs,
        "image_set_sha256": diff_image_set_sha,
        "log": diff_log_obs,
    }

    benchmarks = functional.get("benchmarks")
    benchmark_map = benchmarks if isinstance(benchmarks, dict) else {}
    benchmark_observed: dict[str, Any] = {}
    benchmark_errors: list[str] = []
    benchmark_requirements = {
        "coremark": {"iterations": 10, "crc": "0xfcaf", "good_traps": 1},
        "dhrystone": {"runs": 10000, "good_traps": 1},
    }
    for name, requirements in benchmark_requirements.items():
        record = benchmark_map.get(name)
        bench = record if isinstance(record, dict) else {}
        exact_benchmark_keys = {
            "command", "return_code", "image", "log", "good_traps",
            "iterations", "crc",
        } if name == "coremark" else {
            "command", "return_code", "image", "log", "good_traps", "runs",
        }
        if set(bench) != exact_benchmark_keys:
            benchmark_errors.append(f"{name}: field set differs from exact contract")
        image = bench.get("image")
        image_obs, errors = _functional_artifact_bound(
            root, image, kind="program_image",
            frozen_entries=group_map.get("images"))
        benchmark_errors.extend(f"{name}: {error}" for error in errors)
        command = bench.get("command")
        markers = [
            *common_markers,
            f"image_sha256={image.get('sha256') if isinstance(image, dict) else None}",
            f"command_sha256={sha256_bytes(str(command).encode('utf-8'))}",
            "return_code=0",
            "[RESULT] PASS",
        ]
        markers.extend(f"{key}={value}" for key, value in requirements.items())
        log_obs, errors, _ = _functional_log(
            root, bench.get("log"), kind="benchmark_log",
            required_markers=markers, forbidden_markers=("[RESULT] FAIL",))
        _register_unique_functional_log(
            root, log_obs, name, functional_log_identities, errors)
        benchmark_errors.extend(f"{name}: {error}" for error in errors)
        if not _is_nonempty_string(command) or bench.get("return_code") != 0:
            benchmark_errors.append(f"{name}: command/return_code is invalid")
        for key, expected in requirements.items():
            if bench.get(key) != expected:
                benchmark_errors.append(f"{name}: {key} must equal {expected}")
        benchmark_observed[name] = {"image": image_obs, "log": log_obs}
    add_check(
        checks, blockers, "functional.benchmarks", not benchmark_errors,
        "CoreMark CRC/iterations and Dhrystone run count are bound to GOOD TRAP logs"
        if not benchmark_errors else "; ".join(benchmark_errors[:4]),
    )
    observed["benchmarks"] = benchmark_observed
    return checks, blockers, observed


def validate_freeze_inputs(
    *,
    root: pathlib.Path,
    groups: Any,
    required_tests: list[str],
    cohort: dict[str, Any] | None,
    expected_design_id: str,
    cohort_id: str,
    run_parameters: Any,
    functional: dict[str, Any] | None,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    group_map = groups if isinstance(groups, dict) else {}
    missing_groups = sorted(REQUIRED_FREEZE_GROUPS - set(group_map))
    extra_groups = sorted(set(group_map) - REQUIRED_FREEZE_GROUPS)
    add_check(
        checks, blockers, "freeze_inputs.groups.exact",
        not missing_groups and not extra_groups,
        f"missing_groups={missing_groups} extra_groups={extra_groups}",
    )
    cohort_errors = (
        ["normative cohort inventory is missing"]
        if cohort is None else schema_errors(root, cohort, COHORT_SCHEMA)
    )
    if cohort is not None:
        if cohort.get("design_id") != expected_design_id:
            cohort_errors.append("cohort inventory design_id mismatch")
        if cohort.get("cohort_id") != cohort_id:
            cohort_errors.append("cohort inventory cohort_id mismatch")
        if cohort.get("freeze_inputs") != group_map:
            cohort_errors.append("candidate freeze_inputs differ from normative cohort inventory")
        if cohort.get("run_parameters") != run_parameters:
            cohort_errors.append("candidate run_parameters differ from normative cohort inventory")
    add_check(
        checks, blockers, "freeze_inputs.cohort_inventory",
        not cohort_errors,
        "candidate inputs and run parameters exactly match the schema-valid normative cohort"
        if not cohort_errors else "; ".join(cohort_errors[:4]),
    )

    observed: dict[str, Any] = {}
    paths_by_group: dict[str, set[str]] = {}
    all_file_identities: dict[tuple[int, int], tuple[str, str]] = {}
    for group in sorted(REQUIRED_FREEZE_GROUPS):
        values = group_map.get(group)
        values_list = values if isinstance(values, list) else []
        raw_paths = [
            item.get("path") for item in values_list if isinstance(item, dict)
        ]
        duplicate = len(raw_paths) != len(set(raw_paths)) or len(raw_paths) != len(values_list)
        artifacts: list[dict[str, Any]] = []
        errors: list[str] = []
        group_file_identities: set[tuple[int, int]] = set()
        for entry in values_list:
            artifact, item_errors = artifact_entry_observation(
                root, entry, allowed_kinds=GROUP_KINDS[group])
            artifacts.append(artifact)
            errors.extend(item_errors)
            relative = entry.get("path") if isinstance(entry, dict) else None
            if isinstance(relative, str):
                path, path_error = safe_regular_file(root, relative)
                if path_error is None and path is not None:
                    stat = path.stat()
                    identity = (stat.st_dev, stat.st_ino)
                    if identity in group_file_identities:
                        errors.append(
                            f"artifact file identity is duplicated within {group}: {relative}")
                    group_file_identities.add(identity)
                    previous = all_file_identities.get(identity)
                    if previous is not None and previous[0] != group:
                        errors.append(
                            f"artifact file identity reused across groups "
                            f"{previous[0]} and {group}: {previous[1]} / {relative}")
                    else:
                        all_file_identities[identity] = (group, relative)
        paths_by_group[group] = {
            item for item in raw_paths if isinstance(item, str)
        }
        nonempty = bool(values_list)
        add_check(
            checks, blockers, f"freeze_inputs.{group}.artifacts",
            isinstance(values, list) and nonempty and not duplicate and not errors,
            f"count={len(values_list)} duplicate={duplicate} errors={errors[:3]}",
        )
        observed[group] = artifacts

    expected = expected_input_sets(root, required_tests)
    functional_config = (
        functional.get("configuration")
        if isinstance(functional, dict) else None
    )
    functional_config_path = (
        functional_config.get("path")
        if isinstance(functional_config, dict) else None
    )
    if isinstance(functional_config_path, str):
        expected["config"] = set(expected["config"]) | {functional_config_path}
    expected_test_tops = {
        f"npc/rv64/testbench/tests/{name}.sv" for name in required_tests
    }
    absent_test_tops = sorted(
        expected_test_tops - expected.get("test_sources", set()))
    add_check(
        checks, blockers, "freeze_inputs.test_sources.required_tops",
        not absent_test_tops,
        f"missing_required_test_sources={absent_test_tops[:12]} "
        f"missing_count={len(absent_test_tops)}",
    )
    for group, expected_paths in sorted(expected.items()):
        actual_paths = paths_by_group.get(group, set())
        missing = sorted(expected_paths - actual_paths)
        extra = sorted(actual_paths - expected_paths)
        add_check(
            checks, blockers, f"freeze_inputs.{group}.exact_membership",
            not missing and not extra,
            f"missing={missing[:12]} missing_count={len(missing)} extra={extra[:12]} extra_count={len(extra)}",
        )
    config_equivalence_errors: list[str] = []
    live_config_entries = {
        item.get("path"): item
        for item in group_map.get("config", [])
        if isinstance(item, dict)
    } if isinstance(group_map.get("config"), list) else {}
    live_config = live_config_entries.get("npc/rv64/.config")
    execution_config = live_config_entries.get(functional_config_path)
    if not isinstance(live_config, dict):
        config_equivalence_errors.append("live npc/rv64/.config is not frozen")
    if not isinstance(functional_config_path, str) or not isinstance(
        execution_config, dict
    ):
        config_equivalence_errors.append(
            "functional execution configuration is not frozen")
    if (
        isinstance(live_config, dict)
        and isinstance(execution_config, dict)
        and live_config.get("sha256") != execution_config.get("sha256")
    ):
        config_equivalence_errors.append(
            "live and functional execution configuration hashes differ")
    add_check(
        checks, blockers, "freeze_inputs.config.execution_equivalence",
        not config_equivalence_errors,
        "live Kconfig and frozen functional execution Kconfig are byte-equivalent"
        if not config_equivalence_errors else "; ".join(config_equivalence_errors),
    )
    workflow_paths = paths_by_group.get("workflow", set())
    required_workflow_paths = set(WORKFLOW_BINDING_PATHS)
    add_check(
        checks, blockers, "freeze_inputs.workflow.exact_membership",
        workflow_paths == required_workflow_paths,
        f"missing={sorted(required_workflow_paths - workflow_paths)} "
        f"extra={sorted(workflow_paths - required_workflow_paths)}",
    )

    tool_errors: list[str] = []
    tool_entries = group_map.get("tool_versions")
    if isinstance(tool_entries, list) and len(tool_entries) == 1 \
            and isinstance(tool_entries[0], dict):
        tool_path, error = safe_regular_file(root, tool_entries[0].get("path"))
        if error or tool_path is None:
            tool_errors.append(error or "tool version manifest missing")
        else:
            try:
                tool_manifest = load_json(tool_path)
                tools = tool_manifest.get("tools")
                required_tools = set(TOOL_VERSION_ARGS)
                if tool_manifest.get("schema") != "npc-rv64-tool-versions-v1" \
                        or not isinstance(tools, dict) or set(tools) != required_tools:
                    tool_errors.append("tool manifest schema or exact tool set is invalid")
                else:
                    for name, record in sorted(tools.items()):
                        if not isinstance(record, dict) or set(record) != {
                            "path", "version", "version_output_sha256",
                            "executable_sha256",
                        }:
                            tool_errors.append(f"{name}: tool entry key set is invalid")
                            continue
                        path_value = record.get("path")
                        if not isinstance(path_value, str) or not pathlib.Path(
                            path_value
                        ).is_absolute():
                            tool_errors.append(
                                f"{name}: recorded executable path is not absolute")
                            continue
                        try:
                            executable = pathlib.Path(path_value).resolve(strict=True)
                            if not executable.is_file() or not os.access(
                                executable, os.X_OK
                            ):
                                tool_errors.append(
                                    f"{name}: recorded executable is not runnable")
                                continue
                            completed = subprocess.run(
                                [str(executable), *TOOL_VERSION_ARGS[name]],
                                check=False,
                                capture_output=True,
                                timeout=10,
                            )
                            version_output = completed.stdout + completed.stderr
                            version_text = version_output.decode(
                                "utf-8", errors="replace").strip()
                            if completed.returncode != 0:
                                tool_errors.append(
                                    f"{name}: version command returned {completed.returncode}")
                            if path_value != executable.as_posix():
                                tool_errors.append(
                                    f"{name}: recorded executable path is not canonical")
                            if record.get("executable_sha256") != sha256_file(executable):
                                tool_errors.append(f"{name}: executable hash drifted")
                            if record.get("version_output_sha256") != sha256_bytes(version_output):
                                tool_errors.append(f"{name}: version output hash drifted")
                            if not _is_nonempty_string(record.get("version")) \
                                    or record["version"] not in version_text:
                                tool_errors.append(f"{name}: declared version is absent from output")
                        except (OSError, subprocess.SubprocessError) as exc:
                            tool_errors.append(f"{name}: {exc}")
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                tool_errors.append(str(exc))
    else:
        tool_errors.append("exactly one tool_version_manifest is required")
    add_check(
        checks, blockers, "freeze_inputs.tool_versions.semantic",
        not tool_errors,
        "exact six-tool absolute paths, executable hashes and live version outputs verified independent of caller PATH"
        if not tool_errors else "; ".join(tool_errors[:3]),
    )

    liberty_paths = paths_by_group.get("liberty", set())
    liberty_errors = [path for path in liberty_paths if pathlib.PurePosixPath(path).suffix != ".lib"]
    add_check(
        checks, blockers, "freeze_inputs.liberty.semantic",
        bool(liberty_paths) and not liberty_errors,
        f"non_liberty_paths={liberty_errors}",
    )

    macro_errors: list[str] = []
    macro_entries = group_map.get("macros")
    if isinstance(macro_entries, list) and len(macro_entries) == 1 \
            and isinstance(macro_entries[0], dict):
        macro_path, error = safe_regular_file(root, macro_entries[0].get("path"))
        if error or macro_path is None:
            macro_errors.append(error or "macro inventory missing")
        else:
            try:
                macro_manifest = load_json(macro_path)
                macros = macro_manifest.get("macros")
                if macro_manifest.get("schema") != "npc-rv64-macro-inventory-v1" \
                        or not isinstance(macros, list) or not macros:
                    macro_errors.append("macro inventory schema or entries are invalid")
                elif any(
                    not isinstance(item, dict)
                    or set(item) != {"name", "liberty_path", "qualification"}
                    or not _is_nonempty_string(item.get("name"))
                    or item.get("liberty_path") not in liberty_paths
                    or item.get("qualification") not in {"qualified", "placeholder"}
                    for item in macros
                ):
                    macro_errors.append("macro entry does not bind a declared Liberty model")
            except (OSError, ValueError, json.JSONDecodeError) as exc:
                macro_errors.append(str(exc))
    else:
        macro_errors.append("exactly one macro_inventory is required")
    add_check(
        checks, blockers, "freeze_inputs.macros.semantic",
        not macro_errors,
        "macro inventory is exact and cross-bound to Liberty inputs"
        if not macro_errors else "; ".join(macro_errors[:3]),
    )

    constraint_errors: list[str] = []
    constraint_entries = group_map.get("constraints")
    if isinstance(constraint_entries, list) and len(constraint_entries) == 1 \
            and isinstance(constraint_entries[0], dict):
        constraint_path, error = safe_regular_file(root, constraint_entries[0].get("path"))
        if error or constraint_path is None:
            constraint_errors.append(error or "primary SDC missing")
        else:
            text = constraint_path.read_text(encoding="utf-8")
            period = run_parameters.get("period_ns") if isinstance(run_parameters, dict) else None
            clock = run_parameters.get("clock_port") if isinstance(run_parameters, dict) else None
            if constraint_path.suffix != ".sdc" or "create_clock" not in text:
                constraint_errors.append("primary constraint must be an SDC with create_clock")
            if not isinstance(period, (int, float)) or re.search(
                rf"-period\s+{re.escape(format(float(period), 'g'))}(?:\.0+)?\b", text
            ) is None:
                constraint_errors.append("SDC period does not match frozen period_ns")
            if not isinstance(clock, str) or re.search(rf"\b{re.escape(clock)}\b", text) is None:
                constraint_errors.append("SDC clock port does not match frozen clock_port")
    else:
        constraint_errors.append("exactly one primary_sdc is required")
    add_check(
        checks, blockers, "freeze_inputs.constraints.semantic",
        not constraint_errors,
        "primary SDC create_clock matches frozen clock and period"
        if not constraint_errors else "; ".join(constraint_errors[:3]),
    )

    binary_errors: list[str] = []
    for entry in group_map.get("binaries", []) if isinstance(group_map.get("binaries"), list) else []:
        if not isinstance(entry, dict):
            continue
        path, error = safe_regular_file(root, entry.get("path"))
        if error or path is None or path.stat().st_mode & 0o111 == 0:
            binary_errors.append(error or f"simulator binary is not executable: {entry.get('path')}")
    add_check(
        checks, blockers, "freeze_inputs.binaries.semantic",
        bool(paths_by_group.get("binaries")) and not binary_errors,
        "simulator binaries are exact regular executable artifacts"
        if not binary_errors else "; ".join(binary_errors[:3]),
    )
    observed["derived_required_module_count"] = len(required_tests)
    observed["derived_required_module_tests"] = required_tests
    observed["artifact_hashes_by_group"] = {
        group: sorted(
            artifact.get("sha256") for artifact in observed.get(group, [])
            if isinstance(artifact, dict)
            and isinstance(artifact.get("sha256"), str)
        )
        for group in sorted(REQUIRED_FREEZE_GROUPS)
    }
    return checks, blockers, observed


def validate_run_parameters(value: Any) -> tuple[list[dict[str, Any]], list[str]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    params = value if isinstance(value, dict) else {}
    period = params.get("period_ns")
    valid = (
        set(params) == {
            "top", "clock_port", "period_ns", "synthesis_seed", "threads"
        }
        and _is_nonempty_string(params.get("top"))
        and _is_nonempty_string(params.get("clock_port"))
        and isinstance(period, (int, float))
        and not isinstance(period, bool)
        and math.isfinite(period)
        and period > 0
        and isinstance(params.get("synthesis_seed"), int)
        and not isinstance(params.get("synthesis_seed"), bool)
        and isinstance(params.get("threads"), int)
        and not isinstance(params.get("threads"), bool)
        and params["threads"] > 0
    )
    add_check(
        checks, blockers, "run_parameters.complete", valid,
        "top/clock/positive period/integer seed/positive threads must be frozen exactly",
    )
    return checks, blockers


def validate_claim(value: Any) -> tuple[list[dict[str, Any]], list[str]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    claim = value if isinstance(value, dict) else {}
    safe = (
        claim.get("architecture_freeze") in {"GAP", "ARCH_STABLE"}
        and claim.get("ppa") == "UNQUALIFIED"
        and claim.get("promotion_eligible") is False
        and claim.get("canonical") is None
        and claim.get("architecture_feasible_seed") is None
    )
    add_check(
        checks, blockers, "claim.architecture_only", safe,
        "arch-stable audit must keep PPA UNQUALIFIED, promotion false, canonical/seed null",
    )
    return checks, blockers


INDEPENDENT_REVIEW_SCOPE = {
    "architecture_prerequisites": "PASS",
    "producer_holder_static_semantic_dynamic": "PASS",
    "ppa": "UNQUALIFIED",
    "promotion_eligible": False,
}


def _review_artifact_binding(
    root: pathlib.Path,
    value: Any,
    *,
    expected_kind: str,
) -> tuple[dict[str, Any] | None, list[str]]:
    if not isinstance(value, dict) or set(value) != {
        "kind", "path", "sha256", "size_bytes"
    }:
        return None, [f"{expected_kind} artifact fields are not exact"]
    if value.get("kind") != expected_kind:
        return None, [f"{expected_kind} artifact kind drifted"]
    observed, errors = artifact_observation(root, value.get("path"))
    if errors:
        return None, errors
    expected = {
        "kind": expected_kind,
        "path": observed["path"],
        "sha256": observed["sha256"],
        "size_bytes": observed["size_bytes"],
    }
    if value != expected:
        return None, [f"{expected_kind} artifact hash or size drifted"]
    return expected, []


def validate_independent_review(
    *,
    root: pathlib.Path,
    review_path: pathlib.Path | None,
    candidate_artifact: dict[str, Any],
    expected_design_id: str,
) -> tuple[list[dict[str, Any]], list[str], dict[str, Any]]:
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {"required": True}
    errors: list[str] = []
    if review_path is None:
        add_check(
            checks, blockers, "independent_review.exact_binding", False,
            "ARCH_STABLE requires an independent review receipt bound to the exact candidate",
        )
        observed["receipt"] = {"path": None, "status": "MISSING"}
        return checks, blockers, observed

    try:
        review_relative = review_path.resolve().relative_to(
            root.resolve()).as_posix()
    except (OSError, ValueError):
        review_relative = str(review_path)
        errors.append("independent review receipt escapes the workspace")
    receipt_artifact, receipt_errors = artifact_observation(
        root, review_relative)
    errors.extend(receipt_errors)
    observed["receipt"] = receipt_artifact
    receipt: dict[str, Any] | None = None
    if not receipt_errors:
        receipt_file, _ = safe_regular_file(root, review_relative)
        assert receipt_file is not None
        try:
            receipt = load_json(receipt_file)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"independent review receipt is not parseable: {exc}")
    if receipt is not None:
        errors.extend(schema_errors(root, receipt, INDEPENDENT_REVIEW_SCHEMA))
        expected_candidate = {
            "kind": "arch_stable_candidate",
            "path": candidate_artifact.get("path"),
            "sha256": candidate_artifact.get("sha256"),
            "size_bytes": candidate_artifact.get("size_bytes"),
        }
        if receipt.get("design_id") != expected_design_id:
            errors.append("independent review design identity drifted")
        if receipt.get("candidate") != expected_candidate:
            errors.append("independent review candidate binding drifted")
        if receipt.get("decision") != "APPROVE_ARCH_STABLE":
            errors.append("independent review decision is not APPROVE_ARCH_STABLE")
        if receipt.get("review_scope") != INDEPENDENT_REVIEW_SCOPE:
            errors.append("independent review scope or PPA boundary drifted")
        if receipt.get("open_blockers") != [] or receipt.get("unknowns") != []:
            errors.append("independent review retains blockers or unknowns")
        evidence = receipt.get("evidence")
        by_kind = {
            item.get("kind"): item
            for item in evidence
            if isinstance(item, dict)
        } if isinstance(evidence, list) else {}
        if set(by_kind) != {"rtl_task_contract", "independent_review_report"}:
            errors.append("independent review evidence inventory is not exact")
        else:
            bound_evidence: dict[str, dict[str, Any]] = {}
            for kind in sorted(by_kind):
                binding, binding_errors = _review_artifact_binding(
                    root, by_kind[kind], expected_kind=kind)
                errors.extend(binding_errors)
                if binding is not None:
                    bound_evidence[kind] = binding
            observed["evidence"] = bound_evidence
            marker = (
                "[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] "
                f"design_id={expected_design_id} "
                f"candidate_sha256={candidate_artifact.get('sha256')}"
            )
            for kind in ("rtl_task_contract", "independent_review_report"):
                binding = bound_evidence.get(kind)
                if binding is None:
                    continue
                evidence_file, _ = safe_regular_file(root, binding["path"])
                assert evidence_file is not None
                text = evidence_file.read_text(encoding="utf-8")
                if text.count(marker) != 1:
                    errors.append(
                        f"{kind} lacks one exact candidate/design approval marker")
        observed["decision"] = receipt.get("decision")
        observed["reviewer_task"] = receipt.get("reviewer_task")
        observed["review_scope"] = receipt.get("review_scope")

    add_check(
        checks, blockers, "independent_review.exact_binding", not errors,
        "independent reviewer receipt, contract and report bind the exact candidate/design with PPA unqualified"
        if not errors else "; ".join(errors[:6]),
    )
    return checks, blockers, observed


def _load_referenced_json(
    *,
    root: pathlib.Path,
    relative: Any,
    label: str,
    checks: list[dict[str, Any]],
    blockers: list[str],
    observations: dict[str, Any],
) -> dict[str, Any] | None:
    artifact, errors = artifact_observation(root, relative)
    observations[label] = artifact
    if errors:
        add_check(checks, blockers, f"artifact.{label}", False, errors[0])
        return None
    path, _ = safe_regular_file(root, relative)
    assert path is not None
    try:
        value = load_json(path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        add_check(checks, blockers, f"artifact.{label}", False, str(error))
        return None
    add_check(checks, blockers, f"artifact.{label}", True, "present, regular and parseable")
    return value


def evaluate_candidate(
    *,
    root: pathlib.Path,
    candidate_path: pathlib.Path,
    review_path: pathlib.Path | None = None,
    generated_at_utc: str | None = None,
) -> dict[str, Any]:
    candidate = load_json(candidate_path)
    checks: list[dict[str, Any]] = []
    blockers: list[str] = []
    observed: dict[str, Any] = {}
    candidate_relative = candidate_path.resolve().relative_to(root.resolve()).as_posix()
    candidate_artifact, candidate_errors = artifact_observation(root, candidate_relative)
    observed["candidate"] = candidate_artifact
    for error in candidate_errors:
        add_check(checks, blockers, "candidate.path", False, error)
    candidate_schema_errors = schema_errors(root, candidate, CANDIDATE_SCHEMA)
    add_check(
        checks, blockers, "candidate.json_schema",
        not candidate_schema_errors,
        "valid Draft 2020-12 candidate declaration"
        if not candidate_schema_errors else "; ".join(candidate_schema_errors[:4]),
    )
    add_check(
        checks, blockers, "candidate.schema",
        candidate.get("schema") == CANDIDATE_SCHEMA,
        f"expected {CANDIDATE_SCHEMA}",
    )
    design_id = candidate.get("design_id")
    add_check(
        checks, blockers, "candidate.design_id",
        isinstance(design_id, str) and DESIGN_ID_RE.fullmatch(design_id) is not None,
        "design_id must be sha256:<64 lowercase hex>",
    )
    expected_design_id = design_id if isinstance(design_id, str) else ""
    scope = candidate.get("scope")
    scope_map = scope if isinstance(scope, dict) else {}
    excluded = scope_map.get("excluded_debt_ids")
    excluded_ids = set(excluded) if isinstance(excluded, list) and all(
        isinstance(item, str) for item in excluded) else set()
    scope_ok = (
        _is_nonempty_string(scope_map.get("cohort_id"))
        and _is_nonempty_string(scope_map.get("product"))
        and isinstance(excluded, list)
        and len(excluded) == len(excluded_ids)
    )
    add_check(
        checks, blockers, "candidate.scope", scope_ok,
        "cohort_id/product/exact excluded_debt_ids are required",
    )

    refs = candidate.get("artifacts")
    refs_map = refs if isinstance(refs, dict) else {}
    expected_refs = {
        "debt_ledger", "architecture_evidence", "architecture_result",
        "holder_census", "functional_aggregate", "cohort_inventory",
        "system_recertification",
    }
    add_check(
        checks, blockers, "candidate.artifacts.exact",
        set(refs_map) == expected_refs,
        f"missing={sorted(expected_refs - set(refs_map))} extra={sorted(set(refs_map) - expected_refs)}",
    )
    referenced: dict[str, dict[str, Any] | None] = {}
    for label in sorted(expected_refs):
        relative = refs_map.get(label)
        if relative is None and label in {"functional_aggregate", "cohort_inventory"}:
            referenced[label] = None
            observed[label] = {"path": None, "status": "MISSING"}
            continue
        referenced[label] = _load_referenced_json(
            root=root,
            relative=relative,
            label=label,
            checks=checks,
            blockers=blockers,
            observations=observed,
        )

    ledger = referenced.get("debt_ledger")
    if ledger is not None:
        subchecks, subblockers, subobserved = validate_debt_ledger(
            root=root,
            ledger=ledger,
            expected_design_id=expected_design_id,
            cohort_id=str(scope_map.get("cohort_id", "")),
            excluded_debt_ids=excluded_ids,
        )
        checks.extend(subchecks)
        blockers.extend(subblockers)
        observed["debt"] = subobserved

    try:
        historical_module = load_workspace_module(
            root,
            "npc/rv64/eval/ppa/tools/historical_defect_backfill.py",
            "historical_defect_backfill_audit",
        )
        historical = historical_module.audit(
            root,
            expected_design_id=expected_design_id,
        )
    except (OSError, ValueError, AttributeError, json.JSONDecodeError) as exc:
        historical = {
            "valid": False,
            "status": "INVALID",
            "blocking_ids": [],
            "errors": [str(exc)],
        }
    historical_errors = historical.get("errors")
    historical_error_list = (
        historical_errors if isinstance(historical_errors, list) else []
    )
    add_check(
        checks,
        blockers,
        "historical_defect_backfill.valid",
        historical.get("valid") is True,
        "historical-defect ledger is schema/hash/selection valid"
        if historical.get("valid") is True
        else "; ".join(str(item) for item in historical_error_list[:4]),
    )
    add_check(
        checks,
        blockers,
        "historical_defect_backfill.vd0_vd1_clear",
        historical.get("status") == "PASS",
        "no VD0/VD1 historical defects remain"
        if historical.get("status") == "PASS"
        else (
            "blocking historical defects="
            f"{historical.get('blocking_ids', [])}; "
            f"selected={historical.get('selected_id')}"
        ),
    )
    observed["historical_defect_backfill"] = historical

    architecture_evidence_path, _ = safe_regular_file(
        root, refs_map.get("architecture_evidence"))
    arch_checks, arch_blockers, arch_observed = validate_architecture(
        root=root,
        evidence=referenced.get("architecture_evidence"),
        result=referenced.get("architecture_result"),
        evidence_path=architecture_evidence_path,
        expected_design_id=expected_design_id,
    )
    checks.extend(arch_checks)
    blockers.extend(arch_blockers)
    observed["architecture"] = arch_observed

    census_path, _ = safe_regular_file(root, refs_map.get("holder_census"))
    census_checks, census_blockers, census_observed = validate_census(
        root,
        referenced.get("holder_census"),
        census_path,
        expected_design_id,
    )
    checks.extend(census_checks)
    blockers.extend(census_blockers)
    observed["census"] = census_observed

    system_path, _ = safe_regular_file(
        root, refs_map.get("system_recertification"))
    system_checks, system_blockers, system_observed = (
        validate_system_recertification(
            root=root,
            receipt=referenced.get("system_recertification"),
            receipt_path=system_path,
            expected_design_id=expected_design_id,
        )
    )
    checks.extend(system_checks)
    blockers.extend(system_blockers)
    observed["system_recertification"] = system_observed

    test_makefile = root / "npc/rv64/testbench/Makefile"
    required_tests, inventory_errors = parse_required_tests(
        test_makefile.read_text(encoding="utf-8")
        if test_makefile.is_file() else "")
    for error in inventory_errors:
        add_check(checks, blockers, "functional.module_inventory_source", False, error)
    if not inventory_errors:
        add_check(
            checks, blockers, "functional.module_inventory_source", True,
            f"derived {len(required_tests)} required tests from current TESTS assignment",
        )

    func_checks, func_blockers, func_observed = validate_functional(
        root=root,
        functional=referenced.get("functional_aggregate"),
        expected_design_id=expected_design_id,
        cohort_id=str(scope_map.get("cohort_id", "")),
        required_tests=required_tests,
        freeze_groups=candidate.get("freeze_inputs"),
    )
    checks.extend(func_checks)
    blockers.extend(func_blockers)
    observed["functional"] = func_observed

    input_checks, input_blockers, input_observed = validate_freeze_inputs(
        root=root,
        groups=candidate.get("freeze_inputs"),
        required_tests=required_tests,
        cohort=referenced.get("cohort_inventory"),
        expected_design_id=expected_design_id,
        cohort_id=str(scope_map.get("cohort_id", "")),
        run_parameters=candidate.get("run_parameters"),
        functional=referenced.get("functional_aggregate"),
    )
    checks.extend(input_checks)
    blockers.extend(input_blockers)
    observed["freeze_inputs"] = input_observed

    parameter_checks, parameter_blockers = validate_run_parameters(
        candidate.get("run_parameters"))
    checks.extend(parameter_checks)
    blockers.extend(parameter_blockers)
    claim_checks, claim_blockers = validate_claim(candidate.get("claim"))
    checks.extend(claim_checks)
    blockers.extend(claim_blockers)

    claim = candidate.get("claim") if isinstance(candidate.get("claim"), dict) else {}
    if claim.get("architecture_freeze") == "ARCH_STABLE":
        review_checks, review_blockers, review_observed = (
            validate_independent_review(
                root=root,
                review_path=review_path,
                candidate_artifact=candidate_artifact,
                expected_design_id=expected_design_id,
            )
        )
        checks.extend(review_checks)
        blockers.extend(review_blockers)
        observed["independent_review"] = review_observed
    else:
        observed["independent_review"] = {
            "required": False,
            "status": "NOT_APPLICABLE_TO_GAP_DECLARATION",
        }

    workflow_observed: dict[str, Any] = {}
    workflow_errors: list[str] = []
    for relative in WORKFLOW_BINDING_PATHS:
        artifact, errors = artifact_observation(root, relative)
        workflow_observed[relative] = artifact
        workflow_errors.extend(errors)
    add_check(
        checks, blockers, "workflow.exact_binding", not workflow_errors,
        f"bound {len(WORKFLOW_BINDING_PATHS)} checker/runner/schema/test artifacts"
        if not workflow_errors else "; ".join(workflow_errors[:4]),
    )
    observed["workflow"] = workflow_observed

    prereq_blockers = list(dict.fromkeys(blockers))
    prerequisites_green = not prereq_blockers
    issued = prerequisites_green and claim.get("architecture_freeze") == "ARCH_STABLE"
    if prerequisites_green and not issued:
        prereq_blockers.append(
            "claim.issue: all prerequisites are GREEN but declaration has not issued ARCH_STABLE")
    result_core = {
        "schema": RESULT_SCHEMA,
        "candidate": candidate_artifact,
        "design_id": expected_design_id,
        "scope": scope_map,
        "architecture_freeze": "ARCH_STABLE" if issued else "GAP",
        "ppa": "UNQUALIFIED",
        "promotion_eligible": False,
        "checks": checks,
        "blockers": prereq_blockers,
        "observed": observed,
    }
    result_core["evaluation_sha256"] = canonical_sha256(result_core)
    result = {
        **result_core,
        "generated_at_utc": generated_at_utc or dt.datetime.now(
            dt.timezone.utc).isoformat(),
    }
    result_schema_errors = schema_errors(root, result, RESULT_SCHEMA)
    if result_schema_errors:
        raise RuntimeError(
            "internal result does not satisfy its JSON schema: "
            + "; ".join(result_schema_errors[:4]))
    return result


def _captured_review_artifact(
    root: pathlib.Path, path: pathlib.Path, kind: str,
) -> dict[str, Any]:
    try:
        relative = path.resolve().relative_to(root.resolve()).as_posix()
    except (OSError, ValueError) as exc:
        raise RuntimeError(f"{kind} escapes the workspace") from exc
    observed, errors = artifact_observation(root, relative)
    if errors:
        raise RuntimeError(f"invalid {kind}: {errors[0]}")
    return {
        "kind": kind,
        "path": relative,
        "sha256": observed["sha256"],
        "size_bytes": observed["size_bytes"],
    }


def build_independent_review_receipt(
    *,
    root: pathlib.Path,
    candidate_path: pathlib.Path,
    contract_path: pathlib.Path,
    report_path: pathlib.Path,
    reviewer_task: str,
    reviewed_at_utc: str,
) -> dict[str, Any]:
    candidate = load_json(candidate_path)
    if candidate.get("claim", {}).get("architecture_freeze") != "ARCH_STABLE":
        raise RuntimeError(
            "independent ARCH_STABLE review receipt requires an ARCH_STABLE declaration")
    preflight = evaluate_candidate(
        root=root,
        candidate_path=candidate_path,
        review_path=None,
        generated_at_utc=reviewed_at_utc,
    )
    blockers = preflight.get("blockers")
    if not isinstance(blockers, list) or len(blockers) != 1 or not str(
        blockers[0]).startswith("independent_review.exact_binding:"):
        raise RuntimeError(
            "candidate prerequisites are not green before independent review: "
            f"{blockers}")
    candidate_binding = _captured_review_artifact(
        root, candidate_path, "arch_stable_candidate")
    evidence = [
        _captured_review_artifact(root, contract_path, "rtl_task_contract"),
        _captured_review_artifact(
            root, report_path, "independent_review_report"),
    ]
    marker = (
        "[ARCH-STABLE-INDEPENDENT-REVIEW][APPROVE] "
        f"design_id={candidate.get('design_id')} "
        f"candidate_sha256={candidate_binding['sha256']}"
    )
    for entry in evidence:
        evidence_file, _ = safe_regular_file(root, entry["path"])
        assert evidence_file is not None
        if evidence_file.read_text(encoding="utf-8").count(marker) != 1:
            raise RuntimeError(
                f"{entry['kind']} must contain exactly one approval marker: {marker}")
    receipt = {
        "schema": INDEPENDENT_REVIEW_SCHEMA,
        "decision": "APPROVE_ARCH_STABLE",
        "design_id": candidate.get("design_id"),
        "candidate": candidate_binding,
        "reviewer_task": reviewer_task,
        "review_scope": dict(INDEPENDENT_REVIEW_SCOPE),
        "evidence": sorted(evidence, key=lambda item: item["kind"]),
        "open_blockers": [],
        "unknowns": [],
        "reviewed_at_utc": reviewed_at_utc,
    }
    errors = schema_errors(root, receipt, INDEPENDENT_REVIEW_SCHEMA)
    if errors:
        raise RuntimeError(
            "generated independent review receipt is invalid: "
            + "; ".join(errors[:4]))
    return receipt


def write_json(path: pathlib.Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    try:
        temporary.write_text(
            json.dumps(
                value,
                allow_nan=False,
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            ) + "\n",
            encoding="utf-8",
        )
        load_json(temporary)
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()


def verify_result(
    *, root: pathlib.Path, result_path: pathlib.Path
) -> tuple[dict[str, Any] | None, list[str]]:
    errors: list[str] = []
    stored = load_json(result_path)
    stored_schema_errors = schema_errors(root, stored, RESULT_SCHEMA)
    if stored_schema_errors:
        return None, [
            "stored result schema violation: " + "; ".join(stored_schema_errors[:4])
        ]
    if stored.get("schema") != RESULT_SCHEMA:
        return None, [f"unsupported result schema: {stored.get('schema')!r}"]
    candidate = stored.get("candidate")
    if not isinstance(candidate, dict):
        return None, ["result candidate artifact is missing"]
    relative = candidate.get("path")
    path, error = safe_regular_file(root, relative)
    if error or path is None:
        return None, [error or "candidate path is invalid"]
    if candidate.get("sha256") != sha256_file(path):
        errors.append("candidate declaration hash drifted")
    review_path: pathlib.Path | None = None
    if stored.get("architecture_freeze") == "ARCH_STABLE":
        independent_review = stored.get("observed", {}).get(
            "independent_review", {})
        review_relative = independent_review.get("receipt", {}).get("path")
        if isinstance(review_relative, str):
            review_path = root / review_relative
    fresh = evaluate_candidate(
        root=root,
        candidate_path=path,
        review_path=review_path,
        generated_at_utc=stored.get("generated_at_utc"),
    )
    if stored.get("evaluation_sha256") != fresh.get("evaluation_sha256"):
        errors.append("stored evaluation no longer matches current exact inputs")
    stored_without_time = {
        key: value for key, value in stored.items() if key != "generated_at_utc"
    }
    fresh_without_time = {
        key: value for key, value in fresh.items() if key != "generated_at_utc"
    }
    if stored_without_time != fresh_without_time:
        errors.append("stored result content differs from recomputed evaluation")
    return fresh, errors


def _print_summary(result: dict[str, Any]) -> None:
    print(
        f"[ARCH-STABLE] status={result.get('architecture_freeze')} "
        f"ppa={result.get('ppa')} "
        f"promotion_eligible={str(result.get('promotion_eligible')).lower()} "
        f"blockers={len(result.get('blockers', []))}"
    )
    for blocker in result.get("blockers", [])[:20]:
        print(f"[ARCH-STABLE-GAP] {blocker}")
    if len(result.get("blockers", [])) > 20:
        print(
            f"[ARCH-STABLE-GAP] ... "
            f"{len(result['blockers']) - 20} additional blockers in JSON result")


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    audit = subparsers.add_parser("audit", help="build a current exact-input audit result")
    audit.add_argument("candidate", type=pathlib.Path)
    audit.add_argument("--output", type=pathlib.Path, required=True)
    audit.add_argument("--review", type=pathlib.Path)
    audit.add_argument("--require-stable", action="store_true")
    verify = subparsers.add_parser("verify", help="recompute and verify a stored audit result")
    verify.add_argument("result", type=pathlib.Path)
    verify.add_argument("--require-stable", action="store_true")
    review_receipt = subparsers.add_parser(
        "review-receipt",
        help="bind an independent review contract/report to one exact candidate",
    )
    review_receipt.add_argument("candidate", type=pathlib.Path)
    review_receipt.add_argument("--contract", type=pathlib.Path, required=True)
    review_receipt.add_argument("--report", type=pathlib.Path, required=True)
    review_receipt.add_argument("--reviewer-task", required=True)
    review_receipt.add_argument("--output", type=pathlib.Path, required=True)
    review_receipt.add_argument("--reviewed-at-utc")
    args = parser.parse_args(list(argv) if argv is not None else None)

    try:
        if args.command == "audit":
            root = find_repo_root(args.candidate)
            candidate = args.candidate.resolve()
            candidate.relative_to(root.resolve())
            review = args.review.resolve() if args.review is not None else None
            result = evaluate_candidate(
                root=root, candidate_path=candidate, review_path=review)
            write_json(args.output, result)
            _print_summary(result)
            return 2 if args.require_stable and result["architecture_freeze"] != "ARCH_STABLE" else 0

        if args.command == "review-receipt":
            root = find_repo_root(args.candidate)
            candidate = args.candidate.resolve()
            candidate.relative_to(root.resolve())
            receipt = build_independent_review_receipt(
                root=root,
                candidate_path=candidate,
                contract_path=args.contract.resolve(),
                report_path=args.report.resolve(),
                reviewer_task=args.reviewer_task,
                reviewed_at_utc=args.reviewed_at_utc or dt.datetime.now(
                    dt.timezone.utc).isoformat(),
            )
            write_json(args.output, receipt)
            print(
                "[ARCH-STABLE-INDEPENDENT-REVIEW][PASS] "
                f"design_id={receipt['design_id']} "
                f"candidate_sha256={receipt['candidate']['sha256']}")
            return 0

        root = find_repo_root(args.result)
        result, errors = verify_result(root=root, result_path=args.result.resolve())
        if errors:
            for error in errors:
                print(f"[ARCH-STABLE-VERIFY-ERROR] {error}", file=sys.stderr)
            return 1
        assert result is not None
        _print_summary(result)
        return 2 if args.require_stable and result["architecture_freeze"] != "ARCH_STABLE" else 0
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(f"[ARCH-STABLE-ERROR] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
