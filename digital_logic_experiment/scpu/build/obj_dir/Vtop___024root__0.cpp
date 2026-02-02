// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

void Vtop___024root___eval_triggers__ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_triggers__ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VicoTriggered
                                      [0U]) | (IData)((IData)(vlSelfRef.__VicoFirstIteration)));
    vlSelfRef.__VicoFirstIteration = 0U;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtop___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
    }
#endif
}

bool Vtop___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_anySet__ico\n"); );
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

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ico_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8;
    top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8 = 0;
    // Body
    vlSelfRef.VGA_CLK = vlSelfRef.clk;
    vlSelfRef.uart_tx = vlSelfRef.uart_rx;
    vlSelfRef.ledr = (((IData)(vlSelfRef.top__DOT__my_led__DOT__led_r) 
                       << 9U) | (IData)(vlSelfRef.sw));
    if ((0x00000100U & (IData)(vlSelfRef.sw))) {
        vlSelfRef.seg6 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6)));
        vlSelfRef.seg7 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7)));
    } else {
        vlSelfRef.seg6 = 0x000000ffU;
        vlSelfRef.seg7 = 0x000000ffU;
    }
    top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8 
        = (((IData)(vlSelfRef.sw) >> 8U) & (0U != (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)));
    if (top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8) {
        vlSelfRef.seg0 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0)));
        vlSelfRef.seg1 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1)));
        vlSelfRef.seg2 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2)));
        vlSelfRef.seg3 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3)));
        vlSelfRef.seg4 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4)));
        vlSelfRef.seg5 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5)));
    } else {
        vlSelfRef.seg0 = 0x000000ffU;
        vlSelfRef.seg1 = 0x000000ffU;
        vlSelfRef.seg2 = 0x000000ffU;
        vlSelfRef.seg3 = 0x000000ffU;
        vlSelfRef.seg4 = 0x000000ffU;
        vlSelfRef.seg5 = 0x000000ffU;
    }
}

void Vtop___024root___eval_ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered[0U])) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

