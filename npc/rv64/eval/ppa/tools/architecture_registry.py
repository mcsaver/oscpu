#!/usr/bin/env python3
"""Single-entry ownership and evidence registry for the local RV64 product.

The canonical JSON stores human intent: ownership, product role, capability
membership and physical-boundary contracts.  Inventory, Git lifecycle,
filelist membership, elaboration reachability and evidence visibility are
derived facts.  ``npc/rv64/ARCHITECTURE.md`` is the only human review entry and
is generated from one joined snapshot; generated views are never edited by
hand.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import math
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


SCHEMA = "npc-rv64-architecture-registry-v1"
ELAB_SCHEMA = "npc-rv64-architecture-elaboration-receipt-v1"
MAPPED_BINDING_SCHEMA = "npc-rv64-mapped-architecture-binding-v3"
RUN_PARAMETER_CONTRACT_ID = "npctop-traceable-mapped-5ns-v1"
FOUR_PLACEHOLDER_CONFIGURATION = "mapped-5ns-four-placeholder-v1"
BPU_INLINE_CONFIGURATION = "mapped-5ns-bpu-inline-v1"
BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION = (
    "mapped-5ns-bpu-local-pht-banked-child-inline-v1"
)
BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION = (
    "mapped-5ns-bpu-local-pht-write-banked-flat-read-view-inline-v1"
)
FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION = (
    "mapped-5ns-fp-arith-production-children-inline-v1"
)
FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION = (
    "mapped-5ns-fp-arith-production-children-ooc-boundary-v1"
)
MAPPED_ARTIFACT_PROFILE_NONE = "none"
MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT = "bpu-local-pht-v1"
MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN = "fp-arith-children-v1"
MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE = "fp-arith-ooc-composite-v1"
MAPPED_ARTIFACT_PROFILES = {
    MAPPED_ARTIFACT_PROFILE_NONE,
    MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT,
    MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN,
    MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE,
}
MAPPED_ARTIFACT_FILENAMES = {
    MAPPED_ARTIFACT_PROFILE_NONE: [],
    MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT: [
        "opensta-bpu-negative-slack.tsv",
        "opensta-bpu-update-fanout.tsv",
    ],
    MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN: [
        "opensta-fp-negative-slack.tsv",
        "opensta-fp-internal-paths.rpt",
    ],
    MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE: [
        "fp-ooc-composite-summary.json",
        "fp-ooc-composite-validation-receipt.json",
    ],
}
EXPECTED_B279_DESIGN_ID = (
    "sha256:b279d4bc209013144ea4075aa7102119a28ee2b77f797a98717401bc9272697e"
)
EXPECTED_F5F2_DESIGN_ID = (
    "sha256:f5f2a00a34a25262f9913abda384a197f751afc94cf424e896c7414a65b92eb8"
)
EXPECTED_LIVE_DESIGN_ID = (
    "sha256:9d8bb6af7534717f6ed4b9f93b14f63aef407f5b2bc57feb43aef37ccbfbef5d"
)
FROZEN_B279_MAPPED_SUMMARY = (
    ".github/task-runs/2026-08-10-rv64-bpu-local-pht-banked-child-ppa-b279-a1/"
    "evidence/traceable-b279-bpu-local-pht-banked-child-a1/summary.json"
)
FROZEN_B279_MAPPED_SUMMARY_SHA256 = (
    "fc752a737d3b05edd8ff9f4fe6c94af4b324357bb2857c6c2ea8f7984b62d802"
)
FAILED_F5F2_STATUS = (
    ".github/task-runs/2026-08-10-rv64-bpu-flat-read-view-ppa-f5f2-a1/"
    "traceable-f5f2-bpu-flat-read-view-a1.status"
)
FAILED_F5F2_STATUS_SHA256 = (
    "f923a8ae87f26025bdec54301bf96013c31c323228a3c04f266705cfb5a4fe5e"
)
FAILED_F5F2_COMMAND_STATUS = (
    ".github/task-runs/2026-08-10-rv64-bpu-flat-read-view-ppa-f5f2-a1/"
    "evidence/traceable-f5f2-bpu-flat-read-view-a1/command-status.txt"
)
FAILED_F5F2_COMMAND_STATUS_SHA256 = (
    "7a4d2741e0ac353c60591ac54833a949b470c42b4e28affb694ecb987e2beaa8"
)
FAILED_F5F2_RAW_DIAGNOSTIC = (
    ".github/task-runs/2026-08-10-rv64-bpu-flat-read-view-ppa-f5f2-a1/"
    "evidence/traceable-f5f2-bpu-flat-read-view-a1/"
    "opensta-bpu-negative-slack.tsv"
)
FAILED_F5F2_RAW_DIAGNOSTIC_SHA256 = (
    "4b56ca26b14e52415ac554e4b65e17fb746036782938ce47d13536b97dd97fb4"
)
FAILED_F5F2_ADJUDICATION = (
    ".github/task-runs/2026-08-09-rv64-bpu-inline-ppa-d3f3-a1/"
    "subagent-contracts/bpu-flat-read-view-ppa-f5f2-a1.result.md"
)
FAILED_F5F2_ADJUDICATION_SHA256 = (
    "c535a9aeb9d135ed8cb08e21100764feef35108de8a6788e4a0822a42f2d7edd"
)
EXPECTED_F5F2_FAILED_ATTEMPT: dict[str, Any] = {
    "physical_configuration_id": (
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
    ),
    "source_design_id": EXPECTED_F5F2_DESIGN_ID,
    "result": "FAIL",
    "status_path": FAILED_F5F2_STATUS,
    "status_sha256": FAILED_F5F2_STATUS_SHA256,
    "command_status_path": FAILED_F5F2_COMMAND_STATUS,
    "command_status_sha256": FAILED_F5F2_COMMAND_STATUS_SHA256,
    "raw_diagnostic_path": FAILED_F5F2_RAW_DIAGNOSTIC,
    "raw_diagnostic_sha256": FAILED_F5F2_RAW_DIAGNOSTIC_SHA256,
    "raw_diagnostic_qualification": "UNBOUND_DIAGNOSTIC_ONLY",
    "adjudication_path": FAILED_F5F2_ADJUDICATION,
    "adjudication_sha256": FAILED_F5F2_ADJUDICATION_SHA256,
    "qualified_measurement": False,
    "summary": None,
    "architecture_registry_binding": None,
}
EXPECTED_BPU_PHYSICAL_EXPERIMENT_STATE: dict[str, Any] = {
    "active_configuration": (
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
    ),
    "live_rtl_design_id": EXPECTED_LIVE_DESIGN_ID,
    "source_lifecycle": "development",
    "measurement_status": "FAILED_INCOMPLETE",
    "mapped_execution_receipt": "FAIL",
    "frozen_experiment_verdict": "ROLLBACK",
    "physical_status": "GAP",
    "archive_status": "RETAIN_NONCANONICAL_NEGATIVE_RESULT",
    "front_accepted": False,
    "canonical": False,
    "champion": False,
    "sweep_status": "BPU_CLOSED_FOR_SWEEP",
    "next_action": "STOP_BPU_PIVOT_FP",
    "stop_condition": "TRIGGERED",
    "failed_attempt": EXPECTED_F5F2_FAILED_ATTEMPT,
    "frozen_predecessor": {
        "physical_configuration_id": BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        "source_design_id": EXPECTED_B279_DESIGN_ID,
        "mapped_summary": FROZEN_B279_MAPPED_SUMMARY,
        "mapped_summary_sha256": FROZEN_B279_MAPPED_SUMMARY_SHA256,
        "mapped_execution_receipt": "PASS",
        "frozen_experiment_verdict": "ROLLBACK",
        "physical_status": "GAP",
        "archive_class": "engineering_proxy_archive",
        "archive_status": "RETAIN_NONCANONICAL",
        "front_accepted": False,
        "canonical": False,
        "champion": False,
    },
}
PLACEHOLDER_MODE = "placeholder_blackbox"
INLINE_MODE = "inline_rtl"
KNOWN_OOC_MODE = "known_ooc_macro"
UNKNOWN_PLACEHOLDER_CLASS = "unknown_placeholder"
OOC_STA_ABSTRACTION = "OOC_STA_ABSTRACTION"
SOURCE_SUFFIXES = {".v", ".sv"}
DESIGN_SUFFIXES = {".v", ".sv", ".vh", ".svh", ".mk"}
ROLES = {"product", "catalog_only", "source_fragment", "debug_only", "sim_only"}
NON_PRODUCT_ROLES = {"catalog_only", "debug_only", "sim_only"}
EXPECTED_DEFINES = {
    "OOO_CSR_QUEUE_HEAD": "1",
    "OOO_TERMINAL_HOLDER_ASSERT": "1",
}
MODULE_RE = re.compile(
    r"(?m)^\s*module\s+(?:automatic\s+)?([A-Za-z_$][A-Za-z0-9_$]*)\b"
)
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

EXPECTED_RUN_PARAMETER_CONTRACT: dict[str, Any] = {
    "id": RUN_PARAMETER_CONTRACT_ID,
    "expected_rtl_design_id": EXPECTED_LIVE_DESIGN_ID,
    "mode": "candidate",
    "diagnostic": "traceable-public-autoname",
    "design": "NpcTop",
    "period_ns": 5.0,
    "clock_port": "clk",
    "clock_name": "core_clock",
    "defines": [],
    "synthesis": {
        "flatten": 0,
        "share": 0,
        "stop_after_coarse": 0,
        "public_autoname": 1,
        "dff_autoname": 0,
        "sta_flatten_export": 1,
    },
    "sta": {"stage_scc": 0},
    "keep_hierarchy_modules": [
        "OooIntBackend",
        "OooFpBackend",
        "OooFrontend",
        "OooFetchAxiBridge",
        "OooMemAxiBridge",
        "OooRob",
        "OooIntIssueQueue",
    ],
    "sdc_file": "yosys-sta/scripts/default.sdc",
    "standard_cell_lib": (
        "yosys-sta/pdk/icsprout55/IP/STD_cell/"
        "ics55_LLSC_H7C_V1p10C100/ics55_LLSC_H7CL/liberty/"
        "ics55_LLSC_H7CL_typ_tt_1p2_25_nldm.lib"
    ),
    "opensta_binary": "/home/lyg/tools/OpenSTA/build/sta",
}
EXPECTED_BOUNDARY_MODES = {
    FOUR_PLACEHOLDER_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": PLACEHOLDER_MODE,
        "OooBranchDirectionPredictor": PLACEHOLDER_MODE,
    },
    BPU_INLINE_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": PLACEHOLDER_MODE,
        "OooBranchDirectionPredictor": INLINE_MODE,
    },
    BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": PLACEHOLDER_MODE,
        "OooBranchDirectionPredictor": INLINE_MODE,
    },
    BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": PLACEHOLDER_MODE,
        "OooBranchDirectionPredictor": INLINE_MODE,
    },
    FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": INLINE_MODE,
        "OooBranchDirectionPredictor": PLACEHOLDER_MODE,
    },
    FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION: {
        "Sram4096x199": PLACEHOLDER_MODE,
        "Sram4096x113": PLACEHOLDER_MODE,
        "OooFpArithGate": INLINE_MODE,
        "OooBranchDirectionPredictor": PLACEHOLDER_MODE,
    },
}
EXPECTED_UNKNOWN_MACRO_INSTANCES = {
    FOUR_PLACEHOLDER_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooFpArithGate": 1,
        "OooBranchDirectionPredictor": 1,
    },
    BPU_INLINE_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooFpArithGate": 1,
    },
    BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooFpArithGate": 1,
    },
    BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooFpArithGate": 1,
    },
    FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooBranchDirectionPredictor": 1,
    },
    FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION: {
        "Sram4096x199": 1,
        "Sram4096x113": 2,
        "OooBranchDirectionPredictor": 1,
    },
}

EXPECTED_MAPPED_ARTIFACT_PROFILES = {
    FOUR_PLACEHOLDER_CONFIGURATION: MAPPED_ARTIFACT_PROFILE_NONE,
    BPU_INLINE_CONFIGURATION: MAPPED_ARTIFACT_PROFILE_NONE,
    BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION: (
        MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT
    ),
    BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION: (
        MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT
    ),
    FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION: (
        MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN
    ),
    FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION: (
        MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE
    ),
}

EXPECTED_BANKED_CHILD_INLINE_MODULES = [
    "OooBranchDirectionPredictor",
    "OooBranchLocalPht",
    "OooBranchLocalPhtBank",
]
EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS = [
    "OooBranchDirectionPredictor",
    "OooBranchLocalPht",
    "OooBranchLocalPhtBank",
]
EXPECTED_FP_ARITH_INLINE_MODULES = [
    "OooFpArithGate",
    "OooFpAddSubPipe",
    "OooFpMulProductPipe",
    "OooFpMulNormRoundPipe",
    "OooFpFmaAlignAddPipe",
    "OooFpFmaNormRoundPipe",
]
EXPECTED_FP_ARITH_KEEP_HIERARCHY_ADDITIONS = list(
    EXPECTED_FP_ARITH_INLINE_MODULES
)

EXPECTED_FP_OOC_INLINE_MODULES = ["OooFpArithGate"]
EXPECTED_FP_OOC_MACRO_MODULES = [
    "OooFpAddSubPipe",
    "OooFpMulProductPipe",
    "OooFpMulNormRoundPipe",
    "OooFpFmaAlignAddPipe",
    "OooFpFmaNormRoundPipe",
]
EXPECTED_FP_OOC_KEEP_HIERARCHY_ADDITIONS = [
    *EXPECTED_FP_OOC_INLINE_MODULES,
    *EXPECTED_FP_OOC_MACRO_MODULES,
]
EXPECTED_FP_OOC_UNKNOWN_PLACEHOLDERS = [
    "Sram4096x199",
    "Sram4096x113",
    "OooBranchDirectionPredictor",
]
EXPECTED_FP_OOC_IMPLEMENTATION_CLASSES = {
    INLINE_MODE: EXPECTED_FP_OOC_INLINE_MODULES,
    KNOWN_OOC_MODE: EXPECTED_FP_OOC_MACRO_MODULES,
    UNKNOWN_PLACEHOLDER_CLASS: EXPECTED_FP_OOC_UNKNOWN_PLACEHOLDERS,
}
EXPECTED_FP_OOC_MACRO_INSTANCES = {
    module: 1 for module in EXPECTED_FP_OOC_MACRO_MODULES
}
EXPECTED_FP_OOC_MODEL_CONTRACT = {
    "corner": "typ_tt_1p2_25",
    "time_unit": "1ns",
    "capacitive_load_unit": "1pf",
    "voltage_v": 1.2,
    "temperature_c": 25.0,
    "slew_ns": [0.02, 0.10, 0.50],
    "load_pf": [0.01, 0.10, 0.50],
    "power_model": "absent",
    "path_exceptions": "forbidden",
    "clock_period_ns": 5.0,
    "input_delay_ns": 0.0,
    "timing_derivation": {
        "setup": "max(0,period_ns-input_delay_ns-worst_slack_ns)",
        "hold": "max(0,input_delay_ns-worst_slack_ns)",
        "clk_to_q": "max(0.001,worst_path_delay_ns)",
    },
    "path_measurement_basis": {
        "path_object": "PathEnd_points_Path_arrival",
        "unit_domain": "OpenSTA_PropertyValue_UI_nanoseconds",
        "input_to_register_d": (
            "endpoint_arrival_ns-minus-first_arrival_ns_with_zero_input_seed"
        ),
        "register_q_to_output": (
            "endpoint_cumulative_arrival_ns_from_zero_rising_ideal_clock"
        ),
        "clock_origin_ns": 0.0,
        "clock_source_latency_ns": 0.0,
        "clock_network_latency_ns": 0.0,
        "clock_insertion_ns": 0.0,
        "clock_propagation": "ideal_unpropagated",
        "path_end_validation": (
            "constrained_min_max_check_role_startpoint_endpoint_points_first_last"
        ),
    },
    "mapped_leaf_policy": "bound_stdlib_whitelist_no_dollar_generic",
    "retained_netlist_manifest": "complete_ports_leaf_cells_instances",
    "output_bit_classification_source": (
        "retained_unique_driver_plus_bound_stdlib_output_pin_function"
    ),
    "output_bit_classes": ["DYNAMIC", "CONSTANT_0", "CONSTANT_1"],
    "dynamic_output_path_policy": "real_register_q_path_required",
    "constant_output_path_policy": "zero_register_q_paths_required",
    "constant_inference_from_missing_path": "forbidden",
    "literal_output_timing_group_policy": (
        "none_or_isolated_tied_off_true_without_ordinary_timing"
    ),
    "focused_generated_macro_oracle": (
        "nested_literal_and_top_propagated_constant_no_sdc_seed_"
        "dynamic_reg_clk_to_q"
    ),
    "liberty_output_member_policy": (
        "dynamic_state_function_rising_edge_xor_literal_constant_function"
    ),
    "family_timing_summary_policy": "derived_from_dynamic_bits_only",
    "child_query_budget": {
        "progress_schema": "npc-rv64-fp-ooc-query-progress-v1",
        "completion_marker": "[FP-OOC-QUERY-BUDGET][PASS]",
        "path_class_endpoint_path_count": 1,
        "path_class_group_cap": "exact_target_endpoint_cardinality",
        "input_query_policy": "per_source_bit_setup_max_hold_min",
        "input_endpoint_path_count": 1,
        "input_group_path_count": 1,
        "output_query_policy": "one_bulk_query_per_analysis_join_by_endpoint",
        "output_endpoint_path_count": 1,
        "output_group_cap": "sum_registered_output_widths",
        "pathend_lifetime": "materialize_once_before_next_search",
        "current_addsub": {
            "register_d_endpoints": 608,
            "nonclock_input_bits": 134,
            "output_bits": 138,
            "dynamic_output_bits": 136,
            "find_calls": 273,
            "path_end_limit": 2364,
            "validation_limit": 2364,
        },
    },
    "tcl_row_projection_contract": {
        "encoding": "outer_list_of_brace_quoted_row_lists",
        "atom_policy": "nonempty_ascii_safe_no_brace_or_backslash",
        "child_output_bit_driver": {
            "fields": [
                "family",
                "index",
                "opensta_object_name",
                "classification",
                "constant_value",
                "driver_binding_sha256",
            ],
            "row_count": "sum_registered_output_widths",
        },
        "top_boundary": {
            "fields": [
                "path_class",
                "source_instance_path",
                "source_object_class",
                "source_port_family_widths",
                "endpoint_kind",
                "endpoint_instance_path",
                "endpoint_object_class",
                "endpoint_family_widths",
            ],
            "row_count": 5,
        },
    },
}

# The final FMA child does not drive an NpcTop port.  Its value/fflags pass
# through OooFpBackend completion arbitration and are captured by all eight
# done-FIFO entries.  Keep the linked hierarchy and bit cardinality explicit so
# the top OpenSTA query cannot fall back to a similarly named wire or port.
FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH = (
    "u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/"
    "u_int_backend/u_fp_backend"
)
FP_OOC_BACKEND_COMPLETION_REGISTER_FAMILIES = {
    "df_fflags_q": 8 * 5,
    "df_value_q": 8 * 64,
}

_FP_OOC_CHILD_SPECS: dict[str, dict[str, Any]] = {
    "OooFpAddSubPipe": {
        "rtl": "npc/rv64/vsrc/execute/OooFpAddSubPipe.v",
        "helpers": ["OooFpPredicates.v", "OooFpRound.v"],
        "top_instance": "u_addsub_pipe",
        "inputs": {"clk": 1, "rst": 1, "flush_i": 1, "frs1_value_i": 64,
                   "frs2_value_i": 64, "sub_op_i": 1, "rm_i": 3},
        "outputs": {"addsub_d_value_q_o": 64, "addsub_d_fflags_q_o": 5,
                    "addsub_s_value_q_o": 64, "addsub_s_fflags_q_o": 5},
        "register_to_register": "required",
        "top_boundary": "addsub_s3_q_to_wrapper_s4_d",
    },
    "OooFpMulProductPipe": {
        "rtl": "npc/rv64/vsrc/execute/OooFpMulProductPipe.v",
        "helpers": ["OooFpPredicates.v"],
        "top_instance": "u_mul_product_pipe",
        "inputs": {"clk": 1, "rst": 1, "flush_i": 1, "frs1_value_i": 64,
                   "frs2_value_i": 64, "rm_i": 3},
        "outputs": {"mul_d_special_q_o": 1, "mul_d_spval_q_o": 64,
                    "mul_d_spff_q_o": 5, "mul_d_product_q_o": 106,
                    "mul_d_expz_q_o": 14, "mul_d_signz_q_o": 1,
                    "mul_d_rm_q_o": 3, "mul_s_special_q_o": 1,
                    "mul_s_spval_q_o": 64, "mul_s_spff_q_o": 5,
                    "mul_s_product_q_o": 48, "mul_s_expz_q_o": 14,
                    "mul_s_signz_q_o": 1, "mul_s_rm_q_o": 3},
        "register_to_register": "not_applicable_single_stage",
        "top_boundary": "mul_product_s1_q_to_mul_norm_s2_d",
    },
    "OooFpMulNormRoundPipe": {
        "rtl": "npc/rv64/vsrc/execute/OooFpMulNormRoundPipe.v",
        "helpers": ["OooFpRound.v"],
        "top_instance": "u_mul_norm_round_pipe",
        "inputs": {"clk": 1, "rst": 1, "flush_i": 1,
                   "mul_d_special_q_i": 1, "mul_d_spval_q_i": 64,
                   "mul_d_spff_q_i": 5, "mul_d_product_q_i": 106,
                   "mul_d_expz_q_i": 14, "mul_d_signz_q_i": 1,
                   "mul_d_rm_q_i": 3, "mul_s_special_q_i": 1,
                   "mul_s_spval_q_i": 64, "mul_s_spff_q_i": 5,
                   "mul_s_product_q_i": 48, "mul_s_expz_q_i": 14,
                   "mul_s_signz_q_i": 1, "mul_s_rm_q_i": 3},
        "outputs": {"mul_d_value_q_o": 64, "mul_d_fflags_q_o": 5,
                    "mul_s_value_q_o": 64, "mul_s_fflags_q_o": 5},
        "register_to_register": "required",
        "top_boundary": "mul_norm_s3_q_to_wrapper_s4_d",
    },
    "OooFpFmaAlignAddPipe": {
        "rtl": "npc/rv64/vsrc/execute/OooFpFmaAlignAddPipe.v",
        "helpers": ["OooFpPredicates.v", "OooFpRound.v"],
        "top_instance": "u_fma_align_add_pipe",
        "inputs": {"clk": 1, "rst": 1, "flush_i": 1, "frs1_value_i": 64,
                   "frs2_value_i": 64, "frs3_value_i": 64,
                   "negate_product_i": 1, "subtract_addend_i": 1, "rm_i": 3},
        "outputs": {"fma_d_special_q_o": 1, "fma_d_spval_q_o": 64,
                    "fma_d_spff_q_o": 5, "fma_d_mag_q_o": 128,
                    "fma_d_ressign_q_o": 1, "fma_d_refw_q_o": 32,
                    "fma_d_rm_q_o": 3, "fma_s_special_q_o": 1,
                    "fma_s_spval_q_o": 64, "fma_s_spff_q_o": 5,
                    "fma_s_mag_q_o": 128, "fma_s_ressign_q_o": 1,
                    "fma_s_refw_q_o": 32, "fma_s_rm_q_o": 3},
        "register_to_register": "required",
        "top_boundary": "fma_align_s3_q_to_fma_norm_s4_d",
    },
    "OooFpFmaNormRoundPipe": {
        "rtl": "npc/rv64/vsrc/execute/OooFpFmaNormRoundPipe.v",
        "helpers": ["OooFpRound.v"],
        "top_instance": "u_fma_norm_round_pipe",
        "inputs": {"clk": 1, "rst": 1, "flush_i": 1,
                   "fma_d_special_q_i": 1, "fma_d_spval_q_i": 64,
                   "fma_d_spff_q_i": 5, "fma_d_mag_q_i": 128,
                   "fma_d_ressign_q_i": 1, "fma_d_refw_q_i": 32,
                   "fma_d_rm_q_i": 3, "fma_s_special_q_i": 1,
                   "fma_s_spval_q_i": 64, "fma_s_spff_q_i": 5,
                   "fma_s_mag_q_i": 128, "fma_s_ressign_q_i": 1,
                   "fma_s_refw_q_i": 32, "fma_s_rm_q_i": 3},
        "outputs": {"fma_d_value_q_o": 64, "fma_d_fflags_q_o": 5,
                    "fma_s_value_q_o": 64, "fma_s_fflags_q_o": 5},
        "register_to_register": "required",
        "top_boundary": "fma_norm_s5_q_to_wrapper_result_completion_d",
    },
}


def _expected_fp_ooc_child_contracts() -> dict[str, dict[str, Any]]:
    contracts: dict[str, dict[str, Any]] = {}
    for module, spec in _FP_OOC_CHILD_SPECS.items():
        compile_sources = ["npc/rv64/vsrc/include/define.v"]
        compile_sources.extend(
            f"npc/rv64/vsrc/execute/{helper}" for helper in spec["helpers"]
        )
        compile_sources.append(spec["rtl"])
        source_closure = [*compile_sources, "npc/rv64/vsrc/filelist.mk"]
        endpoint_contracts = {
            "OooFpAddSubPipe": {
                "kind": "wrapper_register_d",
                "object_class": "REGISTER_D",
                "register_families": {"addsub_s4_result_q": 69},
            },
            "OooFpMulProductPipe": {
                "kind": "known_ooc_macro_input",
                "object_class": "MACRO_PIN_INPUT",
                "instance_path": "u_fp_arith/u_mul_norm_round_pipe",
                "port_families": sorted(
                    name for name in _FP_OOC_CHILD_SPECS[
                        "OooFpMulNormRoundPipe"
                    ]["inputs"] if name not in {"clk", "rst", "flush_i"}
                ),
            },
            "OooFpMulNormRoundPipe": {
                "kind": "wrapper_register_d",
                "object_class": "REGISTER_D",
                "register_families": {"mul_s4_result_q": 69},
            },
            "OooFpFmaAlignAddPipe": {
                "kind": "known_ooc_macro_input",
                "object_class": "MACRO_PIN_INPUT",
                "instance_path": "u_fp_arith/u_fma_norm_round_pipe",
                "port_families": sorted(
                    name for name in _FP_OOC_CHILD_SPECS[
                        "OooFpFmaNormRoundPipe"
                    ]["inputs"] if name not in {"clk", "rst", "flush_i"}
                ),
            },
            "OooFpFmaNormRoundPipe": {
                "kind": "backend_completion_register_d",
                "object_class": "REGISTER_D",
                "instance_path": FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH,
                "register_families": (
                    FP_OOC_BACKEND_COMPLETION_REGISTER_FAMILIES
                ),
            },
        }
        contracts[module] = {
            "rtl": spec["rtl"],
            "source_closure": source_closure,
            "compile_sources": compile_sources,
            "top_instance": spec["top_instance"],
            "clock_port": "clk",
            "synchronous_controls": ["rst", "flush_i"],
            "input_ports": spec["inputs"],
            "output_ports": spec["outputs"],
            "path_classes": {
                "port_to_register": "required",
                "register_to_register": spec["register_to_register"],
                "register_to_port": "required",
                "synchronous_control_to_register": "required",
                "top_boundary": spec["top_boundary"],
            },
            "top_boundary_contract": {
                "source_instance_path": f"u_fp_arith/{spec['top_instance']}",
                "source_object_class": "MACRO_PIN_OUTPUT",
                "source_port_families": sorted(spec["outputs"]),
                "endpoint": endpoint_contracts[module],
            },
            "forbidden_timing_exceptions": [
                "false_path", "multicycle_path", "recovery", "removal", "pi_to_po"
            ],
        }
    return contracts


EXPECTED_FP_OOC_CHILD_CONTRACTS = _expected_fp_ooc_child_contracts()


def fp_ooc_child_source_domain_errors(child_contracts: Any) -> list[str]:
    """Keep identity metadata distinct from Verilog compiler inputs."""

    errors: list[str] = []
    expected_modules = set(EXPECTED_FP_OOC_MACRO_MODULES)
    if not isinstance(child_contracts, dict) or set(child_contracts) != expected_modules:
        return ["FP OOC child source-domain module set drifted"]
    for module in EXPECTED_FP_OOC_MACRO_MODULES:
        contract = child_contracts[module]
        if not isinstance(contract, dict):
            errors.append(f"FP OOC {module} source-domain contract is not an object")
            continue
        source_closure = contract.get("source_closure")
        compile_sources = contract.get("compile_sources")
        rtl = contract.get("rtl")
        if not isinstance(source_closure, list) or not all(
            isinstance(path, str) for path in source_closure
        ):
            errors.append(f"FP OOC {module} source_closure is not a string list")
            continue
        if not isinstance(compile_sources, list) or not compile_sources or not all(
            isinstance(path, str) for path in compile_sources
        ):
            errors.append(f"FP OOC {module} compile_sources must be non-empty strings")
            continue
        if len(compile_sources) != len(set(compile_sources)):
            errors.append(f"FP OOC {module} compile_sources contains duplicates")
        invalid_compile_paths = [
            path for path in compile_sources
            if not path.startswith("npc/rv64/vsrc/")
            or "/../" in path
            or Path(path).suffix not in {".v", ".sv"}
        ]
        if invalid_compile_paths:
            errors.append(
                f"FP OOC {module} compile_sources contains non-Verilog or "
                f"out-of-domain paths: {invalid_compile_paths}"
            )
        if any(path not in source_closure for path in compile_sources):
            errors.append(
                f"FP OOC {module} compile_sources is not a source_closure subset"
            )
        expected_compile_sources = [
            path for path in source_closure
            if Path(path).suffix in {".v", ".sv"}
        ]
        if compile_sources != expected_compile_sources:
            errors.append(
                f"FP OOC {module} compile_sources is not the exact Verilog "
                "source_closure subset"
            )
        if rtl not in compile_sources:
            errors.append(f"FP OOC {module} compile_sources lacks child RTL")
        if "npc/rv64/vsrc/filelist.mk" not in source_closure:
            errors.append(f"FP OOC {module} source_closure lacks filelist.mk")
        if "npc/rv64/vsrc/filelist.mk" in compile_sources:
            errors.append(f"FP OOC {module} compile_sources includes filelist.mk")
    return errors

REPO_ROOT = Path(__file__).resolve().parents[5]
CATALOG_PATH = REPO_ROOT / "npc/rv64/design/arch/rv64-architecture-registry-v1.json"
SCHEMA_PATH = REPO_ROOT / "npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json"
ENTRY_PATH = REPO_ROOT / "npc/rv64/ARCHITECTURE.md"


class RegistryError(RuntimeError):
    """A fail-closed registry or evidence error."""


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        allow_nan=False,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return sha256_bytes(canonical_bytes(value))


def architecture_policy(catalog: dict[str, Any]) -> dict[str, Any]:
    """Return stable architecture policy without mutable evidence pointers."""

    return {key: value for key, value in catalog.items() if key != "evidence"}


def architecture_policy_sha256(catalog: dict[str, Any]) -> str:
    return canonical_sha256(architecture_policy(catalog))


def physical_configuration_sha256(
    configuration_id: str, configuration: dict[str, Any]
) -> str:
    return canonical_sha256(
        {"configuration_id": configuration_id, "configuration": configuration}
    )


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise RegistryError(f"cannot read JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RegistryError(f"JSON root must be an object: {path}")
    return value


def repo_path(value: str, *, root: Path = REPO_ROOT) -> Path:
    path = (root / value).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError as exc:
        raise RegistryError(f"path escapes repository: {value}") from exc
    return path


def bpu_physical_experiment_state_errors(
    catalog: dict[str, Any], *, root: Path = REPO_ROOT
) -> list[str]:
    """Validate the one live BPU development candidate and frozen predecessor."""

    errors: list[str] = []
    state = catalog.get("bpu_physical_experiment_state")
    expected = EXPECTED_BPU_PHYSICAL_EXPERIMENT_STATE
    if not isinstance(state, dict):
        return ["bpu_physical_experiment_state must be an object"]
    if set(state) != set(expected):
        errors.append("bpu_physical_experiment_state has an invalid key set")
    for field, expected_value in expected.items():
        if field in {"failed_attempt", "frozen_predecessor"}:
            continue
        if state.get(field) != expected_value:
            errors.append(f"bpu_physical_experiment_state.{field} drifted")
    configurations = catalog.get("physical_configurations")
    if (
        isinstance(configurations, dict)
        and state.get("active_configuration") not in configurations
    ):
        errors.append(
            "bpu_physical_experiment_state.active_configuration is not registered"
        )
    contract = catalog.get("run_parameter_contract")
    if (
        isinstance(contract, dict)
        and state.get("live_rtl_design_id")
        != contract.get("expected_rtl_design_id")
    ):
        errors.append(
            "bpu_physical_experiment_state.live_rtl_design_id differs from the "
            "run parameter contract"
        )

    failed = state.get("failed_attempt")
    expected_failed = expected["failed_attempt"]
    if not isinstance(failed, dict):
        errors.append("bpu_physical_experiment_state.failed_attempt must be an object")
    else:
        if set(failed) != set(expected_failed):
            errors.append(
                "bpu_physical_experiment_state.failed_attempt has an invalid key set"
            )
        for field, expected_value in expected_failed.items():
            if failed.get(field) != expected_value:
                errors.append(
                    f"bpu_physical_experiment_state.failed_attempt.{field} drifted"
                )
        if failed.get("summary") is not None:
            errors.append(
                "bpu_physical_experiment_state.failed_attempt.summary must remain null"
            )
        if failed.get("architecture_registry_binding") is not None:
            errors.append(
                "bpu_physical_experiment_state.failed_attempt."
                "architecture_registry_binding must remain null"
            )
        artifact_fields = (
            ("status", "status_path", "status_sha256"),
            ("command status", "command_status_path", "command_status_sha256"),
            ("raw diagnostic", "raw_diagnostic_path", "raw_diagnostic_sha256"),
            ("adjudication", "adjudication_path", "adjudication_sha256"),
        )
        retained_paths: dict[str, Path] = {}
        for label, path_field, sha_field in artifact_fields:
            relative = failed.get(path_field)
            if not isinstance(relative, str) or not relative:
                errors.append(f"failed f5f2 {label} path is missing")
                continue
            try:
                artifact_path = repo_path(relative, root=root)
            except RegistryError as exc:
                errors.append(str(exc))
                continue
            retained_paths[label] = artifact_path
            if not artifact_path.is_file():
                errors.append(f"failed f5f2 {label} artifact is missing")
                continue
            if sha256_file(artifact_path) != failed.get(sha_field):
                errors.append(f"failed f5f2 {label} SHA-256 mismatches the artifact")
        status_path = retained_paths.get("status")
        if status_path is not None and status_path.is_file():
            status_marker = status_path.read_text(
                encoding="utf-8", errors="replace"
            ).strip()
            if status_marker != (
                "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0"
            ):
                errors.append("failed f5f2 status marker is not fail-closed")
        command_status_path = retained_paths.get("command status")
        if command_status_path is not None and command_status_path.is_file():
            command_status_lines = set(
                command_status_path.read_text(
                    encoding="utf-8", errors="replace"
                ).splitlines()
            )
            required_command_status = {
                "synth_rc=0",
                "opensta_rc=1",
                "parser_rc=1",
                "trace_rc=1",
                "binding_rc=2",
                "cleanup_rc=0",
            }
            if not required_command_status.issubset(command_status_lines):
                errors.append("failed f5f2 command status lost the incomplete chain")
        raw_diagnostic_path = retained_paths.get("raw diagnostic")
        if raw_diagnostic_path is not None and raw_diagnostic_path.is_file():
            raw_header = raw_diagnostic_path.read_text(
                encoding="utf-8", errors="replace"
            ).splitlines()[:1]
            if raw_header != ["schema\tnpc-rv64-opensta-bpu-negative-slack-inventory-v1"]:
                errors.append("failed f5f2 raw diagnostic schema is invalid")

    frozen = state.get("frozen_predecessor")
    expected_frozen = expected["frozen_predecessor"]
    if not isinstance(frozen, dict):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor must be an object"
        )
        return errors
    if set(frozen) != set(expected_frozen):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor has an invalid key set"
        )
    for field, expected_value in expected_frozen.items():
        if frozen.get(field) != expected_value:
            errors.append(
                "bpu_physical_experiment_state.frozen_predecessor."
                f"{field} drifted"
            )

    summary_value = frozen.get("mapped_summary")
    if not isinstance(summary_value, str) or not summary_value:
        return errors
    try:
        summary_path = repo_path(summary_value, root=root)
    except RegistryError as exc:
        errors.append(str(exc))
        return errors
    if not summary_path.is_file():
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor.mapped_summary is missing"
        )
        return errors
    actual_summary_sha256 = sha256_file(summary_path)
    if actual_summary_sha256 != frozen.get("mapped_summary_sha256"):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor."
            "mapped_summary_sha256 mismatches the artifact"
        )
    try:
        summary = load_json(summary_path)
    except RegistryError as exc:
        errors.append(str(exc))
        return errors
    if summary.get("status") != frozen.get("mapped_execution_receipt"):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor."
            "mapped_execution_receipt mismatches summary.status"
        )
    binding = summary.get("architecture_registry_binding")
    if not isinstance(binding, dict):
        errors.append("frozen B279 mapped summary lacks architecture_registry_binding")
        return errors
    if binding.get("design_id") != frozen.get("source_design_id"):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor.source_design_id "
            "mismatches the mapped binding"
        )
    if (
        binding.get("physical_configuration_id")
        != frozen.get("physical_configuration_id")
    ):
        errors.append(
            "bpu_physical_experiment_state.frozen_predecessor."
            "physical_configuration_id mismatches the mapped binding"
        )
    return errors


def physical_configuration_contract_errors(
    catalog: dict[str, Any],
) -> list[str]:
    """Validate the registry-authorized 5 ns boundary projections."""

    errors: list[str] = []
    boundaries = catalog.get("physical_boundaries")
    boundary_names = set(boundaries) if isinstance(boundaries, dict) else set()
    configurations = catalog.get("physical_configurations")
    expected_ids = {
        FOUR_PLACEHOLDER_CONFIGURATION,
        BPU_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
        FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION,
        FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
    }
    if not isinstance(configurations, dict) or set(configurations) != expected_ids:
        actual_ids = set(configurations) if isinstance(configurations, dict) else set()
        return [
            "physical_configurations must contain the exact authorized IDs: "
            f"missing={sorted(expected_ids - actual_ids)} "
            f"extra={sorted(actual_ids - expected_ids)}"
        ]
    for configuration_id in (
        FOUR_PLACEHOLDER_CONFIGURATION,
        BPU_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
        FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION,
        FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
    ):
        configuration = configurations[configuration_id]
        required = {
            "run_parameter_contract",
            "comparison_parent",
            "mapped_artifact_profile",
            "boundary_modes",
            "expected_unknown_macro_instances",
        }
        if configuration_id in {
            BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
            BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
        }:
            required |= {
                "archive_class",
                "canonical",
                "champion",
                "inline_modules",
                "keep_hierarchy_additions",
            }
        elif configuration_id == FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION:
            required |= {
                "archive_class",
                "source_lifecycle",
                "measurement_status",
                "physical_status",
                "canonical",
                "champion",
                "inline_modules",
                "keep_hierarchy_additions",
            }
        elif configuration_id == FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION:
            required |= {
                "abstraction_kind",
                "implementation_classes",
                "expected_known_ooc_macro_instances",
                "archive_class",
                "source_lifecycle",
                "measurement_status",
                "physical_status",
                "canonical",
                "champion",
                "inline_modules",
                "known_ooc_macro_modules",
                "keep_hierarchy_additions",
                "ooc_model_contract",
                "child_contracts",
            }
        if not isinstance(configuration, dict) or set(configuration) != required:
            errors.append(
                f"physical configuration {configuration_id} has an invalid key set"
            )
            continue
        if configuration.get("run_parameter_contract") != RUN_PARAMETER_CONTRACT_ID:
            errors.append(
                f"physical configuration {configuration_id} has a stale run parameter contract"
            )
        expected_parent = {
            FOUR_PLACEHOLDER_CONFIGURATION: None,
            BPU_INLINE_CONFIGURATION: FOUR_PLACEHOLDER_CONFIGURATION,
            BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION: BPU_INLINE_CONFIGURATION,
            BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION: (
                BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
            ),
            FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION: (
                FOUR_PLACEHOLDER_CONFIGURATION
            ),
            FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION: (
                FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
            ),
        }[configuration_id]
        if configuration.get("comparison_parent") != expected_parent:
            errors.append(
                f"physical configuration {configuration_id} comparison parent drifted"
            )
        expected_profile = EXPECTED_MAPPED_ARTIFACT_PROFILES[configuration_id]
        profile = configuration.get("mapped_artifact_profile")
        if profile not in MAPPED_ARTIFACT_PROFILES or profile != expected_profile:
            errors.append(
                f"physical configuration {configuration_id} mapped artifact profile drifted"
            )
        modes = configuration.get("boundary_modes")
        if not isinstance(modes, dict) or set(modes) != boundary_names:
            actual_names = set(modes) if isinstance(modes, dict) else set()
            errors.append(
                f"physical configuration {configuration_id} boundary key set drifted: "
                f"missing={sorted(boundary_names - actual_names)} "
                f"extra={sorted(actual_names - boundary_names)}"
            )
        elif modes != EXPECTED_BOUNDARY_MODES[configuration_id]:
            errors.append(
                f"physical configuration {configuration_id} boundary delta is unauthorized"
            )
        census = configuration.get("expected_unknown_macro_instances")
        if not isinstance(census, dict) or census != EXPECTED_UNKNOWN_MACRO_INSTANCES[
            configuration_id
        ]:
            errors.append(
                f"physical configuration {configuration_id} unknown macro census drifted"
            )
        elif any(
            isinstance(count, bool) or not isinstance(count, int) or count <= 0
            for count in census.values()
        ):
            errors.append(
                f"physical configuration {configuration_id} macro census must be positive integers"
            )
        if isinstance(modes, dict) and isinstance(census, dict):
            blackboxes = {
                module for module, mode in modes.items() if mode == PLACEHOLDER_MODE
            }
            if set(census) != blackboxes:
                errors.append(
                    f"physical configuration {configuration_id} census/blackbox set mismatch"
                )
            invalid_modes = set(modes.values()) - {PLACEHOLDER_MODE, INLINE_MODE}
            if invalid_modes:
                errors.append(
                    f"physical configuration {configuration_id} has invalid modes "
                    f"{sorted(invalid_modes)}"
                )
        if configuration_id in {
            BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
            BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
        }:
            expected_archive_class = (
                "engineering_proxy_archive"
                if configuration_id
                == BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
                else "engineering_proxy_negative_result_archive"
            )
            if configuration.get("archive_class") != expected_archive_class:
                errors.append(
                    f"physical configuration {configuration_id} archive class drifted"
                )
            if configuration.get("canonical") is not False:
                errors.append(
                    f"physical configuration {configuration_id} must remain non-canonical"
                )
            if configuration.get("champion") is not False:
                errors.append(
                    f"physical configuration {configuration_id} must remain non-champion"
                )
            if configuration.get("inline_modules") != EXPECTED_BANKED_CHILD_INLINE_MODULES:
                errors.append(
                    f"physical configuration {configuration_id} inline module set drifted"
                )
            if (
                configuration.get("keep_hierarchy_additions")
                != EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS
            ):
                errors.append(
                    f"physical configuration {configuration_id} "
                    "keep-hierarchy additions drifted"
                )
        elif configuration_id == FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION:
            expected_scalars = {
                "archive_class": "engineering_proxy_development",
                "source_lifecycle": "development",
                "measurement_status": "UNMEASURED",
                "physical_status": "GAP",
                "canonical": False,
                "champion": False,
            }
            for field, expected in expected_scalars.items():
                if configuration.get(field) != expected:
                    errors.append(
                        f"physical configuration {configuration_id} {field} drifted"
                    )
            if configuration.get("inline_modules") != EXPECTED_FP_ARITH_INLINE_MODULES:
                errors.append(
                    f"physical configuration {configuration_id} inline module set drifted"
                )
            if (
                configuration.get("keep_hierarchy_additions")
                != EXPECTED_FP_ARITH_KEEP_HIERARCHY_ADDITIONS
            ):
                errors.append(
                    f"physical configuration {configuration_id} "
                    "keep-hierarchy additions drifted"
                )
        elif configuration_id == FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION:
            expected_scalars = {
                "abstraction_kind": OOC_STA_ABSTRACTION,
                "archive_class": "engineering_proxy_development",
                "source_lifecycle": "development",
                "measurement_status": "UNMEASURED",
                "physical_status": "GAP",
                "canonical": False,
                "champion": False,
            }
            for field, expected in expected_scalars.items():
                if configuration.get(field) != expected:
                    errors.append(
                        f"physical configuration {configuration_id} {field} drifted"
                    )
            if configuration.get("implementation_classes") != EXPECTED_FP_OOC_IMPLEMENTATION_CLASSES:
                errors.append(
                    f"physical configuration {configuration_id} implementation classes drifted"
                )
            if configuration.get("expected_known_ooc_macro_instances") != EXPECTED_FP_OOC_MACRO_INSTANCES:
                errors.append(
                    f"physical configuration {configuration_id} known OOC macro census drifted"
                )
            if configuration.get("inline_modules") != EXPECTED_FP_OOC_INLINE_MODULES:
                errors.append(
                    f"physical configuration {configuration_id} inline module set drifted"
                )
            if configuration.get("known_ooc_macro_modules") != EXPECTED_FP_OOC_MACRO_MODULES:
                errors.append(
                    f"physical configuration {configuration_id} known OOC macro set drifted"
                )
            if configuration.get("keep_hierarchy_additions") != EXPECTED_FP_OOC_KEEP_HIERARCHY_ADDITIONS:
                errors.append(
                    f"physical configuration {configuration_id} keep-hierarchy additions drifted"
                )
            if configuration.get("ooc_model_contract") != EXPECTED_FP_OOC_MODEL_CONTRACT:
                errors.append(
                    f"physical configuration {configuration_id} OOC model contract drifted"
                )
            errors.extend(fp_ooc_child_source_domain_errors(
                configuration.get("child_contracts")
            ))
            if configuration.get("child_contracts") != EXPECTED_FP_OOC_CHILD_CONTRACTS:
                errors.append(
                    f"physical configuration {configuration_id} child timing contracts drifted"
                )
            classes = configuration.get("implementation_classes")
            if isinstance(classes, dict):
                members = [module for values in classes.values()
                           if isinstance(values, list) for module in values]
                if len(members) != len(set(members)):
                    errors.append(
                        f"physical configuration {configuration_id} implementation classes overlap"
                    )
    parent_configuration = configurations[FOUR_PLACEHOLDER_CONFIGURATION]
    child_configuration = configurations[BPU_INLINE_CONFIGURATION]
    banked_configuration = configurations[
        BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION
    ]
    flat_read_configuration = configurations[
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION
    ]
    fp_arith_configuration = configurations[
        FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION
    ]
    fp_ooc_configuration = configurations[
        FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION
    ]
    parent_modes = (
        parent_configuration.get("boundary_modes", {})
        if isinstance(parent_configuration, dict)
        else {}
    )
    child_modes = (
        child_configuration.get("boundary_modes", {})
        if isinstance(child_configuration, dict)
        else {}
    )
    banked_modes = (
        banked_configuration.get("boundary_modes", {})
        if isinstance(banked_configuration, dict)
        else {}
    )
    flat_read_modes = (
        flat_read_configuration.get("boundary_modes", {})
        if isinstance(flat_read_configuration, dict)
        else {}
    )
    fp_arith_modes = (
        fp_arith_configuration.get("boundary_modes", {})
        if isinstance(fp_arith_configuration, dict)
        else {}
    )
    fp_ooc_modes = (
        fp_ooc_configuration.get("boundary_modes", {})
        if isinstance(fp_ooc_configuration, dict)
        else {}
    )
    if isinstance(parent_modes, dict) and isinstance(child_modes, dict):
        delta = {
            module
            for module in boundary_names
            if parent_modes.get(module) != child_modes.get(module)
        }
        if delta != {"OooBranchDirectionPredictor"}:
            errors.append(
                "BPU-inline configuration must change only OooBranchDirectionPredictor"
            )
    if isinstance(child_modes, dict) and isinstance(banked_modes, dict):
        delta = {
            module
            for module in boundary_names
            if child_modes.get(module) != banked_modes.get(module)
        }
        if delta:
            errors.append(
                "banked child archive must preserve the BPU-inline boundary modes"
            )
    if isinstance(banked_modes, dict) and isinstance(flat_read_modes, dict):
        delta = {
            module
            for module in boundary_names
            if banked_modes.get(module) != flat_read_modes.get(module)
        }
        if delta:
            errors.append(
                "flat-read-view development configuration must preserve the banked-child "
                "boundary modes"
            )
    if isinstance(parent_modes, dict) and isinstance(fp_arith_modes, dict):
        delta = {
            module
            for module in boundary_names
            if parent_modes.get(module) != fp_arith_modes.get(module)
        }
        if delta != {"OooFpArithGate"}:
            errors.append(
                "FP-arith production-child configuration must change only "
                "OooFpArithGate"
            )
    if isinstance(fp_arith_modes, dict) and isinstance(fp_ooc_modes, dict):
        delta = {
            module
            for module in boundary_names
            if fp_arith_modes.get(module) != fp_ooc_modes.get(module)
        }
        if delta:
            errors.append(
                "FP OOC composite configuration must preserve wrapper/placeholder boundary modes"
            )
    if isinstance(boundaries, dict):
        for module, boundary in boundaries.items():
            if not isinstance(boundary, dict):
                continue
            baseline_mode = parent_modes.get(module) if isinstance(parent_modes, dict) else None
            if boundary.get("blackbox_in_mapped_flow") != (
                baseline_mode == PLACEHOLDER_MODE
            ):
                errors.append(
                    f"physical boundary {module} legacy baseline projection drifted"
                )
    return errors


def selected_physical_configuration(
    catalog: dict[str, Any], configuration_id: str
) -> dict[str, Any]:
    if not isinstance(configuration_id, str) or not configuration_id:
        raise RegistryError("physical configuration ID must be explicit")
    errors = physical_configuration_contract_errors(catalog)
    if errors:
        raise RegistryError("physical configuration policy invalid: " + "; ".join(errors))
    configurations = catalog["physical_configurations"]
    if configuration_id not in configurations:
        raise RegistryError(f"unknown physical configuration: {configuration_id}")
    return configurations[configuration_id]


def require_expected_rtl_design_id(
    catalog: dict[str, Any], *, expected: str, actual: str
) -> None:
    contract = catalog.get("run_parameter_contract")
    catalog_expected = (
        contract.get("expected_rtl_design_id") if isinstance(contract, dict) else None
    )
    if not isinstance(expected, str) or not re.fullmatch(r"sha256:[0-9a-f]{64}", expected):
        raise RegistryError("expected RTL design-id must be an explicit SHA-256 identity")
    if expected != catalog_expected:
        raise RegistryError(
            "expected RTL design-id differs from the run parameter contract"
        )
    if actual != expected:
        raise RegistryError(
            f"RTL design-id mismatch: expected={expected} actual={actual}"
        )


def run_checked(
    args: list[str],
    *,
    root: Path,
    timeout: int = 30,
    text: bool = True,
) -> subprocess.CompletedProcess[Any]:
    completed = subprocess.run(
        args,
        cwd=root,
        capture_output=True,
        text=text,
        check=False,
        timeout=timeout,
    )
    if completed.returncode != 0:
        stderr = completed.stderr if text else completed.stderr.decode(
            "utf-8", errors="replace"
        )
        stdout = completed.stdout if text else completed.stdout.decode(
            "utf-8", errors="replace"
        )
        detail = (stderr or stdout).strip()
        raise RegistryError(
            f"command failed rc={completed.returncode}: {' '.join(args)}"
            + (f": {detail}" if detail else "")
        )
    return completed


def validate_catalog(catalog: dict[str, Any], *, root: Path = REPO_ROOT) -> list[str]:
    errors: list[str] = []
    if catalog.get("schema") != SCHEMA:
        errors.append(f"catalog schema must be {SCHEMA}")
    expected_keys = {
        "schema",
        "single_entry",
        "scope",
        "bpu_physical_experiment_state",
        "owners",
        "owner_rules",
        "file_overrides",
        "owner_globs",
        "capabilities",
        "physical_boundaries",
        "run_parameter_contract",
        "physical_configurations",
        "evidence",
        "architecture_nodes",
        "architecture_edges",
    }
    if set(catalog) != expected_keys:
        errors.append(
            "catalog top-level keys drifted: "
            f"missing={sorted(expected_keys - set(catalog))} "
            f"extra={sorted(set(catalog) - expected_keys)}"
        )
    scope = catalog.get("scope")
    if not isinstance(scope, dict):
        errors.append("scope must be an object")
        return errors
    if scope.get("source_root") != "npc/rv64/vsrc":
        errors.append("scope.source_root must be npc/rv64/vsrc")
    if scope.get("extensions") != [".v", ".sv"]:
        errors.append("scope.extensions must be the canonical [.v, .sv] list")
    inventory_review = scope.get("inventory_review")
    if not isinstance(inventory_review, dict) or set(inventory_review) != {
        "path_set_sha256",
        "owner",
        "change_policy",
    }:
        errors.append("scope.inventory_review must bind path_set_sha256/owner/change_policy")
    else:
        if not SHA256_RE.fullmatch(str(inventory_review.get("path_set_sha256", ""))):
            errors.append("scope.inventory_review.path_set_sha256 must be a SHA-256")
        if inventory_review.get("owner") != "rv64-architecture":
            errors.append("scope.inventory_review.owner must be rv64-architecture")
        if inventory_review.get("change_policy") != "any-vsrc-path-change-requires-review":
            errors.append("scope.inventory_review.change_policy is not fail-closed")
    owners = catalog.get("owners")
    if not isinstance(owners, dict) or not owners:
        errors.append("owners must be a non-empty object")
        owners = {}
    for owner, value in owners.items():
        if not isinstance(value, dict) or not value.get("responsibility"):
            errors.append(f"owner {owner} lacks responsibility")
    rules = catalog.get("owner_rules")
    if not isinstance(rules, list) or not rules:
        errors.append("owner_rules must be a non-empty list")
        rules = []
    seen_globs: set[str] = set()
    for index, rule in enumerate(rules):
        if not isinstance(rule, dict) or set(rule) != {"glob", "owner"}:
            errors.append(f"owner_rules[{index}] must contain exact glob/owner")
            continue
        pattern = rule.get("glob")
        owner = rule.get("owner")
        if not isinstance(pattern, str) or not pattern:
            errors.append(f"owner_rules[{index}].glob must be non-empty")
        elif pattern in seen_globs:
            errors.append(f"duplicate owner glob: {pattern}")
        else:
            seen_globs.add(pattern)
        if owner not in owners:
            errors.append(f"owner_rules[{index}] references unknown owner {owner}")
    for owner, patterns in (catalog.get("owner_globs") or {}).items():
        if owner not in owners:
            errors.append(f"owner_globs references unknown owner {owner}")
        if not isinstance(patterns, list) or not all(
            isinstance(pattern, str) and pattern for pattern in patterns
        ):
            errors.append(f"owner_globs.{owner} must be a non-empty string list")
    overrides = catalog.get("file_overrides")
    if not isinstance(overrides, dict):
        errors.append("file_overrides must be an object")
        overrides = {}
    allowed_override_keys = {
        "owner",
        "role",
        "intent",
        "review_expiry",
        "configuration_scope",
    }
    for path, value in overrides.items():
        if not isinstance(path, str) or not path.startswith("npc/rv64/vsrc/"):
            errors.append(f"file override path is outside vsrc: {path}")
            continue
        if not isinstance(value, dict) or not value:
            errors.append(f"file override must be a non-empty object: {path}")
            continue
        extra = set(value) - allowed_override_keys
        if extra:
            errors.append(f"file override {path} has unsupported keys: {sorted(extra)}")
        owner = value.get("owner")
        if owner is not None and owner not in owners:
            errors.append(f"file override {path} references unknown owner {owner}")
        role = value.get("role")
        if role is not None and role not in ROLES:
            errors.append(f"file override {path} has invalid role {role}")
        for field in ("intent", "review_expiry", "configuration_scope"):
            if field in value and (not isinstance(value[field], str) or not value[field]):
                errors.append(f"file override {path}.{field} must be non-empty")
        if role in NON_PRODUCT_ROLES:
            missing = {
                field
                for field in ("intent", "review_expiry", "configuration_scope")
                if not value.get(field)
            }
            if missing:
                errors.append(
                    f"non-product override {path} lacks explicit {sorted(missing)}"
                )
        configuration_scope = value.get("configuration_scope")
        allowed_scopes = {
            "product": {"product_core"},
            "catalog_only": {"catalog_compiled"},
            "debug_only": {"sim_top", "focused_only"},
            "sim_only": {"sim_top"},
        }
        if role in allowed_scopes and configuration_scope is not None:
            if configuration_scope not in allowed_scopes[role]:
                errors.append(
                    f"file override {path} configuration_scope={configuration_scope} "
                    f"is invalid for role={role}"
                )
    capabilities = catalog.get("capabilities")
    if not isinstance(capabilities, dict) or not capabilities:
        errors.append("capabilities must be a non-empty object")
        capabilities = {}
    for capability, value in capabilities.items():
        if not isinstance(value, dict):
            errors.append(f"capability {capability} must be an object")
            continue
        required = {"label", "owner", "files", "dynamic_evidence", "closure_condition"}
        if not required.issubset(value):
            errors.append(
                f"capability {capability} lacks {sorted(required - set(value))}"
            )
        if value.get("owner") not in owners:
            errors.append(
                f"capability {capability} references unknown owner {value.get('owner')}"
            )
        transaction_ir = value.get("transaction_ir")
        if not isinstance(transaction_ir, dict) or set(transaction_ir) != {
            "configuration",
            "nodes",
            "edges",
            "invariants",
            "unknowns",
        }:
            errors.append(f"capability {capability} transaction_ir is incomplete")
            continue
        transaction_nodes: set[str] = set()
        for index, node in enumerate(transaction_ir.get("nodes", [])):
            if not isinstance(node, dict) or set(node) != {"id", "label"}:
                errors.append(
                    f"capability {capability} transaction node[{index}] is invalid"
                )
                continue
            node_id = node.get("id")
            if not isinstance(node_id, str) or not node_id or node_id in transaction_nodes:
                errors.append(
                    f"capability {capability} transaction node[{index}] id is invalid"
                )
            else:
                transaction_nodes.add(node_id)
        for index, edge in enumerate(transaction_ir.get("edges", [])):
            if not isinstance(edge, dict) or set(edge) != {
                "from",
                "to",
                "relation",
                "latency",
            }:
                errors.append(
                    f"capability {capability} transaction edge[{index}] is invalid"
                )
                continue
            if edge.get("from") not in transaction_nodes or edge.get("to") not in transaction_nodes:
                errors.append(
                    f"capability {capability} transaction edge[{index}] references unknown node"
                )
        strategy = value.get("physical_strategy")
        if not isinstance(strategy, dict) or set(strategy) != {
            "decision",
            "next_slice",
            "rollback",
        }:
            errors.append(f"capability {capability} physical_strategy is incomplete")
    boundaries = catalog.get("physical_boundaries")
    if not isinstance(boundaries, dict) or not boundaries:
        errors.append("physical_boundaries must be a non-empty object")
        boundaries = {}
    for module, value in boundaries.items():
        required = {
            "rtl",
            "liberty",
            "model",
            "blackbox_in_mapped_flow",
            "netlist_representation",
            "timing_model_kind",
            "internal_path_evidence",
            "area_basis",
            "power_basis",
            "closure_state",
            "capability",
        }
        if not isinstance(value, dict) or set(value) != required:
            errors.append(f"physical boundary {module} has an invalid key set")
            continue
        for field in ("rtl", "liberty"):
            path_value = value.get(field)
            if not isinstance(path_value, str) or not repo_path(path_value, root=root).is_file():
                errors.append(f"physical boundary {module}.{field} is missing")
        allowed_models = {
            "placeholder_non_signoff",
            "inline_measurement_candidate",
            "inline_stdcell_measured",
            "production_child_split_candidate",
            "characterized_ooc_signoff",
        }
        if value.get("model") not in allowed_models:
            errors.append(f"physical boundary {module} model is not an allowed state")
        if not isinstance(value.get("blackbox_in_mapped_flow"), bool):
            errors.append(f"physical boundary {module} blackbox state must be boolean")
        if value.get("closure_state") == "PASS":
            if value.get("model") not in {
                "inline_stdcell_measured",
                "characterized_ooc_signoff",
            }:
                errors.append(
                    f"physical boundary {module} cannot close with model={value.get('model')}"
                )
            for field in (
                "internal_path_evidence",
                "area_basis",
                "power_basis",
            ):
                if value.get(field) in {
                    "absent",
                    "unknown_excluded_from_logic_area_proxy",
                    "unqualified_fixed_toggle_or_absent",
                }:
                    errors.append(
                        f"physical boundary {module} cannot close with {field}={value.get(field)}"
                    )
    run_parameter_contract = catalog.get("run_parameter_contract")
    if run_parameter_contract != EXPECTED_RUN_PARAMETER_CONTRACT:
        errors.append(
            "run_parameter_contract drifted from the authorized NpcTop 5 ns live "
            "flat-read-view contract"
        )
    else:
        for field in ("sdc_file", "standard_cell_lib"):
            relative = run_parameter_contract[field]
            if not repo_path(relative, root=root).is_file():
                errors.append(f"run_parameter_contract.{field} is missing: {relative}")
        opensta_binary = Path(run_parameter_contract["opensta_binary"])
        if not opensta_binary.is_absolute() or not opensta_binary.is_file():
            errors.append("run_parameter_contract.opensta_binary is unavailable")
    errors.extend(physical_configuration_contract_errors(catalog))
    errors.extend(bpu_physical_experiment_state_errors(catalog, root=root))
    evidence = catalog.get("evidence")
    expected_evidence_keys = {
        "elaboration_receipt",
        "functional_result",
        "module_result",
        "l3_result",
        "mapped_summary",
        "latest_mapped_attempt",
    }
    if not isinstance(evidence, dict) or set(evidence) != expected_evidence_keys:
        errors.append(
            "evidence must contain exact derived receipt pointers; manual mapped_design_id "
            "is forbidden"
        )
    else:
        if evidence.get("mapped_summary") != FROZEN_B279_MAPPED_SUMMARY:
            errors.append(
                "evidence.mapped_summary must remain the latest successful bound B279 summary"
            )
        if evidence.get("latest_mapped_attempt") != FAILED_F5F2_STATUS:
            errors.append(
                "evidence.latest_mapped_attempt must point to the failed f5f2 status"
            )
    nodes = catalog.get("architecture_nodes")
    edges = catalog.get("architecture_edges")
    node_ids: set[str] = set()
    if not isinstance(nodes, list):
        errors.append("architecture_nodes must be a list")
        nodes = []
    for index, node in enumerate(nodes):
        if not isinstance(node, dict) or set(node) != {"id", "label", "kind"}:
            errors.append(f"architecture_nodes[{index}] has an invalid key set")
            continue
        node_id = node.get("id")
        if not isinstance(node_id, str) or not node_id:
            errors.append(f"architecture_nodes[{index}].id must be non-empty")
        elif node_id in node_ids:
            errors.append(f"duplicate architecture node: {node_id}")
        else:
            node_ids.add(node_id)
    if not isinstance(edges, list):
        errors.append("architecture_edges must be a list")
        edges = []
    for index, edge in enumerate(edges):
        if not isinstance(edge, dict) or set(edge) != {"from", "to", "relation"}:
            errors.append(f"architecture_edges[{index}] has an invalid key set")
            continue
        if edge.get("from") not in node_ids or edge.get("to") not in node_ids:
            errors.append(f"architecture_edges[{index}] references an unknown node")
    return errors


def git_state(root: Path, source_root: str) -> tuple[str, set[str], dict[str, str], list[str]]:
    head = run_checked(
        ["git", "rev-parse", "HEAD"], root=root
    ).stdout.strip()
    tracked_raw = run_checked(
        ["git", "ls-files", "-z", "--", source_root], root=root
    ).stdout
    tracked = {item for item in tracked_raw.split("\0") if item}
    status_raw = run_checked(
        [
            "git",
            "status",
            "--porcelain=v1",
            "--untracked-files=all",
            "--",
            source_root,
        ],
        root=root,
    ).stdout
    states: dict[str, str] = {}
    deleted: list[str] = []
    for line in status_raw.splitlines():
        if len(line) < 4:
            continue
        code = line[:2]
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        if code == "??":
            states[path] = "development"
        elif "D" in code:
            states[path] = "retired_unapproved"
            deleted.append(path)
        else:
            states[path] = "revision"
    return head, tracked, states, sorted(deleted)


def make_filelists(root: Path) -> dict[str, set[str]]:
    rv64 = root / "npc/rv64"
    source_root = (rv64 / "vsrc").resolve()
    goal = "print-architecture-registry-lists"
    eval_text = (
        f"{goal}:\n"
        "\t@printf 'core\\t%s\\n' \"$(RTL_CORE_SRCS)\"\n"
        "\t@printf 'header\\t%s\\n' \"$(RTL_HEADER_SRCS)\"\n"
        "\t@printf 'sim\\t%s\\n' \"$(SIM_TOP_SRCS)\"\n"
    )
    completed = run_checked(
        [
            "make",
            "--no-print-directory",
            "-s",
            "-C",
            str(rv64),
            "-f",
            "vsrc/filelist.mk",
            f"VSRCDIR={source_root}",
            f"--eval={eval_text}",
            goal,
        ],
        root=root,
    )
    result: dict[str, set[str]] = {"core": set(), "header": set(), "sim": set()}
    for line in completed.stdout.splitlines():
        key, separator, value = line.partition("\t")
        if not separator or key not in result:
            raise RegistryError(f"unexpected filelist output: {line!r}")
        for token in value.split():
            path = Path(token).resolve()
            try:
                relative = path.relative_to(root.resolve()).as_posix()
            except ValueError as exc:
                raise RegistryError(f"filelist path escapes repository: {path}") from exc
            if not path.is_file():
                raise RegistryError(f"filelist path is missing: {relative}")
            if relative in result[key]:
                raise RegistryError(f"duplicate {key} filelist entry: {relative}")
            result[key].add(relative)
    if not result["core"] or not result["header"] or not result["sim"]:
        raise RegistryError("canonical filelist output is incomplete")
    return result


def design_binding(root: Path, source_root: str) -> tuple[str, dict[str, str]]:
    base = root / source_root
    files = sorted(
        path
        for path in base.rglob("*")
        if path.is_file() and path.suffix.lower() in DESIGN_SUFFIXES
    )
    if not files:
        raise RegistryError("RV64 design source set is empty")
    entries = {
        path.relative_to(root).as_posix(): sha256_file(path)
        for path in files
    }
    return canonical_sha256(entries), entries


def inventory_review_errors(
    catalog: dict[str, Any], inventory_paths: list[str]
) -> list[str]:
    actual = canonical_sha256(sorted(inventory_paths))
    review = catalog.get("scope", {}).get("inventory_review", {})
    expected = review.get("path_set_sha256") if isinstance(review, dict) else None
    if actual == expected:
        return []
    return [
        "vsrc path inventory changed without architecture review: "
        f"catalog={expected} actual={actual}"
    ]


def verify_sha256_manifest(path: Path) -> dict[str, Any]:
    """Verify every retained sha256sum record against the current filesystem."""

    if not path.is_file():
        return {
            "manifest_sha256": None,
            "record_count": 0,
            "errors": [f"production manifest is missing: {path}"],
        }
    errors: list[str] = []
    records: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return {
            "manifest_sha256": sha256_file(path),
            "record_count": 0,
            "errors": [f"cannot read production manifest {path}: {exc}"],
        }
    for line_number, line in enumerate(lines, start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            errors.append(f"production manifest line {line_number} is non-canonical")
            continue
        expected, filename = match.groups()
        if filename in records:
            errors.append(f"production manifest duplicates input: {filename}")
            continue
        records[filename] = expected
        input_path = Path(filename)
        if not input_path.is_file():
            errors.append(f"production input is missing: {filename}")
            continue
        try:
            actual = sha256_file(input_path)
        except OSError as exc:
            errors.append(f"cannot hash production input {filename}: {exc}")
            continue
        if actual != expected:
            errors.append(
                f"production input drifted: {filename}; expected={expected} actual={actual}"
            )
    if not records:
        errors.append("production manifest has no records")
    return {
        "manifest_sha256": sha256_file(path),
        "record_count": len(records),
        "records_sha256": canonical_sha256(records) if records else None,
        "errors": errors,
    }


def mapped_runner_contract_errors(runner: str) -> list[str]:
    required = {
        "production-owned mapped STA parser":
            'parser="${repo_root}/npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"',
        "production-owned OpenSTA entry":
            'sta_tcl="${repo_root}/npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"',
        "explicit physical configuration CLI": "--physical-configuration)",
        "explicit expected RTL design-id CLI": "--expected-rtl-design-id)",
        "physical configuration syntax gate":
            '! "${physical_configuration}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$',
        "expected RTL design-id syntax gate":
            '! "${expected_rtl_design_id}" =~ ^sha256:[0-9a-f]{64}$',
        "registry expected design projection": "emit expected-rtl-design-id",
        "registry live design projection": "emit live-rtl-design-id",
        "catalog blackbox projection": "emit mapped-blackbox-modules",
        "catalog artifact profile projection": "emit mapped-artifact-profile",
        "catalog inline projection": "emit inline-modules",
        "catalog liberty projection": "emit macro-lib-files",
        "catalog keep-hierarchy projection": "emit keep-hierarchy-modules",
        "catalog standard-cell projection": "emit standard-cell-lib",
        "catalog SDC projection": "emit sdc-file",
        "catalog OpenSTA projection": "emit opensta-binary",
        "catalog run parameter artifact": "emit run-parameters",
        "OpenSTA profile consumes projection":
            'V15P_STA_MAPPED_ARTIFACT_PROFILE="${mapped_artifact_profile}"',
        "synthesis SDC consumes projection": 'STA_SDC_FILE="${sdc_file}"',
        "synthesis blackboxes consume projection":
            'STA_SYNTH_BLACKBOX_MODULES="${blackbox_modules}"',
        "synthesis hierarchy consumes contract":
            'STA_KEEP_HIERARCHY_MODULES="${keep_hierarchy_modules}"',
        "STA Liberty consumes projection": 'STA_EXTRA_LIB_FILES="${macro_libs[*]}"',
        "OpenSTA macro count consumes projection":
            'V15P_STA_EXPECTED_MACRO_LIB_COUNT="${#macro_libs[@]}"',
        "parser macro count consumes projection":
            '--expected-macro-lib-count "${#macro_libs[@]}"',
        "parser unknown-macro set consumes projection":
            '--expected-unknown-macro-modules "${blackbox_modules}"',
        "parser artifact profile consumes projection":
            '--mapped-artifact-profile "${mapped_artifact_profile}"',
        "binding defaults fail-closed": "binding_rc=1",
        "binding stamp command": "stamp-mapped-summary",
        "binding physical configuration argument":
            '--physical-configuration "${physical_configuration}"',
        "binding artifact profile argument":
            '--mapped-artifact-profile "${mapped_artifact_profile}"',
        "binding expected RTL design-id argument":
            '--expected-rtl-design-id "${expected_rtl_design_id}"',
        "binding parameters artifact": '--parameters "${parameters}"',
        "binding STA input manifest artifact":
            '--sta-input-manifest "${input_manifest}"',
        "binding raw synthesis statistics":
            '--synth-stat "${evidence_dir}/synth_stat.txt"',
        "actual blackbox arguments": '--blackbox-modules "${blackbox_modules}"',
        "actual inline arguments": '--inline-modules "${inline_modules}"',
        "actual liberty arguments": '--macro-lib-files "${macro_lib_rel[*]}"',
        "binding final gate": '"${binding_rc}" -eq 0',
        "binding status receipt": '"binding_rc=${binding_rc}"',
        # runner 必须生成 verifier 可接受的唯一绝对路径集合，不能靠 stamp 阶段补救。
        "canonical runner identity":
            'runner_path="$(realpath -e -- "${BASH_SOURCE[0]}")"',
        "explicit filelist de-duplication":
            '! -path "${repo_root}/npc/rv64/vsrc/filelist.mk"',
        "canonical runner manifest input":
            '"${architecture_registry}" "${runner_path}"',
        "pointer-free catalog binding note":
            "architecture_catalog 由去除 evidence pointer 的 policy/configuration 哈希绑定",
    }
    errors = [
        f"mapped runner lacks {label}"
        for label, marker in required.items()
        if marker not in runner
    ]
    manifest_function = re.search(
        r"(?ms)^production_manifest\(\) \{\n(.*?)^\}", runner
    )
    if manifest_function is None:
        errors.append("mapped runner lacks production manifest function")
    elif '"${architecture_catalog}"' in manifest_function.group(1):
        errors.append(
            "mapped runner production manifest binds the mutable catalog evidence pointer"
        )
    return errors


def mapped_sta_tool_contract_errors(sta_tcl: str, parser: str) -> list[str]:
    """Reject a regression to a physical-configuration-specific macro count."""

    required_tcl = {
        "projected macro-count environment":
            "V15P_STA_EXPECTED_MACRO_LIB_COUNT",
        "positive projected macro-count gate":
            "^[1-9][0-9]*$",
        "actual/projected macro-count comparison":
            'if {$macro_count != $expected_macro_count}',
        "completion receipt uses actual macro count":
            "macro_lib_count=$macro_count",
        "artifact profile environment":
            "V15P_STA_MAPPED_ARTIFACT_PROFILE",
        "artifact profile switch":
            "switch -- $mapped_artifact_profile",
        "BPU profile writer":
            "write_bpu_update_fanout_inventory $bpu_update_fanout_path",
        "FP negative-slack writer":
            "write_fp_negative_slack_inventory $fp_negative_slack_path",
        "FP internal-path writer":
            "write_fp_internal_timing_paths $fp_internal_paths_path",
        "completion receipt uses artifact profile":
            "mapped_artifact_profile=$mapped_artifact_profile",
    }
    required_parser = {
        "explicit expected macro-count CLI":
            'variant.add_argument("--expected-macro-lib-count", type=int, required=True)',
        "positive expected macro-count gate":
            "args.expected_macro_lib_count > 0",
        "completion receipt checks projected macro count":
            '"macro_lib_count": str(args.expected_macro_lib_count)',
        "summary retains projected macro count":
            '"macro_lib_count": args.expected_macro_lib_count',
        "explicit expected unknown-macro CLI":
            'variant.add_argument("--expected-unknown-macro-modules", required=True)',
        "area parser consumes projected unknown macros":
            "parse_area(args.synth_stat.resolve(), expected_unknown_macros)",
        "summary retains projected unknown macros":
            '"unknown_macro_modules": expected_unknown_macro_modules',
        "explicit mapped artifact profile CLI":
            'variant.add_argument(\n        "--mapped-artifact-profile"',
        "profile family parser":
            "profile_evidence = parse_mapped_profile_evidence(",
        "summary retains mapped artifact profile":
            '"mapped_artifact_profile": profile',
        "summary retains profile evidence":
            '"mapped_profile_evidence": profile_evidence',
        "FP synth-stat hierarchy census":
            "parse_fp_mapped_hierarchy_inventory(",
        "FP synth-stat direct-instance census":
            "instance_declarations",
        "FP hierarchy instance count is derived":
            '"instance_count": declared_instance_count',
        "FP negative-slack parser":
            "parse_fp_negative_slack_inventory(",
        "FP internal-path parser":
            "parse_fp_internal_timing_paths(",
    }
    errors = [
        f"mapped OpenSTA entry lacks {label}"
        for label, marker in required_tcl.items()
        if marker not in sta_tcl
    ]
    errors.extend(
        f"mapped STA parser lacks {label}"
        for label, marker in required_parser.items()
        if marker not in parser
    )
    if re.search(r"\$macro_count\s*!=\s*4\b", sta_tcl):
        errors.append("mapped OpenSTA entry hard-codes four macro liberties")
    if re.search(r'"macro_lib_count"\s*:\s*"4"', parser):
        errors.append("mapped STA parser hard-codes four macro liberties")
    if "EXPECTED_UNKNOWN_MACROS" in parser:
        errors.append("mapped STA parser hard-codes the unknown-macro set")
    return errors


def fp_ooc_composite_tool_contract_errors(
    runner: str,
    child_yosys_tcl: str,
    child_sta_tcl: str,
    top_sta_tcl: str,
    parser: str,
    schema: str,
) -> list[str]:
    """Keep the diagnostic OOC profile on one Registry-selected data path."""

    required_runner = {
        "exact physical configuration":
            "mapped-5ns-fp-arith-production-children-ooc-boundary-v1",
        "exact mapped artifact profile": "fp-arith-ooc-composite-v1",
        "canonical repository Python module root":
            'export PYTHONPATH="${repo_root}"',
        "immutable repository Python module root": "readonly PYTHONPATH",
        "Registry known-macro projection": "emit known-ooc-macro-modules",
        "Registry top-blackbox projection": "emit top-blackbox-modules",
        "Registry composite contract": "emit ooc-composite-contract",
        "single known-OOC synthesis class": "SYNTH_KNOWN_OOC_MODULES",
        "child synthesis timeout": "run_bounded 1800",
        "child STA timeout": "run_bounded 600",
        "top synthesis timeout": "run_bounded 5400",
        "top STA timeout": "run_bounded 1200",
        "disk cap": "12884901888",
        "before manifest": "production-manifest-before.sha256",
        "after manifest": "production-manifest-after.sha256",
        "bound stdlib whitelist": "stdlib-leaf-whitelist.json",
        "retained mapped manifest": "netlist-manifest.json",
        "run-bound output-bit driver contract": "output-bit-driver-contract.json",
        "driver contract before child OpenSTA":
            'stage="child-${module}-output-bit-driver-contract"',
        "child OpenSTA driver-contract projection":
            "FP_OOC_OUTPUT_BIT_DRIVER_CONTRACT_TCL",
        "retained child query progress":
            'query_progress_path="${child_dir}/child-query-progress-${analysis}.tsv"',
        "query progress completeness gate":
            '[[ -s "${timing_path}" && -s "${query_progress_path}" ]]',
        "failure stage freeze": 'local failure_stage="${stage}"',
        "failure stage restoration": 'stage="${failure_stage}"',
        "cleanup return-code status field": "CLEANUP_RC=%s",
        "child result directory assignment":
            'child_result_dir="${child_runtime}/${module}-200MHz"',
        "exact child result directory creation":
            'mkdir -p -- "${child_dir}" "${child_runtime}" "${child_result_dir}"',
        "exact runtime-parent cleanup": 'rmdir -- "${resolved_parent}"',
        "Registry identity source-closure emitter": "emit-child-sources",
        "Registry compile-source emitter": "emit-child-compile-sources",
        "retained child source-closure manifest": "source-closure.sha256",
        "retained child compile-source manifest": "compile-sources.sha256",
        "child Yosys consumes compile-source domain":
            '"${child_compile_sources[*]}" "${child_netlist}"',
        "single sealed status path": 'status_path="${evidence_dir}/gate-status.txt"',
        "Registry-generated top boundary contract": "top-boundary-contract.tcl",
        "composite parser": 'python3 "${composite_tool}" compose',
        "composite validator": 'python3 "${composite_tool}" validate',
        "tool manifest binds runner and composite tool":
            'sha256sum "${runner_path}" "${composite_tool}" "${composite_schema}"',
        "tool manifest binds imported Registry module":
            '"${architecture_registry}" "${architecture_catalog}"',
        "unique completion marker": "[TRACEABLE-FP-OOC-COMPOSITE][PASS]",
        "query-budget completion marker":
            "[FP-OOC-QUERY-BUDGET][PASS] child_analyses=10 complete=10",
    }
    required_child_yosys = {
        "registered child set": "OooFpFmaNormRoundPipe",
        "exact profile": "fp-arith-ooc-composite-v1",
        "shared mapping implementation": "source $shared_yosys",
        "machine census": "SYNTH_COMPOSITE_CENSUS_JSON",
        "retained design JSON": "SYNTH_COMPOSITE_DESIGN_JSON",
        "recursive OOC rejection": "cannot recursively instantiate known OOC macros",
    }
    required_child_sta = {
        "exact profile": "fp-arith-ooc-composite-v1",
        "max/min analysis": "FP_OOC_ANALYSIS must be max or min",
        "real timing query": "find_timing_paths",
        "explicit endpoint path cap":
            "-endpoint_path_count $endpoint_path_count",
        "bounded group path cap": "-group_path_count $group_path_count",
        "budgeted timing query wrapper": "proc budgeted_find_timing_paths",
        "exact per-input group cap":
            "1 1 input_arc $kind",
        "single output bulk query":
            "proc collect_output_timing_bulk",
        "output endpoint-name join":
            "proc output_rows_from_observations",
        "query progress schema": "npc-rv64-fp-ooc-query-progress-v1",
        "query progress flush": "flush $fp_ooc_progress_stream",
        "query-budget terminal verifier": "proc verify_query_budget",
        "AddSub exact query count": "$fp_ooc_expected_find_calls != 273",
        "AddSub exact PathEnd limit": "$fp_ooc_pathend_limit != 2364",
        "one PathEnd validation gate":
            "each Search-owned PathEnd must be materialized exactly once",
        "real Q launch collection": "register_q_pins",
        "PathEnd points validator":
            "proc validate_path_end {path_end label expected_min_max expected_roles from_names to_names}",
        "PathEnd points property": "get_property $path_end points",
        "first Path UI-ns arrival": "get_property $first_point arrival",
        "endpoint Path UI-ns arrival": "get_property $last_point arrival",
        "PathEnd min/max object method": "$path_end min_max",
        "PathEnd check-role object method": "$path_end check_role",
        "constrained PathEnd gate": "is not a constrained PathEnd",
        "zero input arrival seed gate":
            "input Path arrival seed is not explicit zero UI-ns",
        "cumulative clock-to-Q endpoint arrival": "return $endpoint_arrival_ns",
        "per-query PathEnd startpoint materialization":
            "set path_startpoint [dict get $observation startpoint]",
        "per-query PathEnd endpoint materialization":
            "set path_endpoint [dict get $observation endpoint]",
        "ordinary selected startpoint state":
            "set selected_startpoint $path_startpoint",
        "ordinary selected endpoint state":
            "set selected_endpoint $path_endpoint",
        "explicit zero rising clock waveform":
            "-waveform [list $fp_ooc_clock_origin_ns [expr {$period_ns / 2.0}]]",
        "zero source clock latency":
            "set_clock_latency -source $fp_ooc_clock_source_latency_ns",
        "zero network clock latency":
            "set_clock_latency $fp_ooc_clock_network_latency_ns",
        "unpropagated clock basis": "set fp_ooc_clock_propagated 0",
        "Registry input-port contract": "FP_OOC_INPUT_PORT_CONTRACT",
        "Tcl-safe exact port-family parser":
            "proc exact_port_family {family width direction}",
        "brace-quoted bracket port-family pattern":
            "set bracket_pattern [format {^%s\\[([0-9]+)\\]$} $family]",
        "brace-quoted splitnets port-family pattern":
            "set splitnets_pattern [format {^%s__v([0-9]+)$} $family]",
        "brace-quoted underscore port-family pattern":
            "set underscore_pattern [format {^%s_([0-9]+)_$} $family]",
        "canonical decimal port index gate":
            "regexp {^(?:0|[1-9][0-9]*)$} $index_text",
        "single indexed-style gate":
            '$selected_style ne "" && $selected_style ne $style',
        "unique port index gate": "dict exists $indexed_ports $index",
        "continuous port index coverage":
            "for {set index 0} {$index < $width} {incr index}",
        "exact port direction gate":
            "get_property $port direction] ne $direction",
        "width-one exact scalar gate":
            '$width == 1 && $selected_style ne "scalar"',
        "per-port measured arc inventory": "arc_inventory",
        "run-bound output-bit contract source":
            "FP_OOC_OUTPUT_BIT_DRIVER_CONTRACT_TCL",
        "driver contract exact derived row count":
            "[llength $::fp_ooc_output_bit_driver_contract] != $expected",
        "driver contract six-field row gate":
            "if {[llength $row] != 6}",
        "bit-exact output timing inventory": "output_bit_inventory",
        "structural constant has zero Q paths":
            "structurally constant output has a register-Q timing path",
        "dynamic output requires a Q path":
            "dynamic output has no real register-Q timing path",
        "port-to-register class": "port_to_register",
        "register-to-port class": "register_to_port",
        "synchronous control class": "synchronous_control_to_register",
        "MulProduct no internal reg-to-reg":
            "register_to_register NOT_APPLICABLE",
    }
    required_top_sta = {
        "exact profile": "fp-arith-ooc-composite-v1",
        "five known OOC libraries": "exactly five known OOC Liberty models",
        "three unknown placeholder libraries":
            "exactly three unknown-placeholder Liberty module families",
        "real timing query": "find_timing_paths",
        "actual pin object intersection": "actual_pin_crosscheck",
        "actual pin full-name equality": "$exact_name ne $full",
        "actual parent cell intersection": "actual_parent_cell_crosscheck",
        "backend completion register-D collection":
            "exact_backend_completion_register_d_objects",
        "Registry exact boundary input": "FP_OOC_TOP_BOUNDARY_CONTRACT_TCL",
        "Registry-generated five-boundary iterator":
            "foreach contract $fp_ooc_boundary_contract",
        "Registry top exact five-row gate":
            "[llength $fp_ooc_boundary_contract] != 5",
        "Registry top eight-field row gate":
            "if {[llength $contract] != 8}",
        "constant macro output timing non-override":
            "never receive a synthetic top-level timing",
    }
    required_parser = {
        "Registry projection": "registry.mapped_projection",
        "sequential Liberty validator": "validate_sequential_liberty",
        "measured setup derivation":
            "max(0,period_ns-input_delay_ns-worst_slack_ns)",
        "measured hold derivation":
            "max(0,input_delay_ns-worst_slack_ns)",
        "measured clk-to-Q derivation": "max(0.001,worst_path_delay_ns)",
        "Registry path-measurement basis binding":
            '"path_measurement_basis": projection()["ooc_model_contract"]',
        "bound stdlib whitelist validator": "validate_stdlib_whitelist",
        "output-bit driver contract builder":
            "build_output_bit_driver_contract",
        "unique mapped output driver gate":
            "output bit has {len(drivers)} mapped drivers",
        "bound output-pin function parser":
            "_stdlib_output_pin_functions",
        "structured literal timing-group parser":
            "_validate_literal_output_timing_groups",
        "whitespace-invariant Liberty group scanner":
            "_extract_liberty_group_blocks",
        "isolated tied-off literal policy":
            "literal stdlib output timing must be an isolated",
        "tied-off SI allowlist gate":
            "literal stdlib tied_off group carries unsupported or ordinary semantics",
        "bit timing/constant XOR validator":
            "validate_output_bit_timing_inventory",
        "complete structural bit-partition validator":
            "validate_output_bit_driver_partition",
        "shared Tcl list-of-lists row encoder":
            "def render_tcl_row_table(",
        "Tcl row atom fail-closed validator":
            "def validate_tcl_row_table(",
        "Tcl brace/backslash atom rejection": "TCL_SAFE_ATOM_RE",
        "bitwise Liberty member emission":
            'pin ({name}[{index}])',
        "dynamic Liberty member state function":
            "_dynamic_state_name",
        "mixed-bus inherited behavior rejection":
            "carries inherited behavior",
        "dollar-generic rejection": "unmapped dollar generic cell remains",
        "retained complete manifest validator": "validate_netlist_manifest",
        "backend completion endpoint projection":
            "backend_completion_register_d",
        "identity replay gate": "validate_identity",
        "hierarchy census": "recursive_design_census",
        "area single accounting":
            "top_excludes_known_ooc_macro_area_plus_each_child_once",
        "zero-negative acceptance": '"zero_negative_slack_is_valid": True',
        "incomplete power claim": "INCOMPLETE_NO_OOC_POWER_MODEL",
        "non-signoff claim": "DIAGNOSTIC_OOC_COMPOSITE_ONLY",
        "query progress parser": "def parse_query_progress(",
        "query budget validator": "def validate_query_budget(",
        "exact query sequence": "def _query_budget_expected_sequence(",
        "AddSub 273/2364 gate":
            "OooFpAddSubPipe 5.0ns query budget is not 273/2364",
        "hardlink replay rejection": "st_nlink == 1",
        "Registry compile-source command":
            "command_emit_child_compile_sources",
        "Registry compile-source CLI": "emit-child-compile-sources",
        "Registry-driven post-split port canonicalizer":
            "canonicalize_retained_ports",
        "retained raw split-port manifest": '"raw_ports"',
        "auditable raw-to-canonical port map": '"raw_to_canonical"',
        "child result port-manifest binding": '"port_manifest"',
        "manifest-to-netlist digest binding": "expected_netlist_sha256",
        "manifest-to-netlist size binding": "expected_netlist_size_bytes",
        "strict port-family parser": "_parse_port_object_family",
        "strict port-family coverage validator":
            "_validate_port_object_family_names",
        "underscore mapped-port style":
            '("underscore", rf"{re.escape(family)}_([0-9]+)_")',
        "canonical mapped-port decimal index":
            're.fullmatch(r"(?:0|[1-9][0-9]*)", index_text)',
        "continuous mapped-port index coverage":
            "set(indices) == set(range(width))",
        "direct PORT full-object parser": "candidate = name",
        "hierarchical PORT owner rejection":
            'require("/" not in name,',
    }
    required_schema = {
        "schema ID": "npc-rv64-fp-ooc-composite-v1",
        "diagnostic claim": "DIAGNOSTIC_OOC_COMPOSITE_ONLY",
        "power gap": "INCOMPLETE_NO_OOC_POWER_MODEL",
        "physical GAP": '"physical_status": {"const": "GAP"}',
        "per-port arc schema": '"arcRecord"',
        "retained manifest receipt": '"netlist_manifest"',
        "post-split port-manifest schema": '"portManifestSummary"',
        "post-split port-manifest field": '"port_manifest"',
        "output-bit timing schema": '"outputBitTimingRecord"',
        "run-bound output-bit driver schema": '"outputBitDriverContract"',
        "output-bit driver receipt": '"output_bit_driver_contract"',
        "query-budget schema": '"queryBudget"',
        "query-progress schema ID": "npc-rv64-fp-ooc-query-progress-v1",
    }
    groups = (
        ("runner", runner, required_runner),
        ("child Yosys Tcl", child_yosys_tcl, required_child_yosys),
        ("child OpenSTA Tcl", child_sta_tcl, required_child_sta),
        ("top OpenSTA Tcl", top_sta_tcl, required_top_sta),
        ("composite parser", parser, required_parser),
        ("composite schema", schema, required_schema),
    )
    errors = [
        f"FP OOC {group} lacks {label}"
        for group, text, requirements in groups
        for label, marker in requirements.items()
        if marker not in text
    ]
    parser_start = parser.find("def _parse_port_object_family")
    parser_end = parser.find("\ndef _port_object_matches_family", parser_start)
    if parser_start < 0 or parser_end < 0:
        errors.append("FP OOC composite parser lacks bounded PORT-family parser")
    elif "rsplit" in parser[parser_start:parser_end]:
        errors.append(
            "FP OOC composite parser discards hierarchical PORT ownership"
        )

    # PathEnd timing values must stay in one unit domain.  PropertyValue
    # renders Path point arrival/slack in UI nanoseconds; raw SWIG Path arrival
    # methods and a second sta::time_sta_ui conversion are different domains.
    forbidden_child_sta = {
        "secondary UI-time conversion": "sta::time_sta_ui",
        "PathEnd data-arrival offset": "data_arrival_time",
        "period/slack pseudo path-delay derivation": "period_ns -",
        "required/slack pseudo path-delay derivation": "required -",
        "deprecated path-group query": "-group_count",
        "cross-query selected PathEnd retention": "selected_path",
        "cross-query selected Path points retention": "selected_points",
        "unbounded 100000 path group": "group_path_count 100000",
    }
    for label, marker in forbidden_child_sta.items():
        if marker in child_sta_tcl:
            errors.append(f"FP OOC child OpenSTA Tcl uses forbidden {label}")
    if re.search(
        r"get_property\s+\$(?:path|path_end)\s+(?:path_delay|delay|arrival)\b",
        child_sta_tcl,
    ):
        errors.append(
            "FP OOC child OpenSTA Tcl reads a PathEnd pseudo delay/arrival property"
        )
    if re.search(r"\$(?:path|path_end)\s+arrival\b", child_sta_tcl):
        errors.append(
            "FP OOC child OpenSTA Tcl mixes raw SWIG Path arrival with UI properties"
        )
    input_delta = (
        "set delay_ns [expr {$endpoint_arrival_ns - $first_arrival_ns}]"
    )
    if child_sta_tcl.count(input_delta) != 1 or child_sta_tcl.count(
        "return $endpoint_arrival_ns"
    ) != 1:
        errors.append(
            "FP OOC child OpenSTA Tcl does not uniquely separate input delta "
            "from cumulative clock-to-Q arrival"
        )
    measured_start = child_sta_tcl.find("proc measured_path_delay_ns")
    measured_end = child_sta_tcl.find("\nproc parse_port_contract", measured_start)
    if measured_start < 0 or measured_end < 0 or "validate_path_end" in child_sta_tcl[
            measured_start:measured_end]:
        errors.append(
            "FP OOC child OpenSTA Tcl revalidates a PathEnd while measuring delay"
        )
    if child_sta_tcl.count("find_timing_paths -from") != 1:
        errors.append(
            "FP OOC child OpenSTA Tcl bypasses the single budgeted query wrapper"
        )

    # fp_ooc_composite.py imports npc.* and is launched by file path.  Accept
    # exactly one caller-independent repository root, fixed immediately after
    # canonical repo_root discovery and before either Python tool can run.
    pythonpath_lines = [
        line.strip()
        for line in runner.splitlines()
        if "PYTHONPATH" in line and not line.lstrip().startswith("#")
    ]
    expected_pythonpath_lines = [
        'export PYTHONPATH="${repo_root}"',
        "readonly PYTHONPATH",
    ]
    if pythonpath_lines != expected_pythonpath_lines:
        errors.append(
            "FP OOC runner lacks deterministic repository PYTHONPATH binding"
        )
    repo_root_position = runner.find('repo_root="$(realpath -e --')
    export_position = runner.find(expected_pythonpath_lines[0])
    readonly_position = runner.find(expected_pythonpath_lines[1])
    python_tool_positions = [
        runner.find('python3 "${architecture_registry}"'),
        runner.find('python3 "${composite_tool}"'),
    ]
    if (
        repo_root_position < 0
        or export_position < 0
        or readonly_position < 0
        or any(position < 0 for position in python_tool_positions)
        or not (
            repo_root_position
            < export_position
            < readonly_position
            < min(python_tool_positions)
        )
    ):
        errors.append(
            "FP OOC runner PYTHONPATH binding does not precede all Python tool calls"
        )

    def shell_function_body(name: str) -> str:
        start = runner.find(f"{name}() {{")
        if start < 0:
            return ""
        end = runner.find("\n}\n", start)
        return runner[start:end if end >= 0 else len(runner)]

    finalize_body = shell_function_body("finalize_on_exit")
    finalize_markers = (
        'local failure_stage="${stage}"',
        "cleanup_runtime",
        'stage="${failure_stage}"',
        "write_status FAIL",
    )
    finalize_positions = [finalize_body.find(marker) for marker in finalize_markers]
    if (
        any(position < 0 for position in finalize_positions)
        or finalize_positions != sorted(finalize_positions)
    ):
        errors.append(
            "FP OOC runner failure-stage cleanup ordering is not freeze-cleanup-restore-write"
        )
    signal_body = shell_function_body("forward_signal")
    signal_markers = (
        'stage="signal-${signal_name}"',
        "cleanup_runtime",
        "write_status FAIL",
    )
    signal_positions = [signal_body.find(marker) for marker in signal_markers]
    if (
        any(position < 0 for position in signal_positions)
        or signal_positions != sorted(signal_positions)
    ):
        errors.append(
            "FP OOC runner signal-stage cleanup ordering is not stage-cleanup-write"
        )
    if "stage=exit-trap" in runner:
        errors.append("FP OOC runner overwrites the real failure stage with exit-trap")

    child_directory_markers = (
        'child_result_dir="${child_runtime}/${module}-200MHz"',
        'mkdir -p -- "${child_dir}" "${child_runtime}" "${child_result_dir}" || fail 1',
        'child_netlist="${child_result_dir}/${module}.netlist.v"',
        "run_bounded 1800",
    )
    child_directory_positions = [
        runner.find(marker) for marker in child_directory_markers
    ]
    if (
        any(position < 0 for position in child_directory_positions)
        or child_directory_positions != sorted(child_directory_positions)
        or any(runner.count(marker) != 1 for marker in child_directory_markers)
    ):
        errors.append(
            "FP OOC runner child result directory ordering is not "
            "assignment-create-netlist-synthesis"
        )

    source_domain_markers = (
        'emit-child-sources --module "${module}"',
        'sha256sum "${child_source_closure[@]}" >"${child_dir}/source-closure.sha256"',
        'emit-child-compile-sources --module "${module}"',
        'sha256sum "${child_compile_sources[@]}" >"${child_dir}/compile-sources.sha256"',
        '"${child_compile_sources[*]}" "${child_netlist}"',
    )
    source_domain_positions = [runner.find(marker) for marker in source_domain_markers]
    if (
        any(position < 0 for position in source_domain_positions)
        or source_domain_positions != sorted(source_domain_positions)
        or runner.count(source_domain_markers[0]) != 1
        or runner.count(source_domain_markers[2]) != 1
        or runner.count(source_domain_markers[4]) != 1
    ):
        errors.append(
            "FP OOC runner source domains are not closure-hash then "
            "compile-hash then compile-only Yosys"
        )
    for forbidden_compile_input in (
        '"${child_source_closure[*]}" "${child_netlist}"',
        '"${child_sources[*]}" "${child_netlist}"',
    ):
        if forbidden_compile_input in runner:
            errors.append(
                "FP OOC runner sends identity source_closure to child Yosys"
            )

    cleanup_body = shell_function_body("cleanup_runtime")
    cleanup_markers = (
        '[[ -e "${runtime_parent}" ]] || return 1',
        'resolved_parent="$(realpath -e -- "${runtime_parent}")"',
        'resolved_runtime="$(realpath -e -- "${runtime_dir}")"',
        '"${resolved_parent}"/run.*) rm -r -- "${resolved_runtime}" || return $? ;;',
        'rmdir -- "${resolved_parent}"',
    )
    cleanup_positions = [cleanup_body.find(marker) for marker in cleanup_markers]
    cleanup_lines = {
        line.strip()
        for line in cleanup_body.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if (
        any(position < 0 for position in cleanup_positions)
        or cleanup_positions != sorted(cleanup_positions)
        or 'rmdir -- "${resolved_parent}"' not in cleanup_lines
    ):
        errors.append(
            "FP OOC runner cleanup is not validate-random-delete-random-"
            "strict-rmdir-exact-parent"
        )
    parent_rmdir_lines = [
        line.strip()
        for line in runner.splitlines()
        if line.strip().startswith("rmdir ")
    ]
    if parent_rmdir_lines != ['rmdir -- "${resolved_parent}"']:
        errors.append(
            "FP OOC runner exact runtime-parent removal is not owned solely "
            "by cleanup_runtime"
        )
    success_cleanup_markers = (
        "stage=cleanup",
        "cleanup_runtime || cleanup_rc=$?",
        '[[ "${cleanup_rc}" -eq 0 ]] || fail "${cleanup_rc}"',
        "stage=complete",
    )
    success_cleanup_positions = [
        runner.rfind(marker) for marker in success_cleanup_markers
    ]
    if (
        any(position < 0 for position in success_cleanup_positions)
        or success_cleanup_positions != sorted(success_cleanup_positions)
    ):
        errors.append(
            "FP OOC runner success cleanup does not share fail-closed "
            "cleanup_runtime ownership"
        )

    for forbidden in ("set_false_path", "set_multicycle_path"):
        if forbidden in child_sta_tcl or forbidden in top_sta_tcl:
            errors.append(f"FP OOC OpenSTA Tcl contains forbidden {forbidden}")
    if re.search(r'regexp\s+"', child_sta_tcl):
        errors.append(
            "FP OOC child OpenSTA Tcl contains double-quoted regexp command substitution"
        )
    for label, marker in (
        ("legacy top-port endpoint dispatch", 'endpoint_kind eq "top_port"'),
        ("legacy top-port object collector", "proc exact_top_port_objects"),
        ("legacy top-port crosscheck", "proc actual_port_crosscheck"),
    ):
        if marker in top_sta_tcl:
            errors.append(f"FP OOC top OpenSTA Tcl contains forbidden {label}")
    return errors


def module_names(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise RegistryError(f"cannot read RTL source {path}: {exc}") from exc
    return MODULE_RE.findall(text)


def camel_to_snake(value: str) -> str:
    first = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", value)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", first).lower()


def owner_for(path: str, catalog: dict[str, Any], errors: list[str]) -> str:
    override = (catalog.get("file_overrides") or {}).get(path, {})
    if isinstance(override, dict) and override.get("owner"):
        owner = override["owner"]
        if owner not in catalog["owners"]:
            errors.append(f"{path}: override references unknown owner {owner}")
        return owner
    special: list[str] = []
    for owner, patterns in (catalog.get("owner_globs") or {}).items():
        if any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns):
            special.append(owner)
    if len(special) > 1:
        errors.append(f"{path}: multiple owner_globs match {sorted(special)}")
        return "UNOWNED"
    if special:
        return special[0]
    matches = [
        rule["owner"]
        for rule in catalog.get("owner_rules", [])
        if fnmatch.fnmatchcase(path, rule["glob"])
    ]
    if len(matches) != 1:
        errors.append(f"{path}: expected exactly one owner rule, got {sorted(matches)}")
        return "UNOWNED"
    return matches[0]


def role_for(path: str, lists: dict[str, set[str]], catalog: dict[str, Any]) -> str:
    override = (catalog.get("file_overrides") or {}).get(path, {})
    if isinstance(override, dict) and override.get("role"):
        return str(override["role"])
    if path in lists["header"]:
        return "source_fragment"
    # A directory name or SIM_TOP_SRCS membership is observation, not intent.
    # Every non-product source therefore needs an explicit file override.
    if path.startswith("npc/rv64/vsrc/debug/") or path.startswith(
        "npc/rv64/vsrc/sim/"
    ):
        return "unclassified"
    if path in lists["core"]:
        return "product"
    return "unclassified"


def file_registration_errors(
    path: str,
    *,
    role: str,
    lifecycle: str,
    lists: dict[str, set[str]],
    catalog: dict[str, Any],
) -> list[str]:
    """Validate human intent against derived filelist and Git observations."""

    errors: list[str] = []
    override = (catalog.get("file_overrides") or {}).get(path, {})
    if not isinstance(override, dict):
        override = {}
    configuration_scope = override.get("configuration_scope")
    if lifecycle == "development":
        required = ("role", "intent", "review_expiry", "configuration_scope")
        missing = [field for field in required if not override.get(field)]
        if missing or override.get("role") != role:
            errors.append(
                f"development RTL lacks explicit role acknowledgement: {path}; "
                f"missing={missing}"
            )
    if role == "product" and path not in lists["core"]:
        errors.append(f"product RTL is absent from RTL_CORE_SRCS: {path}")
    elif role == "catalog_only":
        if path not in lists["core"]:
            errors.append(f"catalog_only RTL is absent from compiled catalog: {path}")
        if configuration_scope != "catalog_compiled":
            errors.append(f"catalog_only RTL lacks catalog_compiled scope: {path}")
    elif role == "sim_only":
        if path not in lists["sim"]:
            errors.append(f"sim_only RTL is absent from SIM_TOP_SRCS: {path}")
        if configuration_scope != "sim_top":
            errors.append(f"sim_only RTL lacks sim_top scope: {path}")
    elif role == "debug_only":
        if configuration_scope == "sim_top" and path not in lists["sim"]:
            errors.append(f"debug sim_top RTL is absent from SIM_TOP_SRCS: {path}")
        elif configuration_scope == "focused_only" and path in lists["sim"]:
            errors.append(f"focused_only debug RTL unexpectedly entered SIM_TOP_SRCS: {path}")
        elif configuration_scope not in {"sim_top", "focused_only"}:
            errors.append(f"debug_only RTL lacks explicit configuration scope: {path}")
        if path in lists["core"]:
            errors.append(f"debug_only RTL unexpectedly entered RTL_CORE_SRCS: {path}")
    return errors


def file_reachability_status(
    path: str,
    *,
    role: str,
    modules: list[str],
    reachable_modules: set[str],
    elaboration_status: str,
) -> tuple[str, list[str]]:
    if elaboration_status != "PASS":
        return elaboration_status, []
    if role in {"sim_only", "debug_only"}:
        return "N_A", []
    if role == "source_fragment":
        return "DEPENDENCY_FRAGMENT", []
    live = any(module in reachable_modules for module in modules)
    if role == "catalog_only":
        if live:
            return "FAIL_UNEXPECTED", [f"catalog_only source became reachable: {path}"]
        return "PASS_EXCLUDED", []
    if live:
        return "PASS", []
    return "FAIL_UNREACHABLE", [f"product source is not top reachable: {path}"]


def original_module_name(elaborated_type: str) -> str:
    if elaborated_type.startswith("$paramod") and "\\" in elaborated_type:
        parts = elaborated_type.split("\\")
        if len(parts) >= 2 and parts[1]:
            return parts[1]
    return elaborated_type


def reachable_instances(yosys_json: dict[str, Any], top: str) -> list[dict[str, str]]:
    modules = yosys_json.get("modules")
    if not isinstance(modules, dict) or top not in modules:
        raise RegistryError(f"Yosys graph lacks top module {top}")
    rows: list[dict[str, str]] = [
        {"module": top, "path": top, "elaborated_type": top}
    ]

    def walk(module_type: str, parent: str, ancestors: tuple[str, ...]) -> None:
        if module_type in ancestors:
            raise RegistryError(
                "recursive module hierarchy: " + " -> ".join((*ancestors, module_type))
            )
        module = modules.get(module_type)
        cells = module.get("cells") if isinstance(module, dict) else None
        if not isinstance(cells, dict):
            return
        for instance, cell in sorted(cells.items()):
            cell_type = cell.get("type") if isinstance(cell, dict) else None
            if not isinstance(cell_type, str) or cell_type not in modules:
                continue
            path = f"{parent}.{instance}"
            rows.append(
                {
                    "module": original_module_name(cell_type),
                    "path": path,
                    "elaborated_type": cell_type,
                }
            )
            walk(cell_type, path, (*ancestors, module_type))

    walk(top, top, ())
    return sorted(rows, key=lambda row: (row["path"], row["module"]))


def synth_sources(root: Path) -> list[Path]:
    completed = run_checked(
        [
            "make",
            "--no-print-directory",
            "-s",
            "-C",
            str(root / "npc/rv64"),
            "print-synth-rtl",
        ],
        root=root,
    )
    paths = [Path(token).resolve() for token in completed.stdout.split()]
    if not paths or any(not path.is_file() for path in paths):
        raise RegistryError("print-synth-rtl returned an invalid source list")
    if len(paths) != len(set(paths)):
        raise RegistryError("print-synth-rtl returned duplicate paths")
    return paths


def capture_elaboration(
    catalog: dict[str, Any],
    *,
    root: Path = REPO_ROOT,
    output: Path | None = None,
    yosys: str | None = None,
    timeout: int = 180,
) -> dict[str, Any]:
    errors = validate_catalog(catalog, root=root)
    if errors:
        raise RegistryError("catalog invalid: " + "; ".join(errors))
    scope = catalog["scope"]
    design_id, _ = design_binding(root, scope["source_root"])
    sources = synth_sources(root)
    source_records = [
        {
            "path": path.relative_to(root).as_posix(),
            "sha256": sha256_file(path),
        }
        for path in sources
    ]
    source_manifest_sha256 = canonical_sha256(source_records)
    requested = Path(yosys) if yosys else None
    if requested is None:
        bundled = root / "oss-cad-suite/bin/yosys"
        requested = bundled if bundled.is_file() else Path(shutil.which("yosys") or "")
    if not requested or not requested.is_file():
        raise RegistryError("Yosys executable is unavailable")
    executable = requested.resolve()
    version = run_checked([str(executable), "-V"], root=root).stdout.strip()
    top = scope["top_module"]
    include_dirs = [
        "npc/rv64/vsrc",
        "npc/rv64/vsrc/include",
    ]
    command = ["read_verilog", "-sv"]
    command.extend(f"-I {path}" for path in include_dirs)
    command.extend(
        f"-D {name}={value}" for name, value in sorted(EXPECTED_DEFINES.items())
    )
    command.extend(row["path"] for row in source_records)
    with tempfile.TemporaryDirectory(prefix="rv64-architecture-elab-") as temp:
        temp_root = Path(temp)
        json_path = temp_root / "hierarchy.json"
        script_path = temp_root / "hierarchy.ys"
        script = (
            " ".join(command)
            + f"\nhierarchy -check -top {top}\n"
            + "proc\n"
            + f"write_json {json_path.as_posix()}\n"
        )
        script_path.write_text(script, encoding="utf-8")
        completed = subprocess.run(
            [str(executable), "-q", "-s", str(script_path)],
            cwd=root,
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout,
        )
        if completed.returncode != 0 or not json_path.is_file():
            detail = (completed.stderr or completed.stdout).strip()
            raise RegistryError(
                f"Yosys hierarchy capture failed rc={completed.returncode}"
                + (f": {detail}" if detail else "")
            )
        yosys_json = load_json(json_path)
        instances = reachable_instances(yosys_json, top)
    receipt: dict[str, Any] = {
        "schema": ELAB_SCHEMA,
        "status": "PASS",
        "product": scope["product"],
        "top_module": top,
        "design_id": f"sha256:{design_id}",
        "source_manifest_sha256": source_manifest_sha256,
        "source_count": len(source_records),
        "source_files": source_records,
        "product_defines": EXPECTED_DEFINES,
        "elaborator": {
            "name": "yosys",
            "path": (
                executable.relative_to(root).as_posix()
                if executable.is_relative_to(root)
                else executable.as_posix()
            ),
            "version": version,
            "executable_sha256": sha256_file(executable),
        },
        "reachable_instance_count": len(instances),
        "reachable_modules": sorted({row["module"] for row in instances}),
        "instances": instances,
    }
    receipt["receipt_id"] = f"sha256:{canonical_sha256(receipt)}"
    destination = output or repo_path(catalog["evidence"]["elaboration_receipt"], root=root)
    destination.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    destination.write_text(payload, encoding="utf-8")
    return receipt


def load_elaboration(
    catalog: dict[str, Any],
    *,
    root: Path,
    design_id: str,
    source_manifest_sha256: str,
) -> tuple[str, dict[str, Any] | None, str | None]:
    path = repo_path(catalog["evidence"]["elaboration_receipt"], root=root)
    if not path.is_file():
        return "GAP_MISSING", None, None
    try:
        receipt = load_json(path)
    except RegistryError:
        return "FAIL_INVALID", None, sha256_file(path)
    digest = sha256_file(path)
    if receipt.get("schema") != ELAB_SCHEMA or receipt.get("status") != "PASS":
        return "FAIL_INVALID", receipt, digest
    if receipt.get("design_id") != design_id:
        return "GAP_STALE_DESIGN", receipt, digest
    if receipt.get("source_manifest_sha256") != source_manifest_sha256:
        return "GAP_STALE_FILELIST", receipt, digest
    return "PASS", receipt, digest


def read_evidence_design(path: Path, field: str) -> tuple[str | None, dict[str, Any] | None]:
    if not path.is_file():
        return None, None
    try:
        value = load_json(path)
    except RegistryError:
        return None, None
    current: Any = value
    for component in field.split("."):
        if not isinstance(current, dict):
            return None, value
        current = current.get(component)
    return current if isinstance(current, str) else None, value


def dynamic_capability(
    capability: dict[str, Any],
    *,
    root: Path,
    live_design_id: str,
) -> dict[str, Any]:
    observations: list[dict[str, Any]] = []
    for evidence in capability.get("dynamic_evidence", []):
        kind = evidence.get("kind")
        if kind == "module_test":
            path = repo_path(evidence["result"], root=root)
            design, value = read_evidence_design(path, "design_id")
            module = evidence.get("module")
            expected_test = f"tb_{camel_to_snake(module)}" if isinstance(module, str) else ""
            inventory = (
                value.get("tests", {}).get("inventory", [])
                if isinstance(value, dict)
                else []
            )
            passed = (
                isinstance(value, dict)
                and value.get("status") == "PASS"
                and design == live_design_id
                and expected_test in inventory
            )
            observations.append(
                {
                    "kind": kind,
                    "subject": module,
                    "status": "PASS" if passed else "GAP",
                    "design_id": design,
                    "path": evidence["result"],
                    "sha256": sha256_file(path) if path.is_file() else None,
                }
            )
        elif kind == "log_regex":
            path = repo_path(evidence["path"], root=root)
            receipt_path = repo_path(evidence["design_receipt"], root=root)
            design, _ = read_evidence_design(receipt_path, evidence["design_field"])
            pattern = evidence.get("regex")
            matched = False
            if path.is_file() and isinstance(pattern, str):
                matched = re.search(
                    pattern,
                    path.read_text(encoding="utf-8", errors="replace"),
                ) is not None
            passed = matched and design == live_design_id
            observations.append(
                {
                    "kind": kind,
                    "subject": pattern,
                    "status": "PASS" if passed else "GAP",
                    "design_id": design,
                    "path": evidence["path"],
                    "sha256": sha256_file(path) if path.is_file() else None,
                }
            )
        else:
            observations.append(
                {
                    "kind": str(kind),
                    "subject": "unsupported",
                    "status": "FAIL",
                    "design_id": None,
                    "path": None,
                    "sha256": None,
                }
            )
    observed = bool(observations) and all(row["status"] == "PASS" for row in observations)
    return {
        "status": "OBSERVED_CLASS_INTERNAL_EDGE_GAP" if observed else "GAP",
        "observations": observations,
        "claim_boundary": (
            "同一 design identity 下相关指令/事务类别已非空；内部 "
            "lookup/update/kill/commit 边仍缺直接非零计数。"
            if observed
            else "当前 design identity 的动态证据不完整或已失效。"
        ),
    }


def mapped_projection(
    catalog: dict[str, Any],
    physical_configuration_id: str,
    *,
    root: Path = REPO_ROOT,
) -> dict[str, Any]:
    """Return one explicit configuration's exact mapped synthesis projection."""

    contract = catalog.get("run_parameter_contract")
    if contract != EXPECTED_RUN_PARAMETER_CONTRACT:
        raise RegistryError("run parameter contract is invalid")
    configuration = selected_physical_configuration(
        catalog, physical_configuration_id
    )
    modes = configuration["boundary_modes"]
    blackboxes: list[str] = []
    inline_modules: list[str] = []
    libraries: list[dict[str, str]] = []
    for module, boundary in catalog["physical_boundaries"].items():
        mode = modes[module]
        if mode == PLACEHOLDER_MODE:
            blackboxes.append(module)
            relative = str(boundary["liberty"])
            path = repo_path(relative, root=root)
            if not path.is_file():
                raise RegistryError(
                    f"mapped projection liberty is missing: {relative}"
                )
            libraries.append({"path": relative, "sha256": sha256_file(path)})
        elif mode == INLINE_MODE:
            inline_modules.append(module)
        else:
            raise RegistryError(
                f"physical configuration {physical_configuration_id} has invalid "
                f"boundary mode {module}={mode}"
            )
    explicit_inline_modules = configuration.get("inline_modules")
    if explicit_inline_modules is not None:
        if not isinstance(explicit_inline_modules, list):
            raise RegistryError(
                f"physical configuration {physical_configuration_id} inline_modules is invalid"
            )
        inline_modules = list(explicit_inline_modules)
    keep_hierarchy_additions = configuration.get("keep_hierarchy_additions", [])
    if not isinstance(keep_hierarchy_additions, list) or not all(
        isinstance(module, str) and module for module in keep_hierarchy_additions
    ):
        raise RegistryError(
            f"physical configuration {physical_configuration_id} "
            "keep_hierarchy_additions is invalid"
        )
    keep_hierarchy_modules = [
        *contract["keep_hierarchy_modules"],
        *keep_hierarchy_additions,
    ]
    if len(keep_hierarchy_modules) != len(set(keep_hierarchy_modules)):
        raise RegistryError(
            f"physical configuration {physical_configuration_id} "
            "keep-hierarchy merge contains duplicates"
        )
    projection = {
        "physical_configuration_id": physical_configuration_id,
        "comparison_parent": configuration["comparison_parent"],
        "run_parameter_contract": configuration["run_parameter_contract"],
        "mapped_artifact_profile": configuration["mapped_artifact_profile"],
        "boundary_modes": dict(modes),
        "blackbox_modules": blackboxes,
        "inline_modules": inline_modules,
        "keep_hierarchy_additions": list(keep_hierarchy_additions),
        "keep_hierarchy_modules": keep_hierarchy_modules,
        "macro_lib_files": libraries,
        "expected_unknown_macro_instances": dict(
            configuration["expected_unknown_macro_instances"]
        ),
    }
    if physical_configuration_id in {
        BPU_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
    }:
        bpu_lib = catalog["physical_boundaries"]["OooBranchDirectionPredictor"][
            "liberty"
        ]
        if (
            "OooBranchDirectionPredictor" in blackboxes
            or "OooBranchDirectionPredictor" not in inline_modules
            or any(row["path"] == bpu_lib for row in libraries)
        ):
            raise RegistryError(
                "BPU-inline projection retained the BPU blackbox or Liberty"
            )
    if physical_configuration_id in {
        FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION,
        FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION,
    }:
        fp_lib = catalog["physical_boundaries"]["OooFpArithGate"]["liberty"]
        if (
            "OooFpArithGate" in blackboxes
            or "OooFpArithGate" not in inline_modules
            or any(row["path"] == fp_lib for row in libraries)
        ):
            raise RegistryError(
                "FP-arith inline projection retained the FP wrapper blackbox or Liberty"
            )
    if physical_configuration_id in {
        BPU_LOCAL_PHT_BANKED_CHILD_INLINE_CONFIGURATION,
        BPU_LOCAL_PHT_WRITE_BANKED_FLAT_READ_VIEW_INLINE_CONFIGURATION,
    }:
        if inline_modules != EXPECTED_BANKED_CHILD_INLINE_MODULES:
            raise RegistryError(
                f"physical configuration {physical_configuration_id} inline projection drifted"
            )
        if (
            keep_hierarchy_additions
            != EXPECTED_BANKED_CHILD_KEEP_HIERARCHY_ADDITIONS
        ):
            raise RegistryError(
                f"physical configuration {physical_configuration_id} "
                "keep-hierarchy projection drifted"
            )
        projection.update(
            {
                "archive_class": configuration["archive_class"],
                "canonical": configuration["canonical"],
                "champion": configuration["champion"],
            }
        )
    elif physical_configuration_id == FP_ARITH_PRODUCTION_CHILDREN_INLINE_CONFIGURATION:
        if inline_modules != EXPECTED_FP_ARITH_INLINE_MODULES:
            raise RegistryError(
                "FP-arith production-child inline projection drifted"
            )
        if keep_hierarchy_additions != EXPECTED_FP_ARITH_KEEP_HIERARCHY_ADDITIONS:
            raise RegistryError(
                "FP-arith production-child keep-hierarchy projection drifted"
            )
        projection.update(
            {
                "archive_class": configuration["archive_class"],
                "source_lifecycle": configuration["source_lifecycle"],
                "measurement_status": configuration["measurement_status"],
                "physical_status": configuration["physical_status"],
                "canonical": configuration["canonical"],
                "champion": configuration["champion"],
            }
        )
    elif physical_configuration_id == FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION:
        known_ooc_macro_modules = configuration["known_ooc_macro_modules"]
        if inline_modules != EXPECTED_FP_OOC_INLINE_MODULES:
            raise RegistryError("FP OOC composite inline projection drifted")
        if known_ooc_macro_modules != EXPECTED_FP_OOC_MACRO_MODULES:
            raise RegistryError("FP OOC composite macro projection drifted")
        if keep_hierarchy_additions != EXPECTED_FP_OOC_KEEP_HIERARCHY_ADDITIONS:
            raise RegistryError("FP OOC composite keep-hierarchy projection drifted")
        top_blackbox_modules = [*blackboxes, *known_ooc_macro_modules]
        if len(top_blackbox_modules) != len(set(top_blackbox_modules)):
            raise RegistryError("FP OOC composite top blackbox projection overlaps")
        projection.update(
            {
                "abstraction_kind": configuration["abstraction_kind"],
                "implementation_classes": configuration["implementation_classes"],
                "known_ooc_macro_modules": known_ooc_macro_modules,
                "top_blackbox_modules": top_blackbox_modules,
                "expected_known_ooc_macro_instances": configuration[
                    "expected_known_ooc_macro_instances"
                ],
                "ooc_model_contract": configuration["ooc_model_contract"],
                "child_contracts": configuration["child_contracts"],
                "archive_class": configuration["archive_class"],
                "source_lifecycle": configuration["source_lifecycle"],
                "measurement_status": configuration["measurement_status"],
                "physical_status": configuration["physical_status"],
                "canonical": configuration["canonical"],
                "champion": configuration["champion"],
            }
        )
    return projection


