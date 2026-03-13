// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vkey__pch.h"
#include "verilated_fst_c.h"

//============================================================
// Constructors

Vkey::Vkey(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vkey__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , a{vlSymsp->TOP.a}
    , b{vlSymsp->TOP.b}
    , f{vlSymsp->TOP.f}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vkey::Vkey(const char* _vcname__)
    : Vkey(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vkey::~Vkey() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vkey___024root___eval_debug_assertions(Vkey___024root* vlSelf);
#endif  // VL_DEBUG
void Vkey___024root___eval_static(Vkey___024root* vlSelf);
void Vkey___024root___eval_initial(Vkey___024root* vlSelf);
void Vkey___024root___eval_settle(Vkey___024root* vlSelf);
void Vkey___024root___eval(Vkey___024root* vlSelf);

void Vkey::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vkey::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vkey___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_activity = true;
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vkey___024root___eval_static(&(vlSymsp->TOP));
        Vkey___024root___eval_initial(&(vlSymsp->TOP));
        Vkey___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vkey___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vkey::eventsPending() { return false; }

uint64_t Vkey::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vkey::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vkey___024root___eval_final(Vkey___024root* vlSelf);

VL_ATTR_COLD void Vkey::final() {
    Vkey___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vkey::hierName() const { return vlSymsp->name(); }
const char* Vkey::modelName() const { return "Vkey"; }
unsigned Vkey::threads() const { return 1; }
void Vkey::prepareClone() const { contextp()->prepareClone(); }
void Vkey::atClone() const {
    contextp()->threadPoolpOnClone();
}
std::unique_ptr<VerilatedTraceConfig> Vkey::traceConfig() const {
    return std::unique_ptr<VerilatedTraceConfig>{new VerilatedTraceConfig{false, false, false}};
};

//============================================================
// Trace configuration

void Vkey___024root__trace_decl_types(VerilatedFst* tracep);

void Vkey___024root__trace_init_top(Vkey___024root* vlSelf, VerilatedFst* tracep);

VL_ATTR_COLD static void trace_init(void* voidSelf, VerilatedFst* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vkey___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vkey___024root*>(voidSelf);
    Vkey__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (!vlSymsp->_vm_contextp__->calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
            "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->pushPrefix(std::string{vlSymsp->name()}, VerilatedTracePrefixType::SCOPE_MODULE);
    Vkey___024root__trace_decl_types(tracep);
    Vkey___024root__trace_init_top(vlSelf, tracep);
    tracep->popPrefix();
}

VL_ATTR_COLD void Vkey___024root__trace_register(Vkey___024root* vlSelf, VerilatedFst* tracep);

VL_ATTR_COLD void Vkey::trace(VerilatedFstC* tfp, int levels, int options) {
    if (tfp->isOpen()) {
        vl_fatal(__FILE__, __LINE__, __FILE__,"'Vkey::trace()' shall not be called after 'VerilatedFstC::open()'.");
    }
    if (false && levels && options) {}  // Prevent unused
    tfp->spTrace()->addModel(this);
    tfp->spTrace()->addInitCb(&trace_init, &(vlSymsp->TOP));
    Vkey___024root__trace_register(&(vlSymsp->TOP), tfp->spTrace());
}
