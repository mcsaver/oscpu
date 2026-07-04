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
| RAS | 32 深（`OooRasStack.v` 的 DEPTH=32；旧 define.v 死宏 BPU_RAS_*=16 已于 2026-07-03 删除） | `frontend/OooRasStack.v` |
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
1. **自修改代码：~~8B store 高 4 字节漏失效取指包 cache~~ 已修复(#3A) + fence.i 真 no-op(#3B 待落地)**。
   ~~`same_fetch_window` store 足迹硬编码 4 字节~~ **→ #3A 已修复（2026-07-03）**：足迹高端 4→8B
   (`cache/OooFetchPacketCache.v` same_fetch_window +3→+7) + 邻域补 p4/p6(idx base+2/+3, INVALIDATE_DELTA_2/3),
   覆盖 8B SD 改写区 [base,base+7] 跨两个 4B 块的高半取指包(fetch_pc=A+4/A+6)。加宽只多失效恒安全(cache 纯性能,
   miss→重取)。**定向证否**:packet cache 模块 TB 加 p4/p6 case(修复前 4 CHECK-FAIL=高半包 got hit=1 未失效,
   修复后 PASS), 零回归(riscv 355/0、模块 TB 96/96)。
   **#3B fence.i 真生效待落地**：fence.i 现译码后合法 no-op(`decode/DecodeUnit.v:781-788` 与 fence 不分), 无重取
   触发——覆盖"投机越过 fence.i 已入 ROB 的年轻改写指令"(#3A 只失效 cache, 管不到已取入 ROB 的项)需让 fence.i 成
   barrier + commit 触发 mmu_flush/redirect(CTRL_BUS_W 扩宽 + 复制 sfence pending_system 提交路径, 5 模块、与 #3A
   部分冗余、fence.i 频繁代码有 perf 回归), 单列评估。次级：分页开启时 probe 拍失效用 VA、drain 拍用 PA，与 VIVT
   cache 索引错配。（BTC 有 fence 全清保底，但 BTC 本身恒空,无实际影响。）
2. ~~**Sv39 下跨 4KB 页的 misaligned load/store 静默错误翻译**~~ **→ 已修复（2026-07-03，最小精确异常）**。
   曾经：数据桥只翻译起始 VA 一次、第二页字节按起始 PA 物理连续读写（`OooMemAxiBridge.v:455-476/490`），
   plain 访存 misaligned 又不 trap（`OooIntBackend.v:1094` 原门只放 AMO）→ 分页 OS 下静默读错/写坏相邻物理页。
   **修复**：`OooIntBackend.v:1094` 拓宽发射拍异常门——对"分页开(`mem_translate_active_i`) + plain LS +
   misaligned + 跨 4KB 页(EA[11:0]+size>0x1000)"抛精确 LOAD/STORE_ADDR_MISALIGN(cause 4/6, tval=EA),
   交软件 trap-and-emulate；cause/tval/请求关断/ROB-commit 上报整链复用 AMO misaligned 机制零改。misaligned
   在发射拍**预占翻译**(不发桥请求),故页内 misaligned 仍由 byte-window 硬件正常支持不 trap、对齐/M 态/satp=Bare
   全不受影响。**验证零退化**(riscv 355/0、模块 TB 96/96、difftest 38/3)+ **新增定向自检 cpu-test
   `am-kernels/.../sv39-xpage-misalign.c`**(分页开跨页 misaligned store → GOOD TRAP,证 cause 6/tval=EA)。
   注：现有套件全 -p 物理/分页用例全对齐,对此零覆盖,故定向 TB 是本修的必需守护(独立跑,不挂 difftest——NEMU
   对同一跨页 misaligned 是静默字节仿真不 trap,属参考模型有意分歧)。"完整硬件双页支持"(镜像取指桥双 walk)可作后续独立项。
3. ~~**difftest MMIO skip 对 RVC 压缩访存指令 ref.pc 毒化**。~~ **→ 已修复（2026-07-03）**：
   `csrc/cpu/difftest.cpp:182` 的 skip 分支已从写死 `pc+4` 改为用已传入的 `next_pc`（对压缩访存=pc+2、
   非压缩=pc+4，访存非控制流恒不误预测故 next_pc 即真实后继）。验证：difftest 计算子集 38/3 与改前
   逐字节一致（git-stash 基线证否——当前测试集 putch 走字节存储 sb、RVC 无 c.sb 恒 4 字节故本修不触发，
   属潜伏正确性修复，将在压缩 word+ 存储命中 MMIO 时兑现）。〔那 3 项 difftest FAIL 为既有 divergence，见 §5〕
4. ~~**unsupported 合法指令的域 B trap 出口悬置**~~ **→ 已修复（2026-07-03，结构性零回归）**：mode=1 下
   dispatch-time unsupported 捕获被门控关闭（防 wrong-path spurious trap），stop 仍置位但无捕获出口。
   **修复**=`OooFetchHeadClassifyGate.v` 加 `unsupported_residual_w = ctrl_legal && !NEED_EXEC` 折入
   arch_trap→head0 精确出口(受 squash 保护、不受 rob_walk 门控), 而非删 :308 门(删门会重引 dispatch 投机 spurious)。
   该残差对当前 ISA 恒 0(DecodeUnit 仅 :758/:763 置 NEED_EXEC=0 且都保持 ILLEGAL=1→ctrl_legal=0), 属补齐
   latent 缺口的防御性精确出口, 结构性零回归(riscv 355/0)。模块 TB 加 unsupported_residual case 验证。

### 3.2 ISA/规范合规缺口
- **ebreak 不产生规范 breakpoint trap**（cause=3 进 mtvec），而是 exit→halted 仿真停机约定
  （semihost ebreak 除外）；分支/跳转目标 misaligned 同样直接 halted 不走 trap 流程。
- **mtvec/stvec 仅 direct 模式**（vectored 写入被 WARL 清除）。
- **medeleg/mideleg 全 64 位可写**，无规范要求的只读 0 位掩码。
- ~~**wfi 忽略 mstatus.TW**~~ **→ 已修复（2026-07-03）**：`OooFetchHeadClassifyGate.v` 加 `wfi_tw_illegal`
  (priv<M 且 mstatus.TW=1 → priv_system_illegal → arch_trap)。现有测试全 TW=0,零回归(riscv 355/0)。
- ~~**rm=DYN 且 frm=101/110/111 不报 illegal**~~ **→ 已修复（2026-07-03）**：不走 OooFpBackend 新增 illegal 通路,
  而是**前端 classify 拿 committed frm 判非法**(与 fp_disabled 同类"该 trap 却在执行的 FP"): `OooFetchHeadClassifyGate.v`
  加 `fp_dyn_frm_illegal = fp_rm_bearing && rm==111 && frm∈{5,6,7}` 折入 illegal_raw→arch_trap, 同步关 fp_enabled
  (否则既 trap 又派 FP 簇); frm_i 经 pair-gate/frontend/glue 贯穿(csr_frm_w 复用, 无新顶层网)。静态 reserved rm(101/110)
  已由 OooFpDecode:59 排除。CSR 写属 stop 类串行→保证 frm 在 head 分类时已 commit。模块 TB 加 DYN+frm=5 illegal /
  DYN+frm=2 legal 对照 case, 零回归(riscv 355/0、rv64uf/ud 23/23)。
- ~~Zb 译码两处过宽接受（REV8 的 0x34 变体、OP 域 zext.h 编码）~~ **→ 已修复（2026-07-03）**：`DecodeUnit.v`
  REV8 收紧到 funct7=0x35(删 0x34 RV32 rev8.w)、删 OP 域 zext.h(RV64 zext.h 是 OP-32=is_zb_op_32:152)。
  objdump 证 rv64uzbb-p-rev8/zext_h 用正确编码(0x35/OP-32),零回归(riscv 355/0)。AMO 的 aq/rl 位不校验(4 组合皆合法,合规)。
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

> **B4 物理删除进度（2026-07-04 起，逐项 cycle-exact 中性验收）**：已删 csrc 死代码、PRF read6/7/9、
> OooSyntheticLane1Ret 家族、五套 checkpoint 影子阵列（下表已标 commit）。前端 prefetch/BTC 网、
> pending branch/jump/mem 链、dispatch 拍快解析族、WBU LOAD 臂、IQ load-branch-fast、fetch bypass 待删。

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
| ~~OooSyntheticLane1Ret 家族（Sequencer/CommitGate + CommitOutputMux 合成臂）~~ **已删（2026-07-04, B4, 21c7fbe14）** | capture≡0（direct_branch_resolve 两臂受 OOO_DBRANCH_DOMAIN_A=1 恒0）→自洽全零不动点;跨模块输出在 OooCoreTopGlue 常量0 tie-off | `writeback/OooWriteback.v:142-144` |
| ~~checkpoint 影子阵列五套（FreeList/RenameMap/BusyTable/IQ/ROB）~~ **已删（2026-07-04, B4, a7d5c5661）** | `cp_*` 恒 gate 0（ROB-walk 已取代）;6 模块 TB 同步退休 checkpoint 场景;ROB-walk 活恢复完整保留 | `rename_allocate/OooDispatchBackend.v:485-486` |
| OooBranchSpecTracker 的 active/checkpoint 机制 | capture 恒 0;但 checkpoint_pending 仍会置位并压制 RAS 更新（副作用活着,机制死) | report-1 |
| ~~OooRedirectArbiter.v~~ **已删档（2026-07-03）** | C7 统一 redirect 仲裁地基,从未接入编译列表/零实例化 → 删档减负（模块+TB+filelist 变量+`REDIR_REASON_*` 宏全删；lint 0/模块 TB 96/96）。当前仲裁=`OooFetchRequestMux` 隐式优先级链；若重启统一 arbiter 从 git 历史复活 | 已删除 |
| fetch 响应 bypass 直通 dispatch 通路 | `OOO_ROB_WALK_MODE=1` 恒禁（防 bypass-after-kill） | `frontend/OooFrontendRunGate.v:62-70` |
| WBU 的 LOAD 源臂 | load_data 口两实例恒接 0（load 走 mem rsp 通道） | `execute/OooIntBackend.v:801,811` |
| IQ load-branch-fast 输出族 + pending_load0/1 | 消费端已删（E7),IQ 内 ~60 行选择逻辑空转 | report-3 |
| PRF ~~read6/7/9~~ **已删（2026-07-04, B4, e72948c90）** + read4/5（保留） | read6/7/9 零消费者/地址接0 已删;read4/5 实为 dispatch 拍快解析族一部分(喂 CompareUnit)→随该族一起摘,暂 SKIP | report-3 |
| 死宏 | ~~`CACHEABLE_BASE/LAST`、`NPC_AXI_SPI_*`、`BPU_RAS_*`、`REDIR_REASON_*`~~ **全部已删除（2026-07-03，lint 0/0 残留）**（`REDIR_REASON_*` 随 `OooRedirectArbiter.v` 删档一并删——唯一消费者已无） | `include/define.v` |
| csrc 侧 | ~~`csrc/memory/cache.c`、`csrc/device/serial.c`~~ **已删（2026-07-04, B4, 15497d2bd）**（连带 NpcSimTop.sv DPI hook + paddr.c init 调用）;`perf/scripts/bench.sh\|profile.sh`、`perf/configs/perf_defconfig`（riscv32 遗留,doc-lifecycle 待清） | report-8 |