def run_parameter_values(
    catalog: dict[str, Any],
    physical_configuration_id: str,
    *,
    expected_rtl_design_id: str,
    result_root: str,
    root: Path = REPO_ROOT,
) -> dict[str, str]:
    """Build the exact parameter artifact consumed by the mapped runner."""

    contract = catalog.get("run_parameter_contract")
    if contract != EXPECTED_RUN_PARAMETER_CONTRACT:
        raise RegistryError("run parameter contract is invalid")
    require_expected_rtl_design_id(
        catalog,
        expected=expected_rtl_design_id,
        actual=expected_rtl_design_id,
    )
    projection = mapped_projection(
        catalog, physical_configuration_id, root=root
    )
    resolved_result_root = Path(result_root)
    if not resolved_result_root.is_absolute():
        raise RegistryError("mapped result_root must be absolute")
    resolved_result_root = resolved_result_root.resolve(strict=False)
    runtime_root = (root / ".github/runtime-artifacts").resolve(strict=False)
    try:
        resolved_result_root.relative_to(runtime_root)
    except ValueError as exc:
        raise RegistryError(
            "mapped result_root must remain below .github/runtime-artifacts"
        ) from exc
    synthesis = contract["synthesis"]
    sta = contract["sta"]
    macro_paths = [
        (root / row["path"]).resolve().as_posix()
        for row in projection["macro_lib_files"]
    ]
    values = {
        "mode": str(contract["mode"]),
        "diagnostic": str(contract["diagnostic"]),
        "run_parameter_contract": str(contract["id"]),
        # 固定 run-start 的 policy/config/projection；长跑期间若 catalog
        # 策略漂移，末端 stamp 会用当前投影拒绝这份参数 artifact。
        "architecture_policy_sha256": architecture_policy_sha256(catalog),
        "physical_configuration": physical_configuration_id,
        "mapped_artifact_profile": str(projection["mapped_artifact_profile"]),
        "physical_configuration_sha256": physical_configuration_sha256(
            physical_configuration_id,
            selected_physical_configuration(catalog, physical_configuration_id),
        ),
        "mapped_projection_sha256": canonical_sha256(projection),
        "expected_rtl_design_id": expected_rtl_design_id,
        "design": str(contract["design"]),
        "period_ns": f"{float(contract['period_ns']):.1f}",
        "clock_port": str(contract["clock_port"]),
        "clock_name": str(contract["clock_name"]),
        "defines": " ".join(str(item) for item in contract["defines"]),
        "result_root": resolved_result_root.as_posix(),
        "synth_flatten": str(synthesis["flatten"]),
        "synth_share": str(synthesis["share"]),
        "synth_stop_after_coarse": str(synthesis["stop_after_coarse"]),
        "synth_public_autoname": str(synthesis["public_autoname"]),
        "synth_dff_autoname": str(synthesis["dff_autoname"]),
        "sta_flatten_export": str(synthesis["sta_flatten_export"]),
        "stage_scc": str(sta["stage_scc"]),
        "blackbox_modules": " ".join(projection["blackbox_modules"]),
        "inline_modules": " ".join(projection["inline_modules"]),
        "keep_hierarchy_modules": " ".join(projection["keep_hierarchy_modules"]),
        "sdc_file": repo_path(contract["sdc_file"], root=root).as_posix(),
        "opensta": str(contract["opensta_binary"]),
        "std_lib": repo_path(contract["standard_cell_lib"], root=root).as_posix(),
        "macro_libs": ":".join(macro_paths),
    }
    if physical_configuration_id == FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION:
        values.update(
            {
                "known_ooc_macro_modules": " ".join(
                    projection["known_ooc_macro_modules"]
                ),
                "top_blackbox_modules": " ".join(
                    projection["top_blackbox_modules"]
                ),
                "ooc_abstraction_kind": str(projection["abstraction_kind"]),
                "ooc_model_contract_sha256": canonical_sha256(
                    projection["ooc_model_contract"]
                ),
                "ooc_child_contracts_sha256": canonical_sha256(
                    projection["child_contracts"]
                ),
            }
        )
    return values


