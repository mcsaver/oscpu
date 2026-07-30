// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VNpcSimTop.h for the primary calling header

#include "VNpcSimTop__pch.h"
#include "VNpcSimTop__Syms.h"
#include "VNpcSimTop___024unit.h"

extern "C" int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit\n"); );
    // Body
    unsigned long long addr__Vcvt;
    for (size_t addr__Vidx = 0; addr__Vidx < 1; ++addr__Vidx) addr__Vcvt = addr;
    unsigned int nbytes__Vcvt;
    for (size_t nbytes__Vidx = 0; nbytes__Vidx < 1; ++nbytes__Vidx) nbytes__Vcvt = nbytes;
    unsigned long long data__Vcvt;
    svBit error__Vcvt;
    npc_ifetch_sized(addr__Vcvt, nbytes__Vcvt, &data__Vcvt, &error__Vcvt);
    data = data__Vcvt;
    error = (1U & error__Vcvt);
}

extern "C" int npc_mem_read_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit\n"); );
    // Body
    unsigned long long addr__Vcvt;
    for (size_t addr__Vidx = 0; addr__Vidx < 1; ++addr__Vidx) addr__Vcvt = addr;
    unsigned int nbytes__Vcvt;
    for (size_t nbytes__Vidx = 0; nbytes__Vidx < 1; ++nbytes__Vidx) nbytes__Vcvt = nbytes;
    unsigned long long data__Vcvt;
    svBit error__Vcvt;
    npc_mem_read_sized(addr__Vcvt, nbytes__Vcvt, &data__Vcvt, &error__Vcvt);
    data = data__Vcvt;
    error = (1U & error__Vcvt);
}

extern "C" int npc_mem_write(unsigned long long addr, unsigned long long data, unsigned long long mask, svBit* error);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit(QData/*63:0*/ addr, QData/*63:0*/ data, QData/*63:0*/ mask, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit\n"); );
    // Body
    unsigned long long addr__Vcvt;
    for (size_t addr__Vidx = 0; addr__Vidx < 1; ++addr__Vidx) addr__Vcvt = addr;
    unsigned long long data__Vcvt;
    for (size_t data__Vidx = 0; data__Vidx < 1; ++data__Vidx) data__Vcvt = data;
    unsigned long long mask__Vcvt;
    for (size_t mask__Vidx = 0; mask__Vidx < 1; ++mask__Vidx) mask__Vcvt = mask;
    svBit error__Vcvt;
    npc_mem_write(addr__Vcvt, data__Vcvt, mask__Vcvt, &error__Vcvt);
    error = (1U & error__Vcvt);
}

extern "C" int npc_virtio_blk_read(unsigned int offset, unsigned long long* data, svBit* error, svBit* irq);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_read_TOP____024unit(IData/*31:0*/ offset, QData/*63:0*/ &data, CData/*0:0*/ &error, CData/*0:0*/ &irq) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_read_TOP____024unit\n"); );
    // Body
    unsigned int offset__Vcvt;
    for (size_t offset__Vidx = 0; offset__Vidx < 1; ++offset__Vidx) offset__Vcvt = offset;
    unsigned long long data__Vcvt;
    svBit error__Vcvt;
    svBit irq__Vcvt;
    npc_virtio_blk_read(offset__Vcvt, &data__Vcvt, &error__Vcvt, &irq__Vcvt);
    data = data__Vcvt;
    error = (1U & error__Vcvt);
    irq = (1U & irq__Vcvt);
}

extern "C" int npc_virtio_blk_write(unsigned int offset, unsigned long long data, unsigned long long mask, svBit* error, svBit* irq);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_write_TOP____024unit(IData/*31:0*/ offset, QData/*63:0*/ data, QData/*63:0*/ mask, CData/*0:0*/ &error, CData/*0:0*/ &irq) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_write_TOP____024unit\n"); );
    // Body
    unsigned int offset__Vcvt;
    for (size_t offset__Vidx = 0; offset__Vidx < 1; ++offset__Vidx) offset__Vcvt = offset;
    unsigned long long data__Vcvt;
    for (size_t data__Vidx = 0; data__Vidx < 1; ++data__Vidx) data__Vcvt = data;
    unsigned long long mask__Vcvt;
    for (size_t mask__Vidx = 0; mask__Vidx < 1; ++mask__Vidx) mask__Vcvt = mask;
    svBit error__Vcvt;
    svBit irq__Vcvt;
    npc_virtio_blk_write(offset__Vcvt, data__Vcvt, mask__Vcvt, &error__Vcvt, &irq__Vcvt);
    error = (1U & error__Vcvt);
    irq = (1U & irq__Vcvt);
}

extern "C" int npc_virtio_blk_irq(svBit* irq);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_irq_TOP____024unit(CData/*0:0*/ &irq) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_virtio_blk_irq_TOP____024unit\n"); );
    // Body
    svBit irq__Vcvt;
    npc_virtio_blk_irq(&irq__Vcvt);
    irq = (1U & irq__Vcvt);
}

