// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "Vkey__Syms.h"


void Vkey___024root__trace_chg_0_sub_0(Vkey___024root* vlSelf, VerilatedFst::Buffer* bufp);

void Vkey___024root__trace_chg_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root__trace_chg_0\n"); );
    // Init
    Vkey___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vkey___024root*>(voidSelf);
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vkey___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vkey___024root__trace_chg_0_sub_0(Vkey___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelf->clk));
    bufp->chgBit(oldp+1,(vlSelf->rst));
    bufp->chgBit(oldp+2,(vlSelf->a));
    bufp->chgBit(oldp+3,(vlSelf->b));
    bufp->chgBit(oldp+4,(vlSelf->f));
}

void Vkey___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root__trace_cleanup\n"); );
    // Init
    Vkey___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vkey___024root*>(voidSelf);
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
