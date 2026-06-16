# display-vga E2E Contract

- **范围**: Linux-visible framebuffer/simplefb/simpledrm/fbcon 与 SDL scanout。
- **上游**: rv64-linux DTB/kernel config、display agent。
- **下游**: Ubuntu 可视化文本输出。
- **L0 gate**: `display-vga-contract` 检查 display agent 和 framebuffer instruction。
- **L1 gate**: 后续 simplefb DTB + fbcon smoke。
- **证据**: kernel config、DTB framebuffer node、SDL scanout/fbcon marker。
- **升级路线**: 自动截图/文本检测进入 task-run artifact。
