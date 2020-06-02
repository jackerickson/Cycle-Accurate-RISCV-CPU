// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcounter.h for the primary calling header

#include "Vcounter.h"          // For This
#include "Vcounter__Syms.h"


//--------------------
// STATIC VARIABLES


//--------------------

VL_CTOR_IMP(Vcounter) {
    Vcounter__Syms* __restrict vlSymsp = __VlSymsp = new Vcounter__Syms(this, name());
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vcounter::__Vconfigure(Vcounter__Syms* vlSymsp, bool first) {
    if (0 && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
}

Vcounter::~Vcounter() {
    delete __VlSymsp; __VlSymsp=NULL;
}

//--------------------


void Vcounter::eval() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcounter::eval\n"); );
    Vcounter__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    while (VL_LIKELY(__Vchange)) {
	VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
	vlSymsp->__Vm_activity = true;
	_eval(vlSymsp);
	__Vchange = _change_request(vlSymsp);
	if (VL_UNLIKELY(++__VclockLoop > 100)) VL_FATAL_MT(__FILE__,__LINE__,__FILE__,"Verilated model didn't converge");
    }
}

void Vcounter::_eval_initial_loop(Vcounter__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    vlSymsp->__Vm_activity = true;
    int __VclockLoop = 0;
    QData __Vchange = 1;
    while (VL_LIKELY(__Vchange)) {
	_eval_settle(vlSymsp);
	_eval(vlSymsp);
	__Vchange = _change_request(vlSymsp);
	if (VL_UNLIKELY(++__VclockLoop > 100)) VL_FATAL_MT(__FILE__,__LINE__,__FILE__,"Verilated model didn't DC converge");
    }
}

//--------------------
// Internal Methods

VL_INLINE_OPT void Vcounter::_combo__TOP__1(Vcounter__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_combo__TOP__1\n"); );
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->z = (0xfU & ((IData)(1U) + (IData)(vlTOPp->x)));
}

void Vcounter::_eval(Vcounter__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_eval\n"); );
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__1(vlSymsp);
}

void Vcounter::_eval_initial(Vcounter__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_eval_initial\n"); );
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vcounter::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::final\n"); );
    // Variables
    Vcounter__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vcounter::_eval_settle(Vcounter__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_eval_settle\n"); );
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__1(vlSymsp);
}

VL_INLINE_OPT QData Vcounter::_change_request(Vcounter__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_change_request\n"); );
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vcounter::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((x & 0xf0U))) {
	Verilated::overWidthError("x");}
}
#endif // VL_DEBUG

void Vcounter::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcounter::_ctor_var_reset\n"); );
    // Body
    x = VL_RAND_RESET_I(4);
    z = VL_RAND_RESET_I(4);
    __Vm_traceActivity = VL_RAND_RESET_I(32);
}
