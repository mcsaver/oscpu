---
name: ace-sim-project
description: "ace-sim = 用户自研的活动驱动周期级体系结构仿真器(C++20 greenfield),与 rv64 OOO 核无关;V1 已落地"
metadata: 
  node_type: memory
  type: project
  originSessionId: 441d4d66-3c02-4794-8002-9e7bd111b1cb
---

`/home/lyg/PA/ysyx-workbench/ace-sim/` 是**独立的 greenfield C++20 项目**,与 npc/rv64 OOO 核完全无关(勿混淆)。用户 2026-07-03 给出完整设计,要求"一步步搭建"。

**它是什么**:ACE = Activity-driven / Completion-event / Eval-driven 的**周期级体系结构仿真器**。介于 Verilator(逐 wire 全量 eval)、gem5(重量级 EventQueue)、Sniper/zsim(延迟模型)之间。核心思想:
- 同步边界由 cycle + commit 保证(`Reg<T>` cur/next、固定 7-phase 顺序);
- 异步行为由 completion event 表达(多周期单元内部**不**逐周期 eval);
- 并发由 active-set + ready-valid 队列表达;
- 性能来自**只 eval 活跃组件 + time-skip**(系统 blocked 时直接跳到下一个事件周期)。

**权威契约**:`ace-sim/DESIGN.md`(10 条不可违反的不变量 + phase 顺序 + time-skip 规则 + V1→V5 版本路线)。改代码前先读它;§5.1 是"睡眠安全律"(见下)。

**构建/验证**:`make test`(内核单元测试:Reg/EventWheel/ActiveScheduler/FunctionalUnit)、`make run`(demo:in-order scoreboard 核 + 多周期 FU + cache 延迟,参考模型对拍 + 7 目标自检 + 2 回归)。g++≥11,无外部依赖。

**当前状态(V1–V5 全部完成,V1-V4 各经对抗式审查加固;OoO 核已模块化重构)**:
- **V1**(`CycleSimpleCpu`,`make run`):in-order scoreboard 核。7 内核目标全 PASS(典型 248 模拟周期只执行 30、跳过 218)。审查修 4 缺陷(HALT 闸门/睡眠安全律 II>latency/停机 off-by-one/FunctionalUnit width 失效)。
- **V2**(`CycleOooCpu`,`make run-ooo`):乱序核 —— 寄存器重命名(RAT+free list+物理寄存器堆)+ issue queue(完成驱动唤醒)+ ROB 按序精确 commit。head-to-head 更快(26 vs 38),completion≠commit 彻底落地。审查 0 真 bug(~1.3M 随机对拍),加 2 防御(num_phys>num_arch assert、on_wakeup dyn_id 守卫)。
- **V3**(`CycleOooCpu` 扩展 LSQ,`make run-lsq`):首次引入 **store**(内存可写)。store queue 兼作 store buffer(dispatch 分配→execute 算地址/数据→commit 标 committed→按程序序 drain 落存)+ **store→load 前递**(最年轻的更老同址 store)+ **内存消歧**(更老 store 地址未知则 load 等待)+ HALT 前 fence。**审查揪出 1 个 critical 死锁**(LOAD 就绪列表 HOL,见硬教训2),修复后 2 万次随机差分零 mismatch。
- **V4**(`CycleOooCpu` 扩展投机,`make run-spec`):PC 驱动取指 + bimodal 分支预测 + 误判 squash(flush 更年轻 ROB/IQ/SQ + RAT 快照回滚 + free-list 恢复 + 取指重定向)+ **dyn_id 惰性取消**(不删 wheel 事件)。控制流参考模型对拍;循环 demo 学习预测器并从两向误判恢复;含分支随机差分 2 万程序 / 2.3 万 squash 全部 regs+mem 一致。**注:惰性取消用单调唯一 dyn_id 标签,不用全局 epoch**——全局 fetch-epoch 无法区分"更老正确/更年轻错误"(同代),我最初的 epoch 方案被证伪。**审查(过程坑:一个 lens agent 编 PoC 跑飞 40 分钟卡死工作流,须 TaskStop + 补跑)**:0 真 correctness bug + 2 处修复——①删死 epoch plumbing;②**睡眠安全律推论2**:on_wakeup 对任何投递事件(含被惰性丢弃的陈旧事件)都须重激活 Eval(否则 squash 后错误路径 load 的陈旧响应被丢弃、漏唤醒端口停顿的存活 load → 静默 halt;难触发,靠推理修)。

