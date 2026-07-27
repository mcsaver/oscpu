# V10A pre-implementation reviewer-v2

RV64 RTL 结论｜对象=OooPendingTrapExitSequencer.pending_arch_trap、
OooStopPendingSequencer.stop_pending、OooCsrTrapRequestMux 及
`subagent-contracts/reviewer-v2.json`｜周期/配置=C0 fire→C1 clear→C2
no-repeat；read-only-review/self-contained-no-tools｜TB/EDA 观测=仅复核冻结
production equation；未运行仿真/综合/STA｜范围=GAP

## 核心发现

限定条件下的 C0→C1 清除可由给定方程证明；无条件的
“`arch fire` 必然在 C1 清 owner/stop，且 C2 不重复”不能证明。最强反例是
`arch_fire` 与 `drain_clear` 的使能不等价：

- `arch_fire = stop_pending && drain_complete && pending_arch_trap`
- `drain_clear` 还要求
  `!csr_trap_mem_valid && !direct_frontend_flush`

因此冻结材料允许 `arch_fire=1 && drain_clear=0`。若 `fire` 表示已接受事务，
这是合同级反例；若仅表示 request-valid，则应以 CsrFile 的
selected/accepted 事件定义一次性提交。

## C0/C1/C2 判定

- C0：当 pending arch/stop/drain 均为 1，且不存在 commit trap/direct
  redirect 时，arch request 与 drain clear 同时成立；仍需动态检查 CsrFile
  选择、redirect 和无新 birth。
- C1：clear_arch 清 owner；stop 清除还依赖 priority chain 没有更高优先写 1；
  需动态检查 owner/stop 归零及 CSR payload 单次更新。
- C2：在无新 capture 条件下请求不得重复；不能把 C1 恢复 can_run 后的新事务
  误认作旧事务重复。

## 五类 overlap

- ECALL：同 lane 的 head0/lane1 仲裁有 arch 排除项，但跨周期仍需验证。
- IRQ：必须验证 same-edge IRQ priority 与 live-owner 时 can_run 抑制；不能只
  依赖 CsrFile ex>irq 优先级。
- xRET：必须证明注册 owner 不重叠；到达后 trap 会抑制 mret/sret。
- CSR：必须覆盖 producer lease，不允许 arch clear 造成 CSR holder/stop 不一致。
- FENCE：`mem_idle` 只证明普通 FENCE 排序，不能替代 owner onehot。

## 必须杀死的动态反例

1. pending arch 与同沿 `csr_trap_mem_valid=1`：确认 commit trap 选择、late
   clear 与无后续 arch side effect。
2. same-edge IRQ + arch birth：注册后不得双 owner。
3. ECALL/xRET/CSR/FENCE 的 head0/lane1 交叉，以及 live arch owner 后持续候选：
   必须经过 OooPendingDispatchArbiter。
4. nominal drain 与新 owner birth 冲突：必须由 can_run/stop_pending_busy 阻止。
5. 连接 CsrFile，分别计数 raw request、accepted trap 与 CSR state update，
   C0/C1/C2 后保持 1/1/1。

## 边界

pre-review 置信度：nominal C0→C1 为中高；全局 overlap 不可达与 CsrFile
exactly-once 为低。该节点未使用 shell、未读取合同外文件、未修改文件。

合同 SHA-256：
`fcb958cfa8984ba7b075ab38317d22385722b8546033c27e3046f1e3a7525aaa`。
