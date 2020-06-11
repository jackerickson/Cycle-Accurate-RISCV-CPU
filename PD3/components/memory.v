`define mem_size 1048576 //Bytes
// `define source "components/simple_programs/SumArray.x" //Binary file to load Memory from
// `define source "components/individual-instructions/rv32ui-p-srai.x" 
`define source "program.x" //used for batch running so I can run multiple tests at once
`define start_address 32'h01000000

//ADD DATA WIDTH INPUT, MODIFY READ/WRITE TO USE THIS MODIFICATION TO READ AND WRITE BITS ACCORDINGLYT
//SHOULDN'T BE TOO HARD TO DO... MAYHBE READ BYTE BY BYTE UNTIL SIGNAL SAYS STOP? OR USE AN ENUMERATION TO TELL WHICH READ TPYE TO DO

module memory(
    input clk,
    input [31:0] address,
    input [31:0] data_in,
    input w_enable,
    input [1:0] width,
    output [31:0] data_out
);

reg [31:0]data_out;
reg [7:0]mem[`start_address:`start_address + (`mem_size-1)];

//setup vars
integer i;
reg [31:0]t_mem[0:(`mem_size/4)-1];
reg [31:0]t_reg;

initial begin

    //$display("memorySize=%d", `mem_size);
    for (i=0;i<=`mem_size;i=i+1) begin
                t_mem[i] = 0;
    end

    //$display("memorySize = %dB", `mem_size);
    $readmemh(`source, t_mem);
    i = 0;

    for (i=0;i<=`mem_size;i=i+1) begin

        t_reg = t_mem[i];
        mem[(4*i)+`start_address] = t_reg[7:0];
        mem[(4*i)+1+`start_address] = t_reg[15:8];
        mem[(4*i)+2+`start_address] = t_reg[23:16];
        mem[(4*i)+3+`start_address] = t_reg[31:24];
    end     


end
// Reads Combinational

always @(w_enable, address)
begin
    if(~w_enable) begin
        data_out[7:0] <= mem[address];
        data_out[15:8] <= mem[address + 1];
        data_out[23:16] <= mem[address + 2];
        data_out[31:24] <= mem[address + 3];
    end
    else data_out <= data_out;
    
end

// Writes Sequential

always@(posedge clk)
begin
    if (w_enable) begin
        mem[address] <= data_in[7:0];
        mem[address + 1] <= data_in[15:8];
        mem[address + 2] <= data_in[23:16];
        mem[address + 3] <= data_in[31:24];

    end
end

endmodule
