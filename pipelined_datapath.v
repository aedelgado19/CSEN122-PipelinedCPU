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

module mux3to1(a, b, c, sel1, sel2, out);
	input [31:0] a, b, c;
	input sel1, sel2;
	output reg [31:0] out;

	wire [1:0] sel;
	assign sel = {sel1, sel2};

	always@(*) begin
		case (sel)
			2'b00: out = a;
			2'b01: out = b;
			2'b10: out = c;
			default: out = 1'b0;
		endcase
	end

endmodule
