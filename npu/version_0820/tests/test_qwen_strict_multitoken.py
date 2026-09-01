#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import pathlib
import sys
import tempfile
import unittest


PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import qwen_strict_multitoken as contract  # noqa: E402


ORACLE_PATH = (
    PROJECT_ROOT / "tests" / "vectors" / "qwen35_08b_q8_0" / "strict-smoke-oracle.json"
)


class StrictMultiTokenContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.oracle = json.loads(ORACLE_PATH.read_text(encoding="utf-8"))

    def test_repository_oracle_is_the_frozen_eight_token_sequence(self) -> None:
        turn = contract.validate_oracle_document(self.oracle)
        self.assertEqual(turn["generated_token_ids"], contract.GENERATED_TOKEN_IDS)
        self.assertEqual(turn["output_text"], " = 10\ny = ")

    def test_two_and_eight_token_profiles_accept_exact_prefixes(self) -> None:
        for depth in contract.SCRIPTED_DEPTHS:
            with self.subTest(depth=depth):
                summary = contract.validate_token_ids(
                    self.oracle,
                    depth,
                    contract.PROMPT_TOKEN_IDS,
                    contract.GENERATED_TOKEN_IDS[:depth],
                )
                self.assertEqual(summary["max_tokens"], depth)

    def test_one_token_regression_is_not_a_scripted_acceptance_profile(self) -> None:
        with self.assertRaisesRegex(contract.ContractError, "token depth"):
            contract.validate_token_ids(
                self.oracle, 1, contract.PROMPT_TOKEN_IDS, [283]
            )

    def test_wrong_prompt_token_is_rejected(self) -> None:
        with self.assertRaisesRegex(contract.ContractError, "prompt token IDs"):
            contract.validate_token_ids(
                self.oracle, 2, [88], contract.GENERATED_TOKEN_IDS[:2]
            )

    def test_wrong_second_generated_token_is_rejected(self) -> None:
        with self.assertRaisesRegex(contract.ContractError, "generated token IDs"):
            contract.validate_token_ids(
                self.oracle, 2, contract.PROMPT_TOKEN_IDS, [283, 221]
            )

    def test_truncated_and_extra_generated_traces_are_rejected(self) -> None:
        cases = (
            contract.GENERATED_TOKEN_IDS[:7],
            contract.GENERATED_TOKEN_IDS + [1],
        )
        for generated in cases:
            with self.subTest(generated=generated):
                with self.assertRaisesRegex(contract.ContractError, "generated token IDs"):
                    contract.validate_token_ids(
                        self.oracle, 8, contract.PROMPT_TOKEN_IDS, generated
                    )

    def test_two_and_eight_dispatch_ledgers_are_bootstrap_plus_steady(self) -> None:
        phase_expected = {
            2: {
                "steady_dispatches": 1,
                "f32_alu_owner_transactions": 734,
                "f32_alu_zero_cardinality_transactions": 36,
                "f32_alu_portal_first_hold_cycles": 698,
                "f32_alu_portal_raw_read_copy_bytes": 402_383_872,
                "f32_alu_portal_raw_write_copy_bytes": 211_440_128,
            },
            8: {
                "steady_dispatches": 7,
                "f32_alu_owner_transactions": 2_936,
                "f32_alu_zero_cardinality_transactions": 252,
                "f32_alu_portal_first_hold_cycles": 2_684,
                "f32_alu_portal_raw_read_copy_bytes": 1_548_931_072,
                "f32_alu_portal_raw_write_copy_bytes": 785_156_096,
            },
        }
        for depth in contract.SCRIPTED_DEPTHS:
            with self.subTest(depth=depth):
                ledger = contract.expected_ledger(depth)
                contract.validate_ledger(ledger, depth)
                self.assertEqual(ledger["dispatches"], depth)
                self.assertEqual(ledger["bootstrap_dispatches"], 1)
                self.assertEqual(ledger["required_completed"], 1080 * depth)
                self.assertEqual(ledger["sampler_argmax_sampled_tokens"], depth)
                for field, expected in phase_expected[depth].items():
                    self.assertEqual(ledger[field], expected)

    def test_f32_alu_steady_ledger_is_not_linear_bootstrap_scaling(self) -> None:
        ledger = contract.expected_ledger(8)
        self.assertNotEqual(
            ledger["f32_alu_portal_raw_read_copy_bytes"],
            contract.F32_ALU_BOOTSTRAP_RAW_READ_BYTES * 8,
        )
        self.assertNotEqual(
            ledger["f32_alu_portal_first_hold_cycles"],
            contract.F32_ALU_BOOTSTRAP_FIRST_HOLDS * 8,
        )

    def test_ledger_rejects_missing_or_noncontiguous_dispatch_total(self) -> None:
        ledger = contract.expected_ledger(8)
        ledger["dispatches"] = 7
        with self.assertRaisesRegex(contract.ContractError, "dispatches"):
            contract.validate_ledger(ledger, 8)

    def test_ledger_rejects_required_completion_loss(self) -> None:
        ledger = contract.expected_ledger(8)
        ledger["required_completed"] -= 1
        with self.assertRaisesRegex(contract.ContractError, "required_completed"):
            contract.validate_ledger(ledger, 8)

    def test_ledger_rejects_host_vocab_export_or_cpu_scan(self) -> None:
        for field in (
            "sampler_argmax_full_vocab_host_exports",
            "sampler_argmax_full_vocab_host_export_bytes",
            "sampler_argmax_cpu_candidate_scans",
        ):
            with self.subTest(field=field):
                ledger = contract.expected_ledger(8)
                ledger[field] = 1
                with self.assertRaisesRegex(contract.ContractError, field):
                    contract.validate_ledger(ledger, 8)

    def test_ledger_rejects_owner_and_physical_traffic_drift(self) -> None:
        for field in (
            "f32_alu_owner_transactions",
            "f32_alu_zero_cardinality_transactions",
            "f32_alu_portal_first_hold_cycles",
            "q8_gemv_owner_transactions",
            "f32_mover_owner_transactions",
            "nonportal_required",
            "q8_portal_raw_copy_bytes",
            "f32_alu_portal_raw_read_copy_bytes",
            "f32_alu_portal_raw_write_copy_bytes",
            "f32_mover_portal_raw_write_copy_bytes",
        ):
            with self.subTest(field=field):
                ledger = contract.expected_ledger(8)
                ledger[field] += 1
                with self.assertRaisesRegex(contract.ContractError, field):
                    contract.validate_ledger(ledger, 8)

    def test_oracle_mutations_are_rejected(self) -> None:
        mutations = (
            ("schema", lambda value: value.__setitem__("schema", "v1")),
            (
                "n_predict",
                lambda value: value["sampler"].__setitem__("n_predict", 1),
            ),
            (
                "scripted_profiles",
                lambda value: value["scripted_profiles"].__setitem__("prefix-2", 1),
            ),
            (
                "generated_tokens",
                lambda value: value["turns"][0].__setitem__("generated_tokens", 1),
            ),
            (
                "token_ids",
                lambda value: value["turns"][0]["generated_token_ids"].__setitem__(1, 221),
            ),
            (
                "output_text",
                lambda value: value["turns"][0].__setitem__("output_text", " ="),
            ),
        )
        for name, mutate in mutations:
            with self.subTest(name=name):
                candidate = copy.deepcopy(self.oracle)
                mutate(candidate)
                with self.assertRaises(contract.ContractError):
                    contract.validate_oracle_document(candidate)

    def test_token_trace_parser_rejects_noninteger_and_oov_ids(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            path = pathlib.Path(temp_dir) / "tokens.ids"
            for payload in ("283\nnot-a-token\n", "248320\n", "\n"):
                with self.subTest(payload=payload):
                    path.write_text(payload, encoding="ascii")
                    with self.assertRaises(contract.ContractError):
                        contract.read_token_ids(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
