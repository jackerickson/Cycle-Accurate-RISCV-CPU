module mem_stage(
    input clk,
    input [31:0] PC,
    input [31:0] alu,
    input [31:0] rs2,
    input inst[31:0],
    
    output inst_o [31:0],
    output [31:0] wb
);


    wire WEn = 0;
    wire [2:0]funct3;
    wire [1:0] access_size;
    wire RdUn = 0;

    wire [31:0] d_mem_out;


    input [31:0] dmem;
    input [31:0] alu;
    input [31:0] pc_next;
    input [1:0] sel;

    output reg [31:0] out;


    assign funct3 = inst[14:12];
    //RdUn check if funct3 is one of the unsigned loads
    assign RdUn = funct3 == 3'b100 || funct3 == 3'b101)? 1: 0;


    assign WEn = (inst[6:0] == 7'b0100011)? 1:0; // if opcode is SX
    
    memory      d_mem(.clk(clk), .address(alu), .data_in(rs2), .w_enable(WEn), .access_size(access_size), .RdUn(RdUn), .data_out(d_mem_out));

    //might want to put RegRW control here then pass it on too...
    always@(*) begin
        case(inst[6:0])
            7'b0000011:  wb <= d_mem_out;
            7'b1101111, 7'b1100111: wb <= PC + 4;
            default: wb <= alu;
        endcase
    end 

    // DMEM access control 
    always@(*) begin
        case(funct3)
            3'b000, 3'b100: access_size <= `BYTE;
            3'b001, 3'101: access_size <= `HALFWORD;
            default: access_size <= `WORD;
        endcase
    end
    








endmodule