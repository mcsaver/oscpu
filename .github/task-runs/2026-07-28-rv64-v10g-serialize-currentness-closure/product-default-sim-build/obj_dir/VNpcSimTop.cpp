// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VNpcSimTop__pch.h"

//============================================================
// Constructors

VNpcSimTop::VNpcSimTop(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VNpcSimTop__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , debug_state_o{vlSymsp->TOP.debug_state_o}
    , debug_pc_o{vlSymsp->TOP.debug_pc_o}
    , debug_ooo_flags_o{vlSymsp->TOP.debug_ooo_flags_o}
    , debug_ooo_satp_o{vlSymsp->TOP.debug_ooo_satp_o}
    , debug_bus_flags_o{vlSymsp->TOP.debug_bus_flags_o}
    , debug_bus2_flags_o{vlSymsp->TOP.debug_bus2_flags_o}
    , debug_fetch_addr_o{vlSymsp->TOP.debug_fetch_addr_o}
    , debug_mem_addr_o{vlSymsp->TOP.debug_mem_addr_o}
    , debug_mem_diag_o{vlSymsp->TOP.debug_mem_diag_o}
    , debug_fetch_pte_addr_o{vlSymsp->TOP.debug_fetch_pte_addr_o}
    , debug_fetch_pte_o{vlSymsp->TOP.debug_fetch_pte_o}
    , debug_fetch_pte_meta_o{vlSymsp->TOP.debug_fetch_pte_meta_o}
    , debug_clint_mtime_o{vlSymsp->TOP.debug_clint_mtime_o}
    , __PVT____024unit{vlSymsp->TOP.__PVT____024unit}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VNpcSimTop::VNpcSimTop(const char* _vcname__)
    : VNpcSimTop(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VNpcSimTop::~VNpcSimTop() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VNpcSimTop___024root___eval_debug_assertions(VNpcSimTop___024root* vlSelf);
#endif  // VL_DEBUG
void VNpcSimTop___024root___eval_static(VNpcSimTop___024root* vlSelf);
void VNpcSimTop___024root___eval_initial(VNpcSimTop___024root* vlSelf);
void VNpcSimTop___024root___eval_settle(VNpcSimTop___024root* vlSelf);
void VNpcSimTop___024root___eval(VNpcSimTop___024root* vlSelf);

void VNpcSimTop::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VNpcSimTop::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VNpcSimTop___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VNpcSimTop___024root___eval_static(&(vlSymsp->TOP));
        VNpcSimTop___024root___eval_initial(&(vlSymsp->TOP));
        VNpcSimTop___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VNpcSimTop___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VNpcSimTop::eventsPending() { return false; }

uint64_t VNpcSimTop::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VNpcSimTop::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VNpcSimTop___024root___eval_final(VNpcSimTop___024root* vlSelf);

VL_ATTR_COLD void VNpcSimTop::final() {
    VNpcSimTop___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VNpcSimTop::hierName() const { return vlSymsp->name(); }
const char* VNpcSimTop::modelName() const { return "VNpcSimTop"; }
unsigned VNpcSimTop::threads() const { return 1; }
void VNpcSimTop::prepareClone() const { contextp()->prepareClone(); }
void VNpcSimTop::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void VNpcSimTop::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'VNpcSimTop::trace()' called on model that was Verilated without --trace option");
}
