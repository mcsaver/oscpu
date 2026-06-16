# Dispatch Log

## 本地执行

- 检查 CoreMark 源码与现有性能日志。
- 检查 `ICache.v`、`DCache.v`、`PipelineControl.v`、`IfStage.v`、`NpcCore.v`，确认统计采样链路与控制流/cache 行为。
- 用 `objdump` 定位旧 progress PC `0x80003154` 到 `__mulsi3`。
- 用 `readelf -A` 确认旧对象 attribute 只有 `rv32i_zicsr`。
- 强制重编 CoreMark。
- 复查新 ELF attribute 与反汇编。
- 运行完整 CoreMark。
- 恢复 monitor 历史长参数兼容。
- 构建、lint、CLI 快速验证。

## 关键证据

- 旧热点：`80003154 <__mulsi3>`，内部包含 `beqz/bnez` 软件乘法循环。
- 旧对象：`Tag_RISCV_arch: "rv32i2p1_zicsr2p0"`。
- 新对象：`Tag_RISCV_arch: "rv32i2p1_m2p0_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zba1p0_zbb1p0_zbc1p0_zbs1p0"`。
- 新反汇编：matrix 内层出现 `mul` 指令。
- 新 CoreMark：`CoreMark PASS 13 Marks`。
