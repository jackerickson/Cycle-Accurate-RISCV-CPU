`include "constants.v"


module fetch_decode(
    input clk,
    input [31:0] instruction,
    input BrEq,
    input BrLt,

    input [31:0] PC,

    output [4:0]addr_rd,
    output [4:0]addr_rs1,
    output [4:0]addr_rs2,
    output [31:0]imm,

    output RdUn,
    output [1:0] access_size,
    output PCSel,   // 1=+4 : 0=ALU
    output BrUn,
    output ASel,    // 1 <= reg, 0 <= PC
    output BSel,    // 1 <= reg, 0 <= imm
    output [3:0]ALUSel ,  
    output MemRW,   // 1 <= read, 0 <= write
    output RegWE,
    output [1:0] WBSel  // MEM, ALU, PC_NEXT 

);
    
    //data mem control wires
    reg [1:0] access_size = 2'b0;
    reg RdUn = 0;

    //execute control wires
    reg PCSel = 1;
    reg ASel, BSel, MemRW, RegWE;
    reg [1:0] WBSel = `ALU;
    reg [3:0] ALUSel = `ADD;

    //instruction components
    reg [31:0]imm;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire BrUn;
   

    // reg[1:0] state = 0;
    // always@(posedge clk) begin
    //     if(user_reg[2] == 32'h0110_0000) begin
    //         if(state < 2) state <= state + 1;
    //         else begin
    //             $display("Ending sim from sp");
    //             $finish;
    //         end
            
    //     end 
    // end

    // combinational decoding

    assign opcode = instruction[6:0];
    assign addr_rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign addr_rs1 = instruction[19:15];
    assign addr_rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];

    assign BrUn = ((opcode == `BCC) && ( (funct3 == 3'b110 ) || (funct3 == 3'b111)) )? 1 : 0;

    always@(*) begin
        //ROM instruction decoder
        case(opcode)
            `LUI: begin
                decode_uType();
                PCSel <= 1;//PC
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 0;
                ALUSel <= `LUIOP;
                MemRW <= 0;
                RegWE <= 1;
                WBSel <= `ALU;
            end
            `AUIPC: begin
                decode_uType();
                PCSel <= 1; //PC+4
                //BrUn <= 0; // X
                ASel <= 0;
                BSel <= 0;
                ALUSel <= `ADD;
                MemRW <= 0; // read
                RegWE <= 1;
                WBSel <= `ALU;
            end
            `JAL: begin 
                decode_jType();
                PCSel <= 0; //ALU
                //BrUn <= 0; // X
                ASel <= 0;
                BSel <= 0;
                ALUSel <= `JADD;
                MemRW <= 0; // read
                RegWE <= 1;
                WBSel <= `PC_NEXT;
            end
            `JALR: begin
                if (funct3 == 3'b000) begin
                    decode_iType();
                    PCSel <= 0; //ALU
                    //BrUn <= 0; // X
                    ASel <= 1;
                    BSel <= 0;
                    ALUSel <= `JADD;
                    MemRW <= 0; // read
                    RegWE <= 1;
                    WBSel <= `PC_NEXT;
                    
                    end
                else $display("Detected Unknown funct3: %0b of Type JALR at PC=%x", funct3, PC);
            end
            `BCC: begin // BRANCHES
                decode_bType();
                ASel <= 0;
                BSel <= 0;
                ALUSel <= `ADD;
                MemRW <= 0; // read
                RegWE <= 0;
                WBSel <= 0; // X
                case(funct3)
                    3'b000: begin // BEQ
                        // it may be adviseable to place //BrUn sets in their own logic block triggered on instruction, then set this always block to trigger on //BrUn (or something that will switch)
                        //BrUn <= 0; // X
                        if(BrEq) PCSel <= 0; // ALU
                        else PCSel <= 1; // PC + 4
                    end
                    3'b001:  begin// BNE
                        //BrUn <= 0; // signed
                        if(BrEq) PCSel <= 1; // ALU
                        else  PCSel <= 0;
                     end
                    3'b100: begin // BLT
                        //BrUn <= 0; // signed
                        if(BrLt) PCSel <= 0; // PC+4
                        else PCSel <= 1;  //ALU
                    end
                    3'b101: begin // BGE
                        //BrUn <= 0; // signed
                        if(BrLt) PCSel <= 1; // PC+4
                        else PCSel <= 0;  //ALU
                    end
                    3'b110: begin // BLTU
                        //BrUn <= 1; // unsigned
                        if(BrLt) PCSel <= 0; // ALU
                        else PCSel <= 1; // PC + 4
                    end
                    3'b111: begin// BGEU
                        //BrUn <= 1; // unsigned
                        if(BrLt) PCSel <= 1; // PC+4
                        else PCSel <= 0;  //ALU
                    end  
                    default: $display("Error in the BCC Decode");
                endcase          
            end
            
            `LCC: begin // LOADS ---- Might need specific signal to tell memory how much to write
                decode_iType();
                // ctl signals are the same throughout
                PCSel <= 1; //PC + 4
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 0;
                ALUSel <= `ADD;
                MemRW <= 0; // read
                RegWE <= 1;
                WBSel <= `MEM;
                // these need to create like a data width signal or smth, and a signed enable for memory to return the right shtuff (Next PD)
                case(funct3)
                    3'b000: begin // LB
                        access_size <= `BYTE;
                        RdUn <= 1'b0;
                    end
                    3'b001:begin // LH
                        access_size <=`HALFWORD;
                        RdUn <= 1'b0;
                    end
                    3'b010:begin // LW
                        access_size <=`WORD;
                        RdUn <= 1'b0;
                    end
                    3'b100:begin // LBU
                        access_size <= `BYTE;
                        RdUn <= 1'b1;
                    end
                    3'b101:begin // LHU
                        access_size <= `HALFWORD;
                        RdUn <= 1'b1;
                    end
                    default: $display("Error in the LCC Decode");
                endcase
            end
                
            `SCC: begin // STORES
                decode_sType();
                PCSel <= 1; //PC + 4
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 0;
                ALUSel <= `ADD;
                MemRW <= 1; // write
                RegWE <= 0;
                WBSel <= `MEM;
                // these need to create like a data width signal or smth, and a signed enable for memory to return the right shtuff (Next PD)

                case(funct3)
                    3'b000: access_size <= `BYTE; //SB
                    3'b001: access_size <= `HALFWORD; //SH
                    3'b010: access_size <=`WORD; //SW
                    default: $display("Error in the SCC Decode");
                endcase
            end

            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                decode_iType();
                PCSel <= 1; //PC + 4
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 0; // imm
                MemRW <= 0; // READ
                RegWE <= 1;
                WBSel <= `ALU;

                case(funct3)
                    //I-Type cases
                    3'b000: begin // ADDI
                        
                        ALUSel <= `ADD;
                    end
                    3'b010: begin //SLTI
                        
                        ALUSel <= `SLT;
                    end
                     
                    3'b011: begin //SLTIU
                        // decode_iTypeUnsigned();
                        
                        ALUSel <= `SLTU;
                    end
                    3'b100: begin //XORI
                       
                        ALUSel <= `XOR;
                    end
                    3'b110: begin //ORI
                        
                        ALUSel <= `OR;
                    end
                    3'b111: begin //ANDI
                        
                        ALUSel <= `AND;
                    end
                    //R-Type cases
                    3'b001: begin // SLLI
                        
                        ALUSel <= `SLL;
                    end
                    3'b101: begin //SRLI/SRAI
                        if(funct7==7'b0000000) ALUSel <= `SRL; //SRLI
                        else if(funct7==7'b0100000) ALUSel <= `SRA; //SRAI
                        else $display("funct7 is malformed");
                    end
                    default: $display("Unknown MCC opcode: %b", opcode);
                endcase
                
            end
            `RCC: begin
                PCSel <= 1; //PC + 4
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 1;
                MemRW <= 0; // read
                RegWE <= 1;
                WBSel <= `ALU;
                case(funct3)
                    3'b000: begin
                        if(funct7==7'b0000000) ALUSel <= `ADD;
                        else if(funct7==7'b0100000) ALUSel <= `SUB;
                    end
                    3'b001: begin // SLL
                        ALUSel <= `SLL;
                    end
                    3'b010: begin // SLT
                        ALUSel <= `SLT;
                    end
                    3'b011: begin // SLTU
                        ALUSel <= `SLTU;
                    end 
                    3'b100: begin // XOR
                        ALUSel <= `XOR;
                    end
                    3'b101: begin // SRL & SRA
                        
                        if(funct7 == 7'b0000000) ALUSel <= `SRL;
                        else if(funct7 == 7'b0100000) ALUSel <= `SRA;
                    end
                    3'b110: begin // OR
                        ALUSel <= `OR;
                    end
                    3'b111: begin // AND
                        ALUSel <= `AND;
                    end
                    default: $display("Error in RCC decode");
                endcase

            end
            `FCC: begin 
                //$write("Detected a FCC opcode, these are not implemented\n"); 
                PCSel <= 1; //PC + 4
                //BrUn <= 0; // X
                ASel <= 1;
                BSel <= 1;
                MemRW <= 0; // read
                RegWE <= 0;
                WBSel <= `ALU;
            end
            `CCC: begin
                if(instruction[31:7] != 25'd0) begin 
                    
                $display("Looks like ECALL but the bits are wrong: %b", instruction);
                    
                end
               
                

            end
            // default: $display("malformed/unimplemented opcode (%0b) encountered at %8x ", opcode, PC);
            default: $write("");
        endcase
        
        

    end

    // Instruction immediate decoder tasks by Type

 

    //R-type requires no immediates decoding so we can just use assigns, but we must assert the enables
    task decode_rType;
        begin
            imm[31:12] <= {20{instruction[31]}};
            
            imm[11:0] <= instruction[32:20];
        end
    endtask
    // task decode_rType;
    //     begin
    //         imm[31:5] <= {27{instruction[31]}};
    //         imm[4:0] <= instruction[24:20];
    //     end
    // endtask
    //12 bit immediate field
    task decode_iType;
        begin
            imm[31:12] <= {20{instruction[31]}};
            imm[11:0] <= instruction[31:20];
        end
    endtask
    //another 12 bit immediate field but split by the rd1 field
    task decode_sType;
        begin
            imm[31:12] <= {20{instruction[31]}};
            imm[11:5] <= instruction[31:25];
            imm[4:0] <= instruction[11:7];
        end
    endtask

    //13 bit immediate field
    task decode_bType;
        begin
            imm[0] <= 1'b0;
            imm[31:13] <= {19{instruction[31]}};
            imm[12] <= instruction[31];
            imm[11] <= instruction[7];
            imm[10:5] <= instruction[30:25];
            imm[4:1] <= instruction[11:8];
        end
    endtask

    task decode_uType;
        begin
            imm[31:12] <= instruction[31:12];
            imm[11:0] <= 12'd0;
        end
    endtask

    task decode_jType;
        begin
            imm[31:21] <= {11{instruction[31]}};
            imm[19:12] <= instruction[19:12];
            imm[11] <= instruction[20];
            imm[10:1] <= instruction[30:21];
            imm[20] <= instruction[31];
        end
    endtask



// for debugging
always@(instruction) begin
        //opcode determines instruction format, except for MCC types instructions (SLLI, SRLI, and SRAI are different than the other MCC instructions)
        //$write("Current instruction components: opcode=%7b, func3=%3b, func7=%7b, addr_rd=x%0d, addr_rs1=x%0d, addr_rs2=x%0d, imm=%0d\n", opcode, funct3, funct7, addr_rd, addr_rs1, addr_rs2,imm);
       
        $write("%x:  \t%8x    \t", PC, instruction);
        case(opcode) //output the instruction contents to the console in simulation
            `LUI: begin
            // 7'b0110111: begin
                $display("LUI    x%0d, 0x%0x", addr_rd, imm);
            end
            `AUIPC: begin
                $display("AUIPC  x%0d, 0x%0x", addr_rd, imm);
            end
            `JAL: begin
                
                $display("JAL    x%0d, %0x", addr_rd, PC+imm);
            end
            `JALR: begin
                if (funct3 == 3'b000) begin
                    $display("JALR   x%0d, %0d(x%0d)", addr_rd, imm,addr_rs1);
                end
                else $display("Unknown function:%0b of Type JALR");
            end
            `BCC: begin
                case(funct3)
                    3'b000: $display("BEQ    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC+imm);
                    3'b001: $display("BNE    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC+imm);
                    3'b100: $display("BLT    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC+imm);
                    3'b101: $display("BGE    x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC+imm);
                    3'b110: $display("BLTU   x%0d, x%0d, %0x", addr_rs1, addr_rs2, PC+imm);
                    3'b111: $display("BGEU    x%0d, x%0d, %0x", addr_rs1, addr_rs2,PC+imm);
                    default: $display("Unknown BCC Type: %0b", funct3);
                endcase
            end
            `LCC: begin
                case(funct3)
                    3'b000: $display("LB     %0d(x%0d)", addr_rd, imm, addr_rs1);
                    3'b001: $display("LH     x%0d, %0d(x%0d)", addr_rd, imm, addr_rs1);
                    3'b010: $display("LW     x%0d, %0d(x%0d)", addr_rd, imm, addr_rs1);
                    3'b100: $display("LBU    x%0d, %0d(x%0d)", addr_rd, imm, addr_rs1);
                    3'b101: $display("LHU    x%0d, %0d(x%0d)", addr_rd, imm, addr_rs1);
                    default: $display("Unknown LCC Type: %0b", funct3);
                endcase
            end
            `SCC: begin
                case(funct3)
                    3'b000: $display("SB     x%0d, %0d(x%0d)", addr_rs2, imm, addr_rs1);
                    3'b001: $display("SH     x%0d, %0d(x%0d)", addr_rs2, imm, addr_rs1);
                    3'b010: $display("SW     x%0d, %0d(x%0d)", addr_rs2, imm, addr_rs1);
                    default: $display("Unknown SCC Type: %0b", funct3);
                endcase
            end
            //we will always want to sign extend in MCC opcodes
            `MCC: begin
                case(funct3)
                    //I-Type cases
                    3'b000: $display("ADDI   x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    3'b010: $display("SLTI   x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    3'b011: $display("SLTIU  x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    3'b100: $display("XORI   x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    3'b110: $display("ORI    x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    3'b111: $display("ANDI   x%0d, x%0d, %0d", addr_rd, addr_rs1, imm);
                    //R-Type cases
                    3'b001: $display("SLLI   x%0d, x%0d, 0x%0x", addr_rd, addr_rs1, addr_rs2);
                    3'b101: begin
                        case(funct7)
                            7'b0000000: $display("SRLI     x%0d,, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SRAI     x%0d, %0d ,x%0d)", addr_rd, addr_rs1, addr_rs2);
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
                            7'b0000000: $display("ADD    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SUB    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                            default: $display("Unknown RCC shift variant (%b) under funt3=000", funct7); 
                        endcase
                    end
                    3'b001: $display("SLL    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b010: $display("SLT    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b011: $display("SLTU   x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b100: $display("XOR    x%0d, x%0d, x%0d", addr_rd, addr_rs1, addr_rs2);
                    3'b101:begin
                        case(funct7)
                            7'b0000000: $display("SRL     x%0d,, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            7'b0100000: $display("SRA     x%0d, %0d ,%0d)", addr_rd, addr_rs1, addr_rs2);
                            default: $display("Unknown RCC shift variant (%b) under funct3=101", funct7); 
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
                if(instruction[31:7] == 25'd0) begin $display("ECALL  "); end
                else $display("Looks an ECALL but doesn't match what I expected: %b", instruction);

            end
            default: begin $display(" error"); end


        endcase


    end



endmodule