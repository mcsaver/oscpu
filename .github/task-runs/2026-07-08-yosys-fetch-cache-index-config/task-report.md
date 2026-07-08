# 任务报告

## 目标

继续推进 `[112] RV64 Yosys full stdcell synthesis`，在不启动 Ubuntu/rootfs 的前提下，围绕正确性、综合和时序准备收敛 blocker。重点验证 fetch packet cache 存储映射、显式宏边界，以及顶层综合后续热点。

## 实现者人格

本轮完成了三组工程改动：

1. `OooFetchPacketCache` 容量配置显式化：
   - `npc/rv64/vsrc/include/define.v` 新增 `OOO_FETCH_PACKET_CACHE_INDEX_W`，默认 12，不改变常规 4096 项容量。
   - `OooFetchAxiBridge` 的 `CACHE_INDEX_W` 改为引用该宏。
   - `npc/rv64/Makefile` 与 `yosys-sta` 支持 `STA_VERILOG_DEFINES` / `VERILOG_DEFINES`，用于综合实验。

2. Yosys 宏边界显式化：
   - `yosys-sta` 新增 `SYNTH_BLACKBOX_MODULES`，在读入 RTL 后对指定模块执行 `blackbox`。
   - `npc/rv64/Makefile` 新增 `STA_SYNTH_BLACKBOX_MODULES` 透传。
   - 该开关默认关闭；不存在的模块名会让 Yosys 报错，避免假绿。

3. `OooMulDivUnit` 乘法迭代化：
   - 删除一拍组合 `selected_prod = mul_op1_ext * mul_op2_ext` 大乘法器。
   - 新增 `STATE_MUL_RUN`，用 64-step shift-add 生成 128-bit product，再按 MUL/MULH/MULHSU/MULHU/MULW 选择结果。
   - flush 与 mispredict-kill 覆盖在飞乘法，仍复用原 ready/valid 响应协议。

同步更新：
- `npc/rv64/design/specs/ooo-muldiv-unit.md`
- `npc/rv64/design/specs/ooo-fetch-axi-bridge.md`
- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/modules/yosys-sta.md`
- `.github/memory/known-issues.md`

## 关键证据

- `OooFetchPacketCache INDEX_W=8` OOC full stdcell 仍失败：到 `MEMORY_MAP/ABC` 后终止，说明单纯缩容量到 256 项不是根解。
- `OooFetchAxiBridge + OooFetchPacketCache blackbox` 100MHz full stdcell PASS：`synth_check` 0 problems，top area（不含 cache 宏）`334737.20`，日志明确 `Area for cell type \OooFetchPacketCache is unknown!`。
- `NpcTop + OooFetchPacketCache blackbox` 旧版在 ABC extraction `OooMulDivUnit` 处 timeout。
- `OooMulDivUnit` 迭代乘法后 OOC 100MHz full stdcell PASS：area `18944.80`，`synth_check` 0 problems。
- `NpcTop + OooFetchPacketCache blackbox` 在迭代乘法后推进到 `OooFpArithGate` 前 timeout，证明旧 MulDiv blocker 已后移。
- `tb_ooo_muldiv_unit` PASS，覆盖 multiply high/low、MULW、div/rem、busy、flush。
- `make -C npc/rv64 check-rtl-style` PASS。

## 审查者人格

未闭合项与风险：

- `OooFetchPacketCache` 仍没有真实 SRAM/memory macro 实现；blackbox 结果只能说明外围逻辑可综合，不能算完整 STA-ready。
- `NpcTop` full stdcell 仍未完成；当前下一处长尾是 `OooFpArithGate`，需要单独 OOC 拆账。
- MulDiv 乘法 latency 从一拍变为 64 拍。模块协议允许长延迟，但整机新版 smoke 尚未跑通。
- 默认 `make lint` / `make -C npc/rv64 -j2` 被既有 `Uart.v PROCASSINIT` warning-as-error 阻塞。
- `tb_ooo_int_backend` 在当前 Icarus 路径下被既有 declare-after-use / implicit-wire 编译问题阻塞，不能作为本轮行为失败归因。
- `make -C Linux/tools smoke-muldiv` PASS 使用的是早于本轮 RTL 改动的旧 `NpcSimTop` 二进制，不能作为当前 RTL 验证证据。

## 下一步

1. 先确定 `OooFetchPacketCache` 的真实 memory macro/SRAM 或 Yosys 保留 memory 边界策略。
2. 对 `OooFpArithGate` 做 OOC full stdcell 拆账，判断 FP 组合 helper 是否需要迭代/流水化。
3. 清理或显式 waiver 当前 Verilator `Uart.v PROCASSINIT` 门禁，使新版 NPC build 与裸机 smoke 可以恢复。
4. 在 `debug/common` 的 spec 语义审核层中，只对跨模块/抽象状态语义新增 facts/checker；单模块 ISA/握手边界继续用 dedicated TB + spec 同步闭环。
