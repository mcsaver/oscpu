#!/usr/bin/env python3
"""从 npc-rv64.yml 生成 Linux bring-up 用 DTB 源文件。"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys

try:
    import yaml
except ImportError as exc:  # pragma: no cover - 依赖缺失时给出可执行修复提示
    raise SystemExit("缺少 PyYAML：请先执行 `make -C Linux setup-env` 或 `python3 -m pip install --user pyyaml`") from exc


def u32_cells(value: int) -> str:
    value &= (1 << 64) - 1
    return f"0x{value >> 32:x} 0x{value & 0xffffffff:x}"


def load_config(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def initrd_cells(cfg: dict, mode: str, initrd_image: str | None) -> tuple[str, str] | None:
    if mode != "initramfs":
        return None
    initrd = cfg["initrd"]
    image = Path(initrd_image or initrd["image"])
    if not image.is_file():
        raise SystemExit(f"initramfs 镜像不存在：{image}")
    start = int(initrd["load_addr"])
    end = start + image.stat().st_size
    return u32_cells(start), u32_cells(end)


def render(
    cfg: dict,
    mode: str,
    initrd_image: str | None,
    bootargs_key: str | None,
    memory_size: str | None,
) -> str:
    mem = cfg["memory"]
    mem_size = int(memory_size, 0) if memory_size else int(mem["size"])
    dev = cfg["devices"]
    uart = dev["uart0"]
    plic = dev["plic"]
    clint = dev["clint"]
    virtio = dev["virtio_blk"]
    bootargs = cfg["bootargs"][bootargs_key or mode]
    initrd = initrd_cells(cfg, mode, initrd_image)
    ndev = int(plic["sources_rootfs"] if mode == "rootfs" else plic["sources_initramfs"])

    initrd_lines = ""
    if initrd:
        # Linux 需要在 /chosen 中看到 initrd 物理地址范围，才能进入真实用户态。
        initrd_lines = (
            f"    linux,initrd-start = <{initrd[0]}>;\n"
            f"    linux,initrd-end = <{initrd[1]}>;\n"
        )

    virtio_node = ""
    if mode == "rootfs":
        # rootfs 模式只描述即将接入的 virtio-mmio block；当前 RTL 未实现时不要用它验收通过。
        virtio_node = f"""

    virtio_blk0: virtio_mmio@{int(virtio["base"]):x} {{
      compatible = "virtio,mmio";
      reg = <{u32_cells(int(virtio["base"]))} {u32_cells(int(virtio["size"]))}>;
      interrupt-parent = <&PLIC>;
      interrupts = <{int(virtio["irq"])}>;
    }};"""

    return f"""/dts-v1/;

/ {{
  #address-cells = <2>;
  #size-cells = <2>;
  compatible = "ysyx,npc-rv64";
  model = "YSYX NPC RV64";

  chosen {{
    stdout-path = "serial0:115200n8";
    bootargs = "{bootargs}";
{initrd_lines}  }};

  aliases {{
    serial0 = &UART0;
  }};

  memory@{int(mem["base"]):x} {{
    device_type = "memory";
    reg = <{u32_cells(int(mem["base"]))} {u32_cells(mem_size)}>;
  }};

  cpus {{
    #address-cells = <1>;
    #size-cells = <0>;
    timebase-frequency = <10000000>;

    cpu@0 {{
      device_type = "cpu";
      reg = <0>;
      status = "okay";
      compatible = "riscv";
      riscv,isa = "rv64imafdc_zicsr_zifencei";
      mmu-type = "riscv,sv39";

      CPU0_INTC: interrupt-controller {{
        #interrupt-cells = <1>;
        interrupt-controller;
        compatible = "riscv,cpu-intc";
      }};
    }};
  }};

  soc {{
    #address-cells = <2>;
    #size-cells = <2>;
    compatible = "simple-bus";
    ranges;

    clint@{int(clint["base"]):x} {{
      compatible = "riscv,clint0";
      reg = <{u32_cells(int(clint["base"]))} {u32_cells(int(clint["size"]))}>;
      interrupts-extended = <&CPU0_INTC 3 &CPU0_INTC 7>;
    }};

    PLIC: interrupt-controller@{int(plic["base"]):x} {{
      #interrupt-cells = <1>;
      interrupt-controller;
      compatible = "riscv,plic0";
      reg = <{u32_cells(int(plic["base"]))} {u32_cells(int(plic["size"]))}>;
      riscv,ndev = <{ndev}>;
      interrupts-extended = <&CPU0_INTC 11 &CPU0_INTC 9>;
    }};

    UART0: serial@{int(uart["base"]):x} {{
      compatible = "ns16550a";
      reg = <{u32_cells(int(uart["base"]))} {u32_cells(int(uart["size"]))}>;
      clock-frequency = <{int(uart["clock_frequency"])}>;
      current-speed = <{int(uart["current_speed"])}>;
      reg-shift = <0>;
      reg-io-width = <1>;
      interrupt-parent = <&PLIC>;
      interrupts = <{int(uart["irq"])}>;
    }};{virtio_node}
  }};
}};
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="Linux/platform/npc-rv64.yml")
    parser.add_argument("--mode", choices=["kernel", "initramfs", "rootfs"], default="kernel")
    parser.add_argument("--bootargs-key", choices=["kernel", "initramfs", "ubuntu_initramfs", "rootfs"])
    parser.add_argument("--initrd-image")
    parser.add_argument("--memory-size", help="覆盖 memory.reg 的 size，支持 0x... 形式")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    config_path = Path(args.config)
    cfg = load_config(config_path)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    text = render(cfg, args.mode, args.initrd_image, args.bootargs_key, args.memory_size)
    output.write_text(text, encoding="utf-8")
    print(f"[gen-dts] {args.mode}: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
