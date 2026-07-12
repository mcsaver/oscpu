# IFU-ACCESS-G1 lane1 fault owner RED

- status: red-established
- base_commit: `b1b1156db`
- scope: 只新增/登记验证代码与 RED 证据，不修改 production RTL。
- boundary: 本切片只覆盖 `IFU-LANE1-OWNER`；ARSIZE、物理读取 footprint、PMP/RRESP 与
  faulting-portion tval 不在本 RED 的实现范围。

## RECALL

- 已读：`.github/AGENTS.md`、`.github/copilot-instructions.md`、DB-backed
  `project-status.md`/`known-issues.md`、`interface-contract-first.instructions.md`、
  `rtl-generation-workflow.instructions.md`。
- 已读 active specs：fetch head pair、frontend dispatch、pending dispatch/lane1 capture、
  stop pending、pending trap/exit、trap/exit mux/output、fetch bridge/decode。
- 已沿生产数据流复核：`OooFetchHeadPairGate -> OooFrontendDispatchGate ->
  OooPendingDispatchArbiter -> {OooPendingTrapExitSequencer,
  OooStopPendingSequencer} -> OooCsrTrapRequestMux`。

## 接口契约冻结

| 场景 | lane1 fault owner | 后续动作 |
| --- | --- | --- |
| ordinary head0 + lane1 PF/AF | 必须捕获 | backend drain 时形成对应 instruction PF/AF |
| pred-NT branch，实际 NT + lane1 PF/AF | 必须捕获 | fault 阻断 branch+lane1 双发并形成 barrier |
| pred-NT branch，随后 actual-taken | 先捕获 | branch squash 必须清 pending valid、cause、pc、tval |
| pred-taken packet 的 poison lane1 | 禁止捕获 | `head_slot1_valid=0` 是 slot1 可见性真源 |
| `arch_trap_raw=1` 但 `head_fetch_fault1=0`，cause 仅默认成 ACCESS | 禁止捕获 | 保留 ROB-walk 旧伪 ACCESS 过滤，不可把放行真实 AF 写成全局去过滤 |

- 握手/stall：TB 不新增协议状态；dispatch ready 恒 1，barrier fire 表示当前 packet owner 转交。
- flush/redirect：actual-taken 用 production `branch_resolve_untracked` squash 源；该源必须同时清
  `stop_pending` 与 pending arch trap/payload。
- 异常序：fault 只进入 pending trap owner，不把 fault slot 当普通 backend uop。
- 访存序：不涉及数据访存。
- 投机恢复：`head_slot1_valid` 决定 pred-taken poison；pred-NT 可见 lane1 先捕获，resolve 再 squash。

## RTL 推导摘要（验证代码）

### 需求

- 新增一个 permanent integration TB，真实串起 PairGate、DispatchGate、PendingArbiter、
  TrapExit/StopPending 与最终 CSR trap request。
- 每行只产生一个矩阵 verdict，避免同一根因的级联检查把 RED 数膨胀。
- 旧 RTL 必须成功编译并运行到 TB 自身失败；不得用编译失败或缺 marker 伪造 RED。

### 协议与状态机

- 组合阶段：head facts -> lane1 barrier -> pending capture request。
- 时序阶段：`IDLE -> CAPTURED -> DRAIN_TRAP`；actual-taken 行改走
  `IDLE -> CAPTURED -> SQUASHED`。
- reset 在每行前清状态；packet pop 用 `fifo_has_packet=0` 建模，避免重复 capture。

### 不变量

- 真实 PF/AF 的 capture cause/pc/tval 必须与 lane1 response/PC 一致。
- pred-NT branch 后 fault 必须使 `dbranch_dual_go=0` 且 barrier fire。
- squash 后 pending valid 与全部 payload 为 0，且不得形成 trap request。
- pred-taken poison 与伪 default ACCESS 均不得产生 pending arch trap。

### 数据通路与拓扑

```text
head packet/ctrl/resp
  -> OooFetchHeadPairGate
  -> OooFrontendDispatchGate
  -> OooPendingDispatchArbiter
       -> OooPendingTrapExitSequencer -> OooCsrTrapRequestMux
       -> OooStopPendingSequencer -----------^
```

