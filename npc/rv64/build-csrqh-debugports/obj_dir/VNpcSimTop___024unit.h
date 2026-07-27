// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VNpcSimTop.h for the primary calling header

#ifndef VERILATED_VNPCSIMTOP___024UNIT_H_
#define VERILATED_VNPCSIMTOP___024UNIT_H_  // guard

#include "verilated.h"


class VNpcSimTop__Syms;

class alignas(VL_CACHE_LINE_BYTES) VNpcSimTop___024unit final : public VerilatedModule {
  public:

    // INTERNAL VARIABLES
    VNpcSimTop__Syms* const vlSymsp;

    // CONSTRUCTORS
    VNpcSimTop___024unit(VNpcSimTop__Syms* symsp, const char* v__name);
    ~VNpcSimTop___024unit();
    VL_UNCOPYABLE(VNpcSimTop___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
