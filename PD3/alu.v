module alu(
    input [31:0]rs1,
    input [31:0]rs2, // can be either rs2 or immediate
    
    //these make up the ALUsel mux selector
    input [2:0]funct3,
    input[6:0]funct7,
    
    output alu_res);

    //we can implement 

    // always begin
    //     //FOR R-TYPE instructions
    //     //set up a decoder for funct3 and funct7 to select what kind of operation the alu should do to it's inputs



    // end


endmodule