`include "components/fetch_decode.v"
`include "components/constants.v"
`include "components/memory.v"
`include "alu.v"
`include "reg_file.v"

module dut;

    reg clk = 0;

    // instruction memory inputs



    wire[31:0] i_mem_out;
    reg [31:0]instruction;


    //Fetch_decoder ports
    wire [4:0] addr_rd;
    wire [4:0] addr_rs1;
    wire [4:0] addr_rs2;
    wire [31:0] imm;
    wire [31:0] PC;
    wire [31:0] PC_next;


    // control wires out of the decoder

    wire BrUn, PCSel,ASel, BSel, BrEq, BrLt;
    wire RegWE; 
    wire MemRW;
    wire [1:0]WBSel;

    wire [3:0]ALUSel;

    //regfile connectors

    wire [31:0] data_rs1;
    wire [31:0] data_rs2;

    //ALU inputs

    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;
    wire [31:0] ALU_out;

    wire [31:0] wb;

    
    // this is the mux on the 2nd ALU input that tell it to use ImmSelediate or the rs2 value

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, dut);
    end

    // simulation end conditions
    always@(posedge clk) if(i_mem_out == 32'd0) begin
        #5$write("\n");
        $finish;
    end

    memory      i_mem(.clk(clk), .address(PC_next), .data_in(32'd0), .w_enable(1'b0),.data_out(i_mem_out));

    PCMux       PCMux(.clk(clk), .PCSel(PCSel), .ALU_out(ALU_out), .PC(PC), .PC_next(PC_next));

    // need to fill out the alu
    alu         alu1(.rs1(ALU_in1), .rs2(ALU_in2), .ALUsel(ALUSel), .alu_res(ALU_out));

    // branchMux   bm1(.rs1(data_rs1), .rs2(data_rs2), .BrUn(BrUn), .BrEq(BrEq), .BrLt(BrLt));
    // need to complete this
    reg_file    reg_file(.clk(clk),
                        .addr_rs1(addr_rs1),
                        .addr_rs2(addr_rs2),
                        .addr_rd(addr_rd),
                        .data_rd(wb),
                        .data_rs1(data_rs1),
                        .data_rs2(data_rs2),
                        .write_enable(RegWE)
                        );

    //NEED TO CHANGE DMEM WHEN MEMORY MODULE IS IMPLEMENTED
    WBMux       WBMux1(.clk(clk), .dmem(32'd0), .alu(ALU_out), .pc_next(PC + 4), .sel(WBSel), .out(wb));

    fetch_decode fd1(
            //inputs
            .clk(clk),
            .instruction(instruction),
            //outputs
            .BrEq(BrEq),
            .BrLt(BrLt),
            .PC(PC),
            .addr_rd(addr_rd),
            .addr_rs1(addr_rs1),
            .addr_rs2(addr_rs2),
            .imm(imm),
            .PCSel(PCSel),
            .BrUn(BrUn),
            .ASel(ASel),
            .BSel(BSel),
            .ALUSel(ALUSel),
            .MemRW(MemRW),
            .RegWE(RegWE),
            .WBSel(WBSel)
        );


    //ALU input muxes

    assign ALU_in1 = ASel ? data_rs1 : PC;
    assign ALU_in2 = BSel ? data_rs2 : imm;

    // BrMux
    assign BrEq = (data_rs1 == data_rs2);
    assign BrLt = BrUn ? (data_rs1 < data_rs2): ($signed(data_rs1) < $signed(data_rs2));
    
    // sequential fetching
    always@(posedge clk) begin
        instruction = i_mem_out;
    end

    // down here need to write logic for:

    //DMEM Stand in

    // clk tick every 10 steps
    always begin
        #5 clk <= ~clk;
    end
    always @(negedge clk)  $write("--------------------------------------\n"); 


endmodule

module PCMux(clk, PCSel, ALU_out, PC, PC_next);

    input clk;
    input PCSel;
    input [31:0]ALU_out;
    output [31:0] PC;
    output [31:0] PC_next;
    
    reg [31:0] PC = 32'h01000000-4;
    reg [31:0] PC_next;
    
    // assign PC_next = PCSel? PC+4:ALU_out;

    always@(posedge clk) begin
        PC <= PC_next;
    end
    always@(*) begin
        $display("PCSEL = %b", PCSel);
        if(PCSel)
            PC_next <= PC + 4;
        else 
            PC_next <= ALU_out;
    end
endmodule

// module branchMux(rs1, rs2, BrUn, BrEq, BrLt);
//     input [31:0] rs1;
//     input [31:0] rs2;
//     input BrUn;

//     output BrEq, BrLt;

//     reg BrEq, BrLt;

//     // always@(*) begin
//     //     BrEq <= (rs1 == rs2);
//     //     if(BrUn)
//     //         BrLt <= (rs1 < rs2);
//     //     else
//     //         BrLt <= ($signed(rs1) < $signed(rs2)); 
//     // end

    

// endmodule

module WBMux (clk, dmem, alu, pc_next, sel, out);
    input clk;
    input [31:0] dmem;
    input [31:0] alu;
    input [31:0] pc_next;
    input [1:0] sel;

    output reg [31:0] out;

   

    always@(*) begin
        case(sel)
            `MEM: out <= dmem;
            `ALU: out <= alu;
            `PC_NEXT: out <= pc_next;
            default: $display("Error in the WB MUX");
        endcase
    end 

endmodule