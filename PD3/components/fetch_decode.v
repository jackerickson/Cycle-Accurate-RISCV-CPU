`include "constants.v"
`define TB



module fetch_decode(
    input clk,
    input [31:0]mem_out,

    output [31:0] next_PC,
    output [31:0] instruction,
    output [6:0]opcode,
    output [4:0]rd,
    output [2:0]funct3,
    output [6:0]funct7,
    output [4:0]rs1,
    output [4:0]rs2,
    output signed [31:0]imm,
    output rs1_en,
    output rs2_en,
    output rd_en,
    output ImmSel

     `ifdef TB
        , output [31:0]PC
    `endif
    
);
    
    reg [31:0] instruction;
    wire [31:0] mem_out;
    ///Address of the instruction currently in the instruction register
    reg [31:0]PC;
    //Memory access register is 4 bytes ahead so the memory can access it while we process the current instruction
    reg [31:0]next_PC = 32'h01000000;

    //instruction components

    reg signed [31:0]imm;
    reg rs1_en, rs2_en, rd_en, imm_e;
    reg [3:0] ALUSel;

    // sequential fetching
    always@(posedge clk) begin
        instruction <= mem_out;
        PC <= next_PC;
        //increment the address selector to the memory so the next instruction will be ready to read on the next clk edge
        next_PC <= next_PC + 4;
    end

    // combinational decoding

    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];
    // assign shamt = instruction[24:20];

    always@(instruction) begin
        // $write("%x:\t %x = %b %b %b %b \t", PC, instruction, instruction[31:24], instruction[23:16], instruction[15:8], instruction[7:0]);
        //$write("%x:\t %x\t", PC, instruction);
        case(opcode)
            `LUI: decode_uType();
            `AUIPC: decode_uType();
            `JAL: decode_jType();
            `JALR: begin
                if (funct3 == 3'b000) decode_iType();
                else $display("Detected Unknown funct3: %0b of Type JALR at PC=%x", funct3, PC);
            end
            `BCC: decode_bType();
            
            `LCC: decode_iType();
                
            `SCC: decode_sType();
            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                //$write("Detected a MCC opcode\n");
                case(funct3)
                    //I-Type cases
                    3'b000, 3'b010, 3'b011,
                    3'b100, 3'b110,
                    3'b111: decode_iType();
                    //R-Type cases
                    3'b001,
                    3'b101: decode_rType();
                    default: $display("Unknown MCC opcode: %b", opcode);
                endcase
                
            end
            `RCC: decode_rType();
            `FCC: $write("Detected a FCC opcode, these are not implemented\n");
            `CCC: begin
                if(instruction[31:7] == 25'd0) begin 
                    $display("ECALL  ");
                    $finish;
                end
                else $display("Looks like ECALL but the bits are wrong: %b", instruction);

            end
            default: $display("malformed/unimplemented opcode (%0b) encountered at %8x ", opcode, PC);
        endcase
        
        

    end

    // Instruction decoder tasks by Type

    // I'm doing sign extension in the decoders, however I think sometimes the immediates are
    // sign extended and sometimes not so maybe need to move sign extension to the case stmnts

    //R-type requires no immediate decoding so we can just use assigns, but we must assert the enables
    task decode_rType;
        begin
            rd_en
     = 1;
            rs1_en = 1;
            rs2_en = 1;
            imm_e = 0;
        end
    endtask

    //12 bit immediate field
    task decode_iType;
        begin
            rd_en
     = 1;
            rs1_en = 1;
            rs2_en = 0;
            imm_e = 1;
            imm[31:12] = {20{instruction[31]}};
            imm[11:0] = instruction[31:20];
        end
    endtask
    //another 12 bit immediate field but split by the rd1 field
    task decode_sType;
        begin
            rd_en
     = 0;
            rs1_en = 1;
            rs2_en = 1;
            imm_e = 1;
            imm[31:12] = {20{instruction[31]}};
            imm[11:5] = instruction[31:25];
            imm[4:0] = instruction[11:7];
        end
    endtask

    //13 bit immediate field
    task decode_bType;
        begin
            rd_en
     = 0;
            rs1_en = 1;
            rs2_en = 1;
            imm_e = 1;
            imm[0] = 1'b0;
            imm[31:13] = {19{instruction[31]}};
            imm[12] = instruction[31];
            imm[11] = instruction[7];
            imm[10:5] = instruction[30:25];
            imm[4:1] = instruction[11:8];
        end
    endtask

    task decode_uType;
        begin
            rd_en
     = 1;
            rs1_en = 0;
            rs2_en = 0;
            imm_e = 1;
            imm[31:12] = instruction[31:12];
            imm[11:0] = 12'd0;
        end
    endtask

    task decode_jType;
        begin
            rd_en
     = 1;
            rs1_en = 0;
            rs2_en = 0;
            imm_e = 1;
            imm[31:21] = {11{instruction[31]}};
            imm[19:12] = instruction[19:12];
            imm[11] = instruction[20];
            imm[10:1] = instruction[30:21];
            imm[20] = instruction[31];
        end
    endtask


// for debugging
always@(posedge clk) begin
        //opcode determines instruction format, except for MCC types instructions (SLLI, SRLI, and SRAI are different than the other MCC instructions)
        $write("\nTB: current instruction components: opcode=%7b, func3=%3b, func7=%7b, rd=x%0d, rs1=x%0d, rs2=x%0d, imm=%0d\n", opcode, funct3, funct7, rd, rs1, rs2,imm);
       
        $write("%0x:  \t%8x    \t", PC, instruction);
        case(opcode) //output the instruction contents to the console in simulation
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
                    3'b001: $display("SLLI   x%0d, x%0d, 0x%0x", rd, rs1, rs2);
                    3'b101: begin
                        case(funct7)
                            7'b0000000: $display("SRLI     x%0d,, %0d ,%0d)", rd, rs1, rs2);
                            7'b0100000: $display("SRAI     x%0d, %0d ,x%0d)", rd, rs1, rs2);
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
                            7'b0000000: $display("SRL     x%0d,, %0d ,%0d)", rd, rs1, rs2);
                            7'b0100000: $display("SRA     x%0d, %0d ,%0d)", rd, rs1, rs2);
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