extern "C" void npc_commit_event(unsigned long long pc, unsigned int inst, unsigned long long next_pc, unsigned int rd_en, unsigned int rd_addr, unsigned long long rd_data, unsigned int is_fp);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_commit_event_TOP____024unit(QData/*63:0*/ pc, IData/*31:0*/ inst, QData/*63:0*/ next_pc, IData/*31:0*/ rd_en, IData/*31:0*/ rd_addr, QData/*63:0*/ rd_data, IData/*31:0*/ is_fp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_commit_event_TOP____024unit\n"); );
    // Body
    unsigned long long pc__Vcvt;
    for (size_t pc__Vidx = 0; pc__Vidx < 1; ++pc__Vidx) pc__Vcvt = pc;
    unsigned int inst__Vcvt;
    for (size_t inst__Vidx = 0; inst__Vidx < 1; ++inst__Vidx) inst__Vcvt = inst;
    unsigned long long next_pc__Vcvt;
    for (size_t next_pc__Vidx = 0; next_pc__Vidx < 1; ++next_pc__Vidx) next_pc__Vcvt = next_pc;
    unsigned int rd_en__Vcvt;
    for (size_t rd_en__Vidx = 0; rd_en__Vidx < 1; ++rd_en__Vidx) rd_en__Vcvt = rd_en;
    unsigned int rd_addr__Vcvt;
    for (size_t rd_addr__Vidx = 0; rd_addr__Vidx < 1; ++rd_addr__Vidx) rd_addr__Vcvt = rd_addr;
    unsigned long long rd_data__Vcvt;
    for (size_t rd_data__Vidx = 0; rd_data__Vidx < 1; ++rd_data__Vidx) rd_data__Vcvt = rd_data;
    unsigned int is_fp__Vcvt;
    for (size_t is_fp__Vidx = 0; is_fp__Vidx < 1; ++is_fp__Vidx) is_fp__Vcvt = is_fp;
    npc_commit_event(pc__Vcvt, inst__Vcvt, next_pc__Vcvt, rd_en__Vcvt, rd_addr__Vcvt, rd_data__Vcvt, is_fp__Vcvt);
}

extern "C" void npc_exit_event(unsigned int is_ebreak, unsigned int is_ecall, unsigned int is_system_reset, unsigned long long code, unsigned long long pc);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_exit_event_TOP____024unit(IData/*31:0*/ is_ebreak, IData/*31:0*/ is_ecall, IData/*31:0*/ is_system_reset, QData/*63:0*/ code, QData/*63:0*/ pc) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_exit_event_TOP____024unit\n"); );
    // Body
    unsigned int is_ebreak__Vcvt;
    for (size_t is_ebreak__Vidx = 0; is_ebreak__Vidx < 1; ++is_ebreak__Vidx) is_ebreak__Vcvt = is_ebreak;
    unsigned int is_ecall__Vcvt;
    for (size_t is_ecall__Vidx = 0; is_ecall__Vidx < 1; ++is_ecall__Vidx) is_ecall__Vcvt = is_ecall;
    unsigned int is_system_reset__Vcvt;
    for (size_t is_system_reset__Vidx = 0; is_system_reset__Vidx < 1; ++is_system_reset__Vidx) is_system_reset__Vcvt = is_system_reset;
    unsigned long long code__Vcvt;
    for (size_t code__Vidx = 0; code__Vidx < 1; ++code__Vidx) code__Vcvt = code;
    unsigned long long pc__Vcvt;
    for (size_t pc__Vidx = 0; pc__Vidx < 1; ++pc__Vidx) pc__Vcvt = pc;
    npc_exit_event(is_ebreak__Vcvt, is_ecall__Vcvt, is_system_reset__Vcvt, code__Vcvt, pc__Vcvt);
}

extern "C" void npc_arch_csr_event(unsigned long long c0, unsigned long long c1, unsigned long long c2, unsigned long long c3, unsigned long long c4, unsigned long long c5, unsigned long long c6, unsigned long long c7, unsigned long long c8, unsigned long long c9, unsigned long long c10, unsigned long long c11, unsigned long long c12, unsigned long long c13, unsigned long long c14, unsigned long long c15, unsigned long long c16, unsigned long long c17, unsigned long long c18, unsigned long long c19, unsigned long long c20, unsigned long long c21, unsigned long long c22);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_arch_csr_event_TOP____024unit(QData/*63:0*/ c0, QData/*63:0*/ c1, QData/*63:0*/ c2, QData/*63:0*/ c3, QData/*63:0*/ c4, QData/*63:0*/ c5, QData/*63:0*/ c6, QData/*63:0*/ c7, QData/*63:0*/ c8, QData/*63:0*/ c9, QData/*63:0*/ c10, QData/*63:0*/ c11, QData/*63:0*/ c12, QData/*63:0*/ c13, QData/*63:0*/ c14, QData/*63:0*/ c15, QData/*63:0*/ c16, QData/*63:0*/ c17, QData/*63:0*/ c18, QData/*63:0*/ c19, QData/*63:0*/ c20, QData/*63:0*/ c21, QData/*63:0*/ c22) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_arch_csr_event_TOP____024unit\n"); );
    // Body
    unsigned long long c0__Vcvt;
    for (size_t c0__Vidx = 0; c0__Vidx < 1; ++c0__Vidx) c0__Vcvt = c0;
    unsigned long long c1__Vcvt;
    for (size_t c1__Vidx = 0; c1__Vidx < 1; ++c1__Vidx) c1__Vcvt = c1;
    unsigned long long c2__Vcvt;
    for (size_t c2__Vidx = 0; c2__Vidx < 1; ++c2__Vidx) c2__Vcvt = c2;
    unsigned long long c3__Vcvt;
    for (size_t c3__Vidx = 0; c3__Vidx < 1; ++c3__Vidx) c3__Vcvt = c3;
    unsigned long long c4__Vcvt;
    for (size_t c4__Vidx = 0; c4__Vidx < 1; ++c4__Vidx) c4__Vcvt = c4;
    unsigned long long c5__Vcvt;
    for (size_t c5__Vidx = 0; c5__Vidx < 1; ++c5__Vidx) c5__Vcvt = c5;
    unsigned long long c6__Vcvt;
    for (size_t c6__Vidx = 0; c6__Vidx < 1; ++c6__Vidx) c6__Vcvt = c6;
    unsigned long long c7__Vcvt;
    for (size_t c7__Vidx = 0; c7__Vidx < 1; ++c7__Vidx) c7__Vcvt = c7;
    unsigned long long c8__Vcvt;
    for (size_t c8__Vidx = 0; c8__Vidx < 1; ++c8__Vidx) c8__Vcvt = c8;
    unsigned long long c9__Vcvt;
    for (size_t c9__Vidx = 0; c9__Vidx < 1; ++c9__Vidx) c9__Vcvt = c9;
    unsigned long long c10__Vcvt;
    for (size_t c10__Vidx = 0; c10__Vidx < 1; ++c10__Vidx) c10__Vcvt = c10;
    unsigned long long c11__Vcvt;
    for (size_t c11__Vidx = 0; c11__Vidx < 1; ++c11__Vidx) c11__Vcvt = c11;
    unsigned long long c12__Vcvt;
    for (size_t c12__Vidx = 0; c12__Vidx < 1; ++c12__Vidx) c12__Vcvt = c12;
    unsigned long long c13__Vcvt;
    for (size_t c13__Vidx = 0; c13__Vidx < 1; ++c13__Vidx) c13__Vcvt = c13;
    unsigned long long c14__Vcvt;
    for (size_t c14__Vidx = 0; c14__Vidx < 1; ++c14__Vidx) c14__Vcvt = c14;
    unsigned long long c15__Vcvt;
    for (size_t c15__Vidx = 0; c15__Vidx < 1; ++c15__Vidx) c15__Vcvt = c15;
    unsigned long long c16__Vcvt;
    for (size_t c16__Vidx = 0; c16__Vidx < 1; ++c16__Vidx) c16__Vcvt = c16;
    unsigned long long c17__Vcvt;
    for (size_t c17__Vidx = 0; c17__Vidx < 1; ++c17__Vidx) c17__Vcvt = c17;
    unsigned long long c18__Vcvt;
    for (size_t c18__Vidx = 0; c18__Vidx < 1; ++c18__Vidx) c18__Vcvt = c18;
    unsigned long long c19__Vcvt;
    for (size_t c19__Vidx = 0; c19__Vidx < 1; ++c19__Vidx) c19__Vcvt = c19;
    unsigned long long c20__Vcvt;
    for (size_t c20__Vidx = 0; c20__Vidx < 1; ++c20__Vidx) c20__Vcvt = c20;
    unsigned long long c21__Vcvt;
    for (size_t c21__Vidx = 0; c21__Vidx < 1; ++c21__Vidx) c21__Vcvt = c21;
    unsigned long long c22__Vcvt;
    for (size_t c22__Vidx = 0; c22__Vidx < 1; ++c22__Vidx) c22__Vcvt = c22;
    npc_arch_csr_event(c0__Vcvt, c1__Vcvt, c2__Vcvt, c3__Vcvt, c4__Vcvt, c5__Vcvt, c6__Vcvt, c7__Vcvt, c8__Vcvt, c9__Vcvt, c10__Vcvt, c11__Vcvt, c12__Vcvt, c13__Vcvt, c14__Vcvt, c15__Vcvt, c16__Vcvt, c17__Vcvt, c18__Vcvt, c19__Vcvt, c20__Vcvt, c21__Vcvt, c22__Vcvt);
}

