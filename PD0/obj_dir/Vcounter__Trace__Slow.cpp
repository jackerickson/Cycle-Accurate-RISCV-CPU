// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vcounter__Syms.h"


//======================

void Vcounter::trace (VerilatedVcdC* tfp, int, int) {
    tfp->spTrace()->addCallback (&Vcounter::traceInit, &Vcounter::traceFull, &Vcounter::traceChg, this);
}
void Vcounter::traceInit(VerilatedVcd* vcdp, void* userthis, uint32_t code) {
    // Callback from vcd->open()
    Vcounter* t=(Vcounter*)userthis;
    Vcounter__Syms* __restrict vlSymsp = t->__VlSymsp;  // Setup global symbol table
    if (!Verilated::calcUnusedSigs()) VL_FATAL_MT(__FILE__,__LINE__,__FILE__,"Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    vcdp->scopeEscape(' ');
    t->traceInitThis (vlSymsp, vcdp, code);
    vcdp->scopeEscape('.');
}
void Vcounter::traceFull(VerilatedVcd* vcdp, void* userthis, uint32_t code) {
    // Callback from vcd->dump()
    Vcounter* t=(Vcounter*)userthis;
    Vcounter__Syms* __restrict vlSymsp = t->__VlSymsp;  // Setup global symbol table
    t->traceFullThis (vlSymsp, vcdp, code);
}

//======================


void Vcounter::traceInitThis(Vcounter__Syms* __restrict vlSymsp, VerilatedVcd* vcdp, uint32_t code) {
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    int c=code;
    if (0 && vcdp && c) {}  // Prevent unused
    vcdp->module(vlSymsp->name());  // Setup signal names
    // Body
    {
	vlTOPp->traceInitThis__1(vlSymsp, vcdp, code);
    }
}

void Vcounter::traceFullThis(Vcounter__Syms* __restrict vlSymsp, VerilatedVcd* vcdp, uint32_t code) {
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    int c=code;
    if (0 && vcdp && c) {}  // Prevent unused
    // Body
    {
	vlTOPp->traceFullThis__1(vlSymsp, vcdp, code);
    }
    // Final
    vlTOPp->__Vm_traceActivity = 0U;
}

void Vcounter::traceInitThis__1(Vcounter__Syms* __restrict vlSymsp, VerilatedVcd* vcdp, uint32_t code) {
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    int c=code;
    if (0 && vcdp && c) {}  // Prevent unused
    // Body
    {
	vcdp->declBus  (c+1,"x",-1,3,0);
	vcdp->declBus  (c+2,"z",-1,3,0);
	vcdp->declBus  (c+1,"counter x",-1,3,0);
	vcdp->declBus  (c+2,"counter z",-1,3,0);
    }
}

void Vcounter::traceFullThis__1(Vcounter__Syms* __restrict vlSymsp, VerilatedVcd* vcdp, uint32_t code) {
    Vcounter* __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    int c=code;
    if (0 && vcdp && c) {}  // Prevent unused
    // Body
    {
	vcdp->fullBus  (c+1,(vlTOPp->x),4);
	vcdp->fullBus  (c+2,(vlTOPp->z),4);
    }
}
