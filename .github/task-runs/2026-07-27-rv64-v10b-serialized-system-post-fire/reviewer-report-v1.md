# V10B serialized SYSTEM post-fire pre-review

## 结论

RV64 RTL 结论｜对象=`OooPendingSystemSequencer` 八类 kind →
`OooPendingDrainResolveGate` / `CsrFile` / typed redirect / MMU｜
周期/配置=`Ccap → C0 → C1 → C2`，CSR 为 enqueue → exact PID/PC
`Ccommit`｜TB/EDA 观测=只读静态预审；未运行仿真/综合/STA，复核既有
TB 源码 marker｜范围=`GAP`。

允许范围内未确认 production RTL 重复副作用或错误优先级；canonical
kind、CSR lease、非 CSR 同沿 holder/stop clear 的静态拓扑合理。但当前
V10B 证据不能 PASS，主要 blocker 是 MMU action 与部分伪提交/no-repeat
没有直接观测。现有绿色 marker 不足以关闭八类 post-fire 合同。

## 八类 transaction 矩阵

| kind | C0/C1/C2 真实路径 | 预期副作用 | 现有观测与裁决 |
| --- | --- | --- | --- |
| CSR | C0 `system_csr_dispatch_fire_w`；C1 `dispatched/producer_valid/stop=1`；`pending_system_csr_commit_w` 仅在 kind + lease + `core_commit0_csr_w` + PID + PC 全匹配时成立；commit 后 holder/stop 清 | `CsrFile.csr_commit_i`、`CSR_COMMIT/NONE` redirect；SATP 写另发 MMU pulse | `V8K-PRIV-DISPATCH/BIRTH/EXACT-COMMIT/DEATH` 与 `V9O-PENDING-CSR-OWNER-INTEGRATION` 源码 oracle 较强。lease 子范围 PASS；SATP MMU action 未观测，整类仍 GAP |
| ECALL | C0 `drain_complete_w → pending_system_ecall_trap_w → trap_ex_valid`；边沿写 xEPC/xCAUSE/xTVAL；C1 owner/stop 清 | `TRAP` redirect；无 MMU | `VECTORED-TRAP-G4-M-SYNC` 计 raw ex request/target，且区分 architectural ECALL 与 simulation exit；缺 system-holder C1/C2 直接计数，GAP |
| XRET | C0 `csr_mret_valid_w`，SRET/real-MRET 分流；边沿更新 privilege/mstatus；C1 clear | `XRET` redirect 到 `ret_target`；无 MMU | legal MRET/SRET request 与 commit 都有 exact-one counter；缺 holder/stop/no-repeat 同一 scoreboard，GAP |
| WFI | C0 drain；不进 `CsrFile`；frontend fallback reason=`SERIAL`；C1 clear | cohort 定义的 immediate-resume redirect/伪提交；无 MMU | 当前仅 `saw_wfi_commit` Boolean；未计 raw redirect、伪提交、C1/C2 或零 CSR/MMU action，GAP |
| SFENCE_FAMILY | C0 `pending_system_sfence_commit_w`；C1 clear | reason=`SFENCE`、`priv_predictor_boundary`、MMU flush、伪提交 | 只覆盖 SFENCE.VMA、SINVAL.VMA；仅 SINVAL typed reason，未覆盖 `SFENCE.W.INVAL/SFENCE.INVAL.IR`，MMU 输出未观测，GAP/blocker |
| FENCEI | C0 `pending_system_fencei_commit_w`；C1 clear | reason=`FENCEI`、MMU/I-side flush、伪提交 | 有 commit Boolean 与 typed reason；没有 MMU pulse或 self-modifying-code / I-cache stale oracle，GAP/blocker |
| FENCE | C0 额外要求 `mem_idle_i`；C1 clear | reason=`SERIAL`、伪提交；不得产生 CSR/trap/MMU action | `FENCE-G1-PROGRAM` 已计 commit=1并检查 store drain/device ordering，ordering 子范围强；零 MMU/CSR、typed redirect、C1/C2 未直接计数，GAP |
| IRQ | C0 `trap_irq_valid_w`；`CsrFile` 以 selected IRQ record写 xEPC/xCAUSE；C1 clear | `TRAP` redirect，vectored 可加偏移；无 MMU | `VECTORED-TRAP-G2/G3` 对 raw irq request、target、handler、xRET 均 exact-one；缺 system-holder C1/C2 同一 scoreboard，GAP |

