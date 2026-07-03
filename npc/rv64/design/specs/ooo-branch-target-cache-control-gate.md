# OooBranchTargetCacheControlGate 规格

> ⚠️ **状态(2026-07-03 RTL 重读)**:服务于恒空死存储——`capture_arm_o` 依赖 direct 分支拍内解析(`direct_branch_resolve_redirect && taken`),在 `OOO_ROB_WALK_MODE=1`+domain-A 下设计路径死,BTC 唯一填充路径断、表恒空(`OooBranchTargetCacheControlGate.v:44-49`);store 失效与 MISC_MEM 全清输出仍每拍工作,但维护对象是零消费的空表(消费端另被 `BRANCH_APPEND_DISPATCH_ENABLE=1'b0` 关死);拆除计划见 `../arch/ooo-core-architecture.md` §8.3。下文保留其设计语义描述。

## 阶段 1：需求

`OooBranchTargetCacheControlGate` 负责从 `OooFrontend` 中抽出 branch
target cache 上游的纯组合控制事实：

- LSU store fire 与 store address 透传（mem1 第二访存端口死硅删除后仅剩
  lane0 单源）。
- commit 侧 `MISC-MEM` 指令触发的 branch target cache 全失效请求。
- direct branch redirect 后，branch target capture buffer 的 arm 条件和 branch
  PC 选择。

输入均来自父模块已有组合事实或输出 ready/valid 结果；输出直接喂给
`OooBranchTargetCaptureBuffer` 与 `OooBranchTargetCache`。本模块没有时钟、复位、
寄存器或 ready/valid 状态。

不在本模块范围内：

- 不保存 branch target cache entry。
- 不判断 store 是否命中某个 target word。
- 不决定 capture buffer 的 pending/hit 清除时序。
- 不修改 direct branch resolve、RAS/BTB、PC/outstanding 或 commit/trap 时序。

## 阶段 2a：协议规则

- Store 侧协议采用父模块已经完成握手后的 fire 事实：
  `valid && ready && write`。
- store 源只有 mem0 单 lane（mem1 第二访存端口已删）；当 store fire 为 0 时，
  下游必须把 address 视为 don't-care。
- `invalidate_all` 是 commit 组合谓词，只检查当前提交指令 opcode 是否为
  `OPCODE_MISC_MEM`，保持旧 `fence/fence.i` 粗粒度失效语义。
- capture arm 只在 direct frontend flush、direct branch redirect、resolved taken、
  非 lane1-return capture、且 branch target fast dispatch 未消费该目标时有效。
- capture arm branch PC 在 direct lane1 branch fire 时选择 `head_pc1`，否则选择
  `head_pc0`。

## 阶段 2b：状态机

本模块无内部状态机，是纯 Mealy 组合网络。所有状态保留在父模块、
`OooBranchTargetCaptureBuffer` 与 `OooBranchTargetCache` 中。

## 阶段 2c：不变量

- `store_fire_o == mem_req_valid_i && mem_req_ready_i && mem_req_write_i`
  （单 lane）。
- `store_addr_o == mem_req_addr_i` 恒等透传。
- `invalidate_all_o` 只由 commit0/commit1 valid 且 opcode 为 `OPCODE_MISC_MEM`
  置位。
- `capture_arm_o` 不得在 lane1 return capture、branch target dispatch 已发生、
  resolve 未 redirect、resolve 未 taken 或 frontend 未 flush 时置位。
- `capture_arm_branch_pc_o` 只由 `direct_branch1_fire_i` 决定，不依赖 arm 是否有效。

## 阶段 2d：数据通路约束

- Store fire 是 mem0 单 lane 的握手 AND；store address 直接透传 mem0 地址。
- Invalidate-all 是两个 commit opcode compare 的 OR。
- Capture arm 是五个一位条件的 AND。
- Capture arm branch PC 是 lane1/lane0 PC 的 2:1 mux。
- 输出全部组合直达下游，不增加周期延迟。

## 阶段 3：RTL 映射

RTL 文件为 `npc/rv64/vsrc/frontend/OooBranchTargetCacheControlGate.v`。每条输出
都对应上述一条组合表达式；单元测试
`tb_ooo_branch_target_cache_control_gate` 覆盖 mem0 单 lane store、
commit0/commit1 invalidate、capture arm 正例和各 blocker，以及 lane1/lane0 branch
PC 选择。
