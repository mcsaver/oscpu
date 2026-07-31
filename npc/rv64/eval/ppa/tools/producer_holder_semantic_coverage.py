#!/usr/bin/env python3
"""Build a fail-closed producer/holder semantic coverage ledger.

The census proves field and elaborated-instance inventory only.  This tool
joins that inventory with heterogeneous directed evidence without turning a
partial or historical candidate into semantic completion.
"""

from __future__ import annotations

import argparse
import copy
import functools
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter, defaultdict
from typing import Any, Iterable


SCHEMA = "rv64-producer-holder-semantic-coverage-v1"
POLICY_SCHEMA = "rv64-producer-holder-semantic-coverage-policy-v1"
V11B_TERMINAL_COLLECTOR_UNIT_IDS = frozenset(
    {
        "terminal-output0-token",
        "terminal-output1-token",
        "terminal-pending-set",
    }
)
V11C_MEMORY_TRACKER_UNIT_IDS = frozenset(
    {
        "memory-tracker-producer-map",
        "memory-tracker-live-set",
    }
)
V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS = frozenset(
    {"tracker-next-token-cursor"}
)
V11E_ROB_SLOT_GENERATION_UNIT_IDS = frozenset(
    {"rob-slot-generation"}
)
V11F_INT_IQ_PRODUCER_UNIT_IDS = frozenset(
    {"integer-iq-producers"}
)
V11G_STORE_QUEUE_HOLDER_UNIT_IDS = frozenset(
    {
        "store-queue-producers",
        "store-queue-owner-tokens",
    }
)
V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS = frozenset(
    {"load-queue-producers"}
)
V11J_BRIDGE_HOLDER_UNIT_IDS = frozenset(
    {
        "bridge-active-token",
        "bridge-response-token",
        "bridge-stage-token",
        "bridge-verified-token-alias",
        "bridge-residency-set",
    }
)
V11J_BRIDGE_HOLDER_SCHEMA = (
    "npc-rv64-v11j-bridge-holder-semantic-evidence-v1"
)
V11J_PRODUCT_INSTANCES = frozenset(
    {
        "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge0",
        "NpcTop.u_core.u_ooo_dual_mem_bridge.u_bridge1",
    }
)
V11J_MUTATION_CASES = frozenset(
    {
        "stage-capture-wrong-token",
        "active-transfer-wrong-token",
        "response-snapshot-wrong-token",
        "verified-alias-x-epoch",
        "active-response-stall-drift",
        "response-stall-drift",
        "residency-omit-stage",
        "residency-add-ghost",
        "wrapper-crosswire-residency-lanes",
        "stage-kind-x-capture",
        "active-epoch-x-transfer",
        "response-kind-x-snapshot",
        "verified-token-x-capture",
    }
)
V11J_REGRESSIONS = frozenset(
    {
        "tb_ooo_mem_axi_bridge",
        "tb_ooo_dual_mem_bridge_wrapper",
        "tb_ooo_mem_axi_bridge_v9r_sq_retry_c0",
    }
)
V11K_MIQ_HOLDER_UNIT_IDS = frozenset({"miq-owner-tokens"})
V11K_MIQ_HOLDER_SCHEMA = (
    "npc-rv64-v11k-miq-holder-semantic-evidence-v2"
)
V11K_PRODUCT_INSTANCES = frozenset(
    {
        "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
        "u_decode_backend.u_int_backend.u_mem1_inflight_queue",
        "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
        "u_decode_backend.u_int_backend.u_mem_inflight_queue",
    }
)
V11K_MUTATION_CASES = frozenset(
    {
        "capture-kind-x",
        "capture-kind-z",
        "capture-token-x",
        "capture-token-z",
        "capture-epoch-x",
        "capture-epoch-z",
        "idle-head-token-drift",
        "consume-without-exact-owner",
        "flush-drop-drain",
        "flush-preserve-killable",
        "occupancy-omit-live",
        "occupancy-add-ghost",
    }
)
V11K_REGRESSIONS = frozenset(
    {
        "tb_ooo_mem_inflight_queue",
        "tb_ooo_dual_mem_inflight_queue_semantic",
        "tb_ooo_int_backend",
    }
)
V11K_STIMULUS_PROBES = {
    "accepted-push-tuple-x": {
        "define": "-DV11K_PUSH_TUPLE_X_PROBE",
        "assertion_marker": "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
        "assertion_marker_key": "v11k_miq_push_tuple_known",
        "release_marker": (
            "[V11K-MIQ-PUSH-TUPLE-FAIL-CLOSED][PASS]"
        ),
        "release_marker_key": "push_fail_closed",
    },
    "accepted-push-tuple-z": {
        "define": "-DV11K_PUSH_TUPLE_Z_PROBE",
        "assertion_marker": "[V11K-MIQ-PUSH-TUPLE-KNOWN]",
        "assertion_marker_key": "v11k_miq_push_tuple_known",
        "release_marker": (
            "[V11K-MIQ-PUSH-TUPLE-FAIL-CLOSED][PASS]"
        ),
        "release_marker_key": "push_fail_closed",
    },
    "valid-head-pop-tuple-x": {
        "define": "-DV11K_POP_TUPLE_X_PROBE",
        "assertion_marker": "[V11K-MIQ-POP-TUPLE-KNOWN]",
        "assertion_marker_key": "v11k_miq_pop_tuple_known",
        "release_marker": (
            "[V11K-MIQ-POP-TUPLE-FAIL-CLOSED][PASS]"
        ),
        "release_marker_key": "pop_fail_closed",
    },
    "valid-head-pop-tuple-z": {
        "define": "-DV11K_POP_TUPLE_Z_PROBE",
        "assertion_marker": "[V11K-MIQ-POP-TUPLE-KNOWN]",
        "assertion_marker_key": "v11k_miq_pop_tuple_known",
        "release_marker": (
            "[V11K-MIQ-POP-TUPLE-FAIL-CLOSED][PASS]"
        ),
        "release_marker_key": "pop_fail_closed",
    },
}
V11L_MEMORY_RETRY_HOLDER_UNIT_IDS = frozenset(
    {
        "memory-retry0-producer-cache",
        "memory-retry0-token",
        "memory-retry1-producer-cache",
        "memory-retry1-token",
    }
)
V11L_MEMORY_RETRY_HOLDER_SCHEMA = (
    "npc-rv64-v11l-memory-retry-holder-semantic-evidence-v1"
)
V11L_PRODUCT_INSTANCES = frozenset(
    {
        "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
        "u_decode_backend.u_int_backend"
    }
)
V11L_REGRESSIONS = frozenset(
    {
        "tb_ooo_int_backend",
        "tb_ooo_int_backend_v9r_sq_retry_c0",
        "tb_ooo_int_backend_v11i_terminal_lifecycle",
    }
)
V11L_R0_UNITS = frozenset(
    {
        "memory-retry0-producer-cache",
        "memory-retry0-token",
    }
)
V11L_R1_UNITS = frozenset(
    {
        "memory-retry1-producer-cache",
        "memory-retry1-token",
    }
)
V11L_MUTATION_EXPECTATIONS = {
    "retry0-producer-cross-lane": {
        "unit_ids": frozenset({"memory-retry0-producer-cache"}),
        "stage": "retry0-holder-tuple",
    },
    "retry0-token-cross-lane": {
        "unit_ids": frozenset({"memory-retry0-token"}),
        "stage": "retry0-holder-tuple",
    },
    "retry1-producer-cross-lane": {
        "unit_ids": frozenset({"memory-retry1-producer-cache"}),
        "stage": "retry1-holder-tuple",
    },
    "retry1-token-cross-lane": {
        "unit_ids": frozenset({"memory-retry1-token"}),
        "stage": "retry1-holder-tuple",
    },
    "retry0-producer-x": {
        "unit_ids": frozenset({"memory-retry0-producer-cache"}),
        "stage": "retry0-holder-tuple",
    },
    "retry0-producer-z": {
        "unit_ids": frozenset({"memory-retry0-producer-cache"}),
        "stage": "retry0-holder-tuple",
    },
    "retry0-token-x": {
        "unit_ids": frozenset({"memory-retry0-token"}),
        "stage": "retry0-holder-tuple",
    },
    "retry0-token-z": {
        "unit_ids": frozenset({"memory-retry0-token"}),
        "stage": "retry0-holder-tuple",
    },
    "retry1-producer-x": {
        "unit_ids": frozenset({"memory-retry1-producer-cache"}),
        "stage": "retry1-holder-tuple",
    },
    "retry1-producer-z": {
        "unit_ids": frozenset({"memory-retry1-producer-cache"}),
        "stage": "retry1-holder-tuple",
    },
    "retry1-token-x": {
        "unit_ids": frozenset({"memory-retry1-token"}),
        "stage": "retry1-holder-tuple",
    },
    "retry1-token-z": {
        "unit_ids": frozenset({"memory-retry1-token"}),
        "stage": "retry1-holder-tuple",
    },
    "retry0-producer-hold-drift": {
        "unit_ids": frozenset({"memory-retry0-producer-cache"}),
        "stage": "retry0-holder-tuple",
    },
    "retry0-token-hold-drift": {
        "unit_ids": frozenset({"memory-retry0-token"}),
        "stage": "retry0-holder-tuple",
    },
    "retry1-producer-hold-drift": {
        "unit_ids": frozenset({"memory-retry1-producer-cache"}),
        "stage": "retry1-holder-tuple",
    },
    "retry1-token-hold-drift": {
        "unit_ids": frozenset({"memory-retry1-token"}),
        "stage": "retry1-holder-tuple",
    },
    "retry0-early-valid-death": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "retry0-holder-tuple",
    },
    "retry1-early-valid-death": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "retry1-holder-tuple",
    },
    "retry0-fire-retains-holder": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "retry0-next-cycle-miq",
    },
    "retry1-fire-retains-holder": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "retry1-next-cycle-miq",
    },
    "retry0-fire-suppresses-miq-push": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "retry0-fire-transfer",
    },
    "retry1-fire-suppresses-miq-push": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "retry1-fire-transfer",
    },
    "retry0-cancel-suppresses-terminal": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "flush-cancel-terminal-priority",
    },
    "retry1-cancel-suppresses-terminal": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "flush-cancel-terminal-priority",
    },
    "retry0-fire-premature-terminal": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "tracker0-not-exact-live",
    },
    "retry1-fire-premature-terminal": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "dual-response-terminal-accept",
    },
    "retry0-c0-capture-open": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "c0-empty-holder-capture-barrier",
    },
    "retry1-c0-capture-open": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "c0-empty-holder-capture-barrier",
    },
    "retry0-c0-resident-fire-open": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "c0-filled-holder-pause",
    },
    "retry1-c0-resident-fire-open": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "c0-filled-holder-pause",
    },
    "retry0-flush-fire-open": {
        "unit_ids": V11L_R0_UNITS,
        "stage": "flush-cancel-terminal-priority",
    },
    "retry1-flush-fire-open": {
        "unit_ids": V11L_R1_UNITS,
        "stage": "flush-cancel-terminal-priority",
    },
}
V11L_BASELINE_MARKERS = {
    "[V11L-RETRY0-CAPTURE-TUPLE][PASS]": (
        "v11l_retry0_capture_tuple_pass",
        2,
    ),
    "[V11L-RETRY1-CAPTURE-TUPLE][PASS]": (
        "v11l_retry1_capture_tuple_pass",
        2,
    ),
    "[V11L-LANE-DISTINCT][PASS]": (
        "v11l_lane_distinct_pass",
        2,
    ),
    "[V11L-RETRY-HOLD][PASS]": ("v11l_retry_hold_pass", 1),
    "[V11L-C0-HOLDER-PAUSE][PASS]": (
        "v11l_c0_holder_pause_pass",
        1,
    ),
    "[V11L-RETRY0-FIRE-TRANSFER][PASS]": (
        "v11l_retry0_fire_transfer_pass",
        1,
    ),
    "[V11L-RETRY1-FIRE-TRANSFER][PASS]": (
        "v11l_retry1_fire_transfer_pass",
        1,
    ),
    "[V11L-RESPONSE-TERMINAL-EXACT][PASS]": (
        "v11l_response_terminal_exact_pass",
        1,
    ),
    "[V11L-FLUSH-CANCEL-LANE10-EXACT][PASS]": (
        "v11l_flush_cancel_lane10_exact_pass",
        1,
    ),
    "[V11L-FLUSH-CANCEL-LANE11-EXACT][PASS]": (
        "v11l_flush_cancel_lane11_exact_pass",
        1,
    ),
}
V11M_MEMORY_RESERVATION_HOLDER_UNIT_IDS = frozenset(
    {
        "memory-reservation-producer",
        "memory-reservation-token",
        "memory-reservation1-producer",
        "memory-reservation1-token",
    }
)
V11M_MEMORY_RESERVATION_HOLDER_SCHEMA = (
    "npc-rv64-v11m-memory-reservation-holder-semantic-evidence-v2"
)
V11M_PRODUCT_INSTANCES = V11L_PRODUCT_INSTANCES
V11M_REGRESSIONS = frozenset(
    {
        "tb_ooo_int_backend",
        "tb_ooo_int_backend_v11l_memory_retry_holder",
        "tb_ooo_int_backend_v11i_terminal_lifecycle",
    }
)
V11M_R0_UNITS = frozenset(
    {"memory-reservation-producer", "memory-reservation-token"}
)
V11M_R1_UNITS = frozenset(
    {"memory-reservation1-producer", "memory-reservation1-token"}
)
V11M_MUTATION_EXPECTATIONS = {
    "pair-capture0-ignores-credit1": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "pair-credit-atomic",
    },
    "reservation0-producer-cross-lane": {
        "unit_ids": frozenset({"memory-reservation-producer"}),
        "stage": "reservation0-holder-tuple",
    },
    "reservation1-producer-cross-lane": {
        "unit_ids": frozenset({"memory-reservation1-producer"}),
        "stage": "reservation1-holder-tuple",
    },
    "reservation0-token-cross-lane": {
        "unit_ids": frozenset({"memory-reservation-token"}),
        "stage": "reservation0-holder-tuple",
    },
    "reservation1-token-cross-lane": {
        "unit_ids": frozenset({"memory-reservation1-token"}),
        "stage": "reservation1-holder-tuple",
    },
    "reservation0-producer-generation-truncate": {
        "unit_ids": frozenset({"memory-reservation-producer"}),
        "stage": "reservation0-holder-tuple",
    },
    "reservation1-producer-generation-truncate": {
        "unit_ids": frozenset({"memory-reservation1-producer"}),
        "stage": "reservation1-holder-tuple",
    },
    "reservation0-token-high-truncate": {
        "unit_ids": frozenset({"memory-reservation-token"}),
        "stage": "reservation0-holder-tuple",
    },
    "reservation1-token-high-truncate": {
        "unit_ids": frozenset({"memory-reservation1-token"}),
        "stage": "reservation1-holder-tuple",
    },
    **{
        f"reservation{lane}-{field}-{state}": {
            "unit_ids": frozenset({unit}),
            "stage": f"reservation{lane}-holder-tuple",
        }
        for lane, field, unit in (
            (0, "producer", "memory-reservation-producer"),
            (0, "token", "memory-reservation-token"),
            (1, "producer", "memory-reservation1-producer"),
            (1, "token", "memory-reservation1-token"),
        )
        for state in ("x", "z")
    },
    **{
        f"reservation{lane}-{field}-hold-drift": {
            "unit_ids": frozenset({unit}),
            "stage": f"reservation{lane}-holder-tuple",
        }
        for lane, field, unit in (
            (0, "producer", "memory-reservation-producer"),
            (0, "token", "memory-reservation-token"),
            (1, "producer", "memory-reservation1-producer"),
            (1, "token", "memory-reservation1-token"),
        )
    },
    "reservation0-early-valid-death": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "reservation0-holder-tuple",
    },
    "reservation1-early-valid-death": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "reservation1-holder-tuple",
    },
    "reservation0-consumes-on-valid": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "ready00-hold-event",
    },
    "reservation1-consumes-on-valid": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "ready00-hold-event",
    },
    "request0-token-cross-lane": {
        "unit_ids": frozenset({"memory-reservation-token"}),
        "stage": "request0-transfer",
    },
    "request1-token-cross-lane": {
        "unit_ids": frozenset({"memory-reservation1-token"}),
        "stage": "request1-transfer",
    },
    "reservation0-terminal-tieoff": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "local0-terminal",
    },
    "reservation1-terminal-tieoff": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "local1-terminal",
    },
    "reservation-terminal-token-swap": {
        "unit_ids": frozenset(
            {"memory-reservation-token", "memory-reservation1-token"}
        ),
        "stage": "local0-terminal",
    },
    "reservation1-selective-kill-disabled": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "selective-recovery",
    },
    "reservation0-selective-survivor-killed": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "selective-recovery",
    },
    "reservation0-global-cancel-disabled": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "selective-survivor-flush",
    },
    "reservation1-global-cancel-disabled": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "global-flush-priority",
    },
    "reservation0-recovery-request-open": {
        "unit_ids": V11M_R0_UNITS,
        "stage": "selective-recovery",
    },
    "reservation1-recovery-request-open": {
        "unit_ids": V11M_R1_UNITS,
        "stage": "selective-recovery",
    },
    "pair-turnover-disabled": {
        "unit_ids": V11M_MEMORY_RESERVATION_HOLDER_UNIT_IDS,
        "stage": "pair-turnover",
    },
}
V11M_BASELINE_MARKERS = {
    "[V11M-BIRTH-CREDIT-ATOMIC][PASS]": (
        "v11m_birth_credit_atomic_pass",
        1,
    ),
    "[V11M-FULL-WIDTH-IDENTITY][PASS]": (
        "v11m_full_width_identity_pass",
        1,
    ),
    "[V11M-HOLD-TUPLE][PASS]": ("v11m_hold_tuple_pass", 1),
    "[V11M-ASYMMETRIC-TRANSFER][PASS]": (
        "v11m_asymmetric_transfer_pass",
        1,
    ),
    "[V11M-LOCAL0-LANE6-EXACT][PASS]": (
        "v11m_local0_lane6_exact_pass",
        1,
    ),
    "[V11M-LOCAL1-LANE7-EXACT][PASS]": (
        "v11m_local1_lane7_exact_pass",
        1,
    ),
    "[V11M-SELECTIVE-RECOVERY][PASS]": (
        "v11m_selective_recovery_pass",
        1,
    ),
    "[V11M-GLOBAL-FLUSH][PASS]": (
        "v11m_global_flush_pass",
        1,
    ),
    "[V11M-PAIR-TURNOVER][PASS]": (
        "v11m_pair_turnover_pass",
        1,
    ),
}
V11N_MEMORY_PENDING_HOLDER_UNIT_IDS = frozenset(
    {
        "memory-pending-producer-cache",
        "memory-pending-token",
    }
)
V11N_MEMORY_PENDING_HOLDER_SCHEMA = (
    "npc-rv64-v11n-memory-pending-holder-semantic-evidence-v1"
)
V11N_PRODUCT_INSTANCES = V11M_PRODUCT_INSTANCES
V11N_REGRESSIONS = V11M_REGRESSIONS
V11N_MUTATION_EXPECTATIONS = {
    "capture-producer-generation-truncate": {
        "unit_ids": frozenset({"memory-pending-producer-cache"}),
        "stage": "amo-read-pending-birth",
    },
    "capture-producer-cross-lane": {
        "unit_ids": frozenset({"memory-pending-producer-cache"}),
        "stage": "amo-read-pending-birth",
    },
    "capture-producer-x": {
        "unit_ids": frozenset({"memory-pending-producer-cache"}),
        "stage": "amo-read-pending-birth",
    },
    "capture-token-high-truncate": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "amo-read-pending-birth",
    },
    "capture-token-z": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "amo-read-pending-birth",
    },
    "read-phase-producer-generation-truncate": {
        "unit_ids": frozenset({"memory-pending-producer-cache"}),
        "stage": "successful-read-write-phase",
    },
    "read-phase-token-high-truncate": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "successful-read-write-phase",
    },
    "read-phase-clears-pending": {
        "unit_ids": V11N_MEMORY_PENDING_HOLDER_UNIT_IDS,
        "stage": "successful-read-write-phase",
    },
    "write-fire-producer-generation-truncate": {
        "unit_ids": frozenset({"memory-pending-producer-cache"}),
        "stage": "post-write-hold",
    },
    "write-fire-token-high-truncate": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "post-write-hold",
    },
    "final-response-keeps-pending": {
        "unit_ids": V11N_MEMORY_PENDING_HOLDER_UNIT_IDS,
        "stage": "amo-final-next-cycle-clear",
    },
    "interphase-cancel-suppressed": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "amo-interphase-cancel",
    },
    "interphase-lane9-token-high-truncate": {
        "unit_ids": frozenset({"memory-pending-token"}),
        "stage": "amo-interphase-lane9",
    },
}
V11N_BASELINE_MARKERS = {
    "[V11N-LANE0-FULL-WIDTH-BIRTH][PASS]": (
        "v11n_lane0_full_width_birth_pass",
        2,
    ),
    "[V11N-DISPATCH1-TO-TERMINAL0][PASS]": (
        "v11n_dispatch1_terminal0_pass",
        1,
    ),
    "[V11N-READ-WRITE-HOLD][PASS]": (
        "v11n_read_write_hold_pass",
        1,
    ),
    "[V11N-FINAL-LANE0-DEATH][PASS]": (
        "v11n_final_lane0_death_pass",
        1,
    ),
    "[V11N-INTERPHASE-LANE9-DEATH][PASS]": (
        "v11n_interphase_lane9_death_pass",
        1,
    ),
    "[V11N-READ-FAULT-LANE0][PASS]": (
        "v11n_read_fault_lane0_pass",
        1,
    ),
}
V11O_MEMORY_BUFFER_TOKEN_UNIT_IDS = frozenset(
    {"memory-buffer-token"}
)
V11O_MEMORY_BUFFER_TOKEN_SCHEMA = (
    "npc-rv64-v11o-memory-buffer-token-semantic-evidence-v1"
)
V11O_PRODUCT_REACHABILITY_SCHEMA = (
    "npc-rv64-memory-buffer-product-reachability-v1"
)
V11O_PRODUCT_INSTANCES = V11N_PRODUCT_INSTANCES
V11O_REGRESSIONS = V11N_REGRESSIONS
V11O_MUTATION_EXPECTATIONS = {
    "lane0-capture-token-high-truncate": "lane0-buffer-birth",
    "lane1-capture-token-high-truncate": "lane1-buffer-birth",
    "lane1-capture-token-x": "lane1-buffer-birth",
    "hold-token-high-truncate": "lane1-buffer-hold",
    "transfer-token-high-truncate": "buffer-transfer-request",
    "transfer-clear-suppressed": "buffer-transfer-next-cycle-clear",
    "cancel-authority-token-high-truncate": "buffer-selective-cancel",
    "cancel-suppressed": "buffer-selective-cancel",
}
V11O_BASELINE_MARKERS = {
    "[V11O-LEGACY-BIRTH-HOLD][PASS]": 2,
    "[V11O-LEGACY-TRANSFER-SQ-DEATH][PASS]": 1,
    "[V11O-LEGACY-CANCEL-AUTHORITY-DEATH][PASS]": 1,
}
V11P_CHECKPOINT_IRREVOCABLE_WRITE_UNIT_IDS = frozenset(
    {"checkpoint-irrevocable-write-producer"}
)
V11P_CHECKPOINT_IRREVOCABLE_WRITE_SCHEMA = (
    "npc-rv64-v11p-checkpoint-irrevocable-write-semantic-evidence-v1"
)
V11P_PRODUCT_INSTANCES = V11O_PRODUCT_INSTANCES
V11P_REGRESSIONS = V11O_REGRESSIONS
V11P_MUTATION_EXPECTATIONS = {
    "capture-pid-generation-truncate": "store-holder-birth",
    "capture-pid-x": "store-holder-birth",
    "store-launch-suppressed": "store-launch-edge",
    "amo-launch-suppressed": "amo-launch-edge",
    "terminal-clears-holder": "store-post-terminal-holder",
    "terminal-corrupts-pid": "store-post-terminal-holder",
    "live-mask-omits-holder": "store-holder-birth",
    "retire-suppressed": "store-exact-retire-edge",
    "retire-compares-index-only": "wrong-generation-retire-guard",
    "restore-gate-omits-holder": "amo-restore-gate",
}
V11P_BASELINE_MARKERS = {
    "[V11P-STORE-LIFECYCLE][PASS]": 1,
    "[V11P-AMO-LIFECYCLE][PASS]": 1,
    "[V11P-WRONG-GENERATION-RETIRE-GUARD][PASS]": 1,
}
V11Q_INT_LANE0_PACKET_UNIT_IDS = frozenset(
    {
        "integer-ex0-packed-alias",
        "integer-ex0-packet",
        "branch-resolve-packet",
    }
)
V11Q_INT_LANE0_PACKET_SCHEMA = (
    "npc-rv64-v11q-int-lane0-packet-semantic-evidence-v1"
)
V11Q_PRODUCT_INSTANCES = V11P_PRODUCT_INSTANCES
V11Q_REGRESSIONS = V11P_REGRESSIONS
V11Q_MUTATION_EXPECTATIONS = {
    "ex0-pack-generation-zero": "alu-down-packet-pid",
    "ex0-pack-index-zero": "alu-down-packet-pid",
    "ex0-pack-result-zero": "alu-down-result",
    "ex0-alias-generation-zero": "alu-down-alias-pid",
    "ex0-alias-index-zero": "alu-down-alias-pid",
    "ex0-capture-suppressed": "alu-up-packet",
    "ex0-preauth-omits-flush": "ex0-flush-cut",
    "branch-pack-generation-zero": "branch-down-pid",
    "branch-pack-index-zero": "branch-down-pid",
    "branch-pack-pc-zero": "branch-down-payload",
    "branch-coherence-index-only": "branch-wrong-generation-fence",
    "branch-candidate-omits-flush": "branch-flush-cut",
}
V11Q_MUTATION_UNIT_EXPECTATIONS = {
    "ex0-pack-generation-zero": frozenset({"integer-ex0-packet"}),
    "ex0-pack-index-zero": frozenset({"integer-ex0-packet"}),
    "ex0-pack-result-zero": frozenset({"integer-ex0-packet"}),
    "ex0-alias-generation-zero": frozenset(
        {"integer-ex0-packed-alias"}
    ),
    "ex0-alias-index-zero": frozenset(
        {"integer-ex0-packed-alias"}
    ),
    "ex0-capture-suppressed": frozenset({"integer-ex0-packet"}),
    "ex0-preauth-omits-flush": frozenset({"integer-ex0-packet"}),
    "branch-pack-generation-zero": frozenset(
        {"branch-resolve-packet"}
    ),
    "branch-pack-index-zero": frozenset({"branch-resolve-packet"}),
    "branch-pack-pc-zero": frozenset({"branch-resolve-packet"}),
    "branch-coherence-index-only": frozenset(
        {"branch-resolve-packet"}
    ),
    "branch-candidate-omits-flush": frozenset(
        {"branch-resolve-packet"}
    ),
}
V11Q_BASELINE_MARKERS = {
    "[V11Q-EX0-PACKET][PASS]": 1,
    "[V11Q-BRANCH-PAIR][PASS]": 1,
    "[V11Q-DEATH-EDGES][PASS]": 1,
}
V11R_INT_LANE1_PACKET_UNIT_IDS = frozenset(
    {
        "integer-ex1-packed-alias",
        "integer-ex1-packet",
    }
)
V11R_INT_LANE1_PACKET_SCHEMA = (
    "npc-rv64-v11r-int-lane1-packet-semantic-evidence-v1"
)
V11R_PRODUCT_INSTANCES = V11Q_PRODUCT_INSTANCES
V11R_REGRESSIONS = V11Q_REGRESSIONS
V11R_MUTATION_EXPECTATIONS = {
    "ex1-pack-generation-zero": "alu-down-packet-pid",
    "ex1-pack-index-zero": "alu-down-packet-pid",
    "ex1-pack-result-zero": "alu-down-payload",
    "ex1-pack-pdest-zero": "alu-down-payload",
    "ex1-alias-generation-zero": "alu-down-alias-pid",
    "ex1-alias-index-zero": "alu-down-alias-pid",
    "ex1-capture-suppressed": "alu-up-packet",
    "ex1-local-capture-suppressed": "local-up-packet",
    "ex1-local-source-uses-iq-identity": "local-up-packet",
    "ex1-local-exception-suppressed": "local-up-exception",
    "ex1-local-tval-zero": "local-up-tval",
    "ex1-preauth-omits-flush": "ex1-flush-cut",
    "ex1-completion-bypasses-exact-open": (
        "alu-wrong-generation-authorization"
    ),
    "ex1-same-edge-claim-index-only": (
        "same-index-wrong-generation-fence"
    ),
}
V11R_MUTATION_UNIT_EXPECTATIONS = {
    name: frozenset({"integer-ex1-packet"})
    for name in V11R_MUTATION_EXPECTATIONS
}
V11R_MUTATION_UNIT_EXPECTATIONS.update(
    {
        "ex1-alias-generation-zero": frozenset(
            {"integer-ex1-packed-alias"}
        ),
        "ex1-alias-index-zero": frozenset(
            {"integer-ex1-packed-alias"}
        ),
    }
)
V11R_BASELINE_MARKERS = {
    "[V11R-EX1-ALU-PACKET][PASS]": 1,
    "[V11R-EX1-LOCAL-PACKET][PASS]": 1,
    "[V11R-EX1-AUTH-EDGES][PASS]": 1,
    "[V11R-EX1-DEATH-EDGES][PASS]": 1,
}
V11S_MULDIV_PRODUCER_UNIT_IDS = frozenset({"muldiv-producer"})
V11S_MULDIV_PRODUCER_SCHEMA = (
    "npc-rv64-v11s-muldiv-producer-semantic-evidence-v1"
)
V11S_PRODUCT_INSTANCES = frozenset(
    {
        (
            "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
            "u_decode_backend.u_int_backend.u_muldiv_unit"
        )
    }
)
V11S_REGRESSIONS = frozenset(
    {
        "tb_ooo_muldiv_unit",
        "tb_ooo_int_backend",
        "tb_ooo_int_backend_v11r_int_lane1_packet",
        "tb_ooo_int_backend_v11i_terminal_lifecycle",
    }
)
V11S_MUTATION_EXPECTATIONS = {
    "request-valid-suppressed": "request-buffer-birth",
    "request-generation-truncated": "request-buffer-birth",
    "request-index-zeroed": "request-buffer-birth",
    "owner-live-mask-generation-truncated": (
        "iterative-hold-live-mask"
    ),
    "completion-query-generation-truncated": "terminal-authorization",
    "completion-bypasses-exact-open": (
        "wrong-generation-authorization"
    ),
    "response-ready-disconnected": "terminal-release",
    "wb0-producer-generation-truncated": "terminal-wb-identity",
    "flush-cut-disconnected": "flush-death",
}
V11S_BASELINE_MARKERS = {
    "[V11S-MULDIV-BIRTH][PASS]": 2,
    "[V11S-MULDIV-HOLD][PASS]": 2,
    "[V11S-MULDIV-WRONG-GEN][PASS]": 2,
    "[V11S-MULDIV-TERMINAL][PASS]": 2,
    "[V11S-MULDIV-FLUSH][PASS]": 1,
    "[V8N-ACTIVATION]": 2,
    "[V8N-MULDIV-8-YOUNGER]": 2,
}
V11S_BASE_TESTBENCH = (
    "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
)
V11S_FOCUSED_FRAGMENT = (
    "npc/rv64/testbench/tests/"
    "tb_ooo_int_backend_v11s_muldiv_producer.svh"
)
V11S_TASK_INSERT_ANCHOR = "`ifdef V11Q_INT_LANE0_PACKET_FOCUSED\n"
V11S_INITIAL_INSERT_ANCHOR = (
    "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
    "    run_hist_ser_qh_younger_store_cycle();\n"
    "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
)
V11S_FINISH_INSERT_ANCHOR = (
    "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
    '        tb_finish("tb_ooo_int_backend_hist_ser_qh_younger_store");\n'
    "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
)
V11T_CLMUL_PRODUCER_UNIT_IDS = frozenset({"clmul-producer"})
V11T_CLMUL_PRODUCER_SCHEMA = (
    "npc-rv64-v11t-clmul-producer-semantic-evidence-v1"
)
V11T_PRODUCT_INSTANCES = frozenset(
    {
        (
            "NpcTop.u_core.u_ooo_core.u_execute_backend.u_core_slice."
            "u_decode_backend.u_int_backend.u_clmul_unit"
        )
    }
)
V11T_REGRESSIONS = frozenset(
    {
        "tb_ooo_clmul_unit",
        "tb_ooo_int_backend",
        "tb_ooo_int_backend_v11r_int_lane1_packet",
        "tb_ooo_int_backend_v11i_terminal_lifecycle",
    }
)
V11T_MUTATION_EXPECTATIONS = dict(V11S_MUTATION_EXPECTATIONS)
V11T_BASELINE_MARKERS = {
    "[V11T-CLMUL-BIRTH][PASS]": 2,
    "[V11T-CLMUL-HOLD][PASS]": 2,
    "[V11T-CLMUL-WRONG-GEN][PASS]": 2,
    "[V11T-CLMUL-TERMINAL][PASS]": 2,
    "[V11T-CLMUL-FLUSH][PASS]": 1,
}
V11T_BASE_TESTBENCH = V11S_BASE_TESTBENCH
V11T_FOCUSED_FRAGMENT = (
    "npc/rv64/testbench/tests/"
    "tb_ooo_int_backend_v11t_clmul_producer.svh"
)
V11T_ARTIFACT_CLEANUP = (
    ".github/task-runs/2026-07-31-rv64-v11t-clmul-producer-semantic/"
    "evidence/attempt-2/artifact-cleanup.json"
)
V11T_TASK_INSERT_ANCHOR = V11S_TASK_INSERT_ANCHOR
V11T_INITIAL_INSERT_ANCHOR = V11S_INITIAL_INSERT_ANCHOR
V11T_FINISH_INSERT_ANCHOR = V11S_FINISH_INSERT_ANCHOR
V11U_PENDING_SYSTEM_PRODUCER_UNIT_IDS = frozenset(
    {"pending-system-producer"}
)
V11U_PENDING_SYSTEM_PRODUCER_SCHEMA = (
    "npc-rv64-v11u-pending-system-producer-semantic-evidence-v1"
)
V11U_PRODUCT_INSTANCES = frozenset(
    {
        (
            "NpcTop.u_core.u_ooo_core.u_control_plane."
            "u_pending_system_sequencer"
        )
    }
)
V11U_ARTIFACT_CLEANUP = (
    ".github/task-runs/2026-07-31-rv64-v11u-"
    "pending-system-producer-semantic/evidence/attempt-2/"
    "artifact-cleanup.json"
)
V11U_REGRESSIONS = (
    "tb_ooo_pending_system_sequencer",
    "tb_ooo_csr_access_request_mux",
    "tb_ooo_pending_system_admission_cancel_gate",
    "tb_ooo_pending_drain_resolve_gate",
)
V11U_POSITIVE_PROFILES = {
    "sequencer-mux-g1-release": {
        "tests": (
            "tb_ooo_pending_system_sequencer",
            "tb_ooo_csr_access_request_mux",
        ),
        "width": 1,
        "assertions": False,
        "defines": ("-DOOO_PRODUCER_GEN_W=1",),
        "markers": (("tb_ooo_pending_system_sequencer", "[V9W-SERIAL-KIND-MATRIX]", 1),),
    },
    "sequencer-mux-g1-assert": {
        "tests": (
            "tb_ooo_pending_system_sequencer",
            "tb_ooo_csr_access_request_mux",
        ),
        "width": 1,
        "assertions": True,
        "defines": ("-DOOO_PRODUCER_GEN_W=1", "-DOOO_ASSERT"),
        "markers": (("tb_ooo_pending_system_sequencer", "[V9W-SERIAL-KIND-MATRIX]", 1),),
    },
    "sequencer-mux-g4-release": {
        "tests": (
            "tb_ooo_pending_system_sequencer",
            "tb_ooo_csr_access_request_mux",
        ),
        "width": 4,
        "assertions": False,
        "defines": ("-DOOO_PRODUCER_GEN_W=4",),
        "markers": (("tb_ooo_pending_system_sequencer", "[V9W-SERIAL-KIND-MATRIX]", 1),),
    },
    "sequencer-mux-g4-assert": {
        "tests": (
            "tb_ooo_pending_system_sequencer",
            "tb_ooo_csr_access_request_mux",
        ),
        "width": 4,
        "assertions": True,
        "defines": ("-DOOO_PRODUCER_GEN_W=4", "-DOOO_ASSERT"),
        "markers": (("tb_ooo_pending_system_sequencer", "[V9W-SERIAL-KIND-MATRIX]", 1),),
    },
    "int-live-mask-g4-release": {
        "tests": ("tb_ooo_int_backend",),
        "width": 4,
        "assertions": False,
        "defines": (
            "-DOOO_PRODUCER_GEN_W=4",
            "-DV8K_PENDING_CSR_LEASE_FOCUSED",
        ),
        "markers": (("tb_ooo_int_backend", "[V8K-PENDING-CSR-LEASE]", 1),),
    },
    "raw-lease-partial-metadata-g4-release": {
        "tests": ("tb_ooo_pending_system_lease_probe",),
        "width": 4,
        "assertions": False,
        "defines": (
            "-DOOO_PRODUCER_GEN_W=4",
            "-DV8K_PROBE_PARTIAL_METADATA",
        ),
        "markers": (("tb_ooo_pending_system_lease_probe", "[V11U-RAW-LEASE-PARTIAL-METADATA][PASS]", 1),),
    },
    "raw-lease-ordinary-clear-g4-release": {
        "tests": ("tb_ooo_pending_system_lease_probe",),
        "width": 4,
        "assertions": False,
        "defines": (
            "-DOOO_PRODUCER_GEN_W=4",
            "-DV8K_PROBE_LIVE_CLEAR",
        ),
        "markers": (("tb_ooo_pending_system_lease_probe", "[V11U-RAW-LEASE-ORDINARY-CLEAR-HOLD][PASS]", 1),),
    },
    "raw-lease-clear-dispatched-g4-release": {
        "tests": ("tb_ooo_pending_system_lease_probe",),
        "width": 4,
        "assertions": False,
        "defines": (
            "-DOOO_PRODUCER_GEN_W=4",
            "-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",
        ),
        "markers": (("tb_ooo_pending_system_lease_probe", "[V11U-RAW-LEASE-CDISP-HOLD][PASS]", 1),),
    },
    "noncsr-dispatch-g4-release": {
        "tests": ("tb_ooo_pending_system_lease_probe",),
        "width": 4,
        "assertions": False,
        "defines": (
            "-DOOO_PRODUCER_GEN_W=4",
            "-DV11U_PROBE_NONCSR_DISPATCH",
        ),
        "markers": (("tb_ooo_pending_system_lease_probe", "[V11U-PROBE-NONCSR-DISPATCH] PASS", 1),),
    },
}
V11U_ASSERTION_PROFILES = {
    "assert-partial-metadata-g4": {
        "marker": "[V8K-PENDING-CSR-LEASE-SHAPE]",
        "define": "-DV8K_ASSERT_PARTIAL_METADATA",
    },
    "assert-live-clear-g4": {
        "marker": "[V8K-PENDING-CSR-NO-RECAPTURE]",
        "define": "-DV8K_ASSERT_LIVE_CLEAR",
    },
    "assert-noncsr-dispatch-g4": {
        "marker": "[V8K-PENDING-CSR-DISPATCH-BIRTH]",
        "define": "-DV11U_ASSERT_NONCSR_DISPATCH",
    },
}
V11U_MUTATIONS = {
    "lease-output-metadata-gated": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_lease_probe",
        "widths": (4,),
        "marker": "[V8K-PROBE-PARTIAL-METADATA]",
        "defines": ("-DV8K_PROBE_PARTIAL_METADATA",),
    },
    "ordinary-clear-kills-live": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_lease_probe",
        "widths": (4,),
        "marker": "[V8K-PROBE-LIVE-CLEAR]",
        "defines": ("-DV8K_PROBE_LIVE_CLEAR",),
    },
    "clear-dispatched-kills-live": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_lease_probe",
        "widths": (4,),
        "marker": "[V8K-PROBE-LIVE-CDISP]",
        "defines": ("-DV8K_PROBE_LIVE_CLEAR_DISPATCHED",),
    },
    "birth-drops-generation": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_sequencer",
        "widths": (1, 4),
        "marker": "FAIL head0 lease pid",
        "defines": (),
    },
    "noncsr-dispatch-birth-widened": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_lease_probe",
        "widths": (4,),
        "marker": "[V11U-PROBE-NONCSR-DISPATCH]",
        "defines": ("-DV11U_PROBE_NONCSR_DISPATCH",),
    },
    "exact-death-disabled": {
        "target": "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
        "override": "RTL_OOO_PENDING_SYSTEM_SEQUENCER",
        "test": "tb_ooo_pending_system_sequencer",
        "widths": (4,),
        "marker": "ordinary clear cross dispatched",
        "defines": (),
    },
    "claim-seal-ignores-raw": {
        "target": "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v",
        "override": "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "test": "tb_ooo_csr_access_request_mux",
        "widths": (4,),
        "marker": "FAIL core=",
        "defines": ("-DOOO_CSR_QUEUE_HEAD=1",),
    },
    "pid-match-ignores-generation": {
        "target": "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v",
        "override": "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "test": "tb_ooo_csr_access_request_mux",
        "widths": (1, 4),
        "marker": "FAIL core=",
        "defines": (),
    },
    "pc-coherence-removed": {
        "target": "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v",
        "override": "RTL_OOO_CSR_ACCESS_REQUEST_MUX",
        "test": "tb_ooo_csr_access_request_mux",
        "widths": (4,),
        "marker": "FAIL core=",
        "defines": (),
    },
    "pending-live-mask-removed": {
        "target": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "override": "RTL_OOO_INT_BACKEND",
        "test": "tb_ooo_int_backend",
        "widths": (4,),
        "marker": "v8k pending lease reaches full holder census",
        "defines": ("-DV8K_PENDING_CSR_LEASE_FOCUSED",),
    },
}
V11H_REPLAY_SCHEMA = "rv64-v11h-load-queue-attempt4-checker-replay-v2"
V11H_REPLAY_STATUS = (
    "FAIL rc=1 stage=semantic-ledger-unit "
    "evidence_complete=0 cleanup_rc=0"
)
CENSUS_SCHEMA = "rv64-producer-holder-census-v1"
INSTANCE_SCHEMA = "rv64-producer-holder-instance-graph-v1"
UNIT_COLLECTIONS = (
    "direct_full_p_fields",
    "packed_full_p_stages",
    "token_q_fields",
    "token_set_holders",
    "generation_authorities",
)
CURRENT_BINDINGS = {
    "CURRENT_FULL_RTL_BOUND",
    "CURRENT_SELECTED_SOURCE_AND_TB_BOUND",
}
NON_SEMANTIC_ORCHESTRATION_PATHS = frozenset(
    {"npc/rv64/testbench/Makefile"}
)
DESIGN_ID_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
V11_SELECTED_BINDINGS = {
    "v11b_terminal_collector": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_terminal_collector.sv",
            "testbench",
        ),
    },
    "v11c_memory_tracker": {
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_mem_owner_tracker.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_tracker_semantic_checker.sv",
            "testbench",
        ),
    },
    "v11d_memory_tracker_cursor": {
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_mem_owner_tracker_cursor.sv",
            "testbench",
        ),
    },
    "v11e_rob_slot_generation": {
        ("npc/rv64/vsrc/writeback/OooRob.v", "rtl"),
        ("npc/rv64/vsrc/writeback/OooArchRegFile.v", "rtl"),
        ("npc/rv64/vsrc/control/OooCsrTrapRequestMux.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        ("npc/rv64/testbench/tests/tb_ooo_rob.sv", "testbench"),
    },
    "v11f_int_iq_producer": {
        ("npc/rv64/vsrc/scheduling/OooIntIssueQueue.v", "rtl"),
        ("npc/rv64/vsrc/scheduling/OooIntIssueSelect8.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_issue_queue.sv",
            "testbench",
        ),
    },
    "v11g_store_queue_holder": {
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_store_queue.sv",
            "testbench",
        ),
    },
    "v11h_load_queue_producer": {
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_load_queue_producer_semantic.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/tb_ooo_load_queue.sv",
            "testbench",
        ),
    },
    "v11j_bridge_holder": {
        ("npc/rv64/vsrc/memory/OooMemAxiBridge.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_dual_mem_bridge_wrapper.sv",
            "testbench",
        ),
    },
    "v11k_miq_holder": {
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_dual_mem_inflight_queue_semantic.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/tb_ooo_mem_inflight_queue.sv",
            "testbench",
        ),
    },
    "v11l_memory_retry_holder": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11m_memory_reservation_holder": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11n_memory_pending_holder": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11o_memory_buffer_token": {
        ("npc/rv64/vsrc/core/NpcCoreTop.v", "rtl"),
        ("npc/rv64/vsrc/core/OooCoreTopGlue.v", "rtl"),
        ("npc/rv64/vsrc/execute/OooExecuteBackend.v", "rtl"),
        ("npc/rv64/vsrc/execute/OooAluCoreSlice.v", "rtl"),
        ("npc/rv64/vsrc/decode/OooAluDecodeBackend.v", "rtl"),
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11p_checkpoint_irrevocable_write": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooLoadQueue.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooMemInflightQueue.v", "rtl"),
        (
            "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/memory/OooMemOwnerTracker.v", "rtl"),
        ("npc/rv64/vsrc/memory/OooStoreQueue.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11q_int_lane0_packet": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/pipeline/PipeStageReg.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11r_int_lane1_packet": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/pipeline/PipeStageReg.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
    "v11s_muldiv_producer": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/execute/OooMulDivUnit.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_int_backend_v11s_muldiv_producer.svh",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/tb_ooo_muldiv_unit.sv",
            "testbench",
        ),
    },
    "v11t_clmul_producer": {
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        ("npc/rv64/vsrc/execute/OooClmulUnit.v", "rtl"),
        ("npc/rv64/vsrc/include/define.v", "rtl"),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_int_backend_v11t_clmul_producer.svh",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv",
            "testbench",
        ),
    },
    "v11u_pending_system_producer": {
        (
            "npc/rv64/vsrc/control/OooPendingSystemSequencer.v",
            "rtl",
        ),
        (
            "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v",
            "rtl",
        ),
        ("npc/rv64/vsrc/execute/OooIntBackend.v", "rtl"),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_pending_system_sequencer.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_pending_system_lease_probe.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/"
            "tb_ooo_csr_access_request_mux.sv",
            "testbench",
        ),
        (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv",
            "testbench",
        ),
    },
}
V11H_REPLAY_CURRENT_FILES = {
    "semantic_checker": (
        "npc/rv64/eval/ppa/tools/"
        "producer_holder_semantic_coverage.py"
    ),
    "semantic_checker_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_producer_holder_semantic_coverage.py"
    ),
    "semantic_policy": (
        "npc/rv64/design/arch/"
        "producer-holder-semantic-coverage-policy.json"
    ),
    "load_queue_evidence_checker": (
        "npc/rv64/eval/ppa/tools/"
        "load_queue_producer_semantic_evidence.py"
    ),
    "load_queue_evidence_checker_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_load_queue_producer_semantic_evidence.py"
    ),
    "checker_replay_builder": (
        "npc/rv64/eval/ppa/tools/"
        "load_queue_producer_checker_replay.py"
    ),
    "checker_replay_builder_tests": (
        "npc/rv64/eval/ppa/tests/"
        "test_load_queue_producer_checker_replay.py"
    ),
    "producer_holder_census": (
        "npc/rv64/design/arch/producer-holder-census.json"
    ),
    "current_instance_graph_result": (
        ".github/task-runs/2026-07-31-rv64-"
        "axi-xbar-naming-refresh/evidence/"
        "current-holder-instance-graph/"
        "holder-instance-graph.json"
    ),
    "current_instance_graph_receipt": (
        ".github/task-runs/2026-07-31-rv64-"
        "axi-xbar-naming-refresh/evidence/"
        "current-holder-instance-graph/"
        "yosys-instance-graph-receipt.json"
    ),
    "current_instance_graph_audit": (
        ".github/task-runs/2026-07-31-rv64-v11t-"
        "clmul-producer-semantic/evidence/"
        "current-instance-graph-audit/"
        "instance-graph-frozen-audit.json"
    ),
    "producer_holder_instance_graph_tool": (
        "npc/rv64/eval/ppa/tools/producer_holder_instance_graph.py"
    ),
    "producer_holder_instance_graph_tests": (
        "npc/rv64/eval/ppa/tests/test_producer_holder_instance_graph.py"
    ),
    "producer_holder_census_tool": (
        "npc/rv64/eval/ppa/tools/producer_holder_census.py"
    ),
    "producer_holder_census_tests": (
        "npc/rv64/eval/ppa/tests/test_producer_holder_census.py"
    ),
}


