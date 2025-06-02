module inst_mem(clk, addr, inst); //size 256x32
    input clk;
    input [7:0] addr;
    output reg [31:0] inst;
    reg [31:0] mem [0:255];

    always @(posedge clk) inst <= mem[addr];

    initial begin
        mem[0] = 32'h000;
        mem[1] = 32'h100;
        mem[2] = 32'h200;
    end
endmodule

module reg_file(clk, wrt, rd, rs, rt, data_in, rs_out, rt_out); //size 64x32
    input clk, wrt;
    input [5:0] rd, rs, rt;
    input [31:0] data_in;
    output reg [31:0] rs_out, rt_out;

    reg [31:0] rf [0:63];

    always @(posedge clk) begin
        rs_out <= rf[rs];
        rt_out <= rf[rt];
        if (wrt) rf[rd] <= data_in;
    end
endmodule

module data_mem(clk, r, w, addr, data_in, data_out); //size 65536x32
    input clk, r, w;
    input [31:0] addr, data_in;
    output reg [31:0] data_out;

    reg [31:0] mem [0:65535];
    wire [15:0] a = addr[15:0]; //made inst_mem word addressed so use 16 bits here

    always @(posedge clk) begin
        if (w) mem[a] <= data_in;
        if (r) data_out <= mem[a];
    end
endmodule

module PC(clk, in, out);
	input clk;
	input [31:0] in;
	output reg [31:0] out;
	
	initial begin
		out = 0;
	end
	
	always@(posedge clk) begin
		out = in;
	end
endmodule

module imm_gen(clk, in, out);
	input clk;
	input [31:0] in;
	output reg [31:0] out;
	
	always@(posedge clk) begin
		out = in;
	end
endmodule

