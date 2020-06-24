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

    wire BrUn, PCSel,ASel, BSel, BrEq, BrLt, RdUn;
    wire [1:0] access_size;
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
    wire [31:0] d_mem_out;
    wire [31:0] formatted_d_mem_out;
    
    // this is the mux on the 2nd ALU input that tell it to use ImmSelediate or the rs2 value

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, dut);

    end

    // simulation end conditions
    always@(posedge clk) begin
        
        if(PC_next == 32'h0000_0000) begin
            $display("PC_Next is blank, exiting since no more instructions");
            $finish;
        end

        if(ALUSel == `JADD && data_rs1 == 32'h0101_1111) begin 
            $display("Returning to SP at end of memory, terminating simulation.");
            $finish;
        end
        // if(i_mem_out == 32'd0 || PC == 32'h0100_0044) begin
        //     #5$write("\n Ending sim since i_mem_out = %x or PC = %x", i_mem_out, PC);
        //     //$finish;
        // end

        if(instruction == 32'hbadbadff)begin $display("Exiting: Instruction memory returned out of range"); $finish; end
    end

    memory #(.LOAD_INSTRUCTION_MEM(1)) i_mem (.clk(clk), .address(PC_next), .data_in(32'd0), .w_enable(1'b0), .access_size(`WORD), .RdUn(1'b0), .data_out(i_mem_out));

    memory      #(.LOAD_INSTRUCTION_MEM(1)) d_mem(.clk(clk), .address(ALU_out), .data_in(data_rs2), .w_enable(MemRW), .access_size(access_size), .RdUn(RdUn), .data_out(d_mem_out));
    PCMux       PCMux(.clk(clk), .PCSel(PCSel), .ALU_out(ALU_out), .PC(PC), .PC_next(PC_next));

    alu         alu1(.rs1(ALU_in1), .rs2(ALU_in2), .ALUsel(ALUSel), .alu_res(ALU_out));


    reg_file    reg_file(.clk(clk),
                        .addr_rs1(addr_rs1),
                        .addr_rs2(addr_rs2),
                        .addr_rd(addr_rd),
                        .data_rd(wb),
                        .data_rs1(data_rs1),
                        .data_rs2(data_rs2),
                        .write_enable(RegWE)
                        );


    WBMux       WBMux1(.clk(clk), .dmem(d_mem_out), .alu(ALU_out), .pc_next(PC + 4), .sel(WBSel), .out(wb));

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
            .RdUn(RdUn),
            .access_size(access_size),
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
        instruction <= i_mem_out;
    end


    always begin
        #5 clk <= ~clk;
    end

    // //Logging for PD3
    always @(posedge clk) begin
    //     //

    //     $write("Execute Stage Signals\n\t");
    //     $write("PCSel=");
    //     if(PCSel) $write("PC+4(no branch), ");
    //     else $write("ALU(branch_addr=%0x), ", ALU_out);

    //     $write("RegWE=");
    //     if(RegWE) $write("write, ");
    //     else $write("read, ");
    //     $write("BrUn=");

    //     if(BrUn) $write("unsigned");
    //     else $write("signed, ");

    //     $write("BrEq=");
    //     if(BrEq) $write("equal, ");
    //     else $write("equal, ");

    //     $write("BrLt=");
    //     if(BrLt) $write("less than, ");
    //     else $write("GE(>=), ");

    //     $write("BSel=");
    //     if(BSel) $write("reg, ");
    //     else $write("imm, ");

    //     $write("ASel=");
    //     if(ASel) $write("reg, ");
    //     else $write("PC, ");

    //     $write("ALUSel=");
    //     case (ALUSel)
    //         `ADD: $write("ADD");
    //         `AND: $write("AND");
    //         `OR:$write("OR");
    //         `SLL: $write("SLL");
    //         `SLT: $write("SLT");
    //         `SLTU: $write("SLTU");
    //         `SRA: $write("SRA");
    //         `SRL: $write("SRL");
    //         `SUB: $write("SUB");
    //         `XOR: $write("XOR");
    //         `LUIOP: $write("LUI");
    //         `JADD: $write("JumpADD");
    //         default: $display("Error in ALU mux");
    //     endcase
    //     $write("(input1=0x%0x, input2=0x%0x, res=0x%0x) ,", ALU_in1, ALU_in2, ALU_out);

    //     $write("MemRW=");
    //     if(MemRW) $write("Read, ");
    //     else $write("Write, ");

    //     $write("WBSel=");
    //     case(WBSel)
    //         `MEM: $write("Mem, ");
    //         `ALU:   $write("ALU, ");
    //         `PC_NEXT: $write("PC+4, ");
    //         default: $display("Error in the WB MUX");
    //     endcase
    //     $write("\n");
    

        //Regfile logging
        // $write("RegFile Ports\n\tInput: addr_rs1 = %0d, addr_rs2 = %0d, addr_rd = %0d, data_rd = %0x (%0d), write_enable = %b \n", addr_rs1, addr_rs2, addr_rd, wb, wb, RegWE);
        // $write("\tOutput: data_rs1 = 0x%0x (%0d), data_rs2 = 0x%0x (%0d)\n",data_rs1, data_rs1, data_rs2, data_rs2);
        $write("\n--------------------------------------\n"); 
    end

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
        
        if(PCSel)
            PC_next <= PC + 4;
        else 
            PC_next <= ALU_out;
    end
endmodule



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

//Reg file monitoring output