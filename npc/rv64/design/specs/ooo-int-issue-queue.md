# 规范：整数发射队列 OooIntIssueQueue

> 模块：`vsrc/scheduling/OooIntIssueQueue.v`(957 行,核心调度器)。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证。

## 1. 目的与范围
保持队列内程序序的压缩式发射队列:每拍接收最多 2 条 dispatch uop、监听 2 个 writeback wakeup、
发射最多 2 个**最老 ready** uop。容量 ENTRY_COUNT=8(`OOO_ISSUE_INDEX_W`=3)。
不负责寄存器读/执行(下游 ALU slice)、不负责 busy-table 状态(由 BusyTable,IQ 内缓存 src ready 位)。

## 2. 结构与时序
- 每项:valid/src1_ready/src2_ready/src preg/pdest/imm/ctrl/rob_idx/pc...,**按程序序排列**(新进尾)。
- **wakeup**:2 个 writeback pdest 广播,匹配 src preg → 置该 src ready(同拍旁路,新发射 uop 同拍可见)。
- **select**:顺序扫描(oldest-first)选最老的 2 个 src1&src2 都 ready 的 uop → issue0/issue1。
  issue1 的就绪需考虑 issue0 同拍消耗(前向检查)。
- **compaction**:发射后剩余项向前压实保持程序序紧凑。
- **dispatch 旁路/快路径**:dispatch entry 可作虚拟队尾同拍参与 select(绕过入队延迟);
  另有 load-dependent-branch 快路径:检测 load 依赖分支直接从 dispatch 转发,绕过 IQ。
- checkpoint/restore:分支投机时快照队列,误预测回滚。

## 3. 不变量
- **IQ-I1 程序序**:select 与 commit 对齐程序序;issue1 不早于 issue0(同拍两发保持相对序)。
- **IQ-I2 唤醒优先**:同拍 wakeup 置 ready 优先于本拍新 dispatch 的初始 ready 判定,避免漏唤醒。
- **IQ-I3 容量**:dispatch ready 严格按空位;compaction 不丢项/不重排乱序。
- **IQ-I4 无组合环**:dispatch-bypass/快路径的 ready/fire 前向不得形成 ready→valid→ready 回边
  (历史踩坑:branch append optional 曾因此 UNOPTFLAT/不收敛,见记忆 2026-05-29)。

## 4. 关键路径
Vivado OOC:IQ 单独 3.25ns/21 级(浅,route 假象使 total 18ns)。但其 ctrl 写使能处于
DispatchBackend 把 free-list 分配+busy 查询+IQ 写**单拍合一**的 39 级最深链末端
(见 `ooo-rename-alloc.md`)。顺序扫描 select 随 ENTRY_COUNT 增深(故 iter2 撤回 IQ 8→16 扩容)。

## 5. 验证
- 模块 TB `tb_ooo_int_issue_queue`;集成 riscv-tests/AM(数据相关唤醒、双发射、load-use、分支恢复)。
- 代表:branch-resolve-loop/ooo-mem-order(读写交替+唤醒时序)。

## 6. 变更记录
- 2026-06-28：逆向文档化(压缩程序序队列/2 唤醒/2 oldest-ready 发射/dispatch 旁路/快路径/不变量)。