def render_run_parameters(
    catalog: dict[str, Any],
    physical_configuration_id: str,
    *,
    expected_rtl_design_id: str,
    result_root: str,
    root: Path = REPO_ROOT,
) -> str:
    values = run_parameter_values(
        catalog,
        physical_configuration_id,
        expected_rtl_design_id=expected_rtl_design_id,
        result_root=result_root,
        root=root,
    )
    return "".join(f"{key}={value}\n" for key, value in values.items())


def parse_run_parameters(path: Path) -> tuple[dict[str, str], list[str]]:
    errors: list[str] = []
    values: dict[str, str] = {}
    if not path.is_file():
        return {}, [f"mapped parameters artifact is missing: {path}"]
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return {}, [f"cannot read mapped parameters artifact {path}: {exc}"]
    for line_number, line in enumerate(lines, start=1):
        match = re.fullmatch(r"([a-z][a-z0-9_]*)=(.*)", line)
        if match is None:
            errors.append(f"parameters line {line_number} is non-canonical")
            continue
        key, value = match.groups()
        if key in values:
            errors.append(f"parameters duplicate key: {key}")
            continue
        values[key] = value
    if not values:
        errors.append("mapped parameters artifact is empty")
    return values, errors


def run_parameter_artifact_errors(
    catalog: dict[str, Any],
    physical_configuration_id: str,
    *,
    expected_rtl_design_id: str,
    parameters_path: Path,
    root: Path = REPO_ROOT,
) -> list[str]:
    values, errors = parse_run_parameters(parameters_path)
    result_root = values.get("result_root", "")
    try:
        expected = run_parameter_values(
            catalog,
            physical_configuration_id,
            expected_rtl_design_id=expected_rtl_design_id,
            result_root=result_root,
            root=root,
        )
    except RegistryError as exc:
        errors.append(str(exc))
        return errors
    if set(values) != set(expected):
        errors.append(
            "mapped parameter key set drifted: "
            f"missing={sorted(set(expected) - set(values))} "
            f"extra={sorted(set(values) - set(expected))}"
        )
    for key in sorted(set(values) & set(expected)):
        if values[key] != expected[key]:
            errors.append(f"mapped parameter {key} drifted from run contract")
    return errors


