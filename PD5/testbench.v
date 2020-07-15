// `include "components/fetch_decode.v"
`include "components/constants.v"
// `include "components/memory.v"
// `include "execute.v"
// `include "alu.v"
// `include "reg_file.v"

/*
Tasks:

    - Correct pipelined executions
    - Instance of stalls due to Read after write data hazards
    - Forwarding happening on each of the input and every stage
    NO BRANCH PREDICTION THANK GOD

    Method to avoid RAW errors - insert nops (stalls until the RAW is cleared)
        - insert NOPS wherever there is a data dependance that cannot be resolved via forwarding

*/


module dut;

    reg clk = 0;

    // instruction memory inputs    

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, dut);

    end

    // simulation end conditions

    always@(posedge clk) begin

        if(dut.reg_file.user_reg[2] == 32'h0101_1111 && dut.execute.opcode == `JALR) begin 
            $display("Returning to SP at end of memory, terminating simulation.");
            
        //     // // $display("Contents of regfile: ");
        //     // for (i=0;i<32;i++) begin
        //     //     $display("r%0d = %0x", i, dut.reg_file.user_reg[i]);
        //     // end
            $finish;
        end
        if(inst_x == 32'd0) #5 $finish;
        if(inst_x == 32'hbadbadff)begin $display("Exiting: Instruction memory returned out of range"); #10 $finish; end
    end

    wire[31:0] inst_f;

    wire [31:0] PC_f; //start out right before the memory starts

    wire RegWE; 

    wire MemRW;

    //fetch_decode
    wire [31:0] inst_d;
    wire [31:0] PC_d;
    wire [4:0] addr_rs1;
    wire [4:0] addr_rs2;
    
    //regfile outputs
    wire [31:0] data_rs1;
    wire [31:0] data_rs2;
    //execute outputs
    wire [31:0] inst_x;
    wire [31:0] PC_x;
    wire [31:0] rs2_x;
    wire [31:0] alu_x;

    //mem stage outputs 
    wire [31:0] wb_m;
    wire [31:0] inst_m;

    //writeback stage outputs
    wire [31:0] wb_w;
    wire [31:0] inst_w;
    wire [4:0] addr_rd;

    //write stuff
    //this is where I'll do the printing now (grab the insn from the execute stage since all of these components can be found there)
    always @(posedge clk) begin
        // for debugging
        //opcode determines instruction format, except for MCC types instructions (SLLI, SRLI, and SRAI are different than the other MCC instructions)
        //$write("Current instruction components: opcode=%7b, func3=%3b, func7=%7b, addr_rd=x%0d, addr_rs1=x%0d, addr_rs2=x%0d, dut.execute.imm=%0d\n", opcode, funct3, funct7, addr_rd, addr_rs1, addr_rs2,dut.execute.imm);
    
        $write("%x:  \t%8x    \t", PC_x, inst_x);
        case(dut.execute.opcode) //output the instruction contents to the console in simulation
            `LUI: begin
            // 7'b0110111: begin
                $display("LUI    x%0d, 0x%0x", addr_rd, dut.execute.imm);
            end
            `AUIPC: begin
                $display("AUIPC  x%0d, 0x%0x", addr_rd, dut.execute.imm);
            end
            `JAL: begin
                
                $display("JAL    x%0d, %0x", addr_rd, PC_x+dut.execute.imm);
            end
            `JALR: begin
                if (dut.execute.funct3 == 3'b000) begin
                    $display("JALR   x%0d, %0d(x%0d)", addr_rd, dut.execute.imm,addr_rs1);
                end
                else $display("Unknown function:%0b of Type JALR");
            end
            `BCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("BEQ    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC_x+dut.execute.imm);
                    3'b001: $display("BNE    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC_x+dut.execute.imm);
                    3'b100: $display("BLT    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC_x+dut.execute.imm);
                    3'b101: $display("BGE    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC_x+dut.execute.imm);
                    3'b110: $display("BLTU   x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC_x+dut.execute.imm);
                    3'b111: $display("BGEU    x%0d, x%0d, %0x", addr_rs1, addr_rs2,PC_x+dut.execute.imm);
                    default: $display("Unknown BCC Type: %0b", dut.execute.funct3);
                endcase
            end
            `LCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("LB     %0d(x%0d)", addr_rd, dut.execute.imm, addr_rs1);
                    3'b001: $display("LH     x%0d, %0d(x%0d)", addr_rd, dut.execute.imm, addr_rs1);
                    3'b010: $display("LW     x%0d, %0d(x%0d)", addr_rd, dut.execute.imm, addr_rs1);
                    3'b100: $display("LBU    x%0d, %0d(x%0d)", addr_rd, dut.execute.imm, addr_rs1);
                    3'b101: $display("LHU    x%0d, %0d(x%0d)", addr_rd, dut.execute.imm, addr_rs1);
                    default: $display("Unknown LCC Type: %0b", dut.execute.funct3);
                endcase
            end
            `SCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("SB     x%0d, %0d(x%0d)", addr_rs2, dut.execute.imm, addr_rs1);
                    3'b001: $display("SH     x%0d, %0d(x%0d)", addr_rs2, dut.execute.imm, addr_rs1);
                    3'b010: $display("SW     x%0d, %0d(x%0d)", addr_rs2, dut.execute.imm, addr_rs1);
                    default: $display("Unknown SCC Type: %0b", dut.execute.funct3);
                endcase
            end
            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                case(dut.execute.funct3)
                    //I-Type cases
                    3'b000: $display("ADDI   x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    3'b010: $display("SLTI   x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    3'b011: $display("SLTIU  x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    3'b100: $display("XORI   x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    3'b110: $display("ORI    x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    3'b111: $display("ANDI   x%0d, x%0d, %0d", addr_rd, addr_rs1, dut.execute.imm);
                    //R-Type cases
                    3'b001: $display("SLLI   x%0d, x%0d, 0x%0x", addr_rd, addr_rs1, addr_rs2);
                    3'b101: begin
                        case(dut.execute.funct7)
                            7'b0000000: $display("SRLI     x%0d,, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SRAI     x%0d, %0d ,x%0d)", addr_rd, addr_rs1, addr_rs2);
                            default: $display("Unknown MCC shift variant (%b) under funt3=101", dut.execute.funct7); 
                        endcase
                    end
                    default: $display("Unknown MCC opcode: %b", dut.execute.opcode);
                endcase
                
            end
            `RCC: begin
                case(dut.execute.funct3)
                    3'b000:begin
                        case(dut.execute.funct7)
                            7'b0000000: $display("ADD    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SUB    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                            default: $display("Unknown RCC shift variant (%b) under funt3=000", dut.execute.funct7); 
                        endcase
                    end
                    3'b001: $display("SLL    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b010: $display("SLT    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b011: $display("SLTU   x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b100: $display("XOR    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b101:begin
                        case(dut.execute.funct7)
                            7'b0000000: $display("SRL     x%0d,, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SRA     x%0d, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            default: $display("Unknown RCC shift variant (%b) under funct3=101", dut.execute.funct7); 
                        endcase
                    end
                    3'b110: $display("OR     x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b111: $display("AND    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                endcase
            end
            `FCC: begin
                $display("NOP (fence)");
                //$display("Detected a Fence opcode, these are not implemented so treating as a NOP");
            end
            `CCC: begin
                //$write("Detected a CCC opcode\n");
                if(inst_x[31:7] == 25'd0) begin $display("ECALL  "); #5 $finish; end
                else $display("Looks an ECALL but doesn't match what I expected: %b", inst_x);

            end
            default: begin $display(" error"); end


        endcase

        $write("\n--------------------------------------\n"); 
    

    end 



    PCMux       PCMux(.clk(clk), .PCSel(PCSel), .alu_x(alu_x), .PC_f(PC_f));

    memory #(.LOAD_INSTRUCTION_MEM(1)) i_mem (.clk(clk), .address(PC_f), .data_in(32'd0), .w_enable(1'b0), .access_size(`WORD), .RdUn(1'b0), .data_out(inst_f));
       
    
    
    fetch_decode fd1(
            //inputs
            .clk(clk),
            .inst_f(inst_f),
            .PC_f(PC_f),
            //outputs

            .PC_d(PC_d),
            .inst_d(inst_d),
            .addr_rs1(addr_rs1),
            .addr_rs2(addr_rs2)
            
        );

    reg_file    reg_file(.clk(clk),
                        .addr_rs1(addr_rs1),
                        .addr_rs2(addr_rs2),
                        .addr_rd(addr_rd),
                        .data_rd(wb_w),
                        .data_rs1(data_rs1),
                        .data_rs2(data_rs2),
                        .write_enable(RegWE)
    );
    execute     execute(
        .clk(clk),
        .PC_d(PC_d),
        .rs1_d(data_rs1),
        .rs2_d(data_rs2),
        .inst_d(inst_d),
        .PC_x(PC_x),
        .inst_x(inst_x),
        .alu_x(alu_x),
        .rs2_x(rs2_x),
        .PCSel(PCSel)
    );

  
    
    mem_stage       mem_stage(
                        .clk(clk),
                        .PC_x(PC_x),
                        .alu_x(alu_x),
                        .rs2_x(rs2_x),
                        .inst_x(inst_x),
                        .inst_m(inst_m), //connect this later
                        .wb_m(wb_m)                        
    );



    WB_stage    WB(.clk(clk), .wb_m(wb_m), .inst_m(inst_m), .wb_w(wb_w), .inst_w(inst_w), .RegWE(RegWE), .addr_rd(addr_rd));
    // sequential fetching
    
    always begin
        #5 clk <= ~clk;
    end

    

endmodule


// fetch stage essentially
module PCMux(clk, PCSel, alu_x, PC_f);

    input clk;
    input PCSel;
    input [31:0]alu_x;
    output reg [31:0] PC_f;
    
    initial begin
        PC_f = 32'h01000000;
    end

    always@(posedge clk) begin
        if(PCSel)
            PC_f <= alu_x;
        else 
            //if we do this we need to nop out the fetch and decode stage
            PC_f <= PC_f + 4;
    end
endmodule

module WB_stage(clk, wb_m, inst_m, wb_w, inst_w, RegWE, addr_rd);

    input clk;
    input [31:0] wb_m;
    input [31:0] inst_m;
    output reg [31:0] wb_w;
    output [31:0] inst_w;
    output wire RegWE;
    output wire [4:0] addr_rd;

    wire [6:0] opcode;
    reg [31:0] inst_w;

    assign addr_rd = inst_w[11:7];
    assign opcode = inst_w[6:0];
    assign RegWE = (opcode == `BCC || opcode == `SCC)? 0 : 1;


    //change to posedge clk for pipelined
    always@(*) begin
        wb_w <= wb_m;
        inst_w <= inst_m;
    end



endmodule