extern "C" void npc_arch_fpr_event(unsigned long long f0, unsigned long long f1, unsigned long long f2, unsigned long long f3, unsigned long long f4, unsigned long long f5, unsigned long long f6, unsigned long long f7, unsigned long long f8, unsigned long long f9, unsigned long long f10, unsigned long long f11, unsigned long long f12, unsigned long long f13, unsigned long long f14, unsigned long long f15, unsigned long long f16, unsigned long long f17, unsigned long long f18, unsigned long long f19, unsigned long long f20, unsigned long long f21, unsigned long long f22, unsigned long long f23, unsigned long long f24, unsigned long long f25, unsigned long long f26, unsigned long long f27, unsigned long long f28, unsigned long long f29, unsigned long long f30, unsigned long long f31);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_arch_fpr_event_TOP____024unit(QData/*63:0*/ f0, QData/*63:0*/ f1, QData/*63:0*/ f2, QData/*63:0*/ f3, QData/*63:0*/ f4, QData/*63:0*/ f5, QData/*63:0*/ f6, QData/*63:0*/ f7, QData/*63:0*/ f8, QData/*63:0*/ f9, QData/*63:0*/ f10, QData/*63:0*/ f11, QData/*63:0*/ f12, QData/*63:0*/ f13, QData/*63:0*/ f14, QData/*63:0*/ f15, QData/*63:0*/ f16, QData/*63:0*/ f17, QData/*63:0*/ f18, QData/*63:0*/ f19, QData/*63:0*/ f20, QData/*63:0*/ f21, QData/*63:0*/ f22, QData/*63:0*/ f23, QData/*63:0*/ f24, QData/*63:0*/ f25, QData/*63:0*/ f26, QData/*63:0*/ f27, QData/*63:0*/ f28, QData/*63:0*/ f29, QData/*63:0*/ f30, QData/*63:0*/ f31) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_arch_fpr_event_TOP____024unit\n"); );
    // Body
    unsigned long long f0__Vcvt;
    for (size_t f0__Vidx = 0; f0__Vidx < 1; ++f0__Vidx) f0__Vcvt = f0;
    unsigned long long f1__Vcvt;
    for (size_t f1__Vidx = 0; f1__Vidx < 1; ++f1__Vidx) f1__Vcvt = f1;
    unsigned long long f2__Vcvt;
    for (size_t f2__Vidx = 0; f2__Vidx < 1; ++f2__Vidx) f2__Vcvt = f2;
    unsigned long long f3__Vcvt;
    for (size_t f3__Vidx = 0; f3__Vidx < 1; ++f3__Vidx) f3__Vcvt = f3;
    unsigned long long f4__Vcvt;
    for (size_t f4__Vidx = 0; f4__Vidx < 1; ++f4__Vidx) f4__Vcvt = f4;
    unsigned long long f5__Vcvt;
    for (size_t f5__Vidx = 0; f5__Vidx < 1; ++f5__Vidx) f5__Vcvt = f5;
    unsigned long long f6__Vcvt;
    for (size_t f6__Vidx = 0; f6__Vidx < 1; ++f6__Vidx) f6__Vcvt = f6;
    unsigned long long f7__Vcvt;
    for (size_t f7__Vidx = 0; f7__Vidx < 1; ++f7__Vidx) f7__Vcvt = f7;
    unsigned long long f8__Vcvt;
    for (size_t f8__Vidx = 0; f8__Vidx < 1; ++f8__Vidx) f8__Vcvt = f8;
    unsigned long long f9__Vcvt;
    for (size_t f9__Vidx = 0; f9__Vidx < 1; ++f9__Vidx) f9__Vcvt = f9;
    unsigned long long f10__Vcvt;
    for (size_t f10__Vidx = 0; f10__Vidx < 1; ++f10__Vidx) f10__Vcvt = f10;
    unsigned long long f11__Vcvt;
    for (size_t f11__Vidx = 0; f11__Vidx < 1; ++f11__Vidx) f11__Vcvt = f11;
    unsigned long long f12__Vcvt;
    for (size_t f12__Vidx = 0; f12__Vidx < 1; ++f12__Vidx) f12__Vcvt = f12;
    unsigned long long f13__Vcvt;
    for (size_t f13__Vidx = 0; f13__Vidx < 1; ++f13__Vidx) f13__Vcvt = f13;
    unsigned long long f14__Vcvt;
    for (size_t f14__Vidx = 0; f14__Vidx < 1; ++f14__Vidx) f14__Vcvt = f14;
    unsigned long long f15__Vcvt;
    for (size_t f15__Vidx = 0; f15__Vidx < 1; ++f15__Vidx) f15__Vcvt = f15;
    unsigned long long f16__Vcvt;
    for (size_t f16__Vidx = 0; f16__Vidx < 1; ++f16__Vidx) f16__Vcvt = f16;
    unsigned long long f17__Vcvt;
    for (size_t f17__Vidx = 0; f17__Vidx < 1; ++f17__Vidx) f17__Vcvt = f17;
    unsigned long long f18__Vcvt;
    for (size_t f18__Vidx = 0; f18__Vidx < 1; ++f18__Vidx) f18__Vcvt = f18;
    unsigned long long f19__Vcvt;
    for (size_t f19__Vidx = 0; f19__Vidx < 1; ++f19__Vidx) f19__Vcvt = f19;
    unsigned long long f20__Vcvt;
    for (size_t f20__Vidx = 0; f20__Vidx < 1; ++f20__Vidx) f20__Vcvt = f20;
    unsigned long long f21__Vcvt;
    for (size_t f21__Vidx = 0; f21__Vidx < 1; ++f21__Vidx) f21__Vcvt = f21;
    unsigned long long f22__Vcvt;
    for (size_t f22__Vidx = 0; f22__Vidx < 1; ++f22__Vidx) f22__Vcvt = f22;
    unsigned long long f23__Vcvt;
    for (size_t f23__Vidx = 0; f23__Vidx < 1; ++f23__Vidx) f23__Vcvt = f23;
    unsigned long long f24__Vcvt;
    for (size_t f24__Vidx = 0; f24__Vidx < 1; ++f24__Vidx) f24__Vcvt = f24;
    unsigned long long f25__Vcvt;
    for (size_t f25__Vidx = 0; f25__Vidx < 1; ++f25__Vidx) f25__Vcvt = f25;
    unsigned long long f26__Vcvt;
    for (size_t f26__Vidx = 0; f26__Vidx < 1; ++f26__Vidx) f26__Vcvt = f26;
    unsigned long long f27__Vcvt;
    for (size_t f27__Vidx = 0; f27__Vidx < 1; ++f27__Vidx) f27__Vcvt = f27;
    unsigned long long f28__Vcvt;
    for (size_t f28__Vidx = 0; f28__Vidx < 1; ++f28__Vidx) f28__Vcvt = f28;
    unsigned long long f29__Vcvt;
    for (size_t f29__Vidx = 0; f29__Vidx < 1; ++f29__Vidx) f29__Vcvt = f29;
    unsigned long long f30__Vcvt;
    for (size_t f30__Vidx = 0; f30__Vidx < 1; ++f30__Vidx) f30__Vcvt = f30;
    unsigned long long f31__Vcvt;
    for (size_t f31__Vidx = 0; f31__Vidx < 1; ++f31__Vidx) f31__Vcvt = f31;
    npc_arch_fpr_event(f0__Vcvt, f1__Vcvt, f2__Vcvt, f3__Vcvt, f4__Vcvt, f5__Vcvt, f6__Vcvt, f7__Vcvt, f8__Vcvt, f9__Vcvt, f10__Vcvt, f11__Vcvt, f12__Vcvt, f13__Vcvt, f14__Vcvt, f15__Vcvt, f16__Vcvt, f17__Vcvt, f18__Vcvt, f19__Vcvt, f20__Vcvt, f21__Vcvt, f22__Vcvt, f23__Vcvt, f24__Vcvt, f25__Vcvt, f26__Vcvt, f27__Vcvt, f28__Vcvt, f29__Vcvt, f30__Vcvt, f31__Vcvt);
}

