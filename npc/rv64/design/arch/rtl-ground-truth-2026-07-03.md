# RV64 OoO 核 · RTL 重读真相基线（2026-07-03）

> **定位**：本文件是对 `npc/rv64` 全部 RTL（约 4.3 万行可综合代码 + 仿真壳/csrc）的一次
> **不依赖任何既有设计文档**的从零重读结论——9 路子系统并行审计 + 交叉矛盾裁定 + 6 项追问验证，
> 全部结论以 `文件:行号` 证据支撑（证据全文见
> `.github/task-runs/2026-07-03-rv64-rtl-reread-audit/report-*.json`）。
> 用途：(1) 回答"这颗核现在能实现什么/不能实现什么"；(2) 作为既有文档（宪法/specs/memory）
> 归档与校正的对照锚。**与旧文档冲突时，以本文件（及其证据）为准。**

---

## 1. 一页总览：这颗核是什么

**RV64IMAFDC + Zba/Zbb/Zbc/Zbs + Zicsr + Zifencei(no-op) + 部分 Svinval，M/S/U 三特权级，
Sv39 虚存（硬件 PTW + I/D TLB），PMP×16，双发射乱序核**。
misa = RV64ACDFIMSU（`core/CsrFile.v`）。复位 PC = 0x8000_0000，无 bootrom。

| 结构参数 | 值 | 证据 |
| --- | --- | --- |
| 取指宽度 | 8B 包 / 恰 2 条指令（RVC 感知） | `frontend/OooFetchPacketDecode.v:27-75` |
| 派发/重命名/提交宽度 | 2 / 2 / 2 | `rename_allocate/OooDispatchBackend.v` |
| ROB | 16 项 | `include/define.v:31` |
| 整数 IQ | 8 项，压缩式程序序，双发射 | `scheduling/OooIntIssueQueue.v` |
| FP IQ | 8 项，oldest-ready，单发射 | `scheduling/OooFpIssueQueue.v` |
| 物理寄存器 | 整数 64（10R2W）+ FP 64（4R2W），各自独立 rename | `regread_bypass/OooPhysRegFile.v`、`OooFpPhysRegFile.v` |
| Store Queue | 4 项（probe→commit→drain） | `OooIntBackend.v:925` |
| 访存在飞队列 MIQ | 4 项（但桥单 outstanding，真实 MLP≈1） | `OooIntBackend.v:1015` |
| ICache（取指包 cache） | 4096 项直接映射 VIVT+上下文 tag（≈34KB 数据） | `cache/OooFetchPacketCache.v` |
| DCache | 32KB 直接映射 PIPT，8B line，write-through/no-allocate | `cache/OooDataWordCache.v` |
| ITLB / DTLB | 各 64 项直接映射，satp 整值 tag，超页支持 | `memory/OooSv39Tlb.v` |
| 方向预测 | gshare(4096×2b, GHR12) + 局部历史(256×8b + 4096×2b PHT) 混合 | `frontend/OooBranchDirectionPredictor.v` |
| RAS | 32 深（define.v 的 BPU_RAS_*=16 是死宏） | `frontend/OooRasStack.v` |
| 误预测恢复 | redirect + ROB-walk（2 项/拍反向 walk），无 checkpoint | `writeback/OooRob.v` |
| 乘/除 | 乘 2 拍非流水；除 radix-4+CLZ 早终止（≤32 拍） | `execute/OooMulDivUnit.v` |
| FADD/FMUL/FMA | 3/3/5 级流水（统一第 5 拍出结果，可背靠背） | `execute/OooFpArithGate.v` |
| FDIV/FSQRT | 56 步迭代（~57 拍），单在飞、互斥 | `execute/OooFpDivIter.v`、`OooFpSqrtIter.v` |
| CLMUL | 64 拍串行 | `execute/OooClmulUnit.v` |

**架构模型（重读后的准确表述）**：旧文档的"两执行域"中,域 B（stop_pending + 全后端 drain 串行化）
**只剩 system/trap/IRQ 类**在用：CSR 指令、ecall/ebreak、mret/sret、wfi、sfence.vma/Svinval、
取指 fault、非法指令类 arch-trap、中断注入、lane1 barrier。
分支/JAL/JALR（F2 真预测 + issue 级解析 + ROB-walk）、FP（独立 rename/IQ/流水簇 + 经 ROB 提交）、
load/store/AMO（SQ + probe/drain + MIQ）已全部迁回域 A。
**pending_branch / pending_jump / pending_mem / pending-FP 四通道已被形式化证死**（见 §4 死硅普查）。