bool Vtop___024root___eval_phase__ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = Vtop___024root___trigger_anySet__ico(vlSelfRef.__VicoTriggered);
    if (__VicoExecute) {
        Vtop___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_triggers__act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((IData)(vlSelfRef.clk) 
                                                     & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtop___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
}

bool Vtop___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_anySet__act\n"); );
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

extern const VlUnpacked<CData/*7:0*/, 256> Vtop__ConstPool__TABLE_ha70c9a6b_0;

void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*7:0*/ top__DOT__ascii;
    top__DOT__ascii = 0;
    CData/*0:0*/ top__DOT__my_vga_ctrl__DOT__h_valid;
    top__DOT__my_vga_ctrl__DOT__h_valid = 0;
    CData/*0:0*/ top__DOT__my_vga_ctrl__DOT__v_valid;
    top__DOT__my_vga_ctrl__DOT__v_valid = 0;
    CData/*0:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8;
    top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8 = 0;
    IData/*23:0*/ top__DOT__my_vmem__DOT__vga_data;
    top__DOT__my_vmem__DOT__vga_data = 0;
    CData/*7:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    IData/*31:0*/ __Vdly__top__DOT__my_scpu__DOT__pc;
    __Vdly__top__DOT__my_scpu__DOT__pc = 0;
    CData/*6:0*/ __Vdly__top__DOT__my_led__DOT__led_r;
    __Vdly__top__DOT__my_led__DOT__led_r = 0;
    IData/*31:0*/ __Vdly__top__DOT__my_led__DOT__count;
    __Vdly__top__DOT__my_led__DOT__count = 0;
    SData/*9:0*/ __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt;
    __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt = 0;
    SData/*9:0*/ __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt;
    __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt = 0;
    CData/*2:0*/ __Vdly__top__DOT__my_keyboard__DOT__ps2_clk_sync;
    __Vdly__top__DOT__my_keyboard__DOT__ps2_clk_sync = 0;
    CData/*3:0*/ __Vdly__top__DOT__my_keyboard__DOT__count;
    __Vdly__top__DOT__my_keyboard__DOT__count = 0;
    CData/*0:0*/ __Vdly__top__DOT__my_keyboard__DOT__is_break;
    __Vdly__top__DOT__my_keyboard__DOT__is_break = 0;
    CData/*7:0*/ __Vdly__top__DOT__my_keyboard__DOT__data_counter;
    __Vdly__top__DOT__my_keyboard__DOT__data_counter = 0;
    QData/*35:0*/ __Vdly__top__DOT__my_seg__DOT__count;
    __Vdly__top__DOT__my_seg__DOT__count = 0;
    CData/*0:0*/ __Vdly__top__DOT__my_seg__DOT__out;
    __Vdly__top__DOT__my_seg__DOT__out = 0;
    IData/*31:0*/ __VdlyVal__top__DOT__my_scpu__DOT__r__v0;
    __VdlyVal__top__DOT__my_scpu__DOT__r__v0 = 0;
    CData/*3:0*/ __VdlyDim0__top__DOT__my_scpu__DOT__r__v0;
    __VdlyDim0__top__DOT__my_scpu__DOT__r__v0 = 0;
    CData/*0:0*/ __VdlySet__top__DOT__my_scpu__DOT__r__v0;
    __VdlySet__top__DOT__my_scpu__DOT__r__v0 = 0;
    // Body
    __Vdly__top__DOT__my_keyboard__DOT__ps2_clk_sync 
        = vlSelfRef.top__DOT__my_keyboard__DOT__ps2_clk_sync;
    __Vdly__top__DOT__my_scpu__DOT__pc = vlSelfRef.top__DOT__my_scpu__DOT__pc;
    __Vdly__top__DOT__my_led__DOT__count = vlSelfRef.top__DOT__my_led__DOT__count;
    __Vdly__top__DOT__my_led__DOT__led_r = vlSelfRef.top__DOT__my_led__DOT__led_r;
    __VdlySet__top__DOT__my_scpu__DOT__r__v0 = 0U;
    __Vdly__top__DOT__my_seg__DOT__count = vlSelfRef.top__DOT__my_seg__DOT__count;
    __Vdly__top__DOT__my_keyboard__DOT__count = vlSelfRef.top__DOT__my_keyboard__DOT__count;
    __Vdly__top__DOT__my_keyboard__DOT__is_break = vlSelfRef.top__DOT__my_keyboard__DOT__is_break;
    __Vdly__top__DOT__my_keyboard__DOT__data_counter 
        = vlSelfRef.top__DOT__my_keyboard__DOT__data_counter;
    __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt = vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt;
    __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt = vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt;
    __Vdly__top__DOT__my_seg__DOT__out = vlSelfRef.top__DOT__my_seg__DOT__out;
    __Vdly__top__DOT__my_keyboard__DOT__ps2_clk_sync 
        = ((6U & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_clk_sync) 
                  << 1U)) | (IData)(vlSelfRef.ps2_clk));
    if ((1U & (~ (IData)(vlSelfRef.rst)))) {
        if ((3U == (IData)(vlSelfRef.top__DOT__my_scpu__DOT__type_in))) {
            __VdlyVal__top__DOT__my_scpu__DOT__r__v0 
                = (vlSelfRef.top__DOT__my_scpu__DOT__r
                   [(0x0000000fU & (vlSelfRef.top__DOT__my_scpu__DOT__inst_reg 
                                    >> 0x0000000fU))] 
                   + (((- (IData)((vlSelfRef.top__DOT__my_scpu__DOT__inst_reg 
                                   >> 0x0000001fU))) 
                       << 0x0000000cU) | (vlSelfRef.top__DOT__my_scpu__DOT__inst_reg 
                                          >> 0x00000014U)));
            __VdlyDim0__top__DOT__my_scpu__DOT__r__v0 
                = (0x0000000fU & (vlSelfRef.top__DOT__my_scpu__DOT__inst_reg 
                                  >> 7U));
            __VdlySet__top__DOT__my_scpu__DOT__r__v0 = 1U;
        }
        if ((2U == (IData)(vlSelfRef.top__DOT__my_scpu__DOT__type_in))) {
            vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                = vlSelfRef.top__DOT__my_scpu__DOT__r
                [1U];
        }
    }
    if (vlSelfRef.rst) {
        __Vdly__top__DOT__my_led__DOT__led_r = 1U;
        __Vdly__top__DOT__my_led__DOT__count = 0U;
        __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt = 1U;
        __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt = 1U;
        __Vdly__top__DOT__my_seg__DOT__count = 0ULL;
        __Vdly__top__DOT__my_seg__DOT__out = 0U;
        __Vdly__top__DOT__my_keyboard__DOT__count = 0U;
        vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg = 0U;
        __Vdly__top__DOT__my_keyboard__DOT__is_break = 0U;
        __Vdly__top__DOT__my_keyboard__DOT__data_counter = 0U;
        __Vdly__top__DOT__my_scpu__DOT__pc = 0U;
        vlSelfRef.top__DOT__my_scpu__DOT__inst_reg = 0U;
    } else {
        if ((0U == vlSelfRef.top__DOT__my_led__DOT__count)) {
            __Vdly__top__DOT__my_led__DOT__led_r = 
                ((0x0000007eU & ((IData)(vlSelfRef.top__DOT__my_led__DOT__led_r) 
                                 << 1U)) | (1U & ((IData)(vlSelfRef.top__DOT__my_led__DOT__led_r) 
                                                  >> 6U)));
        }
        __Vdly__top__DOT__my_led__DOT__count = ((0x004c4b40U 
                                                 <= vlSelfRef.top__DOT__my_led__DOT__count)
                                                 ? 0U
                                                 : 
                                                ((IData)(1U) 
                                                 + vlSelfRef.top__DOT__my_led__DOT__count));
        if ((0x0320U == (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt))) {
            __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt 
                = ((0x020dU == (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt))
                    ? 1U : (0x000003ffU & ((IData)(1U) 
                                           + (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt))));
            __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt = 1U;
        } else {
            __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt 
                = (0x000003ffU & ((IData)(1U) + (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt)));
        }
        if ((0x00000000004c4b40ULL == vlSelfRef.top__DOT__my_seg__DOT__count)) {
            __Vdly__top__DOT__my_seg__DOT__out = (1U 
                                                  & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT__out)));
            __Vdly__top__DOT__my_seg__DOT__count = 0ULL;
        } else {
            __Vdly__top__DOT__my_seg__DOT__count = 
                (0x0000000fffffffffULL & (1ULL + vlSelfRef.top__DOT__my_seg__DOT__count));
        }
        if ((IData)((4U == (6U & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_clk_sync))))) {
            if ((0x0aU == (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__count))) {
                if ((((~ (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__buffer)) 
                      & (IData)(vlSelfRef.ps2_data)) 
                     & VL_REDXOR_32((0x000001ffU & 
                                     ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__buffer) 
                                      >> 1U))))) {
                    if ((0xf0U == (0x000000ffU & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__buffer) 
                                                  >> 1U)))) {
                        __Vdly__top__DOT__my_keyboard__DOT__data_counter 
                            = (0x000000ffU & ((IData)(1U) 
                                              + (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)));
                        __Vdly__top__DOT__my_keyboard__DOT__is_break = 1U;
                    } else if (vlSelfRef.top__DOT__my_keyboard__DOT__is_break) {
                        vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg = 0U;
                        __Vdly__top__DOT__my_keyboard__DOT__is_break = 0U;
                    } else {
                        vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg 
                            = (0x000000ffU & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__buffer) 
                                              >> 1U));
                    }
                }
                __Vdly__top__DOT__my_keyboard__DOT__count = 0U;
            } else {
                vlSelfRef.top__DOT__my_keyboard__DOT____Vlvbound_h07ab4076__0 
                    = vlSelfRef.ps2_data;
                if ((9U >= (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__count))) {
                    vlSelfRef.top__DOT__my_keyboard__DOT__buffer 
                        = (((~ ((IData)(1U) << (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__count))) 
                            & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__buffer)) 
                           | (0x03ffU & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT____Vlvbound_h07ab4076__0) 
                                         << (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__count))));
                }
                __Vdly__top__DOT__my_keyboard__DOT__count 
                    = (0x0000000fU & ((IData)(1U) + (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__count)));
            }
        }
        if (VL_LTS_III(32, 0x0000000aU, vlSelfRef.top__DOT__my_scpu__DOT__pc)) {
            __Vdly__top__DOT__my_scpu__DOT__pc = 0U;
        } else if ((0x00000100U & (IData)(vlSelfRef.sw))) {
            __Vdly__top__DOT__my_scpu__DOT__pc = ((IData)(1U) 
                                                  + vlSelfRef.top__DOT__my_scpu__DOT__pc);
        }
        vlSelfRef.top__DOT__my_scpu__DOT__inst_reg 
            = ((0x0aU >= (0x0000000fU & vlSelfRef.top__DOT__my_scpu__DOT__pc))
                ? vlSelfRef.top__DOT__my_scpu__DOT__rom
               [(0x0000000fU & vlSelfRef.top__DOT__my_scpu__DOT__pc)]
                : 0U);
    }
    vlSelfRef.top__DOT__my_seg__DOT__seg_buffer = (
                                                   ((QData)((IData)(
                                                                    ((((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7) 
                                                                       << 0x00000018U) 
                                                                      | ((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6) 
                                                                         << 0x00000010U)) 
                                                                     | (((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5) 
                                                                         << 8U) 
                                                                        | (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4))))) 
                                                    << 0x00000020U) 
                                                   | (QData)((IData)(
                                                                     ((((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3) 
                                                                        << 0x00000018U) 
                                                                       | ((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2) 
                                                                          << 0x00000010U)) 
                                                                      | (((IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1) 
                                                                          << 8U) 
                                                                         | (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0))))));
    vlSelfRef.top__DOT__my_led__DOT__count = __Vdly__top__DOT__my_led__DOT__count;
    vlSelfRef.top__DOT__my_led__DOT__led_r = __Vdly__top__DOT__my_led__DOT__led_r;
    vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt = __Vdly__top__DOT__my_vga_ctrl__DOT__x_cnt;
    vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt = __Vdly__top__DOT__my_vga_ctrl__DOT__y_cnt;
    vlSelfRef.top__DOT__my_seg__DOT__count = __Vdly__top__DOT__my_seg__DOT__count;
    vlSelfRef.top__DOT__my_seg__DOT__out = __Vdly__top__DOT__my_seg__DOT__out;
    if (__VdlySet__top__DOT__my_scpu__DOT__r__v0) {
        vlSelfRef.top__DOT__my_scpu__DOT__r[__VdlyDim0__top__DOT__my_scpu__DOT__r__v0] 
            = __VdlyVal__top__DOT__my_scpu__DOT__r__v0;
    }
    vlSelfRef.top__DOT__my_keyboard__DOT__count = __Vdly__top__DOT__my_keyboard__DOT__count;
    vlSelfRef.top__DOT__my_keyboard__DOT__is_break 
        = __Vdly__top__DOT__my_keyboard__DOT__is_break;
    vlSelfRef.top__DOT__my_keyboard__DOT__ps2_clk_sync 
        = __Vdly__top__DOT__my_keyboard__DOT__ps2_clk_sync;
    vlSelfRef.top__DOT__my_keyboard__DOT__data_counter 
        = __Vdly__top__DOT__my_keyboard__DOT__data_counter;
    vlSelfRef.ledr = (((IData)(vlSelfRef.top__DOT__my_led__DOT__led_r) 
                       << 9U) | (IData)(vlSelfRef.sw));
    vlSelfRef.VGA_HSYNC = (0x0060U < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt));
    top__DOT__my_vga_ctrl__DOT__h_valid = ((0x0090U 
                                            < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt)) 
                                           & (0x0310U 
                                              >= (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt)));
    vlSelfRef.VGA_VSYNC = (2U < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt));
    top__DOT__my_vga_ctrl__DOT__v_valid = ((0x0023U 
                                            < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt)) 
                                           & (0x0203U 
                                              >= (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt)));
    __Vtableidx1 = vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg;
    top__DOT__ascii = Vtop__ConstPool__TABLE_ha70c9a6b_0
        [__Vtableidx1];
    if (vlSelfRef.top__DOT__my_seg__DOT__out) {
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                       >> 4U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                          >> 4U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                             >> 4U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                >> 4U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                           >> 4U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                >> 4U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                   >> 4U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                      >> 4U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                         >> 4U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                            >> 4U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                               >> 4U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                                >> 4U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                                >> 4U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                                >> 4U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                                >> 4U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__my_scpu__DOT__data_reg 
                                                                                >> 4U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__my_scpu__DOT__data_reg))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__my_scpu__DOT__data_reg)))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                       >> 4U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                          >> 4U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                             >> 4U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                >> 4U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                           >> 4U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                >> 4U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                   >> 4U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                      >> 4U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                         >> 4U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                            >> 4U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                               >> 4U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                                >> 4U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                                >> 4U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                                >> 4U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                                >> 4U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter) 
                                                                                >> 4U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__data_counter))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                       >> 4U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                          >> 4U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                             >> 4U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                >> 4U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                           >> 4U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                >> 4U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                   >> 4U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                      >> 4U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                         >> 4U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                            >> 4U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                               >> 4U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                                >> 4U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                                >> 4U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                                >> 4U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                                >> 4U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg) 
                                                                                >> 4U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & ((IData)(top__DOT__ascii) 
                                                       >> 4U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & ((IData)(top__DOT__ascii) 
                                                          >> 4U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & ((IData)(top__DOT__ascii) 
                                                             >> 4U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(top__DOT__ascii) 
                                                                >> 4U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & ((IData)(top__DOT__ascii) 
                                                           >> 4U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & ((IData)(top__DOT__ascii) 
                                                                >> 4U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & ((IData)(top__DOT__ascii) 
                                                                   >> 4U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & ((IData)(top__DOT__ascii) 
                                                                      >> 4U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & ((IData)(top__DOT__ascii) 
                                                                         >> 4U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & ((IData)(top__DOT__ascii) 
                                                                            >> 4U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & ((IData)(top__DOT__ascii) 
                                                                               >> 4U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & ((IData)(top__DOT__ascii) 
                                                                                >> 4U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(top__DOT__ascii) 
                                                                                >> 4U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(top__DOT__ascii) 
                                                                                >> 4U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(top__DOT__ascii) 
                                                                                >> 4U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & ((IData)(top__DOT__ascii) 
                                                                                >> 4U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (IData)(top__DOT__ascii)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (IData)(top__DOT__ascii)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (IData)(top__DOT__ascii)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(top__DOT__ascii)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (IData)(top__DOT__ascii)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (IData)(top__DOT__ascii)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (IData)(top__DOT__ascii)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (IData)(top__DOT__ascii)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (IData)(top__DOT__ascii)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (IData)(top__DOT__ascii)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (IData)(top__DOT__ascii)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (IData)(top__DOT__ascii)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(top__DOT__ascii)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(top__DOT__ascii)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(top__DOT__ascii)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (IData)(top__DOT__ascii))))))))))))))))))))));
    } else {
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000038U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000030U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000028U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000020U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 8U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0 
            = (0x000000ffU & (IData)(vlSelfRef.top__DOT__my_seg__DOT__seg_buffer));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000018U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000010U)));
    }
    top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8 
        = (((IData)(vlSelfRef.sw) >> 8U) & (0U != (IData)(vlSelfRef.top__DOT__my_keyboard__DOT__ps2_data_out_reg)));
    vlSelfRef.VGA_BLANK_N = ((IData)(top__DOT__my_vga_ctrl__DOT__h_valid) 
                             & (IData)(top__DOT__my_vga_ctrl__DOT__v_valid));
    top__DOT__my_vmem__DOT__vga_data = vlSelfRef.top__DOT__my_vmem__DOT__vga_mem
        [(0x0007ffffU & (((IData)(0x00000280U) * ((IData)(top__DOT__my_vga_ctrl__DOT__v_valid)
                                                   ? 
                                                  (0x000001ffU 
                                                   & ((IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt) 
                                                      - (IData)(0x0024U)))
                                                   : 0U)) 
                         + ((IData)(top__DOT__my_vga_ctrl__DOT__h_valid)
                             ? (0x000003ffU & ((IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt) 
                                               - (IData)(0x0091U)))
                             : 0U)))];
    vlSelfRef.top__DOT__my_scpu__DOT__pc = __Vdly__top__DOT__my_scpu__DOT__pc;
    if ((0x00000100U & (IData)(vlSelfRef.sw))) {
        vlSelfRef.seg7 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7)));
        vlSelfRef.seg6 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6)));
    } else {
        vlSelfRef.seg7 = 0x000000ffU;
        vlSelfRef.seg6 = 0x000000ffU;
    }
    if (top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_8) {
        vlSelfRef.seg0 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0)));
        vlSelfRef.seg1 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1)));
        vlSelfRef.seg4 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4)));
        vlSelfRef.seg5 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5)));
        vlSelfRef.seg3 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3)));
        vlSelfRef.seg2 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2)));
    } else {
        vlSelfRef.seg0 = 0x000000ffU;
        vlSelfRef.seg1 = 0x000000ffU;
        vlSelfRef.seg4 = 0x000000ffU;
        vlSelfRef.seg5 = 0x000000ffU;
        vlSelfRef.seg3 = 0x000000ffU;
        vlSelfRef.seg2 = 0x000000ffU;
    }
    vlSelfRef.VGA_R = (0x000000ffU & (top__DOT__my_vmem__DOT__vga_data 
                                      >> 0x00000010U));
    vlSelfRef.VGA_G = (0x000000ffU & (top__DOT__my_vmem__DOT__vga_data 
                                      >> 8U));
    vlSelfRef.VGA_B = (0x000000ffU & top__DOT__my_vmem__DOT__vga_data);
    vlSelfRef.top__DOT__my_scpu__DOT__type_in = ((IData)(
                                                         (0x00000013U 
                                                          == 
                                                          (0x0000707fU 
                                                           & vlSelfRef.top__DOT__my_scpu__DOT__inst_reg)))
                                                  ? 3U
                                                  : 
                                                 ((IData)(
                                                          (0U 
                                                           == 
                                                           (0x0000707fU 
                                                            & vlSelfRef.top__DOT__my_scpu__DOT__inst_reg)))
                                                   ? 2U
                                                   : 0U));
}

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vtop___024root___trigger_orInto__act(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_orInto__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtop___024root___eval_phase__act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtop___024root___eval_triggers__act(vlSelf);
    Vtop___024root___trigger_orInto__act(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    return (0U);
}

void Vtop___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtop___024root___eval_phase__nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtop___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vtop___024root___eval_nba(vlSelf);
        Vtop___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__ico(vlSelfRef.__VicoTriggered, "ico"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/digital_logic_experiment/scpu/vsrc/top.v", 1, "", "Input combinational region did not converge after 100 tries");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
    } while (Vtop___024root___eval_phase__ico(vlSelf));
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/digital_logic_experiment/scpu/vsrc/top.v", 1, "", "NBA region did not converge after 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/digital_logic_experiment/scpu/vsrc/top.v", 1, "", "Active region did not converge after 100 tries");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
        } while (Vtop___024root___eval_phase__act(vlSelf));
    } while (Vtop___024root___eval_phase__nba(vlSelf));
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");
    }
    if (VL_UNLIKELY(((vlSelfRef.rst & 0xfeU)))) {
        Verilated::overWidthError("rst");
    }
    if (VL_UNLIKELY(((vlSelfRef.btn & 0xe0U)))) {
        Verilated::overWidthError("btn");
    }
    if (VL_UNLIKELY(((vlSelfRef.sw & 0xfe00U)))) {
        Verilated::overWidthError("sw");
    }
    if (VL_UNLIKELY(((vlSelfRef.ps2_clk & 0xfeU)))) {
        Verilated::overWidthError("ps2_clk");
    }
    if (VL_UNLIKELY(((vlSelfRef.ps2_data & 0xfeU)))) {
        Verilated::overWidthError("ps2_data");
    }
    if (VL_UNLIKELY(((vlSelfRef.uart_rx & 0xfeU)))) {
        Verilated::overWidthError("uart_rx");
    }
}
#endif  // VL_DEBUG
