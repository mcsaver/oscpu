# V9B 架构债务审计

状态：账本结构与证据规则 `PASS`；full-core 债务闭合 `GAP`。

机器可读 source of truth：`npc/rv64/design/arch/architecture-debt-ledger.json`，SHA-256
`9a0211e6e36961ce740ff77aff8ae3a3d096d6c99a347c74b4964a8e1c7619d7`，绑定设计
`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。

## 审计汇总

| 优先级 | `CLOSED` | `OPEN` | `STALE_EVIDENCE` | `SCOPE_DECISION_REQUIRED` | 合计 |
| --- | ---: | ---: | ---: | ---: | ---: |
| P0 | 0 | 1 | 8 | 0 | 9 |
| P1 | 1 | 2 | 3 | 5 | 11 |
| 总计 | 1 | 3 | 11 | 5 | 20 |

检查器对账本产生 `92 PASS / 19 GAP`；19 个 GAP 与 19 项未闭合状态一一对应。九项
DI/OOO 架构硬门虽为 `9/9 GREEN`，但不得替代其未覆盖的 ISA、异常、控制事件、访存副作用、
功能汇总或 product-cohort 决策。

## P0 条目

| ID | 状态 | 当前闭合要求 |
| --- | --- | --- |
| `FDG-G1` | `STALE_EVIDENCE` | 将合法/非法 FP `arch_trap` 矩阵、程序汇总与 RTL source mutation 重绑当前设计 |
| `XRET-G1` | `STALE_EVIDENCE` | 将 MRET/SRET 当前特权模式合法性、精确异常与 RTL source mutation 重绑当前设计 |
| `MEM-ISSUE-G1` | `STALE_EVIDENCE` | 重绑 memory dequeue/request/owner birth 的正例、定向反例及 RTL source mutation |
| `IFU-AXI-G1` | `STALE_EVIDENCE` | 重绑 A-update AW/W/B backpressure、frontend flush drain 与 RTL source mutation |
| `IFU-FETCH-G2` | `STALE_EVIDENCE` | 重绑跨页 16/32-bit fault-byte provenance 正例、poison case 与 RTL source mutation |
| `IFU-ACCESS-G1` | `STALE_EVIDENCE` | 重绑 F=0/2/4/6、PMP/RRESP、guard-page、lane1 owner 与 RTL source mutation |
| `IFU-TVAL-G1` | `STALE_EVIDENCE` | 重绑 offset 2/4/6、compressed-control `tval` lifecycle 与 RTL source mutation |
| `PTW-PMP-G1` | `STALE_EVIDENCE` | 重绑 PTE WRITE allow/deny、deny 时无 AW/W 与 RTL source mutation |
| `INSTRET-G1` | `OPEN` | 新增程序级 retirement-count 回归和当前设计 RTL source mutation |

## P1 条目

| ID | 状态 | 当前闭合要求 |
| --- | --- | --- |
| `F0-G1` | `STALE_EVIDENCE` | 生成同一设计的 109 module、official 177、AM 59、DiffTest 与 benchmark aggregate |
| `MIQ-FLUSH-G1` | `STALE_EVIDENCE` | 重绑 MIQ 同周期 flush/DRAIN-pop 正例、定向反例与 RTL source mutation |
| `STORE-BRESP-G1` | `CLOSED` | 当前设计下已绑定 no-retire-before-B、单一 B terminal、error-B cause/tval 与 RTL source mutation |
| `FENCE-G1` | `STALE_EVIDENCE` | 重绑 store→FENCE→device-read full-drain 程序与 RTL source mutation |
| `A-COHERENCE-G1` | `SCOPE_DECISION_REQUIRED` | 冻结 single-hart reservation exclusion，或实现并验证 multi-master invalidation |
| `CONTROL-EVENT-G1` | `OPEN` | 定义 redirect/trap/pending/backend-flush 的单一事件身份、reason 与 consumer set |
| `SERIALIZE-G1` | `OPEN` | 闭合 queue-head serialize，或将 pending full-drain 固化为产品架构并补齐恢复证据 |
| `WFI-G1` | `SCOPE_DECISION_REQUIRED` | 决定并验证 WFI wakeup 语义，或在 cohort 合同中明确排除 |
| `SFENCE-SINVAL-G1` | `SCOPE_DECISION_REQUIRED` | 决定并验证选择性 invalidation，或在 cohort 合同中明确排除 |
| `VECTORED-TRAP-G1` | `SCOPE_DECISION_REQUIRED` | 决定并验证 vectored trap target，或在 cohort 合同中明确排除 |
| `DEBUG-TRIGGER-G1` | `SCOPE_DECISION_REQUIRED` | 决定并验证 architectural debug/trigger precise entry，或在 cohort 合同中明确排除 |

## 裁决

`STORE-BRESP-G1` 是唯一已闭合条目，其证据由当前 design_id、canonical memory-ordering 命令、
raw log、架构定向 suite 和 compile-success RTL source mutation 共同绑定。其余条目不得因 owner
路径存在、旧日志存在或九项汇总为 GREEN 而自动转为 `CLOSED`；必须满足账本中对应的
debt-specific semantic validator，或者通过规范 cohort exclusion 合同作出可审计的范围裁决。
