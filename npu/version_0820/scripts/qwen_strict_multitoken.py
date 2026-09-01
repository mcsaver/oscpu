#!/usr/bin/env python3
"""Validate the frozen multi-token strict-NPU oracle and run ledger."""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
from typing import Any, Iterable


ORACLE_SCHEMA = "qwen35-08b-q8_0-strict-smoke-oracle-v2"
MODEL_SHA256 = "37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f"
LLAMA_COMMIT = "95c409c13625a23da2aa37270339ce9179215a18"
SCRIPTED_DEPTHS = (2, 8)
PROMPT_TOKEN_IDS = [87]
GENERATED_TOKEN_IDS = [283, 220, 16, 15, 198, 88, 283, 220]
OUTPUT_TEXT = " = 10\ny = "

# Dispatch 1 initializes the recurrent cache and therefore executes all 367
# F32 ALU owners.  Dispatch 2 and later preserve the same owner/required
# cardinality, but 36 cache_r/cache_s SCALE owners are canonical zero-work NPU
# transactions.  They complete in SystemTop without starting the raw32 child.
F32_ALU_TRANSACTIONS_PER_DISPATCH = 367
F32_ALU_ZERO_TRANSACTIONS_PER_STEADY_DISPATCH = 36
F32_ALU_BOOTSTRAP_FIRST_HOLDS = 367
F32_ALU_STEADY_FIRST_HOLDS = 331
F32_ALU_BOOTSTRAP_RAW_READ_BYTES = 211_292_672
F32_ALU_BOOTSTRAP_RAW_WRITE_BYTES = 115_820_800
F32_ALU_STEADY_RAW_READ_BYTES = 191_091_200
F32_ALU_STEADY_RAW_WRITE_BYTES = 95_619_328


class ContractError(ValueError):
    """Raised when a frozen oracle or result violates the strict contract."""


def _fail(message: str) -> None:
    raise ContractError(message)


def _load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        _fail(f"cannot read JSON {path}: {exc}")
    if not isinstance(value, dict):
        _fail(f"JSON root must be an object: {path}")
    return value


def _require_equal(actual: Any, expected: Any, field: str) -> None:
    if actual != expected:
        _fail(f"{field} mismatch: actual={actual!r} expected={expected!r}")


def _require_token_ids(value: Any, field: str) -> list[int]:
    if (
        not isinstance(value, list)
        or not value
        or any(type(token) is not int or token < 0 or token >= 248320 for token in value)
    ):
        _fail(f"{field} must be a nonempty in-vocabulary integer list")
    return value


def validate_oracle_document(
    oracle: dict[str, Any],
    *,
    model_sha256: str = MODEL_SHA256,
    llama_commit: str = LLAMA_COMMIT,
) -> dict[str, Any]:
    _require_equal(oracle.get("schema"), ORACLE_SCHEMA, "schema")
    _require_equal(oracle.get("model_sha256"), model_sha256, "model_sha256")
    _require_equal(oracle.get("llama_commit"), llama_commit, "llama_commit")
    _require_equal(oracle.get("prompt_mode"), "raw-no-conversation", "prompt_mode")
    _require_equal(
        oracle.get("scripted_profiles"),
        {"prefix-2": 2, "extended-8": 8},
        "scripted_profiles",
    )

    sampler = oracle.get("sampler")
    if not isinstance(sampler, dict):
        _fail("sampler must be an object")
    expected_sampler = {
        "seed": 1,
        "temperature": 0,
        "top_k": 1,
        "n_batch": 1,
        "n_ubatch": 1,
        "n_predict": 8,
    }
    for key, expected in expected_sampler.items():
        _require_equal(sampler.get(key), expected, f"sampler.{key}")

    turns = oracle.get("turns")
    if not isinstance(turns, list) or len(turns) != 1 or not isinstance(turns[0], dict):
        _fail("turns must contain exactly one object")
    turn = turns[0]
    expected_scalars = {
        "turn": "smoke",
        "prompt_file": "tests/vectors/qwen35_08b_q8_0/smoke.txt",
        "prompt_text": "x",
        "max_tokens": 8,
        "prompt_tokens": 1,
        "generated_tokens": 8,
        "output_text": OUTPUT_TEXT,
    }
    for key, expected in expected_scalars.items():
        _require_equal(turn.get(key), expected, f"turns[0].{key}")

    prompt_ids = _require_token_ids(turn.get("prompt_token_ids"), "turns[0].prompt_token_ids")
    generated_ids = _require_token_ids(
        turn.get("generated_token_ids"), "turns[0].generated_token_ids"
    )
    _require_equal(prompt_ids, PROMPT_TOKEN_IDS, "turns[0].prompt_token_ids")
    _require_equal(generated_ids, GENERATED_TOKEN_IDS, "turns[0].generated_token_ids")
    _require_equal(len(prompt_ids), turn["prompt_tokens"], "prompt token cardinality")
    _require_equal(
        len(generated_ids), turn["generated_tokens"], "generated token cardinality"
    )
    _require_equal(
        turn["generated_tokens"], turn["max_tokens"], "generated/max token cardinality"
    )
    return turn