extern "C" void npc_mmio_load_event();

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_mmio_load_event_TOP____024unit() {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_mmio_load_event_TOP____024unit\n"); );
    // Body
    npc_mmio_load_event();
}

extern "C" void npc_trap_event(unsigned int cause, unsigned long long pc, unsigned long long tval);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_trap_event_TOP____024unit(IData/*31:0*/ cause, QData/*63:0*/ pc, QData/*63:0*/ tval) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_trap_event_TOP____024unit\n"); );
    // Body
    unsigned int cause__Vcvt;
    for (size_t cause__Vidx = 0; cause__Vidx < 1; ++cause__Vidx) cause__Vcvt = cause;
    unsigned long long pc__Vcvt;
    for (size_t pc__Vidx = 0; pc__Vidx < 1; ++pc__Vidx) pc__Vcvt = pc;
    unsigned long long tval__Vcvt;
    for (size_t tval__Vidx = 0; tval__Vidx < 1; ++tval__Vidx) tval__Vcvt = tval;
    npc_trap_event(cause__Vcvt, pc__Vcvt, tval__Vcvt);
}

extern "C" void npc_handled_trap_event(unsigned int kind, unsigned int cause, unsigned long long pc, unsigned long long tval);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_handled_trap_event_TOP____024unit(IData/*31:0*/ kind, IData/*31:0*/ cause, QData/*63:0*/ pc, QData/*63:0*/ tval) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_handled_trap_event_TOP____024unit\n"); );
    // Body
    unsigned int kind__Vcvt;
    for (size_t kind__Vidx = 0; kind__Vidx < 1; ++kind__Vidx) kind__Vcvt = kind;
    unsigned int cause__Vcvt;
    for (size_t cause__Vidx = 0; cause__Vidx < 1; ++cause__Vidx) cause__Vcvt = cause;
    unsigned long long pc__Vcvt;
    for (size_t pc__Vidx = 0; pc__Vidx < 1; ++pc__Vidx) pc__Vcvt = pc;
    unsigned long long tval__Vcvt;
    for (size_t tval__Vidx = 0; tval__Vidx < 1; ++tval__Vidx) tval__Vcvt = tval;
    npc_handled_trap_event(kind__Vcvt, cause__Vcvt, pc__Vcvt, tval__Vcvt);
}

