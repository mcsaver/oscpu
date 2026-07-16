// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VAxiDpiSlave__pch.h"

//============================================================
// Constructors

VAxiDpiSlave::VAxiDpiSlave(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VAxiDpiSlave__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , s_axi_arvalid_i{vlSymsp->TOP.s_axi_arvalid_i}
    , s_axi_arready_o{vlSymsp->TOP.s_axi_arready_o}
    , s_axi_arsize_i{vlSymsp->TOP.s_axi_arsize_i}
    , s_axi_arprot_i{vlSymsp->TOP.s_axi_arprot_i}
    , s_axi_rvalid_o{vlSymsp->TOP.s_axi_rvalid_o}
    , s_axi_rready_i{vlSymsp->TOP.s_axi_rready_i}
    , s_axi_rresp_o{vlSymsp->TOP.s_axi_rresp_o}
    , s_axi_awvalid_i{vlSymsp->TOP.s_axi_awvalid_i}
    , s_axi_awready_o{vlSymsp->TOP.s_axi_awready_o}
    , s_axi_awsize_i{vlSymsp->TOP.s_axi_awsize_i}
    , s_axi_wvalid_i{vlSymsp->TOP.s_axi_wvalid_i}
    , s_axi_wready_o{vlSymsp->TOP.s_axi_wready_o}
    , s_axi_wstrb_i{vlSymsp->TOP.s_axi_wstrb_i}
    , s_axi_bvalid_o{vlSymsp->TOP.s_axi_bvalid_o}
    , s_axi_bready_i{vlSymsp->TOP.s_axi_bready_i}
    , s_axi_bresp_o{vlSymsp->TOP.s_axi_bresp_o}
    , s_axi_araddr_i{vlSymsp->TOP.s_axi_araddr_i}
    , s_axi_rdata_o{vlSymsp->TOP.s_axi_rdata_o}
    , s_axi_awaddr_i{vlSymsp->TOP.s_axi_awaddr_i}
    , s_axi_wdata_i{vlSymsp->TOP.s_axi_wdata_i}
    , __PVT____024unit{vlSymsp->TOP.__PVT____024unit}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VAxiDpiSlave::VAxiDpiSlave(const char* _vcname__)
    : VAxiDpiSlave(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VAxiDpiSlave::~VAxiDpiSlave() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VAxiDpiSlave___024root___eval_debug_assertions(VAxiDpiSlave___024root* vlSelf);
#endif  // VL_DEBUG
void VAxiDpiSlave___024root___eval_static(VAxiDpiSlave___024root* vlSelf);
void VAxiDpiSlave___024root___eval_initial(VAxiDpiSlave___024root* vlSelf);
void VAxiDpiSlave___024root___eval_settle(VAxiDpiSlave___024root* vlSelf);
void VAxiDpiSlave___024root___eval(VAxiDpiSlave___024root* vlSelf);

void VAxiDpiSlave::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VAxiDpiSlave::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VAxiDpiSlave___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VAxiDpiSlave___024root___eval_static(&(vlSymsp->TOP));
        VAxiDpiSlave___024root___eval_initial(&(vlSymsp->TOP));
        VAxiDpiSlave___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VAxiDpiSlave___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VAxiDpiSlave::eventsPending() { return false; }

uint64_t VAxiDpiSlave::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VAxiDpiSlave::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VAxiDpiSlave___024root___eval_final(VAxiDpiSlave___024root* vlSelf);

VL_ATTR_COLD void VAxiDpiSlave::final() {
    contextp()->executingFinal(true);
    VAxiDpiSlave___024root___eval_final(&(vlSymsp->TOP));
    contextp()->executingFinal(false);
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VAxiDpiSlave::hierName() const { return vlSymsp->name(); }
const char* VAxiDpiSlave::modelName() const { return "VAxiDpiSlave"; }
unsigned VAxiDpiSlave::threads() const { return 1; }
void VAxiDpiSlave::prepareClone() const { contextp()->prepareClone(); }
void VAxiDpiSlave::atClone() const {
    contextp()->threadPoolpOnClone();
}