def load_oracle(
    path: pathlib.Path,
    *,
    model_sha256: str = MODEL_SHA256,
    llama_commit: str = LLAMA_COMMIT,
) -> dict[str, Any]:
    oracle = _load_json(path)
    validate_oracle_document(
        oracle, model_sha256=model_sha256, llama_commit=llama_commit
    )
    return oracle


def read_token_ids(path: pathlib.Path) -> list[int]:
    try:
        lines = path.read_text(encoding="ascii").splitlines()
    except (OSError, UnicodeError) as exc:
        _fail(f"cannot read token trace {path}: {exc}")
    if not lines:
        _fail(f"token trace is empty: {path}")
    values: list[int] = []
    for index, line in enumerate(lines, 1):
        if not line or not line.isascii() or not line.isdecimal():
            _fail(f"token trace has a non-integer at {path}:{index}")
        value = int(line)
        if value >= 248320:
            _fail(f"token trace has an out-of-vocabulary ID at {path}:{index}: {value}")
        values.append(value)
    return values


def validate_token_ids(
    oracle: dict[str, Any],
    max_tokens: int,
    prompt_ids: list[int],
    generated_ids: list[int],
) -> dict[str, Any]:
    if max_tokens not in SCRIPTED_DEPTHS:
        _fail(f"scripted token depth must be one of {SCRIPTED_DEPTHS}: {max_tokens}")
    turn = validate_oracle_document(oracle)
    expected_generated = turn["generated_token_ids"][:max_tokens]
    _require_equal(prompt_ids, turn["prompt_token_ids"], "actual prompt token IDs")
    _require_equal(generated_ids, expected_generated, "actual generated token IDs")
    _require_equal(len(generated_ids), max_tokens, "actual generated token count")
    return {
        "max_tokens": max_tokens,
        "prompt_token_ids": prompt_ids,
        "generated_token_ids": generated_ids,
        "output_text": OUTPUT_TEXT if max_tokens == 8 else " = ",
    }