def sta_input_manifest_errors(
    catalog: dict[str, Any],
    physical_configuration_id: str,
    *,
    manifest_path: Path,
    source_manifest_path: Path,
    parameters_path: Path,
    root: Path = REPO_ROOT,
) -> list[str]:
    """Check retained STA inputs named by the manifest; netlist may be deleted."""

    if not manifest_path.is_file():
        return [f"STA input manifest is missing: {manifest_path}"]
    records: dict[str, str] = {}
    errors: list[str] = []
    try:
        lines = manifest_path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return [f"cannot read STA input manifest {manifest_path}: {exc}"]
    for line_number, line in enumerate(lines, start=1):
        match = re.fullmatch(r"([0-9a-f]{64})  (/.+)", line)
        if match is None:
            errors.append(f"STA input manifest line {line_number} is non-canonical")
            continue
        digest, filename = match.groups()
        if filename in records:
            errors.append(f"STA input manifest duplicates input: {filename}")
            continue
        records[filename] = digest
    projection = mapped_projection(
        catalog, physical_configuration_id, root=root
    )
    contract = catalog["run_parameter_contract"]
    required_paths = [
        source_manifest_path.resolve(),
        parameters_path.resolve(),
        repo_path(contract["standard_cell_lib"], root=root),
        repo_path(contract["sdc_file"], root=root),
        *(repo_path(row["path"], root=root) for row in projection["macro_lib_files"]),
        Path(contract["opensta_binary"]).resolve(),
    ]
    for required_path in required_paths:
        filename = required_path.as_posix()
        if filename not in records:
            errors.append(f"STA input manifest lacks required input: {filename}")
            continue
        if not required_path.is_file():
            errors.append(f"STA retained input is missing: {filename}")
            continue
        actual = sha256_file(required_path)
        if records[filename] != actual:
            errors.append(f"STA input manifest hash drifted: {filename}")
    return errors


