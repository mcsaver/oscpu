# OooRasUpdateGate 规格

## 阶段 1：需求

`OooRasUpdateGate` 负责从 `OooAluFetchCore` 中抽出 RAS 栈上游的纯组合更新控制：

- RAS/return-cont 需要清空的全局预测边界。
- direct/pending return-like 触发的 RAS pop；旧 pending lane1-ret dispatch replay
  已移除，不再作为 RAS gate 输入。
- direct/pending call 触发的 RAS push。
- RAS push value 在 pending call 与 direct JAL call link 之间的选择。

输入均来自父模块已经计算出的事件事实和 link/next PC；输出直接喂给
`OooRasStack`，其中 `ras_clear_o` 同时喂给 `OooReturnContBuffer`。模块没有时钟、
复位、寄存器或 ready/valid 状态。

不在本模块范围内：

- 不维护 RAS 栈、可靠性位或栈顶。
- 不决定 direct/pending call/return 是否 fire。
- 不维护 return-cont buffer entry。
- 不参与 PC redirect、dispatch、commit 或 branch recovery 时序。

## 阶段 2a：协议规则

- `ras_clear_o` 是 predictor boundary、branch-spec restore、untracked branch
  recovery 和 unsafe direct JAL call 的 OR。
- `ras_pop_o` 是 direct ret0、direct ret1、pending jump return 和 direct branch
  lane1-ret capture 的 OR。
- `ras_push_o` 是 direct JAL call 与 pending jump call 的 OR。
- `ras_push_value_o` 在 pending jump call fire 时选择 pending jump next PC，否则选择
  direct JAL link；当 `ras_push_o=0` 时 value 为 don't-care。
- 同周期 push/pop/clear 的仲裁不在本模块内完成，继续由 `OooRasStack` 的时序逻辑
  按既有优先级处理。

## 阶段 2b：状态机

本模块无内部状态机，是纯 Mealy 组合网络。所有状态和优先级处理保留在
`OooRasStack` 与父模块。

## 阶段 2c：不变量

- `ras_clear_o == priv_predictor_boundary_i || branch_spec_restore_i ||
  branch_resolve_untracked_i || direct_jal_call_unsafe_i`。
- `ras_pop_o` 必须覆盖所有 direct/pending return-like 事件，且不得依赖 push。
- `ras_push_o == direct_jal_call_i || pending_jump_call_fire_i`。
- `ras_push_value_o` 必须让 pending jump call 优先于 direct JAL link。

## 阶段 2d：数据通路约束

- Clear/pop/push 都是单层 OR 网络。
- Push value 是 pending-call 优先的 2:1 mux。
- 输出全部组合直达，不增加周期延迟。

## 阶段 3：RTL 映射

RTL 文件为 `npc/rv64/vsrc/frontend/OooRasUpdateGate.v`。单元测试
`tb_ooo_ras_update_gate` 覆盖 clear OR、pop OR、push OR、pending push value 优先级
和 direct-only push value。