---

## 2. 能实现什么（已证实的能力）

### 2.1 ISA 与执行
- **RV64I/M/A/C 全集**，Zba/Zbb/Zbs 单拍、Zbc 独立单元；LR/SC（reservation + SC 失败防活锁）与
  AMO 全族在 ROB 队头串行执行（misaligned 精确异常，对齐 NEMU）。
- **F/D 全集**：fused 单舍入 FMA、全 5 种舍入模式（含 DYN 读 frm）、subnormal 全支持（无 FTZ）、
  NaN-boxing 语义完整、fflags 随 ROB commit 架构序累积、FS=Off 时 FP 指令 trap。
  FP 真乱序（独立 rename + IQ + 3/3/5 级流水），GPR↔FPR 跨域指令真跨域。
- **RVC 全量**：取指侧双解压器展开为 32 位标准编码；指令永不跨包（包按任意 2B 对齐 PC 取 8B）；
  跨 4KB 页取指包两页独立翻译、独立 fault 标注。

### 2.2 特权架构
- M/S/U + 委托（medeleg/mideleg）+ trap/xret 全流程；中断 MSIP/MTIP/MEIP 三线，
  经 mideleg 映射 S 视图；中断在 dispatch 边界采样、drain 后精确注入（不打断在飞指令）。
- CSR 覆盖：fcsr 族、s 族（含 satp WARL：仅 Bare/Sv39）、m 族（含 menvcfg.PBMTE）、
  pmpcfg0/2+pmpaddr0-15（TOR/NA4/NAPOT + lock 链）、mcycle/minstret/mcounteren/scounteren/
  mcountinhibit、user 态 cycle/time/instret 分级门控。mvendorid=0x79737978, marchid=26010035。
- **Sv39**：I/D 两侧独立硬件 PTW（取指桥/访存桥 FSM 内），1G/2M 超页，MXR/SUM/MPRV，
  A/D 软件管理（A=0 或 store 遇 D=0 → page fault，Svade 风格）；PMP 对最终 PA + 每级 PTE 隐式读
  全覆盖（取指侧 5 个 checker 实例，数据侧 3 个）。
- CSR/系统指令执行模型 = 串行五步（dispatch 拍读旧值→stop+drain→重锁 rdata→单条注入→commit 拍写副作用），
  每条数十拍,这是域 B 的固有成本。

### 2.3 访存
- plain load 乱序投机发射（不等队头），三层序保护（IQ older-store 拦 / 在飞 probe 8B-line 重叠判定 /
  SQ snoop）；**store-to-load 前递已实现**（SQ 全包含单拍前递，M-mode 非 MMIO 限定）。
- plain store 严格 commit 后落存：发射拍 probe（翻译+PMP 探测回传 PA）→ SQ 回填 → 退休后
  nokill drain；PMEM store 写解耦（AW&W 即完成，B 后台吸收）。
- MMIO（非 PMEM 窗）load 强制 ROB 队头独占、不进 dcache、SQ blind 保序——功能正确、设备安全。
- 任意 misaligned plain load/store 硬件直接支持（byte-window 语义，不 trap；AMO/LR/SC misaligned 精确异常）。

### 2.4 前端与分支预测（F2 形态）
- 取指包 cache 命中背靠背 1 包/拍（峰值 2 条/拍）；每 store fire 逐失效维护 SMC（**有洞，见 §3.1**）。
- F2 真分支预测已启用：not-taken 预测 + head1 平凡 → 原子双发零气泡；taken 预测 → 前端 flush 按预测目标重取；
  pred_npc 单源随 uop 下行，issue 级统一解析（cond/JAL/JALR），显式 mispredict = (架构 next_pc ≠ pred_npc)；
  BPU 回训单源 = issue-resolve（含预测正确的分支）。
- JAL 前端直算恒免 redirect；RET 走 RAS(32 深)投机；非返回 JALR 投机续取（RAS ret-hint > fallthrough；
  JALR-BTB 臂因表恒空而实际失效，见 §4）。
- FIFO 低水位安全网：count<2 时 pred_npc=64'h1 哨兵 → 恒判 mispredict 兜底（正确性换性能）。