- **V5**(`main_ff.cc`,`make run-ff`):**functional backend 与 timing engine 分层**。`isa/FunctionalBackend`(可步进/可界定的纯功能执行,ref_model 委托它 → 功能模型=difftest 金标准**同一份代码**)。**fast-forward**:功能快进无趣前缀到 ROI 入口,把架构状态(regs+mem+PC)种子进详细核(`OooConfig.start_pc`+`SimpleMemory.write`+`set_arch_reg`),只对 ROI 做 cycle-accurate。三方(golden/full-detailed/hybrid)regs+mem 一致;典型快进 602 条、ROI 9 周期 vs 全详细 412 周期。JIT/DBT 是功能后端性能优化(后续)。

**npc 对齐的模块化重构 = 已完成**(用户指令,方案 `ace-sim/design/arch/engineering.md`,决策:①干净逻辑分级 ②RTL 端口 Out>>In ③自动全量迁移)。单体 `ooo_cpu.cc` 拆成 **11 个 RTL 式模块**(一模块一文件,镜像 npc 1:1)+ `top/CpuTop`:`frontend/{Bpu,Fetch}` `execute/{Alu,MulDiv,BranchResolve}` `rename/{RenameMap,FreeList}` `regfile/PhysRegFile` `issue/IssueQueue` `memory/StoreQueue` `dispatch/Rob`。目录:`hw/`(Module 基类+port.hh 的 Out>>In+reg/queue/resource)、`isa/`(inst+ref_model=golden)、`core/<stage>/`、`cpu/`(V1 baseline)、`mem/`、`sim/`(内核原样)。**CpuTop 构造函数=11 模块实例化(读如 Verilog top),phase 方法=连线+流控(= npc OooCoreTopGlue,"存储/流控留 glue"惯例)**。纯组合叶子(predict/compute/resolve/disambiguate)用方法(= npc `*Gate`);持状态件归模块所有。**关键方法学:每抽一个模块立即回归五版+4 万 fuzz,数字逐字不变(59730 分支/22982 squash/0 mismatch)= 接线严格等价的硬护栏**;`make unit`(test/unit/tb_modules)每模块单元测试(镜像 npc tb_ooo_*)。`[DEAD]` npc 模块不镜像。每模块 spec 已补(`design/specs/` 1:1)。

