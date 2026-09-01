#!/usr/bin/env python3
"""Fast mutation tests for the strict Qwen multi-dispatch log validator."""

from __future__ import annotations

import json
import pathlib
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from qwen_strict_log_validator import (  # noqa: E402
    QWEN_RECURRENT_LAYERS,
    validate_strict_log,
)


NODES = 1714
REQUIRED = 1080


def marker(prefix: str, values: dict[str, int], *, owner: str = "") -> str:
    owner_field = f" owner={owner}" if owner else ""
    return prefix + owner_field + " " + " ".join(
        f"{key}={value}" for key, value in values.items()
    )


def strict_values(dispatch: int) -> dict[str, int]:
    values = {
        "dispatch": dispatch,
        "required_seen": REQUIRED,
        "assigned": REQUIRED,
        "required_enqueued": REQUIRED,
        "required_completed": REQUIRED,
        "executed": REQUIRED,
        "commands_accepted": REQUIRED,
        "completion_success": REQUIRED,
    }
    values.update({key: 0 for key in (
        "completion_failure", "coverage_missing", "coverage_duplicate",
        "coverage_hash_mismatch", "completion_identity_mismatch",
        "unsupported", "rtl_failures", "gmem_errors", "timeout_errors",
        "cpu_fallback_attempts", "host_tensor_arithmetic",
    )})
    values.update({
        "rtl_cycles": 100,
        "gmem_read_bytes": 4,
        "gmem_write_bytes": 4,
        "vector_elements": 30_000_000,
    })
    return values


def system_values(dispatch: int) -> dict[str, int]:
    return {
        "dispatch": dispatch,
        "system_transactions": REQUIRED,
        "required_seen": REQUIRED,
        "system_cycles": 101,
        "rtl_cycles": 100,
        "cpu_config_commands": 30 * REQUIRED,
        "cpu_tensor_commands": 31 * REQUIRED,
        "cpu_terminals": 31 * REQUIRED,
        "cpu_config_commits": 30 * REQUIRED,
        "cpu_launch_commits": REQUIRED,
        "public_commands": REQUIRED,
        "public_completions": REQUIRED,
        "public_errors": 0,
        "required_issued": REQUIRED,
        "required_completed": REQUIRED,
        "cpu_pid_identity_mismatch": 0,
        "macro_identity_mismatch": 0,
        "cpu_memory_separate": REQUIRED,
        "first_request_hold_cycles": 1,
        "expected_first_request_hold_cycles": 1,
        "q8_portal_transactions": 187,
        "q8_portal_expected_transactions": 187,
        "q8_portal_requests": 1,
        "q8_portal_responses": 1,
        "q8_portal_blocks": 1,
        "q8_portal_bytes": 34,
        "q8_portal_raw_copy_bytes": 34,
        "q8_portal_first_hold_cycles": 1,
        "q8_portal_expected_first_holds": 1,
        "q8_portal_expected_requests": 1,
        "q8_portal_expected_blocks": 1,
        "q8_portal_expected_bytes": 34,
        "q8_portal_protocol_errors": 0,
        "q8_portal_latency_mismatches": 0,
        "q8_portal_payload_stability_mismatches": 0,
    }


def raw32_values(dispatch: int, owner: str) -> dict[str, int]:
    transactions = 367 if owner == "f32_alu" else 91
    if owner == "f32_alu":
        first_holds = 367 if dispatch == 1 else 331
        read_bytes = 211_292_672 if dispatch == 1 else 191_091_200
        write_bytes = 115_820_800 if dispatch == 1 else 95_619_328
    else:
        first_holds = 1
        read_bytes = 4
        write_bytes = 4
    read_words = read_bytes // 4
    write_words = write_bytes // 4
    return {
        "dispatch": dispatch,
        "transactions": transactions,
        "expected_transactions": transactions,
        "request_groups": transactions,
        "response_groups": transactions,
        "read_groups": 1,
        "write_groups": transactions - 1,
        "read_words": read_words,
        "write_words": write_words,
        "read_bytes": read_bytes,
        "write_bytes": write_bytes,
        "raw_read_copy_bytes": read_bytes,
        "raw_write_copy_bytes": write_bytes,
        "first_hold_cycles": first_holds,
        "expected_first_holds": first_holds,
        "expected_request_groups": transactions,
        "expected_response_groups": transactions,
        "expected_read_groups": 1,
        "expected_write_groups": transactions - 1,
        "expected_read_words": read_words,
        "expected_write_words": write_words,
        "expected_read_bytes": read_bytes,
        "expected_write_bytes": write_bytes,
        "protocol_errors": 0,
        "latency_mismatches": 0,
        "payload_stability_mismatches": 0,
    }