def projection_argument_errors(
    projection: dict[str, Any],
    *,
    mapped_artifact_profile: str,
    blackbox_modules: list[str],
    inline_modules: list[str],
    macro_lib_files: list[str],
) -> list[str]:
    errors: list[str] = []
    expected_modules = projection.get("blackbox_modules", [])
    expected_inline = projection.get("inline_modules", [])
    expected_libs = [
        row.get("path")
        for row in projection.get("macro_lib_files", [])
        if isinstance(row, dict)
    ]
    if mapped_artifact_profile != projection.get("mapped_artifact_profile"):
        errors.append("runner mapped artifact profile drifted from catalog projection")
    if blackbox_modules != expected_modules:
        errors.append("runner blackbox arguments drifted from catalog projection")
    if inline_modules != expected_inline:
        errors.append("runner inline arguments drifted from catalog projection")
    if macro_lib_files != expected_libs:
        errors.append("runner liberty arguments drifted from catalog projection")
    return errors


def workspace_receipt_errors(
    receipt: Any,
    *,
    label: str,
    root: Path,
    expected_path: Path | None = None,
) -> tuple[str | None, list[str], Path | None]:
    """Recompute one retained workspace artifact receipt."""

    errors: list[str] = []
    required = {"path", "path_scope", "sha256", "size_bytes"}
    if not isinstance(receipt, dict) or set(receipt) != required:
        return None, [f"{label} receipt has an invalid key set"], None
    relative = receipt.get("path")
    if receipt.get("path_scope") != "workspace_relative" or not isinstance(
        relative, str
    ):
        return None, [f"{label} receipt must be workspace-relative"], None
    try:
        path = repo_path(relative, root=root)
    except RegistryError as exc:
        return None, [f"{label} receipt path is invalid: {exc}"], None
    if expected_path is not None and path != expected_path.resolve():
        errors.append(f"{label} receipt path is detached")
    if not path.is_file():
        errors.append(f"{label} artifact is missing: {relative}")
        return None, errors, path
    actual_sha256 = sha256_file(path)
    if receipt.get("sha256") != actual_sha256:
        errors.append(f"{label} receipt SHA-256 is stale")
    if receipt.get("size_bytes") != path.stat().st_size:
        errors.append(f"{label} receipt size is stale")
    return actual_sha256, errors, path


