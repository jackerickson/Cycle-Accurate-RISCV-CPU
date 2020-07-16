module fetch_decode(
    input clk,
    input [31:0] inst_f,
    input [31:0] PC_f,
    input stall,
    input kill_dx,

    output [31:0] PC_d,
    output [31:0] inst_d,
    output [4:0]addr_rs1,
    output [4:0]addr_rs2
);
    //this whole file was... deleted lmao
    
    // combinational decoding
    assign addr_rs1 = inst_d[19:15];
    assign addr_rs2 = inst_d[24:20];

    reg [31:0] PC_d;
    reg [31:0] inst_d;

    wire opcode;
    wire kill_d;

    assign opcode = PC_d[6:0];
    assign kill_d = (opcode == `JAL);

    //change to posedge clk for pipelined
    always@(posedge clk) begin
        // if(stall) begin
        //     inst_d <= inst_d;
        //     PC_d <= PC_d;
        // end
        // else begin
        //     PC_d <= PC_f;
        //     inst_d <= inst_f;
        // end
        if(kill_dx) begin
            PC_d <= 32'b0;
            inst_d <= 32'h13;
        end
        else begin
            PC_d <= PC_f;
            inst_d <= inst_f;
        end
    end

endmodule