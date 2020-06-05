module execute(
    input [31:0] rs1,
    input [31:0] rs2,
    input [2:0] funct3,
    input [6:0] funct7,
    input immSel,
    input WBSel,
    memRW
    output [31:0] rd,
    output [32:0]imm
);


// The execute stage implements the immediate generation, branch comparison, and arithmetic logic unit (ALU)
// components. Note that branches get resolved in the execute stage, and the effective address is also computed in the execute
// stage. The entire execute stage is combinational.

//immediate generation is in the fetch and decode... I hope that's ok, we'll come back to that
//shouldn't be too hard to move it though (just a quesiton of how much of the decoding should go into execute vs, decode stage)

// ALU

always begin
    
    //operation will get decided based on the type of instruction
    // once r-type is known, we look at funct3 to decode it down to the operation (then to funct7 if necessary)
    // same logic for all except U and J, use funct3 to determine the type 

    if 


end

//



endmodule