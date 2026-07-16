// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VAxiDpiSlave.h for the primary calling header

#ifndef VERILATED_VAXIDPISLAVE___024UNIT_H_
#define VERILATED_VAXIDPISLAVE___024UNIT_H_  // guard

#include "verilated.h"


class VAxiDpiSlave__Syms;

class alignas(VL_CACHE_LINE_BYTES) VAxiDpiSlave___024unit final {
  public:

    // INTERNAL VARIABLES
    VAxiDpiSlave__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    VAxiDpiSlave___024unit();
    ~VAxiDpiSlave___024unit();
    void ctor(VAxiDpiSlave__Syms* symsp, const char* namep);
    void dtor();
    VL_UNCOPYABLE(VAxiDpiSlave___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
