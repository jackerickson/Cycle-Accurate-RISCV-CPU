`include "components/constants.v"

module execute(
    input clk,
    input [31:0] PC_d,
    input [31:0] rs1_d,
    input [31:0] rs2_d,
    input [31:0] inst_d,
    input [31:0] wb_w_bypass,
    input [31:0] alu_m_bypass,
    input [1:0] rs1_bypass,
    input [1:0] rs2_bypass,

    output reg [31:0] PC_x,
    output reg [31:0] inst_x,
    output wire [31:0] alu_x,
    output reg [31:0] rs2_x,
    output reg PCSel,
    output kill_dx
    );
    
    reg [31:0] rs1;
    reg [31:0] rs2;
    
    reg [31:0] ALU_in1;
    reg [31:0] ALU_in2;

    reg [31:0]imm; //need to generate immediate
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    wire ASel, BSel;
    reg [3:0] ALUSel;
    wire BrUn;
    reg kill_dx;
    reg kill;

    assign opcode = inst_x[6:0];
    assign funct3 = inst_x[14:12];
    assign funct7 = inst_x[31:25];

    


    alu alu1(.rs1(ALU_in1), .rs2(ALU_in2), .ALUsel(ALUSel),.alu_res(alu_x));

    // reg [31:0] interA;
    // reg [31:0] interB;
    reg [31:0] rs1_x;


    // //register the inputs
    always @(posedge clk) begin
        //removed now for testing
        // inst_x <= inst_d
        // PC_x <= PC_d;
        if(kill_dx) begin
            rs1 <= 32'b0;
            rs1 <= 32'b0;
            PC_x <= 32'h0;
            inst_x <= 32'h13;
        end
        else begin
            rs1 <= rs1_d;
            rs2 <= rs2_d;
            PC_x <= PC_d;
            inst_x <= inst_d;
        end
       
    end

    assign write_data = rs2_d;
    // assign rs2_x = rs2_d;

    // //control signals
    assign ASel = (opcode == `JAL || opcode == `AUIPC || opcode == `BCC)? 0: 1;
    assign BSel = (opcode == `RCC)? 1: 0;
    assign BrUn = (opcode == `BCC && (funct3 == 3'b110 || funct3 == 3'b111))? 1: 0;
    
    // BrMux
    assign BrEq = (rs1 == rs2);
    assign BrLt = BrUn ? (rs1 < rs2): ($signed(rs1) < $signed(rs2));

    
    //These have to become always blocks, bigger muxes that take control logic
    //maybe make fwding ctl provide a seperate signal like bypassSel, which says to either use  

    // need to run alu-in1/2-bypass on the rs1 rs2 regs, since beq needs to exist and beq uses immediate AND rs2 so can't tell BSel to use one or other 

    // input A and input B muxes
    // I can merge the ASel logic into this since it's not coming from outside anymore
    // assign ALU_in1 = ASel ? rs1 : PC_x;
    // assign ALU_in2 = BSel ? rs2 : imm;

    reg fault = 0;
    reg WXBP = 0;
    //rs1 and rs2 mux
    always @(*) begin
        
       
        // $display("going through the bypass mux: rs1bypass=%b rs2bypass= %b", rs1_bypass, rs2_bypass);
        //this is to do bypassing into rs1 but I'm gonna stall instead
        // case(rs1_bypass)
        //     `MX: begin WXBP = 0; fault = 0; rs1 = alu_m_bypass; end
        //     `WX:  begin WXBP = 1; fault = 0; rs1 = wb_w_bypass;end
        //     `NONE:  begin WXBP = 0;fault = 0; rs1 = rs1_x;end
        //     default: begin WXBP = 0;fault = 1; end
        // endcase
        // case(rs2_bypass)
        //     `MX: rs2 = alu_m_bypass;
        //     `WX: rs2 = wb_w_bypass;
        //     `NONE: rs2=rs2_x;
        //     default:  rs2 = rs2_x;
        // endcase

        if(ASel) begin
            case(rs1_bypass)
                `MX: ALU_in1 = alu_m_bypass;
                `WX:  ALU_in1 = wb_w_bypass;
                `NONE: ALU_in1 = rs1;
                default: ALU_in1 = rs1;
            endcase
        end
        else ALU_in1 = PC_x;

        if(BSel) begin
            case(rs2_bypass)
                `MX: ALU_in2 = alu_m_bypass;
                `WX: ALU_in2 = wb_w_bypass;
                `NONE: ALU_in2=rs2;
                default:  ALU_in2 = rs2;
            endcase
        end
        else ALU_in2 = imm;

    end



    //multi-case assigns
    always @(*) begin
        case(opcode)
            `MCC, `RCC: begin
                case (funct3)
                    3'b000: begin
                        if (opcode == `MCC) ALUSel <= `ADD;
                        else begin
                            if(funct7[5]) ALUSel <= `SUB;
                            else ALUSel <= `ADD;
                        end
                    end
                    3'b001: ALUSel <= `SLL;
                    3'b010: ALUSel <= `SLT;
                    3'b011: ALUSel <= `SLTU;
                    3'b100: ALUSel <= `XOR;
                    3'b101: begin
                        if(funct7[5])  ALUSel <= `SRA;
                        else  ALUSel <= `SRL;
                    end
                    3'b110: ALUSel <= `OR;
                    3'b111: ALUSel <= `AND;
                    default: ALUSel <= `ADD;
                endcase
            end
            `JAL, `JALR: ALUSel <= `JADD;
            `LUI: ALUSel <= `LUIOP; 
            default: ALUSel <= `ADD;
        endcase
    end

    //immediate generation
    always @(inst_x) begin
        case (opcode)
            `LUI: decode_uType();
            `AUIPC: decode_uType();
            `JAL: decode_jType();
            `BCC: decode_bType();
            `JALR, `LCC, `MCC: decode_iType();
            `RCC: decode_rType();
            `SCC: decode_sType();
            default: decode_rType();
        endcase
    end

    //PCSel
    always @(*) begin
        case  (opcode)
            `JAL, `JALR: PCSel <= 1;
            `BCC: begin
                case(funct3) // PCSel: 1 = branch, 0 = don't branch
                    3'b000: PCSel <= BrEq;//BEQ
                    3'b001: PCSel <= ~BrEq;//BNE
                    3'b100, 3'b110: PCSel <= BrLt;//BLT, BLTU 
                    3'b101, 3'b111: PCSel <= ~BrLt;//BGE, BGEU
                    // 3'b110: PCSel <= //BLTU
                    // 3'b111: PCSel <= //BGEU
                endcase
            end
            default: PCSel <= 0;
        endcase
    end

    //kill bit generation
    // if kill bit, on conditional/jalr on next insn, kill d and x
    // if kill bit, on jal just kill decode
    always @(*) begin
        case(opcode)
            `JALR: kill_dx <= 1;
            `BCC: begin
                case(funct3) // PCSel: 1 = branch, 0 = don't branch
                    3'b000: kill_dx <= BrEq;//BEQ
                    3'b001: kill_dx <= ~BrEq;//BNE
                    3'b100, 3'b110: kill_dx <= BrLt;//BLT, BLTU 
                    3'b101, 3'b111: kill_dx <= ~BrLt;//BGE, BGEU
                    // 3'b110: PCSel <= //BLTU
                    // 3'b111: PCSel <= //BGEU
                endcase
            end
            default: kill_dx <= 0;
        endcase
    end

    //Immediate decoding tasks

    //R-type requires no immediates decoding so we can just use assigns, but we must assert the enables
    task decode_rType;
        begin
            imm[31:12] <= {20{inst_x[31]}};
            //this could've been for internal ALU case selection but not in my implementation
            imm[11:0] <= inst_x[32:20];
        end
    endtask
    //12 bit immediate field
    task decode_iType;
        begin
            imm[31:12] = {20{inst_x[31]}};
            imm[11:0] = inst_x[31:20];
        end
    endtask
    //another 12 bit immediate field but split by the rd1 field
    task decode_sType;
        begin
            imm[31:12] <= {20{inst_x[31]}};
            imm[11:5] <= inst_x[31:25];
            imm[4:0] <= inst_x[11:7];
        end
    endtask

    //13 bit immediate field
    task decode_bType;
        begin
            imm[0] <= 1'b0;
            imm[31:13] <= {19{inst_x[31]}};
            imm[12] <= inst_x[31];
            imm[11] <= inst_x[7];
            imm[10:5] <= inst_x[30:25];
            imm[4:1] <= inst_x[11:8];
        end
    endtask

    task decode_uType;
        begin
            imm[31:12] <= inst_x[31:12];
            imm[11:0] <= 12'd0;
        end
    endtask

    task decode_jType;
        begin
            imm[31:21] <= {11{inst_x[31]}};
            imm[19:12] <= inst_x[19:12];
            imm[11] <= inst_x[20];
            imm[10:1] <= inst_x[30:21];
            imm[20] <= inst_x[31];
        end
    endtask
    

endmodule