 module and_assign ( x, y, z );
    input wire x, y;
    output wire z;
    assign z = x & y;
 endmodule // and_assign

 module reg_and
    (
        input wire clock,
        input wire reset,
        input wire in,
        input wire x,
        input wire y,
        output x_r,
        output y_r,
        output out
    );

    // Sequential logic
    reg out,y_r,x_r;

    always @(posedge clock ) begin
        if ( reset ) 
        begin
            out <= 0;
            x_r <= 0;
            y_r <= 0;
        end
        else
        begin
        out <= in;
        x_r <= x;
        y_r <= y;
        end

    end
    // always @(posedge clock ) begin
    //     if ( reset )
    //     x_r <= 0;
    //     else
    //     x_r <= x;
    // end
    // always @(posedge clock ) begin
    //     if ( reset )
    //     y_r <= 0;
    //     else
    //     y_r <= y;
    // end

    // assign out = out;
 endmodule // reg_and

 module dut;
    reg x, y, reset;
    reg clock = 1;
    wire z, out, x_r, y_r;

    initial begin
        $dumpfile("reg-and.vcd");
        // All variables (0) from module instance gate
        $dumpvars(0, gate);
        $dumpvars(0, reg_gate);

        #0 reset = 1;
        #19 x = 0; y = 0;
        reset <= 0; $display("Reset complete");
        #10 x = 1; y = 1; $display("set 1 1");
        #10 x = 1; y = 0;
        #10 x = 1; y = 1;
        #10 x = 0; y = 1;
        #20 $finish;
    end
    // Instantiate AND gate
    and_assign gate ( .x(x_r), .y(y_r), .z(z));
    reg_and reg_gate ( .clock(clock), .reset(reset), .in(z), .out(out), .x(x), .y(y), .x_r(x_r), .y_r(y_r) );
    // Toggle clock signal every 5
    always begin
        #5 clock = ~clock;
    end
    always @(posedge clock) begin
        $display("time=%t, reset=%b, x=%b, y=%b, x_r=%b , y_r=%b, z=%b, out=%b", $time,reset,x,y,x_r, y_r,z, out);
    end
 endmodule // dut