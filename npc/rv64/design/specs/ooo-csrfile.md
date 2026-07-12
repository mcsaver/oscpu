# 规范：控制状态寄存器文件 CsrFile

> 模块：`vsrc/core/CsrFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：主路径已实现；
> xRET current-mode 合同已冻结由上游 classifier 负责；`minstret` 系统级输入合同仍有开放项。
> 由 `core/NpcCoreTop.v` 直接例化，`OooCoreTopGlue` 只导出 CSR access/trap/fflags/retire 事件并消费状态。

## 1. 目的与范围
RV64 特权状态机:M/S/U 三态、CSR 读写、trap/中断进入与 xRET 返回、计数器、PMP/satp 等状态输出。
不负责 trap 优先级仲裁(由控制面 `OooCsrTrapRequestMux` 等决定何时请求 trap/return)。

## 2. 主要 CSR
- **状态**:mstatus(MIE/SIE/MPIE/SPIE/MPP/SPP/MPRV/SUM/MXR/SD/SXL/UXL/TVM/TW/TSR)、misa(WARL no-op 写)。
- **trap**:mtvec/stvec(WARL 仅 direct 模式,写入低 2 位强制 00,不支持 vectored)、mepc/sepc、mcause/scause、mtval/stval、mscratch/sscratch、medeleg/mideleg(当前全 64 位可写,未实现规范要求的只读 0 位掩码)。
- **中断**:mie/sie、mip/sip(mideleg[SEI]→生成 MIP_SEIP 等委托语义)。
- **MMU/保护**:satp(WARL:仅接受 mode=Bare/Sv39,其它 mode 整体写 0)、menvcfg(仅 PBMTE 位可写→svpbmt_en_o)、pmpcfg0/2 + pmpaddr0..15(16 entry,输出给取指/访存桥的 PmpChecker)。
- **计数器**:mcycle/minstret(只读 cycle/time/instret;RV64 下 *h 高半别名不存在,访问显式判 illegal,与 NEMU 对齐)、mcountinhibit(CY/IR 抑制)、mcounteren/scounteren(S/U 态 counter 访问逐位授权)。
- **FP**:fflags/frm/fcsr(fcsr={frm,fflags} 别名);frm_o 输出给 FP datapath 做 DYN 舍入;FP 提交脉冲 fp_dirty_i 置 mstatus.FS=Dirty(其子集 fp_fflags_valid_i 高时并累积 fflags)。
- **debug/其它**:最小 debug-trigger no-op、mvendorid/marchid/mimpid/mhartid(OpenSBI 需要)。

## 3. trap / 返回时序模型
- **进入 M**(`trap_to_m_mstatus`):MIE→MPIE、清 MIE、MPP←from_priv;mepc←pc、mcause/mtval 置位;priv→M;pc←mtvec。
- **进入 S**(委托时,`trap_to_s_mstatus`):SIE→SPIE、清 SIE、SPP←(from==S);sepc/scause/stval;priv→S;pc←stvec。
- **mret**:收到已判定合法的请求后，MPIE→MIE、priv←MPP、MPP←U;pc←mepc。
  **sret**:收到已判定合法的请求后，SPIE→SIE、priv←SPP、SPP←U;pc←sepc。
- 委托:异常按 medeleg、中断按 mideleg 决定 trap 到 M 还是 S(且当前 priv ≤ S)。

**XRET-G1 已验证合同（2026-07-12）**：xRET current-mode 合法性由
上游 `OooFetchHeadClassifyGate` 负责，CsrFile 不复查。上游必须将 `MRET && priv!=M` 与
`SRET && priv==U` 分类为 illegal-instruction arch trap；`SRET && priv==S && TSR` 同样非法，
而 MRET@M、SRET@S/TSR=0、SRET@M（TSR 任意）可形成合法请求。pending capture 必须以
arch-trap 胜过 system/xRET，故只有已过此门的请求可到达本模块的 mret/sret 输入。

## 4. 不变量
- **CSR-I1 特权合法性**：CSR 访问按 `addr[9:8]`（最低特权）与 `addr[11:10]`（读写）
  校验；非法访问产生 illegal instruction（由 probe gate 上报）。
- **CSR-I2 精确性**:CSR 副作用只在该 CSR 指令/ trap 提交边界生效(配合 ROB 精确提交)。
- **CSR-I3 mstatus 派生**:SD 由 FS==Dirty 派生;SXL/UXL 固定 RV64;WARL 位按规范钳位(已知例外:medeleg/mideleg 无只读 0 掩码,见 §2)。
- **CSR-I4（模块内）计数器**：CsrFile 按 `instret_inc_i` 加 `minstret`，并受
  `mcountinhibit.IR` 抑制。
- **CSR-I4（系统合同）**：`instret_inc_i` 必须来自唯一 ISA-retirement 计数源：异常项
  不计，实际退休的 control-path 指令各计一次。
- **KNOWN GAP INSTRET-G1**：`NpcCoreTop` 当前接入 raw `ooo_core_retire_count_w`，不是
  ISA 过滤后的唯一源；异常 commit-valid 可进入计数，而 mret/sret/wfi/sfence/fence.i
  等 control pseudo-commit 不在该 raw 输入中。此结论来自整机静态接线，尚无专门计数器
  程序波形。

## 5. 关键路径
Vivado OOC:CsrFile 22 逻辑级/logic 3.9ns,主要是 64-bit minstret 计数器加法器(16 CARRY4,专用进位,快);
非 Fmax 瓶颈(见 `../arch/ROADMAP.md` 时序 track)。

## 6. 验证
- riscv-tests `rv64mi-*`(machine trap/csr/illegal/pmpaddr/zicntr)、`rv64si-*`(supervisor csr/wfi/dirty)。
- ACT4:PMP(PMPSm/PMPS/PMPU)、Sv39/Svpbmt/Svinval、mstatus.SD。
- AM:counteren-time/sbi-*/sv39-*(配合 trm.c PMP 配置)。
- XRET-G1：`tb_ooo_priv_system` 用真实编码覆盖 S-mode lane0 MRET 与 U-mode lane1 SRET；
  检查 illegal cause、fault PC、`mtval` 原编码、M handler return 与 no illegal-xRET commit。

## 7. 变更记录
- 2026-06-28：逆向文档化(M/S 特权 / trap-return 栈 / 委托 / PMP/satp/counters / 不变量)。
- 2026-07-03：补登 FP CSR 域(fflags/frm/fcsr、fp_dirty→FS=Dirty、frm_o)与 mcounteren/scounteren、menvcfg(PBMTE),对齐 FP 簇落地后的 RTL 现状。
- 2026-07-11：补充 xRET current-mode 与唯一 ISA-retirement 计数源的跨模块合同。
- 2026-07-12：冻结 XRET-G1 classifier→pending capture→CsrFile current-mode 合同。
- 2026-07-12：XRET-G1 旧 RTL 精确 RED；classifier 与真实编码 CsrFile 边界 focused GREEN、
  final module 87/87；CsrFile 边界不需改 RTL。
