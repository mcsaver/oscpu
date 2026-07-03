# 规范：控制状态寄存器文件 CsrFile

> 模块：`vsrc/core/CsrFile.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证(ACT4/riscv-tests 特权 gate)。
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
- **mret**:MPIE→MIE、priv←MPP、MPP←U;pc←mepc。**sret**:SPIE→SIE、priv←SPP、SPP←U;pc←sepc。
- 委托:异常按 medeleg、中断按 mideleg 决定 trap 到 M 还是 S(且当前 priv ≤ S)。

## 4. 不变量
- **CSR-I1 特权合法性**:CSR 访问按 addr[9:8](最低特权)与 addr[11:10](读写)校验;非法→illegal instruction(由 probe gate 上报)。
- **CSR-I2 精确性**:CSR 副作用只在该 CSR 指令/ trap 提交边界生效(配合 ROB 精确提交)。
- **CSR-I3 mstatus 派生**:SD 由 FS==Dirty 派生;SXL/UXL 固定 RV64;WARL 位按规范钳位(已知例外:medeleg/mideleg 无只读 0 掩码,见 §2)。
- **CSR-I4 计数器**:minstret/mcycle 受 mcountinhibit 抑制;按 retire 数(instret_inc)递增。

## 5. 关键路径
Vivado OOC:CsrFile 22 逻辑级/logic 3.9ns,主要是 64-bit minstret 计数器加法器(16 CARRY4,专用进位,快);
非 Fmax 瓶颈(见 `../arch/ROADMAP.md` 时序 track)。

## 6. 验证
- riscv-tests `rv64mi-*`(machine trap/csr/illegal/pmpaddr/zicntr)、`rv64si-*`(supervisor csr/wfi/dirty)。
- ACT4:PMP(PMPSm/PMPS/PMPU)、Sv39/Svpbmt/Svinval、mstatus.SD。
- AM:counteren-time/sbi-*/sv39-*(配合 trm.c PMP 配置)。

## 7. 变更记录
- 2026-06-28：逆向文档化(M/S 特权 / trap-return 栈 / 委托 / PMP/satp/counters / 不变量)。
- 2026-07-03：补登 FP CSR 域(fflags/frm/fcsr、fp_dirty→FS=Dirty、frm_o)与 mcounteren/scounteren、menvcfg(PBMTE),对齐 FP 簇落地后的 RTL 现状。
