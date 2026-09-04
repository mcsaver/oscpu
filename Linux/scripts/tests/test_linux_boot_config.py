#!/usr/bin/env python3
"""Lightweight behavioral tests for the Linux host launch Kconfig.

The tests intentionally exercise only configuration and ``show-boot`` targets.
Every writable launch-config path is redirected to a temporary directory, and
all guest artifact roots point at a sentinel directory which must stay absent.
Consequently, a passing test cannot have built or started NPC/NEMU, Linux,
OpenSBI, or an Ubuntu rootfs.
"""

from __future__ import annotations

import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


LINUX_HOME = Path(__file__).resolve().parents[2]

LAUNCH_ENV_KEYS = {
    "ARCH",
    "BOOT",
    "LINUX_BOOT_CONFIG",
    "LINUX_BOOT_KCONFIG",
    "LINUX_BOOT_DEFCONFIG",
    "LINUX_BOOT_CONFIG_OUTPUT_DIR",
    "LINUX_BOOT_CONFIG_LOCK",
    "LINUX_RUN_MODE",
    "LINUX_RUN_ROOTFS_FLAVOR",
    "UBUNTU_ROOTFS_FLAVOR",
    "UBUNTU_ROOTFS_IMAGE",
    "UBUNTU_ROOTFS_CPIO_IMAGE",
    "UBUNTU_ROOTFS_DIR",
    "UBUNTU_ROOTFS_CHECK_TARGET",
    "LINUX_FEATURE_PROFILE",
    "NEMU_DEFCONFIG",
    "NEMU_DISPLAY",
    "NEMU_VIRTIO_INPUT",
    "NEMU_PERFORMANCE_REQUIRED",
    "BUILD_DIR",
    "LINUX_BUILD_DIR",
    "NEMU_BUILD_DIR",
    "NEMU_CONFIG_DIR",
    "OPENSBI_BUILD_ROOT",
    "LOG_DIR",
    "LOG_ROOT",
    "ENV_ROOT",
    "MAKEFLAGS",
    "MFLAGS",
    "MAKEOVERRIDES",
    "KCONFIG_CONFIG",
}

CONFIG_SYMBOL_GROUPS = {
    "platform": {
        "npc": "CONFIG_LINUX_RUN_PLATFORM_NPC",
        "nemu": "CONFIG_LINUX_RUN_PLATFORM_NEMU",
    },
    "boot": {
        "ubuntu-rootfs": "CONFIG_LINUX_RUN_BOOT_UBUNTU_ROOTFS",
        "ubuntu-shell": "CONFIG_LINUX_RUN_BOOT_UBUNTU_SHELL",
        "ubuntu-probe": "CONFIG_LINUX_RUN_BOOT_UBUNTU_PROBE",
        "busybox-initramfs": "CONFIG_LINUX_RUN_BOOT_BUSYBOX_INITRAMFS",
        "kernel": "CONFIG_LINUX_RUN_BOOT_KERNEL",
    },
    "console": {
        "serial": "CONFIG_LINUX_RUN_CONSOLE_SERIAL",
        "gui": "CONFIG_LINUX_RUN_CONSOLE_GUI",
    },
    "rootfs": {
        "systemd-minimal": "CONFIG_LINUX_RUN_ROOTFS_SYSTEMD_MINIMAL",
        "interactive": "CONFIG_LINUX_RUN_ROOTFS_INTERACTIVE",
        "full": "CONFIG_LINUX_RUN_ROOTFS_FULL",
    },
}

ROOTFS_EXPECTATIONS = {
    "systemd-minimal": {
        "image": "ubuntu-22.04-riscv64.ext4",
        "cpio": "ubuntu-22.04-riscv64-rootfs.cpio",
        "directory": "rootfs",
        "check": "check-ubuntu-rootfs-systemd",
    },
    "interactive": {
        "image": "ubuntu-22.04-riscv64-interactive.ext4",
        "cpio": "ubuntu-22.04-riscv64-interactive-rootfs.cpio",
        "directory": "rootfs-interactive",
        "check": "check-ubuntu-rootfs-interactive",
    },
    "full": {
        "image": "ubuntu-22.04-riscv64-full.ext4",
        "cpio": "ubuntu-22.04-riscv64-full-rootfs.cpio",
        "directory": "rootfs-full",
        "check": "check-ubuntu-rootfs-full",
    },
}