extern "C" void npc_bpu_lookup_event(unsigned int is_branch, unsigned int is_jalr, unsigned int is_ret, unsigned int btb_hit, unsigned int bht_valid, unsigned int ras_lookup, unsigned int ras_hit, unsigned int ras_overflow);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_bpu_lookup_event_TOP____024unit(IData/*31:0*/ is_branch, IData/*31:0*/ is_jalr, IData/*31:0*/ is_ret, IData/*31:0*/ btb_hit, IData/*31:0*/ bht_valid, IData/*31:0*/ ras_lookup, IData/*31:0*/ ras_hit, IData/*31:0*/ ras_overflow) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_bpu_lookup_event_TOP____024unit\n"); );
    // Body
    unsigned int is_branch__Vcvt;
    for (size_t is_branch__Vidx = 0; is_branch__Vidx < 1; ++is_branch__Vidx) is_branch__Vcvt = is_branch;
    unsigned int is_jalr__Vcvt;
    for (size_t is_jalr__Vidx = 0; is_jalr__Vidx < 1; ++is_jalr__Vidx) is_jalr__Vcvt = is_jalr;
    unsigned int is_ret__Vcvt;
    for (size_t is_ret__Vidx = 0; is_ret__Vidx < 1; ++is_ret__Vidx) is_ret__Vcvt = is_ret;
    unsigned int btb_hit__Vcvt;
    for (size_t btb_hit__Vidx = 0; btb_hit__Vidx < 1; ++btb_hit__Vidx) btb_hit__Vcvt = btb_hit;
    unsigned int bht_valid__Vcvt;
    for (size_t bht_valid__Vidx = 0; bht_valid__Vidx < 1; ++bht_valid__Vidx) bht_valid__Vcvt = bht_valid;
    unsigned int ras_lookup__Vcvt;
    for (size_t ras_lookup__Vidx = 0; ras_lookup__Vidx < 1; ++ras_lookup__Vidx) ras_lookup__Vcvt = ras_lookup;
    unsigned int ras_hit__Vcvt;
    for (size_t ras_hit__Vidx = 0; ras_hit__Vidx < 1; ++ras_hit__Vidx) ras_hit__Vcvt = ras_hit;
    unsigned int ras_overflow__Vcvt;
    for (size_t ras_overflow__Vidx = 0; ras_overflow__Vidx < 1; ++ras_overflow__Vidx) ras_overflow__Vcvt = ras_overflow;
    npc_bpu_lookup_event(is_branch__Vcvt, is_jalr__Vcvt, is_ret__Vcvt, btb_hit__Vcvt, bht_valid__Vcvt, ras_lookup__Vcvt, ras_hit__Vcvt, ras_overflow__Vcvt);
}

extern "C" void npc_bpu_resolve_event(unsigned int is_branch, unsigned int pc, unsigned int is_jal, unsigned int is_jalr, unsigned int is_ret, unsigned int pred_taken, unsigned int actual_taken, unsigned int correct);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_bpu_resolve_event_TOP____024unit(IData/*31:0*/ is_branch, IData/*31:0*/ pc, IData/*31:0*/ is_jal, IData/*31:0*/ is_jalr, IData/*31:0*/ is_ret, IData/*31:0*/ pred_taken, IData/*31:0*/ actual_taken, IData/*31:0*/ correct) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_bpu_resolve_event_TOP____024unit\n"); );
    // Body
    unsigned int is_branch__Vcvt;
    for (size_t is_branch__Vidx = 0; is_branch__Vidx < 1; ++is_branch__Vidx) is_branch__Vcvt = is_branch;
    unsigned int pc__Vcvt;
    for (size_t pc__Vidx = 0; pc__Vidx < 1; ++pc__Vidx) pc__Vcvt = pc;
    unsigned int is_jal__Vcvt;
    for (size_t is_jal__Vidx = 0; is_jal__Vidx < 1; ++is_jal__Vidx) is_jal__Vcvt = is_jal;
    unsigned int is_jalr__Vcvt;
    for (size_t is_jalr__Vidx = 0; is_jalr__Vidx < 1; ++is_jalr__Vidx) is_jalr__Vcvt = is_jalr;
    unsigned int is_ret__Vcvt;
    for (size_t is_ret__Vidx = 0; is_ret__Vidx < 1; ++is_ret__Vidx) is_ret__Vcvt = is_ret;
    unsigned int pred_taken__Vcvt;
    for (size_t pred_taken__Vidx = 0; pred_taken__Vidx < 1; ++pred_taken__Vidx) pred_taken__Vcvt = pred_taken;
    unsigned int actual_taken__Vcvt;
    for (size_t actual_taken__Vidx = 0; actual_taken__Vidx < 1; ++actual_taken__Vidx) actual_taken__Vcvt = actual_taken;
    unsigned int correct__Vcvt;
    for (size_t correct__Vidx = 0; correct__Vidx < 1; ++correct__Vidx) correct__Vcvt = correct;
    npc_bpu_resolve_event(is_branch__Vcvt, pc__Vcvt, is_jal__Vcvt, is_jalr__Vcvt, is_ret__Vcvt, pred_taken__Vcvt, actual_taken__Vcvt, correct__Vcvt);
}

