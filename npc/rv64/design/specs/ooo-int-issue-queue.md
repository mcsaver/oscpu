# 规范：整数发射队列 OooIntIssueQueue

> 模块：`vsrc/scheduling/OooIntIssueQueue.v`(核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证。**T3M：整数 EX/MEM/long-op/FPWB 均 sticky-only**；
> **T3H：FP wake0/1 resident select 均已 sticky-only**；
> **2026-07-09 P5 刀 B:dispatch→issue 同拍 bypass 族已整体删除**
> (决策与数据见 `../arch/p5-repipeline-first-batch.md`、`../arch/timing-dispatch-issue-path.md` §6c)；
> **2026-07-15 R3/R3.1：按执行能力动态分配 Universal/ALU terminal；registered
> Universal owner 占用时允许独立 ALU terminal 继续前进**；
> **R3.2：仅对 actual-fire 的 fixed GPR producer 生成 lookahead sticky wake，consumer
> 下一拍从 registered EX payload 前递，PRF 仍为 stored-only**；
> **R3.3：已冻结 packed-age balanced-select 合同，RTL/验证待本轮候选落地**；
> **R3.4：已冻结 ALU terminal true-by-construction 物理裁剪合同，待 R3.3 后实施**。
> **v8f：已冻结 ProducerId 单一 holder 合同，RTL 落地中；raw ROB index 将只由 PID 低位派生**。

## 1. 目的与范围
保持队列内程序序的压缩式发射队列:每拍接收最多 2 条 dispatch uop、监听 2 个整数 full-WB wakeup
+ 2 个 fixed-producer actual-fire early wakeup + 2 个 FP wakeup、发射最多 2 个**最老 ready** uop。容量 ENTRY_COUNT=8(`OOO_ISSUE_INDEX_W`=3)。
不负责寄存器读/执行(下游 ALU slice)、不负责 busy-table 状态(由 BusyTable,IQ 内缓存 src ready 位)。

## 2. 结构与时序
- 每项:valid/src1_ready/src2_ready/src preg/pdest/imm/ctrl/producer_id/pc...,**按程序序排列**
  (新进尾)。v8f 起 full ProducerId 是 holder 单一真源，raw `rob_idx` 只取其低位用于年龄/地址；
  compaction、dispatch insertion、kill survivor 与 issue payload 必须原子携带完整 ID。
- **wakeup**:2 个 full整数 writeback + 2 个 fixed-producer actual-fire early wakeup +
  2 个 FP wakeup pdest 广播。全部只写 compaction/dispatch insertion/kill survivor 的
  sticky next-state，绝不进入当拍 resident select。R3.2 early wake 仅在 producer actual fire
  时产生；N 沿同时粘住 consumer ready 并寄存 `{valid,pdest,data}`，consumer N+1 只从该
  registered EX payload 前递。memory/AMO、MulDiv、CLMUL、CSR、FP、control-flow、
  system/exception 类 fail-closed，仍由 formal WB 唤醒。T3D 起 FP execution
  completion口(wake0)只服务 FP-store fs2 的 sticky ready：N沿吸收、N+1才可选；T3H 起
  FP load WB口(wake1)也遵守同一边界，以切断 DCache→FP-store 同拍长锥。
- **select/steering**：顺序扫描已寄存阵列，最多选择两个 ready uop，动态分配给
  Universal terminal（物理 `issue0`）和 fixed-latency ALU terminal（物理 `issue1`）。
  older complex + younger simple 保持自然分配；older simple + younger complex 则做 capability
  swap，让 older simple 到 ALU terminal、younger complex 到 Universal terminal。dispatch
  包位置不形成静态 lane 归属，物理 terminal 编号也不表示程序年龄。simultaneous valid
  双 terminal 的 enabled integer source 不可能相互 RAW：early wake 也只在沿上写 sticky，
  consumer 最早下一拍 select；backend 的双向 RAW 断言看护该不变量。R3.2 仅增加
  registered-EX forward，不恢复 issue-current-result 组合旁路。此前 2026-07-12 与
  2026-07-13 两次 fresh 5ns 删除 A/B 均被
  物理证据拒绝。第二次虽让原 39 条 MIQ tail 退出 top40，仍使 WNS `-10.001→-10.182ns`、
  TNS 恶化18.5%、loops `109→142`、area/power 上升并暴露39条更差 FP exec1 tail。因此当前
  物理 mux 暂留，避免用 RTL 代码直觉覆盖映射实测；先切 long-op WB feedback 后再重评。

### 2.1 R3.3 packed-age balanced-select 合同（RTL 前冻结）

R3.2 fresh exact-5ns 表明 top40 全部由 `valid_q[0]` 经串行 scan 发往 EX stage；同起点
R2.5/R3.2 定向 STA 中，EX0 总路径退化 `1.093676 ns`，而 IQ 内段单独退化
`1.200654 ns`。R3.3 只替换选择拓扑，不改端口、状态容量、issue latency 或 owner 语义：

- **紧凑年龄前提**：任意非 reset 拍，`valid_q[i] == (i < count_q)`。normal compaction、
  dispatch append 与 ROB-walk suffix kill 都只能生成有效前缀；新增 `IQ-PACKED-AGE`
  立即断言及可编译 hole mutation，禁止拿未证明的 packed 假设换时序。
- **并行 eligibility**：每项只由其寄存 `valid/src-ready/fp-ready/capability/ctrl` 与全局
  `issue_mem_block` 形成 base-ready。沿用当前单 memory-reservation 排序：memory index0
  可候选；index1 只在无 registered Universal owner、index0 本拍 ready 且 ALU-capable 时
  候选并与 index0 原子成对；index>=2 memory 保守等待。该式是当前逐项
  `older_valid_seen/older_multiple_valid_seen` 在 packed 不变量下的精确化简，不放宽一般
  memory 越序；R4 LQ/双 memory 集成会用独立合同替换它。
- **三个 one-hot 事实**：平衡前缀网络并行产生 `A=first-ready`、`B=second-ready`、
  `S=first-ready-ALU`，不在 for-loop 中让较年轻项组合依赖较老项的可变 index。
  无 owner 时：`A=complex` 则 `{Universal,ALU}={A,S}`；`A=ALU,B=ALU` 则 `{A,B}`；
  `A=ALU,B=complex` 则 `{B,A}` 且 swap=1；只有 A 时只发 A。owner=1 时 Universal
  不输出 valid，ALU 只取 S。该真值表与 R3.1 oldest-first scan 集合/能力完全等价。
- **payload/compaction**：terminal select 保持 one-hot 到 payload mux；binary index 只作
  compaction、age assertion 与 observability。issue fire 仍是 valid&&ready，swapped younger
  memory capture 仍蕴含 older ALU 同拍 fire；不增加 issue register，不改变 R3.2 producer
  N fire→consumer N+1 fire/registered-forward 边界。

六类接口合同不变：valid/ready 与 payload ownership 不变；stall 只冻结未 fire entry；
`rst/flush > kill > normal compaction/dispatch`，kill survivor 继续吸收 wake；异常仍只由 ROB
精确提交；当前 memory 顺序不放宽；capability、年龄与 operand-ready 的单一真源仍是 IQ Q。
预计关键路径为 `ready Q -> 3-level associative prefix -> one-hot terminal mux -> PRF`；禁止
通过静态 lane、false path 或新增流水拍取得时序。

### 2.2 R3.4 ALU terminal true-by-construction 合同（RTL 前冻结）

R3.1 起 `issue1` 的规范能力只含 fixed-latency simple ALU/IMM，但当前 backend 仍实例化第二个
`OooBitmanipGate` 和通用 WBU；综合器无法从独立 capability metadata 推出 wide ctrl 的蕴含，
所以语义不可达电路仍占面积。R3.2 fresh stat 中 `OooBitmanipGate` 单实例 logic-area proxy
约 `12,746.16`，而 R3.2 已因 area ratio `0.9975046 < 0.999` 无法晋级。R3.4 将物理电路
与已冻结能力边界对齐，不改变 IQ 可选集合：

- 删除 ALU terminal 的 bitmanip/CLMUL、MulDiv、branch/JAL/JALR、memory/AMO/exception
  结果臂；这些类别继续由 dynamic steering 送 Universal，不能被丢弃或静态绑定到程序 lane。
- ALU terminal 只保留两类 WB：`WB_SEL_ALU` 取完整 RV64I ALU（含 word/sign、PC/imm operand
  选择，故 AUIPC 等不退化），`WB_SEL_IMM` 取 imm（LUI）；EX payload 的 exception/cause/tval
  结构常零，actual-fire/ROB/pdest/result/early-wake 时序不变。
- `IQ-ALU-TERMINAL-CAPABILITY` 与 backend `INT-ALU-TERMINAL-CAPABILITY` 必须继续在物理
  边界检查原始 ctrl。裁剪不是容错：若上游让非 capable uop 到 issue1，必须 fail closed，
  不得静默用 ALU 结果完成。

无端口、寄存器、FSM、flush/stall/retire/memory-order 变化；共享 Universal 的复杂执行资源
保持完整。该切片要求 focused capability mutation、module/full functionality 与 fresh mapped
area/STA；只有真实 netlist 证明第二 bitmanip 实例消失且功能门全绿，才可记面积收益。
- **Universal memory reservation（T3S/T3V/R3.1）**：IQ 选中的 memory uop 只在 station
  有空 credit 时 pop，沿上原子锁存 ctrl/ROB/pdest/rs1 value/imm/store data；capture
  拍没有执行或请求。T3V 起 generic `issue0_*`/PRF/ALU0 只承载 raw non-memory，
  memory 驻留项用独立的 `captured rs1 + captured imm` AGU 和 captured store data 驱动
  LSU、SQ/MIQ/order、bridge request 与 MIQ metadata。station consume 必须且只能对应
  SQ-forward、failed-SC、精确异常、bridge fire 或 buffer capture 之一。reservation Q
  作为 `universal_owner_present_i` 占有 Universal terminal 时，不得把整个 IQ 冻结：
  raw issue0 必须 quiet，scan 仍把最老 ready、ALU-terminal-capable resident 分配到 issue1，
  包括 IQ 中只有这一项的场景；complex/memory 项仍留队。owner 只能来自
  `mem_issue_res_valid_q` 等寄存状态，禁止接 capture/ready/credit 等组合事实。
- **compaction**:发射后剩余项向前压实保持程序序紧凑。
- **dispatch→issue 时序(P5 刀 B,2026-07-09)**:dispatch 项当拍只写入阵列,**次拍(N+1)起
  才可被 select**——"dispatch 活值作虚拟队尾同拍参与 select"的 bypass 族(bypass 许可判定/
  活值 entry_ready/issue0 前递 forward/payload 直通臂)已整体删除。select 唯一真源=已寄存
  valid_q 项,由 `IQ-NO-BYPASS` 立即断言看护;mode 下 branch/JAL/JALR 原"禁旁路"特例随之
  普适化,pred_npc 恒取寄存 pred_npc_q(loop-free by construction)。full integer、R3.2 early
  与两路 FP wake 都只写 sticky state，不存在 completion/fire→resident select 组合直通。
  backend 的源值选择只读取 PRF stored state 或上一沿 registered EX payload，不存在
  issue-current-result 组合 mux。
  历史:load-dependent-branch 快路径消费端已删(E7);旧 bypass 的 CPI 价值在现核已萎缩
  (CoreMark 10 迭代实测 +0.23%,见 §6 变更记录)。
- 误预测恢复=ROB-walk:按 `kill_rob_idx` 环形年龄 squash 更年轻项,recover 期冻结发射
  (存活前缀同拍继续吸收 wakeup 防漏唤醒);checkpoint 影子阵列在 `OOO_ROB_WALK_MODE=1` 下
  capture/restore 恒被 gate,为死硅(fp 新增字段亦不进影子)。

## 3. 不变量
- **IQ-I1 选择集合、能力与架构序**：无外部 owner 时，选择集合必须来自 oldest-first
  扫描遇到的前两个 eligible ready resident；物理 terminal 分配可因能力 swap 而反转年龄。
  Universal owner 已占用时只选择最老 eligible ALU-capable resident 到 ALU terminal。
  terminal 编号不代表程序序，最终架构序只由 ROB in-order commit 保证。
- **IQ-I2 唤醒优先**:dispatch 撞同拍 wakeup 时,写入阵列的 ready 位必须吸收该唤醒
  (写臂 OR wakeup_match),避免漏唤醒;kill 拍幸存前缀同拍继续吸收 wakeup。
- **IQ-I3 容量**:dispatch ready 严格按空位;compaction 不丢项/不重排乱序。
- **IQ-I4 无组合环**:ready/fire 前向不得形成 ready→valid→ready 回边(历史踩坑:branch
  append optional 曾因此 UNOPTFLAT/不收敛,见记忆 2026-05-29)。P5 刀 B 后 dispatch 活值
  已整体退出 select 锥,该回边结构性不存在。
- **IQ-I5 select 真源(P5 刀 B 新增,`IQ-NO-BYPASS` 立即断言)**:issue lane 选中的槽位
  必须是 valid_q=1 的寄存项;dispatch 活值不得当拍参与 select。
- **IQ-I6 kill 拍无 dispatch(`IQ-KILL-NO-DISPATCH` 立即断言)**:kill_valid_i 拍上游不得
  发 dispatch valid——上游 OooDispatchBackend 用与 kill_valid_i 同源的寄存 kill_valid_q 生成
  dispatch_freeze。这是"当拍 dispatch 写入+同拍 kill"窗口结构性不存在的承重契约:IQ kill
  分支不消费 valid_next_r 写入计划,互斥被破坏时新写项会被静默丢弃。
- **IQ-I7 双 terminal 双向无 RAW（backend 消费边界）**：issue0/issue1 同时 valid 时，
  任一 terminal 的 enabled integer source preg 均不得等于另一 terminal 的非零 integer
  pdest。能力 swap 后 terminal 编号可与年龄相反，故只做 issue0→issue1 单向检查不充分。
  该合同依赖无 dispatch bypass且 early wake 不进入同拍 select；FP destination/default payload 排除。
- **IQ-I8 integer sticky-only（`IQ-INT-WAKE-STICKY-ONLY`）**：任一 issued integer source
  必须在沿前已有对应 `src*_ready_q`；full 与 R3.2 early pulse 均不得在本拍把尚未 ready 项
  选出，但必须在 compaction、dispatch insertion 与 kill-survivor next-state 粘住 ready。
- **IQ-I9 FP 跨域 sticky-only**：`fp_wake0/1` 均不得进入 resident select 的组合 ready
  视图。compaction、dispatch insertion 与 kill survivor 必须继续把两者 OR 入
  `fp_st_ready_q`；dispatch insertion 必须由 IQ 自身捕获，不能隐式依赖上游 query 前视。
- **IQ-I10 memory 单一 owner（T3V）**：raw memory 只能 capture、不能成为 generic
  issue owner；reservation valid 时 raw lane0 冻结且 generic `issue0_valid/fire` 为 0。
  memory class、EA/LSU、SC reservation address、SQ/order、request valid/fire、MIQ
  `{rob,pdest,fp,size,unsigned,addr,wdata,wstrb}` 以及 pending/buffer 快照均只允许读取
  `mem_issue_res_*_q`（外加全局资源/顺序状态），禁止读取 raw IQ/PRF/ALU0。
  flush/restore/younger branch kill 仍在任何 memory side effect 前清 station；station
  已把 owner 交给 plain-memory buffer 后，ROB-walk 也必须按同一环形年龄选择性清除
  尚未 fire 的 younger buffer。若 buffer 在 kill 同拍 fire，则 owner 只能移交给 MIQ，
  并由 MIQ 的 same-cycle push-kill 标记静默回收。AMO/LR/SC 的 ROB-head 与独占语义不变；
  LR reservation 同时记录 address 与 size，SC 必须两者均匹配才可能成功，且任意被消费的
  SC（成功、失败或本地精确异常）都必须使 reservation 失效。
- **IQ-I11 request/MIQ 双射（T3V 审查补强）**：每个 bridge request fire 必须且只能
  产生一个 MIQ push。当前 MIQ 在 old-full 状态不支持 tail=head 的同拍 pop/refill，故
  parent credit 在 `miq_full` 拍必须为 0，即使该拍已有 response pop；下一拍空位可见后
  再接受请求。禁止用 `full || pop` look-through 造成桥已接收而 metadata 未入队。
- **IQ-I12 翻译后 device owner（T4M）**：`issue0_mem_mmio_w` 只按 VA 作明显 MMIO 的
  早期排序提示，不是最终 device 分类。bridge 用最终授权 PA 识别 device read 后必须等待
  `mem_req_device_release`；该信号仅在 MIQ head 有效、未 kill 且其 ROB tag 等于 ROB head 时
  为 1。MIQ head 被 ROB-walk 标记 killed 时必须抬 `mem_req_device_cancel`，使尚未发 AR 的
  device request 无总线 side effect 地 quiet 回收。release/cancel 必须互斥；普通 translated
  PMEM load 不得受这两个 sideband 串行化。
- **IQ-I13 registered Universal owner（R3.1）**：`universal_owner_present_i=1` 时选择器
  必须把 Universal terminal 视为已占有，但 `issue0_valid_o` 必须保持 0，不能用默认 index
  产生假 owner。issue1 只允许选择最老 `alu_terminal_capable_q` resident，可在 issue0
  不 fire 时独立保持、fire 和 compaction；owner 不得被 IQ pop/修改。owner 清零后，
  剩余项恢复普通动态 steering。
- **IQ-I14 swapped-memory 原子 capture（R3.1，P0）**：若 capability swap 令 younger
  memory 位于 Universal terminal、older ALU 位于 ALU terminal，则 memory pop/capture
  必须蕴含 older ALU 同拍 fire。ready bits 按 `{Universal-base-ready, ALU-ready}`：
  `00` 两项保持；`01` 只允许 older ALU 离队；`10` 必须阻止 orphan memory；
  `11` 才允许双离队。MMIO/head gate 可继续延迟 reservation consume，但不得反向丢失、
  replay 或复制 older ALU。
- **IQ-I15 capability metadata 守恒（R3）**：`alu_terminal_capable_q` 必须随 dispatch
  insertion、compaction、kill survivor 原子移动；issue1 永远只读 capability=1 的 resident。
  `issue_pair_swapped_o` 只在两项均 valid 且物理 terminal 年龄反转时有效；两 terminal
  不得引用同一 IQ index。
- **IQ-I16 R3.2 early-wake allow-list 与数据边界**：early valid 必须蕴含对应 terminal
  actual fire、非零 GPR pdest、fixed ALU/IMM WB 类；memory/AMO、MulDiv、CLMUL、CSR、FP、
  control-flow、system/exception 类必须 fail-closed。consumer N+1 只读上一沿 registered
  EX payload；PRF 不增加 current-result write-through，payload 失配后回落 formal WB/PRF state。
- **IQ-I17 packed-age / balanced-select 等价（R3.3）**：valid 必须是长度 `count_q` 的前缀；
  one-hot A/B/S 不得重复，A/B 是 eligibility 集合中程序序前两项，S 是最老 ALU-capable
  项；terminal 真值表必须满足 IQ-I1/I13/I14/I15。reference scan checker 与 directed
  matrix 必须逐周期比较 `{valid,index,swap}`，任一差异立即失败。
- **IQ-I18 ProducerId holder（v8f）**：每个 valid entry 只保存 full ProducerId；dispatch raw idx
  必须等于 PID 低位，issue raw idx 必须从同一 PID 低位派生。stall/compaction/kill survivor 不得
  截断或串 lane；PID 不得进入 eligibility/select/ready 锥。

## 4. 关键路径
P5 刀 B 前,dispatch→issue bypass 把 free-list 分配+busy 查询+IQ select **单拍合一**
(Vivado OOC 39 级最深链;2026-07-09 全核 OpenSTA 中又是 19.8ns/240 级巨型路径的缝合段)。
刀 B 后 dispatch 锥与 issue 锥解耦；T3M 又把 wake CAM 从 select 锥移到 state-D 更新，IQ
前向路径只剩已寄存 valid/ready 的 oldest-first scan + payload 直读。顺序扫描 select 仍随
ENTRY_COUNT 增深(故 iter2 撤回 IQ 8→16 扩容)。

T3V 前的 memory 驻留项虽已跨过一拍边界，执行拍仍回灌 generic `issue0` payload mux 并
复用 ALU0，fresh what-if top40 因而形成 `IQ select → PRF → ALU0 → request/MIQ D`
（WNS `-1.303 ns`）的真实组合锥。T3V 的 reservation-only AGU/metadata 数据面物理切断
该锥；是否闭合 5 ns 必须由 fresh 综合/STA 判定，功能仿真不得越级声明 200 MHz。

R3.2 fresh netlist 的新 top40 为 IQ→EX0/EX1：EX0 worst `-0.433356017 ns`，EX1
`-0.424952984 ns`。同 `valid_q[0]` 起点的 R2.5 IQ 边界约 `0.996/1.180 ns`，R3.2
退到 `2.196/2.333 ns`，证明串行 dynamic-swap scan 是主导回退。40 条中 16 条到 EX0、
24 条到 EX1，仅 3 条显式经过 bitmanip0；WBU 段仅约 `0.116–0.154 ns`，所以先改 WBU 或
撤 registered forward 均不是根因修复。R3.3 晋级要求不仅 WNS>=0，还须 worst slack
>=`+0.10 ns`；focused/OOC 的层数下降只能筛选，不能替代 fresh full-chip 两轮综合/STA。

## 5. 验证
- 模块 TB `tb_ooo_int_issue_queue`(N+1 发射口径契约,含 kill/recover/flush/唤醒吸收);
  上层集成 TB `tb_ooo_dispatch_backend`/`tb_ooo_int_backend`/`tb_ooo_alu_decode_backend`
  已同步 N+1 时序。契约立即断言:IQ-NO-BYPASS/IQ-KILL-NO-DISPATCH(负测试证据存
  `.github/task-runs/2026-07-09-p5-first-batch/`)。
- `tb_ooo_int_backend` 常驻三 uop 场景：P 写 x7，依赖者 A 与 P 同拍 dispatch，P actual-fire
  拍再 dispatch 依赖者 C；A/C 下一拍分别落到 issue0/issue1，并从 registered EX payload
  取得 P 的 64-bit 值。另有 64 级 RAW 链逐级检查 producer N fire→consumer N+1 fire、
  EX hit 与 commit 结果 1..64。`RAW_I1_NEGATIVE_PROBE` 在合法
  双 lane 上做消费边界 source-tag mutation，必须只触发 RAW-I1 且 runner 非零。
- 集成 riscv-tests/AM(数据相关唤醒、双发射、load-use、分支恢复);
  代表:branch-resolve-loop/ooo-mem-order(读写交替+唤醒时序)。
- T3V 定向反例在 bridge stall 下让 younger raw ALU 计算 `9`，同时要求 resident
  memory AGU/request/MIQ address 恒为 captured `0x80000310`、MIQ ROB 恒为 captured ROB，
  且 memory consume 与 generic issue0 fire 互斥；station 释放后还必须观察该 younger
  ALU exactly-once fire/commit=`9`，不能只读取 invalid generic payload。定向测试另覆盖
  younger buffered memory 的 selective kill、MIQ full+pop 一拍 backpressure、
  LR.W/SC.D 与 LR.D/SC.W size mismatch 失败、matching misaligned SC 异常后 reservation
  清除。另跑 `tb_ooo_int_issue_queue` 与 `rv64ua-p-lrsc`，覆盖 oldest promotion、
  LR/SC head/retry 和 side-effect 守恒。
- R3 定向 pair matrix 覆盖 `ALU+{branch,JAL/JALR,load,store}` 的两种程序位置；每例必须
  同拍双 terminal fire，不能用串行 promotion 冒充。R3.1 standalone IQ 覆盖 swapped
  ready `00/01/10/11` 与 registered owner + sole ALU；集成 TB 覆盖 held reservation
  期间 sole ALU 从 issue1 exactly-once fire/WB，以及 older ALU + younger MMIO 的原子
  capture/head release，无 early device request、无 replay/duplicate。真实 iterative DIVU
  加 8 条独立 younger ALU 还必须得到 younger formal-WB mask `ff`、ROB old+8 occupancy、
  9 条程序序 retire 和 ROB/IQ/free-list 全恢复。上述是模块级功能证据，不替代 Linux、
  fresh 综合或 STA。

## 6. 变更记录
- 2026-06-28：逆向文档化(压缩程序序队列/2 唤醒/2 oldest-ready 发射/dispatch 旁路/快路径/不变量)。
- 2026-07-09：**P5 刀 B**——dispatch→issue 同拍 bypass 族整体删除(约 300 行),select 唯一
  真源=寄存阵列项;新增 IQ-I5/IQ-I6 不变量与对应立即断言;TB 契约重写为 N+1 拍口径。
  S0 CPI 数据:CoreMark 10 迭代 bypass-off 仅 +0.23%(10,267,729→10,291,429 cycles),
  历史 +5.5% 为老核数据已失效。决策链:`../arch/p5-repipeline-first-batch.md`、
  `../arch/timing-dispatch-issue-path.md` §6c.1。
- 2026-07-12：新增 IQ-I7/RAW-I1、三 uop WB-wakeup→issue1 PRF 活路径回归与消费边界
  负探针。物理删除实验因 WNS 无改善且 TNS/area/power 回退被拒绝，forward 与 PRF
  WB write-through 均保留；证据见
  `.github/task-runs/2026-07-12-rv64-t3a-dead-crosslane-forward/`。
- 2026-07-13：因 current A top40 的40条路径均实际经过旧 mux，做唯一 RTL 差异 retry；
  focused/module/CoreMark 全绿且旧 arc 真实消失，但 full-chip WNS/TNS/loops/area/power 再次
  全面回退，候选还原。109-loop root 已收敛为108条 long-op full-WB feedback +1条 FP admission
  SCC；T3B 随后让 EX/MEM fast broadcast 参与同拍 select，T3G 又根据 fresh DCache 路径
  将其收紧为 EX-only；full wakeup 始终粘入 IQ state。
  证据 `.github/task-runs/2026-07-13-rv64-t3a-current-top-retry/`。
- 2026-07-13 T3D：FP admission 拆环后 full Verilator 暴露 `FP completion→FP-store
  same-cycle select→branch kill→FP completion` 分支；execution wake0 改为 sticky-only、
  load wake1 保留快路，合同见
  `ooo-cross-domain-wakeup.md`。
- 2026-07-13 T3H：T3G fresh STA 证明 load wake1 快路形成 DCache→FP-store→全核 top1；
  wake1 改为 resident sticky-only，两个 dispatch lane 在 IQ 内显式捕获 wake0/1 collision，
  并与 FP PRF R3 stored-only 原子落地。统一合同见
  `ooo-fp-sticky-wakeup-barrier.md`。
- 2026-07-13 T3M：T3L top40 全部从 `ex0_valid_q` 经 EX fast wake/select/PRF/双 ALU
  到 CsrFile；物理删除 `select_wakeup*`，所有整数 full WB 改为沿上 sticky、N+1 select。
  统一合同见 `ooo-ex-sticky-wakeup-barrier.md`。
- 2026-07-14 T3V：lane0 memory reservation 的执行数据面与 generic issue0/ALU0
  物理解耦；memory classification、dedicated AGU/LSU、SQ/order、request/MIQ metadata、
  pending/buffer 与本地 exception/forward/failed-SC completion 均改为 reservation Q
  单一真源。独立审查随后补齐 post-reservation buffer 的 selective branch kill、
  old-full MIQ 禁止 pop/refill look-through、LR reservation size 匹配，以及任意 SC
  consume 清 reservation 的生命周期合同与定向反例。
  功能门禁通过后仍须 fresh STA 才能裁决 200 MHz。
- 2026-07-15 R3/R3.1：每项新增 ALU-terminal capability metadata；选择器可在
  older simple + younger complex 时动态交换 Universal/ALU terminal，并给出显式
  `issue_pair_swapped`。registered memory reservation 作为 Universal owner 时，sole
  ready ALU 仍可从独立 terminal 前进。swapped younger memory 的 capture 追加
  `issue1_fire` 原子前件，避免 orphan reservation；消费边界 RAW 改成双向。该候选不
  新增 PRF port/FU，不恢复 completion→select 或 dispatch bypass，也不宣称解决一般
  non-alias load/store 越序。
- 2026-07-15 R3.2：IQ 保存 fixed-GPR-producer metadata，并仅由两路 terminal actual fire
  产生 early sticky wake；EX payload 增加 registered valid，两路 terminal 对四个整数源
  tag-match forward。定向覆盖 64 级连续 RAW、dual producer/consumer、stall、kill/flush，
  以及 load/AMO/MulDiv/CLMUL/CSR/FP/branch/illegal 排除矩阵。只建立功能候选，不替代
  fresh synthesis/STA/power 与 benchmark A/B。
