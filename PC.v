module PC(clk, pc_in, pc_out);
	input clk;
	input [7:0] pc_in;
	output reg [7:0] pc_out;
	
	initial begin
		pc_out = 0;
	end
	
	always@(posedge clk) begin
		pc_out = pc_in;
	end
endmodule
