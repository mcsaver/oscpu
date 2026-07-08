# 任务报告

## 目标

在继续推进 `[112] RV64 Yosys full stdcell synthesis` 前，先恢复正确性验证门禁：关闭 `Uart.v PROCASSINIT` 对 `make lint` / RV64 build 的阻塞，并用当前二进制补齐新版 `OooMulDivUnit` 的整机 smoke 证据。本轮仍不启动 Ubuntu/rootfs。

## 实现者人格

完成的 RTL 改动只有一处：

- `npc/rv64/vsrc/bus/Uart.v` 删除 `ier_q/dll_q/dlm_q/fcr_q/lcr_q/rx_valid_q/rx_data_q` 的声明初始化。
- reset 分支已经写入完全相同的初值：`dll_q=8'h01`，其余寄存器为 0。
- 因此这是 Verilator/synthesis 风格修复，不改变 UART reset 语义。

同步留档：

- `.github/memory/project-status.md`
- `.github/memory/modules/npc.md`
- `.github/memory/modules/yosys-sta.md`
- `.github/memory/known-issues.md`

并按用户提醒固化方法论：`npc/rv64/vsrc/common` facts 与 `npc/rv64/vsrc/debug` checkers 是 RTL 是否符合 spec 语义的审核层之一。触碰 redirect、AD-update、slot facts 等跨模块抽象语义时，应先查或补 facts/checker；本轮 Uart reset 等价和 MulDiv 单模块 ISA/握手语义，用 lint/build/TB/smoke/contract 闭环。

## 关键证据

- `make -C npc/rv64 lint` PASS，`PROCASSINIT` 不再出现。
- `make -C npc/rv64 -j2` 在修改后完成；`build/NpcSimTop` mtime 晚于 `Uart.v`。
- `tb_ooo_muldiv_unit` PASS。
- `smoke-muldiv smoke-jal-link smoke-branch-raw smoke-sret-user-sv39-halfword` 全部 GOOD TRAP，日志中的 Build time 为 `02:43:47, Jul 8 2026`。
- `make -C npc/rv64 check-rtl-style` PASS。
- `make -C npc/rv64 check-contract` PASS，`$error` 计数当前 11、基线 11。
- `debug/common` 入口已索引：`OooSlotFacts.v`、`OooRedirectMuxFacts.vh`、`OooRedirectSeqFacts.vh` 与四个 `Ooo*Checker.sv`。
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS；本轮新增的 `npc-dev` evidence 为 `.github/task-runs/2026-07-08-uart-procassinit-rv64-build-unblock-2/`。

## 审查者人格

未闭合项与风险：

- 这只关闭正确性验证门禁，不代表 `NpcTop` full stdcell/STA-ready。
- `OooFetchPacketCache` 仍需要真实 memory macro/SRAM 边界或 Yosys 保留 memory 的策略。
- `NpcTop + OooFetchPacketCache blackbox` 的下一处长尾仍是 `OooFpArithGate`，需要 OOC 拆账。
- `tb_ooo_int_backend` 的 Icarus declare-after-use / implicit-wire 编译问题仍未在本轮解决，不能用作当前集成 TB 证据。
- 本轮没有启动 Ubuntu/rootfs，符合当前阶段“正确性/综合/时序准备先行”的边界。

## 下一步

1. 对 `OooFpArithGate` 做 OOC full stdcell 拆账，判断 FP add/mul/convert helper 是否需要迭代化或流水化。
2. 继续处理 `OooFetchPacketCache` 的存储宏边界，避免把 4096-entry payload/valid 全量映射到门级 stdcell。
3. 若触碰 redirect/AD-update/slot 抽象语义，优先复用或新增 `common` facts + `debug` checker，再跑 contract/smoke。
