#!/usr/bin/env python3
"""校验 NEMU GUI profile 跨 YAML、地址头与两侧 Kconfig 的静态契约。"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("缺少 PyYAML；请先执行 `make -C Linux setup-env`") from exc


def fail(message: str) -> None:
    raise SystemExit(f"[nemu-gui-config] FAIL {message}")


def read_kconfig(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("CONFIG_") and "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
        else:
            match = re.fullmatch(r"# (CONFIG_[A-Za-z0-9_]+) is not set", line)
            if match:
                values[match.group(1)] = "n"
    return values


def require_config(config: dict[str, str], path: Path, symbol: str, value: str) -> None:
    actual = config.get(symbol, "n")
    if actual != value:
        fail(f"{path}: 要求 {symbol}={value}，实际为 {actual}")


def read_define(path: Path, name: str) -> int:
    pattern = re.compile(
        rf"^[ \t]*#[ \t]*define[ \t]+{re.escape(name)}[ \t]+(0x[0-9a-fA-F]+|[0-9]+)[uUlL]*[ \t]*$",
        re.MULTILINE,
    )
    matches = tuple(pattern.finditer(path.read_text(encoding="utf-8")))
    if not matches:
        fail(f"{path}: 找不到数值宏 {name}")
    # generic-map.h 先列 legacy 分支、再列当前非 legacy 分支；GUI profile
    # 明确关闭 DEVICE_MAP_LEGACY，因此同名条件宏取最后一个定义。
    return int(matches[-1].group(1), 0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", type=Path, required=True)
    parser.add_argument("--generic-map", type=Path, required=True)
    parser.add_argument("--nemu-config", type=Path, required=True)
    parser.add_argument("--linux-config", type=Path, required=True)
    args = parser.parse_args()

    for path in (args.platform, args.generic_map, args.nemu_config, args.linux_config):
        if not path.is_file():
            fail(f"缺少输入文件 {path}")

    platform = yaml.safe_load(args.platform.read_text(encoding="utf-8")) or {}
    devices = platform.get("devices", {})
    framebuffer = devices.get("simple_framebuffer")
    input_device = devices.get("virtio_input")
    if not isinstance(framebuffer, dict):
        fail("平台 YAML 缺少 devices.simple_framebuffer")
    if not isinstance(input_device, dict):
        fail("平台 YAML 缺少 devices.virtio_input")

    fb_base = int(framebuffer["base"])
    fb_size = int(framebuffer["size"])
    width = int(framebuffer["width"])
    height = int(framebuffer["height"])
    stride = int(framebuffer["stride"])
    pixel_format = str(framebuffer["format"])
    if (width, height, stride, fb_size, pixel_format) != (
        800,
        600,
        800 * 4,
        800 * 600 * 4,
        "x8r8g8b8",
    ):
        fail(
            "simple-framebuffer 必须为 800x600、stride=3200、size=800*600*4、x8r8g8b8"
        )
    if fb_base != read_define(
        args.generic_map, "NEMU_GENERIC_FRAMEBUFFER_BASE"
    ):
        fail("simple-framebuffer base 与 NEMU_GENERIC_FRAMEBUFFER_BASE 不一致")

    if int(input_device["base"]) != read_define(
        args.generic_map, "NEMU_GENERIC_VIRTIO_INPUT_BASE"
    ):
        fail("virtio-input base 与 NEMU_GENERIC_VIRTIO_INPUT_BASE 不一致")
    if int(input_device["size"]) != 0x1000 or int(input_device["irq"]) != 7:
        fail("virtio-input 必须使用 0x1000 aperture 和 PLIC IRQ7")
    if int(input_device["base"]) == 0x10005000:
        fail("0x10005000/IRQ6 必须为未来 virtio-gpu 保留")

    nemu_config = read_kconfig(args.nemu_config)
    for symbol in (
        "CONFIG_HAS_VGA",
        "CONFIG_VGA_SHOW_SCREEN",
        "CONFIG_VGA_AUTO_SCANOUT",
        "CONFIG_VGA_SIZE_800x600",
        "CONFIG_HAS_VIRTIO_INPUT",
    ):
        require_config(nemu_config, args.nemu_config, symbol, "y")
    require_config(
        nemu_config, args.nemu_config, "CONFIG_DEVICE_MAP_LEGACY", "n"
    )
    require_config(nemu_config, args.nemu_config, "CONFIG_HAS_KEYBOARD", "n")

    linux_config = read_kconfig(args.linux_config)
    for symbol in (
        "CONFIG_FB",
        "CONFIG_FB_SIMPLE",
        "CONFIG_FRAMEBUFFER_CONSOLE",
        "CONFIG_INPUT",
        "CONFIG_INPUT_EVDEV",
        "CONFIG_VIRTIO_INPUT",
        "CONFIG_VT",
        "CONFIG_VT_CONSOLE",
    ):
        require_config(linux_config, args.linux_config, symbol, "y")
    for symbol in ("CONFIG_DRM", "CONFIG_SOUND"):
        require_config(linux_config, args.linux_config, symbol, "n")

    print("__NEMU_GUI_STATIC_CONFIG__:ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
