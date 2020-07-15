// `define mem_size 1048576 //Bytes

// `define source "components/simple-programs/fact.x" //Binary file to load Memory from
// `define source "components/individual-instructions/rv32ui-p-srai.x" 
`define source "temp.x" //used for batch running so I can run multiple tests at once
`define relevant_addr 32'h010002c4
module memory(
    input clk,
    input [31:0] address,
    input [31:0] data_in,
    input w_enable,
    input [1:0] access_size,
    input RdUn, // Load Upper
    output [31:0] data_out
    );

    parameter LOAD_INSTRUCTION_MEM = 1;
    parameter start_address = 32'h01000000;
    parameter mem_size = 32'd1048576; //Bytes


    reg [31:0]data_out;
    reg [7:0]mem[start_address:start_address + (mem_size-1)];

    //setup vars
    integer i;
    reg [31:0] relevant_addr = 32'h0100_0044;
    reg [31:0]t_mem[0:(mem_size/4)-1];
    reg [31:0]t_reg;

    initial begin
        
        //$display("memorySize=%d", mem_size);
        for(i=start_address;i<mem_size + start_address;i=i+1) mem[i] = 0;
  
        //$display("memorySize = %dB", mem_size);

        //TODO: remove LOAD_INSTRUCTION_MEM 
        if(LOAD_INSTRUCTION_MEM) begin
            for (i=0;i<=mem_size;i=i+1) begin
                        t_mem[i] = 0;
            end
            $readmemh(`source, t_mem);
            i = 0;

            for (i=0;i<=mem_size;i=i+1) begin

                t_reg = t_mem[i];
                mem[(4*i)+start_address] = t_reg[7:0];
                mem[(4*i)+1+start_address] = t_reg[15:8];
                mem[(4*i)+2+start_address] = t_reg[23:16];
                mem[(4*i)+3+start_address] = t_reg[31:24];
            end     
        end

        $display("Memory at %x: %x%x%x%x", `relevant_addr,  mem[`relevant_addr + 32'd3], mem [`relevant_addr + 32'd2], mem[ `relevant_addr + 32'd1], mem[`relevant_addr ]);
        
    end 


    // Reads Combinational
    always @(w_enable, address, access_size,RdUn)
    begin

        if (address >= start_address && address < (start_address + mem_size)) begin
            
            case(access_size)
                `BYTE:begin
                    if(RdUn) begin
                        data_out[31:8] <= 24'b0;
                        data_out[7:0] <= mem[address];
                        
                    end
                    else begin
                        data_out[7:0] <= mem[address];
                        data_out[31:8] <= {24{mem[address][7]}};
                    end
                end
                `HALFWORD: begin
                    if(RdUn) begin
                        data_out[7:0] <= mem[address];
                        data_out[15:8] <= mem[address + 1];
                        data_out[31:16] <= 16'b0;
                    end
                    else begin
                        data_out[7:0] <= mem[address];
                        data_out[15:8] <= mem[address + 1];
                        data_out[31:16] <= {16{mem[address + 1][7]}};
                    end
                end
                `WORD: begin
                    //$display("Loading mem[%x] <= %x%x%x%x", address,mem[address + 3],mem[address + 2], mem[address + 1], mem[address] );
                    data_out[7:0] <= mem[address];
                    data_out[15:8] <= mem[address + 1];
                    data_out[23:16] <= mem[address + 2];
                    data_out[31:24] <= mem[address + 3];
                    //if (!LOAD_INSTRUCTION_MEM) $display("data out is now %x", data_out);
                end
                default: begin
                    $display("Issue with access_size in read defaulting to  word");
                    data_out[7:0] <= mem[address];
                    data_out[15:8] <= mem[address + 1];
                    data_out[23:16] <= mem[address + 2];
                    data_out[31:24] <= mem[address + 3];
                end
            endcase
        end
        else begin
            data_out <= 32'hBADB_ADFF;
            //$display("Address %x out of range (%x - %x) writing 0", address, start_address, start_address+mem_size);
        end
        
    end

    // Writes Sequential

    always@(posedge clk)begin
        if(~LOAD_INSTRUCTION_MEM) begin
            //$display("Contents of 10004c4 = %x%x%x%x", mem[32'h010004c4+3],mem[32'h010004c4+2],mem[32'h010004c4+1], mem[32'h010004c4]);
        end
    
        if (w_enable) begin
            case(access_size)
                `BYTE: mem[address] <= data_in[7:0];
                `HALFWORD: begin
                    mem[address] <= data_in[7:0];
                    mem[address + 1] <= data_in[15:8];
                end
                `WORD: begin
                    mem[address] <= data_in[7:0];
                    mem[address + 1] <= data_in[15:8];
                    mem[address + 2] <= data_in[23:16];
                    mem[address + 3] <= data_in[31:24];
                end
                default:begin
                    $display("Issue with access_size in write defaulting to word");
                    mem[address] <= data_in[7:0];
                    mem[address + 1] <= data_in[15:8];
                    mem[address + 2] <= data_in[23:16];
                    mem[address + 3] <= data_in[31:24];
                end
            endcase

        end
    end

endmodule
