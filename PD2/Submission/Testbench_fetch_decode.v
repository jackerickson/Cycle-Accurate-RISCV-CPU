`include "fetch_decode.v"
`include "constants.v"
`include "memory.v"

module dut;

    reg clk = 0;

    // instruction memmory inputs
    wire [31:0]next_PC;
    wire [31:0]i_mem_out;

    //Fetch_decoder inputs
    wire [31:0]instruction;
    wire [6:0]opcode;
    wire [4:0]rd;
    wire [2:0]funct3;
    wire [6:0]funct7;
    wire [4:0]rs1;
    wire [4:0]rs2;
    wire [4:0]shamt;
    wire signed [31:0]imm;
    wire rs1_en, rs2_en, rd_en, imm_e;
    wire [31:0] PC;

    initial begin
        $dumpfile("TB_fetch_decode.vcd");
        $dumpvars(0, dut);

    end

    always@(posedge clk) if(i_mem_out == 32'd0) begin
        #5$write("\n");
        $finish;

    end

    memory i_mem(.clk(clk),.address(next_PC),.data_in(32'd0),.w_enable(1'b0),.data_out(i_mem_out));

    //fetch_decode fd1(.clk(clk), instruction, opcode, rd, funct3, funct7, rs1, rs2, shamt, imm, rs1_en, rs2_en, rd_en, imm_e, PC);
    fetch_decode fd1(
            //inputs
            .clk(clk),
            .mem_out(i_mem_out),
            //outputs
            .next_PC(next_PC),
            .instruction(instruction),
            .opcode(opcode),
            .rd(rd),
            .funct3(funct3),
            .funct7(funct7),
            .rs1(rs1),
            .rs2(rs2),
            .shamt(rs2),
            .imm(imm),
            .rs1_en(rs1_en),
            .rs2_en(rs2_en),
            .rd_en(rd_en),
            .imm_e(imm_e),
            .PC(PC)
        );

    always begin
        #5 clk <= ~clk;
    end


    always@(posedge clk) begin
        //opcode determines instruction format, except for MCC types instructions (SLLI, SRLI, and SRAI are different than the other MCC instructions)
        $write("\nTB: current instruction components: opcode=%7b, func3=%3b, func7=%7b, rd=x%0d, rs1=x%0d, rs2=x%0d, imm=%0d\n", opcode, funct3, funct7, rd, rs1, rs2,imm);
       
        $write("%0x:  \t%8x    \t", PC, instruction);
        case(opcode)
            `LUI: begin
                $display("LUI    x%0d, 0x%0x", rd, imm);
            end
            `AUIPC: begin
                $display("AUIPC  x%0d, 0x%0x", rd, imm);
            end
            `JAL: begin
                $display("JAL    x%0d, %0x", rd, PC+imm);
            end
            `JALR: begin
                if (funct3 == 3'b000) begin
                    $display("JALR   x%0d, %0d(x%0d)", rd, imm,rs1);
                end
                else $display("Unknown function:%0b of Type JALR");
            end
            `BCC: begin
                case(funct3)
                    3'b000: $display("BEQ    x%0d, x%0d, %0x", rs1, rs2, PC+imm);
                    3'b001: $display("BNE    x%0d, x%0d, %0x", rs1, rs2, PC+imm);
                    3'b100: $display("BLT    x%0d, x%0d, %0x", rs1, rs2, PC+imm);
                    3'b101: $display("BGE    x%0d, x%0d, %0x", rs1, rs2, PC+imm);
                    3'b110: $display("BLTU   x%0d, x%0d, %0x", rs1, rs2, PC+imm);
                    3'b111: $display("BGEU    x%0d, x%0d, %0x", rs1, rs2,PC+imm);
                    default: $display("Unknown BCC Type: %0b", funct3);
                endcase
            end
            `LCC: begin
                case(funct3)
                    3'b000: $display("LB     %0d(x%0d)", rd, imm, rs1);
                    3'b001: $display("LH     x%0d, %0d(x%0d)", rd, imm, rs1);
                    3'b010: $display("LW     x%0d, %0d(x%0d)", rd, imm, rs1);
                    3'b100: $display("LBU    x%0d, %0d(x%0d)", rd, imm, rs1);
                    3'b101: $display("LHU    x%0d, %0d(x%0d)", rd, imm, rs1);
                    default: $display("Unknown LCC Type: %0b", funct3);
                endcase
            end
            `SCC: begin
                case(funct3)
                    3'b000: $display("SB     x%0d, %0d(x%0d)", rs2, imm, rs1);
                    3'b001: $display("SH     x%0d, %0d(x%0d)", rs2, imm, rs1);
                    3'b010: $display("SW     x%0d, %0d(x%0d)", rs2, imm, rs1);
                    default: $display("Unknown SCC Type: %0b", funct3);
                endcase
            end
            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                case(funct3)
                    //I-Type cases
                    3'b000: $display("ADDI   x%0d, x%0d, %0d", rd, rs1, imm);
                    3'b010: $display("SLTI   x%0d, x%0d, %0d", rd, rs1, imm);
                    3'b011: $display("SLTIU  x%0d, x%0d, %0d", rd, rs1, imm);
                    3'b100: $display("XORI   x%0d, x%0d, %0d", rd, rs1, imm);
                    3'b110: $display("ORI    x%0d, x%0d, %0d", rd, rs1, imm);
                    3'b111: $display("ANDI   x%0d, x%0d, %0d", rd, rs1, imm);
                    //R-Type cases
                    3'b001: $display("SLLI   x%0d, x%0d, 0x%0x", rd, rs1, shamt);
                    3'b101: begin
                        case(funct7)
                            7'b0000000: $display("SRLI     x%0d,, %0d ,%0d)", rd, rs1, shamt);
                            7'b0100000: $display("SRAI     x%0d, %0d ,x%0d)", rd, rs1, shamt);
                            default: $display("Unknown MCC shift variant (%b) under funt3=101", funct7); 
                        endcase
                    end
                    default: $display("Unknown MCC opcode: %b", opcode);
                endcase
                
            end
            `RCC: begin
                case(funct3)
                    3'b000:begin
                        case(funct7)
                            7'b0000000: $display("ADD    x%0d, x%0d, x%0d", rd, rs1, rs2);
                            7'b0100000: $display("SUB    x%0d, x%0d, x%0d", rd, rs1, rs2);
                            default: $display("Unknown RCC shift variant (%b) under funt3=000", funct7); 
                        endcase
                    end
                    3'b001: $display("SLL    x%0d, x%0d, x%0d", rd, rs1, rs2);
                    3'b010: $display("SLT    x%0d, x%0d, x%0d", rd, rs1, rs2);
                    3'b011: $display("SLTU   x%0d, x%0d, x%0d", rd, rs1, rs2);
                    3'b100: $display("XOR    x%0d, x%0d, x%0d", rd, rs1, rs2);
                    3'b101:begin
                        case(funct7)
                            7'b0000000: $display("SRL     x%0d,, %0d ,%0d)", rd, rs1, shamt);
                            7'b0100000: $display("SRA     x%0d, %0d ,%0d)", rd, rs1, shamt);
                            default: $display("Unknown RCC shift variant (%b) under funct3=101", funct7); 
                        endcase
                    end
                    3'b110: $display("OR     x%0d, x%0d, x%0d", rd, rs1, rs2);
                    3'b111: $display("AND    x%0d, x%0d, x%0d", rd, rs1, rs2);
                endcase
            end
            `FCC: begin
                $write("Detected a FCC opcode, these are not implemented\n");
            end
            `CCC: begin
                //$write("Detected a CCC opcode\n");
                if(instruction[31:7] == 25'd0) $display("ECALL  ");
                else $display("Looks an ECALL but doesn't match what I expected: %b", instruction);

            end
            default: $display(" error");


        endcase


    end








endmodule
