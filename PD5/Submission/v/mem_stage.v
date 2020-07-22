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
    wire [31:0] d_mem_out;

    reg [1:0] access_size;
    reg [31:0]alu_m;
    reg [31:0]rs2_m;
    reg [31:0]PC_m;
    
    reg [31:0] inst_m;

    wire [6:0] opcode = inst_m[6:0];
    wire [2:0] funct3 = inst_m[14:12];
   
    //data_in mux
    wire [31:0] data_in = (WM_bypass)? wb_w_bypass: rs2_m; 
 
    //RdUn check if funct3 is one of the unsigned loads
    wire RdUn = (funct3 == 3'b100 || funct3 == 3'b101)? 1: 0;

    wire WEn = (opcode == `SCC)? 1 :0; // if opcode is SX
    
    memory      d_mem(
        .clk(clk), 
        .address(alu_m), 
        .data_in(data_in), 
        .w_enable(WEn), 
        .access_size(access_size), 
        .RdUn(RdUn), 
        .data_out(d_mem_out)
        );
    
    // reg captures
    always @(posedge clk) begin
        inst_m <= inst_x;
        rs2_m <= rs2_x;
        alu_m <= alu_x;
        PC_m <= PC_x;
    end

    //WBMux
    //  - only wb from mem when insn is LCC
    //  - wb from PC only on J insns
    always @(*) begin
        case(inst_m[6:0])
            `LCC:  wb_m = d_mem_out;
            `JAL, `JALR: wb_m = PC_m + 4;
            default: wb_m = alu_m;
        endcase
    end 

    // DMEM access size mux
    //  - use funct3 to determine access size since for non SCC or LCC insns it doesn't matter what happens
    always @(*) begin
        case(funct3)
            3'b000, 3'b100: access_size = `BYTE;
            3'b001, 3'b101: access_size = `HALFWORD;
            default: access_size = `WORD;
        endcase
    end

endmodule