// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VNPCSIMTOP__DPI_H_
#define VERILATED_VNPCSIMTOP__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI IMPORTS
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:26:30
    extern void npc_arch_csr_event(unsigned long long c0, unsigned long long c1, unsigned long long c2, unsigned long long c3, unsigned long long c4, unsigned long long c5, unsigned long long c6, unsigned long long c7, unsigned long long c8, unsigned long long c9, unsigned long long c10, unsigned long long c11, unsigned long long c12, unsigned long long c13, unsigned long long c14, unsigned long long c15, unsigned long long c16, unsigned long long c17, unsigned long long c18, unsigned long long c19, unsigned long long c20, unsigned long long c21, unsigned long long c22);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:38:30
    extern void npc_arch_fpr_event(unsigned long long f0, unsigned long long f1, unsigned long long f2, unsigned long long f3, unsigned long long f4, unsigned long long f5, unsigned long long f6, unsigned long long f7, unsigned long long f8, unsigned long long f9, unsigned long long f10, unsigned long long f11, unsigned long long f12, unsigned long long f13, unsigned long long f14, unsigned long long f15, unsigned long long f16, unsigned long long f17, unsigned long long f18, unsigned long long f19, unsigned long long f20, unsigned long long f21, unsigned long long f22, unsigned long long f23, unsigned long long f24, unsigned long long f25, unsigned long long f26, unsigned long long f27, unsigned long long f28, unsigned long long f29, unsigned long long f30, unsigned long long f31);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:6:30
    extern void npc_commit_event(unsigned long long pc, unsigned int inst, unsigned long long next_pc, unsigned int rd_en, unsigned int rd_addr, unsigned long long rd_data, unsigned int is_fp);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:16:30
    extern void npc_exit_event(unsigned int is_ebreak, unsigned int is_ecall, unsigned int is_system_reset, unsigned long long code, unsigned long long pc);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:59:30
    extern void npc_handled_trap_event(unsigned int kind, unsigned int cause, unsigned long long pc, unsigned long long tval);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:5:21
    extern int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:154:30
    extern void npc_irq_event(unsigned int uart_irq, unsigned int plic_irq);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:12:21
    extern int npc_mem_read_sized(unsigned long long addr, unsigned int nbytes, unsigned long long* data, svBit* error);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv:19:21
    extern int npc_mem_write(unsigned long long addr, unsigned long long data, unsigned long long mask, svBit* error);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:52:30
    extern void npc_mmio_load_event();
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:53:30
    extern void npc_trap_event(unsigned int cause, unsigned long long pc, unsigned long long tval);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:140:30
    extern void npc_uart_event(unsigned int is_write, unsigned int tx_valid, unsigned int tx_data, unsigned int access_addr, unsigned long long access_wdata, unsigned int access_wstrb, unsigned long long access_rdata);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/NpcSimTop.sv:150:29
    extern int npc_uart_rx_pop(unsigned int* data);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiVirtioBlk.sv:20:21
    extern int npc_virtio_blk_irq(svBit* irq);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiVirtioBlk.sv:5:21
    extern int npc_virtio_blk_read(unsigned int offset, unsigned long long* data, svBit* error, svBit* irq);
    // DPI import at /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiVirtioBlk.sv:12:21
    extern int npc_virtio_blk_write(unsigned int offset, unsigned long long data, unsigned long long mask, svBit* error, svBit* irq);

#ifdef __cplusplus
}
#endif

#endif  // guard
