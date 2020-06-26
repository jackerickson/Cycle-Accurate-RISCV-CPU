module counter
	(
	input [3:0] x,
	output [3:0] z
	);

	assign z = x+1;

endmodule //counter

module top;
	reg [3:0] x;
	wire [3:0] z;
	initial begin
		// File for VCD.
		$dumpfile("hello-world.vcd");
		// All variables (0) from module
		$dumpvars(0,c);
		#0 x = 1;
		#10 x = x + 1;
		#10 x = x + 1;
	end

	always @(*) begin
		$display("[Hello world] x:%h, z:%h", x,z);
	end
	counter c(.x(x),.z(z));
endmodule // top
