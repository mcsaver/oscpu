// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VAXIDPISLAVE__SYMS_H_
#define VERILATED_VAXIDPISLAVE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "VAxiDpiSlave.h"

// INCLUDE MODULE CLASSES
#include "VAxiDpiSlave___024root.h"
#include "VAxiDpiSlave___024unit.h"

// DPI TYPES for DPI Export callbacks (Internal use)

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) VAxiDpiSlave__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    VAxiDpiSlave* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    VAxiDpiSlave___024root         TOP;
    VAxiDpiSlave___024unit         TOP____024unit;

    // CONSTRUCTORS
    VAxiDpiSlave__Syms(VerilatedContext* contextp, const char* namep, VAxiDpiSlave* modelp);
    ~VAxiDpiSlave__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
