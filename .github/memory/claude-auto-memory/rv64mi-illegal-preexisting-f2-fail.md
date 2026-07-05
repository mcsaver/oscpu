---
name: rv64mi-illegal-preexisting-f2-fail
description: F2 head0=分支时 head1 不译码→lane1 CSR/system 双发读0 的 bug(已修);riscv-tests 353/354→355/0
metadata:
  node_type: memory
  type: project
  originSessionId: 024c1dc4-4857-46b0-b044-5f6871f81fb2
---

**已修复（2026-07-03）**：`rv64mi-p-illegal` 曾是当前 F2 核唯一的 riscv-tests 失败（353/354），
现已修复，riscv-tests(默认+特权) **355/0 全绿**、模块 TB 96/96、difftest 38/3 不变（零退化）。

**根因（5+探针逐层钉死，沿途证否 3 个错误假设）**：
`OooFetchHeadPairGate.v:190` 的 `head1_decode_valid_w` 含 `!head0_facts[OOO_SLOT_FACT_BRANCH]`
→ **head0=分支时 head1 不被译码分类(facts 全 0)** → `head1_system_raw=0` → 前端双发逻辑
`dbranch_dual_go`(要求 `!head1_system_raw`)看不到 head1 是 CSR/system 指令 → 允许把它双发进
domain-A → **CSR 指令在 domain-A 不执行(读回 0)**。表现：trap handler 的包 `[bne(head0), csrr mepc(head1)]`
里 csrr mepc 被当无害指令双发读回 0(mepc 寄存器却正确=0x264,trapwatch 证) → handler `beq t0,bad标签`
全不匹配 → `j fail`。这是 `OooFetchHeadClassifyGate:132-134` 注释点名的"head0=FP 压制 head1"FP 家族
bug 的**分支版**(FP 已修、分支没修)。

**修复**：去掉 `head1_decode_valid_w` 里的 `!head0_facts[OOO_SLOT_FACT_BRANCH]`(仅 BRANCH,保留
JUMP/STOP 压制不扩大改动面)。head0=分支时也译码 head1 → head1_system_raw 正确 → dbranch_dual_go 正确
排除 head1=system → 分支 fire+重取 head1 → csrr 成 head0 走 domain-B(读对);head1=普通指令行为不变(仍双发)。

**方法学教训（[[single-line-cross-signal-probe-debug]] 家族)**：此 bug 骗过了两套仔细的根因分析
(我的 dispatch 探针"head1 被丢"、工作流 commit-trace"trap-PC 捕获=0"),都被推翻。定死靠的是**架构退休
真相**：`NPC_TRAPWATCH`(env,免重编,看 trap epc/cause)证 trap 正确设 mepc=0x264、`NPC_COMMITWATCH_START/END`
(env,免重编,看逐 commit 的 rd_data)证 csrr mepc 退休读回 0。**dispatch 侧探针会被投机/双发/截断 confound;
认定根因前务必用 commitwatch/trapwatch 取架构退休真相对齐。** 优先用这两个免重编 env 机制,再上 RTL 探针。
