// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VAxiDpiSlave.h for the primary calling header

#include "VAxiDpiSlave__pch.h"

VL_ATTR_COLD void VAxiDpiSlave___024root___eval_static(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_static\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_static__TOP
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v = 0ULL;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v = 0ULL;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v = 0ULL;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_data_v = 0ULL;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_mask_v = 0ULL;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v = 0U;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v = 0U;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v = 0U;
        vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v = 0U;
    }
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__rst__0 = vlSelfRef.rst;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arvalid_i__0 
        = vlSelfRef.s_axi_arvalid_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_araddr_i__0 
        = vlSelfRef.s_axi_araddr_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arsize_i__0 
        = vlSelfRef.s_axi_arsize_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arprot_i__0 
        = vlSelfRef.s_axi_arprot_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_rready_i__0 
        = vlSelfRef.s_axi_rready_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awvalid_i__0 
        = vlSelfRef.s_axi_awvalid_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awaddr_i__0 
        = vlSelfRef.s_axi_awaddr_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awsize_i__0 
        = vlSelfRef.s_axi_awsize_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wvalid_i__0 
        = vlSelfRef.s_axi_wvalid_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wdata_i__0 
        = vlSelfRef.s_axi_wdata_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wstrb_i__0 
        = vlSelfRef.s_axi_wstrb_i;
    vlSelfRef.__Vtrigprevexpr___TOP__s_axi_bready_i__0 
        = vlSelfRef.s_axi_bready_i;
    vlSelfRef.__Vtrigprevexpr___TOP__clk__1 = vlSelfRef.clk;
}

VL_ATTR_COLD void VAxiDpiSlave___024root___eval_initial(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_initial\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void VAxiDpiSlave___024root___eval_final(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_final\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool VAxiDpiSlave___024root___eval_phase__stl(VAxiDpiSlave___024root* vlSelf);

VL_ATTR_COLD void VAxiDpiSlave___024root___eval_settle(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_settle\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            VAxiDpiSlave___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv", 26, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 10000 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = VAxiDpiSlave___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD bool VAxiDpiSlave___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(VAxiDpiSlave___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool VAxiDpiSlave___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___trigger_anySet__stl\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

VL_ATTR_COLD bool VAxiDpiSlave___024root___eval_phase__stl(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_phase__stl\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__stl
        vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                          & vlSelfRef.__VstlTriggered[0U]) 
                                         | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
    }
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VAxiDpiSlave___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = VAxiDpiSlave___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        {
            // Inlined CFunc: _eval_stl
            if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
                {
                    // Inlined CFunc: _stl_sequent__TOP__0
                    vlSelfRef.s_axi_arready_o = (1U 
                                                 & (~ (IData)(vlSelfRef.s_axi_rvalid_o)));
                    vlSelfRef.s_axi_awready_o = (1U 
                                                 & (~ 
                                                    ((IData)(vlSelfRef.s_axi_bvalid_o) 
                                                     | (IData)(vlSelfRef.AxiDpiSlave__DOT__aw_valid_q))));
                    vlSelfRef.s_axi_wready_o = (1U 
                                                & (~ 
                                                   ((IData)(vlSelfRef.s_axi_bvalid_o) 
                                                    | (IData)(vlSelfRef.AxiDpiSlave__DOT__w_valid_q))));
                    vlSelfRef.AxiDpiSlave__DOT__aw_fire_w 
                        = ((IData)(vlSelfRef.s_axi_awready_o) 
                           & (IData)(vlSelfRef.s_axi_awvalid_i));
                    vlSelfRef.AxiDpiSlave__DOT__w_fire_w 
                        = ((IData)(vlSelfRef.s_axi_wready_o) 
                           & (IData)(vlSelfRef.s_axi_wvalid_i));
                    vlSelfRef.AxiDpiSlave__DOT__write_complete_w 
                        = ((~ (IData)(vlSelfRef.s_axi_bvalid_o)) 
                           & (((IData)(vlSelfRef.AxiDpiSlave__DOT__aw_valid_q) 
                               | (IData)(vlSelfRef.AxiDpiSlave__DOT__aw_fire_w)) 
                              & ((IData)(vlSelfRef.AxiDpiSlave__DOT__w_valid_q) 
                                 | (IData)(vlSelfRef.AxiDpiSlave__DOT__w_fire_w))));
                }
            }
        }
    }
    return (__VstlExecute);
}