### 2.5 SoC / 仿真 / 验证基座
- SoC：2 主(IFU/LSU)×16 从 single-beat 类 AXI-Lite crossbar（带 read-abort 语义）；
  CLINT（mtime=clk/10）、PLIC（32 source、M/S 双 context 寄存器组、单根合并输出线）、
  16550 子集 UART、virtio-mmio v2 block（宿主 DMA 直捅 pmem）。
  可用内存 = 1GB（PSRAM 512MB + SDRAM 512MB 窗，宿主 pmem 与 NEMU 同为 1GB@0x8000_0000）。
- difftest：NEMU 参考，逐 commit 比 PC+32 GPR；MMIO skip 在 commit 拍按指令解码 EA（EA<0x8000_0000）；
  ecall/ebreak 合成 commit 同步。**只比 GPR+PC，不比 CSR/FPR/内存**。
- 验证套件：97 个模块级 iverilog TB；riscv-tests rv64ui/um/ua/uc/uf/ud/uzba/uzbb/uzbc/uzbs(-p) +
  可选 rv64mi/si（make core-regress）；AM cpu-tests/CoreMark/Dhrystone（riscv64-npc）；
  eval CPI 采集对比体系；yosys-sta(icsprout55@500MHz 目标) 与 Vivado OOC 双轨时序流程。
- Linux 启动基础设施齐备（--load 多镜像/virtio 磁盘/UART 注入/GUEST_EXPECT）；
  RTL 侧 perf 探针体系（分支/cache/stall 分桶直方图）可编译期裁除。

---

## 3. 不能实现什么（缺口清单）

### 3.1 硬正确性缺口（已形式化证实）
1. **自修改代码：8B store 高 4 字节漏失效取指包 cache + fence.i 是真 no-op**。
   `OooFetchPacketCache.same_fetch_window` 把 store 足迹硬编码为 4 字节
   （`cache/OooFetchPacketCache.v:61-82`），对齐 `sd/FSD/SC.D/AMO*.D` 覆盖 A+4..A+7 的取指包
   （fetch_pc=A+4/A+6）被谓词与 index 扫描集双重排除;而 fence.i 译码后是合法 no-op
   （`decode/DecodeUnit.v:779-783`，`REDIR_REASON_FENCEI` 全仓无消费者），无任何保底清除——
   即使软件规范执行 fence.i 也无法恢复一致性。次级：分页开启时 probe 拍失效用 VA、drain 拍用 PA，
   与 VIVT cache 索引错配。（BTC 有 fence 全清保底，但 BTC 本身恒空,无实际影响。）
2. **Sv39 下跨 4KB 页的 misaligned load/store 静默错误翻译**。数据桥只翻译起始 VA 一次，
   第二页字节按"起始 PA 物理连续"读写（`memory/OooMemAxiBridge.v:238-252,455-476`），
   plain 访存 misaligned 又不 trap——分页 OS 下会静默读错/写坏相邻物理页，且 drain nokill 写必达。
   （对照：取指桥有完整双页处理，数据桥无对应物。M-mode 恒等映射下无害,现有测试因此不暴露。）
3. **difftest MMIO skip 对 RVC 压缩访存指令 ref.pc 毒化**。commit 上报 inst 是解压后 32 位
   （EA 判定正确），但 skip 后强制 `ref.pc = pc+4`（`csrc/cpu/difftest.cpp:182`），压缩访存真实
   next=pc+2 → 下一条即假阳性 mismatch 中止。修复：skip 分支改用已传入的 event.next_pc。
4. **unsupported 合法指令的域 B trap 出口悬置**：mode=1 下 dispatch-time unsupported 捕获被门控关闭
   （防 wrong-path spurious trap），stop 仍置位但无捕获出口——依赖"后端支持所有已译码指令"假设成立
   （当前译码白名单与后端能力对齐,故未触发）。

### 3.2 ISA/规范合规缺口
- **ebreak 不产生规范 breakpoint trap**（cause=3 进 mtvec），而是 exit→halted 仿真停机约定
  （semihost ebreak 除外）；分支/跳转目标 misaligned 同样直接 halted 不走 trap 流程。
- **mtvec/stvec 仅 direct 模式**（vectored 写入被 WARL 清除）。
- **medeleg/mideleg 全 64 位可写**，无规范要求的只读 0 位掩码。
- **wfi 忽略 mstatus.TW**（TW=1 时 S/U 态应 illegal）；wfi=no-op 立即提交。
- **rm=DYN 且 frm=101/110 不报 illegal**（静默按 RNE 执行）,规范要求报非法指令。
- Zb 译码两处过宽接受（REV8 的 0x34 变体、OP 域 zext.h 编码）;AMO 的 aq/rl 位不校验。
- 无 debug trigger（tselect/tdata* 为 stub）、无 vectored 中断、无 Sv48/Sv57、无 H/V/Zfh/Zicond/Zicboz 等扩展。
- sfence.vma 忽略 vaddr/asid 操作数（一律全清 TLB）;TLB 无 ASID 共享（satp 整值 tag,保守正确）。

