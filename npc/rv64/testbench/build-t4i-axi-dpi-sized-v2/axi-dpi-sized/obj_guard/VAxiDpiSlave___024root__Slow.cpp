// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VAxiDpiSlave.h for the primary calling header

#include "VAxiDpiSlave__pch.h"

void VAxiDpiSlave___024root___ctor_var_reset(VAxiDpiSlave___024root* vlSelf);

VAxiDpiSlave___024root::VAxiDpiSlave___024root(VAxiDpiSlave__Syms* symsp, const char* namep)
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    VAxiDpiSlave___024root___ctor_var_reset(this);
}

void VAxiDpiSlave___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

VAxiDpiSlave___024root::~VAxiDpiSlave___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
