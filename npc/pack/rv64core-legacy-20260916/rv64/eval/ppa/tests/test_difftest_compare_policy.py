#!/usr/bin/env python3
"""Compile-time and runtime checks for the RV64GC CSR comparison profile."""

from __future__ import annotations

import pathlib
import subprocess
import tempfile
import textwrap
import unittest


RV64_DIR = pathlib.Path(__file__).resolve().parents[3]
INCLUDE_DIR = RV64_DIR / "csrc" / "include"


class DifftestComparePolicyTests(unittest.TestCase):
    def test_mstatus_profile_exclusions_are_exact(self) -> None:
        source = textwrap.dedent(
            r"""
            #include "cpu/difftest_compare_policy.h"
            #include <cstdint>

            using npc_difftest_policy::csr_values_match;
            using npc_difftest_policy::kMstatusProfileExcludedMask;

            int main() {
              constexpr std::uint64_t kFs = UINT64_C(0x6000);
              constexpr std::uint64_t kVs = UINT64_C(0x0600);
              constexpr std::uint64_t kSd = UINT64_C(1) << 63;
              constexpr std::uint64_t kMpp = UINT64_C(3) << 11;
              constexpr std::uint64_t kMprv = UINT64_C(1) << 17;
              constexpr std::uint64_t kSum = UINT64_C(1) << 18;
              constexpr std::uint64_t kMxr = UINT64_C(1) << 19;
              constexpr std::uint64_t kMie = UINT64_C(1) << 3;

              if (kMstatusProfileExcludedMask != (kFs | kSd)) return 1;
              if (!csr_values_match(0, 0, kFs)) return 2;
              if (csr_values_match(0, 0, kVs)) return 3;
              if (!csr_values_match(0, 0, kSd)) return 4;
              if (!csr_values_match(0, kFs | kSd, UINT64_C(0))) return 5;

              if (csr_values_match(0, 0, kMpp)) return 6;
              if (csr_values_match(0, 0, kMprv)) return 7;
              if (csr_values_match(0, 0, kSum)) return 8;
              if (csr_values_match(0, 0, kMxr)) return 9;
              if (csr_values_match(0, 0, kMie)) return 10;
              if (csr_values_match(0, kFs, kFs | kMprv)) return 11;

              // The profile exclusion applies only to mstatus (CSR index 0).
              if (csr_values_match(1, 0, kVs)) return 12;
              return 0;
            }
            """
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            binary = pathlib.Path(temp_dir) / "difftest-policy-test"
            compile_result = subprocess.run(
                [
                    "g++",
                    "-std=c++11",
                    "-Wall",
                    "-Wextra",
                    "-Werror",
                    "-I",
                    str(INCLUDE_DIR),
                    "-x",
                    "c++",
                    "-",
                    "-o",
                    str(binary),
                ],
                input=source,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(
                compile_result.returncode,
                0,
                msg=compile_result.stdout + compile_result.stderr,
            )
            run_result = subprocess.run(
                [str(binary)],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(
                run_result.returncode,
                0,
                msg=run_result.stdout + run_result.stderr,
            )


if __name__ == "__main__":
    unittest.main()