extern "C" void npc_icache_event(unsigned int access, unsigned int hit, unsigned int miss);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_icache_event_TOP____024unit(IData/*31:0*/ access, IData/*31:0*/ hit, IData/*31:0*/ miss) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_icache_event_TOP____024unit\n"); );
    // Body
    unsigned int access__Vcvt;
    for (size_t access__Vidx = 0; access__Vidx < 1; ++access__Vidx) access__Vcvt = access;
    unsigned int hit__Vcvt;
    for (size_t hit__Vidx = 0; hit__Vidx < 1; ++hit__Vidx) hit__Vcvt = hit;
    unsigned int miss__Vcvt;
    for (size_t miss__Vidx = 0; miss__Vidx < 1; ++miss__Vidx) miss__Vcvt = miss;
    npc_icache_event(access__Vcvt, hit__Vcvt, miss__Vcvt);
}

extern "C" void npc_dcache_event(unsigned int access, unsigned int hit, unsigned int miss, unsigned int writeback, unsigned int write_through, unsigned int is_store);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_dcache_event_TOP____024unit(IData/*31:0*/ access, IData/*31:0*/ hit, IData/*31:0*/ miss, IData/*31:0*/ writeback, IData/*31:0*/ write_through, IData/*31:0*/ is_store) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_dcache_event_TOP____024unit\n"); );
    // Body
    unsigned int access__Vcvt;
    for (size_t access__Vidx = 0; access__Vidx < 1; ++access__Vidx) access__Vcvt = access;
    unsigned int hit__Vcvt;
    for (size_t hit__Vidx = 0; hit__Vidx < 1; ++hit__Vidx) hit__Vcvt = hit;
    unsigned int miss__Vcvt;
    for (size_t miss__Vidx = 0; miss__Vidx < 1; ++miss__Vidx) miss__Vcvt = miss;
    unsigned int writeback__Vcvt;
    for (size_t writeback__Vidx = 0; writeback__Vidx < 1; ++writeback__Vidx) writeback__Vcvt = writeback;
    unsigned int write_through__Vcvt;
    for (size_t write_through__Vidx = 0; write_through__Vidx < 1; ++write_through__Vidx) write_through__Vcvt = write_through;
    unsigned int is_store__Vcvt;
    for (size_t is_store__Vidx = 0; is_store__Vidx < 1; ++is_store__Vidx) is_store__Vcvt = is_store;
    npc_dcache_event(access__Vcvt, hit__Vcvt, miss__Vcvt, writeback__Vcvt, write_through__Vcvt, is_store__Vcvt);
}

