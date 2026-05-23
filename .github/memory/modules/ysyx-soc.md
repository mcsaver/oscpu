# ysyxSoC 模块笔记

## 当前状态

- 2026-05-23: `ysyxSoC/` 已作为独立 SoC 集成目录进入工作区。当前 CPU 接口规范位于 `ysyxSoC/spec/cpu-interface.md`，要求 CPU 顶层模块名为 `ysyx_8位学号`，端口包含 `clock/reset/io_interrupt`、一路完整 AXI4 master 和一路 AXI4 slave。`ysyxSoC/Makefile` 通过 `mill -i ysyxsoc.runMain ysyx.Elaborate --target-dir build` 生成 `build/ysyxSoCFull.v`，随后做端口名替换和尾部清理。
- 2026-05-23: 已按用户要求移除 `ysyxSoC/` 及其 `rocket-chip` 依赖目录下的 `.git` 元数据，备份位置为 `/tmp/ysyxSoC-git-metadata-backup-2026-05-23/`。`ysyxSoC/` 不再被外层 `.gitignore` 排除，后续可作为普通目录由外层仓库纳入；若执行 `git add .`，仍需注意 `ysyxSoC/.gitignore`、`ysyxSoC/rocket-chip/.gitignore` 会继续排除生成物和上游忽略项。
- 2026-05-23: 当前宿主环境已经配置用户级 Zulu JDK 21 与 `/home/lyg/.local/bin/mill` wrapper；`ysyxSoC/.mill-version` 固定为 Mill 0.12.4。后续 ysyxSoC 任务应优先使用 `mill -i` 或 `make verilog`，避免系统 OpenJDK 8 导致 `readAllBytes()` 等 API 缺失。
- 2026-05-23: `npc/soc` 当前承接 ysyxSoC CPU 集成侧：`ysyx_26010035` wrapper 与 `NpcSoCAxiBridge` 对齐 `cpu-interface.md`，`make -C npc/soc soc` 会纳入 `ysyxSoC/build/ysyxSoCFull.v` 与 perip 源。SoC 地址图还需要同时与 NEMU `CONFIG_SOC_SIM` reference 保持一致，尤其是 SRAM、UART、MROM、VGA、Flash、SDRAM 等窗口。

## 设计笔记

- `ysyxSoC/build/ysyxSoCFull.v` 是生成物，不应优先手写维护；若需要改 SoC 结构，优先改 `ysyxSoC/src/*.scala` 后重新生成。
- CPU RTL 的具体实现与 AXI4 bridge 在 `npc/soc`，SoC agent 主要负责规范、生成链路、外设/地址图与 Chisel 侧连接关系。
- 地址图变更至少要同步检查三侧：ysyxSoC Chisel/生成物、`npc/soc` 仿真顶层/CPU bridge、NEMU `CONFIG_SOC_SIM` reference。

## 踩坑记录

- 系统 `/usr/bin/java` 仍可能是 OpenJDK 8；直接调用不经过 wrapper 的 Mill/Chisel 命令可能失败。先检查 `which mill`、`mill -i --version` 和 `JAVA_HOME`，再归因到工程源码。
