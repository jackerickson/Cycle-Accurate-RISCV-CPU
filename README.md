A Cycle Accurate Fully Pipelined Simulation that supports the RV32I base instruction set.

Memory is loaded at sim time from the .x file specified in memory.v, this file can be compiled from C using the RISC-V toolchain as follows.

To build the compiler toolchain, you can follow the instructions [riscv-gnu-toolchain](https://riscv.org/software-tools/risc-v-gnu-compiler-toolchain/).

Complation options for this sim:
```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
$ ./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
$ make
```

The simulation itself is uses iverilog, the simulator runs the testbench which connects the components and begins fetching instructions.

Build with iverilog using  
```
iverilog -g2005 -o testbench testbench.v -y components
```

some example programs are included in ./programs in the format:

* `.c`: The C program
* `.x`: The executable file the processor will load
* `.d`: The dump file generated using GCC.  This has the addresses, the instruction encoding, and its assembly.
* `.s`: The assembly 

scripts are provided for running the simulation in ./run_file, these work best when placed in the the same directory as the src files due to some dependency issues with iverilog. 


todo: Performance issue for consecutive instructions with the same destination address

    Due to how I determine stalling in the pipeline, stalling takes precedent over the bypass which means 
    in some instances the pipeline will stall until a writeback has cleared when it could be using a bypass lane.

    This may cause instances where under certain conditions the pipeline will only process one instruction at a time.
