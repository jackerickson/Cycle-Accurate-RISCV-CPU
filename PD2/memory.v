`define mem_size 1048576 //Bytes
`define source "simple_programs/SumArray.x" //Binary file to load Memory from
`define start_address 32'h01000000

module memory(
    input clk,
    input [31:0] address,
    input [31:0] data_in,
    input w_enable,
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
// module dut;

//     reg clk = 0;
//     reg [31:0] address = `start_address;
//     wire [31:0] data_out;
//     reg [31:0] data_in = 0;
//     reg w_enable = 0;

   

//     initial begin


    
//         //$dumpfile("memory_testbench.vcd");
//             // All variables (0) from module instance gate
//             $dumpvars(0, mem1);
//             $dumpvars(0, dut);
            
//             #10 address = address + 4;
//             while(data_out != 0) #10 address = address + 4;

//         //    $display("Finished Reading the program");
//         //     #20 data_in = 32'hDEADBEEF;
//         //         w_enable = 1; $display("Driving a write to current address");
//         //     #10 w_enable = 0; $display("Deasserting write");
//         //     #10 address = address + 4;
//         //         data_in = 32'h00000001;
//         //         w_enable = 1;
//         //         #3 data_in = 32'h00000001;
//         //         #3 data_in = 32'h00000002;
//         //         #3 data_in = 32'h00000003;
//         //         #3 data_in = 32'h00000004;
//         //         #3 w_enable = 0;
//              #10 $finish;
//     end
    

//     memory mem1(.clk(clk),.address(address),.data_in(data_in),.w_enable(w_enable),.data_out(data_out));

//     always begin
//         #5 clk <= ~clk;
//     end

//     always @(posedge clk) begin
//        $display("TB: time=%t address=%x data_out(h)=%x, data_in(h)=%x , w_enable=%b", $time, address,data_out,data_in,w_enable);

//     end


// endmodule
