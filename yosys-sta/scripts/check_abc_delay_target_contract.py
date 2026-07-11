#!/usr/bin/env python3
"""Fail closed when a DELAY ABC strategy ignores the requested period."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
YOSYS_TCL = ROOT / "yosys-sta" / "scripts" / "yosys.tcl"
TARGETED_DELAY_COMMAND = re.compile(
    r"(?:^|;)\s*(?:&nf|upsize|dnsize)[^;]*\{D\}"
)


class ContractError(ValueError):
    """The synthesis script does not honor the delay-target contract."""


def validate_text(text: str) -> tuple[int, str, int]:
    strategy_match = re.search(
        r'set\s+SYNTH_STRATEGY\s+"(DELAY|AREA)\s+(\d+)"', text
    )
    if strategy_match is None:
        raise ContractError("cannot resolve the default SYNTH_STRATEGY")

    delay_block_match = re.search(
        r"set\s+delay_scripts\s+\[list\s+\\(?P<body>.*?)\n\s*\]",
        text,
        re.DOTALL,
    )
    if delay_block_match is None:
        raise ContractError("cannot parse delay_scripts")

    delay_scripts = re.findall(r'"\+([^"\n]*)"', delay_block_match.group("body"))
    if not delay_scripts:
        raise ContractError("delay_scripts is empty")

    fine_tune_match = re.search(
        r'if\s+\{\$buffering==1\}\s+\{.*?set\s+abc_fine_tune\s+"([^"]*)"',
        text,
        re.DOTALL,
    )
    fine_tune = fine_tune_match.group(1) if fine_tune_match is not None else ""
    expanded_delay_scripts = [
        script.replace("${abc_fine_tune}", fine_tune) for script in delay_scripts
    ]
    missing_target = [
        str(index)
        for index, script in enumerate(expanded_delay_scripts)
        if TARGETED_DELAY_COMMAND.search(script) is None
    ]
    if missing_target:
        raise ContractError(
            "DELAY strategies missing targeted &nf/upsize/dnsize {D}: "
            + ", ".join(missing_target)
        )

    strategy_kind, strategy_index_text = strategy_match.groups()
    strategy_index = int(strategy_index_text)
    if strategy_kind == "DELAY" and strategy_index >= len(delay_scripts):
        raise ContractError(f"default DELAY strategy index {strategy_index} is out of range")

    if not re.search(
        r'abc\s+-D\s+"\$CLK_PERIOD_PS".*?-script\s+"\$strategy_script"',
        text,
        re.DOTALL,
    ):
        raise ContractError(
            "ABC invocation does not pass CLK_PERIOD_PS with the selected script"
        )

    if "proc strategy_consumes_delay_target" not in text or not re.search(
        r'\$strategy_type\s+==\s+"DELAY".*?!\[strategy_consumes_delay_target\s+\$strategy_script\]',
        text,
        re.DOTALL,
    ):
        raise ContractError(
            "runtime DELAY-strategy targeted-command fail-closed guard is missing"
        )

    return len(delay_scripts), strategy_kind, strategy_index


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--yosys-tcl", type=Path, default=YOSYS_TCL)
    args = parser.parse_args()
    try:
        count, strategy_kind, strategy_index = validate_text(
            args.yosys_tcl.read_text(encoding="utf-8")
        )
    except (ContractError, OSError) as exc:
        print(f"FAIL abc-delay-target-contract: {exc}", file=sys.stderr)
        return 1

    print(
        "PASS abc-delay-target-contract "
        f"delay_strategies={count} default={strategy_kind}-{strategy_index}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