def expected_ledger(max_tokens: int) -> dict[str, int]:
    if max_tokens not in SCRIPTED_DEPTHS:
        _fail(f"scripted token depth must be one of {SCRIPTED_DEPTHS}: {max_tokens}")
    per_dispatch = {
        "required": 1080,
        "sampler_elements": 248320,
        "sampler_read_bytes": 993288,
        "q8_transactions": 187,
        "f32_alu_transactions": F32_ALU_TRANSACTIONS_PER_DISPATCH,
        "f32_mover_transactions": 91,
        "nonportal_required": 435,
        "q8_raw_copy_bytes": 798887936,
        "f32_mover_raw_read_copy_bytes": 20353172,
        "f32_mover_raw_write_copy_bytes": 39079936,
    }
    required_total = per_dispatch["required"] * max_tokens
    steady_dispatches = max_tokens - 1
    f32_alu_first_holds = (
        F32_ALU_BOOTSTRAP_FIRST_HOLDS
        + F32_ALU_STEADY_FIRST_HOLDS * steady_dispatches
    )
    f32_alu_raw_read_copy_bytes = (
        F32_ALU_BOOTSTRAP_RAW_READ_BYTES
        + F32_ALU_STEADY_RAW_READ_BYTES * steady_dispatches
    )
    f32_alu_raw_write_copy_bytes = (
        F32_ALU_BOOTSTRAP_RAW_WRITE_BYTES
        + F32_ALU_STEADY_RAW_WRITE_BYTES * steady_dispatches
    )
    return {
        "preflight_cohorts": 3 + max_tokens,
        "dispatches": max_tokens,
        "bootstrap_dispatches": 1,
        "steady_dispatches": steady_dispatches,
        "required_per_dispatch": per_dispatch["required"],
        "system_transactions": required_total,
        "cpu_config_commands": 30 * required_total,
        "cpu_tensor_commands": 31 * required_total,
        "cpu_terminals": 31 * required_total,
        "public_commands": required_total,
        "public_completions": required_total,
        "required_issued": required_total,
        "required_completed": required_total,
        "sampler_argmax_dispatches": max_tokens,
        "sampler_argmax_transactions": max_tokens,
        "sampler_argmax_transactions_per_dispatch": 1,
        "sampler_argmax_elements": per_dispatch["sampler_elements"] * max_tokens,
        "sampler_argmax_elements_per_dispatch": per_dispatch["sampler_elements"],
        "sampler_argmax_read_bytes": per_dispatch["sampler_read_bytes"] * max_tokens,
        "sampler_argmax_read_bytes_per_dispatch": per_dispatch["sampler_read_bytes"],
        "sampler_argmax_scalar_write_bytes": 4 * max_tokens,
        "sampler_argmax_scalar_write_bytes_per_dispatch": 4,
        "sampler_argmax_sampled_tokens": max_tokens,
        "sampler_argmax_sampled_tokens_per_dispatch": 1,
        "sampler_argmax_host_scalar_copy_bytes": 4 * max_tokens,
        "sampler_argmax_host_scalar_copy_bytes_per_dispatch": 4,
        "sampler_argmax_full_vocab_host_exports": 0,
        "sampler_argmax_full_vocab_host_export_bytes": 0,
        "sampler_argmax_cpu_candidate_scans": 0,
        "sampler_argmax_invalid_tokens": 0,
        "f32_alu_owner_transactions": per_dispatch["f32_alu_transactions"] * max_tokens,
        "f32_alu_zero_cardinality_transactions": (
            F32_ALU_ZERO_TRANSACTIONS_PER_STEADY_DISPATCH * steady_dispatches
        ),
        "f32_alu_nonempty_portal_commands": f32_alu_first_holds,
        "f32_alu_portal_first_hold_cycles": f32_alu_first_holds,
        "q8_gemv_owner_transactions": per_dispatch["q8_transactions"] * max_tokens,
        "f32_mover_owner_transactions": per_dispatch["f32_mover_transactions"] * max_tokens,
        "nonportal_required": per_dispatch["nonportal_required"] * max_tokens,
        "q8_portal_raw_copy_bytes": per_dispatch["q8_raw_copy_bytes"] * max_tokens,
        "f32_alu_portal_raw_read_copy_bytes": f32_alu_raw_read_copy_bytes,
        "f32_alu_portal_raw_write_copy_bytes": f32_alu_raw_write_copy_bytes,
        "f32_mover_portal_raw_read_copy_bytes": per_dispatch[
            "f32_mover_raw_read_copy_bytes"
        ]
        * max_tokens,
        "f32_mover_portal_raw_write_copy_bytes": per_dispatch[
            "f32_mover_raw_write_copy_bytes"
        ]
        * max_tokens,
        "functional_command_dispatches": 0,
        "functional_command_completions": 0,
        "functional_read_bytes": 0,
        "functional_write_bytes": 0,
        "functional_q8_blocks": 0,
        "functional_q8_macs": 0,
        "functional_vector_elements": 0,
        "old_gmem_requests": 0,
        "old_gmem_responses": 0,
        "old_q8_portal_transactions": 0,
        "old_f32_alu_portal_transactions": 0,
        "old_f32_mover_portal_transactions": 0,
    }


