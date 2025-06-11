module mux2to1 #( parameter inputBitSize=32) (  //default size of 32 bits
	input [inputBitSize-1 : 0] a, 
	input [inputBitSize-1 : 0] b,
	input sel,
	output reg [inputBitSize-1 : 0] out
);

	always@(a, b, sel) begin
	    out = (sel == 0) ? a : b;
	end
endmodule
