module imm_gen(clk, imm_in, imm_out);
	input clk;
	input [31:0] imm_in;
	output reg [31:0] imm_out;
	
	always@(posedge clk) begin
		imm_out = imm_in
	end
endmodule
