# RV64 OoO RTL Ground Truth — 2026-07-11

> **类型**：snapshot + current delta（2026-07-28 product-default current replay 校正）。
>
> **状态**：CURRENT。主体基于代码快照 `cab1814b0622e53e1e62f2b0fc17ed6873c72ba2`；
> current delta 已绑定
> `design_id=sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
> 2026-07-28 同步 queue-head CSR 产品配置与 26-stage current replay；下一次结构性架构切片必须生成新的
> dated snapshot 并把本文件整体归档，避免继续累积 delta。
>
> **预期归宿**：下一份 ground-truth snapshot 产生时，移入 `history/` 并登记为
> `SUPERSEDED`；不要在本文件累积跨版本实施历史。
>
> **读法**：架构原则与目标由 `ooo-core-architecture.md` 规定；本文件只冻结当前
> `as-is`。若数字或接线与 RTL 冲突，以当前 RTL 为准，并在同一任务内校正文档。

---

## 0. 2026-07-28 current delta

- Makefile 消费 `configs/product-rtl-defaults.mk`，规范配置为
  `OOO_CSR_QUEUE_HEAD=1`、`OOO_TERMINAL_HOLDER_ASSERT=1`；`define.v` fallback
  与之相同。产品默认生成 RTL 与 A3/A4 的 51 个 Verilator 文件逐项等价，
  8 个 device objects 与 `cpu-exec.o` 精确一致，因此没有触发完整系统重跑条件。
- queue-head CSR assertions-on/off 均覆盖 3 条 committed 与 2 条 selectively-killed
  事务；C2 typed-apply replay、C2 CsrFile-request replay 两个 compile-success
  负向版本均被 raw scoreboard 拒绝；后者是生产绑定等价 verification wiring，
  不宣称为第二份 production RTL mutation。
- 产品默认 pending-SYSTEM matrix 为 3/3 baseline + 14/14 compile-success mutation；
  current replay 为 26/26 stages、module 113/113、official 177/177、AM 59/59、
  DiffTest mismatch 0。V10G 第二次独立审查已批准
  `SERIALIZE-G1=CLOSED`；historical-defect backfill 尚未清零，因此
  `ARCH_STABLE=GAP`、PPA `UNQUALIFIED`。
- A3 原始发布 FAIL 不变；系统执行、终端事务与 RTL assertions 分类独立记录为
  COMPLETE/COMPLETE/CLEAN，旧 dmesg oracle 分类为 INVALID，冻结输入上的 checker
  replay 为 PASS。A4 TERM 不作为系统 PASS 证据。

## 1. 当前定位与真实拓扑

当前实现是一颗已经闭环的小窗口 RV64 OoO 单核，不是顺序核外围增加 OoO 命名：整数和
FP 都进入 rename、物理寄存器、IQ、ROB、完成和顺序退休体系；访存、特权、MMU 与总线
状态机也在真实主路径上。

```text
NpcSimTop                         仿真 shell
└── NpcTop                       SoC / 综合顶层
    ├── NpcCoreTop               CPU 边界：IFU + LSU 两个 64-bit master
    │   ├── OooFetchAxiBridge    packet cache / ITLB / PTW / PMP / A update
    │   ├── OooMemAxiBridge      Dcache / DTLB / PTW / PMP / A-D update
    │   ├── OooCoreTopGlue       微架构装配根
    │   │   ├── OooFrontend      packet/RVC/BPU/RAS/dispatch/redirect
    │   │   ├── OooExecuteBackend -> OooIntBackend
    │   │   │   rename/ROB/IQ/short EX/MulDiv/CLMUL/FP/SQ/MIQ/completion
    │   │   ├── OooMemoryAccess
    │   │   ├── OooControlPlane
    │   │   └── OooWriteback
    │   └── CsrFile
    └── NpcAxiBus / AxiXbar      UART / CLINT / PLIC / memory / MMIO
