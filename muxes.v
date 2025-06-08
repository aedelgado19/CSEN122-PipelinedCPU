module mux2to1(a, b, sel, out);
	input [31:0] a, b;
	input sel;
	output reg [31:0] out;

	//always@() means that every time
	//an input changes, run this body of code again
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
