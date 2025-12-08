// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"

VL_ATTR_COLD void Vtop___024root___eval_static(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_static\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clk__0 = vlSelfRef.clk;
    vlSelfRef.__Vtrigprevexpr___TOP__rst__0 = vlSelfRef.rst;
    vlSelfRef.__Vtrigprevexpr___TOP__top__DOT__clk_en__0 
        = vlSelfRef.top__DOT__clk_en;
}

VL_ATTR_COLD void Vtop___024root___eval_initial__TOP(Vtop___024root* vlSelf);

VL_ATTR_COLD void Vtop___024root___eval_initial(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_initial\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtop___024root___eval_initial__TOP(vlSelf);
}

VL_ATTR_COLD void Vtop___024root___eval_initial__TOP(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_initial__TOP\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    VL_READMEM_N(true, 24, 524288, 0, "resource/picture.hex"s
                 ,  &(vlSelfRef.top__DOT__my_vmem__DOT__vga_mem)
                 , 0, ~0ULL);
}

VL_ATTR_COLD void Vtop___024root___eval_final(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_final\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtop___024root___eval_phase__stl(Vtop___024root* vlSelf);

VL_ATTR_COLD void Vtop___024root___eval_settle(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_settle\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("/home/lyg/PA/ysyx-workbench/digital_logic_experiment/e_6/vsrc/top.v", 1, "", "Settle region did not converge after 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
    } while (Vtop___024root___eval_phase__stl(vlSelf));
}

VL_ATTR_COLD void Vtop___024root___eval_triggers__stl(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_triggers__stl\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered
                                      [0U]) | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
    vlSelfRef.__VstlFirstIteration = 0U;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtop___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
}

