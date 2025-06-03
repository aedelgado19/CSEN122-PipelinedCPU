module mux2to1(a, b, sel, out);
	input a, b, sel;
	output reg out;

	//always@() means that every time
	//an input changes, run this body of code again
	always@(a, b, sel) begin
	    out = (sel == 0) ? a : b;
	end
endmodule

module mux3to1(a, b, c, sel1, sel2, out);
	input a, b, c;
	input sel1, sel2;
	output reg out;

	always@(*) begin
		case (sel)
			2'b00: out = a;
			2'b01: out = b;
			2'b10: out = c;
			default: out = 1'b0;
		endcase
	end

endmodule