def validate_ledger(ledger: dict[str, Any], max_tokens: int) -> None:
    for key, expected in expected_ledger(max_tokens).items():
        if key not in ledger:
            _fail(f"system ledger is missing {key}")
        _require_equal(ledger[key], expected, f"system_ledger.{key}")


def validate_run_artifacts(
    oracle: dict[str, Any],
    max_tokens: int,
    prompt_ids: list[int],
    generated_ids: list[int],
    ledger: dict[str, Any],
) -> dict[str, Any]:
    token_summary = validate_token_ids(
        oracle, max_tokens, prompt_ids, generated_ids
    )
    validate_ledger(ledger, max_tokens)
    return {
        **token_summary,
        "dispatches": ledger["dispatches"],
        "required_completed": ledger["required_completed"],
        "sampler_argmax_elements": ledger["sampler_argmax_elements"],
    }


def _add_oracle_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("oracle", type=pathlib.Path)
    parser.add_argument("--model-sha256", default=MODEL_SHA256)
    parser.add_argument("--llama-commit", default=LLAMA_COMMIT)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    oracle_parser = subparsers.add_parser("oracle", help="validate the frozen oracle")
    _add_oracle_arguments(oracle_parser)

    tokens_parser = subparsers.add_parser("tokens", help="validate token trace files")
    _add_oracle_arguments(tokens_parser)
    tokens_parser.add_argument("--max-tokens", type=int, required=True)
    tokens_parser.add_argument("--prompt-ids", type=pathlib.Path, required=True)
    tokens_parser.add_argument("--generated-ids", type=pathlib.Path, required=True)

    result_parser = subparsers.add_parser(
        "result", help="validate token traces and the scaled NPU ledger"
    )
    _add_oracle_arguments(result_parser)
    result_parser.add_argument("--max-tokens", type=int, required=True)
    result_parser.add_argument("--prompt-ids", type=pathlib.Path, required=True)
    result_parser.add_argument("--generated-ids", type=pathlib.Path, required=True)
    result_parser.add_argument("--ledger", type=pathlib.Path, required=True)
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        oracle = load_oracle(
            args.oracle,
            model_sha256=args.model_sha256,
            llama_commit=args.llama_commit,
        )
        if args.command == "oracle":
            summary: dict[str, Any] = {
                "schema": oracle["schema"],
                "scripted_depths": list(SCRIPTED_DEPTHS),
                "golden_tokens": len(GENERATED_TOKEN_IDS),
            }
        else:
            prompt_ids = read_token_ids(args.prompt_ids)
            generated_ids = read_token_ids(args.generated_ids)
            if args.command == "tokens":
                summary = validate_token_ids(
                    oracle, args.max_tokens, prompt_ids, generated_ids
                )
            else:
                ledger = _load_json(args.ledger)
                summary = validate_run_artifacts(
                    oracle,
                    args.max_tokens,
                    prompt_ids,
                    generated_ids,
                    ledger,
                )
    except ContractError as exc:
        print(f"[QWEN-STRICT-MULTITOKEN][FAIL] {exc}", file=sys.stderr)
        return 1

    print(
        "[QWEN-STRICT-MULTITOKEN][PASS] "
        + json.dumps(summary, ensure_ascii=False, separators=(",", ":"))
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
