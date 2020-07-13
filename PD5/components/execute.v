module execute(
    input clk,
    input [31:0] PC_d,
    input [31:0] rs1_d,
    input [31:0] rs2_d,
    input [31:0] inst_d,
    // input [31:0] imm_in,
    // input [3:0] ALUSel_in,
    // input BrUn_in,
    // input ASel_in,
    // input BSel_in,
    // input MemRW,
    // input WBSel,
    // input wire [31:0] inst_x,
    output wire [31:0] PC_x,
    output wire [31:0] inst_x,
    output wire [31:0] ALU_out,
    output wire [31:0] write_data,


    output BrEq,
    output BrLt);
    
    wire [31:0] rs1 ;
    wire [31:0] rs2 ;
    // reg [31:0] imm=0;
    // reg [3:0] ALUSel=0;
    // reg BrUn=0;
    // reg ASel=0;
    // reg BSel=0;
    

    reg [31:0]imm; //need to generate immediate
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    wire ASel, BSel;
    reg [3:0] ALUSel;
    wire BrUn;

    assign opcode = inst_x[6:0];
    // assign addr_rd = inst_x[11:7];
    assign funct3 = inst_x[14:12];
    // assign addr_rs1 = inst_x[19:15];
    // assign addr_rs2 = inst_x[24:20];
    assign funct7 = inst_x[31:25];

    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;


    alu alu1(.rs1(ALU_in1), .rs2(ALU_in2), .ALUsel(ALUSel),.alu_res(ALU_out));


    // BrMux
    assign BrEq = (rs1 == rs2);
    assign BrLt = BrUn ? (rs1 < rs2): ($signed(rs1) < $signed(rs2));

    // input A and input B muxes
    assign ALU_in1 = ASel ? rs1 : PC_x;
    assign ALU_in2 = BSel ? rs2 : imm;

    // //register the inputs
    always @(posedge clk) begin
    //     rs1 <= rs1_in;
    //     rs2 <= rs2_in
    //     imm <= imm-In;
    //     ALUSel <= ALUSel_in;
    //     BrUn <= BrUn_in;
    //     ASel <= ASel_in;
    //     BSel <= BSel_in;
    //     memRW_r <= MemRW;
    //     WBSel_r <= WBSel;
    //     RegWE_r <= RegWE;

            //removed now for testing
            // inst_x <= inst_d
            // PC_x <= PC_d;
       
    end

    assign rs1 = rs1_d;
    assign rs2 = rs2_d;
    assign write_data = rs2_d;
    assign PC_m = PC_x;
    assign inst_x = inst_d;


    // //control signals
    assign ASel = (opcode == `JAL || opcode == `AUIPC || opcode == `BCC)? 0: 1;
    assign BSel = (opcode == `RCC)? 1: 0;
    assign BrUn = (opcode == `BCC && (funct3 == 3'b110 || funct3 == 3'b111))? 1: 0;
    

    //multi-case assigns
    always @(inst_x) begin
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
            `LUI: begin ALUSel <= `LUIOP; $display("LUIOP"); end
            default: ALUSel <= `ADD;
        endcase

        //immediate generation
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
            $display("Insns: %b at PC_x=%x", inst_x, PC_x );
            imm[31:12] <= {20{inst_x[31]}};
            imm[11:0] <= inst_x[31:20];
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