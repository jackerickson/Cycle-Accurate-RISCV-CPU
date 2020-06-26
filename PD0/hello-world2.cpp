#include <cstdio>
#include <cstdlib>

#include <verilated.h>

#include "Vcounter.h"
#include "verilated_vcd_c.h"

using namespace std;

Vcounter *top;

vluint64_t main_time = 0; //current sim time

double sc_time_stamp () { // Called by $time in Verilog
    return main_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv); // Remember args

    top = new Vcounter; //create instance
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp-> open ("hello-world-2.vcd");

    top->x = 1;
    top->eval();
    printf("[Hellow World] x:%x, z: %x\n", top->x, top->z);
    tfp->dump (main_time);


    main_time += 10;
    top->x = top->x + 1;
    top->eval();

    printf("[Hello World] x:%x, z: %x\n", top->x, top->z);
    tfp->dump (main_time);

    main_time += 10;
    top->x = top->x + 1;
    top->eval();

    printf("[Hello World] x:%x, z: %x\n", top->x, top->z);
    tfp->dump (main_time);

    tfp->close();
    top->final(); // Done Simulating

    delete top;

    return 0;
}