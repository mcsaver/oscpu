// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VNpcSimTop__pch.h"
#include "VNpcSimTop.h"
#include "VNpcSimTop___024root.h"
#include "VNpcSimTop___024unit.h"

// FUNCTIONS
VNpcSimTop__Syms::~VNpcSimTop__Syms()
{
}

VNpcSimTop__Syms::VNpcSimTop__Syms(VerilatedContext* contextp, const char* namep, VNpcSimTop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
    , TOP____024unit{this, Verilated::catName(namep, "$unit")}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    TOP.__PVT____024unit = &TOP____024unit;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP____024unit.__Vconfigure(true);
    // Setup scopes
    __Vscope_NpcSimTop.configure(this, name(), "NpcSimTop", "NpcSimTop", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_fetch_adupd_checker.configure(this, name(), "NpcSimTop.u_ooo_fetch_adupd_checker", "u_ooo_fetch_adupd_checker", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_fetch_adupd_checker__g_fetch_no_d.configure(this, name(), "NpcSimTop.u_ooo_fetch_adupd_checker.g_fetch_no_d", "g_fetch_no_d", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_mem_adupd_checker.configure(this, name(), "NpcSimTop.u_ooo_mem_adupd_checker", "u_ooo_mem_adupd_checker", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_rdmux_checker.configure(this, name(), "NpcSimTop.u_ooo_rdmux_checker", "u_ooo_rdmux_checker", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_rdseq_checker.configure(this, name(), "NpcSimTop.u_ooo_rdseq_checker", "u_ooo_rdseq_checker", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_csr_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_csr_file", "u_csr_file", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_lsu_lane_adapter.configure(this, name(), "NpcSimTop.u_top.u_core.u_lsu_lane_adapter", "u_lsu_lane_adapter", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core", "u_ooo_core", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane", "u_control_plane", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane__u_pending_trap_exit_sequencer.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_pending_trap_exit_sequencer", "u_pending_trap_exit_sequencer", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice", "u_core_slice", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend", "u_int_backend", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_branch_resolve_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_branch_resolve_stage", "u_branch_resolve_stage", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_dispatch_backend__u_issue_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_dispatch_backend.u_issue_queue", "u_issue_queue", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_dispatch_backend__u_rob.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_dispatch_backend.u_rob", "u_rob", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_ex0_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_ex0_stage", "u_ex0_stage", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_ex1_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_ex1_stage", "u_ex1_stage", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend", "u_fp_backend", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_exec1_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_exec1_stage", "u_exec1_stage", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_arith.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith", "u_fp_arith", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_issue_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue", "u_fp_issue_queue", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_issue_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_stage", "u_fp_issue_stage", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_phys_reg_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_phys_reg_file", "u_fp_phys_reg_file", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_mem_inflight_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem_inflight_queue", "u_mem_inflight_queue", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_muldiv_unit.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_muldiv_unit", "u_muldiv_unit", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_phys_reg_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_phys_reg_file", "u_phys_reg_file", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_store_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_store_queue", "u_store_queue", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend", "u_frontend", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_dec0_branch_target.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec0_branch_target", "u_fetch_dec0_branch_target", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_dec1_branch_target.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec1_branch_target", "u_fetch_dec1_branch_target", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_packet_fifo.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo", "u_fetch_packet_fifo", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_writeback.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_writeback", "u_writeback", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_fetch_bridge.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_fetch_bridge", "u_ooo_fetch_bridge", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_fetch_bridge__u_fetch_packet_cache.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_fetch_bridge.u_fetch_packet_cache", "u_fetch_packet_cache", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_mem_bridge.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_mem_bridge", "u_ooo_mem_bridge", -12, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_mem_bridge__u_dcache.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_mem_bridge.u_dcache", "u_dcache", -12, VerilatedScope::SCOPE_OTHER);
    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
    }
}
