// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VAxiDpiSlave.h for the primary calling header

#include "VAxiDpiSlave__pch.h"

void VAxiDpiSlave___024root___eval_triggers_vec__ico(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_triggers_vec__ico\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = (QData)((IData)(
                                                    (((((((IData)(vlSelfRef.s_axi_bready_i) 
                                                          != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_bready_i__0)) 
                                                         << 5U) 
                                                        | (((IData)(vlSelfRef.s_axi_wstrb_i) 
                                                            != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wstrb_i__0)) 
                                                           << 4U)) 
                                                       | ((((vlSelfRef.s_axi_wdata_i 
                                                             != vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wdata_i__0) 
                                                            << 3U) 
                                                           | (((IData)(vlSelfRef.s_axi_wvalid_i) 
                                                               != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_wvalid_i__0)) 
                                                              << 2U)) 
                                                          | ((((IData)(vlSelfRef.s_axi_awsize_i) 
                                                               != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awsize_i__0)) 
                                                              << 1U) 
                                                             | (vlSelfRef.s_axi_awaddr_i 
                                                                != vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awaddr_i__0)))) 
                                                      << 8U) 
                                                     | (((((((IData)(vlSelfRef.s_axi_awvalid_i) 
                                                             != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_awvalid_i__0)) 
                                                            << 3U) 
                                                           | (((IData)(vlSelfRef.s_axi_rready_i) 
                                                               != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_rready_i__0)) 
                                                              << 2U)) 
                                                          | ((((IData)(vlSelfRef.s_axi_arprot_i) 
                                                               != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arprot_i__0)) 
                                                              << 1U) 
                                                             | ((IData)(vlSelfRef.s_axi_arsize_i) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arsize_i__0)))) 
                                                         << 4U) 
                                                        | ((((vlSelfRef.s_axi_araddr_i 
                                                              != vlSelfRef.__Vtrigprevexpr___TOP__s_axi_araddr_i__0) 
                                                             << 3U) 
                                                            | (((IData)(vlSelfRef.s_axi_arvalid_i) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__s_axi_arvalid_i__0)) 
                                                               << 2U)) 
                                                           | ((((IData)(vlSelfRef.rst) 
                                                                != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__rst__0)) 
                                                               << 1U) 
                                                              | ((IData)(vlSelfRef.clk) 
                                                                 != (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0))))))));
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
    if (VL_UNLIKELY(((1U & (~ (IData)(vlSelfRef.__VicoDidInit)))))) {
        vlSelfRef.__VicoDidInit = 1U;
        vlSelfRef.__VicoTriggered[0U] = (1ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (2ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (4ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (8ULL | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000010ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000020ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000040ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000080ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000100ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000200ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000400ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000000800ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000001000ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
        vlSelfRef.__VicoTriggered[0U] = (0x0000000000002000ULL 
                                         | vlSelfRef.__VicoTriggered[0U]);
    }
}

bool VAxiDpiSlave___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 2> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___trigger_anySet__ico\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((2U > n));
    return (0U);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 2> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool VAxiDpiSlave___024root___eval_phase__ico(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_phase__ico\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VicoExecute;
    // Body
    VAxiDpiSlave___024root___eval_triggers_vec__ico(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VAxiDpiSlave___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
    __VicoExecute = VAxiDpiSlave___024root___trigger_anySet__ico(vlSelfRef.__VicoTriggered);
    if (__VicoExecute) {
        {
            // Inlined CFunc: _eval_ico
            if ((0x0000000000000080ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_sequent__TOP__0
                    vlSelfRef.AxiDpiSlave__DOT__aw_fire_w 
                        = ((IData)(vlSelfRef.s_axi_awready_o) 
                           & (IData)(vlSelfRef.s_axi_awvalid_i));
                }
            }
            if ((0x0000000000000400ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_sequent__TOP__1
                    vlSelfRef.AxiDpiSlave__DOT__w_fire_w 
                        = ((IData)(vlSelfRef.s_axi_wready_o) 
                           & (IData)(vlSelfRef.s_axi_wvalid_i));
                }
            }
            if ((0x0000000000000480ULL & vlSelfRef.__VicoTriggered[0U])) {
                {
                    // Inlined CFunc: _ico_comb__TOP__0
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
    return (__VicoExecute);
}

bool VAxiDpiSlave___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___trigger_anySet__act\n"); );
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

void VAxiDpiSlave___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error);
void VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit(QData/*63:0*/ addr, IData/*31:0*/ nbytes, QData/*63:0*/ &data, CData/*0:0*/ &error);
void VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit(QData/*63:0*/ addr, QData/*63:0*/ data, QData/*63:0*/ mask, CData/*0:0*/ &error);

void VAxiDpiSlave___024root___nba_sequent__TOP__0(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___nba_sequent__TOP__0\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    QData/*63:0*/ __Vtask_npc_ifetch_sized__0__data;
    __Vtask_npc_ifetch_sized__0__data = 0;
    CData/*0:0*/ __Vtask_npc_ifetch_sized__0__error;
    __Vtask_npc_ifetch_sized__0__error = 0;
    QData/*63:0*/ __Vtask_npc_mem_read_sized__1__data;
    __Vtask_npc_mem_read_sized__1__data = 0;
    CData/*0:0*/ __Vtask_npc_mem_read_sized__1__error;
    __Vtask_npc_mem_read_sized__1__error = 0;
    CData/*0:0*/ __Vtask_npc_mem_write__2__error;
    __Vtask_npc_mem_write__2__error = 0;
    CData/*0:0*/ __Vdly__s_axi_rvalid_o;
    __Vdly__s_axi_rvalid_o = 0;
    CData/*0:0*/ __Vdly__s_axi_bvalid_o;
    __Vdly__s_axi_bvalid_o = 0;
    QData/*63:0*/ __Vdly__AxiDpiSlave__DOT__awaddr_q;
    __Vdly__AxiDpiSlave__DOT__awaddr_q = 0;
    CData/*2:0*/ __Vdly__AxiDpiSlave__DOT__awsize_q;
    __Vdly__AxiDpiSlave__DOT__awsize_q = 0;
    QData/*63:0*/ __Vdly__AxiDpiSlave__DOT__wdata_q;
    __Vdly__AxiDpiSlave__DOT__wdata_q = 0;
    CData/*7:0*/ __Vdly__AxiDpiSlave__DOT__wstrb_q;
    __Vdly__AxiDpiSlave__DOT__wstrb_q = 0;
    // Body
    __Vdly__AxiDpiSlave__DOT__awaddr_q = vlSelfRef.AxiDpiSlave__DOT__awaddr_q;
    __Vdly__AxiDpiSlave__DOT__awsize_q = vlSelfRef.AxiDpiSlave__DOT__awsize_q;
    __Vdly__AxiDpiSlave__DOT__wdata_q = vlSelfRef.AxiDpiSlave__DOT__wdata_q;
    __Vdly__AxiDpiSlave__DOT__wstrb_q = vlSelfRef.AxiDpiSlave__DOT__wstrb_q;
    __Vdly__s_axi_rvalid_o = vlSelfRef.s_axi_rvalid_o;
    __Vdly__s_axi_bvalid_o = vlSelfRef.s_axi_bvalid_o;
    if (vlSelfRef.rst) {
        __Vdly__s_axi_rvalid_o = 0U;
        vlSelfRef.s_axi_rdata_o = 0ULL;
        vlSelfRef.s_axi_rresp_o = 0U;
        __Vdly__s_axi_bvalid_o = 0U;
        vlSelfRef.s_axi_bresp_o = 0U;
        __Vdly__AxiDpiSlave__DOT__awaddr_q = 0ULL;
        __Vdly__AxiDpiSlave__DOT__awsize_q = 0U;
        vlSelfRef.AxiDpiSlave__DOT__aw_valid_q = 0U;
        __Vdly__AxiDpiSlave__DOT__wdata_q = 0ULL;
        __Vdly__AxiDpiSlave__DOT__wstrb_q = 0U;
        vlSelfRef.AxiDpiSlave__DOT__w_valid_q = 0U;
    } else {
        if (((IData)(vlSelfRef.s_axi_rvalid_o) & (IData)(vlSelfRef.s_axi_rready_i))) {
            __Vdly__s_axi_rvalid_o = 0U;
        }
        if (((IData)(vlSelfRef.s_axi_bvalid_o) & (IData)(vlSelfRef.s_axi_bready_i))) {
            __Vdly__s_axi_bvalid_o = 0U;
        }
        if (((IData)(vlSelfRef.s_axi_arready_o) & (IData)(vlSelfRef.s_axi_arvalid_i))) {
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v 
                = ((3U >= (IData)(vlSelfRef.s_axi_arsize_i))
                    ? ((IData)(1U) << (IData)(vlSelfRef.s_axi_arsize_i))
                    : 0U);
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v = 0ULL;
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v = 0ULL;
            __Vdly__s_axi_rvalid_o = 1U;
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v = 0U;
            if ((((IData)(vlSelfRef.s_axi_arprot_i) 
                  >> 2U) & (0U != vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v))) {
                VAxiDpiSlave___024unit____Vdpiimwrap_npc_ifetch_sized_TOP____024unit(vlSelfRef.s_axi_araddr_i, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v, __Vtask_npc_ifetch_sized__0__data, __Vtask_npc_ifetch_sized__0__error);
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v 
                    = __Vtask_npc_ifetch_sized__0__data;
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v 
                    = __Vtask_npc_ifetch_sized__0__error;
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v 
                    = (0x00000038U & ((IData)(vlSelfRef.s_axi_araddr_i) 
                                      << 3U));
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v 
                    = VL_SHIFTL_QQI(64,64,32, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v);
            } else if (((~ ((IData)(vlSelfRef.s_axi_arprot_i) 
                            >> 2U)) & (0U != vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v))) {
                VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_read_sized_TOP____024unit(vlSelfRef.s_axi_araddr_i, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v, __Vtask_npc_mem_read_sized__1__data, __Vtask_npc_mem_read_sized__1__error);
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v 
                    = __Vtask_npc_mem_read_sized__1__data;
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v 
                    = __Vtask_npc_mem_read_sized__1__error;
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v 
                    = (0x00000038U & ((IData)(vlSelfRef.s_axi_araddr_i) 
                                      << 3U));
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v 
                    = VL_SHIFTL_QQI(64,64,32, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v);
            } else {
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v = 1U;
            }
            vlSelfRef.s_axi_rdata_o = vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v;
            vlSelfRef.s_axi_rresp_o = ((IData)(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v)
                                        ? 2U : 0U);
        }
        if (vlSelfRef.AxiDpiSlave__DOT__aw_fire_w) {
            __Vdly__AxiDpiSlave__DOT__awaddr_q = vlSelfRef.s_axi_awaddr_i;
            __Vdly__AxiDpiSlave__DOT__awsize_q = vlSelfRef.s_axi_awsize_i;
            vlSelfRef.AxiDpiSlave__DOT__aw_valid_q = 1U;
        }
        if (vlSelfRef.AxiDpiSlave__DOT__w_fire_w) {
            __Vdly__AxiDpiSlave__DOT__wdata_q = vlSelfRef.s_axi_wdata_i;
            __Vdly__AxiDpiSlave__DOT__wstrb_q = vlSelfRef.s_axi_wstrb_i;
            vlSelfRef.AxiDpiSlave__DOT__w_valid_q = 1U;
        }
        if (vlSelfRef.AxiDpiSlave__DOT__write_complete_w) {
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v 
                = ((IData)(vlSelfRef.AxiDpiSlave__DOT__aw_fire_w)
                    ? vlSelfRef.s_axi_awaddr_i : vlSelfRef.AxiDpiSlave__DOT__awaddr_q);
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v 
                = ((3U >= ((IData)(vlSelfRef.AxiDpiSlave__DOT__aw_fire_w)
                            ? (IData)(vlSelfRef.s_axi_awsize_i)
                            : (IData)(vlSelfRef.AxiDpiSlave__DOT__awsize_q)))
                    ? ((IData)(1U) << ((IData)(vlSelfRef.AxiDpiSlave__DOT__aw_fire_w)
                                        ? (IData)(vlSelfRef.s_axi_awsize_i)
                                        : (IData)(vlSelfRef.AxiDpiSlave__DOT__awsize_q)))
                    : 0U);
            __Vdly__s_axi_bvalid_o = 1U;
            vlSelfRef.AxiDpiSlave__DOT__aw_valid_q = 0U;
            vlSelfRef.AxiDpiSlave__DOT__w_valid_q = 0U;
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v 
                = (0x00000038U & ((IData)(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v) 
                                  << 3U));
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_data_v 
                = VL_SHIFTR_QQI(64,64,32, ((IData)(vlSelfRef.AxiDpiSlave__DOT__w_fire_w)
                                            ? vlSelfRef.s_axi_wdata_i
                                            : vlSelfRef.AxiDpiSlave__DOT__wdata_q), vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v);
            vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_mask_v 
                = ((QData)((IData)(((IData)(vlSelfRef.AxiDpiSlave__DOT__w_fire_w)
                                     ? (IData)(vlSelfRef.s_axi_wstrb_i)
                                     : (IData)(vlSelfRef.AxiDpiSlave__DOT__wstrb_q)))) 
                   >> (7U & (IData)(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v)));
            if ((((0U == vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v) 
                  | (8U < ((7U & (IData)(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v)) 
                           + vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v))) 
                 | (vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_mask_v 
                    != (VL_SHIFTL_QQI(64,64,32, 1ULL, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v) 
                        - 1ULL)))) {
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v = 1U;
            } else {
                VAxiDpiSlave___024unit____Vdpiimwrap_npc_mem_write_TOP____024unit(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_data_v, vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__write_mask_v, __Vtask_npc_mem_write__2__error);
                vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v 
                    = __Vtask_npc_mem_write__2__error;
            }
            vlSelfRef.s_axi_bresp_o = ((IData)(vlSelfRef.AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v)
                                        ? 2U : 0U);
        }
    }
    vlSelfRef.AxiDpiSlave__DOT__awaddr_q = __Vdly__AxiDpiSlave__DOT__awaddr_q;
    vlSelfRef.AxiDpiSlave__DOT__awsize_q = __Vdly__AxiDpiSlave__DOT__awsize_q;
    vlSelfRef.AxiDpiSlave__DOT__wdata_q = __Vdly__AxiDpiSlave__DOT__wdata_q;
    vlSelfRef.AxiDpiSlave__DOT__wstrb_q = __Vdly__AxiDpiSlave__DOT__wstrb_q;
    vlSelfRef.s_axi_rvalid_o = __Vdly__s_axi_rvalid_o;
    vlSelfRef.s_axi_bvalid_o = __Vdly__s_axi_bvalid_o;
    vlSelfRef.s_axi_arready_o = (1U & (~ (IData)(vlSelfRef.s_axi_rvalid_o)));
    vlSelfRef.s_axi_awready_o = (1U & (~ ((IData)(vlSelfRef.s_axi_bvalid_o) 
                                          | (IData)(vlSelfRef.AxiDpiSlave__DOT__aw_valid_q))));
    vlSelfRef.s_axi_wready_o = (1U & (~ ((IData)(vlSelfRef.s_axi_bvalid_o) 
                                         | (IData)(vlSelfRef.AxiDpiSlave__DOT__w_valid_q))));
    vlSelfRef.AxiDpiSlave__DOT__aw_fire_w = ((IData)(vlSelfRef.s_axi_awready_o) 
                                             & (IData)(vlSelfRef.s_axi_awvalid_i));
    vlSelfRef.AxiDpiSlave__DOT__w_fire_w = ((IData)(vlSelfRef.s_axi_wready_o) 
                                            & (IData)(vlSelfRef.s_axi_wvalid_i));
    vlSelfRef.AxiDpiSlave__DOT__write_complete_w = 
        ((~ (IData)(vlSelfRef.s_axi_bvalid_o)) & (((IData)(vlSelfRef.AxiDpiSlave__DOT__aw_valid_q) 
                                                   | (IData)(vlSelfRef.AxiDpiSlave__DOT__aw_fire_w)) 
                                                  & ((IData)(vlSelfRef.AxiDpiSlave__DOT__w_valid_q) 
                                                     | (IData)(vlSelfRef.AxiDpiSlave__DOT__w_fire_w))));
}

void VAxiDpiSlave___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VAxiDpiSlave___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool VAxiDpiSlave___024root___eval_phase__act(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_phase__act\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        ((IData)(vlSelfRef.clk) 
                                                         & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__1)))));
        vlSelfRef.__Vtrigprevexpr___TOP__clk__1 = vlSelfRef.clk;
    }
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        VAxiDpiSlave___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    VAxiDpiSlave___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    return (0U);
}

void VAxiDpiSlave___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool VAxiDpiSlave___024root___eval_phase__nba(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_phase__nba\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = VAxiDpiSlave___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        {
            // Inlined CFunc: _eval_nba
            if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
                VAxiDpiSlave___024root___nba_sequent__TOP__0(vlSelf);
            }
        }
        VAxiDpiSlave___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void VAxiDpiSlave___024root___eval(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VicoIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            VAxiDpiSlave___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv", 26, "", "DIDNOTCONVERGE: Input combinational region did not converge after '--converge-limit' of 10000 tries");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        vlSelfRef.__VicoPhaseResult = VAxiDpiSlave___024root___eval_phase__ico(vlSelf);
    } while (vlSelfRef.__VicoPhaseResult);
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            VAxiDpiSlave___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv", 26, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 10000 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00002710U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                VAxiDpiSlave___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/sim/AxiDpiSlave.sv", 26, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 10000 tries");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactPhaseResult = VAxiDpiSlave___024root___eval_phase__act(vlSelf);
        } while (vlSelfRef.__VactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = VAxiDpiSlave___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

#ifdef VL_DEBUG
void VAxiDpiSlave___024root___eval_debug_assertions(VAxiDpiSlave___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    VAxiDpiSlave___024root___eval_debug_assertions\n"); );
    VAxiDpiSlave__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");
    }
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_arvalid_i & 0xfeU)))) {
        Verilated::overWidthError("s_axi_arvalid_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_arsize_i & 0xf8U)))) {
        Verilated::overWidthError("s_axi_arsize_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_arprot_i & 0xf8U)))) {
        Verilated::overWidthError("s_axi_arprot_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_rready_i & 0xfeU)))) {
        Verilated::overWidthError("s_axi_rready_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_awvalid_i & 0xfeU)))) {
        Verilated::overWidthError("s_axi_awvalid_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_awsize_i & 0xf8U)))) {
        Verilated::overWidthError("s_axi_awsize_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_wvalid_i & 0xfeU)))) {
        Verilated::overWidthError("s_axi_wvalid_i");
    }
    if (VL_UNLIKELY(((vlSelfRef.s_axi_bready_i & 0xfeU)))) {
        Verilated::overWidthError("s_axi_bready_i");
    }
}
#endif  // VL_DEBUG
