#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PARSER = SCRIPT_DIR.parent / "npc_systemd_transaction_evidence.py"
FIXTURES = SCRIPT_DIR / "fixtures"

PREFLIGHT = (
    "os-release-ubuntu-2204",
    "bin-sh",
    "bin-bash",
    "systemd-binary",
    "systemd-autocheck-script",
    "systemd-wrapper-preflight",
)
AUTOCHECK = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-context",
    "bin-sh",
    "bin-bash",
    "systemd-state",
)
STRICT = (
    "uname-riscv64",
    "os-release-ubuntu-2204",
    "root-shell",
    "bin-sh",
    "bin-bash",
    "systemd-state",
    "block-vda",
    "virtio-blk-driver",
    "root-on-vda",
    "root-ext4",
    "root-rw",
    "rootfs-write-sync-readback",
    "virtio-device-name",
    "virtio-irq-before-parse",
    "virtio-blk-direct-read",
    "virtio-irq-growth",
    "dmesg-no-critical",
)


def ancillary(stage: str, legacy: bool) -> list[str]:
    if stage == "preflight":
        prefix = "__NPC_CHECK" if legacy else "__NPC_PREFLIGHT"
        return [f"{prefix}_SYSTEMD_STATE__:wrapper-pre-systemd"]
    if stage == "autocheck":
        prefix = "__NPC_CHECK" if legacy else "__NPC_AUTOCHECK"
        return [
            f"{prefix}_UNAME__:riscv64",
            f"{prefix}_SYSTEMD_STATE__:pid1-systemd",
        ]
    return [
        "__NPC_CHECK_UNAME__:riscv64",
        "__NPC_CHECK_SYSTEMD_STATE__:pid1-systemd",
        "__NPC_CHECK_VDA_DRIVER__:virtio_blk",
        "__NPC_CHECK_ROOT_SOURCE__:/dev/root:254:0:254:0",
        "__NPC_CHECK_ROOT_MOUNT__:ext4:rw,relatime",
        "__NPC_CHECK_VIRTIO_IRQ_OWNER__:virtio0",
        "__NPC_CHECK_VIRTIO_IRQ__:10->11",
    ]


def make_stage(stage: str, legacy: bool = False) -> list[str]:
    labels = {
        "preflight": PREFLIGHT,
        "autocheck": AUTOCHECK,
        "strict": STRICT,
    }[stage]
    if legacy:
        begin = "__NPC_SYSTEMD_CHECK_BEGIN__"
        pass_prefix = "__NPC_CHECK_PASS__:"
        done = {
            "preflight": "__NPC_SYSTEMD_CHECK_DONE__ rc=0",
            "autocheck": "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0",
            "strict": "__NPC_SYSTEMD_UART_CHECK_DONE__ rc=0",
        }[stage]
    else:
        begin = f"__NPC_SYSTEMD_{stage.upper()}_BEGIN__"
        pass_prefix = (
            "__NPC_CHECK_PASS__:"
            if stage == "strict"
            else f"__NPC_{stage.upper()}_PASS__:"
        )
        done = f"__NPC_SYSTEMD_{stage.upper()}_DONE__ rc=0"
    return [
        begin,
        *ancillary(stage, legacy),
        *(f"{pass_prefix}{label}" for label in labels),
        done,
    ]


def complete_console(legacy: bool = False) -> list[str]:
    return [
        "OpenSBI v1.3",
        *make_stage("preflight", legacy),
        "__NPC_CONSOLE_SHELL_READY__",
        *make_stage("autocheck", legacy),
        *make_stage("strict", legacy),
        "__NPC_SYSTEMD_POWEROFF_BEGIN__",
    ]


