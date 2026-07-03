# OooDirectRasCandidateGate 规格

## 阶段 1：需求

`OooDirectRasCandidateGate` 负责从 `OooFrontend`(原 `OooAluFetchCore`)中抽出 direct RAS/RAS-ret
候选相关的纯组合事实：

- lane0/lane1 JAL 是否是 call-like JAL，即 `rd` 为 `x1` 或 `x5`。
- 当前周期是否允许 direct RAS 更新。
- lane0 JALR 是否可以作为 direct return 处理。
- lane1 JALR 是否可以作为 direct return candidate 交给 dispatch gate。

输入来自前端 decode raw fact、ROB/branch-spec/pending 状态摘要、RAS 状态摘要和
寄存器字段；输出喂给 `OooFrontendDispatchGate`、direct JAL/RAS update 逻辑以及后续
return-cont/PC mux。模块没有时钟、复位、寄存器或 ready/valid 状态。

不在本模块范围内：

- 不维护 RAS 栈或 return-cont buffer。
- 不产生 direct JAL/RET fire，也不选择 redirect PC。
- 不决定 dispatch payload 或 FIFO 行为。
- 不处理 pending JAL/JALR commit 后的 RAS 更新。

## 阶段 2a：协议规则

- Call-like JAL 只看 JAL raw 和 `rd in {x1,x5}`，不受 RAS 安全窗口影响。
- Direct RAS update safe 要求 ROB 为空、没有 stop-pending、没有 branch-spec
  active，也没有 branch-spec checkpoint pending。
- Direct return candidate 仅在 `ENABLE_DIRECT_RAS_RET` 为真时允许。
- Direct return candidate 要求 RAS safe、RAS reliable、RAS 非空、JALR `rd=x0`、
  `rs1 in {x1,x5}` 且 immediate 为 0。
- lane0 return 额外要求 lane0 已经是 dispatch0 jump；lane1 return 额外要求 lane1
  raw JALR。

## 阶段 2b：状态机

本模块无内部状态机，是纯 Mealy 组合网络。所有 RAS 可靠性、栈顶和后续 push/pop
状态仍由父模块与 `OooRasStack` 持有。

## 阶段 2c：不变量

- `head0_jal_call_raw_o == head0_jal_raw_i && rd0 in {x1,x5}`。
- `head1_jal_call_raw_o == head1_jal_raw_i && rd1 in {x1,x5}`。
- `ras_direct_update_safe_o` 只在 ROB count 为 0 且 stop/spec/checkpoint 均为 0 时为真。
- `dispatch0_return_o` 必须受 `ENABLE_DIRECT_RAS_RET`、lane0 jump、RAS safe、
  RAS reliable、RAS non-empty、`rd=x0`、`rs1 in {x1,x5}`、`imm=0` 全部约束。
- `head1_return_candidate_o` 必须受 `ENABLE_DIRECT_RAS_RET`、lane1 raw JALR、RAS
  safe、RAS reliable、RAS non-empty、`rd=x0`、`rs1 in {x1,x5}`、`imm=0` 全部约束。

## 阶段 2d：数据通路约束

- 两个 call-like JAL 输出是两个小寄存器比较器加 AND。
- RAS safe 是 ROB count zero compare 与三个 blocker 的 AND。
- lane0/lane1 return candidate 共用同一组 RAS 状态和 JALR hint 条件，各自只替换
  lane raw/fire 输入与寄存器字段。
- 输出全部组合直达，不增加周期延迟。

## 阶段 3：RTL 映射

RTL 文件为 `npc/rv64/vsrc/frontend/OooDirectRasCandidateGate.v`。单元测试
`tb_ooo_direct_ras_candidate_gate` 覆盖 JAL call-like raw、RAS safe 正例/阻塞项、
lane0/lane1 return candidate 正例与关键 blocker，并用禁用参数实例验证
`ENABLE_DIRECT_RAS_RET=0` 时 return candidate 被关闭。