class CoverageError(RuntimeError):
    """Raised when an evidence or inventory contract is not auditable."""


@functools.lru_cache(maxsize=256)
def _decode_json_cached(
    path_value: str,
    raw: bytes,
) -> dict[str, Any]:
    try:
        payload = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise CoverageError(
            f"cannot read JSON {path_value}: {exc}"
        ) from exc
    if not isinstance(payload, dict):
        raise CoverageError(f"JSON root must be an object: {path_value}")
    return payload


def load_json(path: pathlib.Path) -> dict[str, Any]:
    resolved = path.resolve()
    try:
        raw = resolved.read_bytes()
    except OSError as exc:
        raise CoverageError(f"cannot read JSON {resolved}: {exc}") from exc
    # Cache decoding by the exact bytes, not timestamps: WSL may coalesce
    # timestamps for an immediate same-size rewrite.
    return _decode_json_cached(str(resolved), raw)


_ACTIVE_FILE_SHA_CACHE: dict[str, str] | None = None


def sha256_file(path: pathlib.Path) -> str:
    cache_key = str(path.absolute())
    if (
        _ACTIVE_FILE_SHA_CACHE is not None
        and cache_key in _ACTIVE_FILE_SHA_CACHE
    ):
        return _ACTIVE_FILE_SHA_CACHE[cache_key]
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    result = digest.hexdigest()
    if _ACTIVE_FILE_SHA_CACHE is not None:
        _ACTIVE_FILE_SHA_CACHE[cache_key] = result
    return result


@functools.lru_cache(maxsize=16384)
def _relative_cached(root_value: str, path_value: str) -> str:
    root = pathlib.Path(root_value).resolve()
    path = pathlib.Path(path_value).resolve()
    try:
        return path.relative_to(root).as_posix()
    except ValueError as exc:
        raise CoverageError(f"path escapes repository root: {path}") from exc


def relative(root: pathlib.Path, path: pathlib.Path) -> str:
    return _relative_cached(str(root), str(path))


@functools.lru_cache(maxsize=16384)
def _resolve_repo_path_cached(root_value: str, value: str) -> str:
    root = pathlib.Path(root_value).resolve()
    path = (root / value).resolve()
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise CoverageError(f"path escapes repository root: {path}") from exc
    return str(path)


def resolve_repo_path(root: pathlib.Path, value: str) -> pathlib.Path:
    if not isinstance(value, str) or not value:
        raise CoverageError("repository path must be a non-empty string")
    return pathlib.Path(_resolve_repo_path_cached(str(root), value))


def stale_manifest_paths(
    root: pathlib.Path,
    manifest: dict[str, str],
    candidates: Iterable[str] | None = None,
) -> list[str]:
    selected = set(manifest) if candidates is None else set(candidates)
    return sorted(
        path_value
        for path_value in selected
        if path_value not in NON_SEMANTIC_ORCHESTRATION_PATHS
        and path_value in manifest
        and (
            not resolve_repo_path(root, path_value).is_file()
            or sha256_file(resolve_repo_path(root, path_value))
            != manifest[path_value]
        )
    )


def artifact(root: pathlib.Path, value: str) -> dict[str, Any]:
    path = resolve_repo_path(root, value)
    if not path.is_file():
        raise CoverageError(f"evidence artifact is missing: {value}")
    return {
        "path": relative(root, path),
        "sha256": sha256_file(path),
        "size_bytes": path.stat().st_size,
    }


def current_design_id(root: pathlib.Path) -> str:
    tools = root / "npc/rv64/eval/ppa/tools"
    sys.path.insert(0, str(tools))
    try:
        import architecture_hard_gates as architecture
    finally:
        sys.path.pop(0)
    digest, _ = architecture.rtl_binding(root)
    return f"sha256:{digest}"


def validate_snapshot(
    root: pathlib.Path,
    payload: dict[str, Any],
    expected_design_id: str,
) -> list[str]:
    if payload.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1":
        raise CoverageError("V8L RTL snapshot schema mismatch")
    if payload.get("design_id") != expected_design_id:
        raise CoverageError("V8L RTL snapshot design-id is stale")
    rtl_files = payload.get("rtl_files")
    if not isinstance(rtl_files, dict) or not rtl_files:
        raise CoverageError("V8L RTL snapshot has no source records")
    mismatches: list[str] = []
    for value, expected in sorted(rtl_files.items()):
        path = resolve_repo_path(root, value)
        if not path.is_file() or sha256_file(path) != expected:
            mismatches.append(value)
    return mismatches


def valid_design_id(value: Any) -> bool:
    return isinstance(value, str) and DESIGN_ID_RE.fullmatch(value) is not None


