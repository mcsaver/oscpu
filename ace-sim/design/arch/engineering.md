# ACE-Sim 工程架构:对齐 npc 的模块化重构方案

> 目标(用户指令):把当前单体 `ooo_cpu.cc` 拆成**对齐 npc RTL 模块**的颗粒度 —— BPU、ALU、
> ROB、IQ、LSQ 等各自成模块;**近 RTL 语义、类 Verilator 结构**(cur/next、模块 eval),但
> **顶层暴露类 RTL 写法**(CPU 从 top 出发实例化+连线);工程管理参考 **NEMU**,写法参考 **gem5**。
> 最终模块语义与 npc 一致。**先设计工程,再动手。**

本文件是重构的**工程契约**。内核不变量仍以 [`../../DESIGN.md`](../../DESIGN.md) 为北极星;本文件规定
"代码如何组织成模块"。

---

## 1. 核心张力与解法

ace-sim 的立身之本是**活动驱动 + time-skip**(只 eval 活跃模块、系统 blocked 时跳周期)。
npc 是 RTL:每个模块有 `_q`(cur)/next、`_i/_o` 端口、ready/valid,顶层纯结构连线。

**两者并非冲突,而是叠加**:

| 维度 | 采用 |
|---|---|
| 模块**结构** | 类 RTL / 类 Verilator:每模块 = 一个类,持 `Reg<T>` 状态,`comb()` 算组合逻辑与 next,`tick()` 提交 next→cur |
| 模块**执行** | 活动驱动:模块是内核 `Component`,只在活跃时被调度 eval(保留 time-skip / lazy eval) |
| **顶层** | 类 RTL:`CpuTop` 实例化各模块 + 连线(端口对接),读起来像 Verilog top;这是 npc `OooCoreTopGlue` 的对应物 |

一句话:**RTL 的结构与模块边界 + 活动驱动的执行引擎**。这正是 DESIGN.md 的论点在工程层的落地。

---

## 2. 目标目录结构(参考 NEMU 管理 + npc `vsrc/<stage>/` 分层)

```
ace-sim/
  README.md
  DESIGN.md                     # 内核不变量(北极星,保留)
  Makefile                      # 每模块独立编译单元(后续可升级 Kconfig,见 §8)
  configs/                      # (预留)defconfig:核宽度/队列深度/预测器尺寸 —— 对应 npc include/define.v
  design/
    arch/
      engineering.md            # 本文件:工程结构 + 模块映射 + 约定
      microarch.md              # 微架构:流水线分级、数据流(对应 npc ooo-core-architecture.md)
    specs/
      <module>.md               # 每模块一份 spec(镜像 npc design/specs/ooo-*.md)
  src/
    sim/                        # 活动驱动内核(保留原样):cycle/phase/event/event_wheel/
                                #   active_scheduler/component/context/stats
    hw/                         # RTL-like 硬件基座(新):
      reg.hh                    #   Reg<T> cur/next(从 core/ 迁入)
      port.hh                   #   ready/valid 端口 + 单向 wire 连接(gem5 风格 Port)
      module.hh                 #   Module 基类 = Component + comb()/tick() + 端口注册
      params.hh                 #   全局容量参数(对应 npc OOO_* 宏)
    isa/                        # 功能真源(类 NEMU/spike golden model):
      inst.hh                   #   指令模型
      ref_model.hh              #   控制流参考模型(差分对拍金标准)
    core/                       # OoO 核:一模块一文件,按 stage 分子目录(镜像 npc vsrc/<stage>/)
      frontend/   Fetch.{hh,cc}  Bpu.{hh,cc}  Redirect.{hh,cc}
      decode/     Decode.{hh,cc}
      rename/     RenameMap.{hh,cc}  FreeList.{hh,cc}  BusyTable.{hh,cc}
      dispatch/   Dispatch.{hh,cc}  Rob.{hh,cc}
      issue/      IssueQueue.{hh,cc}
      regfile/    PhysRegFile.{hh,cc}
      execute/    Alu.{hh,cc}  MulDiv.{hh,cc}  BranchResolve.{hh,cc}
      memory/     StoreQueue.{hh,cc}  LoadUnit.{hh,cc}
      commit/     Commit.{hh,cc}
      control/    Squash.{hh,cc}          # 误判/flush 重定向(对应 npc control/ 序列器)
      top/        CpuTop.{hh,cc}          # 类 RTL 顶层实例化+连线("glue")
    mem/          simple_mem.{hh,cc}      # 内存/设备模型(对应 npc mem bridge + DPI slave)
  test/
    test_kernel.cc               # 内核单元测试(保留)
    unit/        tb_<module>.cc  # 每模块单元测试(镜像 npc testbench/tests/tb_*)
    diff/        difftest.cc      # 差分 fuzz 主程序(ref_model vs 模块化 CpuTop)
  tools/          drivers, 反汇编/trace 等(对应 NEMU tools/)
```

