module fetch_decode(
    input clk,
    input [31:0] inst_f,
    input [31:0] PC_f,

    output [31:0] PC_d,
    output [31:0] inst_d,
    output [4:0]addr_rs1,
    output [4:0]addr_rs2
);
    //this whole file was... deleted lmao
    //inst_d components
    
    // combinational decoding
    assign addr_rs1 = inst_d[19:15];
    assign addr_rs2 = inst_d[24:20];

    reg [31:0] PC_d;
    reg [31:0] inst_d;

    //change to posedge clk for pipelined
    always@(*) begin
        PC_d <= PC_f;
        inst_d <= inst_f;
    end


endmodule