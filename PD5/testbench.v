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
    reg [16:0] counter = 0;
    always@(posedge clk) begin
        counter <= counter + 1;
        if(dut.reg_file.user_reg[2] == 32'h0101_1111 && dut.execute.opcode == `JALR) begin 
            $display("Returning to SP at end of memory, terminating simulation.");
            
        //     // // $display("Contents of regfile: ");
        //     // for (i=0;i<32;i++) begin
        //     //     $display("r%0d = %0x", i, dut.reg_file.user_reg[i]);
        //     // end
            $finish;
        end
        if(inst_x == 32'd0) #5 $finish;
        if(inst_x == 32'hbadbadff)begin 
            if(PC_x != 32'h01000000 - 4) begin
                $display("Exiting: Instruction memory returned out of range"); 
                #10 $finish;
            end
        end

        // if(inst_x == 32'h010004e4) #5 $finish;
        // if (counter == 100 ) $finish;
    end


    //Fwding ctl logic signals
    reg [1:0] rs1_bypass;
    reg [1:0] rs2_bypass;
    wire WM_bypass;

    //Hazard ctl
    reg stall = 0;
    wire [31:0] hazard_mux_out;

    //fetch stage internals
    wire[31:0] inst_f;
    wire [31:0] PC_f;

    //fetch_decode outputs
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
    wire kill_dx;

    //mem stage outputs 
    wire [31:0] wb_m;
    wire [31:0] inst_m;
    wire [31:0] alu_m_bypass;

    //writeback stage outputs
    wire [31:0] wb_w;
    wire [31:0] inst_w;
    wire [4:0] addr_rd;
    wire RegWE; 

    //LOGGING 
    always @(posedge clk) begin
        // for debugging
        //opcode determines instruction format, except for MCC types instructions (SLLI, SRLI, and SRAI are different than the other MCC instructions)
        //$write("Current instruction components: opcode=%7b, func3=%3b, func7=%7b,inst_x[11:7]=x%0d, inst_x[19:15]=x%0d, inst_x[24:20]=x%0d, dut.execute.imm=%0d\n", opcode, funct3, funct7,inst_x[11:7], inst_x[19:15], inst_x[24:20],dut.execute.imm);
        
        $write("%x:  \t%8x    \t", PC_x, inst_x);
        
        case(dut.execute.opcode) //output the instruction contents to the console in simulation
            `LUI: begin
            // 7'b0110111: begin
                $display("LUI    x%0d, 0x%0x",inst_x[11:7], dut.execute.imm);
            end
            `AUIPC: begin
                $display("AUIPC  x%0d, 0x%0x",inst_x[11:7], dut.execute.imm);
            end
            `JAL: begin
                
                $display("JAL    x%0d, %0x",inst_x[11:7], PC_x+dut.execute.imm);
            end
            `JALR: begin
                if (dut.execute.funct3 == 3'b000) begin
                    $display("JALR   x%0d, %0d(x%0d)",inst_x[11:7], dut.execute.imm,inst_x[19:15]);
                end
                else $display("Unknown function:%0b of Type JALR");
            end
            `BCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("BEQ    x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20], PC_x+dut.execute.imm);
                    3'b001: $display("BNE    x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20], PC_x+dut.execute.imm);
                    3'b100: $display("BLT    x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20], PC_x+dut.execute.imm);
                    3'b101: $display("BGE    x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20], PC_x+dut.execute.imm);
                    3'b110: $display("BLTU   x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20], PC_x+dut.execute.imm);
                    3'b111: $display("BGEU    x%0d, x%0d, %0x", inst_x[19:15], inst_x[24:20],PC_x+dut.execute.imm);
                    default: $display("Unknown BCC Type: %0b", dut.execute.funct3);
                endcase
            end
            `LCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("LB     %0d(x%0d)",inst_x[11:7], dut.execute.imm, inst_x[19:15]);
                    3'b001: $display("LH     x%0d, %0d(x%0d)",inst_x[11:7], dut.execute.imm, inst_x[19:15]);
                    3'b010: $display("LW     x%0d, %0d(x%0d)",inst_x[11:7], dut.execute.imm, inst_x[19:15]);
                    3'b100: $display("LBU    x%0d, %0d(x%0d)",inst_x[11:7], dut.execute.imm, inst_x[19:15]);
                    3'b101: $display("LHU    x%0d, %0d(x%0d)",inst_x[11:7], dut.execute.imm, inst_x[19:15]);
                    default: $display("Unknown LCC Type: %0b", dut.execute.funct3);
                endcase
            end
            `SCC: begin
                case(dut.execute.funct3)
                    3'b000: $display("SB     x%0d, %0d(x%0d)", inst_x[24:20], dut.execute.imm, inst_x[19:15]);
                    3'b001: $display("SH     x%0d, %0d(x%0d)", inst_x[24:20], dut.execute.imm, inst_x[19:15]);
                    3'b010: $display("SW     x%0d, %0d(x%0d)", inst_x[24:20], dut.execute.imm, inst_x[19:15]);
                    default: $display("Unknown SCC Type: %0b", dut.execute.funct3);
                endcase
            end
            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                case(dut.execute.funct3)
                    //I-Type cases
                    3'b000: $display("ADDI   x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    3'b010: $display("SLTI   x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    3'b011: $display("SLTIU  x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    3'b100: $display("XORI   x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    3'b110: $display("ORI    x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    3'b111: $display("ANDI   x%0d, x%0d, %0d",inst_x[11:7], inst_x[19:15], dut.execute.imm);
                    //R-Type cases
                    3'b001: $display("SLLI   x%0d, x%0d, 0x%0x",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b101: begin
                        case(dut.execute.funct7)
                            7'b0000000: $display("SRLI     x%0d,, %0d ,%0d)",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                            7'b0100000: $display("SRAI     x%0d, %0d ,x%0d)",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
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
                            7'b0000000: $display("ADD    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                            7'b0100000: $display("SUB    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                            default: $display("Unknown RCC shift variant (%b) under funt3=000", dut.execute.funct7); 
                        endcase
                    end
                    3'b001: $display("SLL    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b010: $display("SLT    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b011: $display("SLTU   x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b100: $display("XOR    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b101:begin
                        case(dut.execute.funct7)
                            7'b0000000: $display("SRL     x%0d,, %0d ,%0d)",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                            7'b0100000: $display("SRA     x%0d, %0d ,%0d)",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                            default: $display("Unknown RCC shift variant (%b) under funct3=101", dut.execute.funct7); 
                        endcase
                    end
                    3'b110: $display("OR     x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
                    3'b111: $display("AND    x%0d, x%0d, x%0d",inst_x[11:7], inst_x[19:15], inst_x[24:20]);
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
        $display("Value at reg[30] = %0d", dut.reg_file.user_reg[30]);

        $write("\n--------------------------------------\n"); 
    

    end 
    `define RS1 19:5
    `define RD 11:7

    // assign WM_bypass = (inst_m[11:7]==inst_w[11:7]) ? 1:0;
    // assign stall = ((inst_x[6:0] == `LCC) && 
    //                     ((inst_d[19:5] == inst_x[11:7]) || (inst_d[6:0] != `SCC))
    // ) ||
    
    wire [5:0] w_rd1;
    assign w_rd1 = inst_w[11:7];
    wire [5:0] d_rs1;
    wire [5:0] d_rs2;
    assign d_rs1 = inst_d[19:15];
    assign d_rs2 = inst_d[24:20];

    // assign stall = ((inst_d[19:15] == inst_w[11:7] || inst_d[24:20] == inst_w[11:7]) && inst_w[11:7] != 5'b0);

    always @(*) begin
        
       if (
        //    || inst_m[5:0] ==  `RCC 
           ((inst_d[5:0] == `BCC || inst_d[5:0] == `SCC|| inst_m[5:0] ==  `RCC) && 
           ((inst_d[19:15] == inst_w[11:7] || inst_d[24:20] == inst_w[11:7]) && inst_w[11:7] != 5'b0)) || 
            
           ((inst_m[5:0] == `BCC || inst_m[5:0] == `SCC || inst_m[5:0] ==  `RCC) && 
           ((inst_d[19:15] == inst_m[11:7] || inst_d[24:20] == inst_m[11:7]) && inst_m[11:7] != 5'b0))
           

        //    || 

        //    ((inst_d[19:15] == inst_m[11:7] || inst_d[24:20] == inst_m[11:7]) && inst_m[11:7] != 5'b0)
            ) 
            stall = 1; // thisis for situations like add.d lines 08 to 14, decode needs results to enter into the comparator
        // || inst_d[19:15] == inst_w[24:20] 
        else stall = 0;

    
    end

    assign hazard_mux_out = (stall)? 32'h13 : inst_d;

    always @(*) begin
        if (inst_x[19:15] == inst_m[11:7] && inst_w[11:7] != 5'b0) rs1_bypass <= `MX;
        else if (inst_x[19:15] == inst_w[11:7] && inst_w[11:7] != 5'b0) rs1_bypass <= `WX;
        else rs1_bypass <= `NONE;

        if (inst_x[24:20] == inst_m[11:7] && inst_w[11:7] != 5'b0) rs2_bypass <= `MX;
        else if (inst_x[24:20] == inst_w[11:7] && inst_w[11:7] != 5'b0) rs2_bypass <= `WX;
        else rs2_bypass <= `NONE;

    end


    PCMux       PCMux(.clk(clk), .PCSel(PCSel), .stall(stall), .alu_x(alu_x), .PC_f(PC_f));

    memory #(.LOAD_INSTRUCTION_MEM(1)) i_mem (.clk(clk), .address(PC_f), .data_in(32'd0), .w_enable(1'b0), .access_size(`WORD), .RdUn(1'b0), .data_out(inst_f));
       
    
    
    fetch_decode fd1(
            //inputs
            .clk(clk),
            .inst_f(inst_f),
            .PC_f(PC_f),
            .stall(stall),
            .kill_dx(kill_dx),
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
        .inst_d(hazard_mux_out),
        .wb_w_bypass(wb_w),
        .alu_m_bypass(alu_m_bypass),
        .rs1_bypass(rs1_bypass),
        .rs2_bypass(rs2_bypass),
        //outputs
        .PC_x(PC_x),
        .inst_x(inst_x),
        .alu_x(alu_x),
        .rs2_x(rs2_x),
        .PCSel(PCSel),
        .kill_dx(kill_dx)
    );

  
    
    mem_stage       mem_stage(
                        .clk(clk),
                        .PC_x(PC_x),
                        .alu_x(alu_x),
                        .rs2_x(rs2_x),
                        .inst_x(inst_x),
                        .wb_w_bypass(wb_w),
                        .WM_bypass(WM_bypass),

                        .inst_m(inst_m), 
                        .wb_m(wb_m),       
                        .alu_m(alu_m_bypass)                 
    );



    WB_stage    WB(.clk(clk), .wb_m(wb_m), .inst_m(inst_m), .wb_w(wb_w), .inst_w(inst_w), .RegWE(RegWE), .addr_rd(addr_rd));
    // sequential fetching
    
    always begin
        #5 clk <= ~clk;
    end

    

endmodule


// fetch stage essentially
module PCMux(clk, PCSel, stall, alu_x, PC_f);

    input clk;
    input PCSel;
    input stall;
    input [31:0]alu_x;
    output reg [31:0] PC_f;
    
    initial begin
        PC_f <= 32'h01000000 - 4;
    end

    always@(posedge clk) begin
        // if(!stall) begin
        //     if(PCSel)
        //         PC_f <= alu_x;
        //     else 
        //         //if we do this we need to nop out the fetch and decode stage
        //         PC_f <= PC_f + 4;
        // end
        // else PC_f <= PC_f;

        if(!stall) begin 
            if(PCSel)
                PC_f <= alu_x;
            else 
                //if we do this we need to nop out the fetch and decode stage
                PC_f <= PC_f + 4;
        end
        // else PC_f <= PC_f;
        // if(!stall) begin
        //     if(PCSel)
        //         PC_f <= alu_x;
        //     else 
        //         //if we do this we need to nop out the fetch and decode stage
        //         PC_f <= PC_f + 4;
        // end
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
    always@(posedge clk) begin
        wb_w <= wb_m;
        inst_w <= inst_m;
    end



endmodule