### 3.3 结构性性能边界（非正确性）
- **两桥均单 outstanding**：取指 miss/PTW 期间取指全停;数据侧 MIQ 深 4 只解耦发射,真实 MLP≈1,
  dcache miss 无重叠。这是当前最硬的 IPC 天花板之一（B-LSQ 的 MSHR 部分未做）。
- Sv39 开启时 SQ 前递/重叠精判整体退化为 blind 阻塞（VA 别名不安全）——虚存负载下访存乱序收益大减。
- 每拍至多 1 条访存进桥（mem1 第二端口已删）;store 零乱序（必须 IQ 最老才发射）;无 load queue/
  依赖预测/replay。
- 非返回 JALR 预测实际只剩 RAS/fallthrough 两级（JALR-BTB 恒空）;RAS push 条件极保守
  （rob_count==0 才 safe,否则整栈清空）+ 每次 mispredict 清 RAS——RAS 命中率结构性受限。
- MMIO 独占串行 + 0x9000_0000..0xbfff_ffff 的 768MB 内存被核内当 MMIO 处理
  （PMEM 判定窗仅 256MB,`define.v:152-157`）——带大内存跑 OS 功能正确但该区间访存性能悬崖。
- CSR/系统指令每条全后端排空（数十拍）;CLMUL 固定 64 拍;FDIV/FSQRT 不流水且互斥。
- 取指宽度硬上限 2 条/8B 包,RVC 密集代码有效带宽打折;单 outstanding + count<2 哨兵在 redirect
  风暴下形成恒 mispredict 链。

### 3.4 平台/工具边界
- difftest 不比 CSR/FPR/内存;perf 构建（rv64_perf_defconfig）编译期剔除 difftest。
- VirtIO DMA 在宿主侧直写 pmem,RTL 总线/dcache 无 snoop（一致性靠软件/使用约定）。
- 整核 Vivado P&R 在当前 15.7GB WSL 不可行（自述于 `vivado/run-pnr-core.sh` 头部）,
  时序决策依赖模块级 OOC Logic Levels 代理。
- byte-window 总线语义（wstrb 低位连续、araddr 任意错位、非标 arstrb）是对仿真 DPI slave 的
  硬编码假设,非标准 AXI,不能直接对接真实外设 IP。

---

## 4. 死硅普查（编译在册、功能死）

以下均为**活文件中的死通道/死存储**（在 filelist.mk、被实例化,但被编译期常量或结构性不可达证死）。
拆除前必读 `.github/task-runs/2026-07-03-rv64-rtl-reread-audit/answers.json` 的形式化证据链。