extern "C" void npc_ooo_cycle_event(unsigned int retire_count, unsigned int execute_count, unsigned int dispatch_count, unsigned int fetch_req_valid, unsigned int fetch_req_fire, unsigned int fetch_rsp_fire, unsigned int fetch_rsp_enqueue, unsigned int fetch_rsp_bypass, unsigned int stop_pending, unsigned int pending_branch, unsigned int pending_jump, unsigned int pending_mem, unsigned int synth_ret_pending, unsigned int branch_prefetch_fire, unsigned int branch_prefetch_hit, unsigned int mem0_req_fire, unsigned int mem1_req_fire, unsigned int mem0_rsp_fire, unsigned int mem1_rsp_fire, unsigned int commit1_block, unsigned int fetch_busy, unsigned int mem_busy, unsigned int axi_wait, unsigned int hazard_busy, unsigned int branch_flush, unsigned int exception_busy, unsigned long long pending_branch_pc, unsigned long long pending_jump_pc);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_ooo_cycle_event_TOP____024unit(IData/*31:0*/ retire_count, IData/*31:0*/ execute_count, IData/*31:0*/ dispatch_count, IData/*31:0*/ fetch_req_valid, IData/*31:0*/ fetch_req_fire, IData/*31:0*/ fetch_rsp_fire, IData/*31:0*/ fetch_rsp_enqueue, IData/*31:0*/ fetch_rsp_bypass, IData/*31:0*/ stop_pending, IData/*31:0*/ pending_branch, IData/*31:0*/ pending_jump, IData/*31:0*/ pending_mem, IData/*31:0*/ synth_ret_pending, IData/*31:0*/ branch_prefetch_fire, IData/*31:0*/ branch_prefetch_hit, IData/*31:0*/ mem0_req_fire, IData/*31:0*/ mem1_req_fire, IData/*31:0*/ mem0_rsp_fire, IData/*31:0*/ mem1_rsp_fire, IData/*31:0*/ commit1_block, IData/*31:0*/ fetch_busy, IData/*31:0*/ mem_busy, IData/*31:0*/ axi_wait, IData/*31:0*/ hazard_busy, IData/*31:0*/ branch_flush, IData/*31:0*/ exception_busy, QData/*63:0*/ pending_branch_pc, QData/*63:0*/ pending_jump_pc) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_ooo_cycle_event_TOP____024unit\n"); );
    // Body
    unsigned int retire_count__Vcvt;
    for (size_t retire_count__Vidx = 0; retire_count__Vidx < 1; ++retire_count__Vidx) retire_count__Vcvt = retire_count;
    unsigned int execute_count__Vcvt;
    for (size_t execute_count__Vidx = 0; execute_count__Vidx < 1; ++execute_count__Vidx) execute_count__Vcvt = execute_count;
    unsigned int dispatch_count__Vcvt;
    for (size_t dispatch_count__Vidx = 0; dispatch_count__Vidx < 1; ++dispatch_count__Vidx) dispatch_count__Vcvt = dispatch_count;
    unsigned int fetch_req_valid__Vcvt;
    for (size_t fetch_req_valid__Vidx = 0; fetch_req_valid__Vidx < 1; ++fetch_req_valid__Vidx) fetch_req_valid__Vcvt = fetch_req_valid;
    unsigned int fetch_req_fire__Vcvt;
    for (size_t fetch_req_fire__Vidx = 0; fetch_req_fire__Vidx < 1; ++fetch_req_fire__Vidx) fetch_req_fire__Vcvt = fetch_req_fire;
    unsigned int fetch_rsp_fire__Vcvt;
    for (size_t fetch_rsp_fire__Vidx = 0; fetch_rsp_fire__Vidx < 1; ++fetch_rsp_fire__Vidx) fetch_rsp_fire__Vcvt = fetch_rsp_fire;
    unsigned int fetch_rsp_enqueue__Vcvt;
    for (size_t fetch_rsp_enqueue__Vidx = 0; fetch_rsp_enqueue__Vidx < 1; ++fetch_rsp_enqueue__Vidx) fetch_rsp_enqueue__Vcvt = fetch_rsp_enqueue;
    unsigned int fetch_rsp_bypass__Vcvt;
    for (size_t fetch_rsp_bypass__Vidx = 0; fetch_rsp_bypass__Vidx < 1; ++fetch_rsp_bypass__Vidx) fetch_rsp_bypass__Vcvt = fetch_rsp_bypass;
    unsigned int stop_pending__Vcvt;
    for (size_t stop_pending__Vidx = 0; stop_pending__Vidx < 1; ++stop_pending__Vidx) stop_pending__Vcvt = stop_pending;
    unsigned int pending_branch__Vcvt;
    for (size_t pending_branch__Vidx = 0; pending_branch__Vidx < 1; ++pending_branch__Vidx) pending_branch__Vcvt = pending_branch;
    unsigned int pending_jump__Vcvt;
    for (size_t pending_jump__Vidx = 0; pending_jump__Vidx < 1; ++pending_jump__Vidx) pending_jump__Vcvt = pending_jump;
    unsigned int pending_mem__Vcvt;
    for (size_t pending_mem__Vidx = 0; pending_mem__Vidx < 1; ++pending_mem__Vidx) pending_mem__Vcvt = pending_mem;
    unsigned int synth_ret_pending__Vcvt;
    for (size_t synth_ret_pending__Vidx = 0; synth_ret_pending__Vidx < 1; ++synth_ret_pending__Vidx) synth_ret_pending__Vcvt = synth_ret_pending;
    unsigned int branch_prefetch_fire__Vcvt;
    for (size_t branch_prefetch_fire__Vidx = 0; branch_prefetch_fire__Vidx < 1; ++branch_prefetch_fire__Vidx) branch_prefetch_fire__Vcvt = branch_prefetch_fire;
    unsigned int branch_prefetch_hit__Vcvt;
    for (size_t branch_prefetch_hit__Vidx = 0; branch_prefetch_hit__Vidx < 1; ++branch_prefetch_hit__Vidx) branch_prefetch_hit__Vcvt = branch_prefetch_hit;
    unsigned int mem0_req_fire__Vcvt;
    for (size_t mem0_req_fire__Vidx = 0; mem0_req_fire__Vidx < 1; ++mem0_req_fire__Vidx) mem0_req_fire__Vcvt = mem0_req_fire;
    unsigned int mem1_req_fire__Vcvt;
    for (size_t mem1_req_fire__Vidx = 0; mem1_req_fire__Vidx < 1; ++mem1_req_fire__Vidx) mem1_req_fire__Vcvt = mem1_req_fire;
    unsigned int mem0_rsp_fire__Vcvt;
    for (size_t mem0_rsp_fire__Vidx = 0; mem0_rsp_fire__Vidx < 1; ++mem0_rsp_fire__Vidx) mem0_rsp_fire__Vcvt = mem0_rsp_fire;
    unsigned int mem1_rsp_fire__Vcvt;
    for (size_t mem1_rsp_fire__Vidx = 0; mem1_rsp_fire__Vidx < 1; ++mem1_rsp_fire__Vidx) mem1_rsp_fire__Vcvt = mem1_rsp_fire;
    unsigned int commit1_block__Vcvt;
    for (size_t commit1_block__Vidx = 0; commit1_block__Vidx < 1; ++commit1_block__Vidx) commit1_block__Vcvt = commit1_block;
    unsigned int fetch_busy__Vcvt;
    for (size_t fetch_busy__Vidx = 0; fetch_busy__Vidx < 1; ++fetch_busy__Vidx) fetch_busy__Vcvt = fetch_busy;
    unsigned int mem_busy__Vcvt;
    for (size_t mem_busy__Vidx = 0; mem_busy__Vidx < 1; ++mem_busy__Vidx) mem_busy__Vcvt = mem_busy;
    unsigned int axi_wait__Vcvt;
    for (size_t axi_wait__Vidx = 0; axi_wait__Vidx < 1; ++axi_wait__Vidx) axi_wait__Vcvt = axi_wait;
    unsigned int hazard_busy__Vcvt;
    for (size_t hazard_busy__Vidx = 0; hazard_busy__Vidx < 1; ++hazard_busy__Vidx) hazard_busy__Vcvt = hazard_busy;
    unsigned int branch_flush__Vcvt;
    for (size_t branch_flush__Vidx = 0; branch_flush__Vidx < 1; ++branch_flush__Vidx) branch_flush__Vcvt = branch_flush;
    unsigned int exception_busy__Vcvt;
    for (size_t exception_busy__Vidx = 0; exception_busy__Vidx < 1; ++exception_busy__Vidx) exception_busy__Vcvt = exception_busy;
    unsigned long long pending_branch_pc__Vcvt;
    for (size_t pending_branch_pc__Vidx = 0; pending_branch_pc__Vidx < 1; ++pending_branch_pc__Vidx) pending_branch_pc__Vcvt = pending_branch_pc;
    unsigned long long pending_jump_pc__Vcvt;
    for (size_t pending_jump_pc__Vidx = 0; pending_jump_pc__Vidx < 1; ++pending_jump_pc__Vidx) pending_jump_pc__Vcvt = pending_jump_pc;
    npc_ooo_cycle_event(retire_count__Vcvt, execute_count__Vcvt, dispatch_count__Vcvt, fetch_req_valid__Vcvt, fetch_req_fire__Vcvt, fetch_rsp_fire__Vcvt, fetch_rsp_enqueue__Vcvt, fetch_rsp_bypass__Vcvt, stop_pending__Vcvt, pending_branch__Vcvt, pending_jump__Vcvt, pending_mem__Vcvt, synth_ret_pending__Vcvt, branch_prefetch_fire__Vcvt, branch_prefetch_hit__Vcvt, mem0_req_fire__Vcvt, mem1_req_fire__Vcvt, mem0_rsp_fire__Vcvt, mem1_rsp_fire__Vcvt, commit1_block__Vcvt, fetch_busy__Vcvt, mem_busy__Vcvt, axi_wait__Vcvt, hazard_busy__Vcvt, branch_flush__Vcvt, exception_busy__Vcvt, pending_branch_pc__Vcvt, pending_jump_pc__Vcvt);
}

