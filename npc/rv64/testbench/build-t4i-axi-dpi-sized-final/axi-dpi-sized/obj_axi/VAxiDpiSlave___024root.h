// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VAxiDpiSlave.h for the primary calling header

#ifndef VERILATED_VAXIDPISLAVE___024ROOT_H_
#define VERILATED_VAXIDPISLAVE___024ROOT_H_  // guard

#include "verilated.h"
class VAxiDpiSlave___024unit;


class VAxiDpiSlave__Syms;

class alignas(VL_CACHE_LINE_BYTES) VAxiDpiSlave___024root final {
  public:
    // CELLS
    VAxiDpiSlave___024unit* __PVT____024unit;

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        VL_IN8(clk,0,0);
        VL_IN8(rst,0,0);
        VL_IN8(s_axi_arvalid_i,0,0);
        VL_OUT8(s_axi_arready_o,0,0);
        VL_IN8(s_axi_arsize_i,2,0);
        VL_IN8(s_axi_arprot_i,2,0);
        VL_OUT8(s_axi_rvalid_o,0,0);
        VL_IN8(s_axi_rready_i,0,0);
        VL_OUT8(s_axi_rresp_o,1,0);
        VL_IN8(s_axi_awvalid_i,0,0);
        VL_OUT8(s_axi_awready_o,0,0);
        VL_IN8(s_axi_awsize_i,2,0);
        VL_IN8(s_axi_wvalid_i,0,0);
        VL_OUT8(s_axi_wready_o,0,0);
        VL_IN8(s_axi_wstrb_i,7,0);
        VL_OUT8(s_axi_bvalid_o,0,0);
        VL_IN8(s_axi_bready_i,0,0);
        VL_OUT8(s_axi_bresp_o,1,0);
        CData/*2:0*/ AxiDpiSlave__DOT__awsize_q;
        CData/*0:0*/ AxiDpiSlave__DOT__aw_valid_q;
        CData/*7:0*/ AxiDpiSlave__DOT__wstrb_q;
        CData/*0:0*/ AxiDpiSlave__DOT__w_valid_q;
        CData/*0:0*/ AxiDpiSlave__DOT__aw_fire_w;
        CData/*0:0*/ AxiDpiSlave__DOT__w_fire_w;
        CData/*0:0*/ AxiDpiSlave__DOT__write_complete_w;
        CData/*0:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__bus_error_v;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __VstlPhaseResult;
        CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__s_axi_arvalid_i__0;
        CData/*2:0*/ __Vtrigprevexpr___TOP__s_axi_arsize_i__0;
        CData/*2:0*/ __Vtrigprevexpr___TOP__s_axi_arprot_i__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__s_axi_rready_i__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__s_axi_awvalid_i__0;
        CData/*2:0*/ __Vtrigprevexpr___TOP__s_axi_awsize_i__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__s_axi_wvalid_i__0;
        CData/*7:0*/ __Vtrigprevexpr___TOP__s_axi_wstrb_i__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__s_axi_bready_i__0;
        CData/*0:0*/ __VicoDidInit;
        CData/*0:0*/ __VicoPhaseResult;
        CData/*0:0*/ __Vtrigprevexpr___TOP__clk__1;
        CData/*0:0*/ __VactPhaseResult;
        CData/*0:0*/ __VnbaPhaseResult;
        IData/*31:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__read_size_v;
        IData/*31:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__write_size_v;
        IData/*31:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__lane_shift_v;
        IData/*31:0*/ __VactIterCount;
        VL_IN64(s_axi_araddr_i,63,0);
        VL_OUT64(s_axi_rdata_o,63,0);
        VL_IN64(s_axi_awaddr_i,63,0);
        VL_IN64(s_axi_wdata_i,63,0);
        QData/*63:0*/ AxiDpiSlave__DOT__awaddr_q;
        QData/*63:0*/ AxiDpiSlave__DOT__wdata_q;
        QData/*63:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__bus_data_v;
        QData/*63:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__read_data_v;
        QData/*63:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__write_addr_v;
        QData/*63:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__write_data_v;
        QData/*63:0*/ AxiDpiSlave__DOT__unnamedblk1__DOT__write_mask_v;
        QData/*63:0*/ __Vtrigprevexpr___TOP__s_axi_araddr_i__0;
        QData/*63:0*/ __Vtrigprevexpr___TOP__s_axi_awaddr_i__0;
        QData/*63:0*/ __Vtrigprevexpr___TOP__s_axi_wdata_i__0;
        VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
        VlUnpacked<QData/*63:0*/, 2> __VicoTriggered;
    };
    struct {
        VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
        VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    };

    // INTERNAL VARIABLES
    VAxiDpiSlave__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    VAxiDpiSlave___024root(VAxiDpiSlave__Syms* symsp, const char* namep);
    ~VAxiDpiSlave___024root();
    VL_UNCOPYABLE(VAxiDpiSlave___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
