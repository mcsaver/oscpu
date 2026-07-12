# 规范：整数发射队列 OooIntIssueQueue

> 模块：`vsrc/scheduling/OooIntIssueQueue.v`(核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证。**2026-07-09 P5 刀 B:dispatch→issue 同拍 bypass 族已整体删除**
> (决策与数据见 `../arch/p5-repipeline-first-batch.md`、`../arch/timing-dispatch-issue-path.md` §6c)。

## 1. 目的与范围
保持队列内程序序的压缩式发射队列:每拍接收最多 2 条 dispatch uop、监听 2 个整数 writeback wakeup
+ 2 个 FP wakeup、发射最多 2 个**最老 ready** uop。容量 ENTRY_COUNT=8(`OOO_ISSUE_INDEX_W`=3)。
不负责寄存器读/执行(下游 ALU slice)、不负责 busy-table 状态(由 BusyTable,IQ 内缓存 src ready 位)。

## 2. 结构与时序
- 每项:valid/src1_ready/src2_ready/src preg/pdest/imm/ctrl/rob_idx/pc...,**按程序序排列**(新进尾)。
- **wakeup**:2 个整数 writeback + 2 个 FP wakeup pdest 广播,匹配 src preg → 置该 src ready
  (同拍旁路,新发射 uop 同拍可见;FP 口服务 FP store 数据源 fs2 的就绪监听)。
- **select**:顺序扫描(oldest-first)选最老的 2 个 src1&src2 都 ready 的 uop → issue0/issue1。
  simultaneous valid 双 lane 的 enabled integer source 不可能 RAW：consumer 只能在 producer WB
  wakeup 后成为 ready；`RAW-I1` 在 backend 消费边界看护该不变量。current-result forward
  的 true arm 在合法状态不可达，但 2026-07-12 与 2026-07-13 两次 fresh 5ns 删除 A/B 均被
  物理证据拒绝。第二次虽让原 39 条 MIQ tail 退出 top40，仍使 WNS `-10.001→-10.182ns`、
  TNS 恶化18.5%、loops `109→142`、area/power 上升并暴露39条更差 FP exec1 tail。因此当前
  物理 mux 暂留，避免用 RTL 代码直觉覆盖映射实测；先切 long-op WB feedback 后再重评。
- **compaction**:发射后剩余项向前压实保持程序序紧凑。
- **dispatch→issue 时序(P5 刀 B,2026-07-09)**:dispatch 项当拍只写入阵列,**次拍(N+1)起
  才可被 select**——"dispatch 活值作虚拟队尾同拍参与 select"的 bypass 族(bypass 许可判定/
  活值 entry_ready/issue0 前递 forward/payload 直通臂)已整体删除。select 唯一真源=已寄存
  valid_q 项,由 `IQ-NO-BYPASS` 立即断言看护;mode 下 branch/JAL/JALR 原"禁旁路"特例随之
  普适化,pred_npc 恒取寄存 pred_npc_q(loop-free by construction)。同拍 wakeup→select
  直通(寄存项唤醒 CAM)**保留**,非 dispatch bypass。backend 中仍有由 issue0_fire
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

## 4. 关键路径
P5 刀 B 前,dispatch→issue bypass 把 free-list 分配+busy 查询+IQ select **单拍合一**
(Vivado OOC 39 级最深链;2026-07-09 全核 OpenSTA 中又是 19.8ns/240 级巨型路径的缝合段)。
刀 B 后 dispatch 锥与 issue 锥解耦,IQ 前向路径=已寄存项的唤醒 CAM+oldest-first scan+
payload 直读。顺序扫描 select 仍随 ENTRY_COUNT 增深(故 iter2 撤回 IQ 8→16 扩容)。

## 5. 验证
- 模块 TB `tb_ooo_int_issue_queue`(N+1 发射口径契约,含 kill/recover/flush/唤醒吸收);
  上层集成 TB `tb_ooo_dispatch_backend`/`tb_ooo_int_backend`/`tb_ooo_alu_decode_backend`
  已同步 N+1 时序。契约立即断言:IQ-NO-BYPASS/IQ-KILL-NO-DISPATCH(负测试证据存
  `.github/task-runs/2026-07-09-p5-first-batch/`)。
- `tb_ooo_int_backend` 常驻三 uop 场景：P 写 x7，依赖者 A 与 P 同拍 dispatch，P issue
  拍再 dispatch 依赖者 C；P WB 拍 A/C 同时 wakeup 并分别落到 issue0/issue1，检查
  issue1 直接从 PRF write-through 取得 P 的 64-bit 值。`RAW_I1_NEGATIVE_PROBE` 在合法
  双 lane 上做消费边界 source-tag mutation，必须只触发 RAW-I1 且 runner 非零。
- 集成 riscv-tests/AM(数据相关唤醒、双发射、load-use、分支恢复);
  代表:branch-resolve-loop/ooo-mem-order(读写交替+唤醒时序)。

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
  SCC；下一刀只让 EX/MEM fast broadcast 参与同拍 select，full wakeup 仍粘入 IQ state。
  证据 `.github/task-runs/2026-07-13-rv64-t3a-current-top-retry/`。
