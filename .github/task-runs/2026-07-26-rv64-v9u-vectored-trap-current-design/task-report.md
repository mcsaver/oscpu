# V9U 本地 RV64 向量陷阱与中断委派报告

## 结论

`CsrFile` 的 Direct/Vectored tvec、统一 trap record 和 supervisor interrupt
委派路由已在当前设计
`sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`
上闭合。定向 `rv64mi-p-illegal` 与完整 F0 均通过；该结论不包含 full-core
freeze 或 PPA 晋级。

## Root cause 与最小 RTL 修复

首次完整 F0 在
`.github/cache/rv64-functional-v9l/official-runs/20260726-183420-3396363`
仅失败 `rv64mi-p-illegal`。程序把 `mtvec` 写为 Vectored、置
`mip.SSIP`/`mie.SSIE`、打开 MIE 后停在 `0x800001fc` 等待 trap。

MODE=01 支持使该测试不再被 Direct-only readback 绕过，并暴露两个相邻缺口：

- `m_irq_enabled_pending_w` 只接收 `MACHINE_INT_MASK`，所以未委派 SSIP/STIP/SEIP
  即使在 `mip & mie` 中有效，也不会向 M 发出 pending。
- `trap_irq_to_s_w` 由 SSI/STI/SEI cause 类别直接推断 S 目标，没有以
  `mideleg[cause]` 和当前 privilege 为合同。

生产修复只修改 `npc/rv64/vsrc/core/CsrFile.v` 的组合路由：

- 分离 `delegated_s_irq_mask_w`、machine alias suppression 与 supervisor pending；
- 未委派 supervisor pending bit 保留原 cause 并并入 M pending；
- S pending 只消费已委派 supervisor bit；
- M cause 优先级扩为 MEI>MSI>MTI>SEI>SSI>STI；
- trap delegation 改为 `priv_mode_q != M && mideleg[cause]`。

没有新增队列、状态寄存器、AXI channel 或 terminal-event 去重路径。

## 断言与负向版本

- A1：独立重构 `mem > ex > irq` 选中记录。
- A2：独立重构 BASE 与可选 `4×cause` 目标。
- A3/A4：写后一拍检查 mtvec/stvec WARL，并持续拒绝 MODE=10/11。
- A5：独立重构 M/S pending 与 cause 优先级，marker 为
  `[VECTORED-TRAP-A5-IRQ-ROUTING]`。

`run_csr_vectored_trap_mutations.py` 的 7 个可编译 RTL 版本全部被动态拒绝：
Direct-only target、同步异常错误向量化、强制 mtvec、保留 MODE 透传、
错误 trap 优先级、offset +4，以及丢弃未委派 supervisor interrupt。

## 分层验证证据

- V9U canonical：focused 13/13、full-core 3/3、CSR regression 1/1、
  compile-success/dynamic-rejected mutations 7/7、raw duplicate terminal 0。
- 定向官方：
  `.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/evidence/official-illegal-current/20260726-184439-3423046/status.txt`
  报告 `rv64mi-p-illegal PASS`。
- 完整 F0：module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、
  CoreMark 10/CRC `0xfcaf`、Dhrystone 10000。
- CONTROL：focused 10/10、queue-head config 3/3、RTL variants 11/11、
  V9R baseline 2/2 与负向 3/3、evidence index 165 artifacts。
- 架构：DI-1..DI-5、OOO-1..OOO-4 为 9/9 GREEN；producer/holder
  baseline 8/8、negative variants 9/9。
- 证据单测：`test_vectored_trap_evidence` +
  `test_arch_stable_freeze` 共 56/56 PASS。

关键产物 SHA-256：

- `vectored-trap-current.json`：
  `b0b26dc6fc3849eeef958e23f0ba5e4cff5e29df45f5d86b1d286f080931711d`
- `vectored-trap.log`：
  `fd03801f13a072ee44f3d0d65ee56275037715b99390517ba02e42bd0c4a6639`
- `functional-aggregate-result.json`：
  `3672097358fc230c3059dfb207c772dc62c5f07c0929c36c388baa33de5a070e`
- V9O `evidence-index.json`：
  `640cea706d317de9880c3c6baed616d8b1c0e48a139e1bb936b506764643ed47`
- `architecture-debt-ledger.json`：
  `2b7af8407c10dd233e0f948f3dd042cb9a4b53b462caa4226006288ddd93af02`

## 工作流纠偏与剩余边界

证据 validator 原先把“full-core candidate 必须仍是旧 design-id”写成永久条件。
这与当前设计的诚实 GAP candidate 重绑定冲突。本轮改为：candidate 必须与 live RTL
同 SHA，同时仍必须是 `GAP/UNQUALIFIED/promotion=false`；新增旧 candidate identity
反例，避免历史暂态成为永久门槛。

最终 boundary 为 `GAP`、36 blockers、PPA `UNQUALIFIED`。当前主要剩余项：
`SERIALIZE-G1=OPEN`；`A-COHERENCE-G1`、`DEBUG-TRIGGER-G1`、
`SFENCE-SINVAL-G1`、`WFI-G1` 的 scope 决议；producer-holder census 的
instance/semantic closure；cohort inventory 与 binaries/config/constraints/images/
workflow 等 freeze-input 精确成员。以上均未被本轮局部 PASS 覆盖。

## AI 环境证据与 strict guard

`github-index` 的旧字符分块会让根 `AGENTS.md` 首块超过 1200-token load
预算，使完整 shim 即使已经入库仍无法被有界读取。本轮在
`scripts/dev_memory/core.py` 增加 1000-token 索引分块上限：

- 根 shim 现在形成 972/418-token 两块，`load --path AGENTS.md
  --max-tokens 1200` 可返回首块；
- 单行 `LOAD_ONLY_OVERSIZE` 反例仍保持单个超预算 chunk，并继续 fail-closed；
- `.github/task-runs/2026-07-26-default-chunk-max-tokens/` 的
  `github-index` profile completed。

strict guard 当前仍为非零，但缺口已收敛为两个未冒充 PASS 的 profile：

- `agent-system` 的真实 profile 在 `three-layer-contract` 被既有 Markdown
  覆盖集合阻塞（`active_md=9598`、`db_owned=7378`、`shims=25`、
  `live_evidence=3`、`live_rules=2`）；
- `rv64-linux` 仍由 V9S systemd-strict RED 约束；相同设计、配置和窗口不做
  无信息增量的重复运行。

这两个 strict-guard 缺口均作为显式豁免记录，不提升为 completed，也不改变
当前 RTL design-id、断言强度、terminal-event 语义或 PPA `UNQUALIFIED` 边界。