**gem5-breadth 扩展(engineering.md §11,目标"工程量≥gem5",批 1-7)**:①②③已落地并对抗验证,④-⑦进行中。
- **① 多级 cache**(`mem/{Cache,MemSystem}`,`make run-mem`):L1D+L2+DRAM+LRU+MSHR/MLP,纯时序模型覆盖 SimpleMemory(值走后备内存,difftest 一致)。
- **② FP 数据通路**(`execute/FpAlu`,`make run-fp`,spec `fp-alu`):全流水 FP 单元 + FDIV 长延迟;统一 64-bit PRF 承载 double 位型(f0-31=arch 32-63);host double 语义 golden 逐位同源;2 万程序/20.7 万 FP op bit-exact。
- **③ CSR + trap/中断**(`core/control/CsrFile`,`make run-csr`,spec `csr-file`):CSRW/CSRR/ECALL/MRET;系统 op **dispatch 串行 + 效应在 commit 边界**(不投机 CSR);ECALL/MRET 精确 trap/返回。**异步中断**:on_wakeup 收 TimerInterrupt→最老指令边界 `take_interrupt`:squash-all + RAT 回滚到**新增 RRAT(已提交 rename map)** + `squash_uncommitted`(保留已提交 store)+ 跳 mtvec,对主程序透明。同步路径 difftest bit-exact(8.1 万系统 op/2.7 万 ECALL);异步中断压力(注入周期 1..80)每拍架构态=基线。**RRAT 是精确异常/中断回滚检查点,与分支 squash 的 rat_ckpt 同构(checkpoint=已提交映射)**。
- **④ TLB/MMU**(`mem/mmu.hh` + `core/mmu/Tlb`,`make run-mmu`,spec `tlb`):翻译值 = 双射 `PPN=VPN^KEY`(golden 与详细核共用 → 物理地址一致 → difftest 守恒);`Tlb`(组相联+LRU)纯时序,miss → `MemReq.extra_latency`=页表 walk 延迟。load/store 全程用 paddr(消歧/前递/访存)。`mmu_on` 默认关(不扰其它版本)。fuzz 2 万程序/19.6 万 TLB 访问对拍金标准。**关键模式:翻译值确定性双射 → 功能与 golden 一致;TLB 只管时序**(与 cache 层级同构)。
- **⑤ gshare + RAS + JAL/JALR**(`Bpu` gshare + `core/frontend/Ras` + JAL/JALR,`make run-gshare`,spec `ras`/`bpu`):gshare(GHR^PC 索引 PHT,`ghist_bits>0` opt-in,默认 bimodal → 旧版本不变);RAS 投机 push/pop 预测返回目标;JAL(目标 imm 取指即知,写链接 rd=pc+1,dispatch 即 done)/JALR(目标 reg[rs]+off execute 才知 → RAS 预测,resolve 同分支,rd 在 dispatch 写)。fuzz 2 万程序/2.4 万 call/2.3 万 ret(RAS 命中 100%)对拍金标准。**关键模式:预测器(gshare/RAS)+ 间接目标只影响时序/准确率,架构正确性由 execute resolve + squash 保证**(与 ④ TLB 同族"预测/时序 ≠ 架构结果")。
- **⑥ STA/STD 拆分 + LoadUnit/Decode 模块**(`make run-sta`,spec `decode`/`load-unit`/`store-queue`):STORE 在 dispatch 裂成 STA(地址,等 base)+ STD(数据,等 data)两独立微 op(共享 SQ/ROB 项,IQ 需 2 槽);`StoreQueue` 拆 `addr_ready`/`data_ready`,`disambiguate` 更精确(**异址 load 越过、同址等 STD 前递**);新 `core/decode/Decode`(译码分类+裂分)、`core/memory/LoadUnit`(load AGU+翻译+walk)。fuzz 2 万程序/4 万前递对拍金标准;旧版本全 bit-exact(裂分对内存语义守恒)。
- **⑦ JIT/DBT block 翻译**(`isa/BlockInterpreter`,`make run-dbt`,spec `block-interp`):功能后端从逐指令解释升级为 basic-block 块级执行;按入口 PC 缓存块边界,循环体块翻译一次复用多次(摊销边界扫描)。指令语义抽成 `FunctionalBackend::apply_inst`(**单一来源**)→ 块解释 == 逐指令解释 == 详细核。demo(循环块翻译 2 次/执行 1001 次三方一致)+ fuzz 2 万程序(复用比 2662×,逐位一致)。

**gem5 广度 ①-⑦ 全部落地(2026-07-04),`/goal` 达成**。14 个二进制全绿(V1-V5 + mem/fp/csr/mmu/gshare/sta/dbt + test_kernel + tb_modules)。每批共性方法:功能金标准与详细核共用语义→差分对拍;预测/时序(cache/TLB/gshare/RAS)≠架构结果;精确异常/中断在 commit 边界(RRAT 回滚)。诚实边界:轻量 ISA + 双射页表 + 块级(非机器码)DBT,不逐行对齐 gem5 LOC。总模块 spec 见 `design/specs/README.md`(20 份)。

**硬教训2(睡眠安全律的推论,V3 审查 critical 缺陷)**:"停顿有事件兜底"还不够 —— **兜底事件不能被停顿者自己挡住**。就绪列表若 FIFO+遇阻 `break` 整类,一个等待的 younger 项会 head-of-line 堵住其后、恰好能解析它的 older 项 → load→store→load 环死锁、无事件可破 → 静默 halt。规则:凡停顿原因取决于同列表其它项进展的就绪列表(LOAD 内存消歧),必须**跳过**不可发射项而非 break;仅当停顿原因全列表一致(FU 结构冒险/端口 backpressure)时 break 才安全。已固化进 DESIGN.md §5.1。

**硬教训(睡眠安全律,DESIGN.md §5.1)**:活动驱动仿真里,组件"睡眠(不自激)"只有在**每个阻塞原因都有一个已在 wheel 中的未来事件负责唤醒它**时才安全。数据冒险由 producer 完成事件兜底、内存端口由 load 响应兜底,但**纯 wall-clock 条件(如 FU 的 initiation-interval 窗口,II>latency 时)无事件兜底**,必须显式调度自唤醒事件(`EventKind::CpuWake` at `FunctionalUnit::next_free()`),否则睡死/仿真提前静止。这是 V1 首版审查缺陷 #2/5/9 的根因,也是我当初推理错的地方。相关:用户要求[[respond-and-think-in-chinese]]。
