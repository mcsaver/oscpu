// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VAxiDpiSlave.h for the primary calling header

#include "VAxiDpiSlave__pch.h"

extern "C" int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);

void VAxiDpiSlave___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VAxiDpiSlave___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit\n"); );
    // Body
    data = 0ULL;
    error = 0U;
    unsigned long long addr__Vcvt;
    addr__Vcvt = addr;
    unsigned int nbytes__Vcvt;
    nbytes__Vcvt = nbytes;
    unsigned long long data__Vcvt;
    svBit error__Vcvt;
    npc_ifetch_sized(addr__Vcvt, nbytes__Vcvt, &data__Vcvt, &error__Vcvt);
    data = (data__Vcvt);
    error = (1U & (error__Vcvt));
}

extern "C" int npc_mem_read_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);

void VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit\n"); );
    // Body
    data = 0ULL;
    error = 0U;
    unsigned long long addr__Vcvt;
    addr__Vcvt = addr;
    unsigned int nbytes__Vcvt;
    nbytes__Vcvt = nbytes;
    unsigned long long data__Vcvt;
    svBit error__Vcvt;
    npc_mem_read_sized(addr__Vcvt, nbytes__Vcvt, &data__Vcvt, &error__Vcvt);
    data = (data__Vcvt);
    error = (1U & (error__Vcvt));
}

extern "C" int npc_mem_write(unsigned long long addr, unsigned long long data, unsigned long long mask, svBit* error);

void VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit(QData/*63:0*/ addr, QData/*63:0*/ data, QData/*63:0*/ mask, CData/*0:0*/ &error) {
    VL_DEBUG_IF(VL_DBG_MSGF("+        VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit\n"); );
    // Body
    error = 0U;
    unsigned long long addr__Vcvt;
    addr__Vcvt = addr;
    unsigned long long data__Vcvt;
    data__Vcvt = data;
    unsigned long long mask__Vcvt;
    mask__Vcvt = mask;
    svBit error__Vcvt;
    npc_mem_write(addr__Vcvt, data__Vcvt, mask__Vcvt, &error__Vcvt);
    error = (1U & (error__Vcvt));
}
