# ACE-Sim

**Activity-driven, Completion-event, Eval-driven** —— 活动驱动、完成事件驱动、eval 驱动的
**周期级体系结构仿真器**。

介于 Verilator(逐 wire/逐周期全量 eval)、gem5(重量级 EventQueue)、
Sniper/zsim(延迟/完成模型)三者之间:

- **同步边界**由 cycle / commit 保证(cur/next 时序状态、固定 phase 顺序);
- **异步行为**由 completion event 表达(多周期单元内部不逐周期 eval);
- **模块并发**由 active set + ready-valid 队列表达;
- **性能**来自 lazy eval(只 eval 活跃组件)+ time skipping(系统 blocked 时直接跳到下一个事件周期)。

设计契约见 [`DESIGN.md`](./DESIGN.md)(10 条不可违反的不变量 + phase 顺序 + time-skip 规则 + 版本路线)。

## 构建 / 运行

```bash
make            # 构建 V1/V2 demo 与内核单元测试
make test       # 内核单元测试(Reg cur/next、EventWheel、ActiveScheduler、FunctionalUnit)
make run        # V1 demo(顺序 scoreboard 核 + 多周期 FU + cache 延迟 + 自检)
make run-ooo    # V2 demo(乱序核 rename+IQ+ROB;与 V1 head-to-head + 自检)
make run-lsq    # V3 demo(LSQ:store→load 前递 + 内存消歧 + store buffer 落存)
make run-spec   # V4 demo(投机:分支预测 + 误判 squash + RAT 回滚 + 惰性取消)
make run-ff     # V5 demo(fast-forward + detailed:功能快进前缀,只 cycle-model ROI)
make unit       # 每模块单元测试(镜像 npc tb_ooo_*)
```

要求 g++ ≥ 11(C++20)。无外部依赖。

## 当前状态:V5(功能后端 / 时序引擎分层)已完成

`make run-ff` 演示 **fast-forward + detailed** 切换:`isa/FunctionalBackend`(可步进的纯功能执行,
与 difftest 金标准同一份代码)把无趣前缀(长循环)"0 周期"快进到 ROI 入口,再把架构状态
(寄存器+内存+PC)种子进详细周期级核,只对 ROI 做 cycle-accurate。golden / full-detailed / hybrid
三方 regs+mem 一致;典型:快进 602 条指令,ROI 详细仅 9 周期 vs 全详细 412 周期。

> 至此 V1→V5 全部完成,且 OoO 核已重构为**对齐 npc 的 11 个 RTL 式模块 + CpuTop**
> (见 [`design/arch/engineering.md`](design/arch/engineering.md) 与 [`design/specs/`](design/specs/README.md))。

## 历史里程碑:V4(投机执行)

`make run-spec` 跑带**分支预测 + 投机**的乱序核:PC 驱动取指、bimodal 预测器、误判时 squash
更年轻指令(flush ROB/IQ/SQ + RAT 快照回滚 + free-list 恢复 + 取指重定向),错误路径的在飞
完成事件用 **dyn_id 惰性取消**(不删 wheel 事件)。循环 demo(sum 1..N)学习预测器并从两个方向
的误判中恢复,结果正确;含分支的随机差分 **2 万个程序、约 2.3 万次 squash/恢复**,寄存器 + 内存
全部与控制流参考模型一致。

## 历史里程碑:V3(LSQ / 内存乱序)

`make run-lsq` 跑带 **LSQ** 的乱序核:首次引入 **store**(内存变可写)。store queue 兼作 store
buffer——dispatch 分配、execute 拍算地址/数据、commit 标记、按程序序 drain 落存。三件关键行为:
**store→load 前递**(命中最年轻的更老同址 store,免访存)、**内存消歧**(更老 store 地址未知则
load 必须等待)、**HALT 前 store buffer 排空**。用有状态参考模型(寄存器 + 内存)对拍,并有一条
关键自检:一个 store 的地址锁在 20 周期 DIV 之后,后续同址 load 必须**等待**再前递,不得越序读到
陈旧内存值——这正是主核 LSQ 的"队头=序安全"家族。