def parse_key_value_log(path: pathlib.Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
    return result


def evaluate_v8l(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    pre_path = resolve_repo_path(root, spec["snapshot_pre"])
    post_path = resolve_repo_path(root, spec["snapshot_post"])
    lifecycle_path = resolve_repo_path(root, spec["lifecycle_log"])
    mutation_path = resolve_repo_path(root, spec["mutation_summary"])
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V8L pre/post full RTL snapshots differ")
    evidence_design_id = pre.get("design_id")
    if not valid_design_id(evidence_design_id):
        raise CoverageError("V8L evidence design-id is malformed")
    mismatches = validate_snapshot(root, pre, evidence_design_id)
    lifecycle = parse_key_value_log(lifecycle_path)
    required_lines = {
        "V8L-INTIQ-DEATH-EDGE PASS",
        "V8L-FINITE-GENERATION-WRAP PASS",
        "V8L-TRANSIENT-HOLDER-CENSUS PASS",
        "V8L-MEM-HANDOFF-BACKPRESSURE PASS",
        "V8L-MEM-INDIRECT-TRACKER PASS",
    }
    lifecycle_lines = set(
        lifecycle_path.read_text(encoding="utf-8").splitlines()
    )
    missing_markers = sorted(required_lines - lifecycle_lines)
    mutation = load_json(mutation_path)
    mutation_ok = (
        mutation.get("design_id") == evidence_design_id
        and mutation.get("compile_success") == 9
        and mutation.get("rejected") == 9
        and len(mutation.get("mutations", [])) == 9
        and all(
            item.get("compiled") is True and item.get("rejected") is True
            for item in mutation.get("mutations", [])
            if isinstance(item, dict)
        )
    )
    if (
        missing_markers
        or lifecycle.get("design_id") != evidence_design_id
        or lifecycle.get("source_binding_status") != "PASS"
        or not mutation_ok
    ):
        raise CoverageError(
            "V8L current evidence failed provenance validation: "
            f"rtl_mismatches={mismatches} missing_markers={missing_markers} "
            f"mutation_ok={mutation_ok}"
        )
    artifacts = [
        artifact(root, spec["snapshot_pre"]),
        artifact(root, spec["snapshot_post"]),
        artifact(root, spec["lifecycle_log"]),
        artifact(root, spec["mutation_summary"]),
    ]
    detail = {
        "rtl_file_count": len(pre["rtl_files"]),
        "marker_count": len(required_lines),
        "compile_success_mutations": 9,
        "rejected_mutations": 9,
        "evidence_design_id": evidence_design_id,
        "current_design_id": design_id,
        "live_rtl_mismatches": mismatches,
    }
    state = (
        "CURRENT_FULL_RTL_BOUND"
        if evidence_design_id == design_id and not mismatches
        else "HISTORICAL_FULL_RTL_BOUND"
    )
    return state, artifacts, detail


def evaluate_v9r(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    if not isinstance(source_binding, dict):
        raise CoverageError("V9R summary lacks source binding")
    files = source_binding.get("files")
    if not isinstance(files, dict) or not files:
        raise CoverageError("V9R source binding has no files")
    mismatches: list[str] = []
    for key, record in sorted(files.items()):
        if not isinstance(record, dict) or record.get("path") != key:
            raise CoverageError(f"V9R malformed source record: {key}")
        path = resolve_repo_path(root, key)
        if (
            not path.is_file()
            or sha256_file(path) != record.get("sha256")
            or path.stat().st_size != record.get("size_bytes")
        ):
            mismatches.append(key)
    variants = payload.get("compile_success_rtl_variants")
    baseline = payload.get("baseline")
    result_ok = (
        payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and isinstance(baseline, dict)
        and baseline.get("required") == 2
        and baseline.get("passed") == 2
        and isinstance(variants, list)
        and len(variants) == 3
        and all(item.get("result") == "REJECTED" for item in variants)
    )
    if not result_ok:
        raise CoverageError(
            "V9R current evidence failed provenance validation: "
            f"mismatches={mismatches} result_ok={result_ok}"
        )
    state = (
        "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"
        if not mismatches
        else "HISTORICAL_SELECTED_SOURCE_BOUND"
    )
    return (
        state,
        [artifact(root, spec["summary"])],
        {
            "source_file_count": len(files),
            "baseline_passed": 2,
            "compile_success_variants_rejected": 3,
            "evidence_design_id": payload.get("design_id"),
            "current_design_id": design_id,
            "live_source_mismatches": mismatches,
        },
    )


def parse_sha_manifest(
    root: pathlib.Path, path: pathlib.Path
) -> dict[str, str]:
    result: dict[str, str] = {}
    for lineno, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), 1
    ):
        if not line.strip():
            continue
        try:
            digest, raw_path = line.split(None, 1)
        except ValueError as exc:
            raise CoverageError(
                f"malformed sha256 manifest line {path}:{lineno}"
            ) from exc
        candidate = pathlib.Path(raw_path.strip())
        if not candidate.is_absolute():
            candidate = root / candidate
        key = relative(root, candidate)
        if key in result:
            raise CoverageError(f"duplicate sha256 manifest path: {key}")
        result[key] = digest
    return result


def classify_binding_records(
    records: list[dict[str, Any]],
) -> str:
    rtl = [record for record in records if record["role"] == "rtl"]
    non_rtl = [record for record in records if record["role"] != "rtl"]
    rtl_match = all(record["matches_live"] for record in rtl)
    non_rtl_match = all(record["matches_live"] for record in non_rtl)
    if not rtl_match:
        return "STALE_RTL_SOURCE"
    if not non_rtl_match:
        return "RTL_SOURCE_MATCH_TESTBENCH_DRIFT"
    return "CURRENT_SELECTED_SOURCE_AND_TB_BOUND"


def evaluate_sha_manifest(
    root: pathlib.Path,
    spec: dict[str, Any],
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    pre_path = resolve_repo_path(root, spec["manifest_pre"])
    post_path = resolve_repo_path(root, spec["manifest_post"])
    pre = parse_sha_manifest(root, pre_path)
    post = parse_sha_manifest(root, post_path)
    if pre != post:
        raise CoverageError(
            f"historical pre/post source manifests differ: {spec['id']}"
        )
    records: list[dict[str, Any]] = []
    for binding in spec.get("required_bindings", []):
        value = binding.get("path")
        role = binding.get("role")
        if role not in {"rtl", "testbench", "tool", "spec"}:
            raise CoverageError(f"unsupported evidence binding role: {role}")
        path = resolve_repo_path(root, value)
        if value not in pre:
            raise CoverageError(
                f"required path missing from evidence manifest: {value}"
            )
        live = sha256_file(path) if path.is_file() else None
        records.append(
            {
                "path": value,
                "role": role,
                "evidence_sha256": pre[value],
                "live_sha256": live,
                "matches_live": live == pre[value],
            }
        )
    state = classify_binding_records(records)
    return (
        state,
        [artifact(root, spec["manifest_pre"]),
         artifact(root, spec["manifest_post"])],
        {"bindings": records},
    )


def json_value(payload: dict[str, Any], segments: list[str]) -> Any:
    value: Any = payload
    for segment in segments:
        if not isinstance(value, dict) or segment not in value:
            raise CoverageError(
                f"JSON binding path does not exist: {segments}"
            )
        value = value[segment]
    return value


def evaluate_json_declared(
    root: pathlib.Path,
    spec: dict[str, Any],
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    records: list[dict[str, Any]] = []
    for binding in spec.get("required_bindings", []):
        value = binding.get("path")
        role = binding.get("role")
        segments = binding.get("json_path")
        if not isinstance(segments, list) or not all(
            isinstance(segment, str) for segment in segments
        ):
            raise CoverageError("json_path must be a list of strings")
        expected = json_value(payload, segments)
        path = resolve_repo_path(root, value)
        live = sha256_file(path) if path.is_file() else None
        records.append(
            {
                "path": value,
                "role": role,
                "evidence_sha256": expected,
                "live_sha256": live,
                "matches_live": live == expected,
            }
        )
    state = classify_binding_records(records)
    return (
        state,
        [artifact(root, spec["summary"])],
        {"bindings": records},
    )


def verify_artifact_record(
    root: pathlib.Path, record: Any, label: str
) -> pathlib.Path:
    if not isinstance(record, dict):
        raise CoverageError(f"{label} artifact record is not an object")
    value = record.get("path")
    path = resolve_repo_path(root, value)
    if (
        not path.is_file()
        or sha256_file(path) != record.get("sha256")
        or path.stat().st_size != record.get("size_bytes")
    ):
        raise CoverageError(f"{label} artifact hash/size mismatch")
    return path


def verify_path_sha(
    root: pathlib.Path,
    path_value: Any,
    expected_sha256: Any,
    label: str,
) -> pathlib.Path:
    path = resolve_repo_path(root, path_value)
    if (
        not isinstance(expected_sha256, str)
        or not path.is_file()
        or sha256_file(path) != expected_sha256
    ):
        raise CoverageError(f"{label} artifact hash mismatch")
    return path


def validate_current_manifest_selected_binding(
    root: pathlib.Path,
    spec: dict[str, Any],
    manifest_pre_path: pathlib.Path,
    manifest_post_path: pathlib.Path,
) -> tuple[str, list[dict[str, Any]], dict[str, str]]:
    kind = spec.get("binding_kind")
    expected = V11_SELECTED_BINDINGS.get(kind)
    if expected is None:
        raise CoverageError(
            f"manifest-selected compatibility is unsupported for {kind}"
        )
    declared = spec.get("current_selected_bindings")
    if not isinstance(declared, list):
        raise CoverageError(
            f"{kind} current_selected_bindings must be a list"
        )
    normalized: set[tuple[str, str]] = set()
    for index, binding in enumerate(declared):
        if not isinstance(binding, dict) or set(binding) != {"path", "role"}:
            raise CoverageError(
                f"{kind} selected binding {index} must contain path/role"
            )
        path_value = binding.get("path")
        role = binding.get("role")
        if (
            not isinstance(path_value, str)
            or role not in {"rtl", "testbench"}
            or (path_value, role) in normalized
        ):
            raise CoverageError(
                f"{kind} selected binding {index} is invalid or duplicated"
            )
        normalized.add((path_value, role))
    if normalized != expected:
        raise CoverageError(
            f"{kind} current selected RTL/TB binding set is incomplete"
        )

    manifest_pre = parse_sha_manifest(root, manifest_pre_path)
    manifest_post = parse_sha_manifest(root, manifest_post_path)
    if manifest_pre != manifest_post:
        raise CoverageError(f"{kind} focused pre/post manifests differ")
    records: list[dict[str, Any]] = []
    for path_value, role in sorted(expected):
        if path_value not in manifest_pre:
            raise CoverageError(
                f"{kind} selected path is missing from focused manifest: "
                f"{path_value}"
            )
        live_path = resolve_repo_path(root, path_value)
        live_sha = sha256_file(live_path) if live_path.is_file() else None
        records.append(
            {
                "path": path_value,
                "role": role,
                "evidence_sha256": manifest_pre[path_value],
                "live_sha256": live_sha,
                "matches_live": live_sha == manifest_pre[path_value],
            }
        )
    state = classify_binding_records(records)
    if state != "CURRENT_SELECTED_SOURCE_AND_TB_BOUND":
        raise CoverageError(
            f"{kind} selected RTL/TB source closure is stale: {state}"
        )
    return state, records, manifest_pre


def validate_current_selected_binding(
    root: pathlib.Path,
    spec: dict[str, Any],
    snapshot: dict[str, Any],
    evidence_design_id: str,
    current_design_id_value: str,
    manifest_pre_path: pathlib.Path,
    manifest_post_path: pathlib.Path,
) -> tuple[str, list[dict[str, Any]]]:
    kind = spec.get("binding_kind")
    expected = V11_SELECTED_BINDINGS.get(kind)
    if expected is None:
        raise CoverageError(
            f"selected-source compatibility is unsupported for {kind}"
        )
    declared = spec.get("current_selected_bindings")
    if not isinstance(declared, list):
        raise CoverageError(
            f"{kind} current_selected_bindings must be a list"
        )
    normalized: set[tuple[str, str]] = set()
    for index, binding in enumerate(declared):
        if not isinstance(binding, dict) or set(binding) != {"path", "role"}:
            raise CoverageError(
                f"{kind} selected binding {index} must contain path/role"
            )
        path_value = binding.get("path")
        role = binding.get("role")
        if (
            not isinstance(path_value, str)
            or role not in {"rtl", "testbench"}
            or (path_value, role) in normalized
        ):
            raise CoverageError(
                f"{kind} selected binding {index} is invalid or duplicated"
            )
        normalized.add((path_value, role))
    if normalized != expected:
        raise CoverageError(
            f"{kind} current selected RTL/TB binding set is incomplete"
        )

    if snapshot.get("schema") != "npc-rv64-v8l-rtl-source-binding-v1":
        raise CoverageError(f"{kind} full RTL snapshot schema mismatch")
    if snapshot.get("design_id") != evidence_design_id:
        raise CoverageError(
            f"{kind} summary and full RTL snapshot design-id differ"
        )
    snapshot_files = snapshot.get("rtl_files")
    if not isinstance(snapshot_files, dict) or not snapshot_files:
        raise CoverageError(f"{kind} full RTL snapshot has no source records")

    manifest_pre = parse_sha_manifest(root, manifest_pre_path)
    manifest_post = parse_sha_manifest(root, manifest_post_path)
    if manifest_pre != manifest_post:
        raise CoverageError(f"{kind} focused pre/post manifests differ")

    records: list[dict[str, Any]] = []
    for path_value, role in sorted(expected):
        if path_value not in manifest_pre:
            raise CoverageError(
                f"{kind} selected path is missing from focused manifest: "
                f"{path_value}"
            )
        evidence_sha = manifest_pre[path_value]
        if (
            path_value in snapshot_files
            and snapshot_files[path_value] != evidence_sha
        ):
            raise CoverageError(
                f"{kind} selected RTL hash differs between focused and "
                f"full-snapshot evidence: {path_value}"
            )
        live_path = resolve_repo_path(root, path_value)
        live_sha = sha256_file(live_path) if live_path.is_file() else None
        records.append(
            {
                "path": path_value,
                "role": role,
                "evidence_sha256": evidence_sha,
                "live_sha256": live_sha,
                "matches_live": live_sha == evidence_sha,
            }
        )

    selected_state = classify_binding_records(records)
    if evidence_design_id == current_design_id_value:
        mismatches = validate_snapshot(
            root, snapshot, current_design_id_value
        )
        if mismatches:
            raise CoverageError(
                f"{kind} current full RTL snapshot drift: {mismatches}"
            )
        return "CURRENT_FULL_RTL_BOUND", records
    if selected_state != "CURRENT_SELECTED_SOURCE_AND_TB_BOUND":
        raise CoverageError(
            f"{kind} selected RTL/TB source closure is stale: "
            f"{selected_state}"
        )
    return selected_state, records


def validate_v11h_checker_replay(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[dict[str, Any], dict[str, Any]]:
    receipt_value = spec.get("checker_replay_receipt")
    receipt_path = resolve_repo_path(root, receipt_value)
    receipt = load_json(receipt_path)
    expected_top_keys = {
        "schema",
        "status",
        "design_id",
        "current_design_id_at_replay",
        "original_design_is_current",
        "current_selected_binding",
        "original_attempt",
        "original_failure",
        "frozen_simulation_evidence",
        "replacement_checker_sources",
        "replay_contract",
        "claim_boundary",
    }
    if (
        set(receipt) != expected_top_keys
        or receipt.get("schema") != V11H_REPLAY_SCHEMA
        or receipt.get("status") != "PASS"
        or not valid_design_id(receipt.get("design_id"))
        or receipt.get("current_design_id_at_replay") != design_id
        or receipt.get("original_design_is_current")
        is not (receipt.get("design_id") == design_id)
        or receipt.get("original_attempt") != 4
    ):
        raise CoverageError("V11H checker-replay receipt is incomplete")
    selected = receipt.get("current_selected_binding")
    selected_records = (
        selected.get("records") if isinstance(selected, dict) else None
    )
    if (
        not isinstance(selected, dict)
        or set(selected)
        != {
            "binding_state",
            "evidence_design_id",
            "current_design_id",
            "records",
        }
        or selected.get("binding_state") not in CURRENT_BINDINGS
        or selected.get("evidence_design_id") != receipt.get("design_id")
        or selected.get("current_design_id") != design_id
        or not isinstance(selected_records, list)
        or {
            (item.get("path"), item.get("role"))
            for item in selected_records
            if isinstance(item, dict)
        }
        != V11_SELECTED_BINDINGS["v11h_load_queue_producer"]
        or any(
            not isinstance(item, dict)
            or set(item)
            != {
                "path",
                "role",
                "evidence_sha256",
                "live_sha256",
                "matches_live",
            }
            or item.get("matches_live") is not True
            or item.get("evidence_sha256") != item.get("live_sha256")
            or sha256_file(
                resolve_repo_path(root, item.get("path"))
            )
            != item.get("live_sha256")
            for item in selected_records
        )
    ):
        raise CoverageError(
            "V11H checker replay current selected binding is incomplete"
        )

    failure = receipt.get("original_failure")
    if (
        not isinstance(failure, dict)
        or set(failure)
        != {"stage", "status_line", "status_artifact", "semantic_log"}
        or failure.get("stage") != "semantic-ledger-unit"
        or failure.get("status_line") != V11H_REPLAY_STATUS
    ):
        raise CoverageError(
            "V11H checker replay does not preserve the original FAIL"
        )
    status_path = verify_artifact_record(
        root, failure.get("status_artifact"), "V11H original status"
    )
    if status_path.read_text(encoding="utf-8").strip() != V11H_REPLAY_STATUS:
        raise CoverageError("V11H original attempt status was rewritten")
    semantic_log_path = verify_artifact_record(
        root, failure.get("semantic_log"), "V11H original semantic log"
    )
    semantic_log = semantic_log_path.read_text(encoding="utf-8")
    if (
        "NameError: name 'assertion_probe' is not defined"
        not in semantic_log
        or "FAILED (errors=4)" not in semantic_log
    ):
        raise CoverageError(
            "V11H original semantic-ledger failure reason drifted"
        )

    frozen = receipt.get("frozen_simulation_evidence")
    expected_frozen_keys = {
        "summary",
        "focused_sources_pre",
        "focused_sources_post",
        "full_rtl_pre",
        "full_rtl_post",
        "evidence_checker_unit_log",
        "positive_profiles",
        "raw_q_knownness_assertion_probes",
        "mutation_cases",
        "mutation_simulations",
    }
    if (
        not isinstance(frozen, dict)
        or set(frozen) != expected_frozen_keys
        or frozen.get("positive_profiles") != 4
        or frozen.get("raw_q_knownness_assertion_probes") != 1
        or frozen.get("mutation_cases") != 31
        or frozen.get("mutation_simulations") != 62
    ):
        raise CoverageError("V11H frozen checker-replay inputs are incomplete")
    summary_path = verify_artifact_record(
        root, frozen.get("summary"), "V11H frozen summary"
    )
    if relative(root, summary_path) != spec.get("summary"):
        raise CoverageError(
            "V11H checker replay is bound to a different RTL summary"
        )
    if load_json(summary_path).get("design_id") != receipt.get("design_id"):
        raise CoverageError(
            "V11H checker replay design differs from frozen RTL summary"
        )
    focused_pre = verify_artifact_record(
        root, frozen.get("focused_sources_pre"),
        "V11H frozen focused pre",
    )
    focused_post = verify_artifact_record(
        root, frozen.get("focused_sources_post"),
        "V11H frozen focused post",
    )
    rtl_pre = verify_artifact_record(
        root, frozen.get("full_rtl_pre"), "V11H frozen RTL pre"
    )
    rtl_post = verify_artifact_record(
        root, frozen.get("full_rtl_post"), "V11H frozen RTL post"
    )
    if (
        focused_pre.read_bytes() != focused_post.read_bytes()
        or rtl_pre.read_bytes() != rtl_post.read_bytes()
    ):
        raise CoverageError(
            "V11H checker replay pre/post source bindings differ"
        )
    verify_artifact_record(
        root,
        frozen.get("evidence_checker_unit_log"),
        "V11H frozen evidence-checker unit log",
    )

    checker_sources = receipt.get("replacement_checker_sources")
    if (
        not isinstance(checker_sources, dict)
        or set(checker_sources) != set(V11H_REPLAY_CURRENT_FILES)
    ):
        raise CoverageError(
            "V11H checker replay replacement source set is incomplete"
        )
    for name, expected_path in V11H_REPLAY_CURRENT_FILES.items():
        current_path = verify_artifact_record(
            root,
            checker_sources.get(name),
            f"V11H replacement checker {name}",
        )
        if relative(root, current_path) != expected_path:
            raise CoverageError(
                f"V11H replacement checker path drifted: {name}"
            )

    contract = receipt.get("replay_contract")
    expected_contract = {
        "original_fail_preserved": True,
        "rtl_simulation_reexecuted": False,
        "full_rtl_pre_post_identical": True,
        "focused_sources_pre_post_identical": True,
        "historical_full_rtl_snapshot_is_current":
            receipt.get("design_id") == design_id,
        "current_selected_source_and_tb_bound": True,
        "system_rerun_required_before_system_promotion": True,
        "system_rerun_executed": False,
        "replacement_checker_must_run_positive_and_negative_units": True,
    }
    if contract != expected_contract:
        raise CoverageError("V11H checker-replay contract was weakened")
    if not isinstance(receipt.get("claim_boundary"), str):
        raise CoverageError("V11H checker-replay claim boundary is missing")
    return artifact(root, receipt_value), {
        "status": "PASS",
        "original_attempt": 4,
        "original_fail_preserved": True,
        "rtl_simulation_reexecuted": False,
        "frozen_positive_profiles": 4,
        "frozen_raw_q_knownness_assertion_probes": 1,
        "frozen_mutation_simulations": 62,
        "evidence_design_id": receipt["design_id"],
        "current_design_id": design_id,
        "binding_state": selected["binding_state"],
        "selected_bindings": selected_records,
        "system_rerun_required_before_system_promotion": True,
        "system_rerun_executed": False,
    }


def evaluate_v11b_terminal_collector(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    lane = payload.get("static_lane_contract")
    mutations = payload.get("compile_success_mutations")
    result_ok = (
        payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and payload.get("positive_profile_count") == 2
        and payload.get("mutation_count") == 3
        and payload.get("rejected_mutation_count") == 3
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(lane, dict)
        and lane.get("ingress_lanes") == 12
        and lane.get("tracker_free_lanes") == 2
        and lane.get("accepted_transfer_only") is True
        and lane.get("duplicate_ingress_merged") is False
        and isinstance(mutations, list)
        and len(mutations) == 3
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError("V11B terminal collector summary is not complete")
    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11B RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11B RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11B terminal collector RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11B runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11B runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    verify_artifact_record(
        root, lane.get("artifact"), "V11B lane contract"
    )
    for profile, record in payload.get("positive_profiles", {}).items():
        verify_artifact_record(root, record, f"V11B profile {profile}")
    verify_artifact_record(
        root, payload.get("raw_unknown_negative"), "V11B unknown negative"
    )
    for item in mutations:
        verify_artifact_record(
            root, item.get("receipt"), f"V11B {item.get('case')} receipt"
        )
        verify_artifact_record(
            root, item.get("log"), f"V11B {item.get('case')} log"
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11B {item.get('case')} image",
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "ingress_lanes": 12,
            "tracker_free_lanes": 2,
            "positive_profiles": 2,
            "compile_success_mutations_rejected": 3,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11c_memory_tracker(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    cycle = payload.get("cycle_contract")
    positives = payload.get("positive_profiles")
    negatives = payload.get("unknown_negatives")
    mutations = payload.get("compile_success_mutations")
    expected_negative_cases = {
        "alloc-pid-unknown",
        "release-mask-unknown",
        "live-map-unknown",
        "live-set-unknown",
    }
    expected_mutation_cases = {
        "live-mask-output-zero",
        "drop-live-birth",
        "drop-live-death",
        "wrong-producer-map-birth0",
        "drop-producer-live-birth",
        "wrong-producer-clear",
        "same-edge-exact-token-reuse",
        "same-edge-bulk-token-reuse",
        "allow-dual-duplicate-pid",
    }
    result_ok = (
        payload.get("schema_version")
        == "rv64-v11c-memory-tracker-semantic-evidence-v1"
        and payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", [])) == V11C_MEMORY_TRACKER_UNIT_IDS
        and payload.get("production_rtl_modified") is False
        and payload.get("positive_profile_count") == 2
        and payload.get("unknown_negative_count") == 4
        and payload.get("mutation_count") == 9
        and payload.get("rejected_mutation_count") == 9
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(cycle, dict)
        and cycle.get("allocation_scans_edge_old_live_set") is True
        and cycle.get("birth_and_death_are_disjoint") is True
        and cycle.get("exact_death_same_edge_reuse_rejected") is True
        and cycle.get("bulk_death_same_edge_reuse_rejected") is True
        and cycle.get("next_cycle_reuse_observed") is True
        and cycle.get("token_to_producer_map_checked_each_observed_edge")
        is True
        and cycle.get("next_token_cursor_closed") is False
        and isinstance(positives, dict)
        and set(positives) == {"assert", "release"}
        and isinstance(negatives, list)
        and {
            item.get("case") for item in negatives if isinstance(item, dict)
        }
        == expected_negative_cases
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in negatives
            if isinstance(item, dict)
        )
        and isinstance(mutations, list)
        and {
            item.get("case") for item in mutations if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError("V11C memory tracker summary is not complete")

    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11C RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11C RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11C memory tracker RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11C runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11C runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(root, record, f"V11C profile {profile}")
    for item in negatives:
        verify_artifact_record(
            root, item.get("log"), f"V11C negative {item.get('case')} log"
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11C negative {item.get('case')} image",
        )
    for item in mutations:
        verify_artifact_record(
            root,
            item.get("receipt"),
            f"V11C mutation {item.get('case')} receipt",
        )
        verify_artifact_record(
            root,
            item.get("log"),
            f"V11C mutation {item.get('case')} log",
        )
        verify_artifact_record(
            root,
            item.get("compiled_image"),
            f"V11C mutation {item.get('case')} image",
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 2,
            "unknown_negatives_rejected": 4,
            "compile_success_mutations_rejected": 9,
            "next_token_cursor_closed": False,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11d_memory_tracker_cursor(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    source_binding = payload.get("source_binding")
    cycle = payload.get("cycle_contract")
    positives = payload.get("positive_profiles")
    mutations = payload.get("compile_success_mutations")
    expected_profiles = {
        "assert-t4": (4, True),
        "release-t4": (4, False),
        "assert-t32": (32, True),
        "release-t32": (32, False),
    }
    expected_mutation_cases = {
        "reset-to-one",
        "fixed-scan-base",
        "advance-step-two",
        "dual-advance-lane0",
        "advance-on-ready",
        "idle-increment",
        "lane1-does-not-exclude-lane0",
        "lane1-excludes-unclaimed-lane0",
        "truncate-scan-four",
    }
    cycle_keys = {
        "reference_model_uses_stimulus_and_edge_old_state",
        "dut_token_not_reused_as_expected_token",
        "lane0_only_checked",
        "lane1_only_checked",
        "dual_birth_last_lane_advance_checked",
        "blocked_lane_checked",
        "atomic_single_credit_zero_fire_hold_checked",
        "idle_and_full_hold_checked",
        "exact_and_bulk_death_edge_old_visibility_checked",
        "wraparound_checked",
        "production_32_token_full_scan_checked",
        "next_token_cursor_closed",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("token_count") == token_count
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (token_count, assertions_enabled)
            in expected_profiles.items()
        )
    )
    result_ok = (
        payload.get("schema_version")
        == "rv64-v11d-memory-tracker-cursor-semantic-evidence-v1"
        and payload.get("result") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS
        and payload.get("production_rtl_modified") is False
        and payload.get("positive_profile_count") == 4
        and payload.get("mutation_count") == 9
        and payload.get("rejected_mutation_count") == 9
        and isinstance(source_binding, dict)
        and source_binding.get("rtl_file_count") == 146
        and isinstance(cycle, dict)
        and all(cycle.get(key) is True for key in cycle_keys)
        and profile_shape_ok
        and isinstance(mutations, list)
        and {
            item.get("case") for item in mutations if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            item.get("token_count") == 32
            and item.get("compile_success") is True
            and item.get("dynamically_rejected") is True
            and isinstance(item.get("make_rc"), int)
            and item.get("make_rc") != 0
            for item in mutations
            if isinstance(item, dict)
        )
    )
    if not result_ok:
        raise CoverageError(
            "V11D memory tracker cursor summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, source_binding.get("rtl_pre"), "V11D RTL pre"
    )
    post_path = verify_artifact_record(
        root, source_binding.get("rtl_post"), "V11D RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11D memory tracker RTL snapshots differ")
    runner_pre_path = verify_artifact_record(
        root, source_binding.get("runner_pre"), "V11D runner pre"
    )
    runner_post_path = verify_artifact_record(
        root, source_binding.get("runner_post"), "V11D runner post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        runner_pre_path,
        runner_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("log"), f"V11D profile {profile} log"
        )
        verify_artifact_record(
            root,
            record.get("compiled_image"),
            f"V11D profile {profile} image",
        )
    for item in mutations:
        label = f"V11D mutation {item.get('case')}"
        verify_artifact_record(root, item.get("receipt"), f"{label} receipt")
        verify_artifact_record(
            root, item.get("mutant_rtl"), f"{label} RTL"
        )
        verify_artifact_record(root, item.get("log"), f"{label} log")
        verify_artifact_record(
            root, item.get("compiled_image"), f"{label} image"
        )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, runner_pre_path)),
            artifact(root, relative(root, runner_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "compile_success_mutations_rejected": 9,
            "token_counts": [4, 32],
            "next_token_cursor_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11e_rob_slot_generation(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "reset-seed-zero",
        "flush-resets-generation",
        "candidate-no-increment",
        "candidate-step-two",
        "lane1-uses-lane0-generation",
        "pair-uses-actual-lane1-slot",
        "lane0-write-on-valid",
        "lane1-write-lane0-slot",
        "commit-advances-generation",
        "recovery-resets-generation",
        "full-borrows-commit-slot",
        "head-carrier-zero-generation",
        "commit-carrier-zero-generation",
        "walk-carrier-zero-generation",
        "current-query-ignore-generation",
        "completion-query-ignore-generation",
        "resolve-query-ignore-generation",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11e-rob-slot-generation-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11E_ROB_SLOT_GENERATION_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("checks_every_edge") is True
        and oracle.get("checks_all_slots") is True
        and oracle.get("checks_all_generation_bits") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 17
        and counts.get("mutation_simulations") == 34
        and counts.get("rejected_mutation_simulations") == 34
    )
    if not result_ok:
        raise CoverageError(
            "V11E ROB slot-generation summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11E RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11E RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11E ROB slot-generation RTL snapshots differ")
    verify_artifact_record(
        root, production.get("rtl"), "V11E production ROB"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11E directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11E focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11E focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11E profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11E profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11E profile {profile} image",
        )
    for item in mutations:
        label = f"V11E mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 17,
            "mutation_simulations_rejected": 34,
            "rob_slot_generation_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11f_int_iq_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "dispatch0-generation-zero",
        "dispatch1-uses-lane0-pid",
        "compaction-uses-write-index-pid",
        "compaction-generation-zero",
        "issue0-generation-zero",
        "issue1-generation-zero",
        "issue0-raw-index-entry0",
        "issue1-raw-index-issue0",
        "issue0-fire-not-removed",
        "issue1-fire-not-removed",
        "pair-pop-only-entry0",
        "kill-boundary-inclusive",
        "flush-ignored",
        "reset-ignored",
        "regular-fire-dies-early-mask",
        "pair-fire-dies-early-mask",
        "mask-raw-rob-index",
        "dispatch0-pid-x",
        "dispatch1-pid-x",
        "compaction-pid-x",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11f-int-iq-producer-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11F_INT_IQ_PRODUCER_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_identity_knownness") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 20
        and counts.get("mutation_simulations") == 40
        and counts.get("rejected_mutation_simulations") == 40
    )
    if not result_ok:
        raise CoverageError(
            "V11F integer-IQ ProducerId summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11F RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11F RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError(
            "V11F integer-IQ ProducerId RTL snapshots differ"
        )
    verify_artifact_record(
        root, production.get("rtl"), "V11F production integer IQ"
    )
    verify_artifact_record(
        root, production.get("selector"), "V11F production IQ selector"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11F directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11F focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11F focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11F profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11F profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11F profile {profile} image",
        )
    for item in mutations:
        label = f"V11F mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 20,
            "mutation_simulations_rejected": 40,
            "raw_identity_knownness_closed": True,
            "integer_iq_producer_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11g_store_queue_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "alloc0-generation-zero",
        "alloc1-uses-alloc0-pid",
        "alloc0-pid-x",
        "alloc1-pid-x",
        "slot-reuse-keeps-old-pid",
        "request-full-pid-raw-only",
        "release-full-pid-raw-only",
        "request-clears-valid",
        "terminal-clears-valid",
        "release-keeps-valid",
        "flush-keeps-valid",
        "selective-kills-boundary",
        "global-kills-request-sent",
        "bind1-uses-bind0-tuple",
        "bind0-kind-x",
        "bind0-token-x",
        "bind0-epoch-x",
        "owner-valid-dies-on-request",
        "owner-valid-dies-on-terminal",
        "release-keeps-owner-valid",
        "flush-keeps-owner-valid",
        "release-mask-uses-rob-index",
        "bind-terminal-bypass-removed",
        "release-mask-bind-bypass-removed",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11g-store-queue-holder-semantic-evidence-v1"
        and payload.get("status") == "PASS"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11G_STORE_QUEUE_HOLDER_UNIT_IDS
        and isinstance(production, dict)
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("stimulus_owned_four_entry_model") is True
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_producer_id_knownness") is True
        and oracle.get("checks_raw_owner_tuple_knownness") is True
        and oracle.get("uses_asymmetric_token_epoch") is True
        and profile_shape_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("compile_success_mutation_cases") == 24
        and counts.get("mutation_simulations") == 48
        and counts.get("rejected_mutation_simulations") == 48
    )
    if not result_ok:
        raise CoverageError(
            "V11G StoreQueue holder summary is not complete"
        )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11G RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11G RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11G StoreQueue holder RTL snapshots differ")
    verify_artifact_record(
        root, production.get("rtl"), "V11G production StoreQueue"
    )
    verify_artifact_record(
        root, production.get("testbench"), "V11G directed testbench"
    )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11G focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11G focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11G profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11G profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11G profile {profile} image",
        )
    for item in mutations:
        label = f"V11G mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, focused_pre_path)),
            artifact(root, relative(root, focused_post_path)),
        ],
        {
            "rtl_file_count": len(pre["rtl_files"]),
            "positive_profiles": 4,
            "generation_widths": [1, 4],
            "compile_success_mutation_cases_rejected": 24,
            "mutation_simulations_rejected": 48,
            "raw_producer_identity_knownness_closed": True,
            "raw_owner_tuple_knownness_closed": True,
            "store_queue_producer_closed": True,
            "store_queue_owner_token_closed": True,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "selected_bindings": selected_records,
        },
    )


def evaluate_v11h_load_queue_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    pre_fix = payload.get("pre_fix_reproducer")
    root_cause = payload.get("root_cause")
    binding = payload.get("full_rtl_binding")
    focused = payload.get("focused_source_binding")
    oracle = payload.get("independent_oracle")
    positives = payload.get("positive_profiles")
    assertion_probe = payload.get("rtl_assertion_probe")
    mutations = payload.get("mutations")
    counts = payload.get("counts")
    scope = payload.get("scope")
    expected_profiles = {
        "assert-g1": (1, True),
        "release-g1": (1, False),
        "assert-g4": (4, True),
        "release-g4": (4, False),
    }
    expected_mutation_cases = {
        "alloc0-generation-zero",
        "alloc1-uses-alloc0-pid",
        "alloc0-pid-x",
        "alloc1-pid-x",
        "slot-reuse-keeps-old-pid",
        "issue-full-pid-index-only",
        "launch-full-pid-index-only",
        "query-full-pid-index-only",
        "response-full-pid-index-only",
        "completion-full-pid-index-only",
        "terminal-full-pid-index-only",
        "release-full-pid-index-only",
        "terminal-not-recorded",
        "terminal-seen-x",
        "recovery-ignores-prior-terminal",
        "normal-terminal-clears-valid",
        "killed-terminal-keeps-valid",
        "release-keeps-valid",
        "launched-recovery-drops-entry",
        "recovery-keeps-cleared-entry",
        "selective-includes-boundary",
        "same-edge-launch-ignored",
        "same-edge-completion-ignored",
        "same-edge-terminal-ignored",
        "dual-alloc-same-slot",
        "dual-query-same-pid-bypass",
        "issue-terminal-gate-removed",
        "query-terminal-gate-removed",
        "response-terminal-gate-removed",
        "release-before-completion",
        "alloc-borrows-same-edge-release",
    }
    profile_shape_ok = (
        isinstance(positives, dict)
        and set(positives) == set(expected_profiles)
        and all(
            isinstance(positives.get(profile), dict)
            and positives[profile].get("generation_width")
            == generation_width
            and positives[profile].get("assertions_enabled")
            is assertions_enabled
            and positives[profile].get("compile_rc") == 0
            and positives[profile].get("simulation_rc") == 0
            for profile, (generation_width, assertions_enabled)
            in expected_profiles.items()
        )
    )
    mutation_shape_ok = (
        isinstance(mutations, list)
        and {
            item.get("case")
            for item in mutations
            if isinstance(item, dict)
        }
        == expected_mutation_cases
        and all(
            isinstance(item.get("runs"), dict)
            and set(item["runs"]) == {"g1", "g4"}
            and all(
                isinstance(item["runs"].get(profile), dict)
                and item["runs"][profile].get("generation_width") == width
                and item["runs"][profile].get("assertions_enabled") is False
                and item["runs"][profile].get(
                    "negative_stimulus_enabled"
                )
                is True
                and item["runs"][profile].get("compile_rc") == 0
                and isinstance(
                    item["runs"][profile].get("simulation_rc"), int
                )
                and item["runs"][profile]["simulation_rc"] != 0
                for profile, width in (("g1", 1), ("g4", 4))
            )
            for item in mutations
            if isinstance(item, dict)
        )
    )
    expected_scope = {
        "semantic_unit": "load-queue-producers",
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_rerun": {
            "required_for_local_closure": False,
            "required_before_system_promotion": True,
            "run": False,
        },
    }
    assertion_probe_ok = (
        isinstance(assertion_probe, dict)
        and assertion_probe.get("generation_width") == 4
        and assertion_probe.get("assertions_enabled") is True
        and assertion_probe.get("unknown_generation_injected") is True
        and assertion_probe.get("compile_rc") == 0
        and isinstance(assertion_probe.get("simulation_rc"), int)
        and assertion_probe["simulation_rc"] != 0
        and assertion_probe.get("expected_marker")
        == "[V11H-LQ-PID-KNOWN]"
    )
    result_ok = (
        payload.get("schema")
        == "rv64-v11h-load-queue-producer-semantic-evidence-v2"
        and payload.get("status") == "PASS"
        and payload.get("classification") == "architecture"
        and valid_design_id(payload.get("design_id"))
        and set(payload.get("unit_ids", []))
        == V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS
        and isinstance(production, dict)
        and production.get("pre_fix_rtl_sha256")
        == "82b22c8bf873b26863676823dd677fa8389ca96465e5611ac19e991d92a9752e"
        and production.get("post_fix_rtl_sha256")
        == "4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427"
        and production.get("raw_q_producer_id_knownness_assertion") is True
        and production.get("raw_q_producer_id_knownness_marker")
        == "[V11H-LQ-PID-KNOWN]"
        and isinstance(pre_fix, dict)
        and pre_fix.get("assertions_enabled") is False
        and pre_fix.get("compile_rc") == 0
        and isinstance(pre_fix.get("simulation_rc"), int)
        and pre_fix["simulation_rc"] != 0
        and pre_fix.get("observed_first_bad_state")
        == {"count": 1, "producer_live": 1, "killed": 1}
        and isinstance(root_cause, dict)
        and root_cause.get("confirmed") is True
        and isinstance(binding, dict)
        and binding.get("rtl_file_count") == 146
        and isinstance(focused, dict)
        and isinstance(oracle, dict)
        and oracle.get("stimulus_owned_four_entry_model") is True
        and oracle.get("checks_every_directed_edge") is True
        and oracle.get("checks_all_entries") is True
        and oracle.get("checks_all_generation_bits") is True
        and oracle.get("checks_raw_producer_id_knownness") is True
        and oracle.get("checks_raw_terminal_history") is True
        and oracle.get("dut_outputs_are_observations_only") is True
        and oracle.get("mutation_assertions_enabled") is False
        and profile_shape_ok
        and assertion_probe_ok
        and mutation_shape_ok
        and isinstance(counts, dict)
        and counts.get("positive_profiles") == 4
        and counts.get("raw_q_knownness_assertion_probes") == 1
        and counts.get("compile_success_mutation_cases") == 31
        and counts.get("mutation_simulations") == 62
        and counts.get("rejected_mutation_simulations") == 62
        and scope == expected_scope
    )
    if not result_ok:
        raise CoverageError(
            "V11H LoadQueue producer summary is not complete"
        )
    if spec.get("checker_replay_receipt") is None:
        raise CoverageError(
            "current V11H closure requires the attempt-4 checker replay"
        )
    replay_artifact, replay_detail = validate_v11h_checker_replay(
        root, spec, design_id
    )

    pre_path = verify_artifact_record(
        root, binding.get("pre"), "V11H RTL pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("post"), "V11H RTL post"
    )
    pre = load_json(pre_path)
    post = load_json(post_path)
    if pre != post:
        raise CoverageError("V11H LoadQueue RTL snapshots differ")
    verify_artifact_record(
        root, production.get("rtl"), "V11H production LoadQueue"
    )
    verify_artifact_record(
        root,
        production.get("semantic_testbench"),
        "V11H semantic testbench",
    )
    verify_artifact_record(
        root,
        production.get("ordinary_regression_testbench"),
        "V11H ordinary testbench",
    )
    for key in ("source_manifest", "compile_log", "simulation_log"):
        verify_artifact_record(
            root, pre_fix.get(key), f"V11H pre-fix {key}"
        )
    focused_pre_path = verify_artifact_record(
        root, focused.get("pre"), "V11H focused source pre"
    )
    focused_post_path = verify_artifact_record(
        root, focused.get("post"), "V11H focused source post"
    )
    binding_state, selected_records = validate_current_selected_binding(
        root,
        spec,
        pre,
        payload["design_id"],
        design_id,
        focused_pre_path,
        focused_post_path,
    )
    for profile, record in positives.items():
        verify_artifact_record(
            root, record.get("compile_log"),
            f"V11H profile {profile} compile log",
        )
        verify_artifact_record(
            root, record.get("simulation_log"),
            f"V11H profile {profile} simulation log",
        )
        verify_artifact_record(
            root, record.get("compiled_image"),
            f"V11H profile {profile} image",
        )
    for key, label in (
        ("compile_log", "compile log"),
        ("simulation_log", "simulation log"),
        ("compiled_image", "image"),
    ):
        verify_artifact_record(
            root,
            assertion_probe.get(key),
            f"V11H raw-Q PID knownness assertion probe {label}",
        )
    for item in mutations:
        label = f"V11H mutation {item.get('case')}"
        verify_artifact_record(
            root, item.get("mutant_source"), f"{label} RTL"
        )
        verify_artifact_record(
            root, item.get("receipt"), f"{label} receipt"
        )
        for profile, record in item["runs"].items():
            verify_artifact_record(
                root, record.get("compile_log"),
                f"{label}/{profile} compile log",
            )
            verify_artifact_record(
                root, record.get("simulation_log"),
                f"{label}/{profile} simulation log",
            )
            verify_artifact_record(
                root, record.get("compiled_image"),
                f"{label}/{profile} image",
            )
    detail = {
        "rtl_file_count": len(pre["rtl_files"]),
        "positive_profiles": 4,
        "generation_widths": [1, 4],
        "raw_q_knownness_assertion_probes": 1,
        "compile_success_mutation_cases_rejected": 31,
        "mutation_simulations_rejected": 62,
        "pre_fix_reproducer_rejected": True,
        "raw_producer_identity_knownness_closed": True,
        "raw_q_producer_identity_knownness_assertion_closed": True,
        "terminal_history_lifecycle_closed": True,
        "load_queue_producer_closed": True,
        "system_rerun": scope["system_rerun"],
        "checker_replay": replay_detail,
        "evidence_design_id": payload["design_id"],
        "current_design_id": design_id,
        "selected_bindings": selected_records,
    }
    return (
        binding_state,
        [artifact(root, spec["summary"]), replay_artifact],
        detail,
    )


def evaluate_v11j_bridge_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    expected_profiles = {
        "production-assert",
        "production-release",
        "kind-x-assert",
        "kind-x-release",
        "epoch-x-assert",
        "epoch-x-release",
    } | {
        f"{case}-{configuration}"
        for case in V11J_MUTATION_CASES
        for configuration in ("assert", "release")
    }
    expected_oracle = {
        "stimulus_owned_tuple_schedule": True,
        "expected_tuple_uses_dut_query_or_raw_holder": False,
        "checks_both_product_instances": True,
        "checks_stage_active_response_verified": True,
        "checks_exact_32bit_residency_set": True,
        "checks_every_directed_edge": True,
        "checks_raw_owner_tuple_knownness": True,
        "checks_owner_kind_and_mmu_epoch_x": True,
        "assert_and_release_mutation_rejection": True,
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_rerun": {
            "triggered_by_v11j": False,
            "reason": "production delta is OOO_ASSERT-only",
            "run": False,
        },
    }
    if (
        payload.get("schema") != V11J_BRIDGE_HOLDER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11J_BRIDGE_HOLDER_UNIT_IDS
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11J_PRODUCT_INSTANCES
        or oracle != expected_oracle
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 32
        or counts.get("profiles_pass") != 32
        or counts.get("profiles_fail") != 0
        or counts.get("mutations_total") != 13
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
    ):
        raise CoverageError("V11J bridge-holder summary is not complete")

    bridge_path = resolve_repo_path(
        root, production.get("bridge")
    )
    wrapper_path = resolve_repo_path(
        root, production.get("wrapper")
    )
    if (
        sha256_file(bridge_path) != production.get("bridge_sha256")
        or sha256_file(wrapper_path) != production.get("wrapper_sha256")
    ):
        raise CoverageError("V11J production bridge source binding drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11J focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11J focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/scripts/run_v11j_bridge_holder_semantic.py",
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11j_bridge_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11J runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(profiles, list)
        or len(profiles) != 32
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11J profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11J profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        if (
            record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or not isinstance(markers, dict)
        ):
            raise CoverageError(f"V11J profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11J profile {name} image",
        )
        verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11J profile {name} simulation log",
        )
        is_baseline = name in {
            "production-assert",
            "production-release",
        }
        if is_baseline:
            if (
                simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or markers.get("tuple_marker_total") != 0
            ):
                raise CoverageError(
                    f"V11J production profile is not clean: {name}"
                )
            continue
        if (
            not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("tb_pass") != 0
            or markers.get("negative_escaped") != 0
        ):
            raise CoverageError(
                f"V11J negative profile escaped: {name}"
            )
        if name in {"kind-x-assert", "epoch-x-assert"}:
            if markers.get("v11j_bridge_stage_tuple_known", 0) < 1:
                raise CoverageError(
                    f"V11J tuple-X assertion marker missing: {name}"
                )
        elif name in {"kind-x-release", "epoch-x-release"}:
            if (
                markers.get("oracle_fail", 0) < 1
                or markers.get("tuple_marker_total") != 0
            ):
                raise CoverageError(
                    f"V11J tuple-X release oracle missing: {name}"
                )
        elif name.endswith("-release"):
            if (
                markers.get("oracle_fail", 0) < 1
                or markers.get("tuple_marker_total") != 0
            ):
                raise CoverageError(
                    f"V11J release mutation oracle missing: {name}"
                )
        else:
            expected_marker = record.get("expected_marker")
            if expected_marker is not None:
                if (
                    not isinstance(expected_marker, str)
                    or markers.get("oracle_fail") != 0
                    or verify_path_sha(
                        root,
                        simulation.get("log"),
                        simulation.get("log_sha256"),
                        f"V11J marker profile {name} log",
                    ).read_text(
                        encoding="utf-8", errors="replace"
                    ).count(expected_marker)
                    < 1
                ):
                    raise CoverageError(
                        f"V11J exact holder marker missing: {name}"
                    )
            elif (
                markers.get("oracle_fail", 0)
                + markers.get("tuple_marker_total", 0)
                + markers.get("s2_g1_fail", 0)
                < 1
            ):
                raise CoverageError(
                    f"V11J assert mutation was not rejected: {name}"
                )

    if (
        not isinstance(variants, list)
        or len(variants) != 13
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != V11J_MUTATION_CASES
    ):
        raise CoverageError("V11J mutation inventory is incomplete")
    for record in variants:
        name = record.get("name")
        target = record.get("target")
        expected_target = (
            "npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v"
            if name == "wrapper-crosswire-residency-lanes"
            else "npc/rv64/vsrc/memory/OooMemAxiBridge.v"
        )
        if (
            target != expected_target
            or record.get("compile_success_required") is not True
            or sha256_file(resolve_repo_path(root, target))
            != record.get("production_sha256")
            or not isinstance(record.get("receipts"), list)
            or not record["receipts"]
        ):
            raise CoverageError(f"V11J mutation receipt is invalid: {name}")
        verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11J mutation {name}",
        )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11J_REGRESSIONS
    ):
        raise CoverageError("V11J regression inventory is incomplete")
    for record in regressions:
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11J regression {name}"
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            record.get("status") != "PASS"
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
        ):
            raise CoverageError(f"V11J regression failed: {name}")
    regression_summary_path = summary_path.parent / "regressions/summary.json"
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
    ):
        raise CoverageError("V11J regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 2,
            "tuple_x_profiles": 4,
            "compile_success_mutation_cases_rejected": 13,
            "mutation_simulations_rejected": 26,
            "ordinary_regressions_passed": 3,
            "raw_owner_tuple_knownness_closed": True,
            "exact_residency_set_membership_closed": True,
            "stage_active_response_verified_lifecycle_closed": True,
            "product_instance_paths": sorted(V11J_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
        },
    )


