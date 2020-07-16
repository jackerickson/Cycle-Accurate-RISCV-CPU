module mem_stage(
    input clk,
    input [31:0] PC_x,
    input [31:0] alu_x,
    input [31:0] rs2_x,
    input [31:0] inst_x,
    input [31:0] wb_w_bypass,
    input WM_bypass,

    output [31:0] inst_m ,
    output reg [31:0] wb_m,
    output [31:0] alu_m
);


    
    wire WEn;
    wire [2:0]funct3;
    wire [6:0] opcode;
    wire RdUn;
    wire [31:0] d_mem_out;

    wire [31:0] DataW;
    reg [1:0] access_size;
    reg [31:0]alu_m;
    reg [31:0]rs2_m;
    reg [31:0]PC_m;
    
    reg [31:0] inst_m;

    assign opcode = inst_m[6:0];
    assign funct3 = inst_m[14:12];
    assign funct7 = inst_m[31:25];

    //DataW mux
    assign DataW = (WM_bypass)? wb_w_bypass: rs2_m; 

    //RdUn check if funct3 is one of the unsigned loads
    assign RdUn = (funct3 == 3'b100 || funct3 == 3'b101)? 1: 0;

    assign WEn = (opcode == `SCC)? 1 :0; // if opcode is SX
    
    memory      d_mem(.clk(clk), .address(alu_m), .data_in(DataW), .w_enable(WEn), .access_size(access_size), .RdUn(RdUn), .data_out(d_mem_out));
    //change to posedge clk when piplining
    always @(posedge clk) begin
        inst_m <= inst_x;
        rs2_m <= rs2_x;
        alu_m <= alu_x;
        PC_m <= PC_x;
    end

    //might want to put RegRW control here then pass it on too...
    //WBMux
    always @(*) begin
        case(inst_x[6:0])
            `LCC:  wb_m <= d_mem_out;
            `JAL, `JALR: wb_m <= PC_m + 4;
            default: wb_m <= alu_m;
        endcase
    end 

    // DMEM access control 
    always @(*) begin
        case(funct3)
            3'b000, 3'b100: access_size <= `BYTE;
            3'b001, 3'b101: access_size <= `HALFWORD;
            default: access_size <= `WORD;
        endcase
    end

endmodule