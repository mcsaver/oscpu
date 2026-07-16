# 规范：整数发射队列 OooIntIssueQueue

> 模块：`vsrc/scheduling/OooIntIssueQueue.v`(核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证。**T3M：整数 EX/MEM/long-op/FPWB 均 sticky-only**；
> **T3H：FP wake0/1 resident select 均已 sticky-only**；
> **2026-07-09 P5 刀 B:dispatch→issue 同拍 bypass 族已整体删除**
> (决策与数据见 `../arch/p5-repipeline-first-batch.md`、`../arch/timing-dispatch-issue-path.md` §6c)。

## 1. 目的与范围
保持队列内程序序的压缩式发射队列:每拍接收最多 2 条 dispatch uop、监听 2 个整数 writeback wakeup
+ 2 个 FP wakeup、发射最多 2 个**最老 ready** uop。容量 ENTRY_COUNT=8(`OOO_ISSUE_INDEX_W`=3)。
不负责寄存器读/执行(下游 ALU slice)、不负责 busy-table 状态(由 BusyTable,IQ 内缓存 src ready 位)。

## 2. 结构与时序
- 每项:valid/src1_ready/src2_ready/src preg/pdest/imm/ctrl/rob_idx/pc...,**按程序序排列**(新进尾)。
- **wakeup**:2 个 full整数 writeback + 2 个 FP wakeup pdest 广播,匹配 src preg → 置该 src ready。
  T3M 起所有整数 completion（EX/MEM/MulDiv/CLMUL/FPWB）只服务
  compaction/dispatch insertion/kill survivor 的 sticky ready：N 拍不得进入 resident select，
  N 沿粘住 ready，依赖项 N+1 才可选。T3D 起 FP execution
  completion口(wake0)只服务 FP-store fs2 的 sticky ready：N沿吸收、N+1才可选；T3H 起
  FP load WB口(wake1)也遵守同一边界，以切断 DCache→FP-store 同拍长锥。
- **select**:顺序扫描(oldest-first)选最老的 2 个 src1&src2 都 ready 的 uop → issue0/issue1。
  simultaneous valid 双 lane 的 enabled integer source 不可能 RAW：consumer 只能在 producer WB
  wakeup 后成为 ready；`RAW-I1` 在 backend 消费边界看护该不变量。current-result forward
  的 true arm 在合法状态不可达，但 2026-07-12 与 2026-07-13 两次 fresh 5ns 删除 A/B 均被
  物理证据拒绝。第二次虽让原 39 条 MIQ tail 退出 top40，仍使 WNS `-10.001→-10.182ns`、
  TNS 恶化18.5%、loops `109→142`、area/power 上升并暴露39条更差 FP exec1 tail。因此当前
  物理 mux 暂留，避免用 RTL 代码直觉覆盖映射实测；先切 long-op WB feedback 后再重评。
- **lane0 memory reservation（T3S/T3V）**：IQ 选中的 memory uop 只在 station
  有空 credit 时 pop，沿上原子锁存 ctrl/ROB/pdest/rs1 value/imm/store data；capture
  拍没有执行或请求。T3V 起 generic `issue0_*`/PRF/ALU0 只承载 raw non-memory，
  memory 驻留项用独立的 `captured rs1 + captured imm` AGU 和 captured store data 驱动
  LSU、SQ/MIQ/order、bridge request 与 MIQ metadata。station consume 必须且只能对应
  SQ-forward、failed-SC、精确异常、bridge fire 或 buffer capture 之一。
- **compaction**:发射后剩余项向前压实保持程序序紧凑。
- **dispatch→issue 时序(P5 刀 B,2026-07-09)**:dispatch 项当拍只写入阵列,**次拍(N+1)起
  才可被 select**——"dispatch 活值作虚拟队尾同拍参与 select"的 bypass 族(bypass 许可判定/
  活值 entry_ready/issue0 前递 forward/payload 直通臂)已整体删除。select 唯一真源=已寄存
  valid_q 项,由 `IQ-NO-BYPASS` 立即断言看护;mode 下 branch/JAL/JALR 原"禁旁路"特例随之
  普适化,pred_npc 恒取寄存 pred_npc_q(loop-free by construction)。full integer wake 与
  两路 FP wake 都只写 sticky state，不存在 completion→resident select 组合直通。
  backend 中仍有由 issue0_fire
  驱动的 current-result mux，但 RAW-I1 证明其 true arm 对合法双 lane 不可达；保留原因见上。
  历史:load-dependent-branch 快路径消费端已删(E7);旧 bypass 的 CPI 价值在现核已萎缩
  (CoreMark 10 迭代实测 +0.23%,见 §6 变更记录)。
- 误预测恢复=ROB-walk:按 `kill_rob_idx` 环形年龄 squash 更年轻项,recover 期冻结发射
  (存活前缀同拍继续吸收 wakeup 防漏唤醒);checkpoint 影子阵列在 `OOO_ROB_WALK_MODE=1` 下
  capture/restore 恒被 gate,为死硅(fp 新增字段亦不进影子)。

## 3. 不变量
- **IQ-I1 程序序**:select 与 commit 对齐程序序;issue1 不早于 issue0(同拍两发保持相对序)。
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
- **IQ-I7 双 lane 无 RAW(`RAW-I1`，backend 消费边界)**:issue0/issue1 同时 valid 时，
  issue1 任一 enabled integer source preg 不得等于 issue0 非零 integer pdest。该合同依赖
  无 dispatch bypass/early-result wakeup；FP destination domain 与 invalid/default payload 排除。
- **IQ-I8 integer sticky-only（`IQ-INT-WAKE-STICKY-ONLY`）**：任一 issued integer source
  必须在沿前已有对应 `src*_ready_q`；full pulse 不得在本拍把尚未 ready 项选出，但必须在
  compaction、dispatch insertion 与 kill-survivor 全部 next-state 路径粘住 ready，下一拍可选。
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

## 5. 验证
- 模块 TB `tb_ooo_int_issue_queue`(N+1 发射口径契约,含 kill/recover/flush/唤醒吸收);
  上层集成 TB `tb_ooo_dispatch_backend`/`tb_ooo_int_backend`/`tb_ooo_alu_decode_backend`
  已同步 N+1 时序。契约立即断言:IQ-NO-BYPASS/IQ-KILL-NO-DISPATCH(负测试证据存
  `.github/task-runs/2026-07-09-p5-first-batch/`)。
- `tb_ooo_int_backend` 常驻三 uop 场景：P 写 x7，依赖者 A 与 P 同拍 dispatch，P issue
  拍再 dispatch 依赖者 C；P WB 拍 A/C 均不得 select，N 沿 sticky 后在 N+1 分别落到
  issue0/issue1，检查 issue1 从已落账 PRF 取得 P 的 64-bit 值。`RAW_I1_NEGATIVE_PROBE` 在合法
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
