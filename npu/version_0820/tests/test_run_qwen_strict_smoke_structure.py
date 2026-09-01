#!/usr/bin/env python3
"""Direct structural checks for the multi-phase strict Qwen smoke driver."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import tempfile
import unittest


PROJECT_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = PROJECT_ROOT / "scripts" / "run_qwen_strict_smoke.sh"
SOURCE = SCRIPT.read_text(encoding="utf-8")
EMBEDDED_PROGRAMS = re.findall(r"<<'PY'\n(.*?)\nPY", SOURCE, flags=re.DOTALL)


def function_body(name: str, next_name: str) -> str:
    start = SOURCE.index(f"{name}() {{")
    end = SOURCE.index(f"\n{next_name}() {{", start)
    return SOURCE[start:end]


def run_embedded(index: int, *arguments: pathlib.Path) -> None:
    old_argv = sys.argv
    try:
        sys.argv = [str(SCRIPT), *(str(argument) for argument in arguments)]
        exec(
            compile(
                EMBEDDED_PROGRAMS[index],
                f"{SCRIPT}:embedded-python-{index + 1}",
                "exec",
            ),
            {"__name__": "__strict_smoke_embedded_test__"},
        )
    finally:
        sys.argv = old_argv


class StrictSmokeStructureTests(unittest.TestCase):
    def test_bash_syntax_and_all_embedded_python_compile(self) -> None:
        subprocess.run(["bash", "-n", str(SCRIPT)], check=True)
        self.assertEqual(len(EMBEDDED_PROGRAMS), 5)
        for index, program in enumerate(EMBEDDED_PROGRAMS, start=1):
            compile(program, f"{SCRIPT}:embedded-python-{index}", "exec")

    def test_every_llama_phase_uses_the_full_hermetic_env_surface(self) -> None:
        expected = {
            "LLAMA_NPU_REQUIRED",
            "LLAMA_NPU_ADMISSION_ONLY",
            "LLAMA_NPU_GRAPH_COLLECT",
            "LLAMA_NPU_GRAPH_COLLECT_DISPATCH",
            "LLAMA_NPU_STRICT_SAMPLING",
            "LLAMA_NPU_GRAPH_PROFILE",
            "LLAMA_NPU_GRAPH_NUMERIC_PROFILE",
            "LLAMA_NPU_GRAPH_SOURCE_COMMIT",
            "LLAMA_NPU_GRAPH_MODEL_SHA256",
            "LLAMA_NPU_GRAPH_FUSED_OPS",
            "LLAMA_ARG_BACKEND_SAMPLING",
        }
        names_block = re.search(
            r"declare -ar HERMETIC_NPU_ENV_NAMES=\(\n(.*?)\n\)",
            SOURCE,
            flags=re.DOTALL,
        )
        unset_block = re.search(
            r"declare -ar HERMETIC_NPU_ENV_UNSET_ARGS=\(\n(.*?)\n\)",
            SOURCE,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(names_block)
        self.assertIsNotNone(unset_block)
        self.assertEqual(set(names_block.group(1).split()), expected)
        self.assertEqual(set(re.findall(r"-u (LLAMA_[A-Z0-9_]+)", unset_block.group(1))), expected)

        functions = (
            ("collect_graph_phase", "validate_strict_log"),
            ("verify_cpu_reference", "run_scripted_turn"),
            ("run_scripted_turn", "run_interactive"),
            ("run_interactive", "validate_prompt_cache_creation_log"),
            ("prepare_steady_prompt_cache", "run_admission_phase"),
            ("run_admission_phase", "run_admission_matrix"),
        )
        for name, next_name in functions:
            body = function_body(name, next_name)
            self.assertIn("write_hermetic_env_prefix", body, name)
            self.assertIn('env "${HERMETIC_NPU_ENV_UNSET_ARGS[@]}"', body, name)

    def test_dispatch_three_through_eight_are_independent_repeat_inputs(self) -> None:
        self.assertIn("STEADY_REPEAT_DISPATCHES=(3 4 5 6 7 8)", SOURCE)
        raw_hashes = {
            3: "1131a4dedaf9430e545cea4516807cb0cac67c357b4c8340d4cf4b21ee877959",
            4: "389e60d07ede153efadfc3724aaf8558275041003962c216fa6894bbb0e0929b",
            5: "5bcfa951d47d0ee7c85b2519f9be82eea102b668cf4ec856f55ae804706fccf2",
            6: "0b13c7cf1b333bcc3fb233a6e2cd1e129ef4ac34a9839853598a04c40e31b560",
            7: "f5f55fc67d2454c7ddde86b13457500d4627961212dd01e6c31316bc39a6fb75",
            8: "6e1493ae53b558bf0058dc5692ea906b50150bbe708f0f2b51fc0b463cb8d37b",
        }
        manifest_hashes = {
            3: "1309a6a176a5c1c5627dca7d28c5cf2578ff9c515d5ebc8ca60f1ff21ef766f2",
            4: "1ce4f0735a8131a2198bbebdba8422bf4d86223f41a4b7d73b610bfc4c960259",
            5: "1266d5f928f67e24244ede685acebdd500a54019a2804cd54b0e08aa476bec5e",
            6: "59ccc88eeb7f258f189ced86dcc995bd85074cd021b152c44e5bdd7115c1edf8",
            7: "1091cf6b1c48f11b360e86e804db6fc65c68dded747015753ff1e2f2f8cc0822",
            8: "0d6a67f2dc30c9a759c3200cb267d3f0c3ab0d91863d68064031a7365b9bcce8",
        }
        for dispatch in raw_hashes:
            self.assertIn(f"[{dispatch}]='{raw_hashes[dispatch]}'", SOURCE)
            self.assertIn(f"[{dispatch}]='{manifest_hashes[dispatch]}'", SOURCE)
        self.assertIn(
            "433686dc48cd927ca930b80c8430beec459080cdfc813cd25d927c47e772695f",
            SOURCE,
        )
        self.assertIn('manifest_bundle_repeat_args+=(--steady-repeat-manifest', SOURCE)
        self.assertIn('--expect-bundle-sha256 "${EXPECTED_MANIFEST_BUNDLE_SHA}"', SOURCE)
        self.assertIn('NPU_STEADY_REPEAT_MANIFESTS="${steady_repeat_manifest_env}"', SOURCE)
        self.assertIn("graph manifest test count is not exactly 39", SOURCE)

    def test_cache_creation_and_controlled_replay_are_fail_closed(self) -> None:
        creation = function_body(
            "validate_prompt_cache_creation_log", "validate_prompt_cache_replay_log"
        )
        replay = function_body(
            "validate_prompt_cache_replay_log", "prepare_steady_prompt_cache"
        )
        self.assertIn("saved session before last token to", creation)
        self.assertIn("n_new = 2", creation)
        self.assertIn("loaded a session with prompt size of 2 tokens", replay)
        self.assertIn("session file has exact match for prompt!", replay)
        self.assertIn("common_replay_last_token: failed to replay last token", replay)
        self.assertIn("replay_attempted_controlled_stop", replay)
        self.assertIn("compute_started=0", replay)
        self.assertIn("attempt < loaded < exact < admission < replay_stop", replay)
        self.assertIn("read-only steady replay mutated", SOURCE)

    def test_cache_creation_log_fixture_and_duplicate_rejection(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            session = root / "token2.session"
            log = root / "creation.log"
            evidence = root / "creation.json"
            session.write_bytes(b"frozen-two-token-session")
            lines = [
                f"0 I llama_completion: attempting to load saved session from '{session}'",
                "1 I llama_completion: session file does not exist, will create.",
                f"2 I cmn  common_promp: saved session before last token to {session}, n_new = 2",
            ]
            log.write_text("\n".join(lines) + "\n", encoding="utf-8")
            run_embedded(3, log, session, evidence)
            payload = __import__("json").loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["saved_before_last_token"], 1)
            self.assertEqual(payload["prompt_tokens_saved"], 2)

            log.write_text("\n".join([*lines, lines[-1]]) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(SystemExit, "marker count is 2"):
                run_embedded(3, log, session, evidence)

    def test_cache_replay_fixture_locks_the_controlled_stop(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            session = root / "token2.session"
            log = root / "steady.log"
            evidence = root / "replay.json"
            session.write_bytes(b"frozen-two-token-session")
            lines = [
                f"0 I llama_completion: attempting to load saved session from '{session}'",
                "1 I llama_completion: loaded a session with prompt size of 2 tokens",
                "2 I llama_completion: session file has exact match for prompt!",
                "[NPU-STRICT-ADMISSION-ONLY][PASS] graph=dispatch "
                "phase=post-binding-pre-scheduler compute_started=0 "
                "dispatch_graph_scheduler_allocated=0 compute_dispatched=0",
                "3 E common_replay_last_token: failed to replay last token",
            ]
            log.write_text("\n".join(lines) + "\n", encoding="utf-8")
            run_embedded(4, log, session, evidence)
            payload = __import__("json").loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(payload["exact_prompt_match"], 1)
            self.assertEqual(payload["replay_attempted_controlled_stop"], 1)
            self.assertEqual(payload["replay_completed"], 0)

            log.write_text(
                "\n".join([*lines, "4 I llama_completion: replayed last token from session"])
                + "\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(SystemExit, "unexpectedly completed"):
                run_embedded(4, log, session, evidence)

    def test_v4_envelope_and_phase_ledger_are_explicit(self) -> None:
        self.assertIn("qwen35-08b-q8_0-npu-strict-system-v4", SOURCE)
        self.assertNotIn("qwen35-08b-q8_0-npu-strict-system-v3", SOURCE)
        for field in (
            "bootstrap_manifest_identity",
            "steady_manifest_identity",
            "manifest_bundle_identity",
            "admission_identity",
            "ledger_phases",
            "f32_alu_zero_cardinality_transactions",
            "f32_alu_nonempty_portal_commands",
            "f32_alu_bootstrap_portal_raw_read_copy_bytes",
            "f32_alu_bootstrap_portal_raw_write_copy_bytes",
            "f32_alu_steady_portal_raw_read_copy_bytes",
            "f32_alu_steady_portal_raw_write_copy_bytes",
        ):
            self.assertIn(field, SOURCE)
        self.assertNotIn("required_per_phase=1080/0", SOURCE)
        self.assertNotIn("admission_per_dispatch=1080/0", SOURCE)
        self.assertIn("admission_required_per_dispatch=1080", SOURCE)
        self.assertIn("admission_unsupported_per_dispatch=0", SOURCE)


if __name__ == "__main__":
    unittest.main()