def mapped_profile_evidence_state(
    summary: dict[str, Any], *, expected_profile: str
) -> tuple[str | None, list[str]]:
    """Validate the profile-selected artifact family embedded by the parser."""

    errors: list[str] = []
    if expected_profile not in MAPPED_ARTIFACT_PROFILES:
        return None, [f"unsupported mapped artifact profile: {expected_profile}"]
    if expected_profile == MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE:
        return None, [
            "FP OOC composite profile requires fp_ooc_composite.py dedicated "
            "child/top/area/timing binding; generic mapped-summary stamping is forbidden"
        ]
    if summary.get("mapped_artifact_profile") != expected_profile:
        errors.append("mapped summary artifact profile differs from projection")
    inputs = summary.get("inputs")
    if not isinstance(inputs, dict) or inputs.get("mapped_artifact_profile") != expected_profile:
        errors.append("mapped summary input profile differs from projection")
    evidence = summary.get("mapped_profile_evidence")
    if not isinstance(evidence, dict):
        return None, errors + ["mapped summary lacks profile evidence"]
    required = {
        MAPPED_ARTIFACT_PROFILE_NONE: {"profile", "artifact_family"},
        MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT: {
            "profile",
            "artifact_family",
            "bpu_negative_slack_inventory",
            "bpu_update_fanout_inventory",
        },
        MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN: {
            "profile",
            "artifact_family",
            "fp_negative_slack_inventory",
            "fp_internal_timing_paths",
            "fp_mapped_hierarchy_inventory",
        },
    }[expected_profile]
    if set(evidence) != required:
        errors.append(
            "mapped profile evidence key set drifted: "
            f"missing={sorted(required - set(evidence))} "
            f"extra={sorted(set(evidence) - required)}"
        )
    if evidence.get("profile") != expected_profile:
        errors.append("mapped profile evidence profile differs from projection")
    expected_family = MAPPED_ARTIFACT_FILENAMES[expected_profile]
    if evidence.get("artifact_family") != expected_family:
        errors.append("mapped profile evidence artifact family drifted")

    artifacts = summary.get("artifacts")
    artifacts = artifacts if isinstance(artifacts, dict) else {}
    optional_keys = {
        "bpu_negative_slack",
        "bpu_update_fanout",
        "fp_negative_slack",
        "fp_internal_paths",
    }
    expected_artifact_keys = {
        MAPPED_ARTIFACT_PROFILE_NONE: set(),
        MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT: {
            "bpu_negative_slack",
            "bpu_update_fanout",
        },
        MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN: {
            "fp_negative_slack",
            "fp_internal_paths",
        },
    }[expected_profile]
    if set(artifacts) & optional_keys != expected_artifact_keys:
        errors.append("mapped summary contains the wrong profile artifact family")

    record_map = {
        MAPPED_ARTIFACT_PROFILE_BPU_LOCAL_PHT: {
            "bpu_negative_slack_inventory": "bpu_negative_slack",
            "bpu_update_fanout_inventory": "bpu_update_fanout",
        },
        MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN: {
            "fp_negative_slack_inventory": "fp_negative_slack",
            "fp_internal_timing_paths": "fp_internal_paths",
        },
    }.get(expected_profile, {})
    for evidence_key, artifact_key in record_map.items():
        record = evidence.get(evidence_key)
        receipt = record.get("artifact") if isinstance(record, dict) else None
        if receipt != artifacts.get(artifact_key):
            errors.append(
                f"mapped profile evidence {evidence_key} artifact receipt is detached"
            )

    if expected_profile == MAPPED_ARTIFACT_PROFILE_FP_ARITH_CHILDREN:
        negative = evidence.get("fp_negative_slack_inventory")
        internal = evidence.get("fp_internal_timing_paths")
        hierarchy = evidence.get("fp_mapped_hierarchy_inventory")
        negative_count = (
            negative.get("negative_slack_pin_count")
            if isinstance(negative, dict)
            else None
        )
        if (
            isinstance(negative_count, bool)
            or not isinstance(negative_count, int)
            or negative_count <= 0
        ):
            errors.append("FP profile lacks a non-empty negative-slack inventory")
        path_count = internal.get("path_count") if isinstance(internal, dict) else None
        if (
            isinstance(path_count, bool)
            or not isinstance(path_count, int)
            or path_count <= 0
        ):
            errors.append("FP profile lacks a real internal timing path")
        synthesis = summary.get("synthesis")
        synth_stat = synthesis.get("synth_stat") if isinstance(synthesis, dict) else None
        if not isinstance(hierarchy, dict) or hierarchy.get("source_artifact") != synth_stat:
            errors.append("FP hierarchy inventory is detached from synth_stat")
        else:
            expected_modules = list(EXPECTED_FP_ARITH_INLINE_MODULES)
            modules = hierarchy.get("modules")
            if (
                hierarchy.get("expected_modules") != expected_modules
                or hierarchy.get("module_count") != len(expected_modules)
                or not isinstance(modules, dict)
                or set(modules) != set(expected_modules)
            ):
                errors.append("FP hierarchy inventory module census drifted")
            else:
                required_module_fields = {
                    "instance_count",
                    "parent_heading",
                    "mapped_cells",
                    "area",
                    "section_mapped_cells",
                    "section_area",
                }
                for module in expected_modules:
                    row = modules[module]
                    expected_parent = (
                        "OooFpBackend"
                        if module == "OooFpArithGate"
                        else "OooFpArithGate"
                    )
                    if not isinstance(row, dict) or set(row) != required_module_fields:
                        errors.append(
                            f"FP hierarchy inventory row shape drifted: {module}"
                        )
                        continue
                    numeric_values = (
                        row.get("area"),
                        row.get("section_area"),
                    )
                    positive_cells = (
                        row.get("mapped_cells"),
                        row.get("section_mapped_cells"),
                    )
                    if (
                        row.get("instance_count") != 1
                        or not isinstance(row.get("parent_heading"), str)
                        or expected_parent not in row["parent_heading"]
                        or any(
                            isinstance(value, bool)
                            or not isinstance(value, int)
                            or value <= 0
                            for value in positive_cells
                        )
                        or any(
                            isinstance(value, bool)
                            or not isinstance(value, (int, float))
                            or not math.isfinite(value)
                            or value <= 0.0
                            for value in numeric_values
                        )
                    ):
                        errors.append(
                            f"FP hierarchy inventory row is not exact/nonzero: {module}"
                        )
            if hierarchy.get("fp_placeholder_unknown_notice_count") != 0:
                errors.append("FP hierarchy inventory retains the placeholder macro")
    return canonical_sha256(evidence), errors


def mapped_evidence_artifact_state(
    summary: dict[str, Any], *, root: Path
) -> tuple[str | None, list[str]]:
    artifacts = summary.get("artifacts")
    if not isinstance(artifacts, dict) or not artifacts:
        return None, ["mapped summary artifacts are missing"]
    synthesis = summary.get("synthesis")
    synthesis = synthesis if isinstance(synthesis, dict) else {}
    synthesis_receipts = {
        name: synthesis.get(name)
        for name in (
            "sta_export_check",
            "sta_netlist_compatibility",
            "synth_check",
            "synth_stat",
        )
    }
    errors: list[str] = []
    for name, receipt in sorted(artifacts.items()):
        _, receipt_errors, _ = workspace_receipt_errors(
            receipt,
            label=f"mapped artifact {name}",
            root=root,
        )
        errors.extend(receipt_errors)
    for name, receipt in sorted(synthesis_receipts.items()):
        _, receipt_errors, _ = workspace_receipt_errors(
            receipt,
            label=f"mapped synthesis artifact {name}",
            root=root,
        )
        errors.extend(receipt_errors)
    return canonical_sha256(
        {"opensta_artifacts": artifacts, "synthesis_artifacts": synthesis_receipts}
    ), errors


def synth_stat_unknown_macro_instances(
    path: Path, *, boundary_modules: set[str]
) -> tuple[dict[str, int], list[str]]:
    """Independently read the final Yosys design-hierarchy macro census."""

    if not path.is_file():
        return {}, [f"mapped synth_stat artifact is missing: {path}"]
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        return {}, [f"cannot read mapped synth_stat artifact {path}: {exc}"]
    marker = "=== design hierarchy ==="
    if marker not in text:
        return {}, ["mapped synth_stat lacks final design hierarchy"]
    final_hierarchy = text.rsplit(marker, 1)[1]
    counts: dict[str, int] = {}
    errors: list[str] = []
    for line in final_hierarchy.splitlines():
        match = re.fullmatch(
            r"\s*([0-9]+)\s+-\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*",
            line,
        )
        if match is None or match.group(2) not in boundary_modules:
            continue
        module = match.group(2)
        if module in counts:
            errors.append(f"mapped synth_stat duplicates macro census: {module}")
            continue
        counts[module] = int(match.group(1))
    return counts, errors


def summary_unknown_macro_instances(summary: dict[str, Any]) -> Any:
    synthesis = summary.get("synthesis")
    area = synthesis.get("area") if isinstance(synthesis, dict) else None
    return area.get("unknown_macro_instances") if isinstance(area, dict) else None


def mapped_binding_errors(
    summary: dict[str, Any],
    *,
    live_design_id: str,
    current_sources: dict[str, str],
    policy_sha256: str,
    physical_configuration_id: str,
    physical_configuration_digest: str,
    projection: dict[str, Any],
    mapped_artifact_profile: str,
    mapped_profile_evidence_sha256: str | None,
    source_manifest_sha256: str | None,
    production_manifest_before_sha256: str | None,
    production_manifest_after_sha256: str | None,
    run_parameter_contract_sha256: str,
    parameters_sha256: str | None,
    sta_input_manifest_sha256: str | None,
    evidence_artifacts_sha256: str | None,
) -> list[str]:
    """Reject self-reported or artifact-detached mapped v2 identities."""

    binding = summary.get("architecture_registry_binding")
    if not isinstance(binding, dict):
        return ["mapped summary lacks architecture_registry_binding"]
    required = {
        "schema",
        "design_id",
        "synthesis_sources_sha256",
        "source_manifest_sha256",
        "production_manifest_before_sha256",
        "production_manifest_after_sha256",
        "architecture_policy_sha256",
        "physical_configuration_id",
        "physical_configuration_sha256",
        "mapped_projection",
        "mapped_projection_sha256",
        "mapped_artifact_profile",
        "mapped_profile_evidence_sha256",
        "run_parameter_contract_sha256",
        "parameters_sha256",
        "sta_input_manifest_sha256",
        "evidence_artifacts_sha256",
    }
    errors: list[str] = []
    if set(binding) != required:
        errors.append(
            "mapped binding key set drifted: "
            f"missing={sorted(required - set(binding))} "
            f"extra={sorted(set(binding) - required)}"
        )
        return errors
    if binding.get("schema") != MAPPED_BINDING_SCHEMA:
        errors.append("mapped binding schema is invalid")
    if summary.get("status") != "PASS":
        errors.append("mapped summary status is not PASS")
    if binding.get("design_id") != live_design_id:
        errors.append("mapped binding design_id is stale")
    actual_sources = summary.get("actual_synthesis_source_sha256")
    if actual_sources != current_sources:
        errors.append("mapped summary synthesis source set is stale")
    expected_source_digest = canonical_sha256(current_sources)
    if binding.get("synthesis_sources_sha256") != expected_source_digest:
        errors.append("mapped binding synthesis_sources_sha256 is invalid")
    if binding.get("source_manifest_sha256") != source_manifest_sha256:
        errors.append("mapped binding source manifest hash is detached")
    if (
        binding.get("production_manifest_before_sha256")
        != production_manifest_before_sha256
        or binding.get("production_manifest_after_sha256")
        != production_manifest_after_sha256
        or production_manifest_before_sha256 is None
        or production_manifest_before_sha256 != production_manifest_after_sha256
    ):
        errors.append("mapped binding production manifests are missing or drifted")
    if binding.get("architecture_policy_sha256") != policy_sha256:
        errors.append("mapped binding architecture policy is stale")
    if binding.get("physical_configuration_id") != physical_configuration_id:
        errors.append("mapped binding physical configuration ID is stale")
    if (
        binding.get("physical_configuration_sha256")
        != physical_configuration_digest
    ):
        errors.append("mapped binding physical configuration hash is invalid")
    projection_sha256 = canonical_sha256(projection)
    if binding.get("mapped_projection") != projection:
        errors.append("mapped binding blackbox/inline/Liberty projection differs")
    if binding.get("mapped_projection_sha256") != projection_sha256:
        errors.append("mapped binding projection hash is invalid")
    if (
        binding.get("mapped_artifact_profile") != mapped_artifact_profile
        or mapped_artifact_profile != projection.get("mapped_artifact_profile")
    ):
        errors.append("mapped binding artifact profile differs from projection")
    if (
        binding.get("mapped_profile_evidence_sha256")
        != mapped_profile_evidence_sha256
        or mapped_profile_evidence_sha256 is None
    ):
        errors.append("mapped binding profile evidence hash is detached")
    if (
        binding.get("run_parameter_contract_sha256")
        != run_parameter_contract_sha256
    ):
        errors.append("mapped binding run parameter contract hash is invalid")
    if binding.get("parameters_sha256") != parameters_sha256:
        errors.append("mapped binding parameters artifact hash is detached")
    if binding.get("sta_input_manifest_sha256") != sta_input_manifest_sha256:
        errors.append("mapped binding STA input manifest hash is detached")
    if binding.get("evidence_artifacts_sha256") != evidence_artifacts_sha256:
        errors.append("mapped binding evidence artifact hash is detached")
    if (
        summary_unknown_macro_instances(summary)
        != projection["expected_unknown_macro_instances"]
    ):
        errors.append("mapped summary unknown macro census differs from projection")
    return errors


def load_mapped_evidence(
    catalog: dict[str, Any],
    *,
    root: Path,
    live_design_id: str,
    source_records: list[dict[str, str]],
) -> dict[str, Any]:
    """Derive mapped identity from sealed evidence; never trust catalog labels."""

    relative = catalog["evidence"]["mapped_summary"]
    path = repo_path(relative, root=root)
    if not path.is_file():
        return {
            "status": "GAP_MISSING",
            "design_id": None,
            "source_set_id": None,
            "summary": relative,
            "summary_sha256": None,
            "binding_errors": ["mapped summary is missing"],
        }
    try:
        summary = load_json(path)
    except RegistryError as exc:
        return {
            "status": "GAP_INVALID_SUMMARY",
            "design_id": None,
            "source_set_id": None,
            "summary": relative,
            "summary_sha256": sha256_file(path),
            "binding_errors": [str(exc)],
        }
    actual_sources = summary.get("actual_synthesis_source_sha256")
    source_set_id = (
        f"sha256:{canonical_sha256(actual_sources)}"
        if isinstance(actual_sources, dict)
        else None
    )
    current_sources = {row["path"]: row["sha256"] for row in source_records}
    binding = summary.get("architecture_registry_binding")
    if not isinstance(binding, dict):
        return {
            "status": (
                "GAP_STALE_SOURCES_UNBOUND"
                if actual_sources != current_sources
                else "GAP_UNBOUND_IDENTITY"
            ),
            "design_id": None,
            "source_set_id": source_set_id,
            "summary": relative,
            "summary_sha256": sha256_file(path),
            "binding_errors": ["mapped summary lacks architecture_registry_binding"],
        }
    physical_configuration_id = binding.get("physical_configuration_id")
    try:
        configuration = selected_physical_configuration(
            catalog, physical_configuration_id
        )
        projection = mapped_projection(
            catalog, physical_configuration_id, root=root
        )
    except RegistryError as exc:
        return {
            "status": "GAP_INVALID_BINDING",
            "design_id": binding.get("design_id"),
            "source_set_id": source_set_id,
            "summary": relative,
            "summary_sha256": sha256_file(path),
            "physical_configuration_id": physical_configuration_id,
            "boundary_modes": {},
            "binding_errors": [str(exc)],
        }
    source_manifest_sha, source_manifest_errors, source_manifest_path = workspace_receipt_errors(
        summary.get("source_manifest"),
        label="mapped source manifest",
        root=root,
    )
    inputs = summary.get("inputs")
    inputs = inputs if isinstance(inputs, dict) else {}
    parameters_sha, parameters_receipt_errors, parameters_path = (
        workspace_receipt_errors(
            inputs.get("parameters"),
            label="mapped parameters",
            root=root,
        )
    )
    sta_manifest_sha, sta_manifest_errors, sta_manifest_path = workspace_receipt_errors(
        inputs.get("manifest"),
        label="mapped STA input manifest",
        root=root,
    )
    parameter_errors: list[str] = []
    if parameters_path is not None and parameters_path.is_file():
        parameter_errors = run_parameter_artifact_errors(
            catalog,
            physical_configuration_id,
            expected_rtl_design_id=binding.get("design_id", ""),
            parameters_path=parameters_path,
            root=root,
        )
    sta_semantic_errors: list[str] = []
    if (
        sta_manifest_path is not None
        and source_manifest_path is not None
        and parameters_path is not None
        and sta_manifest_path.is_file()
        and source_manifest_path.is_file()
        and parameters_path.is_file()
    ):
        sta_semantic_errors = sta_input_manifest_errors(
            catalog,
            physical_configuration_id,
            manifest_path=sta_manifest_path,
            source_manifest_path=source_manifest_path,
            parameters_path=parameters_path,
            root=root,
        )
    evidence_artifacts_sha, evidence_artifact_errors = (
        mapped_evidence_artifact_state(summary, root=root)
    )
    profile_evidence_sha, profile_evidence_errors = mapped_profile_evidence_state(
        summary,
        expected_profile=projection["mapped_artifact_profile"],
    )
    synthesis = summary.get("synthesis")
    synthesis = synthesis if isinstance(synthesis, dict) else {}
    _, synth_stat_receipt_errors, synth_stat_path = workspace_receipt_errors(
        synthesis.get("synth_stat"),
        label="mapped synthesis artifact synth_stat",
        root=root,
    )
    raw_macro_census: dict[str, int] = {}
    raw_census_errors: list[str] = []
    if synth_stat_path is not None:
        raw_macro_census, raw_census_errors = synth_stat_unknown_macro_instances(
            synth_stat_path,
            boundary_modules=set(catalog["physical_boundaries"]),
        )
    before = path.parent / "production-manifest-before.sha256"
    after = path.parent / "production-manifest-after.sha256"
    before_verification = verify_sha256_manifest(before)
    before_sha = before_verification["manifest_sha256"]
    after_sha = sha256_file(after) if after.is_file() else None
    binding_errors = mapped_binding_errors(
        summary,
        live_design_id=live_design_id,
        current_sources=current_sources,
        policy_sha256=architecture_policy_sha256(catalog),
        physical_configuration_id=physical_configuration_id,
        physical_configuration_digest=physical_configuration_sha256(
            physical_configuration_id, configuration
        ),
        projection=projection,
        mapped_artifact_profile=projection["mapped_artifact_profile"],
        mapped_profile_evidence_sha256=profile_evidence_sha,
        source_manifest_sha256=source_manifest_sha,
        production_manifest_before_sha256=before_sha,
        production_manifest_after_sha256=after_sha,
        run_parameter_contract_sha256=canonical_sha256(
            catalog["run_parameter_contract"]
        ),
        parameters_sha256=parameters_sha,
        sta_input_manifest_sha256=sta_manifest_sha,
        evidence_artifacts_sha256=evidence_artifacts_sha,
    )
    binding_errors.extend(source_manifest_errors)
    binding_errors.extend(parameters_receipt_errors)
    binding_errors.extend(sta_manifest_errors)
    binding_errors.extend(parameter_errors)
    binding_errors.extend(sta_semantic_errors)
    binding_errors.extend(evidence_artifact_errors)
    binding_errors.extend(profile_evidence_errors)
    binding_errors.extend(synth_stat_receipt_errors)
    binding_errors.extend(raw_census_errors)
    if raw_macro_census != projection["expected_unknown_macro_instances"]:
        binding_errors.append(
            "mapped raw synth_stat macro census differs from physical configuration"
        )
    binding_errors.extend(before_verification["errors"])
    if after_sha is None:
        binding_errors.append(f"production manifest is missing: {after}")
    if not binding_errors:
        status = "PASS"
    elif actual_sources != current_sources or binding.get("design_id") != live_design_id:
        status = "GAP_STALE_DESIGN"
    elif any(
        "policy" in error
        or "configuration" in error
        or "projection" in error
        for error in binding_errors
    ):
        status = "GAP_STALE_PROJECTION"
    elif any("production input" in error for error in binding_errors):
        status = "GAP_STALE_PRODUCTION_INPUTS"
    else:
        status = "GAP_INVALID_BINDING"
    return {
        "status": status,
        "design_id": binding.get("design_id"),
        "source_set_id": source_set_id,
        "summary": relative,
        "summary_sha256": sha256_file(path),
        "physical_configuration_id": physical_configuration_id,
        "boundary_modes": projection["boundary_modes"],
        "binding_errors": binding_errors,
    }


