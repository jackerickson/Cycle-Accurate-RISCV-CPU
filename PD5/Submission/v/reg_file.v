module reg_file(
    input clk,
    input [4:0] addr_rs1,
    input [4:0] addr_rs2,
    input [4:0] addr_rd,
    input [31:0] data_rd,
    input write_enable,
    output [31:0] data_rs1,
    output [31:0] data_rs2
    );

    reg [31:0]user_reg[0:31]; // 2^5, 32b registers in the regfile

    wire [31:0] out [0:31];
    // //setup var
    integer i;

    //initialize to 0
    initial begin
        for(i=0; i < 32; i++) begin
            user_reg[i] = 0;          
        end

        user_reg[2] = 32'h0100_0000 + 32'h0001_1111; //Init SP to end of memory
        user_reg[0] = 0;
        $display("Initial Contents of regfile: ");
        for (i=0;i<32;i++) begin
            $display("r%0d = 0x%0x", i, user_reg[i]);
        end
    end
    
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
    
    end

endmodule