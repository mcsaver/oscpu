# Dispatch Log

## RECALL

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、项目状态/已知问题/模块记忆、RTL 生成与 NPC 优化流程说明，以及 `npc/rv64/design/study/` 中 RISC-V 功能仿真和硬件架构笔记。

## PLAN

- Linux 早期启动首先需要从 M-mode handoff 到 S-mode，并处理 S-mode trap 返回；比完整 Linux 更小的可验证闭环是：`mret -> S-mode`、写 `satp`、`sfence.vma`、S-mode `ecall` 经 `medeleg` 到 `stvec`、handler `sret` 回来。
- A 扩展需要覆盖 Linux 可能使用的原子 RMW 和 LR/SC；在当前单 outstanding LSU 上采用序列化 read-modify-write，先保证 ordering/可见性和写回值正确。
- CPI 目标沿用当前 CoreMark 1000 iterations 作为代表性能验收。

## DISPATCH

- 扩展 CSR/privilege 状态和 S-mode CSR 读写。
- 增加 SRET decode 和 xRET frontend drain/redirect。
- 增加 AMO decode/backend 执行；修正 AMO 地址生成不使用 rs2 偏移。
- 补 focused test 和小型 S-mode boot test。

## VERIFY

- Focused module tests PASS。
- rv64 lint/build PASS。
- cpu-tests 40/40 PASS。
- CoreMark PASS，CPI `0.779`。
- 全量 module test 的 `tb_ooo_alu_fetch_core` 旧语义不适配当前 RV64 privilege/LSU/exit 协议，未作为本轮验收门槛。

## RECORD

- 已更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/am-kernels.md`、`.github/memory/known-issues.md`。