~~**理论风险残留**（死而未 tie-off）：DirectBranchResolveGate 的 issue 臂靠"跨实例 PC 别名巧合"仍可
触发（紧循环+长延迟可构造）,巧合发生时 lane1-ret 合成 commit 存在双提交理论风险~~
**→ 已修复（2026-07-03）**：`OooDirectBranchResolveGate.v` 的 `direct_branch_issue_resolve_valid_w`
已用 `!(\`OOO_DBRANCH_DOMAIN_A)` 显式门死（F2 下恒 0，dispatch 臂本就由源头 `dispatch_resolve_valid_i=0`
门死），双提交理论风险消除。验证：模块 TB 97/97（`tb_ooo_direct_branch_resolve_gate` 契约同步更新为
随模式断言 F2→0/mode0→1，未弱化检查）+ riscv-tests 353/354（唯一 FAIL=`rv64mi-p-illegal` 为既有失败，
git-stash 基线证否，与本改动无关）。

---

## 5. 验证现状的证据边界

- 文件系统证据证明被大量跑过：eval/results 57 个运行目录、perf/results 364 个、vivado/out 36 个。
- 本次审计**只读源码,未跑仿真**,"当前全绿与否"不在本文件断言范围;历史通过状态见
  `.github/memory/project-status.md`。