VL_ATTR_COLD bool Vtop___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vtop___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vtop___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vtop___024root___stl_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___stl_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ top__DOT__my_vga_ctrl__DOT__h_valid;
    top__DOT__my_vga_ctrl__DOT__h_valid = 0;
    CData/*0:0*/ top__DOT__my_vga_ctrl__DOT__v_valid;
    top__DOT__my_vga_ctrl__DOT__v_valid = 0;
    IData/*23:0*/ top__DOT__my_vmem__DOT__vga_data;
    top__DOT__my_vmem__DOT__vga_data = 0;
    // Body
    vlSelfRef.VGA_CLK = vlSelfRef.clk;
    vlSelfRef.top__DOT__clk_en = (1U & (IData)(vlSelfRef.sw));
    vlSelfRef.uart_tx = vlSelfRef.uart_rx;
    vlSelfRef.VGA_HSYNC = (0x0060U < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt));
    vlSelfRef.VGA_VSYNC = (2U < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt));
    vlSelfRef.ledr = (((IData)(vlSelfRef.top__DOT__my_led__DOT__led_r) 
                       << 9U) | (IData)(vlSelfRef.sw));
    top__DOT__my_vga_ctrl__DOT__v_valid = ((0x0023U 
                                            < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt)) 
                                           & (0x0203U 
                                              >= (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt)));
    top__DOT__my_vga_ctrl__DOT__h_valid = ((0x0090U 
                                            < (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt)) 
                                           & (0x0310U 
                                              >= (IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt)));
    vlSelfRef.top__DOT__num = ((0xffffff00U & vlSelfRef.top__DOT__num) 
                               | (IData)(vlSelfRef.top__DOT__my_shift__DOT__data));
    vlSelfRef.VGA_BLANK_N = ((IData)(top__DOT__my_vga_ctrl__DOT__h_valid) 
                             & (IData)(top__DOT__my_vga_ctrl__DOT__v_valid));
    top__DOT__my_vmem__DOT__vga_data = vlSelfRef.top__DOT__my_vmem__DOT__vga_mem
        [((((IData)(top__DOT__my_vga_ctrl__DOT__h_valid)
             ? (0x000003ffU & ((IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__x_cnt) 
                               - (IData)(0x0091U)))
             : 0U) << 9U) | ((IData)(top__DOT__my_vga_ctrl__DOT__v_valid)
                              ? (0x000001ffU & ((IData)(vlSelfRef.top__DOT__my_vga_ctrl__DOT__y_cnt) 
                                                - (IData)(0x0024U)))
                              : 0U))];
    if (vlSelfRef.top__DOT__my_seg__DOT__out) {
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (vlSelfRef.top__DOT__num 
                                                    >> 0x0000001cU))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (vlSelfRef.top__DOT__num 
                                                       >> 0x0000001cU))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (vlSelfRef.top__DOT__num 
                                                          >> 0x0000001cU))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (vlSelfRef.top__DOT__num 
                                                             >> 0x0000001cU))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (vlSelfRef.top__DOT__num 
                                                        >> 0x0000001cU))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (vlSelfRef.top__DOT__num 
                                                             >> 0x0000001cU))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (vlSelfRef.top__DOT__num 
                                                                >> 0x0000001cU))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (vlSelfRef.top__DOT__num 
                                                                   >> 0x0000001cU))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (vlSelfRef.top__DOT__num 
                                                                      >> 0x0000001cU))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (vlSelfRef.top__DOT__num 
                                                                         >> 0x0000001cU))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (vlSelfRef.top__DOT__num 
                                                                            >> 0x0000001cU))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (vlSelfRef.top__DOT__num 
                                                                               >> 0x0000001cU))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000001cU))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000001cU))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000001cU))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000001cU)))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 0x00000018U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 0x00000018U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 0x00000018U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000018U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 0x00000018U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000018U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 0x00000018U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 0x00000018U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 0x00000018U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 0x00000018U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 0x00000018U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000018U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000018U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000018U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000018U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000018U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 0x00000014U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 0x00000014U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 0x00000014U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000014U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 0x00000014U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000014U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 0x00000014U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 0x00000014U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 0x00000014U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 0x00000014U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 0x00000014U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000014U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000014U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000014U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000014U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000014U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 0x00000010U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 0x00000010U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 0x00000010U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000010U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 0x00000010U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x00000010U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 0x00000010U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 0x00000010U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 0x00000010U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 0x00000010U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 0x00000010U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000010U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000010U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000010U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000010U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x00000010U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 0x0000000cU)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 0x0000000cU)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 0x0000000cU)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x0000000cU)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 0x0000000cU)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 0x0000000cU)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 0x0000000cU)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 0x0000000cU)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 0x0000000cU)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 0x0000000cU)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 0x0000000cU)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000000cU)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000000cU)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000000cU)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000000cU)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 0x0000000cU))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 8U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 8U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 8U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 8U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 8U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 8U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 8U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 8U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 8U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 8U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 8U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 8U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 8U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 8U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 8U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 8U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & (vlSelfRef.top__DOT__num 
                                                       >> 4U)))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & (vlSelfRef.top__DOT__num 
                                                          >> 4U)))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & (vlSelfRef.top__DOT__num 
                                                             >> 4U)))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 4U)))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & (vlSelfRef.top__DOT__num 
                                                           >> 4U)))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & (vlSelfRef.top__DOT__num 
                                                                >> 4U)))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & (vlSelfRef.top__DOT__num 
                                                                   >> 4U)))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & (vlSelfRef.top__DOT__num 
                                                                      >> 4U)))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & (vlSelfRef.top__DOT__num 
                                                                         >> 4U)))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & (vlSelfRef.top__DOT__num 
                                                                            >> 4U)))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & (vlSelfRef.top__DOT__num 
                                                                               >> 4U)))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & (vlSelfRef.top__DOT__num 
                                                                                >> 4U)))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 4U)))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 4U)))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 4U)))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & (vlSelfRef.top__DOT__num 
                                                                                >> 4U))))))))))))))))))))));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0 
            = (0x000000ffU & ((0x8eU & (- (IData)((0x0fU 
                                                   == 
                                                   (0x0000000fU 
                                                    & vlSelfRef.top__DOT__num))))) 
                              | ((0x9eU & (- (IData)(
                                                     (0x0eU 
                                                      == 
                                                      (0x0000000fU 
                                                       & vlSelfRef.top__DOT__num))))) 
                                 | ((0x7aU & (- (IData)(
                                                        (0x0dU 
                                                         == 
                                                         (0x0000000fU 
                                                          & vlSelfRef.top__DOT__num))))) 
                                    | ((0x9cU & (- (IData)(
                                                           (0x0cU 
                                                            == 
                                                            (0x0000000fU 
                                                             & vlSelfRef.top__DOT__num))))) 
                                       | ((0x3eU & 
                                           (- (IData)(
                                                      (0x0bU 
                                                       == 
                                                       (0x0000000fU 
                                                        & vlSelfRef.top__DOT__num))))) 
                                          | ((0xeeU 
                                              & (- (IData)(
                                                           (0x0aU 
                                                            == 
                                                            (0x0000000fU 
                                                             & vlSelfRef.top__DOT__num))))) 
                                             | ((0xf6U 
                                                 & (- (IData)(
                                                              (9U 
                                                               == 
                                                               (0x0000000fU 
                                                                & vlSelfRef.top__DOT__num))))) 
                                                | ((0xfeU 
                                                    & (- (IData)(
                                                                 (8U 
                                                                  == 
                                                                  (0x0000000fU 
                                                                   & vlSelfRef.top__DOT__num))))) 
                                                   | ((0xe0U 
                                                       & (- (IData)(
                                                                    (7U 
                                                                     == 
                                                                     (0x0000000fU 
                                                                      & vlSelfRef.top__DOT__num))))) 
                                                      | ((0xbeU 
                                                          & (- (IData)(
                                                                       (6U 
                                                                        == 
                                                                        (0x0000000fU 
                                                                         & vlSelfRef.top__DOT__num))))) 
                                                         | ((0xb6U 
                                                             & (- (IData)(
                                                                          (5U 
                                                                           == 
                                                                           (0x0000000fU 
                                                                            & vlSelfRef.top__DOT__num))))) 
                                                            | ((0x66U 
                                                                & (- (IData)(
                                                                             (4U 
                                                                              == 
                                                                              (0x0000000fU 
                                                                               & vlSelfRef.top__DOT__num))))) 
                                                               | ((0xf2U 
                                                                   & (- (IData)(
                                                                                (3U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__num))))) 
                                                                  | ((0xdaU 
                                                                      & (- (IData)(
                                                                                (2U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__num))))) 
                                                                     | ((0x60U 
                                                                         & (- (IData)(
                                                                                (1U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__num))))) 
                                                                        | (0xfcU 
                                                                           & (- (IData)(
                                                                                (0U 
                                                                                == 
                                                                                (0x0000000fU 
                                                                                & vlSelfRef.top__DOT__num)))))))))))))))))))));
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
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000018U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 0x00000010U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1 
            = (0x000000ffU & (IData)((vlSelfRef.top__DOT__my_seg__DOT__seg_buffer 
                                      >> 8U)));
        vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0 
            = (0x000000ffU & (IData)(vlSelfRef.top__DOT__my_seg__DOT__seg_buffer));
    }
    vlSelfRef.VGA_R = (0x000000ffU & (top__DOT__my_vmem__DOT__vga_data 
                                      >> 0x00000010U));
    vlSelfRef.VGA_G = (0x000000ffU & (top__DOT__my_vmem__DOT__vga_data 
                                      >> 8U));
    vlSelfRef.VGA_B = (0x000000ffU & top__DOT__my_vmem__DOT__vga_data);
    if ((0x00000100U & (IData)(vlSelfRef.sw))) {
        vlSelfRef.seg7 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7)));
        vlSelfRef.seg6 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6)));
        vlSelfRef.seg5 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5)));
        vlSelfRef.seg4 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4)));
        vlSelfRef.seg3 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3)));
        vlSelfRef.seg2 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2)));
        vlSelfRef.seg1 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1)));
        vlSelfRef.seg0 = (0x000000ffU & (~ (IData)(vlSelfRef.top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0)));
    } else {
        vlSelfRef.seg7 = 0x000000ffU;
        vlSelfRef.seg6 = 0x000000ffU;
        vlSelfRef.seg5 = 0x000000ffU;
        vlSelfRef.seg4 = 0x000000ffU;
        vlSelfRef.seg3 = 0x000000ffU;
        vlSelfRef.seg2 = 0x000000ffU;
        vlSelfRef.seg1 = 0x000000ffU;
        vlSelfRef.seg0 = 0x000000ffU;
    }
}

