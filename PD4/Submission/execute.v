module execute(
    input clk,
    input [31:0] PC_x,
    input [31:0] rs1,
    input [31:0] rs2,
    //input [31:0] inst_x,
    input [31:0] imm,
    input [3:0] ALUSel,
    input BrUn,
    input ASel,
    input BSel,
    //output [31:0] PC_m,
    output [31:0] ALU_out,
    output [31:0] write_data,
    //output [31:0] inst_m

    output BrEq,
    output BrLt);


    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;
    

    alu alu1(.rs1(ALU_in1), .rs2(ALU_in2), .ALUsel(ALUSel),.alu_res(ALU_out));

    assign write_data = rs2;
    //assign PC_m = PC_x;
    //assign inst_x = inst_m;

    // BrMux
    assign BrEq = (rs1 == rs2);
    assign BrLt = BrUn ? (rs1 < rs2): ($signed(rs1) < $signed(rs2));

    assign ALU_in1 = ASel ? rs1 : PC_x;
    assign ALU_in2 = BSel ? rs2 : imm;

    

endmodule