**与现状的映射**:`src/sim/` 原样保留;`src/core/reg.hh|queue.hh|resource.hh` 迁入 `src/hw/`;
`src/cpu/` 现有单体逻辑拆散进 `src/core/<stage>/`;`main_*.cc` 收敛为 `test/diff/` + `tools/` 驱动。

---

## 3. 模块接口约定(镜像 npc,gem5 端口风格)

### 3.1 命名(对齐 npc)
- **`_q`** = 寄存器状态(cur);**next** 由 `comb()` 写、`tick()` 提交。用 `Reg<T>`。
- **`_i` / `_o`** = 输入/输出端口;**`_w`** = 内部组合 wire。
- 双发多路命名:`slot0_*`/`slot1_*`、`commit0_*`/`commit1_*`(ace-sim 先单/双发可配)。
- 后缀语义(与 npc 一致,用于类名/文件名):
  - **`*Unit`/`*Queue`/`*Map`/`*File`** = 持状态的功能模块(Alu 用 `Alu`,IQ 用 `IssueQueue`)。
  - **`*Gate`** = 纯组合 facts/mux 叶子(如 `BranchResolveGate`)。
  - **`*Sequencer`** = 持寄存器状态的小 FSM(如 `SquashSequencer`)。
- **一模块一文件,文件名 == 类名**(镜像 npc 1:1;单元测试 `tb_<module>.cc`、spec `<module>.md` 同名对应)。