def stamp_mapped_summary(
    catalog: dict[str, Any],
    *,
    physical_configuration_id: str,
    expected_rtl_design_id: str,
    summary_path: Path,
    source_manifest_path: Path,
    parameters_path: Path,
    sta_input_manifest_path: Path,
    synth_stat_path: Path,
    production_manifest_before: Path,
    production_manifest_after: Path,
    mapped_artifact_profile: str,
    blackbox_modules: list[str],
    inline_modules: list[str],
    macro_lib_files: list[str],
    root: Path = REPO_ROOT,
) -> dict[str, Any]:
    """Seal a newly generated mapped summary to exact architecture inputs."""

    root = root.resolve()
    resolved_inputs = [
        summary_path.resolve(),
        source_manifest_path.resolve(),
        parameters_path.resolve(),
        sta_input_manifest_path.resolve(),
        synth_stat_path.resolve(),
        production_manifest_before.resolve(),
        production_manifest_after.resolve(),
    ]
    for path in resolved_inputs:
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise RegistryError(f"mapped binding path escapes repository: {path}") from exc
        if not path.is_file():
            raise RegistryError(f"mapped binding input is missing: {path}")
    configuration = selected_physical_configuration(
        catalog, physical_configuration_id
    )
    design_digest, _ = design_binding(root, catalog["scope"]["source_root"])
    live_design_id = f"sha256:{design_digest}"
    require_expected_rtl_design_id(
        catalog,
        expected=expected_rtl_design_id,
        actual=live_design_id,
    )
    summary = load_json(summary_path)
    if summary.get("status") != "PASS":
        raise RegistryError("mapped summary status must be PASS before binding")
    current_sources = {
        path.relative_to(root).as_posix(): sha256_file(path)
        for path in synth_sources(root)
    }
    if summary.get("actual_synthesis_source_sha256") != current_sources:
        raise RegistryError("mapped summary source map does not match current synthesis inputs")
    source_manifest_sha, source_receipt_errors, _ = workspace_receipt_errors(
        summary.get("source_manifest"),
        label="mapped source manifest",
        root=root,
        expected_path=source_manifest_path,
    )
    if source_receipt_errors or source_manifest_sha is None:
        raise RegistryError(
            "mapped summary source manifest receipt is detached: "
            + "; ".join(source_receipt_errors)
        )
    inputs = summary.get("inputs")
    if not isinstance(inputs, dict):
        raise RegistryError("mapped summary inputs are missing")
    parameters_sha, parameters_receipt_errors, _ = workspace_receipt_errors(
        inputs.get("parameters"),
        label="mapped parameters",
        root=root,
        expected_path=parameters_path,
    )
    sta_input_manifest_sha, sta_manifest_receipt_errors, _ = (
        workspace_receipt_errors(
            inputs.get("manifest"),
            label="mapped STA input manifest",
            root=root,
            expected_path=sta_input_manifest_path,
        )
    )
    parameter_errors = run_parameter_artifact_errors(
        catalog,
        physical_configuration_id,
        expected_rtl_design_id=expected_rtl_design_id,
        parameters_path=parameters_path,
        root=root,
    )
    sta_semantic_errors = sta_input_manifest_errors(
        catalog,
        physical_configuration_id,
        manifest_path=sta_input_manifest_path,
        source_manifest_path=source_manifest_path,
        parameters_path=parameters_path,
        root=root,
    )
    artifact_sha256, artifact_errors = mapped_evidence_artifact_state(
        summary, root=root
    )
    synthesis = summary.get("synthesis")
    synthesis = synthesis if isinstance(synthesis, dict) else {}
    _, synth_stat_receipt_errors, _ = workspace_receipt_errors(
        synthesis.get("synth_stat"),
        label="mapped synthesis artifact synth_stat",
        root=root,
        expected_path=synth_stat_path,
    )
    raw_macro_census, raw_census_errors = synth_stat_unknown_macro_instances(
        synth_stat_path,
        boundary_modules=set(catalog["physical_boundaries"]),
    )
    receipt_errors = (
        parameters_receipt_errors
        + sta_manifest_receipt_errors
        + parameter_errors
        + sta_semantic_errors
        + artifact_errors
        + synth_stat_receipt_errors
        + raw_census_errors
    )
    if receipt_errors:
        raise RegistryError(
            "mapped parameter/artifact receipts are invalid: "
            + "; ".join(receipt_errors)
        )
    contract = catalog["run_parameter_contract"]
    if summary.get("mode") != contract["mode"]:
        raise RegistryError("mapped summary mode differs from run parameter contract")
    if summary.get("period_ns") != contract["period_ns"]:
        raise RegistryError("mapped summary period differs from run parameter contract")
    before_verification = verify_sha256_manifest(production_manifest_before)
    manifest_errors = before_verification["errors"]
    if manifest_errors:
        raise RegistryError("production manifest inputs are stale: " + "; ".join(manifest_errors))
    before_sha = before_verification["manifest_sha256"]
    after_sha = sha256_file(production_manifest_after)
    if before_sha != after_sha:
        raise RegistryError("production manifest changed during mapped run")
    projection = mapped_projection(
        catalog, physical_configuration_id, root=root
    )
    profile_evidence_sha256, profile_evidence_errors = mapped_profile_evidence_state(
        summary,
        expected_profile=projection["mapped_artifact_profile"],
    )
    argument_errors = projection_argument_errors(
        projection,
        mapped_artifact_profile=mapped_artifact_profile,
        blackbox_modules=blackbox_modules,
        inline_modules=inline_modules,
        macro_lib_files=macro_lib_files,
    )
    if argument_errors or profile_evidence_errors or profile_evidence_sha256 is None:
        raise RegistryError(
            "; ".join(argument_errors + profile_evidence_errors)
            or "mapped profile evidence is missing"
        )
    if (
        summary_unknown_macro_instances(summary)
        != projection["expected_unknown_macro_instances"]
    ):
        raise RegistryError(
            "mapped summary unknown macro census differs from physical configuration"
        )
    if raw_macro_census != projection["expected_unknown_macro_instances"]:
        raise RegistryError(
            "mapped raw synth_stat macro census differs from physical configuration"
        )
    binding = {
        "schema": MAPPED_BINDING_SCHEMA,
        "design_id": live_design_id,
        "synthesis_sources_sha256": canonical_sha256(current_sources),
        "source_manifest_sha256": source_manifest_sha,
        "production_manifest_before_sha256": before_sha,
        "production_manifest_after_sha256": after_sha,
        "architecture_policy_sha256": architecture_policy_sha256(catalog),
        "physical_configuration_id": physical_configuration_id,
        "physical_configuration_sha256": physical_configuration_sha256(
            physical_configuration_id, configuration
        ),
        "mapped_projection": projection,
        "mapped_projection_sha256": canonical_sha256(projection),
        "mapped_artifact_profile": mapped_artifact_profile,
        "mapped_profile_evidence_sha256": profile_evidence_sha256,
        "run_parameter_contract_sha256": canonical_sha256(contract),
        "parameters_sha256": parameters_sha,
        "sta_input_manifest_sha256": sta_input_manifest_sha,
        "evidence_artifacts_sha256": artifact_sha256,
    }
    summary["architecture_registry_binding"] = binding
    payload = json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        dir=summary_path.parent,
        prefix=f".{summary_path.name}.",
        delete=False,
    ) as handle:
        handle.write(payload)
        temporary = Path(handle.name)
    temporary.replace(summary_path)
    return binding


def build_snapshot(
    catalog: dict[str, Any],
    *,
    root: Path = REPO_ROOT,
) -> dict[str, Any]:
    errors = validate_catalog(catalog, root=root)
    scope = catalog["scope"]
    source_root = scope["source_root"]
    base = root / source_root
    inventory_paths = sorted(
        path
        for path in base.rglob("*")
        if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES
    )
    if not inventory_paths:
        errors.append("source inventory is empty")
    inventory_relative_paths = [
        path.relative_to(root).as_posix() for path in inventory_paths
    ]
    inventory_path_sha256 = canonical_sha256(inventory_relative_paths)
    errors.extend(inventory_review_errors(catalog, inventory_relative_paths))
    lists = make_filelists(root)
    mapped_runner_path = root / "npc/rv64/eval/ppa/run-traceable-mapped-current.sh"
    mapped_sta_tcl_path = root / "npc/rv64/eval/ppa/opensta-traceable-mapped-current.tcl"
    mapped_sta_parser_path = root / "npc/rv64/eval/ppa/tools/traceable_mapped_sta.py"
    fp_ooc_paths = {
        "runner": root / "npc/rv64/eval/ppa/run-fp-ooc-composite-current.sh",
        "child_yosys": root / "npc/rv64/eval/ppa/yosys-fp-ooc-child.tcl",
        "child_sta": root / "npc/rv64/eval/ppa/opensta-fp-ooc-child.tcl",
        "top_sta": root / "npc/rv64/eval/ppa/opensta-fp-ooc-top.tcl",
        "parser": root / "npc/rv64/eval/ppa/tools/fp_ooc_composite.py",
        "schema": root / "npc/rv64/eval/ppa/schemas/fp-ooc-composite-v1.schema.json",
    }
    if not mapped_runner_path.is_file():
        errors.append("mapped runner is missing")
    else:
        errors.extend(
            mapped_runner_contract_errors(
                mapped_runner_path.read_text(encoding="utf-8", errors="replace")
            )
        )
    if not mapped_sta_tcl_path.is_file() or not mapped_sta_parser_path.is_file():
        errors.append("production-owned mapped STA Tcl/parser is missing")
    else:
        errors.extend(
            mapped_sta_tool_contract_errors(
                mapped_sta_tcl_path.read_text(encoding="utf-8", errors="replace"),
                mapped_sta_parser_path.read_text(encoding="utf-8", errors="replace"),
            )
        )
    missing_fp_ooc = [label for label, path in fp_ooc_paths.items() if not path.is_file()]
    if missing_fp_ooc:
        errors.append(f"FP OOC composite tooling is missing: {sorted(missing_fp_ooc)}")
    else:
        errors.extend(
            fp_ooc_composite_tool_contract_errors(
                fp_ooc_paths["runner"].read_text(encoding="utf-8", errors="replace"),
                fp_ooc_paths["child_yosys"].read_text(encoding="utf-8", errors="replace"),
                fp_ooc_paths["child_sta"].read_text(encoding="utf-8", errors="replace"),
                fp_ooc_paths["top_sta"].read_text(encoding="utf-8", errors="replace"),
                fp_ooc_paths["parser"].read_text(encoding="utf-8", errors="replace"),
                fp_ooc_paths["schema"].read_text(encoding="utf-8", errors="replace"),
            )
        )
    head, tracked, git_states, deleted = git_state(root, source_root)
    for path in deleted:
        if Path(path).suffix.lower() in SOURCE_SUFFIXES:
            errors.append(f"deleted RTL lacks explicit retired catalog state: {path}")
    design_digest, design_files = design_binding(root, source_root)
    live_design_id = f"sha256:{design_digest}"
    bpu_physical_experiment_state = catalog.get("bpu_physical_experiment_state", {})
    if (
        not isinstance(bpu_physical_experiment_state, dict)
        or bpu_physical_experiment_state.get("live_rtl_design_id") != live_design_id
    ):
        errors.append(
            "bpu_physical_experiment_state.live_rtl_design_id does not match the "
            "derived live RTL design identity"
        )
    source_records = [
        {
            "path": path.relative_to(root).as_posix(),
            "sha256": sha256_file(path),
        }
        for path in synth_sources(root)
    ]
    source_manifest_sha256 = canonical_sha256(source_records)
    elaboration_status, elaboration, elaboration_sha = load_elaboration(
        catalog,
        root=root,
        design_id=live_design_id,
        source_manifest_sha256=source_manifest_sha256,
    )
    reachable_modules = set(
        elaboration.get("reachable_modules", [])
        if elaboration_status == "PASS" and isinstance(elaboration, dict)
        else []
    )
    instance_paths_by_module: dict[str, list[str]] = defaultdict(list)
    if elaboration_status == "PASS" and isinstance(elaboration, dict):
        for instance in elaboration.get("instances", []):
            if not isinstance(instance, dict):
                continue
            module = instance.get("module")
            path = instance.get("path")
            if isinstance(module, str) and isinstance(path, str):
                instance_paths_by_module[module].append(path)
    module_to_paths: dict[str, list[str]] = defaultdict(list)
    raw_files: list[dict[str, Any]] = []
    capability_files = {
        name: set(value.get("files", []))
        for name, value in catalog.get("capabilities", {}).items()
    }
    for path in inventory_paths:
        relative = path.relative_to(root).as_posix()
        modules = module_names(path)
        for module in modules:
            module_to_paths[module].append(relative)
        owner = owner_for(relative, catalog, errors)
        role = role_for(relative, lists, catalog)
        if role == "unclassified":
            errors.append(f"unclassified RTL source: {relative}")
        lifecycle = git_states.get(
            relative,
            "committed" if relative in tracked else "development",
        )
        errors.extend(
            file_registration_errors(
                relative,
                role=role,
                lifecycle=lifecycle,
                lists=lists,
                catalog=catalog,
            )
        )
        raw_files.append(
            {
                "path": relative,
                "sha256": sha256_file(path),
                "owner": owner,
                "role": role,
                "lifecycle": lifecycle,
                "modules": modules,
                "capabilities": sorted(
                    name for name, paths in capability_files.items() if relative in paths
                ),
            }
        )
    for module, paths in sorted(module_to_paths.items()):
        if len(paths) > 1:
            errors.append(f"duplicate module definition {module}: {paths}")
    inventory_set = {row["path"] for row in raw_files}
    for path in sorted((catalog.get("file_overrides") or {})):
        if path not in inventory_set:
            errors.append(f"stale file override: {path}")
    for capability, paths in capability_files.items():
        for path in sorted(paths - inventory_set):
            errors.append(f"capability {capability} references missing source: {path}")

    module_result_path = repo_path(catalog["evidence"]["module_result"], root=root)
    module_design, module_result = read_evidence_design(module_result_path, "design_id")
    module_tests = set(
        module_result.get("tests", {}).get("inventory", [])
        if isinstance(module_result, dict)
        and module_result.get("status") == "PASS"
        and module_design == live_design_id
        else []
    )
    boundary_by_path = {
        value["rtl"]: module
        for module, value in catalog.get("physical_boundaries", {}).items()
    }
    mapped_evidence = load_mapped_evidence(
        catalog,
        root=root,
        live_design_id=live_design_id,
        source_records=source_records,
    )
    mapped_identity = mapped_evidence["status"]
    mapped_boundary_modes = mapped_evidence.get("boundary_modes", {})
    files: list[dict[str, Any]] = []
    for row in raw_files:
        role = row["role"]
        modules = row["modules"]
        if role == "product":
            filelist = "PASS" if row["path"] in lists["core"] else "FAIL"
        elif role == "catalog_only":
            filelist = (
                "CATALOG_COMPILED"
                if row["path"] in lists["core"]
                else "FAIL_NOT_COMPILED"
            )
        elif role == "source_fragment":
            filelist = "SOURCE_FRAGMENT"
        elif role == "debug_only":
            filelist = "DEBUG_ONLY"
        elif role == "sim_only":
            filelist = "SIM_ONLY"
        else:
            filelist = "FAIL"
        reachable, reachability_errors = file_reachability_status(
            row["path"],
            role=role,
            modules=modules,
            reachable_modules=reachable_modules,
            elaboration_status=elaboration_status,
        )
        errors.extend(reachability_errors)
        matching_tests = sorted(
            test
            for module in modules
            for test in [f"tb_{camel_to_snake(module)}"]
            if test in module_tests
        )
        instance_paths = sorted(
            {
                instance_path
                for module in modules
                for instance_path in instance_paths_by_module.get(module, [])
            }
        )
        if role in {"sim_only", "debug_only", "source_fragment", "catalog_only"}:
            dynamic = "N_A" if role != "source_fragment" else "DEPENDENCY_FRAGMENT"
        elif matching_tests:
            dynamic = "FOCUSED_PASS"
        elif module_design == live_design_id:
            dynamic = "SYSTEM_BOUND_NO_NODE_COUNTER"
        else:
            dynamic = "GAP_STALE_OR_MISSING"
        boundary = boundary_by_path.get(row["path"])
        boundary_value = (
            catalog["physical_boundaries"].get(boundary) if boundary else None
        )
        if role in {"sim_only", "debug_only", "source_fragment", "catalog_only"}:
            mapped = "N_A"
            sta_ppa = "N_A"
        elif boundary and isinstance(boundary_value, dict):
            boundary_mode = mapped_boundary_modes.get(boundary)
            if boundary_mode == PLACEHOLDER_MODE:
                mapped = (
                    "GAP_PLACEHOLDER_BLACKBOX"
                    if mapped_identity == "PASS"
                    else "GAP_STALE_PLUS_PLACEHOLDER_BLACKBOX"
                )
            elif boundary_mode == INLINE_MODE and mapped_identity != "PASS":
                mapped = mapped_identity
            elif boundary_mode == INLINE_MODE and boundary_value["closure_state"] == "PASS":
                mapped = "VISIBLE"
            elif boundary_mode == INLINE_MODE:
                mapped = "GAP_INLINE_OR_SPLIT_CANDIDATE_UNCLOSED"
            else:
                mapped = mapped_identity
            sta_ppa = (
                "PASS"
                if mapped_identity == "PASS"
                and boundary_value["closure_state"] == "PASS"
                else "GAP_INTERNAL_PATH_AREA_POWER_INVISIBLE"
            )
        else:
            mapped = "VISIBLE" if mapped_identity == "PASS" else mapped_identity
            sta_ppa = "BOUND" if mapped_identity == "PASS" else mapped_identity
        files.append(
            {
                **row,
                "filelist": filelist,
                "reachable": reachable,
                "dynamic": dynamic,
                "instance_paths": instance_paths,
                "focused_tests": matching_tests,
                "mapped": mapped,
                "sta_ppa": sta_ppa,
                "physical_boundary": boundary,
            }
        )

    capabilities: dict[str, Any] = {}
    for name, value in sorted(catalog.get("capabilities", {}).items()):
        selected = [row for row in files if name in row["capabilities"]]
        filelist_status = (
            "PASS"
            if selected and all(row["filelist"] != "FAIL" for row in selected)
            else "FAIL"
        )
        required_module_rows = [
            row for row in selected if row["role"] == "product" and row["modules"]
        ]
        reachable_status = (
            "PASS"
            if required_module_rows
            and all(row["reachable"] == "PASS" for row in required_module_rows)
            else (elaboration_status if elaboration_status != "PASS" else "GAP")
        )
        dynamic = dynamic_capability(
            value,
            root=root,
            live_design_id=live_design_id,
        )
        boundary_modules = sorted(
            module
            for module, boundary in catalog["physical_boundaries"].items()
            if boundary["capability"] == name
        )
        boundary_values = [
            catalog["physical_boundaries"][module]
            for module in boundary_modules
        ]
        boundary_modes = [mapped_boundary_modes.get(module) for module in boundary_modules]
        if any(mode == PLACEHOLDER_MODE for mode in boundary_modes):
            mapped_status = "GAP_PLACEHOLDER_BLACKBOX"
        elif boundary_values and any(
            value["closure_state"] != "PASS" for value in boundary_values
        ):
            mapped_status = "GAP_BOUNDARY_NOT_CLOSED"
        else:
            mapped_status = "PASS" if mapped_identity == "PASS" else mapped_identity
        physical_closed = bool(boundary_values) and all(
            value["closure_state"] == "PASS" for value in boundary_values
        )
        capabilities[name] = {
            "label": value["label"],
            "owner": value["owner"],
            "files": [row["path"] for row in selected],
            "nodes": [
                {
                    "path": row["path"],
                    "modules": row["modules"],
                    "instance_paths": row["instance_paths"],
                    "lifecycle": row["lifecycle"],
                    "dynamic": row["dynamic"],
                    "mapped": row["mapped"],
                }
                for row in selected
            ],
            "file_count": len(selected),
            "filelist": filelist_status,
            "reachable": reachable_status,
            "dynamic": dynamic,
            "mapped": mapped_status,
            "sta_ppa": (
                "PASS"
                if physical_closed and mapped_identity == "PASS"
                else "GAP_INTERNAL_PATH_AREA_POWER_INVISIBLE"
            ),
            "physical_boundary_modules": boundary_modules,
            "transaction_ir": value.get("transaction_ir"),
            "physical_strategy": value.get("physical_strategy"),
            "closure_condition": value["closure_condition"],
            "overall": (
                "PASS"
                if filelist_status == "PASS"
                and reachable_status == "PASS"
                and dynamic["status"] == "PASS"
                and physical_closed
                and mapped_identity == "PASS"
                else "GAP"
            ),
        }

    config_path = repo_path(scope["product_config"], root=root)
    catalog_hash = canonical_sha256(catalog)
    inventory_hash = canonical_sha256(
        [{"path": row["path"], "sha256": row["sha256"]} for row in files]
    )
    evidence_hashes = {
        "elaboration": elaboration_sha,
        "module": sha256_file(module_result_path) if module_result_path.is_file() else None,
        "mapped": mapped_evidence["summary_sha256"],
        "latest_mapped_attempt": (
            bpu_physical_experiment_state.get("failed_attempt", {}).get(
                "status_sha256"
            )
            if isinstance(
                bpu_physical_experiment_state.get("failed_attempt"), dict
            )
            else None
        ),
    }
    for name, value in capabilities.items():
        for index, observation in enumerate(value["dynamic"]["observations"]):
            evidence_hashes[f"dynamic.{name}.{index}"] = observation.get("sha256")
    snapshot_inputs = {
        "catalog_sha256": catalog_hash,
        "inventory_sha256": inventory_hash,
        "product_config_sha256": sha256_file(config_path),
        "design_id": live_design_id,
        "source_manifest_sha256": source_manifest_sha256,
        "evidence_sha256": evidence_hashes,
    }
    snapshot_id = f"sha256:{canonical_sha256(snapshot_inputs)}"
    lifecycle_counts = dict(sorted(Counter(row["lifecycle"] for row in files).items()))
    role_counts = dict(sorted(Counter(row["role"] for row in files).items()))
    gaps = [
        "动态类别证据尚未给出 BPU lookup/update/recovery 与 FP launch/kill/stage5/commit 每条内部边的非零计数。",
        "BPU write-banked/flat-read-view source 仍为 development，但 exactly-once mapped attempt "
        "为 FAILED_INCOMPLETE/ROLLBACK/GAP；raw WNS/area 仅是 unbound diagnostic，BPU sweep 已关闭并转向 FP。",
        "冻结 B279 mapped execution receipt 为 PASS，但实验裁决为 ROLLBACK、物理状态为 GAP，"
        "仅保留为 noncanonical archive。",
        "当前 live FP production-child identity 没有 mapped summary 或 architecture_registry_binding；"
        "latest BPU f5f2/B279 receipts 均为 stale-design，不能充当 current PPA。",
        "mapped-5ns-fp-arith-production-children-inline-v1 已登记为 "
        "development/UNMEASURED/GAP/noncanonical；本 snapshot 不把配置登记当作测量。",
    ]
    bpu_mode = mapped_boundary_modes.get("OooBranchDirectionPredictor")
    if bpu_mode == PLACEHOLDER_MODE:
        gaps.append(
            "BPU：当前 mapped configuration 仍把 OooBranchDirectionPredictor 当作 "
            "placeholder blackbox；内部 timing/area/power 不可见。"
        )
    elif bpu_mode == INLINE_MODE:
        gaps.append(
            "BPU：当前 mapped configuration 已选择 inline RTL，但 physical closure "
            "仍需同配置 timing/area/power 证据。"
        )
    fp_mode = mapped_boundary_modes.get("OooFpArithGate")
    if fp_mode == PLACEHOLDER_MODE:
        gaps.append(
            "FP：当前 mapped configuration 把 OooFpArithGate 当作 placeholder "
            "blackbox；内部 timing/area/power 不可见。"
        )
    elif fp_mode == INLINE_MODE:
        gaps.append(
            "FP：当前 mapped configuration 已选择 inline RTL，但 physical closure "
            "仍需同配置 timing/area/power 证据。"
        )
    if mapped_identity != "PASS":
        gaps.append(
            "Mapped STA/PPA 身份未闭合："
            f"status={mapped_identity}，evidence={mapped_evidence['design_id']}，"
            f"live={live_design_id}。"
        )
    if elaboration_status != "PASS":
        gaps.append(f"Elaboration 收据不是 current：{elaboration_status}。")
    snapshot = {
        "schema": "npc-rv64-architecture-registry-snapshot-v1",
        "status": "FAIL" if errors else "PASS_WITH_PRODUCT_GAPS",
        "snapshot_id": snapshot_id,
        "snapshot_inputs": snapshot_inputs,
        "product": scope["product"],
        "top_module": scope["top_module"],
        "git_head": head,
        "design_id": live_design_id,
        "inventory_path_sha256": inventory_path_sha256,
        "counts": {
            "source_files": len(files),
            "synthesis_files": len(lists["core"]),
            "header_fragments": len(lists["header"]),
            "simulation_files": len(lists["sim"]),
            "reachable_modules": len(reachable_modules),
            "physical_boundaries": len(catalog["physical_boundaries"]),
            "open_capability_gaps": sum(
                value["overall"] == "GAP" for value in capabilities.values()
            ),
        },
        "lifecycle_counts": lifecycle_counts,
        "role_counts": role_counts,
        "elaboration": {
            "status": elaboration_status,
            "receipt": catalog["evidence"]["elaboration_receipt"],
            "receipt_id": elaboration.get("receipt_id") if elaboration else None,
        },
        "mapped_evidence": mapped_evidence,
        "bpu_physical_experiment_state": bpu_physical_experiment_state,
        "latest_mapped_attempt": bpu_physical_experiment_state.get(
            "failed_attempt", {}
        ),
        "files": files,
        "file_exceptions": [
            {
                "path": path,
                "owner": value.get("owner"),
                "role": value.get("role"),
                "intent": value.get("intent"),
                "review_expiry": value.get("review_expiry"),
                "configuration_scope": value.get("configuration_scope"),
            }
            for path, value in sorted(catalog.get("file_overrides", {}).items())
            if isinstance(value, dict)
            and (value.get("role") or value.get("intent") or value.get("review_expiry"))
        ],
        "capabilities": capabilities,
        "physical_boundaries": catalog["physical_boundaries"],
        "architecture_nodes": catalog["architecture_nodes"],
        "architecture_edges": catalog["architecture_edges"],
        "gaps": gaps,
        "errors": sorted(set(errors)),
    }
    return snapshot


