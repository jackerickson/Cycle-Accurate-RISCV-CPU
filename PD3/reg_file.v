module reg_file(
    input clk,
    input [4:0]addr_rs1,
    input [4:0] addr_rs2,
    input [5:0] addr_rd,
    input [31:0] data_rd,
    output [31:0] data_rs1,
    output [31:0] data_rs2,
    output write_enable);

    reg [31:0]user_reg[0:4]; // 2^5, 32b registers in the regfile
    reg [31:0] data_rs1;
    reg [31:0] data_rs2;
    //setup var
    integer i;

    //initialize to 0
    initial begin
        for(i=0; i < 2^5; i++) begin
            user_reg[i] = i;
        end
    end

    
    // Reads Combinational

    always @(*) begin
        data_rs1 <= user_reg[addr_rs1];
        data_rs2 <= user_reg[addr_rs2];
    end

    // Writes Sequential

    always@(posedge clk)
    begin
        if (write_enable) begin
            user_reg[addr_rd] <= data_rd;
        end
    end



endmodule