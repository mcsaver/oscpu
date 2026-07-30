#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import unittest


RUNNER = (
    pathlib.Path(__file__).resolve().parent
    / "run-historical-reconstruction.py"
)


def load_runner():
    spec = importlib.util.spec_from_file_location(
        "historical_reconstruction_runner_tested",
        RUNNER,
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class HistoricalReconstructionRunnerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.runner = load_runner()

    def test_vvp_pointer_ids_do_not_change_normalized_identity(self) -> None:
        first = (
            b"S_0x5c510932dc30 .scope package;\n"
            b"v0x5c51094ff7c0_0 .net signal, 0 0;\n"
            b"C4<1010>;\n"
        )
        second = (
            b"S_0x5649c4355c30 .scope package;\n"
            b"v0x5649c45ff7c0_0 .net signal, 0 0;\n"
            b"C4<1010>;\n"
        )
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            first_path = root / "first.vvp"
            second_path = root / "second.vvp"
            first_path.write_bytes(first)
            second_path.write_bytes(second)
            self.assertNotEqual(
                self.runner.sha256_file(first_path),
                self.runner.sha256_file(second_path),
            )
            self.assertEqual(
                self.runner.normalized_vvp_sha256(first_path),
                self.runner.normalized_vvp_sha256(second_path),
            )

    def test_vvp_semantic_content_changes_normalized_identity(self) -> None:
        first = b"S_0x1111 .scope package;\nC4<1010>;\n"
        second = b"S_0x2222 .scope package;\nC4<1011>;\n"
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            first_path = root / "first.vvp"
            second_path = root / "second.vvp"
            first_path.write_bytes(first)
            second_path.write_bytes(second)
            self.assertNotEqual(
                self.runner.normalized_vvp_sha256(first_path),
                self.runner.normalized_vvp_sha256(second_path),
            )


if __name__ == "__main__":
    unittest.main()
