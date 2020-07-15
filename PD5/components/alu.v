module alu(
    input [31:0]rs1,
    input [31:0]rs2, // can be either rs2 or immediate
    input [3:0] ALUsel,
    //these make up the ALUsel mux selector    
    output [31:0] alu_res);

    ////!!!!!!!!!!!!!!!MAKE SURE BREQ AND BRLT ARE ASSIGNED IN BLOCKING STATEMENTS
    reg [31:0] alu_res;



    always@(*) begin
        //FOR R-TYPE instructions
        //set up a decoder for funct3 and funct7 to select what kind of operation the alu should do to it's inputs
        case (ALUsel)
            `ADD: alu_res = $signed(rs1) + $signed(rs2); 
            `AND: alu_res = rs1 & rs2;
            `OR: alu_res = rs1 | rs2;
            `SLL: alu_res = rs1 << (rs2%32);
            `SLT: begin
                 if($signed(rs1) < $signed(rs2)) alu_res = 1;
                 else alu_res = 0;
            end
            `SLTU:begin
                 if(rs1 < $unsigned(rs2)) alu_res = 1;
                 else alu_res = 0;
            end
            `SRA: alu_res =  $signed(rs1) >>> (rs2%32);
            `SRL: alu_res = rs1 >> (rs2%32);
            `SUB: alu_res = $signed(rs1) - $signed(rs2); 
            `XOR: alu_res = rs1 ^ rs2;
            `LUIOP: alu_res = rs2;
            `JADD: alu_res = ($signed(rs1) + $signed(rs2) & (32'hffff_ffff - 32'd1));
            default: begin alu_res =   $signed(rs1) + $signed(rs2); $display("Error in ALU mux %0d", ALUsel); end
        endcase
            
        
    end


endmodule