VL_ATTR_COLD void Vtop___024root___eval_stl(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_stl\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
        Vtop___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD bool Vtop___024root___eval_phase__stl(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__stl\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtop___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = Vtop___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vtop___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vtop___024root___trigger_anySet__ico(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(Vtop___024root___trigger_anySet__ico(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

bool Vtop___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtop___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(posedge rst)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @(posedge top.clk_en)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ctor_var_reset\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clk = 0;
    vlSelf->rst = 0;
    vlSelf->btn = 0;
    vlSelf->sw = 0;
    vlSelf->ps2_clk = 0;
    vlSelf->ps2_data = 0;
    vlSelf->uart_rx = 0;
    vlSelf->uart_tx = 0;
    vlSelf->ledr = 0;
    vlSelf->VGA_CLK = 0;
    vlSelf->VGA_HSYNC = 0;
    vlSelf->VGA_VSYNC = 0;
    vlSelf->VGA_BLANK_N = 0;
    vlSelf->VGA_R = 0;
    vlSelf->VGA_G = 0;
    vlSelf->VGA_B = 0;
    vlSelf->seg0 = 0;
    vlSelf->seg1 = 0;
    vlSelf->seg2 = 0;
    vlSelf->seg3 = 0;
    vlSelf->seg4 = 0;
    vlSelf->seg5 = 0;
    vlSelf->seg6 = 0;
    vlSelf->seg7 = 0;
    vlSelf->top__DOT__num = 0;
    vlSelf->top__DOT__clk_en = 0;
    vlSelf->top__DOT__my_led__DOT__count = 0;
    vlSelf->top__DOT__my_led__DOT__led_r = 0;
    vlSelf->top__DOT__my_vga_ctrl__DOT__x_cnt = 0;
    vlSelf->top__DOT__my_vga_ctrl__DOT__y_cnt = 0;
    vlSelf->top__DOT__my_keyboard__DOT____Vlvbound_h07ab4076__0 = 0;
    vlSelf->top__DOT__my_keyboard__DOT__buffer = 0;
    vlSelf->top__DOT__my_keyboard__DOT__count = 0;
    vlSelf->top__DOT__my_keyboard__DOT__ps2_clk_sync = 0;
    vlSelf->top__DOT__my_seg__DOT__out = 0;
    vlSelf->top__DOT__my_seg__DOT__count = 0;
    vlSelf->top__DOT__my_seg__DOT__seg_buffer = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6 = 0;
    vlSelf->top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7 = 0;
    vlSelf->top__DOT__my_shift__DOT__data = 0;
    for (int __Vi0 = 0; __Vi0 < 524288; ++__Vi0) {
        vlSelf->top__DOT__my_vmem__DOT__vga_mem[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VicoTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__rst__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__top__DOT__clk_en__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
}