## 最强 reachable counterexample

当前最强反例是验证假绿，而不是已确认的 production bug：

1. 在 `OooMemoryAccess.v` 将
   `.pending_system_fencei_commit_i(pending_system_fencei_commit_w)`
   编译成功地变异为 `1'b0`。
2. 上游 holder clear、伪提交和 `FENCEI` typed redirect 均保持不变。
3. `tb_ooo_core_top_glue.sv` 与 `tb_ooo_priv_system.sv` 都把
   `.mmu_flush_o()` 留空；其它已审 TB 不包含该 MMU 路径。
4. 因而现有 FENCE.I marker 构造上可能继续为绿。
5. 在真实 `NpcCoreTop` 中，普通 store 明确不会主动失效 I-cache；若执行
   “缓存旧指令 → 写入新指令 → FENCE.I → 跳回”，fetch bridge 未收到
   `ooo_mmu_flush_w`，可执行 stale instruction。

SFENCE 与 pending-SATP 的 MMU 输入断线存在同型假绿。该反例必须通过实际
compile-success mutation 动态确认；本节点未运行变异。

## 最小验证方案

- 新增一个基于 production `OooCoreTopGlue + CsrFile` 的 clocked
  scoreboard，逐 kind 直接计数 C0 authority、raw CSR request、typed
  reason/PC/action、伪提交、`mmu_flush_o`、C1 owner/stop、C2 repeat；
  不得去重。
- CSR 另检查 enqueue 后 lease 保持、错误 PID/PC 均不得提交、exact
  commit 后 `CsrFile` readback 和 lease death。
- SFENCE family 跑四种编码；WFI 跑无 IRQ immediate-resume 及 IRQ
  birth-priority；FENCE 跑 busy → idle；ECALL/IRQ/XRET 检查 selected
  `CsrFile` record。
- FENCE.I 再加一个 `NpcCoreTop` self-modifying-code / I-cache test，不能
  只看 pulse。

## 最小 compile-success mutation 家族

- 分别删除 CSR PID match、PC match。
- 分别删除 non-CSR holder clear、stop clear。
- 分别切断 SATP/SFENCE/FENCEI 三路 MMU action。
- 将 SFENCE/FENCEI reason 各退化为 `SERIAL`。
- 删除 FENCE 的 `mem_idle_i` 项。
- 删除 commit-exception 对 pending system 请求的 mask。
- 删除 WFI terminal redirect/伪提交。
- 令 WFI/FENCE 错误地产生 MMU action，验证零副作用 oracle 非真空。

## Scope extension request

- `npc/rv64/vsrc/memory/OooMemoryRequestGate.v`：核对 MMU pulse 真正方程与
  是否注册/重复。
- `npc/rv64/vsrc/core/OooWriteback.v` 及其
  `OooControlCommitSequencer` / 输出 mux 真源：核对七类伪提交
  exact-one。
- `npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v`：核对 typed
  redirect 的实际 PC 写入与 next-cycle 消脉冲。
- head/lane classifier 与 `OooPendingLane1CaptureGate` 真源：核对 SFENCE
  family 四编码。
- `OooFetchAxiBridge` / D-side MMU flush consumer：核对 pulse 确实清理
  I-cache/TLB，而非只到 wrapper 端口。

## 假设与未知项

- WFI immediate-resume 是 `wfi-g1-exclusion.json` 的明确 cohort 决策，
  不是遗漏 sleep FSM。
- 未读模块的行为不能由 wrapper 端口名推定。
- 既有 `PASS` 字符串仅为 TB 源码中的预期 marker，本节点未把它们当作
  本轮运行结果。
- simulation exit / semihost `pending_exit` 未与 architectural ECALL
  混合。
- 静态 holder/lease/priority 置信度高；伪提交、MMU consumer 与完整
  SFENCE family 置信度中低。

## 证据身份与协调状态

- contract SHA-256:
  `fb88f47b1d59abf01ea637db7f3a57fee6e76fe58451946025ad40fdbcb84a5e`
- reviewer 未修改文件，未运行仿真/综合/STA。
- reviewer 已停止全部 WSL 工程命令并归还唯一 Windows→WSL shell
  ownership。