- riscv-tests 仅跑 -p（物理内存）变体,无 -v 虚存变体——§3.1-2 的跨页 misaligned 缺口因此不被现有套件覆盖。
- **✅ 已修复（2026-07-03）：`rv64mi-p-illegal`**（曾是 F2 核唯一 riscv-tests 失败，353/354）。
  修复后 riscv-tests(默认+特权) **355/0 全绿**、模块 TB 96/96、difftest 38/3 不变（零退化）。
  **根因（5+探针逐层钉死，沿途证否 3 个错误假设：head1-drop / trap-PC 捕获=0 / CSR 读陈旧均被架构退休真相推翻）**：
  `OooFetchHeadPairGate.v:190` 的 `head1_decode_valid_w` 含 `!head0_facts[OOO_SLOT_FACT_BRANCH]`
  → **head0=分支时 head1 不译码(facts 全 0)** → `head1_system_raw=0` → 前端双发 `dbranch_dual_go`
  看不到 head1 是 CSR/system → 把 CSR 双发进 domain-A（domain-A 不执行 CSR→读回 0）。表现：trap handler 包
  `[bne(head0), csrr mepc(head1)]` 里 csrr mepc 读回 0（mepc 寄存器却=0x264，`NPC_TRAPWATCH` 证），
  handler `beq t0,bad标签` 全不匹配 → `j fail`。这是 `OooFetchHeadClassifyGate:132-134` 注释点名的
  "head0=FP 压制 head1"FP 家族 bug 的**分支版**（FP 已修、分支没修）。
  **修复**：去掉 `head1_decode_valid_w` 的 `!head0_facts[OOO_SLOT_FACT_BRANCH]`（仅 BRANCH，保留 JUMP/STOP）——
  head0=分支时也译码 head1 → head1_system_raw 正确 → dbranch_dual_go 正确排除 head1=system → 分支 fire+重取
  head1 → csrr 成 head0 走 domain-B 读对；head1=普通指令行为不变。
  **方法学**：dispatch 侧探针会被投机/双发/截断 confound；用 `NPC_TRAPWATCH`/`NPC_COMMITWATCH`（env,免重编）
  取架构退休真相定死（详见记忆 [[rv64mi-illegal-preexisting-f2-fail]]）。
- ACT/arch-test 入口不在本目录（已迁 `am-kernels/arch-test`）;Linux/Ubuntu 启动编排在仓库根 `Linux/`。

---

## 6. 与旧文档的关系

- 本文件产出的同时,对 `design/arch/*.md`、`design/specs/*.md`、三个 README 与
  `.github/memory/*` 做了逐份对照校正/归档（记录见 task-run 目录与 `design/specs/history/README.md`）。
- 微架构宪法 `ooo-core-architecture.md` 的 normative 部分（C1-C7、对象契约、owner 表纪律）继续有效;
  其【现状】层已按本文件同步。