def sampler_values(dispatch: int) -> dict[str, int]:
    return {
        "dispatch": dispatch,
        "transactions": 1,
        "expected_transactions": 1,
        "elements": 248320,
        "expected_elements": 248320,
        "read_bytes": 993288,
        "expected_read_bytes": 993288,
        "scalar_write_bytes": 4,
        "expected_scalar_write_bytes": 4,
        "sampled_tokens": 1,
        "expected_sampled_tokens": 1,
        "host_scalar_copy_bytes": 4,
        "full_vocab_host_exports": 0,
        "full_vocab_host_export_bytes": 0,
        "cpu_candidate_scans": 0,
        "invalid_tokens": 0,
    }


def functional_values(dispatch: int) -> dict[str, int]:
    values = {"dispatch": dispatch}
    values.update({key: 0 for key in (
        "command_dispatches", "command_completions", "successes", "failures",
        "read_words", "write_words", "read_bytes", "write_bytes", "q8_blocks",
        "q8_macs", "vector_elements", "expected_read_words",
        "expected_write_words", "expected_read_bytes", "expected_write_bytes",
        "expected_q8_blocks", "expected_q8_macs", "expected_vector_elements",
        "callback_read_calls", "callback_write_calls", "callback_read_bytes",
        "callback_write_bytes", "callback_errors", "command_mismatches",
        "protocol_errors", "old_gmem_requests", "old_gmem_responses",
        "old_q8_portal_transactions", "old_f32_alu_portal_transactions",
        "old_f32_mover_portal_transactions",
    )})
    return values


def cache_scale_descriptor(
    kind: str, layer: int, node: int, *, steady: bool
) -> str:
    full_ne0 = 18_432 if kind == "r" else 262_144
    full_nb = 73_728 if kind == "r" else 1_048_576
    ne0 = 0 if steady else full_ne0
    nb = 0 if steady else full_nb
    return (
        f"canonical_id={node:064x} "
        f"name=cache_{kind}_l{layer} (reshaped) (view) (view) op=SCALE "
        f"dst_type=f32 dst_ne={ne0},1,1,1 dst_nb=4,{nb},{nb},{nb} "
        f"src0_type=f32 src0_ne={ne0},1,1,1 src0_nb=4,{nb},{nb},{nb} "
        "supported=1"
    )


def preflight_block(graph: str, cohort: int, *, steady: bool = False) -> list[str]:
    result = [
        f"[NPU-STRICT][PREFLIGHT-BEGIN] graph={graph} cohort={cohort} nodes={NODES}"
    ]
    for node in range(REQUIRED):
        if node < 18:
            descriptor = cache_scale_descriptor(
                "r", QWEN_RECURRENT_LAYERS[node], node, steady=steady
            )
        elif node < 36:
            descriptor = cache_scale_descriptor(
                "s", QWEN_RECURRENT_LAYERS[node - 18], node, steady=steady
            )
        else:
            descriptor = (
                f"canonical_id={node:064x} name=node-{node} op=ADD "
                "dst_type=f32 dst_ne=1,1,1,1 dst_nb=4,4,4,4 "
                "src0_type=f32 src0_ne=1,1,1,1 src0_nb=4,4,4,4 supported=1"
            )
        result.append(
            f"[NPU-STRICT][MANIFEST] graph={graph} cohort={cohort} node={node} "
            + descriptor
        )
    result.append(
        f"[NPU-STRICT][PREFLIGHT-END] graph={graph} cohort={cohort} "
        f"nodes={NODES} required_seen={REQUIRED} supported={REQUIRED} "
        "unsupported=0 canonical_errors=0"
    )
    return result


def dispatch_ledgers(dispatch: int) -> list[str]:
    return [
        marker("[NPU-STRICT][PASS]", strict_values(dispatch)),
        marker("[NPU-SYSTEM-LEDGER][PASS]", system_values(dispatch)),
        marker(
            "[NPU-RAW32-PORTAL-LEDGER][PASS]",
            raw32_values(dispatch, "f32_alu"), owner="f32_alu",
        ),
        marker(
            "[NPU-RAW32-PORTAL-LEDGER][PASS]",
            raw32_values(dispatch, "f32_mover"), owner="f32_mover",
        ),
        marker("[NPU-SAMPLER-ARGMAX-LEDGER][PASS]", sampler_values(dispatch)),
        marker(
            "[NPU-FUNCTIONAL-COMMAND-LEDGER][PASS]",
            functional_values(dispatch),
        ),
    ]