def evaluate_v11k_miq_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    logic_identity_path = resolve_repo_path(
        root, spec["elaborated_logic_identity"]
    )
    logic_identity = load_json(logic_identity_path)
    production = payload.get("production")
    binding = payload.get("binding")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    expected_profiles = {
        "production-assert",
        "production-release",
    } | {
        f"{case}-{configuration}"
        for case in V11K_MUTATION_CASES
        for configuration in ("assert", "release")
    } | {
        f"{case}-{configuration}"
        for case in V11K_STIMULUS_PROBES
        for configuration in ("assert", "release")
    }
    expected_oracle = {
        "stimulus_owned_fixed_tuple_schedule": True,
        "expected_tuple_uses_dut_state": False,
        "checks_both_product_instances": True,
        "checks_same_rob_distinct_owner": True,
        "checks_swapped_tuple_rejection": True,
        "checks_hold_flush_kill_exact_consume": True,
        "checks_exact_32bit_occupancy_set": True,
        "checks_full_tuple_x_and_z": True,
        "checks_push_pop_interface_x_and_z": True,
        "checks_release_invalid_tuple_state_fail_closed": True,
        "assert_and_release_mutation_rejection": True,
        "regressions_source_artifact_post_bound": True,
    }
    expected_scope = {
        "semantic_units": sorted(V11K_MIQ_HOLDER_UNIT_IDS),
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_rerun": {
            "triggered_by_v11k": False,
            "reason": "production delta is OOO_ASSERT-only",
            "run": False,
        },
    }
    if (
        payload.get("schema") != V11K_MIQ_HOLDER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11K_MIQ_HOLDER_UNIT_IDS
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11K_PRODUCT_INSTANCES
        or oracle != expected_oracle
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 34
        or counts.get("profiles_pass") != 34
        or counts.get("profiles_fail") != 0
        or counts.get("mutations_total") != 12
        or counts.get("stimulus_probes_total") != 4
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
    ):
        raise CoverageError("V11K MIQ-holder summary is not complete")

    v11j_logic = logic_identity.get("v11j")
    v11k_logic = logic_identity.get("v11k")
    expected_logic_paths = {
        "v11j": (
            ".github/task-runs/2026-07-30-rv64-v11j-bridge-holder-"
            "semantic-coverage/evidence/current-instance-graph/"
            "yosys-instance-graph.full.json.gz"
        ),
        "v11k": (
            ".github/task-runs/2026-07-30-rv64-v11k-holder-"
            "semantic-next/evidence/current-instance-graph/"
            "yosys-instance-graph.full.json.gz"
        ),
    }
    if (
        logic_identity.get("schema")
        != "npc-rv64-v11k-elaborated-logic-identity-v1"
        or logic_identity.get("status") != "PASS"
        or logic_identity.get("production_elaborated_logic_changed")
        is not False
        or logic_identity.get("system_rerun_triggered_by_v11k")
        is not False
        or not isinstance(v11j_logic, dict)
        or not isinstance(v11k_logic, dict)
        or v11j_logic.get("path") != expected_logic_paths["v11j"]
        or v11k_logic.get("path") != expected_logic_paths["v11k"]
        or v11j_logic.get("module_count") != 130
        or v11k_logic.get("module_count") != 130
        or v11j_logic.get("cell_count") != 176087
        or v11k_logic.get("cell_count") != 176087
        or v11j_logic.get("logic_sha256")
        != v11k_logic.get("logic_sha256")
        or v11j_logic.get("logic_size_bytes")
        != v11k_logic.get("logic_size_bytes")
    ):
        raise CoverageError(
            "V11K two-state elaborated RTL identity is not proven"
        )
    for label, record in (("V11J", v11j_logic), ("V11K", v11k_logic)):
        verify_path_sha(
            root,
            record.get("path"),
            record.get("compressed_sha256"),
            f"{label} canonical elaborated RTL",
        )

    miq_path = resolve_repo_path(root, production.get("miq"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        sha256_file(miq_path) != production.get("miq_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError("V11K production MIQ/TB source binding drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11K focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11K focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/scripts/run_v11k_miq_holder_semantic.py",
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11k_miq_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11K runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(profiles, list)
        or len(profiles) != 34
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11K profile inventory is incomplete")
    profile_by_name: dict[str, dict[str, Any]] = {}
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11K profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or not isinstance(markers, dict)
        ):
            raise CoverageError(f"V11K profile failed: {name}")
        profile_by_name[name] = record
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11K profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11K profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        compile_manifest = record.get("compile_source_manifest")
        focused_tb = production.get("focused_testbench")
        if (
            not isinstance(compile_manifest, dict)
            or focused_tb not in compile_manifest
            or compile_manifest[focused_tb]
            != production.get("focused_testbench_sha256")
        ):
            raise CoverageError(
                f"V11K profile source binding is invalid: {name}"
            )
        if name in {"production-assert", "production-release"}:
            if (
                record.get("kind") != "baseline"
                or production.get("miq") not in compile_manifest
                or compile_manifest[production["miq"]]
                != production.get("miq_sha256")
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or markers.get("negative_escaped") != 0
                or markers.get("assertion_marker_total") != 0
            ):
                raise CoverageError(
                    f"V11K production profile is not clean: {name}"
                )
            continue
        case, configuration = name.rsplit("-", 1)
        if case in V11K_STIMULUS_PROBES:
            probe = V11K_STIMULUS_PROBES[case]
            if (
                record.get("kind") != "stimulus-probe"
                or record.get("mutation") is not None
                or record.get("stimulus_define")
                != probe["define"]
                or record.get("release_fail_closed_marker")
                != probe["release_marker"]
                or production.get("miq") not in compile_manifest
                or compile_manifest[production["miq"]]
                != production.get("miq_sha256")
            ):
                raise CoverageError(
                    f"V11K interface probe binding is invalid: {name}"
                )
            if configuration == "assert":
                if (
                    record.get("expected_marker")
                    != probe["assertion_marker"]
                    or not isinstance(simulation.get("rc"), int)
                    or simulation["rc"] == 0
                    or markers.get(probe["assertion_marker_key"], 0)
                    < 1
                    or markers.get("oracle_fail") != 0
                    or markers.get("assertion_marker_total") != 1
                    or markers.get("tb_pass") != 0
                    or markers.get("negative_escaped") != 0
                ):
                    raise CoverageError(
                        "V11K interface assertion probe did not "
                        f"hit its marker: {name}"
                    )
            else:
                fail_closed = (
                    simulation.get("rc") == 0
                    and markers.get(
                        probe["release_marker_key"], 0
                    )
                    == 1
                    and markers.get("oracle_fail") == 0
                )
                oracle_rejected = (
                    isinstance(simulation.get("rc"), int)
                    and simulation["rc"] != 0
                    and markers.get("oracle_fail", 0) >= 1
                    and markers.get(
                        probe["release_marker_key"], 0
                    )
                    == 0
                )
                if (
                    record.get("expected_marker") is not None
                    or not (fail_closed or oracle_rejected)
                    or markers.get("assertion_marker_total") != 0
                    or markers.get("tb_pass") != 0
                    or markers.get("negative_escaped") != 0
                ):
                    raise CoverageError(
                        "V11K release interface probe did not "
                        f"fail closed: {name}"
                    )
            if "[V11K-MIQ-NEGATIVE-ESCAPED][FAIL]" in log_text:
                raise CoverageError(
                    f"V11K interface probe escaped: {name}"
                )
            continue
        if (
            record.get("kind") != "mutation"
            or record.get("mutation") != case
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("tb_pass") != 0
            or markers.get("negative_escaped") != 0
        ):
            raise CoverageError(
                f"V11K negative profile escaped: {name}"
            )
        if name.endswith("-release"):
            if (
                markers.get("oracle_fail", 0) < 1
                or markers.get("assertion_marker_total", 0) != 0
            ):
                raise CoverageError(
                    f"V11K release oracle did not reject: {name}"
                )
        elif case.startswith("capture-"):
            if (
                markers.get("v11k_miq_owner_tuple_known", 0) < 1
                or markers.get("oracle_fail", 0) != 0
            ):
                raise CoverageError(
                    f"V11K tuple knownness marker missing: {name}"
                )
        elif case == "idle-head-token-drift":
            if (
                markers.get("v11k_miq_owner_tuple_stable", 0) < 1
                or markers.get("oracle_fail", 0) != 0
            ):
                raise CoverageError(
                    f"V11K tuple stability marker missing: {name}"
                )
        elif case == "consume-without-exact-owner":
            if (
                markers.get("miq_owner_mismatch", 0) < 1
                or markers.get("oracle_fail", 0) != 0
            ):
                raise CoverageError(
                    f"V11K exact owner marker missing: {name}"
                )
        elif (
            markers.get("oracle_fail", 0)
            + markers.get("assertion_marker_total", 0)
            < 1
        ):
            raise CoverageError(
                f"V11K assert mutation was not rejected: {name}"
            )
        if "[V11K-MIQ-NEGATIVE-ESCAPED][FAIL]" in log_text:
            raise CoverageError(
                f"V11K profile reached escaped marker: {name}"
            )

    if (
        not isinstance(variants, list)
        or len(variants) != 12
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != V11K_MUTATION_CASES
    ):
        raise CoverageError("V11K mutation inventory is incomplete")
    for record in variants:
        name = record.get("name")
        target = record.get("target")
        if (
            target != "npc/rv64/vsrc/memory/OooMemInflightQueue.v"
            or record.get("unit_id") != "miq-owner-tokens"
            or record.get("compile_success_required") is not True
            or sha256_file(resolve_repo_path(root, target))
            != record.get("production_sha256")
            or not isinstance(record.get("receipts"), list)
            or not record["receipts"]
        ):
            raise CoverageError(f"V11K mutation receipt is invalid: {name}")
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11K mutation {name}",
        )
        for configuration in ("assert", "release"):
            profile = profile_by_name[f"{name}-{configuration}"]
            compile_manifest = profile.get("compile_source_manifest")
            if (
                not isinstance(compile_manifest, dict)
                or relative(root, variant_path) not in compile_manifest
                or compile_manifest[relative(root, variant_path)]
                != record.get("variant_sha256")
                or target in compile_manifest
            ):
                raise CoverageError(
                    f"V11K mutation compile binding is invalid: "
                    f"{name}-{configuration}"
                )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11K_REGRESSIONS
    ):
        raise CoverageError("V11K regression inventory is incomplete")
    regression_testbenches = {
        name: f"npc/rv64/testbench/tests/{name}.sv"
        for name in V11K_REGRESSIONS
    }
    for record in regressions:
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11K regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11K regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or regression_testbenches[name] not in source_pre
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11K regression binding is incomplete: {name}"
            )
        stale_regression_inputs = stale_manifest_paths(root, source_pre)
        if stale_regression_inputs:
            raise CoverageError(
                "V11K regression source binding drifted: "
                f"{name} stale={stale_regression_inputs}"
            )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            record.get("status") != "PASS"
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
        ):
            raise CoverageError(f"V11K regression failed: {name}")
    regression_summary_path = summary_path.parent / "regressions/summary.json"
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("all_source_pre_post_match")
        is not True
        or regression_summary.get("tests") != regressions
    ):
        raise CoverageError("V11K regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
            artifact(root, relative(root, logic_identity_path)),
        ],
        {
            "positive_profiles": 2,
            "compile_success_mutation_cases_rejected": 12,
            "mutation_simulations_rejected": 24,
            "interface_xz_probe_cases": 4,
            "interface_probe_simulations": 8,
            "ordinary_regressions_passed": 3,
            "push_pop_assertion_markers_closed": True,
            "regressions_current_source_artifact_post_bound": True,
            "raw_owner_tuple_xz_knownness_closed": True,
            "exact_occupancy_set_membership_closed": True,
            "capture_hold_cross_reject_flush_kill_consume_closed": True,
            "production_elaborated_logic_identical": True,
            "product_instance_paths": sorted(V11K_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
        },
    )


