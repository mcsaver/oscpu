from __future__ import annotations

import hashlib
import importlib.util
import pathlib
import sys
import unittest


TOOL = pathlib.Path(__file__).resolve().parents[1] / "tools" / (
    "irrevocable_owner_residency_evidence.py"
)
SPEC = importlib.util.spec_from_file_location(
    "irrevocable_owner_residency_evidence_tested", TOOL)
assert SPEC is not None and SPEC.loader is not None
evidence = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = evidence
SPEC.loader.exec_module(evidence)


class OwnerResidencyEvidenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.root = pathlib.Path(__file__).resolve().parents[5]
        rtl_sha, _ = evidence.arch.rtl_binding(cls.root)
        cls.design_id = f"sha256:{rtl_sha}"

    def positive_text(self, name: str) -> str:
        spec = evidence.POSITIVE[name]
        return "\n".join((
            spec["marker"],
            f"[PASS] {spec['test']}",
            f"[RTL-DESIGN-ID] {self.design_id}",
            "[RESULT] PASS",
            "",
        ))

    def variant_fixture(self):
        module = evidence.load_variant_module(self.root)
        source_paths = sorted({spec.source_rel for spec in module.VARIANTS})
        live = {
            name: hashlib.sha256((self.root / name).read_bytes()).hexdigest()
            for name in source_paths
        }
        rows = []
        logs = {}
        for spec in module.VARIANTS:
            original, variant = module.reconstruct_variant(self.root, spec)
            rows.append({
                "name": spec.name,
                "source": spec.source_rel,
                "make_variable": spec.make_variable,
                "test_name": spec.test_name,
                "original_sha256": hashlib.sha256(
                    original.encode("utf-8")).hexdigest(),
                "variant_sha256": hashlib.sha256(
                    variant.encode("utf-8")).hexdigest(),
                "expected_marker": spec.expected_marker,
                "marker_observed": True,
                "old_same_edge_assertion_quiet": True,
                "compile_success": True,
                "dynamic_rejected": True,
                "make_returncode": 2,
            })
            logs[spec.name] = "\n".join((
                f"[COMPILE] iverilog -s {spec.test_name}",
                spec.expected_marker,
                f"[FAIL] {spec.test_name} errors=1",
                "[RESULT] FAIL status=1",
                "",
            ))
        payload = {
            "schema": evidence.VARIANT_SCHEMA,
            "suite_run_id": evidence.RUN_ID,
            "required": len(rows),
            "compile_success": len(rows),
            "dynamic_rejected": len(rows),
            "source_unchanged": True,
            "source_sha256_before": live,
            "source_sha256_after": live,
            "results": rows,
        }
        return module, payload, logs

    def test_positive_log_accepts_exact_markers(self) -> None:
        for name, spec in evidence.POSITIVE.items():
            evidence.validate_positive_text(
                self.positive_text(name),
                test_name=spec["test"],
                marker=spec["marker"],
                design_id=self.design_id,
            )

    def test_positive_log_rejects_foreign_design(self) -> None:
        spec = evidence.POSITIVE["store"]
        text = self.positive_text("store").replace(
            self.design_id, "sha256:" + "0" * 64)
        with self.assertRaisesRegex(ValueError, "RTL-DESIGN-ID"):
            evidence.validate_positive_text(
                text,
                test_name=spec["test"],
                marker=spec["marker"],
                design_id=self.design_id,
            )

    def test_positive_log_rejects_failure_marker(self) -> None:
        spec = evidence.POSITIVE["amo"]
        with self.assertRaisesRegex(ValueError, "unexpected failure"):
            evidence.validate_positive_text(
                self.positive_text("amo") + "[CHECK-FAIL] unrelated\n",
                test_name=spec["test"],
                marker=spec["marker"],
                design_id=self.design_id,
            )

    def test_variant_payload_accepts_reconstructed_sources(self) -> None:
        _, payload, logs = self.variant_fixture()
        rows = evidence.validate_variant_payload(self.root, payload, logs)
        self.assertEqual(len(rows), 2)

    def test_variant_payload_rejects_missing_identity(self) -> None:
        _, payload, logs = self.variant_fixture()
        payload["results"].pop()
        with self.assertRaisesRegex(ValueError, "aggregate is incomplete"):
            evidence.validate_variant_payload(self.root, payload, logs)

    def test_variant_payload_rejects_stale_variant_digest(self) -> None:
        _, payload, logs = self.variant_fixture()
        payload["results"][0]["variant_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "rejection is incomplete"):
            evidence.validate_variant_payload(self.root, payload, logs)

    def test_variant_payload_rejects_old_assertion_failure(self) -> None:
        module, payload, logs = self.variant_fixture()
        spec = module.VARIANTS[0]
        logs[spec.name] += spec.superseded_same_edge_marker + "\n"
        with self.assertRaisesRegex(ValueError, "rejection is incomplete"):
            evidence.validate_variant_payload(self.root, payload, logs)

    def test_canonical_top_flush_is_static_low(self) -> None:
        text = (self.root / "npc/rv64/vsrc/core/NpcCoreTop.v").read_text(
            encoding="utf-8")
        self.assertEqual(text.count(evidence.TOP_FLUSH_BINDING), 1)


if __name__ == "__main__":
    unittest.main()
