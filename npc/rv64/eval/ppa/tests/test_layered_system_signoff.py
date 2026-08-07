from __future__ import annotations

import hashlib
import json
import pathlib
import tempfile
import unittest

from npc.rv64.eval.ppa.tools import layered_system_signoff as signoff


DESIGN_ID = "sha256:" + "a" * 64


def base_policy() -> dict:
    return {
        "default_signoff_conjunction": list(signoff.DEFAULT_CONJUNCTION),
        "optional_full_ubuntu": {
            "launch_policy": "explicit-user-request-only",
            "absence_blocks_default_signoff": False,
        },
        "promotion_boundary": {
            "required_default_claim": "LAYERED_SYSTEM_SIGNOFF_PASS_CURRENT_IDENTITY",
            "ubuntu2204_full_recertification": "OPTIONAL_NOT_IMPLIED",
        },
    }


def layer(**extra: object) -> dict:
    value = {"status": "PASS", "design_id": DESIGN_ID}
    value.update(extra)
    return value


class LayeredSystemSignoffTests(unittest.TestCase):
    def compose(self, **updates: dict) -> dict:
        values = {
            "policy": base_policy(),
            "policy_artifact": {
                "kind": "layered_signoff_policy",
                "path": "policy.json",
                "sha256": "0" * 64,
                "size_bytes": 1,
            },
            "checker_artifact": {
                "kind": "layered_signoff_checker",
                "path": "checker.py",
                "sha256": "1" * 64,
                "size_bytes": 1,
            },
            "schema_artifact": {
                "kind": "layered_signoff_schema",
                "path": "schema.json",
                "sha256": "2" * 64,
                "size_bytes": 1,
            },
            "design_id": DESIGN_ID,
            "rtl_file_count": 146,
            "source_directories": {
                "l0_module": ".github/task-runs/l0/module",
                "l1_checker_replay": ".github/task-runs/l1",
                "l2_mini_system": ".github/task-runs/l2/mini-system",
                "l3_lightweight_linux": ".github/task-runs/l3/lightweight-linux",
            },
            "l0": layer(),
            "l1": layer(),
            "l2": layer(case="all"),
            "l3": layer(case="all"),
        }
        values.update(updates)
        return signoff.compose_receipt(**values)

    def test_default_conjunction_excludes_optional_ubuntu(self) -> None:
        result = self.compose()
        self.assertEqual(result["default_signoff_conjunction"], signoff.DEFAULT_CONJUNCTION)
        self.assertEqual(result["optional_full_ubuntu"]["status"], "NOT_RUN")
        self.assertFalse(result["optional_full_ubuntu"]["blocks_default_signoff"])
        self.assertIn("PPA qualification", result["non_claims"][-1])

    def test_design_identity_mismatch_is_rejected(self) -> None:
        with self.assertRaisesRegex(signoff.SignoffError, "common PASS design"):
            self.compose(l3=layer(case="all", design_id="sha256:" + "b" * 64))

    def test_directed_case_cannot_claim_complete_layer(self) -> None:
        for name in ("l2", "l3"):
            with self.subTest(layer=name), self.assertRaisesRegex(
                signoff.SignoffError, "directed L2/L3"
            ):
                self.compose(**{name: layer(case="boot")})

    def test_optional_ubuntu_cannot_become_a_default_conjunct(self) -> None:
        policy = base_policy()
        policy["default_signoff_conjunction"].append("UBUNTU_2204")
        with self.assertRaisesRegex(signoff.SignoffError, "default conjunction"):
            self.compose(policy=policy)

    def test_direct_l1_source_directory_is_preserved(self) -> None:
        source_directories = {
            "l0_module": ".github/task-runs/l0/module",
            "l1_full_core": ".github/task-runs/l1",
            "l2_mini_system": ".github/task-runs/l2/mini-system",
            "l3_lightweight_linux": ".github/task-runs/l3/lightweight-linux",
        }
        result = self.compose(source_directories=source_directories)
        self.assertEqual(result["source_directories"], source_directories)

    def test_l1_authority_rejects_ambiguous_top_status(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            source = root / ".github/task-runs/l1"
            source.mkdir(parents=True)
            (source / "full-core-current.status").write_text(
                "PASS\n", encoding="utf-8"
            )
            (source / "full-core-checker-replay.status").write_text(
                "PASS\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(signoff.SignoffError, "ambiguous"):
                signoff.verify_l1(source, design_id=DESIGN_ID, root=root)

    def test_l1_authority_rejects_missing_top_status(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            source = root / ".github/task-runs/l1"
            source.mkdir(parents=True)
            with self.assertRaisesRegex(signoff.SignoffError, "no supported"):
                signoff.verify_l1(source, design_id=DESIGN_ID, root=root)

    def test_checksum_manifest_rejects_duplicate_path(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            evidence.mkdir(parents=True)
            payload = evidence / "payload.txt"
            payload.write_text("payload\n", encoding="utf-8")
            digest = hashlib.sha256(payload.read_bytes()).hexdigest()
            manifest = evidence / "manifest.sha256"
            manifest.write_text(
                f"{digest}  payload.txt\n{digest}  payload.txt\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(signoff.SignoffError, "duplicate"):
                signoff.parse_checksum_manifest(
                    manifest, base=evidence, root=root
                )

    def test_checksum_manifest_rejects_symlink_target(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            evidence.mkdir(parents=True)
            real = evidence / "real.txt"
            real.write_text("payload\n", encoding="utf-8")
            alias = evidence / "alias.txt"
            alias.symlink_to(real)
            digest = hashlib.sha256(real.read_bytes()).hexdigest()
            manifest = evidence / "manifest.sha256"
            manifest.write_text(f"{digest}  alias.txt\n", encoding="utf-8")
            with self.assertRaisesRegex(signoff.SignoffError, "symlink"):
                signoff.parse_checksum_manifest(
                    manifest, base=evidence, root=root
                )

    def test_seal_rejects_manifest_substitution(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            evidence.mkdir(parents=True)
            payload = evidence / "payload.txt"
            payload.write_text("payload\n", encoding="utf-8")
            digest = hashlib.sha256(payload.read_bytes()).hexdigest()
            manifest = evidence / "evidence-files.sha256"
            manifest.write_text(f"{digest}  payload.txt\n", encoding="utf-8")
            verify_log = evidence / "evidence-files.verify.log"
            verify_log.write_text("payload.txt: OK\n", encoding="utf-8")
            seal = evidence / "evidence-seal.txt"
            seal.write_text(
                "schema=npc-rv64-final-evidence-seal-v1\n"
                "file_count=1\n"
                f"manifest_sha256={hashlib.sha256(manifest.read_bytes()).hexdigest()}\n"
                f"verification_log_sha256={hashlib.sha256(verify_log.read_bytes()).hexdigest()}\n"
                "verification=PASS\n",
                encoding="utf-8",
            )
            manifest.write_text(f"{'0' * 64}  payload.txt\n", encoding="utf-8")
            with self.assertRaisesRegex(signoff.SignoffError, "seal hash"):
                signoff.verify_seal(evidence, root=root)

    def test_current_input_pair_rejects_drift(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            evidence.mkdir(parents=True)
            (evidence / "input-hashes-before.sha256").write_text(
                f"{'0' * 64}  before\n", encoding="utf-8"
            )
            (evidence / "input-hashes-after.sha256").write_text(
                f"{'1' * 64}  after\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(signoff.SignoffError, "before/after"):
                signoff.verify_current_inputs(evidence, root=root)

    def test_current_inputs_accept_exact_current_execution(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            payload = root / "npc/rv64/vsrc/core/OooCoreTop.v"
            evidence.mkdir(parents=True)
            payload.parent.mkdir(parents=True)
            payload.write_text("current RTL\n", encoding="utf-8")
            digest = hashlib.sha256(payload.read_bytes()).hexdigest()
            manifest = f"{digest}  {payload}\n"
            for name in ("input-hashes-before.sha256", "input-hashes-after.sha256"):
                (evidence / name).write_text(manifest, encoding="utf-8")

            result = signoff.verify_current_inputs(evidence, root=root)

            self.assertFalse(result["execution_reused"])
            self.assertEqual(result["replay_scope"], "exact-current-inputs")
            self.assertEqual(result["live_drift"], [])

    def test_current_inputs_accept_exact_identity_helper_replay(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            helper = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
            evidence.mkdir(parents=True)
            helper.parent.mkdir(parents=True)
            helper.write_text("current identity helper\n", encoding="utf-8")
            recorded = hashlib.sha256(b"recorded identity helper\n").hexdigest()
            manifest = f"{recorded}  {helper}\n"
            for name in ("input-hashes-before.sha256", "input-hashes-after.sha256"):
                (evidence / name).write_text(manifest, encoding="utf-8")

            result = signoff.verify_current_inputs(
                evidence,
                allowed_live_drift=signoff.LAYER_IDENTITY_HELPER_REPLAY_PATHS,
                root=root,
            )

            self.assertTrue(result["execution_reused"])
            self.assertEqual(result["replay_scope"], "rtl-identity-helper-only")
            self.assertEqual(
                result["live_drift"][0]["path"],
                "npc/rv64/eval/ppa/tools/architecture_hard_gates.py",
            )

    def test_current_inputs_reject_unlisted_live_drift(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            payload = root / "npc/rv64/rtl/core/OooCoreTop.v"
            evidence.mkdir(parents=True)
            payload.parent.mkdir(parents=True)
            payload.write_text("current RTL\n", encoding="utf-8")
            recorded = hashlib.sha256(b"recorded RTL\n").hexdigest()
            manifest = f"{recorded}  {payload}\n"
            for name in ("input-hashes-before.sha256", "input-hashes-after.sha256"):
                (evidence / name).write_text(manifest, encoding="utf-8")

            with self.assertRaisesRegex(signoff.SignoffError, "checksum mismatch"):
                signoff.verify_current_inputs(
                    evidence,
                    allowed_live_drift=signoff.LAYER_IDENTITY_HELPER_REPLAY_PATHS,
                    root=root,
                )

    def test_current_inputs_reject_unused_drift_allowance(self) -> None:
        with tempfile.TemporaryDirectory(prefix="rv64-layered-signoff-") as raw:
            root = pathlib.Path(raw)
            evidence = root / ".github/task-runs/a/evidence"
            helper = root / "npc/rv64/eval/ppa/tools/architecture_hard_gates.py"
            evidence.mkdir(parents=True)
            helper.parent.mkdir(parents=True)
            helper.write_text("same identity helper\n", encoding="utf-8")
            digest = hashlib.sha256(helper.read_bytes()).hexdigest()
            manifest = f"{digest}  {helper}\n"
            for name in ("input-hashes-before.sha256", "input-hashes-after.sha256"):
                (evidence / name).write_text(manifest, encoding="utf-8")

            with self.assertRaisesRegex(signoff.SignoffError, "differs from observed"):
                signoff.verify_current_inputs(
                    evidence,
                    allowed_live_drift=signoff.LAYER_IDENTITY_HELPER_REPLAY_PATHS,
                    root=root,
                )


if __name__ == "__main__":
    unittest.main()
