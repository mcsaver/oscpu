// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VAxiDpiSlave.h for the primary calling header

#include "VAxiDpiSlave__pch.h"


VAxiDpiSlave___024unit::VAxiDpiSlave___024unit() = default;
VAxiDpiSlave___024unit::~VAxiDpiSlave___024unit() = default;

void VAxiDpiSlave___024unit::ctor(VAxiDpiSlave__Syms* symsp, const char* namep) {
    vlSymsp = symsp;
    vlNamep = strdup(Verilated::catName(vlSymsp->name(), namep));
    // Reset structure values
}

void VAxiDpiSlave___024unit::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

void VAxiDpiSlave___024unit::dtor() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
