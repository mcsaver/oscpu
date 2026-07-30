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
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    TOP.__PVT____024unit = &TOP____024unit;
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    TOP____024unit.__Vconfigure(true);
    // Setup scopes
    __Vscope_NpcSimTop.configure(this, name(), "NpcSimTop", "NpcSimTop", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_fetch_adupd_checker.configure(this, name(), "NpcSimTop.u_ooo_fetch_adupd_checker", "u_ooo_fetch_adupd_checker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_fetch_adupd_checker__g_fetch_no_d.configure(this, name(), "NpcSimTop.u_ooo_fetch_adupd_checker.g_fetch_no_d", "g_fetch_no_d", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_mem0_adupd_checker.configure(this, name(), "NpcSimTop.u_ooo_mem0_adupd_checker", "u_ooo_mem0_adupd_checker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_mem1_adupd_checker.configure(this, name(), "NpcSimTop.u_ooo_mem1_adupd_checker", "u_ooo_mem1_adupd_checker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_rdmux_checker.configure(this, name(), "NpcSimTop.u_ooo_rdmux_checker", "u_ooo_rdmux_checker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_ooo_rdseq_checker.configure(this, name(), "NpcSimTop.u_ooo_rdseq_checker", "u_ooo_rdseq_checker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core.configure(this, name(), "NpcSimTop.u_top.u_core", "u_core", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_csr_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_csr_file", "u_csr_file", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_lsu_lane_adapter.configure(this, name(), "NpcSimTop.u_top.u_core.u_lsu_lane_adapter", "u_lsu_lane_adapter", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core", "u_ooo_core", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_event_apply_sequencer.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_event_apply_sequencer", "u_control_event_apply_sequencer", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane", "u_control_plane", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane__u_pending_system_sequencer.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_pending_system_sequencer", "u_pending_system_sequencer", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane__u_pending_trap_exit_sequencer.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_pending_trap_exit_sequencer", "u_pending_trap_exit_sequencer", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_control_plane__u_stop_pending_sequencer.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_stop_pending_sequencer", "u_stop_pending_sequencer", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice", "u_core_slice", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend", "u_int_backend", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_branch_resolve_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_branch_resolve_stage", "u_branch_resolve_stage", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_clmul_unit.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_clmul_unit", "u_clmul_unit", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_dispatch_backend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_dispatch_backend", "u_dispatch_backend", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_dispatch_backend__u_issue_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_dispatch_backend.u_issue_queue", "u_issue_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_dispatch_backend__u_rob.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_dispatch_backend.u_rob", "u_rob", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_ex0_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_ex0_stage", "u_ex0_stage", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_ex1_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_ex1_stage", "u_ex1_stage", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend", "u_fp_backend", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_exec1_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_exec1_stage", "u_exec1_stage", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_arith.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith", "u_fp_arith", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_arith__fp_arith_pid_assert_blk.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk", "fp_arith_pid_assert_blk", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_issue_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue", "u_fp_issue_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_issue_queue__fp_iq_pid_unique_assert_blk.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk", "fp_iq_pid_unique_assert_blk", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_issue_stage.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_stage", "u_fp_issue_stage", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__u_fp_phys_reg_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_phys_reg_file", "u_fp_phys_reg_file", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_fp_backend__v8i_fp_lease_assert_blk.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.v8i_fp_lease_assert_blk", "v8i_fp_lease_assert_blk", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_load_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue", "u_load_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_mem1_inflight_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem1_inflight_queue", "u_mem1_inflight_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_mem_inflight_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem_inflight_queue", "u_mem_inflight_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_mem_owner_terminal_collector.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem_owner_terminal_collector", "u_mem_owner_terminal_collector", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_mem_owner_tracker.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_mem_owner_tracker", "u_mem_owner_tracker", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_muldiv_unit.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_muldiv_unit", "u_muldiv_unit", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_phys_reg_file.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_phys_reg_file", "u_phys_reg_file", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_execute_backend__u_core_slice__u_decode_backend__u_int_backend__u_store_queue.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_store_queue", "u_store_queue", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend", "u_frontend", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_dec0_branch_target.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec0_branch_target", "u_fetch_dec0_branch_target", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_dec1_branch_target.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec1_branch_target", "u_fetch_dec1_branch_target", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_fetch_packet_fifo.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo", "u_fetch_packet_fifo", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_frontend__u_redirect_arbiter.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_redirect_arbiter", "u_redirect_arbiter", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_core__u_writeback.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_core.u_writeback", "u_writeback", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge", "u_ooo_dual_mem_bridge", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge0.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0", "u_bridge0", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge0__u_dcache.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache", "u_dcache", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge0__u_req_post_translate_class.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_req_post_translate_class", "u_req_post_translate_class", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge0__u_walk_post_translate_class.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_walk_post_translate_class", "u_walk_post_translate_class", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge1.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1", "u_bridge1", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge1__u_dcache.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache", "u_dcache", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge1__u_req_post_translate_class.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_req_post_translate_class", "u_req_post_translate_class", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_bridge1__u_walk_post_translate_class.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_walk_post_translate_class", "u_walk_post_translate_class", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_dual_mem_bridge__u_miss_arbiter.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter", "u_miss_arbiter", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_fetch_bridge.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_fetch_bridge", "u_ooo_fetch_bridge", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_top__u_core__u_ooo_fetch_bridge__u_fetch_packet_cache.configure(this, name(), "NpcSimTop.u_top.u_core.u_ooo_fetch_bridge.u_fetch_packet_cache", "u_fetch_packet_cache", -9, VerilatedScope::SCOPE_OTHER);
    __Vscope_NpcSimTop__u_virtio_blk_axi.configure(this, name(), "NpcSimTop.u_virtio_blk_axi", "u_virtio_blk_axi", -9, VerilatedScope::SCOPE_OTHER);
    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
    }
}
