module reg_file(
    input clk,
    input [4:0] addr_rs1,
    input [4:0] addr_rs2,
    input [4:0] addr_rd,
    input [31:0] data_rd,
    output [31:0] data_rs1,
    output [31:0] data_rs2,
    output write_enable);

    reg [31:0]user_reg[0:31]; // 2^5, 32b registers in the regfile
    // reg [31:0] data_rs1;
    // reg [31:0] data_rs2;
    // //setup var
    integer i;

    //initialize to 0
    initial begin
        for(i=0; i < 32; i++) begin
            user_reg[i] = i;          
        end

        user_reg[0] = 0;
    end
    wire [31:0] out [0:31];

    genvar j;
    generate
        for (j=0; j<32;j = j+ 1) begin
            assign out[j] = user_reg[i];
        end
    endgenerate

    // Reads Combinational
    assign data_rs1 = user_reg[addr_rs1];
    assign data_rs2 = user_reg[addr_rs2];
    // Writes Sequential

    always@(posedge clk)
    begin
        if (write_enable) begin
            //$display("Writing %d to reg %d", data_rd, addr_rd);
            if(!addr_rd == 32'd0)
                user_reg[addr_rd] <= data_rd;
        end
        for(i=0; i < 32; i++) begin
            if(i<6 || i >28)
                $write("x%0d = %0d | ", i, user_reg[i]);
        end
        $write("\n");

    end




endmodule