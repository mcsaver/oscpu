---
description: "Linux framebuffer/VGA 显示约束。处理 NPC RV64 上 Linux/Ubuntu 屏幕输出、simple-framebuffer、simpledrm、fbcon、SDL scanout 或 VGA 设备时使用。"
applyTo: "npc/rv64/**"
---

# Linux Framebuffer / VGA 约束

## 核心区分

AM/NEMU legacy `vgactl + framebuffer + sync` 不是 Linux kernel 自动识别的屏幕。Linux 需要 DTB 中可识别的 framebuffer/DRM/virtio-gpu 设备，以及对应 kernel config。

近期只追最小 Linux 文本屏幕：

```text
Linux framebuffer/simpledrm/simplefb -> fbcon -> guest framebuffer memory -> host SDL scanout
```

不把完整图形桌面作为近期验收目标。

## 必须说明的契约

- framebuffer 物理地址、大小、宽高、stride、像素格式。
- DTB 节点类型和 `compatible`。
- kernel config 是否启用 simplefb/simpledrm/fbcon/console。
- host SDL presenter 从哪里扫描 guest framebuffer。
- bootargs 是否包含 `console=tty0` 与串口并行输出。

## 禁止误判

- 不把 `CONFIG_NPC_HAS_VGA=y` 当作 Linux 屏幕可用。
- 不把 AM `AM_GPU_FBDRAW` 输出当作 Linux fbcon 输出。
- 不把 SoC 地址图预留 `VGA` window 当作设备已实现。
- 不用 dark magic 直接从 host 打字到屏幕来伪造 Linux 输出；必须来自 guest framebuffer 写入。

## 验证 gate

1. QEMU reference 或 Linux config 能识别 framebuffer 节点。
2. NPC/Verilator 的 guest 侧确实写入 framebuffer 区域。
3. SDL 窗口显示的文本能与串口日志中的 Linux/Ubuntu 输出对应。
4. 若输出失败，先区分 DTB/config、guest 写入、host scanout、像素格式四类边界。