def evaluate_v11l_memory_retry_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11L_MUTATION_EXPECTATIONS)
    expected_profiles = {
        "production-assert",
        "production-release",
    } | {f"{case}-release" for case in mutation_cases}
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11L_MEMORY_RETRY_HOLDER_FOCUSED",
        "profile_count": 34,
        "mutation_count": 32,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
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
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
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
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11L_MEMORY_RETRY_HOLDER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11L_MEMORY_RETRY_HOLDER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11L_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 34
        or counts.get("profiles_pass") != 34
        or counts.get("profiles_fail") != 0
        or counts.get("mutations_total") != 32
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11L memory retry-holder summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11L production OooIntBackend/TB source binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11L simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11L {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11L {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11L focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11L focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11l_memory_retry_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11l_memory_retry_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11L runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 32
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11L mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11L mutation record is not an object")
        name = record.get("name")
        expectation = V11L_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expectation is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", []))
            != expectation["unit_ids"]
            or record.get("expected_stage") != expectation["stage"]
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11L mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11L mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(
                f"V11L mutation did not change RTL: {name}"
            )
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 34
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11L profile inventory is incomplete")
    profile_by_name: dict[str, dict[str, Any]] = {}
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11L profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11L profile failed: {name}")
        profile_by_name[name] = record
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11L profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11L profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11L compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11L compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        if name.startswith("production-"):
            expected_defines = [
                "-DV11L_MEMORY_RETRY_HOLDER_FOCUSED"
            ]
            if name == "production-assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions")
                is not (name == "production-assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11l_"
                    "memory_retry_holder"
                )
                != 1
                or log_text.count(
                    "[V11L-RETRY-HOLDER-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_key) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, (
                        marker_key,
                        expected_count,
                    ) in V11L_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11L production profile is not clean: {name}"
                )
            continue

        case = name.removesuffix("-release")
        expectation = V11L_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11L_MEMORY_RETRY_HOLDER_FOCUSED",
            "-DV11L_NEGATIVE_PROFILE",
        ]
        exact_stage_marker = (
            "[V11L-RETRY-HOLDER-ORACLE][FAIL] "
            f"stage={expectation['stage']}"
            if expectation
            else ""
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expectation is None
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expectation["stage"]
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or log_text.count(
                "[V11L-RETRY-HOLDER-ORACLE][FAIL]"
            )
            != 1
            or log_text.count(exact_stage_marker) != 1
            or "[V11L-RETRY-HOLDER-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11l_" in log_text
        ):
            raise CoverageError(
                f"V11L release mutation escaped or was misbound: {name}"
            )

    for case in mutation_cases:
        profile = profile_by_name[f"{case}-release"]
        compile_manifest = profile["compile_source_manifest"]
        variant_relative = relative(root, variant_paths[case])
        if set(
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        ) != {variant_relative}:
            raise CoverageError(
                f"V11L mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11L_REGRESSIONS
    ):
        raise CoverageError("V11L regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11L regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11L regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11L regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11L regression binding is incomplete: {name}"
            )
        stale_regression_inputs = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale_regression_inputs
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11L-RETRY-HOLDER-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11L regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11L regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 2,
            "compile_success_mutation_cases_rejected": 32,
            "mutation_simulations_rejected": 32,
            "ordinary_regressions_passed": 3,
            "raw_producer_and_token_xz_knownness_closed": True,
            "simultaneous_lane_distinguishability_closed": True,
            "capture_hold_transfer_terminal_death_closed": True,
            "c0_empty_and_resident_barriers_closed": True,
            "flush_cancel_over_fire_priority_closed": True,
            "lane10_lane11_cancel_terminal_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11L_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
        },
    )


def evaluate_v11m_memory_reservation_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11M_MUTATION_EXPECTATIONS)
    expected_profiles = {
        "production-assert",
        "production-release",
    } | {f"{case}-release" for case in mutation_cases}
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": (
            "-DV11M_MEMORY_RESERVATION_HOLDER_FOCUSED"
        ),
        "profile_count": 39,
        "mutation_count": 37,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
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
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
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
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema")
        != V11M_MEMORY_RESERVATION_HOLDER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11M_MEMORY_RESERVATION_HOLDER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11M_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 39
        or counts.get("profiles_pass") != 39
        or counts.get("profiles_fail") != 0
        or counts.get("mutations_total") != 37
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11M memory-reservation holder summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11M production OooIntBackend/TB source binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11M simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11M {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11M {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11M focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11M focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11M runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 37
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11M mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11M mutation record is not an object")
        name = record.get("name")
        expectation = V11M_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expectation is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", []))
            != expectation["unit_ids"]
            or record.get("expected_stage") != expectation["stage"]
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11M mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11M mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(f"V11M mutation did not change RTL: {name}")
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 39
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11M profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11M profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11M profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11M profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11M profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11M compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11M compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        if name.startswith("production-"):
            expected_defines = [
                "-DV11M_MEMORY_RESERVATION_HOLDER_FOCUSED"
            ]
            if name == "production-assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions")
                is not (name == "production-assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11m_"
                    "memory_reservation_holder"
                )
                != 1
                or log_text.count(
                    "[V11M-RESERVATION-HOLDER-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, (
                        _marker_key,
                        expected_count,
                    ) in V11M_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11M production profile is not clean: {name}"
                )
            continue

        case = name.removesuffix("-release")
        expectation = V11M_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11M_MEMORY_RESERVATION_HOLDER_FOCUSED"
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11M-RESERVATION-HOLDER-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expectation is None
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expectation["stage"]
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or log_text.count(
                "[V11M-RESERVATION-HOLDER-ORACLE][FAIL]"
            )
            != 1
            or failure_stages != [expectation["stage"]]
            or "[V11M-RESERVATION-HOLDER-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11m_" in log_text
        ):
            raise CoverageError(
                f"V11M release mutation escaped or was misbound: {name}"
            )
        if set(
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        ) != {variant_relative}:
            raise CoverageError(
                f"V11M mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11M_REGRESSIONS
    ):
        raise CoverageError("V11M regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11M regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11M regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11M regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11M regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11M-RESERVATION-HOLDER-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11M regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11M regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 2,
            "compile_success_mutation_cases_rejected": 37,
            "mutation_simulations_rejected": 37,
            "ordinary_regressions_passed": 3,
            "raw_producer_and_token_xz_knownness_closed": True,
            "pair_credit_and_turnover_atomicity_closed": True,
            "capture_hold_request_terminal_death_closed": True,
            "lane6_lane7_accepted_terminal_closed": True,
            "selective_and_global_recovery_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11M_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_frozen_evidence_unchanged": True,
        },
    )


def evaluate_v11n_memory_pending_holder(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11N_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11N_MEMORY_PENDING_HOLDER_FOCUSED",
        "producer_gen_widths": [1, 4],
        "profile_count": 30,
        "baseline_profile_count": 4,
        "mutation_count": 13,
        "mutation_profile_count": 26,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_reset_allocation_schedule": True,
        "expected_pid_uses_pending_dut_state": False,
        "expected_token_uses_pending_dut_state": False,
        "four_state_exact_comparison": True,
        "producer_generation_one_exercised": True,
        "producer_gen_width_one_and_four": True,
        "owner_token_28_high_bits_exercised": True,
        "dispatch_lane1_routes_to_execution_terminal0": True,
        "read_pending_hold": True,
        "read_to_write_phase_hold": True,
        "write_grant_stall_hold": True,
        "post_write_hold": True,
        "collector_lane0_final_acceptance": True,
        "collector_lane9_cancel_acceptance": True,
        "read_fault_lane0_no_lane9_duplicate": True,
        "tracker_terminal_death": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "system_rerun": {
            "triggered_by_v11n": False,
            "run": False,
            "current_whole_design_recertification": (
                "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                "PRODUCTION_RTL_DELTA"
            ),
        },
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11N_MEMORY_PENDING_HOLDER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11N_MEMORY_PENDING_HOLDER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11N_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 30
        or counts.get("profiles_pass") != 30
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 13
        or counts.get("mutation_profiles_total") != 26
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11N memory-pending holder summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11N production OooIntBackend/TB source binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11N simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11N {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11N {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11N focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11N focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11N runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 13
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11N mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11N mutation record is not an object")
        name = record.get("name")
        expectation = V11N_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expectation is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", []))
            != expectation["unit_ids"]
            or record.get("expected_stage") != expectation["stage"]
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11N mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11N mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(f"V11N mutation did not change RTL: {name}")
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 30
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11N profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11N profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11N profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11N profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11N profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11N compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11N compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11N_MEMORY_PENDING_HOLDER_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11n_"
                    "memory_pending_holder"
                )
                != 1
                or log_text.count(
                    "[V11N-MEM-PENDING-HOLDER-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, (
                        _marker_key,
                        expected_count,
                    ) in V11N_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11N production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11N profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expectation = V11N_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11N_MEMORY_PENDING_HOLDER_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11N-MEM-PENDING-HOLDER-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expectation is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expectation["stage"]
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or log_text.count(
                "[V11N-MEM-PENDING-HOLDER-ORACLE][FAIL]"
            )
            != 1
            or failure_stages != [expectation["stage"]]
            or "[V11N-MEM-PENDING-HOLDER-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11n_" in log_text
        ):
            raise CoverageError(
                f"V11N release mutation escaped or was misbound: {name}"
            )
        if set(
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        ) != {variant_relative}:
            raise CoverageError(
                f"V11N mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11N_REGRESSIONS
    ):
        raise CoverageError("V11N regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11N regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11N regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11N regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11N regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11N-MEM-PENDING-HOLDER-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11N regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11N regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 13,
            "mutation_simulations_rejected": 26,
            "ordinary_regressions_passed": 3,
            "stimulus_owned_full_pid_and_token": True,
            "dispatch_lane1_to_execution_terminal0_closed": True,
            "read_write_hold_and_terminal_death_closed": True,
            "lane0_lane9_accepted_terminal_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11N_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_checker_replay": scope["a3_checker_replay"],
        },
    )


