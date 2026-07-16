// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VAXIDPISLAVE__DPI_H_
#define VERILATED_VAXIDPISLAVE__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI IMPORTS
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:5:21
    extern int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:12:21
    extern int npc_mem_read_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:19:21
    extern int npc_mem_write(unsigned long long addr, unsigned long long data, unsigned long long mask, svBit* error);

#ifdef __cplusplus
}
#endif

#endif  // guard
