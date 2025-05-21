`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Name: Yi Qian Goh
// 
// Create Date: 04/03/2025 02:40:31 PM
// Design Name: 
// Module Name: tb_mux
// Project Name: Lab 1 - 4 to 1 mux
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module mux(a, b, c, d, sel, out);
	input [1:0] sel;
	input a, b, c, d;
	output reg out;

	//always@() means that every time
	//an input changes, run this body of code again
	always@(a, b, c, d, sel[1], sel[0])
	begin
	    //out = sel[1] ? (sel[0] ? d : c) : (sel[0] ? b : a);
	    out = (~sel[1] && ~sel[0] && a) || (~sel[1] && sel[0] && b) || (sel[1] && ~sel[0] && c) || (sel[1] && sel[0] && d);
	end
endmodule