| 死硅 | 判死机制 | 关键证据 |
| --- | --- | --- |
| pending_branch / pending_jump 全链（2 个 Sequencer + PendingControlResolveGate + RecoveryGate 的 pending/spec 臂） | capture 被 `!rob_walk_mode` 门死（OOO_ROB_WALK_MODE=1'b1） | `control/OooPendingDispatchArbiter.v:160-171` |
| pending_mem 全链（OooPendingMemorySequencer + mux mem 臂 + DrainResolveGate mem 注入） | lane1 barrier 条件不含 FACT_MEM,严格互斥 → capture 恒 0（可整链删除） | `control/OooPendingLane1CaptureGate.v:50`、`frontend/OooFrontendDispatchGate.v:102-109` |
| dispatch 拍分支快解析全族（IntBackend candidate/CompareUnit/FAST_BRANCH_TRACK 8 项表/PRF read4-5、DirectBranchResolveGate dispatch 臂） | `!(OOO_DBRANCH_DOMAIN_A)` 恒 0 | `execute/OooIntBackend.v:531-532` |
| BPU 更新旧四臂（direct/pending/drained/commit）→ 只剩 issue-resolve 单源 | 依赖拍内解析或 pending_branch,均死 | `frontend/OooBranchBpuUpdateGate.v:33-35` 注释自证 |
| OooBranchTargetCache（BTC 16 项）+ CaptureBuffer | 唯一填充路径依赖拍内解析 → 恒空;消费端 append 又被 `BRANCH_APPEND_DISPATCH_ENABLE=1'b0` 关死（双重死） | `frontend/OooBranchTargetCacheControlGate.v:44-49`、`OooBranchAppendDispatchGate.v:68` |
| JALR-BTB 更新口 | update 依赖 pending_jump 恒 0 → 表恒空 → spec 查询恒 miss | `frontend/OooPredictorUpdateGate.v:17-19` |
| branch/JALR prefetch 全家桶（Buffer/Request/Source/Status/ClearGate + 2 个 HitMux + JalrPrefetchStatusGate） | req 依赖 pending_branch/btb_hit 恒 0 | report-1 |
| OooReturnContBuffer | consume 端 `return_cont_attempt_o=1'b0` 硬禁 | `frontend/OooBranchAppendDispatchGate.v:82` |
| OooSyntheticLane1Ret 家族（Sequencer/CommitGate + CommitOutputMux 合成臂） | capture 依赖拍内解析同拍谓词,设计路径死 | `writeback/OooWriteback.v:142-144` |
| checkpoint 影子阵列五套（FreeList/RenameMap/BusyTable/IQ/ROB） | `cp_*` 恒 gate 0（ROB-walk 已取代） | `rename_allocate/OooDispatchBackend.v:485-486` |
| OooBranchSpecTracker 的 active/checkpoint 机制 | capture 恒 0;但 checkpoint_pending 仍会置位并压制 RAS 更新（副作用活着,机制死) | report-1 |
| OooRedirectArbiter.v | **未编译**（filelist 只定义变量未入 RTL_CORE_SRCS）+ 零实例化,仅 TB 引用 | `vsrc/filelist.mk:85` |
| fetch 响应 bypass 直通 dispatch 通路 | `OOO_ROB_WALK_MODE=1` 恒禁（防 bypass-after-kill） | `frontend/OooFrontendRunGate.v:62-70` |
| WBU 的 LOAD 源臂 | load_data 口两实例恒接 0（load 走 mem rsp 通道） | `execute/OooIntBackend.v:801,811` |
| IQ load-branch-fast 输出族 + pending_load0/1 | 消费端已删（E7),IQ 内 ~60 行选择逻辑空转 | report-3 |
| PRF read4/5/6/7/9 五个读口 | 消费死硅/声明后未用/地址接 0（"10R2W"实际有效 5R2W） | report-3 |
| 死宏 | `CACHEABLE_BASE/LAST`（与实际 256MB PMEM mask 矛盾!）、`NPC_AXI_SPI_*`、`BPU_RAS_*`、`REDIR_REASON_*` 全仓零消费 | `include/define.v:53-58,86-91` |
| csrc 侧 | `csrc/memory/cache.c`（宿主 cache 模型,uint32_t 地址 RV32 遗留）、`csrc/device/serial.c`、`perf/scripts/bench.sh|profile.sh`（riscv32 遗留）、`perf/configs/perf_defconfig`（过时副本,构建不读） | report-8 |

**理论风险残留**（死而未 tie-off）：DirectBranchResolveGate 的 issue 臂靠"跨实例 PC 别名巧合"仍可
触发（紧循环+长延迟可构造）,巧合发生时 lane1-ret 合成 commit 存在双提交理论风险——
建议显式 tie-off（见 answers.json #1 open questions）。

---

## 5. 验证现状的证据边界

- 文件系统证据证明被大量跑过：eval/results 57 个运行目录、perf/results 364 个、vivado/out 36 个。
- 本次审计**只读源码,未跑仿真**,"当前全绿与否"不在本文件断言范围;历史通过状态见
  `.github/memory/project-status.md`。
- riscv-tests 仅跑 -p（物理内存）变体,无 -v 虚存变体——§3.1-2 的跨页 misaligned 缺口因此不被现有套件覆盖。
- ACT/arch-test 入口不在本目录（已迁 `am-kernels/arch-test`）;Linux/Ubuntu 启动编排在仓库根 `Linux/`。

---

## 6. 与旧文档的关系

- 本文件产出的同时,对 `design/arch/*.md`、`design/specs/*.md`、三个 README 与
  `.github/memory/*` 做了逐份对照校正/归档（记录见 task-run 目录与 `design/specs/history/README.md`）。
- 微架构宪法 `ooo-core-architecture.md` 的 normative 部分（C1-C7、对象契约、owner 表纪律）继续有效;
  其【现状】层已按本文件同步。
