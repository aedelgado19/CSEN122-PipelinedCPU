module imm_gen(clk, in, out);
	input clk;
	input [31:0] in;
	output reg [31:0] out;
	
	always@(posedge clk) begin
		out = in;
	end
endmodule
