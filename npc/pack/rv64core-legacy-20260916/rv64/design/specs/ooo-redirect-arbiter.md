# OooRedirectArbiter —— 统一控制流重定向仲裁器(年龄律)

> ✅ **状态(2026-07-09 P4 切消费点)**: 生产在线。redirect PC 唯一真源, 生产实例
> `OooFrontend.u_redirect_arbiter`; 权威优先级契约见
> `ooo-flush-redirect-contract.md` §2.2, 治理路线见
> `../arch/pipeline-stage-boundary.md` §5/P4。
> 历史: 2026-07-03 因未接线删档(fece978e6) → 2026-07-08 shadow 复活(assert-then-converge)
> → 2026-07-09 shadow 全绿后切消费点转正。

## 需求

把全核多个 redirect 源仲裁成**唯一** redirect_request(单赢家), 消灭「散落优先级双落点
人工同步」失败模式(GAP-1)与「CSR/xRET vs branch mispredict 序倒置」缺陷(GAP-2)。

## 协议

纯组合 selector, 无 clk/状态。三输入口, 每口 `{valid, pc, rob_idx, reason, flush_fetch,
flush_backend}`; 单输出 `{redirect_valid, redirect_pc, kill_idx, reason, flush_fetch,
flush_backend}`——只"选择并透传胜者字段", 不发明 flush 策略。

- **仲裁 = 年龄律**: `age = rob_idx − rob_head_idx`(`OOO_ROB_INDEX_W` 位环形减法),
  最老(age 最小)胜; 同 age 平手按类序 trap > branch > direct。静态优先编码器方案被
  宪法否决(会让 younger direct 覆盖 older trap/branch, 见 history/b2 §3.2)。
- **trap 口** = commit 家族(E1 csr_trap > E5 csr_commit > E6 drain 终态; 家族内序在
  `OooFrontend` pre-mux——三者同为 commit-time、同 rob_idx=head、age≡0, 年龄律无法区分
  家族内成员), rob_idx 接 head。
- **branch 口** = E3 后端 mispredict(valid=`branch_resolve_untracked_redirect`,
  已含 misaligned/trap_redirect_squash 掩码), rob_idx = resolve 真 rob_idx。
- **direct 口** = E4 dispatch 拍直算控制流(valid/pc = e4 构造式: direct_fire_succ +
  fallthrough-capture 覆写), rob_idx = **head−1 哨兵**(age=2^W−1 恒最年轻)——direct 是
  dispatch 拍事件, 构造上严格年轻于任何本拍后端 resolve 分支, 哨兵是该语义的保守编码;
  age15 平手拍不可达(分支占 head+15 ⟹ ROB 满 ⟹ 无 dispatch ⟹ 无 direct fire),
  即便可达 tiebreak branch>direct 与原 :263 override 同向。

## 消费点

- `OooFetchRequestMux.redirect_pc_i`: 赢家透传(无赢家拍兜底 core_branch_resolve_next_pc)。
- `OooFetchPcOutstandingSequencer.redirect_pc_i`: always 块文本最后唯一 arb 终写。
- `kill_idx / reason / flush_fetch / flush_backend`: **本阶段 unused-sink**(房规
  `_unused_` wire)——后端 kill(E3 `branch_resolve_mispredict_w` 扇出)与 nuke
  (E1/E2 `core_local_flush`)保持原源, GAP-4 后端扁平 OR 收敛另立刀。
  reason 同时被 `OooFrontend` INV-1 断言消费(branch 口接线守卫)。

## 不变量与守卫

- 「同拍两源都赢由构造不可能」: argmin 是函数, 输出基数=1(对照旧双机制的 GAP-1)。
- INV-1(`OooFrontend`): branch 口赢家拍 redirect_pc == core_branch_resolve_next_pc
  (负测试: 错接 branch_pc_i → tb_ooo_sv39_boot 623 fire → 复原 0 fire)。
- INV-2/INV-3c(`OooFetchPcOutstandingSequencer`): arb 终写与保留臂(E7/E8/E9)的
  onehot0 + 排除拍互斥哨兵。
- INV-3/INV-3b(`OooControlPlane`): GAP-2 甲门删除的不可达性哨兵(flag=1 唯一可能违反域)。
- `tb_ooo_redirect_arbiter` 13 例: 年龄序/平手类序/环形 wrap/字段透传。

## 非职责

- 不裁决 AXI 事务层(铁律② nokill 旁路)、不并入 E11 mmu_flush(正交)与 E10
  trap_redirect_squash(掩码, 年龄律最终可吸收但非本阶段)。
- 不产生 flush 策略——flush_fetch/flush_backend 由源口提供、透传。

## V9O 类型化控制事件 overlay

V9O 把仲裁字段从两个松散 Boolean 收敛为：

```
{valid, pc, rob_idx, reason[3:0], flush_fetch, backend_action[1:0]}
backend_action = NONE | SELECTIVE_NOW | FULL_NEXT
```

`control_event_valid_o` 表示本拍存在年龄律赢家；`redirect_valid_o` 仅表示赢家同时要求
`flush_fetch`，二者不得再互相代替。`redirect_flush_backend_o` 只作为兼容观察量，
严格由 `backend_action != NONE` 派生。该仲裁输出是 canonical frontend/reference
consumer；production backend 不直接反馈读取它，而使用 ROB edge-old cycle-free 投影，
并在 `OooCoreTopGlue` 以双向断言证明 action/payload 一致，避免 ready/direct-fire
组合反馈。

源口合同：

- commit 家族：E1=`TRAP/FULL_NEXT`，queue-head E5=`CSR_COMMIT/FULL_NEXT`；
  exact pending-system CSR owner 提交及 drained pending E5/E6 提供
  `CSR_COMMIT|SERIAL/NONE` 前端事件，不请求 C1 full apply。
- branch/JALR：后端已通过 C0 队头预授权裁决的 resolve apply，
  `BRANCH_MISS|JALR_MISS/SELECTIVE_NOW`。misaligned resolve 仍是类型化
  selective backend event，但 `flush_fetch=0`，由精确 trap 路径接管 fetch PC。
- direct：`DIRECT/*/NONE`；只控制前端，不直接清后端。

新增不变量：

- **REDIR-I5 event/redirect 分离**：
  `redirect_valid_o == control_event_valid_o && redirect_flush_fetch_o`。
- **REDIR-I6 action 透传**：赢家 reason/action/kill_idx 必须来自同一输入记录，
  禁止由胜者类别在仲裁器内重新推断。
- **REDIR-I7 合法 action**：所有 valid 源 action 只能取上述三值。

变更记录补充：

- 2026-07-23（V9O）：reason 扩为 4 bit，新增 `CSR_COMMIT`；后端动作改为三值枚举，
  控制事件存在性与 fetch redirect 分离。