class LinuxBootConfigTest(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self._temporary_directory = tempfile.TemporaryDirectory(
            prefix="linux-boot-config-test-"
        )
        self.test_root = Path(self._temporary_directory.name)
        self.boot_config = self.test_root / "boot.config"
        self.boot_config_output_dir = self.test_root / "kconfig-output"
        self.boot_config_lock = self.test_root / "locks" / "boot-config.lock"

        # No configuration/show target may create anything below this path.
        # All potential guest outputs are redirected here so the assertion is
        # independent of artifacts that already exist in the user's worktree.
        self.guest_artifact_root = self.test_root / "forbidden-guest-artifacts"
        self.gui_platform_root = self.guest_artifact_root / "gui-platform"
        self.gui_front_build = self.guest_artifact_root / "gui-front"
        self.gui_linux_build = self.guest_artifact_root / "gui-linux"
        self.gui_opensbi_build = self.guest_artifact_root / "gui-opensbi"
        self.gui_nemu_build = self.guest_artifact_root / "gui-nemu"
        self.gui_nemu_config = self.guest_artifact_root / "gui-nemu-config"
        self.gui_log_dir = self.guest_artifact_root / "gui-logs"
        self.gui_rootfs_work = self.guest_artifact_root / "gui-rootfs-work"

    def tearDown(self) -> None:
        self._temporary_directory.cleanup()

    def clean_environment(self) -> dict[str, str]:
        env = os.environ.copy()
        for key in tuple(env):
            if key in LAUNCH_ENV_KEYS or key.startswith("CONFIG_LINUX_RUN_"):
                env.pop(key, None)
        env.update(
            {
                "CI": "1",
                "LC_ALL": "C",
                "LANG": "C",
                "PAGER": "cat",
            }
        )
        env.pop("TERM", None)
        return env

    def common_make_assignments(self) -> list[str]:
        generic_root = self.guest_artifact_root / "generic"
        return [
            f"LINUX_BOOT_CONFIG={self.boot_config}",
            f"LINUX_BOOT_CONFIG_OUTPUT_DIR={self.boot_config_output_dir}",
            f"LINUX_BOOT_CONFIG_LOCK={self.boot_config_lock}",
            f"ENV_ROOT={generic_root / 'env'}",
            f"BUILD_DIR={generic_root / 'front'}",
            f"LINUX_BUILD_DIR={generic_root / 'linux'}",
            f"NEMU_BUILD_DIR={generic_root / 'nemu'}",
            f"NEMU_CONFIG_DIR={generic_root / 'nemu-config'}",
            f"NPC_SIM={generic_root / 'npc' / 'NpcSimTop'}",
            f"OPENSBI_BUILD_ROOT={generic_root / 'opensbi'}",
            f"LOG_ROOT={generic_root / 'logs'}",
            f"NEMU_GUI_PLATFORM_ROOT={self.gui_platform_root}",
            f"NEMU_GUI_FRONT_BUILD_DIR={self.gui_front_build}",
            f"NEMU_GUI_KERNEL_BUILD_DIR={self.gui_linux_build}",
            f"NEMU_GUI_OPENSBI_BUILD_ROOT={self.gui_opensbi_build}",
            f"NEMU_GUI_BUILD_DIR={self.gui_nemu_build}",
            f"NEMU_GUI_CONFIG_DIR={self.gui_nemu_config}",
            f"NEMU_GUI_SIM={self.gui_nemu_build / 'riscv64-nemu-interpreter'}",
            f"NEMU_GUI_LOG_DIR={self.gui_log_dir}",
            f"NEMU_GUI_ROOTFS_WORK={self.gui_rootfs_work}",
        ]

    def run_make(
        self,
        target: str,
        *assignments: str,
        expect_success: bool = True,
        timeout: float = 20.0,
    ) -> subprocess.CompletedProcess[str]:
        command = [
            "make",
            "--no-print-directory",
            "-s",
            "-C",
            str(LINUX_HOME),
            *self.common_make_assignments(),
            *assignments,
            target,
        ]
        try:
            result = subprocess.run(
                command,
                env=self.clean_environment(),
                stdin=subprocess.DEVNULL,
                text=True,
                capture_output=True,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as error:
            self.fail(
                f"configuration target blocked or entered a build after {timeout}s: "
                f"{' '.join(command)}\nstdout:\n{error.stdout or ''}\n"
                f"stderr:\n{error.stderr or ''}"
            )

        combined = result.stdout + result.stderr
        if expect_success and result.returncode != 0:
            self.fail(
                f"command failed with rc={result.returncode}: {' '.join(command)}\n"
                f"output:\n{combined}"
            )
        if not expect_success and result.returncode == 0:
            self.fail(
                f"command unexpectedly succeeded: {' '.join(command)}\n"
                f"output:\n{combined}"
            )

        self.assertFalse(
            self.guest_artifact_root.exists(),
            "configuration/show target created a guest artifact directory; "
            "these tests must never build or start a guest",
        )
        return result

    def parse_show_boot(
        self, result: subprocess.CompletedProcess[str]
    ) -> dict[str, str]:
        values: dict[str, str] = {}
        for raw_line in result.stdout.splitlines():
            line = raw_line.strip()
            if "=" not in line:
                continue
            key, value = line.split("=", maxsplit=1)
            if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
                continue
            self.assertNotIn(key, values, f"show-boot emitted duplicate key {key}")
            values[key] = value
        return values

    def show_boot(self, *assignments: str) -> dict[str, str]:
        return self.parse_show_boot(self.run_make("show-boot", *assignments))

    def normalize_boot_config(self) -> dict[str, str]:
        """Normalize with olddefconfig, then inspect the saved selection."""
        self.run_make("boot-olddefconfig")
        return self.show_boot()

    def require_values(self, actual: dict[str, str], **expected: str) -> None:
        for key, value in expected.items():
            self.assertIn(key, actual, f"show-boot did not emit required key {key}")
            self.assertEqual(actual[key], value, key)

    def write_boot_config(
        self,
        *,
        platform: str,
        boot: str,
        console: str,
        rootfs: str | None = None,
    ) -> None:
        selected = {
            CONFIG_SYMBOL_GROUPS["platform"][platform],
            CONFIG_SYMBOL_GROUPS["boot"][boot],
            CONFIG_SYMBOL_GROUPS["console"][console],
        }
        if rootfs is not None:
            selected.add(CONFIG_SYMBOL_GROUPS["rootfs"][rootfs])

        lines = ["# Linux startup configuration test fixture"]
        for group in CONFIG_SYMBOL_GROUPS.values():
            for symbol in group.values():
                if symbol in selected:
                    lines.append(f"{symbol}=y")
                else:
                    lines.append(f"# {symbol} is not set")
        self.boot_config.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def assert_rootfs_bundle(
        self, values: dict[str, str], flavor: str
    ) -> None:
        expected = ROOTFS_EXPECTATIONS[flavor]
        self.require_values(
            values,
            BOOT="ubuntu-rootfs",
            UBUNTU_ROOTFS_FLAVOR=flavor,
            UBUNTU_ROOTFS_CHECK_TARGET=expected["check"],
            RUN_INITRD="",
        )
        for key in (
            "UBUNTU_ROOTFS_IMAGE",
            "UBUNTU_ROOTFS_CPIO_IMAGE",
            "UBUNTU_ROOTFS_DIR",
            "RUN_ROOTFS",
        ):
            self.assertIn(key, values, f"show-boot did not emit required key {key}")
        self.assertEqual(
            Path(values["UBUNTU_ROOTFS_IMAGE"]).name, expected["image"]
        )
        self.assertEqual(
            Path(values["UBUNTU_ROOTFS_CPIO_IMAGE"]).name, expected["cpio"]
        )
        self.assertEqual(Path(values["UBUNTU_ROOTFS_DIR"]).name, expected["directory"])
        self.assertEqual(values["RUN_ROOTFS"], values["UBUNTU_ROOTFS_IMAGE"])

    def test_missing_config_uses_documented_built_in_defaults(self) -> None:
        self.assertFalse(self.boot_config.exists())
        values = self.show_boot()

        self.require_values(
            values,
            LINUX_BOOT_CONFIG_STATE="built-in defaults",
            ARCH="riscv64-npc",
            BOOT="ubuntu-rootfs",
            LINUX_RUN_MODE="serial",
            LINUX_GUEST_PID1=(
                "/usr/local/sbin/ysyx-npc-systemd-wrapper -> "
                "/lib/systemd/systemd"
            ),
            LINUX_CONSOLE="ttyS0 serial/headless",
            UBUNTU_ROOTFS_FLAVOR="systemd-minimal",
            LINUX_FEATURE_PROFILE="headless",
            NEMU_DEFCONFIG="riscv64-linux_defconfig",
            NEMU_DISPLAY="0",
            NEMU_VIRTIO_INPUT="0",
            NEMU_ROOTFS_BOOTARGS_EXTRA="",
        )
        self.assert_rootfs_bundle(values, "systemd-minimal")
        self.assertFalse(
            self.boot_config.exists(), "show-boot must not create a missing config"
        )

    def test_boot_defconfig_is_noninteractive_and_matches_fallback(self) -> None:
        self.run_make("boot-defconfig", timeout=60.0)
        self.assertTrue(self.boot_config.is_file())
        generated = self.boot_config.read_text(encoding="utf-8")
        for symbol in (
            "CONFIG_LINUX_RUN_PLATFORM_NPC=y",
            "CONFIG_LINUX_RUN_BOOT_UBUNTU_ROOTFS=y",
            "CONFIG_LINUX_RUN_CONSOLE_SERIAL=y",
            "CONFIG_LINUX_RUN_ROOTFS_SYSTEMD_MINIMAL=y",
        ):
            self.assertIn(symbol, generated)

        values = self.show_boot()
        self.require_values(
            values,
            LINUX_BOOT_CONFIG_STATE="loaded",
            ARCH="riscv64-npc",
            BOOT="ubuntu-rootfs",
            LINUX_RUN_MODE="serial",
        )
        self.assert_rootfs_bundle(values, "systemd-minimal")

    def test_each_saved_rootfs_flavor_selects_one_coherent_artifact_bundle(self) -> None:
        for flavor in ROOTFS_EXPECTATIONS:
            with self.subTest(flavor=flavor):
                self.write_boot_config(
                    platform="nemu",
                    boot="ubuntu-rootfs",
                    console="serial",
                    rootfs=flavor,
                )
                values = self.normalize_boot_config()
                self.require_values(
                    values,
                    LINUX_BOOT_CONFIG_STATE="loaded",
                    ARCH="riscv64-nemu",
                    LINUX_RUN_MODE="serial",
                    LINUX_FEATURE_PROFILE="headless",
                    NEMU_DISPLAY="0",
                    NEMU_VIRTIO_INPUT="0",
                )
                self.assert_rootfs_bundle(values, flavor)
                self.assertIn(
                    "/platforms/nemu/", values["UBUNTU_ROOTFS_IMAGE"]
                )

    def test_command_line_selection_overrides_saved_config(self) -> None:
        cases = (
            {
                "name": "platform-boot-and-flavor",
                "saved": {
                    "platform": "nemu",
                    "boot": "ubuntu-shell",
                    "console": "serial",
                    "rootfs": None,
                },
                "assignments": (
                    "ARCH=riscv64-npc",
                    "BOOT=ubuntu-rootfs",
                    "LINUX_RUN_MODE=serial",
                    "UBUNTU_ROOTFS_FLAVOR=full",
                ),
                "expected": {
                    "ARCH": "riscv64-npc",
                    "BOOT": "ubuntu-rootfs",
                    "LINUX_RUN_MODE": "serial",
                    "flavor": "full",
                },
            },
            {
                "name": "console-and-flavor",
                "saved": {
                    "platform": "nemu",
                    "boot": "ubuntu-rootfs",
                    "console": "gui",
                    "rootfs": None,
                },
                "assignments": (
                    "ARCH=riscv64-nemu",
                    "BOOT=ubuntu-rootfs",
                    "LINUX_RUN_MODE=serial",
                    "LINUX_RUN_ROOTFS_FLAVOR=interactive",
                ),
                "expected": {
                    "ARCH": "riscv64-nemu",
                    "BOOT": "ubuntu-rootfs",
                    "LINUX_RUN_MODE": "serial",
                    "flavor": "interactive",
                },
            },
        )

        for case in cases:
            with self.subTest(case=case["name"]):
                self.write_boot_config(**case["saved"])
                self.normalize_boot_config()
                values = self.show_boot(*case["assignments"])
                self.require_values(
                    values,
                    LINUX_BOOT_CONFIG_STATE="loaded",
                    ARCH=case["expected"]["ARCH"],
                    BOOT=case["expected"]["BOOT"],
                    LINUX_RUN_MODE=case["expected"]["LINUX_RUN_MODE"],
                )
                self.assert_rootfs_bundle(values, case["expected"]["flavor"])
                expected_platform = case["expected"]["ARCH"].removeprefix(
                    "riscv64-"
                )
                self.assertIn(
                    f"/platforms/{expected_platform}/",
                    values["UBUNTU_ROOTFS_IMAGE"],
                )

    def test_saved_gui_selection_resolves_the_complete_isolated_profile(self) -> None:
        self.write_boot_config(
            platform="nemu",
            boot="ubuntu-rootfs",
            console="gui",
            rootfs=None,
        )
        self.normalize_boot_config()
        adversarial_image = self.guest_artifact_root / "wrong-rootfs.ext4"
        values = self.show_boot(
            "LINUX_FEATURE_PROFILE=headless",
            "NEMU_DEFCONFIG=riscv64-linux_defconfig",
            "NEMU_DISPLAY=0",
            "NEMU_VIRTIO_INPUT=0",
            "NEMU_PERFORMANCE_REQUIRED=1",
            f"UBUNTU_ROOTFS_IMAGE={adversarial_image}",
            f"UBUNTU_ROOTFS_CPIO_IMAGE={self.guest_artifact_root / 'wrong.cpio'}",
            f"UBUNTU_ROOTFS_DIR={self.guest_artifact_root / 'wrong-rootfs'}",
            "UBUNTU_ROOTFS_VT_AUTOLOGIN=0",
            "UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN=0",
        )

        expected_gui_image = (
            self.gui_platform_root
            / "images"
            / "ubuntu2204"
            / "ubuntu-22.04-riscv64-gui.ext4"
        )
        expected_gui_cpio = (
            self.gui_platform_root
            / "images"
            / "ubuntu2204"
            / "ubuntu-22.04-riscv64-gui-rootfs.cpio"
        )
        self.require_values(
            values,
            LINUX_BOOT_CONFIG_STATE="loaded",
            ARCH="riscv64-nemu",
            BOOT="ubuntu-rootfs",
            LINUX_RUN_MODE="gui",
            LINUX_GUEST_PID1="/lib/systemd/systemd",
            LINUX_CONSOLE=(
                "ttyS0 + SDL simplefb/fbcon tty1 with virtio-input"
            ),
            UBUNTU_ROOTFS_FLAVOR="systemd-minimal",
            LINUX_FEATURE_PROFILE="display",
            NEMU_DEFCONFIG="riscv64-linux-gui_defconfig",
            NEMU_CONFIG_DIR=str(self.gui_nemu_config),
            NEMU_BUILD_DIR=str(self.gui_nemu_build),
            NEMU_DISPLAY="1",
            NEMU_VIRTIO_INPUT="1",
            NEMU_ROOTFS_BOOTARGS_EXTRA="console=tty0",
            BUILD_DIR=str(self.gui_front_build),
            LINUX_BUILD_DIR=str(self.gui_linux_build),
            OPENSBI_BUILD_ROOT=str(self.gui_opensbi_build),
            LOG_DIR=str(self.gui_log_dir),
            NEMU_RUN_ROOTFS_OVERLAY=str(
                self.gui_log_dir / "rootfs-overlay.raw"
            ),
            UBUNTU_ROOTFS_IMAGE=str(expected_gui_image),
            UBUNTU_ROOTFS_CPIO_IMAGE=str(expected_gui_cpio),
            UBUNTU_ROOTFS_DIR=str(self.gui_rootfs_work / "rootfs-gui"),
            UBUNTU_ROOTFS_CHECK_TARGET="check-ubuntu-rootfs",
            UBUNTU_ROOTFS_VT_AUTOLOGIN="1",
            UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN="1",
            RUN_ROOTFS=str(expected_gui_image),
            RUN_INITRD="",
        )

    def test_explicit_invalid_combinations_fail_before_any_build(self) -> None:
        self.write_boot_config(
            platform="nemu",
            boot="ubuntu-rootfs",
            console="serial",
            rootfs="systemd-minimal",
        )
        self.normalize_boot_config()
        original_config = self.boot_config.read_bytes()
        cases = (
            (
                "gui-on-npc",
                (
                    "ARCH=riscv64-npc",
                    "BOOT=ubuntu-rootfs",
                    "LINUX_RUN_MODE=gui",
                    "UBUNTU_ROOTFS_FLAVOR=systemd-minimal",
                ),
                "requires ARCH=riscv64-nemu",
            ),
            (
                "gui-with-non-rootfs-boot",
                (
                    "ARCH=riscv64-nemu",
                    "BOOT=kernel",
                    "LINUX_RUN_MODE=gui",
                ),
                "requires BOOT=ubuntu-rootfs",
            ),
            (
                "gui-with-full-rootfs",
                (
                    "ARCH=riscv64-nemu",
                    "BOOT=ubuntu-rootfs",
                    "LINUX_RUN_MODE=gui",
                    "UBUNTU_ROOTFS_FLAVOR=full",
                ),
                "supports only systemd-minimal",
            ),
            (
                "unknown-rootfs-flavor",
                (
                    "ARCH=riscv64-nemu",
                    "BOOT=ubuntu-rootfs",
                    "LINUX_RUN_MODE=serial",
                    "UBUNTU_ROOTFS_FLAVOR=unknown",
                ),
                "unsupported Linux run rootfs flavor",
            ),
        )

        for name, assignments, expected_error in cases:
            with self.subTest(case=name):
                result = self.run_make(
                    "show-boot", *assignments, expect_success=False
                )
                self.assertIn(expected_error, result.stdout + result.stderr)
                self.assertEqual(self.boot_config.read_bytes(), original_config)


if __name__ == "__main__":
    unittest.main(verbosity=2)
