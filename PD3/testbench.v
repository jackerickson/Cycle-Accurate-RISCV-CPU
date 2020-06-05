`include "components/fetch_decode.v"
`include "components/constants.v"
`include "components/memory.v"
`include "alu.v"
`include "reg_file.v"

module dut;

    reg clk = 0;

    // instruction memmory inputs
    wire [31:0]next_PC;
    wire [31:0]i_mem_out;

    //Fetch_decoder inputs
    wire [31:0]instruction;
    wire [6:0]opcode;
    wire [4:0]rd;
    wire [2:0]funct3;
    wire [6:0]funct7;
    wire [4:0]rs1;
    wire [4:0]rs2;
    wire [4:0]shamt;
    wire signed [31:0]imm;
    wire rs1_en, rs2_en, rd_en;
    wire [31:0] PC;


    // control wires from decode -> execute

    
    wire RegWEn;
    wire ImmSel; //ImmSelSel 
    wire MemRW;
    wire WBSel;


    //

    //ALU inputs

    wire [31:0] ALU_in1;
    wire [31:0] ALU_in2;
    wire [31:0] ALU_out;

    wire [31:0] wb;

    assign wb = WBSel ? ALU_out : 32'b0;
    
    // this is the mux on the 2nd ALU input that tell it to use ImmSelediate or the rs2 value
    assign ALU_in2 = ImmSel? imm: rs2; 

    initial begin
        $dumpfile("TB_fetch_decode.vcd");
        $dumpvars(0, dut);

    end

    always@(posedge clk) if(i_mem_out == 32'd0) begin
        #5$write("\n");
        $finish;

    end

    memory      i_mem(.clk(clk),.address(next_PC),.data_in(32'd0),.w_enable(1'b0),.data_out(i_mem_out));
    alu         alu1();
    reg_file    reg_file();

    fetch_decode fd1(
            //inputs
            .clk(clk),
            .mem_out(i_mem_out),
            //outputs
            .next_PC(next_PC),
            .instruction(instruction),
            .opcode(opcode),
            .rd(rd),
            .funct3(funct3),
            .funct7(funct7),
            .rs1(rs1),
            .rs2(rs2),
            .imm(imm),
            .rs1_en(rs1_en),
            .rs2_en(rs2_en),
            .rd_en(rd_en),
            .ImmSel(ImmSel),
            .PC(PC)
        );

    always begin
        #5 clk <= ~clk;
    end









    //sim debug stuff
    








endmodule