- 寄存器只来自两个 production sequencer；TB 不复制 owner 状态。
- reset > squash/clear > capture/normal advance 采用各 production module 当前优先级。
- 关键路径/PPA 不在验证代码范围；TB 只观察功能合同。
- helper task 只组织激励/检查，不封装 production 仲裁或状态更新。

## RED matrix

执行命令：

```bash
source scripts/agent-env.sh
make -C npc/rv64/testbench \
  RESULT_DIR=../../../.github/task-runs/2026-07-12-rv64-ifu-access-g1-red/evidence/current-red \
  TESTS="tb_ooo_ifu_lane1_fault_owner" run
make -C npc/rv64/testbench \
  RESULT_DIR=../../../.github/task-runs/2026-07-12-rv64-ifu-access-g1-red/evidence/pair-red \
  TESTS="tb_ooo_fetch_head_pair_gate" run
```

两条命令均为**编译成功、仿真按 TB 合同失败**；日志出现实际 row/check marker、
`simulation returned nonzero status 1` 与 runner `[RESULT] FAIL`，不是 compile RED 或缺模块假红。

| row | current result | 首个断点 |
| --- | --- | --- |
| ordinary head0 + lane1 PF | PASS | Pair/dispatch/capture/pending/drain=`1/1/1/1/1` |
| ordinary head0 + lane1 AF | **RED** | Pair/dispatch=`1/1`，Arbiter capture=`0`：ROB-walk cause filter 把真实 AF 与伪 default ACCESS 混同 |
| pred-NT correct-NT branch + lane1 PF | **RED** | PairGate fault owner=`0` |
| pred-NT correct-NT branch + lane1 AF | **RED** | PairGate fault owner=`0` |
| pred-NT actual-taken branch + lane1 PF | **RED** | 应有的 capture=`0`；随后 squash 正对照=`1`，排除“从未捕获所以看似清除”的假绿 |
| pred-NT actual-taken branch + lane1 AF | **RED** | 应有的 capture=`0`；随后 squash 正对照=`1` |
| pred-taken poison lane1 PF | PASS | slot1_valid=0，全链无 owner |
| pred-taken poison lane1 AF | PASS | slot1_valid=0，全链无 owner |
| pseudo arch-trap default ACCESS, no fault provenance | PASS | barrier 可见，但 Arbiter arch capture 保持 0 |

整链精确计数：**9 rows = 4 PASS + 5 RED**。局部 PairGate TB 另有 **1 个精确 RED**：
`pred-NT lane0 branch preserves lane1 fault got=0 expected=1`。

证据：

- `evidence/current-red/logs/tb_ooo_ifu_lane1_fault_owner.log`
- `evidence/pair-red/logs/tb_ooo_fetch_head_pair_gate.log`

## 实现者 / 审查者对抗

- 实现者：整链不靠 force production internal net；真实 PF/AF 从 PairGate response 输入进入，
  时序状态完全由 production sequencer 持有。每行聚合一个 verdict，RED 数不受级联检查膨胀。
- 审查者反例 1：actual-taken 行若只检查 squash 后 `pending=0` 会因“从未捕获”假绿。
  已在同一行先检查 capture，再检查 squash 后 validity/payload/stop/trap request 全清。
- 审查者反例 2：直接删除 ROB-walk ACCESS cause filter 会让旧 pseudo arch-trap default cause
  重新污染 pending。第 9 行显式构造 `ARCH_TRAP=1 && head_fetch_fault1=0` 锁住该反例。
- 审查者反例 3：pred-taken packet 的 raw resp poison 不是架构路径。第 7/8 行以
  `head_slot1_valid=0` 锁住 no-capture，防止未来粗暴“branch 后一律保留 fault”。
- 剩余边界：本 RED 不证明 actual branch execute/ROB-walk 计算本身，只使用其 production
  `branch_resolve_untracked` squash 接口；也不关闭物理 footprint、PMP/RRESP 或 IFU-TVAL。
