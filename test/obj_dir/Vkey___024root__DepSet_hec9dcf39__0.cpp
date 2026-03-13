// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vkey.h for the primary calling header

#include "Vkey__pch.h"
#include "Vkey___024root.h"

void Vkey___024root___eval_act(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vkey___024root___nba_sequent__TOP__0(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___nba_sequent__TOP__0\n"); );
    // Body
    vlSelf->f = ((1U & (~ (IData)(vlSelf->rst))) && 
                 ((IData)(vlSelf->a) ^ (IData)(vlSelf->b)));
}

void Vkey___024root___eval_nba(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vkey___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vkey___024root___eval_triggers__act(Vkey___024root* vlSelf);

bool Vkey___024root___eval_phase__act(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vkey___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vkey___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vkey___024root___eval_phase__nba(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vkey___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vkey___024root___dump_triggers__nba(Vkey___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vkey___024root___dump_triggers__act(Vkey___024root* vlSelf);
#endif  // VL_DEBUG

void Vkey___024root___eval(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vkey___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("key.v", 3, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vkey___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("key.v", 3, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vkey___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vkey___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vkey___024root___eval_debug_assertions(Vkey___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vkey___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->a & 0xfeU))) {
        Verilated::overWidthError("a");}
    if (VL_UNLIKELY((vlSelf->b & 0xfeU))) {
        Verilated::overWidthError("b");}
}
#endif  // VL_DEBUG