def mermaid_id(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def render_markdown(snapshot: dict[str, Any], catalog: dict[str, Any]) -> str:
    bpu_state = snapshot["bpu_physical_experiment_state"]
    failed_bpu = bpu_state["failed_attempt"]
    frozen_bpu = bpu_state["frozen_predecessor"]
    lines: list[str] = [
        "# RV64 Architecture Registry",
        "",
        "> 本文件是本地 RV64 架构审阅的**唯一入口**，由",
        "> `npc/rv64/design/arch/rv64-architecture-registry-v1.json` 与当前工程证据自动生成。",
        "> 不要手工编辑；spec/历史 Markdown 只提供语义和证据，不再各自维护“当前状态”。",
        "",
        "生成/检查命令：",
        "",
        "```bash",
        "python3 npc/rv64/eval/ppa/tools/architecture_registry.py capture-elaboration",
        "python3 npc/rv64/eval/ppa/tools/architecture_registry.py render",
        "python3 npc/rv64/eval/ppa/tools/architecture_registry.py check",
        "```",
        "",
        "## 当前快照",
        "",
        f"- registry 状态：`{snapshot['status']}`；这表示治理结构一致，但不把已知物理 GAP 写成 PASS。",
        f"- snapshot：`{snapshot['snapshot_id']}`",
        f"- live design：`{snapshot['design_id']}`",
        f"- 已审阅 vsrc 路径集合：`sha256:{snapshot['inventory_path_sha256']}`（任意新增/删除均 fail-closed）",
        f"- Git HEAD：`{snapshot['git_head']}`",
        f"- 产品：`{snapshot['product']}`，top=`{snapshot['top_module']}`",
        f"- 源文件：{snapshot['counts']['source_files']}；综合清单：{snapshot['counts']['synthesis_files']}；可达 module：{snapshot['counts']['reachable_modules']}",
        f"- elaboration：`{snapshot['elaboration']['status']}`；mapped evidence：`{snapshot['mapped_evidence']['status']}`",
        f"- BPU 当前 physical configuration：`{bpu_state['active_configuration']}`；"
        f"source=`{bpu_state['source_lifecycle']}`；measurement=`{bpu_state['measurement_status']}`；"
        f"execution=`{bpu_state['mapped_execution_receipt']}`；verdict="
        f"`{bpu_state['frozen_experiment_verdict']}`；physical=`{bpu_state['physical_status']}`；"
        f"canonical=`{str(bpu_state['canonical']).lower()}`；sweep="
        f"`{bpu_state['sweep_status']}`",
        "",
        "状态分两条正交轴：Git 内容状态为 `development → revision → committed`；产品资格为",
        "`cataloged → filelist-bound → elaboration-reachable → dynamic-observed → mapped-visible → physically-closed`。",
        "`committed` 绝不等于已验证，仿真 PASS 也绝不等于 STA/PPA 内部可见。",
        "",
        "## 当前必须面对的 GAP",
        "",
    ]
    lines.extend(f"- {gap}" for gap in snapshot["gaps"])
    if snapshot["errors"]:
        lines.extend(["", "结构错误（`check` 会 fail-closed）：", ""])
        lines.extend(f"- `{error}`" for error in snapshot["errors"])

    lines.extend(
        [
            "",
            "## BPU physical experiment 状态",
            "",
            f"- live candidate：`{bpu_state['active_configuration']}`，"
            f"design=`{bpu_state['live_rtl_design_id']}`，"
            f"source=`{bpu_state['source_lifecycle']}`，"
            f"measurement=`{bpu_state['measurement_status']}`，"
            f"mapped execution receipt=`{bpu_state['mapped_execution_receipt']}`，"
            f"experiment verdict=`{bpu_state['frozen_experiment_verdict']}`，"
            f"physical=`{bpu_state['physical_status']}`，archive="
            f"`{bpu_state['archive_status']}`，front_accepted="
            f"`{str(bpu_state['front_accepted']).lower()}`，canonical="
            f"`{str(bpu_state['canonical']).lower()}`，champion="
            f"`{str(bpu_state['champion']).lower()}`。",
            f"- sweep：`{bpu_state['sweep_status']}`；唯一 next action："
            f"`{bpu_state['next_action']}`；stop condition："
            f"`{bpu_state['stop_condition']}`。",
            f"- latest failed mapped attempt：`{failed_bpu['status_path']}` "
            f"(`sha256:{failed_bpu['status_sha256']}`)；command status="
            f"`{failed_bpu['command_status_path']}`；raw diagnostic="
            f"`{failed_bpu['raw_diagnostic_path']}` "
            f"(`{failed_bpu['raw_diagnostic_qualification']}`)。",
            f"- f5f2 bound evidence：summary=`{failed_bpu['summary']}`；"
            f"architecture_registry_binding=`{failed_bpu['architecture_registry_binding']}`；"
            f"qualified_measurement=`{str(failed_bpu['qualified_measurement']).lower()}`。",
            f"- frozen predecessor：`{frozen_bpu['physical_configuration_id']}`，"
            f"design=`{frozen_bpu['source_design_id']}`，mapped execution receipt="
            f"`{frozen_bpu['mapped_execution_receipt']}`，experiment verdict="
            f"`{frozen_bpu['frozen_experiment_verdict']}`，physical="
            f"`{frozen_bpu['physical_status']}`，archive=`{frozen_bpu['archive_status']}`。",
            f"- latest successful bound mapped summary / frozen receipt："
            f"`{frozen_bpu['mapped_summary']}` "
            f"(`sha256:{frozen_bpu['mapped_summary_sha256']}`)。runner PASS 不是物理晋级，"
            "且该收据不绑定当前 live candidate。",
        ]
    )

    directory_rows: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in snapshot["files"]:
        relative = row["path"].removeprefix("npc/rv64/vsrc/")
        directory = relative.split("/", 1)[0]
        directory_rows[directory].append(row)
    lines.extend(["", "## 权责源码树", "", "```text", "npc/rv64/vsrc"])
    directories = sorted(directory_rows)
    for index, directory in enumerate(directories):
        rows = directory_rows[directory]
        owners = Counter(row["owner"] for row in rows)
        states = Counter(row["lifecycle"] for row in rows)
        branch = "└──" if index == len(directories) - 1 else "├──"
        owner_text = ",".join(f"{key}:{value}" for key, value in sorted(owners.items()))
        state_text = ",".join(f"{key}:{value}" for key, value in sorted(states.items()))
        lines.append(
            f"{branch} {directory}/  files={len(rows)}  owner=[{owner_text}]  lifecycle=[{state_text}]"
        )
    lines.extend(["```", "", "完整到每个 `.v/.sv` 的状态见本文末尾“全量文件账本”。"])

    lines.extend(["", "## 抽象架构图", "", "```mermaid", "flowchart LR"])
    for node in snapshot["architecture_nodes"]:
        node_id = mermaid_id(node["id"])
        label = str(node["label"]).replace('"', "'")
        lines.append(f'  {node_id}["{label}"]')
    for edge in snapshot["architecture_edges"]:
        lines.append(
            f"  {mermaid_id(edge['from'])} -->|{edge['relation']}| {mermaid_id(edge['to'])}"
        )
    lines.extend(["```", "", "图节点表达人工确认的架构职责；实例可达性仍只由同一 snapshot 绑定的 Yosys elaboration 收据决定。"])

    lines.extend(["", "## Capability 事务图", ""])
    for name, value in snapshot["capabilities"].items():
        transaction_ir = value.get("transaction_ir")
        if not isinstance(transaction_ir, dict):
            continue
        lines.append(f"### {name.upper()}")
        lines.append("")
        lines.append(str(transaction_ir.get("configuration", "")))
        lines.extend(["", "```mermaid", "flowchart LR"])
        prefix = mermaid_id(name.upper())
        for node in transaction_ir.get("nodes", []):
            node_id = f"{prefix}_{mermaid_id(node['id'])}"
            label = str(node["label"]).replace('"', "'")
            lines.append(f'  {node_id}["{label}"]')
        for edge in transaction_ir.get("edges", []):
            source = f"{prefix}_{mermaid_id(edge['from'])}"
            target = f"{prefix}_{mermaid_id(edge['to'])}"
            relation = f"{edge['relation']} / {edge['latency']}"
            lines.append(f"  {source} -->|{relation}| {target}")
        lines.extend(["```", "", "保持的不变量：", ""])
        lines.extend(f"- {item}" for item in transaction_ir.get("invariants", []))
        lines.extend(["", "当前 UNKNOWN/GAP：", ""])
        lines.extend(f"- {item}" for item in transaction_ir.get("unknowns", []))
        lines.append("")

    lines.extend(["", "## BPU / FP 可见性网络", "", "```mermaid", "flowchart LR"])
    for name, value in snapshot["capabilities"].items():
        prefix = mermaid_id(name.upper())
        lines.append(f'  {prefix}_SRC["{name.upper()} RTL / owner={value["owner"]}"]')
        lines.append(f'  {prefix}_L1["L1 filelist: {value["filelist"]}"]')
        lines.append(f'  {prefix}_L2["L2 reachable: {value["reachable"]}"]')
        lines.append(f'  {prefix}_L3["L3 dynamic: {value["dynamic"]["status"]}"]')
        lines.append(f'  {prefix}_L4["L4 mapped: {value["mapped"]}"]')
        lines.append(f'  {prefix}_L5["L5 STA/PPA: {value["sta_ppa"]}"]')
        lines.append(
            f"  {prefix}_SRC --> {prefix}_L1 --> {prefix}_L2 --> {prefix}_L3 --> {prefix}_L4 --> {prefix}_L5"
        )
    lines.extend(["```", ""])
    lines.append(
        "这里的 L3 只证明相关指令/事务类别在同一 design identity 下非空；BPU lookup/update/recovery 与 "
        "FP launch/kill/stage5/commit 的逐边非空计数仍是 GAP。"
    )

    lines.extend(
        [
            "",
            "### 五层能力矩阵",
            "",
            "| Capability | Owner | L1 filelist | L2 reachable | L3 dynamic | L4 mapped | L5 STA/PPA | Overall |",
            "|---|---|---|---|---|---|---|---|",
        ]
    )
    for name, value in snapshot["capabilities"].items():
        lines.append(
            f"| {name} | {value['owner']} | {value['filelist']} | {value['reachable']} | "
            f"{value['dynamic']['status']} | {value['mapped']} | {value['sta_ppa']} | {value['overall']} |"
        )
    lines.extend(["", "关闭条件：", ""])
    for name, value in snapshot["capabilities"].items():
        lines.append(f"- **{name}**：{value['closure_condition']}")
    lines.extend(["", "当前物理结构裁决：", ""])
    for name, value in snapshot["capabilities"].items():
        strategy = value.get("physical_strategy")
        if not isinstance(strategy, dict):
            continue
        lines.append(
            f"- **{name} / `{strategy.get('decision')}`**：{strategy.get('next_slice')} "
            f"回滚/升级边界：{strategy.get('rollback')}"
        )

    lines.extend(
        [
            "",
            "## 物理边界",
            "",
            "| Module | RTL / Liberty | Netlist representation | Timing / area / power basis | Capability | State |",
            "|---|---|---|---|---|---|",
        ]
    )
    for module, boundary in snapshot["physical_boundaries"].items():
        lines.append(
            f"| {module} | `{boundary['rtl']}`<br>`{boundary['liberty']}` | "
            f"{boundary['netlist_representation']} | {boundary['timing_model_kind']}<br>"
            f"{boundary['area_basis']}<br>{boundary['power_basis']} | "
            f"{boundary['capability']} | {boundary['closure_state']} |"
        )
    lines.extend(
        [
            "",
            "`runner PASS` 只说明工具流程完成。placeholder Liberty 的零面积、无内部 path 或边界 arc 不能升级为物理闭环。",
            "",
            "### FP production-child OOC composite 诊断配置",
            "",
            f"- Configuration：`{FP_ARITH_PRODUCTION_CHILDREN_OOC_BOUNDARY_CONFIGURATION}`；profile：`{MAPPED_ARTIFACT_PROFILE_FP_ARITH_OOC_COMPOSITE}`；abstraction：`{OOC_STA_ABSTRACTION}`。",
            f"- Inline RTL：`{', '.join(EXPECTED_FP_OOC_INLINE_MODULES)}`。",
            f"- Known OOC macros：`{', '.join(EXPECTED_FP_OOC_MACRO_MODULES)}`（各 1 instance）。",
            "- Child source domains：`source_closure` 绑定 define/helper/child RTL/`filelist.mk` 身份；`compile_sources` 是其精确 Verilog 子集且包含 child RTL，只有该列表可送入 child Yosys。",
            f"- Unknown placeholders：`Sram4096x199×1, Sram4096x113×2, OooBranchDirectionPredictor×1`。",
            f"- Final FMA boundary sink：`{FP_OOC_BACKEND_COMPLETION_INSTANCE_PATH}` 的 completion FIFO `df_value_q`/`df_fflags_q` register-D（cardinality 512/40）；`OooFpArithGate.out_value_o/out_fflags_o` 不是 NpcTop ports。",
            "- 该配置只授权一个新 run-id 的 5.0ns diagnostic composite：child max/min/internal、top 五条 boundary、面积单计与 identity receipts 全部闭合后也仍为 GAP/noncanonical/nonchampion；无 OOC power/signoff 模型。",
            "",
            "## 显式产品角色例外",
            "",
            "这些例外是人工真源中必须审阅的意图；未实例化本身不会自动得到 `catalog_only` 豁免。",
            "",
            "| Path | Role | Configuration | Intent | Review expiry |",
            "|---|---|---|---|---|",
        ]
    )
    for row in snapshot["file_exceptions"]:
        lines.append(
            f"| `{row['path']}` | {row.get('role') or 'owner-only'} | "
            f"{row.get('configuration_scope') or '—'} | "
            f"{row.get('intent') or '—'} | {row.get('review_expiry') or '—'} |"
        )
    lines.extend(
        [
            "",
            "## 全量文件账本",
            "",
            "| Path | Owner | Role | Lifecycle | Module(s) / instance path(s) | Filelist | Reachable | Dynamic | Mapped / STA-PPA |",
            "|---|---|---|---|---|---|---|---|---|",
        ]
    )
    for row in snapshot["files"]:
        modules = ", ".join(row["modules"]) if row["modules"] else "—"
        instances = "<br>".join(row["instance_paths"]) if row["instance_paths"] else "—"
        module_instances = f"{modules}<br>{instances}"
        mapped = f"{row['mapped']} / {row['sta_ppa']}"
        lines.append(
            f"| `{row['path']}` | {row['owner']} | {row['role']} | {row['lifecycle']} | "
            f"{module_instances} | {row['filelist']} | {row['reachable']} | {row['dynamic']} | {mapped} |"
        )

    lines.extend(
        [
            "",
            "## 有界查询与审阅",
            "",
            "后续 Agent 不需要重扫全部文档。先按任务分类，再从本入口或机器查询读取最小切片：",
            "",
            "```bash",
            "python3 npc/rv64/eval/ppa/tools/architecture_registry.py query --capability bpu",
            "python3 npc/rv64/eval/ppa/tools/architecture_registry.py query --capability fp",
            "python3 npc/rv64/eval/ppa/tools/architecture_registry.py query --path npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v",
            "python3 npc/rv64/eval/ppa/tools/architecture_registry.py emit mapped-blackbox-modules --physical-configuration mapped-5ns-four-placeholder-v1",
            "python3 npc/rv64/eval/ppa/tools/architecture_registry.py emit ooc-composite-contract --physical-configuration mapped-5ns-fp-arith-production-children-ooc-boundary-v1",
            "```",
            "",
            "确定性 inventory/schema/hash/elaboration join 默认一次。只有输入变化、工具异常、非确定性测量或正式高风险晋级才追加不同证据或独立审查。",
            "",
            "## 证据指针",
            "",
            f"- Elaboration：`{snapshot['elaboration']['receipt']}` (`{snapshot['elaboration']['status']}`)",
            f"- Latest successful bound mapped summary：`{snapshot['mapped_evidence']['summary']}` "
            f"(`{snapshot['mapped_evidence']['status']}`)",
            f"- Latest failed mapped attempt：`{failed_bpu['status_path']}` "
            f"(`{failed_bpu['result']}`；summary/binding absent；raw diagnostic unbound)",
        ]
    )
    for error in snapshot["mapped_evidence"].get("binding_errors", []):
        lines.append(f"  - mapped binding GAP：{error}")
    for name, value in snapshot["capabilities"].items():
        for observation in value["dynamic"]["observations"]:
            lines.append(
                f"- {name} dynamic `{observation['status']}`：`{observation['path']}`"
            )
    lines.append("")
    return "\n".join(lines)


def command_capture(args: argparse.Namespace, catalog: dict[str, Any]) -> int:
    output = args.output.resolve() if args.output else None
    receipt = capture_elaboration(
        catalog,
        output=output,
        yosys=args.yosys,
        timeout=args.timeout_seconds,
    )
    print(
        json.dumps(
            {
                "status": "PASS",
                "design_id": receipt["design_id"],
                "receipt_id": receipt["receipt_id"],
                "reachable_instance_count": receipt["reachable_instance_count"],
                "output": (
                    str(output)
                    if output
                    else catalog["evidence"]["elaboration_receipt"]
                ),
            },
            ensure_ascii=False,
            sort_keys=True,
        )
    )
    return 0


def command_render(args: argparse.Namespace, catalog: dict[str, Any]) -> int:
    snapshot = build_snapshot(catalog)
    if snapshot["errors"]:
        for error in snapshot["errors"]:
            print(f"[RV64-ARCH-REGISTRY][FAIL] {error}", file=sys.stderr)
        return 2
    output = args.output.resolve() if args.output else ENTRY_PATH
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_markdown(snapshot, catalog), encoding="utf-8")
    print(
        f"[RV64-ARCH-REGISTRY][PASS] snapshot={snapshot['snapshot_id']} "
        f"files={snapshot['counts']['source_files']} output={output} product_status=GAP"
    )
    return 0


def command_check(args: argparse.Namespace, catalog: dict[str, Any]) -> int:
    snapshot = build_snapshot(catalog)
    errors = list(snapshot["errors"])
    expected = render_markdown(snapshot, catalog)
    if not ENTRY_PATH.is_file():
        errors.append(f"single entry is missing: {ENTRY_PATH.relative_to(REPO_ROOT)}")
    elif ENTRY_PATH.read_text(encoding="utf-8") != expected:
        errors.append("single entry is stale; run architecture_registry.py render")
    if errors:
        for error in sorted(set(errors)):
            print(f"[RV64-ARCH-REGISTRY][FAIL] {error}", file=sys.stderr)
        return 2
    if args.require_product_closed and any(
        value["overall"] != "PASS" for value in snapshot["capabilities"].values()
    ):
        print(
            "[RV64-ARCH-REGISTRY][GAP] product physical closure is incomplete",
            file=sys.stderr,
        )
        return 3
    print(
        f"[RV64-ARCH-REGISTRY][PASS] snapshot={snapshot['snapshot_id']} "
        f"files={snapshot['counts']['source_files']} structural=PASS product=GAP"
    )
    return 0


def command_query(args: argparse.Namespace, catalog: dict[str, Any]) -> int:
    snapshot = build_snapshot(catalog)
    if snapshot["errors"]:
        result: Any = {
            "status": "FAIL",
            "snapshot_id": snapshot["snapshot_id"],
            "errors": snapshot["errors"],
        }
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
        return 2
    if args.capability:
        if args.capability not in snapshot["capabilities"]:
            print(f"unknown capability: {args.capability}", file=sys.stderr)
            return 2
        result = {
            "snapshot_id": snapshot["snapshot_id"],
            "design_id": snapshot["design_id"],
            "capability": args.capability,
            **snapshot["capabilities"][args.capability],
        }
        if args.capability == "bpu":
            result.update(
                {
                    "mapped_evidence_status": snapshot["mapped_evidence"]["status"],
                    "sweep_status": snapshot["bpu_physical_experiment_state"][
                        "sweep_status"
                    ],
                    "physical_experiment_state": snapshot[
                        "bpu_physical_experiment_state"
                    ],
                    "latest_mapped_attempt": snapshot["latest_mapped_attempt"],
                }
            )
    elif args.path:
        matches = [row for row in snapshot["files"] if row["path"] == args.path]
        if not matches:
            print(f"path is not in the RV64 source inventory: {args.path}", file=sys.stderr)
            return 2
        result = {
            "snapshot_id": snapshot["snapshot_id"],
            "design_id": snapshot["design_id"],
            "file": matches[0],
        }
    else:
        result = {
            key: snapshot[key]
            for key in (
                "status",
                "snapshot_id",
                "design_id",
                "product",
                "top_module",
                "counts",
                "lifecycle_counts",
                "role_counts",
                "elaboration",
                "mapped_evidence",
                "bpu_physical_experiment_state",
                "latest_mapped_attempt",
                "gaps",
            )
        }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


def command_emit(args: argparse.Namespace, catalog: dict[str, Any]) -> int:
    projection = mapped_projection(catalog, args.physical_configuration)
    if args.field == "mapped-blackbox-modules":
        print(" ".join(projection["blackbox_modules"]))
    elif args.field == "mapped-artifact-profile":
        print(projection["mapped_artifact_profile"])
    elif args.field == "inline-modules":
        print(" ".join(projection["inline_modules"]))
    elif args.field == "known-ooc-macro-modules":
        modules = projection.get("known_ooc_macro_modules")
        if modules is None:
            raise RegistryError("selected physical configuration has no known OOC macros")
        print(" ".join(modules))
    elif args.field == "top-blackbox-modules":
        modules = projection.get("top_blackbox_modules")
        if modules is None:
            raise RegistryError("selected physical configuration is not an OOC composite")
        print(" ".join(modules))
    elif args.field == "ooc-composite-contract":
        required = (
            "abstraction_kind", "implementation_classes",
            "expected_known_ooc_macro_instances", "ooc_model_contract",
            "child_contracts",
        )
        if any(field not in projection for field in required):
            raise RegistryError("selected physical configuration is not an OOC composite")
        print(json.dumps(
            {field: projection[field] for field in required},
            allow_nan=False,
            ensure_ascii=False,
            sort_keys=True,
        ))
    elif args.field == "physical-configuration-sha256":
        configuration = selected_physical_configuration(
            catalog, args.physical_configuration
        )
        print(physical_configuration_sha256(
            args.physical_configuration, configuration
        ))
    elif args.field == "mapped-projection-sha256":
        print(canonical_sha256(projection))
    elif args.field == "macro-lib-files":
        print(" ".join(row["path"] for row in projection["macro_lib_files"]))
    elif args.field == "keep-hierarchy-modules":
        print(" ".join(projection["keep_hierarchy_modules"]))
    elif args.field == "standard-cell-lib":
        print(catalog["run_parameter_contract"]["standard_cell_lib"])
    elif args.field == "sdc-file":
        print(catalog["run_parameter_contract"]["sdc_file"])
    elif args.field == "opensta-binary":
        print(catalog["run_parameter_contract"]["opensta_binary"])
    elif args.field == "expected-rtl-design-id":
        print(catalog["run_parameter_contract"]["expected_rtl_design_id"])
    elif args.field == "live-rtl-design-id":
        design_digest, _ = design_binding(
            REPO_ROOT, catalog["scope"]["source_root"]
        )
        print(f"sha256:{design_digest}")
    elif args.field == "run-parameters":
        if not args.expected_rtl_design_id or not args.result_root:
            raise RegistryError(
                "run-parameters emission requires expected RTL design-id and result root"
            )
        print(
            render_run_parameters(
                catalog,
                args.physical_configuration,
                expected_rtl_design_id=args.expected_rtl_design_id,
                result_root=args.result_root,
            ),
            end="",
        )
    else:
        raise AssertionError(args.field)
    return 0


def command_stamp_mapped_summary(
    args: argparse.Namespace, catalog: dict[str, Any]
) -> int:
    snapshot = build_snapshot(catalog)
    if snapshot["errors"]:
        raise RegistryError("registry invalid: " + "; ".join(snapshot["errors"]))
    binding = stamp_mapped_summary(
        catalog,
        physical_configuration_id=args.physical_configuration,
        expected_rtl_design_id=args.expected_rtl_design_id,
        summary_path=args.summary.resolve(),
        source_manifest_path=args.source_manifest.resolve(),
        parameters_path=args.parameters.resolve(),
        sta_input_manifest_path=args.sta_input_manifest.resolve(),
        synth_stat_path=args.synth_stat.resolve(),
        production_manifest_before=args.production_manifest_before.resolve(),
        production_manifest_after=args.production_manifest_after.resolve(),
        mapped_artifact_profile=args.mapped_artifact_profile,
        blackbox_modules=args.blackbox_modules.split(),
        inline_modules=args.inline_modules.split(),
        macro_lib_files=args.macro_lib_files.split(),
    )
    print(
        json.dumps(
            {
                "status": "PASS",
                "design_id": binding["design_id"],
                "architecture_policy_sha256": binding[
                    "architecture_policy_sha256"
                ],
                "physical_configuration_id": binding[
                    "physical_configuration_id"
                ],
                "mapped_projection_sha256": binding[
                    "mapped_projection_sha256"
                ],
                "summary": str(args.summary),
            },
            ensure_ascii=False,
            sort_keys=True,
        )
    )
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=CATALOG_PATH)
    subparsers = parser.add_subparsers(dest="command", required=True)
    capture = subparsers.add_parser("capture-elaboration")
    capture.add_argument("--output", type=Path)
    capture.add_argument("--yosys")
    capture.add_argument("--timeout-seconds", type=int, default=180)
    capture.set_defaults(function=command_capture)
    render = subparsers.add_parser("render")
    render.add_argument("--output", type=Path)
    render.set_defaults(function=command_render)
    check = subparsers.add_parser("check")
    check.add_argument("--require-product-closed", action="store_true")
    check.set_defaults(function=command_check)
    query = subparsers.add_parser("query")
    selection = query.add_mutually_exclusive_group()
    selection.add_argument("--capability")
    selection.add_argument("--path")
    query.set_defaults(function=command_query)
    emit = subparsers.add_parser("emit")
    emit.add_argument(
        "field",
        choices=(
            "mapped-blackbox-modules",
            "mapped-artifact-profile",
            "inline-modules",
            "known-ooc-macro-modules",
            "top-blackbox-modules",
            "ooc-composite-contract",
            "physical-configuration-sha256",
            "mapped-projection-sha256",
            "macro-lib-files",
            "keep-hierarchy-modules",
            "standard-cell-lib",
            "sdc-file",
            "opensta-binary",
            "expected-rtl-design-id",
            "live-rtl-design-id",
            "run-parameters",
        ),
    )
    emit.add_argument("--physical-configuration", required=True)
    emit.add_argument("--expected-rtl-design-id")
    emit.add_argument("--result-root")
    emit.set_defaults(function=command_emit)
    stamp = subparsers.add_parser("stamp-mapped-summary")
    stamp.add_argument("--physical-configuration", required=True)
    stamp.add_argument("--expected-rtl-design-id", required=True)
    stamp.add_argument("--summary", type=Path, required=True)
    stamp.add_argument("--source-manifest", type=Path, required=True)
    stamp.add_argument("--parameters", type=Path, required=True)
    stamp.add_argument("--sta-input-manifest", type=Path, required=True)
    stamp.add_argument("--synth-stat", type=Path, required=True)
    stamp.add_argument("--production-manifest-before", type=Path, required=True)
    stamp.add_argument("--production-manifest-after", type=Path, required=True)
    stamp.add_argument(
        "--mapped-artifact-profile",
        choices=tuple(sorted(MAPPED_ARTIFACT_PROFILES)),
        required=True,
    )
    stamp.add_argument("--blackbox-modules", required=True)
    stamp.add_argument("--inline-modules", required=True)
    stamp.add_argument("--macro-lib-files", required=True)
    stamp.set_defaults(function=command_stamp_mapped_summary)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        catalog = load_json(args.catalog.resolve())
        return int(args.function(args, catalog))
    except (RegistryError, subprocess.TimeoutExpired) as exc:
        print(f"[RV64-ARCH-REGISTRY][FAIL] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