def evaluate_v11o_memory_buffer_token(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("legacy_dynamic_oracle")
    product = payload.get("product_reachability")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11O_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11O_MEMORY_BUFFER_TOKEN_FOCUSED",
        "legacy_enable_dual_mem": 0,
        "product_enable_dual_mem": 1,
        "producer_gen_widths": [1, 4],
        "profile_count": 20,
        "baseline_profile_count": 4,
        "mutation_count": 8,
        "mutation_profile_count": 16,
        "regression_count": 3,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_token_28_29": True,
        "expected_token_uses_buffer_dut_state": False,
        "four_state_exact_comparison": True,
        "producer_gen_width_one_and_four": True,
        "lane0_birth": True,
        "lane1_birth": True,
        "three_cycle_hold_each": True,
        "buffer_to_miq_transfer": True,
        "sq_physical_write_b_commit_death": True,
        "selective_cancel_authority_end_death": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "system_rerun": {
            "triggered_by_v11o": False,
            "run": False,
            "current_whole_design_recertification": (
                "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                "PRODUCTION_RTL_DELTA"
            ),
        },
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11O_MEMORY_BUFFER_TOKEN_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11O_MEMORY_BUFFER_TOKEN_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11O_PRODUCT_INSTANCES
        or not isinstance(product, dict)
        or product.get("status") != "PASS"
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 20
        or counts.get("profiles_pass") != 20
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 8
        or counts.get("mutation_profiles_total") != 16
        or counts.get("product_static_negative_tests") != 8
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11O memory-buffer token summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11O production OooIntBackend/TB source binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11O simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11O {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11O {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11O focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11O focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11o_memory_buffer_token_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11o_memory_buffer_token_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
        (
            "npc/rv64/eval/ppa/tools/"
            "memory_buffer_product_reachability.py"
        ),
        (
            "npc/rv64/eval/ppa/tests/"
            "test_memory_buffer_product_reachability.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11O runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if not isinstance(product, dict) or product.get("status") != "PASS":
        raise CoverageError("V11O product reachability result is not PASS")
    graph_record = product.get("graph")
    static_tests = product.get("static_negative_tests")
    checker_record = product.get("checker")
    reachability = product.get("receipt_payload")
    if (
        not isinstance(graph_record, dict)
        or graph_record.get("rc") != 0
        or graph_record.get("timeout") is not False
        or not isinstance(static_tests, dict)
        or static_tests.get("rc") != 0
        or static_tests.get("timeout") is not False
        or static_tests.get("test_count") != 8
        or not isinstance(checker_record, dict)
        or checker_record.get("rc") != 0
        or checker_record.get("timeout") is not False
        or not isinstance(reachability, dict)
        or reachability.get("schema")
        != V11O_PRODUCT_REACHABILITY_SCHEMA
        or reachability.get("status") != "PASS"
        or not valid_design_id(reachability.get("design_id"))
    ):
        raise CoverageError(
            "V11O product reachability conjunction is incomplete"
        )
    reachability_path = verify_artifact_record(
        root, checker_record.get("receipt"), "V11O reachability receipt"
    )
    graph_receipt_path = verify_artifact_record(
        root, graph_record.get("receipt"), "V11O instance-graph receipt"
    )
    full_graph_path = verify_artifact_record(
        root, graph_record.get("full_json"), "V11O full Yosys JSON"
    )
    graph_result_path = verify_artifact_record(
        root, graph_record.get("result"), "V11O instance-graph result"
    )
    graph_result = load_json(graph_result_path)
    historical_graph_tool = (
        "npc/rv64/eval/ppa/tools/"
        "producer_holder_instance_graph.py"
    )
    graph_bindings = graph_result.get("bindings")
    if (
        historical_graph_tool not in manifest
        or not isinstance(graph_bindings, dict)
        or manifest[historical_graph_tool]
        != graph_bindings.get("tool_sha256")
    ):
        raise CoverageError(
            "V11O frozen graph-tool provenance is incomplete"
        )
    if load_json(reachability_path) != reachability:
        raise CoverageError(
            "V11O embedded reachability payload differs from receipt"
        )
    source_contract = reachability.get("source_contract")
    elaborated_contract = reachability.get("elaborated_contract")
    if (
        source_contract
        != {
            "product_top_binding": 1,
            "parameter_pass_through_count": 4,
            "legacy_birth_gate_count": 2,
            "legacy_valid_set_count": 2,
            "exact_token_capture_count": 2,
        }
        or not isinstance(elaborated_contract, dict)
        or elaborated_contract.get("design_id")
        != reachability.get("design_id")
        or elaborated_contract.get("product_instance")
        not in V11O_PRODUCT_INSTANCES
        or elaborated_contract.get("constant_zero_nets")
        != {
            "issue0_mem_buffer_fire_w": ["0"],
            "issue1_mem_buffer_fire_w": ["0"],
            "mem_buffer_req_valid_w": ["0"],
        }
    ):
        raise CoverageError(
            "V11O product source/elaboration contract is incomplete"
        )
    source_rows = reachability.get("sources")
    expected_product_sources = {
        "npc/rv64/vsrc/core/NpcCoreTop.v",
        "npc/rv64/vsrc/core/OooCoreTopGlue.v",
        "npc/rv64/vsrc/execute/OooExecuteBackend.v",
        "npc/rv64/vsrc/execute/OooAluCoreSlice.v",
        "npc/rv64/vsrc/decode/OooAluDecodeBackend.v",
        "npc/rv64/vsrc/execute/OooIntBackend.v",
    }
    if (
        not isinstance(source_rows, list)
        or {
            row.get("path")
            for row in source_rows
            if isinstance(row, dict)
        }
        != expected_product_sources
        or any(
            not isinstance(row, dict)
            or sha256_file(resolve_repo_path(root, row.get("path")))
            != row.get("sha256")
            for row in source_rows
        )
    ):
        raise CoverageError("V11O product parameter-chain source drifted")

    graph_receipt = load_json(graph_receipt_path)
    reachability_artifacts = reachability.get("artifacts")
    reachability_graph = (
        reachability_artifacts.get("instance_graph_receipt")
        if isinstance(reachability_artifacts, dict)
        else None
    )
    reachability_full = (
        reachability_artifacts.get("full_yosys_json")
        if isinstance(reachability_artifacts, dict)
        else None
    )
    if (
        graph_receipt.get("design_id") != reachability.get("design_id")
        or graph_receipt.get("full_yosys_json_sha256")
        != elaborated_contract.get("full_yosys_json_sha256")
        or not isinstance(reachability_graph, dict)
        or set(reachability_graph) != {"path", "sha256"}
        or reachability_graph.get("path")
        != relative(root, graph_receipt_path)
        or reachability_graph.get("sha256")
        != graph_record["receipt"].get("sha256")
        or not isinstance(reachability_full, dict)
        or set(reachability_full)
        != {"path", "sha256", "uncompressed_sha256"}
        or reachability_full.get("path") != relative(root, full_graph_path)
        or reachability_full.get("sha256")
        != graph_record["full_json"].get("sha256")
        or reachability_full.get("uncompressed_sha256")
        != graph_receipt.get("full_yosys_json_sha256")
    ):
        raise CoverageError("V11O full Yosys graph binding drifted")

    if (
        not isinstance(variants, list)
        or len(variants) != 8
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11O mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11O mutation record is not an object")
        name = record.get("name")
        receipts = record.get("receipts")
        if (
            name not in V11O_MUTATION_EXPECTATIONS
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", []))
            != V11O_MEMORY_BUFFER_TOKEN_UNIT_IDS
            or record.get("expected_stage")
            != V11O_MUTATION_EXPECTATIONS[name]
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11O mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11O mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(f"V11O mutation did not change RTL: {name}")
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 20
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11O profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11O profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11O profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11O profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11O profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11O compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11O compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11O_MEMORY_BUFFER_TOKEN_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11o_"
                    "memory_buffer_token"
                )
                != 1
                or log_text.count(
                    "[V11O-MEMORY-BUFFER-TOKEN-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11O_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11O production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11O profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11O_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11O_MEMORY_BUFFER_TOKEN_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11O-MEMORY-BUFFER-TOKEN-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or log_text.count(
                "[V11O-MEMORY-BUFFER-TOKEN-ORACLE][FAIL]"
            )
            != 1
            or failure_stages != [expected_stage]
            or "[V11O-MEMORY-BUFFER-TOKEN-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11o_" in log_text
        ):
            raise CoverageError(
                f"V11O release mutation escaped or was misbound: {name}"
            )
        if {
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        } != {variant_relative}:
            raise CoverageError(
                f"V11O mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11O_REGRESSIONS
    ):
        raise CoverageError("V11O regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11O regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11O regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11O regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11O regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11O-MEMORY-BUFFER-TOKEN-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11O regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11O regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
            artifact(root, relative(root, reachability_path)),
            artifact(root, relative(root, graph_receipt_path)),
            artifact(root, relative(root, full_graph_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 8,
            "mutation_simulations_rejected": 16,
            "product_static_negative_tests": 8,
            "ordinary_regressions_passed": 3,
            "product_parameter_chain_closed": True,
            "product_birth_and_request_constant_zero": True,
            "legacy_lane0_lane1_birth_closed": True,
            "legacy_hold_transfer_cancel_death_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11O_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_checker_replay": scope["a3_checker_replay"],
        },
    )


def evaluate_v11p_checkpoint_irrevocable_write(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11P_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": (
            "-DV11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED"
        ),
        "producer_gen_widths": [1, 4],
        "profile_count": 24,
        "baseline_profile_count": 4,
        "mutation_count": 10,
        "mutation_profile_count": 20,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_reset_allocation_schedule": True,
        "expected_pid_uses_holder_dut_state": False,
        "four_state_exact_comparison": True,
        "producer_generation_one_exercised": True,
        "producer_gen_width_one_and_four": True,
        "owner_token_28_high_bits_exercised": True,
        "store_physical_write_birth": True,
        "amo_physical_write_birth": True,
        "preterminal_hold": True,
        "postterminal_hold": True,
        "amo_tracker_death_before_retire": True,
        "checkpoint_live_mask_exact_onehot": True,
        "restore_blocked_until_exact_retire": True,
        "lane0_exact_retire": True,
        "wrong_generation_retire_rejected": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "semantic_units": payload.get("unit_ids"),
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "system_rerun": {
            "triggered_by_v11p": False,
            "run": False,
            "current_whole_design_recertification": (
                "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                "PRODUCTION_RTL_DELTA"
            ),
        },
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema")
        != V11P_CHECKPOINT_IRREVOCABLE_WRITE_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11P_CHECKPOINT_IRREVOCABLE_WRITE_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11P_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 24
        or counts.get("profiles_pass") != 24
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 10
        or counts.get("mutation_profiles_total") != 20
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11P checkpoint irreversible-write summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11P production OooIntBackend/TB source binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11P simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11P {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11P {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11P focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11P focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11p_checkpoint_irrevocable_write_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11p_checkpoint_irrevocable_write_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11P runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 10
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11P mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11P mutation record is not an object")
        name = record.get("name")
        expected_stage = V11P_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expected_stage is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", []))
            != V11P_CHECKPOINT_IRREVOCABLE_WRITE_UNIT_IDS
            or record.get("expected_stage") != expected_stage
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11P mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11P mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(f"V11P mutation did not change RTL: {name}")
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 24
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11P profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11P profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11P profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11P profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11P profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11P compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11P compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11p_"
                    "checkpoint_irrevocable_write"
                )
                != 1
                or log_text.count(
                    "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-MATRIX]"
                    "[PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11P_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11P production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11P profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11P_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or failure_stages != [expected_stage]
            or "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-MATRIX]"
            "[PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11p_" in log_text
        ):
            raise CoverageError(
                f"V11P release mutation escaped or was misbound: {name}"
            )
        if {
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        } != {variant_relative}:
            raise CoverageError(
                f"V11P mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11P_REGRESSIONS
    ):
        raise CoverageError("V11P regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11P regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11P regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11P regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11P regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11P-CHECKPOINT-IRREVOCABLE-WRITE-ORACLE][FAIL]"
            in log_text
        ):
            raise CoverageError(f"V11P regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11P regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 10,
            "mutation_simulations_rejected": 20,
            "ordinary_regressions_passed": 3,
            "store_and_amo_physical_write_birth_closed": True,
            "postterminal_holder_residency_closed": True,
            "amo_tracker_death_before_retire_closed": True,
            "full_width_lane0_retire_guard_closed": True,
            "restore_gate_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11P_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_checker_replay": scope["a3_checker_replay"],
        },
    )


def evaluate_v11q_int_lane0_packet(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11Q_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11Q_INT_LANE0_PACKET_FOCUSED",
        "producer_gen_widths": [1, 4],
        "profile_count": 28,
        "baseline_profile_count": 4,
        "mutation_count": 12,
        "mutation_profile_count": 24,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_allocation_schedule": True,
        "expected_pid_uses_packet_dut_state": False,
        "four_state_exact_comparison": True,
        "producer_generation_one_exercised": True,
        "nonzero_rob_index_two_exercised": True,
        "producer_gen_width_one_and_four": True,
        "raw_ex0_packet_slice_checked": True,
        "ex0_alias_checked_separately": True,
        "branch_packet_payload_checked": True,
        "raw_ex0_resolve_coherence_checked": True,
        "wrong_generation_rejected": True,
        "same_cycle_flush_cut_checked": True,
        "next_cycle_stage_empty_checked": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "mechanism": "integer-lane0-completion-resolve-paired-packet",
        "semantic_units": payload.get("unit_ids"),
        "excluded_units": [
            "integer-ex1-packed-alias",
            "integer-ex1-packet",
        ],
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "system_rerun": {
            "triggered_by_v11q": False,
            "run": False,
            "current_whole_design_recertification": (
                "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                "PRODUCTION_RTL_DELTA"
            ),
        },
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11Q_INT_LANE0_PACKET_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11Q_INT_LANE0_PACKET_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11Q_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 28
        or counts.get("profiles_pass") != 28
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 12
        or counts.get("mutation_profiles_total") != 24
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11Q integer lane0 packet summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    pipe_path = resolve_repo_path(root, production.get("pipe_stage_rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("pipe_stage_rtl")
        != "npc/rv64/vsrc/pipeline/PipeStageReg.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(pipe_path)
        != production.get("pipe_stage_rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11Q production OooIntBackend/PipeStageReg/TB binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11Q simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11Q {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11Q {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11Q focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11Q focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11q_int_lane0_packet_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11q_int_lane0_packet_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11Q runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 12
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11Q mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11Q mutation record is not an object")
        name = record.get("name")
        expected_stage = V11Q_MUTATION_EXPECTATIONS.get(name)
        expected_units = V11Q_MUTATION_UNIT_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expected_stage is None
            or expected_units is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", [])) != expected_units
            or record.get("expected_stage") != expected_stage
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11Q mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11Q mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(
                f"V11Q mutation did not change RTL: {name}"
            )
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 28
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11Q profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11Q profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11Q profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11Q profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11Q profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11Q compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11Q compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11Q_INT_LANE0_PACKET_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["pipe_stage_rtl"] not in compile_manifest
                or compile_manifest[production["pipe_stage_rtl"]]
                != production["pipe_stage_rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11q_int_lane0_packet"
                )
                != 1
                or log_text.count(
                    "[V11Q-INT-LANE0-PACKET-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11Q_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11Q production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11Q profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11Q_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11Q_INT_LANE0_PACKET_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11Q-INT-LANE0-PACKET-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or failure_stages != [expected_stage]
            or "[V11Q-INT-LANE0-PACKET-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11q_" in log_text
        ):
            raise CoverageError(
                f"V11Q release mutation escaped or was misbound: {name}"
            )
        if {
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        } != {variant_relative}:
            raise CoverageError(
                f"V11Q mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11Q_REGRESSIONS
    ):
        raise CoverageError("V11Q regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11Q regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11Q regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11Q regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or production["pipe_stage_rtl"] not in source_pre
            or source_pre[production["pipe_stage_rtl"]]
            != production["pipe_stage_rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11Q regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11Q-INT-LANE0-PACKET-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11Q regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11Q regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 12,
            "mutation_simulations_rejected": 24,
            "ordinary_regressions_passed": 3,
            "stimulus_owned_generation_one_index_two": True,
            "ex0_raw_packet_fields_closed": True,
            "ex0_packed_alias_closed": True,
            "branch_resolve_packet_fields_closed": True,
            "raw_ex0_resolve_full_pid_coherence_closed": True,
            "wrong_generation_negative_closed": True,
            "same_cycle_flush_and_next_cycle_death_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11Q_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_checker_replay": scope["a3_checker_replay"],
        },
    )


def evaluate_v11r_int_lane1_packet(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11R_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11R_INT_LANE1_PACKET_FOCUSED",
        "enable_dual_mem": 1,
        "producer_gen_widths": [1, 4],
        "profile_count": 32,
        "baseline_profile_count": 4,
        "mutation_count": 14,
        "mutation_profile_count": 28,
        "regression_count": 3,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_allocation_schedule": True,
        "expected_pid_uses_ex1_or_memory_holder_state": False,
        "four_state_exact_comparison": True,
        "producer_generation_one_exercised": True,
        "nonzero_rob_index_three_exercised": True,
        "producer_gen_width_one_and_four": True,
        "dual_dispatch_alu_source_checked": True,
        "lane1_local_memory_source_checked": True,
        "raw_ex1_packet_slice_checked": True,
        "ex1_alias_checked_separately": True,
        "result_and_pdest_checked": True,
        "exception_cause_tval_checked": True,
        "exact_rob_open_checked": True,
        "same_index_wrong_generation_not_claimed": True,
        "wrong_generation_rejected": True,
        "same_cycle_flush_cut_checked": True,
        "next_cycle_stage_empty_checked": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "mechanism": "integer-lane1-completion-packet",
        "semantic_units": payload.get("unit_ids"),
        "source_paths": [
            "lane1-fixed-latency-alu",
            "lane1-local-memory-completion",
        ],
        "excluded_units": [
            "floating-point-completion-paths",
            "remote-memory-response-completion",
        ],
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_execution_state": "COMPLETE",
        "a3_terminal_state": "COMPLETE",
        "a3_oracle_state": "OLD_ORACLE_INVALID",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "a3_interpretation": (
            "SYSTEM_TRANSACTION_COMPLETE_"
            "LEGACY_ORACLE_FALSE_POSITIVE"
        ),
        "system_rerun": {
            "triggered_by_v11r": False,
            "run": False,
            "current_whole_design_recertification": (
                "REQUIRED_BEFORE_PROMOTION_DUE_TO_PRIOR_"
                "PRODUCTION_RTL_DELTA"
            ),
        },
    }
    expected_promotion = {
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11R_INT_LANE1_PACKET_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11R_INT_LANE1_PACKET_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11R_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 32
        or counts.get("profiles_pass") != 32
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 14
        or counts.get("mutation_profiles_total") != 28
        or counts.get("regressions_total") != 3
        or counts.get("regressions_pass") != 3
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11R integer lane1 packet summary is not complete"
        )

    rtl_path = resolve_repo_path(root, production.get("rtl"))
    pipe_path = resolve_repo_path(root, production.get("pipe_stage_rtl"))
    focused_tb_path = resolve_repo_path(
        root, production.get("focused_testbench")
    )
    if (
        production.get("rtl")
        != "npc/rv64/vsrc/execute/OooIntBackend.v"
        or production.get("pipe_stage_rtl")
        != "npc/rv64/vsrc/pipeline/PipeStageReg.v"
        or production.get("focused_testbench")
        != "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        or sha256_file(rtl_path) != production.get("rtl_sha256")
        or sha256_file(pipe_path)
        != production.get("pipe_stage_rtl_sha256")
        or sha256_file(focused_tb_path)
        != production.get("focused_testbench_sha256")
    ):
        raise CoverageError(
            "V11R production OooIntBackend/PipeStageReg/TB binding drifted"
        )

    if not isinstance(tools, dict):
        raise CoverageError("V11R simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11R {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11R {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11R focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11R focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11r_int_lane1_packet_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11r_int_lane1_packet_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11R runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 14
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11R mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11R mutation record is not an object")
        name = record.get("name")
        expected_stage = V11R_MUTATION_EXPECTATIONS.get(name)
        expected_units = V11R_MUTATION_UNIT_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expected_stage is None
            or expected_units is None
            or record.get("target") != production.get("rtl")
            or set(record.get("unit_ids", [])) != expected_units
            or record.get("expected_stage") != expected_stage
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256")
            != production.get("rtl_sha256")
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11R mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11R mutation {name}",
        )
        if record.get("variant_sha256") == production.get("rtl_sha256"):
            raise CoverageError(
                f"V11R mutation did not change RTL: {name}"
            )
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 32
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11R profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11R profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11R profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11R profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11R profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11R compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11R compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11R_INT_LANE1_PACKET_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or production["rtl"] not in compile_manifest
                or compile_manifest[production["rtl"]]
                != production["rtl_sha256"]
                or production["pipe_stage_rtl"] not in compile_manifest
                or compile_manifest[production["pipe_stage_rtl"]]
                != production["pipe_stage_rtl_sha256"]
                or production["focused_testbench"]
                not in compile_manifest
                or compile_manifest[production["focused_testbench"]]
                != production["focused_testbench_sha256"]
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11r_int_lane1_packet"
                )
                != 1
                or log_text.count(
                    "[V11R-INT-LANE1-PACKET-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11R_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11R production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11R profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11R_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11R_INT_LANE1_PACKET_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11R-INT-LANE1-PACKET-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or production["rtl"] in compile_manifest
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or failure_stages != [expected_stage]
            or "[V11R-INT-LANE1-PACKET-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11r_" in log_text
        ):
            raise CoverageError(
                f"V11R release mutation escaped or was misbound: {name}"
            )
        if {
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        } != {variant_relative}:
            raise CoverageError(
                f"V11R mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 3
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11R_REGRESSIONS
    ):
        raise CoverageError("V11R regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11R regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11R regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11R regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or production["focused_testbench"] not in source_pre
            or production["rtl"] not in source_pre
            or source_pre[production["rtl"]]
            != production["rtl_sha256"]
            or production["pipe_stage_rtl"] not in source_pre
            or source_pre[production["pipe_stage_rtl"]]
            != production["pipe_stage_rtl_sha256"]
            or "npc/rv64/testbench/Makefile" not in source_pre
            or "npc/rv64/vsrc/include/define.v" not in source_pre
        ):
            raise CoverageError(
                f"V11R regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11R-INT-LANE1-PACKET-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11R regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11R regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 14,
            "mutation_simulations_rejected": 28,
            "ordinary_regressions_passed": 3,
            "stimulus_owned_generation_one_index_three": True,
            "ex1_alu_source_closed": True,
            "ex1_local_memory_source_closed": True,
            "ex1_raw_packet_fields_closed": True,
            "ex1_packed_alias_closed": True,
            "exact_open_and_full_pid_claim_closed": True,
            "wrong_generation_negative_closed": True,
            "same_cycle_flush_and_next_cycle_death_closed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11R_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_execution_state": scope["a3_execution_state"],
            "a3_terminal_state": scope["a3_terminal_state"],
            "a3_oracle_state": scope["a3_oracle_state"],
            "a3_checker_replay": scope["a3_checker_replay"],
            "a3_interpretation": scope["a3_interpretation"],
        },
    )


def render_v11s_focused_testbench(
    base_source: str,
    focused_fragment: str,
) -> tuple[str, list[dict[str, Any]]]:
    replacements = (
        (
            "task-fragment",
            V11S_TASK_INSERT_ANCHOR,
            (
                focused_fragment.rstrip()
                + "\n"
                + V11S_TASK_INSERT_ANCHOR
            ),
        ),
        (
            "initial-dispatch",
            V11S_INITIAL_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "    run_hist_ser_qh_younger_store_cycle();\n"
                "`elsif V11S_MULDIV_PRODUCER_FOCUSED\n"
                "    run_v11s_muldiv_producer_semantic();\n"
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
        (
            "finish-dispatch",
            V11S_FINISH_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_hist_ser_qh_younger_store");\n'
                "`elsif V11S_MULDIV_PRODUCER_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_v11s_muldiv_producer");\n'
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
    )
    rendered = base_source
    receipts: list[dict[str, Any]] = []
    for label, anchor, replacement_text in replacements:
        count = rendered.count(anchor)
        if count != 1:
            raise CoverageError(
                "V11S focused testbench anchor is not unique: "
                f"{label} count={count}"
            )
        rendered = rendered.replace(anchor, replacement_text, 1)
        receipts.append(
            {
                "label": label,
                "anchor_count": count,
                "anchor_sha256": hashlib.sha256(
                    anchor.encode("utf-8")
                ).hexdigest(),
                "replacement_sha256": hashlib.sha256(
                    replacement_text.encode("utf-8")
                ).hexdigest(),
            }
        )
    return rendered, receipts


def evaluate_v11s_muldiv_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    mutation_cases = frozenset(V11S_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11S_MULDIV_PRODUCER_FOCUSED",
        "enable_dual_mem": 1,
        "producer_gen_widths": [1, 4],
        "profile_count": 22,
        "baseline_profile_count": 4,
        "mutation_count": 9,
        "mutation_profile_count": 18,
        "regression_count": 4,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_allocation_schedule": True,
        "expected_pid_uses_muldiv_holder_state": False,
        "four_state_exact_comparison": True,
        "nonzero_generation_one_exercised": True,
        "nonzero_rob_index_two_exercised": True,
        "producer_gen_width_one_and_four": True,
        "mul_and_div_iterative_paths": True,
        "request_buffer_capture_checked": True,
        "iterative_hold_checked": True,
        "product_live_mask_checked": True,
        "wrong_generation_query_checked": True,
        "wrong_generation_authorization_rejected": True,
        "authorized_writeback_checked": True,
        "ordered_retirement_checked": True,
        "terminal_release_checked": True,
        "full_flush_death_checked": True,
        "eight_younger_dual_issue_pressure_checked": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "mechanism": "muldiv-producer-lifecycle",
        "semantic_units": payload.get("unit_ids"),
        "source_paths": [
            "mul-iterative-product-path",
            "divu-iterative-product-path",
            "full-flush-death",
            "leaf-kill-and-functional-regression",
        ],
        "excluded_units": [
            "clmul-producer",
            "floating-point-producer-paths",
            "pending-system-producer",
        ],
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_execution_state": "COMPLETE",
        "a3_terminal_state": "COMPLETE",
        "a3_oracle_state": "OLD_ORACLE_INVALID",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "a3_interpretation": (
            "SYSTEM_TRANSACTION_COMPLETE_"
            "LEGACY_ORACLE_FALSE_POSITIVE"
        ),
        "system_rerun": {
            "triggered_by_v11s": False,
            "run": False,
            "required_for_current_scope": False,
        },
    }
    expected_promotion = {
        "semantic_unit": "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11S_MULDIV_PRODUCER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or set(payload.get("unit_ids", []))
        != V11S_MULDIV_PRODUCER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11S_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 22
        or counts.get("profiles_pass") != 22
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 9
        or counts.get("mutation_profiles_total") != 18
        or counts.get("regressions_total") != 4
        or counts.get("regressions_pass") != 4
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError(
            "V11S MulDiv producer summary is not complete"
        )

    expected_production_paths = {
        "integration_rtl": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "muldiv_rtl": "npc/rv64/vsrc/execute/OooMulDivUnit.v",
        "base_testbench": V11S_BASE_TESTBENCH,
        "focused_testbench": V11S_FOCUSED_FRAGMENT,
        "leaf_testbench": (
            "npc/rv64/testbench/tests/tb_ooo_muldiv_unit.sv"
        ),
    }
    for key, expected_path in expected_production_paths.items():
        digest_key = f"{key}_sha256"
        if (
            production.get(key) != expected_path
            or sha256_file(resolve_repo_path(root, expected_path))
            != production.get(digest_key)
        ):
            raise CoverageError(
                f"V11S production binding drifted: {key}"
            )

    generated_testbench = verify_artifact_record(
        root,
        production.get("generated_testbench"),
        "V11S generated focused testbench",
    )
    expected_generated, expected_overlay_receipts = (
        render_v11s_focused_testbench(
            resolve_repo_path(
                root, production["base_testbench"]
            ).read_text(encoding="utf-8"),
            resolve_repo_path(
                root, production["focused_testbench"]
            ).read_text(encoding="utf-8"),
        )
    )
    if (
        generated_testbench.read_text(encoding="utf-8")
        != expected_generated
        or production.get("overlay_injection_receipts")
        != expected_overlay_receipts
    ):
        raise CoverageError(
            "V11S generated focused testbench overlay is invalid"
        )
    generated_relative = relative(root, generated_testbench)
    generated_sha256 = sha256_file(generated_testbench)

    if not isinstance(tools, dict):
        raise CoverageError("V11S simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11S {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11S {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11S focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11S focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11s_muldiv_producer_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11s_muldiv_producer_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11n_memory_pending_holder_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "run_v11m_memory_reservation_holder_semantic.py"
        ),
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11S runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 9
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11S mutation inventory is incomplete")
    variant_paths: dict[str, pathlib.Path] = {}
    integration_rtl = production["integration_rtl"]
    integration_sha = production["integration_rtl_sha256"]
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11S mutation record is not an object")
        name = record.get("name")
        expected_stage = V11S_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expected_stage is None
            or record.get("target") != integration_rtl
            or set(record.get("unit_ids", []))
            != V11S_MULDIV_PRODUCER_UNIT_IDS
            or record.get("expected_stage") != expected_stage
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256") != integration_sha
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(
                f"V11S mutation receipt is invalid: {name}"
            )
        variant_path = verify_path_sha(
            root,
            record.get("variant"),
            record.get("variant_sha256"),
            f"V11S mutation {name}",
        )
        if record.get("variant_sha256") == integration_sha:
            raise CoverageError(
                f"V11S mutation did not change RTL: {name}"
            )
        variant_paths[name] = variant_path

    if (
        not isinstance(profiles, list)
        or len(profiles) != 22
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11S profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11S profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11S profile failed: {name}")
        verify_path_sha(
            root,
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            f"V11S profile {name} image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11S profile {name} simulation log",
        )
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1]
            != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11S compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
            and pathlib.Path(item).is_file()
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11S compile source manifest is incomplete: {name}"
            )
        stale_inputs = stale_manifest_paths(root, compile_manifest)
        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11S_MULDIV_PRODUCER_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or integration_rtl not in compile_manifest
                or compile_manifest[integration_rtl] != integration_sha
                or production["muldiv_rtl"] not in compile_manifest
                or compile_manifest[production["muldiv_rtl"]]
                != production["muldiv_rtl_sha256"]
                or generated_relative
                not in compile_manifest
                or compile_manifest[generated_relative]
                != generated_sha256
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11s_muldiv_producer"
                )
                != 1
                or log_text.count(
                    "[V11S-MULDIV-PRODUCER-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11S_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11S production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(
            r"(.+)-g([14])-release", name
        )
        if not mutation_match:
            raise CoverageError(f"V11S profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11S_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11S_MULDIV_PRODUCER_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape(
                "[V11S-MULDIV-PRODUCER-ORACLE][FAIL]"
            )
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant_path = variant_paths.get(case)
        variant_relative = (
            relative(root, variant_path) if variant_path else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or variant_relative not in compile_manifest
            or compile_manifest.get(variant_relative)
            != sha256_file(variant_path)
            or integration_rtl in compile_manifest
            or production["muldiv_rtl"] not in compile_manifest
            or generated_relative not in compile_manifest
            or compile_manifest.get(generated_relative)
            != generated_sha256
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or failure_stages != [expected_stage]
            or "[V11S-MULDIV-PRODUCER-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11s_" in log_text
        ):
            raise CoverageError(
                f"V11S release mutation escaped or was misbound: {name}"
            )
        if {
            path_value
            for path_value in compile_manifest
            if "/variants/" in path_value
        } != {variant_relative}:
            raise CoverageError(
                f"V11S mutation compile selected wrong variant: {case}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 4
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11S_REGRESSIONS
    ):
        raise CoverageError("V11S regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11S regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11S regression {name}"
        )
        verify_artifact_record(
            root,
            record.get("compile_artifact"),
            f"V11S regression {name} image",
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        required_paths = {
            "npc/rv64/testbench/Makefile",
            "npc/rv64/vsrc/include/define.v",
            production["muldiv_rtl"],
        }
        if name == "tb_ooo_muldiv_unit":
            required_paths.add(production["leaf_testbench"])
        else:
            required_paths.update(
                {
                    production["integration_rtl"],
                    production["base_testbench"],
                }
            )
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or not required_paths.issubset(source_pre)
            or source_pre[production["muldiv_rtl"]]
            != production["muldiv_rtl_sha256"]
        ):
            raise CoverageError(
                f"V11S regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(
            encoding="utf-8", errors="replace"
        )
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11S-MULDIV-PRODUCER-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11S regression failed: {name}")
    regression_summary_path = (
        summary_path.parent / "regressions/summary.json"
    )
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11S regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, generated_testbench)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 9,
            "mutation_simulations_rejected": 18,
            "ordinary_regressions_passed": 4,
            "stimulus_owned_generation_one_index_two": True,
            "mul_and_div_iterative_paths_closed": True,
            "request_capture_and_holder_residency_closed": True,
            "exact_open_and_wrong_generation_negative_closed": True,
            "authorized_wb_and_ordered_retirement_closed": True,
            "terminal_release_and_full_flush_death_closed": True,
            "eight_younger_dual_issue_pressure_closed": True,
            "leaf_kill_and_functional_regression_closed": True,
            "focused_testbench_overlay_reconstructed": True,
            "production_design_id_current": payload["design_id"] == design_id,
            "product_instance_paths": sorted(V11S_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_execution_state": scope["a3_execution_state"],
            "a3_terminal_state": scope["a3_terminal_state"],
            "a3_oracle_state": scope["a3_oracle_state"],
            "a3_checker_replay": scope["a3_checker_replay"],
            "a3_interpretation": scope["a3_interpretation"],
        },
    )


def render_v11t_focused_testbench(
    base_source: str,
    focused_fragment: str,
) -> tuple[str, list[dict[str, Any]]]:
    replacements = (
        (
            "task-fragment",
            V11T_TASK_INSERT_ANCHOR,
            focused_fragment.rstrip() + "\n" + V11T_TASK_INSERT_ANCHOR,
        ),
        (
            "initial-dispatch",
            V11T_INITIAL_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "    run_hist_ser_qh_younger_store_cycle();\n"
                "`elsif V11T_CLMUL_PRODUCER_FOCUSED\n"
                "    run_v11t_clmul_producer_semantic();\n"
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
        (
            "finish-dispatch",
            V11T_FINISH_INSERT_ANCHOR,
            (
                "`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_hist_ser_qh_younger_store");\n'
                "`elsif V11T_CLMUL_PRODUCER_FOCUSED\n"
                "        tb_finish("
                '"tb_ooo_int_backend_v11t_clmul_producer");\n'
                "`elsif V11R_INT_LANE1_PACKET_FOCUSED\n"
            ),
        ),
    )
    rendered = base_source
    receipts: list[dict[str, Any]] = []
    for label, anchor, replacement_text in replacements:
        count = rendered.count(anchor)
        if count != 1:
            raise CoverageError(
                "V11T focused testbench anchor is not unique: "
                f"{label} count={count}"
            )
        rendered = rendered.replace(anchor, replacement_text, 1)
        receipts.append(
            {
                "label": label,
                "anchor_count": count,
                "anchor_sha256": hashlib.sha256(
                    anchor.encode("utf-8")
                ).hexdigest(),
                "replacement_sha256": hashlib.sha256(
                    replacement_text.encode("utf-8")
                ).hexdigest(),
            }
        )
    return rendered, receipts


def evaluate_v11t_clmul_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    if spec.get("artifact_cleanup") != V11T_ARTIFACT_CLEANUP:
        raise CoverageError("V11T cleanup artifact binding is invalid")
    cleanup_path = resolve_repo_path(root, V11T_ARTIFACT_CLEANUP)
    cleanup_root = cleanup_path.parent
    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    cleanup = payload.get("artifact_cleanup")
    mutation_cases = frozenset(V11T_MUTATION_EXPECTATIONS)
    expected_profiles = {
        f"production-g{width}-{mode}"
        for width in (1, 4)
        for mode in ("assert", "release")
    } | {
        f"{case}-g{width}-release"
        for case in mutation_cases
        for width in (1, 4)
    }
    expected_configuration = {
        "top": "tb_ooo_int_backend",
        "focused_define": "-DV11T_CLMUL_PRODUCER_FOCUSED",
        "producer_gen_widths": [1, 4],
        "profile_count": 22,
        "baseline_profile_count": 4,
        "mutation_count": 9,
        "mutation_profile_count": 18,
        "regression_count": 4,
        "baseline_assert_and_release": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
        "stimulus_owned_allocation_schedule": True,
        "expected_pid_uses_clmul_holder_state": False,
        "four_state_exact_comparison": True,
        "nonzero_generation_one_exercised": True,
        "nonzero_rob_index_two_exercised": True,
        "producer_gen_width_one_and_four": True,
        "clmul_and_clmulh_paths": True,
        "request_capture_checked": True,
        "run_and_response_hold_checked": True,
        "product_live_mask_checked": True,
        "wrong_generation_query_checked": True,
        "wrong_generation_authorization_rejected": True,
        "authorized_writeback_checked": True,
        "ordered_retirement_checked": True,
        "terminal_release_checked": True,
        "full_flush_death_checked": True,
        "release_mode_mutation_rejection": True,
    }
    expected_scope = {
        "mechanism": "clmul-producer-lifecycle",
        "semantic_units": payload.get("unit_ids"),
        "source_paths": [
            "clmul-low-product-path",
            "clmul-high-product-path",
            "full-flush-death",
            "leaf-kill-and-functional-regression",
        ],
        "excluded_units": [
            "floating-point-producer-paths",
            "pending-system-producer",
        ],
        "eight_younger_pressure": "NOT_RUN_IN_V11T",
        "global_no_live_reuse": "NOT_PROVEN",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "production_rtl_change": False,
        "a3_original_status": "FAIL_RETAINED",
        "a3_execution_state": "COMPLETE",
        "a3_terminal_state": "COMPLETE",
        "a3_oracle_state": "OLD_ORACLE_INVALID",
        "a3_checker_replay": "PASS_INDEPENDENT",
        "a3_interpretation": (
            "SYSTEM_TRANSACTION_COMPLETE_"
            "LEGACY_ORACLE_FALSE_POSITIVE"
        ),
        "system_rerun": {
            "triggered_by_v11t": False,
            "run": False,
            "required_for_current_scope": False,
        },
    }
    expected_promotion = {
        "semantic_unit": "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    if (
        payload.get("schema") != V11T_CLMUL_PRODUCER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or payload.get("design_id") != design_id
        or set(payload.get("unit_ids", []))
        != V11T_CLMUL_PRODUCER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11T_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
        or not isinstance(counts, dict)
        or counts.get("profiles_total") != 22
        or counts.get("profiles_pass") != 22
        or counts.get("profiles_fail") != 0
        or counts.get("baseline_profiles_total") != 4
        or counts.get("mutations_total") != 9
        or counts.get("mutation_profiles_total") != 18
        or counts.get("regressions_total") != 4
        or counts.get("regressions_pass") != 4
        or scope != expected_scope
        or promotion != expected_promotion
    ):
        raise CoverageError("V11T CLMUL producer summary is not complete")

    expected_production_paths = {
        "integration_rtl": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "clmul_rtl": "npc/rv64/vsrc/execute/OooClmulUnit.v",
        "base_testbench": V11T_BASE_TESTBENCH,
        "focused_testbench": V11T_FOCUSED_FRAGMENT,
        "leaf_testbench": "npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv",
    }
    for key, expected_path in expected_production_paths.items():
        if (
            production.get(key) != expected_path
            or sha256_file(resolve_repo_path(root, expected_path))
            != production.get(f"{key}_sha256")
        ):
            raise CoverageError(f"V11T production binding drifted: {key}")

    cleanup_payload = load_json(cleanup_path)
    removed = cleanup.get("removed") if isinstance(cleanup, dict) else None
    if (
        cleanup_payload != cleanup
        or set(cleanup) != {"status", "policy", "removed_count", "removed"}
        or cleanup.get("status") != "PASS"
        or cleanup.get("policy")
        != "retain-results-logs-and-hashes-only"
        or cleanup.get("removed_count") != 36
        or not isinstance(removed, list)
        or len(removed) != 36
    ):
        raise CoverageError("V11T compact artifact cleanup is incomplete")
    removed_by_path: dict[str, dict[str, Any]] = {}
    for record in removed:
        if (
            not isinstance(record, dict)
            or set(record)
            != {
                "path",
                "sha256",
                "size_bytes",
                "kind",
                "removed_after_validation",
            }
            or record.get("removed_after_validation") is not True
            or re.fullmatch(r"[0-9a-f]{64}", str(record.get("sha256", "")))
            is None
            or not isinstance(record.get("size_bytes"), int)
            or record["size_bytes"] <= 0
            or record.get("path") in removed_by_path
        ):
            raise CoverageError("V11T retired artifact record is invalid")
        retired_path = resolve_repo_path(root, record["path"])
        try:
            retired_path.relative_to(cleanup_root)
        except ValueError as exc:
            raise CoverageError(
                "V11T retired artifact escapes the evidence attempt"
            ) from exc
        if retired_path.exists():
            raise CoverageError("V11T retired artifact still exists")
        removed_by_path[record["path"]] = record
    kind_counts = {
        kind: sum(item["kind"] == kind for item in removed)
        for kind in {
            "focused-compile-image",
            "regression-compile-image",
            "generated-negative-rtl",
            "generated-focused-testbench",
        }
    }
    if kind_counts != {
        "focused-compile-image": 22,
        "regression-compile-image": 4,
        "generated-negative-rtl": 9,
        "generated-focused-testbench": 1,
    }:
        raise CoverageError("V11T retired artifact inventory is incomplete")

    def require_retired(
        path_value: Any,
        digest: Any,
        kind: str,
        size: Any = None,
    ) -> dict[str, Any]:
        record = removed_by_path.get(path_value)
        if (
            not isinstance(path_value, str)
            or not isinstance(digest, str)
            or record is None
            or record.get("sha256") != digest
            or record.get("kind") != kind
            or (size is not None and record.get("size_bytes") != size)
        ):
            raise CoverageError(
                f"V11T retired artifact binding is invalid: {path_value}"
            )
        return record

    expected_generated, expected_overlay_receipts = (
        render_v11t_focused_testbench(
            resolve_repo_path(root, production["base_testbench"]).read_text(
                encoding="utf-8"
            ),
            resolve_repo_path(root, production["focused_testbench"]).read_text(
                encoding="utf-8"
            ),
        )
    )
    generated_record = production.get("generated_testbench")
    generated_bytes = expected_generated.encode("utf-8")
    generated_sha = hashlib.sha256(generated_bytes).hexdigest()
    if (
        not isinstance(generated_record, dict)
        or set(generated_record) != {"path", "sha256", "size_bytes"}
        or generated_record.get("sha256") != generated_sha
        or generated_record.get("size_bytes") != len(generated_bytes)
        or production.get("overlay_injection_receipts")
        != expected_overlay_receipts
    ):
        raise CoverageError(
            "V11T generated focused testbench overlay is invalid"
        )
    generated_relative = generated_record["path"]
    require_retired(
        generated_relative,
        generated_sha,
        "generated-focused-testbench",
        len(generated_bytes),
    )

    if not isinstance(tools, dict):
        raise CoverageError("V11T simulator identity is missing")
    for name in ("iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11T {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11T {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11T focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11T focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        "npc/rv64/testbench/scripts/run_v11t_clmul_producer_semantic.py",
        "npc/rv64/testbench/scripts/test_run_v11t_clmul_producer_semantic.py",
        "npc/rv64/testbench/scripts/run_v11s_muldiv_producer_semantic.py",
        "npc/rv64/testbench/scripts/run_v11n_memory_pending_holder_semantic.py",
        "npc/rv64/testbench/scripts/run_v11m_memory_reservation_holder_semantic.py",
    }
    missing_support = sorted(support_paths - set(manifest))
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if missing_support or stale_support:
        raise CoverageError(
            "V11T runner/checker binding drifted: "
            f"missing={missing_support} stale={stale_support}"
        )

    if (
        not isinstance(variants, list)
        or len(variants) != 9
        or {
            item.get("name")
            for item in variants
            if isinstance(item, dict)
        }
        != mutation_cases
    ):
        raise CoverageError("V11T mutation inventory is incomplete")
    variant_records: dict[str, dict[str, Any]] = {}
    integration_rtl = production["integration_rtl"]
    integration_sha = production["integration_rtl_sha256"]
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11T mutation record is not an object")
        name = record.get("name")
        expected_stage = V11T_MUTATION_EXPECTATIONS.get(name)
        receipts = record.get("receipts")
        if (
            expected_stage is None
            or record.get("target") != integration_rtl
            or set(record.get("unit_ids", []))
            != V11T_CLMUL_PRODUCER_UNIT_IDS
            or record.get("expected_stage") != expected_stage
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or record.get("production_sha256") != integration_sha
            or record.get("variant_sha256") == integration_sha
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or not isinstance(receipt.get("purpose"), str)
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(f"V11T mutation receipt is invalid: {name}")
        require_retired(
            record.get("variant"),
            record.get("variant_sha256"),
            "generated-negative-rtl",
        )
        variant_records[name] = record

    if (
        not isinstance(profiles, list)
        or len(profiles) != 22
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11T profile inventory is incomplete")
    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11T profile record is not an object")
        name = record.get("profile")
        compile_record = record.get("compile")
        simulation = record.get("simulation")
        markers = record.get("markers")
        compile_manifest = record.get("compile_source_manifest")
        if (
            not isinstance(name, str)
            or record.get("status") != "PASS"
            or not isinstance(compile_record, dict)
            or compile_record.get("rc") != 0
            or compile_record.get("timeout") is not False
            or compile_record.get("artifact_exists") is not True
            or not isinstance(simulation, dict)
            or simulation.get("timeout") is not False
            or not isinstance(markers, dict)
            or not isinstance(compile_manifest, dict)
            or not compile_manifest
        ):
            raise CoverageError(f"V11T profile failed: {name}")
        require_retired(
            compile_record.get("artifact"),
            compile_record.get("artifact_sha256"),
            "focused-compile-image",
        )
        log_path = verify_path_sha(
            root,
            simulation.get("log"),
            simulation.get("log_sha256"),
            f"V11T profile {name} simulation log",
        )
        log_text = log_path.read_text(encoding="utf-8", errors="replace")
        command = compile_record.get("command")
        defines = compile_record.get("defines")
        if (
            not isinstance(command, list)
            or not all(isinstance(item, str) for item in command)
            or not isinstance(defines, list)
            or not all(isinstance(item, str) for item in defines)
            or not command
            or command[0] != tools["iverilog"]
            or "-s" not in command
            or command[command.index("-s") + 1] != configuration["top"]
            or any(command.count(define) != 1 for define in defines)
        ):
            raise CoverageError(
                f"V11T compile command binding is invalid: {name}"
            )
        command_sources = {
            relative(root, pathlib.Path(item))
            for item in command
            if pathlib.Path(item).is_absolute()
            and pathlib.Path(item).suffix in {".v", ".sv"}
        }
        if command_sources != set(compile_manifest):
            raise CoverageError(
                f"V11T compile source manifest is incomplete: {name}"
            )
        stale_inputs: list[str] = []
        for path_value, digest in compile_manifest.items():
            if path_value == generated_relative:
                expected_digest = generated_sha
            elif "/variants/" in path_value:
                variant = next(
                    (
                        item
                        for item in variant_records.values()
                        if item.get("variant") == path_value
                    ),
                    None,
                )
                expected_digest = (
                    variant.get("variant_sha256")
                    if isinstance(variant, dict)
                    else None
                )
            else:
                live_path = resolve_repo_path(root, path_value)
                expected_digest = (
                    sha256_file(live_path) if live_path.is_file() else None
                )
            if expected_digest != digest:
                stale_inputs.append(path_value)

        baseline_match = re.fullmatch(
            r"production-g([14])-(assert|release)", name
        )
        if baseline_match:
            width = int(baseline_match.group(1))
            mode = baseline_match.group(2)
            expected_defines = [
                "-DV11T_CLMUL_PRODUCER_FOCUSED",
                f"-DOOO_PRODUCER_GEN_W={width}",
            ]
            if mode == "assert":
                expected_defines.append("-DOOO_ASSERT")
            if (
                record.get("producer_gen_width") != width
                or record.get("kind") != "baseline"
                or record.get("mutation") is not None
                or record.get("expected_stage") is not None
                or record.get("assertions") is not (mode == "assert")
                or defines != expected_defines
                or stale_inputs
                or compile_manifest.get(integration_rtl) != integration_sha
                or compile_manifest.get(production["clmul_rtl"])
                != production["clmul_rtl_sha256"]
                or compile_manifest.get(generated_relative) != generated_sha
                or simulation.get("rc") != 0
                or markers.get("tb_pass") != 1
                or markers.get("matrix_pass") != 1
                or markers.get("oracle_fail") != 0
                or log_text.count(
                    "[PASS] tb_ooo_int_backend_v11t_clmul_producer"
                )
                != 1
                or log_text.count(
                    "[V11T-CLMUL-PRODUCER-MATRIX][PASS]"
                )
                != 1
                or any(
                    markers.get(marker_text) != expected_count
                    or log_text.count(marker_text) != expected_count
                    for marker_text, expected_count
                    in V11T_BASELINE_MARKERS.items()
                )
            ):
                raise CoverageError(
                    f"V11T production profile is not clean: {name}"
                )
            continue

        mutation_match = re.fullmatch(r"(.+)-g([14])-release", name)
        if not mutation_match:
            raise CoverageError(f"V11T profile name is invalid: {name}")
        case = mutation_match.group(1)
        width = int(mutation_match.group(2))
        expected_stage = V11T_MUTATION_EXPECTATIONS.get(case)
        expected_defines = [
            "-DV11T_CLMUL_PRODUCER_FOCUSED",
            f"-DOOO_PRODUCER_GEN_W={width}",
        ]
        failure_stages = re.findall(
            re.escape("[V11T-CLMUL-PRODUCER-ORACLE][FAIL]")
            + r" stage=([A-Za-z0-9_-]+)(?=[ \t\r\n@]|$)",
            log_text,
        )
        variant = variant_records.get(case)
        variant_relative = (
            variant.get("variant") if isinstance(variant, dict) else None
        )
        if (
            expected_stage is None
            or record.get("producer_gen_width") != width
            or record.get("kind") != "mutation"
            or record.get("mutation") != case
            or record.get("expected_stage") != expected_stage
            or record.get("assertions") is not False
            or defines != expected_defines
            or stale_inputs
            or compile_manifest.get(variant_relative)
            != variant.get("variant_sha256")
            or integration_rtl in compile_manifest
            or compile_manifest.get(production["clmul_rtl"])
            != production["clmul_rtl_sha256"]
            or compile_manifest.get(generated_relative) != generated_sha
            or not isinstance(simulation.get("rc"), int)
            or simulation["rc"] == 0
            or markers.get("oracle_fail") != 1
            or markers.get("tb_pass") != 0
            or markers.get("matrix_pass") != 0
            or failure_stages != [expected_stage]
            or "[V11T-CLMUL-PRODUCER-MATRIX][PASS]" in log_text
            or "[PASS] tb_ooo_int_backend_v11t_" in log_text
            or {
                path_value
                for path_value in compile_manifest
                if "/variants/" in path_value
            }
            != {variant_relative}
        ):
            raise CoverageError(
                f"V11T release mutation escaped or was misbound: {name}"
            )

    if (
        not isinstance(regressions, list)
        or len(regressions) != 4
        or {
            item.get("test")
            for item in regressions
            if isinstance(item, dict)
        }
        != V11T_REGRESSIONS
    ):
        raise CoverageError("V11T regression inventory is incomplete")
    for record in regressions:
        if not isinstance(record, dict):
            raise CoverageError("V11T regression record is not an object")
        name = record.get("test")
        log_path = verify_artifact_record(
            root, record.get("log"), f"V11T regression {name}"
        )
        compile_artifact = record.get("compile_artifact")
        if not isinstance(compile_artifact, dict):
            raise CoverageError(
                f"V11T regression compile record is absent: {name}"
            )
        require_retired(
            compile_artifact.get("path"),
            compile_artifact.get("sha256"),
            "regression-compile-image",
            compile_artifact.get("size_bytes"),
        )
        source_pre = record.get("compile_source_manifest")
        source_post = record.get("compile_source_post_manifest")
        required_paths = {
            "npc/rv64/testbench/Makefile",
            "npc/rv64/vsrc/include/define.v",
            production["clmul_rtl"],
        }
        if name == "tb_ooo_clmul_unit":
            required_paths.add(production["leaf_testbench"])
        else:
            required_paths.update(
                {production["integration_rtl"], production["base_testbench"]}
            )
        if (
            record.get("status") != "PASS"
            or record.get("source_pre_post_match") is not True
            or not isinstance(source_pre, dict)
            or not source_pre
            or source_pre != source_post
            or not required_paths.issubset(source_pre)
            or source_pre[production["clmul_rtl"]]
            != production["clmul_rtl_sha256"]
        ):
            raise CoverageError(
                f"V11T regression binding is incomplete: {name}"
            )
        stale = stale_manifest_paths(root, source_pre)
        log_text = log_path.read_text(encoding="utf-8", errors="replace")
        if (
            stale
            or log_text.count(f"[PASS] {name}") != 1
            or log_text.count("[RESULT] PASS") != 1
            or "[RESULT] FAIL" in log_text
            or "[V11T-CLMUL-PRODUCER-ORACLE][FAIL]" in log_text
        ):
            raise CoverageError(f"V11T regression failed: {name}")
    regression_summary_path = summary_path.parent / "regressions/summary.json"
    regression_summary = load_json(regression_summary_path)
    if (
        regression_summary.get("status") != "PASS"
        or regression_summary.get("command_rc") != 0
        or regression_summary.get("timeout") is not False
        or regression_summary.get("all_source_pre_post_match") is not True
        or regression_summary.get("tests") != regressions
        or not isinstance(regression_summary.get("command"), list)
    ):
        raise CoverageError("V11T regression summary is not PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, cleanup_path)),
            artifact(root, relative(root, regression_summary_path)),
        ],
        {
            "positive_profiles": 4,
            "compile_success_mutation_cases_rejected": 9,
            "mutation_simulations_rejected": 18,
            "ordinary_regressions_passed": 4,
            "stimulus_owned_generation_one_index_two": True,
            "clmul_low_and_high_paths_closed": True,
            "request_capture_and_holder_residency_closed": True,
            "exact_open_and_wrong_generation_negative_closed": True,
            "authorized_wb_and_ordered_retirement_closed": True,
            "terminal_release_and_full_flush_death_closed": True,
            "leaf_kill_and_functional_regression_closed": True,
            "eight_younger_pressure_closed": False,
            "focused_testbench_overlay_reconstructed": True,
            "retired_compile_artifacts_validated": 36,
            "production_design_id_current": True,
            "product_instance_paths": sorted(V11T_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_execution_state": scope["a3_execution_state"],
            "a3_terminal_state": scope["a3_terminal_state"],
            "a3_oracle_state": scope["a3_oracle_state"],
            "a3_checker_replay": scope["a3_checker_replay"],
            "a3_interpretation": scope["a3_interpretation"],
        },
    )


def evaluate_v11u_pending_system_producer(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> tuple[str, list[dict[str, Any]], dict[str, Any]]:
    summary_path = resolve_repo_path(root, spec["summary"])
    if spec.get("artifact_cleanup") != V11U_ARTIFACT_CLEANUP:
        raise CoverageError("V11U cleanup artifact binding is invalid")
    cleanup_path = resolve_repo_path(root, V11U_ARTIFACT_CLEANUP)
    attempt_root = cleanup_path.parent

    payload = load_json(summary_path)
    production = payload.get("production")
    binding = payload.get("binding")
    configuration = payload.get("configuration")
    oracle = payload.get("independent_oracle")
    counts = payload.get("counts")
    profiles = payload.get("profiles")
    variants = payload.get("variants")
    regressions = payload.get("regressions")
    scope = payload.get("scope")
    promotion = payload.get("promotion")
    tools = payload.get("tools")
    cleanup = payload.get("artifact_cleanup")
    expected_configuration = {
        "producer_gen_widths": [1, 4],
        "positive_profile_count": 9,
        "assertion_negative_profile_count": 3,
        "mutation_count": 10,
        "mutation_profile_count": 12,
        "profile_count": 24,
        "regression_count": 4,
        "assert_and_release_baseline": True,
        "mutations_release_mode": True,
        "full_system_run": False,
    }
    expected_oracle = {
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
        "assertion_negative_rejection": True,
        "compile_success_release_mutation_rejection": True,
    }
    expected_scope = {
        "mechanism": "pending-system-producer-lifecycle",
        "semantic_units": ["pending-system-producer"],
        "source_paths": [
            "pre-rob-csr-holder",
            "rob-allocation-birth",
            "raw-q-lease-hold",
            "exact-commit-and-flush-death",
            "global-live-mask-reuse-fence",
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
    }
    expected_promotion = {
        "semantic_unit": "ELIGIBLE_IF_LEDGER_REBIND_AND_REVIEW_PASS",
        "whole_architecture": "RED",
        "ppa": "UNPROMOTED",
        "system_recertification": "NOT_RUN",
    }
    expected_counts = {
        "profiles_total": 24,
        "profiles_pass": 24,
        "positive_profiles_total": 9,
        "assertion_negative_profiles_total": 3,
        "mutations_total": 10,
        "mutation_profiles_total": 12,
        "regressions_total": 4,
        "regressions_pass": 4,
        "retired_artifacts": 42,
    }
    if (
        payload.get("schema") != V11U_PENDING_SYSTEM_PRODUCER_SCHEMA
        or payload.get("status") != "PASS"
        or payload.get("classification") != "verification"
        or payload.get("design_id") != design_id
        or set(payload.get("unit_ids", []))
        != V11U_PENDING_SYSTEM_PRODUCER_UNIT_IDS
        or configuration != expected_configuration
        or oracle != expected_oracle
        or counts != expected_counts
        or scope != expected_scope
        or promotion != expected_promotion
        or not isinstance(production, dict)
        or set(production.get("product_instances", []))
        != V11U_PRODUCT_INSTANCES
        or not isinstance(binding, dict)
        or binding.get("pre_post_match") is not True
    ):
        raise CoverageError(
            "V11U pending-system producer summary is not complete"
        )

    expected_production_paths = {
        "sequencer_rtl": (
            "npc/rv64/vsrc/control/OooPendingSystemSequencer.v"
        ),
        "csr_mux_rtl": (
            "npc/rv64/vsrc/control/OooCsrAccessRequestMux.v"
        ),
        "int_backend_rtl": "npc/rv64/vsrc/execute/OooIntBackend.v",
        "sequencer_testbench": (
            "npc/rv64/testbench/tests/"
            "tb_ooo_pending_system_sequencer.sv"
        ),
        "lease_probe_testbench": (
            "npc/rv64/testbench/tests/"
            "tb_ooo_pending_system_lease_probe.sv"
        ),
        "csr_mux_testbench": (
            "npc/rv64/testbench/tests/"
            "tb_ooo_csr_access_request_mux.sv"
        ),
        "int_backend_testbench": (
            "npc/rv64/testbench/tests/tb_ooo_int_backend.sv"
        ),
    }
    if set(production) != {
        "product_instances",
        *expected_production_paths,
        *(f"{key}_sha256" for key in expected_production_paths),
    }:
        raise CoverageError("V11U production binding inventory is invalid")
    for key, expected_path in expected_production_paths.items():
        live_path = resolve_repo_path(root, expected_path)
        if (
            production.get(key) != expected_path
            or not live_path.is_file()
            or sha256_file(live_path)
            != production.get(f"{key}_sha256")
        ):
            raise CoverageError(f"V11U production binding drifted: {key}")

    if not isinstance(tools, dict) or set(tools) != {
        "make",
        "make_sha256",
        "iverilog",
        "iverilog_sha256",
        "vvp",
        "vvp_sha256",
    }:
        raise CoverageError("V11U EDA tool identity is missing")
    for name in ("make", "iverilog", "vvp"):
        path_value = tools.get(name)
        digest = tools.get(f"{name}_sha256")
        if not isinstance(path_value, str) or not isinstance(digest, str):
            raise CoverageError(f"V11U {name} identity is incomplete")
        tool_path = pathlib.Path(path_value)
        if not tool_path.is_file() or sha256_file(tool_path) != digest:
            raise CoverageError(f"V11U {name} identity drifted")

    pre_path = verify_artifact_record(
        root, binding.get("source_before"), "V11U focused source pre"
    )
    post_path = verify_artifact_record(
        root, binding.get("source_after"), "V11U focused source post"
    )
    binding_state, selected_records, manifest = (
        validate_current_manifest_selected_binding(
            root, spec, pre_path, post_path
        )
    )
    support_paths = {
        "npc/rv64/testbench/Makefile",
        (
            "npc/rv64/testbench/scripts/"
            "run_v11u_pending_system_producer_semantic.py"
        ),
        (
            "npc/rv64/testbench/scripts/"
            "test_run_v11u_pending_system_producer_semantic.py"
        ),
        "npc/rv64/vsrc/include/define.v",
    }
    expected_manifest_paths = support_paths | {
        item[0] for item in V11_SELECTED_BINDINGS[spec["binding_kind"]]
    }
    stale_support = stale_manifest_paths(root, manifest, support_paths)
    if set(manifest) != expected_manifest_paths or stale_support:
        raise CoverageError(
            "V11U runner/checker binding drifted: "
            f"inventory={sorted(set(manifest) ^ expected_manifest_paths)} "
            f"stale={stale_support}"
        )

    cleanup_payload = load_json(cleanup_path)
    removed = cleanup.get("removed") if isinstance(cleanup, dict) else None
    if (
        cleanup_payload != cleanup
        or not isinstance(cleanup, dict)
        or set(cleanup) != {"status", "policy", "removed_count", "removed"}
        or cleanup.get("status") != "PASS"
        or cleanup.get("policy")
        != "retain-results-logs-hashes-and-summary-only"
        or cleanup.get("removed_count") != 42
        or not isinstance(removed, list)
        or len(removed) != 42
    ):
        raise CoverageError("V11U compact artifact cleanup is incomplete")
    removed_by_path: dict[str, dict[str, Any]] = {}
    for record in removed:
        if (
            not isinstance(record, dict)
            or set(record)
            != {
                "path",
                "sha256",
                "size_bytes",
                "kind",
                "removed_after_validation",
            }
            or record.get("removed_after_validation") is not True
            or re.fullmatch(
                r"[0-9a-f]{64}", str(record.get("sha256", ""))
            )
            is None
            or not isinstance(record.get("size_bytes"), int)
            or record["size_bytes"] <= 0
            or record.get("path") in removed_by_path
        ):
            raise CoverageError("V11U retired artifact record is invalid")
        retired_path = resolve_repo_path(root, record["path"])
        try:
            retired_path.relative_to(attempt_root)
        except ValueError as exc:
            raise CoverageError(
                "V11U retired artifact escapes the evidence attempt"
            ) from exc
        if retired_path.exists():
            raise CoverageError("V11U retired artifact still exists")
        removed_by_path[record["path"]] = record
    kind_counts = {
        kind: sum(item["kind"] == kind for item in removed)
        for kind in {
            "focused-compile-image",
            "regression-compile-image",
            "generated-negative-rtl",
        }
    }
    if kind_counts != {
        "focused-compile-image": 28,
        "regression-compile-image": 4,
        "generated-negative-rtl": 10,
    }:
        raise CoverageError("V11U retired artifact inventory is incomplete")

    def require_retired(
        record: Any, kind: str, label: str
    ) -> dict[str, Any]:
        if not isinstance(record, dict) or set(record) != {
            "path",
            "sha256",
            "size_bytes",
        }:
            raise CoverageError(f"V11U {label} record is invalid")
        retired = removed_by_path.get(record["path"])
        if (
            retired is None
            or retired.get("kind") != kind
            or retired.get("sha256") != record.get("sha256")
            or retired.get("size_bytes") != record.get("size_bytes")
        ):
            raise CoverageError(f"V11U {label} cleanup binding is invalid")
        return retired

    if (
        not isinstance(variants, list)
        or len(variants) != 10
        or {
            item.get("name") for item in variants if isinstance(item, dict)
        }
        != set(V11U_MUTATIONS)
    ):
        raise CoverageError("V11U mutation inventory is incomplete")
    variant_records: dict[str, dict[str, Any]] = {}
    for record in variants:
        if not isinstance(record, dict):
            raise CoverageError("V11U mutation record is not an object")
        name = record.get("name")
        expected = V11U_MUTATIONS.get(name)
        receipts = record.get("receipts")
        target = expected.get("target") if expected else None
        expected_variant = (
            relative(
                root,
                attempt_root
                / "variants"
                / f"{name}-{pathlib.Path(target).name}",
            )
            if isinstance(name, str) and isinstance(target, str)
            else None
        )
        if (
            expected is None
            or record.get("unit_ids") != ["pending-system-producer"]
            or record.get("target") != target
            or record.get("target_sha256")
            != sha256_file(resolve_repo_path(root, target))
            or record.get("variant") != expected_variant
            or record.get("variant_sha256")
            == record.get("target_sha256")
            or re.fullmatch(
                r"[0-9a-f]{64}", str(record.get("variant_sha256", ""))
            )
            is None
            or record.get("override") != expected["override"]
            or record.get("test") != expected["test"]
            or tuple(record.get("widths", [])) != expected["widths"]
            or tuple(record.get("extra_defines", []))
            != expected["defines"]
            or record.get("expected_marker") != expected["marker"]
            or record.get("compile_success_required") is not True
            or record.get("assertions") is not False
            or not isinstance(receipts, list)
            or not receipts
            or any(
                not isinstance(receipt, dict)
                or receipt.get("anchor_count") != 1
                or not isinstance(receipt.get("purpose"), str)
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("anchor_sha256", "")),
                )
                is None
                or re.fullmatch(
                    r"[0-9a-f]{64}",
                    str(receipt.get("replacement_sha256", "")),
                )
                is None
                for receipt in receipts
            )
        ):
            raise CoverageError(f"V11U mutation receipt is invalid: {name}")
        require_retired(
            {
                "path": record["variant"],
                "sha256": record["variant_sha256"],
                "size_bytes": removed_by_path.get(
                    record["variant"], {}
                ).get("size_bytes"),
            },
            "generated-negative-rtl",
            f"mutation {name}",
        )
        variant_records[name] = record

    expected_mutation_profiles = {
        f"mutation-{name}-g{width}-release"
        for name, expected in V11U_MUTATIONS.items()
        for width in expected["widths"]
    }
    expected_profiles = (
        set(V11U_POSITIVE_PROFILES)
        | set(V11U_ASSERTION_PROFILES)
        | expected_mutation_profiles
    )
    if (
        not isinstance(profiles, list)
        or len(profiles) != 24
        or {
            item.get("profile")
            for item in profiles
            if isinstance(item, dict)
        }
        != expected_profiles
    ):
        raise CoverageError("V11U profile inventory is incomplete")

    testbench_dir = root / "npc/rv64/testbench"

    def verify_profile_record(
        record: dict[str, Any],
        *,
        bucket: str,
        expected_kind: str,
        expected_tests: tuple[str, ...],
        expected_width: int,
        expected_assertions: bool,
        expected_defines: tuple[str, ...],
        expected_marker: str | None,
        expected_mutation: str | None,
        expected_markers: tuple[tuple[str, str, int], ...] = (),
        cleanup_kind: str = "focused-compile-image",
    ) -> None:
        name = record.get("profile")
        profile_root = attempt_root / bucket / str(name)
        expected_command = [
            "make",
            "-B",
            "-C",
            str(testbench_dir),
            f"TESTS={' '.join(expected_tests)}",
            f"BUILD_DIR={profile_root / 'build'}",
            f"RESULT_DIR={profile_root / 'results'}",
            "IVFLAGS="
            + " ".join(
                (
                    "-g2012",
                    "-Wall",
                    "-I../vsrc",
                    "-I../vsrc/include",
                    "-Icommon",
                    *expected_defines,
                )
            ),
        ]
        if expected_mutation is not None:
            variant = variant_records[expected_mutation]
            expected_command.append(
                f"{variant['override']}="
                f"{resolve_repo_path(root, variant['variant'])}"
            )
        expected_command.append("run")
        logs = record.get("logs")
        images = record.get("compile_artifacts")
        if (
            record.get("status") != "PASS"
            or record.get("kind") != expected_kind
            or tuple(record.get("tests", [])) != expected_tests
            or record.get("producer_gen_width") != expected_width
            or record.get("assertions") is not expected_assertions
            or tuple(record.get("defines", [])) != expected_defines
            or record.get("mutation") != expected_mutation
            or record.get("expected_failure_marker") != expected_marker
            or tuple(
                tuple(item) for item in record.get("required_markers", [])
            )
            != expected_markers
            or record.get("timeout") is not False
            or record.get("command") != expected_command
            or not isinstance(logs, dict)
            or set(logs) != set(expected_tests)
            or not isinstance(images, list)
            or len(images) != len(expected_tests)
        ):
            raise CoverageError(f"V11U profile contract failed: {name}")
        image_by_path = {
            item.get("path"): item
            for item in images
            if isinstance(item, dict)
        }
        if len(image_by_path) != len(expected_tests):
            raise CoverageError(f"V11U compile inventory failed: {name}")
        for test in expected_tests:
            expected_image = relative(
                root, profile_root / "build" / f"{test}.vvp"
            )
            image_record = image_by_path.get(expected_image)
            require_retired(
                image_record,
                cleanup_kind,
                f"profile {name} compile image",
            )
            log_path = verify_artifact_record(
                root, logs[test], f"V11U profile {name} log {test}"
            )
            log_text = log_path.read_text(
                encoding="utf-8", errors="replace"
            )
            if log_text.count("[COMPILE]") != 1:
                raise CoverageError(
                    f"V11U profile compile marker failed: {name}"
                )
            if expected_kind in {"positive", "regression"}:
                if (
                    record.get("make_rc") != 0
                    or log_text.count("[RESULT] PASS") != 1
                    or "[RESULT] FAIL" in log_text
                    or (
                        log_text.count(f"PASS {test}")
                        + log_text.count(f"[PASS] {test}")
                    )
                    != 1
                ):
                    raise CoverageError(
                        f"V11U positive profile failed: {name}"
                    )
            elif (
                not isinstance(record.get("make_rc"), int)
                or record["make_rc"] == 0
                or log_text.count("[RESULT] FAIL") != 1
                or "[RESULT] PASS" in log_text
                or expected_marker is None
                or expected_marker not in log_text
            ):
                raise CoverageError(
                    f"V11U negative profile escaped: {name}"
                )
        for test, marker, count in expected_markers:
            marker_log = verify_artifact_record(
                root, logs[test], f"V11U profile {name} marker log"
            ).read_text(encoding="utf-8", errors="replace")
            if marker_log.count(marker) != count:
                raise CoverageError(
                    f"V11U profile marker count failed: {name}"
                )

    for record in profiles:
        if not isinstance(record, dict):
            raise CoverageError("V11U profile record is not an object")
        name = record.get("profile")
        positive = V11U_POSITIVE_PROFILES.get(name)
        if positive is not None:
            verify_profile_record(
                record,
                bucket="profiles",
                expected_kind="positive",
                expected_tests=positive["tests"],
                expected_width=positive["width"],
                expected_assertions=positive["assertions"],
                expected_defines=positive["defines"],
                expected_marker=None,
                expected_mutation=None,
                expected_markers=positive["markers"],
            )
            continue
        assertion = V11U_ASSERTION_PROFILES.get(name)
        if assertion is not None:
            verify_profile_record(
                record,
                bucket="profiles",
                expected_kind="assertion-negative",
                expected_tests=("tb_ooo_pending_system_lease_probe",),
                expected_width=4,
                expected_assertions=True,
                expected_defines=(
                    "-DOOO_PRODUCER_GEN_W=4",
                    "-DOOO_ASSERT",
                    assertion["define"],
                ),
                expected_marker=assertion["marker"],
                expected_mutation=None,
            )
            continue
        match = re.fullmatch(r"mutation-(.+)-g([14])-release", str(name))
        mutation_name = match.group(1) if match else None
        width = int(match.group(2)) if match else 0
        mutation = V11U_MUTATIONS.get(mutation_name)
        if mutation is None or width not in mutation["widths"]:
            raise CoverageError(f"V11U profile name is invalid: {name}")
        verify_profile_record(
            record,
            bucket="profiles",
            expected_kind="mutation",
            expected_tests=(mutation["test"],),
            expected_width=width,
            expected_assertions=False,
            expected_defines=(
                f"-DOOO_PRODUCER_GEN_W={width}",
                *mutation["defines"],
            ),
            expected_marker=mutation["marker"],
            expected_mutation=mutation_name,
        )

    if not isinstance(regressions, dict):
        raise CoverageError("V11U regression profile is absent")
    verify_profile_record(
        regressions,
        bucket="regressions",
        expected_kind="regression",
        expected_tests=V11U_REGRESSIONS,
        expected_width=4,
        expected_assertions=False,
        expected_defines=("-DOOO_PRODUCER_GEN_W=4",),
        expected_marker=None,
        expected_mutation=None,
        cleanup_kind="regression-compile-image",
    )

    runner_status_path = attempt_root / "runner.status"
    if (
        not runner_status_path.is_file()
        or runner_status_path.read_text(encoding="utf-8").strip()
        != "PASS rc=0 stage=complete evidence_complete=1 cleanup_rc=0"
    ):
        raise CoverageError("V11U runner status is not terminal PASS")

    return (
        binding_state,
        [
            artifact(root, spec["summary"]),
            artifact(root, relative(root, pre_path)),
            artifact(root, relative(root, post_path)),
            artifact(root, relative(root, cleanup_path)),
            artifact(root, relative(root, runner_status_path)),
        ],
        {
            "positive_profiles": 9,
            "assertion_negative_profiles_rejected": 3,
            "compile_success_mutation_cases_rejected": 10,
            "mutation_simulations_rejected": 12,
            "ordinary_regressions_passed": 4,
            "pre_rob_has_no_lease_closed": True,
            "csr_only_exact_birth_closed": True,
            "raw_lease_metadata_independence_closed": True,
            "ordinary_clear_and_clear_dispatched_hold_closed": True,
            "exact_commit_and_flush_death_closed": True,
            "full_pid_and_pc_authorization_closed": True,
            "global_live_mask_reuse_fence_closed": True,
            "retired_compile_artifacts_validated": 42,
            "production_design_id_current": True,
            "product_instance_paths": sorted(V11U_PRODUCT_INSTANCES),
            "selected_bindings": selected_records,
            "evidence_design_id": payload["design_id"],
            "current_design_id": design_id,
            "system_rerun": scope["system_rerun"],
            "a3_original_status": scope["a3_original_status"],
            "a3_execution_state": scope["a3_execution_state"],
            "a3_terminal_state": scope["a3_terminal_state"],
            "a3_oracle_state": scope["a3_oracle_state"],
            "a3_checker_replay": scope["a3_checker_replay"],
        },
    )


def evaluate_evidence_set(
    root: pathlib.Path,
    spec: dict[str, Any],
    design_id: str,
) -> dict[str, Any]:
    kind = spec.get("binding_kind")
    if kind == "v8l_full_rtl_snapshot":
        state, artifacts, detail = evaluate_v8l(root, spec, design_id)
    elif kind == "v9r_json_source_binding":
        state, artifacts, detail = evaluate_v9r(root, spec, design_id)
    elif kind == "sha256_manifest_subset":
        state, artifacts, detail = evaluate_sha_manifest(root, spec)
    elif kind == "json_declared_bindings":
        state, artifacts, detail = evaluate_json_declared(root, spec)
    elif kind == "v11b_terminal_collector":
        if set(spec.get("unit_ids", [])) != V11B_TERMINAL_COLLECTOR_UNIT_IDS:
            raise CoverageError(
                "V11B terminal collector evidence must bind the exact "
                "collector unit set"
            )
        state, artifacts, detail = evaluate_v11b_terminal_collector(
            root, spec, design_id
        )
    elif kind == "v11c_memory_tracker":
        if set(spec.get("unit_ids", [])) != V11C_MEMORY_TRACKER_UNIT_IDS:
            raise CoverageError(
                "V11C memory tracker evidence must bind the exact map/live-set "
                "unit set"
            )
        state, artifacts, detail = evaluate_v11c_memory_tracker(
            root, spec, design_id
        )
    elif kind == "v11d_memory_tracker_cursor":
        if (
            set(spec.get("unit_ids", []))
            != V11D_MEMORY_TRACKER_CURSOR_UNIT_IDS
        ):
            raise CoverageError(
                "V11D memory tracker cursor evidence must bind only "
                "tracker-next-token-cursor"
            )
        state, artifacts, detail = evaluate_v11d_memory_tracker_cursor(
            root, spec, design_id
        )
    elif kind == "v11e_rob_slot_generation":
        if (
            set(spec.get("unit_ids", []))
            != V11E_ROB_SLOT_GENERATION_UNIT_IDS
        ):
            raise CoverageError(
                "V11E ROB slot-generation evidence must bind only "
                "rob-slot-generation"
            )
        state, artifacts, detail = evaluate_v11e_rob_slot_generation(
            root, spec, design_id
        )
    elif kind == "v11f_int_iq_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11F_INT_IQ_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11F integer-IQ evidence must bind only "
                "integer-iq-producers"
            )
        state, artifacts, detail = evaluate_v11f_int_iq_producer(
            root, spec, design_id
        )
    elif kind == "v11g_store_queue_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11G_STORE_QUEUE_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11G StoreQueue evidence must bind exactly "
                "store-queue-producers and store-queue-owner-tokens"
            )
        state, artifacts, detail = evaluate_v11g_store_queue_holder(
            root, spec, design_id
        )
    elif kind == "v11h_load_queue_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11H_LOAD_QUEUE_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11H LoadQueue evidence must bind only "
                "load-queue-producers"
            )
        state, artifacts, detail = evaluate_v11h_load_queue_producer(
            root, spec, design_id
        )
    elif kind == "v11j_bridge_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11J_BRIDGE_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11J bridge-holder evidence must bind exactly the five "
                "bridge holder/set units"
            )
        state, artifacts, detail = evaluate_v11j_bridge_holder(
            root, spec, design_id
        )
    elif kind == "v11k_miq_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11K_MIQ_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11K MIQ-holder evidence must bind only "
                "miq-owner-tokens"
            )
        state, artifacts, detail = evaluate_v11k_miq_holder(
            root, spec, design_id
        )
    elif kind == "v11l_memory_retry_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11L_MEMORY_RETRY_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11L memory retry-holder evidence must bind exactly "
                "the four bank-local producer/token units"
            )
        state, artifacts, detail = evaluate_v11l_memory_retry_holder(
            root, spec, design_id
        )
    elif kind == "v11m_memory_reservation_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11M_MEMORY_RESERVATION_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11M memory-reservation holder evidence must bind "
                "exactly the four reservation producer/token units"
            )
        state, artifacts, detail = (
            evaluate_v11m_memory_reservation_holder(
                root, spec, design_id
            )
        )
    elif kind == "v11n_memory_pending_holder":
        if (
            set(spec.get("unit_ids", []))
            != V11N_MEMORY_PENDING_HOLDER_UNIT_IDS
        ):
            raise CoverageError(
                "V11N memory-pending holder evidence must bind "
                "exactly the singleton producer-cache/token units"
            )
        state, artifacts, detail = evaluate_v11n_memory_pending_holder(
            root, spec, design_id
        )
    elif kind == "v11o_memory_buffer_token":
        if (
            set(spec.get("unit_ids", []))
            != V11O_MEMORY_BUFFER_TOKEN_UNIT_IDS
        ):
            raise CoverageError(
                "V11O memory-buffer evidence must bind only "
                "memory-buffer-token"
            )
        state, artifacts, detail = evaluate_v11o_memory_buffer_token(
            root, spec, design_id
        )
    elif kind == "v11p_checkpoint_irrevocable_write":
        if (
            set(spec.get("unit_ids", []))
            != V11P_CHECKPOINT_IRREVOCABLE_WRITE_UNIT_IDS
        ):
            raise CoverageError(
                "V11P checkpoint irreversible-write evidence must bind "
                "only checkpoint-irrevocable-write-producer"
            )
        state, artifacts, detail = (
            evaluate_v11p_checkpoint_irrevocable_write(
                root, spec, design_id
            )
        )
    elif kind == "v11q_int_lane0_packet":
        if (
            set(spec.get("unit_ids", []))
            != V11Q_INT_LANE0_PACKET_UNIT_IDS
        ):
            raise CoverageError(
                "V11Q integer lane0 packet evidence must bind exactly "
                "integer-ex0-packed-alias, integer-ex0-packet, and "
                "branch-resolve-packet"
            )
        state, artifacts, detail = evaluate_v11q_int_lane0_packet(
            root, spec, design_id
        )
    elif kind == "v11r_int_lane1_packet":
        if (
            set(spec.get("unit_ids", []))
            != V11R_INT_LANE1_PACKET_UNIT_IDS
        ):
            raise CoverageError(
                "V11R integer lane1 packet evidence must bind exactly "
                "integer-ex1-packed-alias and integer-ex1-packet"
            )
        state, artifacts, detail = evaluate_v11r_int_lane1_packet(
            root, spec, design_id
        )
    elif kind == "v11s_muldiv_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11S_MULDIV_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11S MulDiv evidence must bind only muldiv-producer"
            )
        state, artifacts, detail = evaluate_v11s_muldiv_producer(
            root, spec, design_id
        )
    elif kind == "v11t_clmul_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11T_CLMUL_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11T CLMUL evidence must bind only clmul-producer"
            )
        state, artifacts, detail = evaluate_v11t_clmul_producer(
            root, spec, design_id
        )
    elif kind == "v11u_pending_system_producer":
        if (
            set(spec.get("unit_ids", []))
            != V11U_PENDING_SYSTEM_PRODUCER_UNIT_IDS
        ):
            raise CoverageError(
                "V11U pending-system evidence must bind only "
                "pending-system-producer"
            )
        state, artifacts, detail = evaluate_v11u_pending_system_producer(
            root, spec, design_id
        )
    else:
        raise CoverageError(f"unsupported binding kind: {kind}")
    return {
        "id": spec["id"],
        "binding_kind": kind,
        "binding_state": state,
        "scope": spec.get("scope"),
        "semantic_closure": spec.get("semantic_closure") is True,
        "unit_ids": sorted(spec.get("unit_ids", [])),
        "gap_classifications": sorted(
            set(spec.get("gap_classifications", []))
        ),
        "artifacts": artifacts,
        "instance_paths": sorted(
            detail.get("product_instance_paths", [])
        ),
        "detail": detail,
    }