```

这不是固定线性“八级流水”。更准确的模型是 packet 前端、rename/ROB、整数/FP IQ、多个
可变延迟执行域、共享双完成口、顺序双退休，以及独立 memory/control FSM 的解耦拓扑。

## 2. 宽度、容量与真实并行度

| 项目 | 当前值 | 边界 |
| --- | --- | --- |
| fetch/decode/dispatch | 每拍最多 2 条 | 每个 8B packet 最多展开两条，无通用 byte queue |
| commit / global completion | 2 / 2 | 中心域双宽，不代表所有执行资源双宽 |
| fetch FIFO | 4 packets | 每包最多两条 |
| IFU outstanding | 1 | miss/PTW/redirect 目标取指强串行 |
| int PRF / FP PRF | 64 / 64 | 独立 rename/free/busy |
| ROB | 16 | dispatch 2 / commit 2 |
| int IQ / FP IQ | 8 / 8 | int 最多 issue 2；FP issue 1 |
| SQ / MIQ | 4 / 4 | bridge 只有 active+staged，MIQ4 不等于四笔 AXI 并行 |
| RAS | 32 | 使用窗口保守 |
| ITLB / DTLB | 各 64，direct-mapped | 单 walker |
| BPU | gshare1024/GHR10 | local history256×8、local PHT4096 |
| fetch packet cache | 4096×199 bit | 精确 PC packet、direct-mapped |
| Dcache | 4096×8B = 32KiB | 8B line、direct-mapped、write-no-allocate |
| MulDiv / CLMUL | 各单实例 | 迭代、单在飞 |
| FP short arithmetic | 外部结果对齐第 5 拍 | 无回压时可每拍 launch 1 条 |
| FP div/sqrt | 共享 long-meta 域 | 约 56 步、单在飞 |

## 3. 当前已经形成的主路径

- RV64 I/M/A/F/D/C、Zicsr 与当前实现的 Zba/Zbb/Zbc/Zbs 路径；保留编码是否被正确
  拒绝必须另看 §5，不能由已覆盖合法用例外推。
- M/S/U、CSR、trap/interrupt/delegation、direct-only mtvec/stvec。
- Sv39 4KiB/2MiB/1GiB、Svnapot64K、SUM/MXR/MPRV、ITLB/DTLB、硬件 A/D update。
- PMP16：TOR/NA4/NAPOT、最低编号优先、full-coverage、M-mode lock 语义。
- int/FP rename、PRF、busy/free、IQ、ROB、双完成、双退休；FP fflags 随 ROB 提交。
- branch direction prediction、fetch-time taken path、RAS、ROB age kill + 双宽 reverse walk。
- fetch redirect PC 已由 `OooRedirectArbiter` 按年龄律单源化；其 kill/reason/flush_backend
  输出尚未成为整个控制面的唯一来源。
- store probe -> SQ fill -> ROB retire -> committed drain；受限的整数 store-to-load
  forwarding；Dcache 与最小单拍 AXI4-to-AXI4-Lite 路径。
- `fence.i` 已进入 pending system commit / `mmu_flush` / 清取指状态 / 重取路径，不再是 no-op。

## 4. 当前结构限制与未实现能力

- 普通 JALR 没有有效 target predictor/BTB；branch prefetch、BTC、return continuation 已删除。
- IFU 单 outstanding；BPU history 非投机，每拍只训练一个 source。
- IQ 全表 oldest-ready 扫描与 compact；int/FP PRF 是多口异步 FF 阵列；completion 固定优先级。
- wrong-path FP div/sqrt 可清 metadata，但迭代器本身仍可能继续占用。
- 无 load queue、memory dependence predictor、violation replay、MSHR、hit-under-miss、L2、
  coherence 或 ECC；Dcache 只有 8B line。
- 产品默认 `OOO_CSR_QUEUE_HEAD=1`：合法 non-FP head0 CSR 走 queue-head
  `birth→C0 commit/CsrFile/barrier→C1 apply/clear→C2 quiet`；lane1/FP CSR 与
  system/trap/interrupt/fault 仍走 pending + full drain。显式 `=0` 仅为比较/恢复配置。
- 普通 `FENCE` 当前译码为 legal no-op，`pred/succ` 未进入专用排序控制。
- WFI 不是真正 sleep；SFENCE/SINVAL 偏全刷；无 vectored trap、完整 debug/trigger、NMI、
  H、V、Zfh 或多核一致性。
- A 扩展 reservation 只在本 hart 内部；外部写无 invalidation/snoop，AXI 无
  exclusive/lock/coherence，不能外推到多主平台级原子事务。
- AXI 使用单拍、单 outstanding 有效子集；不支持 burst、多 ID 并行。

## 5. 正确性合同状态

除明确标为 CLOSED 的条目外，以下内容描述当前仍开放的 RTL 合同：

1. **FDG-G1 — CLOSED；V9D 于 2026-07-21 重绑当前设计：head0 arch-trap 不得呈现 backend**

   当前 source-to-sink 为 `OooFetchHeadClassifyGate/OooFetchHeadPairGate` →
   `OooFrontendDispatchGate` → `OooFrontendBackendDispatchMux` → `OooCoreTopGlue` backend；
   ordinary、lane1 和 unsupported admission 方程均排除 `dispatch0_arch_trap_i`，父级
   `OooFrontend` 以 `FDG-I1` 立即断言守护。精确 trap owner 独立经
   `OooPendingDispatchArbiter` → `OooPendingTrapExitSequencer` →
   `OooCsrTrapRequestMux/CsrFile` 保存 cause/PC/tval。

   V9D focused 证据覆盖 4 类非法 FP 均分类为 `arch_trap`、backend 0 呈现，以及 1 个合法
   FADD.S 正控制；全核程序精确捕获 1 次非法指令 trap，capture PC/tval 与 CSR
   `mepc/mtval` 各 1/1，同一 commit observation interface 命中 1 条已知 ADDI、非法 FP 0
   提交，并完成 handler/MRET。6/6 current-source 可编译 RTL 验证变体及 1/1 commit-observer
   非空性探针被动态拒绝，current module 109/109；
   canonical command 为 `make -C npc/rv64 check-fdg-arch-trap`，绑定
   `design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
   V9D 未修改生产 RTL，也未把旧 AM/official 结果扩写成当前同源 aggregate。

