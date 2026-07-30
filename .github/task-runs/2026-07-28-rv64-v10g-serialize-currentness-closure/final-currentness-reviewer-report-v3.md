# V10G serialize currentness final reviewer report v3

RV64 RTL 结论｜对象=`SERIALIZE` Phase1、
`historical-defect-backfill-ledger.json`、
`arch-stable-audit-current.json`、`OooPendingLane1CaptureGate.v`｜
周期/配置=`product-default`、
`design_id=sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`｜
testbench/EDA 观测=checker 9/9、architecture 9/9、V9O 167/167、
XRET compile-success negative 命中 holder-onehot｜范围=PASS

## 裁决

`APPROVED_FOR_CURRENT_SCOPE`

## 反例优先复核

- 历史缺陷账本有效：`VD0=0`、`VD1=2`，且只有一个
  `SELECTED`。选中项仍是 queue-head CSR 与 younger SQ store
  的等待环；另一 VD1 保持 `QUEUED`，均未错误晋级。零 VD0/VD1
  fixture 可通过，证明 `ARCH_STABLE` 集成不是恒阻塞。
- 当前审计仍明确保留 `architecture_freeze=GAP`、32 个 blocker、
  `PPA=UNQUALIFIED`、`promotion_eligible=false`。本裁决只批准
  `SERIALIZE` Phase1 currentness closure。
- 冻结输入 replay 的 9 个 checker 全部通过，且输入 SHA-256
  前后不变。该 replay 只证明 checker-derived identity；
  production RTL currentness 另由 product-current 26/26、XRET
  定向重跑和 architecture 9/9 约束，未用 checker replay 替代
  RTL 语义验证。
- XRET 负向证据是真实 compile-success RTL version：移除 lane1
  arch/system exclusion 后，仿真命中
  `[V10A-SERIAL-OWNER-ONEHOT] arch and system holders overlap`
  并非零退出；源文件、version 和日志 SHA-256 一致。
- 四份 cohort contract 均绑定当前 design-id。V9O 的 167 个
  artifact 是逐项路径、大小和 SHA-256 验证后的计数，不是声明字段。
- `GAP_MARKER_SCHEMA_ONLY` 只记录旧 marker schema：旧
  pre-scoreboard fixture 会错误放行；当前 owner-bound raw scoreboard
  对同一 compile-success RTL version 以 `rc=1` 拒绝，并分别记录
  3 次 repeated/unowned request。未发现 terminal-event dedup 或
  assertion weakening 遮蔽失败。
- A3 保留 oracle-invalid `FAIL`，A4 保留 `TERM/rc=143 FAIL`；
  未发现将其改写为 PASS 的证据。A3/A4 直接状态源不在本次只读
  合同路径内，本项通过 SHA-256 绑定的 V10G verifier、decision
  与 current audit 复核，属于已声明的范围限制。

## 保留边界

- 完整 `ARCH_STABLE` 和 PPA promotion 不在批准范围。
- 后续先为 `HIST-SER-QH-YOUNGER-STORE-CYCLE` 增加
  younger-store 定向正例，以及恢复等待依赖的 compile-success
  负向 RTL version；随后处理
  `HIST-SER-QH-STOP-HOLD-DROP`。
- whole-core holder census 与 formal freeze-input inventory 的其余
  blocker 保持开放。

置信度：当前证据链高。审查者仅运行合同允许的只读命令，未修改
文件，未启动仿真、综合或 STA，且已归还唯一 WSL shell ownership。