def flatten_units(census: dict[str, Any]) -> list[dict[str, Any]]:
    units: list[dict[str, Any]] = []
    for collection in UNIT_COLLECTIONS:
        values = census.get(collection)
        if not isinstance(values, list):
            raise CoverageError(f"census collection is not a list: {collection}")
        category = {
            "direct_full_p_fields": "DIRECT_OR_ALIAS_FIELD",
            "packed_full_p_stages": "PACKED_STAGE",
            "token_q_fields": "TOKEN_FIELD",
            "token_set_holders": "TOKEN_SET",
            "generation_authorities": "GENERATION_AUTHORITY",
        }[collection]
        for value in values:
            if not isinstance(value, dict):
                raise CoverageError(f"census unit is not an object: {collection}")
            record = copy.deepcopy(value)
            record["category"] = category
            units.append(record)
    ids = [record.get("id") for record in units]
    if len(ids) != len(set(ids)) or not all(
        isinstance(value, str) and value for value in ids
    ):
        raise CoverageError("census semantic unit IDs are missing or duplicate")
    return sorted(units, key=lambda item: item["id"])


def gap_classes(
    unit: dict[str, Any],
    evidence: list[dict[str, Any]],
    instance_count: int,
) -> list[str]:
    gaps = {"SEMANTIC_LIFECYCLE_NOT_CLOSED"}
    if not evidence:
        gaps.update(
            {
                "NO_DYNAMIC_EVIDENCE_CANDIDATE",
                "RAW_IDENTITY_NEGATIVE_COVERAGE_GAP",
            }
        )
    for item in evidence:
        gaps.update(item["gap_classifications"])
        state = item["binding_state"]
        if state == "STALE_RTL_SOURCE":
            gaps.add("CANDIDATE_RTL_SOURCE_DRIFT")
        elif state == "RTL_SOURCE_MATCH_TESTBENCH_DRIFT":
            gaps.add("CANDIDATE_TESTBENCH_SOURCE_DRIFT")
        elif state == "CURRENT_SELECTED_SOURCE_AND_TB_BOUND":
            gaps.add("CURRENT_FULL_DESIGN_REPLAY_GAP")
    if instance_count > 1:
        gaps.add("PRODUCT_INSTANCE_DISTINGUISHABILITY_GAP")
    if unit["category"] == "TOKEN_FIELD":
        gaps.add("RAW_TOKEN_TUPLE_KNOWN_NEGATIVE_COVERAGE_GAP")
    elif unit["category"] == "TOKEN_SET":
        gaps.add("TOKEN_SET_MEMBERSHIP_NEGATIVE_COVERAGE_GAP")
    elif unit["category"] == "GENERATION_AUTHORITY":
        gaps.add("CURRENT_PRODUCT_GEN_W1_WRAP_PATH_GAP")
    else:
        gaps.add("RAW_PRODUCER_ID_KNOWN_NEGATIVE_COVERAGE_GAP")
    return sorted(gaps)