def make_log(dispatches: int = 2) -> list[str]:
    lines = [
        "[NPU-STRICT-SAMPLER][READY] mode=backend-greedy "
        "full_vocab_host_export=0 cpu_candidate_scan=0",
        "[NPU-STRICT][READY] backend=NPU candidates=1 audit_abi=v2 "
        "canonical_binding_abi=v1",
    ]
    for cohort in range(1, 4):
        lines.extend(preflight_block("reserve", cohort))
    for dispatch in range(1, dispatches + 1):
        lines.extend(
            preflight_block("dispatch", dispatch + 3, steady=dispatch >= 2)
        )
        lines.extend(dispatch_ledgers(dispatch))
    return lines


class StrictLogValidatorTests(unittest.TestCase):
    def test_real_qwen_recurrent_layer_set_is_sparse_and_frozen(self) -> None:
        self.assertEqual(
            QWEN_RECURRENT_LAYERS,
            (0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 16, 17, 18, 20, 21, 22),
        )

    def validate(self, lines: list[str], expected: int = 2) -> dict[str, int]:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            log_path = root / "run.log"
            summary_path = root / "summary.json"
            log_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
            summary, marker_text = validate_strict_log(
                log_path, summary_path, expected
            )
            self.assertEqual(summary, json.loads(summary_path.read_text()))
            self.assertTrue(marker_text.startswith("[NPU-STRICT-LEDGER][PASS] "))
            return summary

    def rejected(self, lines: list[str], pattern: str, expected: int = 2) -> None:
        with self.assertRaisesRegex(SystemExit, pattern):
            self.validate(lines, expected)

    def test_two_dispatches_pass_and_scale_frozen_summary(self) -> None:
        summary = self.validate(make_log())
        self.assertEqual(summary["preflight_cohorts"], 5)
        self.assertEqual(summary["dispatches"], 2)
        self.assertEqual(summary["required_completed"], 2160)
        self.assertEqual(summary["sampler_argmax_sampled_tokens"], 2)
        self.assertEqual(summary["sampler_argmax_elements"], 496640)
        self.assertEqual(summary["f32_alu_owner_transactions"], 734)
        self.assertEqual(summary["bootstrap_dispatches"], 1)
        self.assertEqual(summary["steady_dispatches"], 1)
        self.assertEqual(
            {
                key: summary[key]
                for key in (
                    "f32_alu_bootstrap_owner_transactions",
                    "f32_alu_bootstrap_zero_cardinality_transactions",
                    "f32_alu_bootstrap_nonempty_portal_commands",
                    "f32_alu_bootstrap_portal_raw_read_copy_bytes",
                    "f32_alu_bootstrap_portal_raw_write_copy_bytes",
                    "f32_alu_steady_owner_transactions",
                    "f32_alu_steady_zero_cardinality_transactions",
                    "f32_alu_steady_nonempty_portal_commands",
                    "f32_alu_steady_portal_raw_read_copy_bytes",
                    "f32_alu_steady_portal_raw_write_copy_bytes",
                )
            },
            {
                "f32_alu_bootstrap_owner_transactions": 367,
                "f32_alu_bootstrap_zero_cardinality_transactions": 0,
                "f32_alu_bootstrap_nonempty_portal_commands": 367,
                "f32_alu_bootstrap_portal_raw_read_copy_bytes": 211_292_672,
                "f32_alu_bootstrap_portal_raw_write_copy_bytes": 115_820_800,
                "f32_alu_steady_owner_transactions": 367,
                "f32_alu_steady_zero_cardinality_transactions": 36,
                "f32_alu_steady_nonempty_portal_commands": 331,
                "f32_alu_steady_portal_raw_read_copy_bytes": 191_091_200,
                "f32_alu_steady_portal_raw_write_copy_bytes": 95_619_328,
            },
        )
        self.assertEqual(summary["f32_alu_zero_cardinality_transactions"], 36)
        self.assertEqual(summary["f32_alu_nonempty_portal_commands"], 698)
        self.assertEqual(summary["f32_alu_portal_first_hold_cycles"], 698)
        self.assertEqual(
            summary["f32_alu_portal_raw_read_copy_bytes"], 402_383_872
        )
        self.assertEqual(
            summary["f32_alu_portal_raw_write_copy_bytes"], 211_440_128
        )
        self.assertEqual(summary["q8_gemv_owner_transactions"], 374)
        self.assertEqual(summary["f32_mover_owner_transactions"], 182)
        self.assertEqual(summary["nonportal_required"], 870)
        self.assertEqual(summary["functional_command_dispatches"], 0)

    def test_token_stdout_can_coalesce_with_later_dispatch_begin(self) -> None:
        lines = [
            " =" + line
            if line == (
                "[NPU-STRICT][PREFLIGHT-BEGIN] "
                "graph=dispatch cohort=5 nodes=1714"
            )
            else line
            for line in make_log()
        ]
        summary = self.validate(lines)
        self.assertEqual(summary["dispatches"], 2)
        self.assertEqual(summary["steady_dispatches"], 1)

    def test_coalesced_dispatch_begin_grammar_remains_fail_closed(self) -> None:
        marker_text = (
            "[NPU-STRICT][PREFLIGHT-BEGIN] "
            "graph=dispatch cohort=5 nodes=1714"
        )
        base = make_log()
        mutants = {
            "trailing_text": " =" + marker_text + " trailing-junk",
            "duplicate_marker": " =" + marker_text + marker_text,
            "bootstrap_cohort": (
                " =" + marker_text.replace("cohort=5", "cohort=4")
            ),
        }
        for name, replacement in mutants.items():
            with self.subTest(name=name):
                lines = [
                    replacement if line == marker_text else line
                    for line in base
                ]
                self.rejected(lines, "coalesced preflight BEGIN")

    def test_eight_dispatch_phase_totals_are_exact(self) -> None:
        summary = self.validate(make_log(8), expected=8)
        self.assertEqual(summary["preflight_cohorts"], 11)
        self.assertEqual(summary["dispatches"], 8)
        self.assertEqual(summary["bootstrap_dispatches"], 1)
        self.assertEqual(summary["steady_dispatches"], 7)
        self.assertEqual(
            {
                key: summary[key]
                for key in (
                    "f32_alu_bootstrap_owner_transactions",
                    "f32_alu_bootstrap_zero_cardinality_transactions",
                    "f32_alu_bootstrap_nonempty_portal_commands",
                    "f32_alu_bootstrap_portal_raw_read_copy_bytes",
                    "f32_alu_bootstrap_portal_raw_write_copy_bytes",
                    "f32_alu_steady_owner_transactions",
                    "f32_alu_steady_zero_cardinality_transactions",
                    "f32_alu_steady_nonempty_portal_commands",
                    "f32_alu_steady_portal_raw_read_copy_bytes",
                    "f32_alu_steady_portal_raw_write_copy_bytes",
                    "f32_alu_owner_transactions",
                    "f32_alu_zero_cardinality_transactions",
                    "f32_alu_nonempty_portal_commands",
                    "f32_alu_portal_raw_read_copy_bytes",
                    "f32_alu_portal_raw_write_copy_bytes",
                )
            },
            {
                "f32_alu_bootstrap_owner_transactions": 367,
                "f32_alu_bootstrap_zero_cardinality_transactions": 0,
                "f32_alu_bootstrap_nonempty_portal_commands": 367,
                "f32_alu_bootstrap_portal_raw_read_copy_bytes": 211_292_672,
                "f32_alu_bootstrap_portal_raw_write_copy_bytes": 115_820_800,
                "f32_alu_steady_owner_transactions": 2_569,
                "f32_alu_steady_zero_cardinality_transactions": 252,
                "f32_alu_steady_nonempty_portal_commands": 2_317,
                "f32_alu_steady_portal_raw_read_copy_bytes": 1_337_638_400,
                "f32_alu_steady_portal_raw_write_copy_bytes": 669_335_296,
                "f32_alu_owner_transactions": 2_936,
                "f32_alu_zero_cardinality_transactions": 252,
                "f32_alu_nonempty_portal_commands": 2_684,
                "f32_alu_portal_raw_read_copy_bytes": 1_548_931_072,
                "f32_alu_portal_raw_write_copy_bytes": 785_156_096,
            },
        )

    def test_missing_duplicate_and_gapped_dispatch_are_rejected(self) -> None:
        base = make_log()
        cases = {
            "missing": [line for line in base if "dispatch=2" not in line],
            "duplicate": base + [
                marker("[NPU-STRICT][PASS]", strict_values(1))
            ],
            "gapped": [
                line.replace("dispatch=2", "dispatch=3") for line in base
            ],
        }
        for name, mutant in cases.items():
            with self.subTest(name=name):
                self.rejected(mutant, "dispatch|strict PASS")

    def test_cohort_reordering_and_identity_reuse_are_rejected(self) -> None:
        reserve_1 = preflight_block("reserve", 1)
        reserve_2 = preflight_block("reserve", 2)
        reserve_3 = preflight_block("reserve", 3)
        base = make_log()
        prefix = base[:2]
        rest = base[2 + len(reserve_1) + len(reserve_2) + len(reserve_3):]
        reordered = prefix + reserve_1 + reserve_3 + reserve_2 + rest
        reused = [
            line.replace("graph=dispatch cohort=5", "graph=dispatch cohort=4")
            for line in base
        ]
        self.rejected(reordered, "observation order")
        self.rejected(reused, "duplicate preflight BEGIN")

    def test_second_dispatch_node_map_descriptor_and_bounds_drift_rejected(self) -> None:
        base = make_log()
        map_drift = [
            line.replace("cohort=5 node=17 ", "cohort=5 node=1080 ")
            if "[MANIFEST] graph=dispatch cohort=5 node=17 " in line else line
            for line in base
        ]
        descriptor_drift = [
            line.replace("name=cache_r_l22", "name=descriptor-drift")
            if "[MANIFEST] graph=dispatch cohort=5 node=17 " in line else line
            for line in base
        ]
        out_of_bounds = [
            line.replace("cohort=5 node=17 ", "cohort=5 node=1714 ")
            if "[MANIFEST] graph=dispatch cohort=5 node=17 " in line else line
            for line in base
        ]
        self.rejected(map_drift, "node-index set changed")
        self.rejected(descriptor_drift, "invalid bootstrap-to-steady")
        self.rejected(out_of_bounds, "outside 0..1713")

    def test_bootstrap_and_steady_phases_cannot_be_swapped(self) -> None:
        base = make_log()
        swapped = []
        bootstrap_block = preflight_block("dispatch", 4)
        steady_block = preflight_block("dispatch", 4, steady=True)
        replacements = dict(zip(bootstrap_block, steady_block))
        for line in base:
            swapped.append(replacements.get(line, line))
        self.rejected(swapped, "bootstrap manifest")

    def test_steady_requires_exactly_the_36_cache_scale_zero_variants(self) -> None:
        base = make_log()
        missing_zero = [
            line.replace(
                cache_scale_descriptor("r", 0, 0, steady=True),
                cache_scale_descriptor("r", 0, 0, steady=False),
            )
            if "[MANIFEST] graph=dispatch cohort=5 node=0 " in line else line
            for line in base
        ]
        extra_zero = [
            line.replace(
                "dst_ne=1,1,1,1 dst_nb=4,4,4,4",
                "dst_ne=0,1,1,1 dst_nb=4,0,0,0",
            ).replace(
                "src0_ne=1,1,1,1 src0_nb=4,4,4,4",
                "src0_ne=0,1,1,1 src0_nb=4,0,0,0",
            )
            if "[MANIFEST] graph=dispatch cohort=5 node=36 " in line else line
            for line in base
        ]
        bad_tail_stride = [
            line.replace("dst_nb=4,0,0,0", "dst_nb=4,0,4,0")
            if "[MANIFEST] graph=dispatch cohort=5 node=0 " in line else line
            for line in base
        ]
        self.rejected(missing_zero, "delta is 35")
        self.rejected(extra_zero, "delta is 37")
        self.rejected(bad_tail_stride, "invalid bootstrap-to-steady")

    def test_steady_canonical_identity_swap_and_late_drift_are_rejected(self) -> None:
        base = make_log(3)
        swapped = []
        for line in base:
            if "[MANIFEST] graph=dispatch cohort=5 node=0 " in line:
                line = line.replace(f"canonical_id={0:064x}", f"canonical_id={1:064x}")
            elif "[MANIFEST] graph=dispatch cohort=5 node=1 " in line:
                line = line.replace(f"canonical_id={1:064x}", f"canonical_id={0:064x}")
            swapped.append(line)
        late_drift = [
            line.replace("name=node-100", "name=late-drift")
            if "[MANIFEST] graph=dispatch cohort=6 node=100 " in line else line
            for line in base
        ]
        self.rejected(swapped, "invalid bootstrap-to-steady", expected=3)
        self.rejected(late_drift, "drifted after dispatch 2", expected=3)

    def test_f32_alu_phase_ledger_cannot_be_linearly_scaled_or_swapped(self) -> None:
        base = make_log()
        linear = [
            line.replace("first_hold_cycles=331", "first_hold_cycles=367").replace(
                "expected_first_holds=331", "expected_first_holds=367"
            ).replace("read_bytes=191091200", "read_bytes=211292672").replace(
                "expected_read_bytes=191091200", "expected_read_bytes=211292672"
            ).replace(
                "raw_read_copy_bytes=191091200",
                "raw_read_copy_bytes=211292672",
            ).replace("read_words=47772800", "read_words=52823168").replace(
                "expected_read_words=47772800", "expected_read_words=52823168"
            ).replace("write_bytes=95619328", "write_bytes=115820800").replace(
                "expected_write_bytes=95619328", "expected_write_bytes=115820800"
            ).replace(
                "raw_write_copy_bytes=95619328",
                "raw_write_copy_bytes=115820800",
            ).replace("write_words=23904832", "write_words=28955200").replace(
                "expected_write_words=23904832", "expected_write_words=28955200"
            )
            if line.startswith(
                "[NPU-RAW32-PORTAL-LEDGER][PASS] owner=f32_alu dispatch=2"
            ) else line
            for line in base
        ]
        self.rejected(linear, "bootstrap/steady ledger mismatch")

    def test_ledger_total_and_host_export_are_rejected(self) -> None:
        base = make_log()
        ledger_drift = [
            line.replace("required_completed=1080", "required_completed=1079")
            if line.startswith("[NPU-SYSTEM-LEDGER][PASS] dispatch=2") else line
            for line in base
        ]
        host_export = [
            line.replace("full_vocab_host_exports=0", "full_vocab_host_exports=1")
            if line.startswith("[NPU-SAMPLER-ARGMAX-LEDGER][PASS] dispatch=2")
            else line
            for line in base
        ]
        self.rejected(ledger_drift, "System transport ledger mismatch")
        self.rejected(host_export, "sampler ARGMAX ledger mismatch")

    def test_all_ledger_marker_grammars_are_fail_closed(self) -> None:
        base = make_log()
        grammars = (
            (
                "strict",
                "[NPU-STRICT][PASS] dispatch=1 ",
                "host_tensor_arithmetic",
            ),
            (
                "system",
                "[NPU-SYSTEM-LEDGER][PASS] dispatch=1 ",
                "macro_identity_mismatch",
            ),
            (
                "functional",
                "[NPU-FUNCTIONAL-COMMAND-LEDGER][PASS] dispatch=1 ",
                "old_gmem_requests",
            ),
            (
                "raw32",
                "[NPU-RAW32-PORTAL-LEDGER][PASS] "
                "owner=f32_alu dispatch=1 ",
                "payload_stability_mismatches",
            ),
            (
                "sampler",
                "[NPU-SAMPLER-ARGMAX-LEDGER][PASS] dispatch=1 ",
                "invalid_tokens",
            ),
        )

        for grammar, line_prefix, removable_field in grammars:
            marker_index = next(
                index
                for index, line in enumerate(base)
                if line.startswith(line_prefix)
            )
            original = base[marker_index]
            removable_token = next(
                token
                for token in original.split()
                if token.startswith(removable_field + "=")
            )
            mutations = {
                "unknown_nonzero": original + " future_error=1",
                "unknown_zero": original + " future_error=0",
                "non_field_tail": original + " trailing-junk",
                "duplicate": original + " " + removable_token,
                "missing": " ".join(
                    token
                    for token in original.split()
                    if token != removable_token
                ),
            }
            for mutation, mutated_line in mutations.items():
                with self.subTest(grammar=grammar, mutation=mutation):
                    mutant = list(base)
                    mutant[marker_index] = mutated_line
                    self.rejected(
                        mutant,
                        "unknown fields|malformed field token|duplicate field|"
                        "missing required fields",
                    )


if __name__ == "__main__":
    unittest.main()
