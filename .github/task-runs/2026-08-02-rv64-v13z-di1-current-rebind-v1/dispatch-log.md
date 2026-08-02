# V13Z DI-1 dispatch log

## root/currentness-audit

- RTL 对象：`OooFetchAxiBridge` H1 lookup/response turnover、`OooFetchFlowControl`
  outstanding/FIFO credit、`OooFetchPcOutstandingSequencer` owner replacement、packet FIFO
  到真实 backend sink。
- 配置：current 146-file design-id `093c2380…a7488`，Icarus `OOO_ASSERT`。
- 观测：current frontend 与 Bridge 正向定向仿真均 PASS；production RTL/TB 关键文件与
  V8Z 证据逐字相同，历史 full-design/provenance 绑定已过期。
- 决策：实现 scoped current rebind；不得覆盖 V8Z 历史 evidence 或 canonical manifest。

## root/current-design-implementation

- suite：`v13z-di1-20260802T032848Z-328215`；design-id：
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`。
- 观测：assert/release frontend 与 Bridge 4/4 PASS；9/9 compile-success RTL source mutation
  被定向 testbench 拒绝；6/6 相邻 TB PASS；局部 DI-1 GREEN、overall RED、PPA UNQUALIFIED。
- 证据：`evidence/di1-current/result.json`、`evidence/frontend-ii1.log`、
  `evidence/architecture-current.json`、`evidence/di1-mutations/summary.json`。
- 边界：production RTL 未修改；canonical manifest SHA 保持 `a0bd58bf…bc1`。

## v13z-di1-frozen-review-v1

- 模式：本地 RV64 限定材料只读复核，`self-contained-no-tools`；不持有 WSL shell ownership。
- 合同：`.github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/subagent-contracts/v13z-di1-frozen-review-v1.json`。
- 合同 SHA-256：`3c4d4e19187fe8c857d49884328fb9bfc3c2112ed1d6138190f269311fc265d7`；该哈希只绑定合同 JSON。
- 状态：`PASS`；未发现阻断反例，批准 current-design DI-1 局部 GREEN。
- 保留 GAP：measurement-window 原始逐拍重算、逐 payload/tag 双射、FIFO/tag wrap 与综合/STA
  未由限定材料证明；不得用于整体架构或 PPA 晋级。
- 输出：`reviewer-result.md`；`scope_extension_request=none`。
