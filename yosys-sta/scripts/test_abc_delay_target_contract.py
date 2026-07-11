#!/usr/bin/env python3
"""Focused negative tests for the ABC delay-target contract checker."""

from __future__ import annotations

import unittest

from check_abc_delay_target_contract import ContractError, YOSYS_TCL, validate_text


def fixture(script: str) -> str:
    return rf'''set SYNTH_STRATEGY "DELAY 0"
set delay_scripts [list \\
  "+{script}" \\
]
set strategy_type "DELAY"
set strategy_script [lindex $delay_scripts 0]
proc strategy_consumes_delay_target {{script}} {{
  return [regexp {{(^|;)[[:space:]]*(&nf|upsize|dnsize)[^;]*\{{D\}}}} $script]
}}
if {{$strategy_type == "DELAY" &&
    ![strategy_consumes_delay_target $strategy_script]}} {{
  exit 1
}}
abc -D "$CLK_PERIOD_PS" \\
  -script "$strategy_script"
'''


class DelayTargetContractTest(unittest.TestCase):
    def test_repository_script_passes(self) -> None:
        validate_text(YOSYS_TCL.read_text(encoding="utf-8"))

    def test_missing_target_is_rejected(self) -> None:
        with self.assertRaises(ContractError):
            validate_text(fixture("&nf;&put"))

    def test_decoy_target_is_rejected(self) -> None:
        with self.assertRaises(ContractError):
            validate_text(fixture("echo,{D};&nf;&put"))

    def test_targeted_mapping_command_is_accepted(self) -> None:
        validate_text(fixture("&nf,{D};&put;upsize,{D};dnsize,{D}"))


if __name__ == "__main__":
    unittest.main()
