# V9A DI-2 RTL / 验证派生记录

## Phase 1：需求解码

- 规范真源：`rv64-architecture-ppa-contract.md` DI-2 与 `ooo-core-architecture.md` §8.5。
- 必须证明七个边界的 64-cycle 非真空双宽轨迹及独立 ALU IPC，不接受静态双 lane 外形或一次峰值。
- 当前唯一缺失的架构 directed record 是 `width_continuity`；其余八项绑定同一生产 RTL design_id。
- 初始分类为验证/证据闭合；尚无证据说明生产 RTL 需要修改。

## Phase 2a：调用链与数据流

`fetch response -> OooFetchPacketDecode -> OooFetchPacketFifo -> OooFrontendBackendDispatchMux -> OooAluDecodeBackend(DecodeStage x2) -> OooIntBackend -> OooDispatchBackend(RenameMap/FreeList/BusyTable/ROB/IQ) -> OooIntIssueQueue -> physical terminal 0/1 -> ALU result -> PipeStageReg EX0/EX1 -> WB -> OooRob done -> dual commit`。

decode→rename→dispatch 是零寄存融合链；Dispatch→Issue 是 IQ 弹性边界，EX→WB 是显式刚性边界，Execute→Retire 由 ROB 解耦。观测点详见 `contract.md` §2。

## Phase 2b：状态、holder 与 owner

- 生产状态 owner 不变：FetchPacketFifo、RenameMap、FreeList、BusyTable、ROB、IQ、EX stage、PRF。
- 新增状态只存在于 focused testbench 的计数器和 PC/full-ProducerId 账本，仿真结束即消失，不进入综合 source set。
- dispatch 前身份为 PC 与由 PC 派生的 `{inst,rd,imm,expected_data}`；ROB allocate 后身份为 full ProducerId。active PID table 允许旧生命周期退休后复用，但每一条 issue/execute/retire 必须回指当前 allocation instance，按 `allocated->issued->executed->retired` exactly-once 转换。
- RenameMap 更新、ROB 接纳与 IQ 接纳使用各自模块内部 sink witness；父级 `dispatchN_fire_w` 不能单独代表三个 owner 都已接纳。EX up-side capture 还要与下一拍 stage down-side授权 WB 对账。
- EX0/EX1 另有 previous-cycle ledger，逐 lane 保存 capture 的 full ProducerId、pdest、result、exception、cause、tval 与 forwarding-valid；下一拍直接核对 `PipeStageReg` down-side 字段，再独立核对 WB→ROB completion sink，禁止仅凭同拍 valid 或全局生命周期间接推断 stage payload 正确。
- 结束时验证 FIFO/outstanding/ROB/IQ/EX holder 与 free-list 守恒，禁止 flush 代替 drain。

## Phase 2c：控制、异常与访存排除

- 指令只用合法 RV64I `ADDI rd,x0,imm`；没有 branch/JAL/JALR/system/trap。
- 没有 load/store/AMO；memory request 必须保持 0。
- 窗口内 redirect/stop/flush/recovery/exception 都是反例，不是被忽略的 don't-care。

## Phase 2d：时序与取样语义

- testbench 在每个上升沿前的稳定组合点读取 actual fire，随后推进时钟；同一事件不跨两个周期重复计数。
- reset 释放后的首个 fetch request fire 是唯一 cycle 0；固定预热 24 周期，随后连续 64 周期要求每级恰为 2，不搜索、等待或挑选最有利子窗口。另用第 17 测量拍的单拍 request-admission stall 负探针证明窗口不能滑动。
- 采样结束关闭新 request admission，保留现有 response ready 和 commit ready，直到所有 holder 自然排空。

## Phase 2e：反例与可观测性

- 指令 immediate/PC/rd 随地址变化；scoreboard 在各边界核 `{inst,rd,imm,expected_data}`，避免两 lane payload 相同或只核 PID 导致连接错误不可观测。
- 11 项 compile-success RTL verification mutations 分别破坏七级宽度、ROB/IQ 独立 sink、EX capture、EX1 full payload、WB sink 和 lane1 immediate payload；每个变异必须产生独立 witness。`ex1_stage_payload_alias` 保持 valid 但把 EX1 stage payload 接为 EX0，专门关闭同拍-valid 假绿路径。
- release/assert 各输出 64 条 canonical cycle trace，builder 计算并比较相同的 trace digest。
- parser/unit tests 覆盖 boundary key 缺失、总数 121、peak 1、IPC 低于 1.90、重复 marker、错误 design binding 和 mutation aggregate 漂移。

## Phase 3：实现决策

第一步只添加 focused TB、永久命令、evidence builder 与 fail-closed checker。生产 RTL 保持字节不变。首轮 baseline 已在七边界达到 exact 2.000，因此没有扩大生产 RTL 写范围。独立审查指出 EX stage full-payload 前后拍对账及 adjacent-regression TB provenance 两项证据缺口；两者只通过 testbench ledger、额外 source mutation 与 exact source inventory 修正，不改设计。

## Phase 4：验证顺序

1. baseline release / assert focused simulation；
2. compile-success RTL verification mutation matrix；
3. 相邻 frontend/decode/dispatch/IQ/backend/ROB regressions；
4. evidence builder 单元测试与 architecture checker 单元测试；
5. 同 design_id 重建八个 sibling records；
6. 发布 DI-2 record，运行九项 architecture hard gate；
7. implementer/reviewer 双人格复核、task-run 索引、DB memory、npc-dev e2e 与 strict guard。
