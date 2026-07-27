// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VNpcSimTop.h for the primary calling header

#include "VNpcSimTop__pch.h"
#include "VNpcSimTop__Syms.h"
#include "VNpcSimTop___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void VNpcSimTop___024root___dump_triggers__act(VNpcSimTop___024root* vlSelf);
#endif  // VL_DEBUG

void VNpcSimTop___024root___eval_triggers__act(VNpcSimTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VNpcSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VNpcSimTop___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, ((IData)(vlSelf->clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__clk__0))));
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VNpcSimTop___024root___dump_triggers__act(vlSelf);
    }
#endif
}

extern const VlWide<8>/*255:0*/ VNpcSimTop__ConstPool__CONST_h4e9f510d_0;
extern const VlWide<8>/*255:0*/ VNpcSimTop__ConstPool__CONST_h9e67c271_0;

VL_INLINE_OPT void VNpcSimTop___024root___nba_sequent__TOP__0(VNpcSimTop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VNpcSimTop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VNpcSimTop___024root___nba_sequent__TOP__0\n"); );
    // Init
    VlWide<4>/*127:0*/ __Vtemp_10;
    VlWide<23>/*735:0*/ __Vtemp_18;
    VlWide<8>/*255:0*/ __Vtemp_49;
    VlWide<8>/*255:0*/ __Vtemp_51;
    VlWide<8>/*255:0*/ __Vtemp_52;
    VlWide<8>/*255:0*/ __Vtemp_54;
    VlWide<8>/*255:0*/ __Vtemp_56;
    VlWide<8>/*255:0*/ __Vtemp_57;
    VlWide<8>/*255:0*/ __Vtemp_59;
    // Body
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((3U == ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                                  & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w)) 
                                 << 1U) | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                                           ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w)))))) {
            VL_WRITEF("[%0t] %%Error: OooWriteback.v:214: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_writeback: [INSTRET-G1-FINAL-EQ] final_count=%0# expected=%0# c0=%b/%b c1=%b/%b @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),2,((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                                           & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w)) 
                                          << 1U) | 
                                         ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                                          ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w))),
                      2,((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                           & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w)) 
                          << 1U) | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit0_isa_retire_w) 
                                    ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_writeback__DOT__u_commit_output_mux__DOT__commit1_isa_retire_w))),
                      1,(IData)(vlSelf->NpcSimTop__DOT__core_commit0_valid_w),
                      1,vlSelf->NpcSimTop__DOT__core_commit0_exception_w,
                      1,(IData)(vlSelf->NpcSimTop__DOT__core_commit1_valid_w),
                      1,vlSelf->NpcSimTop__DOT__core_commit1_exception_w,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/OooWriteback.v", 214, "");
            VL_WRITEF("[%0t] %%Fatal: OooWriteback.v:218: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_writeback\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/OooWriteback.v", 218, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__uart_rx_poll_q 
        = vlSelf->NpcSimTop__DOT__uart_rx_poll_q;
    vlSelf->__Vdly__NpcSimTop__DOT__uart_rx_data_q 
        = vlSelf->NpcSimTop__DOT__uart_rx_data_q;
    vlSelf->__Vdly__NpcSimTop__DOT__uart_rx_valid_q 
        = vlSelf->NpcSimTop__DOT__uart_rx_valid_q;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_pred_taken_redirect_w) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__can_issue_request_w)))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2438: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [B2S2-PRED-BLOCK] pred-taken \346\224\271\346\265\201\346\213\215\351\241\272\345\272\217\345\217\226\346\214\207\350\207\202\346\234\252\350\242\253\345\205\263\346\226\255(can_issue \346\263\204\346\274\217) @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2438, "");
        }
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_req_fire_w)) 
                     & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_cache_read_window_w))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketCache.v:223: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_fetch_bridge.u_fetch_packet_cache: [FPC-ACCEPT-REQUIRES-READ] semantic lookup accept without physical SRAM read: lookup_pc=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_pc_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooFetchPacketCache.v", 223, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w)) 
                     & (((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_system_capture_irq_w) 
                           | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_system_capture_head0_w)) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_dispatch_arbiter__DOT__lane1_system_capture_w)) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_exit_capture_exit_w)) 
                        | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_exit_capture_arch_valid_w))))) {
        VL_WRITEF("[%0t] %%Error: OooControlPlane.v:1014: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane: [T3Y-DIRECT-CAPTURE-DISJOINT] direct flush collided with pending capture: irq=%b h0=%b l1=%b exit=%b arch=%b\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_system_capture_irq_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_system_capture_head0_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_dispatch_arbiter__DOT__lane1_system_capture_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_exit_capture_exit_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_exit_capture_arch_valid_w));
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 1014, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__tail_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__tail_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__vaddr_q__v11 = 0U;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (0x63U 
                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_dispatch_decode__DOT__u_decode__DOT__opcode_w))) 
                     & ((((((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec0_next_pc_w 
                             >> 0xcU) + (QData)((IData)(
                                                        (1U 
                                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_branch_target__DOT__low_sum_w) 
                                                            >> 0xcU))))) 
                           - (QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_branch_target__DOT____VdfgTmp_h214288c1__0))) 
                          << 0xcU) | (QData)((IData)(
                                                     (0xfffU 
                                                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_branch_target__DOT__low_sum_w))))) 
                        != (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec0_next_pc_w 
                            + (((- (QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_branch_target__DOT____VdfgTmp_h214288c1__0))) 
                                << 0xdU) | (QData)((IData)(
                                                           ((0x63U 
                                                             == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec1_dispatch_decode__DOT__u_decode__DOT__opcode_w))
                                                             ? 
                                                            (((IData)(vlSelf->__VdfgTmp_hddebeb43__0) 
                                                              << 0xcU) 
                                                             | (IData)(vlSelf->__VdfgTmp_ha9dc50f1__0))
                                                             : 0U))))))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchBranchTarget.v:29: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec1_branch_target: [FETCH-BRANCH-TARGET-EQUIV] split target differs from RV64 reference\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchBranchTarget.v", 29, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__u_itlb__DOT__vpn_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__fault_tval_q__v11 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__ghr_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__ghr_q;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (0x63U 
                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_dispatch_decode__DOT__u_decode__DOT__opcode_w))) 
                     & ((((((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__pc_q 
                             >> 0xcU) + (QData)((IData)(
                                                        (1U 
                                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_branch_target__DOT__low_sum_w) 
                                                            >> 0xcU))))) 
                           - (QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_branch_target__DOT____VdfgTmp_h214288c1__0))) 
                          << 0xcU) | (QData)((IData)(
                                                     (0xfffU 
                                                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_branch_target__DOT__low_sum_w))))) 
                        != (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__pc_q 
                            + (((- (QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_branch_target__DOT____VdfgTmp_h214288c1__0))) 
                                << 0xdU) | (QData)((IData)(
                                                           ((0x63U 
                                                             == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_dec0_dispatch_decode__DOT__u_decode__DOT__opcode_w))
                                                             ? 
                                                            (((IData)(vlSelf->__VdfgTmp_h30edc1cc__0) 
                                                              << 0xcU) 
                                                             | (IData)(vlSelf->__VdfgTmp_hdd83ced3__0))
                                                             : 0U))))))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchBranchTarget.v:29: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_dec0_branch_target: [FETCH-BRANCH-TARGET-EQUIV] split target differs from RV64 reference\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchBranchTarget.v", 29, "");
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__direct_jal_fire_w) 
                          | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_ret0_fire_w) 
                             | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_ret1_fire_w) 
                                | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__direct_jump_spec_fire_w)))) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2402: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [FLUSH-CONTRACT GAP-3] mux direct_redirect_fetch \347\275\256\344\275\215\350\200\214 FE direct_frontend_flush \346\234\252\347\275\256\344\275\215: fetch_req \350\242\253 mux \351\207\215\345\256\232\345\220\221\344\275\206 sequencer \346\234\252 latch next_fetch/\346\234\252 reset outstanding -> \344\270\244\350\220\275\347\202\271\345\210\206\345\217\211 @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2402, "");
        }
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__u_itlb__DOT__pte_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_arch_fpr__DOT__fpr_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_arch_fpr__DOT__fpr_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_arch_fpr__DOT__fpr_q__v33 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__u_itlb__DOT__level_q__v0 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[1U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[1U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[2U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[2U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[3U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[3U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[4U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[4U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[5U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[5U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[6U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[6U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[7U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[7U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[8U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[8U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[9U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[9U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xaU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xaU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xbU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xbU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xcU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xcU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xdU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xdU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xeU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xeU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xfU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0xfU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x10U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x10U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x11U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x11U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x12U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x12U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x13U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x13U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x14U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x14U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x15U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x15U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x16U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x16U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x17U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x17U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x18U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x18U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x19U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x19U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1aU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1aU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1bU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1bU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1cU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1cU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1dU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1dU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1eU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1eU];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1fU] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__bht_valid_q[0x1fU];
    VL_ASSIGN_W(4096,vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__local_pht_valid_q, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__local_pht_valid_q);
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_branch_direction_predictor__DOT__local_hist_q__v0 = 0U;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__iq_issue_valid_w)) 
                     & (((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_en_q
                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r] 
                          & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q
                             [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r])) 
                         | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_en_q
                            [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r] 
                            & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q
                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r]))) 
                        | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_en_q
                           [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r] 
                           & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q
                              [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r])))))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:392: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [FP-IQ-FP-STICKY-ONLY] FP source issued before sticky ready\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 392, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__iq_issue_valid_w)) 
                      & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_en_q
                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r]) 
                     & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q
                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r])))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:397: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [FP-IQ-INT-STICKY-ONLY] GPR source issued before sticky ready\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 397, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb0_write_valid_w)) 
                     & (0U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__wb0_pdest_w))))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:401: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [FP-INT-WAKE-WRITE] lane0 formal wake targets p0\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 401, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb1_write_valid_w)) 
                     & (0U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__wb1_pdest_w))))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:405: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [FP-INT-WAKE-WRITE] lane1 formal wake targets p0\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 405, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__iq_issue_valid_w)) 
                     & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                         [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r]) 
                        != (0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                            [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__issue_idx_r]))))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:409: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [V8I-FP-IQ-PID-PROJECTION] issue raw index diverged from PID\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 409, "");
        VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:410: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 410, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dispatch_fire_w)) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dispatch1_fire_w)) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_dispatch0_producer_id_w) 
                        == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_dispatch1_producer_id_w))))) {
        VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:414: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue: [V8I-FP-IQ-DUAL-PID] dual dispatch accepted one PID twice\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 414, "");
        VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:415: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 415, "");
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [0U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [0U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [0U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [1U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [1U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [1U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [2U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [2U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [2U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [3U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [3U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [3U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [4U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [4U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [4U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [5U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [5U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [5U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [6U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [6U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [6U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:433: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8I-FP-IQ-PID-UNIQUE] duplicate resident PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 433, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:434: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 434, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q
                         [7U] & (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_live_mask_r[
                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [7U] >> 5U)] >> 
                                    (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q
                                     [7U])))))) {
            VL_WRITEF("[%0t] %%Error: OooFpIssueQueue.v:427: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk: [V8L-FP-IQ-LEASE-KNOWN] resident PID is unknown or missing from live mask\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 427, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpIssueQueue.v:428: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_issue_queue.fp_iq_pid_unique_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v", 428, "");
        }
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__arith_out_valid_w) 
                         & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                             [4U]) != (0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                       [4U]))))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1537: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-PROJECTION] output raw index diverged from PID\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1537, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1538: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1538, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [1U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [1U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [2U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [2U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [3U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_arith__DOT__meta_producer_id_q
                                   [4U])))) {
            VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1549: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk: [V8I-FP-ARITH-PID-UNIQUE] duplicate PID in metadata pipeline\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1549, "");
            VL_WRITEF("[%0t] %%Fatal: OooFpArithGate.v:1550: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith.fp_arith_pid_assert_blk\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1550, "");
        }
    }
    if (((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_valid_w)) 
          & (0U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_w))) 
         & (0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp1_w)))) {
        if (VL_UNLIKELY((((2U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                          & (3U != (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__dec0_range_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2449: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B2-C0] B=2 compressed slot0 consumed second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2449, "");
        }
        if (VL_UNLIKELY((((2U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                          & (3U != (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp1_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2453: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B2-C1] B=2 slot1 did not consume second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2453, "");
        }
        if (VL_UNLIKELY((((2U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                          & (3U == (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__dec0_range_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp1_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2457: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B2-U0] B=2 32-bit slot0 did not consume second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2457, "");
        }
        if (VL_UNLIKELY(((IData)((((6U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                                   & (0x30000U == (0x30000U 
                                                   & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                                  & (3U != (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w)))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2462: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B6-CU] B=6 C+32 slot1 was falsely assigned second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2462, "");
        }
        if (VL_UNLIKELY(((((6U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                           & (3U == (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                          & (3U != (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst1_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2467: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B6-UC] B=6 32+C slot1 was falsely assigned second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2467, "");
        }
        if (VL_UNLIKELY(((((6U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp0_bytes_w)) 
                           & (3U == (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))) 
                          & (3U == (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst1_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_resp_w) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_resp1_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2472: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-FETCH-G2-B6-UU] B=6 32+32 slot1 did not consume second-segment fault\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2472, "");
        }
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q__v16 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q__v17 = 0U;
    if (VL_UNLIKELY((((((((~ (IData)(vlSelf->rst)) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_access_valid_w)) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_probe_valid_w)) 
                        & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__csr_access_inst_w 
                            >> 0x14U) == (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_csr_access_request_mux__DOT__csr_probe_inst_w 
                                          >> 0x14U))) 
                       & ((7U & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__csr_access_inst_w 
                                 >> 0xcU)) == (7U & 
                                               (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_csr_access_request_mux__DOT__csr_probe_inst_w 
                                                >> 0xcU)))) 
                      & ((0x1fU & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__csr_access_inst_w 
                                   >> 0xfU)) == (0x1fU 
                                                 & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_csr_access_request_mux__DOT__csr_probe_inst_w 
                                                    >> 0xfU)))) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_csr_file__DOT__csr_access_illegal_w) 
                        != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_csr_file__DOT__csr_probe_illegal_w))))) {
        VL_WRITEF("[%0t] %%Error: CsrFile.v:681: Assertion failed in %NNpcSimTop.u_top.u_core.u_csr_file: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v", 681, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_ras_stack__DOT__count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_ras_stack__DOT__count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__count_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__mmu_epoch_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_kind_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__owner_token_q__v11 = 0U;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__branch_resolve_untracked_w)))) {
        VL_WRITEF("[%0t] %%Error: OooControlPlane.v:971: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane: [FLUSH-CONTRACT INV-3] CSR-commit \344\270\216 younger-branch-mispredict \345\220\214\346\213\215(GAP-2 \344\272\222\346\226\245\350\242\253\350\277\235\345\217\215): spec_restore=0 untracked=%b pend_resolve=0 pend_clear=0\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__branch_resolve_untracked_w));
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 971, "");
        VL_WRITEF("[%0t] %%Fatal: OooControlPlane.v:975: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 975, "");
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__b2s2_pred_redirect_pending_q) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_req_fire_w)) 
                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_pc_w 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__b2s2_pred_target_q)))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2429: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [B2S2-PRED-REDIRECT] pred-taken \346\224\271\346\265\201\345\220\216\351\246\226\344\270\252\351\241\272\345\272\217\345\217\226\346\214\207\350\257\267\346\261\202 pc=%x != \351\242\204\346\265\213 target=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_pc_w,
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__b2s2_pred_target_q,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2429, "");
        }
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i) 
                            | ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)) 
                               & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____Vcellinp__u_fetch_pc_outstanding__drain_complete_i) 
                                  & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)))))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2351: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3Y-DIRECT-COMMIT-DISJOINT] direct flush collided with E5/E6 owner: e5=%0# e6=%0# stop=%0# busy=%0# run=%0# @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i),
                      1,((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____Vcellinp__u_fetch_pc_outstanding__drain_complete_i) 
                            & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                               | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)))),
                      1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q),
                      1,((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__orphan_stop_pending_w)) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q)),
                      1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2351, "");
        }
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((4U < (7U & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q) 
                                     + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__outstanding_valid_q)))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2361: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3U-FETCH-CREDIT] fifo=%0# outstanding=%0# exceeds depth=4 @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),3,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q),
                      3,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__outstanding_valid_q,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2361, "");
        }
    }
    if (((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_req_fire_w) 
                                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__outstanding_valid_q)))) {
        if (VL_UNLIKELY((1U & (((((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_valid_w)) 
                                  | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_rsp_fire_w))) 
                                 | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__fetch_rsp_enqueue_w))) 
                                | (0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__dec0_range_resp_w))) 
                               | (0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_resp_w)))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2480: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-R2P3-RAW-TOKEN] raw successor fired without a successful response owner\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2480, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__pc_q 
                          + (QData)((IData)(((3U != 
                                              (3U & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))
                                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__raw_dec1_compressed_w)
                                                  ? 4U
                                                  : 6U)
                                              : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__raw_dec1_compressed_w)
                                                  ? 6U
                                                  : 8U))))) 
                         != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_next_pc_w))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2482: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-R2P3-RAW-EQ] consumed raw successor differs from semantic successor\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2482, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_pc_w 
                         != (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__pc_q 
                             + (QData)((IData)(((3U 
                                                 != 
                                                 (3U 
                                                  & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_rsp_inst0_w))
                                                 ? 
                                                ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__raw_dec1_compressed_w)
                                                  ? 4U
                                                  : 6U)
                                                 : 
                                                ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_decode__DOT__raw_dec1_compressed_w)
                                                  ? 6U
                                                  : 8U)))))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2484: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [IFU-R2P3-RAW-PC] normal turnover did not select the raw successor payload\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2484, "");
        }
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_pending_system_csr_commit_w) 
                                                  | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w) 
                                                     | ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)) 
                                                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q) 
                                                           & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__drain_complete_w) 
                                                              & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                                                                 | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__valid_q)))))))) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__branch_resolve_untracked_w)))) {
        VL_WRITEF("[%0t] %%Error: OooControlPlane.v:997: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane: [FLUSH-CONTRACT INV-3b] commit \345\256\266\346\227\217(E5/E6) redirect \344\270\216 younger-branch untracked mispredict \345\220\214\346\213\215(GAP-2 \344\272\222\346\226\245\350\242\253\350\277\235\345\217\215): e5=%b e6=%b untracked=%b\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_pending_system_csr_commit_w) 
                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)),
                  1,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__drain_complete_w)),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__branch_resolve_untracked_w));
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 997, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__discard_fetch_rsp_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__discard_fetch_rsp_q;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_system_capture_head0_w)) 
                     & (~ ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)) 
                           & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w)) 
                              & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w) 
                                 & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q) 
                                    & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_irq_pending_w)) 
                                       & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__head_fetch_fault0_w)) 
                                          & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_arch_trap_w)) 
                                             & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_dispatch_arbiter__DOT__dispatch0_exit_w)) 
                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_system_w))))))))))))) {
        VL_WRITEF("[%0t] %%Error: OooControlPlane.v:1042: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane: [FLUSH-CONTRACT INV-7] arbiter \346\216\210\344\272\210 head0-system \351\230\237\345\244\264\346\211\200\346\234\211\346\235\203 \344\275\206 sequencer \346\234\252 arm stop_pending SET \345\211\215\344\273\266(GAP-7 SET \350\260\223\350\257\215\344\270\244\345\244\204\351\225\234\345\203\217\346\274\202\347\247\273): capture_head0=1 seq_set=%b [csr_trap=%b dflush=%b can_run=%b fifo=%b irq=%b fault0=%b arch=%b exit=%b sys=%b]\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)) 
                     & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w)) 
                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w) 
                           & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q) 
                              & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_irq_pending_w)) 
                                 & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__head_fetch_fault0_w)) 
                                    & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_arch_trap_w)) 
                                       & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_dispatch_arbiter__DOT__dispatch0_exit_w)) 
                                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_system_w))))))))),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_irq_pending_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__head_fetch_fault0_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_arch_trap_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_dispatch_arbiter__DOT__dispatch0_exit_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_system_w));
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 1042, "");
        VL_WRITEF("[%0t] %%Fatal: OooControlPlane.v:1047: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 1047, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__tail_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__tail_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q__v4 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_ras_stack__DOT__stack_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_ras_stack__DOT__stack_q__v32 = 0U;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__dispatch0_arch_trap_w) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__frontend_dispatch_to_backend_valid_w)))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2370: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [FDG-CONTRACT FDG-I1] head0 arch trap \345\220\214\346\213\215\344\273\215\345\221\210\347\216\260 backend: pc=%x inst=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,(((QData)((IData)(
                                                           vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x16U])) 
                                           << 0x33U) 
                                          | (((QData)((IData)(
                                                              vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x15U])) 
                                              << 0x13U) 
                                             | ((QData)((IData)(
                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x14U])) 
                                                >> 0xdU))),
                      32,((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                           << 0x13U) | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                        >> 0xdU)),64,
                      VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2370, "");
        }
    }
    if (((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q))) {
        if (VL_UNLIKELY(((0x3ffffU & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U] 
                                       << 0xbU) | (
                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[4U] 
                                                   >> 0x15U))) 
                         != (((0x40705013U == ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                << 0x13U) 
                                               | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                  >> 0xdU))) 
                              << 0x11U) | (((IData)(
                                                    ((0xe000000U 
                                                      == 
                                                      (0xe000000U 
                                                       & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                     & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                         & ((0U 
                                                             == 
                                                             (0x7fU 
                                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                 >> 6U))) 
                                                            | ((1U 
                                                                == 
                                                                (0x7fU 
                                                                 & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                    >> 6U))) 
                                                               | ((4U 
                                                                   == 
                                                                   (0x7fU 
                                                                    & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                       >> 6U))) 
                                                                  | (5U 
                                                                     == 
                                                                     (0x7fU 
                                                                      & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                         >> 6U))))))) 
                                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                            & ((8U 
                                                                == 
                                                                (0x7fU 
                                                                 & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                    >> 6U))) 
                                                               | (9U 
                                                                  == 
                                                                  (0x7fU 
                                                                   & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                      >> 6U))))) 
                                                           | ((((0x43U 
                                                                 == 
                                                                 (0x7fU 
                                                                  & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                     >> 0xdU))) 
                                                                | ((0x47U 
                                                                    == 
                                                                    (0x7fU 
                                                                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                        >> 0xdU))) 
                                                                   | ((0x4bU 
                                                                       == 
                                                                       (0x7fU 
                                                                        & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                           >> 0xdU))) 
                                                                      | (0x4fU 
                                                                         == 
                                                                         (0x7fU 
                                                                          & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                             >> 0xdU)))))) 
                                                               & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w) 
                                                                  & ((0U 
                                                                      == 
                                                                      (3U 
                                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                          >> 6U))) 
                                                                     | (1U 
                                                                        == 
                                                                        (3U 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                            >> 6U)))))) 
                                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                  & ((0xcU 
                                                                      == 
                                                                      (0x7fU 
                                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                          >> 6U))) 
                                                                     | (0xdU 
                                                                        == 
                                                                        (0x7fU 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                            >> 6U))))) 
                                                                 | ((IData)(
                                                                            ((((0xa6000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                               & (0U 
                                                                                == 
                                                                                (0x3eU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU]))) 
                                                                              & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w)) 
                                                                             & ((0x2cU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | (0x2dU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U)))))) 
                                                                    | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                        & ((IData)(
                                                                                ((0U 
                                                                                == 
                                                                                (0x38U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU])) 
                                                                                & ((0x68U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | (0x69U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U)))))) 
                                                                           | ((IData)(
                                                                                (0x802U 
                                                                                == 
                                                                                (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU]))) 
                                                                              | (IData)(
                                                                                (0x840U 
                                                                                == 
                                                                                (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU])))))) 
                                                                       | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__fp_convert_to_gpr_w))))))))) 
                                            << 0x10U) 
                                           | ((((IData)(
                                                        (0x600e000U 
                                                         == 
                                                         (0xe0fe000U 
                                                          & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                | ((IData)(
                                                           (0x604e000U 
                                                            == 
                                                            (0xe0fe000U 
                                                             & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                   | (IData)(
                                                             ((0x40U 
                                                               == 
                                                               (0xc0U 
                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU])) 
                                                              & ((0x53U 
                                                                  == 
                                                                  (0x7fU 
                                                                   & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                      >> 0xdU))) 
                                                                 | ((0x43U 
                                                                     == 
                                                                     (0x7fU 
                                                                      & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                         >> 0xdU))) 
                                                                    | ((0x47U 
                                                                        == 
                                                                        (0x7fU 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                            >> 0xdU))) 
                                                                       | ((0x4bU 
                                                                           == 
                                                                           (0x7fU 
                                                                            & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                               >> 0xdU))) 
                                                                          | (0x4fU 
                                                                             == 
                                                                             (0x7fU 
                                                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 0xdU))))))))))) 
                                               << 0xfU) 
                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__fp_convert_to_gpr_w) 
                                                  << 0xeU) 
                                                 | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                      & ((IData)(
                                                                 ((0U 
                                                                   == 
                                                                   (0x38U 
                                                                    & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU])) 
                                                                  & ((0x68U 
                                                                      == 
                                                                      (0x7fU 
                                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                          >> 6U))) 
                                                                     | (0x69U 
                                                                        == 
                                                                        (0x7fU 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                            >> 6U)))))) 
                                                         | ((IData)(
                                                                    (0x802U 
                                                                     == 
                                                                     (0x1ffeU 
                                                                      & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU]))) 
                                                            | (IData)(
                                                                      (0x840U 
                                                                       == 
                                                                       (0x1ffeU 
                                                                        & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU])))))) 
                                                     << 0xdU) 
                                                    | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__fp_compare_w) 
                                                        << 0xcU) 
                                                       | (((IData)(
                                                                   (((0xa6000U 
                                                                      == 
                                                                      (0xfe000U 
                                                                       & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hae7a3c7d__0)) 
                                                                    & ((0x14U 
                                                                        == 
                                                                        (0x7fU 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                            >> 6U))) 
                                                                       | (0x15U 
                                                                          == 
                                                                          (0x7fU 
                                                                           & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                              >> 6U)))))) 
                                                           << 0xbU) 
                                                          | (((IData)(
                                                                      ((((0xa6000U 
                                                                          == 
                                                                          (0xfe000U 
                                                                           & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                         & (0U 
                                                                            == 
                                                                            (0x3eU 
                                                                             & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU]))) 
                                                                        & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w)) 
                                                                       & ((0x2cU 
                                                                           == 
                                                                           (0x7fU 
                                                                            & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                               >> 6U))) 
                                                                          | (0x2dU 
                                                                             == 
                                                                             (0x7fU 
                                                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U)))))) 
                                                              << 0xaU) 
                                                             | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                  & ((0xcU 
                                                                      == 
                                                                      (0x7fU 
                                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                          >> 6U))) 
                                                                     | (0xdU 
                                                                        == 
                                                                        (0x7fU 
                                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                            >> 6U))))) 
                                                                 << 9U) 
                                                                | (((((0x43U 
                                                                       == 
                                                                       (0x7fU 
                                                                        & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                           >> 0xdU))) 
                                                                      | ((0x47U 
                                                                          == 
                                                                          (0x7fU 
                                                                           & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                              >> 0xdU))) 
                                                                         | ((0x4bU 
                                                                             == 
                                                                             (0x7fU 
                                                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 0xdU))) 
                                                                            | (0x4fU 
                                                                               == 
                                                                               (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 0xdU)))))) 
                                                                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w) 
                                                                        & ((0U 
                                                                            == 
                                                                            (3U 
                                                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                           | (1U 
                                                                              == 
                                                                              (3U 
                                                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U)))))) 
                                                                    << 8U) 
                                                                   | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                        & ((8U 
                                                                            == 
                                                                            (0x7fU 
                                                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                           | (9U 
                                                                              == 
                                                                              (0x7fU 
                                                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))))) 
                                                                       << 7U) 
                                                                      | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                           & ((0U 
                                                                               == 
                                                                               (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                              | ((1U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | ((4U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | (5U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))))))) 
                                                                          << 6U) 
                                                                         | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_ha868e187__0) 
                                                                              & ((0x10U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | (0x11U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))))) 
                                                                             << 5U) 
                                                                            | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__fp_class_w) 
                                                                                << 4U) 
                                                                               | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__fp_move_to_gpr_w) 
                                                                                << 3U) 
                                                                                | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hc9ea9278__0) 
                                                                                & ((0x78U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))) 
                                                                                | (0x79U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                                                >> 6U))))) 
                                                                                << 2U) 
                                                                                | (((IData)(
                                                                                ((0x4e000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hf2362ed8__0))) 
                                                                                << 1U) 
                                                                                | (IData)(
                                                                                ((0xe000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head0_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hf2362ed8__0))))))))))))))))))))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2294: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3W-STATIC-FACTS-COHERENCE] lane0 stored facts mismatch instruction @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2294, "");
        }
        if (VL_UNLIKELY(((0x3ffffU & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[4U] 
                                      >> 3U)) != ((
                                                   (0x1f01013U 
                                                    == 
                                                    ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                      << 0x13U) 
                                                     | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                        >> 0xdU))) 
                                                   << 0x11U) 
                                                  | (((IData)(
                                                              ((0xe000000U 
                                                                == 
                                                                (0xe000000U 
                                                                 & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                               & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                   & ((0U 
                                                                       == 
                                                                       (0x7fU 
                                                                        & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                           >> 6U))) 
                                                                      | ((1U 
                                                                          == 
                                                                          (0x7fU 
                                                                           & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                              >> 6U))) 
                                                                         | ((4U 
                                                                             == 
                                                                             (0x7fU 
                                                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                            | (5U 
                                                                               == 
                                                                               (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))))) 
                                                                  | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                      & ((8U 
                                                                          == 
                                                                          (0x7fU 
                                                                           & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                              >> 6U))) 
                                                                         | (9U 
                                                                            == 
                                                                            (0x7fU 
                                                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                     | ((((0x43U 
                                                                           == 
                                                                           (0x7fU 
                                                                            & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                               >> 0xdU))) 
                                                                          | ((0x47U 
                                                                              == 
                                                                              (0x7fU 
                                                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                             | ((0x4bU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | (0x4fU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU)))))) 
                                                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w) 
                                                                            & ((0U 
                                                                                == 
                                                                                (3U 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                               | (1U 
                                                                                == 
                                                                                (3U 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                            & ((0xcU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                               | (0xdU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                           | ((IData)(
                                                                                ((((0xa6000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                                & (0U 
                                                                                == 
                                                                                (0x3eU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w)) 
                                                                                & ((0x2cU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x2dU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                                & ((IData)(
                                                                                ((0U 
                                                                                == 
                                                                                (0x38U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                                & ((0x68U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x69U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                                | ((IData)(
                                                                                (0x802U 
                                                                                == 
                                                                                (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                                                | (IData)(
                                                                                (0x840U 
                                                                                == 
                                                                                (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])))))) 
                                                                                | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__fp_convert_to_gpr_w))))))))) 
                                                      << 0x10U) 
                                                     | ((((IData)(
                                                                  (0x600e000U 
                                                                   == 
                                                                   (0xe0fe000U 
                                                                    & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U]))) 
                                                          | ((IData)(
                                                                     (0x604e000U 
                                                                      == 
                                                                      (0xe0fe000U 
                                                                       & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U]))) 
                                                             | (IData)(
                                                                       ((0x40U 
                                                                         == 
                                                                         (0xc0U 
                                                                          & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                        & ((0x53U 
                                                                            == 
                                                                            (0x7fU 
                                                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                           | ((0x43U 
                                                                               == 
                                                                               (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                              | ((0x47U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | ((0x4bU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | (0x4fU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))))))))))) 
                                                         << 0xfU) 
                                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__fp_convert_to_gpr_w) 
                                                            << 0xeU) 
                                                           | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                & ((IData)(
                                                                           ((0U 
                                                                             == 
                                                                             (0x38U 
                                                                              & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])) 
                                                                            & ((0x68U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                               | (0x69U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                   | ((IData)(
                                                                              (0x802U 
                                                                               == 
                                                                               (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                                      | (IData)(
                                                                                (0x840U 
                                                                                == 
                                                                                (0x1ffeU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U])))))) 
                                                               << 0xdU) 
                                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__fp_compare_w) 
                                                                  << 0xcU) 
                                                                 | (((IData)(
                                                                             (((0xa6000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                               & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hae7a3c7d__0)) 
                                                                              & ((0x14U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x15U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                     << 0xbU) 
                                                                    | (((IData)(
                                                                                ((((0xa6000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                                & (0U 
                                                                                == 
                                                                                (0x3eU 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U]))) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w)) 
                                                                                & ((0x2cU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x2dU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                        << 0xaU) 
                                                                       | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                            & ((0xcU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                               | (0xdU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                           << 9U) 
                                                                          | (((((0x43U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | ((0x47U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | ((0x4bU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU))) 
                                                                                | (0x4fU 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                                                >> 0xdU)))))) 
                                                                               & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT__fp_rounding_arith_w) 
                                                                                & ((0U 
                                                                                == 
                                                                                (3U 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (1U 
                                                                                == 
                                                                                (3U 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U)))))) 
                                                                              << 8U) 
                                                                             | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                                & ((8U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (9U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                                << 7U) 
                                                                                | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_h27d8fb5b__0) 
                                                                                & ((0U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | ((1U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | ((4U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (5U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))))) 
                                                                                << 6U) 
                                                                                | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_ha868e187__0) 
                                                                                & ((0x10U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x11U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                                << 5U) 
                                                                                | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__fp_class_w) 
                                                                                << 4U) 
                                                                                | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__fp_move_to_gpr_w) 
                                                                                << 3U) 
                                                                                | ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hc9ea9278__0) 
                                                                                & ((0x78U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))) 
                                                                                | (0x79U 
                                                                                == 
                                                                                (0x7fU 
                                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                                                >> 6U))))) 
                                                                                << 2U) 
                                                                                | (((IData)(
                                                                                ((0x4e000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hf2362ed8__0))) 
                                                                                << 1U) 
                                                                                | (IData)(
                                                                                ((0xe000U 
                                                                                == 
                                                                                (0xfe000U 
                                                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_t3w_head1_static_reference__DOT__u_fp_decode__DOT____VdfgTmp_hf2362ed8__0))))))))))))))))))))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2297: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3W-STATIC-FACTS-COHERENCE] lane1 stored facts mismatch instruction @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2297, "");
        }
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_clear_w))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__fetch_rsp_enqueue_w)) 
                     & (((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec0_imm_w 
                                  >> 0x20U)) != (- (IData)(
                                                           (1U 
                                                            & (IData)(
                                                                      (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec0_imm_w 
                                                                       >> 0x1fU)))))) 
                        | ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_imm_w 
                                    >> 0x20U)) != (- (IData)(
                                                             (1U 
                                                              & (IData)(
                                                                        (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fetch_dec1_imm_w 
                                                                         >> 0x1fU)))))))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:395: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [IFU-R2P4-IMM-CANONICAL] enqueue immediate is not an RV64 sign extension\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 395, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:396: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 396, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (4U 
                                                 < (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:399: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [CONTRACT-FIFO-OVFL] OooFetchPacketFifo count_q=%0# exceeds depth=4\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  3,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q));
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 399, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:401: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 401, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_clear_w))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_pop_w)) 
                     & (0U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:404: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [CONTRACT-FIFO-UNDERFLOW] OooFetchPacketFifo pop while empty\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 404, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:405: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 405, "");
    }
    if (VL_UNLIKELY((((((~ (IData)(vlSelf->rst)) & 
                        (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_clear_w))) 
                       & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__fetch_rsp_enqueue_w)) 
                      & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_pop_w))) 
                     & (4U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:409: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [CONTRACT-FIFO-OVFL-REQUEST] OooFetchPacketFifo enqueue while full\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 409, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:410: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 410, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q) 
                                                 != 
                                                 (0U 
                                                  != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q)))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:413: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [T4B-FIFO-HEAD-PRESENCE] registered presence differs from occupancy\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 413, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:414: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 414, "");
    }
    __Vtemp_10[1U] = (((IData)((((QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_1_q
                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                 << 0x32U) | (((QData)((IData)(
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_1_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                               << 0x2dU) 
                                              | (((QData)((IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd1_q
                                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                  << 0x28U) 
                                                 | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm1_q
                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                     << 4U) 
                                                    | (QData)((IData)(
                                                                      ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp0_q
                                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                        << 2U) 
                                                                       | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp1_q
                                                                       [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])))))))) 
                       >> 0x14U) | ((IData)(((((QData)((IData)(
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_1_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                               << 0x32U) 
                                              | (((QData)((IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_1_q
                                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                  << 0x2dU) 
                                                 | (((QData)((IData)(
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd1_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                     << 0x28U) 
                                                    | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm1_q
                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                        << 4U) 
                                                       | (QData)((IData)(
                                                                         ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp0_q
                                                                           [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                           << 2U) 
                                                                          | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp1_q
                                                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]))))))) 
                                             >> 0x20U)) 
                                    << 0xcU));
    __Vtemp_10[2U] = (((0xff8U & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm0_q
                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                  << 3U)) | ((IData)(
                                                     ((((QData)((IData)(
                                                                        vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_1_q
                                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                        << 0x32U) 
                                                       | (((QData)((IData)(
                                                                           vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_1_q
                                                                           [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                           << 0x2dU) 
                                                          | (((QData)((IData)(
                                                                              vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd1_q
                                                                              [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                              << 0x28U) 
                                                             | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm1_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                 << 4U) 
                                                                | (QData)((IData)(
                                                                                ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp0_q
                                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                                << 2U) 
                                                                                | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp1_q
                                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]))))))) 
                                                      >> 0x20U)) 
                                             >> 0x14U)) 
                      | (0xfffff000U & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm0_q
                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                        << 3U)));
    __Vtemp_18[0U] = ((((IData)((((QData)((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_1_q
                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                  << 0x32U) | (((QData)((IData)(
                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_1_q
                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                << 0x2dU) 
                                               | (((QData)((IData)(
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd1_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                   << 0x28U) 
                                                  | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm1_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                      << 4U) 
                                                     | (QData)((IData)(
                                                                       ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp0_q
                                                                         [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                         << 2U) 
                                                                        | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp1_q
                                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])))))))) 
                        << 0x19U) | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pred_taken0_q
                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                      << 0x18U) | (
                                                   (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pred_taken1_q
                                                    [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                    << 0x17U) 
                                                   | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__bht_idx0_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                      << 0xdU)))) 
                      | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__bht_idx1_q
                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                          << 3U) | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__bht_valid0_q
                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                     << 2U) | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__bht_valid1_q
                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                << 1U) 
                                               | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__slot1_valid_q
                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]))));
    __Vtemp_18[1U] = (((0x1fffU & ((IData)((((QData)((IData)(
                                                             vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_1_q
                                                             [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                             << 0x32U) 
                                            | (((QData)((IData)(
                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_1_q
                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                << 0x2dU) 
                                               | (((QData)((IData)(
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd1_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])) 
                                                   << 0x28U) 
                                                  | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm1_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                      << 4U) 
                                                     | (QData)((IData)(
                                                                       ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp0_q
                                                                         [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                         << 2U) 
                                                                        | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__resp1_q
                                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q])))))))) 
                                   >> 7U)) | ((0x1fffU 
                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pred_taken0_q
                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                  >> 8U)) 
                                              | ((0x1fffU 
                                                  & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pred_taken1_q
                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                     >> 9U)) 
                                                 | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__bht_idx0_q
                                                    [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                    >> 0x13U)))) 
                      | (__Vtemp_10[1U] << 0xdU));
    __Vtemp_18[4U] = (((0x1ff8U & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__static_facts1_q
                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                   << 3U)) | (0x1fffU 
                                              & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_0_q
                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                  >> 2U) 
                                                 | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_0_q
                                                    [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                    >> 7U)))) 
                      | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__static_facts0_q
                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                          << 0x15U) | (0xffffe000U 
                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__static_facts1_q
                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                          << 3U))));
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (0U 
                                                  != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__count_q))) 
                     & (0U != (((((((((((((((((((((
                                                   ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0U] 
                                                     ^ 
                                                     __Vtemp_18[0U]) 
                                                    | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[1U] 
                                                       ^ 
                                                       __Vtemp_18[1U])) 
                                                   | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[2U] 
                                                      ^ 
                                                      ((__Vtemp_10[1U] 
                                                        >> 0x13U) 
                                                       | (__Vtemp_10[2U] 
                                                          << 0xdU)))) 
                                                  | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[3U] 
                                                     ^ 
                                                     ((__Vtemp_10[2U] 
                                                       >> 0x13U) 
                                                      | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs1_0_q
                                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                          << 0x1eU) 
                                                         | ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rs2_0_q
                                                             [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                             << 0x19U) 
                                                            | ((0x1f00000U 
                                                                & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__rd0_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                   << 0x14U)) 
                                                               | ((0xe000U 
                                                                   & ((IData)(
                                                                              vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm0_q
                                                                              [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                                      >> 0x10U)) 
                                                                  | (0x1ff0000U 
                                                                     & ((IData)(
                                                                                (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__imm0_q
                                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                                >> 0x20U)) 
                                                                        << 0x10U))))))))) 
                                                 | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[4U] 
                                                    ^ 
                                                    __Vtemp_18[4U])) 
                                                | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U] 
                                                   ^ 
                                                   (((0x1f80U 
                                                      & ((IData)(
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                         << 7U)) 
                                                     | ((0x1fffU 
                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__static_facts0_q
                                                            [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                            >> 0xbU)) 
                                                        | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__static_facts1_q
                                                           [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                           >> 0x1dU))) 
                                                    | (0xffffe000U 
                                                       & ((IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                          << 7U))))) 
                                               | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U] 
                                                  ^ 
                                                  ((((IData)(
                                                             vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                             [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                     >> 0x19U) 
                                                    | (0x1f80U 
                                                       & ((IData)(
                                                                  (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                   >> 0x20U)) 
                                                          << 7U))) 
                                                   | (((IData)(
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl0_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                       << 0x1aU) 
                                                      | (0xffffe000U 
                                                         & ((IData)(
                                                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                     >> 0x20U)) 
                                                            << 7U)))))) 
                                              | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[7U] 
                                                 ^ 
                                                 (((0x1fffU 
                                                    & ((IData)(
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl0_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                       >> 6U)) 
                                                   | ((IData)(
                                                              (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl1_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                               >> 0x20U)) 
                                                      >> 0x19U)) 
                                                  | ((0x3ffe000U 
                                                      & ((IData)(
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl0_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                         >> 6U)) 
                                                     | ((IData)(
                                                                (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl0_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                 >> 0x20U)) 
                                                        << 0x1aU))))) 
                                             | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                ^ (
                                                   (0x1fffU 
                                                    & ((IData)(
                                                               (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__ctrl0_q
                                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                                >> 0x20U)) 
                                                       >> 6U)) 
                                                   | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__inst1_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                      << 0xdU)))) 
                                            | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                               ^ ((
                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__inst1_q
                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                   >> 0x13U) 
                                                  | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__inst0_q
                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                     << 0xdU)))) 
                                           | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                              ^ ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__inst0_q
                                                  [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                  >> 0x13U) 
                                                 | ((IData)(
                                                            vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__fault_tval_q
                                                            [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                    << 0xdU)))) 
                                          | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xbU] 
                                             ^ (((IData)(
                                                         vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__fault_tval_q
                                                         [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                 >> 0x13U) 
                                                | ((IData)(
                                                           (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__fault_tval_q
                                                            [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                            >> 0x20U)) 
                                                   << 0xdU)))) 
                                         | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xcU] 
                                            ^ (((IData)(
                                                        (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__fault_tval_q
                                                         [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                         >> 0x20U)) 
                                                >> 0x13U) 
                                               | ((IData)(
                                                          vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__packet_next_pc_q
                                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                  << 0xdU)))) 
                                        | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xdU] 
                                           ^ (((IData)(
                                                       vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__packet_next_pc_q
                                                       [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                               >> 0x13U) 
                                              | ((IData)(
                                                         (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__packet_next_pc_q
                                                          [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                          >> 0x20U)) 
                                                 << 0xdU)))) 
                                       | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xeU] 
                                          ^ (((IData)(
                                                      (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__packet_next_pc_q
                                                       [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                       >> 0x20U)) 
                                              >> 0x13U) 
                                             | ((IData)(
                                                        vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc1_q
                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                                << 0xdU)))) 
                                      | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xfU] 
                                         ^ (((IData)(
                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc1_q
                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                             >> 0x13U) 
                                            | ((IData)(
                                                       (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc1_q
                                                        [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                        >> 0x20U)) 
                                               << 0xdU)))) 
                                     | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x10U] 
                                        ^ (((IData)(
                                                    (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc1_q
                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                     >> 0x20U)) 
                                            >> 0x13U) 
                                           | ((IData)(
                                                      vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc0_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                              << 0xdU)))) 
                                    | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x11U] 
                                       ^ (((IData)(
                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc0_q
                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                           >> 0x13U) 
                                          | ((IData)(
                                                     (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc0_q
                                                      [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                      >> 0x20U)) 
                                             << 0xdU)))) 
                                   | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x12U] 
                                      ^ (((IData)((
                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__next_pc0_q
                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                   >> 0x20U)) 
                                          >> 0x13U) 
                                         | ((IData)(
                                                    vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc1_q
                                                    [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                            << 0xdU)))) 
                                  | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x13U] 
                                     ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc1_q
                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                         >> 0x13U) 
                                        | ((IData)(
                                                   (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc1_q
                                                    [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                    >> 0x20U)) 
                                           << 0xdU)))) 
                                 | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x14U] 
                                    ^ (((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc1_q
                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                 >> 0x20U)) 
                                        >> 0x13U) | 
                                       ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q
                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                        << 0xdU)))) 
                                | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x15U] 
                                   ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q
                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q]) 
                                       >> 0x13U) | 
                                      ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q
                                                [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                                >> 0x20U)) 
                                       << 0xdU)))) 
                               | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0x16U] 
                                  ^ ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__pc0_q
                                              [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_q] 
                                              >> 0x20U)) 
                                     >> 0x13U))))))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketFifo.v:448: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo: [T3W-FIFO-HEAD-SHADOW] registered head differs from ring owner\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 448, "");
        VL_WRITEF("[%0t] %%Fatal: OooFetchPacketFifo.v:449: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend.u_fetch_packet_fifo\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchPacketFifo.v", 449, "");
    }
    if (((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_valid_q))) {
        if (VL_UNLIKELY((0U != ((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_head_imm0_w) 
                                    ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_imm_ref_w)) 
                                   | ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_head_imm0_w 
                                               >> 0x20U)) 
                                      ^ (IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_imm_ref_w 
                                                 >> 0x20U)))) 
                                  | ((((IData)((0x7ffffffffffffULL 
                                                & (((QData)((IData)(
                                                                    vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                    << 0x26U) 
                                                   | (((QData)((IData)(
                                                                       vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[7U])) 
                                                       << 6U) 
                                                      | ((QData)((IData)(
                                                                         vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                         >> 0x1aU))))) 
                                       << 0xfU) | (
                                                   (0x7c00U 
                                                    & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[4U] 
                                                        << 0xcU) 
                                                       | (0xc00U 
                                                          & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[3U] 
                                                             >> 0x14U)))) 
                                                   | ((0x3e0U 
                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[3U] 
                                                          >> 0x14U)) 
                                                      | (0x1fU 
                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[3U] 
                                                            >> 0x14U))))) 
                                     ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_ctrl_ref_w) 
                                         << 0xfU) | 
                                        ((0x7c00U & 
                                          ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                            << 0xeU) 
                                           | (0x3c00U 
                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                 >> 0x12U)))) 
                                         | ((0x3e0U 
                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[0xaU] 
                                                << 4U)) 
                                            | (0x1fU 
                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                  >> 0x14U))))))) 
                                 | ((((IData)((0x7ffffffffffffULL 
                                               & (((QData)((IData)(
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                   << 0x26U) 
                                                  | (((QData)((IData)(
                                                                      vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[7U])) 
                                                      << 6U) 
                                                     | ((QData)((IData)(
                                                                        vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                        >> 0x1aU))))) 
                                      >> 0x11U) | ((IData)(
                                                           ((0x7ffffffffffffULL 
                                                             & (((QData)((IData)(
                                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                                 << 0x26U) 
                                                                | (((QData)((IData)(
                                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[7U])) 
                                                                    << 6U) 
                                                                   | ((QData)((IData)(
                                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                                      >> 0x1aU)))) 
                                                            >> 0x20U)) 
                                                   << 0xfU)) 
                                    ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_ctrl_ref_w) 
                                        >> 0x11U) | 
                                       ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_ctrl_ref_w 
                                                 >> 0x20U)) 
                                        << 0xfU)))) 
                                | (((IData)(((0x7ffffffffffffULL 
                                              & (((QData)((IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U])) 
                                                  << 0x26U) 
                                                 | (((QData)((IData)(
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[7U])) 
                                                     << 6U) 
                                                    | ((QData)((IData)(
                                                                       vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                       >> 0x1aU)))) 
                                             >> 0x20U)) 
                                    ^ (IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head0_ctrl_ref_w 
                                               >> 0x20U))) 
                                   >> 0x11U))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2326: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3V-PREDECODE-COHERENCE] lane0 stored decode mismatches instruction @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2326, "");
        }
        if (VL_UNLIKELY((0U != ((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_head_imm1_w) 
                                    ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_imm_ref_w)) 
                                   | ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_head_imm1_w 
                                               >> 0x20U)) 
                                      ^ (IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_imm_ref_w 
                                                 >> 0x20U)))) 
                                  | ((((IData)((0x7ffffffffffffULL 
                                                & (((QData)((IData)(
                                                                    vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                    << 0x19U) 
                                                   | ((QData)((IData)(
                                                                      vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U])) 
                                                      >> 7U)))) 
                                       << 0xfU) | (
                                                   (0x7c00U 
                                                    & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[2U] 
                                                       >> 1U)) 
                                                   | ((0x3e0U 
                                                       & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[2U] 
                                                          >> 1U)) 
                                                      | (0x1fU 
                                                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[2U] 
                                                            >> 1U))))) 
                                     ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_ctrl_ref_w) 
                                         << 0xfU) | 
                                        ((0x7c00U & 
                                          ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                            << 0xeU) 
                                           | (0x3c00U 
                                              & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                 >> 0x12U)))) 
                                         | ((0x3e0U 
                                             & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[9U] 
                                                << 4U)) 
                                            | (0x1fU 
                                               & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[8U] 
                                                  >> 0x14U))))))) 
                                 | ((((IData)((0x7ffffffffffffULL 
                                               & (((QData)((IData)(
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                   << 0x19U) 
                                                  | ((QData)((IData)(
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U])) 
                                                     >> 7U)))) 
                                      >> 0x11U) | ((IData)(
                                                           ((0x7ffffffffffffULL 
                                                             & (((QData)((IData)(
                                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                                 << 0x19U) 
                                                                | ((QData)((IData)(
                                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U])) 
                                                                   >> 7U))) 
                                                            >> 0x20U)) 
                                                   << 0xfU)) 
                                    ^ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_ctrl_ref_w) 
                                        >> 0x11U) | 
                                       ((IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_ctrl_ref_w 
                                                 >> 0x20U)) 
                                        << 0xfU)))) 
                                | (((IData)(((0x7ffffffffffffULL 
                                              & (((QData)((IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[6U])) 
                                                  << 0x19U) 
                                                 | ((QData)((IData)(
                                                                    vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_packet_fifo__DOT__head_packet_q[5U])) 
                                                    >> 7U))) 
                                             >> 0x20U)) 
                                    ^ (IData)((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__t3v_head1_ctrl_ref_w 
                                               >> 0x20U))) 
                                   >> 0x11U))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2332: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3V-PREDECODE-COHERENCE] lane1 stored decode mismatches instruction @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2332, "");
        }
    }
    if (((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_trap_exit_sequencer__DOT__gap6_squash_noload_q))) {
        if (VL_UNLIKELY((((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_trap_cause_q)) 
                          | (0ULL != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_pc_q)) 
                         | (0ULL != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_tval_q)))) {
            VL_WRITEF("[%0t] %%Error: OooPendingTrapExitSequencer.v:116: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_pending_trap_exit_sequencer: [FLUSH-CONTRACT GAP-6] squash \346\270\205 arch trap \345\220\216 payload \346\256\213\347\225\231: cause=%x pc=%x tval=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),5,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_trap_cause_q),
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_pc_q,
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_tval_q,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v", 116, "");
        }
    }
    if (((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_trap_exit_sequencer__DOT__gap6_squash_collision_q))) {
        if (VL_UNLIKELY(((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                           | (0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_trap_cause_q))) 
                          | (0ULL != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_pc_q)) 
                         | (0ULL != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_tval_q)))) {
            VL_WRITEF("[%0t] %%Error: OooPendingTrapExitSequencer.v:123: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane.u_pending_trap_exit_sequencer: [FLUSH-CONTRACT GAP-6-COLLISION] squash/capture \345\220\214\346\213\215\345\220\216 wrong-path trap \345\244\215\346\264\273: valid=%b cause=%x pc=%x tval=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q),
                      5,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_trap_cause_q,
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_pc_q,
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__pending_trap_tval_q,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v", 123, "");
        }
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_is_muldiv_w)) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_fire_w) 
                        != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_fire_w))))) {
        VL_WRITEF("[%0t] %%Error: OooIntBackend.v:4258: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-MULDIV-CANONICAL-FIRE] issue fire=%b request fire=%b rob=%0# @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_fire_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_fire_w,
                  4,(0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_producer_id_w)),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 4258, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_is_clmul_w)) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_fire_w) 
                        != (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_is_clmul_w) 
                             & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_ctrlflow_ready_w)) 
                            & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_req_ready_w)))))) {
        VL_WRITEF("[%0t] %%Error: OooIntBackend.v:4263: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-CLMUL-CANONICAL-FIRE] issue fire=%b request fire=%b rob=%0# @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_fire_w),
                  1,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_is_clmul_w) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_ctrlflow_ready_w)) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_req_ready_w)),
                  4,(0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_producer_id_w)),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 4263, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_issue_res_dual_local_consume_w) 
                                                 != 
                                                 ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_issue_res_consume_fire_w) 
                                                  & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_is_mem_w)) 
                                                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue0_mem_exception_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooIntBackend.v:4923: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8G-MEM-LOCAL-READY-CUT] factored local terminal diverged from consume semantics @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 4923, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_issue1_res_local_complete_w) 
                                                 != 
                                                 ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_issue1_res_consume_fire_w) 
                                                  & ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_plain_ls_w)) 
                                                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_mem_exception_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooIntBackend.v:4929: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8P-MEM1-LOCAL-READY-CUT] factored terminal1 local completion diverged @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 4929, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__producer_id_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__producer_id_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__producer_id_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__rob_idx_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__rob_idx_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__rob_idx_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__data_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__strb_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v4 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v5 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v6 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v7 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__paddr_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__u_sram__DOT__mem_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__u_sram__DOT__mem_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__producer_id_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__producer_id_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__producer_id_q__v33 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__15__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__15__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__14__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__14__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__10__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__10__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__9__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__9__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__8__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__8__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__7__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__7__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__6__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__6__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__5__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__5__KET____DOT__g__DOT__u_stub__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_uart_axi__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_uart_axi__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_reset_syscon_axi__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_reset_syscon_axi__s_axi_rvalid_o;
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (1U 
                                                 < 
                                                 (7U 
                                                  & ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_en_w) 
                                                       + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w)) 
                                                      + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_start_w)) 
                                                     + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_pending_q))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:469: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache: [DWC-SRAM-1RW] \345\256\217\345\217\243\345\206\262\347\252\201: lookup=%b fill=%b rmw_rd=%b rmw_wr=%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_en_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_start_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_pending_q,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 469, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:471: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 471, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (1U 
                                                 < 
                                                 (7U 
                                                  & ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_en_w) 
                                                       + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w)) 
                                                      + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_start_w)) 
                                                     + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_pending_q))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:469: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache: [DWC-SRAM-1RW] \345\256\217\345\217\243\345\206\262\347\252\201: lookup=%b fill=%b rmw_rd=%b rmw_wr=%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_en_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w,
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_start_w),
                  1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_pending_q,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 469, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:471: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 471, "");
    }
    if (VL_UNLIKELY((((((((~ (IData)(vlSelf->rst)) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_event_w)) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_en_w))) 
                        & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w))) 
                       & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_start_w))) 
                      & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_pending_q))) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_en_w) 
                        | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__fill_we_w) 
                           | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_start_w) 
                              | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_hit_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:378: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache: [DWC-PEER-NO-SRAM-OWNER] peer-only event enabled SRAM @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 378, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:380: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 380, "");
    }
    if (VL_UNLIKELY((((((((~ (IData)(vlSelf->rst)) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_event_w)) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_en_w))) 
                        & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w))) 
                       & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_start_w))) 
                      & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_pending_q))) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_en_w) 
                        | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__fill_we_w) 
                           | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_start_w) 
                              | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_hit_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:378: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache: [DWC-PEER-NO-SRAM-OWNER] peer-only event enabled SRAM @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 378, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:380: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 380, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__15__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__15__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__14__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__14__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__10__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__10__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__9__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__9__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__8__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__8__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__7__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__7__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__6__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__6__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__5__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__gen_device_stub__BRA__5__KET____DOT__g__DOT__u_stub__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_uart_axi__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_uart_axi__s_axi_bvalid_o;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_cache_read_window_w)) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_cache_fill_valid_w)))) {
        VL_WRITEF("[%0t] %%Error: OooFetchPacketCache.v:232: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_fetch_bridge.u_fetch_packet_cache: [CONTRACT-FPC-1RW] physical read and fill write in same cycle violate 1RW SRAM: lookup_pc=%x fill_pc=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_pc_w,
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__fetch_ctx_exec_pc_q,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooFetchPacketCache.v", 232, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_plic_axi__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_plic_axi__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__threshold_s_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__threshold_s_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__threshold_m_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__threshold_m_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__priority_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__priority_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_plic_axi__DOT__priority_q__v33 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtime_div_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtime_div_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtimecmp_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtimecmp_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtime_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__mtime_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_clint_axi__s_axi_rvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_clint_axi__s_axi_rvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__msip_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_clint_axi__DOT__msip_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_cross_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_cross_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_idx_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_idx_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__invalidate_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_legacy_mmio_slave__DOT__wstrb_q 
        = vlSelf->NpcSimTop__DOT__u_legacy_mmio_slave__DOT__wstrb_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_legacy_mmio_slave__DOT__wdata_q 
        = vlSelf->NpcSimTop__DOT__u_legacy_mmio_slave__DOT__wdata_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_legacy_mmio_slave__DOT__awsize_q 
        = vlSelf->NpcSimTop__DOT__u_legacy_mmio_slave__DOT__awsize_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_legacy_mmio_slave__DOT__awaddr_q 
        = vlSelf->NpcSimTop__DOT__u_legacy_mmio_slave__DOT__awaddr_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_sdram_slave__DOT__wstrb_q 
        = vlSelf->NpcSimTop__DOT__u_sdram_slave__DOT__wstrb_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_sdram_slave__DOT__wdata_q 
        = vlSelf->NpcSimTop__DOT__u_sdram_slave__DOT__wdata_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_sdram_slave__DOT__awsize_q 
        = vlSelf->NpcSimTop__DOT__u_sdram_slave__DOT__awsize_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_sdram_slave__DOT__awaddr_q 
        = vlSelf->NpcSimTop__DOT__u_sdram_slave__DOT__awaddr_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_psram_slave__DOT__wstrb_q 
        = vlSelf->NpcSimTop__DOT__u_psram_slave__DOT__wstrb_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_psram_slave__DOT__wdata_q 
        = vlSelf->NpcSimTop__DOT__u_psram_slave__DOT__wdata_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_psram_slave__DOT__awsize_q 
        = vlSelf->NpcSimTop__DOT__u_psram_slave__DOT__awsize_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_psram_slave__DOT__awaddr_q 
        = vlSelf->NpcSimTop__DOT__u_psram_slave__DOT__awaddr_q;
    vlSelf->__Vdly__NpcSimTop__DOT__legacy_mmio_axi_rvalid_w 
        = vlSelf->NpcSimTop__DOT__legacy_mmio_axi_rvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__sdram_axi_rvalid_w 
        = vlSelf->NpcSimTop__DOT__sdram_axi_rvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__psram_axi_rvalid_w 
        = vlSelf->NpcSimTop__DOT__psram_axi_rvalid_w;
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (8U 
                                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__state_q))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__ifu_axi_awvalid_w)) 
                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__walk_pte_addr_q 
                        != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__walk_pte_addr_w)))) {
        VL_WRITEF("[%0t] %%Error: OooAdUpdateChecker.sv:76: Assertion failed in %NNpcSimTop.u_ooo_fetch_adupd_checker: [ADUPD-ADDR] %NNpcSimTop.u_ooo_fetch_adupd_checker: A/D \345\206\231\345\234\260\345\235\200 %x != \346\234\254\347\272\247 walk_pte_addr %x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  vlSymsp->name(),64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__walk_pte_addr_q,
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_fetch_bridge__DOT__walk_pte_addr_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 76, "");
        VL_WRITEF("[%0t] %%Fatal: OooAdUpdateChecker.sv:78: Assertion failed in %NNpcSimTop.u_ooo_fetch_adupd_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 78, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_plic_axi__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_plic_axi__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT____Vcellout__u_clint_axi__s_axi_bvalid_o 
        = vlSelf->NpcSimTop__DOT__u_top__DOT____Vcellout__u_clint_axi__s_axi_bvalid_o;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_cross_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_cross_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_idx_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_idx_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__invalidate_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__legacy_mmio_axi_bvalid_w 
        = vlSelf->NpcSimTop__DOT__legacy_mmio_axi_bvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__sdram_axi_bvalid_w 
        = vlSelf->NpcSimTop__DOT__sdram_axi_bvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__psram_axi_bvalid_w 
        = vlSelf->NpcSimTop__DOT__psram_axi_bvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_irq_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_irq_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_bresp_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_bresp_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__wstrb_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__wstrb_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__wdata_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__wdata_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_release_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_release_q;
    vlSelf->__Vdly__NpcSimTop__DOT__virtio_blk_axi_rvalid_w 
        = vlSelf->NpcSimTop__DOT__virtio_blk_axi_rvalid_w;
    if (((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_control_full_flush_barrier_w))) {
        if (VL_UNLIKELY((((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__direct_jal_fire_w) 
                              | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_ret0_fire_w)) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_ret1_fire_w)) 
                            | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__direct_jump_spec_fire_w)) 
                           | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__direct_frontend_flush_w)) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__fifo_pop_w)) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_fetch_req_valid_w)))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2390: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [V9O-FRONTEND-C0] frontend action escaped queue-head barrier @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2390, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_cross_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_cross_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_idx1_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_idx1_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_idx0_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_idx0_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__virtio_blk_axi_bvalid_w 
        = vlSelf->NpcSimTop__DOT__virtio_blk_axi_bvalid_w;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_cross_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_cross_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_idx1_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_idx1_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_idx0_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_idx0_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_check_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v33 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v34 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v35 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v36 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v37 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v38 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v39 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v40 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v41 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v42 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__epoch_q__v43 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v33 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v34 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v35 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v36 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v37 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v38 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v39 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v40 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v41 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v42 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__kind_q__v43 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_valid_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_valid_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_event_model_q 
        = vlSelf->NpcSimTop__DOT__u_virtio_blk_axi__DOT__notify_event_model_q;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__rmw_pending_q)) 
                     & (((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__active_sq_query_valid_w) 
                           & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__sq_query_decision_onehot_w) 
                              & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_allow_w) 
                                 & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w)))) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__station_sq_lookahead_lookup_fire_w)) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w)) 
                        | (9U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q)))))) {
        VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2073: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [MEM-RMW-PORT] RMW \345\210\244\345\206\263\346\213\215\345\207\272\347\216\260 query-lookup/fill/S_LOOKUP: state=%0# query=%b fill=%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  4,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q),
                  1,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__active_sq_query_valid_w) 
                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__sq_query_decision_onehot_w) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_allow_w) 
                            & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w)))) 
                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__station_sq_lookahead_lookup_fire_w)),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2073, "");
        VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2076: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2076, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (8U 
                                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_wvalid_w)) 
                     & (~ (IData)((0xffU == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_wstrb_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooAdUpdateChecker.sv:104: Assertion failed in %NNpcSimTop.u_ooo_mem0_adupd_checker: [ADUPD-STRB] %NNpcSimTop.u_ooo_mem0_adupd_checker: A/D \345\206\231 wstrb \351\235\236\345\205\250\347\275\256 =%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  vlSymsp->name(),8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_wstrb_w),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 104, "");
        VL_WRITEF("[%0t] %%Fatal: OooAdUpdateChecker.sv:106: Assertion failed in %NNpcSimTop.u_ooo_mem0_adupd_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 106, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__rmw_pending_q)) 
                     & (((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__active_sq_query_valid_w) 
                           & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__sq_query_decision_onehot_w) 
                              & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_allow_w) 
                                 & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w)))) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__station_sq_lookahead_lookup_fire_w)) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w)) 
                        | (9U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q)))))) {
        VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2073: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [MEM-RMW-PORT] RMW \345\210\244\345\206\263\346\213\215\345\207\272\347\216\260 query-lookup/fill/S_LOOKUP: state=%0# query=%b fill=%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  4,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q),
                  1,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__active_sq_query_valid_w) 
                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__sq_query_decision_onehot_w) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_allow_w) 
                            & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w)))) 
                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__station_sq_lookahead_lookup_fire_w)),
                  1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2073, "");
        VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2076: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2076, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (8U 
                                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_wvalid_w)) 
                     & (~ (IData)((0xffU == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_wstrb_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooAdUpdateChecker.sv:104: Assertion failed in %NNpcSimTop.u_ooo_mem1_adupd_checker: [ADUPD-STRB] %NNpcSimTop.u_ooo_mem1_adupd_checker: A/D \345\206\231 wstrb \351\235\236\345\205\250\347\275\256 =%b @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  vlSymsp->name(),8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_wstrb_w),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 104, "");
        VL_WRITEF("[%0t] %%Fatal: OooAdUpdateChecker.sv:106: Assertion failed in %NNpcSimTop.u_ooo_mem1_adupd_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 106, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (8U 
                                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_awvalid_w)) 
                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_awaddr_w 
                        != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__walk_pte_addr_w)))) {
        VL_WRITEF("[%0t] %%Error: OooAdUpdateChecker.sv:76: Assertion failed in %NNpcSimTop.u_ooo_mem0_adupd_checker: [ADUPD-ADDR] %NNpcSimTop.u_ooo_mem0_adupd_checker: A/D \345\206\231\345\234\260\345\235\200 %x != \346\234\254\347\272\247 walk_pte_addr %x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  vlSymsp->name(),64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_awaddr_w,
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__walk_pte_addr_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 76, "");
        VL_WRITEF("[%0t] %%Fatal: OooAdUpdateChecker.sv:78: Assertion failed in %NNpcSimTop.u_ooo_mem0_adupd_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 78, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_control_full_flush_barrier_w)) 
                     & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_req_ready_w) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__stage_advance_w)) 
                        | (((9U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q)) 
                            | (0xaU == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__state_q))) 
                           & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_axi_arvalid_w)))))) {
        VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:1875: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [V9O-MEM-C0] request/station/pre-owner AR escaped barrier @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 1875, "");
        VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:1877: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 1877, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_en_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_en_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_en_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_preg_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_preg_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_preg_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_en_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_en_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_en_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_preg_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_preg_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_preg_q__v9 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_sqrt_iter__DOT__step_idx_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_sqrt_iter__DOT__step_idx_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_sqrt_iter__DOT__busy_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_sqrt_iter__DOT__busy_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_preg_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_preg_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_preg_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_preg_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_preg_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_preg_q__v9 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_div_iter__DOT__bit_idx_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_div_iter__DOT__bit_idx_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_div_iter__DOT__busy_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_long_op__DOT__u_fp_div_iter__DOT__busy_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__head_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__head_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__tail_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__tail_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__fifo_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__fifo_q__v1 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__fifo_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__fifo_q__v65 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_busy_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_busy_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_busy_q__v65 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_busy_q__v66 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_busy_q__v67 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__ready_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__ready_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__ready_q__v65 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__ready_q__v66 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__ready_q__v67 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__head_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__head_q;
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__exec1_kill_w)) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__exec1_take_w)))) {
        VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1256: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-COMPLETION-KILL-NOW] killed exec1 completed on kill edge\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1256, "");
    }
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__long_kill_w)) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__long_take_pre_w)))) {
        VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1258: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-COMPLETION-KILL-NOW] killed long completed on kill edge\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1258, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q__v128 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q__v129 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__tail_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__tail_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__fifo_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__fifo_q__v1 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__fifo_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_free_list__DOT__fifo_q__v65 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v12 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v13 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v14 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_ready_q__v15 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v12 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v13 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v14 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_ready_q__v15 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v12 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v13 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v14 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs2_ready_q__v15 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v12 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v13 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v14 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v15 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v16 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_ready_q__v17 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q__v64 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q__v128 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q__v129 = 0U;
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (0U 
                                                 != 
                                                 (((((((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_gpr_read_data_w) 
                                                           ^ (IData)(
                                                                     ((0U 
                                                                       == 
                                                                       (0x3fU 
                                                                        & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U]))
                                                                       ? 0ULL
                                                                       : 
                                                                      vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                      [
                                                                      (0x3fU 
                                                                       & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U])]))) 
                                                          | ((IData)(
                                                                     (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_gpr_read_data_w 
                                                                      >> 0x20U)) 
                                                             ^ (IData)(
                                                                       (((0U 
                                                                          == 
                                                                          (0x3fU 
                                                                           & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U]))
                                                                          ? 0ULL
                                                                          : 
                                                                         vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                         [
                                                                         (0x3fU 
                                                                          & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U])]) 
                                                                        >> 0x20U)))) 
                                                         | ((IData)(
                                                                    ((0U 
                                                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w))
                                                                      ? 0ULL
                                                                      : 
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w])) 
                                                            ^ (IData)(
                                                                      ((0U 
                                                                        == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w))
                                                                        ? 0ULL
                                                                        : 
                                                                       vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                       [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w])))) 
                                                        | ((IData)(
                                                                   (((0U 
                                                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w))
                                                                      ? 0ULL
                                                                      : 
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w]) 
                                                                    >> 0x20U)) 
                                                           ^ (IData)(
                                                                     (((0U 
                                                                        == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w))
                                                                        ? 0ULL
                                                                        : 
                                                                       vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                       [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src2_preg_w]) 
                                                                      >> 0x20U)))) 
                                                       | ((IData)(
                                                                  ((0U 
                                                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w))
                                                                    ? 0ULL
                                                                    : 
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w])) 
                                                          ^ (IData)(
                                                                    ((0U 
                                                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w))
                                                                      ? 0ULL
                                                                      : 
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w])))) 
                                                      | ((IData)(
                                                                 (((0U 
                                                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w))
                                                                    ? 0ULL
                                                                    : 
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w]) 
                                                                  >> 0x20U)) 
                                                         ^ (IData)(
                                                                   (((0U 
                                                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w))
                                                                      ? 0ULL
                                                                      : 
                                                                     vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                     [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_src1_preg_w]) 
                                                                    >> 0x20U)))) 
                                                     | ((IData)(
                                                                ((0U 
                                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w))
                                                                  ? 0ULL
                                                                  : 
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w])) 
                                                        ^ (IData)(
                                                                  ((0U 
                                                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w))
                                                                    ? 0ULL
                                                                    : 
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w])))) 
                                                    | ((IData)(
                                                               (((0U 
                                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w))
                                                                  ? 0ULL
                                                                  : 
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w]) 
                                                                >> 0x20U)) 
                                                       ^ (IData)(
                                                                 (((0U 
                                                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w))
                                                                    ? 0ULL
                                                                    : 
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                   [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src2_preg_w]) 
                                                                  >> 0x20U)))) 
                                                   | ((IData)(
                                                              ((0U 
                                                                == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w))
                                                                ? 0ULL
                                                                : 
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w])) 
                                                      ^ (IData)(
                                                                ((0U 
                                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w))
                                                                  ? 0ULL
                                                                  : 
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w])))) 
                                                  | ((IData)(
                                                             (((0U 
                                                                == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w))
                                                                ? 0ULL
                                                                : 
                                                               vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                               [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w]) 
                                                              >> 0x20U)) 
                                                     ^ (IData)(
                                                               (((0U 
                                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w))
                                                                  ? 0ULL
                                                                  : 
                                                                 vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_phys_reg_file__DOT__regs_q
                                                                 [vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_src1_preg_w]) 
                                                                >> 0x20U)))))))) {
        VL_WRITEF("[%0t] %%Error: OooPhysRegFile.v:71: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_phys_reg_file: [PRF-INT-READ-STORED-ONLY] integer PRF read differs from registered state\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/regread_bypass/OooPhysRegFile.v", 71, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (0U 
                                                 != 
                                                 (((((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpst_read_data_w) 
                                                         ^ (IData)(
                                                                   vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                   [
                                                                   ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_fp_st_en_w)
                                                                     ? (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_fp_st_preg_w)
                                                                     : (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_fp_st_preg_w))])) 
                                                        | ((IData)(
                                                                   (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpst_read_data_w 
                                                                    >> 0x20U)) 
                                                           ^ (IData)(
                                                                     (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                      [
                                                                      ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_fp_st_en_w)
                                                                        ? (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__iq_issue0_fp_st_preg_w)
                                                                        : (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__issue1_fp_st_preg_w))] 
                                                                      >> 0x20U)))) 
                                                       | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs3_data_w) 
                                                          ^ (IData)(
                                                                    vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                    [
                                                                    (0x3fU 
                                                                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                        >> 6U))]))) 
                                                      | ((IData)(
                                                                 (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs3_data_w 
                                                                  >> 0x20U)) 
                                                         ^ (IData)(
                                                                   (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                    [
                                                                    (0x3fU 
                                                                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                        >> 6U))] 
                                                                    >> 0x20U)))) 
                                                     | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs2_data_w) 
                                                        ^ (IData)(
                                                                  vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                  [
                                                                  (0x3fU 
                                                                   & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                      >> 0xcU))]))) 
                                                    | ((IData)(
                                                               (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs2_data_w 
                                                                >> 0x20U)) 
                                                       ^ (IData)(
                                                                 (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                  [
                                                                  (0x3fU 
                                                                   & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                      >> 0xcU))] 
                                                                  >> 0x20U)))) 
                                                   | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs1_data_w) 
                                                      ^ (IData)(
                                                                vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                [
                                                                (0x3fU 
                                                                 & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                    >> 0x12U))]))) 
                                                  | ((IData)(
                                                             (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fs1_data_w 
                                                              >> 0x20U)) 
                                                     ^ (IData)(
                                                               (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_phys_reg_file__DOT__regs_q
                                                                [
                                                                (0x3fU 
                                                                 & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[0U] 
                                                                    >> 0x12U))] 
                                                                >> 0x20U)))))))) {
        VL_WRITEF("[%0t] %%Error: OooFpPhysRegFile.v:74: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_phys_reg_file: [FP-PRF-STORED-ONLY] read port bypassed stored regs_q data\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/regread_bypass/OooFpPhysRegFile.v", 74, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__double_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__double_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__double_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_en_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_en_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__gpr_en_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__producer_id_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_gpr_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_gpr_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__dst_gpr_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__pdest_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__pdest_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__pdest_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_en_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_en_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs3_en_q__v9 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__mul_count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__mul_count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__div_count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__div_count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_pdest_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_pdest_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_word_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__req_word_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__state_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__state_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__inst_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__inst_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__inst_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_en_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_en_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__fs1_en_q__v9 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__iter_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__iter_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q;
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (8U 
                                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q))) 
                      & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_awvalid_w)) 
                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_awaddr_w 
                        != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__walk_pte_addr_w)))) {
        VL_WRITEF("[%0t] %%Error: OooAdUpdateChecker.sv:76: Assertion failed in %NNpcSimTop.u_ooo_mem1_adupd_checker: [ADUPD-ADDR] %NNpcSimTop.u_ooo_mem1_adupd_checker: A/D \345\206\231\345\234\260\345\235\200 %x != \346\234\254\347\272\247 walk_pte_addr %x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  vlSymsp->name(),64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_awaddr_w,
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__walk_pte_addr_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 76, "");
        VL_WRITEF("[%0t] %%Fatal: OooAdUpdateChecker.sv:78: Assertion failed in %NNpcSimTop.u_ooo_mem1_adupd_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv", 78, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_apply_w) 
                                                  & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_lookup_line0_match_w) 
                                                     | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_cross_w) 
                                                        & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_lookup_line1_match_w))))) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__lookup_pend_q) 
                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__lookup_cacheable_q) 
                           & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__valid_q[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__lookup_idx_q) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__lookup_idx_q))) 
                              & ((~ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__dcache_invalidate_all_w) 
                                     | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_invalidate_apply_w) 
                                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_lookup_line0_match_w) 
                                           | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_cross_w) 
                                              & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__peer_lookup_line1_match_w)))))) 
                                 & ((0x1ffffffffffffULL 
                                     & (((QData)((IData)(
                                                         vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__sram_rdata_w[3U])) 
                                         << 0x20U) 
                                        | (QData)((IData)(
                                                          vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__sram_rdata_w[2U])))) 
                                    == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__u_dcache__DOT__lookup_tag_q)))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:367: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache: [DWC-PEER-HIT-BLOCK] peer-invalidated exact lookup returned hit: addr=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane0_peer_maintenance_addr_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 367, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:369: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 369, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_control_full_flush_barrier_w)) 
                     & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_req_ready_w) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__stage_advance_w)) 
                        | (((9U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q)) 
                            | (0xaU == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__state_q))) 
                           & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_axi_arvalid_w)))))) {
        VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:1875: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [V9O-MEM-C0] request/station/pre-owner AR escaped barrier @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 1875, "");
        VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:1877: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 1877, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v8 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v9 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v10 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v11 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v12 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v13 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v14 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v15 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v16 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v17 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__valid_q__v18 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__epoch_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__epoch_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__epoch_q__v33 = 0U;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_apply_w) 
                                                  & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_lookup_line0_match_w) 
                                                     | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_cross_w) 
                                                        & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_lookup_line1_match_w))))) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__lookup_pend_q) 
                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__lookup_cacheable_q) 
                           & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__valid_q[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__lookup_idx_q) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__lookup_idx_q))) 
                              & ((~ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__dcache_invalidate_all_w) 
                                     | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_invalidate_apply_w) 
                                        & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_lookup_line0_match_w) 
                                           | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_cross_w) 
                                              & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__peer_lookup_line1_match_w)))))) 
                                 & ((0x1ffffffffffffULL 
                                     & (((QData)((IData)(
                                                         vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__sram_rdata_w[3U])) 
                                         << 0x20U) 
                                        | (QData)((IData)(
                                                          vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__sram_rdata_w[2U])))) 
                                    == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__u_dcache__DOT__lookup_tag_q)))))))) {
        VL_WRITEF("[%0t] %%Error: OooDataWordCache.v:367: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache: [DWC-PEER-HIT-BLOCK] peer-invalidated exact lookup returned hit: addr=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__lane1_peer_maintenance_addr_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 367, "");
        VL_WRITEF("[%0t] %%Fatal: OooDataWordCache.v:369: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.u_dcache\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/cache/OooDataWordCache.v", 369, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i) 
                                                  | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_mispredict_w))) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fire_w)))) {
        VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1198: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ISSUE-STAGE-NO-KILL-LAUNCH] kill/flush \346\213\215\344\273\215 launch @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1198, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_mispredict_w)) 
                     & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_issue_stage_up_ready_w) 
                        & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT____VdfgTmp_hb4bc3eb2__0))))) {
        VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1201: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ISSUE-STAGE-NO-KILL-REFILL] kill \346\213\215 IQ ready \346\234\252\345\216\213\344\275\216 @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1201, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_control_full_flush_barrier_w)) 
                     & (((((((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp_fire_w) 
                                 | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp1_fire_w)) 
                                | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld0_alloc_valid_i) 
                                   & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__dispatch0_accept_w))) 
                               | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld1_alloc_valid_i) 
                                  & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__dispatch1_accept_w))) 
                              | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_issue_stage_up_ready_w) 
                                 & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT____VdfgTmp_hb4bc3eb2__0))) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fire_w)) 
                            | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_result_wb_valid_w)) 
                           | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__df_pop_w)) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_valid_w)) 
                         | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_wake0_valid_w)) 
                        | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_wake1_valid_w))))) {
        VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1207: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [V9O-FP-C0] FP admission/issue/completion escaped barrier @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1207, "");
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_w_sent_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_w_sent_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_aw_sent_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_aw_sent_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_araddr_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__d_araddr_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__cmd_split_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__cmd_split_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__cmd_nbytes_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__cmd_nbytes_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__kind_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__kind_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__kind_q__v33 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__dispatched_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__dispatched_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__csr_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__csr_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__valid_q;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (0U 
                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rob__DOT__count_q))) 
                     & (0U != ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                                 & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w)) 
                                << 1U) | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                                          ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooAluCoreSlice.v:598: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice: [CORE-RETIRE-REQUIRES-ROB] retire=%0# while ROB is empty @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  2,((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                       & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w)) 
                      << 1U) | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                                ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w))),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooAluCoreSlice.v", 598, "");
    }
    if (VL_UNLIKELY(((~ (IData)(vlSelf->rst)) & (3U 
                                                 == 
                                                 ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                                                    & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w)) 
                                                   << 1U) 
                                                  | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit0_isa_retire_w) 
                                                     ^ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__commit1_isa_retire_w))))))) {
        VL_WRITEF("[%0t] %%Error: OooAluCoreSlice.v:602: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice: [INSTRET-G1-CORE-RANGE] core ISA retire count exceeded two lanes @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooAluCoreSlice.v", 602, "");
        VL_WRITEF("[%0t] %%Fatal: OooAluCoreSlice.v:604: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooAluCoreSlice.v", 604, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_arch_reg_file__DOT__rf__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_arch_reg_file__DOT__rf__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_arch_reg_file__DOT__rf__v33 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem1_inflight_queue__DOT__flush_expected_count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem1_inflight_queue__DOT__flush_expected_count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem1_inflight_queue__DOT__flush_count_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem1_inflight_queue__DOT__flush_count_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_inflight_queue__DOT__flush_expected_count_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_inflight_queue__DOT__flush_expected_count_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_inflight_queue__DOT__flush_count_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_inflight_queue__DOT__flush_count_check_q;
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i))) 
                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__issue_fire_w) 
                         & ((IData)(((0xa6U == (0xfeU 
                                                & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[1U])) 
                                     & ((0U == (0x7fU 
                                                & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[2U] 
                                                    << 6U) 
                                                   | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[1U] 
                                                      >> 0x1aU)))) 
                                        | ((1U == (0x7fU 
                                                   & ((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[2U] 
                                                       << 6U) 
                                                      | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__payload_q[1U] 
                                                         >> 0x1aU)))) 
                                           | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__arith_sub_op_w))))) 
                            | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__op_mul_w) 
                               | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__op_fma_w))))) 
                     & (3U == ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__op_fma_w)
                                ? 2U : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__op_mul_w)
                                         ? 1U : 0U)))))) {
        VL_WRITEF("[%0t] %%Error: OooFpArithGate.v:1435: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend.u_fp_arith: [FP-ARITH-CONTRACT] illegal launch_kind_i=3\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v", 1435, "");
    }
    if (VL_UNLIKELY((((((~ (IData)(vlSelf->rst)) & 
                        (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i))) 
                       & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_result_wb_valid_w)) 
                      & (~ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__arith_out_valid_w) 
                            | ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__exec1_take_w)) 
                               | (IData)((0x20U == 
                                          (0x60U & 
                                           vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__payload_q[2U]))))))) 
                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_wake0_valid_w)))) {
        VL_WRITEF("[%0t] %%Fatal: OooFpBackend.v:1249: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: GPR-destination FP completion woke FPR domain\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1249, "");
    }
    if ((1U & ((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i))))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d0_fp_arith_w) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld0_alloc_valid_i)))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1216: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-RAW-ONEHOT] lane0 arith/load raw intent overlap @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1216, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d1_fp_arith_w) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld1_alloc_valid_i)))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1219: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-RAW-ONEHOT] lane1 arith/load raw intent overlap @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1219, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp_fire_w) 
                          | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld0_alloc_valid_i) 
                             & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__dispatch0_accept_w))) 
                         & (~ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__count_q) 
                                >= (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__lane0_frd_intent_w)) 
                               & (8U >= (0x1fU & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__count_q) 
                                                  + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d0_fp_arith_w))))))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1223: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-CREDIT] lane0 accepted without lane0 credit @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1223, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp1_fire_w) 
                          | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld1_alloc_valid_i) 
                             & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__dispatch1_accept_w))) 
                         & (~ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__count_q) 
                                >= (0xffU & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__lane0_frd_intent_w) 
                                             + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_fp_backend__fpld1_alloc_valid_i) 
                                                | ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__d1_fp_gpr_write_w)) 
                                                   & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d1_fp_arith_w)))))) 
                               & (8U >= (0x1fU & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__count_q) 
                                                  + 
                                                  ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d0_fp_arith_w) 
                                                   + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__d1_fp_arith_w)))))))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1226: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-CREDIT] lane1 accepted without packet credit @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1226, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__alloc0_valid_w) 
                         & (0U == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__count_q))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1230: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-FREELIST-READY] lane0 alloc without FreeList ready @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1230, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__alloc1_valid_w) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__count_q) 
                            <= (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_free_list__DOT__alloc0_fire_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1233: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-FREELIST-READY] lane1 alloc without FreeList ready @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1233, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp_fire_w) 
                         & (~ ((8U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__count_q)) 
                               & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT____VdfgTmp_h2ca92426__0)))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1237: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-IQ-READY] lane0 arith accept without FP-IQ ready @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1237, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp1_fire_w) 
                         & (~ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT__count_q) 
                                < (0xfU & ((IData)(8U) 
                                           - (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__disp_fire_w)))) 
                               & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_queue__DOT____VdfgTmp_h2ca92426__0)))))) {
            VL_WRITEF("[%0t] %%Error: OooFpBackend.v:1240: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_fp_backend: [FP-ADMISSION-IQ-READY] lane1 arith accept without FP-IQ ready @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpBackend.v", 1240, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__state_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_lsu_lane_adapter__DOT__state_q;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q)) 
                          != (0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q))) 
                         | ((0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q)) 
                            != (0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q)))))) {
            VL_WRITEF("[%0t] %%Error: OooClmulUnit.v:181: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_clmul_unit: [V8H-CLMUL-PID-PROJECTION] holder identity projection mismatch @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v", 181, "");
            VL_WRITEF("[%0t] %%Fatal: OooClmulUnit.v:182: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_clmul_unit\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v", 182, "");
        }
        if (VL_UNLIKELY(((((IData)(vlSelf->rst) | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____Vcellinp__u_branch_resolve_stage__flush_i)) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_mispredict_w)) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_req_ready_w)))) {
            VL_WRITEF("[%0t] %%Error: OooClmulUnit.v:185: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_clmul_unit: [V8H-CLMUL-REQ-GUARD] request ready during reset/flush/kill @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v", 185, "");
            VL_WRITEF("[%0t] %%Fatal: OooClmulUnit.v:186: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_clmul_unit\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v", 186, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q;
    if (VL_UNLIKELY(((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__drain_complete_w)) 
                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__valid_q) 
                         & (IData)((0xfU == (0x707fU 
                                             & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__inst_q))))) 
                     & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_mem_idle_w))))) {
        VL_WRITEF("[%0t] %%Error: OooControlPlane.v:947: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_control_plane: [FENCE-DRAIN-MEM-IDLE] ordinary FENCE completed with MIQ/bridge/reservation busy\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v", 947, "");
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_valid_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__alloc0_found_r)) 
                         & ((0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_producer_id_w)) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_rob_w))))) {
            VL_WRITEF("[V8V-LQ-ALLOC0-PID] pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:473: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_producer_id_w,
                      4,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_rob_w),
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 473, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc1_valid_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__alloc1_found_r)) 
                         & ((0xfU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_dispatch1_producer_id_w)) 
                            != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_dispatch1_idx_w))))) {
            VL_WRITEF("[V8V-LQ-ALLOC1-PID] pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:479: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_dispatch1_producer_id_w,
                      4,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_dispatch1_idx_w),
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 479, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc1_valid_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_alloc0_valid_w))))) {
            VL_WRITEF("[V8V-LQ-ALLOC-PREFIX] alloc1 without alloc0 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:483: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 483, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_launch0_valid_w) 
                         & (1U != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launch0_hits_r)))) {
            VL_WRITEF("[V8V-LQ-LAUNCH0-HIT] hits=%0d pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:488: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launch0_hits_r,
                      8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_launch0_producer_id_w),
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 488, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_launch1_valid_w) 
                         & (1U != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launch1_hits_r)))) {
            VL_WRITEF("[V8V-LQ-LAUNCH1-HIT] hits=%0d pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:493: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launch1_hits_r,
                      8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_launch1_producer_id_w),
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 493, "");
        }
        if (VL_UNLIKELY((((((VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__issue0_hits_r) 
                             | VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__issue1_hits_r)) 
                            | VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query0_hits_r)) 
                           | VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query1_hits_r)) 
                          | VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__response0_hits_r)) 
                         | VL_LTS_III(32, 1U, vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__response1_hits_r)))) {
            VL_WRITEF("[V8V-LQ-CAM-ONEHOT] issue=%0d/%0d query=%0d/%0d response=%0d/%0d @%0t\n[%0t] %%Fatal: OooLoadQueue.v:501: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__issue0_hits_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__issue1_hits_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query0_hits_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query1_hits_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__response0_hits_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__response1_hits_r,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 501, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_query0_update_w) 
                         & (1U != (7U & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query0_allow_r) 
                                          + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query0_forward_r)) 
                                         + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query0_replay_r))))))) {
            VL_WRITEF("[V8V-LQ-QUERY0-DISPOSITION] allow/fwd/replay not onehot @%0t\n[%0t] %%Fatal: OooLoadQueue.v:508: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 508, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_query1_update_w) 
                         & (1U != (7U & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query1_allow_r) 
                                          + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query1_forward_r)) 
                                         + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_store_queue__DOT__query1_replay_r))))))) {
            VL_WRITEF("[V8V-LQ-QUERY1-DISPOSITION] allow/fwd/replay not onehot @%0t\n[%0t] %%Fatal: OooLoadQueue.v:515: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 515, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query_pair_same_pid_w) 
                         & ((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query0_open_r) 
                              | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__query1_open_r)) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_query0_update_w)) 
                            | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_query1_update_w))))) {
            VL_WRITEF("[V8V-LQ-DUAL-QUERY-SAME-PID] duplicate disposition pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:522: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_sq_query_producer_id_w,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 522, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_response0_query_valid_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_response1_query_valid_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w))))) {
            VL_WRITEF("[V8V-LQ-DUAL-RESPONSE-SAME-PID] pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:528: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 528, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__execute0_valid_unused_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__execute1_valid_unused_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__wb0_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__wb1_producer_id_w))))) {
            VL_WRITEF("[V8V-LQ-DUAL-COMPLETION-SAME-PID] pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:534: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__wb0_producer_id_w,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 534, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_terminal0_valid_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_terminal1_valid_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_terminal0_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_terminal1_producer_id_w))))) {
            VL_WRITEF("[V8V-LQ-DUAL-TERMINAL-SAME-PID] pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:540: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_terminal0_producer_id_w,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 540, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_release0_fire_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__lq_release1_fire_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__rob_commit1_producer_id_w))))) {
            VL_WRITEF("[V8V-LQ-DUAL-RELEASE-SAME-PID] pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:546: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_producer_id_w,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 546, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__count_r) 
                         != (0x1fU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__live_count_r)))) {
            VL_WRITEF("[V8V-LQ-COUNT] count=%0# live=%0d @%0t\n[%0t] %%Fatal: OooLoadQueue.v:551: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      5,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__count_r,
                      32,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__live_count_r,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 551, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [0U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [0U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=0 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [0U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [0U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=0 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/1 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/2 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/3 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/4 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/5 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=0/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [1U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [1U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [1U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=1 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [1U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [1U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [1U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=1 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/2 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/3 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/4 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/5 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [1U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [1U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=1/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [1U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [2U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [2U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [2U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=2 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [2U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [2U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [2U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=2 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/3 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/4 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/5 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [2U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [2U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=2/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [2U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [3U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [3U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [3U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=3 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [3U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [3U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [3U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=3 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/4 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/5 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [3U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [3U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=3/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [3U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [4U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [4U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [4U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=4 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [4U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [4U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [4U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=4 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/5 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [4U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [4U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=4/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [4U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [5U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [5U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [5U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=5 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [5U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [5U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [5U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=5 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/6 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [5U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [5U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=5/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [5U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [6U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [6U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [6U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=6 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [6U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [6U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [6U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=6 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/7 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [6U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [6U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=6/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [6U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [7U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [7U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [7U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=7 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [7U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [7U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [7U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=7 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/8 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [7U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [7U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=7/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [7U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [8U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [8U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [8U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=8 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [8U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [8U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [8U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=8 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/9 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [8U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [8U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=8/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [8U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [9U] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                  [9U]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                 [9U])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=9 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [9U]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                    [9U]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                   [9U])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=9 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/10 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [9U] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [9U] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=9/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [9U],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xaU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xaU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xaU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=10 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xaU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xaU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xaU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=10 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=10/11 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=10/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=10/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=10/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xaU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xaU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=10/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xaU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xbU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xbU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xbU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=11 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xbU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xbU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xbU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xbU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xbU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=11 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=11/12 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xbU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=11/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xbU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=11/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xbU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xbU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xbU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=11/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xbU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xcU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xcU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xcU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=12 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xcU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xcU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xcU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xcU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xcU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=12 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=12/13 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xcU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=12/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xcU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xcU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xcU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=12/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xcU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xdU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xdU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xdU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=13 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xdU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xdU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xdU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xdU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xdU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=13 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=13/14 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xdU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xdU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xdU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=13/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xdU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xeU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xeU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xeU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=14 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xeU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xeU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xeU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xeU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xeU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=14 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xeU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU]) & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xeU] == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-DUP-PID] entries=14/15 pid=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:571: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xeU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 571, "");
        }
        if (VL_UNLIKELY((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                         [0xfU] & ((0xfU & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                                    [0xfU]) != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                                   [0xfU])))) {
            VL_WRITEF("[V8V-LQ-PID-INDEX] entry=15 pid=%x rob=%x @%0t\n[%0t] %%Fatal: OooLoadQueue.v:558: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      8,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q
                      [0xfU],4,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__rob_idx_q
                      [0xfU],64,VL_TIME_UNITED_Q(1000),
                      -9,64,VL_TIME_UNITED_Q(1000),
                      -9,vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 558, "");
        }
        if (VL_UNLIKELY(((vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__valid_q
                          [0xfU] & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__killed_q
                          [0xfU]) & ((~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__launched_q
                                      [0xfU]) | vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__completed_q
                                     [0xfU])))) {
            VL_WRITEF("[V8V-LQ-KILLED-STATE] entry=15 @%0t\n[%0t] %%Fatal: OooLoadQueue.v:563: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.u_load_queue\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v", 563, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_flush_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_flush_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_hold_expect_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_hold_expect_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[0U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[0U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[1U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[1U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[2U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_fp_issue_stage__DOT__assert_payload_prev_q[2U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_flush_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_flush_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_hold_expect_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_hold_expect_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[0U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[0U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[1U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[1U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[2U] 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__u_exec1_stage__DOT__assert_payload_prev_q[2U];
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_expect_iters_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_expect_iters_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_golden_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_golden_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_iters_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_iters_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_golden_valid_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_mul_golden_valid_q;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_map_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_map_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_map_q__v33 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_map_q__v34 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__fp_map_q__v35 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rename_map__DOT__map_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rename_map__DOT__map_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rename_map__DOT__map_q__v33 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rename_map__DOT__map_q__v34 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_rename_map__DOT__map_q__v35 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_miss_arbiter__DOT__owner_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_miss_arbiter__DOT__owner_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_miss_arbiter__DOT__state_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_miss_arbiter__DOT__state_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_death_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_death_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_prev_q;
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w)) 
                     & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w)
                          ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                  : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                      ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                          : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                      : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                          : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                  : 
                                                 ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                              : 0ULL))))
                              : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                                  : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w))
                          : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w) 
                        != ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                             ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                 ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                 : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                     ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                         ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                         : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                     : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                         ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                         : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                             ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                                 ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                 : 
                                                ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                  : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                             : 0ULL))))
                             : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                 ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                                 : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w)))))) {
        VL_WRITEF("[%0t] %%Error: OooRedirectMuxChecker.sv:50: Assertion failed in %NNpcSimTop.u_ooo_rdmux_checker: [RDMUX-ARB-PC] arbiter \350\265\242\345\256\266\346\213\215 mux \350\220\275\347\202\271\346\234\252\351\200\217\344\274\240\350\265\242\345\256\266 PC(\351\223\276\350\207\202\345\244\215\346\264\273?): pc=%x expect=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w)
                       ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                           ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                   ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                       ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                       : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                   : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                       ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                       : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                           ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                           : 0ULL))))
                           : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                               : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w))
                       : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w),
                  64,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                       ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                           ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                           : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                               ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                   : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                       ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                           ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                           : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                               : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                       : 0ULL)))) : 
                      ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                        ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                        : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w)),
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectMuxChecker.sv", 50, "");
        VL_WRITEF("[%0t] %%Fatal: OooRedirectMuxChecker.sv:52: Assertion failed in %NNpcSimTop.u_ooo_rdmux_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectMuxChecker.sv", 52, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w))) 
                     & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w)
                          ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                  : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                      ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                          : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                      : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                          : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                  : 
                                                 ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                              : 0ULL))))
                              : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                                  : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w))
                          : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w) 
                        != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w)))) {
        VL_WRITEF("[%0t] %%Error: OooRedirectMuxChecker.sv:56: Assertion failed in %NNpcSimTop.u_ooo_rdmux_checker: [RDMUX-DEFAULT-PC] \346\227\240\350\265\242\345\256\266\346\213\215 mux \350\220\275\347\202\271\346\234\252\345\205\234\345\272\225 core_branch_resolve_next_pc: pc=%x expect=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__inv2_win_g_w)
                       ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                           ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                   ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                       ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                       : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                   : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                       ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                       : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                           ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                           : 0ULL))))
                           : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                               : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w))
                       : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectMuxChecker.sv", 56, "");
        VL_WRITEF("[%0t] %%Fatal: OooRedirectMuxChecker.sv:58: Assertion failed in %NNpcSimTop.u_ooo_rdmux_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectMuxChecker.sv", 58, "");
    }
    if (VL_UNLIKELY((((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->NpcSimTop__DOT__u_ooo_rdseq_checker__DOT__csr_trap_seen_q)) 
                     & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__next_fetch_pc_q 
                        != vlSelf->NpcSimTop__DOT__u_ooo_rdseq_checker__DOT__csr_trap_target_seen_q)))) {
        VL_WRITEF("[%0t] %%Error: OooRedirectSeqChecker.sv:73: Assertion failed in %NNpcSimTop.u_ooo_rdseq_checker: [RDSEQ-CSRTRAP-PC] CSR_TRAP \345\205\250\345\261\200\346\234\200\351\253\230\344\274\230\345\205\210\344\270\215\345\217\230\351\207\217\347\240\264\345\235\217: \344\270\212\346\213\215 csr_trap \345\221\275\344\270\255\344\275\206 next_fetch_pc_q=%x != csr_trap_target=%x @%0t\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name(),
                  64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_fetch_pc_outstanding__DOT__next_fetch_pc_q,
                  64,vlSelf->NpcSimTop__DOT__u_ooo_rdseq_checker__DOT__csr_trap_target_seen_q,
                  64,VL_TIME_UNITED_Q(1000),-9);
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectSeqChecker.sv", 73, "");
        VL_WRITEF("[%0t] %%Fatal: OooRedirectSeqChecker.sv:75: Assertion failed in %NNpcSimTop.u_ooo_rdseq_checker\n",
                  64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
        VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooRedirectSeqChecker.sv", 75, "");
    }
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q__v16 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_load_queue__DOT__producer_id_q__v17 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__assert_kind_prev_q__v0 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__assert_kind_prev_q__v32 = 0U;
    vlSelf->__Vdlyvset__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__assert_kind_prev_q__v33 = 0U;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__assert_live_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__assert_live_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__conservation_expected_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__conservation_expected_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__conservation_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_tracker__DOT__conservation_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_req_capture_pending_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__md_req_capture_pending_q;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__control_event_valid_w) 
                           & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w) 
                              | ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)) 
                                 | (~ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_misaligned_w) 
                                       | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_control_flush_sequencer__DOT__trap_redirect_squash_q)))))) 
                          & ((1U == ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                                      ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                          ? 3U : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                                   ? 8U
                                                   : 
                                                  (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                                                    | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                       & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)))
                                                    ? 3U
                                                    : 
                                                   (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q))
                                                     ? 4U
                                                     : 
                                                    (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                      & (0x12000073U 
                                                         == 
                                                         (0xfe007fffU 
                                                          & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__inst_q)))
                                                      ? 5U
                                                      : 
                                                     (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                       & (0x100fU 
                                                          == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__inst_q))
                                                       ? 6U
                                                       : 
                                                      ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                                        ? 9U
                                                        : 7U)))))))
                                      : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                          ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_is_branch_w)
                                              ? 1U : 2U)
                                          : 7U))) | 
                             (2U == ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                                      ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                          ? 3U : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                                   ? 8U
                                                   : 
                                                  (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q) 
                                                    | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                       & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)))
                                                    ? 3U
                                                    : 
                                                   (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                     & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q))
                                                     ? 4U
                                                     : 
                                                    (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                      & (0x12000073U 
                                                         == 
                                                         (0xfe007fffU 
                                                          & vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__inst_q)))
                                                      ? 5U
                                                      : 
                                                     (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w) 
                                                       & (0x100fU 
                                                          == vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__inst_q))
                                                       ? 6U
                                                       : 
                                                      ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                                        ? 9U
                                                        : 7U)))))))
                                      : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                          ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_is_branch_w)
                                              ? 1U : 2U)
                                          : 7U))))) 
                         & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                  : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                      ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                          : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                      : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                          ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                          : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                              ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                  : 
                                                 ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                   ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                   : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                              : 0ULL))))
                              : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                  ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                                  : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w)) 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w)))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2384: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [FLUSH-CONTRACT INV-1] arbiter branch \345\217\243\350\265\242\345\256\266 PC != core_branch_resolve_next_pc: arb=%x expect=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_trap_valid_w)
                                           ? ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_mem_valid_w)
                                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                               : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT____Vcellinp__u_csr_file__csr_commit_i)
                                                   ? 
                                                  ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_head0_csr_commit_w)
                                                    ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_commit0_next_pc_w
                                                    : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q)
                                                   : 
                                                  ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__pending_arch_trap_q)
                                                    ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                    : 
                                                   ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__commit_e6_sel_system_w)
                                                     ? 
                                                    ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT____VdfgTmp_h12de4349__0)
                                                      ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_trap_target_w
                                                      : 
                                                     ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__mret_q)
                                                       ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_csr_ret_target_w
                                                       : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__next_pc_q))
                                                     : 0ULL))))
                                           : ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__u_redirect_arbiter__DOT__branch_win_w)
                                               ? vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w
                                               : vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__e4_redirect_pc_w)),
                      64,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_branch_resolve_next_pc_w,
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2384, "");
        }
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_frontend__DOT__head0_csr_inflight_q) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q)) 
                         & (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__orphan_stop_pending_w) 
                             | (~ ((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__orphan_stop_pending_w)) 
                                   & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q)))) 
                            | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w))))) {
            VL_WRITEF("[%0t] %%Error: OooFrontend.v:2341: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_frontend: [T3U-CSR-STOP-OWNER] inflight CSR lost stop ownership orphan=%0# busy=%0# run=%0# @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__orphan_stop_pending_w),
                      1,((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__orphan_stop_pending_w)) 
                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q)),
                      1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__can_run_w),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v", 2341, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__stop_pending_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_hold_tuple_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_hold_tuple_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_hold_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out1_hold_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_hold_tuple_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_hold_tuple_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_hold_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__out0_hold_check_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__conservation_expected_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__conservation_expected_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__conservation_check_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_mem_owner_terminal_collector__DOT__conservation_check_q;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        VL_SHIFTL_WWI(256,256,8, __Vtemp_49, VNpcSimTop__ConstPool__CONST_h4e9f510d_0, (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_q));
        VL_SHIFTL_WWI(256,256,8, __Vtemp_51, VNpcSimTop__ConstPool__CONST_h4e9f510d_0, (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_q));
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q) 
                         & (0U != ((((((((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                            ? __Vtemp_49[0U]
                                            : VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U]) 
                                          ^ __Vtemp_51[0U]) 
                                         | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                              ? __Vtemp_49[1U]
                                              : VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U]) 
                                            ^ __Vtemp_51[1U])) 
                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                             ? __Vtemp_49[2U]
                                             : VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U]) 
                                           ^ __Vtemp_51[2U])) 
                                       | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                            ? __Vtemp_49[3U]
                                            : VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U]) 
                                          ^ __Vtemp_51[3U])) 
                                      | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                           ? __Vtemp_49[4U]
                                           : VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U]) 
                                         ^ __Vtemp_51[4U])) 
                                     | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                          ? __Vtemp_49[5U]
                                          : VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U]) 
                                        ^ __Vtemp_51[5U])) 
                                    | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                         ? __Vtemp_49[6U]
                                         : VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U]) 
                                       ^ __Vtemp_51[6U])) 
                                   | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                        ? __Vtemp_49[7U]
                                        : VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U]) 
                                      ^ __Vtemp_51[7U])))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5645: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8K-PENDING-CSR-LEASE-DECODE] raw pending lease is not exact onehot pid=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_q),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5645, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5647: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5647, "");
        }
        VL_SHIFTL_WWI(256,256,8, __Vtemp_52, VNpcSimTop__ConstPool__CONST_h4e9f510d_0, (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_q));
        if (VL_UNLIKELY(((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)) 
                         & (0U != ((((((((VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U] 
                                          ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                              ? __Vtemp_52[0U]
                                              : VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U])) 
                                         | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U] 
                                            ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                                ? __Vtemp_52[1U]
                                                : VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U]))) 
                                        | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U] 
                                           ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                               ? __Vtemp_52[2U]
                                               : VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U]))) 
                                       | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U] 
                                          ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                              ? __Vtemp_52[3U]
                                              : VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U]))) 
                                      | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U] 
                                         ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                             ? __Vtemp_52[4U]
                                             : VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U]))) 
                                     | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U] 
                                        ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                            ? __Vtemp_52[5U]
                                            : VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U]))) 
                                    | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U] 
                                       ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                           ? __Vtemp_52[6U]
                                           : VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U]))) 
                                   | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U] 
                                      ^ ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)
                                          ? __Vtemp_52[7U]
                                          : VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U]))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5652: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8K-PENDING-CSR-LEASE-ZERO] invalid pending lease contributed holder bits @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5652, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5654: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5654, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__dispatch0_fire_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_valid_q)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_dispatch0_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__u_pending_system_sequencer__DOT__producer_id_q))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5658: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8K-PENDING-CSR-NO-LIVE-REUSE] lane0 reused pending CSR ProducerId=%x @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),8,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__core_dispatch0_producer_id_w),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5658, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5660: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5660, "");
        }
        if (VL_UNLIKELY((1U < (7U & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w) 
                                     + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb0_valid_w) 
                                        + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb0_valid_w) 
                                           + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb0_valid_w) 
                                              + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb0_valid_w) 
                                                 + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb0_valid_w)))))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5663: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-WB0-SOURCE-ONEHOT0] sources=%b @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),6,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb0_valid_w) 
                                          << 5U) | 
                                         (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb0_valid_w) 
                                           << 4U) | 
                                          (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb0_valid_w) 
                                            << 3U) 
                                           | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb0_valid_w) 
                                               << 2U) 
                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb0_valid_w) 
                                                  << 1U) 
                                                 | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w)))))),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5663, "");
        }
        if (VL_UNLIKELY((1U < (7U & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w) 
                                     + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb1_valid_w) 
                                        + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb1_valid_w) 
                                           + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb1_valid_w) 
                                              + ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb1_valid_w) 
                                                 + (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb1_valid_w)))))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5666: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-WB1-SOURCE-ONEHOT0] sources=%b @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),6,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb1_valid_w) 
                                          << 5U) | 
                                         (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb1_valid_w) 
                                           << 4U) | 
                                          (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb1_valid_w) 
                                            << 3U) 
                                           | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb1_valid_w) 
                                               << 2U) 
                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb1_valid_w) 
                                                  << 1U) 
                                                 | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w)))))),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5666, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb0_write_valid_w) 
                         != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__wakeup0_real_w)))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5669: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-WB0-WRITE-VALID-EQUIV] local=%b legacy=%b sources=%b @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb0_write_valid_w),
                      1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__wakeup0_real_w,
                      6,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb0_valid_w) 
                          << 5U) | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb0_valid_w) 
                                     << 4U) | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb0_valid_w) 
                                                << 3U) 
                                               | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb0_valid_w) 
                                                   << 2U) 
                                                  | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb0_valid_w) 
                                                      << 1U) 
                                                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w)))))),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5669, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb1_write_valid_w) 
                         != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__wakeup1_real_w)))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5673: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [INT-WB1-WRITE-VALID-EQUIV] local=%b legacy=%b sources=%b @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),1,(IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__gpr_wb1_write_valid_w),
                      1,vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_dispatch_backend__DOT__u_busy_table__DOT__wakeup1_real_w,
                      6,(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb1_valid_w) 
                          << 5U) | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb1_valid_w) 
                                     << 4U) | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_wb1_valid_w) 
                                                << 3U) 
                                               | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_wb1_valid_w) 
                                                   << 2U) 
                                                  | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_wb1_valid_w) 
                                                      << 1U) 
                                                     | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w)))))),
                      64,VL_TIME_UNITED_Q(1000),-9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5673, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_actual_claim_w) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_completion_rob_open_w)) 
                             | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w) 
                                 & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_producer_id_q) 
                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))) 
                                | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w) 
                                    & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_producer_id_q) 
                                       == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))) 
                                   | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                                       & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                          == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))) 
                                      | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w) 
                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w) 
                                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))))))) 
                            | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5679: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-MULDIV-COMPLETION-AUTH] actual completion escaped exact-open/claim gate @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5679, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5681: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5681, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb0_valid_w) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb1_valid_w)) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_completion_rob_open_w)) 
                             | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w) 
                                 & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_producer_id_q) 
                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))) 
                                | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w) 
                                    & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_producer_id_q) 
                                       == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))) 
                                   | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                                       & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                          == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))) 
                                      | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w) 
                                          & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w) 
                                             == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))) 
                                         | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_actual_claim_w) 
                                            & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q) 
                                               == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q)))))))) 
                            | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5686: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-CLMUL-COMPLETION-AUTH] actual completion escaped exact-open/claim gate @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5686, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5688: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5688, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_resp_ready_w) 
                          != ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_rsp_to_wb0_w) 
                              | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_rsp_to_wb1_w))) 
                         | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_rsp_to_wb0_w) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_rsp_to_wb1_w)) 
                            != ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_rsp_to_wb0_w) 
                                | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_rsp_to_wb1_w)))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5694: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-LONGOP-TRANSPORT-AUTH-SEPARATION] response ready diverged from raw route @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5694, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5696: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5696, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_actual_claim_w) 
                          & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb0_valid_w) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__clmul_wb1_valid_w))) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5701: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-LONGOP-SAME-EDGE-CLAIM] MulDiv/CLMUL completed one PID twice @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5701, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5703: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5703, "");
        }
        VL_SHIFTL_WWI(256,256,8, __Vtemp_54, VNpcSimTop__ConstPool__CONST_h4e9f510d_0, (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q));
        if ((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__state_q))) {
            __Vtemp_56[0U] = __Vtemp_54[0U];
            __Vtemp_56[1U] = __Vtemp_54[1U];
            __Vtemp_56[2U] = __Vtemp_54[2U];
            __Vtemp_56[3U] = __Vtemp_54[3U];
            __Vtemp_56[4U] = __Vtemp_54[4U];
            __Vtemp_56[5U] = __Vtemp_54[5U];
            __Vtemp_56[6U] = __Vtemp_54[6U];
            __Vtemp_56[7U] = __Vtemp_54[7U];
        } else {
            __Vtemp_56[0U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U];
            __Vtemp_56[1U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U];
            __Vtemp_56[2U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U];
            __Vtemp_56[3U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U];
            __Vtemp_56[4U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U];
            __Vtemp_56[5U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U];
            __Vtemp_56[6U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U];
            __Vtemp_56[7U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U];
        }
        if (VL_UNLIKELY(((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__state_q)) 
                         & (~ (__Vtemp_56[((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q) 
                                           >> 5U)] 
                               >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5707: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-MULDIV-LEASE-DECODE] live holder missing from dispatch mask @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5707, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5709: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5709, "");
        }
        VL_SHIFTL_WWI(256,256,8, __Vtemp_57, VNpcSimTop__ConstPool__CONST_h4e9f510d_0, (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q));
        if ((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q))) {
            __Vtemp_59[0U] = __Vtemp_57[0U];
            __Vtemp_59[1U] = __Vtemp_57[1U];
            __Vtemp_59[2U] = __Vtemp_57[2U];
            __Vtemp_59[3U] = __Vtemp_57[3U];
            __Vtemp_59[4U] = __Vtemp_57[4U];
            __Vtemp_59[5U] = __Vtemp_57[5U];
            __Vtemp_59[6U] = __Vtemp_57[6U];
            __Vtemp_59[7U] = __Vtemp_57[7U];
        } else {
            __Vtemp_59[0U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U];
            __Vtemp_59[1U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U];
            __Vtemp_59[2U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U];
            __Vtemp_59[3U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U];
            __Vtemp_59[4U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U];
            __Vtemp_59[5U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U];
            __Vtemp_59[6U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U];
            __Vtemp_59[7U] = VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U];
        }
        if (VL_UNLIKELY(((0U != (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__state_q)) 
                         & (~ (__Vtemp_59[((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q) 
                                           >> 5U)] 
                               >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5713: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8H-CLMUL-LEASE-DECODE] live holder missing from dispatch mask @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5713, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5715: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5715, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_rob_open_w)) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_same_edge_claimed_w)) 
                            | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5720: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8I-MEM-COMPLETION-OWNER] memory bypassed exact/claim/pending fence @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5720, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5722: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5722, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_rob_open_w)) 
                             | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_done_now_w) 
                                | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                                   & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w))))) 
                            | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                               ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w) 
                                >> 5U)] >> (0x1fU & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5727: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8S-MEM1-COMPLETION-OWNER] bank1 memory bypassed exact/claim/pending fence @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5727, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5729: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5729, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                          & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w)) 
                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5733: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8S-DUAL-MEM-SAME-EDGE-CLAIM] both banks completed one PID @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5733, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5735: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5735, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb0_valid_w) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb1_valid_w)) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_formal_completion_rob_open_w)) 
                             | (~ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                                   ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w) 
                                    >> 5U)] >> (0x1fU 
                                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))))) 
                            | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w) 
                                & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_producer_id_q) 
                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))) 
                               | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w) 
                                   & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_producer_id_q) 
                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))) 
                                  | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                         == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))) 
                                     | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w) 
                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w) 
                                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))) 
                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_actual_claim_w) 
                                            & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w) 
                                               == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))) 
                                           | ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____VdfgTmp_h9ebfecf0__0) 
                                              & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q) 
                                                 == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w)))))))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5740: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8I-FP-FORMAL-AUTH] formal token bypassed exact owner/claim fence @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5740, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5742: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5742, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_authorized_w) 
                         & (((~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_completion_rob_open_w)) 
                             | (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[
                                ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w) 
                                 >> 5U)] >> (0x1fU 
                                             & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w)))) 
                            | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_wb_valid_w) 
                                & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex0_producer_id_q) 
                                   == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w))) 
                               | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_wb_valid_w) 
                                   & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__ex1_producer_id_q) 
                                      == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w))) 
                                  | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_actual_claim_w) 
                                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem_completion_producer_id_w) 
                                         == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w))) 
                                     | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_actual_claim_w) 
                                         & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__mem1_completion_producer_id_w) 
                                            == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w))) 
                                        | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__muldiv_actual_claim_w) 
                                            & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w) 
                                               == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_muldiv_unit__DOT__producer_id_q))) 
                                           | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT____VdfgTmp_h9ebfecf0__0) 
                                               & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_clmul_unit__DOT__producer_id_q) 
                                                  == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w))) 
                                              | (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb0_valid_w) 
                                                  | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_wb1_valid_w)) 
                                                 & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_result_query_producer_id_w) 
                                                    == (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_producer_id_w))))))))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5747: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8I-FP-RESULT-AUTH] result bypassed exact/pending/claim fence @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5747, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5749: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5749, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_to_wb0_w) 
                          | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_to_wb1_w)) 
                         != ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_to_wb0_w) 
                             | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fpwb_to_wb1_w))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5752: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8I-FP-FORMAL-TRANSPORT] raw ready read completion authority @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5752, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5754: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5754, "");
        }
        if (VL_UNLIKELY((0U != ((((((((VNpcSimTop__ConstPool__CONST_h9e67c271_0[0U] 
                                       ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[0U] 
                                          & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[0U]))) 
                                      | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[1U] 
                                         ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[1U] 
                                            & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[1U])))) 
                                     | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[2U] 
                                        ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[2U] 
                                           & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[2U])))) 
                                    | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[3U] 
                                       ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[3U] 
                                          & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[3U])))) 
                                   | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[4U] 
                                      ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[4U] 
                                         & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[4U])))) 
                                  | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[5U] 
                                     ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[5U] 
                                        & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[5U])))) 
                                 | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[6U] 
                                    ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[6U] 
                                       & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[6U])))) 
                                | (VNpcSimTop__ConstPool__CONST_h9e67c271_0[7U] 
                                   ^ (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__u_fp_backend__DOT__completion_pending_mask_r[7U] 
                                      & (~ vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_execute_backend__DOT__u_core_slice__DOT__u_decode_backend__DOT__u_int_backend__DOT__fp_producer_live_mask_w[7U]))))))) {
            VL_WRITEF("[%0t] %%Error: OooIntBackend.v:5758: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend: [V8I-FP-PENDING-LEASE] completion owner missing from live mask @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5758, "");
            VL_WRITEF("[%0t] %%Fatal: OooIntBackend.v:5760: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_core.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v", 5760, "");
        }
    }
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__station_sq_lookahead_lookup_fire_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__req_dcacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2030: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [V8U-SQ-LOOKAHEAD-CACHE-CLASS] non-CACHED station query issued lookup @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2030, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2032: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2032, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_en_w) 
                         & ((((~ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__active_sq_query_valid_w) 
                                   & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__sq_query_decision_onehot_w) 
                                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_allow_w) 
                                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w)))) 
                                  | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__station_sq_lookahead_lookup_fire_w))) 
                              | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_valid_w))) 
                             | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_allow_w))) 
                            | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__sq_query_decision_onehot_w)))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2039: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [V8T-SQ-QUERY-CACHE-AUTH] lookup bypassed exact SQ allow @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2039, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2041: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2041, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__active_sq_query_valid_w) 
                          & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__sq_query_decision_onehot_w) 
                             & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem1_sq_query_allow_w) 
                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w)))) 
                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_addr_w 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__paddr_q)))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2045: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [V8T-SQ-QUERY-CACHE-PA] lookup address differs from final PA Q @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2045, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2047: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2047, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__station_sq_lookahead_lookup_fire_w) 
                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_lookup_addr_w 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__req_cache_addr_w)))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2051: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [V8U-SQ-LOOKAHEAD-CACHE-PA] station lookup address differs from final PA @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2051, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2053: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2053, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_read_fill_valid_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2056: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [S1-TYPED-DCACHE-FILL] non-CACHED transaction attempted fill @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2056, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2058: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2058, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__dcache_store_rmw_en_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge1__DOT__access_cacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2061: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1: [S1-TYPED-DCACHE-RMW] non-CACHED store attempted RMW @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2061, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2062: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2062, "");
        }
    }
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_core_flush_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_core_flush_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_death_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_death_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_lease_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_lease_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_system_fire_pid_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_system_fire_pid_prev_q;
    vlSelf->__Vdly__NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_system_fire_prev_q 
        = vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_core__DOT__u_control_plane__DOT__v8k_system_fire_prev_q;
    if ((1U & (~ (IData)(vlSelf->rst)))) {
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__station_sq_lookahead_lookup_fire_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__req_dcacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2030: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [V8U-SQ-LOOKAHEAD-CACHE-CLASS] non-CACHED station query issued lookup @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2030, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2032: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2032, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_en_w) 
                         & ((((~ (((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__active_sq_query_valid_w) 
                                   & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__sq_query_decision_onehot_w) 
                                      & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_allow_w) 
                                         & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w)))) 
                                  | (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__station_sq_lookahead_lookup_fire_w))) 
                              | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_valid_w))) 
                             | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_allow_w))) 
                            | (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__sq_query_decision_onehot_w)))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2039: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [V8T-SQ-QUERY-CACHE-AUTH] lookup bypassed exact SQ allow @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2039, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2041: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2041, "");
        }
        if (VL_UNLIKELY((((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__active_sq_query_valid_w) 
                          & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__sq_query_decision_onehot_w) 
                             & ((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__ooo_mem0_sq_query_allow_w) 
                                & (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w)))) 
                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_addr_w 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__paddr_q)))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2045: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [V8T-SQ-QUERY-CACHE-PA] lookup address differs from final PA Q @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2045, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2047: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2047, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__station_sq_lookahead_lookup_fire_w) 
                         & (vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_lookup_addr_w 
                            != vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__req_cache_addr_w)))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2051: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [V8U-SQ-LOOKAHEAD-CACHE-PA] station lookup address differs from final PA @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2051, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2053: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2053, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_read_fill_valid_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2056: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [S1-TYPED-DCACHE-FILL] non-CACHED transaction attempted fill @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2056, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2058: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2058, "");
        }
        if (VL_UNLIKELY(((IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__dcache_store_rmw_en_w) 
                         & (~ (IData)(vlSelf->NpcSimTop__DOT__u_top__DOT__u_core__DOT__u_ooo_dual_mem_bridge__DOT__u_bridge0__DOT__access_cacheable_w))))) {
            VL_WRITEF("[%0t] %%Error: OooMemAxiBridge.v:2061: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0: [S1-TYPED-DCACHE-RMW] non-CACHED store attempted RMW @%0t\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name(),64,VL_TIME_UNITED_Q(1000),
                      -9);
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2061, "");
            VL_WRITEF("[%0t] %%Fatal: OooMemAxiBridge.v:2062: Assertion failed in %NNpcSimTop.u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0\n",
                      64,VL_TIME_UNITED_Q(1000),-9,
                      vlSymsp->name());
            VL_STOP_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v", 2062, "");
        }
    }
}
