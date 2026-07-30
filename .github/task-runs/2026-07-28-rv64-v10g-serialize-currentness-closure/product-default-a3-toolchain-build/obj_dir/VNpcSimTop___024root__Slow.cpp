// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VNpcSimTop.h for the primary calling header

#include "VNpcSimTop__pch.h"
#include "VNpcSimTop__Syms.h"
#include "VNpcSimTop___024root.h"

void VNpcSimTop___024root___ctor_var_reset(VNpcSimTop___024root* vlSelf);

VNpcSimTop___024root::VNpcSimTop___024root(VNpcSimTop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VNpcSimTop___024root___ctor_var_reset(this);
}

void VNpcSimTop___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

VNpcSimTop___024root::~VNpcSimTop___024root() {
}