def unit_is_closed(
    evidence: list[dict[str, Any]], instance_paths: list[str]
) -> bool:
    closing = [
        item
        for item in evidence
        if item.get("semantic_closure") is True
    ]
    if not closing:
        return False
    for item in closing:
        if (
            item.get("scope") != "COMPLETE"
            or item.get("binding_state") not in CURRENT_BINDINGS
            or item.get("gap_classifications")
        ):
            raise CoverageError(
                f"invalid semantic closure evidence set: {item.get('id')}"
            )
        if len(instance_paths) > 1 and set(
            item.get("instance_paths", [])
        ) != set(instance_paths):
            raise CoverageError(
                "semantic closure for a duplicated module requires exact "
                "per-instance evidence"
            )
    return True


def _build_ledger(
    root: pathlib.Path,
    census_path: pathlib.Path,
    graph_path: pathlib.Path,
    policy_path: pathlib.Path,
) -> dict[str, Any]:
    design_id = current_design_id(root)
    census = load_json(census_path)
    graph = load_json(graph_path)
    policy = load_json(policy_path)
    if census.get("schema_version") != CENSUS_SCHEMA:
        raise CoverageError("producer/holder census schema mismatch")
    if graph.get("schema_version") != INSTANCE_SCHEMA:
        raise CoverageError("holder instance graph schema mismatch")
    if policy.get("schema_version") != POLICY_SCHEMA:
        raise CoverageError("semantic coverage policy schema mismatch")
    if census.get("design_id") != design_id:
        raise CoverageError("producer/holder census is not current-design")
    if graph.get("design_id") != design_id or graph.get("status") != "PASS":
        raise CoverageError("holder instance graph is not current PASS evidence")
    if policy.get("semantic_complete") is not False:
        raise CoverageError(
            "policy cannot claim semantic completion before per-unit closure"
        )

    units = flatten_units(census)
    if len(units) != 44:
        raise CoverageError(f"expected 44 semantic units, found {len(units)}")
    holder_instances = graph.get("graph", {}).get("holder_instances")
    if not isinstance(holder_instances, list):
        raise CoverageError("holder instance graph lacks holder_instances")
    instance_paths = [item.get("path") for item in holder_instances]
    if (
        len(holder_instances) != 17
        or len(instance_paths) != len(set(instance_paths))
    ):
        raise CoverageError(
            "expected 17 unique elaborated holder instance paths"
        )
    by_module: dict[str, list[str]] = defaultdict(list)
    for item in holder_instances:
        module = item.get("module")
        path = item.get("path")
        if not isinstance(module, str) or not isinstance(path, str):
            raise CoverageError("malformed holder instance record")
        by_module[module].append(path)

    known_ids = {unit["id"] for unit in units}
    evidence_specs = policy.get("evidence_sets")
    if not isinstance(evidence_specs, list):
        raise CoverageError("policy evidence_sets must be a list")
    evidence_results: list[dict[str, Any]] = []
    evidence_by_unit: dict[str, list[dict[str, Any]]] = defaultdict(list)
    evidence_ids: set[str] = set()
    for spec in evidence_specs:
        if not isinstance(spec, dict):
            raise CoverageError("evidence set must be an object")
        evidence_id = spec.get("id")
        if not isinstance(evidence_id, str) or evidence_id in evidence_ids:
            raise CoverageError("evidence set ID is missing or duplicate")
        evidence_ids.add(evidence_id)
        unit_ids = spec.get("unit_ids")
        if (
            not isinstance(unit_ids, list)
            or len(unit_ids) != len(set(unit_ids))
            or not set(unit_ids) <= known_ids
        ):
            raise CoverageError(f"evidence set has invalid unit IDs: {evidence_id}")
        result = evaluate_evidence_set(root, spec, design_id)
        evidence_results.append(result)
        for unit_id in unit_ids:
            evidence_by_unit[unit_id].append(result)

    output_units: list[dict[str, Any]] = []
    flat_bindings: list[dict[str, Any]] = []
    all_unit_modules: set[str] = set()
    for unit in units:
        module = unit.get("module")
        if not isinstance(module, str) or module not in by_module:
            raise CoverageError(
                f"census unit has no elaborated product instance: {unit['id']}"
            )
        all_unit_modules.add(module)
        paths = sorted(by_module[module])
        evidence = sorted(
            evidence_by_unit.get(unit["id"], []),
            key=lambda item: item["id"],
        )
        closed = unit_is_closed(evidence, paths)
        gaps = [] if closed else gap_classes(unit, evidence, len(paths))
        source_path = resolve_repo_path(root, unit["path"])
        if not source_path.is_file():
            raise CoverageError(f"census source file is missing: {unit['path']}")
        unit_record = {
            "id": unit["id"],
            "category": unit["category"],
            "classification": unit.get("classification"),
            "module": module,
            "source": {
                "path": unit["path"],
                "sha256": sha256_file(source_path),
            },
            "symbol": unit.get("symbol"),
            "stage_instance": unit.get("instance"),
            "instance_paths": paths,
            "instance_count": len(paths),
            "candidate_evidence": [
                {
                    "id": item["id"],
                    "binding_state": item["binding_state"],
                    "scope": item["scope"],
                }
                for item in evidence
            ],
            "semantic_status": "PASS" if closed else "GAP",
            "gap_classifications": gaps,
        }
        output_units.append(unit_record)
        for path in paths:
            binding_gaps = list(gaps)
            flat_bindings.append(
                {
                    "unit_id": unit["id"],
                    "module": module,
                    "instance_path": path,
                    "semantic_status": "PASS" if closed else "GAP",
                    "gap_classifications": binding_gaps,
                }
            )
    missing_modules = sorted(set(by_module) - all_unit_modules)
    if missing_modules:
        raise CoverageError(
            f"elaborated holder modules lack census units: {missing_modules}"
        )

    state_counts = Counter(
        result["binding_state"] for result in evidence_results
    )
    units_with_candidates = sum(
        bool(unit["candidate_evidence"]) for unit in output_units
    )
    duplicate_modules = sorted(
        module for module, paths in by_module.items() if len(paths) > 1
    )
    units_semantic_pass = sum(
        unit["semantic_status"] == "PASS" for unit in output_units
    )
    return {
        "schema_version": SCHEMA,
        "status": "GAP",
        "design_id": design_id,
        "inputs": {
            "census": artifact(root, relative(root, census_path)),
            "instance_graph": artifact(root, relative(root, graph_path)),
            "policy": artifact(root, relative(root, policy_path)),
        },
        "counts": {
            "semantic_units": len(output_units),
            "holder_instances": len(holder_instances),
            "unit_instance_bindings": len(flat_bindings),
            "units_semantic_pass": units_semantic_pass,
            "units_semantic_gap": len(output_units) - units_semantic_pass,
            "units_with_candidate_evidence": units_with_candidates,
            "units_without_candidate_evidence": len(output_units)
            - units_with_candidates,
            "ledger_only_units": 0,
            "evidence_binding_states": dict(sorted(state_counts.items())),
        },
        "duplicate_instance_modules": duplicate_modules,
        "evidence_sets": sorted(evidence_results, key=lambda item: item["id"]),
        "units": output_units,
        "unit_instance_bindings": sorted(
            flat_bindings,
            key=lambda item: (item["unit_id"], item["instance_path"]),
        ),
        "claim_boundary": policy["claim_boundary"],
        "promotion": {
            "global_no_live_reuse": "SEMANTIC_COVERAGE_REQUIRED",
            "whole_architecture": "RED",
            "ppa": "UNPROMOTED",
        },
    }


def build_ledger(
    root: pathlib.Path,
    census_path: pathlib.Path,
    graph_path: pathlib.Path,
    policy_path: pathlib.Path,
) -> dict[str, Any]:
    global _ACTIVE_FILE_SHA_CACHE
    previous_cache = _ACTIVE_FILE_SHA_CACHE
    if previous_cache is not None:
        return _build_ledger(root, census_path, graph_path, policy_path)
    _ACTIVE_FILE_SHA_CACHE = {}
    try:
        return _build_ledger(root, census_path, graph_path, policy_path)
    finally:
        _ACTIVE_FILE_SHA_CACHE = None


def write_json(path: pathlib.Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[5],
    )
    result.add_argument(
        "--census",
        default="npc/rv64/design/arch/producer-holder-census.json",
    )
    result.add_argument(
        "--instance-graph",
        default=(
            ".github/task-runs/2026-07-31-rv64-"
            "axi-xbar-naming-refresh/evidence/"
            "current-holder-instance-graph/"
            "holder-instance-graph.json"
        ),
    )
    result.add_argument(
        "--policy",
        default=(
            "npc/rv64/design/arch/"
            "producer-holder-semantic-coverage-policy.json"
        ),
    )
    sub = result.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--output", type=pathlib.Path, required=True)
    verify = sub.add_parser("verify")
    verify.add_argument("--input", type=pathlib.Path, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    root = args.root.resolve()
    expected = build_ledger(
        root,
        resolve_repo_path(root, args.census),
        resolve_repo_path(root, args.instance_graph),
        resolve_repo_path(root, args.policy),
    )
    if args.command == "build":
        output = args.output
        if not output.is_absolute():
            output = root / output
        output = output.resolve()
        relative(root, output)
        write_json(output, expected)
    else:
        input_path = args.input
        if not input_path.is_absolute():
            input_path = root / input_path
        actual = load_json(input_path.resolve())
        if actual != expected:
            raise CoverageError(
                "semantic coverage ledger differs from current inputs"
            )
    counts = expected["counts"]
    print(
        "[PRODUCER-HOLDER-SEMANTIC-COVERAGE][GAP] "
        f"design_id={expected['design_id']} "
        f"units={counts['semantic_units']} "
        f"instances={counts['holder_instances']} "
        f"bindings={counts['unit_instance_bindings']} "
        f"candidate={counts['units_with_candidate_evidence']} "
        f"no_candidate={counts['units_without_candidate_evidence']} "
        f"ledger_only=0 semantic_pass={counts['units_semantic_pass']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CoverageError as exc:
        print(
            f"[PRODUCER-HOLDER-SEMANTIC-COVERAGE][FAIL] {exc}",
            file=sys.stderr,
        )
        raise SystemExit(1)
