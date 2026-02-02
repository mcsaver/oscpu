// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(btn,4,0);
    VL_IN8(ps2_clk,0,0);
    VL_IN8(ps2_data,0,0);
    VL_IN8(uart_rx,0,0);
    VL_OUT8(uart_tx,0,0);
    VL_OUT8(VGA_CLK,0,0);
    VL_OUT8(VGA_HSYNC,0,0);
    VL_OUT8(VGA_VSYNC,0,0);
    VL_OUT8(VGA_BLANK_N,0,0);
    VL_OUT8(VGA_R,7,0);
    VL_OUT8(VGA_G,7,0);
    VL_OUT8(VGA_B,7,0);
    VL_OUT8(seg0,7,0);
    VL_OUT8(seg1,7,0);
    VL_OUT8(seg2,7,0);
    VL_OUT8(seg3,7,0);
    VL_OUT8(seg4,7,0);
    VL_OUT8(seg5,7,0);
    VL_OUT8(seg6,7,0);
    VL_OUT8(seg7,7,0);
    CData/*1:0*/ top__DOT__my_scpu__DOT__type_in;
    CData/*6:0*/ top__DOT__my_led__DOT__led_r;
    CData/*0:0*/ top__DOT__my_keyboard__DOT____Vlvbound_h07ab4076__0;
    CData/*3:0*/ top__DOT__my_keyboard__DOT__count;
    CData/*2:0*/ top__DOT__my_keyboard__DOT__ps2_clk_sync;
    CData/*7:0*/ top__DOT__my_keyboard__DOT__ps2_data_out_reg;
    CData/*0:0*/ top__DOT__my_keyboard__DOT__is_break;
    CData/*7:0*/ top__DOT__my_keyboard__DOT__data_counter;
    CData/*0:0*/ top__DOT__my_seg__DOT__out;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_0;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_1;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_2;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_3;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_4;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_5;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_6;
    CData/*7:0*/ top__DOT__my_seg__DOT____VdfgRegularize_h688ea705_0_7;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    VL_IN16(sw,8,0);
    VL_OUT16(ledr,15,0);
    SData/*9:0*/ top__DOT__my_vga_ctrl__DOT__x_cnt;
    SData/*9:0*/ top__DOT__my_vga_ctrl__DOT__y_cnt;
    SData/*9:0*/ top__DOT__my_keyboard__DOT__buffer;
    IData/*31:0*/ top__DOT__my_scpu__DOT__inst_reg;
    IData/*31:0*/ top__DOT__my_scpu__DOT__pc;
    IData/*31:0*/ top__DOT__my_scpu__DOT__data_reg;
    IData/*31:0*/ top__DOT__my_led__DOT__count;
    IData/*31:0*/ __VactIterCount;
    QData/*35:0*/ top__DOT__my_seg__DOT__count;
    QData/*63:0*/ top__DOT__my_seg__DOT__seg_buffer;
    VlUnpacked<IData/*31:0*/, 16> top__DOT__my_scpu__DOT__r;
    VlUnpacked<IData/*31:0*/, 11> top__DOT__my_scpu__DOT__rom;
    VlUnpacked<IData/*23:0*/, 524288> top__DOT__my_vmem__DOT__vga_mem;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VicoTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* namep);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
