// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VAxiDpiSlave__pch.h"

VAxiDpiSlave__Syms::VAxiDpiSlave__Syms(VerilatedContext* contextp, const char* namep, VAxiDpiSlave* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup top module instance
    , TOP{this, namep}
{
    // Check resources
    Verilated::stackCheck(544);
    // Setup sub module instances
    TOP____024unit.ctor(this, "$unit");
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    TOP.__PVT____024unit = &TOP____024unit;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP____024unit.__Vconfigure(true);
    // Setup scopes
    // Setup export functions - final: 0
    // Setup export functions - final: 1
}

VAxiDpiSlave__Syms::~VAxiDpiSlave__Syms() {
    // Tear down scopes
    // Tear down sub module instances
    TOP____024unit.dtor();
}
