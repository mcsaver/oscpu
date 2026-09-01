# RV64 adapter input AW/W fall-through：本地 retained-point 契约

## 目标

删除“完整、合法、自然对齐的上游 write”到下游 AXI AW/W 之间固定的一拍 adapter admission
bubble，同时不改变 store retirement、response/error owner、split write 行为或上游 READY 公式。

候选为 `npc/rv64/vsrc/memory/OooLsuAxiLaneAdapter.v` 中的
`adapter-input-aw-w-fall-through-v1`。

## 必须保持的行为

- Direct offer 仅允许完整 AW+W、size 合法、WSTRB 精确 low-contiguous、地址自然对齐的命令。
- 上游 AWREADY/WREADY 仍只由本地 state/holder 决定。
- E0 downstream 接收矩阵必须精确：
  - `11`：进入 write-response owner；
  - `10`：只重发 W；
  - `01`：只重发 AW；
  - `00`：从寄存 payload 重发两通道。
- same-cycle、AW-first、W-first 三种上游组装顺序遵守同一规则。
- invalid、sparse、misaligned、split write 保持原有路径。
- OKAY/SLVERR/DECERR、split sticky error、final-B fall-through、上游 B backpressure、reset、
  escaped-write drain/drop 语义不变。

## Acceptance criteria

1. Adapter focused TB 在打开 `OOO_ASSERT` 时覆盖 E0 `11/10/01/00`、三种上游组装顺序、
   reset 屏蔽、每个 AW/W 恰好一次 fire、response class、backpressure、split 与 fail-closed 请求。
2. 仅关闭 input fall-through 的 compile-success mutation 必须恢复 causal
   `store_terminal=2,4,7` 与 `peer_admission=4,6,9`；mutation 前后 production source hash
   必须相同。
3. Candidate causal probe 必须报告 `store_terminal=1,3,6` 与
   `peer_admission=3,5,8`；B-delay slope、B-phase blocking 与 zero early peer admission 不变。
4. 本地 full-core A/B 使用同一当前源码树、config、frozen image、ROI 与 runtime 参数。唯一有效
   RTL source 差异是 adapter：candidate 对比从 `HEAD` 提取的 exact predecessor。
5. CoreMark 与 Dhrystone 两边都必须 HIT GOOD TRAP、保持相同 ROI retired，且 counter
   complete/available/conservation 为真、overflow/invalid events 为零；任一 workload 不得回退。

## 声明边界

本 task-run 最多建立 **retained local exploratory A/B**。每个 design/workload 各一次不是
promotion evidence。Promotion 仍要求规定的重复顺序、完整 system signoff、current mapped
STA/area 与独立审查。在此之前固定为 `PPA=UNQUALIFIED`、`promotion_eligible=false`，不得
宣称频率、面积、功耗或 5 ns timing 已合格。