bool VAxiDpiSlave___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 2> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 2> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(VAxiDpiSlave___024root___trigger_anySet__ico(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @( clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @( rst)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @( s_axi_arvalid_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @( s_axi_araddr_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 4U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 4 is active: @( s_axi_arsize_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 5U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 5 is active: @( s_axi_arprot_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 6U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 6 is active: @( s_axi_rready_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 7U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 7 is active: @( s_axi_awvalid_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 8U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 8 is active: @( s_axi_awaddr_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 9U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 9 is active: @( s_axi_awsize_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 0x0000000aU)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 10 is active: @( s_axi_wvalid_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 0x0000000bU)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 11 is active: @( s_axi_wdata_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 0x0000000cU)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 12 is active: @( s_axi_wstrb_i)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 0x0000000dU)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 13 is active: @( s_axi_bready_i)\n");
    }
    if ((1U & (IData)(triggers[1U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 64 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

bool VAxiDpiSlave___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(VAxiDpiSlave___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VAxiDpiSlave___024root___ctor_var_reset(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___ctor_var_reset\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16707436170211756652ull);
    vlSelf->rst = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18209466448985614591ull);
    vlSelf->s_axi_arvalid_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11165017966399429700ull);
    vlSelf->s_axi_arready_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10085976981439743887ull);
    vlSelf->s_axi_araddr_i = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 5973446809134854721ull);
    vlSelf->s_axi_arsize_i = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 3934553219665786629ull);
    vlSelf->s_axi_arprot_i = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 16393182084152685203ull);
    vlSelf->s_axi_rvalid_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12221046268638023673ull);
    vlSelf->s_axi_rready_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17556091252003766926ull);
    vlSelf->s_axi_rdata_o = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 2360870040284959982ull);
    vlSelf->s_axi_rresp_o = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 8506256820532876053ull);
    vlSelf->s_axi_awvalid_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8613786161829284788ull);
    vlSelf->s_axi_awready_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14658084339374955554ull);
    vlSelf->s_axi_awaddr_i = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 12567015837251455679ull);
    vlSelf->s_axi_awsize_i = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10170394043634454817ull);
    vlSelf->s_axi_wvalid_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9040219475216960761ull);
    vlSelf->s_axi_wready_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10609376082359566060ull);
    vlSelf->s_axi_wdata_i = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 3961460011658238697ull);
    vlSelf->s_axi_wstrb_i = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 14460145002665476403ull);
    vlSelf->s_axi_bvalid_o = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 595306830199995702ull);
    vlSelf->s_axi_bready_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8799575018614520078ull);
    vlSelf->s_axi_bresp_o = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 17868722530768879257ull);
    vlSelf->AxiDpiSlave__DOT__awaddr_q = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 9647879838965511907ull);
    vlSelf->AxiDpiSlave__DOT__awsize_q = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 7462793640592210587ull);
    vlSelf->AxiDpiSlave__DOT__aw_valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1091545697627997677ull);
    vlSelf->AxiDpiSlave__DOT__wdata_q = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 9941235103658437337ull);
    vlSelf->AxiDpiSlave__DOT__wstrb_q = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 9892939870919450579ull);
    vlSelf->AxiDpiSlave__DOT__w_valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7984047118828309786ull);
    vlSelf->AxiDpiSlave__DOT__aw_fire_w = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1627056507589060842ull);
    vlSelf->AxiDpiSlave__DOT__w_fire_w = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11438695710490425713ull);
    vlSelf->AxiDpiSlave__DOT__write_complete_w = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7617521544926741875ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__VicoTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__rst__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_arvalid_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_araddr_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_arsize_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_arprot_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_rready_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_awvalid_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_awaddr_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_awsize_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_wvalid_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_wdata_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_wstrb_i__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__s_axi_bready_i__0 = 0;
    vlSelf->__VicoDidInit = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__1 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
}