extern "C" void npc_uart_event(unsigned int is_write, unsigned int tx_valid, unsigned int tx_data, unsigned int access_addr, unsigned long long access_wdata, unsigned int access_wstrb, unsigned long long access_rdata);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_uart_event_TOP____024unit(IData/*31:0*/ is_write, IData/*31:0*/ tx_valid, IData/*31:0*/ tx_data, IData/*31:0*/ access_addr, QData/*63:0*/ access_wdata, IData/*31:0*/ access_wstrb, QData/*63:0*/ access_rdata) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_uart_event_TOP____024unit\n"); );
    // Body
    unsigned int is_write__Vcvt;
    for (size_t is_write__Vidx = 0; is_write__Vidx < 1; ++is_write__Vidx) is_write__Vcvt = is_write;
    unsigned int tx_valid__Vcvt;
    for (size_t tx_valid__Vidx = 0; tx_valid__Vidx < 1; ++tx_valid__Vidx) tx_valid__Vcvt = tx_valid;
    unsigned int tx_data__Vcvt;
    for (size_t tx_data__Vidx = 0; tx_data__Vidx < 1; ++tx_data__Vidx) tx_data__Vcvt = tx_data;
    unsigned int access_addr__Vcvt;
    for (size_t access_addr__Vidx = 0; access_addr__Vidx < 1; ++access_addr__Vidx) access_addr__Vcvt = access_addr;
    unsigned long long access_wdata__Vcvt;
    for (size_t access_wdata__Vidx = 0; access_wdata__Vidx < 1; ++access_wdata__Vidx) access_wdata__Vcvt = access_wdata;
    unsigned int access_wstrb__Vcvt;
    for (size_t access_wstrb__Vidx = 0; access_wstrb__Vidx < 1; ++access_wstrb__Vidx) access_wstrb__Vcvt = access_wstrb;
    unsigned long long access_rdata__Vcvt;
    for (size_t access_rdata__Vidx = 0; access_rdata__Vidx < 1; ++access_rdata__Vidx) access_rdata__Vcvt = access_rdata;
    npc_uart_event(is_write__Vcvt, tx_valid__Vcvt, tx_data__Vcvt, access_addr__Vcvt, access_wdata__Vcvt, access_wstrb__Vcvt, access_rdata__Vcvt);
}

extern "C" int npc_uart_rx_pop(unsigned int* data);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_uart_rx_pop_TOP____024unit(IData/*31:0*/ &data, IData/*31:0*/ &npc_uart_rx_pop__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_uart_rx_pop_TOP____024unit\n"); );
    // Body
    unsigned int data__Vcvt;
    int npc_uart_rx_pop__Vfuncrtn__Vcvt;
    npc_uart_rx_pop__Vfuncrtn__Vcvt = npc_uart_rx_pop(&data__Vcvt);
    data = data__Vcvt;
    npc_uart_rx_pop__Vfuncrtn = npc_uart_rx_pop__Vfuncrtn__Vcvt;
}

extern "C" void npc_irq_event(unsigned int uart_irq, unsigned int plic_irq);

VL_INLINE_OPT void VNpcSimTop___024unit____Vdpiimwrap_npc_irq_event_TOP____024unit(IData/*31:0*/ uart_irq, IData/*31:0*/ plic_irq) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VNpcSimTop___024unit____Vdpiimwrap_npc_irq_event_TOP____024unit\n"); );
    // Body
    unsigned int uart_irq__Vcvt;
    for (size_t uart_irq__Vidx = 0; uart_irq__Vidx < 1; ++uart_irq__Vidx) uart_irq__Vcvt = uart_irq;
    unsigned int plic_irq__Vcvt;
    for (size_t plic_irq__Vidx = 0; plic_irq__Vidx < 1; ++plic_irq__Vidx) plic_irq__Vcvt = plic_irq;
    npc_irq_event(uart_irq__Vcvt, plic_irq__Vcvt);
}
