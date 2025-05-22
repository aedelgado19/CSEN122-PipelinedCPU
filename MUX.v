module mux(a, b, sel, out);
	input a, b, sel;
	output reg out;

	//always@() means that every time
	//an input changes, run this body of code again
	always@(a, b, sel) begin
	    out = (sel == 0) ? a : b;
	end
endmodule