2. **XRET-G1 — CLOSED 2026-07-12：current-mode 合法性**

   `OooFetchHeadClassifyGate` 已在唯一 privileged-illegal 汇合点加入
   `MRET && priv!=M` 与 `SRET && priv==U`；S-mode+TSR 的 SRET 保持非法，M-mode SRET
   不受 TSR 越权拦截。旧 RTL 对 MRET-from-S/U、SRET-from-U 精确 6 fail；真实编码整核
   integration 进一步覆盖 S-mode lane0 MRET 与 U-mode lane1 SRET，检查 illegal cause、
   `mepc/mtval`、handler return 与 no illegal-xRET commit。current module 87/87、AM 59/59、
   official 177/177 均通过；CsrFile 不复制 legality decode。

3. **MEM-ISSUE-G1 — CLOSED 2026-07-12：lane1 dequeue/request/MIQ owner 同源**

   `OooIntBackend` 已把 lane0 order/SQ/AMO 公共资格抽成不依赖 ready 的
   `issue0_mem_issue_eligible`，并只在 lane0 非 memory 或本地异常且 eligible 时授予
   lane1 memory port owner。旧 RTL 精确复现 IQ pop 无 request；独立 reviewer 又以更老
   CLMUL + head-blocked misaligned LR 证伪过宽首版，锁住 request/MIQ 先于 IQ pop 的幽灵事务。
   `MEM-I1/I2` 检查 IQ、request mux 与 MIQ owner；current module 87/87、Difftest-ON AM
   59/59、official 177/177 均通过。

4. **IFU-AXI-G1 — CLOSED 2026-07-12：A-update write flush-drain**

   `OooFetchAxiBridge` 已把 reset 与 mmu flush 分离；`S_AD_UPDATE` 用 sticky `ad_drop_q`
   作废旧 fetch 语义，同时保持 PTE payload 与 AW/W accepted 位，补齐 channel 并消费 B 后
   才回 IDLE。旧 RTL bridge 22 RED、bridge+xbar 3 RED 精确复现 owner 遗弃/后一 master
   无进展；修复后同用例、同拍 corner、12 条独立 shadow 负探针、module 88/88、AM 59/59
   与 official p-mode 153/153 全绿。当前配置 Difftest OFF，privileged rv64mi/si 本轮未重跑。

5. **IFU-FETCH-G2 — CLOSED 2026-07-12：page-end page-fault byte provenance**

   bridge 已删除 `first_bytes<4` 的长度猜测，并以 3-bit split 保存 first/second-page segment
   response；`OooFetchPacketDecode` 成为唯一 C/32 长度 owner，按完整半开 byte range 生成
   per-slot response，faulted inst 净化为 NOP。旧 RTL 真实 Sv39 B=2/4/6 12 行矩阵精确
   4 RED；current focused 5/5、module 89/89、AM 59/59、official 177/177、9/9 assertion
   non-vacuity 与独立 reviewer 8/8 全绿。

6. **IFU-ACCESS-G1 — 精确物理 footprint/access-fault owner（OPEN）**

   IFU 仍固定发 exact-address 8B read，xbar/slave 未完整保留 ARSIZE，PMP 仍按固定两个 4B
   word 检查；`IFU-LANE1-OWNER` 子节点还发现 PairGate 会在 head0 branch 后压掉 lane1
   page/access fault，ROB-walk 对 instruction-access fault 另有 cause filter。简单 B/(8-B)
   会在不知道 L0+L1 时继续过查；`pmp_active=0` 的 cache-hit allow 分支还会在 M-fill 后切
   S/no-PMP 时绕过 S/U default deny。必须以增量/窄读、PMP/RRESP、M→S cache context 与
   pred-NT/actual-taken branch 下的精确 fault capture/squash 整体关闭。G2 只关闭
   bridge→decoder response owner。

7. **IFU-TVAL-G1 — faulting instruction portion 地址（OPEN）**

   当前 fetch fault payload 统一使用 slot 起始 PC；跨 segment 32-bit 指令的 faulting portion
   `mtval/stval` 合同与程序证据尚未冻结。G2 只关闭 response owner。

8. **PTW-PMP-G1 — A/D PTE 写回缺独立 PMP WRITE 判定**

   walker 读取 PTE 时做 read check；进入 A/D update 后未见以 WRITE 类型重新检查 PTE
   物理地址。