## 历史里程碑:V2(乱序执行)

`make run-ooo` 跑 `CycleOooCpu`:寄存器重命名 + issue queue(完成驱动唤醒)+ ROB 精确提交。
与 V1 顺序核 head-to-head 跑同一程序,证明四件事:功能一致(对拍参考模型)、**乱序完成**
(younger 独立指令越过 stalled 的 DIV 先完成)、**按序精确提交**(ROB 按程序序退休)、更快
(典型 26 vs 38 周期)。这标志 completion≠commit 在架构上彻底落地。

## 历史里程碑:V1(MVP)

顺序核(in-order issue + scoreboard,无 ROB)+ 多周期功能单元 + cache 命中/未命中延迟模型。
`make run` 用**参考模型对拍**验证功能正确性,并逐条自检 7 个内核目标:

| 目标 | 含义 | 验证方式 |
|---|---|---|
| 1 | cur/next 状态正确 | `make test`(Reg 单元测试) |
| 2 | event wheel 正确(含 far-future 溢出桶) | `make test` + demo 事件投递 |
| 3 | 只 eval 活跃组件 | demo:eval 次数 ≪ 全量扫描,空闲周期被跳过 |
| 4 | 多周期 FU completion 正确 | demo:参考模型对拍 |
| 5 | FU 忙时前端仍前进 | demo:fetch 队列被填满 |
| 6 | 队列满时 backpressure 正确 | demo:fetch-full / issue-hazard 事件 |
| 7 | 系统 blocked 时跳到 next event | demo:DRAM miss 触发大幅 time-skip |

一次典型运行:**248 个模拟周期中仅 30 个被实际执行,218 个被 time-skip 跳过**。

## 源码结构

重构后对齐 npc 的 `vsrc/<stage>/` 分层(NEMU 式管理 + gem5 式端口);详见
[`design/arch/engineering.md`](design/arch/engineering.md)。

```
src/
  sim/      活动驱动内核:cycle/phase/event/event_wheel/active_scheduler/component/context/stats
  hw/       RTL-like 基座:module(Module 基类) / port(Out>>In + ReadyValid) / reg(cur/next) / queue / resource
  isa/      功能真源:inst(指令模型) / functional(FunctionalBackend) / ref_model(委托 functional=golden)
  core/     OoO 核(一模块一文件,镜像 npc):
    frontend/  Bpu  Fetch          rename/  RenameMap  FreeList     regfile/  PhysRegFile
    issue/     IssueQueue          execute/ Alu  MulDiv  BranchResolve
    memory/    StoreQueue          dispatch/ Rob         top/  CpuTop(实例化+流控编排)
  mem/      simple_mem(可写内存 + cache 延迟) / mem_req(端口)
  cpu/      simple_cpu(V1 顺序 baseline)
  main.cc main_ooo.cc main_lsq.cc main_spec.cc main_ff.cc   V1..V5 demo/自检/差分 fuzz
test/
  test_kernel.cc      内核单元测试
  unit/tb_modules.cc  每模块单元测试(镜像 npc tb_ooo_*)
design/
  arch/engineering.md   工程结构 + 模块映射 + §8 迁移记录
  specs/<module>.md     每模块 spec(file↔module↔tb↔spec 1:1)
```

## 路线(见 DESIGN.md §6)

- **V1 ✅** 顺序核 + 多周期 FU + EventWheel + ActiveScheduler + cache 延迟
- **V2 ✅** ROB + issue queue + 物理寄存器重命名 + 异步唤醒 + 精确 commit
- **V3 ✅** LSQ + store→load 前递 + 内存消歧 + store buffer 落存
- **V4 ✅** 分支预测 + mispredict squash + RAT 回滚 + dyn_id 惰性取消
- **V5 ✅** functional backend / timing engine 分层 + fast-forward→detailed 切换
- **重构 ✅** OoO 核拆成对齐 npc 的 11 个 RTL 式模块 + CpuTop(每步差分 fuzz 护栏)
