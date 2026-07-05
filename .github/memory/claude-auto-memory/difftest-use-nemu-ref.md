---
name: difftest-use-nemu-ref
description: "用户要求 NPC difftest 用 NEMU 参考(非 spike);so 用 make difftest-ref 构建,历史坑=Linux config 污染"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

NPC rv64 的 difftest 参考模型用 **NEMU**(`nemu/build/riscv64-nemu-interpreter-so`,sim 默认路径,不传 `--diff` 即用),不要用 spike-diff so(除非 NEMU so 临时不可用)。

**Why:** 用户明确要求(2026-07-02);NEMU 是本工程自己维护的金标准(ACT4 161/161 已验)。此前用 spike 是因为 NEMU so 不存在+历史上被 Linux config 污染的 so 崩 Verilator 宿主。

**How to apply:** so 缺失/过期时用钦定构建:`make -C npc/rv64 difftest-ref`(内部=切 `riscv64-npc_defconfig` + `SHARE=1` 构建)。**坑**:该命令会覆盖 `nemu/.config`——先备份用户当前 config,构建后恢复并 `make -C nemu` 重建主 interpreter(防 stale 二进制/autoconf 漂移)。so 必须用干净 npc_defconfig 构建(Linux/Ubuntu config 构建的 so 加载进 Verilator 宿主会崩)。已知限制(#107):DiffContext 无 FPR→rv64uf/ud 在 difftest 下有假 mismatch;尾部 exit-ecall 记账 off-by-one 属 harness 层。相关 [[lsq-sq-switch-landed]]。