### 3.2 Module 基类(`src/hw/module.hh`)
```cpp
class Module : public Component {           // 是内核 Component -> 参与活动调度
 public:
  virtual void comb(SimContext&) {}         // 组合:读 _i / _q,写 _o / next(Verilator eval)
  virtual void tick() {}                    // 时钟沿:所有 Reg commit(next -> cur)
  // eval(phase) 的默认实现把 Eval 映射到 comb()、EdgeCommit 映射到 tick(),
  // 其它 phase 由具体模块覆盖(见 §3.4)。
};
```
模块只读 `_i`(上游 cur)、只写 `_o`/next(不变量 #4 cur/next 由此天然满足)。

### 3.3 端口 / 连接(gem5 风格,`src/hw/port.hh`)
- `Out<T>` / `In<T>`:顶层把上游 `Out` 连到下游 `In`(一次性 bind);下游读到的是**上一周期**上游值
  (cur 语义),避免同周期组合环——与 RTL 寄存的模块边界一致。
- ready/valid:`ReadyValid<T>` 通道,`fire = valid && ready`;跨模块背压载体(不变量 #7)。
- **禁止**模块间深层方法调用(不变量 #6);一切走端口。

### 3.4 与活动驱动内核的接合
- 模块用现有 7-phase(EdgeCommit/Wakeup/Arbitrate/Eval/Transfer/Retire/EndCycle)。
- 默认:`EdgeCommit→tick()`,`Eval→comb()`;需要跨周期完成事件的模块(FU、LSU)仍走
  `schedule(Event)` + `Wakeup`(不变量 #1/#2)。
- 睡眠安全律(DESIGN.md §5.1 + HOL 推论)对每个自激模块继续生效。

---

## 4. 模块分解表(ace-sim ↔ npc,及承接的现有逻辑)

> 只镜像 ace-sim **已实现功能**对应的 npc 模块;FP/CSR/trap/TLB/PMP/cache 层级为**未来桩**
> (建目录+spec 占位,不强行实现)。npc 的 **[DEAD]** 模块一律不镜像。

| ace-sim 模块 | 对应 npc 模块 | 承接现有 `ooo_cpu.cc` 逻辑 |
|---|---|---|
| `frontend/Fetch` | `OooFetchPacketDecode` + `OooFetchPcOutstandingSequencer` | `fetch()`:PC 驱动取指、FetchItem |
| `frontend/Bpu` | `OooBranchDirectionPredictor` | bimodal BHT `predict_taken`/`update_predictor` |
| `frontend/Redirect` | `OooFetchRequestMux` | 取指 PC 重定向优先级(squash redirect 汇入) |
| `decode/Decode` | `DecodeUnit`/`DecodeStage` | 指令分类(fu 类别 / 源目的 / 分支条件) |
| `rename/RenameMap` | `OooRenameMap` | `arch_map_` RAT + 快照/回滚 |
| `rename/FreeList` | `OooFreeList` | `free_phys_` 分配/释放 |
| `rename/BusyTable` | `OooBusyTable` | 物理寄存器 ready 位(现分散在 phys_) |
| `dispatch/Dispatch` | `OooDispatchBackend` | `rename_dispatch()` 分配 ROB/IQ/SQ |
| `dispatch/Rob` | `OooRob` | ROB 环、`on_retire()` 提交、squash 走 walk |
| `issue/IssueQueue` | `OooIntIssueQueue` | IQ 条目 + 唤醒 + `select_issue()` 选择(含 LOAD 跳过) |
| `regfile/PhysRegFile` | `OooPhysRegFile` | `phys_[]` 值/ready + 读口 |
| `execute/Alu` | `ALU`+`CompareUnit` | ALU 计算 + 分支比较 |
| `execute/MulDiv` | `OooMulDivUnit` | MUL(3)/DIV(20)多周期 completion |
| `execute/BranchResolve` | `OooDirectBranchResolveGate` | `resolve_branch()` 误判判定 |
| `memory/StoreQueue` | `OooStoreQueue` | SQ + 前递 `disambiguate_load` + drain |
| `memory/LoadUnit` | `OooMemoryRequestGate` + `OooMemInflightQueue` | load 发送/响应回填 |
| `commit/Commit` | `OooCommitOutputMux` | 提交口 + commit_order 观测 |
| `control/Squash` | `OooControlFlushSequencer` | `squash_after()` flush + RAT 回滚 + epoch(dyn_id) |
| `top/CpuTop` | `OooCoreTopGlue`/`NpcCoreTop` | 实例化+连线;暴露顶层 |
| `mem/SimpleMemory` | `OooMemAxiBridge` + DPI slave | cache 延迟 + 可写 backing |
| `isa/ref_model` | (NEMU/spike golden) | 差分对拍金标准 |

**未来桩目录**(建 spec 占位):`execute/fp/`(OooFp*)、`control/csr/`(CsrFile/trap)、
`memory/mmu/`(Sv39Tlb/Pmp)、`frontend/ras/`(OooRasStack)。

---

## 5. 顶层 RTL 写法(`top/CpuTop`)

`CpuTop::CpuTop(...)` 读起来像一个 Verilog top:先实例化各模块,再连线端口(npc glue 的对应物)。

```cpp
CpuTop::CpuTop(SimContext& ctx, Program prog, MemPort* mem) {
  // ---- 实例化(instantiate)----
  bpu_    = ctx.make<Bpu>(cfg_.bht_size);
  fetch_  = ctx.make<Fetch>(std::move(prog), bpu_);
  decode_ = ctx.make<Decode>();
  rename_ = ctx.make<RenameMap>(cfg_.num_arch, cfg_.num_phys);
  rob_    = ctx.make<Rob>(cfg_.rob_size);
  iq_     = ctx.make<IssueQueue>(cfg_.iq_size);
  alu_    = ctx.make<Alu>(cfg_.alu);
  // ... muldiv_, brres_, sq_, load_, commit_, squash_ ...

  // ---- 连线(wire,像 Verilog 的 .port(net))----
  fetch_->out_fetch >> decode_->in_fetch;        // fetch -> decode
  decode_->out_uop  >> rename_->in_uop;          // decode -> rename
  rename_->out_disp >> dispatch_->in_disp;
  iq_->out_issue    >> alu_->in_op;              // issue -> ALU
  brres_->out_redir >> squash_->in_mispredict;   // 分支解析 -> squash
  squash_->out_flush >> {rob_, iq_, sq_, rename_}; // flush 广播
  // ...
}
```
`>>` 是 `Out<T> -> In<T>` 的连接语法糖(`hw/port.hh`)。顶层没有算法逻辑,只有结构 —— 与 npc
"storage/flow-control 决策留在 glue、wrapper 只聚合"一致,但 ace-sim 把决策进一步下沉到各模块。

---

## 6. 构建与配置(参考 NEMU)

- **现阶段**:`Makefile` 编译每模块为独立 `.o`,链接成 `ace-sim` + 各 `tb_*`/`difftest`。
  一模块一编译单元 -> 增量编译 + 强制模块边界(头文件即接口)。
- **后续可选**:引入 NEMU 风格 `Kconfig` + `configs/*_defconfig`,把核宽度/队列深度/预测器尺寸做成
  编译期或运行期配置(对应 npc `include/define.v` 的 `OOO_*`)。先不做,避免过早复杂化。

## 7. 测试(镜像 npc testbench + 差分)
- **每模块单元测试** `test/unit/tb_<module>.cc`:对单模块喂激励、查端口/状态(镜像 npc `tb_ooo_*`)。
- **差分 fuzz** `test/diff/difftest.cc`:随机程序 ref_model vs CpuTop,regs+mem 对拍(已有,迁入)。
- **五版 demo** 保留为顶层驱动(验证等价);重构以"全绿不回退"为硬约束。

## 8. 迁移计划(增量,每步全绿)

不做 big-bang。逐模块从单体切出,**每切一块立即回归五版 demo + 差分 fuzz**:

1. **地基**:建目录;`core/*` → `hw/`;写 `hw/module.hh`+`port.hh`;`CpuTop` 先直接内联现单体逻辑(等价重命名),全绿。
2. **叶子先行**:切 `Bpu`、`Alu`、`MulDiv`、`BranchResolve`(纯功能,依赖少)。
3. **结构件**:切 `RenameMap`/`FreeList`/`BusyTable`、`Rob`、`IssueQueue`。
4. **内存**:切 `StoreQueue`/`LoadUnit`。
5. **控制**:切 `Squash`/`Redirect`;`Fetch`/`Decode`/`Commit`/`Dispatch` 收口。
6. **接线**:`CpuTop` 变纯结构连线;补每模块单元 TB + spec。
7. 每步:`make && 五版 + fuzz` 绿;关键步跑对抗式审查。

## 9. 明确不做 / 边界
- 不镜像 npc **[DEAD]** 模块(pending 链/BTC/JALR-BTB/prefetch/synthetic-lane1)。
- FP/CSR/trap/TLB/PMP/多级 cache:建目录+spec 占位,**不强行实现**(ace-sim 现无对应功能)。
- 不追求 RTL 位级/时序级一致;追求**模块边界与语义一致** + 可差分对拍的功能正确。
- 顶层不放算法;模块间只经端口(不变量 #6)。

## 10. 迁移进度(逐模块,每步回归五版 + 差分 fuzz 全绿、数字不变)

- [x] **步骤1 地基**:`core/{reg,queue,resource}`→`hw/`;`hw/module.hh`(Module 基类)、`hw/port.hh`(Out>>In + ReadyValid)。
- [x] **步骤2 叶子**:`frontend/Bpu` ↔ OooBranchDirectionPredictor;`execute/Alu` ↔ ALU+CompareUnit;`execute/MulDiv` ↔ OooMulDivUnit;`execute/BranchResolve` ↔ OooDirectBranchResolveGate。
- [x] **步骤3a rename+regfile**:`rename/RenameMap` ↔ OooRenameMap;`rename/FreeList` ↔ OooFreeList;`regfile/PhysRegFile` ↔ OooPhysRegFile+OooBusyTable(值+ready 合并)。
- [x] **步骤3b 结构件**:`issue/IssueQueue` ↔ OooIntIssueQueue ✅;`dispatch/Rob` ↔ OooRob(环/提交/squash walk)✅。
- [~] **步骤4 内存**:`memory/StoreQueue` ↔ OooStoreQueue ✅;`memory/LoadUnit`(load 发送/响应)仍内联于编排,后续可抽 ⬜。
- [~] **步骤5 前端/控制/提交**:`frontend/Fetch` ↔ OooFetchPacketDecode+PcSequencer ✅;squash/commit/dispatch 的**流控策略**按 npc 惯例留在顶层 glue(OooCoreTopGlue 亦如此)。
- [x] **步骤6 顶层**:`CycleOooCpu`→`top/CpuTop`(构造函数=11 模块实例化,读如 Verilog top;phase 方法=连线/流控)✅;`isa/`(inst+ref_model)✅;`test/unit/tb_modules` 每模块单元测试 ✅。

> **迁移完成**:11 模块(Bpu/Fetch/Alu/MulDiv/BranchResolve/RenameMap/FreeList/PhysRegFile/IssueQueue/StoreQueue/Rob)+ `top/CpuTop`(纯实例化+流控编排,= npc OooCoreTopGlue 对应物)。目录:`hw/`(基座)`isa/`(inst+ref_model=golden)`core/<stage>/`(模块)`cpu/`(V1 baseline)`mem/` `sim/`。**行为等价护栏**:每步 make+五版+4 万 fuzz 数字逐字不变(59730 分支/22982 squash/0 mismatch)+ `make unit` 每模块单元测试全过。**后续可选**:`memory/LoadUnit`/`decode/Decode` 再薄抽;FP/CSR/TLB 占位实现。

## 11. gem5 广度扩展(用户"都加上"指令,逐批建,均带 difftest 护栏)

> 目标:补齐 gem5 的主要子系统为真实、可差分验证的模块。诚实边界:不逐行对齐 gem5 LOC,
> 而是覆盖其主要架构子系统。每批:扩 ISA + FunctionalBackend(golden 覆盖新指令)→ 加详细核模块 → fuzz 对拍。

- [x] **① 多级 cache 层级**:`mem/Cache`(组相联+LRU)+ `mem/MemSystem`(L1D+L2+DRAM+MSHR/MLP)。
  可插拔替代 SimpleMemory(同 MemPort),值走后备内存(difftest 一致),延迟走层级走查。`make run-mem`。
  对应 gem5 classic memory(BaseCache×N + MSHR + MemCtrl)。
- [x] **② FP 数据通路**:`execute/FpAlu`(一个全流水 FP 单元,FDIV 长延迟)+ FADD/FMUL/FDIV/FCVT/FCMP;统一 64-bit 物理寄存器堆承载 double 位型(f0-31=arch 32-63);host double 语义 golden 同源。`make run-fp`:2 万程序/20.7 万 FP op bit-exact。
- [x] **③ CSR + trap/中断**:`core/control/CsrFile`(mtvec/mepc/mcause + 通用)+ CSRW/CSRR/ECALL/MRET。
  系统 op **dispatch 串行**(不投机 CSR)+ 效应在 **commit 边界**;ECALL 在 commit 拍精确 trap→mtvec,MRET→mepc。
  异步中断:on_wakeup 收 `TimerInterrupt`→在最老指令边界 `take_interrupt`:squash 全体在飞 + RAT 回滚到 **RRAT**
  (新增已提交 rename map)+ `squash_uncommitted`(保留已提交 store)+ 跳 handler,对主程序透明。
  `make run-csr`:同步 ECALL/MRET difftest bit-exact;fuzz 2 万程序/8.1 万系统 op(2.7 万 ECALL)对拍金标准;
  中断压力(注入周期 1..80)每拍架构态与基线一致。对应 gem5 ISA CSR + Fault/Interrupt + 精确异常。
- [x] **④ TLB / MMU**:`mem/mmu.hh`(翻译值 = 双射 `PPN=VPN^KEY`,golden 与详细核共用 → 物理地址一致 → difftest 守恒)
  + `core/mmu/Tlb`(组相联 + LRU,纯时序/统计)。load/store 翻译到物理地址(消歧/访存/前递均用 paddr);
  TLB miss → `MemReq.extra_latency` = 页表 walk 延迟(SimpleMemory/MemSystem 加到响应时刻)。`mmu_on` 默认关(不影响其它版本)。
  `make run-mmu`:demo(V→P 翻译 + 同页 TLB 命中 + 值往返)+ fuzz 2 万程序 / 19.6 万 TLB 访问(63% 命中)对拍金标准(regs + 物理内存)。
  对应 gem5 TLB + PageTableWalker(此处翻译走轻量双射,时序/缓存行为完整)。
- [x] **⑤ gshare + RAS + JAL/JALR**:`Bpu` 加 gshare(GHR ^ PC 索引 PHT,`ghist_bits>0` opt-in,默认仍 bimodal → 旧版本不变)
  + `core/frontend/Ras`(返回地址栈,投机 push/pop)+ JAL(直接调用,目标 imm 取指即知,写链接 rd=pc+1)/ JALR(间接跳转/返回,
  目标 reg[rs]+off execute 才知 → RAS 预测,误判 execute 拍 squash,与分支同构)。fetch call push、ret pop RAS。
  `make run-gshare`:demo(两次 call/ret,RAS 零误判)+ fuzz 2 万程序 / 2.4 万 call / 2.3 万 ret(RAS 命中 100%)对拍金标准。
  对应 gem5 BranchPredictor(gshare/TAGE 家族)+ RAS + IndirectPredictor。
- [x] **⑥ STA/STD 拆分 + LoadUnit/Decode 模块**:STORE 在 dispatch 裂成 **STA**(地址,等 base)+ **STD**(数据,等 data)两个独立微 op
  共享 SQ/ROB 项;`StoreQueue` 拆 `addr_ready`/`data_ready`,`disambiguate` 更精确(异址 load 越过、同址等 STD 前递);
  新 `core/decode/Decode`(译码分类 + 裂分)、`core/memory/LoadUnit`(load AGU + 翻译 + TLB walk)两模块。
  `make run-sta`:demo(store 数据来自长延迟 div,异址 load 越过 / 同址前递)+ fuzz 2 万程序 / 4 万前递对拍金标准。
  旧版本全 bit-exact(裂分对内存语义守恒)。对应 gem5 O3 StoreSet + STA/STD split + LSQUnit。
- [x] **⑦ JIT/DBT block 翻译**:`isa/BlockInterpreter` —— 功能后端从逐指令解释升级为 **basic-block 块级执行**。
  按 basic block(直线段 + 一条终结指令)切分,按入口 PC 缓存块边界;循环体的块只翻译一次、复用多次 → 摊销边界扫描。
  指令语义抽出为 `FunctionalBackend::apply_inst`(**单一来源**)→ 块解释与逐指令解释逐位一致。
  `make run-dbt`:循环 demo(块翻译 2 次 / 执行 1001 次,三方一致)+ fuzz 2 万程序(复用比 2662×,块 vs 逐指令逐位一致)。
  对应 gem5 的 KVM/FastModel fast-forward + DBT 思路(此处块级解释,不发宿主机器码)。

> **①-⑦ 全部落地并各带 difftest 护栏(2026-07-04)**。14 个二进制全绿(V1-V5 五版 + mem/fp/csr/mmu/gshare/sta/dbt 七批 demo + test_kernel + tb_modules)。
> 新增模块:`mem/{Cache,MemSystem,mmu}`、`core/execute/FpAlu`、`core/control/CsrFile`、`core/mmu/Tlb`、`core/frontend/Ras`、
> `core/decode/Decode`、`core/memory/LoadUnit`、`isa/BlockInterpreter`;新增 RRAT(精确中断)、gshare(Bpu)、STA/STD(StoreQueue)。
> 每批的共性方法:**功能金标准(FunctionalBackend)与详细核共用语义 → 差分对拍**;**预测/时序(cache/TLB/gshare/RAS)≠ 架构结果**;
> **精确异常/中断在 commit 边界(RRAT 回滚)**。诚实边界:轻量 ISA + 双射页表 + 块级(非机器码)DBT,不逐行对齐 gem5 LOC。
