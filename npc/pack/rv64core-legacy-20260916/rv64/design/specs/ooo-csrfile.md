# 规范：控制状态寄存器文件 CsrFile

> 模块：`vsrc/core/CsrFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：主路径已实现；
> xRET current-mode 合同已冻结由上游 classifier 负责；`minstret` 系统级输入合同已由
> 2026-07-21 V9C 当前设计程序级证据关闭；mtvec/stvec Direct/Vectored 与选中
> trap record 合同已由 2026-07-26 V9U 当前设计证据覆盖。
> 由 `core/NpcCoreTop.v` 直接例化，`OooCoreTopGlue` 只导出 CSR access/trap/fflags/retire 事件并消费状态。

## 1. 目的与范围
RV64 特权状态机:M/S/U 三态、CSR 读写、trap/中断进入与 xRET 返回、计数器、PMP/satp 等状态输出。
控制面 `OooCsrTrapRequestMux` 负责形成 mem/ex/irq 三类请求；若三类输入同拍有效，
`CsrFile` 负责以 `mem > ex > irq` 选择唯一记录，并让重定向目标与 xEPC/xCAUSE/xTVAL
状态写共享该记录。

## 2. 主要 CSR
- **状态**:mstatus(MIE/SIE/MPIE/SPIE/MPP/SPP/MPRV/SUM/MXR/SD/SXL/UXL/TVM/TW/TSR)、misa(WARL no-op 写)。
- **trap**:mtvec/stvec(WARL 接受 MODE=00 Direct 与 MODE=01 Vectored；保留
  MODE=10/11 钳位为同 BASE 的 Direct)、mepc/sepc、mcause/scause、mtval/stval、
  mscratch/sscratch、medeleg/mideleg(当前全 64 位可写,未实现规范要求的只读 0 位掩码)。
- **中断**:mie/sie、mip/sip。`mideleg` 只决定低于 M-mode 时的目标特权级：
  已委派的 SSI/STI/SEI 进入 S，未委派的 supervisor pending bit 保留原 cause 并进入 M；
  在 M-mode 中已委派的 supervisor interrupt 被屏蔽。
- **MMU/保护**:satp(WARL:仅接受 mode=Bare/Sv39,其它 mode 整体写 0)、menvcfg(仅 PBMTE 位可写→svpbmt_en_o)、pmpcfg0/2 + pmpaddr0..15(16 entry,输出给取指/访存桥的 PmpChecker)。
- **计数器**:mcycle/minstret(只读 cycle/time/instret;RV64 下 *h 高半别名不存在,访问显式判 illegal,与 NEMU 对齐)、mcountinhibit(CY/IR 抑制)、mcounteren/scounteren(S/U 态 counter 访问逐位授权)。
- **FP**:fflags/frm/fcsr(fcsr={frm,fflags} 别名);frm_o 输出给 FP datapath 做 DYN 舍入;FP 提交脉冲 fp_dirty_i 置 mstatus.FS=Dirty(其子集 fp_fflags_valid_i 高时并累积 fflags)。
- **debug/其它**:最小 debug-trigger no-op、mvendorid/marchid/mimpid/mhartid(OpenSBI 需要)。

## 3. trap / 返回时序模型
- **进入 M**(`trap_to_m_mstatus`):MIE→MPIE、清 MIE、MPP←from_priv;mepc←pc、
  mcause/mtval 置位;priv→M;同步异常 pc←mtvec.BASE，MODE=01 的中断
  pc←mtvec.BASE+4×cause。
- **进入 S**(委托时,`trap_to_s_mstatus`):SIE→SPIE、清 SIE、SPP←(from==S);
  sepc/scause/stval;priv→S;同步异常 pc←stvec.BASE，MODE=01 的中断
  pc←stvec.BASE+4×cause。
- **mret**:收到已判定合法的请求后，MPIE→MIE、priv←MPP、MPP←U;pc←mepc。
  **sret**:收到已判定合法的请求后，SPIE→SIE、priv←SPP、SPP←U;pc←sepc。
- 委托:异常按 medeleg、中断按 mideleg 决定 trap 到 M 还是 S(且当前 priv ≤ S)。

**XRET-G1 已验证合同（2026-07-12）**：xRET current-mode 合法性由
上游 `OooFetchHeadClassifyGate` 负责，CsrFile 不复查。上游必须将 `MRET && priv!=M` 与
`SRET && priv==U` 分类为 illegal-instruction arch trap；`SRET && priv==S && TSR` 同样非法，
而 MRET@M、SRET@S/TSR=0、SRET@M（TSR 任意）可形成合法请求。pending capture 必须以
arch-trap 胜过 system/xRET，故只有已过此门的请求可到达本模块的 mret/sret 输入。

### 3.1 CSR access 与 legality probe 双视图合同（T3K）

`CsrFile` 同拍接收两条无握手组合视图：

| View | 输入 | 输出/用途 | 允许影响状态 |
| --- | --- | --- | --- |
| main access | `csr_valid/addr/funct3/rs1_idx/rs1_data/zimm/commit` | `csr_rdata`、内部 `csr_access_illegal_w`、提交写副作用 | 仅 `csr_commit && valid && !illegal && need_write` |
| head probe | `csr_probe_valid/addr/funct3/rs1_idx` | 对外 `csr_illegal_o`，供 pending trap 分类 | 永不允许 |

两条视图必须调用同一个纯组合 `csr_access_illegal_raw` 定义。该定义完整覆盖
known/implemented、write-intent 与 writable、当前 privilege、S-mode SATP+TVM、
`mcounteren/scounteren`；不得复制或弱化为第二张地址表。main 与 probe 可以同拍
访问不同地址，`csr_illegal_o` 只回答 probe，main 写入许可只看内部
`csr_access_illegal_w`。

令上升沿前架构状态为 `S_q`，则同拍语义固定为：

```text
main_illegal  = L(S_q, main_access)
probe_illegal = L(S_q, head_probe)
S_next        = T(S_q, trap/xRET/main_commit/fp_dirty)
```

两次合法性都观察 pre-edge `S_q`。禁止把同拍提交、trap 或 xRET 形成的
`S_next` 旁路给 probe；NBA 更新后从下一拍起才按新状态重算。probe 不进入
`csr_new_value`、read-data mux、PMP lock/write 或任何时序块。上游继续以
trap/exit/privileged boundary 优先级阻断 younger probe 的消费。

### 3.2 Vectored trap 与选中记录合同（V9U）

三类 trap 输入以独立 valid/payload 进入 CsrFile；唯一选择顺序固定为
`trap_mem > trap_ex > trap_irq`。选中记录同时产生：

- 委托目标 M/S；
- xEPC、xCAUSE、xTVAL 写入；
- `trap_target_o` 的 tvec BASE 与可选向量偏移。

仅“选中源是 irq 且所选 mtvec/stvec MODE=01”时加入
`{{cause},2'b00}`；同步 mem/ex 即使 MODE=01 也只跳 BASE。该公式不得从另一个
未选中请求借用 cause、委托位或 tvec。`OOO_ASSERT` 下 A1 核对独立
`mem > ex > irq` 参考记录，A2 核对独立目标公式，A3/A4 在写入后一拍核对
mtvec/stvec WARL 并持续拒绝保留 MODE。A5 由独立 pending/cause 优先级表达式核对
MEI>MSI>MTI>SEI>SSI>STI，并覆盖已委派与未委派 supervisor interrupt 的 M/S 路由。

## 4. 不变量
- **CSR-I1 特权合法性**：CSR 访问按 `addr[9:8]`（最低特权）与 `addr[11:10]`（读写）
  校验；非法访问产生 illegal instruction（由 probe gate 上报）。
- **CSR-I2 精确性**:CSR 副作用只在该 CSR 指令/ trap 提交边界生效(配合 ROB 精确提交)。
- **CSR-I2a probe 隔离**：`csr_illegal_o` 只依赖 head probe payload 与当前 CSR
  状态；commit/pending/main-access payload 不得进入该输出的组合依赖锥。
- **CSR-I2b 定义唯一**：main 与 probe 的 legality 对同一 payload/同一 `S_q`
  必须 bit-exact；main legality 仍独立守住所有 CSR 写副作用。
- **CSR-I3 mstatus 派生**:SD 由 FS==Dirty 派生;SXL/UXL 固定 RV64;WARL 位按规范钳位(已知例外:medeleg/mideleg 无只读 0 掩码,见 §2)。
- **CSR-I4（模块内）计数器**：CsrFile 按 `instret_inc_i` 加 `minstret`，并受
  `mcountinhibit.IR` 抑制。
- **CSR-I4（系统合同）**：`instret_inc_i` 必须来自唯一 ISA-retirement 计数源：异常项
  不计，实际退休的 control-path 指令各计一次。
- **CSR-I5 tvec WARL**：MODE=00/01 原样保存；MODE=10/11 保留 BASE 并钳位到 00。
- **CSR-I6 目标公式**：中断 Vectored=`BASE+4×cause`；Direct 或任意同步异常=`BASE`。
- **CSR-I7 单记录精确性**：委托、状态写和 redirect 必须消费同一个
  `mem > ex > irq` 选中记录，不得跨请求拼接 payload。
- **INSTRET-G1（2026-07-21 V9C CLOSED）**：`NpcCoreTop` 接入 output mux 的最终
  `retire_count_o`；该值只按最终 commit lane 的 `valid && !exception` 计数，故异常项不计，
  mret/sret/wfi/sfence/fence.i 等在实际产生合法 control pseudo-commit 时各计一次。focused TB
  覆盖 0/1/2、异常过滤、control 优先级、`mcountinhibit.IR` 与显式 minstret 写优先；V9C
  全核 Sv39 程序进一步证明异常 lane 2/2 零增量、MRET/SRET/SFENCE.VMA=1/6/1、控制提交
  8/8 精确单增量和 1052 次 CsrFile 边沿增量，并以 3/3 current-source 可编译 RTL
  验证变体锁定 final-mux 与 CsrFile 消费边。WFI 能力范围仍由独立 `WFI-G1` 决策负责。

## 5. 关键路径
Vivado OOC:CsrFile 22 逻辑级/logic 3.9ns,主要是 64-bit minstret 计数器加法器(16 CARRY4,专用进位,快);
非 Fmax 瓶颈(见 `../arch/ROADMAP.md` 时序 track)。

## 6. 验证
- riscv-tests `rv64mi-*`(machine trap/csr/illegal/pmpaddr/zicntr)、`rv64si-*`(supervisor csr/wfi/dirty)。
- ACT4:PMP(PMPSm/PMPS/PMPU)、Sv39/Svpbmt/Svinval、mstatus.SD。
- AM:counteren-time/sbi-*/sv39-*(配合 trm.c PMP 配置)。
- XRET-G1：`tb_ooo_priv_system` 用真实编码覆盖 S-mode lane0 MRET 与 U-mode lane1 SRET；
  检查 illegal cause、fault PC、`mtval` 原编码、M handler return 与 no illegal-xRET commit。
- T3K：standalone TB 交叉 main/probe 地址与合法性，覆盖 read-only write-intent、
  privilege、TVM、counter-enable，并证明 probe 无副作用与 policy 写入边沿的
  pre-edge→post-edge 翻转；结构/变异检查证明 commit/pending 不再进入 probe 锥。
- INSTRET-G1：`make -C npc/rv64 check-instret-retirement`；证据入口
  `npc/rv64/eval/ppa/evidence/instret-retirement-current.json`，PPA 声明保持 `UNQUALIFIED`。
- VECTORED-TRAP-G1：`make -C npc/rv64 check-vectored-trap`；独立 CsrFile
  13 类用例（含 3 类 interrupt delegation/routing）、完整 OoO 核 M/S 中断与 M
  同步异常 3 条路径、既有 CSR 回归，以及 7 个 compile-success 负向 RTL 版本。
  官方 `rv64mi-p-illegal` 定向重跑与完整 177/177 官方集合均通过。证据入口
  `npc/rv64/eval/ppa/evidence/vectored-trap-current.json`，PPA 保持 `UNQUALIFIED`。

## 7. 变更记录
- 2026-06-28：逆向文档化(M/S 特权 / trap-return 栈 / 委托 / PMP/satp/counters / 不变量)。
- 2026-07-03：补登 FP CSR 域(fflags/frm/fcsr、fp_dirty→FS=Dirty、frm_o)与 mcounteren/scounteren、menvcfg(PBMTE),对齐 FP 簇落地后的 RTL 现状。
- 2026-07-11：补充 xRET current-mode 与唯一 ISA-retirement 计数源的跨模块合同。
- 2026-07-12：冻结 XRET-G1 classifier→pending capture→CsrFile current-mode 合同。
- 2026-07-12：XRET-G1 旧 RTL 精确 RED；classifier 与真实编码 CsrFile 边界 focused GREEN、
  final module 87/87；CsrFile 边界不需改 RTL。
- 2026-07-13：冻结 T3K 双视图 legality 合同：head-only probe 与
  commit/pending main access 解耦，共用唯一纯组合 predicate，保持 pre-edge 语义。
- 2026-07-21：V9C 以全核程序事件清单、逐拍 CsrFile 增量和三类可编译 RTL 验证变体
  关闭 `INSTRET-G1`；生产 RTL 无需修改。
- 2026-07-26：V9U 实现 mtvec/stvec MODE=01、保留 MODE WARL 钳位和统一
  `mem > ex > irq` trap record；随后由官方 `rv64mi-p-illegal` 暴露并修复未委派
  SSIP 未进入 M-mode 的中断路由缺口。最终以 13 类 CsrFile 周期用例、三条全核路径、
  A1..A5 断言及七类负向 RTL 版本建立当前设计证据，PPA 未据此晋级。