9. **MIQ-G1 — flush 与 DRAIN pop 同拍可留下 ghost entry**

   MIQ 局部动态已复现；年轻同步异常与更老 retired-store drain 的默认整链交叠为高置信
   静态序列，尚无完整 NpcCoreTop 程序波形。另一个 MIQ full+pop 模块反例在当前
   active+staged bridge 下不可达到 full=4，只是未来扩展前的潜伏接口项。

10. **INSTRET-G1 — CLOSED 2026-07-21：唯一 ISA-retirement 计数源**

   `OooCommitOutputMux` 的最终可见 lane 统一过滤异常退休并合并 control-path
   pseudo-commit，`OooWriteback/NpcCoreTop` 只把该最终计数送入 `CsrFile`。V9C 全核 Sv39
   程序证明两条异常 lane 均为零增量，MRET/SRET/SFENCE.VMA 分别 1/6/1 次精确单增量，
   control commit 8/8 且 CsrFile prior-edge 检查 1052 次；3/3 current-source 可编译 RTL
   验证变体被动态拒绝。canonical command 为 `make -C npc/rv64 check-instret-retirement`。

11. **store/device 平台边界**

   retired store 的 late B error 已无 ROB entry，只能报告；Sv39 device 访问资格按翻译前
   VA 数值窗分类；对齐 full-beat device read 会丢原 lane/size。后两项仍需
   bridge+xbar+device 联测冻结最终平台合同。

## 6. 验证与 PPA 证据边界

### 6.1 当前可直接采信

- 2026-07-11 core-regress 中 177 个 official `riscv-tests` 项逐项记录为 PASS。
- IFU-FETCH-G2 current-source focused 5/5、module 89/89、AM 59/59、official 177/177；
  9 个新增 marker 均有 exact 独立违约证据，ABI reviewer 复跑 8/8。
- current-source whole-core 5ns target remap/OpenSTA 为 WNS `-9.99ns`、TNS
  `-121006.91ns`；top40 为 39 条 D-cache SRAM→MIQ 与 1 条跨 backend/frontend 到 fetch-cache
  SRAM enable 的控制链。该结果只作同模型 current path-family 真源，不是 post-route Fmax。

### 6.2 历史汇总缺口与 F0 收口

`npc/rv64/perf/results/core-regress/20260711-133547-973361/summary.txt` 与
`status.txt` 写 `overall_rc=0`，但原始日志复核发现：

- `am-cpu-tests.log` 的 59 项中 `fp-difftest-probe` 为 FAIL，即实际 58/59；上层仍记录
  `am-cpu-tests PASS`。
- module summary 把 86 项全部列为 PASS，但以下日志先出现 FAIL / `$finish(1)`，随后仍写
  `[RESULT] PASS`：
  - `tb_ooo_control_commit_sequencer.log`：7 个检查失败；
  - `tb_ooo_pending_system_sequencer.log`：IRQ cause 检查失败；
  - `tb_ooo_stop_pending_sequencer.log`：direct-branch 检查失败。

上述内容是 F0 前的审计反例，不能继续描述 current gate。2026-07-11 F0 已修复结果传播、
三个 sequencer TB 合同和 FP destination-domain 资格；FDG-G1 后新鲜证据为 module 87/87、AM
59/59（`fp-difftest-probe` 明确 Difftest ON）、official 177/177，core-regress 的
module/lint/build/AM 子层与 `overall_rc=0` 一致。原失败日志继续作为 RED 历史证据；F0 与
FDG-G1 current 结果分别见 `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/` 和
`.github/task-runs/2026-07-12-rv64-f1-fdg-g1/`。

### 6.3 PPA 与 Difftest 限定

- 当前工作区 `.config` 未开启 `CONFIG_NPC_DIFFTEST`。Difftest 代码已能比较 GPR/PC、FPR、
  CSR、privilege、fflags/frm；F0 另用 `default_defconfig` 得到 AM 59/59 的 Difftest-ON
  证据后按哈希恢复配置。常规 current-config core-regress 仍不能冒充逐退休全状态对拍。
- OpenSTA 使用当前 liberty 与 ideal-clock 条件；SRAM、FP arith、BPU 等宏的
  area/power/timing 模型不完整。WNS 只适合同一模型下的相对比较，不是 post-route Fmax。

## 7. 当前文档入口

- normative architecture：`ooo-core-architecture.md`
- living backlog：`ROADMAP.md`
- active module contracts：`../specs/README.md`
- RTL owner/index：`../../vsrc/README.md`
- dated history：`history/README.md`

本快照取代 `history/rtl-ground-truth-2026-07-03.md`（已归档）作为当前 `as-is`
入口；旧快照继续保留其时点证据，不再裁决当前 RTL。
