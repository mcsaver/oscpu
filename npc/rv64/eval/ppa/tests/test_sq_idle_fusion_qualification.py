#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[5]
TOOL = ROOT / "npc/rv64/eval/ppa/tools/sq_idle_fusion_qualification.py"
SCHEMA_PATH = ROOT / "npc/rv64/design/arch/sq-idle-fusion-qualification-v1.json"

SPEC = importlib.util.spec_from_file_location("sq_idle_fusion_qualification", TOOL)
assert SPEC is not None and SPEC.loader is not None
QUAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(QUAL)


class SqIdleFusionQualificationTests(unittest.TestCase):
    def marker(
        self,
        name: str,
        *,
        values: dict[str, object] | None = None,
        omit: set[str] | None = None,
        extra: tuple[str, object] | None = None,
        order: tuple[str, ...] | None = None,
        duplicate: tuple[str, object] | None = None,
    ) -> str:
        base: dict[str, object] = {
            "schema": QUAL.SCHEMA,
            "complete": 1,
            "available": 1,
            "overflow": 0,
            "malformed": 0,
            "cycles": 4,
            "prequal": 6,
            "exact": 5,
            "identity_or_lq_reject": 1,
            "allow": 2,
            "forward": 2,
            "replay": 1,
            "invalid": 0,
            "allow_rob_head": 1,
            "conservation": 1,
        }
        if name == QUAL.FINAL_MARKER:
            base.update({
                "cycles": 10,
                "prequal": 12,
                "exact": 10,
                "identity_or_lq_reject": 2,
                "allow": 4,
                "forward": 3,
                "replay": 3,
                "allow_rob_head": 2,
            })
        if values:
            base.update(values)
        omitted = omit or set()
        keys = order or QUAL.FIELDS
        fields = [f"{key}={base[key]}" for key in keys if key not in omitted]
        if extra is not None:
            fields.append(f"{extra[0]}={extra[1]}")
        if duplicate is not None:
            fields.append(f"{duplicate[0]}={duplicate[1]}")
        return f"[cpu-exec.cpp:1 sq_idle_fusion] {name} " + " ".join(fields)

    def log(
        self,
        *,
        region: str | None = None,
        final: str | None = None,
    ) -> str:
        region_line = region or self.marker(QUAL.REGION_MARKER)
        final_line = final or self.marker(QUAL.FINAL_MARKER)
        return f"boot\n{region_line}\n{final_line}\nshutdown\n"

    def assert_rejected(self, text: str, pattern: str) -> None:
        with self.assertRaisesRegex(QUAL.QualificationError, pattern):
            QUAL.parse_text(text)

    def test_accepts_conserving_region_and_final(self) -> None:
        result = QUAL.parse_text(self.log())
        self.assertEqual(result["schema"], QUAL.SCHEMA)
        self.assertEqual(result["status"], QUAL.STATUS)
        self.assertEqual(result["region"]["identity_or_lq_reject"], 1)

    def test_dual_lane_same_cycle_counts_two(self) -> None:
        values = {
            "cycles": 1,
            "prequal": 2,
            "exact": 2,
            "identity_or_lq_reject": 0,
            "allow": 2,
            "forward": 0,
            "replay": 0,
            "invalid": 0,
            "allow_rob_head": 2,
        }
        result = QUAL.parse_text(self.log(
            region=self.marker(QUAL.REGION_MARKER, values=values),
            final=self.marker(QUAL.FINAL_MARKER, values=values),
        ))
        self.assertEqual(result["region"]["prequal"], 2)
        self.assertEqual(result["region"]["allow"], 2)
        self.assertEqual(result["region"]["allow_rob_head"], 2)

    def test_missing_marker_is_rejected(self) -> None:
        self.assert_rejected(
            self.marker(QUAL.FINAL_MARKER) + "\n", "exactly one.*REGION")

    def test_duplicate_marker_is_rejected(self) -> None:
        region = self.marker(QUAL.REGION_MARKER)
        self.assert_rejected(
            self.log() + region + "\n", "exactly one.*REGION")

    def test_bare_and_truncated_duplicate_occurrences_are_rejected(self) -> None:
        for marker in (QUAL.REGION_MARKER, QUAL.FINAL_MARKER):
            for suffix in ("", " schema=npc-rv64"):
                with self.subTest(marker=marker, suffix=suffix):
                    duplicate = (
                        f"[cpu-exec.cpp:2 sq_idle_fusion] {marker}{suffix}\n")
                    self.assert_rejected(
                        self.log() + duplicate,
                        f"exactly one.*{marker}",
                    )

    def test_unique_bare_marker_is_rejected(self) -> None:
        for marker in (QUAL.REGION_MARKER, QUAL.FINAL_MARKER):
            with self.subTest(marker=marker):
                bare = f"[cpu-exec.cpp:2 sq_idle_fusion] {marker}"
                if marker == QUAL.REGION_MARKER:
                    text = self.log(region=bare)
                else:
                    text = self.log(final=bare)
                self.assert_rejected(text, "missing its payload delimiter")

    def test_bad_schema_is_rejected(self) -> None:
        region = self.marker(
            QUAL.REGION_MARKER, values={"schema": "wrong-v1"})
        self.assert_rejected(self.log(region=region), "schema mismatch")

    def test_missing_extra_reordered_and_duplicate_fields_are_rejected(self) -> None:
        missing = self.marker(QUAL.REGION_MARKER, omit={"prequal"})
        self.assert_rejected(self.log(region=missing), "field list or order")

        extra = self.marker(QUAL.REGION_MARKER, extra=("surprise", 0))
        self.assert_rejected(self.log(region=extra), "field list or order")

        reordered_keys = list(QUAL.FIELDS)
        reordered_keys[5], reordered_keys[6] = reordered_keys[6], reordered_keys[5]
        reordered = self.marker(
            QUAL.REGION_MARKER, order=tuple(reordered_keys))
        self.assert_rejected(self.log(region=reordered), "field list or order")

        duplicate = self.marker(
            QUAL.REGION_MARKER, duplicate=("cycles", 4))
        self.assert_rejected(self.log(region=duplicate), "duplicate field")

    def test_uint64_domain_is_strict(self) -> None:
        for value, pattern in (
            ("-1", "unsigned decimal"),
            ("1.0", "unsigned decimal"),
            (1 << 64, "exceeds uint64"),
        ):
            with self.subTest(value=value):
                region = self.marker(
                    QUAL.REGION_MARKER, values={"cycles": value})
                self.assert_rejected(self.log(region=region), pattern)

    def test_overflow_malformed_and_false_conservation_are_rejected(self) -> None:
        for key, pattern in (
            ("overflow", "reports overflow"),
            ("malformed", "reports malformed"),
            ("conservation", "conservation marker is false"),
        ):
            with self.subTest(key=key):
                value = 0 if key == "conservation" else 1
                region = self.marker(
                    QUAL.REGION_MARKER,
                    values={key: value, "complete": 0},
                )
                self.assert_rejected(self.log(region=region), pattern)

    def test_local_conservation_equations_are_rechecked(self) -> None:
        mutations = (
            ({"identity_or_lq_reject": 0}, "reject mismatch"),
            ({"exact": 4, "identity_or_lq_reject": 2},
             "decision partition"),
            ({"allow_rob_head": 3}, "allow_rob_head exceeds"),
            ({"invalid": 1, "exact": 6, "identity_or_lq_reject": 0},
             "non-onehot exact decision"),
        )
        for values, pattern in mutations:
            with self.subTest(values=values):
                region = self.marker(QUAL.REGION_MARKER, values=values)
                self.assert_rejected(self.log(region=region), pattern)

    def test_two_lane_cycle_capacity_is_checked(self) -> None:
        region = self.marker(
            QUAL.REGION_MARKER,
            values={
                "cycles": 1,
                "prequal": 3,
                "exact": 2,
                "identity_or_lq_reject": 1,
                "allow": 1,
                "forward": 1,
                "replay": 0,
            },
        )
        self.assert_rejected(self.log(region=region), "two-lane cycle capacity")

    def test_region_must_be_contained_in_final(self) -> None:
        final = self.marker(QUAL.FINAL_MARKER, values={"allow_rob_head": 0})
        self.assert_rejected(
            self.log(final=final), "region.allow_rob_head exceeds final")

        final = self.marker(QUAL.FINAL_MARKER, values={
            "cycles": 3,
            "prequal": 6,
            "exact": 5,
            "identity_or_lq_reject": 1,
            "allow": 2,
            "forward": 2,
            "replay": 1,
            "allow_rob_head": 1,
        })
        self.assert_rejected(self.log(final=final), "region.cycles exceeds final")

    def test_contract_json_binds_mask_and_region_semantics(self) -> None:
        contract = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
        self.assertEqual(contract["schema"], QUAL.SCHEMA)
        fields = contract["event_mask"]["fields"]
        self.assertEqual(
            [(item["name"], item["bits"]) for item in fields],
            [
                ("prequal", [1, 0]),
                ("exact", [3, 2]),
                ("allow", [5, 4]),
                ("forward", [7, 6]),
                ("replay", [9, 8]),
                ("invalid", [11, 10]),
                ("allow_rob_head", [13, 12]),
            ],
        )
        self.assertEqual(contract["region_sampling"]["interval"], "(S,E]")

    def test_cli_writes_validated_receipt(self) -> None:
        with tempfile.TemporaryDirectory(prefix="sq-idle-fusion-") as tmp:
            work = pathlib.Path(tmp)
            log_path = work / "run.log"
            output_path = work / "receipt.json"
            log_path.write_text(self.log(), encoding="utf-8")
            completed = subprocess.run(
                [sys.executable, "-B", str(TOOL), str(log_path),
                 "--output", str(output_path)],
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stdout)
            receipt = json.loads(output_path.read_text(encoding="utf-8"))
            self.assertEqual(receipt["status"], QUAL.STATUS)


if __name__ == "__main__":
    unittest.main()