class TransactionEvidenceTest(unittest.TestCase):
    def run_parser(
        self,
        lines: list[str],
        *,
        protocol: str = "auto",
        crlf: bool = False,
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, object]]:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            console = tmp_path / "console.log"
            evidence = tmp_path / "evidence.json"
            separator = "\r\n" if crlf else "\n"
            console.write_bytes((separator.join(lines) + separator).encode("utf-8"))
            proc = subprocess.run(
                [
                    sys.executable,
                    str(PARSER),
                    "--console",
                    str(console),
                    "--protocol",
                    protocol,
                    "--json-out",
                    str(evidence),
                ],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            return proc, json.loads(evidence.read_text(encoding="utf-8"))

    def assert_pass(self, lines: list[str], **kwargs: object) -> dict[str, object]:
        proc, payload = self.run_parser(lines, **kwargs)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(payload["status"], "PASS")
        self.assertEqual(
            [stage["pass_observation_count"] for stage in payload["stages"]],
            [6, 6, 17],
        )
        return payload

    def assert_red(
        self, lines: list[str], expected_error: str, **kwargs: object
    ) -> dict[str, object]:
        proc, payload = self.run_parser(lines, **kwargs)
        self.assertNotEqual(proc.returncode, 0)
        self.assertEqual(payload["status"], "FAIL")
        self.assertIn(expected_error, "\n".join(payload["errors"]))
        return payload

    def test_strict_v2_pass(self) -> None:
        payload = self.assert_pass(complete_console())
        self.assertEqual(payload["protocol"], "strict-v2")

    def test_legacy_v1_pass(self) -> None:
        payload = self.assert_pass(complete_console(legacy=True))
        self.assertEqual(payload["protocol"], "legacy-v1")

    def test_ansi_and_crlf_are_normalized_before_exact_match(self) -> None:
        lines = complete_console()
        lines[1] = f"\x1b[1;34m{lines[1]}\x1b[0m"
        self.assert_pass(lines, crlf=True)

    def test_legacy_stage_cannot_borrow_earlier_pass(self) -> None:
        lines = complete_console(legacy=True)
        strict_begin = len(make_stage("preflight", True)) + len(
            make_stage("autocheck", True)
        ) + 2
        strict_bin_sh = lines.index(
            "__NPC_CHECK_PASS__:bin-sh", strict_begin
        )
        del lines[strict_bin_sh]
        self.assert_red(lines, "strict: missing PASS label bin-sh")

    def test_duplicate_strict_pass_is_not_deduplicated(self) -> None:
        lines = complete_console()
        marker = "__NPC_CHECK_PASS__:virtio-irq-growth"
        lines.insert(lines.index(marker), marker)
        payload = self.assert_red(
            lines, "strict: PASS label virtio-irq-growth observed 2 times"
        )
        strict = payload["stages"][2]
        self.assertEqual(strict["observed_pass_counts"]["virtio-irq-growth"], 2)

    def test_embedded_literal_is_not_a_marker(self) -> None:
        lines = complete_console()
        marker = "__NPC_CHECK_PASS__:dmesg-no-critical"
        lines[lines.index(marker)] = f"driver argument contains {marker}"
        self.assert_red(lines, "strict: missing PASS label dmesg-no-critical")

    def test_duplicate_begin_is_red(self) -> None:
        lines = complete_console()
        lines.insert(2, "__NPC_SYSTEMD_PREFLIGHT_BEGIN__")
        self.assert_red(lines, "preflight: begin marker observed 2 times")

    def test_duplicate_done_is_red(self) -> None:
        lines = complete_console()
        marker = "__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0"
        lines.insert(lines.index(marker), marker)
        self.assert_red(lines, "autocheck: done marker observed 2 times")

    def test_fail_marker_is_red(self) -> None:
        lines = complete_console()
        done = lines.index("__NPC_SYSTEMD_STRICT_DONE__ rc=0")
        lines.insert(done, "__NPC_CHECK_FAIL__:dmesg-no-critical")
        self.assert_red(lines, "strict: 1 FAIL marker(s)")

    def test_mixed_protocol_is_red(self) -> None:
        lines = complete_console()
        lines.insert(1, "__NPC_SYSTEMD_CHECK_BEGIN__")
        self.assert_red(lines, "strict-v2 console contains legacy-v1")

    def test_v9s_rerun4_incomplete_replay_is_16_of_17_red(self) -> None:
        fixture = (FIXTURES / "v9s-rerun4-incomplete.console").read_text(
            encoding="utf-8"
        ).splitlines()
        payload = self.assert_red(
            fixture, "strict: done marker observed 0 times"
        )
        strict = payload["stages"][2]
        self.assertEqual(strict["pass_observation_count"], 16)
        self.assertEqual(strict["observed_pass_counts"]["virtio-irq-growth"], 1)
        self.assertNotIn("dmesg-no-critical", strict["observed_pass_counts"])


if __name__ == "__main__":
    unittest.main()
