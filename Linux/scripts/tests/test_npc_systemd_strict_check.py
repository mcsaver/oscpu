#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
STRICT_CHECKER = SCRIPT_DIR.parent / "npc-systemd-strict-check.sh"


def production_regex() -> str:
    text = STRICT_CHECKER.read_text(encoding="utf-8")
    match = re.search(r"^bad_dmesg_regex='([^']+)'$", text, re.MULTILINE)
    if match is None:
        raise AssertionError("production bad_dmesg_regex assignment is missing")
    return match.group(1)


def grep_matches(regex: str, line: str) -> bool:
    result = subprocess.run(
        ["grep", "-i", "-E", "-q", regex],
        input=f"{line}\n",
        text=True,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise AssertionError(f"grep returned rc={result.returncode}")
    return result.returncode == 0


class StrictDmesgTokenTest(unittest.TestCase):
    def test_debug_text_is_not_a_bug_token(self) -> None:
        regex = production_regex()
        for line in (
            "[    0.000000] printk: debug: ignoring loglevel setting.",
            "DEBUG: diagnostic level",
            "myBUG: identifier",
            "_BUG: identifier",
        ):
            with self.subTest(line=line):
                self.assertFalse(grep_matches(regex, line))

    def test_real_critical_markers_remain_sensitive(self) -> None:
        regex = production_regex()
        for line in (
            "BUG: unable to handle page fault",
            "[  12.3] BUG: unable to handle page fault",
            "Kernel panic - not syncing",
            "Oops: supervisor access fault",
            "bad trap at pc",
            "illegal instruction",
            "segfault at 0",
            "Buffer I/O error on dev vda",
            "EXT4-fs error (device vda)",
        ):
            with self.subTest(line=line):
                self.assertTrue(grep_matches(regex, line))

    def test_legacy_unbounded_mutation_reproduces_a3_false_red(self) -> None:
        mutated = production_regex().replace(
            "(^|[^[:alnum:]_])BUG:",
            "BUG:",
        )
        witness = "[    0.000000] printk: debug: ignoring loglevel setting."
        self.assertTrue(grep_matches(mutated, witness))
        self.assertFalse(grep_matches(production_regex(), witness))


if __name__ == "__main__":
    unittest.main()
